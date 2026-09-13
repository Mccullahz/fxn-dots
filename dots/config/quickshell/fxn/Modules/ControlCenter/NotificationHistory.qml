import QtQuick
import QtQuick.Layouts
import "root:/Config"
import "root:/Services"
import "root:/Widgets"
import "root:/Modules/Notifications"

/*! scrollable list of everything received this session. */
ColumnLayout {
    id: root

    spacing: Theme.spacingSm

    RowLayout {
        Layout.fillWidth: true

        StyledText {
            text: "Notifications"
            font.pixelSize: Theme.fontSizeSm
            color: Theme.subtext
        }

        StyledText {
            visible: Notifications.count > 0
            text: Notifications.count
            font.pixelSize: Theme.fontSizeXs
            color: Theme.faint
        }

        Item { Layout.fillWidth: true }

        IconButton {
            visible: Notifications.count > 0
            icon: "󰎟"
            size: 24
            iconSize: Theme.fontSizeSm
            iconColor: Theme.faint
            tooltip: "Clear all"
            onClicked: Notifications.clearHistory()
        }
    }

    StyledScroll {
        Layout.fillWidth: true
        Layout.fillHeight: true
        // Ask for the whole list. When the panel is capped, the layout
        // shrinks this back toward the minimum and the rest scrolls.
        Layout.preferredHeight: list.implicitHeight
        Layout.minimumHeight: Math.min(list.implicitHeight, 80)
        visible: Notifications.count > 0

        contentHeight: list.implicitHeight

        Column {
            id: list
            width: parent.width
            spacing: Theme.spacingSm

            Repeater {
                model: Notifications.history

                delegate: NotificationItem {
                    required property var modelData

                    width: list.width
                    entry: modelData
                    compact: false
                    color: Theme.alpha(Theme.foreground, 0.05)
                    elevated: false

                    onDismissed: Notifications.remove(entry)
                }
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        Layout.topMargin: Theme.spacing
        Layout.bottomMargin: Theme.spacing
        visible: Notifications.count === 0
        text: "Nothing here"
        horizontalAlignment: Text.AlignHCenter
        color: Theme.faint
        font.pixelSize: Theme.fontSizeSm
    }
}
