-- ─── Keybinds ────────────────────────────────────────────────
-- https://wiki.hypr.land/configuring/core/binds/
--
-- Anything that used to shell out to rofi / wlogout / swaync now
-- talks to Quickshell over IPC. `qs -c fxn ipc call <target> <fn>`
-- is cheap — it is a unix-socket round trip, no process spawn.
--
-- The Quickshell cheat sheet (SUPER+H) reads this file: keep one
-- hl.bind per line, with the description as a trailing `-- comment`.
-- `-- ─── Section ───` headers become its groups.

local dsp  = hl.dsp
local bin  = fxn.bin
local term = fxn.term

local function exec(cmd) return dsp.exec_cmd(cmd) end
local function qs(call) return dsp.exec_cmd("qs -c fxn ipc call " .. call) end

-- Replacement for the removed `workspaceopt allfloat`: float every
-- window on the workspace, or tile them all back if none are tiled.
local function toggle_all_float()
    local ws = hl.get_active_workspace()
    if not ws then return end
    local windows = ws:get_windows() or {}
    local any_tiled = false
    for _, w in ipairs(windows) do
        if not w.floating then any_tiled = true; break end
    end
    for _, w in ipairs(windows) do
        hl.dispatch(dsp.window.float({ window = "address:" .. w.address, action = any_tiled and "enable" or "disable" }))
    end
end

-- ALT+Tab: focus the next window and raise it.
local function cycle_and_raise()
    hl.dispatch(dsp.window.cycle_next())
    hl.dispatch(dsp.window.alter_zorder({ mode = "top" }))
end

local repeating = { repeating = true }
local locked    = { locked = true }
local lockedrep = { locked = true, repeating = true }
local mouse     = { mouse = true }

-- ─── Launching ──────────────────────────────────────────────
hl.bind("SUPER + Return",         exec(term))                                    -- terminal
hl.bind("SUPER + SHIFT + Return", dsp.exec_cmd(term, { float = true, move = { "monitor_w*0.15", "monitor_h*0.05" }, size = { "monitor_w*0.7", "monitor_h*0.6" } })) -- floating terminal
hl.bind("SUPER + E",              exec(fxn.files))                               -- file manager
hl.bind("SUPER + B",              exec(fxn.browser))                             -- browser

-- ─── Quickshell surfaces ────────────────────────────────────
hl.bind("SUPER + D",            qs("launcher toggle"))          -- app launcher
hl.bind("SUPER + S",            qs("launcher openWeb"))         -- web search
hl.bind("SUPER + ALT + C",      qs("launcher openCalc"))        -- calculator
hl.bind("SUPER + ALT + E",      qs("launcher openEmoji"))       -- emoji picker
hl.bind("SUPER + ALT + V",      qs("launcher openClipboard"))   -- clipboard history
hl.bind("SUPER + A",            qs("overview toggle"))          -- workspace overview
hl.bind("SUPER + W",            qs("wallpaper toggle"))         -- wallpaper picker
hl.bind("SUPER + H",            qs("cheatsheet toggle"))        -- this keybind list
hl.bind("SUPER + SHIFT + N",    qs("controlcenter toggle"))     -- notifications + toggles
hl.bind("SUPER + SHIFT + D",    qs("notifications toggleDnd"))  -- do-not-disturb
hl.bind("CTRL + ALT + P",       qs("powermenu toggle"))         -- power menu
hl.bind("SUPER + grave",        qs("edge toggle"))              -- open the edge island
hl.bind("SUPER + CTRL + ALT + B", qs("bar toggle"))             -- hide/show the bar

hl.bind("SUPER + Escape",       qs("shell dismiss"))            -- close whatever is open
hl.bind("CTRL + ALT + L",       exec("loginctl lock-session"))  -- lock (hyprlock via hypridle)
hl.bind("CTRL + ALT + Delete",  dsp.exit())                     -- exit Hyprland

