pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "root:/Config"

/*!
    Default sink and source, exposed as plain 0..1 volumes.

    PipeWire nodes only publish volume/mute once something is
    bound to them, hence the PwObjectTracker — without it the
    properties read back as zero.
*/
Singleton {
    id: root

    readonly property PwNode sink:   Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property bool ready:      sink?.ready ?? false
    readonly property real volume:     sink?.audio?.volume ?? 0
    readonly property bool muted:      sink?.audio?.muted ?? true
    readonly property string sinkName: sink?.nickname || sink?.description || sink?.name || "No output"

    readonly property bool  sourceReady: source?.ready ?? false
    readonly property real  micVolume:   source?.audio?.volume ?? 0
    readonly property bool  micMuted:    source?.audio?.muted ?? true
    readonly property string sourceName: source?.nickname || source?.description || source?.name || "No input"

    signal changed(string kind)   // "volume" | "mute" | "mic" | "micMute"

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    /* ─── Output ───────────────────────────────────────────── */

    function setVolume(v: real): void {
        if (!sink?.audio)
            return;
        sink.audio.volume = Math.max(0, Math.min(Settings.volumeMax, v));
        root.changed("volume");
    }

    function volumeUp(): void   { root.setVolume(root.volume + Settings.volumeStep / 100); }
    function volumeDown(): void { root.setVolume(root.volume - Settings.volumeStep / 100); }

    function setMuted(m: bool): void {
        if (!sink?.audio)
            return;
        sink.audio.muted = m;
        root.changed("mute");
    }

    function toggleMute(): void { root.setMuted(!root.muted); }

    /* ─── Input ────────────────────────────────────────────── */

    function setMicVolume(v: real): void {
        if (!source?.audio)
            return;
        source.audio.volume = Math.max(0, Math.min(1, v));
        root.changed("mic");
    }

    function micUp(): void   { root.setMicVolume(root.micVolume + Settings.volumeStep / 100); }
    function micDown(): void { root.setMicVolume(root.micVolume - Settings.volumeStep / 100); }

    function toggleMicMute(): void {
        if (!source?.audio)
            return;
        source.audio.muted = !source.audio.muted;
        root.changed("micMute");
    }

    /* ─── Presentation ─────────────────────────────────────── */

    readonly property string icon: {
        if (muted || volume <= 0) return "󰸈";
        if (volume < 0.34) return "󰕿";
        if (volume < 0.67) return "󰖀";
        return "󰕾";
    }

    readonly property string micIcon: micMuted ? "󰍭" : "󰍬"
}
