pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "root:/Config"

Singleton {
    id: root

    property string expression: ""
    property string result: ""
    property bool   error: false

    property bool qalcAvailable: false

    onExpressionChanged: root.evaluate()

    function evaluate(): void {
        const expr = root.expression.trim();
        if (!expr) {
            root.result = "";
            root.error = false;
            return;
        }
        if (root.qalcAvailable) {
            qalcProc.command = ["qalc", "-t", "-terse", expr];
            qalcProc.running = true;
        } else {
            root.evaluateJs(expr);
        }
    }

    Process {
        id: qalcProc
        stdout: StdioCollector {
            onStreamFinished: {
                const out = text.trim();
                root.error = !out || out.toLowerCase().includes("error");
                root.result = root.error ? "" : out;
            }
        }
    }

    function evaluateJs(expr: string): void {
        const safe = expr
            .replace(/\bpi\b/gi, "Math.PI")
            .replace(/\be\b/g, "Math.E")
            .replace(/\b(sqrt|cbrt|abs|floor|ceil|round|sin|cos|tan|asin|acos|atan|log2|log10|log|exp|sign|min|max|pow)\s*\(/gi,
                     (m, fn) => "Math." + fn.toLowerCase() + "(")
            .replace(/\^/g, "**");

        if (/[^0-9+\-*/%().,\s eMath:?<>=|&!]/.test(safe.replace(/Math\.\w+/g, ""))) {
            root.error = true;
            root.result = "";
            return;
        }

        try {
            const v = Function('"use strict"; return (' + safe + ')')();
            if (typeof v !== "number" || !isFinite(v)) throw new Error("not a number");
            root.result = String(Math.round(v * 1e10) / 1e10);
            root.error = false;
        } catch (e) {
            root.result = "";
            root.error = true;
        }
    }

    function copyResult(): void {
        if (root.result)
            Quickshell.execDetached(["wl-copy", "--", root.result]);
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v qalc >/dev/null && echo yes || echo no"]
        stdout: StdioCollector {
            onStreamFinished: root.qalcAvailable = text.trim() === "yes"
        }
    }
}
