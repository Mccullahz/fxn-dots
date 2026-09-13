#!/usr/bin/env bash
#
# run the playground config in a nested Hyprland session
#   ./launch.sh            start the nested session
#   ./launch.sh --clean    wipe the sandbox home first
#   ./launch.sh --shell    just run quickshell against the playground,
set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
playground=$(dirname -- "$here")
sandbox="$playground/.sandbox"

die() { printf '\033[31m%s\033[0m\n' "$*" >&2; exit 1; }
info() { printf '\033[36m▸\033[0m %s\n' "$*"; }

# ─── prereqs ──────────────────────────────────────────────
command -v Hyprland >/dev/null || die "Hyprland is not installed"
command -v qs >/dev/null || die "quickshell is not installed — pacman -S quickshell"
[[ -n ${WAYLAND_DISPLAY:-} ]] || die "not inside a Wayland session; nothing to nest in"
[[ -d $playground/config/hypr ]] || die "no config tree at $playground/config"

clean=false
shell_only=false
for arg in "$@"; do
  case $arg in
    --clean) clean=true ;;
    --shell) shell_only=true ;;
    -h|--help) sed -n '2,/^set -euo/p' "$0" | sed 's/^# \?//;$d'; exit 0 ;;
    *) die "unknown option: $arg" ;;
  esac
done

$clean && { info "wiping $sandbox"; rm -rf "$sandbox"; }

# ─── sandbox home ───────────────────────────────────────────
mkdir -p "$sandbox"/{.cache,.local/share,.local/state}

# .config points straight at the working tree, so edits are live.
ln -sfn "$playground/config" "$sandbox/.config"

for dir in Pictures Documents Downloads Music Videos; do
  [[ -d "$HOME/$dir" ]] && ln -sfn "$HOME/$dir" "$sandbox/$dir"
done

mkdir -p "$sandbox/.local/share"
[[ -d "$HOME/.local/share/applications" ]] &&
  ln -sfn "$HOME/.local/share/applications" "$sandbox/.local/share/applications"

# ─── isolated runtime dir ───────────────────────────────────
host_runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
runtime="$host_runtime/fxn-qa"
mkdir -p "$runtime"
chmod 700 "$runtime"

link_socket() {
  [[ -e "$host_runtime/$1" ]] && ln -sfn "$host_runtime/$1" "$runtime/$1"
}

link_socket "$WAYLAND_DISPLAY"
link_socket "$WAYLAND_DISPLAY.lock"
link_socket bus                      # dbus session
link_socket pipewire-0               # audio
link_socket pipewire-0.lock
link_socket pulse                    # pulse shim

# ─── Launch ─────────────────────────────────────────────────
export HOME="$sandbox"
export XDG_CONFIG_HOME="$sandbox/.config"
export XDG_CACHE_HOME="$sandbox/.cache"
export XDG_DATA_HOME="$sandbox/.local/share"
export XDG_STATE_HOME="$sandbox/.local/state"
export XDG_RUNTIME_DIR="$runtime"
export FXN_SANDBOX=1

if $shell_only; then
  info "running quickshell only against $playground/config"
  info "ctrl-c to stop"
  exec qs -c fxn
fi

info "sandbox home:  $sandbox"
info "runtime dir:   $runtime"
info "config:        $playground/config  (live — edit and it reloads)"
echo
info "Known limits of the nested session:"
echo "    · the tray is empty — the host shell already owns the"
echo "      StatusNotifierHost dbus name"
echo "    · notifications route to whichever shell claimed"
echo "      org.freedesktop.Notifications first (usually the host)"
echo "    · brightness and battery read the real hardware"
echo
info "CTRL+ALT+DELETE inside the nested window exits it"
echo

exec Hyprland -c "$sandbox/.config/hypr/hyprland.conf"
