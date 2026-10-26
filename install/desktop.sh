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
# enable, never --now: starting greetd from inside a running session would
# put a second session on top of it. Everything here takes effect on the
# next boot.
enable_services() {
  ui_step "Services"
  local -a units=(NetworkManager.service bluetooth.service greetd.service)
  [[ " ${groups[*]} " == *" dev "* ]] && units+=(docker.service)

  # greetd is a display manager; if another one already owns
  # display-manager.service, enabling greetd would fail. sddm was this
  # installer's choice before greetd, so that one is swapped out; any
  # other is left alone.
  local dm
  dm=$(readlink /etc/systemd/system/display-manager.service 2>/dev/null || true)
  if [[ $dm == */sddm.service ]]; then
    sudo systemctl disable sddm.service >/dev/null 2>&1 &&
      ui_ok "sddm.service disabled — greetd replaces it"
  elif [[ -n $dm && $dm != */greetd.service ]]; then
    ui_warn "display manager is already $(basename "$dm") — not switching to greetd"
    units=("${units[@]/greetd.service}")
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
  # package presets, and upower by D-Bus; nothing to enable.
}

# ─── login ───────────────────────────────────────────────────
#
# The login screen is the lock screen: quickshell/fxn-greeter redraws
# hyprlock.conf for greetd. greetd runs it as the `greeter` user inside
# a bare Hyprland (fxn-greeter/hyprland.conf), and that user cannot read
# your home, so hypr/bin/fxn-greeter-sync publishes the greeter, theme
# and wallpaper to $GREETER_DIR — owned by you, readable by everyone.
readonly GREETD_CONF=/etc/greetd/config.toml
readonly GREETD_MARK="# written by fxn install/desktop.sh"
readonly GREETER_DIR=/var/lib/fxn-greeter

configure_greetd() {
  ui_step "Login screen"
  if [[ ! -d /etc/greetd ]]; then
    ui_warn "greetd is not installed — skipping"
    return
  fi
  sudo install -d -m 755 -o "$USER" -g "$(id -gn)" "$GREETER_DIR"
  # The greeter's own corner: it remembers who logged in last. Its home
  # is /, read-only, so this is the one place it can write.
  if getent passwd greeter >/dev/null; then
    sudo install -d -m 755 -o greeter -g greeter "$GREETER_DIR/state"
  fi

  # Keep whatever was there first, once; our own file is just rewritten.
  if [[ -f $GREETD_CONF ]] && ! grep -qF "$GREETD_MARK" "$GREETD_CONF"; then
    sudo cp "$GREETD_CONF" "$GREETD_CONF.fxn-orig"
    ui_ok "kept the original as $GREETD_CONF.fxn-orig"
  fi
  sudo tee "$GREETD_CONF" >/dev/null <<EOF
$GREETD_MARK — re-run it to regenerate.

[terminal]
vt = 1

[default_session]
command = "start-hyprland -- -c $GREETER_DIR/greeter/hyprland.conf"
user = "greeter"
EOF
  ui_ok "greetd → fxn-greeter (published to $GREETER_DIR)"
}

# After the deploy, so the greeter and the sync script are in ~/.config.
publish_greeter() {
  local sync="$HOME/.config/hypr/bin/fxn-greeter-sync"
  [[ -d $GREETER_DIR && -x $sync ]] || return 0
  "$sync" && ui_ok "login screen published" ||
    ui_warn "could not publish the login screen — run $sync"
}

# ─── machine quirks ──────────────────────────────────────────
#
# Each one matches on hardware, so it only lands where it is needed.
has_pci() {  # vendor device
  local dev
  for dev in /sys/bus/pci/devices/*; do
    [[ $(<"$dev/vendor") == "$1" && $(<"$dev/device") == "$2" ]] && return 0
  done
  return 1
}

machine_quirks() {
  ui_step "Machine quirks"
  local any=false

  # 2016–17 MacBook Pros (MacBookPro13,x / 14,x), told apart by their
  # Apple S3X NVMe controller. S3 ("deep") suspend never resumes on
  # them — black screen, hard reset — so suspend uses s2idle instead,
  # which skips the firmware's S3 path. The controller also does not
  # come back from D3cold, so that stays off too.
  if has_pci 0x106b 0x2003; then
    local sleep_conf=/etc/systemd/sleep.conf.d/90-fxn-s2idle.conf
    sudo install -d /etc/systemd/sleep.conf.d
    sudo tee "$sleep_conf" >/dev/null <<'EOF'
# S3 suspend never resumes on 2016–17 MacBook Pros; s2idle does.
# Written by fxn install/desktop.sh.
[Sleep]
MemorySleepMode=s2idle
EOF
    ui_ok "MacBook: suspend uses s2idle ($sleep_conf)"

    local rule=/etc/udev/rules.d/90-fxn-apple-nvme-d3cold.rules
    sudo tee "$rule" >/dev/null <<'EOF'
# Apple S3X NVMe (MacBookPro13,x / 14,x) never resumes from D3cold,
# which turns every suspend into a hard reset. Written by fxn install/desktop.sh.
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x106b", ATTR{device}=="0x2003", ATTR{d3cold_allowed}="0"
EOF
    # Apply it now as well, so the next suspend works without a reboot.
    # No udevd in arch.sh's chroot; there the rule waits for first boot.
    { sudo udevadm control --reload &&
      sudo udevadm trigger --action=add --subsystem-match=pci \
        --attr-match=vendor=0x106b --attr-match=device=0x2003; } 2>/dev/null || true
    ui_ok "Apple NVMe: D3cold off ($rule)"
    any=true
  fi

  $any || ui_ok "none for this machine"
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
  printf '    %s\n' NetworkManager bluetooth greetd
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
  configure_greetd
  machine_quirks
  user_dirs
  deploy
  publish_greeter

  ui_step "Done"
  ui_ok "reboot — the login screen is your lock screen"
  ui_say "monitors: write your layout in ~/.config/hypr/conf.d/10-monitors.conf"
}

main
