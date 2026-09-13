import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import "root:/Config"
import "root:/Services"
import "root:/Widgets"

/*! Paired devices, plus whatever discovery turns up. */
ColumnLayout {
    id: root

    spacing: Theme.spacingSm

    component DeviceRow: Rectangle {
        id: drow

        required property var device

        width: parent?.width ?? 0
        implicitHeight: 46
        radius: Theme.radiusSm
        color: drow.device.connected ? Theme.alpha(Theme.accent, 0.16) : "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingSm
            anchors.rightMargin: Theme.spacingSm
            spacing: Theme.spacingSm

            Icon {
                text: drow.iconFor(drow.device.icon)
                size: Theme.fontSize
                color: drow.device.connected ? Theme.accent : Theme.subtext
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: drow.device.alias || drow.device.name || drow.device.address
                    font.pixelSize: Theme.fontSizeSm
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: {
                        if (drow.device.state === BluetoothDeviceState.Connecting) return "Connecting…";
                        if (drow.device.state === BluetoothDeviceState.Disconnecting) return "Disconnecting…";
                        if (drow.device.connected && drow.device.batteryAvailable)
                            return "Connected · " + Math.round(drow.device.battery * 100) + "%";
                        if (drow.device.connected) return "Connected";
                        if (drow.device.paired) return "Paired";
                        return "";
                    }
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.faint
                    elide: Text.ElideRight
                }
            }

            IconButton {
                visible: drow.device.paired || drow.device.bonded
                icon: "󰆴"
                size: 22
                iconSize: Theme.fontSizeXs
                iconColor: Theme.faint
                tooltip: "Forget"
                onClicked: drow.device.forget()
            }
        }

        StateLayer {
            radius: drow.radius
            onClicked: {
                if (drow.device.connected) drow.device.disconnect();
                else if (drow.device.paired || drow.device.bonded) drow.device.connect();
                else drow.device.pair();
            }
        }

        /*! BlueZ icon names → Nerd Font glyphs. */
        function iconFor(name: string): string {
            const n = (name ?? "").toLowerCase();
            if (n.includes("headset") || n.includes("headphone")) return "󰋋";
            if (n.includes("audio"))    return "󰓃";
            if (n.includes("phone"))    return "󰄜";
            if (n.includes("mouse"))    return "󰍽";
            if (n.includes("keyboard")) return "󰌌";
            if (n.includes("computer")) return "󰟀";
            if (n.includes("watch"))    return "󰖉";
            if (n.includes("input"))    return "󰙈";
            return "󰂯";
        }
    }

    RowLayout {
        Layout.fillWidth: true

        Toggle {
            checked: BluetoothSvc.enabled
            enabled: BluetoothSvc.available
            onToggled: BluetoothSvc.toggle()
        }

        StyledText {
            text: BluetoothSvc.enabled ? "Bluetooth on" : "Bluetooth off"
            font.pixelSize: Theme.fontSizeSm
            color: Theme.subtext
        }

        Item { Layout.fillWidth: true }

        IconButton {
            icon: "󰒓"
            size: 26
            iconSize: Theme.fontSizeSm
            tooltip: "Open blueman"
            onClicked: BluetoothSvc.openSettings()
        }
    }

    StyledScroll {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 200

        contentHeight: column.implicitHeight

        Column {
            id: column
            width: parent.width
            spacing: 2

            StyledText {
                visible: BluetoothSvc.known.length > 0
                text: "My devices"
                font.pixelSize: Theme.fontSizeXs
                color: Theme.faint
                bottomPadding: Theme.spacingXs
            }

            Repeater {
                model: BluetoothSvc.known
                delegate: DeviceRow {
                    required property var modelData
                    device: modelData
                }
            }

            Item { width: 1; height: Theme.spacing }

            RowLayout {
                width: column.width
                visible: BluetoothSvc.enabled

                StyledText {
                    text: "Available"
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.faint
                }

                Item { Layout.fillWidth: true }

                StyledText {
                    visible: BluetoothSvc.discovering
                    text: "scanning…"
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.accent
                }
            }

            Repeater {
                model: BluetoothSvc.discovered
                delegate: DeviceRow {
                    required property var modelData
                    device: modelData
                }
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: !BluetoothSvc.available
        text: "No Bluetooth adapter found"
        horizontalAlignment: Text.AlignHCenter
        color: Theme.faint
        font.pixelSize: Theme.fontSizeSm
    }
}
