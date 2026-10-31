-- ─── Autostart ───────────────────────────────────────────────
-- hyprland.start fires once per session, after the config has
-- loaded — the old exec-once. A config reload does not re-run it.

local bin = fxn.bin

hl.on("hyprland.start", function()
  -- Make the Wayland session visible to systemd user units and to
  -- xdg-desktop-portal. Must run before anything that needs a portal.
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE")
  hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE")

  -- Polkit authentication agent
  hl.exec_cmd(bin .. "/polkit-agent.sh")

  -- Wallpaper daemon. The script resolves swww vs. the awww fork, which
  -- ship the same CLI under different binary names.
  hl.exec_cmd(bin .. "/wallpaper.sh daemon")

  -- The shell. Replaces waybar + swaync + rofi + wlogout + ags.
  hl.exec_cmd("qs -c fxn")

  -- Clipboard history, consumed by the Quickshell clipboard palette.
  hl.exec_cmd("wl-paste --type text  --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")

  -- Idle & lock
  hl.exec_cmd("hypridle")

  -- Bluetooth pairing agent. NetworkManager needs no applet — the
  -- control center talks to it over D-Bus directly.
  hl.exec_cmd("blueman-applet")

  -- Restore the last wallpaper (and with it the wallust palette)
  hl.exec_cmd(bin .. "/wallpaper.sh restore")

  -- Republish the login screen, picking up a freshly deployed greeter.
  -- wallpaper.sh does this on every change; restore skips it when there
  -- is no wallpaper to restore.
  hl.exec_cmd(bin .. "/fxn-greeter-sync")
end)
