import QtQuick
import QtQuick.Layouts
import "root:/Config"
import "root:/Widgets"

/*! preview of where the `?` mode will take you. */
Item {
    id: root

    property string url: ""
    property string term: ""

    implicitHeight: visible ? 64 : 0

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingLg
        anchors.rightMargin: Theme.spacingLg
        spacing: Theme.spacing

        Icon {
            text: root.url.startsWith("http") && !root.url.includes("search?")
                ? "󰌷" : "󰖟"
            size: Theme.fontSizeXl
            color: Theme.accent
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.term
                font.pixelSize: Theme.fontSize
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: root.url
                font.pixelSize: Theme.fontSizeXs
                color: Theme.faint
                elide: Text.ElideMiddle
            }
        }

        StyledText {
            text: "↵"
            color: Theme.accent
        }
    }
}
