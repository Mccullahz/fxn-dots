import QtQuick
import QtQuick.Layouts
import Quickshell
import "root:/Config"
import "root:/Services"
import "root:/Widgets"

/*!
    The panel that drops in beneath the island: playback, volume, and
    the session row.

    A separate surface from the pill on purpose — it arrives as its own
    object, which is what makes the two-stage reveal legible.
*/
Card {
    id: root

    required property bool shown
    required property int duration

    implicitHeight: layout.implicitHeight + Theme.spacing * 2

    color: Theme.panel
    border.color: Theme.border
    radius: Theme.radius
    elevated: true
    clip: true

    transformOrigin: Item.Top
    opacity: root.shown ? 1 : 0
    scale: root.shown ? 1 : 0.97
    transform: Translate { y: root.shown ? 0 : -14 }
    visible: opacity > 0.01

    Behavior on opacity {
        NumberAnimation { duration: Math.round(root.duration * 0.7) }
    }
    Behavior on scale {
        NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Theme.spacing
        spacing: Theme.spacingSm

        // ─── Playback ───────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing
            visible: Players.has

            Rectangle {
                Layout.preferredWidth: 46
                Layout.preferredHeight: 46
                radius: Theme.radiusSm
                color: Theme.alpha(Theme.accent, 0.15)
                clip: true

                Image {
                    anchors.fill: parent
                    source: Players.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 92
                    sourceSize.height: 92
                    visible: status === Image.Ready
                }

                Icon {
                    anchors.centerIn: parent
                    visible: Players.artUrl === ""
                    text: Players.icon
                    size: Theme.fontSizeLg
                    color: Theme.accent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

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
            }

            RowLayout {
                spacing: Theme.spacingXs

                IconButton {
                    icon: "󰒮"
                    size: 30
                    iconSize: Theme.fontSize
                    enabled: Players.active?.canGoPrevious ?? false
                    opacity: enabled ? 1 : 0.35
                    onClicked: Players.previous()
                }

                IconButton {
                    icon: Players.playing ? "󰏤" : "󰐊"
                    size: 34
                    iconSize: Theme.fontSizeLg
                    active: true
                    iconColor: Theme.accent
                    onClicked: Players.playPause()
                }

                IconButton {
                    icon: "󰒭"
                    size: 30
                    iconSize: Theme.fontSize
                    enabled: Players.active?.canGoNext ?? false
                    opacity: enabled ? 1 : 0.35
                    onClicked: Players.next()
                }
            }
        }

        // ─── Seek ───────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSm
            visible: Players.has && Players.length > 0

            StyledText {
                text: root.clock(Players.position)
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeXs
                color: Theme.faint
            }

            StyledSlider {
                Layout.fillWidth: true
                trackHeight: 3
                value: Players.progress
                enabled: Players.active?.canSeek ?? false
                onMoved: v => Players.seek(v)
            }

            StyledText {
                text: root.clock(Players.length)
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeXs
                color: Theme.faint
            }
        }

        // ─── Volume ─────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSm

            IconButton {
                icon: Audio.icon
                size: 26
                iconSize: Theme.fontSizeSm
                iconColor: Audio.muted ? Theme.faint : Theme.text
                onClicked: Audio.toggleMute()
            }

            StyledSlider {
                Layout.fillWidth: true
                trackHeight: 3
                value: Audio.volume
                fillColor: Audio.muted ? Theme.faint : Theme.accent
                onMoved: v => Audio.setVolume(v)
            }

            IconButton {
                visible: Brightness.available
                icon: Brightness.icon
                size: 26
                iconSize: Theme.fontSizeSm
            }

            StyledSlider {
                Layout.fillWidth: true
                Layout.maximumWidth: 96
                visible: Brightness.available
                trackHeight: 3
                value: Brightness.value
                onMoved: v => Brightness.set(v)
            }
        }

        Separator { Layout.fillWidth: true; Layout.topMargin: Theme.spacingXs }

        // ─── Session ────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingXs

            Repeater {
                model: Session.actions

                delegate: SysButton {
                    required property var modelData

                    Layout.fillWidth: true
                    action: modelData
                }
            }
        }

        // ─── Overflow ───────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingXs

            StyledText {
                Layout.fillWidth: true
                text: Notifications.count > 0
                    ? `${Notifications.count} notification${Notifications.count === 1 ? "" : "s"}`
                    : Network.label
                font.pixelSize: Theme.fontSizeXs
                color: Theme.faint
                elide: Text.ElideRight
            }

            IconButton {
                icon: "󰍡"
                size: 24
                iconSize: Theme.fontSizeSm
                iconColor: Theme.faint
                badge: Notifications.count
                tooltip: "Notifications, network and bluetooth"
                onClicked: {
                    Ui.edgeTo("rest", "");
                    Ui.openControlCenter("home");
                }
            }
        }
    }

    function clock(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }
}
