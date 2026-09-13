import QtQuick
import QtQuick.Layouts
import "root:/Config"
import "root:/Services"
import "root:/Widgets"

/*!
    system session action.

    destructive actions arm on first press and fire on the second, so a misinput
    doesn't immediately log you out or power off your machine
*/
Rectangle {
    id: root

    required property var action

    property bool armed: false

    implicitHeight: 50
    radius: Theme.radiusSm

    color: root.armed ? Theme.alpha(Theme.error, 0.28)
                      : Theme.alpha(Theme.foreground, 0.05)

    Behavior on color {
        ColorAnimation { duration: Theme.durFast }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 3

        Icon {
            Layout.alignment: Qt.AlignHCenter
            text: root.action.icon
            size: Theme.fontSizeLg
            color: root.armed ? Theme.error : Theme.subtext
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: root.armed ? "Sure?" : root.action.label
            font.pixelSize: Theme.fontSizeXs
            color: root.armed ? Theme.error : Theme.subtext
        }
    }

    Timer {
        id: disarm
        interval: 2600
        onTriggered: root.armed = false
    }

    StateLayer {
        radius: root.radius
        tint: root.action.confirm ? Theme.error : Theme.foreground

        onClicked: {
            if (!root.action.confirm || root.armed) {
                disarm.stop();
                Session.run(root.action.id);
                return;
            }
            root.armed = true;
            disarm.restart();
        }
    }
}
