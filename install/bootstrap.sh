#!/usr/bin/env bash
#
# fxn — get this repo onto an Arch live ISO and start install/arch.sh
#
# From the stock Arch ISO, once online:
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/mccullahz/fxn-dots/main/install/bootstrap.sh)
#
# On the fxn ISO (install/usb.sh) this is what `fxn-install` runs. The
# ISO carries the repo as it was at build time; when online, that copy is
# fast-forwarded to its upstream first, so a USB stick does not need
# rebuilding for every commit. It is used as-is when offline, when it has
# uncommitted changes, or when it cannot fast-forward.
#
#   --baked   use the ISO's copy even when online
#   anything else goes to install/arch.sh (e.g. --dry-run)
#
# Standalone on purpose — it runs before the repo, and lib.sh, exist.
set -euo pipefail

readonly REPO_URL=${FXN_REPO_URL:-https://github.com/mccullahz/fxn-dots}
readonly BRANCH=${FXN_BRANCH:-main}
readonly DEST=/root/fxn-dots
readonly BAKED=/root/fxn-dots.tar

say() { printf '\033[2m  %s\033[0m\n' "$*"; }
die() { printf '\033[31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

use_baked=false
args=()
for a in "$@"; do
  if [[ $a == --baked ]]; then use_baked=true; else args+=("$a"); fi
done

[[ $EUID -eq 0 ]] || die "run as root from the live ISO"

online=false
curl -fsS --max-time 10 -o /dev/null https://archlinux.org && online=true

# One sync for both. gum here means arch.sh is styled from its first line
# instead of restarting itself to get it.
if $online; then
  say "fetching git and gum"
  pacman -Sy --needed --noconfirm git gum >/dev/null 2>&1 ||
    say "could not install git/gum — continuing without"
fi

[[ -d $DEST || ! -f $BAKED ]] || tar -C /root -xf "$BAKED"

if [[ -d $DEST/.git ]]; then
  rev=$(git -C "$DEST" rev-parse --short HEAD 2>/dev/null || echo '?')
  if $use_baked || ! $online || ! command -v git >/dev/null; then
    say "repo: baked copy at $rev"
  elif [[ -n $(git -C "$DEST" status --porcelain) ]]; then
    say "repo: baked copy at $rev has uncommitted changes — using it as-is"
  elif git -C "$DEST" pull --ff-only -q 2>/dev/null; then
    say "repo: $rev → $(git -C "$DEST" rev-parse --short HEAD)"
  else
    say "repo: could not fast-forward — using the baked copy at $rev"
  fi
elif [[ ! -d $DEST ]]; then
  $online || die "offline, and no repo on this ISO — connect first (iwctl for wifi)"
  command -v git >/dev/null || die "git is missing and could not be installed"
  say "cloning $REPO_URL ($BRANCH)"
  git clone -q --branch "$BRANCH" "$REPO_URL" "$DEST"
fi

# </dev/tty: when this arrives through a pipe, stdin is the script, and
# every prompt after this point would read it instead of the keyboard.
exec bash "$DEST/install/arch.sh" "${args[@]}" < /dev/tty
