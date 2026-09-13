import QtQuick
import "root:/Config"

/*!
    horizontal slider
*/
Item {
    id: root

    property real value: 0
    property color fillColor: Theme.accent
    property int trackHeight: 6
    property string icon: ""

    signal moved(real value)

    implicitHeight: Math.max(20, trackHeight)
    opacity: root.enabled ? 1 : 0.4

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.trackHeight
        radius: height / 2
        color: Theme.alpha(Theme.foreground, 0.15)

        Rectangle {
            width: Math.max(parent.height, parent.width * Math.max(0, Math.min(1, root.value)))
            height: parent.height
            radius: parent.radius
            color: root.fillColor

            Behavior on width {
                enabled: !drag.pressed
                NumberAnimation { duration: Theme.durFast }
            }
        }
    }

    Icon {
        visible: root.icon !== ""
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        size: Theme.fontSizeSm
        color: Theme.contrastOn(root.fillColor)
        opacity: root.value > 0.12 ? 1 : 0
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        anchors.margins: -6
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        function apply(x: real): void {
            const local = drag.mapToItem(track, x, 0).x;
            const v = Math.max(0, Math.min(1, local / track.width));
            root.value = v;
            root.moved(v);
        }

        onPressed: mouse => apply(mouse.x)
        onPositionChanged: mouse => { if (pressed) apply(mouse.x); }
        onWheel: wheel => {
            const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            const v = Math.max(0, Math.min(1, root.value + step));
            root.value = v;
            root.moved(v);
        }
    }
}