-- ─── Window management ──────────────────────────────────────
hl.bind("SUPER + Q",            dsp.window.close())                              -- close window
hl.bind("SUPER + SHIFT + Q",    exec(bin .. "/kill-active.sh"))                  -- kill window
hl.bind("SUPER + SPACE",        dsp.window.float())                              -- toggle floating
hl.bind("SUPER + ALT + SPACE",  toggle_all_float)                                -- float/tile whole workspace
hl.bind("SUPER + SHIFT + F",    dsp.window.fullscreen({ mode = "fullscreen" }))  -- fullscreen
hl.bind("SUPER + CTRL + F",     dsp.window.fullscreen({ mode = "maximized" }))   -- maximize
hl.bind("SUPER + P",            dsp.window.pseudo())                             -- pseudotile
hl.bind("SUPER + G",            dsp.group.toggle())                              -- toggle group
hl.bind("SUPER + CTRL + tab",   dsp.group.next())                                -- next in group
hl.bind("SUPER + CTRL + O",     dsp.window.set_prop({ prop = "opaque", value = "toggle" })) -- toggle opaque

hl.bind("ALT + tab",            cycle_and_raise)                                 -- cycle windows

-- Master layout
hl.bind("SUPER + CTRL + D",      dsp.layout("removemaster"))    -- remove master
hl.bind("SUPER + I",             dsp.layout("addmaster"))       -- add master
hl.bind("SUPER + J",             dsp.layout("cyclenext"))       -- cycle next
hl.bind("SUPER + K",             dsp.layout("cycleprev"))       -- cycle previous
hl.bind("SUPER + CTRL + Return", dsp.layout("swapwithmaster"))  -- swap with master
hl.bind("SUPER + M",             dsp.layout("togglesplit"))     -- toggle split

-- Focus
hl.bind("SUPER + left",  dsp.focus({ direction = "left" }))   -- focus left
hl.bind("SUPER + right", dsp.focus({ direction = "right" }))  -- focus right
hl.bind("SUPER + up",    dsp.focus({ direction = "up" }))     -- focus up
hl.bind("SUPER + down",  dsp.focus({ direction = "down" }))   -- focus down

-- Move
hl.bind("SUPER + CTRL + left",  dsp.window.move({ direction = "left" }))   -- move left
hl.bind("SUPER + CTRL + right", dsp.window.move({ direction = "right" }))  -- move right
hl.bind("SUPER + CTRL + up",    dsp.window.move({ direction = "up" }))     -- move up
hl.bind("SUPER + CTRL + down",  dsp.window.move({ direction = "down" }))   -- move down

-- Swap
hl.bind("SUPER + ALT + left",  dsp.window.swap({ direction = "left" }))   -- swap left
hl.bind("SUPER + ALT + right", dsp.window.swap({ direction = "right" }))  -- swap right
hl.bind("SUPER + ALT + up",    dsp.window.swap({ direction = "up" }))     -- swap up
hl.bind("SUPER + ALT + down",  dsp.window.swap({ direction = "down" }))   -- swap down

-- Resize
hl.bind("SUPER + SHIFT + left",  dsp.window.resize({ x = -50, y = 0, relative = true }), repeating)  -- shrink width
hl.bind("SUPER + SHIFT + right", dsp.window.resize({ x = 50, y = 0, relative = true }), repeating)   -- grow width
hl.bind("SUPER + SHIFT + up",    dsp.window.resize({ x = 0, y = -50, relative = true }), repeating)  -- shrink height
hl.bind("SUPER + SHIFT + down",  dsp.window.resize({ x = 0, y = 50, relative = true }), repeating)   -- grow height

hl.bind("SUPER + mouse:272", dsp.window.drag(),   mouse)  -- drag window
hl.bind("SUPER + mouse:273", dsp.window.resize(), mouse)  -- resize window

