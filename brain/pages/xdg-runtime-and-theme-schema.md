---
id: xdg-runtime-and-theme-schema
title: Explicit XDG runtime layout and portable theme colors
category: decision
status: active
tags: [config, xdg, theme, composition]
created: "2026-10-06T16:51:45"
updated: "2026-11-05T06:41:24"
---

<!-- compiled_truth -->
# Decision

The supported runtime root is $XDG_CONFIG_HOME/ui-shell (XDG's explicit HOME/.config default when unset), containing scripts/, quickshell/, themes/, profiles/, default/ and config.ini, with room for owned subsystem configuration such as hypr/ and component overrides. Source folders remain development organization, not runtime addresses; the only shipped seed is default/, while themes/ and profiles/ are runtime user stores. See [[shipped-default-seed]].

config.ini is a versioned, strictly validated installation/path and selected-profile manifest. QML remains the shell behavior/style configuration and Lua remains Hyprland configuration. No arbitrary evaluation, shell expansion, custom daemon, IPC control plane or settings application is added. Generated JSON is intermediate data only, not user shell configuration.

Runtime consumers must use configured command roles and generated paths rather than reconstructing checkout locations. Pure color renderers take explicit input/output arguments. The only stable conventions are documented bootstrap/config locations and native language module relationships; moving scripts or palette folders changes manifest data and its generated projections, not UI code.

A Theme explicitly declares mode, shell color roles, its full named color palette and native subsystem color settings. Imported local 100-themes definitions preserve every named hex slot, all bright/background/foreground shades and native Hyprland gradient stops, alpha and angle. Caller-chosen status mappings remain explicit; ANSI names do not promise hue or severity. Import is distinct from activation; selected file palettes and wallpaper-derived palettes are explicit sources. Colors do not alter the sharp geometry, motion or keyboard interaction contracts.

Tests must stage the real scripts/quickshell/themes/profiles/default/config.ini layout under their private XDG config root, generate non-default Theme/profile fixtures privately, prove relocation through manifest edits, retain explicitly persistent wallpaper/settings state, and inspect rendered symptoms and cleanup without changing host HOME/XDG or generated files. Cache and state locations are explicit configuration, not compatibility aliases.

Related: [[shared-style-and-toolkit-integration]], [[wallpaper-source-and-generation]], [[isolated-nested-test-environment]].


## Wallpaper folders

The manifest declares only the required named wallpaper folder list; there is no [wallpaper] section or defaultFolder option. The checked-in list explicitly maps `default = default` (the shipped wallpaper seed) and `project = wallpapers`; these are manifest entries, not built-in locations. The catalog reads all configured roots, not a folder compiled into code. A saved wallpaper is a stable folder ID plus filename; changing that folder's configured path does not invalidate its selection, and duplicate filenames across folders remain distinct. Every saved wallpaper selection, including the default image and each output override, must explicitly declare its folder ID. Missing IDs are configuration errors, never inherited from another setting or list order. Missing/invalid folders fail visibly. The current unreleased manifest remains schema 2, with no schema-1 support, migration helper or recovery mode.

## Pre-release changes

No backward-compatibility code is justified for unreleased contracts. Change the current model directly; remove deprecated settings, dual-read paths, automatic conversions and copies of old test preferences. Outdated configuration fails clearly and is updated explicitly or reset through the dedicated private test-state command. Preserve unrelated user data; do not silently clean it.

## Theme definitions and compiled profiles

The manifest declares independent paths.themes and paths.profiles roots. Theme definitions are flat themes/<id>/config.ini sources; there is no custom/ or 100-themes/ storage category. Schema 2 separates explicit shell roles in [palette], the complete named source slots in [colors], and native border expressions in [hyprland]. The editor, save protocol, and every native projection carry the full source data without dropping unedited values.

Profiles are composition recipes under XDG config, while resolved palettes and complete generated subsystem bundles are reproducible under XDG cache. Installation/bootstrap projection is separate from color bundles. One focused coordinator prepares enabled target renderers before native activation. Import/browse/preview never publishes a profile. The Source selector retains the current wallpaper draft and loads only the selected Theme. Only final Save and apply persists the association; selected named identity survives restart, and validation/stale-edit/native partial-failure reporting remains explicit.

Profiles commit one self-contained INI recipe: full saved color data, optional named Theme identities and wallpaper choices. Generated palettes and native subsystem projections belong together in a complete immutable XDG-cache generation. Bootstrap addresses and configured renderer roles remain separate from generated colors. There is no unreleased-schema migration or dual reader. Explicit reference-theme regeneration replaces matching reference IDs with the current full-color schema; unrelated definitions and saved profiles stay untouched, and import never compiles profiles.

Wallpaper cache defaults use ui-shell explicitly. Full named image palettes use the content-addressed `<sha256>-<mode>-v2` cache key: the hash identifies image bytes, and the key carries neither the wallpaper filename nor the extractor name. Old `matugen4` keys are rejected and require reselection; changing the key schema invalidates old entries instead of treating incomplete palettes as valid. See [[theme-profile-bundles]] and [[wallpaper-cache-identity]].


## Timeline

- time: 2026-10-06T16:51:45
  kind: decision
  summary: "Created this page: Explicit XDG runtime layout and portable theme colors"
  source: "User standard ui-shell layout requirement, 2026-10-06"
  affects: [xdg-runtime-and-theme-schema]

- time: 2026-10-06T16:51:45
  kind: decision
  summary: "Separate deployment manifest and palette data from native QML behavior; test installed XDG layout rather than checkout paths."
  source: User standard ui-shell config scheme and custom/100-themes requirements
  affects: [xdg-runtime-and-theme-schema]

- time: 2026-10-06T17:35:12
  kind: decision
  summary: "Require configurable wallpaper folder list and stable folder IDs; preserve explicit default inheritance during schema migration."
  source: "User: config should list wallpaper folders, never hardcode them"
  affects: [xdg-runtime-and-theme-schema]

- time: 2026-10-06T17:58:16
  kind: decision
  summary: Remove defaultFolder and compatibility machinery for unreleased configuration.
  source: "User: remove defaultFolder; no backward compatibility before release"
  affects: [xdg-runtime-and-theme-schema]

- time: 2026-10-06T17:58:16
  kind: reversal
  summary: Unreleased configuration must not retain default-folder inheritance or compatibility migrations.
  source: User explicitly rejected pre-release backward compatibility
  affects: [xdg-runtime-and-theme-schema]

- time: 2026-10-07T20:20:10
  kind: decision
  summary: Select named wallpaper/color bundles and native live palettes in the XDG contract
  source: "User approved palette editor/profile bundles, 2026-10-07"
  affects: [xdg-runtime-and-theme-schema]

- time: 2026-10-08T00:00:30
  kind: decision
  summary: Replace immediate wallpaper commit with the approved wallpaper/color draft flow and explicit labels
  source: "User-approved final Save and apply workflow, 2026-10-07"
  affects: [xdg-runtime-and-theme-schema]

- time: 2026-10-08T00:00:30
  kind: reversal
  summary: "Enter advances the draft rather than applying; saved profiles load as draft bases, and final Save and apply is the only UI commit."
  source: "User explicitly chose deferred wallpaper and colors until final save, 2026-10-07"
  affects: [xdg-runtime-and-theme-schema]

- time: 2026-10-08T02:18:23
  kind: decision
  summary: Separate flat Theme definition storage from generated profiles and standardize all wallpaper XDG namespaces to ui-shell.
  source: brain update-truth
  affects: [xdg-runtime-and-theme-schema]

- time: 2026-10-09T05:04:36
  kind: decision
  summary: "Preserve full named palette schema and native border settings; distinguish profile recipes from compiled cache bundles"
  source: "Approved theme composition design, 2026-10-09"
  affects: [xdg-runtime-and-theme-schema]

- time: 2026-10-10T03:19:02
  kind: decision
  summary: "Specify self-contained durable recipes, cached native generations and current-schema-only reference regeneration"
  source: "Approved implementation and user regeneration/no-backward-compatibility requirements, 2026-10-10"
  affects: [xdg-runtime-and-theme-schema]

- time: 2026-10-27T02:44:54
  kind: decision
  summary: "Replace the matugen4 cache identity with the content-addressed sha256-mode-v2 key; old keys require reselection."
  source: "Wallpaper cache key decision, 2026-10-27"
  affects: [xdg-runtime-and-theme-schema]

- time: 2026-10-27T03:30:58
  kind: decision
  summary: Add the single default seed and private fixture policy to the XDG runtime contract
  source: "Default seed redesign, 2026-10-27"
  affects: [xdg-runtime-and-theme-schema]

- time: 2026-10-27T03:30:58
  kind: decision
  summary: Add the single default seed and private fixture policy to the XDG runtime contract
  source: "Implemented default seed and staging migration, 2026-10-27"
  affects: [xdg-runtime-and-theme-schema, shipped-default-seed]

- time: 2026-11-05T06:41:24
  kind: decision
  summary: "Manifest seed moved from repo root to tools/config.ini (used only by dev staging and tests; installed copy is ~/.config/ui-shell/config.ini, created once and never overwritten). read-shell-config defaults renderControlTuning when an installed manifest lacks it, so adding a command key never invalidates existing installs."
  source: pre-push preparation
  affects: [xdg-runtime-and-theme-schema]
