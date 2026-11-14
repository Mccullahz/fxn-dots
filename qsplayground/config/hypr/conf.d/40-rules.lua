-- ─── Window & layer rules ────────────────────────────────────
-- https://wiki.hypr.land/configuring/core/rules/window-rules/
--
-- Apps are sorted into tags first, then rules are applied per tag. Add
-- an app to an existing tag and it inherits every rule for that tag.
-- Rule names must be unique; the helpers below number them for you.

local n = 0
local function rule(spec)
    n = n + 1
    spec.name = spec.name or string.format("r%03d", n)
    return hl.window_rule(spec)
end

-- ─── Tags ───────────────────────────────────────────────────
-- { tag, match-field, regex }
local tags = {
    { "browser",     "class", "^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr|[Ff]irefox-bin)$" },
    { "browser",     "class", "^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$" },
    { "browser",     "class", "^(chrome-.+-Default)$" },
    { "browser",     "class", "^([Cc]hromium)$" },
    { "browser",     "class", "^([Mm]icrosoft-edge(-stable|-beta|-dev|-unstable))$" },
    { "browser",     "class", "^(Brave-browser(-beta|-dev|-unstable)?)$" },
    { "browser",     "class", "^([Tt]horium-browser|[Cc]achy-browser)$" },
    { "browser",     "class", "^(zen-alpha|zen)$" },
    { "terminal",    "class", "^([Aa]lacritty|kitty|kitty-dropterm|foot|com.mitchellh.ghostty)$" },
    { "email",       "class", "^([Tt]hunderbird|org.gnome.Evolution|eu.betterbird.Betterbird)$" },
    { "projects",    "class", "^(codium|codium-url-handler|VSCodium)$" },
    { "projects",    "class", "^(VSCode|code-url-handler|code)$" },
    { "projects",    "class", "^(jetbrains-.+)$" },
    { "screenshare", "class", "^(com.obsproject.Studio)$" },
    { "im",          "class", "^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$" },
    { "im",          "class", "^([Ff]erdium)$" },
    { "im",          "class", "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" },
    { "im",          "class", "^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$" },
    { "im",          "class", "^(teams-for-linux)$" },
    { "games",       "class", "^(gamescope)$" },
    { "games",       "class", "^(steam_app_\\d+)$" },
    { "gamestore",   "class", "^([Ss]team)$" },
    { "gamestore",   "class", "^(com.heroicgameslauncher.hgl)$" },
    { "gamestore",   "title", "^([Ll]utris)$" },
    { "filemanager", "class", "^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt|app.drey.Warp)$" },
    { "multimedia",  "class", "^([Aa]udacious|mpv|com.github.rafostar.Clapper)$" },
    { "settings",    "class", "^(nwg-displays|nwg-look|qt5ct|qt6ct|[Yy]ad)$" },
    { "settings",    "class", "^(nm-applet|nm-connection-editor|blueman-manager)$" },
    { "settings",    "class", "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" },
    { "settings",    "class", "^(gnome-disks|wihotspot(-gui)?)$" },
    { "settings",    "class", "^([Bb]aobab|org.gnome.[Bb]aobab)$" },
    { "settings",    "class", "^(file-roller|org.gnome.FileRoller)$" },
    { "settings",    "class", "^(xdg-desktop-portal-gtk)$" },
    { "settings",    "class", "^(org.kde.polkit-kde-authentication-agent-1)$" },
    { "settings",    "title", "^(Kvantum Manager)$" },
    { "viewer",      "class", "^(gnome-system-monitor|org.gnome.SystemMonitor|io.missioncenter.MissionCenter)$" },
    { "viewer",      "class", "^(evince|org.gnome.Evince)$" },
    { "viewer",      "class", "^(eog|org.gnome.Loupe)$" },
}

for _, t in ipairs(tags) do
    rule({ tag = "+" .. t[1], match = { [t[2]] = t[3] } })
end

-- ─── Workspace placement ────────────────────────────────────
rule({ workspace = "1",        match = { tag = "email*" } })
rule({ workspace = "2",        match = { tag = "browser*" } })
rule({ workspace = "4 silent", match = { tag = "screenshare*" } })
rule({ workspace = "5",        match = { tag = "gamestore*" } })
rule({ workspace = "6 silent", match = { class = "^\\.?(virt-manager)(-wrapped)?$" } })
rule({ workspace = "7",        match = { tag = "im*" } })
rule({ workspace = "8",        match = { tag = "games*" } })
rule({ workspace = "9 silent", match = { tag = "multimedia*" } })

-- Scratchpad: SUPER+U opens it, and an empty one spawns a terminal.
hl.workspace_rule({ workspace = "special:scratch", on_created_empty = fxn.term })

-- ─── Opacity ────────────────────────────────────────────────
-- Values live in 30-look.lua (fxn.opacity, fxn.opacity_inactive, …).
local normal = string.format("%s override %s override", fxn.opacity, fxn.opacity_inactive)
local media  = string.format("%s override %s override", fxn.opacity_media, fxn.opacity_media_inactive)

