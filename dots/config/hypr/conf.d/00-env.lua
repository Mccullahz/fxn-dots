-- ─── Environment & default applications ──────────────────────

-- Default apps. Referenced by keybinds and by the Quickshell launcher.
fxn.term    = "kitty"
fxn.files   = "thunar"
fxn.browser = 'xdg-open "https://"'
fxn.editor  = "nvim"

hl.env("EDITOR", "nvim")
hl.env("VISUAL", "nvim")
hl.env("TERMINAL", "kitty")

-- ─── Toolkit backends ───────────────────────────────────────
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("SDL_VIDEODRIVER", "wayland")

-- ─── XDG session identity ───────────────────────────────────
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- ─── Qt ─────────────────────────────────────────────────────
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- NOTE: deliberately NOT setting QT_QUICK_CONTROLS_STYLE.
-- The old config set it to org.hyprland.style, which Quickshell
-- inherits and which can break its QML rendering. Leave it unset
-- so the shell gets the default style.

-- ─── Scaling ────────────────────────────────────────────────
-- Keep in step with the scale factors in 10-monitors.lua.
hl.env("GDK_SCALE", "1")
hl.env("QT_SCALE_FACTOR", "1")

-- ─── Cursor ─────────────────────────────────────────────────
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")

-- ─── Applications ───────────────────────────────────────────
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- ─── NVIDIA (uncomment on an nvidia box) ────────────────────
-- hl.env("LIBVA_DRIVER_NAME", "nvidia")
-- hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
-- hl.env("NVD_BACKEND", "direct")
