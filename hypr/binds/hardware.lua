local profile = require("profile")

hl.bind("Print", hl.dsp.exec_cmd(profile.commands.screenshot_area), { description = "Capture area" })
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(profile.commands.screenshot_output), { description = "Capture output" })
hl.bind(profile.main_mod .. " + Print", hl.dsp.exec_cmd("hyprpicker -a"), { description = "Pick colour" })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -q set +10%"), { repeating = true, locked = true, description = "Brightness up" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -q set 10%-"), { repeating = true, locked = true, description = "Brightness down" })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true, locked = true, description = "Volume up" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true, locked = true, description = "Volume down" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, description = "Toggle output mute" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, description = "Toggle microphone mute" })

-- The media keys are handled by the shell (shell/modules/mpris/MprisKeys.qml), so they act on the
-- player the media panel shows. `locked` keeps them working on the lock screen. If the shell is
-- down they do nothing.
for _, media_key in ipairs(profile.media_keys) do
  hl.bind(media_key.key, hl.dsp.global(media_key.target), { locked = true, description = media_key.description })
end
