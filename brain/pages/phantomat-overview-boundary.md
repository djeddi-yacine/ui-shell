---
id: phantomat-overview-boundary
title: Phantomat is an explicit opt-in overview
category: decision
status: active
tags: [hyprland, phantomat, plugin, monitors]
created: "2026-09-30T22:37:08"
updated: "2026-10-14T02:20:07"
---

<!-- compiled_truth -->
# Decision

Phantomat Canvas in the local fork is workspace-scoped, not monitor-scoped. Canvas is a per-Hyprland-workspace layout mode; its overview HUD is a separate navigation mode, optionally remembered across workspace switches.

## Workspace ownership

- Ctrl+Shift+F5 toggles Canvas only for the focused workspace. Workspace Canvas state persists while switching elsewhere and resumes on return. Explicit Canvas activation does not open the HUD.
- Ctrl+Shift+O toggles only the focused Canvas workspace HUD and is inert when that workspace is not rendering Canvas. The nested plugin keymap does not combine Ctrl+Alt.
- Canvas manages only windows assigned to that workspace. It must not move windows between real workspaces to follow monitor visibility. Explicit Hyprland workspace moves change the window owner; undo must not reclaim them.
- Camera, Canvas positions, activation, and native-layout restoration are isolated per workspace. A workspace outside Canvas keeps its own native layout and geometry untouched.
- Switching away retains the outgoing Canvas renderer through Hyprland workspace alpha/render-offset animation, without retiling, resizing, moving clients, or changing the saved camera. Incoming and outgoing Canvas client planes compose within Hyprland's one native monitor render pass, at its window-pass boundary. Keep native workspaces, special workspaces, pinned clients and layer surfaces in that pass; do not replace it with a full-screen Canvas redraw during the handoff. The temporary renderer is released when the workspace animation settles; returning restores the remembered Canvas camera. Explicitly disabling Canvas or unloading the plugin restores native layout.
- Canvas workspace animation moves a finite monitor-sized view through its saved camera, never the entire infinite plane. Project client content through the camera, clip surfaces, borders and shadows to that view, then use Hyprland's signed workspace displacement and opacity. Off-camera content must not enter another or empty native workspace. Preserve native damage outside the camera clip; no client resizing, camera movement, new framebuffer or animation-timing change is required.
- Fast returns reuse the exact monitor/workspace renderer while it is still retained by the native transition. Reactivation removes it from transition cleanup, preserves the resting camera and client geometry, and restores the overview only when `canvas.remember_overview` is enabled; otherwise the HUD stays closed. Shared input override bookkeeping has one owner throughout the handoff, preserving original native values on idle release and unloading. Do not add a permanent renderer pool or change animation timing to implement reuse.
- Hyprland workspace animations must bypass Canvas preview throttling and render-damage suppression, including early frames when every incoming Canvas client is off-screen. The camera transform uses the actual native surface origin, including the temporary floating-window offset, so client contents and borders share the same projected box.
- During real workspace switches, overview chrome fades with native workspace visibility and opacity, not a second animation clock. Selected outlines use the same signed displacement and finite camera clip as their clients. Retained renderers keep only their last visual HUD textures and weak window/match references until native cleanup; live Navigator input ends immediately. Compose independent workspace HUD/minimap layers in the native pass rather than the single final-screen shader slot. Opening/closing the HUD is unchanged.
- Entering Canvas keeps the focused client selected and animates the camera to center it.
- The existing `places` feature represents virtual camera positions, not real workspaces. Linked-screen camera behavior must not merge separate workspace canvases.

- `canvas.remember_overview` restores each real workspace's overview camera, zoom, search, selected live client and return target. Plugin default is false; `hypr/user/canvas.lua` explicitly enables it. A closed HUD stays closed. State is compositor-session-only, independent of persistent `remember_layout`, guarded by weak workspace/client identity, consumed on restoration and cleared on explicit Canvas disable or unload. Restore only after registering the renderer; adopt selection/focus without moving the restored camera, and use the existing single-owner Navigator handoff across monitors.

