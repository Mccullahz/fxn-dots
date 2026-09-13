pragma Singleton

import QtQuick
import Quickshell
import "root:/Config"

Singleton {
    id: root

    readonly property var actions: [
        { id: "lock",      icon: "󰌾", label: "Lock",      confirm: false,
          cmd: ["loginctl", "lock-session"] },
        { id: "sleep",     icon: "󰤄", label: "Sleep",     confirm: false,
          cmd: ["systemctl", "suspend"] },
        { id: "hibernate", icon: "󰋊", label: "Hibernate", confirm: false,
          cmd: ["systemctl", "hibernate"] },
        { id: "logout",    icon: "󰗽", label: "Log out",   confirm: true,
          cmd: ["hyprctl", "dispatch", "exit", "0"] },
        { id: "reboot",    icon: "󰜉", label: "Reboot",    confirm: true,
          cmd: ["systemctl", "reboot"] },
        { id: "poweroff",  icon: "󰐥", label: "Power",     confirm: true,
          cmd: ["systemctl", "poweroff"] }
    ]

    function find(id: string): var {
        for (const a of root.actions)
            if (a.id === id) return a;
        return null;
    }

    function run(id: string): void {
        const action = root.find(id);
        if (!action) {
            console.warn("Session: no such action", id);
            return;
        }
        Ui.closeAll("");
        Quickshell.execDetached(action.cmd);
    }
}
