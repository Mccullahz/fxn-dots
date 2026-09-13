import QtQuick
import "root:/Config"

/*!
    Nerd Font glyph.
*/
Item {
    id: root

    property alias text: label.text
    property int size: Theme.fontSizeLg
    property color color: Theme.text

    implicitWidth: Math.max(label.implicitWidth, size * 1.25)
    implicitHeight: size * 1.25

    Text {
        id: label

        anchors.centerIn: parent

        color: root.color
        font.family: Theme.fontFamily
        font.pixelSize: root.size
        renderType: Text.NativeRendering
        textFormat: Text.PlainText

        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