## Mode, rendering, and input

- Requested Canvas mode and the live renderer are different states. Fullscreen may suspend rendering while keeping the workspace Canvas mode enabled. Rendering resumes after fullscreen ends without implicitly opening the HUD.
- Disabling a suspended Canvas or unloading the plugin must restore saved native ownership, without cancelling the user fullscreen state.
- Workspace-bound Canvas must not suppress Hyprland `workspaces`, `workspacesIn`, or `workspacesOut` animations or force workspace visibility state. Keep both incoming and outgoing workspace animation leaves explicitly configured.
- A special workspace owns its native input. Canvas controls must not change the regular workspace underneath it or redirect its keyboard/pointer focus.
- Shared window shortcuts use the plugin direct `workspace_canvas_active()` Lua query to choose Canvas or native actions. Do not maintain duplicate Lua mode tables or add script polling. Workspace and group shortcuts remain real Hyprland bindings.
- Directional navigation belongs to the focused workspace renderer, not another output last camera. Window candidates, memory, and history retain the same workspace scope.

## Existing interaction and visual constraints

- Nested Super remains Ctrl+Alt. Ctrl+Shift+F5 is the sole nested Canvas enter/exit toggle; Ctrl+Shift+O is gated to the active Canvas workspace. Both bindings allow input capture.
- Keep Phantomat opt-in; starting the plugin or adding a monitor must not enter Canvas. Native tiling remains until explicit workspace toggle.
- Canvas and HUD remain separate. Fresh Canvas activation and cancelled teardown must not implicitly show the HUD. Returning may restore a previously open overview only through the explicit remember option.
- Preserve the local theme branch behavior: square corners, semantic HUD/minimap colors, generated global defaults and per-output palette overrides.

## Verification

- Keep a focused nested regression using MPV clients and real workspaces: focused-client centering, both directions of workspace-animation handoff, workspace isolation, untouched client geometry and camera on suspension, native restoration on explicit exit, and independent camera resume.
- The scoped `--overview-state-only` MPV regression verifies retained and recreated renderer restoration, independent workspace camera/search state, keyboard focus matching selection, unchanged geometry, native input release, closed-HUD return, disabled-option behavior and explicit reset. It is a state regression, not a visual-animation gate.
- The focused `--hud-transition-only` MPV pixel check verifies partially transparent HUD frames in both directions, selected-frame/client alignment, no residual HUD on the native workspace, full visibility on return and unchanged client geometry/camera. It slows only the test workspace slide for sampling.
- Cover simultaneously visible outputs, explicit window moves and undo, fullscreen activation/suspension/disable, special-workspace input, reload/teardown, and plugin unloading. The test environment must not change host configuration or leave spawned processes alive.

The upstream desktop Canvas shared its window plane across monitors and workspaces. This workspace contract supersedes that ownership model.


## Timeline

- time: 2026-09-30T22:37:08
  kind: decision
  summary: "Created this page: Phantomat is an explicit opt-in overview"
  source: Local refs/phantomat source and nested smoke test
  affects: [phantomat-overview-boundary]

- time: 2026-09-30T22:37:08
  kind: decision
  summary: "Recorded explicit overview-only Phantomat profile, monitor semantics, and plugin lifecycle."
  source: Local refs/phantomat source and nested smoke test
  affects: [phantomat-overview-boundary]

- time: 2026-10-10T16:15:01
  kind: decision
  summary: "Use workspace-grid overview without canvas viewport or navigator, and document the profile-based toggle."
  source: "User overview configuration request and refreshed Phantomat source, 2026-10-10"
  affects: [phantomat-overview-boundary]

- time: 2026-10-10T16:15:01
  kind: reversal
  summary: "Disable the mixed canvas viewport and navigator in favor of the plain workspace grid; clicking a preview still intentionally selects and closes."
  source: "User rounded-square symptom and source-confirmed overview behavior, 2026-10-10"
  affects: [phantomat-overview-boundary]

