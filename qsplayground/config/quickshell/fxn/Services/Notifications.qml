pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "root:/Config"

/*!
 org.freedesktop.Notifications server - swayc replacement
*/
Singleton {
    id: root

    property bool dnd: false
    property var history: []
    property var popups: []

    readonly property int count: history.length
    readonly property bool hasCritical: {
        for (const n of root.popups)
            if (n.urgency === NotificationUrgency.Critical) return true;
        return false;
    }
    readonly property string icon: dnd   ? "󰂛"
                                 : count ? "󱅫"
                                         : "󰂚"

    NotificationServer {
        id: server
        actionsSupported:     true
        actionIconsSupported: false
        bodyMarkupSupported:  true
        bodyImagesSupported:  true
        imageSupported:       true
        persistenceSupported: true
        inlineReplySupported: false

        onNotification: notification => {
            notification.tracked = true;

            const entry = wrapper.createObject(root, { notification });
            root.history = [entry, ...root.history];

            // Critical notifications ignore do-not-disturb, per spec.
            if (!root.dnd || notification.urgency === NotificationUrgency.Critical) {
                const shown = [entry, ...root.popups];
                // Drop the oldest popups past the limit, but leave them in history.
                root.popups = shown.slice(0, Settings.notificationLimit);
                for (const dropped of shown.slice(Settings.notificationLimit))
                    dropped.popup = false;
            }
        }
    }

    /* ─── Wrapper ──────────────────────────────────────────── */

    Component {
        id: wrapper

        QtObject {
            id: entry

            required property Notification notification

            property bool popup: true
            readonly property date time: new Date()

            readonly property string appName: notification.appName || "Notification"
            readonly property string summary: notification.summary
            readonly property string body:    notification.body
            readonly property string image:   notification.image
            readonly property string appIcon: notification.appIcon
            readonly property int    urgency: notification.urgency
            readonly property var    actions: notification.actions
            readonly property int timeout: {
                const t = notification.expireTimeout;
                if (urgency === NotificationUrgency.Critical) return 0;   // sticky
                if (t < 0) return Settings.notificationTimeout;
                if (t === 0) return 0;
                return Math.max(2000, Math.min(30000, t));
            }

            function dismissPopup(): void { entry.popup = false; }

            function close(): void {
                entry.popup = false;
                notification.dismiss();
            }

            function invoke(action: var): void {
                action.invoke();
                entry.popup = false;
            }
        }
    }

    Timer {
        interval: 250
        running: root.popups.length > 0
        repeat: true
        onTriggered: {
            const now = Date.now();
            const live = root.popups.filter(n => {
                if (!n.popup) return false;
                if (n.timeout === 0) return true;
                return now - n.time.getTime() < n.timeout;
            });
            if (live.length !== root.popups.length) {
                for (const n of root.popups)
                    if (live.indexOf(n) < 0) n.popup = false;
                root.popups = live;
            }
        }
    }

    /* ─── Actions ──────────────────────────────────────────── */

    function toggleDnd(): void {
        root.dnd = !root.dnd;
        if (root.dnd) root.dismissAllPopups();
    }

    function dismissAllPopups(): void {
        for (const n of root.popups) n.popup = false;
        root.popups = [];
    }

    function remove(entry: var): void {
        root.popups  = root.popups.filter(n => n !== entry);
        root.history = root.history.filter(n => n !== entry);
        entry.close();
        entry.destroy();
    }

    function clearHistory(): void {
        const all = root.history;
        root.popups = [];
        root.history = [];
        for (const n of all) {
            n.close();
            n.destroy();
        }
    }
}
