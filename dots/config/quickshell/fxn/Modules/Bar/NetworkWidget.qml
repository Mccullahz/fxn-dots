import QtQuick
import "root:/Config"
import "root:/Services"
import "root:/Widgets"

/*! connection indicator. opens the control center's network page. */
IconButton {
    id: root

    icon: Network.icon
    iconColor: Network.connected ? Theme.text : Theme.faint
    tooltip: Network.kind === "wifi"
        ? `${Network.ssid} · ${Network.strength}%\nClick to open network settings`
        : `${Network.label}\nClick to open network settings`

    onClicked: Ui.openControlCenter("network")
    onRightClicked: Network.openSettings()
}
