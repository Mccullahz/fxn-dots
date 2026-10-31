-- ─── Keybinds ────────────────────────────────────────────────
-- https://wiki.hypr.land/configuring/core/binds/
--
-- Anything that used to shell out to rofi / wlogout / swaync now
-- talks to Quickshell over IPC. `qs -c fxn ipc call <target> <fn>`
-- is cheap — it is a unix-socket round trip, no process spawn.
--
-- The Quickshell cheat sheet (SUPER+H) reads this file: keep one
-- bind per line, the key combo as a literal string, and the trailing
-- `-- comment` as its description. The ─── headers become its groups.

local bind, dsp = hl.bind, hl.dsp
local bin = fxn.bin
local qs  = "qs -c fxn ipc call "

local function exec(cmd, rules) return dsp.exec_cmd(cmd, rules) end

local repeating = { repeating = true }
local locked    = { locked = true }
local held      = { locked = true, repeating = true }
local mouse     = { mouse = true }

-- `workspaceopt allfloat` no longer exists: float every window on the
-- workspace, or tile them all again if they already float.
local function toggle_all_float()
  local ws = hl.get_active_workspace()
  if not ws then return end
  local windows = ws:get_windows()
  local float = false
  for _, w in ipairs(windows) do
    if not w.floating then float = true break end
  end
  for _, w in ipairs(windows) do
    if w.floating ~= float then
      hl.dispatch(dsp.window.float({ action = "toggle", window = w }))
    end
  end
end

local function cycle_and_raise()
  hl.dispatch(dsp.window.cycle_next())
  hl.dispatch(dsp.window.bring_to_top())
end

-- ─── Launching ──────────────────────────────────────────────
bind("SUPER + Return",         exec(fxn.term))                                                      -- terminal
bind("SUPER + SHIFT + Return", exec(fxn.term, { float = true, move = "15% 5%", size = "70% 60%" })) -- floating terminal
bind("SUPER + E",              exec(fxn.files))                                                     -- file manager
bind("SUPER + B",              exec(fxn.browser))                                                   -- browser

-- ─── Quickshell surfaces ────────────────────────────────────
bind("SUPER + D",              exec(qs .. "launcher toggle"))          -- app launcher
bind("SUPER + S",              exec(qs .. "launcher openWeb"))         -- web search
bind("SUPER + ALT + C",        exec(qs .. "launcher openCalc"))        -- calculator
bind("SUPER + ALT + E",        exec(qs .. "launcher openEmoji"))       -- emoji picker
bind("SUPER + ALT + V",        exec(qs .. "launcher openClipboard"))   -- clipboard history
bind("SUPER + A",              exec(qs .. "overview toggle"))          -- workspace overview
bind("SUPER + W",              exec(qs .. "wallpaper toggle"))         -- wallpaper picker
bind("SUPER + H",              exec(qs .. "cheatsheet toggle"))        -- this keybind list
bind("SUPER + SHIFT + N",      exec(qs .. "controlcenter toggle"))     -- notifications + toggles
bind("SUPER + SHIFT + D",      exec(qs .. "notifications toggleDnd"))  -- do-not-disturb
bind("CTRL + ALT + P",         exec(qs .. "powermenu toggle"))         -- power menu
bind("SUPER + grave",          exec(qs .. "edge toggle"))              -- open the edge island
bind("SUPER + CTRL + ALT + B", exec(qs .. "bar toggle"))               -- hide/show the bar

bind("SUPER + Escape",         exec(qs .. "shell dismiss"))            -- close whatever is open
bind("CTRL + ALT + L",         exec("loginctl lock-session"))          -- hyprlock via hypridle
bind("CTRL + ALT + Delete",    dsp.exit())                             -- exit Hyprland

