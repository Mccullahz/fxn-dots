import QtQuick
import QtQuick.Layouts
import Quickshell
import "root:/Config"
import "root:/Services"
import "root:/Widgets"

Card {
    id: root

    required property bool shown
    required property int duration

    signal clicked()

    color: Theme.panel
    border.color: Theme.border
    radius: Theme.radius
    elevated: true
    clip: true

    transformOrigin: Item.Top
    scale: root.shown ? 1 : 0.34
    opacity: root.shown ? 1 : 0
    visible: opacity > 0.01

    Behavior on scale {
        NumberAnimation {
            duration: root.duration
            easing.type: Easing.OutBack
            easing.overshoot: 1.1
        }
    }
    Behavior on opacity {
        NumberAnimation { duration: Math.round(root.duration * 0.6) }
    }

    property real contentOpacity: root.shown ? 1 : 0
    Behavior on contentOpacity {
        SequentialAnimation {
            PauseAnimation { duration: root.shown ? Math.round(root.duration * 0.35) : 0 }
            NumberAnimation { duration: Math.round(root.duration * 0.55) }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacing
        anchors.rightMargin: Theme.spacing
        spacing: Theme.spacingSm
        opacity: root.contentOpacity

        StyledText {
            text: Qt.formatDateTime(clock.date, Settings.clockFormat)
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSizeSm
        }

        StyledText {
            text: "·"
            color: Theme.faint
        }

        // ─── Now playing ────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingXs
            visible: Players.has

            Waveform {
                playing: Players.playing
                color: Theme.accent
            }

            StyledText {
                Layout.fillWidth: true
                text: Players.summary
                font.pixelSize: Theme.fontSizeSm
                elide: Text.ElideRight
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: !Players.has
            text: SysInfo.uptime ? "up " + SysInfo.uptime : ""
            font.pixelSize: Theme.fontSizeSm
            color: Theme.faint
            elide: Text.ElideRight
        }

        // ─── Status ─────────────────────────────────────────
        RowLayout {
            spacing: Theme.spacingSm

            Icon {
                text: Network.icon
                size: Theme.fontSizeSm
                color: Network.connected ? Theme.subtext : Theme.faint
            }

            Icon {
                visible: BluetoothSvc.primary !== null
                text: BluetoothSvc.icon
                size: Theme.fontSizeSm
                color: Theme.accent
            }

            StyledText {
                text: Math.round(Audio.volume * 100) + "%"
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeXs
                color: Audio.muted ? Theme.faint : Theme.subtext
            }

            RowLayout {
                spacing: 3
                visible: Battery.available

                Icon {
                    text: Battery.icon
                    size: Theme.fontSizeSm
                    color: Battery.tint
                }

                StyledText {
                    text: Math.round(Battery.percent * 100) + "%"
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeXs
                    color: Battery.tint
                }
            }
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    StateLayer {
        radius: root.radius
        showState: false
        enabled: root.shown
        onClicked: root.clicked()
    }
}
