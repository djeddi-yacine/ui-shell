local settings = require("user.monitors")

local default = assert(settings.default, "Monitors: explicit default settings are required")
assert(default.output == "", "Monitors: the default must use the native all-output target")
hl.monitor(default)
for _, override in ipairs(settings.overrides) do
  assert(type(override.output) == "string" and override.output ~= "", "Monitors: an override needs an explicit output")
  local configured = {}
  for key, value in pairs(default) do configured[key] = value end
  for key, value in pairs(override) do configured[key] = value end
  hl.monitor(configured)
end