-- ─── Window management ──────────────────────────────────────
bind("SUPER + Q",              dsp.window.close())                                 -- close window
bind("SUPER + SHIFT + Q",      exec(bin .. "/kill-active.sh"))                     -- kill window
bind("SUPER + SPACE",          dsp.window.float({ action = "toggle" }))            -- toggle floating
bind("SUPER + ALT + SPACE",    toggle_all_float)                                   -- float every window here
bind("SUPER + SHIFT + F",      dsp.window.fullscreen({ mode = "fullscreen" }))     -- fullscreen
bind("SUPER + CTRL + F",       dsp.window.fullscreen({ mode = "maximized" }))      -- maximize
bind("SUPER + P",              dsp.window.pseudo())                                -- pseudotile
bind("SUPER + G",              dsp.group.toggle())                                 -- toggle group
bind("SUPER + CTRL + tab",     dsp.group.next())                                   -- next window in group
bind("SUPER + CTRL + O",       dsp.window.set_prop({ prop = "opaque", value = "toggle" })) -- toggle opaque

bind("ALT + tab",              cycle_and_raise)                                    -- cycle windows

-- Master layout
bind("SUPER + CTRL + D",       dsp.layout("removemaster"))     -- remove master
bind("SUPER + I",              dsp.layout("addmaster"))        -- add master
bind("SUPER + J",              dsp.layout("cyclenext"))        -- next window
bind("SUPER + K",              dsp.layout("cycleprev"))        -- previous window
bind("SUPER + CTRL + Return",  dsp.layout("swapwithmaster"))   -- swap with master
bind("SUPER + M",              dsp.layout("togglesplit"))      -- toggle split

-- Focus
bind("SUPER + left",           dsp.focus({ direction = "left" }))    -- focus left
bind("SUPER + right",          dsp.focus({ direction = "right" }))   -- focus right
bind("SUPER + up",             dsp.focus({ direction = "up" }))      -- focus up
bind("SUPER + down",           dsp.focus({ direction = "down" }))    -- focus down

-- Move
bind("SUPER + CTRL + left",    dsp.window.move({ direction = "left" }))    -- move left
bind("SUPER + CTRL + right",   dsp.window.move({ direction = "right" }))   -- move right
bind("SUPER + CTRL + up",      dsp.window.move({ direction = "up" }))      -- move up
bind("SUPER + CTRL + down",    dsp.window.move({ direction = "down" }))    -- move down

-- Swap
bind("SUPER + ALT + left",     dsp.window.swap({ direction = "left" }))    -- swap left
bind("SUPER + ALT + right",    dsp.window.swap({ direction = "right" }))   -- swap right
bind("SUPER + ALT + up",       dsp.window.swap({ direction = "up" }))      -- swap up
bind("SUPER + ALT + down",     dsp.window.swap({ direction = "down" }))    -- swap down

-- Resize
bind("SUPER + SHIFT + left",   dsp.window.resize({ x = -50, y = 0, relative = true }), repeating)   -- shrink width
bind("SUPER + SHIFT + right",  dsp.window.resize({ x = 50, y = 0, relative = true }), repeating)    -- grow width
bind("SUPER + SHIFT + up",     dsp.window.resize({ x = 0, y = -50, relative = true }), repeating)   -- shrink height
bind("SUPER + SHIFT + down",   dsp.window.resize({ x = 0, y = 50, relative = true }), repeating)    -- grow height

bind("SUPER + mouse:272",      dsp.window.drag(), mouse)     -- drag window
bind("SUPER + mouse:273",      dsp.window.resize(), mouse)   -- resize window

