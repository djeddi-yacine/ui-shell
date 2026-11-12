-- Resolve the chosen compiled bundle without regenerating wallpaper outputs.
local runtime = require("runtime")
local selections = dofile(runtime.bundle.wallpaperRegistry)
local outputs_policy = require("userlua").load("monitors")
local folders = {}

for _, folder in ipairs(runtime.wallpaperFolders) do
  folders[folder.id] = folder.path
end

assert(selections.schema == 1, "Wallpaper: unsupported selection schema")
assert(selections.cache_namespace, "Wallpaper: cache namespace is required")
assert(selections.color_mode == "dark" or selections.color_mode == "light",
  "Wallpaper: color_mode must be dark or light")

local function resolve(output, selection)
  assert(type(selection) == "table", "Wallpaper: default and output selections must be tables")
  assert(selection.path and selection.fit_mode and selection.palette_key,
    "Wallpaper: each selection needs path, fit_mode, and palette_key")
  assert(selection.fit_mode == "contain" or selection.fit_mode == "cover"
    or selection.fit_mode == "tile" or selection.fit_mode == "fill",
    "Wallpaper: unsupported fit_mode")

  local folder_id = selection.folder
  assert(type(folder_id) == "string" and folder_id ~= "",
    "Wallpaper: each selection needs an explicit folder ID")
  local directory = assert(folders[folder_id],
    "Wallpaper: selection names an unknown folder: " .. tostring(folder_id))
  assert(selection.path ~= "" and not selection.path:find("/", 1, true)
    and not selection.path:find("%c"),
    "Wallpaper: selection path must be a filename in its configured folder")

  return {
    output = output,
    source = directory .. "/" .. selection.path,
    folder = folder_id,
    fit_mode = selection.fit_mode,
    palette_key = selection.palette_key,
  }
end

local default = resolve("", selections.default)
local by_output = { [""] = default }
local entries = { default }
local outputs = {}

for output in pairs(selections.monitors) do
  table.insert(outputs, output)
end
table.sort(outputs)

for _, output in ipairs(outputs) do
  local entry = resolve(output, selections.monitors[output])
  by_output[output] = entry
  table.insert(entries, entry)
end

local palette_source = outputs_policy.palette_source
assert(palette_source and (palette_source.kind == "default-wallpaper"
    or palette_source.kind == "output-wallpaper"),
  "Wallpaper: palette_source.kind must be default-wallpaper or output-wallpaper")

local primary
if palette_source.kind == "default-wallpaper" then
  primary = default
else
  assert(palette_source.output and palette_source.output ~= "",
    "Wallpaper: output-wallpaper requires an output name")
  primary = assert(by_output[palette_source.output],
    "Wallpaper: chosen palette output has no saved wallpaper selection")
end

return {
  entries = entries,
  by_output = by_output,
  primary = primary,
  wallpaper_registry = runtime.bundle.wallpaperRegistry,
  hyprpaper_config = runtime.bundle.hyprpaper,
  shell_path = runtime.paths.quickshell,
}
