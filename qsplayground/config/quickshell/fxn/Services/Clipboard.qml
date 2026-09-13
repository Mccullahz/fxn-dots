pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "root:/Config"

Singleton {
    id: root

    property var entries: []
    property bool loading: false

    function refresh(): void {
        root.loading = true;
        listProc.running = true;
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    if (!line) continue;
                    const tab = line.indexOf("\t");
                    if (tab < 0) continue;
                    const preview = line.slice(tab + 1);
                    out.push({
                        id: line.slice(0, tab),
                        preview: preview,
                        // cliphist renders binary entries as "[[ binary data ... ]]"
                        isImage: /^\[\[\s*binary data/.test(preview)
                    });
                }
                root.entries = out;
                root.loading = false;
            }
        }
        onExited: root.loading = false
    }

    function query(text: string, limit: int): var {
        if (!text) return root.entries.slice(0, limit);
        return Fuzzy.rank(text, root.entries, e => [e.preview], limit);
    }

    function copy(entry: var): void {
        Quickshell.execDetached(["sh", "-c",
            'printf "%s\\t" "$1" | cliphist decode | wl-copy', "sh", entry.id]);
    }

    function remove(entry: var): void {
        deleteProc.command = ["sh", "-c",
            'printf "%s\\t" "$1" | cliphist delete', "sh", entry.id];
        deleteProc.running = true;
    }

    Process {
        id: deleteProc
        onExited: root.refresh()
    }

    function wipe(): void {
        wipeProc.running = true;
    }

    Process {
        id: wipeProc
        command: ["cliphist", "wipe"]
        onExited: root.refresh()
    }
}
