---
id: hyprland-native-composition
title: Hyprland uses native per-workspace composition
category: decision
status: active
tags: [hyprland, lua, workspaces, groups]
created: "2026-09-30T22:10:36"
updated: "2026-10-30T14:22:34"
---

<!-- compiled_truth -->
# Decision

The project Hyprland configuration is a small Lua composition rooted at `hypr/hyprland.lua`, not a port of the legacy Hyprland 0.40 configuration. It targets Hyprland 0.57.0 or newer and follows the current native Lua/config contracts directly, with no compatibility path for older versions.

## Constraints

- Old configuration is evidence only for durable personal hardware and keyboard facts: US + Arabic qwerty, Alt+Shift layout switching, Menu Compose, and the known output.
- Use current native Hyprland Lua APIs and built-in layouts; do not add a scrolling-layout plugin.
- Keep the scrolling special workspace (`special:scroll`) permanently on the built-in `scrolling` layout. Its `follow_focus` config uses the explicit integer mode `1`: focus may move the tape, and mouse clicks always move it.
- Use a one-window tagged hidden special workspace rather than an always-visible scratchpad.
- Groups are deliberate and discoverable through a short submap, with automatic grouping disabled. Group-lock bindings use `hl.dsp.group.lock({ action = "toggle" })`; `lock_active()` is deprecated.
- A layout-cycling binding changes the current regular workspace only; layout is a workspace property, not global shell state.
- Layer policy explicitly allows newly opened Quickshell overlays above fullscreen windows and keeps keyboard-interactive layers focused when the pointer moves.
- Hyprland binds use direct dispatchers and known system backends. There is no project daemon, IPC control plane, or custom shell CLI.

## Rationale

This preserves sophisticated window management while keeping the shell focused and composable. It adopts modern Hyprland capabilities directly instead of importing Omarchy helper tooling or an obsolete legacy configuration.


## Timeline

- time: 2026-09-30T22:10:36
  kind: decision
  summary: "Created this page: Hyprland uses native per-workspace composition"
  source: User direction and Hyprland 0.56 wiki
  affects: [hyprland-native-composition]

- time: 2026-09-30T22:10:36
  kind: decision
  summary: "Recorded native workspace, hidden-window, scrolling, and group composition policy."
  source: User direction and Hyprland 0.56 wiki
  affects: [hyprland-native-composition]

- time: 2026-10-10T15:43:58
  kind: decision
  summary: Prioritize native workspace controls in the temporary bar and full nested-session Phantomat integration before screenshot and recording menus.
  source: "User next-step preference, 2026-10-10"
  affects: [phantomat-overview-boundary]

- time: 2026-10-10T15:49:39
  kind: decision
  summary: "The current bar remains temporary test UI: add only numbered workspace controls now to test switching, moving windows and Phantomat. Defer final bar design until later reference study."
  source: "User scope correction, 2026-10-10"
  affects: [hyprland-native-composition]

- time: 2026-10-30T14:17:18
  kind: decision
  summary: Align Hyprland configuration with the installed 0.57.0 Lua/config API and make shell-layer focus/stacking policy explicit.
  source: "Hyprland wiki update b8b7239..b0a33ad; installed Hyprland 0.57.0; CONFIGURATION.md"
  affects: [hyprland-native-composition]

- time: 2026-10-30T14:18:23
  kind: decision
  summary: Defer recording the 0.57 target and layer-policy conclusion until a live nested session verifies the config.
  source: User requested live-run verification before documentation
  affects: [hyprland-native-composition]

- time: 2026-10-30T14:22:34
  kind: decision
  summary: "Adopt the verified Hyprland 0.57 config contract: numeric scrolling mode, current group-lock API, and explicit shell-layer policy."
  source: Hyprland wiki refresh and live nested startup on installed 0.57.0
  affects: [hyprland-native-composition]

- time: 2026-10-30T14:22:34
  kind: evidence
  summary: "Live make test-env on Hyprland 0.57.0 loaded the Lua config and mapped the Quickshell bar with no config/Lua/deprecation errors; exact-prefix cleanup left no test children. The nested virtual output still logs NO PREFERRED MODE; forced cleanup made this interactive target exit 137, so normal close behavior was not verified."
  source: "Launcher and hyprland.log in /tmp/my-shell-test.PMtBuX; close-session ui-shell-test-PMtBuX"
  affects: [hyprland-native-composition]
