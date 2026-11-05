---
id: wallpaper-source-and-generation
title: Project wallpapers drive Hyprpaper and palette generation
category: decision
status: active
tags: [wallpaper, hyprpaper, matugen, theme]
created: "2026-09-30T22:47:55"
updated: "2026-11-05T07:01:31"
---

<!-- compiled_truth -->
# Decision

The wallpaper picker is the first stage of a focused wallpaper/color bundle draft. Choosing an image from the user-declared folder list advances to palette choice and optional edits; only final Save and apply persists and activates the bundle. See [[theme-profile-bundles]].

## Configured folder identity

config.ini lists every source in [wallpaper_folders] with a stable ID. The checked-in manifest explicitly maps `default = default` (the shipped wallpaper seed) and `project = wallpapers`; these are manifest entries, not built-in locations. There is no inferred active folder; the picker combines all configured folders. The shipped default profile selects folder `default` and path `default.png`. See [[shipped-default-seed]]. A selection persists folder ID plus filename, so identical basenames across folders remain distinct and relocating a folder changes manifest data only. Every saved selection must explicitly name its folder ID. Missing or empty IDs fail, including on the default wallpaper image; no folder is inferred from list order or legacy state. Missing folders and unknown IDs fail visibly; the catalog does not silently omit sources. Ctrl+I identifies the candidate folder and search includes its ID. Catalog scanning remains flat, not recursive.

Runtime paths and commands come from [[xdg-runtime-and-theme-schema]]. Native Hyprpaper receives a canonical image path only at its API boundary; the configured logical path remains the QML identity. Derived caches remain content-addressed and independent of source-folder relocation.

## Default and overrides

The registry has one required user-set default and optional monitors entries. Every display uses its override or the default. Default is a configuration scope, not a separate runtime state. The picker labels it Shared default and exposes further scope information through Ctrl+I. Default/default instead identifies a named profile title and ID, not another state; the shipped default profile selects folder `default` and path `default.png`, and its palette is generated from that image. Host-specific monitor overrides remain explicit user data. Per-output colors resolve through an explicit defaultPalette and optional overrides, with no missing-assignment modes. Missing defaults and invalid values are errors.

## Interaction contract

- The target is either the explicitly editable default wallpaper or one exact connected output override; there is no ambiguous apply-everywhere action.
- A flat thumbnail grid across configured folders, search field, and keyboard selection are sufficient. Pointer and keyboard share one candidate. Enter or Choose theme advances without applying or persisting. Tab moves focus, not candidate identity. Escape dismisses the editor back to the picker; closing the whole picker discards its draft without a write.
- Opening clears the filter, selects the saved image and focuses its grid tile; Ctrl+F focuses search. A missing saved image is reported, not replaced by another image. The chosen output, folder ID, filename and fit mode are captured for the editor's draft. Back preserves it. Only Save and apply publishes and activates wallpapers and palette policy together.
- Draft reads may populate derived color caches and immutable native QML snapshots, but cannot change the selected manifest, saved registry, live wallpaper or palette. Final commit validates the active and chosen-base revisions and rejects stale edits before selection. Runtime errors use a scoped copyable popup; no staged status text or error-driven resizing belongs in the picker.
- Successful native bundle activation updates reactive current and saved read models together. Validation/preflight failure leaves active configuration intact; errors after durable profile selection report partial native activation honestly. Last confirmed native state remains authoritative if activation fails. The immutable startup snapshot remains separate. External wallpaper changes are not watched.
- Selection, hover, focus and current values are distinct; tiles show only In use. Persistence remains internal to supply the opening candidate and reflect save errors. Ordinary controls use neutral surfaces and uniform full-perimeter state borders; only the primary action has a contrast-aware solid fill. Focus is an independent outline; shared style tokens and per-output palettes apply throughout.

## Scope boundary

- The picker owns UI draft state only. Configured roles separate pure selection transformation, color caching, native QML/Lua rendering, owned bundle publication, revision-checked selection and native application. Loaded profiles are draft bases, not intermediate activation actions.
- Live application uses the existing explicitly enabled native Hyprpaper interface and an explicit Hyprland session; it adds no custom daemon, IPC protocol or product CLI. Exact targets must be connected. Hyprpaper encodes Default as an empty output; changing it updates displays that inherit the default and preserves explicit display overrides.
- Native startup composition seeds QML/Lua palettes and Hyprpaper assignments. Final Save and apply commits the pending image and selected palette policy together. Wallpaper providers resolve per-image colors; authored providers preserve custom colors. Other selections/scopes in the chosen base remain intact. Low-level persist-only helpers remain distinct from native activation and color refresh.
- No image framework, generic plugin system, video wallpaper support, favorites, folder navigation, sorting controls, blur, or shader effects.

