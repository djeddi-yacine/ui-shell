---
id: shell-scope-and-layout
title: Focused shell scope and repository layout
category: decision
status: active
tags: [scope, quickshell, hyprland, qml, lua, bash]
created: "2026-09-30T19:32:35"
updated: "2026-11-08T05:31:33"
---

<!-- compiled_truth -->
# Decision

Build a focused, composable Hyprland shell rather than a desktop-environment replacement.

## Scope

- `hypr/` contains Hyprland Lua configuration.
- `shell/` contains Quickshell QML UI; JavaScript is not part of the shell implementation.
- `scripts/` contains only installed runtime Bash helpers for deliberate external effects such as wallpaper changes and color generation.
- `tools/` owns development staging/build tooling and its Make definitions; it is not installed into the shell runtime.
- `tests/` owns test configuration, fixtures and QML cases; `tests/scripts/` owns sandbox, session lifecycle and check helpers. No test code is installed into the runtime package.
- The root Makefile routes explicitly named `dev-*` and `test-*` targets from their owning directories. `make test-env` is the persistent interactive test entrypoint, `make test-env-fresh` is disposable and `make test` is the automated suite. See [[isolated-nested-test-environment]].
- `FEATURES.md` is the controlled feature inventory and must be updated before adding feature work.

## Constraints

- No custom daemon.
- No custom IPC protocol.
- No custom shell CLI.
- No weather, btop-style monitoring panel, full settings app, or broad system-management UI unless the feature inventory is explicitly changed.
- Shared generated state uses files watched by QML rather than a service bus.

## Rationale

The shell should stay smooth, small, and composable. QML owns composition and presentation, Lua owns Hyprland policy, and Bash owns a small set of external system effects. Keeping these responsibilities separate limits process count, duplicated state, and accidental desktop-environment scope.


## Timeline

- time: 2026-09-30T19:32:35
  kind: decision
  summary: "Created this page: Focused shell scope and repository layout"
  source: User requirements and FEATURES.md
  affects: [shell-scope-and-layout]

- time: 2026-09-30T19:32:43
  kind: decision
  summary: "Recorded the clarified shell scope, folder boundaries, and no-daemon/no-IPC/no-CLI constraints."
  source: User requirements and FEATURES.md
  affects: [shell-scope-and-layout]

- time: 2026-10-07T10:58:49
  kind: decision
  summary: "Make runtime, development, and testing distinct ownership boundaries and public Make entrypoints."
  source: User approved removing mixed runtime/test scripts and ambiguous targets.
  affects: [shell-scope-and-layout]

- time: 2026-11-05T06:19:34
  kind: decision
  summary: "Project renamed my-shell -> ui-shell, case by case: my-shell->ui-shell (layer namespaces, ShellId, bar label, docs), MY_SHELL_*->UI_SHELL_* (env vars), MyShell.*->UiShell.* (QML module URIs), myshell->uishell (test desktop entries), org.my.shell->org.ui.shell (AppId). No absolute or personal paths exist in tracked content (whitelist .gitignore; refs/, .build, .test-state untracked). Older brain pages and timeline text still say my-shell as history. The checkout directory name itself is unchanged."
  source: pre-push preparation
  affects: [shell-scope-and-layout]

- time: 2026-11-05T06:41:24
  kind: decision
  summary: "Tuning is the third shell module beside launcher and wallpaper picker (modules/tuning, SUPER+T, layer ui-shell-control-tuning, click-through mask). scripts/control-model/ holds the model data inside scripts/ because stage-config installs scripts/ whole and the renderer runs from the installed copy; a top-level model/ dir is the cleaner future home. Verification runs foreground, one target at a time."
  source: session decisions 2026-11-05
  affects: [shell-scope-and-layout]

- time: 2026-11-08T03:42:11
  kind: decision
  summary: "Panel mutual exclusion is one owner: shell/modules/panels PanelGroup lists the panel states that may not be open together (shell.qml). It replaced seven hand-written Connections blocks that had drifted (tuning and audio did not close the picker or launcher). Coexistence is a separate group, not a per-panel flag. Tuning's exit dialog asks on editor.dirty (differs from what the panel opened with), not on differing from the mode preset."
  source: chat
  affects: [shell-scope-and-layout]

- time: 2026-11-08T04:27:08
  kind: decision
  summary: "Bar design is deferred to last. Until then the bar is development scaffolding: one labelled text button per panel (Launcher, Wallpaper, Tuning, Audio, Screenshot, Record, Media), then the workspace numbers, so every panel can be opened by mouse on the host. Mpris bar entry is always visible."
  source: chat
  affects: [shell-scope-and-layout]

- time: 2026-11-08T04:32:38
  kind: decision
  summary: "Panels spawn centered by default via one shared rule (config/Placement.qml); each panel config has its own 'placement' (center|top|bottom) so any panel moves independently. Replaces ad-hoc per-panel positions."
  affects: [shell-scope-and-layout]

- time: 2026-11-08T05:31:33
  kind: decision
  summary: "Panel motion is a pop-in (scale 0.96->1 + fade from 0, 120ms), no slide (PanelMotion.scale replaces offset). On a host Hyprland the compositor's own layersIn slide still shows unless the user's config has the no_anim layer rule for ui-shell-* namespaces (project profile has it in hypr/rules.lua; host config does not)."
  affects: [shell-scope-and-layout]
