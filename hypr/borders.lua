-- Native rules follow each workspace's monitor, not a guessed output order.
local index = require("runtime").bundle.hyprOutputPalettes
local directory = assert(index:match("^(.*)/"), "ui-shell: output palette index must have an absolute path")

for _, output in ipairs(dofile(index)) do
  local colors = dofile(directory .. "/" .. output.palette)
  local workspace = "m[" .. output.output .. "]"
  -- Group and locked-group decoration retain their explicit global policy.
  hl.window_rule({
    name = "ui-shell-border-" .. output.id .. "-active",
    match = { workspace = workspace, focus = true, group = false },
    border_color = colors.active_border,
  })
  hl.window_rule({
    name = "ui-shell-border-" .. output.id .. "-inactive",
    match = { workspace = workspace, focus = false, group = false },
    -- 0.56.2 fills only the active slot for a single-gradient effect, and its
    -- paired-gradient parser omits inactive OKLab initialization. A native
    -- solid-color pair initializes both slots; this unfocused rule uses the
    -- configured inactive color for both. No callbacks or version branches.
    border_color = colors.hyprland.inactive_border .. " " .. colors.hyprland.inactive_border,
  })
end
