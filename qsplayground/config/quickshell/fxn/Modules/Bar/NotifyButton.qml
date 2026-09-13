import QtQuick
import "root:/Config"
import "root:/Services"
import "root:/Widgets"

/*! notification bell. opens the control center; right click toggles DND. */
IconButton {
    icon: Notifications.icon
    iconColor: Notifications.dnd ? Theme.faint
             : Notifications.hasCritical ? Theme.error
                                         : Theme.text
    badge: Notifications.dnd ? 0 : Notifications.count
    active: Ui.controlCenterOpen
    tooltip: Notifications.dnd
        ? "Do not disturb\nRight click to re-enable notifications"
        : `${Notifications.count} notification${Notifications.count === 1 ? "" : "s"}\n` +
          "Click: open centre · Right: do not disturb"

    onClicked: Ui.toggleControlCenter()
    onRightClicked: Notifications.toggleDnd()
}