## Composition and output policy

- Picker state, overlay surface, panel, and tile have separate responsibilities. Generated QML catalog and target singletons provide QML-native read models; color mode and cache namespace come from explicit generated state rather than component literals.
- Picker targets are Shared default plus currently connected Quickshell screens; saved entries do not constrain available monitors. First save for a new output creates its registry entry and uses the default fit mode; known selections preserve their fit mode.
- Global Hyprland palette policy is explicit in hypr/user/monitors.lua: palette_source.kind selects default-wallpaper or output-wallpaper. Output mode requires an exact saved output name; unknown targets are errors, not silent substitutions.
- Keyboard picker hosting is independent static user policy in shell/config/Outputs.qml: pickerTargetMode selects an exact screen-index or output-name. An unavailable target is reported without falling back to another screen.
- Native Hyprland global shortcuts open the lazily loaded picker. Controls receive their owning output's style explicitly.
- Tests use private HOME/XDG state and a freshly staged standard runtime package; see [[isolated-nested-test-environment]]. Host selections are protected, and every run is checked for readiness symptoms and cleanup.

## Reference takeaways

Omarchy contributes strong keyboard state distinctions and overlay composition, not its carousel, masks, generic callbacks, or JS helper layer. Noctalia contributes monitor targeting and bounded loading/error feedback, not broad settings. Caelestia contributes direct choose-and-close flow.

The active profile owns its registry; named profile versions preserve other bundles. Configuration persistence is separate from native application/color refresh and always resolves the selected manifest, not stale cached source paths. The Ctrl+T preview-first color editor and profile contract are in [[theme-profile-bundles]].


## Timeline

- time: 2026-09-30T22:47:55
  kind: decision
  summary: "Created this page: Project wallpapers drive Hyprpaper and palette generation"
  source: User direction and local Hyprpaper documentation
  affects: [wallpaper-source-and-generation]

- time: 2026-09-30T22:47:55
  kind: decision
  summary: Recorded explicit project wallpaper source and Hyprpaper/Matugen startup composition.
  source: User direction and local Hyprpaper documentation
  affects: [wallpaper-source-and-generation]

- time: 2026-09-30T22:54:07
  kind: decision
  summary: Recorded generated Lua palette output alongside the existing Quickshell palette renderer.
  source: "User requirement: generated.lua holds explicit constants for Hyprland consumers."
  affects: [wallpaper-source-and-generation]

- time: 2026-09-30T23:20:57
  kind: decision
  summary: "Established per-output wallpaper registry, content-addressed XDG cache palettes, and the global Hyprland palette boundary."
  source: User approved per-monitor wallpaper cache plan.
  affects: [wallpaper-source-and-generation]

- time: 2026-10-01T00:07:57
  kind: decision
  summary: Added the focused wallpaper picker interaction and architecture boundary.
  source: User approved the researched picker direction.
  affects: [wallpaper-source-and-generation]

- time: 2026-10-01T01:03:55
  kind: decision
  summary: Recorded the picker apply pipeline and cleanup-safe nested test contract.
  source: Implemented focused picker and verified bounded nested cleanup.
  affects: [wallpaper-source-and-generation]

- time: 2026-10-02T04:51:51
  kind: decision
  summary: "Made shared control states and runtime monitor discovery explicit, with static user-owned output policy."
  source: User requirements for aligned states and scalable monitor configuration
  affects: [wallpaper-source-and-generation]

- time: 2026-10-02T05:29:08
  kind: decision
  summary: "Saved wallpaper is reactive state distinct from startup; targeting is strict and testing isolated"
  source: "User explicit state and no hidden fallback requirements; isolated runtime checks"
  affects: [wallpaper-source-and-generation]

- time: 2026-10-02T06:25:47
  kind: reversal
  summary: "Confirmed wallpaper selection must apply live to its exact target as well as persist; browsing does not apply. Use existing explicitly enabled native Hyprpaper API, not a new daemon or custom IPC protocol; track confirmed current state separately from saved/startup state."
  source: "User: when I pick a wallpaper it should change."
  affects: [wallpaper-source-and-generation]

- time: 2026-10-02T06:37:07
  kind: decision
  summary: Explicit live Apply and saved/current state replace save-only picker behavior
  source: User request and verified native Hyprpaper contract
  affects: [wallpaper-source-and-generation]

- time: 2026-10-02T06:59:00
  kind: decision
  summary: Single Enter commit and saved-tile initial focus with aligned picker layout
  source: User requirements for complete selection action and keyboard-first opening
  affects: [wallpaper-source-and-generation]

