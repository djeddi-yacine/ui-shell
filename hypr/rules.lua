-- Only durable window behaviour belongs here. App-specific convenience rules
-- get added when there is a concrete need, rather than importing a catalogue.
-- QML owns these surfaces' motion. Never stack compositor fades over it.
local profile = require("profile")

hl.layer_rule({
  name = "shell-owns-motion",
  match = { namespace = "^ui-shell-(bar|wallpaper-picker|app-launcher|control-tuning|audio-control|record|shot|auth|auth-scrim)$" },
  no_anim = true,
})

-- The authentication dialog's card is kept out of compositor screen sharing (captures show a
-- black rectangle there; the dimming layer around it is not hidden). Whether the screen
-- recorder, which captures below the compositor, honours this is tested, not assumed.
hl.layer_rule({
  name = "auth-not-shared",
  match = { namespace = "^ui-shell-auth$" },
  no_screen_share = true,
})

hl.window_rule({
  name = "nested-aquamarine",
  match = { class = "^aquamarine$" },
  float = true,
  size = { 1280, 720 },
  center = true,
})

hl.window_rule({
  name = "portal-dialogs",
  match = { class = "^(xdg-desktop-portal|org.freedesktop.impl.portal.*)$" },
  float = true,
  center = true,
})

hl.window_rule({
  name = "games-do-not-fade",
  match = { class = "^(steam_app_.*|gamescope)$" },
  content = "game",
  immediate = true,
})

-- The recording's webcam overlay (see profile.webcam_overlay).
hl.window_rule({
  name = "recording-webcam-overlay",
  match = { class = "^" .. profile.webcam_overlay.app_id .. "$" },
  float = true,
  pin = true,
  no_focus = true,
  no_initial_focus = true,
  no_anim = true,
  size = { profile.webcam_overlay.width, profile.webcam_overlay.height },
  move = { "monitor_w - window_w - " .. profile.webcam_overlay.margin, "monitor_h - window_h - " .. profile.webcam_overlay.margin },
})
