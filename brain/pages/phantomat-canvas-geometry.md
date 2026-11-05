---
id: phantomat-canvas-geometry
title: Phantomat Canvas owns client geometry only in canvas mode
category: decision
status: active
tags: [hyprland, phantomat, canvas, geometry]
created: "2026-11-03T05:30:21"
updated: "2026-11-05T01:35:37"
---

<!-- compiled_truth -->
## Scope
Phantomat's Canvas controls where canvas clients live and how the overview
draws them. It never resizes a client to fit the overview, and it never moves a
client because the overview selection changed.

## Sizing
- `plugin:spatialoverview:canvas:client_size` (`WxH`) wins when set; otherwise
  Hyprland's computed box or the client request decides, then
  `desiredGeometry()`; never invent a size.
- `window.openEarly` calls `prepareCanvasWindowEarly()`, which sets
  `setFloatingInitial(true)` before the first target exists.
- Placement is anchored to existing window boxes, cardinal offsets, nearest
  first; effective step is `client_size` + `placement_gap` rounded to the grid
  (720 px with `700x500` and gap 40, grid 80).
- Camera memory is the only persisted state (`canvas-memory.tsv`, camera-only).

## Overview previews
- `plugin:spatialoverview:canvas:overview_client_scale` is a string:
  - empty (default) derives the value per monitor from the physical output:
    `clamp(min(physicalWidth/2560, physicalHeight/1440), 0.2, 1.0)`;
  - `"0.5"` sets every monitor;
  - `"DP-1:0.45,HDMI-A-1:0.6"` sets monitors by name.
  The resolved value is clamped to 0.1..1.0 and logged once per monitor/value
  as `overview_client_scale <monitor> -> <value> (<source>)`.
- Previews shrink around the client's center, so world position and camera
  targeting are unchanged. 1.0 disables it; it never upscales. Real client
  geometry is never touched.
- Shrinking is a render-time transform plus a center-preserving box shrink
  (`shrinkOverviewPreviewBox`), so borders, shadows, labels, reticle, hit tests
  and direct-input mapping all follow the visible preview.

## Selection camera
- Opening the overview centers the selected client; every selection change
  animates the new client's center to the monitor center. There is no
  "only pan if off-screen" guard and no palette-based vertical offset while
  navigating.
- Clients keep their boxes across `navigate`, HUD clicks and focus switches;
  only the camera moves.

## Dragging and stacking
- A canvas drop lands exactly at the release point: no grid snapping, and the
  release point is taken fresh at drop time rather than from a stale motion
  sample.
- The dropped client is raised with `alterZOrder("top")`, so the scene's
  stacking order matches what the user expects after overlap.
- The selected client's accent outline is drawn inside the scene, right after
  that client, so any client above it covers both surface and outline. Only a
  dragged client's reticle is drawn after the scene, above everything.
- `plugin:spatialoverview:navigator:drag_behavior` = `follow` (default, reticle
  rides the dragged preview), `jump` (reticle stays on the old box until drop),
  `hidden` (no reticle while that window is dragged).
- While a client is held, hover is suppressed: no other client lights up under
  the pointer and the cursor stays `grabbing`.

## Verification
Nested Hyprland 0.57, 6 `foot` clients at `320,80 … 3920,80`, all `700x500`:
overview open + repeated `navigate left/right` moved the camera center exactly
onto client centers (4270/3550/2830/2110, y 330) at fixed zoom 0.72, while all
client positions and sizes stayed identical. Auto scale logged
`overview_client_scale WAYLAND-1 -> 0.50 (auto)` on the 1280x720 test output.
Drop position, raise-on-drop, outline stacking and hover suppression require a
real pointer and are verified manually in the nested session.


## Timeline

- time: 2026-11-03T05:30:21
  kind: decision
  summary: "Created this page: Phantomat Canvas owns client geometry only in canvas mode"
  source: "Phantomat 0.57 nested verification, 2026-11-03"
  affects: [phantomat-canvas-geometry]

- time: 2026-11-04T01:54:40
  kind: decision
  summary: "Canvas owns client geometry; overview previews scale and center without moving clients"
  source: "Phantomat 0.57 nested verification, 2026-11-04"
  affects: [phantomat-canvas-geometry]

