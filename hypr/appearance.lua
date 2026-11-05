local colors = dofile(require("runtime").bundle.hyprPalette)

-- Smooth means short, direct transitions. Blur and shadows stay off: they add
-- GPU work without improving a deliberately spare shell.
hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 8,
    border_size = 2,
    col = {
      active_border = colors.active_border,
      inactive_border = colors.inactive_border,
    },
    layout = "dwindle",
    resize_on_border = false,
    allow_tearing = false,
  },

  decoration = {
    rounding = 0,
    shadow = { enabled = false },
    blur = { enabled = false },
    -- Windows deform like a spring while moved or resized (Hyprland 0.57).
    -- Values are the defaults; the `no_wobble` window rule opts a client out.
    wobble = {
      enabled = true,
      intensity = 0.2, -- [0 - 2] how far the mesh bends
      stiffness = 200, -- higher snaps back faster
      damping = 12, -- higher settles with fewer bounces
    },
    active_opacity = 1,
    inactive_opacity = 1,
    fullscreen_opacity = 1,
  },

  layers = {
    allow_new_top_layers_over_existing_fullscreen = true,
    layers_hog_keyboard_focus = true,
  },

  dwindle = {
    preserve_split = true,
    smart_split = false,
    smart_resizing = false,
  },

  scrolling = {
    column_width = 0.5,
    focus_fit_method = 1,
    follow_focus = 1, -- Focus may move the tape; mouse clicks always move it.
    follow_min_visible = 0.4,
    wrap_focus = true,
    wrap_swapcol = true,
    direction = "right",
  },

  group = {
    auto_group = false,
    drag_into_group = 2,
    group_on_movetoworkspace = false,
    col = {
      border_active = colors.group_border_active,
      border_inactive = colors.group_border_inactive,
      border_locked_active = colors.group_border_locked_active,
      border_locked_inactive = colors.group_border_locked_inactive,
    },
    groupbar = {
      enabled = true,
      gradients = false,
      font_size = 10,
      height = 18,
      indicator_height = 2,
      render_titles = true,
      disable_when_only = true,
      col = {
        active = colors.groupbar_active,
        inactive = colors.groupbar_inactive,
        locked_active = colors.groupbar_locked_active,
        locked_inactive = colors.groupbar_locked_inactive,
      },
    },
  },

  misc = {
    vrr = 1,
    animate_manual_resizes = false,
    animate_mouse_windowdragging = false,
    force_default_wallpaper = 0,
    on_focus_under_fullscreen = 2,
    allow_session_lock_restore = true,
    initial_workspace_tracking = false,
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
  },

  binds = {
    allow_workspace_cycles = true,
    movefocus_cycles_fullscreen = true,
    hide_special_on_workspace_change = true,
  },

  xwayland = {
    enabled = true,
    force_zero_scaling = true,
  },
})

hl.curve("quick-out", { type = "bezier", points = { { 0.2, 0 }, { 0, 1 } } })
hl.curve("quick-in", { type = "bezier", points = { { 0.4, 0 }, { 1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 2, bezier = "quick-out" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2, bezier = "quick-out", style = "popin 96%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.5, bezier = "quick-in", style = "popin 96%" })
hl.animation({ leaf = "fade", enabled = true, speed = 1.5, bezier = "quick-out" })
hl.animation({ leaf = "layers", enabled = true, speed = 1.5, bezier = "quick-out", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2, bezier = "quick-out", style = "slide" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 2, bezier = "quick-out", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 2, bezier = "quick-out", style = "slide" })