-- ─── Workspaces ─────────────────────────────────────────────
-- code:10 = "1", code:11 = "2" ... code:19 = "0".
-- Using keycodes keeps these working on non-US layouts.
hl.bind("SUPER + code:10", dsp.focus({ workspace = 1 }))   -- workspace 1
hl.bind("SUPER + code:11", dsp.focus({ workspace = 2 }))   -- workspace 2
hl.bind("SUPER + code:12", dsp.focus({ workspace = 3 }))   -- workspace 3
hl.bind("SUPER + code:13", dsp.focus({ workspace = 4 }))   -- workspace 4
hl.bind("SUPER + code:14", dsp.focus({ workspace = 5 }))   -- workspace 5
hl.bind("SUPER + code:15", dsp.focus({ workspace = 6 }))   -- workspace 6
hl.bind("SUPER + code:16", dsp.focus({ workspace = 7 }))   -- workspace 7
hl.bind("SUPER + code:17", dsp.focus({ workspace = 8 }))   -- workspace 8
hl.bind("SUPER + code:18", dsp.focus({ workspace = 9 }))   -- workspace 9
hl.bind("SUPER + code:19", dsp.focus({ workspace = 10 }))  -- workspace 10

hl.bind("SUPER + SHIFT + code:10", dsp.window.move({ workspace = 1 }))   -- move to workspace 1
hl.bind("SUPER + SHIFT + code:11", dsp.window.move({ workspace = 2 }))   -- move to workspace 2
hl.bind("SUPER + SHIFT + code:12", dsp.window.move({ workspace = 3 }))   -- move to workspace 3
hl.bind("SUPER + SHIFT + code:13", dsp.window.move({ workspace = 4 }))   -- move to workspace 4
hl.bind("SUPER + SHIFT + code:14", dsp.window.move({ workspace = 5 }))   -- move to workspace 5
hl.bind("SUPER + SHIFT + code:15", dsp.window.move({ workspace = 6 }))   -- move to workspace 6
hl.bind("SUPER + SHIFT + code:16", dsp.window.move({ workspace = 7 }))   -- move to workspace 7
hl.bind("SUPER + SHIFT + code:17", dsp.window.move({ workspace = 8 }))   -- move to workspace 8
hl.bind("SUPER + SHIFT + code:18", dsp.window.move({ workspace = 9 }))   -- move to workspace 9
hl.bind("SUPER + SHIFT + code:19", dsp.window.move({ workspace = 10 }))  -- move to workspace 10

hl.bind("SUPER + CTRL + code:10", dsp.window.move({ workspace = 1, follow = false }))   -- send to workspace 1
hl.bind("SUPER + CTRL + code:11", dsp.window.move({ workspace = 2, follow = false }))   -- send to workspace 2
hl.bind("SUPER + CTRL + code:12", dsp.window.move({ workspace = 3, follow = false }))   -- send to workspace 3
hl.bind("SUPER + CTRL + code:13", dsp.window.move({ workspace = 4, follow = false }))   -- send to workspace 4
hl.bind("SUPER + CTRL + code:14", dsp.window.move({ workspace = 5, follow = false }))   -- send to workspace 5
hl.bind("SUPER + CTRL + code:15", dsp.window.move({ workspace = 6, follow = false }))   -- send to workspace 6
hl.bind("SUPER + CTRL + code:16", dsp.window.move({ workspace = 7, follow = false }))   -- send to workspace 7
hl.bind("SUPER + CTRL + code:17", dsp.window.move({ workspace = 8, follow = false }))   -- send to workspace 8
hl.bind("SUPER + CTRL + code:18", dsp.window.move({ workspace = 9, follow = false }))   -- send to workspace 9
hl.bind("SUPER + CTRL + code:19", dsp.window.move({ workspace = 10, follow = false }))  -- send to workspace 10

hl.bind("SUPER + tab",        dsp.focus({ workspace = "m+1" }))  -- next workspace on monitor
hl.bind("SUPER + SHIFT + tab", dsp.focus({ workspace = "m-1" })) -- previous workspace on monitor
hl.bind("SUPER + period",     dsp.focus({ workspace = "e+1" }))  -- next workspace
hl.bind("SUPER + comma",      dsp.focus({ workspace = "e-1" }))  -- previous workspace
hl.bind("SUPER + mouse_down", dsp.focus({ workspace = "e+1" }))  -- next workspace
hl.bind("SUPER + mouse_up",   dsp.focus({ workspace = "e-1" }))  -- previous workspace

