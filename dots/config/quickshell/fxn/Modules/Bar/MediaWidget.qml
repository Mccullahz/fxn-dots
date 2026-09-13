import QtQuick
import QtQuick.Layouts
import Quickshell
import "root:/Config"
import "root:/Services"
import "root:/Widgets"

/*!
    now-playing indicator.

    left click toggles playback, side buttons skip, scroll changes volume — matching the mpris module this replaces. collapses to zero width when nothing is playing.
*/
Item {
    id: root

    visible: Players.has
    implicitWidth: Players.has ? Math.min(row.implicitWidth + Theme.spacingSm * 2, 260) : 0
    implicitHeight: parent?.height ?? 28

    Behavior on implicitWidth {
        NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easeStandard }
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingSm
        anchors.rightMargin: Theme.spacingSm
        spacing: Theme.spacingXs

        Icon {
            text: Players.icon
            size: Theme.fontSize
            color: Players.playing ? Theme.accent : Theme.subtext
        }

        StyledText {
            Layout.fillWidth: true
            text: Players.summary
            font.pixelSize: Theme.fontSizeSm
            font.italic: !Players.playing
            color: Players.playing ? Theme.text : Theme.subtext
            elide: Text.ElideRight
        }
    }

    StateLayer {
        id: state
        radius: Theme.radiusSm
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: mouse => {
            switch (mouse.button) {
            case Qt.RightButton:  Players.next(); break;
            case Qt.MiddleButton: Players.playPause(); break;
            default:              Players.playPause();
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
        text: Players.has
            ? `${Players.statusIcon}  ${Players.summary}\n${Players.identity}\n` +
              "Click: play/pause · Right: next · Scroll: volume"
            : ""
    }
}
