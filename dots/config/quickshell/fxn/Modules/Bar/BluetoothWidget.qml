import QtQuick
import "root:/Config"
import "root:/Services"
import "root:/Widgets"

IconButton {
    visible: BluetoothSvc.available
    icon: BluetoothSvc.icon
    iconColor: BluetoothSvc.primary ? Theme.accent
             : BluetoothSvc.enabled ? Theme.text
                                    : Theme.faint
    tooltip: BluetoothSvc.label + "\nClick to open bluetooth settings"

    onClicked: Ui.openControlCenter("bluetooth")
    onRightClicked: BluetoothSvc.toggle()
}