-- ─── Workspaces ─────────────────────────────────────────────
-- code:10 = "1", code:11 = "2" ... code:19 = "0".
-- Using keycodes keeps these working on non-US layouts.
bind("SUPER + code:10", dsp.focus({ workspace = 1 }))    -- workspace 1
bind("SUPER + code:11", dsp.focus({ workspace = 2 }))    -- workspace 2
bind("SUPER + code:12", dsp.focus({ workspace = 3 }))    -- workspace 3
bind("SUPER + code:13", dsp.focus({ workspace = 4 }))    -- workspace 4
bind("SUPER + code:14", dsp.focus({ workspace = 5 }))    -- workspace 5
bind("SUPER + code:15", dsp.focus({ workspace = 6 }))    -- workspace 6
bind("SUPER + code:16", dsp.focus({ workspace = 7 }))    -- workspace 7
bind("SUPER + code:17", dsp.focus({ workspace = 8 }))    -- workspace 8
bind("SUPER + code:18", dsp.focus({ workspace = 9 }))    -- workspace 9
bind("SUPER + code:19", dsp.focus({ workspace = 10 }))   -- workspace 10

bind("SUPER + SHIFT + code:10", dsp.window.move({ workspace = 1 }))    -- move to workspace 1
bind("SUPER + SHIFT + code:11", dsp.window.move({ workspace = 2 }))    -- move to workspace 2
bind("SUPER + SHIFT + code:12", dsp.window.move({ workspace = 3 }))    -- move to workspace 3
bind("SUPER + SHIFT + code:13", dsp.window.move({ workspace = 4 }))    -- move to workspace 4
bind("SUPER + SHIFT + code:14", dsp.window.move({ workspace = 5 }))    -- move to workspace 5
bind("SUPER + SHIFT + code:15", dsp.window.move({ workspace = 6 }))    -- move to workspace 6
bind("SUPER + SHIFT + code:16", dsp.window.move({ workspace = 7 }))    -- move to workspace 7
bind("SUPER + SHIFT + code:17", dsp.window.move({ workspace = 8 }))    -- move to workspace 8
bind("SUPER + SHIFT + code:18", dsp.window.move({ workspace = 9 }))    -- move to workspace 9
bind("SUPER + SHIFT + code:19", dsp.window.move({ workspace = 10 }))   -- move to workspace 10

bind("SUPER + CTRL + code:10", dsp.window.move({ workspace = 1, follow = false }))    -- send to workspace 1
bind("SUPER + CTRL + code:11", dsp.window.move({ workspace = 2, follow = false }))    -- send to workspace 2
bind("SUPER + CTRL + code:12", dsp.window.move({ workspace = 3, follow = false }))    -- send to workspace 3
bind("SUPER + CTRL + code:13", dsp.window.move({ workspace = 4, follow = false }))    -- send to workspace 4
bind("SUPER + CTRL + code:14", dsp.window.move({ workspace = 5, follow = false }))    -- send to workspace 5
bind("SUPER + CTRL + code:15", dsp.window.move({ workspace = 6, follow = false }))    -- send to workspace 6
bind("SUPER + CTRL + code:16", dsp.window.move({ workspace = 7, follow = false }))    -- send to workspace 7
bind("SUPER + CTRL + code:17", dsp.window.move({ workspace = 8, follow = false }))    -- send to workspace 8
bind("SUPER + CTRL + code:18", dsp.window.move({ workspace = 9, follow = false }))    -- send to workspace 9
bind("SUPER + CTRL + code:19", dsp.window.move({ workspace = 10, follow = false }))   -- send to workspace 10

bind("SUPER + tab",            dsp.focus({ workspace = "m+1" }))   -- next workspace on monitor
bind("SUPER + SHIFT + tab",    dsp.focus({ workspace = "m-1" }))   -- previous workspace on monitor
bind("SUPER + period",         dsp.focus({ workspace = "e+1" }))   -- next workspace
bind("SUPER + comma",          dsp.focus({ workspace = "e-1" }))   -- previous workspace
bind("SUPER + mouse_down",     dsp.focus({ workspace = "e+1" }))   -- next workspace
bind("SUPER + mouse_up",       dsp.focus({ workspace = "e-1" }))   -- previous workspace

