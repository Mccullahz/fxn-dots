#!/usr/bin/env bash
# Lid switch handler.
#
# Disabling the internal panel when it is the only display would leave
# the session with no output at all, so in that case do nothing:
# systemd-logind already suspends on lid close (HandleLidSwitch), and
# suspending here as well raced it with a second sleep request.
set -euo pipefail

internal="eDP-1"

case "${1:-}" in
  close)
    outputs=$(hyprctl -j monitors | jq -r --arg i "$internal" \
      '[.[] | select(.name != $i)] | length')
    if [[ $outputs -gt 0 ]]; then
      hyprctl keyword monitor "$internal, disable"
    fi
    ;;
  open)
    hyprctl keyword monitor "$internal, preferred, auto, 1"
    ;;
  *)
    printf 'usage: %s {close|open}\n' "${0##*/}" >&2
    exit 1
    ;;
esac
