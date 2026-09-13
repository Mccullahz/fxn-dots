import QtQuick
import QtQuick.Controls
import "root:/Config"

/*!
    ScrollView replacemen so rhe scrollbar matches the palette and doesn't reserve layout width
*/
Flickable {
    id: root

    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickDeceleration: 6000
    maximumFlickVelocity: 3000
    contentWidth: width

    ScrollBar.vertical: ScrollBar {
        id: bar
        policy: root.contentHeight > root.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
        width: 6

        contentItem: Rectangle {
            radius: width / 2
            color: Theme.alpha(Theme.foreground, bar.pressed ? 0.45 : bar.hovered ? 0.32 : 0.18)

            Behavior on color {
                ColorAnimation { duration: Theme.durFast }
            }
        }

        background: null
    }
}
