import QtQuick
import QtQuick.Layouts
import "root:/Config"
import "root:/Services"
import "root:/Widgets"

/*! one result row. renders differently per launcher mode. */
Rectangle {
    id: root

    required property string mode
    required property var item
    property bool selected: false

    signal hovered()
    signal activated()

    implicitHeight: 48
    radius: Theme.radiusSm
    color: root.selected ? Theme.alpha(Theme.accent, 0.18) : "transparent"

    Behavior on color {
        ColorAnimation { duration: Theme.durFast }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacing
        anchors.rightMargin: Theme.spacing
        spacing: Theme.spacing

        // ─── Leading visual ─────────────────────────────────
        Loader {
            Layout.alignment: Qt.AlignVCenter
            sourceComponent: {
                switch (root.mode) {
                case "apps":      return appIcon;
                case "emoji":     return emojiGlyph;
                case "wallpaper": return thumbnail;
                default:          return genericIcon;
                }
            }
        }

        Component {
            id: appIcon
            AppIcon {
                size: 32
                source: root.item?.icon ?? ""
                fallbackText: root.item?.name ?? ""
            }
        }

        Component {
            id: emojiGlyph
            Item {
                implicitWidth: 32
                implicitHeight: 32
                Text {
                    anchors.centerIn: parent
                    text: root.item?.c ?? ""
                    font.pixelSize: 24
                    // fontconfig picks the colour emoji font rather than the Nerd Font.
                }
            }
        }

        Component {
            id: thumbnail
            Rectangle {
                implicitWidth: 48
                implicitHeight: 32
                radius: Theme.radiusSm
                color: Theme.alpha(Theme.foreground, 0.08)
                clip: true

                Image {
                    anchors.fill: parent
                    source: root.item?.path ? "file://" + root.item.path : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    // decode at display size, not full resolution — space
                    sourceSize.width: 96
                    sourceSize.height: 64
                }
            }
        }

        Component {
            id: genericIcon
            Icon {
                text: root.item?.isImage ? "󰋩" : "󰅇"
                size: Theme.fontSizeLg
                color: Theme.subtext
                implicitWidth: 32
            }
        }

        // ─── Text ───────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.primaryText
                font.pixelSize: Theme.fontSize
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.secondaryText
                font.pixelSize: Theme.fontSizeXs
                color: Theme.faint
                elide: Text.ElideRight
            }
        }

        // ─── Trailing ───────────────────────────────────────
        StyledText {
            visible: root.selected
            text: "↵"
            color: Theme.accent
            font.pixelSize: Theme.fontSize
        }
    }

    readonly property string primaryText: {
        switch (root.mode) {
        case "apps":      return root.item?.name ?? "";
        case "emoji":     return Emoji.nameOf(root.item);
        case "clipboard": return (root.item?.preview ?? "").slice(0, 120);
        case "wallpaper": return root.item?.name ?? "";
        }
        return "";
    }

    readonly property string secondaryText: {
        switch (root.mode) {
        case "apps":      return root.item?.genericName || root.item?.comment || "";
        case "emoji":     return root.item?.c ?? "";
        case "clipboard": return root.item?.isImage ? "image" : "";
        case "wallpaper": return root.item?.group ?? "";
        }
        return "";
    }

    StateLayer {
        radius: root.radius
        showState: false
        onContainsMouseChanged: if (containsMouse) root.hovered()
        onClicked: root.activated()
    }
}