- time: 2026-10-11T00:46:12
  kind: decision
  summary: "Use explicit full toggle chord; nested Ctrl+Alt+O does not collide with group controls"
  source: "User-approved Ctrl+Alt nested keymap, 2026-10-11"
  affects: [phantomat-overview-boundary]

- time: 2026-10-11T01:07:03
  kind: decision
  summary: Record reproduced animated teardown defect and separate global outline versus per-output window color ownership
  source: "Current local Phantomat a1e8a0806541 and Hyprland wiki; isolated 2026-10-11 A/B frames in /tmp/ui-shell-phantomat-check.zoj1Ny"
  affects: [phantomat-overview-boundary]

- time: 2026-10-11T01:22:51
  kind: decision
  summary: Distinguish creator canvas desktop from current overview preset and limit teardown diagnosis to verified nested evidence
  source: "User floating/panning demo description, current local README and examples/spatialoverview.lua; X fetch 403; incomplete nested screencopy comparisons"
  affects: [phantomat-overview-boundary]

- time: 2026-10-11T01:22:51
  kind: reversal
  summary: "Withdraw claim that two plugin patches are required before evaluating the actual canvas-desktop mode; native physical-session behavior remains untested."
  source: "User clarification: creator demonstration pans a freely floating plane rather than workspace tiles"
  affects: [phantomat-overview-boundary]

- time: 2026-10-11T01:30:30
  kind: decision
  summary: "User approves an explicit canvas-desktop preset for isolated testing, superseding grid-only test intent"
  source: "User: exactly canvas mode, do it now; refreshed local creator configuration and native dispatcher source"
  affects: [phantomat-overview-boundary]

- time: 2026-10-11T01:43:04
  kind: decision
  summary: "User approves local Phantomat fix/canvas-theme-style branch for configurable minimap rounding and generated HUD/minimap palette roles; no push or PR submission"
  source: "User identifies rounded corner minimap, requests source/tests and local branch including colors"
  affects: [phantomat-overview-boundary]

- time: 2026-10-11T01:50:23
  kind: decision
  summary: Specify combined canvas shape/color patch and replace auto accent policy with prepared semantic palette mapping
  source: "User-approved fix/canvas-theme-style branch; local Phantomat source and generated native palette"
  affects: [phantomat-overview-boundary]

- time: 2026-10-11T01:53:33
  kind: decision
  summary: "Preserve native zero/per-window rounding in selected, hovered and search-match canvas outlines"
  source: "User still-rounded selected-window report; captured frame and native decoration:rounding=0; renderNavigatorReticle/renderNavigatorWindowOverlay source"
  affects: [phantomat-overview-boundary]

- time: 2026-10-11T01:59:32
  kind: decision
  summary: "Complete native shape and semantic color contract for canvas overlays, grid and HUD chrome"
  source: User corners/colors follow-up and local renderer/cache patch
  affects: [phantomat-overview-boundary]

- time: 2026-10-11T02:02:14
  kind: evidence
  summary: "ABI-matched build and isolated startup passed; native seven color settings match generated palette, selected outline is square, HUD/minimap pixels refresh with unchanged accent, and reload restores generated palette"
  source: "Local fix/canvas-theme-style; completed frames in /tmp/my-shell-test.yvbmbz; native color queries and checked-renderer logs"
  affects: [phantomat-overview-boundary]

- time: 2026-10-11T02:08:55
  kind: reversal
  summary: "Replace shared-only canvas HUD policy with rendering-output palettes from the existing generated native index; global native colors are the explicit default for unassigned outputs. No new extraction, daemon or generated hierarchy."
  source: "User per-monitor Phantomat colors request; existing bundle.hyprOutputPalettes and local native rendering boundary"
  affects: [phantomat-overview-boundary]

- time: 2026-10-11T02:13:23
  kind: decision
  summary: Wire generated native output palettes into atomic Phantomat output-color configuration and output-scoped rendering caches
  source: "User per-monitor requirement; existing output index, local Config/Hud render patch and Lua consumer regression"
  affects: [phantomat-overview-boundary]

