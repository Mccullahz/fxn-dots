# fxn (affection) dotfiles

A Hyprland config built with [Quickshell](https://quickshell.org).

```
qsplayground/  edit, test, break things
dots/          the promoted, known-good copy
promote.sh     moves changes between playground and official dots, and onto the system
install/       installers: bare metal → Arch → this desktop
```

## install

```
install/
  usb.sh          build an Arch live ISO with this repo + gum baked in
  bootstrap.sh    on any live ISO: git + gum, fetch/update the repo, run arch.sh
  arch.sh         from the live USB: disk → pacstrap → chroot → dots
  arch-chroot.sh  arch.sh's second half, run inside the new system
  fxn.sh          zsh + neovim
  desktop.sh      Hyprland + Quickshell desktop, services, deploy
  lib.sh          shared gum / plain-prompt UI
  packages/       package lists by group
```

### a new machine, from a USB stick

Two ways onto install media. Both end in the same `install/bootstrap.sh`
→ `install/arch.sh`, and both need the network (pacstrap downloads every
package either way).

**Recommended — the fxn ISO.** Build once, keep the stick:

```sh
install/usb.sh                     # → install/out/fxn-arch-<date>.iso
install/usb.sh --write /dev/sdX --iso install/out/fxn-arch-<date>.iso
```

It is the stock Arch `releng` profile plus gum, git, pciutils and this repo,
with a login banner telling you what to run. At install time the baked repo
is fast-forwarded to GitHub when it can be, so the stick does not go stale
with every commit — rebuild only when you want a newer Arch base. The ISO
also works from a Ventoy stick: copy the file over.

**No build — any Arch ISO.** Boot the stock image (or Ventoy), get online, then:

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/mccullahz/fxn-dots/main/install/bootstrap.sh)
```

This installs git and gum, clones `main`, and starts the installer.

Either way: boot **in UEFI mode**, get online (wired just works; wifi is
`iwctl station wlan0 connect <SSID>`), then on the fxn ISO:

```sh
fxn-install              # or: fxn-install --dry-run   ·   --baked: skip the GitHub update
```

The whole run is in gum. Any script that starts without it installs gum and
restarts itself, so even the first prompt is styled. Long steps (pacstrap,
pacman, AUR builds, plugin syncs) run behind a spinner, with their output in
`~/.cache/fxn/install.log`. On failure the last lines are printed, and on the
live ISO you can `tail -f` the log from Alt+F2. The installed system keeps
both halves: `/var/log/fxn-install-live.log`, and the user stage's log in
`~/.cache/fxn/install.log`.

It asks for hostname, user, password, timezone, disk and extra groups, shows
the plan, and only then touches the disk. Two disk modes:

| mode | layout |
|---|---|
| `wipe`   | erases one disk: 1G EFI at `/boot` + ext4 root. The USB you booted from is never offered |
| `manual` | you partition first (`cfdisk`); pick an ESP and a root. Root is formatted, the ESP only if you say so — keep it for dual boot, and os-prober finds Windows |

Then it pacstraps base + desktop + your groups (+ CPU microcode), sets up
locale, users, sudo, GRUB (and NVIDIA early KMS when that group is on),
copies the repo to `~/code/fxn-dots`, and runs `install/fxn.sh` and
`install/desktop.sh` **as the new user** — so the result is the same as
running them by hand later. Reboot into the fxn login screen: greetd runs
`quickshell/fxn-greeter`, a copy of the hyprlock screen in the current
theme and wallpaper.

### an existing Arch install

```sh
install/fxn.sh                         # zsh + neovim
install/desktop.sh --with apps,dev     # desktop + optional groups, then deploys dots
```

Both take `--list` to show the plan and change nothing, and `--no-aur`.
Both are idempotent: `--needed` skips what is installed, `fxn.sh` copies any
config it would overwrite to `~/.fxn-install-backup-<timestamp>/`, and
`desktop.sh` deploys through `promote.sh`, which keeps its own backup.

`fxn.sh` covers oh-my-zsh and its plugins, oh-my-posh, packer, copilot.vim,
the LSP servers, and `~/.zshrc`, `ohmyposh/`, `fastfetch/`, `nvim/init.lua`
(`--no-chsh` leaves the login shell alone).

### package groups

| group | file | |
|---|---|---|
| base    | `packages/base.txt`    | pacstrapped by `arch.sh` only |
| desktop | `packages/desktop.txt`, `desktop.aur` | always — it is what the dots configure |
| apps    | `packages/apps.txt`    | browsers, media, monitors |
| dev     | `packages/dev.txt`     | go, python, node, docker (and the docker group) |
| nvidia  | `packages/nvidia.txt`  | `nvidia-open`; preselected when an NVIDIA GPU is found |
| extras  | `packages/extras.txt`  | discord, blender, ufw |

One name per line, `#` comments. Every installer resolves the names against
the repos before installing anything, so a stale name stops the run up front.

