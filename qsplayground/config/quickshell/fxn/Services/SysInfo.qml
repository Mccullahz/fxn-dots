pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "root:/Config"

/*!
    CPU, memory, disk, uptime and temperature, read from /proc and /sys.
*/
Singleton {
    id: root

    property int subscribed: 0

    property real cpu: 0
    property real memory: 0
    property real swap: 0
    property real disk: 0
    property real temperature: 0
    property int  memUsedMb: 0
    property int  memTotalMb: 0
    property string uptime: ""
    property string kernel: ""
    property string distro: ""
    property var _prev: null

    Process {
        id: statProc
        command: ["cat", "/proc/stat", "/proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: root.parseStat(text)
        }
    }

    function parseStat(text: string): void {
        for (const line of text.split("\n")) {
            if (line.startsWith("cpu ")) {
                const f = line.split(/\s+/).slice(1).map(Number);
                const idle  = f[3] + f[4];
                const total = f.reduce((a, b) => a + b, 0);
                if (root._prev) {
                    const dt = total - root._prev.total;
                    const di = idle  - root._prev.idle;
                    if (dt > 0) root.cpu = Math.max(0, Math.min(1, 1 - di / dt));
                }
                root._prev = { idle, total };
            } else if (line.startsWith("MemTotal:")) {
                root._memTotal = parseInt(line.split(/\s+/)[1]);
            } else if (line.startsWith("MemAvailable:")) {
                root._memAvail = parseInt(line.split(/\s+/)[1]);
            } else if (line.startsWith("SwapTotal:")) {
                root._swapTotal = parseInt(line.split(/\s+/)[1]);
            } else if (line.startsWith("SwapFree:")) {
                root._swapFree = parseInt(line.split(/\s+/)[1]);
            }
        }
        if (root._memTotal > 0) {
            root.memory     = 1 - root._memAvail / root._memTotal;
            root.memTotalMb = Math.round(root._memTotal / 1024);
            root.memUsedMb  = Math.round((root._memTotal - root._memAvail) / 1024);
        }
        if (root._swapTotal > 0)
            root.swap = 1 - root._swapFree / root._swapTotal;
    }

    property int _memTotal: 0
    property int _memAvail: 0
    property int _swapTotal: 0
    property int _swapFree: 0

    Process {
        id: tempProc
        command: ["sh", "-c",
            "for z in /sys/class/thermal/thermal_zone*; do " +
            "  t=$(cat \"$z/type\" 2>/dev/null); " +
            "  case \"$t\" in *x86_pkg_temp*|*cpu*|*acpitz*|*k10temp*) cat \"$z/temp\"; exit;; esac; " +
            "done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(text.trim());
                if (v > 0) root.temperature = v / 1000;
            }
        }
    }

    Process {
        id: diskProc
        command: ["sh", "-c", "df -P / | awk 'NR==2 {gsub(/%/,\"\",$5); print $5}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(text.trim());
                if (v >= 0) root.disk = v / 100;
            }
        }
    }

    Process {
        id: uptimeProc
        command: ["sh", "-c", "uptime -p | sed 's/^up //'"]
        stdout: StdioCollector {
            onStreamFinished: root.uptime = text.trim()
        }
    }

    Process {
        id: osProc
        command: ["sh", "-c",
            ". /etc/os-release 2>/dev/null; printf '%s\\n%s\\n' \"${PRETTY_NAME:-Linux}\" \"$(uname -r)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                root.distro = lines[0] ?? "";
                root.kernel = lines[1] ?? "";
            }
        }
    }

    Timer {
        interval: 2000
        running: root.subscribed > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statProc.running = true;
            tempProc.running = true;
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            diskProc.running = true;
            uptimeProc.running = true;
        }
    }

    Component.onCompleted: osProc.running = true

    function formatBytes(mb: int): string {
        return mb >= 1024 ? (mb / 1024).toFixed(1) + " GiB" : mb + " MiB";
    }
}
