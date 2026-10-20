#!/usr/bin/env bash
#
# fxn — build an Arch live ISO with this repo and gum baked in
#
#   install/usb.sh                       build install/out/fxn-arch-<date>.iso
#   install/usb.sh --write /dev/sdX      build, then write it to a USB stick
#   install/usb.sh --write /dev/sdX --iso <file>   write an existing ISO
#
# The ISO is the official releng profile (the stock Arch ISO) plus:
#   · gum, git and pciutils
#   · this repo, at the commit you build from, as /root/fxn-dots.tar
#   · fxn-install — unpacks the repo and runs install/bootstrap.sh, which
#     fast-forwards it to GitHub when online and starts install/arch.sh
#
# Boot it, connect to the network, run `fxn-install`. Because the repo
# updates itself at install time, rebuild only for a newer Arch ISO base.
#
# Needs archiso and sudo; mkarchiso must run as root.
set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"

readonly OUT="$INSTALL_DIR/out"
readonly RELENG=/usr/share/archiso/configs/releng
readonly -a EXTRA_PKGS=(gum git pciutils)
readonly -a ARGS=("$@")

write_dev=""
iso=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --write) write_dev=${2:?--write needs a device}; shift ;;
    --iso)   iso=${2:?--iso needs a file}; shift ;;
    -h|--help) sed -n '2,/^set -euo/p' "$0" | sed 's/^# \?//;$d'; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

# ─── build ───────────────────────────────────────────────────
build() {
  ui_step "Build"
  [[ $EUID -ne 0 ]] || die "run as your normal user; it sudos for mkarchiso"
  if [[ ! -d $RELENG ]]; then
    ui_confirm "archiso is not installed. Install it?" || die "cancelled"
    sudo_keepalive
    ui_run "installing archiso" sudo pacman -S --needed --noconfirm archiso
  fi

  if [[ -n $(git -C "$REPO_DIR" status --porcelain 2>/dev/null) ]]; then
    ui_warn "the repo has uncommitted changes — they go on the ISO as they are"
  fi

  local tmp; tmp=$(mktemp -d "${TMPDIR:-/tmp}/fxn-iso.XXXXXX")
  local profile="$tmp/profile"
  cp -r "$RELENG" "$profile"

  # packages
  local p
  for p in "${EXTRA_PKGS[@]}"; do
    grep -qx "$p" "$profile/packages.x86_64" || echo "$p" >> "$profile/packages.x86_64"
  done

  # The repo, as a tarball. mkarchiso copies airootfs with
  # --no-preserve=mode, which would strip every exec bit and leave git
  # reporting a mode change on every script in the installed copy.
  tar -C "$(dirname "$REPO_DIR")" -cf "$profile/airootfs/root/fxn-dots.tar" \
    --exclude="$(basename "$REPO_DIR")/.backups" \
    --exclude="$(basename "$REPO_DIR")/promote.json" \
    --exclude="$(basename "$REPO_DIR")/qsplayground/.sandbox" \
    --exclude="$(basename "$REPO_DIR")/install/out" \
    --transform="s|^$(basename "$REPO_DIR")|fxn-dots|" \
    "$(basename "$REPO_DIR")"

  mkdir -p "$profile/airootfs/usr/local/bin"
  cat > "$profile/airootfs/usr/local/bin/fxn-install" <<'EOF'
#!/usr/bin/env bash
# Unpack the fxn repo baked into this ISO and start the installer.
set -euo pipefail
[[ -d /root/fxn-dots ]] || tar -C /root -xf /root/fxn-dots.tar
exec bash /root/fxn-dots/install/bootstrap.sh "$@"
EOF

  cat >> "$profile/airootfs/etc/motd" <<'EOF'

fxn — connect to the network (iwctl for wifi), then run: fxn-install

EOF

  sed -i 's/^iso_name=.*/iso_name="fxn-arch"/' "$profile/profiledef.sh"
  printf '%s\n' 'file_permissions+=(["/usr/local/bin/fxn-install"]="0:0:755")' \
    >> "$profile/profiledef.sh"

  mkdir -p "$OUT"
  sudo_keepalive
  ui_say "several minutes, and a few GB in $tmp — tail -f $FXN_LOG to watch"
  ui_run "mkarchiso" sudo mkarchiso -v -w "$tmp/work" -o "$OUT" "$profile"
  sudo rm -rf -- "$tmp"

  iso=$(ls -t "$OUT"/fxn-arch-*.iso | head -1)
  sudo chown "$(id -u):$(id -g)" "$iso"
  ui_ok "$iso"
}

# ─── write ───────────────────────────────────────────────────
write_usb() {
  ui_step "Write"
  [[ -f $iso ]] || die "no ISO at $iso"
  [[ -b $write_dev ]] || die "$write_dev is not a block device"
  [[ $(lsblk -dno TYPE "$write_dev") == disk ]] ||
    die "$write_dev is a partition — give the whole device (/dev/sdX, not /dev/sdX1)"

  # A system disk is never removable and is almost always mounted; refuse
  # both, so a typo in --write cannot reach the disk you are running on.
  [[ $(lsblk -dno RM "$write_dev" | tr -d ' ') == 1 ]] ||
    die "$write_dev is not a removable device — refusing"
  lsblk -o NAME,SIZE,MODEL,TRAN,FSTYPE,LABEL,MOUNTPOINTS "$write_dev"
  ui_warn "Everything on $write_dev will be destroyed."
  local typed
  typed=$(ui_input "type the device name ($(basename "$write_dev")) to continue:" "")
  [[ $typed == "$(basename "$write_dev")" ]] || die "cancelled"

  # Desktops auto-mount a stick the moment it is plugged in. Unmount only
  # after the typed confirmation, and only this device's partitions.
  local part mp
  while read -r part mp; do
    [[ -n $mp ]] || continue
    sudo umount "$part" || die "could not unmount $part ($mp)"
    ui_ok "unmounted $part"
  done < <(lsblk -lnpo NAME,MOUNTPOINT "$write_dev")

  sudo dd if="$iso" of="$write_dev" bs=4M status=progress oflag=sync conv=fsync
  sync
  ui_ok "written — boot it in UEFI mode and run fxn-install"
}

ensure_gum "${ARGS[@]}"
ui_title "fxn — usb"
if [[ -z $iso ]]; then build; fi
if [[ -n $write_dev ]]; then write_usb; else
  ui_say "write it with: install/usb.sh --write /dev/sdX --iso $iso"
fi
