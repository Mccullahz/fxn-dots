import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "root:/Config"
import "root:/Services"
import "root:/Widgets"

/*!
    wlogout replacement.
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

    screen: root.focused
    visible: Ui.powerMenuOpen

    WlrLayershell.namespace: "fxn-powermenu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"

    property int selected: 0
    property bool confirming: false

    readonly property var hints: ({
        lock:      { key: "l", hint: "Ctrl+Alt+L" },
        logout:    { key: "e", hint: "end session" },
        sleep:     { key: "s", hint: "sleep to RAM" },
        hibernate: { key: "h", hint: "sleep to disk" },
        reboot:    { key: "r", hint: "restart now" },
        poweroff:  { key: "p", hint: "power off" }
    })

    readonly property var actions: Session.actions.map(a => ({
        id: a.id,
        icon: a.icon,
        label: a.label,
        confirm: a.confirm,
        key: root.hints[a.id]?.key ?? "",
        hint: root.hints[a.id]?.hint ?? ""
    }))

    onVisibleChanged: {
        if (visible) {
            root.selected = 0;
            root.confirming = false;
            focusScope.forceActiveFocus();
        }
    }

    function close(): void {
        Ui.powerMenuOpen = false;
    }

    function run(index: int): void {
        const action = root.actions[index];
        if (!action) return;

        if (action.confirm && !root.confirming) {
            root.selected = index;
            root.confirming = true;
            return;
        }

        root.close();
        Session.run(action.id);
    }

    function move(delta: int): void {
        root.confirming = false;
        const n = root.actions.length;
        root.selected = (root.selected + delta + n) % n;
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    FocusScope {
        id: focusScope
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: root.confirming ? root.confirming = false : root.close()
        Keys.onLeftPressed: root.move(-1)
        Keys.onRightPressed: root.move(1)
        Keys.onUpPressed: root.move(-3)
        Keys.onDownPressed: root.move(3)
        Keys.onReturnPressed: root.run(root.selected)
        Keys.onEnterPressed: root.run(root.selected)

        Keys.onPressed: event => {
            const ch = event.text.toLowerCase();
            for (let i = 0; i < root.actions.length; i++) {
                if (root.actions[i].key === ch) {
                    root.selected = i;
                    root.confirming = false;
                    event.accepted = true;
                    return;
                }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Theme.spacingXl

            GridLayout {
                Layout.alignment: Qt.AlignHCenter
                columns: 3
                columnSpacing: Theme.spacing
                rowSpacing: Theme.spacing

                Repeater {
                    model: root.actions

                    delegate: Card {
                        id: tile

                        required property int index
                        required property var modelData

                        readonly property bool current: root.selected === tile.index
                        readonly property bool armed: tile.current && root.confirming

                        implicitWidth: 160
                        implicitHeight: 130
                        radius: Theme.radiusLg
                        elevated: true

                        color: tile.armed   ? Theme.alpha(Theme.error, 0.25)
                             : tile.current ? Theme.alpha(Theme.accent, 0.22)
                                            : Theme.panel
                        border.color: tile.armed   ? Theme.error
                                    : tile.current ? Theme.accent
                                                   : Theme.borderFaint
                        border.width: tile.current ? 2 : 1

                        scale: tile.current ? 1.04 : 1

                        Behavior on color { ColorAnimation { duration: Theme.durFast } }
                        Behavior on scale {
                            NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easeEmphasized }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: Theme.spacingSm

                            Icon {
                                Layout.alignment: Qt.AlignHCenter
                                text: tile.modelData.icon
                                size: 38
                                color: tile.armed   ? Theme.error
                                     : tile.current ? Theme.accent
                                                    : Theme.text
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: tile.armed ? "Press ↵ again" : tile.modelData.label
                                font.pixelSize: Theme.fontSize
                                font.bold: tile.current
                                color: tile.armed ? Theme.error : Theme.text
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: tile.modelData.hint
                                font.pixelSize: Theme.fontSizeXs
                                color: Theme.faint
                            }
                        }

                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.margins: Theme.spacingSm
                            implicitWidth: 18
                            implicitHeight: 18
                            radius: 4
                            color: Theme.alpha(Theme.foreground, 0.10)

                            StyledText {
                                anchors.centerIn: parent
                                text: tile.modelData.key.toUpperCase()
                                font.pixelSize: Theme.fontSizeXs
                                color: Theme.faint
                            }
                        }

                        StateLayer {
                            radius: tile.radius
                            showState: false
                            onContainsMouseChanged: if (containsMouse) {
                                root.selected = tile.index;
                                root.confirming = false;
                            }
                            onClicked: root.run(tile.index)
                        }
                    }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Battery.available
                    ? `${Battery.statusText}   ·   esc to cancel`
                    : "esc to cancel"
                color: Theme.faint
                font.pixelSize: Theme.fontSizeSm
            }
        }
    }
}
