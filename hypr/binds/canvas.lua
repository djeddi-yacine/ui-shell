local profile = require("profile")
local mod = profile.main_mod

local native_direction = { left = "l", right = "r", up = "u", down = "d" }

local function canvas_or_native(canvas_action, native_action)
  return function()
    local action = hl.plugin.spatialoverview.workspace_canvas_active()
      and canvas_action or native_action
    hl.dispatch(action)
  end
end

for key, direction in pairs({ LEFT = "left", RIGHT = "right", UP = "up", DOWN = "down" }) do
  hl.bind(mod .. " + " .. key,
    canvas_or_native(hl.plugin.spatialoverview.navigate(direction), hl.dsp.focus({ direction = native_direction[direction] })), {
    description = "Focus window " .. direction,
    repeating = true,
  })
  hl.bind(profile.action_mod .. " + " .. key,
    canvas_or_native(hl.plugin.spatialoverview.canvas("nudge " .. direction), hl.dsp.window.move({ direction = native_direction[direction] })), {
    description = "Move window " .. direction,
    repeating = true,
  })
end

hl.bind(profile.window_maximize_bind,
  canvas_or_native(hl.plugin.spatialoverview.canvas("fill"), hl.dsp.window.fullscreen({ mode = "maximized" })), {
  description = "Toggle maximized or Canvas fill",
})
hl.bind(mod .. " + Z",
  canvas_or_native(hl.plugin.spatialoverview.canvas("pin"), hl.dsp.window.float()), {
  description = "Toggle floating or Canvas pin",
})

-- Native switcher watches Alt release even when Ctrl is also held. A quick
-- tap flips windows; holding Alt reveals the list, as in the creator's tests.
hl.bind(profile.window_cycle_mod .. " + TAB",
  canvas_or_native(hl.plugin.spatialoverview.canvas("switch next"), hl.dsp.window.cycle_next()), {
  description = "Focus next window",
  repeating = true,
})
hl.bind(profile.window_cycle_previous_bind,
  canvas_or_native(hl.plugin.spatialoverview.canvas("switch prev"), hl.dsp.window.cycle_next({ next = false })), {
  description = "Focus previous window",
  repeating = true,
})
