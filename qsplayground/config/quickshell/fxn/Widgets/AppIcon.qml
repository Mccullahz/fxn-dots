import QtQuick
import Quickshell
import Quickshell.Widgets
import "root:/Config"

/*!
    application icon looked up in the icon theme
    fallback to colored initial when the theme has nothing for it.
*/
Item {
    id: root

    property string source: ""
    property string fallbackText: ""
    property int size: 32

    implicitWidth: size
    implicitHeight: size

    readonly property string resolved: root.source
        ? (root.source.includes("://") ? root.source
           : root.source.startsWith("/") ? "file://" + root.source
           : Quickshell.iconPath(root.source, true))
        : ""

    IconImage {
        id: image
        anchors.fill: parent
        source: root.resolved
        implicitSize: root.size
        visible: root.resolved !== "" && status === Image.Ready
        asynchronous: true
    }

    Rectangle {
        anchors.fill: parent
        visible: !image.visible
        radius: width / 4
        color: Theme.alpha(Theme.accent, 0.22)

        StyledText {
            anchors.centerIn: parent
            text: (root.fallbackText || "?").charAt(0).toUpperCase()
            color: Theme.accent
            font.pixelSize: root.size * 0.5
            font.bold: true
        }
    }
}
