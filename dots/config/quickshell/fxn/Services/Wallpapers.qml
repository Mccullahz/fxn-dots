pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "root:/Config"

/*!
    wallpaper library, per theme.
*/
Singleton {
    id: root

    /*! the theme whose wallpapers are listed. "auto" lists everything. */
    property string theme: "auto"
    property var items: []
    property string current: ""
    property bool scanning: false

    readonly property int count: items.length

    onThemeChanged: root.refresh()

    function refresh(): void {
        root.scanning = true;
        scanProc.command = [Paths.hyprBin + "/fxn-walls", "list", root.theme];
        scanProc.running = true;
        currentProc.running = true;
    }

    Process {
        id: scanProc
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.trim().split("\n")) {
                    if (!line) continue;
                    const parts = line.split("/");
                    out.push({
                        path: line,
                        name: parts[parts.length - 1].replace(/\.[^.]+$/, ""),
                        group: parts[parts.length - 2] ?? ""
                    });
                }
                const rank = g => g === "curated" ? 0 : g === "generated" ? 2 : 1;
                out.sort((a, b) => rank(a.group) - rank(b.group) || a.name.localeCompare(b.name));
                root.items = out;
                root.scanning = false;
            }
        }
        onExited: root.scanning = false
    }

    Process {
        id: currentProc
        command: ["readlink", "-f", Paths.currentWallpaper]
        stdout: StdioCollector {
            onStreamFinished: root.current = text.trim()
        }
    }

    function query(text: string, limit: int): var {
        if (!text) return root.items.slice(0, limit);
        return Fuzzy.rank(text, root.items, w => [w.name, w.group], limit);
    }

    function apply(path: string): void {
        root.current = path;
        applyProc.command = [Paths.hyprBin + "/wallpaper.sh", "set", path];
        applyProc.running = true;
    }

    function random(): void {
        applyProc.command = [Paths.hyprBin + "/wallpaper.sh", "random", Theme.name];
        applyProc.running = true;
    }

    Process {
        id: applyProc
        onExited: currentProc.running = true
    }

    Timer {
        interval: Math.max(1, Settings.wallpaperInterval) * 60000
        running: Settings.wallpaperInterval > 0
        repeat: true
        onTriggered: root.random()
    }

    Component.onCompleted: root.refresh()
}
