#!/usr/bin/env bash
#
# validate the playground config without touching live session.
#
#   1. Hyprland config      — Hyprland --verify-config
#   2. hypridle config      — parse and register, then exit
#   3. Quickshell QML       — compile every module
set -uo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
playground=$(dirname -- "$here")
sandbox="$playground/.sandbox"

green() { printf '\033[32m✓\033[0m %s\n' "$*"; }
red()   { printf '\033[31m✗\033[0m %s\n' "$*"; }
head_() { printf '\n\033[1;36m── %s ──\033[0m\n' "$*"; }

mkdir -p "$sandbox"/{.cache,.local/share,.run}
ln -sfn "$playground/config" "$sandbox/.config"

sandboxed() {
  env -i \
    HOME="$sandbox" \
    XDG_CONFIG_HOME="$sandbox/.config" \
    XDG_CACHE_HOME="$sandbox/.cache" \
    XDG_DATA_HOME="$sandbox/.local/share" \
    XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" \
    ${WAYLAND_DISPLAY:+WAYLAND_DISPLAY="$WAYLAND_DISPLAY"} \
    PATH=/usr/bin:/bin \
    "$@"
}

status=0

# ─── Hyprland ───────────────────────────────────────────────
head_ "Hyprland config"
out=$(sandboxed timeout 30 Hyprland --verify-config \
        -c "$sandbox/.config/hypr/hyprland.conf" 2>&1 |
      sed -n '/Config parsing result/,$p')
if printf '%s' "$out" | grep -q 'config ok'; then
  green "hyprland.conf and every conf.d file parse"
else
  red "config errors:"
  printf '%s\n' "$out" | grep -i 'error' | sort -u | head -20
  status=1
fi

# ─── hypridle ───────────────────────────────────────────────
head_ "hypridle config"
out=$(sandboxed timeout 4 hypridle -c "$sandbox/.config/hypr/hypridle.conf" 2>&1)
if printf '%s' "$out" | grep -q 'Registered timeout rule'; then
  green "$(printf '%s' "$out" | grep -c 'Registered timeout rule') idle rules registered"
else
  red "hypridle rejected the config:"
  printf '%s\n' "$out" | head -10
  status=1
fi

# ─── Quickshell ─────────────────────────────────────────────
head_ "Quickshell QML"
if [[ -z ${WAYLAND_DISPLAY:-} ]]; then
  red "not in a Wayland session — skipping (PanelWindow needs a layer-shell backend)"
else
  out=$(sandboxed timeout 20 qs -p "$sandbox/.config/quickshell/fxn/_check.qml" \
          --no-color 2>&1)
  if printf '%s' "$out" | grep -q 'Configuration Loaded'; then
    green "all modules, services and widgets compile"
    warns=$(printf '%s' "$out" | grep -c 'WARN' || true)
    [[ $warns -gt 0 ]] && printf '  %s runtime warning(s) — run with -v to see them\n' "$warns"
  else
    red "QML errors:"
    printf '%s\n' "$out" | grep -E 'ERROR' | head -20
    status=1
  fi
fi

echo
[[ $status -eq 0 ]] && green "all checks passed" || red "checks failed"
exit $status
