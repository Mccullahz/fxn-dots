#!/usr/bin/env bash
# Lid switch handler.
#
# Disabling the internal panel when it is the only display would leave
# the session with no output at all, so in that case suspend instead.
set -euo pipefail

internal="eDP-1"

case "${1:-}" in
  close)
    outputs=$(hyprctl -j monitors | jq -r --arg i "$internal" \
      '[.[] | select(.name != $i)] | length')
    if [[ $outputs -gt 0 ]]; then
      hyprctl keyword monitor "$internal, disable"
    else
      systemctl suspend
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
