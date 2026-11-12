-- Native Phantomat canvas preset. Edit this static file for camera, placement,
-- motion and HUD choices. It contains no monitor names or generated paths.
return {
  layout = "grid", -- Native canvas backing geometry, not a tiling layout.
  scale = 0.36,
  workspace_gap = 0,
  grid = { columns = 3, stagger = 0 },
  input = {
    pan_sensitivity = 1,
    drag_threshold = 10,
    touchpad_scroll_factor = 1,
    scroll_event_delay = 160,
  },
  animation = {
    enabled = true, -- Set false for reduced camera motion.
    speed = 2, -- Match Hyprland window transitions.
    bezier = "quick-out", -- Shared with Hyprland's window-entry animation.
  },
  workspace_outline = {
    enabled = false,
    width = 2,
    drop_width = 2,
    rounding = 0,
    opacity = 0.3,
    active_opacity = 0.85,
    drop_opacity = 1,
    drop_fill_opacity = 0.1,
  },
  canvas = {
    enabled = true,
    desktop_mode = true,
    workspace_bound = true, -- Each real Hyprland workspace owns an independent Canvas.
    persistent = true,
    linked_screens = false, -- Workspace Canvas cameras never link across outputs.
    places = false, -- No experimental workspace-to-place mapping.
    initial_zoom = 0.72,
    min_zoom = 0.05,
    max_zoom = 2.5,
    zoom_step = 0.12,
    auto_float = true,
    auto_place = true,
    client_size = "700x500", -- Empty: the client request and Hyprland `size` rules decide.
    overview_client_scale = "", -- Empty: derived per monitor from its resolution. "0.5" sets all; "DP-1:0.45,HDMI-A-1:0.6" sets one by name.
    overview_border_size = 3, -- Border thickness of clients in the overview, also while they wobble. 0: the window's own.
    placement_gap = 40,
    space_pan = false,
    direct_input = true,
    hover_focus = true,
    minimap_enabled = true,
    minimap_width = 200,
    minimap_height = 125,
    minimap_margin = 16,
    minimap_rounding = 0,
    minimap_opacity = 0.8,
    arrange_context_grouping = true,
    arrange_size_similarity = 0.12,
    arrange_resize_limit = 0.15,
    grid_enabled = true,
    grid_size = 80,
    grid_width = 1,
    grid_opacity = 0.08,
    grid_style = 1, -- Native dotted grid.
    grid_dot_size = 2,
    background_dim = 0.16,
    viewport_enabled = false,
    viewport_width = 2,
    viewport_rounding = 0,
    viewport_border_opacity = 0.9,
    viewport_outside_opacity = 0.16,
    float_on_drag = true,
    allow_window_overflow = true,
    snap_viewport_on_pan = false, -- Camera motion remains continuous.
    commit_viewport_on_close = true,
    snap_enabled = true, -- Window placement snaps; the camera does not.
    remember_layout = true, -- Cameras only; window boxes follow Hyprland and client_size.
    remember_overview = true, -- Keep this workspace's HUD, search and camera on return.
  },
  navigator = {
    enabled = true,
    auto_open = false, -- Keep implicit navigation entry HUD-free; Ctrl+O explicitly toggles it.
    labels = true,
    label_drag = true, -- Keep the window title on the card while that window is dragged.
    hide_outline_in_motion = true, -- Hide the selection outline while its client is dragged or wobbling.
    dim_unmatched = 0.7,
    pointer = true,
    -- Accent and colors are supplied explicitly from the generated palette
    -- by phantomat.lua, rather than an unrelated plugin color preset.
    mono_font = "Monospace",
    hud_scale = 1,
    width = 600,
    top = 0.075,
    rows = 5,
    row_height = 44,
    rounding = 0,
    panel_opacity = 0.96,
    uppercase = false,
    letter_spacing = 0,
    query_size = 16,
    title_size = 14,
    detail_size = 11,
    corner_size = 12,
    label_size = 11,
    corner_labels = false,
    search_height = 44,
    search_border = 2,
    search_border_opacity = 0.85,
    search_border_color = "accent",
    search_glow = 0,
    panel_padding = 8,
    panel_shadow = 0,
    panel_shadow_size = 0,
  },
  distortion = {
    enabled = false,
    strength = 0,
    edge_scale = 1,
    feather = 0,
    transition_power = 1,
    edge_blur = 0,
    edge_blur_start = 0.45,
    vignette = 0,
    chromatic = 0,
  },
  parallax = { enabled = false, strength = 0, depth = 0, desktop = false },
  -- Quickshell retains ownership of its surfaces and their animations.
  chrome_animation = { enabled = false },
  wallpaper = 0,
  blur = false,
  blur_strength = 0,
  shadow = { enabled = false, range = 0 },
}
