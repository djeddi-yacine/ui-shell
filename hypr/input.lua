local profile = require("profile")

-- Keep US first: Hyprland resolves symbol binds through the first layout.
-- Alt+Shift changes to Arabic qwerty; Menu is Compose, matching the existing
-- daily configuration.
hl.config({
  input = {
    kb_layout = profile.keyboard.layouts,
    kb_variant = profile.keyboard.variants,
    kb_model = "",
    kb_options = profile.keyboard.options,
    kb_rules = "",
    resolve_binds_by_sym = false,
    numlock_by_default = true,
    follow_mouse = 1,
    sensitivity = 0,
    repeat_rate = 40,
    repeat_delay = 250,

    touchpad = {
      natural_scroll = false,
      scroll_factor = 1,
    },
  },

  cursor = {
    hide_on_key_press = true,
    warp_on_change_workspace = 1,
    -- Hyprland 0.57 defaults this to -1 (copy the line above). Canvas clients
    -- sit at world positions far from any monitor; never warp the pointer to one.
    warp_on_monitor_change = 0,
  },

  misc = {
    key_press_enables_dpms = true,
    mouse_move_enables_dpms = true,
  },
})
