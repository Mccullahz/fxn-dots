# fxn (affection) dotfiles

A Hyprland config built with [Quickshell](https://quickshell.org).

```
qsplayground/  edit, test, break things
dots/          the promoted, known-good copy
promote.sh     moves changes between playground and official dots, and onto the system
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
