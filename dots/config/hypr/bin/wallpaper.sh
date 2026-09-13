#!/usr/bin/env bash
# Wallpaper + palette. The one place that knows how swww and wallust
# fit together, so the shell, autostart and your prompt all agree.
#
#   wallpaper.sh daemon       start the wallpaper daemon if it isn't up
#   wallpaper.sh set <path>   apply a specific image
#   wallpaper.sh random [t]   pick one at random — from theme t if given
#   wallpaper.sh restore      re-apply whatever was last set
#   wallpaper.sh current      print the current path
#   wallpaper.sh list         list every wallpaper found on the search path
set -euo pipefail

cache="${XDG_CACHE_HOME:-$HOME/.cache}/fxn/wallpaper"
current="$cache/current"
config="${XDG_CONFIG_HOME:-$HOME/.config}"

# Read the search path out of the shell's settings so there is a single
# source of truth. Falls back to the system collections plus a personal
# directory if the file is missing or unreadable.
settings="$config/quickshell/fxn/settings.json"
declare -a library=()
if [[ -r $settings ]] && command -v jq >/dev/null; then
  mapfile -t library < <(jq -r '.wallpaperDirs[]? // empty' "$settings" 2>/dev/null)
fi
[[ ${#library[@]} -gt 0 ]] || library=("/usr/share/backgrounds" "$HOME/Pictures/wallpapers")

mkdir -p "$cache"

die() { printf '%s: %s\n' "${0##*/}" "$1" >&2; exit 1; }

# swww and its awww fork are CLI-compatible but ship different binary
# names, and the Arch `swww` package may be either. Resolve once.
if command -v swww >/dev/null; then
  WALL=swww; WALLD=swww-daemon
elif command -v awww >/dev/null; then
  WALL=awww; WALLD=awww-daemon
else
  WALL=""; WALLD=""
fi

start_daemon() {
  [[ -n $WALLD ]] || return 1
  "$WALL" query >/dev/null 2>&1 && return 0
  "$WALLD" --format xrgb &
  # Give it a moment to take the socket before the first img call.
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    "$WALL" query >/dev/null 2>&1 && return 0
    sleep 0.2
  done
  return 1
}

apply() {
  local image=$1
  [[ -f $image ]] || die "no such file: $image"

  if start_daemon; then
    "$WALL" img "$image" \
      --transition-type grow \
      --transition-pos 0.9,0.9 \
      --transition-duration 1.2 \
      --transition-fps 60
  else
    printf '%s: no wallpaper daemon (install swww); theming anyway\n' \
      "${0##*/}" >&2
  fi

  # Point the marker at the new image. hyprlock reads this path too.
  ln -sfn "$image" "$current"

  # Colours. A hand-made theme keeps its own palette whatever the
  # wallpaper; only the Auto theme takes its colours from the image.
  # fxn-theme then turns that palette into the named roles the shell,
  # Hyprland and hyprlock all share.
  local theme
  theme=$(jq -r '.name // "auto"' "$config/quickshell/fxn/theme.json" 2>/dev/null || echo auto)
  if [[ $theme == auto ]] && command -v wallust >/dev/null; then
    wallust run "$image" --quiet --skip-sequences
    "$config/hypr/bin/fxn-theme" auto >/dev/null
  fi

  # Kitty picks up its theme file only when told to.
  if command -v kitten >/dev/null && pgrep -x kitty >/dev/null 2>&1; then
    kitten @ --to "unix:/tmp/kitty-$USER" set-colors --all --configured \
      "$config/kitty/theme.conf" 2>/dev/null || true
  fi
}

list_all() {
  local dir
  for dir in "${library[@]}"; do
    [[ -d $dir ]] || continue
    # Depth 3 reaches ~/Pictures/wallpapers/<theme>/<curated|generated>/.
    find "$dir" -maxdepth 3 -type f \
      \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
         -o -iname '*.webp' -o -iname '*.gif' \) -print0 2>/dev/null
  done
}

pick_random() {
  list_all | shuf -z -n1 | tr -d '\0'
}

case "${1:-restore}" in
  daemon)
    start_daemon || die "no swww/awww daemon available"
    ;;
  set)
    [[ ${2:-} ]] || die "usage: wallpaper.sh set <path>"
    apply "$2"
    ;;
  random)
    # With a theme, pick from that theme's own wallpapers.
    if [[ -n ${2:-} && $2 != auto ]]; then
      image=$("$config/hypr/bin/fxn-walls" list "$2" | shuf -n1)
    else
      image=$(pick_random)
    fi
    [[ -n $image ]] || die "no images found in: ${library[*]}"
    apply "$image"
    ;;
  restore)
    if [[ -L $current && -e $current ]]; then
      apply "$(readlink -f "$current")"
    else
      image=$(pick_random)
      [[ -n $image ]] && apply "$image"
    fi
    ;;
  current)
    [[ -L $current ]] && readlink -f "$current"
    ;;
  list)
    list_all | tr '\0' '\n'
    ;;
  *)
    die "unknown command: $1"
    ;;
esac
