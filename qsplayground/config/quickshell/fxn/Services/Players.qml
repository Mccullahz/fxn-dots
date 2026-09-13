pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "root:/Config"

Singleton {
    id: root

    readonly property var all: Mpris.players

    property MprisPlayer pinned: null

    readonly property MprisPlayer active: {
        const list = root.all?.values ?? [];
        if (list.length === 0) return null;
        if (root.pinned && list.indexOf(root.pinned) >= 0) return root.pinned;
        for (const p of list)
            if (p.playbackState === MprisPlaybackState.Playing) return p;
        return list[0];
    }
    readonly property bool has:     active !== null
    readonly property bool playing: active?.playbackState === MprisPlaybackState.Playing
    readonly property string title:  active?.trackTitle  || ""
    readonly property string artist: active?.trackArtist || ""
    readonly property string album:  active?.trackAlbum  || ""
    readonly property string artUrl: active?.trackArtUrl || ""
    readonly property string identity: active?.identity  || ""
    readonly property string summary: {
        if (!has) return "";
        if (!title) return identity;
        return artist ? `${artist} — ${title}` : title;
    }

    property int tick: 0
    readonly property real position: {
        root.tick;                      // dependency, deliberately unused
        return active?.position ?? 0;
    }
    readonly property real length:   active?.length ?? 0
    readonly property real progress: length > 0 ? Math.min(1, position / length) : 0

    readonly property string statusIcon: {
        if (!has) return "";
        switch (active.playbackState) {
        case MprisPlaybackState.Playing: return "";
        case MprisPlaybackState.Paused:  return "󰐎";
        default:                         return "";
        }
    }

    function iconFor(player: var): string {
        const id = (player?.desktopEntry || player?.identity || "").toLowerCase();
        if (id.includes("spotify"))  return "";
        if (id.includes("firefox"))  return "";
        if (id.includes("chrom"))    return "";
        if (id.includes("mpv"))      return "󰐹";
        if (id.includes("vlc"))      return "󰕼";
        if (id.includes("musicfox") || id.includes("ncspot")) return "󰝚";
        return "";
    }

    readonly property string icon: root.iconFor(root.active)

    /* ─── Transport ────────────────────────────────────────── */

    function playPause(): void { if (active?.canTogglePlaying) active.togglePlaying(); }
    function next(): void      { if (active?.canGoNext)        active.next(); }
    function previous(): void  { if (active?.canGoPrevious)    active.previous(); }
    function stop(): void      { if (active)                   active.stop(); }

    function seek(fraction: real): void {
        if (active?.canSeek && length > 0)
            active.position = Math.max(0, Math.min(length, fraction * length));
    }

    Timer {
        interval: 1000
        running: root.playing
        repeat: true
        onTriggered: root.tick++
    }
}
