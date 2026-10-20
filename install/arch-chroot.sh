#!/usr/bin/env bash
#
# The second half of install/arch.sh. Runs inside `arch-chroot /mnt`,
# reads its answers from /root/fxn-install.env, and is not meant to be
# run by hand.
#
#   system   timezone, locale, hostname, users, sudo, initramfs, GRUB
#   user     install/fxn.sh and install/desktop.sh, run as the new user,
#            so the result is exactly what running them later would give
set -euo pipefail

readonly ENV_FILE=/root/fxn-install.env
[[ -f $ENV_FILE ]] || { echo "no $ENV_FILE — run install/arch.sh instead" >&2; exit 1; }
# shellcheck source=/dev/null
source "$ENV_FILE"

source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"

IFS=, read -r -a GROUPS_ <<< "$GROUPS_CSV_"
has_group() { [[ " ${GROUPS_[*]} " == *" $1 "* ]]; }

readonly HOME_=/home/$USERNAME_
readonly REPO_DEST=$HOME_/code/fxn-dots
# Lets the user stage run pacman and makepkg -si unattended. Removed on
# every exit path — a leftover NOPASSWD rule is the one thing this
# script must not leave behind.
readonly SUDO_TMP=/etc/sudoers.d/99-fxn-install

cleanup() {
  rm -f "$SUDO_TMP" "$ENV_FILE"
}
trap cleanup EXIT

# ─── system ──────────────────────────────────────────────────
base_config() {
  ui_step "System"
  ln -sf "/usr/share/zoneinfo/$TIMEZONE_" /etc/localtime
  hwclock --systohc

  sed -i "s/^#\(${LOCALE_//./\\.} \)/\1/" /etc/locale.gen
  ui_run "locale-gen" locale-gen
  printf 'LANG=%s\n' "$LOCALE_" > /etc/locale.conf
  printf 'KEYMAP=%s\n' "$KEYMAP_" > /etc/vconsole.conf

  printf '%s\n' "$HOSTNAME_" > /etc/hostname
  cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME_.localdomain $HOSTNAME_
EOF
  ui_ok "$HOSTNAME_ · $TIMEZONE_ · $LOCALE_"
}

users() {
  ui_step "Users"
  printf 'root:%s\n' "$ROOT_PASSWORD_" | chpasswd

  if ! id "$USERNAME_" >/dev/null 2>&1; then
    useradd -m -G wheel,input -s /usr/bin/zsh "$USERNAME_"
  fi
  printf '%s:%s\n' "$USERNAME_" "$PASSWORD_" | chpasswd

  printf '%%wheel ALL=(ALL:ALL) ALL\n' > /etc/sudoers.d/10-wheel
  chmod 440 /etc/sudoers.d/10-wheel
  visudo -cf /etc/sudoers.d/10-wheel >/dev/null || die "sudoers drop-in is invalid"
  ui_ok "$USERNAME_ (wheel, input, zsh)"
}

# nouveau and the proprietary driver both want the GPU; the kms hook
# pulls nouveau into the initramfs, so it goes, and the nvidia modules
# load early instead. Matches the reference machine's cmdline.
nvidia() {
  has_group nvidia || return 0
  ui_step "NVIDIA"
  sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/; s/^MODULES=( /MODULES=(/' \
    /etc/mkinitcpio.conf
  sed -i '/^HOOKS=/s/ kms//' /etc/mkinitcpio.conf
  sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia_drm.modeset=1 nvidia_drm.fbdev=1"/' \
    /etc/default/grub
  ui_ok "early KMS, kms hook dropped"
}

bootloader() {
  ui_step "Initramfs + GRUB"
  ui_run "initramfs" mkinitcpio -P

  # Some boards refuse NVRAM writes. On a wiped disk the fallback path
  # below boots anyway; on a shared ESP it is the only way in, so fail.
  if ! ui_run "GRUB → EFI boot entry" grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB; then
    [[ $MODE_ == wipe ]] || die "grub-install could not write a boot entry"
    ui_warn "no NVRAM boot entry — relying on the fallback path"
  fi
  if [[ $MODE_ == wipe ]]; then
    # Some firmware forgets NVRAM boot entries; the fallback path always
    # boots. Only on a disk we own outright — on a shared ESP that path
    # may already belong to Windows.
    ui_run "GRUB → fallback path" grub-install --target=x86_64-efi --efi-directory=/boot --removable
  else
    # Dual boot: let GRUB find the other OSes on the next mkconfig.
    sed -i 's/^#\?GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
    grep -q '^GRUB_DISABLE_OS_PROBER=' /etc/default/grub ||
      echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub
  fi
  ui_run "grub.cfg" grub-mkconfig -o /boot/grub/grub.cfg || die "grub-mkconfig failed"
  # The kernels and any other OS os-prober found.
  tail -n 30 "$FXN_LOG" | grep -i '^found' | sed 's/^/    /' || true
  systemctl enable systemd-timesyncd.service >/dev/null 2>&1
}

# ─── user ────────────────────────────────────────────────────
place_repo() {
  mkdir -p "$(dirname "$REPO_DEST")"
  rm -rf "$REPO_DEST"
  mv /root/fxn-dots "$REPO_DEST"
  chown -R "$USERNAME_:$USERNAME_" "$HOME_/code"
}

# Run a repo script as the new user, with a clean login-like env. Hyprland
# --verify-config (inside the deploy) wants a runtime dir, which nothing
# creates in a chroot.
as_user() {
  local uid; uid=$(id -u "$USERNAME_")
  install -d -m 700 -o "$USERNAME_" -g "$USERNAME_" "/run/user/$uid"
  runuser -u "$USERNAME_" -- env -i \
    HOME="$HOME_" USER="$USERNAME_" LOGNAME="$USERNAME_" SHELL=/usr/bin/zsh \
    PATH=/usr/local/bin:/usr/bin:/bin TERM="${TERM:-linux}" LANG="$LOCALE_" \
    XDG_RUNTIME_DIR="/run/user/$uid" \
    bash -c 'cd "$1" && shift && exec bash "$@"' _ "$REPO_DEST" "$@"
}

user_stage() {
  ui_step "Dots"
  install -m 440 /dev/null "$SUDO_TMP"
  printf '%s ALL=(ALL:ALL) NOPASSWD: ALL\n' "$USERNAME_" > "$SUDO_TMP"

  # Each half failing is survivable — the system boots either way, and
  # both scripts are idempotent, so the fix is to re-run the one that
  # failed after first login.
  as_user install/fxn.sh --no-chsh ||
    ui_warn "install/fxn.sh failed — re-run it after first login"

  local -a with=()
  [[ ${#GROUPS_[@]} -gt 0 ]] && with=(--with "$GROUPS_CSV_")
  as_user install/desktop.sh --yes "${with[@]}" ||
    ui_warn "install/desktop.sh failed — re-run it after first login"
}

base_config
users
nvidia
bootloader
place_repo
user_stage
ui_ok "chroot stage finished"