- time: 2026-11-04T01:54:40
  kind: decision
  summary: "Overview previews scale by canvas:overview_client_scale (default 0.5) around their center; selection always animates the client center to the monitor center, so clients never move when selection changes"
  source: "6-client nested test, 2026-11-04"
  affects: [phantomat-canvas-geometry]

- time: 2026-11-04T02:20:19
  kind: decision
  summary: "Canvas scale is per monitor and derived when unset; drops are exact and raise the client; selection outline renders with its client; hover is suppressed while dragging"
  source: "Phantomat 0.57 nested verification, 2026-11-04"
  affects: [phantomat-canvas-geometry]

- time: 2026-11-04T02:20:21
  kind: decision
  summary: "overview_client_scale is per monitor: empty derives it from physical output size (clamped, logged), a bare number sets all monitors, name:value pairs override by monitor"
  source: "6-client nested test, 2026-11-04"
  affects: [phantomat-canvas-geometry]

- time: 2026-11-04T02:20:24
  kind: decision
  summary: "Drops land exactly at the release point and raise the client; the selection outline draws inside the scene with its client; hover is suppressed while a client is dragged"
  source: "User-verified drag/selection behaviour in nested session, 2026-11-04"
  affects: [phantomat-canvas-geometry]

- time: 2026-11-04T20:03:56
  kind: evidence
  summary: "Re-applied on compat/hyprland-0.57-render-context-v2 (b3f8073): client_size sizing precedence, anchored cardinal placement (step 720 = 700+40 on grid 80), camera-only memory (window lines in canvas-memory.tsv are now ignored and dropped), per-monitor overview_client_scale (logged WAYLAND-1 -> 0.50 auto), exact unsnapped drops from the fresh release point with raise, in-scene selection outline, drag_behavior and label_drag, press-time select+raise, hover suppression while held, no palette offset, HUD opens on the selected client. Nested 0.57.1 check: six foot clients 700x500 floating in one row 720 px apart; HUD open and navigate left/left/right centred the camera on each client (view 2350/1630/910/1630, y 370) with no client moved; close and reopen kept camera and focus. Drag, drop, outline stacking and hover need a real pointer and are pending manual verification."
  source: "nested make test-env-phantomat, 2026-11-04"
  affects: [phantomat-canvas-geometry, phantomat-toggle-and-focus]

- time: 2026-11-04T20:38:26
  kind: decision
  summary: "Canvas supports Hyprland 0.57 decoration:wobble: drags report the preview's on-screen box to effects().onPositionUpdate (WINDOW_UPDATE_MOUSE, grab point follows), keyboard nudges report their step (WINDOW_UPDATE_ANIMATION); a transformed window's plugin border is queued into its CTransformedWindowPassElement pass in the surfaces' space; the plugin's draw hooks must pass through untouched while ctx.m_data.renderingTransformedSource is set, otherwise the offscreen canvas is clipped in screen coordinates and shows stale-buffer tiles."
  source: "user report + 4727d9f/6a5329e, 2026-11-04"
  affects: [phantomat-canvas-geometry]

- time: 2026-11-04T20:46:46
  kind: evidence
  summary: "Coloured tiles at wobbling window edges: Hyprland clears a transformed window's offscreen canvas with empty damage (meaning unbounded) before setting renderingTransformedSource; the plugin's drawElement hook treated empty clipped damage as nothing and skipped the clear. Rule: draw hooks pass through empty damage and any target whose fbSize differs from the monitor. Added navigator:hide_outline_in_motion (default true) because the accent outline lies outside the window bounding box that wobble deforms."
  source: "user report + 03bd536, 2026-11-04"
  affects: [phantomat-canvas-geometry]

- time: 2026-11-05T01:35:37
  kind: decision
  summary: "Host config sets cursor.warp_on_monitor_change = 0 (new in Hyprland 0.57; default -1 follows warp_on_change_workspace, which is 1). Canvas clients live at world positions far from any monitor, so a cross-monitor focus change must never warp the pointer to one; a warp also counts as real pointer movement for hover-focus. misc.new_float_force_onscreen (new, default 2) is left alone: new canvas clients landed at their planned positions in the nested session. Multi-monitor behaviour not yet tested (nested session has one output)."
  source: "user request, hypr/input.lua, 2026-11-05"
  affects: [phantomat-canvas-geometry]
