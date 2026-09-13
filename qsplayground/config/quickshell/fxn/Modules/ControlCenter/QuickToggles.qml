import QtQuick
import QtQuick.Layouts
import Quickshell
import "root:/Config"
import "root:/Services"
import "root:/Widgets"

/*!
    the tile grid.

    tiles with a detail page (wifi, bluetooth) navigate on click of the behave
*/
GridLayout {
    id: root

    columns: 2
    columnSpacing: Theme.spacingSm
    rowSpacing: Theme.spacingSm

    component Tile: Rectangle {
        id: tile

        property string icon: ""
        property string label: ""
        property string detail: ""
        property bool active: false
        property bool hasPage: false

        signal toggled()
        signal opened()

        Layout.fillWidth: true
        implicitHeight: 56
        radius: Theme.radius
        color: tile.active ? Theme.alpha(Theme.accent, 0.22)
                           : Theme.alpha(Theme.foreground, 0.06)

        Behavior on color {
            ColorAnimation { duration: Theme.durFast }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacing
            anchors.rightMargin: Theme.spacingSm
            spacing: Theme.spacingSm

            Icon {
                text: tile.icon
                size: Theme.fontSizeLg
                color: tile.active ? Theme.accent : Theme.subtext
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: tile.label
                    font.pixelSize: Theme.fontSizeSm
                    color: tile.active ? Theme.text : Theme.subtext
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: tile.detail !== ""
                    text: tile.detail
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.faint
                    elide: Text.ElideRight
                }
            }

            Icon {
                visible: tile.hasPage
                text: "󰅂"
                size: Theme.fontSizeSm
                color: Theme.faint
            }
        }

        StateLayer {
            radius: tile.radius
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton || !tile.hasPage) tile.toggled();
                else tile.opened();
            }
        }
    }

    Tile {
        icon: Network.icon
        label: Network.kind === "wifi" ? Network.ssid : Network.label
        detail: Network.kind === "wifi" ? Network.strength + "%" : ""
        active: Network.connected
        hasPage: true
        onOpened: Ui.controlCenterPage = "network"
        onToggled: Network.toggleWifi()
    }

    Tile {
        icon: BluetoothSvc.icon
        label: "Bluetooth"
        detail: BluetoothSvc.label
        active: BluetoothSvc.enabled
        hasPage: BluetoothSvc.available
        onOpened: Ui.controlCenterPage = "bluetooth"
        onToggled: BluetoothSvc.toggle()
    }

    Tile {
        icon: Notifications.dnd ? "󰂛" : "󰂚"
        label: "Do not disturb"
        detail: Notifications.dnd ? "On" : "Off"
        active: Notifications.dnd
        onToggled: Notifications.toggleDnd()
    }

    Tile {
        icon: Audio.micIcon
        label: "Microphone"
        detail: Audio.micMuted ? "Muted" : Math.round(Audio.micVolume * 100) + "%"
        active: !Audio.micMuted
        onToggled: Audio.toggleMicMute()
    }

    Tile {
        icon: "󰖩"
        label: "Airplane mode"
        detail: Network.wifiEnabled || BluetoothSvc.enabled ? "Off" : "On"
        active: !Network.wifiEnabled && !BluetoothSvc.enabled
        onToggled: {
            const goingOn = Network.wifiEnabled || BluetoothSvc.enabled;
            if (Network.wifiEnabled === goingOn) Network.toggleWifi();
            if (BluetoothSvc.available && BluetoothSvc.enabled === goingOn) BluetoothSvc.toggle();
        }
    }

    Tile {
        icon: "󰸉"
        label: "Wallpaper"
        detail: "Shuffle"
        onToggled: Wallpapers.random()
    }
}
