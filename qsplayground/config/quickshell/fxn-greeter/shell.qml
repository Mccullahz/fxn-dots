import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd

/*!
    fxn-greeter — the login screen. hypr/hyprlock.conf, redrawn in
    Quickshell for greetd, so boot and lock are the same screen.

    greetd runs this as the `greeter` user, which cannot read your home,
    so everything it shows comes from a public copy that
    hypr/bin/fxn-greeter-sync keeps in /var/lib/fxn-greeter:

        greeter/         this directory
        theme.json       the shell's palette and roles
        wallpaper        the current wallpaper (hyprlock's background)
        lock-status.sh   hyprlock's status line
        user             who published it, the default account
        state/           the greeter's own: last-user

    Outside greetd it runs as a preview: nothing authenticates, Enter
    shows the failure state, Escape quits.
*/
ShellRoot {
    id: root

    readonly property string data: Quickshell.env("FXN_GREETER_DATA")
                                   || (Quickshell.shellDir + "/..")
    readonly property bool preview: !Greetd.available

    /* ─── Theme ─────────────────────────────────────────────── */
    // hyprlock's colours are roles.conf; these are the same roles, read
    // from theme.json. Defaults are the shipped Catppuccin Mocha.

    property color bg:        "#1e1e2e"
    property color fg:        "#cdd6f4"
    property color muted:     "#a6adc8"
    property color surface:   "#313244"
    property color accent:    "#cba6f7"
    property color accentAlt: "#89b4fa"
    property color warning:   "#f9e2af"
    property color error:     "#f38ba8"

    readonly property string font: "JetBrainsMono Nerd Font"

    FileView {
        path: root.data + "/theme.json"
        printErrors: false
        onLoaded: {
            try {
                const t = JSON.parse(text());
                const r = t.roles ?? {};
                root.bg        = r.bg         ?? t.background ?? root.bg;
                root.fg        = r.fg         ?? t.foreground ?? root.fg;
                root.muted     = r.muted      ?? root.muted;
                root.surface   = r.surface    ?? root.surface;
                root.accent    = r.accent     ?? root.accent;
                root.accentAlt = r.accent_alt ?? root.accentAlt;
                root.warning   = r.warning    ?? root.warning;
                root.error     = r.error      ?? root.error;
            } catch (e) {
                console.warn("greeter: theme.json is not valid JSON —", e);
            }
        }
    }

    readonly property string wallpaper: "file://" + data + "/wallpaper"

    /* ─── Status line ───────────────────────────────────────── */

    property string status: ""

    Process {
        id: statusProc
        command: [root.data + "/lock-status.sh"]
        stdout: StdioCollector {
            onStreamFinished: root.status = text.trim()
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statusProc.running = true
    }

    /* ─── Users ─────────────────────────────────────────────── */
    // Every human account in /etc/passwd, shown under the password
    // field; Tab or the arrows switch. It starts on whoever logged in
    // here last (state/last-user, written by the greeter itself), then
    // whoever last published the greeter (user), then the first account.

    property var users: []
    property int userIndex: 0
    property string lastUser: ""
    property string savedUser: ""
    property string typedUser: ""

    readonly property string user: users.length ? users[userIndex] : typedUser
    // No accounts readable: the field asks for a name first, then the password.
    readonly property bool askingUser: user === ""

    FileView {
        path: "/etc/passwd"
        printErrors: false
        onLoaded: {
            const out = [];
            for (const line of text().split("\n")) {
                const f = line.split(":");
                const uid = parseInt(f[2]);
                if (f.length < 7 || uid < 1000 || uid >= 60000) continue;
                if (/(nologin|false)$/.test(f[6])) continue;
                out.push(f[0]);
            }
            root.users = out;
            root.pickDefault();
        }
    }

    FileView {
        path: root.data + "/user"
        printErrors: false
        onLoaded: { root.savedUser = text().trim(); root.pickDefault(); }
    }

    // install/desktop.sh makes state/ writable by the greeter user.
    FileView {
        id: lastUserFile
        path: root.data + "/state/last-user"
        printErrors: false
        blockWrites: true   // written right before launch quits the greeter
        onLoaded: { root.lastUser = text().trim(); root.pickDefault(); }
    }

    function pickDefault(): void {
        for (const name of [lastUser, savedUser]) {
            const i = users.indexOf(name);
            if (name && i >= 0) { userIndex = i; return; }
        }
    }

    function cycleUser(step: int): void {
        if (checking || users.length < 2) return;
        userIndex = (userIndex + step + users.length) % users.length;
        buffer = "";
        failText = "";
    }

    /* ─── Login ─────────────────────────────────────────────── */

    property string buffer: ""
    property string pending: ""
    property bool checking: false
    property string failText: ""

    function type(s: string): void {
        if (checking) return;
        failText = "";
        buffer += s;
    }

    function erase(all: bool): void {
        if (checking) return;
        buffer = all ? "" : buffer.slice(0, -1);
    }

    function submit(): void {
        if (checking || buffer === "") return;
        if (askingUser) {
            typedUser = buffer;
            buffer = "";
            return;
        }
        pending = buffer;
        checking = true;
        failText = "";
        if (preview) previewFail.start();
        else Greetd.createSession(user);
    }

    function fail(message: string): void {
        checking = false;
        pending = "";
        buffer = "";
        failText = message || "Authentication failed";
        if (Greetd.state !== GreetdState.Inactive) Greetd.cancelSession();
    }

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) {
                Greetd.respond(root.pending);
                root.pending = "";
            } else if (error) {
                root.failText = message;
            }
        }
        function onAuthFailure(message) { root.fail(message); }
        function onError(error) { root.fail(error); }
        function onReadyToLaunch() {
            lastUserFile.setText(root.user + "\n");
            Greetd.launch(["start-hyprland"]);
        }
    }

    Timer {
        id: previewFail
        interval: 600
        onTriggered: root.fail("preview — not running under greetd")
    }

    /* ─── Surfaces ──────────────────────────────────────────── */

    Variants {
        model: Quickshell.screens

        Surface {
            required property var modelData
            greeter: root
            screen: modelData
            // One surface takes the keyboard; the rest mirror it.
            primary: modelData === Quickshell.screens[0]
        }
    }
}
