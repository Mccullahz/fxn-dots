import QtQuick
import QtQuick.Layouts
import "root:/Config"
import "root:/Services"
import "root:/Widgets"

/*! now-playing card with album art, transport and a seek bar. */
Rectangle {
    id: root

    implicitHeight: 92
    radius: Theme.radius
    color: Theme.alpha(Theme.foreground, 0.06)
    clip: true

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing
        spacing: Theme.spacing

        Rectangle {
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            radius: Theme.radiusSm
            color: Theme.alpha(Theme.accent, 0.15)
            clip: true

            Image {
                anchors.fill: parent
                source: Players.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 128
                sourceSize.height: 128
                visible: status === Image.Ready
            }

            Icon {
                anchors.centerIn: parent
                visible: Players.artUrl === ""
                text: Players.icon
                size: Theme.fontSizeXl
                color: Theme.accent
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: Players.title || Players.identity
                font.pixelSize: Theme.fontSize
                font.bold: true
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: Players.artist
                font.pixelSize: Theme.fontSizeXs
                color: Theme.subtext
                elide: Text.ElideRight
            }

            StyledSlider {
                Layout.fillWidth: true
                Layout.topMargin: 2
                trackHeight: 4
                value: Players.progress
                enabled: Players.active?.canSeek ?? false
                onMoved: v => Players.seek(v)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingXs

                IconButton {
                    icon: "󰒮"
                    size: 26
                    iconSize: Theme.fontSize
                    enabled: Players.active?.canGoPrevious ?? false
                    opacity: enabled ? 1 : 0.4
                    onClicked: Players.previous()
                }

                IconButton {
                    icon: Players.playing ? "󰏤" : "󰐊"
                    size: 26
                    iconSize: Theme.fontSizeLg
                    iconColor: Theme.accent
                    onClicked: Players.playPause()
                }

                IconButton {
                    icon: "󰒭"
                    size: 26
                    iconSize: Theme.fontSize
                    enabled: Players.active?.canGoNext ?? false
                    opacity: enabled ? 1 : 0.4
                    onClicked: Players.next()
                }

                Item { Layout.fillWidth: true }

                StyledText {
                    text: root.timeText
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.faint
                }
            }
        }
    }

    readonly property string timeText: {
        if (Players.length <= 0) return "";
        return root.clock(Players.position) + " / " + root.clock(Players.length);
    }

    function clock(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        const m = Math.floor(s / 60);
        return m + ":" + String(s % 60).padStart(2, "0");
    }
}
