import QtQuick
import QtQuick.Layouts
import Quickshell
import "root:/Config"
import "root:/Services"
import "root:/Widgets"

/*! identity, uptime, back button and power. */
RowLayout {
    id: root

    spacing: Theme.spacing

    IconButton {
        visible: Ui.controlCenterPage !== "home"
        icon: "󰁍"
        tooltip: "Back"
        onClicked: Ui.controlCenterPage = "home"
    }

    Rectangle {
        visible: Ui.controlCenterPage === "home"
        implicitWidth: 40
        implicitHeight: 40
        radius: width / 2
        color: Theme.alpha(Theme.accent, 0.2)

        StyledText {
            anchors.centerIn: parent
            text: (Quickshell.env("USER") ?? "?").charAt(0).toUpperCase()
            color: Theme.accent
            font.pixelSize: Theme.fontSizeLg
            font.bold: true
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        StyledText {
            text: {
                switch (Ui.controlCenterPage) {
                case "network":   return "Network";
                case "bluetooth": return "Bluetooth";
                default:          return Quickshell.env("USER") ?? "";
                }
            }
            font.pixelSize: Theme.fontSizeLg
            font.bold: true
        }

        StyledText {
            text: Ui.controlCenterPage === "home"
                ? (SysInfo.uptime ? "up " + SysInfo.uptime : SysInfo.distro)
                : (Ui.controlCenterPage === "network" ? Network.label : BluetoothSvc.label)
            font.pixelSize: Theme.fontSizeXs
            color: Theme.faint
        }
    }

    IconButton {
        icon: "󰒓"
        tooltip: "Edit settings.json"
        onClicked: {
            Quickshell.execDetached([Settings.terminal, "-e",
                Quickshell.env("EDITOR") || "nano", Paths.settings]);
            Ui.controlCenterOpen = false;
        }
    }

    IconButton {
        icon: "󰐥"
        iconColor: Theme.error
        tooltip: "Power menu"
        onClicked: Ui.togglePowerMenu()
    }
}
