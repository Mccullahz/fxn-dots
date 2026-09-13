import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "root:/Config"
import "root:/Widgets"

/*!
    workspace pills.
*/
Item {
    id: root

    required property ShellScreen screen

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)

    readonly property var shown: {
        const live = {};
        for (const ws of Hyprland.workspaces.values) {
            if (ws.id < 0) continue;                       // special workspaces
            if (!Settings.workspacesAllOutputs && ws.monitor !== root.monitor) continue;
            live[ws.id] = ws;
        }

        const ids = new Set();
        for (let i = 1; i <= Settings.workspaceCount; i++) ids.add(i);
        for (const id of Object.keys(live)) ids.add(parseInt(id));

        return [...ids].sort((a, b) => a - b).map(id => ({
            id: id,
            ws: live[id] ?? null,
            occupied: (live[id]?.toplevels?.values?.length ?? 0) > 0,
            focused: live[id] ? live[id].id === Hyprland.focusedWorkspace?.id : false,
            urgent: live[id]?.urgent ?? false
        }));
    }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.spacingXs

        Repeater {
            model: root.shown

            delegate: Rectangle {
                id: pill

                required property var modelData

                readonly property string label: {
                    switch (Settings.workspaceStyle) {
                    case "kanji":
                        const kanji = ["一","二","三","四","五","六","七","八","九","十"];
                        return pill.modelData.id <= 10 ? kanji[pill.modelData.id - 1]
                                                       : pill.modelData.id;
                    case "dots":
                        return pill.modelData.occupied ? "" : "";
                    default:
                        return pill.modelData.id;
                    }
                }

                implicitWidth: pill.modelData.focused ? 34 : 26
                implicitHeight: 24
                radius: Theme.radiusPill

                color: pill.modelData.focused ? Theme.alpha(Theme.accent, 0.25)
                     : pill.modelData.urgent  ? Theme.alpha(Theme.error, 0.25)
                                              : "transparent"

                Behavior on implicitWidth {
                    NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easeEmphasized }
                }
                Behavior on color {
                    ColorAnimation { duration: Theme.durNormal }
                }

                StyledText {
                    anchors.centerIn: parent
                    text: pill.label
                    font.pixelSize: Settings.workspaceStyle === "dots"
                        ? Theme.fontSizeXs : Theme.fontSize
                    color: pill.modelData.focused  ? Theme.accent
                         : pill.modelData.urgent   ? Theme.error
                         : pill.modelData.occupied ? Theme.text
                                                   : Theme.faint

                    Behavior on color {
                        ColorAnimation { duration: Theme.durNormal }
                    }
                }

                StateLayer {
                    radius: pill.radius
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton)
                            Hyprland.dispatch(`movetoworkspace ${pill.modelData.id}`);
                        else
                            Hyprland.dispatch(`workspace ${pill.modelData.id}`);
                    }
                    onWheel: wheel => Hyprland.dispatch(
                        wheel.angleDelta.y > 0 ? "workspace e-1" : "workspace e+1")
                }
            }
        }
    }
}