### testing the installer

Don't test `wipe` on hardware first. A QEMU VM with UEFI firmware works:

```sh
sudo pacman -S --needed qemu-desktop edk2-ovmf
qemu-img create -f qcow2 vm.qcow2 40G
cp /usr/share/edk2/x64/OVMF_VARS.4m.fd vm-vars.fd   # writable: GRUB adds a boot entry
qemu-system-x86_64 -enable-kvm -m 8G -smp 4 -cpu host \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.4m.fd \
  -drive if=pflash,format=raw,file=vm-vars.fd \
  -cdrom install/out/fxn-arch-*.iso -drive file=vm.qcow2,if=virtio
```

## pipeline

```
  qsplayground/  ──stage──▶  dots/  ──deploy──▶  ~/.config
     (testing)               (prod)              (live)
```

`./promote.sh`

| command | what it does |
|---|---|
| `./promote.sh status`   | what differs at each stage |
| `./promote.sh stage`    | playground → `dots/`, replacing the single backup |
| `./promote.sh deploy`   | `dots/` → live config, replacing the single backup |
| `./promote.sh diff`     | show the actual changes before committing to them |
| `./promote.sh rollback` | restore either backup |
| `./promote.sh init`     | re-run the target-path wizard |

Target paths are detected on first run, confirmed by you, and remembered in `promote.json`. Backups live in `.backups/` - one per stage, replaced on every run, and the old one is only deleted once the new one is complete.

Before anything is swapped, deploy parses the new Hyprland config with `Hyprland --verify-config` and stops if it has errors. Afterwards, when the target is the config your running compositor loaded, it reloads Hyprland and reports any config errors.

We are avoiding touching:
```
hypr/conf.d/99-local.lua         your own overrides
hypr/conf.d/10-monitors.lua      machine's displays
hypr/theme/colors.conf           written by wallust or fxn-theme
hypr/theme/roles.conf            written by fxn-theme
quickshell/fxn/theme.json        written by fxn-theme
```

**Generated**, never staged, never deployed, in either direction. `settings.json` absorbs whatever `$HOME` produced it, so a QA sandbox run would otherwise bake the sandbox's wallpaper paths into the repo. The shell recreates it from the defaults in `Settings.qml` on first run.

```
quickshell/fxn/settings.json     your shell settings
```

## Testing

```sh
./qsplayground/session/check.sh    # validate without touching your session
./qsplayground/session/launch.sh   # nested Hyprland running the playground
./qsplayground/session/launch.sh --shell   # just the shell, no compositor
```

`check.sh` verifies the Hyprland config, the hypridle config, and compiles every QML module. It draws nothing on screen.

`launch.sh` runs a full nested session against a sandbox `$HOME` whose `.config` symlinks back to `qsplayground/config` so the exact same files run in both the sandbox and the real session. Known limits of nesting: the tray is empty and notifications go to the host shell, because those D-Bus names are already taken by the outer session.

## shell

