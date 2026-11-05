local profile = require("profile")
local mod = profile.main_mod

-- Grouping is opt-in. A short submap gives groups their own vocabulary without
-- consuming every modifier combination in the normal keymap.
hl.bind(mod .. " + G", hl.dsp.submap("groups"), { description = "Enter group controls" })

local function group_bind(key, dispatcher, description)
  hl.bind(key, function()
    hl.dispatch(dispatcher)
    hl.dispatch(hl.dsp.submap("reset"))
  end, { description = description })
end

hl.define_submap("groups", function()
  group_bind("G", hl.dsp.group.toggle(), "Toggle group")
  group_bind("H", hl.dsp.window.move({ into_group = "l" }), "Move window into left group")
  group_bind("J", hl.dsp.window.move({ into_group = "d" }), "Move window into lower group")
  group_bind("K", hl.dsp.window.move({ into_group = "u" }), "Move window into upper group")
  group_bind("L", hl.dsp.window.move({ into_group = "r" }), "Move window into right group")
  group_bind("E", hl.dsp.window.move({ out_of_group = true }), "Move window out of group")
  group_bind("N", hl.dsp.group.next(), "Focus next group window")
  group_bind("P", hl.dsp.group.prev(), "Focus previous group window")
  group_bind("F", hl.dsp.group.move_window(), "Move group window forward")
  group_bind("B", hl.dsp.group.move_window({ forward = false }), "Move group window backward")
  group_bind("T", hl.dsp.group.lock({ action = "toggle" }), "Toggle group lock")
  hl.bind("ESCAPE", hl.dsp.submap("reset"), { description = "Leave group controls" })
end)