hl.bind("SUPER + SHIFT + bracketleft",  dsp.window.move({ workspace = "-1" }))                  -- move to previous workspace
hl.bind("SUPER + SHIFT + bracketright", dsp.window.move({ workspace = "+1" }))                  -- move to next workspace
hl.bind("SUPER + CTRL + bracketleft",   dsp.window.move({ workspace = "-1", follow = false }))  -- send to previous workspace
hl.bind("SUPER + CTRL + bracketright",  dsp.window.move({ workspace = "+1", follow = false }))  -- send to next workspace

-- Scratchpad
hl.bind("SUPER + U",         dsp.workspace.toggle_special("scratch"))               -- toggle scratchpad
hl.bind("SUPER + SHIFT + U", dsp.window.move({ workspace = "special:scratch" }))   -- move to scratchpad

-- ─── Media & hardware keys ──────────────────────────────────
-- Routed through Quickshell so the OSD follows every change.
hl.bind("XF86AudioRaiseVolume",  qs("audio volumeUp"),      lockedrep)  -- volume up
hl.bind("XF86AudioLowerVolume",  qs("audio volumeDown"),    lockedrep)  -- volume down
hl.bind("XF86AudioMute",         qs("audio toggleMute"),    locked)     -- mute
hl.bind("XF86AudioMicMute",      qs("audio toggleMicMute"), locked)     -- mute mic
hl.bind("XF86MonBrightnessUp",   qs("brightness up"),       lockedrep)  -- brightness up
hl.bind("XF86MonBrightnessDown", qs("brightness down"),     lockedrep)  -- brightness down
hl.bind("XF86KbdBrightnessUp",   qs("brightness kbdUp"),    lockedrep)  -- keyboard light up
hl.bind("XF86KbdBrightnessDown", qs("brightness kbdDown"),  lockedrep)  -- keyboard light down

hl.bind("XF86AudioPlay",      qs("mpris playPause"), locked)  -- play/pause
hl.bind("XF86AudioPause",     qs("mpris playPause"), locked)  -- play/pause
hl.bind("XF86AudioNext",      qs("mpris next"),      locked)  -- next track
hl.bind("XF86AudioPrev",      qs("mpris previous"),  locked)  -- previous track
hl.bind("XF86AudioStop",      qs("mpris stop"),      locked)  -- stop

hl.bind("XF86Sleep",  exec("systemctl suspend"),            locked)  -- suspend
hl.bind("XF86Rfkill", exec(bin .. "/airplane-mode.sh"),     locked)  -- airplane mode

-- ─── Screenshots ────────────────────────────────────────────
hl.bind("SUPER + Print",              exec(bin .. "/screenshot.sh screen"))    -- screenshot screen
hl.bind("SUPER + SHIFT + Print",      exec(bin .. "/screenshot.sh area"))      -- screenshot area
hl.bind("ALT + Print",                exec(bin .. "/screenshot.sh window"))    -- screenshot window
hl.bind("SUPER + CTRL + Print",       exec(bin .. "/screenshot.sh delay 5"))   -- screenshot in 5s
hl.bind("SUPER + CTRL + SHIFT + Print", exec(bin .. "/screenshot.sh delay 10")) -- screenshot in 10s
hl.bind("SUPER + SHIFT + S",          exec(bin .. "/screenshot.sh edit"))      -- screenshot and edit

-- Same set on F6 for keyboards with no PrtSc
hl.bind("SUPER + F6",         exec(bin .. "/screenshot.sh screen"))  -- screenshot screen
hl.bind("SUPER + SHIFT + F6", exec(bin .. "/screenshot.sh area"))    -- screenshot area
hl.bind("ALT + F6",           exec(bin .. "/screenshot.sh window"))  -- screenshot window

-- ─── Desktop zoom ───────────────────────────────────────────
hl.bind("SUPER + ALT + mouse_down", exec(bin .. "/zoom.sh in"),  repeating)  -- zoom in
hl.bind("SUPER + ALT + mouse_up",   exec(bin .. "/zoom.sh out"), repeating)  -- zoom out
hl.bind("SUPER + ALT + 0",          exec(bin .. "/zoom.sh reset"))           -- reset zoom
