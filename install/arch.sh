#!/usr/bin/env bash
#
# fxn — bare metal → Arch → this desktop, from the live USB
#
#   install/arch.sh            the interactive installer (run as root)
#   install/arch.sh --dry-run  ask everything, print the plan, touch nothing
#
# Booted from a USB built by install/usb.sh, this is `fxn-install`. From
# the stock Arch ISO it works too:
#
#   pacman -Sy git gum && git clone <this repo> && fxn-dots/install/arch.sh
#
# What it does, in order:
#   1. asks for hostname, user, password, timezone, disk, extra groups
#   2. partitions (whole-disk) or mounts what you point it at (manual)
#   3. pacstraps base + desktop + chosen groups, writes fstab
#   4. copies this repo to ~/code/fxn-dots in the new system
#   5. arch-chroots in and runs install/arch-chroot.sh, which configures
#      the system and runs install/fxn.sh and install/desktop.sh as you
#
# UEFI only, ext4, GRUB — the same shape as the reference machine.
set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"

readonly MNT=/mnt

dry_run=false
for arg in "$@"; do
  case $arg in
    --dry-run) dry_run=true ;;
    -h|--help) sed -n '2,/^set -euo/p' "$0" | sed 's/^# \?//;$d'; exit 0 ;;
    *) die "unknown option: $arg" ;;
  esac
done

# ─── preflight ───────────────────────────────────────────────
#
# Split in two around ensure_gum: the hard requirements and the network
# check run before gum exists (plain output is unavoidable there), then
# the script restarts under gum and everything after is styled.
require_live() {
  [[ $EUID -eq 0 ]] || die "run as root from the live USB"
  [[ -d /sys/firmware/efi/efivars ]] ||
    die "not booted in UEFI mode — this installer only does UEFI + GRUB"
  command -v pacstrap >/dev/null ||
    die "pacstrap not found — this must run from the Arch live ISO"
}

require_network() {
  curl -fsS --max-time 10 -o /dev/null https://archlinux.org && return 0
  ui_err "no network"
  ui_say "wired should just work. For wifi:"
  ui_say "  iwctl station wlan0 connect <SSID>"
  exit 1
}

preflight() {
  ui_step "Preflight"
  ui_ok "root, UEFI, live ISO"
  ui_ok "online"
  $HAS_GUM || ui_warn "no gum — plain prompts"
  timedatectl set-ntp true 2>/dev/null || true
}

# ─── questions ───────────────────────────────────────────────
ask_identity() {
  ui_step "Who"
  HOSTNAME_=$(ui_input "hostname:" "fxn")
  [[ $HOSTNAME_ =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}$ ]] || die "invalid hostname: $HOSTNAME_"

  USERNAME_=$(ui_input "username:" "")
  [[ $USERNAME_ =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] ||
    die "invalid username: '$USERNAME_' (lowercase, start with a letter)"

  local p1 p2
  while true; do
    p1=$(ui_password "password for $USERNAME_:")
    p2=$(ui_password "again:")
    [[ -n $p1 && $p1 == "$p2" ]] && break
    ui_warn "passwords were empty or did not match — try again"
  done
  PASSWORD_=$p1

  if ui_confirm "Use the same password for root?"; then
    ROOT_PASSWORD_=$PASSWORD_
  else
    while true; do
      p1=$(ui_password "root password:")
      p2=$(ui_password "again:")
      [[ -n $p1 && $p1 == "$p2" ]] && break
      ui_warn "passwords were empty or did not match — try again"
    done
    ROOT_PASSWORD_=$p1
  fi
}

