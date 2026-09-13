import QtQuick
import Quickshell
import "root:/Config"

/*!
    hover tooltip drawn inside the parent window.
*/
Item {
    id: root

    property string text: ""
    property Item target: parent
    property bool hovered: false
    property int delay: 450
    /*! "top" | "bottom" — which side of the target to sit on. */
    property string side: Settings.barPosition === "top" ? "bottom" : "top"

    visible: false

    Timer {
        interval: root.delay
        running: root.hovered && root.text !== "" && root.target !== null
        onTriggered: bubble.show()
    }

    onHoveredChanged: if (!hovered) bubble.opacity = 0

    Card {
        id: bubble

        parent: root.rootItemOf(root.target)
        visible: false
        opacity: 0
        z: 9999
        elevated: true
        color: Theme.panelSolid

        implicitWidth: label.implicitWidth + Theme.spacing * 2
        implicitHeight: label.implicitHeight + Theme.spacingSm * 2

        StyledText {
            id: label
            anchors.centerIn: parent
            text: root.text
            color: Theme.text
            font.pixelSize: Theme.fontSizeSm
        }

        function show(): void {
            if (!root.target || !bubble.parent)
                return;
            const pos = root.target.mapToItem(bubble.parent, 0, 0);
            const centred = pos.x + root.target.width / 2 - width / 2;
            x = Math.max(4, Math.min(bubble.parent.width - width - 4, centred));
            y = root.side === "top" ? pos.y - height - 6
                                    : pos.y + root.target.height + 6;
            visible = true;
            opacity = 1;
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durFast
                onRunningChanged: if (!running && bubble.opacity === 0) bubble.visible = false
            }
        }
    }

    /*! Topmost ancestor of `item` — the window's content item. */
    function rootItemOf(item: Item): Item {
        if (!item) return null;
        let cur = item;
        while (cur.parent) cur = cur.parent;
        return cur;
    }
}
