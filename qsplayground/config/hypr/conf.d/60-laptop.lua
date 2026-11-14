-- ─── Laptop-specific ─────────────────────────────────────────
-- ASUS ROG. Harmless on a desktop — the binds just never fire and
-- the device rule no-ops if the touchpad isn't present.

-- Keep in step with bin/touchpad.sh.
fxn.touchpad = "asue1209:00-04f3:319f-touchpad"

hl.device({ name = fxn.touchpad, enabled = true })

local function exec(cmd) return hl.dsp.exec_cmd(cmd) end

-- ASUS hardware keys
hl.bind("XF86Launch1",        exec("rog-control-center"))         -- Armoury Crate key
hl.bind("XF86Launch3",        exec("asusctl led-mode -n"))        -- Fn+F4  keyboard RGB profile
hl.bind("XF86Launch4",        exec("asusctl profile -n"))         -- Fn+F5  fan profile
hl.bind("XF86TouchpadToggle", exec(fxn.bin .. "/touchpad.sh"))   -- toggle touchpad

-- ─── Lid switch ─────────────────────────────────────────────
-- Disable the internal panel on close, restore on open. Suspend is
-- logind's job: it suspends on close unless an external display is
-- attached (HandleLidSwitchDocked=ignore), which is exactly when the
-- script disables the panel instead.
hl.bind("switch:on:Lid Switch",  exec(fxn.bin .. "/lid.sh close"), { locked = true })  -- lid closed
hl.bind("switch:off:Lid Switch", exec(fxn.bin .. "/lid.sh open"),  { locked = true })  -- lid opened
