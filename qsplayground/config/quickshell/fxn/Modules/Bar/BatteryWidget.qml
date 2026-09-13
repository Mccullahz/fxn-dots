import QtQuick
import QtQuick.Layouts
import "root:/Config"
import "root:/Services"
import "root:/Widgets"

/*! battery readout. should be hid on desktops. */
Item {
    id: root

    visible: Battery.available
    implicitWidth: visible ? row.implicitWidth + Theme.spacingSm * 2 : 0
    implicitHeight: parent?.height ?? 28

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.spacingXs

        Icon {
            text: Battery.icon
            size: Theme.fontSize
            color: Battery.tint

            // Draw attention when critical, but only then.
            SequentialAnimation on opacity {
                running: Battery.critical
                loops: Animation.Infinite
                alwaysRunToEnd: true
                NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 1.0;  duration: 700; easing.type: Easing.InOutQuad }
            }
        }

        StyledText {
            text: Math.round(Battery.percent * 100) + "%"
            font.pixelSize: Theme.fontSizeSm
            color: Battery.tint
        }
    }

    StateLayer {
        id: state
        radius: Theme.radiusSm
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) Ui.togglePowerMenu();
            else Ui.toggleControlCenter();
        }
    }

    Tooltip {
        target: root
        hovered: state.containsMouse
        text: Battery.statusText +
              (Battery.rate > 0 ? `\n${Battery.rate.toFixed(1)} W` : "") +
              (Battery.health > 0 ? `\nHealth ${Math.round(Battery.health)}%` : "") +
              "\nClick: control centre · Right: power menu"
    }
}
