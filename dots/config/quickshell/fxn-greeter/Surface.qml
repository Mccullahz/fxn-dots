import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

/*!
    One screen of the login screen. Every value here is lifted from
    hypr/hyprlock.conf — keep the two in step. hyprlock measures y from
    the centre with positive up; Qt's offsets point down, hence the
    flipped signs. Its font sizes are points, so they stay points here.
*/
PanelWindow {
    id: win

    required property var greeter
    property bool primary: false

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: greeter.bg

    WlrLayershell.namespace: "fxn-greeter"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: primary ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Item {
        id: content
        anchors.fill: parent
        focus: win.primary

        // animation = fadeIn, 1, 3, settle
        opacity: 0
        Component.onCompleted: opacity = 1
        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        Keys.onPressed: event => {
            const g = win.greeter;
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                g.submit();
            } else if (event.key === Qt.Key_Backspace) {
                g.erase(event.modifiers & Qt.ControlModifier);
            } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Down) {
                g.cycleUser(1);
            } else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Up) {
                g.cycleUser(-1);
            } else if (event.key === Qt.Key_Escape) {
                if (g.preview) Qt.quit();
                else g.erase(true);
            } else if (event.text.length > 0 && event.text.charCodeAt(0) >= 32) {
                g.type(event.text);
            } else {
                return;
            }
            event.accepted = true;
        }

        /* ─── background ─────────────────────────────────────── */

        Image {
            id: wall
            anchors.fill: parent
            source: win.greeter.wallpaper
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(win.width, win.height)
            asynchronous: true
            visible: false
        }

        // blur_passes = 2, blur_size = 4
        MultiEffect {
            anchors.fill: parent
            source: wall
            visible: wall.status === Image.Ready
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 0.6
            blurMax: 32
        }

        // brightness = 0.62
        Rectangle {
            anchors.fill: parent
            visible: wall.status === Image.Ready
            color: "black"
            opacity: 0.38
        }

        /* ─── time and date ──────────────────────────────────── */

        property date now: new Date()

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: content.now = new Date()
        }

        // date +"%-I:%M"
        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -150
            text: (content.now.getHours() % 12 || 12) + ":"
                  + String(content.now.getMinutes()).padStart(2, "0")
            color: win.greeter.fg
            font.family: win.greeter.font
            font.weight: Font.ExtraBold
            font.pointSize: 92
        }

        // date +"%A, %-d %B"
        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -68
            text: Qt.formatDate(content.now, "dddd, d MMMM")
            color: win.greeter.muted
            font.family: win.greeter.font
            font.pointSize: 15
        }

        /* ─── password ───────────────────────────────────────── */

        Rectangle {
            id: field
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 24
            width: parent.width * 0.22     // size = 22%, 6%
            height: parent.height * 0.06
            radius: height / 2             // rounding = -1

            color: Qt.rgba(win.greeter.surface.r, win.greeter.surface.g,
                           win.greeter.surface.b, 0.85)   // $surface_glass
            border.width: 2
            border.color: win.greeter.failText ? win.greeter.error
                        : win.greeter.checking ? win.greeter.accentAlt
                                               : win.greeter.accent
            Behavior on border.color { ColorAnimation { duration: 200 } }

            readonly property real dot: height * 0.22       // dots_size
            readonly property int fits:
                Math.floor((width - height) / (dot * 1.35))

            // dots_center = true, dots_spacing = 0.35
            Row {
                anchors.centerIn: parent
                spacing: field.dot * 0.35
                visible: !win.greeter.askingUser

                Repeater {
                    model: Math.min(win.greeter.buffer.length, field.fits)

                    Rectangle {
                        width: field.dot
                        height: field.dot
                        radius: field.dot / 2
                        color: win.greeter.fg

                        // animation = inputFieldDots, 1, 2, settle
                        scale: 0
                        Component.onCompleted: scale = 1
                        Behavior on scale {
                            NumberAnimation { duration: 200; easing.type: Easing.OutBack }
                        }
                    }
                }
            }

            // The name step echoes what is typed.
            Text {
                anchors.centerIn: parent
                width: parent.width - parent.height
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideLeft
                visible: win.greeter.askingUser
                text: win.greeter.buffer
                color: win.greeter.fg
                font.family: win.greeter.font
                font.pointSize: 13
            }

            // placeholder_text, then fail_text in its place
            Text {
                anchors.centerIn: parent
                visible: win.greeter.buffer === ""
                text: win.greeter.failText
                      || (win.greeter.askingUser ? "username" : "password")
                color: win.greeter.failText ? win.greeter.error : win.greeter.muted
                font.family: win.greeter.font
                font.italic: !win.greeter.failText
                font.pointSize: 13
            }
        }

        /* ─── user ───────────────────────────────────────────── */
        // Not in hyprlock: a lock screen knows whose session it is.
        // Always shown, so it is never a guess whose password is wanted.

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: field.bottom
            anchors.topMargin: 18
            spacing: 14
            visible: !win.greeter.askingUser

            component Chevron: Text {
                id: chev
                property int step
                visible: win.greeter.users.length > 1
                color: chevMouse.containsMouse ? win.greeter.fg : win.greeter.muted
                font.family: win.greeter.font
                font.pointSize: 13
                Behavior on color { ColorAnimation { duration: 120 } }

                MouseArea {
                    id: chevMouse
                    anchors.fill: parent
                    anchors.margins: -8
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.greeter.cycleUser(chev.step)
                }
            }

            Chevron { text: "󰅁"; step: -1 }

            Text {
                text: "󰀄  " + win.greeter.user
                color: win.greeter.fg
                font.family: win.greeter.font
                font.pointSize: 13
            }

            Chevron { text: "󰅂"; step: 1 }
        }

        /* ─── status ─────────────────────────────────────────── */

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 28
            text: win.greeter.status
            color: win.greeter.muted
            font.family: win.greeter.font
            font.pointSize: 12
        }

        /* ─── power ──────────────────────────────────────────── */
        // The one thing a login screen needs that a lock screen
        // doesn't: a way out without logging in.

        Row {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 28
            spacing: 18

            Repeater {
                model: [
                    { icon: "󰜉", cmd: ["systemctl", "reboot"] },
                    { icon: "󰐥", cmd: ["systemctl", "poweroff"] }
                ]

                Text {
                    required property var modelData
                    text: modelData.icon
                    color: mouse.containsMouse ? win.greeter.fg : win.greeter.muted
                    font.family: win.greeter.font
                    font.pointSize: 16
                    Behavior on color { ColorAnimation { duration: 120 } }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (!win.greeter.preview) power.exec(modelData.cmd)
                    }
                }
            }
        }

        Process { id: power }
    }
}
