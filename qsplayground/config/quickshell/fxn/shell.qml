//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark

import Quickshell
import "Modules/Bar"
import "Modules/Edge"
import "Modules/Osd"
import "Modules/Notifications"
import "Modules/ControlCenter"
import "Modules/Launcher"
import "Modules/PowerMenu"
import "Modules/Overview"
import "Modules/Cheatsheet"

/*!
    fxn — a Quickshell desktop shell for Hyprland
    replaces waybar, swaync, rofi, wlogout and ags well enough for my needs
        Config/    palette, settings, paths, UI state
        Services/  data sources (audio, network, notifications…)
        Widgets/   reusable UI primitives
        Modules/   the surfaces themselves
    `qs -c fxn ipc show` to list the IPC entry points
*/
ShellRoot {
    Edge {}
    Bar {}

    NotificationPopups {}
    Osd {}

    ControlCenter {}
    Launcher {}
    PowerMenu {}
    Overview {}
    Cheatsheet {}

    Ipc {}
}
