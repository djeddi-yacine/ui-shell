-- Keep compositor diagnostics inside the disposable test session. File logs are
-- retained under the run's artifacts/hypr directory; stdout is tee'd to
-- artifacts/launcher.log by the outer harness.
hl.config({
  debug = {
    disable_logs = false,
    enable_stdout_logs = true,
  },
  -- The disposable session never edits its config live; the watcher also floods the log with
  -- "got an event for wd N which we don't have" errors.
  misc = {
    disable_autoreload = true,
  },
})

local profile = require("profile")
local settings = require("userlua").load("nested")
for key, value in pairs(settings.profile_overrides) do
  assert(profile[key] ~= nil, "Nested profile: unknown option " .. tostring(key))
  profile[key] = value
end

-- Per-shortcut key replacements, for shell shortcuts whose production key collides here.
for name, key in pairs(settings.shell_shortcut_keys or {}) do
  assert(profile.shell_shortcuts[name] ~= nil, "Nested profile: unknown shell shortcut " .. tostring(name))
  profile.shell_shortcuts[name].key = key
end

require("hyprland")

-- Only the disposable session records clipboard history here; on a real desktop the
-- cliphist user unit owns the watcher. Both selections feed the same private store.
hl.on("hyprland.start", function()
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
  -- A few sample entries so the panel (Super+V) has something to show in the test session.
  hl.exec_cmd([[sh -c 'for text in "first sample entry" "a second one, with several words" "quote \" and backslash \\" "file:///usr/share/applications/foot.desktop"; do printf "%s" "$text" | cliphist store; done; printf "line one\nline two\nline three" | cliphist store']])
end)

hl.monitor(settings.output)

hl.bind(settings.terminal.bind, hl.dsp.exec_cmd(settings.terminal.command), {
  description = "Open terminal",
})
hl.bind(settings.exit_bind, hl.dsp.exit(), {
  description = "Exit nested test session",
  submap_universal = true,
})
