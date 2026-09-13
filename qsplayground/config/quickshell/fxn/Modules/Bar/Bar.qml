import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "root:/Config"
import "root:/Widgets"

/*!
    bar - waybar replacement

    two shapes, chosen by Settings.barMode:
      "full"     spans the whole output edge
      "floating" is a centred island of Settings.barWidth
*/
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar

        required property ShellScreen modelData

        readonly property bool atTop: Settings.barPosition === "top"
        readonly property bool floating: Settings.barMode === "floating"

        screen: bar.modelData
        visible: Settings.useBar && !Ui.barHidden

        WlrLayershell.namespace: "fxn-bar"
        WlrLayershell.layer: WlrLayer.Top

        color: "transparent"

        anchors {
            top: bar.atTop
            bottom: !bar.atTop
            left: !bar.floating
            right: !bar.floating
        }

        margins {
            top: bar.atTop ? Settings.barMargin : 0
            bottom: bar.atTop ? 0 : Settings.barMargin
        }

        implicitHeight: Settings.barHeight
        implicitWidth: bar.floating
            ? Math.min(Settings.barWidth, bar.modelData.width - Settings.barMargin * 2)
            : 0

        // reserve space so windows don't sit underneath.
        exclusiveZone: Settings.barExclusive
            ? Settings.barHeight + Settings.barMargin
            : 0

        Card {
            anchors.fill: parent
            color: Theme.panel
            radius: bar.floating ? Theme.radius : 0
            border.color: Theme.border
            border.width: bar.floating ? Theme.borderWidth : 0

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacing
                anchors.rightMargin: Theme.spacing
                spacing: Theme.spacingSm

                // ─── Left ───────────────────────────────────
                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Theme.spacingSm

                    Clock {}

                    Separator { vertical: true; Layout.fillHeight: true }

                    MediaWidget { Layout.maximumWidth: 260 }

                    Tray { screen: bar.modelData }

                    NotifyButton {}
                }

                Item { Layout.fillWidth: true }

                // ─── Centre ─────────────────────────────────
                Workspaces {
                    Layout.alignment: Qt.AlignVCenter
                    screen: bar.modelData
                }

                Item { Layout.fillWidth: true }

                // ─── Right ──────────────────────────────────
                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Theme.spacingSm

                    Resources {}

                    Separator { vertical: true; Layout.fillHeight: true }

                    NetworkWidget {}

                    BluetoothWidget {}

                    AudioWidget {}

                    BrightnessWidget {}

                    BatteryWidget {}
                }
            }
        }
    }
}
