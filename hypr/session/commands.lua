-- Native startup delegates profile preparation to the configured runtime command.
local runtime = require("runtime")
require("wallpaper")

local function shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local runtime_env = "env UI_SHELL_RUNTIME=" .. shell_quote(runtime.runtimeFile)
local prepare_palettes = runtime_env .. " " .. shell_quote(runtime.commands.preparePalettes)
local start_wallpaper = "hyprpaper --config " .. shell_quote(runtime.bundle.hyprpaper)
-- The session bootstrap already compiled this generation before Hyprland loaded it.
local start_shell = runtime_env .. " qs --no-duplicate --path "
  .. shell_quote(runtime.paths.quickshell)

return {
  prepare_palettes = prepare_palettes,
  start_wallpaper = start_wallpaper,
  start_shell = start_shell,
}
