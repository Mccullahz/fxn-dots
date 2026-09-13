import QtQuick
import QtQuick.Layouts
import Quickshell
import "root:/Config"
import "root:/Widgets"
import "root:/Modules/Launcher"

Card {
    id: root

    required property var model        // LauncherModel
    required property bool shown
    required property int duration

    property int maxListHeight: 360

    implicitHeight: layout.implicitHeight + Theme.spacingSm * 2

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
    Behavior on implicitHeight {
        NumberAnimation { duration: Theme.durFast; easing.type: Easing.OutCubic }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Theme.spacingSm
        spacing: 0

        CalcResult {
            Layout.fillWidth: true
            visible: root.model.mode === "calc"
            expression: root.model.queryText
        }

        WebResult {
            Layout.fillWidth: true
            visible: root.model.mode === "web" && root.model.queryText !== ""
            url: root.model.queryText ? root.model.webUrl(root.model.queryText) : ""
            term: root.model.queryText
        }

        ListView {
            id: list

            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, Math.floor(root.maxListHeight / 48) * 48)

            visible: root.model.listMode && root.model.results.length > 0
            model: root.model.results
            currentIndex: root.model.selected
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: 200
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            delegate: LauncherRow {
                required property int index
                required property var modelData

                width: list.width
                mode: root.model.mode
                item: modelData
                selected: index === root.model.selected

                onHovered: root.model.selected = index
                onActivated: root.model.activateAt(index)
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.margins: Theme.spacingLg
            visible: root.model.listMode && root.model.results.length === 0
            text: root.model.queryText ? "No matches" : "Start typing"
            horizontalAlignment: Text.AlignHCenter
            color: Theme.faint
            font.pixelSize: Theme.fontSizeSm
        }

        Separator {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacingXs
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.spacingXs
            spacing: Theme.spacing

            Repeater {
                model: [
                    { p: "=", n: "calc" },
                    { p: ":", n: "emoji" },
                    { p: "?", n: "web" },
                    { p: "#", n: "clipboard" }
                ]

                delegate: RowLayout {
                    required property var modelData
                    spacing: 4

                    Rectangle {
                        implicitWidth: 16
                        implicitHeight: 16
                        radius: 4
                        color: Theme.alpha(Theme.foreground, 0.10)

                        StyledText {
                            anchors.centerIn: parent
                            text: modelData.p
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.subtext
                        }
                    }

                    StyledText {
                        text: modelData.n
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.faint
                    }
                }
            }

            Item { Layout.fillWidth: true }

            StyledText {
                text: "esc"
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeXs
                color: Theme.faint
            }
        }
    }
}
