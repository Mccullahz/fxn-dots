import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "root:/Config"
import "root:/Services"
import "root:/Widgets"

/*!
    transient notification toasts — swaync replacement.
*/
PanelWindow {
    id: root

    readonly property bool corner: Settings.notificationPosition.includes("right") ? true : false
    readonly property bool atTop: Settings.notificationPosition.includes("top")

    readonly property ShellScreen focused: {
        const name = Hyprland.focusedMonitor?.name;
        if (name)
            for (const s of Quickshell.screens)
                if (s.name === name) return s;
        return Quickshell.screens[0] ?? null;
    }

    screen: root.focused
    // Hidden while the control center is open: it lists the same
    // notifications, and it sits in the same corner.
    visible: Notifications.popups.length > 0 && !Ui.controlCenterOpen

    WlrLayershell.namespace: "fxn-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: root.atTop
        bottom: !root.atTop
        right: Settings.notificationPosition.includes("right")
        left: Settings.notificationPosition.includes("left")
    }

    margins {
        top: root.atTop ? Settings.barMargin + (Settings.barPosition === "top" ? Settings.barHeight : 0) + 8 : 0
        bottom: root.atTop ? 0 : Settings.barMargin + (Settings.barPosition === "bottom" ? Settings.barHeight : 0) + 8
        left: 8
        right: 8
    }

    exclusiveZone: 0
    color: "transparent"

    implicitWidth: 400
    implicitHeight: Math.max(1, column.implicitHeight)

    Column {
        id: column
        width: parent.width
        spacing: Theme.spacingSm
        add: Transition {
            NumberAnimation {
                properties: "y"
                duration: Theme.durNormal
                easing.type: Theme.easeStandard
            }
        }
        move: Transition {
            NumberAnimation {
                properties: "y"
                duration: Theme.durNormal
                easing.type: Theme.easeStandard
            }
        }

        Repeater {
            model: root.atTop ? Notifications.popups
                              : Notifications.popups.slice().reverse()

            delegate: NotificationItem {
                required property var modelData

                width: column.width
                entry: modelData
                compact: true

                onDismissed: Notifications.remove(entry)
            }
        }
    }
}
