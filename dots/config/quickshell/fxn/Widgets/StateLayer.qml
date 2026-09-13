import QtQuick
import "root:/Config"

/*!
    hover and press feedback for clickable surfaces
*/
MouseArea {
    id: root

    property int radius: Theme.radiusSm
    property color tint: Theme.foreground
    property real hoverOpacity: 0.08
    property real pressOpacity: 0.16
    property bool showState: true

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton

    Rectangle {
        anchors.fill: parent
        z: -1
        radius: root.radius
        visible: root.showState
        color: Theme.alpha(root.tint,
            !root.enabled     ? 0
            : root.pressed    ? root.pressOpacity
            : root.containsMouse ? root.hoverOpacity
            : 0)

        Behavior on color {
            ColorAnimation { duration: Theme.durFast; easing.type: Theme.easeStandard }
        }
    }
}
