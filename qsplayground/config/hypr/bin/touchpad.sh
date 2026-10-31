#!/usr/bin/env bash
# Toggle the touchpad. The device name must match 60-laptop.lua.
#
# Hyprland exposes no per-device enabled state to query, so it lives in
# a runtime flag file. 60-laptop.lua reads the same file, which keeps a
# disabled touchpad disabled across config reloads.
set -euo pipefail

device="asue1209:00-04f3:319f-touchpad"
flag="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/fxn-touchpad-off"

state=$(hyprctl -j devices |
  jq -r --arg d "$device" '.mice[]? | select(.name == $d) | .name' | head -1)

if [[ -z $state ]]; then
  notify-send -a Hyprland "Touchpad" "Device '$device' not found"
  exit 1
fi

if [[ -e $flag ]]; then
  rm -f "$flag"
  hyprctl eval "hl.device({ name = \"$device\", enabled = true })" >/dev/null
  notify-send -a Hyprland -i input-touchpad "Touchpad enabled"
else
  touch "$flag"
  hyprctl eval "hl.device({ name = \"$device\", enabled = false })" >/dev/null
  notify-send -a Hyprland -i input-touchpad "Touchpad disabled"
fi
