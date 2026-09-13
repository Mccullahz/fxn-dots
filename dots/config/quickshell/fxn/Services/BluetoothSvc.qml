pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "root:/Config"

/*!
    wrapper over qs BlueZ binding.

    named BluetoothSvc rather than bluetooth so it doesn't shadow the `Bluetooth` singleton this module imports.
*/
Singleton {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool available:   adapter !== null
    readonly property bool enabled:     adapter?.enabled ?? false
    readonly property bool discovering: adapter?.discovering ?? false
    readonly property var devices: adapter?.devices ?? null

    property var known: []
    property var discovered: []
    property int subscribed: 0

    readonly property BluetoothDevice primary: {
        for (const d of root.known)
            if (d.connected) return d;
        return null;
    }

    readonly property string icon: !enabled ? "󰂲"
                                 : primary  ? "󰂱"
                                            : "󰂯"

    readonly property string label: !available ? "No adapter"
                                  : !enabled   ? "Bluetooth off"
                                  : primary    ? (primary.alias || primary.name)
                                               : "Not connected"

    function toggle(): void {
        if (adapter) adapter.enabled = !adapter.enabled;
    }

    function setDiscovering(on: bool): void {
        if (adapter && adapter.enabled) adapter.discovering = on;
    }

    onSubscribedChanged: root.setDiscovering(subscribed > 0)

    function rebuild(): void {
        const k = [], d = [];
        const list = root.devices?.values ?? [];
        for (const dev of list) {
            if (dev.paired || dev.bonded || dev.trusted || dev.connected) k.push(dev);
            else if (dev.name) d.push(dev);
        }
        k.sort((a, b) => (b.connected ? 1 : 0) - (a.connected ? 1 : 0));
        root.known = k;
        root.discovered = d;
    }

    Connections {
        target: root.devices
        function onValuesChanged(): void { root.rebuild(); }
    }

    Component.onCompleted: root.rebuild()

    function openSettings(): void {
        Quickshell.execDetached(["blueman-manager"]);
    }
}
