#!/usr/bin/env bash
#
# fxn — fresh Arch install → this exact dot replica
#
#   ./install.sh              install everything
#   ./install.sh --list       show what would be installed, change nothing
#   ./install.sh --no-aur     skip AUR packages (drops the pokemon greeting)
#   ./install.sh --no-chsh    do not change the login shell
#
# Idempotent: safe to re-run. Anything already present is left alone,
# and every config file that exists is backed up before being replaced.
#
# Scope today: zsh and neovim. Hyprland, Quickshell and wallust are
# installed separately via ./promote.sh deploy — see README.
set -euo pipefail

readonly ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
readonly DOTS="$ROOT/dots/config"
readonly STAMP=$(date +%Y%m%d-%H%M%S)
readonly BACKUP="$HOME/.fxn-install-backup-$STAMP"

# ─── packages ────────────────────────────────────────────────
#
# Verified against core/extra on 2026-09-19. Keep this list honest:
# a name that no longer resolves aborts the run at the preflight
# check rather than halfway through.

# zsh side
readonly -a PKG_ZSH=(
  zsh                 # the shell itself
  git                 # oh-my-zsh + plugin clones
  curl                # oh-my-zsh installer
  fastfetch           # the interactive greeting
  lsd                 # the ls aliases in zshrc
  fzf                 # sourced by zshrc for ctrl-r / ctrl-t
)

# neovim side. The LSP servers are listed in init.lua's
# mason-lspconfig ensure_installed; these are the system toolchains
# Mason needs to build or run them.
readonly -a PKG_NVIM=(
  neovim
  base-devel          # treesitter parsers compile on install
  tree-sitter-cli     # :TSInstall without a vendored parser
  ripgrep             # grep backend
  fd                  # file finder backend
  unzip               # Mason unpacks release archives
  nodejs npm          # ts_ls, copilot
  go gopls            # gopls
  clang               # clangd
  lua-language-server # lua_ls
  marksman            # marksman
)

# AUR. Only two, and only one is load-bearing.
#   oh-my-posh-bin        — owns the prompt (zshrc line 19)
#   pokemon-colorscripts-git — the greeting sprite; cosmetic
readonly -a PKG_AUR=(
  oh-my-posh-bin
  pokemon-colorscripts-git
)

# oh-my-zsh custom plugins, cloned rather than packaged.
readonly -a OMZ_PLUGINS=(
  "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions"
  "zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting"
)

# neovim plugins that live in pack/ rather than under packer.
# Pinned: copilot.vim ships a language-server binary and an unpinned
# clone is a silent version drift across machines.
readonly COPILOT_TAG="v1.50.0"

# ─── ui ──────────────────────────────────────────────────────
c()    { printf '\033[%sm%s\033[0m' "$1" "$2"; }
info() { printf '%s %s\n' "$(c 36 '▸')" "$*"; }
ok()   { printf '%s %s\n' "$(c 32 '✓')" "$*"; }
warn() { printf '%s %s\n' "$(c 33 '!')" "$*"; }
die()  { printf '%s %s\n' "$(c 31 '✗')" "$*" >&2; exit 1; }
step() { printf '\n%s\n' "$(c '1;36' "── $* ──")"; }

do_aur=true
do_chsh=true
list_only=false
for arg in "$@"; do
  case $arg in
    --list)    list_only=true ;;
    --no-aur)  do_aur=false ;;
    --no-chsh) do_chsh=false ;;
    -h|--help) sed -n '2,/^set -euo/p' "$0" | sed 's/^# \?//;$d'; exit 0 ;;
    *) die "unknown option: $arg" ;;
  esac
done

