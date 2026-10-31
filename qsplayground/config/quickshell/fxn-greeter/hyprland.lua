-- ─── fxn-greeter compositor ──────────────────────────────────
--
-- greetd starts this as the `greeter` user (install/desktop.sh writes
-- /etc/greetd/config.toml). It exists to host the Quickshell login
-- screen and nothing else: when the greeter quits — after handing greetd
-- a session — Hyprland exits too, and greetd starts that session.
--
-- Paths are absolute: this runs from fxn-greeter-sync's public copy in
-- /var/lib/fxn-greeter, not from anyone's ~/.config.

-- The machine's own display layout, copied from hypr/conf.d/10-monitors.lua.
-- Missing on a machine that has never synced; Hyprland's defaults apply.
local monitors = loadfile("/var/lib/fxn-greeter/monitors.lua")
if monitors then pcall(monitors) end

hl.config({
  misc = {
    disable_hyprland_logo    = true,
    disable_splash_rendering = true,
    force_default_wallpaper  = 0,
  },

  ecosystem = {
    no_update_news  = true,
    no_donation_nag = true,
  },
})

hl.on("hyprland.start", function()
  hl.exec_cmd("qs -p /var/lib/fxn-greeter/greeter; hyprctl dispatch 'hl.dsp.exit()'")
end)
