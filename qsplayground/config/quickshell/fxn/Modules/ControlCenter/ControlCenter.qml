import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "root:/Config"
import "root:/Services"
import "root:/Widgets"
import "root:/Modules/Notifications"

/*!
    replacemnet for swaync's control center
*/
PanelWindow {
    id: root

    readonly property ShellScreen focused: {
        const name = Hyprland.focusedMonitor?.name;
        if (name)
            for (const s of Quickshell.screens)
                if (s.name === name) return s;
        return Quickshell.screens[0] ?? null;
    }

    /*! Open state. The window outlives it by the length of the closing
        animation, so the panel leaves rather than vanishing. */
    readonly property bool shown: Ui.controlCenterOpen

    /*! The edge's timing: leaving takes 70% of the time arriving does. */
    readonly property int dur: root.shown
        ? Settings.edgeDuration
        : Math.round(Settings.edgeDuration * 0.7)

    screen: root.focused
    visible: root.shown || panel.opacity > 0.01

    // Anything still popped up is in the list below; don't keep it
    // waiting to reappear when the panel closes.
    onShownChanged: if (root.shown) Notifications.dismissAllPopups()

    WlrLayershell.namespace: "fxn-controlcenter"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"

    // subscribe pollers only while the panel is up.
    onVisibleChanged: {
        if (visible) {
            Network.subscribed++;
            BluetoothSvc.subscribed++;
            SysInfo.subscribed++;
        } else {
            Network.subscribed--;
            BluetoothSvc.subscribed--;
            SysInfo.subscribed--;
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.shown
        onClicked: Ui.controlCenterOpen = false
    }

    Card {
        id: panel

        /*! With the edge, the panel drops from the top-right corner the
            way the dashboard drops from the island. With the bar, it sits
            against whichever edge the bar is on. */
        readonly property bool fromTop: Settings.useEdge || Settings.barPosition === "top"
        readonly property int gap: Settings.useEdge
            ? Settings.edgeRestHeight + Theme.spacingSm
            : Settings.barHeight + Settings.barMargin + Theme.spacingSm

        width: 420
        anchors.right: parent.right
        anchors.rightMargin: Settings.useEdge ? Theme.spacingSm : Theme.spacing
        anchors.top: panel.fromTop ? parent.top : undefined
        anchors.bottom: panel.fromTop ? undefined : parent.bottom
        anchors.topMargin: panel.gap
        anchors.bottomMargin: panel.gap

        // Content plus its margins, capped to what the screen leaves.
        // implicitHeight alone leaves the margins out, which squeezed the
        // layout and pushed the notification list out past the bottom.
        height: Math.min(content.implicitHeight + Theme.spacingLg * 2,
                         parent.height - panel.gap - Theme.spacing)

        color: Theme.panel
        border.color: Theme.border
        radius: Theme.radiusLg
        elevated: true
        clip: true

        transformOrigin: panel.fromTop ? Item.TopRight : Item.BottomRight
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.97
        transform: Translate {
            y: root.shown ? 0 : (panel.fromTop ? -14 : 14)
            Behavior on y {
                NumberAnimation { duration: root.dur; easing.type: Easing.OutCubic }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: Math.round(root.dur * 0.7) }
        }
        Behavior on scale {
            NumberAnimation { duration: root.dur; easing.type: Easing.OutCubic }
        }

        // intentionally swallow clicks so they don't reach the dismiss layer behind.
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: Theme.spacingLg
            spacing: Theme.spacing

            Header {
                Layout.fillWidth: true
            }

            // ─── Page switcher ──────────────────────────────
            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true

                sourceComponent: {
                    switch (Ui.controlCenterPage) {
                    case "network":   return networkPage;
                    case "bluetooth": return bluetoothPage;
                    default:          return homePage;
                    }
                }
            }

            Component {
                id: homePage

                ColumnLayout {
                    spacing: Theme.spacing

                    QuickToggles { Layout.fillWidth: true }

                    Sliders { Layout.fillWidth: true }

                    MediaCard {
                        Layout.fillWidth: true
                        visible: Players.has
                    }

                    NotificationHistory {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }
            }

            Component {
                id: networkPage
                NetworkPage {}
            }

            Component {
                id: bluetoothPage
                BluetoothPage {}
            }
        }
    }
}
