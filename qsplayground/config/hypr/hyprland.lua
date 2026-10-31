-- ─────────────────────────────────────────────────────────────
--  Hyprland — entry point
--
--  Hyprland 0.57+ reads Lua only; hyprlang is gone from the
--  compositor (hypridle and hyprlock still use it).
--
--  Everything lives in conf.d/ and is loaded in numeric order.
--  Drop your own overrides in conf.d/99-local.lua; it is the
--  last file read and is never overwritten by promote.sh.
--
--  Paths are all $HOME-relative on purpose: the QA sandbox runs
--  with a fake $HOME, so the exact same config works unmodified
--  in both the playground and the real session.
-- ─────────────────────────────────────────────────────────────

local cfg = os.getenv("HOME") .. "/.config/hypr"

-- Shared between the conf.d files, the way $variables were global
-- across sourced hyprlang files.
fxn = {
  cfg = cfg,
  bin = cfg .. "/bin",
}

-- theme/*.conf stay hyprlang: fxn-theme and wallust write them, and
-- hyprlock sources them. Read their `$name = value` lines into
-- fxn.theme rather than keeping a second copy in Lua.
fxn.theme = {}
for _, name in ipairs({ "colors.conf", "roles.conf" }) do
  local file = io.open(cfg .. "/theme/" .. name, "r")
  if file then
    for line in file:lines() do
      local key, value = line:match("^%s*%$([%w_]+)%s*=%s*(.-)%s*$")
      if key then fxn.theme[key] = value end
    end
    file:close()
  end
end

-- A failing file is reported, not fatal: the ones after it still load,
-- so a typo in the rules never costs you your keybinds.
local errors = {}
local function load(name, optional)
  local path = cfg .. "/conf.d/" .. name
  local chunk, err = loadfile(path)
  if not chunk then
    if not (optional and err:find("No such file", 1, true)) then
      errors[#errors + 1] = err
    end
    return
  end
  local ok, run_err = pcall(chunk)
  if not ok then errors[#errors + 1] = tostring(run_err) end
end

load("00-env.lua")
load("10-monitors.lua")
load("20-input.lua")
load("30-look.lua")
load("40-rules.lua")
load("50-binds.lua")
load("60-laptop.lua")
load("70-autostart.lua")
load("99-local.lua", true)

if #errors > 0 then
  error(table.concat(errors, "\n"), 0)
end
