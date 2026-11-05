-- Phantomat is optional and isolated from the normal workspace policy.
-- Its binary is intentionally built by this project's Makefile, never loaded
-- from a mutable system-wide plugin directory.
local profile = require("profile")
local settings = profile.phantomat
assert(settings.mode == "overview" or settings.mode == "canvas",
  "Phantomat: mode must be overview or canvas")

if not settings.enabled then
  return
end

local runtime = require("runtime")
local colors = dofile(runtime.bundle.hyprPalette)

local function native_color(value)
  return "rgb(" .. value:sub(2) .. ")"
end

local function navigator_colors(palette)
  return {
    panel = native_color(palette.surface),
    card = native_color(palette.elevated),
    edge = native_color(palette.outline),
    text = native_color(palette.text),
    text_dim = native_color(palette.text_muted),
    text_faint = native_color(palette.text_muted),
  }
end

hl.plugin.load(runtime.paths.phantomatLibrary)

local loaded = false
for _, plugin in ipairs(hl.get_loaded_plugins()) do
  if plugin.name == "spatialoverview" then
    loaded = true
    break
  end
end
assert(loaded, "Phantomat: spatialoverview plugin did not load")

hl.curve("phantomat-overview", {
  type = "bezier",
  points = { { 0.22, 1 }, { 0.36, 1 } },
})

-- Overview and canvas are complete native settings tables, not implicit
-- combinations of flags that can accidentally mix window-management modes.
local config = {
      layout = "grid",
      scale = 0.42,
      workspace_gap = 16,
      grid = {
        columns = 3,
        stagger = 0,
      },
      animation = {
        enabled = true,
        speed = 4,
        bezier = "phantomat-overview",
      },
      workspace_outline = {
        enabled = true,
        width = 2,
        drop_width = 3,
        rounding = 0,
        opacity = 0.3,
        active_opacity = 0.85,
        drop_opacity = 1,
        drop_fill_opacity = 0.1,
      },
      canvas = {
        enabled = false,
        desktop_mode = false,
        workspace_bound = false,
        persistent = false,
        linked_screens = false,
        places = false,
        auto_float = false,
        auto_place = false,
        remember_layout = false,
        remember_overview = false,
        space_pan = false,
        direct_input = true,
        hover_focus = true,
        minimap_enabled = true,
        grid_enabled = false,
        snap_enabled = false,
        viewport_enabled = false,
        viewport_rounding = 0,
      },
      navigator = {
        enabled = false,
        labels = true,
        dim_unmatched = 0.7,
        pointer = true,
        accent = colors.accent,
        mono_font = "Monospace",
        hud_scale = 1,
        rounding = 0,
        panel_opacity = 0.96,
      },
      distortion = {
        enabled = false,
        strength = 0,
        edge_blur = 0,
        vignette = 0,
        chromatic = 0,
      },
      parallax = {
        enabled = false,
        strength = 0,
        depth = 0,
        desktop = false,
      },
      blur = false,
}

if settings.mode == "canvas" then
  config = require("user.canvas")
end

-- Configured global colors are the explicit default for unassigned outputs.
config.navigator.accent = colors.accent
config.navigator.colors = navigator_colors(colors)
hl.config({ plugin = { spatialoverview = config } })

-- Reuse the bundle's native output index, replacing the complete override map
-- on reload. Static config contains neither device names nor generated paths.
local index = runtime.bundle.hyprOutputPalettes
local directory = assert(index:match("^(.*)/"),
  "Phantomat: output palette index must have an absolute path")
local output_colors = {}
for _, output in ipairs(dofile(index)) do
  local palette = dofile(directory .. "/" .. output.palette)
  local roles = navigator_colors(palette)
  roles.accent = native_color(palette.accent)
  output_colors[output.output] = roles
end
hl.plugin.spatialoverview.output_colors(output_colors)

if settings.mode == "canvas" then
  require("binds.canvas")
end

require("binds.phantomat")
