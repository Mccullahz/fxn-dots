#!/usr/bin/env bash
#
#   dotfile promotion pipeline
#
#   qsplayground/  →  dots/  →  your live ~/.config
#      (testing)      (prod)      (the system)
#
#   stage    promote the playground to dots/, replacing the backup
#   deploy   promote dots/ onto the system, replacing the backup
#            --yes: no prompts, default target paths (used by install/)
#   init     (re)run the target path detection wizard
#   status   show what differs at each stage
#   diff     show the actual diff for one stage
#   rollback restore the most recent backup of either stage
set -euo pipefail

readonly ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
readonly PLAYGROUND="$ROOT/qsplayground/config"
readonly DOTS="$ROOT/dots"
readonly BACKUPS="$ROOT/.backups"
readonly STATE="$ROOT/promote.json"

readonly -a PRESERVE=(
  "hypr/conf.d/99-local.conf"
  "hypr/conf.d/10-monitors.conf"
  "hypr/theme/colors.conf"
  "hypr/theme/roles.conf"
  "quickshell/fxn/theme.json"
)

# Written at runtime and never shipped from the repo: carry_over copies
# these back out of the live target, so a deploy cannot delete them.
#   quickshell/fxn/settings.json  — written by the running shell, derived
#                                   entirely from defaults in QML.
#   kitty/theme.conf              — the terminal palette, rewritten by
#                                   wallust and fxn-theme on every theme
#                                   change. Shipping it would reset the
#                                   colours on every deploy.
#   nvim/pack, nvim/plugin        — packer and the pack/ plugins, installed
#                                   by install/fxn.sh. Without these two the
#                                   nvim component ships a lone init.lua and
#                                   a deploy would wipe copilot.vim (45M)
#                                   and plugin/packer_compiled.lua.
readonly -a GENERATED=(
  "quickshell/fxn/settings.json"
  "kitty/theme.conf"
  "nvim/pack"
  "nvim/plugin"
)

# ─────────────────────────────────────────────────────────────
#  UI — gum when available, plain prompts otherwise
# ─────────────────────────────────────────────────────────────

HAS_GUM=false
command -v gum >/dev/null && HAS_GUM=true

# set by `deploy --yes`: every confirm passes, unset targets take defaults.
ASSUME_YES=false

c_accent=212; c_dim=245; c_ok=42; c_warn=214; c_err=196

ui_title() {
  if $HAS_GUM; then
    gum style --border rounded --border-foreground $c_accent \
      --padding "0 2" --margin "1 0" --bold "$*"
  else
    printf '\n\033[1;35m── %s ──\033[0m\n' "$*"
  fi
}

ui_say()  { if $HAS_GUM; then gum style --foreground $c_dim "$*"; else printf '  %s\n' "$*"; fi; }
ui_ok()   { if $HAS_GUM; then gum style --foreground $c_ok  "✓ $*"; else printf '\033[32m✓ %s\033[0m\n' "$*"; fi; }
ui_warn() { if $HAS_GUM; then gum style --foreground $c_warn "! $*"; else printf '\033[33m! %s\033[0m\n' "$*"; fi; }
ui_err()  { if $HAS_GUM; then gum style --foreground $c_err "✗ $*"; else printf '\033[31m✗ %s\033[0m\n' "$*"; fi; }

die() { ui_err "$*"; exit 1; }

ui_confirm() {
  local prompt=$1
  $ASSUME_YES && return 0
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
    gum input --prompt "$prompt " --value "$default" --width 80
  else
    local reply
    read -r -e -p "$prompt " -i "$default" reply
    printf '%s\n' "$reply"
  fi
}

ui_choose() {
  local header=$1; shift
  if $HAS_GUM; then
    gum choose --header "$header" "$@"
  else
    printf '\n%s\n' "$header" >&2
    select choice in "$@"; do
      [[ -n $choice ]] && { printf '%s\n' "$choice"; return; }
    done
  fi
}

ui_spin() {
  local message=$1; shift
  if $HAS_GUM; then
    gum spin --spinner dot --title "$message" -- "$@"
  else
    printf '  %s… ' "$message"
    "$@"
    printf 'done\n'
  fi
}

# ─────────────────────────────────────────────────────────────
#  State
# ─────────────────────────────────────────────────────────────

