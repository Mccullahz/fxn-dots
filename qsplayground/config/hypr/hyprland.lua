-- ─────────────────────────────────────────────────────────────
--  Hyprland — entry point
--
--  Hyprland 0.57 replaced hyprlang with Lua: hyprland.conf is no
--  longer read at all, and without this file Hyprland writes a
--  stock hyprland.lua and runs that instead.
--
--  Everything lives in conf.d/ and is loaded in numeric order.
--  Drop your own overrides in conf.d/99-local.lua; it is the last
--  file read and is never overwritten by promote.sh.
--
--  Paths are resolved from this file's own location, not $HOME, so
--  the same tree works unmodified in the QA sandbox (fake $HOME), in
--  promote.sh's verify step, and in the real session.
-- ─────────────────────────────────────────────────────────────

local cfg = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
    or (os.getenv("HOME") .. "/.config/hypr")

-- Shared between the conf.d modules. Each one is a plain dofile'd
-- chunk, so a global table is how they see each other's settings.
fxn = {
    cfg = cfg,
    bin = cfg .. "/bin",
}

-- Read a hyprlang-style `$name = value` file into a table. The theme
-- files in theme/ stay in that format because hyprlock (still on
-- hyprlang) sources them too; fxn-theme and wallust write them.
function fxn.read_vars(path)
    local vars = {}
    local f = io.open(path, "r")
    if not f then return vars end
    for line in f:lines() do
        local name, value = line:match("^%s*%$([%w_]+)%s*=%s*(.-)%s*$")
        if name then
            vars[name] = value:gsub("%s+#.*$", "")
        end
    end
    f:close()
    return vars
end

local modules = {
    "00-env",
    "10-monitors",
    "20-input",
    "30-look",
    "40-rules",
    "50-binds",
    "60-laptop",
    "70-autostart",
    "99-local",
}

-- A broken module must not take the rest of the desktop down with it
-- (an error in 50-binds would otherwise leave you with no autostart
-- and no local overrides). Load everything, then re-raise so the
-- errors still reach `hyprctl configerrors` and --verify-config.
local errors = {}
for _, name in ipairs(modules) do
    local path = cfg .. "/conf.d/" .. name .. ".lua"
    local f = io.open(path, "r")
    if f then
        f:close()
        local ok, err = pcall(dofile, path)
        if not ok then errors[#errors + 1] = tostring(err) end
    end
end

if #errors > 0 then
    error(table.concat(errors, "\n"), 0)
end
