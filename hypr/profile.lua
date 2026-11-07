-- Personal, machine-specific choices. This is data, not a configuration
-- framework: edit named values here when your hardware or preferred apps change.
return {
  main_mod = "SUPER",
  layout_mod = "SUPER",
  -- Complete modifier families/chords, never suffixes appended to main_mod.
  action_mod = "SUPER + SHIFT",
  workspace_silent_mod = "SUPER + ALT",
  workspace_previous_bind = "SUPER + SHIFT + UP",
  workspace_empty_bind = "SUPER + CTRL + DOWN",
  workspace_move_empty_bind = "SUPER + SHIFT + DOWN",
  window_cycle_mod = "ALT",
  window_cycle_previous_bind = "ALT + SHIFT + TAB",
  window_maximize_bind = "SUPER + CTRL + F",
  phantomat_canvas_toggle_bind = "SUPER + F5",
  phantomat_navigator_toggle_bind = "SUPER + CTRL + G",
  layout_cycle_key = "TAB",
  shell_shortcuts = {
    app_launcher = { key = "SPACE", target = "ui-shell:app-launcher" },
    wallpaper_picker = {
      key = "W",
      target = "ui-shell:wallpaper-picker",
    },
    control_tuning = { key = "T", target = "ui-shell:control-tuning" },
    audio_control = { key = "M", target = "ui-shell:audio-control" },
    screen_record = { key = "R", target = "ui-shell:screen-record" },
    screen_shot = { key = "P", target = "ui-shell:screen-shot" },
    media_panel = { key = "N", target = "ui-shell:media-panel" },
  },

  -- The keyboard media keys, handled by the shell (shell/modules/mpris/MprisKeys.qml). An ordered
  -- array, one entry per line: tests/scripts/check-mpris reads it. XF86AudioStop keeps its "pause"
  -- meaning from the old playerctl binds.
  media_keys = {
    { action = "playPause", key = "XF86AudioPlay", target = "ui-shell:media-play-pause", description = "Play or pause" },
    { action = "pause", key = "XF86AudioStop", target = "ui-shell:media-pause", description = "Pause" },
    { action = "next", key = "XF86AudioNext", target = "ui-shell:media-next", description = "Next track" },
    { action = "previous", key = "XF86AudioPrev", target = "ui-shell:media-previous", description = "Previous track" },
  },

  -- The webcam overlay of a recording: a small floating video window in the bottom-right corner,
  -- on every workspace, never taking focus. scripts/screen-record starts it with this app id.
  webcam_overlay = { app_id = "ui-shell-webcam", width = 320, height = 180, margin = 24 },

  commands = {
    terminal = "foot",
    lock = "hyprlock",
    screenshot_area = "grimblast --notify copysave area",
    screenshot_output = "grimblast --notify copysave screen",
  },

  keyboard = {
    layouts = "us,ara",
    variants = ",qwerty",
    options = "grp:alt_shift_toggle,compose:menu",
  },

  -- Opt-in native plugin. Canvas replaces workspace/layout/group controls;
  -- its editable presentation lives in user/canvas.lua.
  phantomat = {
    enabled = false,
    mode = "canvas", -- Canvas config is ready before the toggle bind.
    overview_target = "active", -- Regular overview only: "active", "all", or an exact output name.
  },
}
