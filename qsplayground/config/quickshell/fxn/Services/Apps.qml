pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "root:/Config"

/*!
    Installed applications, ranked for the launcher.
*/
Singleton {
    id: root

    readonly property var all: {
        const out = [];
        for (const e of DesktopEntries.applications.values)
            if (!e.noDisplay) out.push(e);
        return out;
    }

    /*! { "org.kde.foo.desktop": launchCount } */
    property var frequency: ({})

    function usesOf(entry: var): int {
        return root.frequency[entry.id] ?? 0;
    }

    /*! Ranked results for a query. Empty query = most-used first. */
    function query(text: string, limit: int): var {
        if (!text) {
            const sorted = root.all.slice();
            sorted.sort((a, b) => {
                const d = root.usesOf(b) - root.usesOf(a);
                return d !== 0 ? d : a.name.localeCompare(b.name);
            });
            return sorted.slice(0, limit);
        }

        const scored = [];
        for (const e of root.all) {
            const s = Fuzzy.scoreFields(text, [
                e.name,
                e.genericName ?? "",
                (e.keywords ?? []).join(" "),
                e.comment ?? "",
                e.execString ?? ""
            ]);
            if (s >= 0)
                scored.push({ e, s: s + Math.min(root.usesOf(e), 20) * 4 });
        }
        scored.sort((a, b) => b.s - a.s);
        return scored.slice(0, limit).map(x => x.e);
    }

    function launch(entry: var): void {
        root.frequency[entry.id] = root.usesOf(entry) + 1;
        root.frequencyChanged();
        freqFile.save();
        entry.execute();
    }

    FileView {
        id: freqFile
        path: Paths.cache + "/app-frequency.json"
        watchChanges: false
        printErrors: false

        onLoaded: {
            try {
                root.frequency = JSON.parse(text()) ?? {};
            } catch (e) {
                root.frequency = {};
            }
        }
        onLoadFailed: root.frequency = {}

        // Named save() rather than writeAdapter() — FileView already
        // has a writeAdapter() for JsonAdapter-backed views.
        function save(): void {
            setText(JSON.stringify(root.frequency));
        }
    }
}