`qsplayground/config/quickshell/fxn/`
```
shell.qml     entry point
Ipc.qml       IPC surface for keybinds  (qs -c fxn ipc show)
Config/       palette, settings, paths, UI state
Services/     data sources — audio, network, notifications, mpris, …
Widgets/      reusable primitives
Modules/      the surfaces themselves
```

Surfaces: edge, notification popups, OSD, control center, launcher, power menu, workspace overview, keybind cheat sheet.

## Settings

`quickshell/fxn/settings.json` is watched: edit it and the running shell updates. Shell style, edge geometry and timing, workspace style, fonts, panel opacity, clock format, wallpaper directories, notification placement and timeouts all live there. The control centre's gear icon opens it in `$EDITOR`.

## Themes and wallpapers

Five themes: **Auto**, **Rosé Pine**, **Catppuccin Mocha**, **Nord** and **Gruvbox**. Pick one from the tabs in the wallpaper picker (`SUPER W`) and the palette, window borders, lock screen, terminal colors and wallpaper all change together, live.

Auto takes its colors from whatever wallpaper you choose, via wallust. The four named themes keep their own hand-tuned palette whatever the wallpaper is.

## Requirements

```sh
sudo pacman -S --needed quickshell gum awww rsync jq \
                        hypridle hyprlock cliphist wl-clipboard \
                        brightnessctl grim slurp swappy upower \
                        python imagemagick curl
```

`qalc` (from `libqalculate`) is optional

These are all in `install/packages/desktop.txt`; `install/desktop.sh` installs
them. The zsh and neovim packages are handled by `install/fxn.sh` — run
`install/fxn.sh --list` to see that list.

### what PRESERVE and GENERATED actually do

Both lists live at the top of `promote.sh`. The semantics are narrower than
"never touched", so it is worth being precise:

| | `stage` (playground → dots) | `deploy` (dots → system) |
|---|---|---|
| **PRESERVE** | **synced normally** — `cmd_stage` passes `preserve=0` | the **live** file wins if it exists; otherwise `dots/` seeds it |
| **GENERATED** | excluded both ways | carried back out of the live target, never deleted |

So a PRESERVE file is not fenced off from the repo at all. It is only
protected from being *overwritten* on a machine that already has one — which
is what makes `dots/` the seed for a fresh install, and why the copy in
`dots/` still has to be correct.

`PRESERVE` holds `hypr/conf.d/10-monitors.lua` (per-machine displays) and the
files wallust rewrites on every theme change: `hypr/theme/colors.conf`,
`hypr/theme/roles.conf`, `quickshell/fxn/theme.json`.

`GENERATED` holds `quickshell/fxn/settings.json` plus `nvim/pack` and
`nvim/plugin` — the plugin trees `install/fxn.sh` and packer create. Without those
two entries the `nvim` component ships a lone `init.lua` and a deploy would
delete copilot.vim (45M) along with `plugin/packer_compiled.lua`.
`kitty/theme.conf` is there for the same reason as the wallust files: it is
rewritten on every theme change, and shipping it would reset the colours.

### monitors

Write your display layout in `conf.d/10-monitors.lua` by hand. **nwg-displays
saves to `~/.config/hypr/monitors.lua`, which this config never loads** —
its output is silently ignored, so the GUI appears to work and changes nothing.
Use it to read coordinates off, then copy them in yourself.

Remember that a rotated output swaps its logical dimensions: a 1920x1080 panel
at `transform = 1` occupies 1080x1920, and every neighbouring position has to be
computed against that.

### not managed by promote.sh

One of wallust's four targets belongs to an app this repo does not manage,
and is deliberately absent from the config tree:

| file | owner |
|---|---|
| `~/.config/cava/config` | wallust (`wallust.toml`, `cava.target`) |

wallust rewrites it on every theme change, so there is nothing here to
promote. Do **not** add cava as a component without first putting
`cava/config` in `GENERATED` — a deploy would otherwise overwrite the live
colours with a stale copy. kitty is the worked example: `kitty/kitty.conf` is
a component, and `kitty/theme.conf` (wallust and fxn-theme write it) is in
`GENERATED`.
