pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "root:/Config"

/*!
    display and keyboard backlight, via brightnessctl.
*/
Singleton {
    id: root

    /*! 0..1, or -1 when there is no backlight on the machine. */
    property real value: -1
    property real kbdValue: -1

    readonly property bool available:    value >= 0
    readonly property bool kbdAvailable: kbdValue >= 0

    signal changed(string kind)   // "screen" | "kbd"

    readonly property string icon: {
        if (value < 0.25) return "󰃞";
        if (value < 0.50) return "󰃟";
        if (value < 0.75) return "󰃝";
        return "󰃠";
    }

    /* ─── Screen ───────────────────────────────────────────── */

    function set(v: real): void {
        const clamped = Math.max(0.01, Math.min(1, v));
        root.value = clamped;
        setProc.command = ["brightnessctl", "-m", "set", Math.round(clamped * 100) + "%"];
        setProc.running = true;
        root.changed("screen");
    }

    function up(): void   { root.set(root.value + Settings.brightnessStep / 100); }
    function down(): void { root.set(root.value - Settings.brightnessStep / 100); }

    /* ─── Keyboard ─────────────────────────────────────────── */

    function setKbd(v: real): void {
        const clamped = Math.max(0, Math.min(1, v));
        root.kbdValue = clamped;
        kbdSetProc.command = ["brightnessctl", "-m", "-d", "asus::kbd_backlight",
                              "set", Math.round(clamped * 100) + "%"];
        kbdSetProc.running = true;
        root.changed("kbd");
    }

    function kbdUp(): void   { root.setKbd(root.kbdValue + 0.34); }
    function kbdDown(): void { root.setKbd(root.kbdValue - 0.34); }

    /* ─── Processes ────────────────────────────────────────── */

    Process { id: setProc }
    Process { id: kbdSetProc }

    Process {
        id: readProc
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim().split("\n")[0];
                if (!line) return;
                const f = line.split(",");
                const max = parseInt(f[4]);
                if (max > 0) root.value = parseInt(f[2]) / max;
            }
        }
    }

    Process {
        id: kbdReadProc
        command: ["brightnessctl", "-m", "-d", "asus::kbd_backlight"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim().split("\n")[0];
                if (!line) return;
                const f = line.split(",");
                const max = parseInt(f[4]);
                if (max > 0) root.kbdValue = parseInt(f[2]) / max;
            }
        }
    }

    function refresh(): void {
        readProc.running = true;
        kbdReadProc.running = true;
    }

    Component.onCompleted: root.refresh()

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
