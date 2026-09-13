import QtQuick
import Quickshell
import Quickshell.Hyprland
import "root:/Config"
import "root:/Widgets"

/*!
    resting state
*/
Item {
    id: root

    required property string screenName
    required property bool expanded
    required property int spread
    required property int duration

    readonly property int count: Settings.workspaceCount
    readonly property int segW: Settings.edgeSegmentWidth
    readonly property int gap: Settings.edgeSegmentGap

    implicitWidth: root.count * root.segW + (root.count - 1) * root.gap
    implicitHeight: 3

    /*! Live workspace state, keyed by id. */
    readonly property var occupancy: {
        const map = {};
        for (const ws of Hyprland.workspaces.values) {
            if (ws.id < 1 || ws.id > root.count) continue;
            map[ws.id] = {
                has: (ws.toplevels?.values?.length ?? 0) > 0,
                focused: ws.id === Hyprland.focusedWorkspace?.id,
                urgent: ws.urgent ?? false
            };
        }
        return map;
    }

    Repeater {
        model: root.count

        delegate: Rectangle {
            id: seg

            required property int index

            readonly property int slot: seg.index - Math.floor(root.count / 2)
            readonly property var state: root.occupancy[seg.index + 1] ?? null
            readonly property bool middle: seg.slot === 0

            /*! Outer segments slide away from centre; the middle one
                stays put and collapses instead, so the gap reads as
                opening rather than as the bar vanishing. */
            readonly property int travel: root.expanded && !seg.middle
                ? (seg.slot < 0 ? -root.spread : root.spread)
                : 0

            x: (root.width - width) / 2
                + seg.slot * (root.segW + root.gap)
                + seg.travel
            y: 0

            width: (seg.state?.focused ?? false) ? root.segW + 14 : root.segW
            height: 3
            radius: 2

            transformOrigin: Item.Center
            scale: root.expanded && seg.middle ? 0.2 : 1
            opacity: root.expanded && seg.middle ? 0 : 1

            color: seg.state?.urgent  ? Theme.error
                 : seg.state?.focused ? Theme.accent
                 : seg.state?.has     ? Theme.alpha(Theme.foreground, 0.5)
                                      : Theme.alpha(Theme.foreground, 0.22)

            // 166px of travel — too far for a spring, which would read
            // as a bounce rather than a snap. See EdgePill for the
            // short-travel case.
            Behavior on x {
                NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic }
            }
            Behavior on scale {
                NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                NumberAnimation { duration: Math.round(root.duration * 0.6) }
            }
            Behavior on width {
                NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic }
            }
            Behavior on color {
                ColorAnimation { duration: Theme.durNormal }
            }
        }
    }
}
