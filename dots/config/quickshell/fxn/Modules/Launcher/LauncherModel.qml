import QtQuick
import Quickshell
import "root:/Config"
import "root:/Services"

QtObject {
    id: root

    property string text: ""

    signal done()

    readonly property var modes: ({
        "apps":      { prefix: "",  icon: "󰀻", placeholder: "Search applications" },
        "calc":      { prefix: "=", icon: "󰪚", placeholder: "Calculate — 2+2, 30 USD in EUR" },
        "emoji":     { prefix: ":", icon: "󰞅", placeholder: "Search emoji" },
        "web":       { prefix: "?", icon: "󰖟", placeholder: "Search the web" },
        "clipboard": { prefix: "#", icon: "󰅇", placeholder: "Search clipboard history" }
    })

    readonly property string mode: {
        for (const key of Object.keys(root.modes)) {
            const p = root.modes[key].prefix;
            if (p && root.text.startsWith(p)) return key;
        }
        return "apps";
    }

    readonly property var current: root.modes[root.mode]

    readonly property string queryText: {
        const p = root.current.prefix;
        return (p ? root.text.slice(p.length) : root.text).trim();
    }

    readonly property bool listMode: root.mode !== "calc" && root.mode !== "web"

    property int selected: 0
    readonly property int limit: 40

    readonly property var results: {
        switch (root.mode) {
        case "apps":      return Apps.query(root.queryText, root.limit);
        case "emoji":     return Emoji.query(root.queryText, root.limit);
        case "clipboard": return Clipboard.query(root.queryText, root.limit);
        case "calc":      return Calc.result ? [{ calc: true }] : [];
        case "web":       return root.queryText ? [{ web: true }] : [];
        }
        return [];
    }

    onResultsChanged: root.selected = 0
    onModeChanged: root.prepare()
    onQueryTextChanged: if (root.mode === "calc") Calc.expression = root.queryText

    function prefixFor(mode: string): string {
        return root.modes[mode]?.prefix ?? "";
    }

    function prepare(): void {
        switch (root.mode) {
        case "emoji":     Emoji.ensureLoaded(); break;
        case "clipboard": Clipboard.refresh();  break;
        }
    }

    /*! start fresh in a mode, with its prefix already typed. */
    function reset(mode: string): void {
        root.text = root.prefixFor(mode || "apps");
        root.selected = 0;
        root.prepare();
    }

    function move(delta: int): void {
        const n = root.results.length;
        if (n === 0) return;
        root.selected = (root.selected + delta + n) % n;
    }

    function activate(): void {
        if (root.mode === "web") {
            if (!root.queryText) return;
            Qt.openUrlExternally(root.webUrl(root.queryText));
            root.done();
            return;
        }
        if (root.mode === "calc") {
            Calc.copyResult();
            root.done();
            return;
        }

        const item = root.results[root.selected];
        if (!item) return;

        switch (root.mode) {
        case "apps":      Apps.launch(item); break;
        case "emoji":     Emoji.copy(item); break;
        case "clipboard": Clipboard.copy(item); break;
        }
        root.done();
    }

    function activateAt(index: int): void {
        root.selected = index;
        root.activate();
    }

    function webUrl(text: string): string {
        if (/^[a-z][a-z0-9+.-]*:\/\//i.test(text)) return text;
        if (/^[\w-]+(\.[\w-]+)+(\/\S*)?$/.test(text)) return "https://" + text;
        return Settings.searchEngine + encodeURIComponent(text);
    }
}