ask_locale() {
  ui_step "Where"
  local tz_guess
  tz_guess=$(curl -fsS --max-time 5 https://ipapi.co/timezone 2>/dev/null || true)
  if [[ -n $tz_guess && -f /usr/share/zoneinfo/$tz_guess ]] &&
     ui_confirm "Timezone $tz_guess?"; then
    TIMEZONE_=$tz_guess
  else
    TIMEZONE_=$(timedatectl list-timezones | ui_filter "timezone")
  fi
  [[ -f /usr/share/zoneinfo/$TIMEZONE_ ]] || die "unknown timezone: $TIMEZONE_"

  LOCALE_=$(ui_input "locale:" "en_US.UTF-8")
  grep -q "^#\?${LOCALE_//./\\.} " /etc/locale.gen || die "unknown locale: $LOCALE_"
  KEYMAP_=$(ui_input "console keymap:" "us")
}

# The disk the live system booted from. Listing it as a target is how
# people wipe their installer mid-install.
boot_disk() {
  local src
  src=$(findmnt -no SOURCE /run/archiso/bootmnt 2>/dev/null || true)
  if [[ -n $src ]]; then lsblk -no PKNAME "$src" 2>/dev/null | head -1; fi
}

ask_disk() {
  ui_step "Disk"
  local skip; skip=$(boot_disk || true)
  local -a disks=()
  local name size model
  while read -r name size model; do
    [[ $name == "$skip" ]] && continue
    disks+=("/dev/$name  $size  ${model:-?}")
  done < <(lsblk -dno NAME,SIZE,MODEL -e 7,11)
  [[ ${#disks[@]} -gt 0 ]] || die "no installable disks found"

  MODE_=$(ui_choose "How should the disk be set up?" \
    "wipe     — erase one whole disk: 1G EFI + ext4 root" \
    "manual   — I already partitioned (dual boot, custom layout)")
  MODE_=${MODE_%% *}

  if [[ $MODE_ == wipe ]]; then
    local pick
    pick=$(ui_choose "Disk to ERASE" "${disks[@]}")
    DISK_=${pick%% *}
    # Partition names: nvme0n1 → nvme0n1p1, sda → sda1.
    local sep=""; [[ $DISK_ =~ [0-9]$ ]] && sep=p
    ESP_=${DISK_}${sep}1
    ROOT_=${DISK_}${sep}2
    FORMAT_ESP_=true
  else
    # One lsblk per field: in a multi-column listing an empty FSTYPE or
    # LABEL collapses and shifts every column after it.
    local -a parts=()
    local dev
    while read -r dev; do
      parts+=("$dev  $(lsblk -dno SIZE "$dev")  $(lsblk -dno FSTYPE "$dev" | sed 's/^$/-/')  $(lsblk -dno LABEL "$dev")")
    done < <(lsblk -lnpo NAME,TYPE -e 7,11 | awk '$2=="part"{print $1}')
    [[ ${#parts[@]} -gt 0 ]] || die "no partitions found — use wipe, or partition with cfdisk first"

    ui_say "Partition first with cfdisk if you haven't: an EFI partition (vfat) and a root."
    local pick
    pick=$(ui_choose "EFI system partition (mounted at /boot)" "${parts[@]}"); ESP_=${pick%% *}
    pick=$(ui_choose "Root partition — will be FORMATTED ext4" "${parts[@]}"); ROOT_=${pick%% *}
    [[ $ESP_ != "$ROOT_" ]] || die "EFI and root must be different partitions"
    DISK_=/dev/$(lsblk -no PKNAME "$ROOT_" | head -1)

    # An existing ESP (Windows) holds other bootloaders. Formatting it is
    # opt-in, and the default answer is no.
    FORMAT_ESP_=false
    if [[ $(lsblk -no FSTYPE "$ESP_") == vfat ]]; then
      if ui_confirm "Format the EFI partition too? (No keeps Windows/other loaders)"; then
        FORMAT_ESP_=true
      fi
    else
      FORMAT_ESP_=true
      ui_warn "$ESP_ is not vfat — it will be formatted FAT32"
    fi
  fi
}

detect_hardware() {
  CPU_UCODE_=""
  case $(grep -m1 vendor_id /proc/cpuinfo | awk '{print $3}') in
    GenuineIntel) CPU_UCODE_=intel-ucode ;;
    AuthenticAMD) CPU_UCODE_=amd-ucode ;;
  esac
  # sysfs rather than lspci: the stock ISO does not ship pciutils.
  # Vendor 0x10de is NVIDIA; class 0x03xxxx is a display controller.
  HAS_NVIDIA_=false
  local dev
  # `if`, not `[[ ]] && …`: as the loop's last command a false test
  # becomes the function's status, and set -e ends the run silently.
  for dev in /sys/bus/pci/devices/*; do
    if [[ $(<"$dev/vendor") == 0x10de && $(<"$dev/class") == 0x03* ]]; then
      HAS_NVIDIA_=true
    fi
  done
}

ask_groups() {
  ui_step "Software"
  ui_say "Always installed: base, the Hyprland desktop, zsh + neovim (install/fxn.sh)."
  local preselect="apps,dev"
  $HAS_NVIDIA_ && preselect+=",nvidia"
  mapfile -t GROUPS_ < <(ui_choose_many "Extra groups (space to toggle, enter to accept)" \
    "$preselect" "${OPTIONAL_GROUPS[@]}")
  if $HAS_NVIDIA_ && [[ " ${GROUPS_[*]} " != *" nvidia "* ]]; then
    ui_warn "NVIDIA GPU detected but the nvidia group is off — you will get nouveau"
  fi
}

summary() {
  ui_step "Plan"
  local layout
  if [[ $MODE_ == wipe ]]; then
    layout="ERASE $DISK_ → $ESP_ (1G EFI) + $ROOT_ (ext4)"
  else
    layout="format $ROOT_ ext4; $ESP_ → /boot ($($FORMAT_ESP_ && echo FORMAT || echo keep))"
  fi
  local text
  text=$(cat <<EOF
host      $HOSTNAME_
user      $USERNAME_  (wheel, zsh)
timezone  $TIMEZONE_
locale    $LOCALE_  keymap $KEYMAP_
disk      $layout
cpu       ${CPU_UCODE_:-no microcode}
groups    base desktop ${GROUPS_[*]}
EOF
)
  if $HAS_GUM; then
    gum style --border rounded --border-foreground $c_warn --padding "0 2" "$text"
  else
    printf '%s\n' "$text" | sed 's/^/    /'
  fi
}

confirm_destruction() {
  $dry_run && { ui_ok "dry run — nothing was changed"; exit 0; }
  if [[ $MODE_ == wipe ]]; then
    ui_warn "Everything on $DISK_ will be destroyed."
    local typed
    typed=$(ui_input "type the disk name ($(basename "$DISK_")) to continue:" "")
    [[ $typed == "$(basename "$DISK_")" ]] || die "cancelled"
  else
    ui_confirm "Format $ROOT_ and install?" || die "cancelled"
  fi
}

# ─── doing it ────────────────────────────────────────────────
partition() {
  ui_step "Disk"
  umount -R "$MNT" 2>/dev/null || true

  if [[ $MODE_ == wipe ]]; then
    ui_run "wiping $DISK_" wipefs -af "$DISK_"
    sgdisk -Z "$DISK_" >/dev/null
    sgdisk -n1:0:+1G -t1:ef00 -c1:EFI \
           -n2:0:0   -t2:8304 -c2:root "$DISK_" >/dev/null
    partprobe "$DISK_" 2>/dev/null || true
    udevadm settle
  fi
  [[ -b $ESP_ && -b $ROOT_ ]] || die "partitions $ESP_ / $ROOT_ did not appear"

  ui_run "formatting $ROOT_ ext4" mkfs.ext4 -F -q "$ROOT_"
  if $FORMAT_ESP_; then
    ui_run "formatting $ESP_ FAT32" mkfs.fat -F 32 -n EFI "$ESP_"
  fi

  mount "$ROOT_" "$MNT"
  mount --mkdir "$ESP_" "$MNT/boot"
  ui_ok "mounted at $MNT"
}

install_base() {
  ui_step "pacstrap"
  local -a pkgs
  mapfile -t pkgs < <(
    pkgs_of base.txt desktop.txt
    for g in "${GROUPS_[@]}"; do pkgs_of "$g.txt"; done
    [[ -n $CPU_UCODE_ ]] && echo "$CPU_UCODE_"
  )
  # Dedupe: groups overlap (python is in desktop and dev).
  mapfile -t pkgs < <(printf '%s\n' "${pkgs[@]}" | sort -u)

  # Several minutes behind a spinner, so say where to watch it.
  ui_say "the long part. To watch: Alt+F2, log in as root, tail -f $FXN_LOG"
  ui_run "pacstrap — ${#pkgs[@]} packages" pacstrap -K "$MNT" "${pkgs[@]}"
  genfstab -U "$MNT" >> "$MNT/etc/fstab"
}

copy_repo() {
  ui_step "Repo"
  local dest="$MNT/root/fxn-dots"
  # Machine-local state stays behind: backups and promote targets belong
  # to the machine that made them.
  rsync -a \
    --exclude .backups --exclude promote.json \
    --exclude qsplayground/.sandbox --exclude install/out \
    "$REPO_DIR/" "$dest/"
  ui_ok "repo copied (moves to ~$USERNAME_/code/fxn-dots in the chroot)"
}

run_chroot() {
  ui_step "Configure"
  # Handed over in a root-only file rather than argv, so passwords never
  # show up in a process listing.
  local env="$MNT/root/fxn-install.env"
  install -m 600 /dev/null "$env"
  {
    printf 'HOSTNAME_=%q\n'      "$HOSTNAME_"
    printf 'USERNAME_=%q\n'      "$USERNAME_"
    printf 'PASSWORD_=%q\n'      "$PASSWORD_"
    printf 'ROOT_PASSWORD_=%q\n' "$ROOT_PASSWORD_"
    printf 'TIMEZONE_=%q\n'      "$TIMEZONE_"
    printf 'LOCALE_=%q\n'        "$LOCALE_"
    printf 'KEYMAP_=%q\n'        "$KEYMAP_"
    printf 'MODE_=%q\n'          "$MODE_"
    printf 'GROUPS_CSV_=%q\n'    "$(IFS=,; echo "${GROUPS_[*]}")"
  } > "$env"

  arch-chroot "$MNT" bash /root/fxn-dots/install/arch-chroot.sh
  rm -f "$env"
}

finish() {
  # Keep the live half of the log; the ISO's copy dies with the reboot.
  install -Dm600 "$FXN_LOG" "$MNT/var/log/fxn-install-live.log"

  ui_step "Done"
  ui_ok "installed. Remove the USB and reboot."
  ui_say "Log in through sddm, pick Hyprland. Then:"
  ui_say "  · write your monitors into ~/.config/hypr/conf.d/10-monitors.conf"
  ui_say "  · :Copilot setup in nvim, once"
  if ui_confirm "Reboot now?"; then
    umount -R "$MNT"
    reboot
  fi
  ui_say "the new system is still mounted at $MNT — umount -R $MNT before rebooting"
}

main() {
  require_live
  require_network
  ensure_gum "$@"
  ui_title "fxn — arch installer"
  preflight
  detect_hardware
  ask_identity
  ask_locale
  ask_disk
  ask_groups
  summary
  confirm_destruction
  partition
  install_base
  copy_repo
  run_chroot
  finish
}

main "$@"
