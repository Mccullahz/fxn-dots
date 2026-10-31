-- ─── Laptop-specific ─────────────────────────────────────────
-- ASUS ROG. Harmless on a desktop — the binds just never fire and
-- the device rule no-ops if the touchpad isn't present.

local bind, dsp = hl.bind, hl.dsp
local bin = fxn.bin

local function exec(cmd) return dsp.exec_cmd(cmd) end

-- bin/touchpad.sh toggles this device by name; keep the two in step.
-- It records "off" in a runtime flag, read here so a config reload
-- does not quietly re-enable a touchpad you switched off.
fxn.touchpad = "asue1209:00-04f3:319f-touchpad"

local runtime = os.getenv("XDG_RUNTIME_DIR") or ""
local flag = io.open(runtime .. "/fxn-touchpad-off", "r")
if flag then flag:close() end

hl.device({ name = fxn.touchpad, enabled = flag == nil })

-- ASUS hardware keys
bind("XF86Launch1",        exec("rog-control-center"))        -- Armoury Crate key
bind("XF86Launch3",        exec("asusctl led-mode -n"))       -- Fn+F4  keyboard RGB profile
bind("XF86Launch4",        exec("asusctl profile -n"))        -- Fn+F5  fan profile
bind("XF86TouchpadToggle", exec(bin .. "/touchpad.sh"))       -- toggle touchpad

-- ─── Lid switch ─────────────────────────────────────────────
-- Disable the internal panel on close, restore on open. Suspend is
-- logind's job: it suspends on close unless an external display is
-- attached (HandleLidSwitchDocked=ignore), which is exactly when the
-- script disables the panel instead.
bind("switch:on:Lid Switch",  exec(bin .. "/lid.sh close"), { locked = true })   -- lid closed
bind("switch:off:Lid Switch", exec(bin .. "/lid.sh open"), { locked = true })    -- lid opened
