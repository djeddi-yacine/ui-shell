---
id: phantomat-toggle-and-focus
title: "Phantomat overview toggle + selection preservation"
category: decision
status: active
created: "2026-11-04T05:56:37"
updated: "2026-11-05T01:52:17"
---

<!-- compiled_truth -->
## Compiled truth

### What it should be
When the overview opens, the camera and keyboard focus land on the SAME client that is selected on the navigator HUD - the result of the arrow key / click that picked it, not a random client at a fixed position.

### Why
- Opening via `hud toggle` (Ctrl+Shift+O) today goes straight to `toggleCanvasNavigation(true)`: the camera animates to `canvasCameraOffsetFor(bestCandidate)` with the HUD's best candidate - the first result of the search, not the selected one.
- Selection changes use `selectOverviewWindow(bestCandidate, workspaceIdx, true)` + `syncFocusedSelection()` - camera and focus track the selection.
- Opening must re-run the same path the selection/sync path already uses: choose the selected client, `selectOverviewWindow(..., true)`, `syncFocusedSelection()`, then `followCanvasWindow(selected, true, true)` at the current scale.

### Constraints
- `toggleCanvasNavigation(true, true)` close already keeps the selected client (Fix 1 from the page timeline).
- The close path must not replace the selection with `closeOnWindow` / `rememberedWindow`.
- `syncFocusedSelection` already takes the selected window; the open path must not reset `closeOnWindow`.
- Navigation must never panic/assert when the selected window is gone (remains on the previous valid selection).

### Verification
- Open with Ctrl+Shift+O, select with arrows, close: open again -> camera and focus on the selected client.
- Arrow only, no click: open -> camera on the last arrow target, focus follows.
- No selection: open -> previous behaviour (random/first client) preserved.

### Remaining work
- [ ] Select the currently selected window on open via the same path used by selection changes (do not rerun search / candidate ranking).
- [ ] Re-run `syncFocusedSelection()` (with `closeOnWindow` and `rememberSelection` on the selected client) so keyboard focus follows the camera.
- [ ] Animate to the selected client at the current scale: `followCanvasWindow(selected, true, true)`.
- [ ] Verify the selected window is still valid when it is in a different workspace / closed (keep previous valid selection).


## Timeline

- time: 2026-11-04T05:56:37
  kind: decision
  summary: "Created this page: Phantomat overview toggle + selection preservation"
  source: "session chat, 2026-11-04"
  affects: [phantomat-toggle-and-focus]

- time: 2026-11-04T05:56:37
  kind: note
  summary: "Ctrl+Shift+O described as the open/close overview toggle; closing keeps the selected client (camera + focus) instead of Landing commit/rewind"
  affects: [phantomat-toggle-and-focus]

- time: 2026-11-04T05:56:37
  kind: note
  summary: "Fix 1: toggleWorkspaceCanvasHud() closes only - no auto-open; canvas key owns enable/disable. closeOnWindow with syncFocus=true + canvasCameraOffsetFor keeps camera on the selected client."
  affects: [phantomat-toggle-and-focus]

- time: 2026-11-04T05:56:37
  kind: note
  summary: "Fix 2: handleNavigatorKey fallback releases unhandled Ctrl chords to Hyprland binds (only Super chords passed before), so the close key reaches its binding."
  affects: [phantomat-toggle-and-focus]

- time: 2026-11-04T05:56:37
  kind: note
  summary: "Leave: focus does not follow the selected client when the overview opens - camera animates to a random client instead of the selected one."
  affects: [phantomat-toggle-and-focus]

- time: 2026-11-04T05:57:10
  kind: decision
  summary: "Compiling open-path selection: camera + focus must follow the selected client, not the HUD best candidate"
  source: brain update-truth
  affects: [phantomat-toggle-and-focus]

- time: 2026-11-04T06:04:24
  kind: decision
  summary: "Recorded patches: (1) drag-and-drop clients inside the overview moves windows; (2) selection follow - camera + keyboard focus track the selected client on any selection change, via selectOverviewWindow + syncFocusedSelection + followCanvasWindow. Open path still to implement."
  affects: [phantomat-toggle-and-focus]

- time: 2026-11-04T20:14:49
  kind: decision
  summary: "The overview toggle key closes the open HUD: while the navigator owns the keyboard, any Ctrl/Alt/Super chord that Hyprland has bound in the current submap (or as submap-universal) passes through to Hyprland via registry().findShortcutConflict; plain and Shift-only keys stay with the search. Replaces the lost 'Fix 2' without hardcoding a modifier set."
  source: "user request + 22c21fe, 2026-11-04"
  affects: [phantomat-toggle-and-focus]

- time: 2026-11-05T00:17:22
  kind: decision
  summary: "Keyboard selection always owns focus on the canvas. Root cause of intermittent misses: after each keyboard step the camera moves and Hyprland replays a pointer-move at the unchanged position, and forwardCanvasPointerMotion hover-focused the window that slid under the resting mouse. Hover-focus now requires the pointer position to change (or a button press). Dispatch targeting: a held mouse button (0.57 inputState().pressed(), key.event starts with mouse) marks a mouse bind and uses the overview under the pointer; keyboard binds use the focused screen's overview. Verified over IPC in the nested 0.57 session: 40 keyboard steps at 100% and in the overview, rapid repeats, and real pointer movement still hover-focuses."
  source: "nested IPC sweep, 40045c0 and 77130d4, 2026-11-05"
  affects: [phantomat-toggle-and-focus]

- time: 2026-11-05T01:52:17
  kind: evidence
  summary: "Focus cases verified over IPC in the nested 0.57.1 session (plugin 77130d4, main de7c458 is format-only): typed search focuses the matching client each time and arrows stay inside the matches while a query is active; a fullscreen client keeps focus and arrows do nothing until restore; with a special workspace open arrows are ignored and focus stays with the special client, then returns to the previous canvas client; with a second (headless) monitor keyboard steps follow the focused monitor's canvas and moving focus between monitors does not move the cursor (cursor:warp_on_monitor_change = 0). Not testable without a real pointer: mouse-bind detection from held buttons, hover-focus across monitors."
  source: "nested IPC session, 2026-11-05"
  affects: [phantomat-toggle-and-focus]
