pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "root:/Config"

/*!
    NetworkManager, via nmcli.

    Quickshell has no native NM binding, so this polls `nmcli`. The
    poll is cheap (one short-lived process every 5s) and only runs
    while something is actually watching — see `subscribed`.
*/
Singleton {
    id: root

    property string kind: "disconnected"
    property string ssid: ""
    property int    strength: 0          // 0..100, wifi only
    property bool   wifiEnabled: true
    property bool   connecting: false
    property var networks: []

    readonly property bool connected: kind !== "disconnected"

    property int subscribed: 0

    readonly property string icon: {
        if (kind === "ethernet") return "󰈀";
        if (kind !== "wifi")     return wifiEnabled ? "󰤮" : "󰤭";
        if (strength >= 80) return "󰤨";
        if (strength >= 55) return "󰤥";
        if (strength >= 30) return "󰤢";
        if (strength >= 10) return "󰤟";
        return "󰤯";
    }

    readonly property string label: {
        if (kind === "ethernet") return "Wired";
        if (kind === "wifi")     return ssid;
        return wifiEnabled ? "Disconnected" : "Wi-Fi off";
    }

    /* ─── Status poll ──────────────────────────────────────── */

    // TYPE:STATE:CONNECTION
    Process {
        id: statusProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                let found = false;
                for (const line of text.trim().split("\n")) {
                    const [type, state, name] = line.split(":");
                    if (state !== "connected") continue;
                    if (type === "ethernet") {
                        root.kind = "ethernet";
                        root.ssid = name;
                        found = true;
                        break;              // ethernet takes precedence over wifi
                    }
                    if (type === "wifi" && !found) {
                        root.kind = "wifi";
                        root.ssid = name;
                        found = true;
                    }
                }
                if (!found) {
                    root.kind = "disconnected";
                    root.ssid = "";
                    root.strength = 0;
                }
                if (root.kind === "wifi") signalProc.running = true;
            }
        }
    }

    Process {
        id: signalProc
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL", "device", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    if (line.startsWith("*")) {
                        root.strength = parseInt(line.split(":")[1]) || 0;
                        return;
                    }
                }
            }
        }
    }

    Process {
        id: radioProc
        command: ["nmcli", "-t", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = text.trim() === "enabled"
        }
    }

    function refresh(): void {
        statusProc.running = true;
        radioProc.running = true;
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    /* ─── Access point list ────────────────────────────────── */

    Process {
        id: scanProc
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {};
                const out = [];
                for (const line of text.trim().split("\n")) {
                    // nmcli escapes literal colons as "\:" — split on unescaped ones only.
                    const f = line.split(/(?<!\\):/).map(s => s.replace(/\\:/g, ":"));
                    if (f.length < 4 || !f[1]) continue;
                    if (seen[f[1]]) continue;           // keep the strongest duplicate
                    seen[f[1]] = true;
                    out.push({
                        ssid: f[1],
                        strength: parseInt(f[2]) || 0,
                        security: f[3] || "",
                        active: f[0] === "*",
                        known: root.knownNetworks.indexOf(f[1]) >= 0
                    });
                }
                out.sort((a, b) => b.strength - a.strength);
                root.networks = out;
            }
        }
    }

    property var knownNetworks: []

    Process {
        id: knownProc
        command: ["nmcli", "-t", "-f", "NAME", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: root.knownNetworks = text.trim().split("\n").filter(s => s)
        }
    }

    function scan(): void {
        knownProc.running = true;
        scanProc.running = true;
    }

    Timer {
        interval: 10000
        running: root.subscribed > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: root.scan()
    }

    /* ─── Actions ──────────────────────────────────────────── */

    function toggleWifi(): void {
        actionProc.command = ["nmcli", "radio", "wifi", root.wifiEnabled ? "off" : "on"];
        actionProc.running = true;
    }

    function connect(ssid: string, password: string): void {
        root.connecting = true;
        actionProc.command = password
            ? ["nmcli", "device", "wifi", "connect", ssid, "password", password]
            : ["nmcli", "connection", "up", ssid];
        actionProc.running = true;
    }

    function disconnect(): void {
        if (!root.ssid) return;
        actionProc.command = ["nmcli", "connection", "down", root.ssid];
        actionProc.running = true;
    }

    function forget(ssid: string): void {
        actionProc.command = ["nmcli", "connection", "delete", ssid];
        actionProc.running = true;
    }

    Process {
        id: actionProc
        onExited: {
            root.connecting = false;
            root.refresh();
            if (root.subscribed > 0) root.scan();
        }
    }

    function openSettings(): void {
        Quickshell.execDetached(["nm-connection-editor"]);
    }
}
