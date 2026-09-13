import QtQuick
import QtQuick.Layouts
import "root:/Config"
import "root:/Services"
import "root:/Widgets"

Item {
    id: root

    visible: Brightness.available
    implicitWidth: visible ? row.implicitWidth + Theme.spacingSm * 2 : 0
    implicitHeight: parent?.height ?? 28

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.spacingXs

        Icon {
            text: Brightness.icon
            size: Theme.fontSize
        }

        StyledText {
            text: Math.round(Brightness.value * 100) + "%"
            font.pixelSize: Theme.fontSizeSm
        }
    }

    StateLayer {
        id: state
        radius: Theme.radiusSm
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) Brightness.up();
            else Brightness.down();
        }
    }

    Tooltip {
        target: root
        hovered: state.containsMouse
        text: `Brightness ${Math.round(Brightness.value * 100)}%\nScroll to adjust`
    }
}
