-- ─── Appearance ──────────────────────────────────────────────
-- Colours come from theme/colors.conf (wallust: background,
-- foreground, color0..15) and theme/roles.conf (fxn-theme: accent,
-- border …), both regenerated on every wallpaper or theme change.
-- hyprland.lua reads them into fxn.theme.
local t = fxn.theme

-- ─── Window transparency ────────────────────────────────────
-- Used by the opacity rules in 40-rules.lua. Absolute values, not
-- multipliers: 0.85 means 85% opaque whatever decoration{} says.
-- Kitty also has its own background_opacity in kitty.conf, which
-- stacks on top of these.
fxn.opacity                = 0.95   -- terminals, browsers, editors… focused
fxn.opacity_inactive       = 0.80   -- …and unfocused
fxn.opacity_media          = 0.94   -- chat, video, image viewers
fxn.opacity_media_inactive = 0.86

hl.config({
  general = {
    border_size      = 2,
    gaps_in          = 2,   -- between tiled windows
    gaps_out         = { top = 64, right = 32, bottom = 32, left = 32 },   -- between windows and the screen edge
    resize_on_border = true,
    layout           = "dwindle",

    col = {
      active_border   = t.border,
      inactive_border = t.border_inactive,
    },
  },

  decoration = {
    rounding = 10,

    active_opacity     = 1.0,
    inactive_opacity   = 0.9,
    fullscreen_opacity = 1.0,

    dim_inactive = true,
    dim_strength = 0.1,
    dim_special  = 0.8,

    shadow = {
      enabled        = true,
      range          = 3,
      render_power   = 1,
      color          = t.border,
      color_inactive = t.border_inactive,
    },

    -- Tuned for Intel HD 5500. Each pass is a full-region Gaussian;
    -- 2 → 1 roughly halves the cost and the difference is hard to see
    -- at size 4. Raise both on a machine with a discrete GPU.
    blur = {
      enabled           = true,
      size              = 4,
      passes            = 1,
      ignore_opacity    = true,
      new_optimizations = true,
      special           = false,
      popups            = true,
    },
  },

  group = {
    col = {
      border_active = t.accent_alt,
    },

    groupbar = {
      col = {
        active = t.surface,
      },
    },
  },

  dwindle = {
    preserve_split       = true,
    special_scale_factor = 0.8,
  },

  master = {
    new_status = "master",
    new_on_top = true,
    mfact      = 0.5,
  },

  animations = {
    enabled = true,
  },
})

local function bezier(name, x1, y1, x2, y2)
  hl.curve(name, { type = "bezier", points = { { x1, y1 }, { x2, y2 } } })
end

bezier("wind",      0.05, 0.9,  0.1,  1.05)
bezier("winIn",     0.1,  1.1,  0.1,  1.1)
bezier("winOut",    0.3, -0.3,  0.0,  1.0)
bezier("liner",     1.0,  1.0,  1.0,  1.0)
bezier("overshot",  0.05, 0.9,  0.1,  1.05)
bezier("smoothOut", 0.5,  0.0,  0.99, 0.99)
bezier("smoothIn",  0.5, -0.5,  0.68, 1.5)

local function animation(leaf, speed, curve, style)
  hl.animation({ leaf = leaf, enabled = true, speed = speed, bezier = curve, style = style })
end

animation("windows",       6, "wind",      "slide")
animation("windowsIn",     5, "winIn",     "slide")
animation("windowsOut",    3, "smoothOut", "slide")
animation("windowsMove",   5, "wind",      "slide")
animation("border",        1, "liner")
animation("fade",          3, "smoothOut")
animation("workspaces",    5, "overshot")
animation("workspacesIn",  5, "winIn",     "slide")
animation("workspacesOut", 5, "winOut",    "slide")

-- Quickshell surfaces. `layers` covers every wlr-layer-shell
-- surface; the per-namespace rules in 40-rules.lua refine it.
animation("layers",    3, "smoothOut", "slide")
animation("layersIn",  3, "winIn",     "slide")
animation("layersOut", 3, "smoothOut", "slide")
