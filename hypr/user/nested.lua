-- User-owned settings for the focused nested test session.
-- Alt + Multi_key: the nested stand-in for the host SUPER key.
local main = "ALT + Multi_key"
-- Multi_key is a key, so extra modifiers must come before it.
local shifted = "ALT + SHIFT + Multi_key"
local ctrled = "ALT + CTRL + Multi_key"

return {
  -- Applied before production modules register any bindings. The nested
  -- session stands in for SUPER with Alt + Multi_key, so every chord below
  -- is built from these names and never spells the modifiers inline.
  profile_overrides = {
    main_mod = main,
    mouse_mod = "ALT", -- Multi_key is a key, so mouse binds use Alt alone.
    layout_mod = shifted, -- Layout F-keys avoid host TTY chords.
    action_mod = shifted,
    workspace_silent_mod = ctrled,
    workspace_previous_bind = main .. " + P",
    workspace_empty_bind = main .. " + E", -- N opens the media panel.
    workspace_move_empty_bind = shifted .. " + N",
    window_cycle_mod = main,
    window_cycle_previous_bind = main .. " + PAGE_UP",
    window_maximize_bind = main .. " + M",
    phantomat_canvas_toggle_bind = shifted .. " + F5",
    phantomat_navigator_toggle_bind = shifted .. " + O",
    layout_cycle_key = "B",
  },
  terminal = {
    bind = main .. " + Q",
    command = "foot",
  },
  exit_bind = main .. " + ESCAPE",
  output = {
    output = "",
    mode = "1280x720@60",
    position = "auto",
    scale = 1,
    bitdepth = 8,
  },
}
