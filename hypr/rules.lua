-- Only durable window behaviour belongs here. App-specific convenience rules
-- get added when there is a concrete need, rather than importing a catalogue.
-- QML owns these surfaces' motion. Never stack compositor fades over it.
hl.layer_rule({
  name = "shell-owns-motion",
  match = { namespace = "^ui-shell-(bar|wallpaper-picker|app-launcher|control-tuning)$" },
  no_anim = true,
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
