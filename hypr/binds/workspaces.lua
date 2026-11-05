local profile = require("profile")
local mod = profile.main_mod

-- This special workspace is permanently a scrolling tape. Hyprland 0.56
-- ships the scrolling layout, so no third-party layout plugin is necessary.
hl.workspace_rule({
  workspace = "special:scroll",
  layout = "scrolling",
  layout_opts = { direction = "right" },
})

-- Keycodes make the row stable for the US/Arabic layout pair.
for workspace = 1, 10 do
  local keycode = "code:" .. tostring(workspace + 9)
  local target = tostring(workspace)

  hl.bind(mod .. " + " .. keycode, hl.dsp.focus({ workspace = target }), {
    description = "Focus workspace " .. target,
  })
  hl.bind(profile.action_mod .. " + " .. keycode, hl.dsp.window.move({ workspace = target }), {
    description = "Move window to workspace " .. target,
  })
  hl.bind(profile.workspace_silent_mod .. " + " .. keycode, hl.dsp.window.move({ workspace = target, follow = false }), {
    description = "Move window silently to workspace " .. target,
  })
end

-- Canvas workspaces own their windows spatially. Creating a hidden native
-- workspace from one would strand the window outside the canvas camera.
local function native_workspace_only(action)
  return function()
    if hl.plugin.spatialoverview.workspace_canvas_active() then
      return
    end
    hl.dispatch(action)
  end
end

hl.bind(profile.workspace_previous_bind, hl.dsp.focus({ workspace = "previous" }), { description = "Focus previous workspace" })
hl.bind(profile.workspace_empty_bind, hl.dsp.focus({ workspace = "empty" }), { description = "Focus empty workspace" })
hl.bind(profile.workspace_move_empty_bind, native_workspace_only(hl.dsp.window.move({ workspace = "empty" })), {
  description = "Move window to empty workspace (native workspaces only)",
})

hl.bind(mod .. " + S", hl.dsp.workspace.toggle_special("scroll"), { description = "Toggle scrolling special workspace" })
hl.bind(profile.action_mod .. " + S", hl.dsp.window.move({ workspace = "special:scroll", follow = false }), { description = "Move window to scrolling special workspace" })


-- One-window hidden workspace. It is intentionally never toggled onscreen:
-- the same bind restores the tagged window to the active workspace.
hl.bind(mod .. " + X", function()
  local hidden = hl.get_workspace("special:hidden")
  if not hidden and hl.plugin.spatialoverview.workspace_canvas_active() then
    return
  end

  if hidden then
    hl.dispatch(hl.dsp.window.move({ workspace = hl.get_active_workspace(), window = "tag:hidden" }))
    hl.dispatch(hl.dsp.window.clear_tags({ window = "tag:hidden" }))
    return
  end

  local active = hl.get_active_window()
  if not active then
    return
  end

  hl.dispatch(hl.dsp.window.tag({ tag = "hidden", window = active }))
  hl.dispatch(hl.dsp.window.move({ workspace = "special:hidden", follow = false, window = active }))
end, { description = "Hide or restore window (native workspaces only)" })
