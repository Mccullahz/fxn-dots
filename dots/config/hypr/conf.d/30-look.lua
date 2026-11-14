-- ─── Appearance ──────────────────────────────────────────────
-- Colours come from theme/roles.conf (fxn-theme) and theme/colors.conf
-- (wallust). Both stay in hyprlang `$name = value` form because hyprlock
-- sources them as well; fxn.read_vars parses them for Lua. fxn-theme
-- runs `hyprctl reload` after rewriting them.
local colors = fxn.read_vars(fxn.cfg .. "/theme/colors.conf")
local roles  = fxn.read_vars(fxn.cfg .. "/theme/roles.conf")
fxn.colors, fxn.roles = colors, roles

-- Fallbacks so a missing/half-written theme never breaks the config.
local function role(name, default) return roles[name] or default end

-- ─── Window transparency ────────────────────────────────────
-- Used by the opacity rules in 40-rules.lua. Absolute values, not
-- multipliers: 0.85 means 85% opaque whatever decoration says.
-- Kitty also has its own background_opacity in kitty.conf, which
-- stacks on top of these.
fxn.opacity                = 0.95 -- terminals, browsers, editors… focused
fxn.opacity_inactive       = 0.80 -- …and unfocused
fxn.opacity_media          = 0.94 -- chat, video, image viewers
fxn.opacity_media_inactive = 0.86

hl.config({
    general = {
        border_size      = 2,
        gaps_in          = 2, -- between tiled windows
        gaps_out         = { top = 64, right = 32, bottom = 32, left = 32 }, -- between windows and the screen edge
        resize_on_border = true,
        layout           = "dwindle",

        col = {
            active_border   = role("border", "rgb(cba6f7)"),
            inactive_border = role("border_inactive", "rgb(45475a)"),
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
            color          = role("border", "rgb(cba6f7)"),
            color_inactive = role("border_inactive", "rgb(45475a)"),
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
            border_active = role("accent_alt", "rgb(89b4fa)"),
        },
        groupbar = {
            col = {
                active = role("surface", "rgb(313244)"),
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

local function bezier(name, x0, y0, x1, y1)
    hl.curve(name, { type = "bezier", points = { { x0, y0 }, { x1, y1 } } })
end

bezier("wind",      0.05, 0.9,  0.1,  1.05)
bezier("winIn",     0.1,  1.1,  0.1,  1.1)
bezier("winOut",    0.3, -0.3,  0.0,  1.0)
bezier("liner",     1.0,  1.0,  1.0,  1.0)
bezier("overshot",  0.05, 0.9,  0.1,  1.05)
bezier("smoothOut", 0.5,  0.0,  0.99, 0.99)
bezier("smoothIn",  0.5, -0.5,  0.68, 1.5)

local function anim(leaf, speed, curve, style)
    hl.animation({ leaf = leaf, enabled = true, speed = speed, bezier = curve, style = style })
end

anim("windows",       6, "wind",      "slide")
anim("windowsIn",     5, "winIn",     "slide")
anim("windowsOut",    3, "smoothOut", "slide")
anim("windowsMove",   5, "wind",      "slide")
anim("border",        1, "liner")
anim("fade",          3, "smoothOut")
anim("workspaces",    5, "overshot")
anim("workspacesIn",  5, "winIn",     "slide")
anim("workspacesOut", 5, "winOut",    "slide")

-- Quickshell surfaces. `layers` covers every wlr-layer-shell
-- surface; the per-namespace rules in 40-rules.lua refine it.
anim("layers",    3, "smoothOut", "slide")
anim("layersIn",  3, "winIn",     "slide")
anim("layersOut", 3, "smoothOut", "slide")
