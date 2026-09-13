import QtQuick
import Quickshell
import "root:/Config"
import "root:/Widgets"

Item {
    id: root

    property bool expanded: false

    implicitWidth: label.implicitWidth + Theme.spacingSm * 2
    implicitHeight: parent?.height ?? 28

    Behavior on implicitWidth {
        NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easeStandard }
    }

    // SystemClock only ticks as often as the precision asks it to.
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    StyledText {
        id: label
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date,
            root.expanded ? Settings.clockFormatAlt : Settings.clockFormat)
        font.pixelSize: Theme.fontSize
        color: Theme.text
    }

    StateLayer {
        id: state
        radius: Theme.radiusSm
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) Ui.toggleControlCenter();
            else root.expanded = !root.expanded;
        }
    }

    Tooltip {
        target: root
        hovered: state.containsMouse
        text: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy") +
              "\nClick: switch format · Right: control center"
    }
}
