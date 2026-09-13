import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "root:/Config"
import "root:/Services"
import "root:/Widgets"

/*!
    replacement for every rofi menus
*/
PanelWindow {
    id: root

    readonly property ShellScreen focused: {
        const name = Hyprland.focusedMonitor?.name;
        if (name)
            for (const s of Quickshell.screens)
                if (s.name === name) return s;
        return Quickshell.screens[0] ?? null;
    }

    screen: root.focused
    visible: Settings.useBar && Ui.paletteOpen

    WlrLayershell.namespace: "fxn-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"

    /* ─── Mode ─────────────────────────────────────────────── */

    readonly property var modes: ({
        "apps":      { prefix: "",  icon: "󰀻", placeholder: "Search applications…" },
        "calc":      { prefix: "=", icon: "󰪚", placeholder: "2 + 2, 30 USD to EUR, 5 km in mi…" },
        "emoji":     { prefix: ":", icon: "󰞅", placeholder: "Search emoji…" },
        "web":       { prefix: "?", icon: "󰖟", placeholder: "Search the web…" },
        "clipboard": { prefix: "#", icon: "󰅇", placeholder: "Search clipboard history…" },
        "wallpaper": { prefix: "~", icon: "󰸉", placeholder: "Search wallpapers…" }
    })

    readonly property string mode: {
        const t = input.text;
        for (const key of Object.keys(root.modes)) {
            const p = root.modes[key].prefix;
            if (p && t.startsWith(p)) return key;
        }
        return "apps";
    }

    readonly property string queryText: {
        const p = root.modes[root.mode].prefix;
        return p ? input.text.slice(p.length).trim() : input.text.trim();
    }

    property int selected: 0

    /* ─── Results ──────────────────────────────────────────── */

    readonly property int limit: 40

    readonly property var results: {
        // referenced so the list refreshes when the backing data loads.
        switch (root.mode) {
        case "apps":      return Apps.query(root.queryText, root.limit);
        case "emoji":     return Emoji.query(root.queryText, root.limit);
        case "clipboard": return Clipboard.query(root.queryText, root.limit);
        case "wallpaper": return Wallpapers.query(root.queryText, root.limit);
        case "calc":      return Calc.result ? [{ calc: true }] : [];
        case "web":       return root.queryText ? [{ web: true }] : [];
        }
        return [];
    }

    onResultsChanged: root.selected = 0
    onModeChanged: root.onModeEntered()

    function onModeEntered(): void {
        switch (root.mode) {
        case "emoji":     Emoji.ensureLoaded(); break;
        case "clipboard": Clipboard.refresh();  break;
        case "wallpaper": Wallpapers.refresh(); break;
        }
    }

    onQueryTextChanged: if (root.mode === "calc") Calc.expression = root.queryText

    /* ─── Open / close ─────────────────────────────────────── */

    onVisibleChanged: {
        if (!visible) return;
        input.text = root.modes[Ui.launcherMode]?.prefix ?? "";
        root.selected = 0;
        root.onModeEntered();
        input.forceActiveFocus();
    }

    function close(): void {
        Ui.paletteOpen = false;
    }

    function activate(): void {
        if (root.mode === "web") {
            if (!root.queryText) return;
            Qt.openUrlExternally(root.webUrl(root.queryText));
            root.close();
            return;
        }
        if (root.mode === "calc") {
            Calc.copyResult();
            root.close();
            return;
        }

        const item = root.results[root.selected];
        if (!item) return;

        switch (root.mode) {
        case "apps":      Apps.launch(item); break;
        case "emoji":     Emoji.copy(item); break;
        case "clipboard": Clipboard.copy(item); break;
        case "wallpaper": Wallpapers.apply(item.path); break;
        }
        root.close();
    }

    function webUrl(text: string): string {
        if (/^[a-z][a-z0-9+.-]*:\/\//i.test(text)) return text;
        if (/^[\w-]+(\.[\w-]+)+(\/\S*)?$/.test(text)) return "https://" + text;
        return Settings.searchEngine + encodeURIComponent(text);
    }

    function move(delta: int): void {
        const n = root.results.length;
        if (n === 0) return;
        root.selected = (root.selected + delta + n) % n;
        list.positionViewAtIndex(root.selected, ListView.Contain);
    }

    /* ─── Scrim ────────────────────────────────────────────── */

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
        opacity: root.visible ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.durFast }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    /* ─── Palette ──────────────────────────────────────────── */

    Card {
        id: palette

        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.18

        width: Math.min(640, parent.width - 80)
        implicitHeight: content.implicitHeight

        color: Theme.panel
        border.color: Theme.border
        radius: Theme.radiusLg
        elevated: true

        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.96

        Behavior on opacity { NumberAnimation { duration: Theme.durNormal } }
        Behavior on scale {
            NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easeEmphasized }
        }

        ColumnLayout {
            id: content
            width: parent.width
            spacing: 0

            // ─── Search field ───────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: Theme.spacingLg
                spacing: Theme.spacing

                Icon {
                    text: root.modes[root.mode].icon
                    size: Theme.fontSizeXl
                    color: Theme.accent
                }

                TextInput {
                    id: input

                    Layout.fillWidth: true
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLg
                    selectByMouse: true
                    selectionColor: Theme.alpha(Theme.accent, 0.4)
                    selectedTextColor: Theme.text
                    clip: true

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: input.text === "" || input.text === root.modes[root.mode].prefix
                        text: root.modes[root.mode].placeholder
                        color: Theme.faint
                        font.pixelSize: Theme.fontSizeLg
                    }

                    Keys.onEscapePressed: root.close()
                    Keys.onReturnPressed: root.activate()
                    Keys.onEnterPressed: root.activate()
                    Keys.onUpPressed: root.move(-1)
                    Keys.onDownPressed: root.move(1)

                    Keys.onPressed: event => {
                        // Ctrl-N / Ctrl-P for people with the habit.
                        if (event.modifiers & Qt.ControlModifier) {
                            if (event.key === Qt.Key_N)      { root.move(1);  event.accepted = true; }
                            else if (event.key === Qt.Key_P) { root.move(-1); event.accepted = true; }
                        } else if (event.key === Qt.Key_Tab) {
                            root.move(1);
                            event.accepted = true;
                        }
                    }
                }

                StyledText {
                    visible: root.results.length > 0 && root.mode !== "calc" && root.mode !== "web"
                    text: root.results.length + (root.results.length >= root.limit ? "+" : "")
                    font.pixelSize: Theme.fontSizeSm
                    color: Theme.faint
                }
            }

            Separator { Layout.fillWidth: true }

            // ─── Calculator result ──────────────────────────
            CalcResult {
                Layout.fillWidth: true
                visible: root.mode === "calc"
                expression: root.queryText
            }

            // ─── Web search hint ────────────────────────────
            WebResult {
                Layout.fillWidth: true
                visible: root.mode === "web" && root.queryText !== ""
                url: root.queryText ? root.webUrl(root.queryText) : ""
                term: root.queryText
            }

            // ─── Result list ────────────────────────────────
            ListView {
                id: list

                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(
                    contentHeight, root.height * 0.45)
                Layout.margins: root.results.length > 0 ? Theme.spacingSm : 0

                visible: root.mode !== "calc" && root.mode !== "web"
                model: root.results
                clip: true
                currentIndex: root.selected
                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: 200

                delegate: LauncherRow {
                    required property int index
                    required property var modelData

                    width: list.width
                    mode: root.mode
                    item: modelData
                    selected: index === root.selected

                    onHovered: root.selected = index
                    onActivated: {
                        root.selected = index;
                        root.activate();
                    }
                }
            }

            // ─── Empty state ────────────────────────────────
            StyledText {
                Layout.fillWidth: true
                Layout.margins: Theme.spacingXl
                visible: root.results.length === 0
                      && root.mode !== "calc" && root.mode !== "web"
                text: root.queryText ? "No matches" : "Start typing…"
                horizontalAlignment: Text.AlignHCenter
                color: Theme.faint
            }

            // ─── Mode hints ─────────────────────────────────
            Separator { Layout.fillWidth: true }

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: Theme.spacingSm
                spacing: Theme.spacing

                Repeater {
                    model: [
                        { p: "=", n: "calc" },
                        { p: ":", n: "emoji" },
                        { p: "?", n: "web" },
                        { p: "#", n: "clipboard" },
                        { p: "~", n: "wallpaper" }
                    ]

                    delegate: RowLayout {
                        required property var modelData
                        spacing: 4

                        Rectangle {
                            implicitWidth: 16
                            implicitHeight: 16
                            radius: 4
                            color: Theme.alpha(Theme.foreground, 0.10)

                            StyledText {
                                anchors.centerIn: parent
                                text: modelData.p
                                font.pixelSize: Theme.fontSizeXs
                                color: Theme.subtext
                            }
                        }

                        StyledText {
                            text: modelData.n
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.faint
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                StyledText {
                    text: "esc to close"
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.faint
                }
            }
        }
    }
}
