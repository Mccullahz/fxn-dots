#!/usr/bin/env bash
# Toggle the touchpad. The device name must match 60-laptop.conf.
set -euo pipefail

device="asue1209:00-04f3:319f-touchpad"

state=$(hyprctl -j devices |
  jq -r --arg d "$device" '.mice[]? | select(.name == $d) | .name' | head -1)

if [[ -z $state ]]; then
  notify-send -a Hyprland "Touchpad" "Device '$device' not found"
  exit 1
fi

if [[ $(hyprctl getoption "device[$device]:enabled" -j | jq -r '.int') == "1" ]]; then
  hyprctl keyword "device[$device]:enabled" false
  notify-send -a Hyprland -i input-touchpad "Touchpad disabled"
else
  hyprctl keyword "device[$device]:enabled" true
  notify-send -a Hyprland -i input-touchpad "Touchpad enabled"
fi
