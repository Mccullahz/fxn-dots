import QtQuick
import "root:/Config"

Rectangle {
    property bool vertical: false

    implicitWidth:  vertical ? 1 : parent?.width ?? 0
    implicitHeight: vertical ? (parent?.height ?? 0) * 0.55 : 1
    color: Theme.alpha(Theme.foreground, 0.12)
}
