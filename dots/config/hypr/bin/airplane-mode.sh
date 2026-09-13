#!/usr/bin/env bash
# Toggle all radios. Bound to the Rfkill key.
set -euo pipefail

if rfkill list | grep -q 'Soft blocked: yes'; then
  rfkill unblock all
  notify-send -a rfkill -i network-wireless "Airplane mode off" "Radios enabled"
else
  rfkill block all
  notify-send -a rfkill -i airplane-mode "Airplane mode on" "All radios disabled"
fi
