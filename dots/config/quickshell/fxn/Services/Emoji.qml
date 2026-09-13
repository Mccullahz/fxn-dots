pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "root:/Config"

Singleton {
    id: root

    property var items: []
    property bool loaded: false

    /*! Most recently used characters, newest first. */
    property var recent: []

    function ensureLoaded(): void {
        if (!root.loaded) file.reload();
    }

    FileView {
        id: file
        path: Paths.shell + "/emoji.json"
        blockLoading: false
        printErrors: false

        onLoaded: {
            try {
                root.items = JSON.parse(text());
                root.loaded = true;
            } catch (e) {
                console.warn("Emoji: emoji.json is not valid JSON —", e);
            }
        }
        onLoadFailed: console.warn("Emoji: could not read", path)
    }

    function query(text: string, limit: int): var {
        if (!root.loaded) return [];
        if (!text) {
            const recentItems = root.recent
                .map(c => root.items.find(e => e.c === c))
                .filter(e => e);
            const rest = root.items.filter(e => root.recent.indexOf(e.c) < 0);
            return [...recentItems, ...rest].slice(0, limit);
        }
        return Fuzzy.rank(text, root.items, e => [e.k], limit);
    }

    function nameOf(entry: var): string {
        return (entry?.k ?? "").split(" ").slice(0, 4).join(" ");
    }

    function copy(entry: var): void {
        Quickshell.execDetached(["wl-copy", "--", entry.c]);

        root.recent = [entry.c, ...root.recent.filter(c => c !== entry.c)].slice(0, 40);
        recentFile.setText(JSON.stringify(root.recent));
    }

    FileView {
        id: recentFile
        path: Paths.cache + "/emoji-recent.json"
        printErrors: false
        onLoaded: {
            try { root.recent = JSON.parse(text()) ?? []; } catch (e) { root.recent = []; }
        }
        onLoadFailed: root.recent = []
    }
}
