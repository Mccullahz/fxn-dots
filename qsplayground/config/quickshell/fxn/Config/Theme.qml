pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/*!
    palette, plus every sizing and timing constant the shell uses.
    colors come from theme.json
*/
Singleton {
    id: root

    /* ─── Raw palette ──────────────────────────────────────── */

    property color background: "#1e1e2e"
    property color foreground: "#cdd6f4"
    property var   palette: [
        "#45475a", "#f38ba8", "#a6e3a1", "#f9e2af",
        "#89b4fa", "#f5c2e7", "#94e2d5", "#bac2de",
        "#585b70", "#f38ba8", "#a6e3a1", "#f9e2af",
        "#89b4fa", "#f5c2e7", "#94e2d5", "#a6adc8"
    ]

    property var roles: ({})
    property string name: "auto"

    function color(i: int): color {
        return palette[Math.max(0, Math.min(15, i))];
    }

    /* ─── Semantic roles ───────────────────────────────────── */

    readonly property color base:        background
    readonly property color surface:     roles.surface ?? mix(background, palette[0], 0.55)
    readonly property color surfaceAlt:  roles.surface_alt ?? mix(background, palette[0], 0.85)
    readonly property color overlay:     mix(background, palette[8], 0.7)

    readonly property color text:        foreground
    readonly property color subtext:     roles.muted ?? mix(foreground, background, 0.35)
    readonly property color faint:       roles.faint ?? mix(foreground, background, 0.6)

    readonly property var ranked: {
        const out = [];
        for (let i = 0; i < 16; i++) {
            const c = rgbOf(palette[i]);
            if (contrastRatio(relLuminance(c), bgLuminance) < 3.0) continue;
            out.push({ hex: palette[i], chroma: chromaOf(c), hue: hueOf(c) });
        }
        out.sort((a, b) => b.chroma - a.chroma);
        return out;
    }

    readonly property real bgLuminance: relLuminance(rgbOf(String(background)))
    readonly property bool darkBase: bgLuminance < 0.4

    readonly property color accent: roles.accent ? roles.accent
                                  : ranked.length > 0 ? ranked[0].hex
                                                      : (darkBase ? "#89b4fa" : "#1B6FD4")

    readonly property color accentAlt: {
        if (roles.accent_alt) return roles.accent_alt;
        if (ranked.length < 2) return root.accent;
        const h0 = ranked[0].hue;
        for (let i = 1; i < ranked.length; i++) {
            let d = Math.abs(ranked[i].hue - h0);
            if (d > 180) d = 360 - d;
            if (d > 50) return ranked[i].hex;
        }
        return ranked[1].hex;
    }

    readonly property color onAccent: roles.on_accent ?? contrastOn(accent)

    readonly property color success: roles.success ?? (darkBase ? "#6BCB8B" : "#2C7A50")
    readonly property color warning: roles.warning ?? (darkBase ? "#E8B04B" : "#8C5F0C")
    readonly property color error:   roles.error ?? (darkBase ? "#E0685F" : "#AC382F")

    readonly property color border:      alpha(accent, 0.45)
    readonly property color borderFaint: roles.border_inactive ? alpha(roles.border_inactive, 0.7) : alpha(palette[8], 0.35)
    readonly property color shadow:      Qt.rgba(0, 0, 0, 0.45)
    readonly property color panel:       alpha(background, Settings.panelOpacity)
    readonly property color panelSolid:  background

    /* ─── Color helpers ───────────────────────────────────── */

    function alpha(c: color, a: real): color {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    function mix(a: color, b: color, ratio: real): color {
        return Qt.rgba(
            a.r + (b.r - a.r) * ratio,
            a.g + (b.g - a.g) * ratio,
            a.b + (b.b - a.b) * ratio,
            a.a + (b.a - a.a) * ratio
        );
    }

    function luminance(c: color): real {
        return relLuminance({ r: c.r, g: c.g, b: c.b });
    }

    /* ─── Palette analysis ─────────────────────────────────── */

    function rgbOf(hex: string): var {
        const h = hex.replace("#", "");
        return {
            r: parseInt(h.substr(0, 2), 16) / 255,
            g: parseInt(h.substr(2, 2), 16) / 255,
            b: parseInt(h.substr(4, 2), 16) / 255
        };
    }

    function relLuminance(o: var): real {
        const f = ch => ch <= 0.03928 ? ch / 12.92 : Math.pow((ch + 0.055) / 1.055, 2.4);
        return 0.2126 * f(o.r) + 0.7152 * f(o.g) + 0.0722 * f(o.b);
    }

    function contrastRatio(a: real, b: real): real {
        return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
    }

    function chromaOf(o: var): real {
        return Math.max(o.r, o.g, o.b) - Math.min(o.r, o.g, o.b);
    }

    function hueOf(o: var): real {
        const max = Math.max(o.r, o.g, o.b), min = Math.min(o.r, o.g, o.b);
        const d = max - min;
        if (d === 0) return 0;
        let h;
        if (max === o.r)      h = ((o.g - o.b) / d) % 6;
        else if (max === o.g) h = (o.b - o.r) / d + 2;
        else                  h = (o.r - o.g) / d + 4;
        h *= 60;
        return h < 0 ? h + 360 : h;
    }

    function contrastOn(c: color): color {
        return luminance(c) > 0.45 ? Qt.rgba(0, 0, 0, 1) : Qt.rgba(1, 1, 1, 1);
    }

    /* ─── Metrics ──────────────────────────────────────────── */

    readonly property int radiusSm: 6
    readonly property int radius:   12
    readonly property int radiusLg: 20
    readonly property int radiusPill: 999

    readonly property int spacingXs: 4
    readonly property int spacingSm: 8
    readonly property int spacing:   12
    readonly property int spacingLg: 18
    readonly property int spacingXl: 28

    readonly property int borderWidth: 1

    /* ─── Type ─────────────────────────────────────────────── */

    readonly property string fontFamily:  Settings.fontFamily
    readonly property string fontMono:    Settings.fontMono

    readonly property int fontSizeXs: 10
    readonly property int fontSizeSm: 12
    readonly property int fontSize:   13
    readonly property int fontSizeLg: 16
    readonly property int fontSizeXl: 22
    readonly property int fontSizeHuge: 42

    /* ─── Motion ───────────────────────────────────────────── */

    readonly property int durFast:   120
    readonly property int durNormal: 200
    readonly property int durSlow:   350

    readonly property int easeStandard:   Easing.OutCubic
    readonly property int easeEmphasized: Easing.OutBack
    readonly property int easeExit:       Easing.InCubic

    /* ─── Live reload from wallust ─────────────────────────── */

    FileView {
        path: Paths.theme
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: root.apply(text())
        // missing theme.json is fine, the defaults above stick
        onLoadFailed: console.warn("Theme: could not read", path, "— using built-in palette")
    }

    function apply(raw: string): void {
        try {
            const t = JSON.parse(raw);
            if (Array.isArray(t.colors) && t.colors.length >= 16)
                root.palette = t.colors;
            if (t.background) root.background = t.background;
            if (t.foreground) root.foreground = t.foreground;
            root.roles = (t.roles && typeof t.roles === "object") ? t.roles : {};
            root.name = t.name ?? "auto";
        } catch (e) {
            console.warn("Theme: theme.json is not valid JSON —", e);
        }
    }
}
