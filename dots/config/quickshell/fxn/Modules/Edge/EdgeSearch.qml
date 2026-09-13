import QtQuick
import QtQuick.Layouts
import Quickshell
import "root:/Config"
import "root:/Widgets"

Card {
    id: root

    required property bool shown
    required property int duration

    property string icon: "󰍉"
    property string placeholder: "Search"
    property string trailing: ""
    property alias text: input.text

    signal navigate(int dx, int dy)
    signal accepted()
    signal dismissed()

    function focusInput(): void {
        input.forceActiveFocus();
        input.cursorPosition = input.text.length;
    }

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
        NumberAnimation { duration: root.duration; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
    }
    Behavior on opacity {
        NumberAnimation { duration: Math.round(root.duration * 0.6) }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacing
        anchors.rightMargin: Theme.spacing
        spacing: Theme.spacingSm

        Icon {
            text: root.icon
            size: Theme.fontSizeLg
            color: Theme.accent
        }

        TextInput {
            id: input

            Layout.fillWidth: true
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            selectByMouse: true
            selectionColor: Theme.alpha(Theme.accent, 0.4)
            selectedTextColor: Theme.text
            clip: true

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text === ""
                text: root.placeholder
                color: Theme.faint
                font.pixelSize: Theme.fontSize
            }

            Keys.onEscapePressed: root.dismissed()
            Keys.onReturnPressed: root.accepted()
            Keys.onEnterPressed: root.accepted()
            Keys.onUpPressed: root.navigate(0, -1)
            Keys.onDownPressed: root.navigate(0, 1)

            Keys.onPressed: event => {
                const ctrl = event.modifiers & Qt.ControlModifier;
                const empty = input.text === "";
                if (event.key === Qt.Key_Tab) {
                    root.navigate(1, 0);
                } else if (event.key === Qt.Key_Backtab) {
                    root.navigate(-1, 0);
                } else if (ctrl && event.key === Qt.Key_N) {
                    root.navigate(0, 1);
                } else if (ctrl && event.key === Qt.Key_P) {
                    root.navigate(0, -1);
                } else if (empty && event.key === Qt.Key_Left) {
                    root.navigate(-1, 0);
                } else if (empty && event.key === Qt.Key_Right) {
                    root.navigate(1, 0);
                } else {
                    return;
                }
                event.accepted = true;
            }
        }

        StyledText {
            visible: root.trailing !== ""
            text: root.trailing
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSizeXs
            color: Theme.faint
        }
    }
}
