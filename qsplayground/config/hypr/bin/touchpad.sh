#!/usr/bin/env bash
# Toggle the touchpad. The device name must match 60-laptop.lua.
#
# Hyprland 0.57 dropped `hyprctl keyword` and per-device getoption, so
# the state is tracked in $XDG_RUNTIME_DIR (cleared on logout, matching
# the config, which enables the touchpad at login).
set -euo pipefail

device="asue1209:00-04f3:319f-touchpad"
state_file="${XDG_RUNTIME_DIR:-/tmp}/fxn-touchpad-disabled"

found=$(hyprctl -j devices |
  jq -r --arg d "$device" '.mice[]? | select(.name == $d) | .name' | head -1)

if [[ -z $found ]]; then
  notify-send -a Hyprland "Touchpad" "Device '$device' not found"
  exit 1
fi

if [[ -e $state_file ]]; then
  hyprctl eval "hl.device({ name = \"$device\", enabled = true })" >/dev/null
  rm -f "$state_file"
  notify-send -a Hyprland -i input-touchpad "Touchpad enabled"
else
  hyprctl eval "hl.device({ name = \"$device\", enabled = false })" >/dev/null
  : > "$state_file"
  notify-send -a Hyprland -i input-touchpad "Touchpad disabled"
fi