# ─── preflight ───────────────────────────────────────────────
preflight() {
  step "Preflight"

  [[ -f /etc/arch-release ]] || die "this script is for Arch Linux"
  [[ $EUID -ne 0 ]] || die "run as your normal user, not root — it needs \$HOME"
  command -v pacman >/dev/null || die "pacman not found"
  command -v sudo   >/dev/null || die "sudo not found — install it first"
  [[ -d $DOTS ]] || die "no config tree at $DOTS — run this from the repo"

  # Fail now, not halfway through, if a package name has gone stale.
  info "resolving package names against core/extra"
  local -a missing=()
  local p
  for p in "${PKG_ZSH[@]}" "${PKG_NVIM[@]}"; do
    pacman -Si "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  [[ ${#missing[@]} -eq 0 ]] ||
    die "these names no longer resolve: ${missing[*]} — update install.sh"
  ok "all $(( ${#PKG_ZSH[@]} + ${#PKG_NVIM[@]} )) official packages resolve"
}

# ─── pacman ──────────────────────────────────────────────────
install_official() {
  step "Official packages"
  # --needed makes this a no-op for anything already present, which is
  # what keeps re-runs cheap.
  sudo pacman -S --needed --noconfirm "${PKG_ZSH[@]}" "${PKG_NVIM[@]}"
  ok "zsh and neovim toolchains present"
}

# ─── AUR ─────────────────────────────────────────────────────
#
# Builds yay from source rather than installing yay-bin. yay-bin links
# against a specific libalpm; when pacman later moves to a new soname
# the prebuilt binary dies with "libalpm.so.NN: cannot open shared
# object file" and takes AUR access with it. Building against the
# pacman that is actually installed avoids that.
ensure_aur_helper() {
  if command -v yay >/dev/null && yay --version >/dev/null 2>&1; then
    ok "yay present and working"
    return
  fi

  if command -v yay >/dev/null; then
    warn "yay is installed but broken (usually a libalpm soname bump) — rebuilding"
  else
    info "no AUR helper — building yay from source"
  fi

  sudo pacman -S --needed --noconfirm git base-devel
  local tmp; tmp=$(mktemp -d)
  git clone --depth 1 https://aur.archlinux.org/yay.git "$tmp/yay"
  ( cd "$tmp/yay" && makepkg -si --noconfirm )
  rm -rf "$tmp"
  ok "yay built against pacman $(pacman -Q pacman | awk '{print $2}')"
}

install_aur() {
  step "AUR packages"
  if ! $do_aur; then
    warn "skipped (--no-aur)"
    warn "without oh-my-posh the prompt falls back to a bare zsh prompt"
    return
  fi
  ensure_aur_helper
  yay -S --needed --noconfirm "${PKG_AUR[@]}"
  ok "oh-my-posh and pokemon-colorscripts present"
}

