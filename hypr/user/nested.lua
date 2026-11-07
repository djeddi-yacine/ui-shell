-- User-owned settings for the focused nested test session.
return {
  -- Applied before production modules register any bindings. Shift actions
  -- omit Alt because the host reserves Alt+Shift for keyboard language.
  profile_overrides = {
    main_mod = "CTRL + ALT",
    layout_mod = "CTRL + SHIFT", -- Layout F-keys avoid host TTY chords.
    action_mod = "CTRL + SHIFT",
    workspace_silent_mod = "CTRL",
    workspace_previous_bind = "CTRL + ALT + P",
    workspace_empty_bind = "CTRL + ALT + E", -- N opens the media panel (Ctrl+Alt is the nested main mod).
    workspace_move_empty_bind = "CTRL + SHIFT + N",
    window_cycle_mod = "CTRL + ALT",
    window_cycle_previous_bind = "CTRL + ALT + PAGE_UP",
    window_maximize_bind = "CTRL + ALT + M",
    phantomat_canvas_toggle_bind = "CTRL + SHIFT + F5",
    phantomat_navigator_toggle_bind = "CTRL + SHIFT + O",
    layout_cycle_key = "B",
  },
  terminal = {
    bind = "CTRL + ALT + Q",
    command = "foot",
  },
  exit_bind = "CTRL + ALT + ESCAPE",
  output = {
    output = "",
    mode = "1280x720@60",
    position = "auto",
    scale = 1,
    bitdepth = 8,
  },
}
