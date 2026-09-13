import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "root:/Config"
import "root:/Widgets"

/*! StatusNotifierItem tray */
Item {
    id: root

    required property ShellScreen screen

    visible: SystemTray.items.values.length > 0
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: parent?.height ?? 28

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.spacingXs

        Repeater {
            model: SystemTray.items

            delegate: Item {
                id: entry

                required property SystemTrayItem modelData

                implicitWidth: 24
                implicitHeight: 24

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 18
                    source: entry.modelData.icon
                    asynchronous: true
                }

                StateLayer {
                    id: state
                    radius: Theme.radiusSm
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                    onClicked: mouse => {
                        // items that are menu-only have nothing to activate.
                        if (mouse.button === Qt.RightButton || entry.modelData.onlyMenu) {
                            if (entry.modelData.hasMenu) menu.open();
                            return;
                        }
                        if (mouse.button === Qt.MiddleButton) entry.modelData.secondaryActivate();
                        else entry.modelData.activate();
                    }

                    onWheel: wheel => entry.modelData.scroll(wheel.angleDelta.y, false)
                }

                QsMenuAnchor {
                    id: menu
                    menu: entry.modelData.menu
                    anchor.item: entry
                    anchor.edges: Settings.barPosition === "top" ? Edges.Bottom : Edges.Top
                }

                Tooltip {
                    target: entry
                    hovered: state.containsMouse
                    text: entry.modelData.tooltipTitle || entry.modelData.title || entry.modelData.id
                }
            }
        }
    }
}