- time: 2026-10-11T02:14:09
  kind: evidence
  summary: "ABI-matched build and actual Lua palette consumer passed. Isolated two-output rendering confirmed independent generated panel colors, rejected-map atomicity, same-accent color refresh, reload retention and override removal to default; frame/log inspection and clean teardown passed with host environment/files unchanged."
  source: "Completed /tmp/my-shell-test.eOcXWD/phantomat-output-colors.log and frame-phantomat-*; standalone check-theme-profiles refs/100-themes; make test-scripts"
  affects: [phantomat-overview-boundary]

- time: 2026-10-11T02:44:28
  kind: decision
  summary: "Ordinary workspaces use explicit Super+F1..F4 layout bindings (dwindle, scrolling, master, monocle); nested Super is Ctrl+Alt. Special workspaces retain their own layouts. Dwindle remains the explicit global default. Phantomat stays opt-in and defaults to Canvas; its Canvas navigation toggle opens the configured canvas before toggling. Source/runtime inspection found Phantomat temporarily pseudo-focuses app borders and restores native border state; canvas navigation adds a separate outline."
  source: "User request; Hyprland config/API inspection; Phantomat source review and isolated rendered Canvas comparison"
  affects: [phantomat-overview-boundary]

- time: 2026-10-11T02:48:30
  kind: reversal
  summary: "Nested layout shortcuts use an explicit layout_mod override of Ctrl+Shift, not the shared Ctrl+Alt main modifier, to avoid host TTY switching; production layout modifier remains Super."
  source: "User correction about Ctrl+Alt+F host TTY chords; nested binding configuration"
  affects: [phantomat-overview-boundary]

- time: 2026-10-11T02:53:38
  kind: decision
  summary: "Keep nested Super mapped to Ctrl+Alt; the independent layout modifier alone is Ctrl+Shift for layout F-keys. Phantomat Canvas test still has Hyprland dwindle as its global layout, but canvas auto_float/auto_place intentionally make app windows floating; Canvas and Overview are plugin modes, not Hyprland layouts, and the Canvas preset omits normal layout binds."
  source: "User clarification; verified nested profile override, Hyprland appearance config, Phantomat Canvas preset and binding gates"
  affects: [phantomat-overview-boundary]

- time: 2026-10-11T03:11:34
  kind: decision
  summary: "Dormant-until-enter Canvas, explicit nested controls, and restored native tiling"
  source: "User clarified two-stage tiling-to-Canvas-to-HUD flow; verified config, plugin source, and isolated nested run"
  affects: [phantomat-overview-boundary]

- time: 2026-10-11T03:11:34
  kind: reversal
  summary: "Replace startup-open persistent Canvas behavior: nested test starts with native dwindle/tiled windows; explicit enter opens monitor-scoped Canvas, HUD remains separately toggled, and exit closes Canvas restoring native state. Keep layout binds loaded. Synchronize Canvas easing/speed with Hyprland and fade the minimap Arrange control with its map."
  source: "User requested native layout until explicit plugin entry, separate HUD toggle, aligned minimap animation; isolated foot tile/float/restore test"
  affects: [phantomat-overview-boundary]

- time: 2026-10-11T03:27:32
  kind: decision
  summary: "Replace split Canvas controls with one nested Ctrl+Shift+F5 toggle and gate Ctrl+Alt+O to the active Canvas; remove the startup GUI probe."
  source: brain update-truth
  affects: [phantomat-overview-boundary]

- time: 2026-10-11T03:27:33
  kind: reversal
  summary: "Replace Ctrl+Alt+C enter and Ctrl+Shift+C exit with one Ctrl+Shift+F5 Canvas toggle; Ctrl+Alt+O is inert unless Canvas is active on the focused output."
  source: "User-confirmed keymap and startup-flash fix, 2026-10-11"
  affects: [phantomat-overview-boundary]

- time: 2026-10-11T03:32:07
  kind: decision
  summary: "Make both Canvas controls survive Phantomat keyboard input capture; runtime regression check verifies their exact chords and capture flags."
  source: brain update-truth
  affects: [phantomat-overview-boundary]

