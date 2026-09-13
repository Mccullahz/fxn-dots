import QtQuick
import "root:/Config"

/*! square icon button with hover feedback and badge */
Rectangle {
    id: root

    property string icon: ""
    property int iconSize: Theme.fontSizeLg
    property color iconColor: Theme.text
    property int size: 32
    property bool active: false
    property string tooltip: ""
    property int badge: 0

    signal clicked()
    signal rightClicked()
    signal middleClicked()

    implicitWidth: size
    implicitHeight: size
    radius: Theme.radiusSm
    color: root.active ? Theme.alpha(Theme.accent, 0.20) : "transparent"

    Behavior on color {
        ColorAnimation { duration: Theme.durFast }
    }

    Icon {
        anchors.centerIn: parent
        text: root.icon
        size: root.iconSize
        color: root.active ? Theme.accent : root.iconColor

        Behavior on color {
            ColorAnimation { duration: Theme.durFast }
        }
    }

    Rectangle {
        visible: root.badge > 0
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 1
        width: Math.max(14, label.implicitWidth + 6)
        height: 14
        radius: height / 2
        color: Theme.accent

        StyledText {
            id: label
            anchors.centerIn: parent
            text: root.badge > 99 ? "99+" : root.badge
            color: Theme.onAccent
            font.pixelSize: Theme.fontSizeXs - 1
            font.bold: true
        }
    }

    StateLayer {
        id: state
        radius: root.radius
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) root.rightClicked();
            else if (mouse.button === Qt.MiddleButton) root.middleClicked();
            else root.clicked();
        }
    }

    Tooltip {
        text: root.tooltip
        target: root
        hovered: state.containsMouse
    }
}
