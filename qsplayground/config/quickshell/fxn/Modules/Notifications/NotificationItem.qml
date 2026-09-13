import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import "root:/Config"
import "root:/Services"
import "root:/Widgets"

Card {
    id: root

    required property var entry
    property bool compact: false

    signal dismissed()
    signal clicked()

    readonly property bool critical: entry?.urgency === NotificationUrgency.Critical

    implicitHeight: layout.implicitHeight + Theme.spacing * 2
    color: Theme.panel
    border.color: root.critical ? Theme.alpha(Theme.error, 0.6) : Theme.borderFaint
    elevated: root.compact

    opacity: 0
    Component.onCompleted: {
        opacity = 1;
        root.updateTime();
    }
    Behavior on opacity {
        NumberAnimation { duration: Theme.durNormal }
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Theme.spacing
        spacing: Theme.spacing

        AppIcon {
            Layout.alignment: Qt.AlignTop
            size: 36
            source: root.entry?.image || root.entry?.appIcon || ""
            fallbackText: root.entry?.appName ?? ""
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingXs

                StyledText {
                    text: root.entry?.appName ?? ""
                    font.pixelSize: Theme.fontSizeXs
                    color: root.critical ? Theme.error : Theme.subtext
                }

                Item { Layout.fillWidth: true }

                StyledText {
                    text: root.timeLabel
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.faint
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.entry?.summary ?? ""
                font.pixelSize: Theme.fontSize
                font.bold: true
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.entry?.body ?? ""
                font.pixelSize: Theme.fontSizeSm
                color: Theme.subtext
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: root.compact ? 3 : 12
                elide: Text.ElideRight
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: Theme.spacingXs
                visible: (root.entry?.actions?.length ?? 0) > 0
                spacing: Theme.spacingXs

                Repeater {
                    model: root.entry?.actions ?? []

                    delegate: Rectangle {
                        required property var modelData

                        implicitWidth: actionLabel.implicitWidth + Theme.spacing * 2
                        implicitHeight: 26
                        radius: Theme.radiusSm
                        color: Theme.alpha(Theme.accent, 0.16)

                        StyledText {
                            id: actionLabel
                            anchors.centerIn: parent
                            text: modelData.text
                            font.pixelSize: Theme.fontSizeSm
                            color: Theme.accent
                        }

                        StateLayer {
                            radius: parent.radius
                            onClicked: {
                                root.entry.invoke(modelData);
                                root.dismissed();
                            }
                        }
                    }
                }
            }
        }

        IconButton {
            Layout.alignment: Qt.AlignTop
            icon: "󰅖"
            iconSize: Theme.fontSizeSm
            size: 22
            iconColor: Theme.faint
            onClicked: root.dismissed()
        }
    }

    StateLayer {
        radius: root.radius
        z: -1
        onClicked: {
            root.clicked();
            root.dismissed();
        }
    }

    /* ─── Relative timestamp ───────────────────────────────── */

    property string timeLabel: ""

    function updateTime(): void {
        if (!root.entry) return;
        const secs = Math.floor((Date.now() - root.entry.time.getTime()) / 1000);
        if (secs < 60)   root.timeLabel = "now";
        else if (secs < 3600) root.timeLabel = Math.floor(secs / 60) + "m";
        else if (secs < 86400) root.timeLabel = Math.floor(secs / 3600) + "h";
        else root.timeLabel = Math.floor(secs / 86400) + "d";
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.updateTime()
    }

    /* ─── Expiry countdown ─────────────────────────────────── */

    Rectangle {
        visible: root.compact && (root.entry?.timeout ?? 0) > 0
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: Theme.radius
        anchors.bottomMargin: 2
        height: 2
        radius: 1
        color: Theme.alpha(Theme.accent, 0.5)

        width: (parent.width - Theme.radius * 2) * countdown.progress

        QtObject {
            id: countdown
            property real progress: 1
        }

        NumberAnimation {
            target: countdown
            property: "progress"
            from: 1
            to: 0
            duration: root.entry?.timeout ?? 0
            running: root.compact && (root.entry?.timeout ?? 0) > 0
        }
    }
}
