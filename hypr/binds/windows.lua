local profile = require("profile")
local mod = profile.main_mod

hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd(profile.commands.terminal), { description = "Open terminal" })
hl.bind(mod .. " + L", hl.dsp.exec_cmd(profile.commands.lock), { description = "Lock session" })

hl.bind(profile.action_mod .. " + X", hl.dsp.window.close(), { description = "Close window" })
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), { description = "Toggle fullscreen" })
hl.bind(profile.mouse_mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move window" })
hl.bind(profile.mouse_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })

-- Persistent canvas owns positioning, focus, fill and pinning. Do not also
-- register normal floating/tiling actions on the same keys.
if profile.phantomat.enabled and profile.phantomat.mode == "canvas" then
  return
end

hl.bind(profile.window_maximize_bind, hl.dsp.window.fullscreen({ mode = "maximized" }), { description = "Toggle maximized" })
hl.bind(mod .. " + Z", hl.dsp.window.float(), { description = "Toggle floating" })

for key, direction in pairs({ LEFT = "l", RIGHT = "r", UP = "u", DOWN = "d" }) do
  hl.bind(mod .. " + " .. key, hl.dsp.focus({ direction = direction }), { description = "Focus " .. direction })
  hl.bind(profile.action_mod .. " + " .. key, hl.dsp.window.move({ direction = direction }), { description = "Move " .. direction })
end

hl.bind(profile.window_cycle_mod .. " + TAB", hl.dsp.window.cycle_next(), { description = "Focus next window" })
hl.bind(profile.window_cycle_previous_bind, hl.dsp.window.cycle_next({ next = false }), { description = "Focus previous window" })

