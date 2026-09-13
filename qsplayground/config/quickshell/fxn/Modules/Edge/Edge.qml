import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "root:/Config"
import "root:/Services"
import "root:/Widgets"
import "root:/Modules/Launcher"

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: root

        required property ShellScreen modelData

        readonly property bool onThisScreen: {
            const target = Ui.edgeScreen
                || Hyprland.focusedMonitor?.name
                || (Quickshell.screens[0]?.name ?? "");
            return target === root.modelData.name;
        }

        readonly property bool active: Ui.edgeShown && root.onThisScreen
        readonly property bool open:   Ui.edgeOpen && root.active

        readonly property string page: Ui.edgePage
        readonly property bool home: root.open && root.page === "home"
        readonly property bool searching: root.open
            && (root.page === "launcher" || root.page === "wallpaper")

        screen: root.modelData
        visible: Settings.useEdge

        WlrLayershell.namespace: "fxn-edge"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: root.searching ? WlrKeyboardFocus.Exclusive
                                   : root.open      ? WlrKeyboardFocus.OnDemand
                                                    : WlrKeyboardFocus.None

        anchors { top: true; left: true; right: true }
        exclusiveZone: Settings.edgeRestHeight
        implicitHeight: root.open ? root.modelData.height : 380
        color: "transparent"

        /* ─── Geometry ─────────────────────────────────────── */

        readonly property int pillTop: 5
        readonly property int pillW: Settings.edgePillWidth
        readonly property int pillH: 38
        readonly property int panelTop: pillTop + pillH + 8

        readonly property int pageW: root.page === "wallpaper" ? 580
                                   : root.page === "launcher"  ? 520
                                   : Settings.edgePanelWidth
        readonly property int topW: root.searching ? root.pageW : root.pillW
        readonly property int spread: Math.round(root.topW / 2) - 14

        /* ─── Motion ───────────────────────────────────────── */

        property int lastRank: 0
        readonly property int rank: Ui.edgeOpen ? 2 : Ui.edgePeek ? 1 : 0
        onRankChanged: root.lastRank = rank

        readonly property bool opening: root.rank > root.lastRank
        readonly property int dur: root.opening
            ? Settings.edgeDuration
            : Math.round(Settings.edgeDuration * 0.7)

        /* ─── Input region ─────────────────────────────────── */

        mask: Region {
            x: 0
            y: 0
            width: root.width
            height: Settings.edgeRestHeight

            Region {
                intersection: Intersection.Combine
                item: hitbox
            }
        }

        Item {
            id: hitbox

            readonly property int buffer: Settings.edgeHoverBuffer

            x: root.open ? 0 : (root.width - width) / 2
            y: 0
            width: root.open ? root.width
                 : root.active ? root.pillW + buffer * 2
                 : 0
            height: root.open ? root.height
                  : root.active ? root.pillTop + root.pillH + buffer
                  : 0
        }

        /* ─── Hover and dismiss ────────────────────────────── */

        Timer {
            id: closeGrace
            interval: Settings.edgeCloseDelay
            onTriggered: {
                if (Ui.edgePeek && Ui.edgeScreen === root.modelData.name)
                    Ui.edgeTo("rest", "");
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

            onEntered: {
                closeGrace.stop();
                if (Settings.edgePeekOnHover && Ui.edgeRest)
                    Ui.edgeTo("peek", root.modelData.name);
            }
            onExited: {
                if (Ui.edgePeek && Ui.edgeScreen === root.modelData.name)
                    closeGrace.restart();
            }
            onPressed: {
                if (root.open && Settings.edgeClickOutside)
                    Ui.edgeTo("rest", "");
            }
        }

        onOpenChanged: if (root.open) closeGrace.stop()

        FocusScope {
            anchors.fill: parent
            focus: root.home

            Keys.onEscapePressed: Ui.edgeTo("rest", "")
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Space) {
                    Ui.edgeTo("peek", root.modelData.name);
                    event.accepted = true;
                }
            }
        }

        /* ─── Launcher state ───────────────────────────────── */

        LauncherModel {
            id: launcher
            text: search.text
            onDone: Ui.closeLauncher()
        }

        readonly property string searchKey: root.searching ? root.page + ":" + Ui.launcherMode : ""
        onSearchKeyChanged: {
            if (!root.searching) return;
            search.text = root.page === "launcher" ? launcher.prefixFor(Ui.launcherMode) : "";
            launcher.selected = 0;
            launcher.prepare();
            Qt.callLater(search.focusInput);
        }

        /* ─── Segments ─────────────────────────────────────── */

        EdgeSegments {
            id: segments
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.max(0, (Settings.edgeRestHeight - height) / 2)

            screenName: root.modelData.name
            expanded: root.active
            spread: root.spread
            duration: root.dur
        }

        /* ─── Island, or the search field in its place ────── */

        EdgePill {
            id: pill
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.pillTop

            width: root.pillW
            height: root.pillH

            shown: root.active && !root.searching
            duration: root.dur

            onClicked: {
                if (!root.open)
                    Ui.edgePage = "home";
                Ui.edgeTo(root.open ? "peek" : "open", root.modelData.name);
            }
        }

        EdgeSearch {
            id: search
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.pillTop

            width: root.topW
            height: root.pillH

            shown: root.searching
            duration: root.dur

            icon: root.page === "wallpaper" ? "󰸉" : launcher.current.icon
            placeholder: root.page === "wallpaper" ? "Search wallpapers" : launcher.current.placeholder
            trailing: root.page === "wallpaper"
                ? String(walls.shownItems.length)
                : (launcher.listMode && launcher.results.length > 0 ? String(launcher.results.length) : "")

            onNavigate: (dx, dy) => {
                if (root.page === "wallpaper") walls.navigate(dx, dy);
                else launcher.move(dy !== 0 ? dy : dx);
            }
            onAccepted: {
                if (root.page === "wallpaper") walls.activate();
                else launcher.activate();
            }
            onDismissed: Ui.edgeTo("rest", "")

            Behavior on width {
                NumberAnimation { duration: root.dur; easing.type: Easing.OutCubic }
            }
        }

        /* ─── Pages ────────────────────────────────────────── */

        EdgePanel {
            id: panel
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.panelTop

            width: Settings.edgePanelWidth
            shown: root.home
            duration: root.dur
        }

        EdgeResults {
            id: results
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.panelTop

            width: 520
            model: launcher
            maxListHeight: Math.min(360, root.modelData.height - root.panelTop - 120)
            shown: root.open && root.page === "launcher"
            duration: root.dur
        }

        EdgeWallpapers {
            id: walls
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.panelTop

            width: 580
            filter: root.page === "wallpaper" ? search.text : ""
            shown: root.open && root.page === "wallpaper"
            duration: root.dur

            onDone: Ui.closeLauncher()
        }
    }
}