rule({ opacity = normal, match = { tag = "terminal*" } })
rule({ opacity = normal, match = { tag = "browser*" } })
rule({ opacity = normal, match = { tag = "projects*" } })
rule({ opacity = normal, match = { tag = "filemanager*" } })
rule({ opacity = media,  match = { tag = "im*" } })
rule({ opacity = media,  match = { tag = "multimedia*" } })
rule({ opacity = normal, match = { tag = "settings*" } })
rule({ opacity = media,  match = { tag = "viewer*" } })
rule({ opacity = normal, match = { class = "^(gedit|org.gnome.TextEditor|mousepad)$" } })
rule({ opacity = normal, match = { class = "^(im.riot.Riot|deluge|seahorse)$" } })

-- ─── Floating ───────────────────────────────────────────────
rule({ float = true, center = true, size = { "monitor_w*0.7", "monitor_h*0.7" }, match = { tag = "settings*" } })
rule({ float = true, center = true, match = { tag = "viewer*" } })
rule({ float = true, center = true, match = { tag = "multimedia*" } })
rule({ float = true, center = true, size = { "monitor_w*0.6", "monitor_h*0.7" }, match = { tag = "im*" } })
rule({ float = true, center = true, match = { class = "^([Zz]oom|onedriver|onedriver-launcher)$" } })
rule({ float = true, center = true, match = { class = "^(org.gnome.Calculator|[Qq]alculate-gtk)$" } })
rule({ float = true, center = true, match = { title = "^(Authentication Required)$" } })

-- Dialogs that open detached from their parent
rule({ float = true, match = { class = "^(codium|codium-url-handler|VSCodium)$", title = "negative:(.*codium.*|.*VSCodium.*)" } })
rule({ float = true, match = { class = "^([Ss]team)$", title = "negative:^([Ss]team)$" } })
rule({ float = true, match = { class = "^(com.heroicgameslauncher.hgl)$", title = "negative:^(Heroic Games Launcher)$" } })
rule({ float = true, center = true, match = { class = "^([Tt]hunar)$", title = "negative:(.*[Tt]hunar.*)" } })
rule({
    float = true, center = true,
    size  = { "monitor_w*0.7", "monitor_h*0.6" },
    match = { initial_title = "^(Open Files|Add Folder to Workspace)$" },
})

-- ─── Misc behaviour ─────────────────────────────────────────
rule({ no_blur = true, fullscreen = true, match = { tag = "games*" } })
rule({ idle_inhibit = "fullscreen", match = { fullscreen = true } })
rule({
    float = true, pin = true, keep_aspect_ratio = true,
    opacity = "0.95 0.75",
    move    = { "monitor_w*0.72", "monitor_h*0.07" },
    match   = { title = "^(Picture-in-Picture)$" },
})

-- The XWayland screenshare bridge must stay invisible
rule({
    no_anim = true, opacity = "0.0 override", no_initial_focus = true,
    match   = { class = "^(xwaylandvideobridge)$" },
})

-- Waydroid: Android sizes its display once per session and can't re-layout
-- on resize (resizing only crops), so float every Waydroid window at the
-- fixed size set by persist.waydroid.width/height (see ~/.local/bin/music).
-- 500x900 fits both the portrait and landscape monitors.
-- Full-UI window is class Waydroid; after `waydroid app launch` it's waydroid.<pkg>.
rule({ float = true, center = true, size = { 500, 900 }, match = { class = "^([Ww]aydroid(\\..+)?)$" } })

-- ─── Layer rules: Quickshell surfaces ───────────────────────
-- Namespaces are set in each module's WlrLayershell.namespace —
-- keep the two lists in step.
--
-- Only the edge is blurred. On a Broadwell iGPU each blurred layer
-- costs a framebuffer readback plus a Gaussian pass every frame it
-- is visible, and the edge is the one surface that is always up.
-- The transient surfaces stay sharp and are cheap because of it.

hl.layer_rule({ name = "layer-edge", blur = true, ignore_alpha = 0.4, match = { namespace = "^(fxn-edge)$" } })

-- The bar, when shellStyle is "bar" instead of "edge".
hl.layer_rule({ name = "layer-bar", blur = true, ignore_alpha = 0.3, match = { namespace = "^(fxn-bar)$" } })

-- The control center animates itself, on the edge's timing. Hyprland's
-- layer slide would move the whole full-screen surface on top of that.
hl.layer_rule({ name = "layer-controlcenter", no_anim = true, match = { namespace = "^(fxn-controlcenter)$" } })

-- Everything below is deliberately unblurred. Uncomment a rule if
-- you would rather spend the frames — measure before you do.
--
-- hl.layer_rule({ name = "layer-launcher", blur = true, ignore_alpha = 0.3, match = { namespace = "^(fxn-launcher)$" } })