- time: 2026-10-11T03:32:07
  kind: decision
  summary: Set allow_input_capture on the Canvas toggle and HUD bindings because Phantomat captures keyboard input while Canvas is active.
  source: "User-reported inactive HUD key; Hyprland binds/flags.md and captured bind JSON showed both flags false."
  affects: [phantomat-overview-boundary]

- time: 2026-10-12T03:03:59
  kind: evidence
  summary: "Current Phantomat desktop Canvas is monitor-instantiated, not workspace-bound: desktop_mode selects one shared floating-window plane; workspace keys become virtual canvas places, not independent Hyprland workspaces. The upstream planned isolation is per-screen, not per-workspace. A workspace-bound Canvas therefore needs plugin architecture changes, not a config switch."
  source: "Inspected refs/phantomat source, docs/window-rules.md, examples/spatialoverview.lua, tests/places-nested.py; fetched origin (no upstream commits beyond a1e8a08), 2026-10-12"
  affects: [phantomat-overview-boundary]

- time: 2026-10-12T03:14:17
  kind: decision
  summary: "Reverse monitor-scoped Canvas ownership: Canvas mode, camera/layout state, and native restoration now belong to each real Hyprland workspace; HUD remains separate."
  source: "User approved implementation of workspace-bound Canvas after upstream/source feasibility review, 2026-10-12"
  affects: [phantomat-overview-boundary]

- time: 2026-10-13T03:40:02
  kind: decision
  summary: "Separate requested workspace Canvas mode from live rendering and native input; preserve fullscreen and explicit window ownership during suspension, teardown and navigation."
  source: "User workspace-bound Canvas requirement; scoped source audit and isolated fullscreen activation/resume run, 2026-10-13"
  affects: [phantomat-overview-boundary]

- time: 2026-10-13T04:03:17
  kind: evidence
  summary: "Rebuilt workspace-bound fork passed native geometry/camera isolation, incoming-window adoption, moved-window undo, deferred fullscreen activation and disable, special-workspace state, two-output arrow routing, and unload with fullscreen preservation. Physical shortcut/typing injection skipped explicitly because wtype is absent. Actual isolated test-env runtime validated startup dwindle/dormant Canvas, exact bindings and generated palette; closure preserved host hashes/manager environment and left no tagged children."
  source: "refs/phantomat/tests/workspace-canvas-nested.py; /tmp/my-shell-test.rIFXg1/preflight.log and cleanup logs; rebuilt plugin SHA-256 38dc3daabfee2c2c6887f749ba8f525a9988da140a0ac2b81010eca41b4f186b, 2026-10-13"
  affects: [phantomat-overview-boundary]

- time: 2026-10-13T05:07:16
  kind: reversal
  summary: "Workspace switch suspends Canvas without restoring native tiling or changing client targets; focused client is selected and centered on Canvas entry, and Hyprland workspace animation remains enabled."
  source: "User requirement; source-level correction and passing MPV-based nested regression, 2026-10-13"
  affects: [phantomat-overview-boundary]

- time: 2026-10-13T05:07:16
  kind: decision
  summary: Rewrote compiled_truth to the new best understanding
  source: brain update-truth
  affects: [phantomat-overview-boundary]

- time: 2026-10-13T05:21:51
  kind: reversal
  summary: "Retain the outgoing Canvas renderer through Hyprland's workspace animation so camera-transformed clients do not jump; render an incoming Canvas independently and preserve the saved camera. Nested HUD binding uses Ctrl+O, not Ctrl+Alt+O."
  source: "User transition/input request; reviewed workspace renderer handoff and passing MPV nested transition run, 2026-10-13"
  affects: [phantomat-overview-boundary]

- time: 2026-10-13T05:21:51
  kind: decision
  summary: Correct the workspace-animation handoff model and use a single Ctrl modifier chord for the nested HUD.
  source: "User-approved renderer handoff; MPV nested transition regression and frame captures, 2026-10-13"
  affects: [phantomat-overview-boundary]

