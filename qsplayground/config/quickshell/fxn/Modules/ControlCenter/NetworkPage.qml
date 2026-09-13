import QtQuick
import QtQuick.Layouts
import "root:/Config"
import "root:/Services"
import "root:/Widgets"

/*! network list with inline password entry. */
ColumnLayout {
    id: root

    property string promptFor: ""

    spacing: Theme.spacingSm

    RowLayout {
        Layout.fillWidth: true

        Toggle {
            checked: Network.wifiEnabled
            onToggled: Network.toggleWifi()
        }

        StyledText {
            text: Network.wifiEnabled ? "Wi-Fi on" : "Wi-Fi off"
            font.pixelSize: Theme.fontSizeSm
            color: Theme.subtext
        }

        Item { Layout.fillWidth: true }

        IconButton {
            icon: "󰑐"
            size: 26
            iconSize: Theme.fontSizeSm
            tooltip: "Rescan"
            onClicked: Network.scan()
        }

        IconButton {
            icon: "󰒓"
            size: 26
            iconSize: Theme.fontSizeSm
            tooltip: "Open NetworkManager editor"
            onClicked: Network.openSettings()
        }
    }

    StyledScroll {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 200

        contentHeight: list.implicitHeight

        Column {
            id: list
            width: parent.width
            spacing: 2

            Repeater {
                model: Network.networks

                delegate: Rectangle {
                    id: apRow

                    required property var modelData

                    readonly property bool prompting: root.promptFor === apRow.modelData.ssid

                    width: list.width
                    implicitHeight: apRow.prompting ? 88 : 46
                    radius: Theme.radiusSm
                    color: apRow.modelData.active
                        ? Theme.alpha(Theme.accent, 0.16)
                        : "transparent"

                    Behavior on implicitHeight {
                        NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easeStandard }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingSm
                        spacing: Theme.spacingXs

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingSm

                            Icon {
                                text: {
                                    const s = apRow.modelData.strength;
                                    if (s >= 80) return "󰤨";
                                    if (s >= 55) return "󰤥";
                                    if (s >= 30) return "󰤢";
                                    if (s >= 10) return "󰤟";
                                    return "󰤯";
                                }
                                size: Theme.fontSize
                                color: apRow.modelData.active ? Theme.accent : Theme.subtext
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: apRow.modelData.ssid
                                font.pixelSize: Theme.fontSizeSm
                                elide: Text.ElideRight
                            }

                            Icon {
                                visible: apRow.modelData.security !== ""
                                text: "󰌾"
                                size: Theme.fontSizeXs
                                color: Theme.faint
                            }

                            StyledText {
                                visible: apRow.modelData.active
                                text: "connected"
                                font.pixelSize: Theme.fontSizeXs
                                color: Theme.accent
                            }

                            IconButton {
                                visible: apRow.modelData.known && !apRow.modelData.active
                                icon: "󰆴"
                                size: 22
                                iconSize: Theme.fontSizeXs
                                iconColor: Theme.faint
                                tooltip: "Forget"
                                onClicked: Network.forget(apRow.modelData.ssid)
                            }
                        }

                        // inline password field for unknown secured networks.
                        RowLayout {
                            Layout.fillWidth: true
                            visible: apRow.prompting
                            spacing: Theme.spacingSm

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 30
                                radius: Theme.radiusSm
                                color: Theme.alpha(Theme.foreground, 0.08)

                                TextInput {
                                    id: password
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.spacingSm
                                    anchors.rightMargin: Theme.spacingSm
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                    echoMode: TextInput.Password
                                    selectByMouse: true

                                    onAccepted: {
                                        Network.connect(apRow.modelData.ssid, text);
                                        text = "";
                                        root.promptFor = "";
                                    }
                                    Keys.onEscapePressed: root.promptFor = ""
                                }
                            }

                            IconButton {
                                icon: "󰄾"
                                size: 28
                                iconColor: Theme.accent
                                onClicked: {
                                    Network.connect(apRow.modelData.ssid, password.text);
                                    password.text = "";
                                    root.promptFor = "";
                                }
                            }
                        }
                    }

                    StateLayer {
                        radius: apRow.radius
                        enabled: !apRow.prompting
                        onClicked: {
                            if (apRow.modelData.active) {
                                Network.disconnect();
                            } else if (apRow.modelData.known || apRow.modelData.security === "") {
                                Network.connect(apRow.modelData.ssid, "");
                            } else {
                                root.promptFor = apRow.modelData.ssid;
                                password.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: Network.networks.length === 0
        text: Network.wifiEnabled ? "Scanning…" : "Wi-Fi is off"
        horizontalAlignment: Text.AlignHCenter
        color: Theme.faint
        font.pixelSize: Theme.fontSizeSm
    }
}
