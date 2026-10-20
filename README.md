# fxn (affection) dotfiles

A Hyprland config built with [Quickshell](https://quickshell.org).

```
qsplayground/  edit, test, break things
dots/          the promoted, known-good copy
promote.sh     moves changes between playground and official dots, and onto the system
install.sh     fresh Arch install → zsh + neovim, ready to go
```

## fresh install

```sh
./install.sh --list     # show everything it would install, change nothing
./install.sh            # do it
```

Covers **zsh and neovim** end to end: packages, oh-my-zsh and its plugins,
oh-my-posh, packer, copilot.vim, the LSP servers, and the config files
themselves (`~/.zshrc`, `ohmyposh/zen.toml`, `fastfetch/`, `nvim/init.lua`).

It is idempotent — re-running is safe, `--needed` skips what is already
installed, and any config file it would overwrite is copied to
`~/.fxn-install-backup-<timestamp>/` first.

| flag | effect |
|---|---|
| `--list`    | print the plan and exit |
| `--no-aur`  | skip AUR packages (you lose the oh-my-posh prompt) |
| `--no-chsh` | leave the login shell alone |

The desktop half — Hyprland, Quickshell, wallust — is **not** installed by
`install.sh`. Install those packages (see [Requirements](#requirements)) and
then run `./promote.sh deploy`.

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
hypr/conf.d/99-local.conf        your own overrides
hypr/conf.d/10-monitors.conf     machine's displays
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
sudo pacman -S --needed quickshell gum swww rsync jq \
                        hypridle hyprlock cliphist wl-clipboard \
                        brightnessctl grim slurp swappy \
                        python imagemagick curl
```

`qalc` (from `libqalculate`) is optional

The zsh and neovim packages are handled by `./install.sh` instead — run
`./install.sh --list` to see that list.

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

`PRESERVE` holds `hypr/conf.d/10-monitors.conf` (per-machine displays) and the
files wallust rewrites on every theme change: `hypr/theme/colors.conf`,
`hypr/theme/roles.conf`, `quickshell/fxn/theme.json`.

`GENERATED` holds `quickshell/fxn/settings.json` plus `nvim/pack` and
`nvim/plugin` — the plugin trees `install.sh` and packer create. Without those
two entries the `nvim` component ships a lone `init.lua` and a deploy would
delete copilot.vim (45M) along with `plugin/packer_compiled.lua`.

### monitors

Write your display layout in `conf.d/10-monitors.conf` by hand. **nwg-displays
saves to `~/.config/hypr/monitors.conf`, which this config never sources** —
its output is silently ignored, so the GUI appears to work and changes nothing.
Use it to read coordinates off, then copy them in yourself.

Remember that a rotated output swaps its logical dimensions: a 1920x1080 panel
at `transform, 1` occupies 1080x1920, and every neighbouring position has to be
computed against that.

### not managed by promote.sh

Two of wallust's four targets belong to apps this repo does not manage, and
they are deliberately absent from the config tree:

| file | owner |
|---|---|
| `~/.config/cava/config` | wallust (`wallust.toml`, `cava.target`) |
| `~/.config/kitty/theme.conf` | wallust (`wallust.toml`, `kitty.target`) |

wallust rewrites both on every theme change, so there is nothing here to
promote. Do **not** add either as a component without first putting the
generated file in `GENERATED` — a deploy would otherwise overwrite the live
colours with a stale copy.
