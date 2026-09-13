import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "root:/Config"
import "root:/Services"
import "root:/Widgets"

/*!
    volume / brightness / mic on-screen display
*/
PanelWindow {
    id: root

    property string kind: "volume"
    property bool showing: false

    readonly property ShellScreen focused: {
        const name = Hyprland.focusedMonitor?.name;
        if (name)
            for (const s of Quickshell.screens)
                if (s.name === name) return s;
        return Quickshell.screens[0] ?? null;
    }

    screen: root.focused
    visible: root.showing

    WlrLayershell.namespace: "fxn-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors.bottom: true
    margins.bottom: 140
    exclusiveZone: 0

    implicitWidth: 300
    implicitHeight: 64
    color: "transparent"

    /* ─── Content ──────────────────────────────────────────── */

    readonly property real level: {
        switch (root.kind) {
        case "volume":
        case "mute":    return Audio.volume;
        case "mic":
        case "micMute": return Audio.micVolume;
        case "kbd":     return Brightness.kbdValue;
        default:        return Brightness.value;
        }
    }

    readonly property bool off: {
        switch (root.kind) {
        case "volume":
        case "mute":    return Audio.muted;
        case "mic":
        case "micMute": return Audio.micMuted;
        default:        return false;
        }
    }

    readonly property string glyph: {
        switch (root.kind) {
        case "volume":
        case "mute":    return Audio.icon;
        case "mic":
        case "micMute": return Audio.micIcon;
        case "kbd":     return "󰌌";
        default:        return Brightness.icon;
        }
    }

    readonly property string caption: {
        switch (root.kind) {
        case "volume":
        case "mute":    return "Volume";
        case "mic":
        case "micMute": return "Microphone";
        case "kbd":     return "Keyboard";
        default:        return "Brightness";
        }
    }

    Card {
        id: card
        anchors.fill: parent
        color: Theme.panel
        border.color: Theme.border
        radius: Theme.radiusLg
        elevated: true

        opacity: root.showing ? 1 : 0.9
        scale: root.showing ? 1 : 0.92

        Behavior on opacity {
            NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easeStandard }
        }
        Behavior on scale {
            NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easeEmphasized }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingLg
            spacing: Theme.spacing

            Icon {
                text: root.glyph
                size: Theme.fontSizeXl
                color: root.off ? Theme.faint : Theme.accent
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingXs

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        text: root.caption
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.subtext
                    }

                    Item { Layout.fillWidth: true }

                    StyledText {
                        text: root.off ? "muted" : Math.round(root.level * 100) + "%"
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.subtext
                    }
                }

                StyledSlider {
                    Layout.fillWidth: true
                    value: root.off ? 0 : root.level
                    enabled: false
                    fillColor: root.off ? Theme.faint : Theme.accent
                }
            }
        }
    }

    /* ─── Triggers ─────────────────────────────────────────── */

    Timer {
        id: hideTimer
        interval: Settings.osdTimeout
        onTriggered: root.showing = false
    }

    function show(kind: string): void {
        root.kind = kind;
        root.showing = true;
        hideTimer.restart();
    }

    Connections {
        target: Audio
        function onChanged(kind: string): void { root.show(kind); }
    }

    Connections {
        target: Brightness
        function onChanged(kind: string): void { root.show(kind); }
    }
}