# hard requirements, checked lazily so --help and the menu still work on a machine that is missing them.
require() {
  local missing=()
  local tool
  for tool in "$@"; do
    command -v "$tool" >/dev/null || missing+=("$tool")
  done
  [[ ${#missing[@]} -eq 0 ]] ||
    die "missing: ${missing[*]}  —  sudo pacman -S --needed ${missing[*]}"
}

# components: <name>|<path within the config tree>|<kind>|<description> kind is "dir" for a whole tree or "file" for a single file.
readonly -a COMPONENTS=(
  "hypr|hypr|dir|Hyprland, hypridle, hyprlock and helper scripts"
  "quickshell|quickshell|dir|The Quickshell desktop shell"
  "wallust|wallust|dir|Colour generation templates"
  "zsh|zsh/zshrc|file|Shell config (deploys to ~/.zshrc)"
  "ohmyposh|ohmyposh|dir|Prompt theme (zen.toml; sourced by zshrc)"
  "nvim|nvim|dir|Neovim config (init.lua; plugins are installed by install/fxn.sh)"
  "fastfetch|fastfetch|dir|Fastfetch configs used by the zsh greeting"
  "kitty|kitty|dir|Kitty terminal (theme.conf is generated, never shipped)"
)

state_init() {
  [[ -f $STATE ]] || printf '{"targets":{},"history":[]}\n' > "$STATE"
}

state_get_target() {
  jq -r --arg k "$1" '.targets[$k] // empty' "$STATE"
}

state_set_target() {
  local tmp; tmp=$(mktemp)
  jq --arg k "$1" --arg v "$2" '.targets[$k] = $v' "$STATE" > "$tmp"
  mv "$tmp" "$STATE"
}

state_record() {
  local tmp; tmp=$(mktemp)
  jq --arg stage "$1" --arg when "$(date -Is)" --arg backup "${2:-}" \
    '.history = ([{stage: $stage, when: $when, backup: $backup}] + .history)[0:20]' \
    "$STATE" > "$tmp"
  mv "$tmp" "$STATE"
}

# ─────────────────────────────────────────────────────────────
#  Target detection
# ─────────────────────────────────────────────────────────────

# where a component lands if the user doesn't override it.
default_target() {
  local name=$1 path=$2
  case $name in
    zsh) printf '%s/.zshrc\n' "$HOME" ;;
    *)   printf '%s/%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}" "$path" ;;
  esac
}

cmd_init() {
  require jq
  state_init
  ui_title "Target paths"
  ui_say "Where each component should land on this system."
  echo

  for entry in "${COMPONENTS[@]}"; do
    IFS='|' read -r name path kind description <<< "$entry"

    local current suggested
    current=$(state_get_target "$name")
    suggested=${current:-$(default_target "$name" "$path")}

    local marker="new"
    [[ -e $suggested ]] && marker="exists"
    [[ -L $suggested ]] && marker="exists, symlink"

    if $HAS_GUM; then
      gum style --foreground $c_accent --bold "$name"
      gum style --foreground $c_dim "  $description"
      gum style --foreground $c_dim "  detected: $suggested ($marker)"
    else
      printf '\n\033[1m%s\033[0m — %s\n  detected: %s (%s)\n' \
        "$name" "$description" "$suggested" "$marker"
    fi

    local chosen
    chosen=$(ui_input "target:" "$suggested")
    [[ -n $chosen ]] || chosen=$suggested
    # Expand a leading ~ that the prompt took literally.
    chosen=${chosen/#\~/$HOME}

    state_set_target "$name" "$chosen"
    echo
  done

  ui_ok "Saved to ${STATE/#$HOME/\~}"
}

ensure_targets() {
  state_init
  local missing=false
  for entry in "${COMPONENTS[@]}"; do
    IFS='|' read -r name _ _ _ <<< "$entry"
    [[ -n $(state_get_target "$name") ]] || missing=true
  done

  if $missing && $ASSUME_YES; then
    for entry in "${COMPONENTS[@]}"; do
      IFS='|' read -r name path _ _ <<< "$entry"
      [[ -n $(state_get_target "$name") ]] ||
        state_set_target "$name" "$(default_target "$name" "$path")"
    done
    ui_ok "target paths set to the defaults"
  elif $missing; then
    ui_warn "Target paths have not been configured yet."
    cmd_init
  fi
}

# ─────────────────────────────────────────────────────────────
#  Sync
# ─────────────────────────────────────────────────────────────

# build the rsync exclude list from preserve, relative to a component.
# One line per rsync argument, nothing at all when the component has no
# preserved files.
#
# Printing an array with `printf '%s\n' "${args[@]}"` looks equivalent but
# is not: with an empty array printf still runs its format once and emits
# a bare newline, which mapfile turns into a one-element array holding "".
# rsync then receives an empty path and bails with "Empty source arg".
# Same contract as preserve_args: one line per rsync argument, and
# nothing at all when there is no match.
generated_args() {
  local component=$1
  local path
  for path in "${GENERATED[@]}"; do
    [[ $path == "$component/"* ]] || continue
    printf -- '--exclude
%s
' "${path#"$component"/}"
  done
}

preserve_args() {
  local component=$1
  local path
  for path in "${PRESERVE[@]}"; do
    [[ $path == "$component/"* ]] || continue
    printf -- '--exclude\n%s\n' "${path#"$component"/}"
  done
}

# replace the single backup for a stage: the previous one is removed
# only after the new one is complete, so there is never a window with
# no backup at all.
rotate_backup() {
  local stage=$1 source=$2
  mkdir -p "$BACKUPS"

  [[ -e $source ]] || { printf '\n'; return; }

  local stamp; stamp=$(date +%Y%m%d-%H%M%S)
  local fresh="$BACKUPS/$stage-$stamp"

  cp -a "$source" "$fresh"

  # drop every other backup for this stage.
  local old
  for old in "$BACKUPS/$stage"-*; do
    [[ -e $old ]] || continue
    [[ $old == "$fresh" ]] && continue
    rm -rf -- "$old"
  done

  printf '%s\n' "$fresh"
}

# copy a component into place. `kind` is "dir" (mirror the tree,
# deleting anything extra) or "file" (copy one file).
sync_tree() {
  local source=$1 target=$2 component=$3 kind=${4:-dir} preserve=${5:-0}

  if [[ $kind == file ]]; then
    mkdir -p "$(dirname "$target")"
    rsync -a "$source" "$target"
    return
  fi

  local -a excludes=()
  mapfile -t excludes < <(generated_args "$component")
  if [[ $preserve == 1 ]]; then
    local -a keep=()
    mapfile -t keep < <(preserve_args "$component")
    excludes+=("${keep[@]}")
  fi

  mkdir -p "$target"
  rsync -a --delete \
    "${excludes[@]}" \
    --exclude '.git' \
    --exclude '_*' \
    "$source/" "$target/"
}

# itemised list of what sync_tree would change. empty means in sync.
diff_tree() {
  local source=$1 target=$2 component=$3 kind=${4:-dir} preserve=${5:-0}

  # Nothing to compare against if the source side does not exist yet —
  # an unstaged dots/, or a component that was never added.
  [[ -e $source ]] || return 0

  if [[ $kind == file ]]; then
    [[ -e $source ]] || return
    [[ -e $target ]] || { printf 'new: %s
' "$target"; return; }
    cmp -s "$source" "$target" || printf 'changed: %s
' "$target"
    return
  fi

  [[ -d $target ]] || { printf 'new: %s
' "$target"; return; }

  local -a excludes=()
  mapfile -t excludes < <(generated_args "$component")
  if [[ $preserve == 1 ]]; then
    local -a keep=()
    mapfile -t keep < <(preserve_args "$component")
    excludes+=("${keep[@]}")
  fi

  rsync -ain --delete "${excludes[@]}" --exclude '.git' --exclude '_*' \
    "$source/" "$target/" | grep -v '^\.d\.\.t\.\.\.\.\.\.' || true
}

# ─────────────────────────────────────────────────────────────
#  Stage: playground → dots
# ─────────────────────────────────────────────────────────────

cmd_stage() {
  require jq rsync
  [[ -d $PLAYGROUND ]] || die "no playground config at $PLAYGROUND"

  ui_title "Stage — playground → dots"

  local changes
  changes=$(for entry in "${COMPONENTS[@]}"; do
    IFS='|' read -r name path kind _ <<< "$entry"
    [[ -e "$PLAYGROUND/$path" ]] || continue
    diff_tree "$PLAYGROUND/$path" "$DOTS/config/$path" "$path" "$kind" 0
  done)

  if [[ -z $changes ]]; then
    ui_ok "dots/ is already up to date"
    return
  fi

  ui_say "$(printf '%s\n' "$changes" | wc -l) path(s) will change:"
  printf '%s\n' "$changes" | head -40 | sed 's/^/    /'
  [[ $(printf '%s\n' "$changes" | wc -l) -gt 40 ]] && ui_say "    … and more (run: $0 diff stage)"
  echo

  ui_confirm "Promote the playground to dots/?" || { ui_say "cancelled"; return; }

  local backup
  backup=$(rotate_backup dots "$DOTS")
  [[ -n $backup ]] && ui_say "backup: ${backup/#$ROOT\//}"

  # Components are copied one at a time, so a failure halfway leaves
  # dots/ partially written. Report that plainly rather than exiting on
  # a bare rsync error, and point at the backup.
  local failed=""
  for entry in "${COMPONENTS[@]}"; do
    IFS='|' read -r name path kind _ <<< "$entry"
    [[ -e "$PLAYGROUND/$path" ]] || continue
    if ! sync_tree "$PLAYGROUND/$path" "$DOTS/config/$path" "$path" "$kind" 0; then
      failed=$name
      break
    fi
  done

  if [[ -n $failed ]]; then
    ui_err "failed while staging '$failed' — dots/ is partially written"
    [[ -n $backup ]] && ui_say "restore with: $0 rollback  (${backup##*/})"
    return 1
  fi

  # Carry the session tooling across so dots/ is self-contained.
  if [[ -d "$ROOT/qsplayground/session" ]]; then
    mkdir -p "$DOTS/session"
    rsync -a --delete "$ROOT/qsplayground/session/" "$DOTS/session/"
  fi

  state_record stage "$backup"
  ui_ok "staged to dots/"
}

# ─────────────────────────────────────────────────────────────
#  Deploy: dots → system
# ─────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────
#  Installing onto the live system
#
#  Hyprland reloads the moment a file it sourced changes. Writing a tree
#  in place — which is what rsync does — let it parse hyprland.conf
#  before the files hyprland.conf sources had landed. That is how a
#  rollback left the running compositor with no keybinds while every
#  file on disk was correct.
#
#  So nothing on the live system is written in place. Each replacement
#  is assembled in a hidden sibling path on the same filesystem, then
#  swapped in with one rename: RENAME_EXCHANGE for an existing
#  directory, rename-over for a file. The target is only ever entirely
#  old or entirely new.
# ─────────────────────────────────────────────────────────────

# Scratch paths from the current run, removed on exit however it ends.
declare -a CANDIDATES=()
CAND=""

cleanup_candidates() {
  local c
  for c in "${CANDIDATES[@]}"; do
    if [[ -e $c || -L $c ]]; then
      rm -rf -- "$c"
    fi
  done
  return 0
}
trap cleanup_candidates EXIT

# A symlinked target is written through to what it points at, so the
# links a dotfile manager set up survive a deploy.
resolve_target() {
  if [[ -L $1 ]]; then
    readlink -f -- "$1"
  else
    printf '%s\n' "$1"
  fi
}

# Copy machine-owned files from the live target into a candidate:
# PRESERVE files replace the shipped default, GENERATED files (never
# shipped) are simply kept.
carry_over() {
  local target=$1 cand=$2 component=$3
  local path rel
  [[ -d $target ]] || return 0
  for path in "${PRESERVE[@]}" "${GENERATED[@]}"; do
    [[ $path == "$component/"* ]] || continue
    rel=${path#"$component"/}
    [[ -e "$target/$rel" ]] || continue
    mkdir -p -- "$(dirname -- "$cand/$rel")"
    cp -a -- "$target/$rel" "$cand/$rel"
  done
  return 0
}

# build_candidate <source> <target> <component> <kind> <mode>
#
# Assembles the replacement beside the target and leaves its path in
# CAND. It is not returned through $( ): a subshell would lose the
# CANDIDATES registration and leak the scratch path on failure. Call it
# plainly, never as an `if` condition — that would switch off `set -e`
# inside it and let a failed copy produce a partial candidate.
#
#   mode  deploy — from dots/, keeping PRESERVE and GENERATED files
#                  already on the target
#         exact  — reproduce <source> byte for byte, for rollback
build_candidate() {
  local source=$1 target=$2 component=$3 kind=$4 mode=$5
  local parent leaf cand
  parent=$(dirname -- "$target")
  leaf=$(basename -- "$target")
  mkdir -p -- "$parent"

  if [[ $kind == file ]]; then
    cand=$(mktemp "$parent/.$leaf.promote.XXXXXX")
    CANDIDATES+=("$cand")
    cp -p -- "$source" "$cand"
  else
    cand=$(mktemp -d "$parent/.$leaf.promote.XXXXXX")
    CANDIDATES+=("$cand")
    if [[ $mode == exact ]]; then
      cp -a -- "$source/." "$cand/"
    else
      local -a excludes=()
      mapfile -t excludes < <(generated_args "$component")
      rsync -a "${excludes[@]}" --exclude '.git' --exclude '_*' "$source/" "$cand/"
      carry_over "$target" "$cand" "$component"
    fi
  fi

  # mktemp creates 0600 files and 0700 directories.
  chmod --reference="$source" -- "$cand"
  CAND=$cand
}

# swap_in <candidate> <target> <kind>
swap_in() {
  local cand=$1 target=$2 kind=$3

  if [[ $kind == file || ! -e $target ]]; then
    mv -fT -- "$cand" "$target"
    return 0
  fi

  if mv -T --exchange -- "$cand" "$target" 2>/dev/null; then
    rm -rf -- "$cand"              # now holds the previous tree
    return 0
  fi

  # No RENAME_EXCHANGE on this filesystem. Fall back to two renames —
  # the target is absent for a moment — and put the old tree back if
  # the second one fails. The old tree is deliberately not registered
  # for cleanup: until the swap completes it is the live config.
  local old="$cand.old"
  mv -T -- "$target" "$old"
  if ! mv -T -- "$cand" "$target"; then
    mv -T -- "$old" "$target"
    return 1
  fi
  rm -rf -- "$old"
}

# Parse a candidate hypr tree with Hyprland itself, through a throwaway
# $HOME whose .config/hypr points at it. Prints the errors and returns
# non-zero if the config does not parse.
verify_hypr_tree() {
  local dir=$1 fake out
  fake=$(mktemp -d "${TMPDIR:-/tmp}/promote-verify.XXXXXX")
  mkdir -p "$fake/.config"
  ln -s -- "$dir" "$fake/.config/hypr"
  out=$(env -i HOME="$fake" XDG_CONFIG_HOME="$fake/.config" \
          XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" \
          PATH=/usr/bin:/bin \
          timeout 60 Hyprland --verify-config -c "$fake/.config/hypr/hyprland.conf" 2>&1) || true
  rm -rf -- "$fake"
  if printf '%s' "$out" | grep -q 'config ok'; then
    return 0
  fi
  printf '%s\n' "$out" | sed -n '/Config parsing result/,$p' \
    | grep -i 'error' | sed "s|$fake/.config/hypr/||g" | sort -u | head -20
  return 1
}

# True when <dir> is the config the running compositor loaded.
is_live_hypr() {
  [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] || return 1
  command -v hyprctl >/dev/null 2>&1 || return 1
  local live="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
  [[ $(readlink -f -- "$1") == "$(readlink -f -- "$live")" ]]
}

reload_and_check() {
  local errs binds
  if ! hyprctl reload >/dev/null 2>&1; then
    ui_warn "could not reach Hyprland to reload it"
    return 0
  fi
  sleep 1
  errs=$(hyprctl configerrors 2>/dev/null) || errs=""
  binds=$(hyprctl -j binds 2>/dev/null | jq length 2>/dev/null) || binds="?"
  if [[ -z ${errs//[[:space:]]/} ]]; then
    ui_ok "Hyprland reloaded — no config errors, ${binds:-?} binds loaded"
    return 0
  fi
  ui_err "Hyprland reloaded with config errors:"
  printf '%s\n' "$errs" | head -15 | sed 's/^/    /'
  return 1
}

# Deploying changes files, not processes. exec-once only runs at login,
# so moving between the fxn shell and the previous one needs a fresh
# session; until then the old bar keeps running, and the new keybinds —
# which call into Quickshell — have nothing to talk to.
shell_handoff_note() {
  local dir=$1 wants_qs=0 legacy=0 qs=0
  if grep -rqs 'qs -c ' "$dir/hyprland.conf" "$dir/conf.d"; then wants_qs=1; fi
  if pgrep -x waybar >/dev/null 2>&1 || pgrep -x swaync >/dev/null 2>&1; then legacy=1; fi
  if pgrep -x quickshell >/dev/null 2>&1 || pgrep -x qs >/dev/null 2>&1; then qs=1; fi

  if [[ $wants_qs == 1 && $legacy == 1 ]]; then
    echo
    ui_warn "waybar and swaync from your previous session are still running"
    ui_say  "the new shell starts at login, so its keybinds do nothing until then"
    ui_say  "log out and back in to switch"
  elif [[ $wants_qs == 0 && $qs == 1 ]]; then
    echo
    ui_warn "Quickshell from the fxn session is still running"
    ui_say  "log out and back in to return to your previous shell"
  fi
  return 0
}

cmd_deploy() {
  require jq rsync
  [[ -d $DOTS/config ]] || die "dots/ is empty — run '$0 stage' first"
  ensure_targets

  ui_title "Deploy — dots → system"

  local -a planned=()
  local changes="" entry name path kind source target component_diff

  for entry in "${COMPONENTS[@]}"; do
    IFS='|' read -r name path kind _ <<< "$entry"
    source="$DOTS/config/$path"
    [[ -e $source ]] || continue
    target=$(resolve_target "$(state_get_target "$name")")

    component_diff=$(diff_tree "$source" "$target" "$path" "$kind" 1)
    if [[ -n $component_diff ]]; then
      planned+=("$name|$source|$target|$path|$kind")
      changes+=$(printf '\n  %s → %s\n' "$name" "$target")
      changes+=$(printf '%s\n' "$component_diff" | head -15 | sed 's/^/      /')
    fi
  done

  if [[ ${#planned[@]} -eq 0 ]]; then
    ui_ok "the system is already up to date"
    return 0
  fi

  printf '%s\n' "$changes"
  echo
  ui_warn "This replaces your live config. These are kept if they already exist:"
  printf '    %s\n' "${PRESERVE[@]}" "${GENERATED[@]}"
  echo

  ui_confirm "Deploy to the system?" || { ui_say "cancelled"; return 0; }

  # ── Assemble every replacement before touching anything ──
  local -a cands=()
  local hypr_cand=""
  for entry in "${planned[@]}"; do
    IFS='|' read -r name source target path kind <<< "$entry"
    build_candidate "$source" "$target" "$path" "$kind" deploy
    cands+=("$CAND")
    if [[ $name == hypr ]]; then
      hypr_cand=$CAND
      if [[ -d $CAND/bin ]]; then
        chmod +x "$CAND"/bin/*.sh 2>/dev/null || true
      fi
    fi
  done

  # ── Refuse a config Hyprland can't parse ──
  if [[ -n $hypr_cand ]]; then
    if command -v Hyprland >/dev/null 2>&1; then
      ui_say "verifying the new Hyprland config…"
      local verr=""
      if ! verr=$(verify_hypr_tree "$hypr_cand"); then
        ui_err "the new Hyprland config does not parse — nothing was changed"
        printf '%s\n' "$verr" | sed 's/^/    /'
        cleanup_candidates
        CANDIDATES=()
        return 1
      fi
      ui_ok "Hyprland config verifies"
    else
      ui_warn "Hyprland is not installed — the config was not verified"
    fi
  fi

  # ── Back up what is live now ──
  local stamp backup old
  stamp=$(date +%Y%m%d-%H%M%S)
  backup="$BACKUPS/system-$stamp"
  mkdir -p "$backup"
  for entry in "${planned[@]}"; do
    IFS='|' read -r name _ target _ kind <<< "$entry"
    [[ -e $target ]] || continue
    cp -a -- "$target" "$backup/$name"
    printf '%s\n' "$target" > "$backup/$name.target"
    printf '%s\n' "$kind"   > "$backup/$name.kind"
  done

  # Only now discard the previous system backup.
  for old in "$BACKUPS"/system-*; do
    [[ -e $old ]] || continue
    [[ $old == "$backup" ]] && continue
    rm -rf -- "$old"
  done
  ui_say "backup: ${backup/#$ROOT\//}"

  # ── Swap each replacement in ──
  local i=0 hypr_target=""
  for entry in "${planned[@]}"; do
    IFS='|' read -r name source target path kind <<< "$entry"
    swap_in "${cands[$i]}" "$target" "$kind"
    ui_ok "$name → $target"
    if [[ $name == hypr ]]; then hypr_target=$target; fi
    i=$((i + 1))
  done

  state_record deploy "$backup"

  if [[ -n $hypr_target ]] && is_live_hypr "$hypr_target"; then
    echo
    reload_and_check || ui_say "to undo: $0 rollback"
    shell_handoff_note "$hypr_target"
  fi
  return 0
}

# ─────────────────────────────────────────────────────────────
#  Status, diff, rollback
# ─────────────────────────────────────────────────────────────

cmd_status() {
  require jq rsync
  state_init
  ui_title "Status"

  local staged=0 deployed=0

  for entry in "${COMPONENTS[@]}"; do
    IFS='|' read -r name path kind _ <<< "$entry"
    local n
    n=$(diff_tree "$PLAYGROUND/$path" "$DOTS/config/$path" "$path" "$kind" 0 | wc -l)
    staged=$((staged + n))
  done

  for entry in "${COMPONENTS[@]}"; do
    IFS='|' read -r name path kind _ <<< "$entry"
    local target; target=$(state_get_target "$name")
    [[ -n $target ]] || continue
    local n
    n=$(diff_tree "$DOTS/config/$path" "$target" "$path" "$kind" 1 | wc -l)
    deployed=$((deployed + n))
  done

  if [[ ! -d $DOTS/config ]]; then
    ui_warn "playground → dots:   dots/ is empty — run '$0 stage'"
  elif [[ $staged -eq 0 ]]; then ui_ok  "playground → dots:   in sync"
  else                          ui_warn "playground → dots:   $staged path(s) differ"; fi

  if [[ ! -d $DOTS/config ]]; then
    ui_say  "dots → system:       nothing staged to compare"
  elif [[ $deployed -eq 0 ]]; then ui_ok  "dots → system:       in sync"
  else                            ui_warn "dots → system:       $deployed path(s) differ"; fi

  echo
  ui_say "Targets:"
  for entry in "${COMPONENTS[@]}"; do
    IFS='|' read -r name _ _ _ <<< "$entry"
    printf '    %-12s %s\n' "$name" "$(state_get_target "$name" || echo '(unset)')"
  done

  echo
  ui_say "Backups:"
  if compgen -G "$BACKUPS/*" >/dev/null; then
    for backup in "$BACKUPS"/*; do
      [[ -d $backup ]] || continue
      printf '    %-28s %s\n' "$(basename "$backup")" "$(du -sh "$backup" | cut -f1)"
    done
  else
    printf '    none yet\n'
  fi

  echo
  local last
  last=$(jq -r '.history[0] // empty | "\(.stage) at \(.when)"' "$STATE")
  if [[ -n $last ]]; then ui_say "Last run: $last"; fi
}

cmd_diff() {
  require jq rsync
  local stage=${1:-}
  [[ -n $stage ]] || stage=$(ui_choose "Which stage?" stage deploy)

  ui_title "Diff — $stage"

  for entry in "${COMPONENTS[@]}"; do
    IFS='|' read -r name path kind _ <<< "$entry"

    local source target
    if [[ $stage == stage ]]; then
      source="$PLAYGROUND/$path"; target="$DOTS/config/$path"
    else
      source="$DOTS/config/$path"; target=$(state_get_target "$name")
    fi
    [[ -e $source && -n $target ]] || continue

    local out
    out=$(diff_tree "$source" "$target" "$path" "$kind" \
            "$([[ $stage == stage ]] && echo 0 || echo 1)")
    [[ -n $out ]] || continue

    if $HAS_GUM; then gum style --foreground $c_accent --bold "$name"
    else printf '\n\033[1m%s\033[0m\n' "$name"; fi

    # rsync itemised output: first char is the change type.
    printf '%s\n' "$out" | sed 's/^/    /'

    if command -v diff >/dev/null && [[ -d $target ]]; then
      diff -ru --color=always \
        --exclude=.git "$target" "$source" 2>/dev/null | head -60 | sed 's/^/    /' || true
    fi
  done
}

cmd_rollback() {
  require jq rsync
  state_init
  ui_title "Rollback"

  compgen -G "$BACKUPS/*" >/dev/null || die "no backups to roll back to"

  local -a options=()
  local backup
  for backup in "$BACKUPS"/*; do
    if [[ -d $backup ]]; then
      options+=("$(basename "$backup")")
    fi
  done

  local chosen
  chosen=$(ui_choose "Restore which backup?" "${options[@]}")
  [[ -n $chosen ]] || return 0
  backup="$BACKUPS/$chosen"

  if [[ $chosen == dots-* ]]; then
    ui_warn "This replaces dots/ with $chosen"
    ui_confirm "Continue?" || return 0
    rsync -a --delete "$backup/" "$DOTS/"
    state_record rollback "$backup"
    ui_ok "dots/ restored"
    return 0
  fi

  [[ $chosen == system-* ]] || die "unrecognised backup: $chosen"
  ui_warn "This replaces your live config with $chosen"
  ui_confirm "Continue?" || return 0

  # Assemble every restoration first, then swap each into place — the
  # same atomic path deploy uses, since a rollback races Hyprland's
  # autoreload just the same.
  #
  # A component's kind comes from what is actually in the backup, not
  # from its .kind sidecar. The sidecar used to be read with
  # $(< file 2>/dev/null || echo dir), which is not bash's special
  # $(< file) form and always yields "" — so ~/.zshrc, the one file
  # component, went down the directory path and the restore died.
  local -a names=() targets=() kinds=() cands=() skipped=()
  local saved name target kind
  for saved in "$backup"/*; do
    case $saved in *.target|*.kind) continue ;; esac
    name=$(basename -- "$saved")
    if [[ ! -f "$backup/$name.target" ]]; then
      ui_warn "no target recorded for $name — skipping it"
      skipped+=("$name")
      continue
    fi
    target=$(resolve_target "$(cat -- "$backup/$name.target")")
    if [[ -d $saved ]]; then kind=dir; else kind=file; fi

    build_candidate "$saved" "$target" "$name" "$kind" exact
    names+=("$name")
    targets+=("$target")
    kinds+=("$kind")
    cands+=("$CAND")
  done

  local i
  for i in "${!names[@]}"; do
    swap_in "${cands[$i]}" "${targets[$i]}" "${kinds[$i]}"
    ui_ok "${names[$i]} → ${targets[$i]}"
  done

  state_record rollback "$backup"

  for i in "${!names[@]}"; do
    if [[ ${names[$i]} == hypr ]] && is_live_hypr "${targets[$i]}"; then
      echo
      reload_and_check || true
      shell_handoff_note "${targets[$i]}"
    fi
  done

  if [[ ${#skipped[@]} -gt 0 ]]; then
    ui_err "not restored: ${skipped[*]}"
    return 1
  fi
  return 0
}

# ─────────────────────────────────────────────────────────────
#  Menu
# ─────────────────────────────────────────────────────────────

cmd_menu() {
  while true; do
    ui_title "promote"

    local choice
    choice=$(ui_choose "What would you like to do?" \
      "status    — what differs where" \
      "stage     — playground → dots" \
      "deploy    — dots → system" \
      "diff      — inspect changes" \
      "rollback  — restore a backup" \
      "init      — reconfigure target paths" \
      "quit")

    case ${choice%% *} in
      status)   cmd_status || true ;;
      stage)    cmd_stage || true ;;
      deploy)   cmd_deploy || true ;;
      diff)     cmd_diff || true ;;
      rollback) cmd_rollback || true ;;
      init)     cmd_init || true ;;
      quit|"")  exit 0 ;;
    esac

    echo
    ui_confirm "Back to the menu?" || exit 0
  done
}

# ─────────────────────────────────────────────────────────────

case "${1:-menu}" in
  stage)    cmd_stage ;;
  deploy)   [[ ${2:-} == --yes ]] && ASSUME_YES=true; cmd_deploy ;;
  init)     cmd_init ;;
  status)   cmd_status ;;
  diff)     shift; cmd_diff "${1:-}" ;;
  rollback) cmd_rollback ;;
  menu)     cmd_menu ;;
  -h|--help)
    sed -n '2,/^set -euo/p' "$0" | sed 's/^#\ \?//;$d'
    ;;
  *) die "unknown command: $1  (try --help)" ;;
esac