- time: 2026-10-13T05:32:29
  kind: decision
  summary: "Use explicit fade-only Hyprland workspace transitions in production and nested tests; preserve animated workspace opacity in Canvas surfaces while keeping client geometry and camera unchanged across handoff."
  source: "User request and MPV nested regression; local Phantomat renderer inspection"
  affects: [phantomat-overview-boundary]

- time: 2026-10-13T05:36:41
  kind: decision
  summary: "Change the nested Phantomat HUD binding from Ctrl+O to Ctrl+Shift+O as requested."
  source: "User request; hypr/user/nested.lua and tests/README.md updated"
  affects: [phantomat-overview-boundary]

- time: 2026-10-13T05:41:48
  kind: evidence
  summary: "Changed production and nested workspace animation leaves to slide for the requested trial. MPV captures show both transition directions; the isolated regression passes client geometry and camera handoff checks with no compositor config errors. Subjective motion feel awaits user review."
  source: "User requested a slide trial after the workspace-offset fix; refs/phantomat/tests/workspace-canvas-nested.py and captured transition frames, 2026-10-13"
  affects: [phantomat-overview-boundary]

- time: 2026-10-13T05:52:59
  kind: decision
  summary: "Compose each workspace-bound Canvas slide with that workspace's signed m_renderOffset in monitor pixels after the Canvas camera; preserve client geometry and camera state, and keep screen-fixed windows stationary."
  source: "User-approved motion fix; rebuilt plugin and successful nested regression of both workspace-switch directions, 2026-10-13"
  affects: [phantomat-overview-boundary]

- time: 2026-10-13T06:12:59
  kind: reversal
  summary: "Hyprland renders all animating workspaces in one monitor workspace pass, not one call per workspace. Preserve that native pass during Canvas transitions; replace only the Canvas-owned client planes at the native window-pass boundary so outgoing native clients, pinned windows, special workspaces, and layers remain present."
  source: "Installed Hyprland efb5099378 renderWorkspace/renderAllClientsForWorkspace source and user-reported incoming Canvas blank interval, 2026-10-13"
  affects: [phantomat-overview-boundary]

- time: 2026-10-13T06:32:17
  kind: decision
  summary: "Correct monitor render-pass composition, preserve native animation scheduling, and align Canvas surfaces with borders; old build fails both transition pixel directions, rebuilt fix passes MPV frames, geometry/camera isolation, fullscreen/unload and scoped child cleanup."
  source: "Reviewed local workspace-bound fork, ABI-matched build, and captured early/middle/late/final MPV frames, 2026-10-13"
  affects: [phantomat-overview-boundary]

- time: 2026-10-13T06:45:35
  kind: evidence
  summary: "Rapid-switch regression passed 384 native/Canvas and Canvas/Canvas switches, including maximum-rate bursts and 8 ms reversal gaps with concurrent frame captures. Saved cameras, client geometry/ownership, Canvas activation, visible content, fullscreen/unload and scoped MPV cleanup stayed correct; no Lua or hook errors. Dispatch medians 2.97/3.06 ms and p95 3.87/3.94 ms measure control round trips, not frame rate. Source audit identified retained-renderer recreation on quick return as a future allocation/ownership optimization; no collapse was observed and animation parameters were left intact."
  source: "refs/phantomat/tests/workspace-canvas-nested.py; rapid-* captures and compositor log; unchanged rebuilt plugin 1255ef6d2bca835f, 2026-10-13"
  affects: [phantomat-overview-boundary]

- time: 2026-10-13T06:54:14
  kind: decision
  summary: "Reuse only an exact monitor/workspace renderer still retained by the native transition; reactivation removes it from transition cleanup and keeps the HUD closed, camera and client geometry unchanged. Retention remains animation-bounded, not a permanent renderer cache, and input override ownership must remain singular through handoff."
  source: "User approved retained-renderer reuse after rapid-switch verification, 2026-10-13"
  affects: [phantomat-overview-boundary]