bind("SUPER + SHIFT + bracketleft",  dsp.window.move({ workspace = "-1" }))                   -- move to previous workspace
bind("SUPER + SHIFT + bracketright", dsp.window.move({ workspace = "+1" }))                   -- move to next workspace
bind("SUPER + CTRL + bracketleft",   dsp.window.move({ workspace = "-1", follow = false }))   -- send to previous workspace
bind("SUPER + CTRL + bracketright",  dsp.window.move({ workspace = "+1", follow = false }))   -- send to next workspace

-- Scratchpad
hl.workspace_rule({ workspace = "special:scratch", on_created_empty = fxn.term })
bind("SUPER + U",              dsp.workspace.toggle_special("scratch"))              -- toggle scratchpad
bind("SUPER + SHIFT + U",      dsp.window.move({ workspace = "special:scratch" }))   -- move to scratchpad

-- ─── Media & hardware keys ──────────────────────────────────
-- Routed through Quickshell so the OSD follows every change.
bind("XF86AudioRaiseVolume",   exec(qs .. "audio volumeUp"), held)        -- volume up
bind("XF86AudioLowerVolume",   exec(qs .. "audio volumeDown"), held)      -- volume down
bind("XF86AudioMute",          exec(qs .. "audio toggleMute"), locked)    -- mute
bind("XF86AudioMicMute",       exec(qs .. "audio toggleMicMute"), locked) -- mute microphone
bind("XF86MonBrightnessUp",    exec(qs .. "brightness up"), held)         -- brightness up
bind("XF86MonBrightnessDown",  exec(qs .. "brightness down"), held)       -- brightness down
bind("XF86KbdBrightnessUp",    exec(qs .. "brightness kbdUp"), held)      -- keyboard backlight up
bind("XF86KbdBrightnessDown",  exec(qs .. "brightness kbdDown"), held)    -- keyboard backlight down

bind("XF86AudioPlay",          exec(qs .. "mpris playPause"), locked)     -- play/pause
bind("XF86AudioPause",         exec(qs .. "mpris playPause"), locked)     -- play/pause
bind("XF86AudioNext",          exec(qs .. "mpris next"), locked)          -- next track
bind("XF86AudioPrev",          exec(qs .. "mpris previous"), locked)      -- previous track
bind("XF86AudioStop",          exec(qs .. "mpris stop"), locked)          -- stop

bind("XF86Sleep",              exec("systemctl suspend"), locked)         -- suspend
bind("XF86Rfkill",             exec(bin .. "/airplane-mode.sh"), locked)  -- airplane mode

-- ─── Screenshots ────────────────────────────────────────────
bind("SUPER + Print",              exec(bin .. "/screenshot.sh screen"))     -- screenshot: screen
bind("SUPER + SHIFT + Print",      exec(bin .. "/screenshot.sh area"))       -- screenshot: area
bind("ALT + Print",                exec(bin .. "/screenshot.sh window"))     -- screenshot: window
bind("SUPER + CTRL + Print",       exec(bin .. "/screenshot.sh delay 5"))    -- screenshot in 5s
bind("SUPER + CTRL + SHIFT + Print", exec(bin .. "/screenshot.sh delay 10")) -- screenshot in 10s
bind("SUPER + SHIFT + S",          exec(bin .. "/screenshot.sh edit"))       -- screenshot and edit

-- Same set on F6 for keyboards with no PrtSc
bind("SUPER + F6",             exec(bin .. "/screenshot.sh screen"))   -- screenshot: screen
bind("SUPER + SHIFT + F6",     exec(bin .. "/screenshot.sh area"))     -- screenshot: area
bind("ALT + F6",               exec(bin .. "/screenshot.sh window"))   -- screenshot: window

-- ─── Desktop zoom ───────────────────────────────────────────
bind("SUPER + ALT + mouse_down", exec(bin .. "/zoom.sh in"), repeating)    -- zoom in
bind("SUPER + ALT + mouse_up",   exec(bin .. "/zoom.sh out"), repeating)   -- zoom out
bind("SUPER + ALT + 0",          exec(bin .. "/zoom.sh reset"))            -- reset zoom
