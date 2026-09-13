#!/usr/bin/env bash
# Desktop magnifier, bound to SUPER+ALT+scroll.
set -euo pipefail

factor=$(hyprctl -j getoption cursor:zoom_factor | jq -r '.float')

case "${1:-in}" in
  in)    new=$(awk -v f="$factor" 'BEGIN { f = (f < 1 ? 1 : f); print (f * 1.4 > 10 ? 10 : f * 1.4) }') ;;
  out)   new=$(awk -v f="$factor" 'BEGIN { f = (f < 1 ? 1 : f); print (f / 1.4 < 1 ? 1 : f / 1.4) }') ;;
  reset) new=1 ;;
  *)     exit 1 ;;
esac

hyprctl keyword cursor:zoom_factor "$new"