- time: 2026-10-13T07:05:35
  kind: decision
  summary: "Bound fast-return renderer reuse to existing native transitions and keep original input settings under singular ownership; rebuilt fork passes rapid-switch, HUD-return, idle release and unload regressions."
  source: "User-approved optimization; rebuilt plugin 02cfd8c686e0ca2f and MPV nested regression, 2026-10-13"
  affects: [phantomat-overview-boundary]

- time: 2026-10-13T07:06:11
  kind: evidence
  summary: "Rebuilt reuse optimization passed 384 rapid native/Canvas and Canvas/Canvas switches: 287 retained-renderer resumes and one fresh renderer during bursts. Client ownership/geometry, camera, frame content, HUD-closed quick return, idle renderer release, original input-setting restoration, fullscreen/multi-output/unload and scoped child cleanup all passed; no Lua or overview-hook errors. Dispatch medians 2.93/3.16 ms are control round trips, not FPS; animation timing unchanged. Physical shortcut/typing injection remains explicitly skipped without wtype."
  source: "refs/phantomat/tests/workspace-canvas-nested.py; final MPV captures/log and plugin SHA-256 02cfd8c686e0ca2fb07b98f9636d3e286bdff5e9c6817ce2848ac4e4eaeaeb0e, 2026-10-13"
  affects: [phantomat-overview-boundary]

- time: 2026-10-13T18:28:43
  kind: decision
  summary: "Native workspaces must retain native Hyprland drawing, damage tracking and input behavior. Canvas owns only its requested workspace and animation-bounded outgoing plane; empty native workspaces must never retain or flash Canvas client fragments. Diagnose/fix the ownership and repaint boundary rather than clearing persistent configuration/theme caches."
  source: "User clarified the half-client flashing symptom and strict workspace-only plugin ownership, 2026-10-13"
  affects: [phantomat-overview-boundary]

- time: 2026-10-13T18:53:41
  kind: decision
  summary: "Represent a workspace-bound Canvas transition as a finite monitor-sized camera viewport, not a translated infinite canvas. Project windows through the saved camera, clip to that viewport, then apply native workspace displacement/opacity. Off-camera canvas content must not enter an exiting workspace or the empty native workspace. Preserve native workspace animation math, window geometry, input and ownership."
  source: "User identified camera-view versus whole-canvas transition boundary, verified against renderCanvasDesktopScene loop, 2026-10-13"
  affects: [phantomat-overview-boundary]

- time: 2026-10-14T00:44:37
  kind: decision
  summary: "Define Canvas workspace transitions as finite camera views, with native rendering and damage preserved outside their clip."
  source: "User camera-view correction and local rendering-boundary implementation, 2026-10-14"
  affects: [phantomat-overview-boundary]

- time: 2026-10-14T00:53:13
  kind: decision
  summary: "A camera-owned output must expand current-frame damage before Hyprland beginRender snapshots the damage ring, without scheduling an idle repaint loop; retiring the last plane schedules one native erase. Reset lens/minimap uniforms at each output render begin and keep the final-screen lens off during mixed native/Canvas workspace composition."
  source: "Native-buffer ghost captures and installed-ABI Hyprland Renderer.cpp render.pre/beginRender and damageWindow paths, 2026-10-14"
  affects: [phantomat-overview-boundary]

- time: 2026-10-14T01:06:43
  kind: evidence
  summary: "Finite camera-view clip and pre-beginRender output damage are implemented and rebuilt as 95ec96ff2194655cb0e194679c8d2eb0d32e08363206c3edf5348d02aca08f6f. MPV workspace state, camera/geometry preservation, 192 fast switches (96 resumes, zero creations), input restoration and child teardown pass. Natural parent-buffer/displayed-pixel gates still fail intermittently with old-frame snapshots or missing visible Canvas baselines; do not declare the flashing fixed or treat child screencopy-forced repaint as proof. Further visual/presentation verification remains required."
  source: "refs/phantomat/tests/workspace-canvas-nested.py and recorded native parent captures, 2026-10-14"
  affects: [phantomat-overview-boundary]

