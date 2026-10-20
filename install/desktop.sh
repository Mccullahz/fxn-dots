#!/usr/bin/env bash
#
# fxn — the Hyprland + Quickshell desktop, onto an existing Arch install
#
#   install/desktop.sh                     install, enable services, deploy dots
#   install/desktop.sh --with apps,dev     also install optional groups
#   install/desktop.sh --list              show the plan, change nothing
#   install/desktop.sh --no-aur            skip wallust and the cursor theme
#   install/desktop.sh --no-deploy         packages and services only
#   install/desktop.sh --yes               no prompts (used by install/arch.sh)
#
# Optional groups: apps, dev, extras, nvidia — see install/packages/.
# zsh and neovim are install/fxn.sh's job; run that too.
#
# Idempotent: --needed skips what is installed, and the deploy goes
# through promote.sh, which backs up the live config before replacing it.
set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"

readonly -a ARGS=("$@")   # parsing below shifts; ensure_gum re-execs with these
groups=()
do_aur=true
do_deploy=true
assume_yes=false
list_only=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --with)      IFS=, read -r -a groups <<< "${2:?--with needs a list}"; shift ;;
    --with=*)    IFS=, read -r -a groups <<< "${1#*=}" ;;
    --list)      list_only=true ;;
    --no-aur)    do_aur=false ;;
    --no-deploy) do_deploy=false ;;
    --yes)       assume_yes=true ;;
    -h|--help)   sed -n '2,/^set -euo/p' "$0" | sed 's/^# \?//;$d'; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

for g in "${groups[@]}"; do
  [[ " ${OPTIONAL_GROUPS[*]} " == *" $g "* ]] ||
    die "unknown group: $g  (choose from: ${OPTIONAL_GROUPS[*]})"
done

official=(); aur=()
mapfile -t official < <(pkgs_of desktop.txt; for g in "${groups[@]}"; do pkgs_of "$g.txt"; done)
mapfile -t aur      < <(pkgs_of desktop.aur)

# ─── preflight ───────────────────────────────────────────────
preflight() {
  ui_step "Preflight"
  [[ -f /etc/arch-release ]] || die "this script is for Arch Linux"
  [[ $EUID -ne 0 ]] || die "run as your normal user, not root — it needs \$HOME"
  command -v sudo >/dev/null || die "sudo not found — install it first"

  # A stale name aborts here rather than halfway through the transaction.
  local -a missing=()
  local p
  for p in "${official[@]}"; do
    pacman -Si "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  [[ ${#missing[@]} -eq 0 ]] ||
    die "these names no longer resolve: ${missing[*]} — update install/packages/"
  ui_ok "all ${#official[@]} official packages resolve"
}

# ─── packages ────────────────────────────────────────────────
install_official() {
  ui_step "Official packages"
  ui_run "pacman — ${#official[@]} packages" sudo pacman -S --needed --noconfirm "${official[@]}"
}

# Same reasoning as install/fxn.sh: build yay from source so it links
# against the libalpm that is actually installed. yay-bin breaks on the
# next pacman soname bump and takes AUR access with it.
ensure_aur_helper() {
  if command -v yay >/dev/null && yay --version >/dev/null 2>&1; then
    return
  fi
  ui_run "yay build deps" sudo pacman -S --needed --noconfirm git base-devel
  local tmp; tmp=$(mktemp -d)
  ui_run "fetching yay" git clone --depth 1 https://aur.archlinux.org/yay.git "$tmp/yay"
  ui_run "building yay" bash -c 'cd "$1" && makepkg -si --noconfirm' _ "$tmp/yay"
  rm -rf "$tmp"
}

install_aur() {
  ui_step "AUR packages"
  if ! $do_aur; then
    ui_warn "skipped (--no-aur) — the Auto theme needs wallust"
    return
  fi
  ensure_aur_helper
  ui_run "AUR — ${aur[*]}" yay -S --needed --noconfirm "${aur[@]}"
}

# ─── services ────────────────────────────────────────────────
#
# enable, never --now: starting sddm from inside a running session would
# put a second greeter on top of it. Everything here takes effect on the
# next boot.
enable_services() {
  ui_step "Services"
  local -a units=(NetworkManager.service bluetooth.service sddm.service)
  [[ " ${groups[*]} " == *" dev "* ]] && units+=(docker.service)

  # sddm is a display manager; if another one already owns
  # display-manager.service, enabling sddm would fail. Leave it alone.
  local dm
  dm=$(readlink /etc/systemd/system/display-manager.service 2>/dev/null || true)
  if [[ -n $dm && $dm != */sddm.service ]]; then
    ui_warn "display manager is already $(basename "$dm") — not switching to sddm"
    units=("${units[@]/sddm.service}")
  fi

  local u
  for u in "${units[@]}"; do
    [[ -n $u ]] || continue
    sudo systemctl enable "$u" >/dev/null 2>&1 && ui_ok "$u" || ui_warn "could not enable $u"
  done

  if [[ " ${groups[*]} " == *" dev "* ]] && ! id -nG | grep -qw docker; then
    sudo usermod -aG docker "$USER"
    ui_ok "added $USER to docker (next login)"
  fi

  # PipeWire and WirePlumber are socket-activated per user by their
  # package presets; nothing to enable.
}

# ─── dots ────────────────────────────────────────────────────
user_dirs() {
  xdg-user-dirs-update 2>/dev/null || true
  # Settings.qml's default wallpaperDirs. The picker is empty without it.
  mkdir -p "$HOME/Pictures/wallpapers"
}

deploy() {
  ui_step "Deploy dots"
  if ! $do_deploy; then
    ui_warn "skipped (--no-deploy) — run ./promote.sh deploy when ready"
    return
  fi
  local -a args=(deploy)
  $assume_yes && args+=(--yes)
  # A deploy that refuses (e.g. the Hyprland config fails to verify) must
  # not abort the whole install — the packages are in, and the fix is one
  # re-run away.
  if ! "$REPO_DIR/promote.sh" "${args[@]}"; then
    ui_warn "deploy did not complete — fix and re-run: $REPO_DIR/promote.sh deploy"
    return 0
  fi
}

show_list() {
  ui_step "Official — desktop${groups:+ + ${groups[*]}}"
  printf '    %s\n' "${official[@]}"
  ui_step "AUR"
  printf '    %s\n' "${aur[@]}"
  ui_step "Services enabled"
  printf '    %s\n' NetworkManager bluetooth sddm
  [[ " ${groups[*]} " == *" dev "* ]] && printf '    %s\n' docker
  ui_step "Then"
  printf '    %s\n' "./promote.sh deploy  — dots/ → ~/.config"
  echo
}

main() {
  $list_only || ensure_gum "${ARGS[@]}"
  ui_title "fxn — desktop"
  if $list_only; then show_list; exit 0; fi

  preflight
  sudo_keepalive
  install_official
  install_aur
  enable_services
  user_dirs
  deploy

  ui_step "Done"
  ui_ok "reboot (or log out) and pick Hyprland in sddm"
  ui_say "monitors: write your layout in ~/.config/hypr/conf.d/10-monitors.conf"
}

main
