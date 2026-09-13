pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

/*!
    which shell surfaces are currently open

    note the name: QtQuick already defines `State`, and `Shell` reads
    like the shell.qml entry point, so this is `Ui`.
*/
Singleton {
    id: root

    /* ─── Surfaces ─────────────────────────────────────────── */

    property bool barHidden: false

    /* ─── Edge ─────────────────────────────────────────────── */

    /*! "rest" | "peek" | "open"
        rest — five segments, nothing interactive but the trigger strip
        peek — the island, showing clock, playback and status
        open — the island plus the full panel below it */
    property string edgeState: "rest"
    property string edgeScreen: ""
    property string edgePage: "home"

    readonly property bool edgeRest: edgeState === "rest"
    readonly property bool edgePeek: edgeState === "peek"
    readonly property bool edgeOpen: edgeState === "open"
    readonly property bool edgeShown: edgeState !== "rest"

    function edgeTo(state: string, screen: string): void {
        if (screen)
            root.edgeScreen = screen;
        if (root.edgeState === state)
            return;
        if (state === "open")
            root.closeAll("");
        root.edgeState = state;
    }

    function edgeToggle(screen: string): void {
        if (!root.edgeOpen)
            root.edgePage = "home";
        root.edgeTo(root.edgeOpen ? "rest" : "open", screen);
    }

    property string launcherMode: "apps"

    property bool paletteOpen: false

    readonly property bool launcherOpen: paletteOpen
        || (edgeOpen && (edgePage === "launcher" || edgePage === "wallpaper"))

    property bool controlCenterOpen: false
    property string controlCenterPage: "home"
    property bool powerMenuOpen: false
    property bool overviewOpen: false
    property bool cheatsheetOpen: false

    /*! Surfaces that grab the keyboard and should close on Escape. */
    readonly property bool modalOpen: launcherOpen || powerMenuOpen
                                   || overviewOpen || cheatsheetOpen
                                   || edgeOpen

    readonly property bool anyOpen: modalOpen || controlCenterOpen

    /* ─── Exclusivity ──────────────────────────────────────── */

    function closeAll(keep: string): void {
        if (keep !== "launcher")      root.paletteOpen = false;
        if (keep !== "controlcenter") root.controlCenterOpen = false;
        if (keep !== "powermenu")     root.powerMenuOpen = false;
        if (keep !== "overview")      root.overviewOpen = false;
        if (keep !== "cheatsheet")    root.cheatsheetOpen = false;
    }

    function openLauncher(mode: string): void {
        const m = mode || "apps";
        root.launcherMode = m;
        if (Settings.useEdge) {
            root.edgePage = m === "wallpaper" ? "wallpaper" : "launcher";
            root.edgeTo("open", Hyprland.focusedMonitor?.name ?? "");
        } else {
            root.closeAll("launcher");
            root.paletteOpen = true;
        }
    }

    function closeLauncher(): void {
        root.paletteOpen = false;
        if (root.edgeOpen && root.edgePage !== "home")
            root.edgeTo("rest", "");
    }

    function toggleLauncher(mode: string): void {
        const m = mode || "apps";
        const page = m === "wallpaper" ? "wallpaper" : "launcher";
        const showing = Settings.useEdge
            ? root.edgeOpen && root.edgePage === page
              && (page === "wallpaper" || root.launcherMode === m)
            : root.paletteOpen && root.launcherMode === m;
        if (showing)
            root.closeLauncher();
        else
            root.openLauncher(m);
    }

    function toggleControlCenter(): void {
        const next = !root.controlCenterOpen;
        root.closeAll("controlcenter");
        root.controlCenterPage = "home";
        root.controlCenterOpen = next;
    }

    function openControlCenter(page: string): void {
        const p = page || "home";
        if (root.controlCenterOpen && root.controlCenterPage === p) {
            root.controlCenterOpen = false;
            return;
        }
        root.closeAll("controlcenter");
        root.controlCenterPage = p;
        root.controlCenterOpen = true;
    }

    function togglePowerMenu(): void {
        const next = !root.powerMenuOpen;
        root.closeAll("powermenu");
        root.powerMenuOpen = next;
    }

    function toggleOverview(): void {
        const next = !root.overviewOpen;
        root.closeAll("overview");
        root.overviewOpen = next;
    }

    function toggleCheatsheet(): void {
        const next = !root.cheatsheetOpen;
        root.closeAll("cheatsheet");
        root.cheatsheetOpen = next;
    }

    function toggleBar(): void {
        root.barHidden = !root.barHidden;
    }

    function dismiss(): void {
        root.closeAll("");
        root.edgeTo("rest", "");
    }
}
