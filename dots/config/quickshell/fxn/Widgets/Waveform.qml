import QtQuick
import "root:/Config"

/*!
    four bars that bounce while something is playing.
*/
Row {
    id: root

    property bool playing: false
    property color color: Theme.accent
    property int barHeight: 12

    spacing: 2
    height: root.barHeight

    Repeater {
        model: [0.45, 0.92, 0.6, 1.0]

        delegate: Rectangle {
            id: bar

            required property int index
            required property real modelData

            width: 2
            height: root.barHeight * bar.modelData
            radius: 1
            color: root.color
            anchors.verticalCenter: parent.verticalCenter

            transform: Scale {
                id: squash
                origin.x: 1
                origin.y: bar.height / 2
                yScale: 1
            }

            SequentialAnimation {
                running: root.playing && root.visible
                loops: Animation.Infinite
                PauseAnimation { duration: bar.index * 120 }
                NumberAnimation {
                    target: squash; property: "yScale"
                    to: 0.34; duration: 450; easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: squash; property: "yScale"
                    to: 1.0; duration: 450; easing.type: Easing.InOutQuad
                }
            }

            onVisibleChanged: if (!visible) squash.yScale = 1
            Connections {
                target: root
                function onPlayingChanged(): void {
                    if (!root.playing) squash.yScale = 1;
                }
            }
        }
    }
}
