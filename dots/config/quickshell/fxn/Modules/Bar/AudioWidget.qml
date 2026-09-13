import QtQuick
import QtQuick.Layouts
import Quickshell
import "root:/Config"
import "root:/Services"
import "root:/Widgets"

/*! Volume readout. Scroll to change, click to mute, right click for pvcontrol. */
Item {
    id: root

    visible: Audio.ready
    implicitWidth: row.implicitWidth + Theme.spacingSm * 2
    implicitHeight: parent?.height ?? 28

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.spacingXs

        Icon {
            text: Audio.icon
            size: Theme.fontSize
            color: Audio.muted ? Theme.faint : Theme.text
        }

        StyledText {
            text: Math.round(Audio.volume * 100) + "%"
            font.pixelSize: Theme.fontSizeSm
            color: Audio.muted ? Theme.faint : Theme.text
        }

        Icon {
            visible: Audio.sourceReady && Audio.micMuted
            text: Audio.micIcon
            size: Theme.fontSizeSm
            color: Theme.error
        }
    }

    StateLayer {
        id: state
        radius: Theme.radiusSm
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: mouse => {
            switch (mouse.button) {
            case Qt.RightButton:  Quickshell.execDetached(["pavucontrol"]); break;
            case Qt.MiddleButton: Audio.toggleMicMute(); break;
            default:              Audio.toggleMute();
            }
        }

        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) Audio.volumeUp();
            else Audio.volumeDown();
        }
    }

    Tooltip {
        target: root
        hovered: state.containsMouse
        text: `${Audio.sinkName}\n${Math.round(Audio.volume * 100)}%` +
              (Audio.muted ? " (muted)" : "") +
              `\nMic: ${Audio.micMuted ? "muted" : Math.round(Audio.micVolume * 100) + "%"}` +
              "\nScroll: volume · Click: mute · Middle: mic · Right: pavucontrol"
    }
}
