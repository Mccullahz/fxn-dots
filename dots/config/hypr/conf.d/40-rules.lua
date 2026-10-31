-- ─── Window & layer rules ────────────────────────────────────
-- https://wiki.hypr.land/configuring/core/rules/
--
-- Apps are sorted into tags first, then rules are applied per tag. Add
-- an app to an existing tag and it inherits every rule for that tag.
-- Every rule needs a unique `name`.

local rule = hl.window_rule

-- ─── Tags ───────────────────────────────────────────────────
-- { tag, match property, pattern } — named r001, r002 … in order.
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

for i, entry in ipairs(tags) do
  local tag, property, pattern = entry[1], entry[2], entry[3]
  rule({ name = string.format("r%03d", i), tag = "+" .. tag, match = { [property] = pattern } })
end

-- ─── Workspace placement ────────────────────────────────────
rule({ name = "r039", workspace = "1",        match = { tag = "email*" } })
rule({ name = "r040", workspace = "2",        match = { tag = "browser*" } })
rule({ name = "r041", workspace = "4 silent", match = { tag = "screenshare*" } })
rule({ name = "r042", workspace = "5",        match = { tag = "gamestore*" } })
rule({ name = "r043", workspace = "6 silent", match = { class = "^\\.?(virt-manager)(-wrapped)?$" } })
rule({ name = "r044", workspace = "7",        match = { tag = "im*" } })
rule({ name = "r045", workspace = "8",        match = { tag = "games*" } })
rule({ name = "r046", workspace = "9 silent", match = { tag = "multimedia*" } })

-- ─── Opacity ────────────────────────────────────────────────
-- Values live in 30-look.lua (fxn.opacity, fxn.opacity_inactive, …).
local function opacity(active, inactive)
  return string.format("%s override %s override", active, inactive)
end
local normal = opacity(fxn.opacity, fxn.opacity_inactive)
local media  = opacity(fxn.opacity_media, fxn.opacity_media_inactive)

rule({ name = "r047", opacity = normal, match = { tag = "terminal*" } })
rule({ name = "r048", opacity = normal, match = { tag = "browser*" } })
rule({ name = "r049", opacity = normal, match = { tag = "projects*" } })
rule({ name = "r050", opacity = normal, match = { tag = "filemanager*" } })
rule({ name = "r051", opacity = media,  match = { tag = "im*" } })
rule({ name = "r052", opacity = media,  match = { tag = "multimedia*" } })
rule({ name = "r053", opacity = normal, match = { tag = "settings*" } })
rule({ name = "r054", opacity = media,  match = { tag = "viewer*" } })
rule({ name = "r055", opacity = normal, match = { class = "^(gedit|org.gnome.TextEditor|mousepad)$" } })
rule({ name = "r056", opacity = normal, match = { class = "^(im.riot.Riot|deluge|seahorse)$" } })

-- ─── Floating ───────────────────────────────────────────────
rule({ name = "r057", float = true, center = true, size = "(monitor_w*0.7) (monitor_h*0.7)", match = { tag = "settings*" } })
rule({ name = "r058", float = true, center = true, match = { tag = "viewer*" } })
rule({ name = "r059", float = true, center = true, match = { tag = "multimedia*" } })
rule({ name = "r060", float = true, center = true, size = "(monitor_w*0.6) (monitor_h*0.7)", match = { tag = "im*" } })
rule({ name = "r061", float = true, center = true, match = { class = "^([Zz]oom|onedriver|onedriver-launcher)$" } })
rule({ name = "r062", float = true, center = true, match = { class = "^(org.gnome.Calculator|[Qq]alculate-gtk)$" } })
rule({ name = "r063", float = true, center = true, match = { title = "^(Authentication Required)$" } })

-- Dialogs that open detached from their parent
rule({
  name  = "r064",
  float = true,
  match = { class = "^(codium|codium-url-handler|VSCodium)$", title = "negative:(.*codium.*|.*VSCodium.*)" },
})
rule({
  name  = "r065",
  float = true,
  match = { class = "^([Ss]team)$", title = "negative:^([Ss]team)$" },
})
rule({
  name  = "r066",
  float = true,
  match = { class = "^(com.heroicgameslauncher.hgl)$", title = "negative:^(Heroic Games Launcher)$" },
})
rule({
  name   = "r067",
  float  = true,
  center = true,
  match  = { class = "^([Tt]hunar)$", title = "negative:(.*[Tt]hunar.*)" },
})
rule({
  name   = "r068",
  float  = true,
  center = true,
  size   = "(monitor_w*0.7) (monitor_h*0.6)",
  match  = { initial_title = "^(Open Files|Add Folder to Workspace)$" },
})

-- ─── Misc behaviour ─────────────────────────────────────────
rule({ name = "r069", no_blur = true, fullscreen = true, match = { tag = "games*" } })
rule({ name = "r070", idle_inhibit = "fullscreen", match = { fullscreen = true } })
rule({
  name              = "r071",
  float             = true,
  pin               = true,
  keep_aspect_ratio = true,
  opacity           = "0.95 0.75",
  move              = "(monitor_w*0.72) (monitor_h*0.07)",
  match             = { title = "^(Picture-in-Picture)$" },
})

-- The XWayland screenshare bridge must stay invisible
rule({
  name             = "r072",
  no_anim          = true,
  opacity          = "0.0 override",
  no_initial_focus = true,
  match            = { class = "^(xwaylandvideobridge)$" },
})

-- Waydroid: Android sizes its display once per session and can't re-layout
-- on resize (resizing only crops), so float every Waydroid window at the
-- fixed size set by persist.waydroid.width/height (see ~/.local/bin/music).
-- 500x900 fits both the portrait and landscape monitors.
-- Full-UI window is class Waydroid; after `waydroid app launch` it's waydroid.<pkg>.
rule({ name = "r073", float = true, center = true, size = "500 900", match = { class = "^([Ww]aydroid(\\..+)?)$" } })

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