# ─── backup helper ───────────────────────────────────────────
#
# Never overwrite something the user already has without keeping a copy.
# Everything lands in one timestamped dir so a bad run is one mv away
# from being undone.
backup() {
  local path=$1
  [[ -e $path || -L $path ]] || return 0
  local rel=${path#"$HOME"/}
  mkdir -p "$BACKUP/$(dirname "$rel")"
  cp -a "$path" "$BACKUP/$rel"
  info "backed up $rel"
}

# ─── zsh ─────────────────────────────────────────────────────
install_omz() {
  step "oh-my-zsh"

  if [[ -d $HOME/.oh-my-zsh ]]; then
    ok "already installed"
  else
    # The installer would otherwise launch a subshell and rewrite
    # .zshrc; both flags below stop it doing either.
    RUNZSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    ok "installed"
  fi

  local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  local entry name url
  for entry in "${OMZ_PLUGINS[@]}"; do
    IFS='|' read -r name url <<< "$entry"
    local dest="$custom/plugins/$name"
    if [[ -d $dest ]]; then
      ok "plugin $name already present"
    else
      git clone --depth 1 "$url" "$dest"
      ok "plugin $name cloned"
    fi
  done
}

install_zsh_config() {
  step "zsh config"

  backup "$HOME/.zshrc"
  install -Dm644 "$DOTS/zsh/zshrc" "$HOME/.zshrc"
  ok "~/.zshrc"

  backup "$HOME/.config/ohmyposh/zen.toml"
  install -Dm644 "$DOTS/ohmyposh/zen.toml" "$HOME/.config/ohmyposh/zen.toml"
  ok "~/.config/ohmyposh/zen.toml"

  # zshrc's greeting calls fastfetch with these by absolute path; a
  # missing config is a visible error on every new shell.
  backup "$HOME/.config/fastfetch"
  mkdir -p "$HOME/.config/fastfetch"
  cp -a "$DOTS/fastfetch/." "$HOME/.config/fastfetch/"
  ok "~/.config/fastfetch"
}

set_login_shell() {
  step "Login shell"
  if ! $do_chsh; then
    warn "skipped (--no-chsh)"
    return
  fi
  if [[ ${SHELL:-} == */zsh ]]; then
    ok "already zsh"
    return
  fi
  info "changing login shell to zsh — this will ask for your password"
  chsh -s /usr/bin/zsh
  ok "login shell set (takes effect on next login)"
}

# ─── neovim ──────────────────────────────────────────────────
install_nvim_config() {
  step "neovim config"

  backup "$HOME/.config/nvim/init.lua"
  install -Dm644 "$DOTS/nvim/init.lua" "$HOME/.config/nvim/init.lua"
  ok "~/.config/nvim/init.lua"
}

install_nvim_plugins() {
  step "neovim plugins"

  # packer bootstraps itself from init.lua on first launch, but doing it
  # here means the headless sync below has something to run.
  local packer="$HOME/.local/share/nvim/site/pack/packer/start/packer.nvim"
  if [[ -d $packer ]]; then
    ok "packer already present"
  else
    git clone --depth 1 https://github.com/wbthomason/packer.nvim "$packer"
    ok "packer cloned"
  fi

  # copilot.vim is a pack/ plugin, not a packer one — init.lua does not
  # manage it, so it has to be cloned explicitly or Copilot silently
  # never loads.
  local copilot="$HOME/.config/nvim/pack/github/start/copilot.vim"
  if [[ -d $copilot ]]; then
    ok "copilot.vim already present"
  else
    git clone --depth 1 --branch "$COPILOT_TAG" \
      https://github.com/github/copilot.vim.git "$copilot"
    ok "copilot.vim $COPILOT_TAG cloned"
  fi

  info "syncing packer plugins (headless — this takes a minute)"
  nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync' || true

  info "installing LSP servers via Mason"
  nvim --headless -c 'MasonInstall lua-language-server gopls clangd typescript-language-server marksman' -c qall || true

  ok "plugins synced"
}

post_notes() {
  step "Done"
  ok "zsh and neovim are installed and configured"
  echo
  info "What is NOT covered by this script:"
  echo "    · Hyprland / Quickshell / wallust — use ./promote.sh deploy"
  echo "    · ~/.config/hypr/conf.d/10-monitors.conf is machine-specific"
  echo "      and intentionally never deployed; write your layout there"
  echo "    · Copilot needs ':Copilot setup' once, interactively"
  echo
  if [[ -d $BACKUP ]]; then
    info "replaced files were backed up to:"
    echo "    $BACKUP"
  else
    info "nothing needed backing up — this was a clean install"
  fi
  echo
  info "open a new shell, or: exec zsh"
}

show_list() {
  step "Official — zsh"
  printf '    %s\n' "${PKG_ZSH[@]}"
  step "Official — neovim"
  printf '    %s\n' "${PKG_NVIM[@]}"
  step "AUR"
  printf '    %s\n' "${PKG_AUR[@]}"
  step "Cloned"
  printf '    %s\n' "oh-my-zsh" "${OMZ_PLUGINS[@]%%|*}" "packer.nvim" "copilot.vim $COPILOT_TAG"
  step "Config files written"
  printf '    %s\n' \
    "~/.zshrc" \
    "~/.config/ohmyposh/zen.toml" \
    "~/.config/fastfetch/" \
    "~/.config/nvim/init.lua"
  echo
}

main() {
  printf '\n%s\n' "$(c '1;35' '  fxn — zsh + neovim')"

  if $list_only; then
    show_list
    exit 0
  fi

  preflight
  install_official
  install_aur
  install_omz
  install_zsh_config
  install_nvim_config
  install_nvim_plugins
  set_login_shell
  post_notes
}

main "$@"
