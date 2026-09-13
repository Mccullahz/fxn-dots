import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "root:/Config"
import "root:/Widgets"

/*!
    Keybind cheat sheet — the KeyHints.sh replacement.

    Reads conf.d/50-binds.conf directly rather than asking hyprctl,
    because the trailing `# comment` on each bind is the only place
    the human-readable description lives. Section headers in the file
    become the groups here, so reorganising the config reorganises
    this page for free.
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
    visible: Ui.cheatsheetOpen

    WlrLayershell.namespace: "fxn-overview"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"

    property var groups: []
    property string filter: ""

    onVisibleChanged: {
        if (visible) {
            binds.reload();
            root.filter = "";
            search.forceActiveFocus();
        }
    }

    FileView {
        id: binds
        path: Paths.hyprConfig + "/conf.d/50-binds.conf"
        printErrors: false
        onLoaded: root.parse(text())
        onLoadFailed: root.groups = []
    }

    /*!
        Pull `bind... = MODS, KEY, ... # description` out of the config,
        bucketed by the `# ─── Section ───` headers above them.
    */
    function parse(text: string): void {
        const out = [];
        let current = null;

        for (const raw of text.split("\n")) {
            const line = raw.trim();

            const header = line.match(/^#\s*─+\s*(.+?)\s*─+/);
            if (header) {
                current = { name: header[1], binds: [] };
                out.push(current);
                continue;
            }

            const bind = line.match(/^bind[elmrtn]*\s*=\s*(.*)$/);
            if (!bind) continue;

            const [body, ...commentParts] = bind[1].split("#");
            const description = commentParts.join("#").trim();
            const fields = body.split(",").map(s => s.trim());
            if (fields.length < 2) continue;

            const mods = fields[0]
                .replace(/\$mainMod/g, "SUPER")
                .split(/\s+/)
                .filter(s => s);
            const key = root.prettyKey(fields[1]);
            if (!key) continue;

            if (!current) {
                current = { name: "Other", binds: [] };
                out.push(current);
            }

            current.binds.push({
                combo: [...mods, key],
                // Fall back to the dispatcher when there is no comment.
                description: description || fields.slice(2).join(", ")
            });
        }

        root.groups = out.filter(g => g.binds.length > 0);
    }

    /*! Turn Hyprland key spellings into something readable. */
    function prettyKey(key: string): string {
        const codes = {
            "code:10": "1", "code:11": "2", "code:12": "3", "code:13": "4",
            "code:14": "5", "code:15": "6", "code:16": "7", "code:17": "8",
            "code:18": "9", "code:19": "0"
        };
        if (codes[key]) return codes[key];

        const names = {
            "Return": "↵", "space": "Space", "SPACE": "Space",
            "left": "←", "right": "→", "up": "↑", "down": "↓",
            "mouse_down": "Scroll ↓", "mouse_up": "Scroll ↑",
            "mouse:272": "LMB", "mouse:273": "RMB",
            "bracketleft": "[", "bracketright": "]",
            "period": ".", "comma": ",", "Print": "PrtSc", "tab": "Tab",
            "Delete": "Del"
        };
        if (names[key]) return names[key];
        if (key.startsWith("XF86")) return key.slice(4);
        return key;
    }

    readonly property var filtered: {
        if (!root.filter) return root.groups;
        const needle = root.filter.toLowerCase();
        const out = [];
        for (const g of root.groups) {
            const hits = g.binds.filter(b =>
                b.description.toLowerCase().includes(needle) ||
                b.combo.join(" ").toLowerCase().includes(needle));
            if (hits.length > 0) out.push({ name: g.name, binds: hits });
        }
        return out;
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)

        MouseArea {
            anchors.fill: parent
            onClicked: Ui.cheatsheetOpen = false
        }
    }

    Card {
        anchors.centerIn: parent
        width: Math.min(1000, parent.width - 100)
        height: Math.min(760, parent.height - 100)
        color: Theme.panel
        border.color: Theme.border
        radius: Theme.radiusLg
        elevated: true

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingLg
            spacing: Theme.spacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacing

                Icon {
                    text: "󰌌"
                    size: Theme.fontSizeXl
                    color: Theme.accent
                }

                StyledText {
                    text: "Keybinds"
                    font.pixelSize: Theme.fontSizeXl
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 240
                    implicitHeight: 32
                    radius: Theme.radiusSm
                    color: Theme.alpha(Theme.foreground, 0.08)

                    TextInput {
                        id: search
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacing
                        anchors.rightMargin: Theme.spacing
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        selectByMouse: true

                        onTextChanged: root.filter = text
                        Keys.onEscapePressed: Ui.cheatsheetOpen = false

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: search.text === ""
                            text: "Filter…"
                            color: Theme.faint
                            font.pixelSize: Theme.fontSizeSm
                        }
                    }
                }
            }

            Separator { Layout.fillWidth: true }

            StyledScroll {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: flow.implicitHeight

                Column {
                    id: flow
                    width: parent.width
                    spacing: Theme.spacingLg

                    Repeater {
                        model: root.filtered

                        delegate: Column {
                            required property var modelData

                            width: flow.width
                            spacing: Theme.spacingXs

                            StyledText {
                                text: modelData.name
                                font.pixelSize: Theme.fontSizeSm
                                font.bold: true
                                color: Theme.accent
                            }

                            Repeater {
                                model: modelData.binds

                                delegate: RowLayout {
                                    required property var modelData

                                    width: flow.width
                                    spacing: Theme.spacing

                                    Row {
                                        Layout.preferredWidth: 240
                                        spacing: 3

                                        Repeater {
                                            model: modelData.combo

                                            delegate: Rectangle {
                                                required property string modelData

                                                implicitWidth: Math.max(22, keyLabel.implicitWidth + 10)
                                                implicitHeight: 20
                                                radius: 4
                                                color: Theme.alpha(Theme.foreground, 0.10)
                                                border.width: 1
                                                border.color: Theme.alpha(Theme.foreground, 0.08)

                                                StyledText {
                                                    id: keyLabel
                                                    anchors.centerIn: parent
                                                    text: modelData
                                                    font.pixelSize: Theme.fontSizeXs
                                                    font.family: Theme.fontMono
                                                    color: Theme.subtext
                                                }
                                            }
                                        }
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: modelData.description
                                        font.pixelSize: Theme.fontSizeSm
                                        color: Theme.text
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.filtered.length === 0
                text: root.groups.length === 0
                    ? "Could not read 50-binds.conf"
                    : "No binds match"
                horizontalAlignment: Text.AlignHCenter
                color: Theme.faint
            }
        }
    }
}
