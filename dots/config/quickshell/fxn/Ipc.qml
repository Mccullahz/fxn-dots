import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "root:/Config"
import "root:/Services"

/*!
    IPC surface for Hyprland keybinds.

    qs -c fxn ipc call <target> <function> [args]

    matching binds in conf.d/50-binds.conf
*/
Item {
    id: root

    function focusedScreen(): string {
        return Hyprland.focusedMonitor?.name ?? "";
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void      { Ui.toggleLauncher("apps"); }
        function open(): void        { Ui.openLauncher("apps"); }
        function close(): void       { Ui.closeLauncher(); }
        function openWeb(): void       { Ui.toggleLauncher("web"); }
        function openCalc(): void      { Ui.toggleLauncher("calc"); }
        function openEmoji(): void     { Ui.toggleLauncher("emoji"); }
        function openClipboard(): void { Ui.toggleLauncher("clipboard"); }
    }

    IpcHandler {
        target: "wallpaper"

        function toggle(): void { Ui.toggleLauncher("wallpaper"); }
        function random(): void { Wallpapers.random(); }
        function set(path: string): void { Wallpapers.apply(path); }
        /*! switch theme by name */
        function theme(name: string): void { Themes.apply(name); }
        function themes(): string { return JSON.stringify(Themes.list); }
    }

    IpcHandler {
        target: "controlcenter"

        function toggle(): void { Ui.toggleControlCenter(); }
        function open(page: string): void { Ui.openControlCenter(page); }
        function close(): void  { Ui.controlCenterOpen = false; }
    }

    IpcHandler {
        target: "powermenu"

        function toggle(): void { Ui.togglePowerMenu(); }
        function close(): void  { Ui.powerMenuOpen = false; }
    }

    IpcHandler {
        target: "overview"

        function toggle(): void { Ui.toggleOverview(); }
        function close(): void  { Ui.overviewOpen = false; }
    }

    IpcHandler {
        target: "cheatsheet"

        function toggle(): void { Ui.toggleCheatsheet(); }
    }

    IpcHandler {
        target: "edge"

        function toggle(): void { Ui.edgeToggle(root.focusedScreen()); }
        function peek(): void   { Ui.edgeTo("peek", root.focusedScreen()); }
        function open(): void   { Ui.edgeTo("open", root.focusedScreen()); }
        function close(): void  { Ui.edgeTo("rest", ""); }

        function onScreen(name: string): void {
            Ui.edgeTo(Ui.edgeOpen ? "rest" : "open", name);
        }
    }

    IpcHandler {
        target: "bar"

        function toggle(): void { Ui.toggleBar(); }
        function show(): void   { Ui.barHidden = false; }
        function hide(): void   { Ui.barHidden = true; }
    }

    IpcHandler {
        target: "notifications"

        function toggleDnd(): void { Notifications.toggleDnd(); }
        function clear(): void     { Notifications.clearHistory(); }
        function dismiss(): void   { Notifications.dismissAllPopups(); }
    }

    IpcHandler {
        target: "audio"

        function volumeUp(): void     { Audio.volumeUp(); }
        function volumeDown(): void   { Audio.volumeDown(); }
        function toggleMute(): void   { Audio.toggleMute(); }
        function toggleMicMute(): void { Audio.toggleMicMute(); }
        function setVolume(percent: string): void {
            Audio.setVolume(parseFloat(percent) / 100);
        }
    }

    IpcHandler {
        target: "brightness"

        function up(): void      { Brightness.up(); }
        function down(): void    { Brightness.down(); }
        function kbdUp(): void   { Brightness.kbdUp(); }
        function kbdDown(): void { Brightness.kbdDown(); }
        function set(percent: string): void {
            Brightness.set(parseFloat(percent) / 100);
        }
    }

    IpcHandler {
        target: "mpris"

        function playPause(): void { Players.playPause(); }
        function next(): void      { Players.next(); }
        function previous(): void  { Players.previous(); }
        function stop(): void      { Players.stop(); }
    }

    IpcHandler {
        target: "shell"

        function dismiss(): void { Ui.dismiss(); }
        function status(): string {
            return JSON.stringify({
                style: Settings.shellStyle,
                edge: Ui.edgeState,
                edgeScreen: Ui.edgeScreen,
                edgePage: Ui.edgePage,
                theme: Theme.name,
                bar: !Ui.barHidden,
                launcher: Ui.launcherOpen,
                launcherMode: Ui.launcherMode,
                controlCenter: Ui.controlCenterOpen,
                powerMenu: Ui.powerMenuOpen,
                overview: Ui.overviewOpen,
                cheatsheet: Ui.cheatsheetOpen,
                dnd: Notifications.dnd,
                notifications: Notifications.count
            });
        }
    }
}
