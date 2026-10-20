# shellcheck shell=bash
#
# Shared by the installers in install/. Source it, don't run it.
#
#   ensure_gum  install gum if it is missing, then re-exec the caller so
#               the whole run is in gum, not just the part after the install
#   ui_*        gum when available, plain prompts otherwise — a missing
#               pretty-printer must never be the reason an install can't
#               proceed
#   ui_run      a long command under a spinner, its output in $FXN_LOG
#   pkgs_of     read a package list from install/packages/

INSTALL_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=$(cd -- "$INSTALL_DIR/.." && pwd)
PKG_DIR="$INSTALL_DIR/packages"

HAS_GUM=false
command -v gum >/dev/null && HAS_GUM=true

# set -e alone exits without a word, which on a live ISO looks like a hang.
# Say where it stopped. -E carries the trap into functions; it does not
# fire for tests in if/while/&&/|| — the same places set -e ignores.
set -E
on_err() {
  local rc=$1 cmd=$2 where="${BASH_SOURCE[1]:-$0}:${BASH_LINENO[0]}"
  printf '\033[31m✗ stopped at %s (exit %s)\033[0m\n    %s\n    log: %s\n' \
    "${where#"$REPO_DIR"/}" "$rc" "$cmd" "$FXN_LOG" >&2
}
trap 'on_err $? "$BASH_COMMAND"' ERR

# Everything ui_run hides behind a spinner lands here. Exported so the
# bash -c that ui_run wraps around its command can see it.
export FXN_LOG=${FXN_LOG:-${XDG_CACHE_HOME:-$HOME/.cache}/fxn/install.log}
mkdir -p "$(dirname "$FXN_LOG")"

# ensure_gum "$@" — call before the first line of output, with the
# script's original arguments. On success this does not return: the
# script starts over with gum on PATH. FXN_GUM_TRIED stops a loop when
# the install "succeeds" but gum still is not runnable.
ensure_gum() {
  $HAS_GUM && return 0
  [[ -z ${FXN_GUM_TRIED:-} ]] || return 0
  export FXN_GUM_TRIED=1

  # -y only on the live ISO, whose sync db starts empty. On an installed
  # system -Sy without -u is a partial upgrade.
  local -a cmd=(pacman -S --needed --noconfirm gum)
  [[ -d /run/archiso ]] && cmd=(pacman -Sy --needed --noconfirm gum)
  [[ $EUID -eq 0 ]] || cmd=(sudo "${cmd[@]}")

  printf '\033[2m  fetching gum for the installer UI…\033[0m\n'
  if "${cmd[@]}" >/dev/null 2>&1 && command -v gum >/dev/null; then
    exec bash "$0" "$@"
  fi
  printf '\033[33m! gum unavailable — continuing with plain prompts\033[0m\n'
}

c_accent=212; c_dim=245; c_ok=42; c_warn=214; c_err=196

ui_title() {
  if $HAS_GUM; then
    gum style --border rounded --border-foreground $c_accent \
      --padding "0 2" --margin "1 0" --bold "$*"
  else
    printf '\n\033[1;35m── %s ──\033[0m\n' "$*"
  fi
}

ui_step() { if $HAS_GUM; then gum style --margin "1 0 0 0" --foreground $c_accent --bold "── $* ──"; else printf '\n\033[1;36m── %s ──\033[0m\n' "$*"; fi; }
ui_say()  { if $HAS_GUM; then gum style --foreground $c_dim "$*"; else printf '  %s\n' "$*"; fi; }
ui_ok()   { if $HAS_GUM; then gum style --foreground $c_ok  "✓ $*"; else printf '\033[32m✓ %s\033[0m\n' "$*"; fi; }
ui_warn() { if $HAS_GUM; then gum style --foreground $c_warn "! $*"; else printf '\033[33m! %s\033[0m\n' "$*"; fi; }
ui_err()  { if $HAS_GUM; then gum style --foreground $c_err "✗ $*" >&2; else printf '\033[31m✗ %s\033[0m\n' "$*" >&2; fi; }

die() { ui_err "$*"; exit 1; }

ui_confirm() {
  local prompt=$1
  if $HAS_GUM; then
    gum confirm "$prompt"
  else
    local reply
    read -r -p "$prompt [y/N] " reply
    [[ $reply == [yY]* ]]
  fi
}

ui_input() {
  local prompt=$1 default=${2:-}
  if $HAS_GUM; then
    gum input --prompt "$prompt " --value "$default" --width 60
  else
    local reply
    read -r -e -p "$prompt " -i "$default" reply
    # -i only pre-fills under readline (a real tty); empty means default.
    printf '%s\n' "${reply:-$default}"
  fi
}

