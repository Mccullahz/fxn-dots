#!/usr/bin/env bash
# One-line status for the hyprlock screen.
set -euo pipefail

parts=()

# Battery
for supply in /sys/class/power_supply/BAT*; do
  [[ -r $supply/capacity ]] || continue
  capacity=$(< "$supply/capacity")
  status=$(< "$supply/status")
  case $status in
    Charging) icon="󰂄" ;;
    Full)     icon="󰁹" ;;
    *)        icon="󰁽" ;;
  esac
  parts+=("$icon $capacity%")
  break
done

# Network
if command -v nmcli >/dev/null; then
  ssid=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null |
    awk -F: '$2 ~ /wireless/ { print $1; exit }')
  if [[ -n $ssid ]]; then
    parts+=("󰤨 $ssid")
  elif nmcli -t -f TYPE,STATE device 2>/dev/null | grep -q '^ethernet:connected'; then
    parts+=("󰈀 Wired")
  fi
fi

# Unread notifications, if the shell is up
if command -v qs >/dev/null; then
  count=$(qs -c fxn ipc call shell status 2>/dev/null |
    grep -o '"notifications":[0-9]*' | cut -d: -f2 || true)
  [[ ${count:-0} -gt 0 ]] && parts+=("󱅫 $count")
fi

(IFS='   '; printf '%s\n' "${parts[*]}")