- time: 2026-10-03T03:04:57
  kind: decision
  summary: "Removed the redundant Saved tile badge: persistence chooses the opening candidate while Current marks the applied image; Set wallpaper normally makes them coincide."
  source: User questioned whether Saved and Current still belong in the single apply-and-save workflow.
  affects: [wallpaper-source-and-generation]

- time: 2026-10-03T03:18:52
  kind: decision
  summary: "Adopt user-set defaults and optional overrides throughout configuration; remove recovery/missing-assignment modes."
  source: "User: everything needing fallback must instead have a default; CONFIGURATION.md and migrated Lua/QML/scripts."
  affects: [wallpaper-source-and-generation]

- time: 2026-10-03T03:25:53
  kind: decision
  summary: Align wording with the explicit default-and-override configuration contract.
  source: "User: every configurable concern uses a user-set default, not a recovery state."
  affects: [wallpaper-source-and-generation]

- time: 2026-10-06T17:45:54
  kind: decision
  summary: Replace project-local wallpaper assumption with explicit named configuration folders.
  source: User runtime scheme and explicit wallpaper folder list
  affects: [wallpaper-source-and-generation]

- time: 2026-10-06T17:58:16
  kind: decision
  summary: "Require explicit folder ID on every saved wallpaper; all configured folders remain browsable together."
  source: "User: remove defaultFolder; no backward compatibility before release"
  affects: [wallpaper-source-and-generation]

- time: 2026-10-06T17:58:16
  kind: reversal
  summary: Unreleased configuration must not retain default-folder inheritance or compatibility migrations.
  source: User explicitly rejected pre-release backward compatibility
  affects: [wallpaper-source-and-generation]

- time: 2026-10-07T20:20:10
  kind: decision
  summary: Replace startup-only recoloring with explicit profile-owned live palette refresh
  source: "Approved wallpaper/color bundle workflow, 2026-10-07"
  affects: [wallpaper-source-and-generation]

- time: 2026-10-07T20:20:10
  kind: reversal
  summary: "Wallpaper commit now refreshes live colors for the selected profile; file-provider colors remain fixed instead of always deriving the active theme from the image."
  source: "User approved profile bundle and palette editor, 2026-10-07"
  affects: [wallpaper-source-and-generation]

- time: 2026-10-08T00:00:29
  kind: decision
  summary: Replace immediate wallpaper commit with the approved wallpaper/color draft flow and explicit labels
  source: "User-approved final Save and apply workflow, 2026-10-07"
  affects: [wallpaper-source-and-generation]

- time: 2026-10-08T00:00:29
  kind: reversal
  summary: "Enter advances the draft rather than applying; saved profiles load as draft bases, and final Save and apply is the only UI commit."
  source: "User explicitly chose deferred wallpaper and colors until final save, 2026-10-07"
  affects: [wallpaper-source-and-generation]

- time: 2026-10-27T03:30:58
  kind: decision
  summary: Map the shipped default wallpaper folder explicitly and remove source-store assumptions
  source: "Default seed redesign, 2026-10-27"
  affects: [wallpaper-source-and-generation]

- time: 2026-10-27T03:30:58
  kind: decision
  summary: Map the shipped default wallpaper folder explicitly and remove source-store assumptions
  source: "Implemented default seed and staging migration, 2026-10-27"
  affects: [wallpaper-source-and-generation, shipped-default-seed]

- time: 2026-11-05T06:45:59
  kind: decision
  summary: "Project wallpapers are no longer tracked (40 MB). wallpapers/manifest.txt pins SHA-256; tools/scripts/fetch-wallpapers downloads missing files from this repo's GitHub release assets (tag wallpapers-v1, derived from git remote origin, UI_SHELL_WALLPAPER_URL overrides) and verifies hashes; test-nested runs it before every test mode. Changing an image means a new tag and manifest. default/default.png (1.5 MB) stays tracked."
  source: "user: wallpapers are a problem for the repo"
  affects: [wallpaper-source-and-generation]

- time: 2026-11-05T07:01:31
  kind: reversal
  summary: "Reverses the GitHub-release plan: wallpapers (not tracked) are served from a free image host (i.8upload.com). wallpapers/manifest.txt now holds sha512, name and https URL per file; tools/scripts/fetch-wallpapers downloads only missing or mismatching files, keeps a download only after the sha512 matches, bounds size/time/retries, supports --check, and leaves no temp files on failure. Hosted files are re-encoded versions (wallhaven-01 is now .jpg); tests updated. The old image blobs were pruned from the unpushed initial commit's history (.git 45 MiB -> 3 MiB). Risk: the host could delete files; the hash pins whatever is re-uploaded."
  source: "user supplied hosted URLs; live-tested fetch and failure modes"
  affects: [wallpaper-source-and-generation]
