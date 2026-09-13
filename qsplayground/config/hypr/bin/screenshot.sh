#!/usr/bin/env bash
# Screenshots via grim/slurp, saved to XDG_PICTURES_DIR/Screenshots.
#
#   screenshot.sh screen      whole focused output
#   screenshot.sh area        drag a region
#   screenshot.sh window      the active window
#   screenshot.sh edit        drag a region, then open swappy
#   screenshot.sh delay <n>   whole output after n seconds
set -euo pipefail

for tool in grim slurp; do
  command -v "$tool" >/dev/null || { notify-send "Screenshot" "$tool is not installed"; exit 1; }
done

pictures="${XDG_PICTURES_DIR:-$HOME/Pictures}"
dir="$pictures/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +'%Y-%m-%d_%H-%M-%S').png"

# grim needs the output name, not the Hyprland monitor id.
focused_output() {
  hyprctl -j monitors | jq -r '.[] | select(.focused) | .name'
}

# Hyprland reports the active window's geometry in layout coordinates,
# which is exactly what grim -g wants.
active_geometry() {
  hyprctl -j activewindow |
    jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
}

finish() {
  wl-copy < "$file"
  notify-send -a Screenshot -i "$file" "Screenshot saved" "${file##*/} — copied to clipboard" \
    -A "open=Open" -A "dir=Show folder" |
  while read -r action; do
    case $action in
      open) xdg-open "$file" ;;
      dir)  xdg-open "$dir" ;;
    esac
  done &
}

case "${1:-area}" in
  screen)
    grim -o "$(focused_output)" "$file"
    finish
    ;;
  area)
    geometry=$(slurp -d) || exit 0        # cancelled
    grim -g "$geometry" "$file"
    finish
    ;;
  window)
    grim -g "$(active_geometry)" "$file"
    finish
    ;;
  edit)
    command -v swappy >/dev/null || { notify-send "Screenshot" "swappy is not installed"; exit 1; }
    geometry=$(slurp -d) || exit 0
    grim -g "$geometry" - | swappy -f -
    ;;
  delay)
    sleep "${2:-5}"
    grim -o "$(focused_output)" "$file"
    finish
    ;;
  *)
    printf 'usage: %s {screen|area|window|edit|delay <n>}\n' "${0##*/}" >&2
    exit 1
    ;;
esac
