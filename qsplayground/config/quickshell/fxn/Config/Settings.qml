pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/*!
    user-editable shell settings, persisted in settings.json
*/
Singleton {
    id: root

    /* ─── Shell style ──────────────────────────────────────── */

    /*
     * "edge" - the top edge that expands into an island (default)
     *
     * "bar"  — the classic full bar, kept so the two can be compared on real hardware without editing any QML. 
     */
    readonly property string shellStyle: adapter.shellStyle

    readonly property bool useEdge: shellStyle === "edge"
    readonly property bool useBar:  shellStyle === "bar"

    /* ─── Edge ─────────────────────────────────────────────── */

    readonly property int  edgeRestHeight: adapter.edgeRestHeight
    readonly property int  edgeSegmentWidth: adapter.edgeSegmentWidth
    readonly property int  edgeSegmentGap: adapter.edgeSegmentGap
    readonly property int  edgePillWidth: adapter.edgePillWidth
    readonly property int  edgePanelWidth: adapter.edgePanelWidth
    readonly property int  edgeDuration: adapter.edgeDuration
    readonly property bool edgePeekOnHover: adapter.edgePeekOnHover

    /*! Slack around the island and panel, in pixels. The pointer can
        stray this far outside them before the edge counts as left —
        without it, the hit area is exactly the visible surface and
        approaching the island is fiddly. */
    readonly property int  edgeHoverBuffer: adapter.edgeHoverBuffer
    readonly property int  edgeCloseDelay: adapter.edgeCloseDelay
    readonly property bool edgeClickOutside: adapter.edgeClickOutside

    /* ─── Bar ──────────────────────────────────────────────── */
    readonly property string barPosition: adapter.barPosition
    readonly property string barMode:     adapter.barMode
    readonly property int    barHeight:   adapter.barHeight
    readonly property int    barWidth:    adapter.barWidth      // floating mode only
    readonly property int    barMargin:   adapter.barMargin
    readonly property bool   barExclusive: adapter.barExclusive

    /* ─── Workspaces ───────────────────────────────────────── */

    readonly property int    workspaceCount: adapter.workspaceCount
    readonly property string workspaceStyle: adapter.workspaceStyle
    readonly property bool   workspacesAllOutputs: adapter.workspacesAllOutputs

    /* ─── Look ─────────────────────────────────────────────── */

    readonly property real   panelOpacity: adapter.panelOpacity
    readonly property string fontFamily:   adapter.fontFamily
    readonly property string fontMono:     adapter.fontMono

    /* ─── Clock ────────────────────────────────────────────── */

    /*! Qt.formatDateTime pattern. */
    readonly property string clockFormat:     adapter.clockFormat
    readonly property string clockFormatAlt:  adapter.clockFormatAlt

    /* ─── Behavior ────────────────────────────────────────── */

    readonly property string terminal:      adapter.terminal
    readonly property string fileManager:   adapter.fileManager
    readonly property string searchEngine:  adapter.searchEngine
    readonly property var    wallpaperDirs: adapter.wallpaperDirs
    readonly property int    wallpaperInterval: adapter.wallpaperInterval

    readonly property int    notificationTimeout: adapter.notificationTimeout   // ms
    readonly property int    notificationLimit:   adapter.notificationLimit
    readonly property string notificationPosition: adapter.notificationPosition // "top"|"bottom" + "left"|"right"|"center"

    readonly property int    osdTimeout: adapter.osdTimeout

    readonly property int    volumeStep:     adapter.volumeStep 
    readonly property int    brightnessStep: adapter.brightnessStep
    readonly property real   volumeMax:      adapter.volumeMax	// 1.0 = 100%

    /* ─── Mutation ─────────────────────────────────────────── */

    function set(key: string, value: var): void {
        if (adapter[key] === undefined) {
            console.warn("Settings: unknown key", key);
            return;
        }
        adapter[key] = value;
    }

    function toggle(key: string): void {
        root.set(key, !adapter[key]);
    }

    FileView {
        id: file
        path: Paths.settings
        watchChanges: true
        printErrors: false
        onLoadFailed: writeAdapter()
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        adapter: JsonAdapter {
            id: adapter

            property string shellStyle: "edge"
            property int    edgeRestHeight:   6
            property int    edgeSegmentWidth: 20
            property int    edgeSegmentGap:   4
            property int    edgePillWidth:    360
            property int    edgePanelWidth:   420
            property int    edgeDuration:     300
            property bool   edgePeekOnHover:  true
            property int    edgeHoverBuffer:  40
            property int    edgeCloseDelay:   250
            property bool   edgeClickOutside: true
            property string barPosition:  "bottom"
            property string barMode:      "floating"
            property int    barHeight:    38
            property int    barWidth:     1000
            property int    barMargin:    6
            property bool   barExclusive: true
            property int    workspaceCount: 5
            property string workspaceStyle: "kanji"
            property bool   workspacesAllOutputs: true
            property real   panelOpacity: 0.95
            property string fontFamily:   "JetBrainsMono Nerd Font"
            property string fontMono:     "JetBrainsMono Nerd Font Mono"
            property string clockFormat:    "h:mm AP"
            property string clockFormatAlt: "HH:mm  ·  yyyy, d MMMM, dddd"
            property string terminal:     "kitty"
            property string fileManager:  "thunar"
            property string searchEngine: "https://www.google.com/search?q="
            property var    wallpaperDirs: [
                "/usr/share/backgrounds",
                Paths.home + "/Pictures/wallpapers"
            ]
            property int    wallpaperInterval: 0
            property int    notificationTimeout:  5000
            property int    notificationLimit:    5
            property string notificationPosition: "top-right"
            property int    osdTimeout: 1600
            property int    volumeStep:     5
            property int    brightnessStep: 5
            property real   volumeMax:      1.0
        }
    }
}
