local profile = require("profile")
local target = profile.phantomat.overview_target

assert(target == "active" or target == "all" or target:match("^[%w%-_]+$"),
  "Phantomat: overview_target must be active, all, or an exact output name")

local function command(action)
  if target ~= "active" then
    action = action .. " " .. target
  end
  return hl.plugin.spatialoverview.overview(action)
end

if profile.phantomat.mode == "canvas" then
  assert(target == "active",
    "Phantomat workspace Canvas always follows the focused real workspace; overview_target must be active")

  hl.bind(profile.phantomat_canvas_toggle_bind, hl.plugin.spatialoverview.canvas("workspace toggle"), {
    description = "Toggle Phantomat Canvas for this workspace",
    allow_input_capture = true,
  })

  -- Canvas mode and its navigation HUD are separate workspace-scoped states.
  hl.bind(profile.phantomat_navigator_toggle_bind, hl.plugin.spatialoverview.canvas("hud toggle"), {
    description = "Toggle Phantomat Canvas navigation HUD",
    allow_input_capture = true,
  })
else
  hl.bind(profile.phantomat_navigator_toggle_bind, command("toggle"), {
    description = "Toggle Phantomat overview on " .. target,
  })
end