- time: 2026-10-14T01:18:11
  kind: reversal
  summary: "User confirms camera-view transition currently feels stable and requests an explicit per-workspace remember_overview option. Enabled: returning restores the previous overview camera/zoom and workspace-scoped HUD/search selection instead of forcing 100% Canvas. Disabled: retain HUD-closed return. Keep this compositor-session state separate from persistent window layout, isolate it by real workspace identity, and clear it on explicit Canvas disable/unload."
  source: "User stability confirmation and overview-preserving workspace option request, 2026-10-14"
  affects: [phantomat-overview-boundary]

- time: 2026-10-14T01:31:09
  kind: decision
  summary: "Enable explicit session-only overview restoration; retained/fresh returns, separate searches, focus, native input release, disabled behavior and scoped child cleanup pass."
  source: "User overview-return request; rebuilt fork and focused MPV nested regression, 2026-10-14"
  affects: [phantomat-overview-boundary]

- time: 2026-10-14T01:45:57
  kind: evidence
  summary: "Border-only MPV control with solid green native colors, zero rounding, no blur/shadow/grid/minimap/Navigator reproduces uneven client-border coverage: native 2 pixels on all edges, Canvas at 0.72/0.90 has top/left 2 and bottom/right 1; pan can produce a 3-pixel edge. Native borders return uniformly to 2 after Canvas disable. Exact user-reported thin top edge was not reproduced. Likely mechanism: camera texture boxes are pixel-rounded while manually redrawn border boxes remain fractional; native Hyprland rounds its border box. This is a diagnostic inference, not an implemented or verified fix; no plugin code changed."
  source: "Isolated /tmp/ui-shell-border-check.AdAAiL captures and check.py; refs/phantomat Window.cpp:662 and main.cpp:514; installed-ABI Hyprland efb5099378 border decoration source, 2026-10-14"
  affects: [phantomat-overview-boundary]

- time: 2026-10-14T01:50:09
  kind: evidence
  summary: "The border diagnostic inference is confirmed by a narrow rendering-only fix: round the final overview border box onto the same pixel grid as its surface. Rebuilt MPV captures show all visible edges uniformly 2 pixels at 100% output scaling; assert-based checks show uniformly 3 pixels at 125% scaling across rest, overview zoom 0.72/0.90/1.125, up/down pan, resting return and native restoration. The adjacent overview-state regression passes retained/fresh restoration, workspace isolation, keyboard focus, unchanged geometry, native input release and scoped MPV cleanup. No camera, workspace, animation or palette changes were made."
  source: "refs/phantomat/Window.cpp:664; make dev-build-phantomat; /tmp/ui-shell-border-check.AdAAiL/check.py and scale-1.25 frames; workspace-canvas-nested.py --overview-state-only, 2026-10-14"
  affects: [phantomat-overview-boundary]

- time: 2026-10-14T02:01:29
  kind: decision
  summary: "User requests overview HUD/labels/selection to fade during real workspace switching only, with the selected outline moving with its client rather than waiting at the destination. Reuse native workspace displacement, visibility and opacity; retain only renderer-local visual data for animation-bounded outgoing drawing while Navigator input/query ownership ends immediately. Do not add timers, a second animation system, client geometry/resize changes or unrelated HUD-toggle behavior."
  source: "User clarified Switching workspaces; selected-reticle and workspace camera render paths, 2026-10-14"
  affects: [phantomat-overview-boundary]

- time: 2026-10-14T02:20:07
  kind: decision
  summary: "Workspace-switch overview chrome now follows native motion/visibility, selected frames stay attached and clipped to clients, and outgoing visuals retain no live input. Rebuilt focused fade/alignment and overview-state MPV regressions passed with scoped cleanup."
  source: "User clarified workspace switches only; scrollOverview.cpp renderer-local visual frame and native opacity/displacement; --hud-transition-only and --overview-state-only, plugin 64493fd6a6f763e7, 2026-10-14"
  affects: [phantomat-overview-boundary]
