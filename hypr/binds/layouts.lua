local profile = require("profile")
local mod = profile.layout_mod
local layouts = { "dwindle", "scrolling", "master", "monocle" }

-- Fixed layouts target the active regular workspace. Special workspaces keep
-- their explicit rules, particularly the scrolling scratchpad.
for _, binding in ipairs({
  { key = "F1", layout = "dwindle" },
  { key = "F2", layout = "scrolling" },
  { key = "F3", layout = "master" },
  { key = "F4", layout = "monocle" },
}) do
  hl.bind(mod .. " + " .. binding.key, function()
    local workspace = hl.get_active_workspace()
    if not workspace or workspace.special then
      return
    end

    hl.workspace_rule({
      workspace = "name:" .. tostring(workspace.name),
      layout = binding.layout,
    })
  end, { description = "Set current workspace layout to " .. binding.layout })
end

-- Layout is per workspace. Special workspaces retain their explicit rules.
hl.bind(mod .. " + " .. profile.layout_cycle_key, function()
  local workspace = hl.get_active_workspace()
  if not workspace then
    return
  end

  for index, layout in ipairs(layouts) do
    if layout == workspace.tiled_layout then
      hl.workspace_rule({
        workspace = "name:" .. tostring(workspace.name),
        layout = layouts[(index % #layouts) + 1],
      })
      return
    end
  end

  hl.workspace_rule({ workspace = "name:" .. tostring(workspace.name), layout = layouts[1] })
end, { description = "Cycle current workspace layout" })

local function layout_action(actions)
  return function()
    local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
    if not workspace or not actions[workspace.tiled_layout] then
      return
    end
    hl.dispatch(actions[workspace.tiled_layout])
  end
end

hl.bind(mod .. " + A", layout_action({
  scrolling = hl.dsp.layout("swapcol l"),
  dwindle = hl.dsp.layout("swapsplit"),
  monocle = hl.dsp.layout("cycleprev"),
  master = hl.dsp.layout("cycleprev"),
}), { description = "Previous layout action" })

hl.bind(mod .. " + D", layout_action({
  scrolling = hl.dsp.layout("swapcol r"),
  dwindle = hl.dsp.layout("togglesplit"),
  monocle = hl.dsp.layout("cyclenext"),
  master = hl.dsp.layout("cyclenext"),
}), { description = "Next layout action" })
