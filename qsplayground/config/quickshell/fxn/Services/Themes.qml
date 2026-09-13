pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "root:/Config"

Singleton {
    id: root

    property var list: [{ name: "auto", label: "Auto" }]
    readonly property string current: Theme.name
    property bool busy: false

    function refresh(): void {
        listProc.running = true;
    }

    // fxn-theme list prints "name<TAB>label — description".
    Process {
        id: listProc
        command: [Paths.hyprBin + "/fxn-theme", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.trim().split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab < 0) continue;
                    out.push({
                        name: line.slice(0, tab),
                        label: line.slice(tab + 1).split(" — ")[0]
                    });
                }
                if (out.length > 0) root.list = out;
            }
        }
    }

    /*! switch theme, then show one of its wallpapers. Auto instead
        re-derives the palette from the wallpaper already on screen. */
    function apply(name: string): void {
        if (root.busy || name === root.current) return;
        root.busy = true;
        applyProc.command = name === "auto"
            ? ["sh", "-c", '"$1/fxn-theme" auto && "$1/wallpaper.sh" restore',
               "sh", Paths.hyprBin]
            : ["sh", "-c", '"$1/fxn-theme" apply "$2" && "$1/wallpaper.sh" random "$2"',
               "sh", Paths.hyprBin, name];
        applyProc.running = true;
    }

    Process {
        id: applyProc
        onExited: {
            root.busy = false;
            Wallpapers.refresh();
        }
    }

    Component.onCompleted: root.refresh()
}
