-- Keep compositor diagnostics inside the disposable test session. File logs are
-- retained under the run's artifacts/hypr directory; stdout is tee'd to
-- artifacts/launcher.log by the outer harness.
hl.config({
  debug = {
    disable_logs = false,
    enable_stdout_logs = true,
  },
})

local profile = require("profile")
local settings = require("user.nested")
for key, value in pairs(settings.profile_overrides) do
  assert(profile[key] ~= nil, "Nested profile: unknown option " .. tostring(key))
  profile[key] = value
end

require("hyprland")

hl.monitor(settings.output)

hl.bind(settings.terminal.bind, hl.dsp.exec_cmd(settings.terminal.command), {
  description = "Open terminal",
})
hl.bind(settings.exit_bind, hl.dsp.exit(), {
  description = "Exit nested test session",
  submap_universal = true,
})
