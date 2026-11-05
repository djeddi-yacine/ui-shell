local profile = require("profile")
local picker = profile.shell_shortcuts.wallpaper_picker
local launcher = profile.shell_shortcuts.app_launcher
local tuning = profile.shell_shortcuts.control_tuning
hl.bind(profile.main_mod .. " + " .. launcher.key, hl.dsp.global(launcher.target), {
  description = "Open application launcher",
})

hl.bind(profile.main_mod .. " + " .. picker.key, hl.dsp.global(picker.target), {
  description = "Open wallpaper picker",
})

hl.bind(profile.main_mod .. " + " .. tuning.key, hl.dsp.global(tuning.target), {
  description = "Tune control colors",
})