ui_password() {
  local prompt=$1
  if $HAS_GUM; then
    gum input --password --prompt "$prompt " --width 60
  else
    local reply
    read -r -s -p "$prompt " reply
    printf '\n' >&2
    printf '%s\n' "$reply"
  fi
}

# ui_choose <header> <option>...  →  one line on stdout
ui_choose() {
  local header=$1; shift
  if $HAS_GUM; then
    gum choose --header "$header" "$@"
  else
    printf '\n%s\n' "$header" >&2
    local choice
    select choice in "$@"; do
      [[ -n $choice ]] && { printf '%s\n' "$choice"; return; }
    done
  fi
}

# ui_choose_many <header> <preselected,csv> <option>...  →  one per line
ui_choose_many() {
  local header=$1 selected=$2; shift 2
  if $HAS_GUM; then
    gum choose --no-limit --header "$header" --selected "$selected" "$@"
  else
    printf '\n%s\n' "$header" >&2
    local opt reply def
    for opt in "$@"; do
      def=n; [[ ,$selected, == *",$opt,"* ]] && def=y
      read -r -p "  $opt? [$def] " reply
      if [[ ${reply:-$def} == [yY]* ]]; then printf '%s\n' "$opt"; fi
    done
  fi
}

# ui_filter <header> < options  →  one line; type to narrow (timezones)
ui_filter() {
  local header=$1
  if $HAS_GUM; then
    gum filter --header "$header" --height 15
  else
    # stdin is the option list, so the prompts read the terminal.
    local -a opts; mapfile -t opts
    local q
    read -r -p "$header (type to search): " q < /dev/tty
    local -a hits
    mapfile -t hits < <(printf '%s\n' "${opts[@]}" | grep -i -- "$q")
    [[ ${#hits[@]} -gt 0 ]] || hits=("${opts[@]}")
    ui_choose "$header" "${hits[@]}" < /dev/tty
  fi
}

# ui_run <title> <cmd>... — run a long command under a spinner, with its
# output appended to $FXN_LOG. On failure the tail of the log is shown, so
# nothing is lost by hiding it. Without gum the output goes to the screen
# as well as the log.
#
# Anything here must not prompt: the spinner owns the terminal. Callers
# that sudo run sudo_keepalive first.
ui_run() {
  local title=$1; shift
  printf '\n── %s\n$ %s\n' "$title" "$*" >> "$FXN_LOG"
  local rc=0
  if $HAS_GUM; then
    gum spin --spinner dot --title "$title" -- \
      bash -c '"$@" >>"$FXN_LOG" 2>&1' _ "$@" || rc=$?
  else
    printf '  %s…\n' "$title"
    "$@" 2>&1 | tee -a "$FXN_LOG" || rc=${PIPESTATUS[0]}
  fi
  if [[ $rc -ne 0 ]]; then
    ui_err "$title failed — last lines of $FXN_LOG:"
    $HAS_GUM && tail -n 25 "$FXN_LOG" | sed 's/^/    /' >&2
    return "$rc"
  fi
  ui_ok "$title"
}

# Ask for the sudo password once, up front, and keep the credential warm
# for the rest of the run. Without this, a sudo inside ui_run (makepkg -si
# after a long build) would prompt invisibly behind the spinner and hang.
sudo_keepalive() {
  [[ $EUID -ne 0 && -z ${FXN_SUDO_KEPT:-} ]] || return 0
  FXN_SUDO_KEPT=1
  sudo -n true 2>/dev/null || { ui_say "sudo is needed for pacman:"; sudo -v || die "sudo failed"; }
  ( while kill -0 $$ 2>/dev/null; do sudo -n true 2>/dev/null; sleep 50; done ) &
  disown
}

# pkgs_of <group>...  →  package names, one per line, comments stripped.
# A group is install/packages/<group>.txt (official) or .aur (AUR); pass
# the name with the extension.
pkgs_of() {
  local f
  for f in "$@"; do
    [[ -f $PKG_DIR/$f ]] || die "no package list: packages/$f"
    sed 's/#.*//; s/[[:space:]]\+/\n/g' "$PKG_DIR/$f" | sed '/^$/d'
  done
}

# Groups a person may choose. desktop is not optional — it is what the
# dots configure — so it is not listed here.
readonly -a OPTIONAL_GROUPS=(apps dev extras nvidia)
