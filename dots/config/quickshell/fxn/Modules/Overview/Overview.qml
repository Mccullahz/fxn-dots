import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "root:/Config"
import "root:/Services"
import "root:/Widgets"

/*!
    ags -t overview replacement.
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
    visible: Ui.overviewOpen

    WlrLayershell.namespace: "fxn-overview"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"

    onVisibleChanged: {
        if (visible) {
            Hyprland.refreshWorkspaces();
            Hyprland.refreshToplevels();
            scope.forceActiveFocus();
        }
    }

    readonly property var workspaces: {
        const live = {};
        for (const ws of Hyprland.workspaces.values)
            if (ws.id > 0) live[ws.id] = ws;

        const ids = new Set();
        for (let i = 1; i <= Settings.workspaceCount; i++) ids.add(i);
        for (const id of Object.keys(live)) ids.add(parseInt(id));

        return [...ids].sort((a, b) => a - b).map(id => ({
            id: id,
            ws: live[id] ?? null,
            windows: live[id]?.toplevels?.values ?? []
        }));
    }

    function close(): void {
        Ui.overviewOpen = false;
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    FocusScope {
        id: scope
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: root.close()
        Keys.onPressed: event => {
            // 1-9 jump straight to a workspace.
            if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                Hyprland.dispatch(`workspace ${event.key - Qt.Key_0}`);
                root.close();
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(1200, parent.width - 120)
            spacing: Theme.spacingLg

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: "Workspaces"
                font.pixelSize: Theme.fontSizeXl
                color: Theme.text
            }

            GridLayout {
                Layout.fillWidth: true
                columns: Math.min(5, root.workspaces.length)
                columnSpacing: Theme.spacing
                rowSpacing: Theme.spacing

                Repeater {
                    model: root.workspaces

                    delegate: Card {
                        id: card

                        required property var modelData

                        readonly property bool current:
                            card.modelData.id === Hyprland.focusedWorkspace?.id

                        Layout.fillWidth: true
                        Layout.preferredHeight: 190

                        radius: Theme.radius
                        elevated: true
                        color: card.current ? Theme.alpha(Theme.accent, 0.18) : Theme.panel
                        border.color: card.current ? Theme.accent : Theme.borderFaint
                        border.width: card.current ? 2 : 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.spacing
                            spacing: Theme.spacingSm

                            RowLayout {
                                Layout.fillWidth: true

                                StyledText {
                                    text: card.modelData.id
                                    font.pixelSize: Theme.fontSizeLg
                                    font.bold: true
                                    color: card.current ? Theme.accent : Theme.subtext
                                }

                                Item { Layout.fillWidth: true }

                                StyledText {
                                    visible: card.modelData.windows.length > 0
                                    text: card.modelData.windows.length
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Theme.faint
                                }
                            }

                            StyledScroll {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                contentHeight: windows.implicitHeight

                                Column {
                                    id: windows
                                    width: parent.width
                                    spacing: 2

                                    Repeater {
                                        model: card.modelData.windows

                                        delegate: WindowRow {
                                            required property var modelData

                                            width: windows.width
                                            toplevel: modelData
                                            onActivated: root.close()
                                        }
                                    }
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                visible: card.modelData.windows.length === 0
                                text: "empty"
                                horizontalAlignment: Text.AlignHCenter
                                color: Theme.faint
                                font.pixelSize: Theme.fontSizeXs
                            }
                        }

                        StateLayer {
                            radius: card.radius
                            z: -1
                            onClicked: {
                                Hyprland.dispatch(`workspace ${card.modelData.id}`);
                                root.close();
                            }
                        }
                    }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: "1-9 to jump · click a window to focus · esc to close"
                color: Theme.faint
                font.pixelSize: Theme.fontSizeSm
            }
        }
    }
}
