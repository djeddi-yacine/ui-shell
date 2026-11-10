local profile = require("profile")
local picker = profile.shell_shortcuts.wallpaper_picker
local launcher = profile.shell_shortcuts.app_launcher
local tuning = profile.shell_shortcuts.control_tuning
local audio = profile.shell_shortcuts.audio_control
local record = profile.shell_shortcuts.screen_record
local shot = profile.shell_shortcuts.screen_shot
local media = profile.shell_shortcuts.media_panel
local drawer = profile.shell_shortcuts.notifications
local dnd = profile.shell_shortcuts.notifications_dnd
local dismiss = profile.shell_shortcuts.notifications_dismiss
hl.bind(profile.main_mod .. " + " .. launcher.key, hl.dsp.global(launcher.target), {
  description = "Open application launcher",
})

hl.bind(profile.main_mod .. " + " .. picker.key, hl.dsp.global(picker.target), {
  description = "Open wallpaper picker",
})

hl.bind(profile.main_mod .. " + " .. tuning.key, hl.dsp.global(tuning.target), {
  description = "Tune control colors",
})

hl.bind(profile.main_mod .. " + " .. audio.key, hl.dsp.global(audio.target), {
  description = "Open audio control",
})

hl.bind(profile.main_mod .. " + " .. record.key, hl.dsp.global(record.target), {
  description = "Open screen recording, or stop the recording",
})

hl.bind(profile.main_mod .. " + " .. shot.key, hl.dsp.global(shot.target), {
  description = "Open screenshot",
})

hl.bind(profile.main_mod .. " + " .. media.key, hl.dsp.global(media.target), {
  description = "Open media control",
})

hl.bind(profile.action_mod .. " + " .. dnd.key, hl.dsp.global(dnd.target), {
  description = "Toggle notification do not disturb",
})

hl.bind(profile.action_mod .. " + " .. dismiss.key, hl.dsp.global(dismiss.target), {
  description = "Dismiss the notification popup",
})

hl.bind(profile.action_mod .. " + " .. drawer.key, hl.dsp.global(drawer.target), {
  description = "Open the notification drawer",
})
