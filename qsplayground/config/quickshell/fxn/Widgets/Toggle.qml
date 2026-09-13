import QtQuick
import "root:/Config"

Item {
    id: root

    property bool checked: false

    signal toggled(bool value)

    implicitWidth: 42
    implicitHeight: 24
    opacity: root.enabled ? 1 : 0.4

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.accent : Theme.alpha(Theme.foreground, 0.18)

        Behavior on color {
            ColorAnimation { duration: Theme.durNormal; easing.type: Theme.easeStandard }
        }
    }

    Rectangle {
        id: knob
        width: parent.height - 6
        height: width
        radius: width / 2
        y: 3
        x: root.checked ? parent.width - width - 3 : 3
        color: root.checked ? Theme.onAccent : Theme.foreground

        Behavior on x {
            NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easeEmphasized }
        }
        Behavior on color {
            ColorAnimation { duration: Theme.durNormal }
        }
    }

    StateLayer {
        radius: height / 2
        enabled: root.enabled
        showState: false
        onClicked: {
            root.checked = !root.checked;
            root.toggled(root.checked);
        }
    }
}
