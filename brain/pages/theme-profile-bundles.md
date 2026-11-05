---
id: theme-profile-bundles
title: Theme profiles bundle wallpapers and palette policy
category: decision
status: active
tags: [theme, profiles, qml, composition]
created: "2026-10-07T19:20:31"
updated: "2026-11-05T02:25:46"
---

<!-- compiled_truth -->
# Decision

## Approved full-palette and profile compilation model

A Theme is one reusable colors-only config.ini directly under themes/<id>/. It preserves the complete named reference palette, bright slots, background/foreground shades, explicit shell color roles and subsystem-native color overrides. Import never discards unconsumed values or flattens Hyprland gradients to an accent. ANSI slot names do not guarantee hue or severity. Native QML and Lua retain behavior, geometry, typography, motion and explicit semantic bindings.

A profile is a composition recipe outside themes/: wallpaper choices, selected named Theme or wallpaper-color source, explicit output overrides and enabled subsystem targets. Its compiled bundle contains the resolved full palette and every generated native subsystem projection, not just wallpaper/palette snapshots. Profile recipes belong in XDG config; wallpaper extraction and complete reproducible profile builds belong in XDG cache. Installation bootstrap is separate from color outputs. Native consumers use the chosen bundle instead of independently configured scattered color destinations.

The source tree has no themes/ or profiles/ stores. Its single default/ seed contains default.png plus theme.ini and profile.ini generated from it; staging cleanly installs that seed and creates themes/default/config.ini and profiles/default/profile.ini only when those runtime stores are absent. User-created and imported stores are never rewritten. See [[shipped-default-seed]].

A focused coordinator resolves sources, reuses the wallpaper cache, invokes separate configured target renderers, publishes a complete generation, then applies native consumers. Import creates inactive Theme definitions only; browsing is metadata-only; preview reads the selected source only. Save and apply is the only UI persistence/activation boundary. Native application may fail partially and must be reported honestly; publishing files atomically does not promise simultaneous compositor and shell application.

The editor/save protocol carries the full named theme, preserving unedited palette slots and native overrides. Cache keys account for source bytes, extraction settings/schema and renderer policies. Cache clearing never deletes authored/imported Theme definitions or saved profile choices. No compatibility layer, theme daemon, custom IPC or speculative plugin framework is introduced.

This model replaces the thirteen-role-only source schema, copied palette/wallpaper objects and scattered color output paths. One atomically replaced INI recipe commits full palette snapshots, optional named definition identities and exact-output wallpaper choices. Configured renderers compile the whole native generation under XDG cache; cache deletion cannot erase committed colors. Installation bootstrap points to that generation, and the complete bundle is prepared before a compositor/shell starts. See [[xdg-runtime-and-theme-schema]] and [[shared-style-and-toolkit-integration]].

The palette editor is keyboard-first. Source is its first control and contains saved Theme definitions, Wallpaper and Custom only. A saved definition reads only its chosen colors into the current wallpaper draft; it never restores another wallpaper profile. Wallpaper derives colors from the picked image. Custom copies the preview into editable colors and alone reveals a Theme name plus Dark/Light metadata. Custom Save and apply writes its reusable definition and commits the wallpaper/color association. The name identifies configuration; numeric list position must not define it.

Catalog discovery uses only directory/file metadata: IDs, labels and direct recipe/definition paths. No Theme, palette or wallpaper content is parsed or verified while listing. Selected loading and final commit perform validation; scoped error popups preserve the valid draft. Dropdown rows are virtualized and inactive while closed. No watcher, persistent index, daemon or custom IPC is introduced.

Wallpaper choice, Theme choice and optional color edits form one draft. Enter/Choose theme advances from image choice to the editor without desktop changes. Only final Save and apply persists/activates the association. Back preserves the draft; closing the whole picker discards it. The explicit destination target remains internal to the editor; Shared default is output scope, not another state. Exact-output palettes/selections remain explicit. Native ungrouped window borders consume explicit output palettes through workspace-monitor rules; output identities are never guessed, and other compositor color scopes remain separate.

Every editor control, color role and action fits the supported nested viewport without scrolling, stretched rows or empty footer gaps. Sharp geometry, consistent color-only focus/hover/selection feedback, fixed font weight, contextual information/help and scoped error copy/dismiss remain shared contracts. Ctrl+Enter acts only on the enabled primary action of the focused topmost popup.

Shape, typography, density, motion, shell behavior and hardware policy remain independent native QML/Lua configuration. User choices are durable configuration; image-derived palettes are XDG cache. Cache/state defaults use ui-shell explicitly. Runtime consumers use manifest command roles and paths, never checkout-derived addresses. There is no pre-release compatibility or runtime migration layer.

Saves validate first, reject stale active/base edits and preserve valid configuration on validation failure. Native failure after durable selection is reported as partial. Color-only refresh never claims other persisted wallpapers were applied; only successful native bundle activation restores all current selections. Configured identities and RGB channels are named, with numeric indexes reserved for iteration/framework events/bounds checks.

## Restore and cache requirements

Saving a Theme must retain the exact named palette definition for the shared default and each explicit output, independently of owned committed colors. Restart restores that source label from durable identity; do not infer it from colors or catalog order. Custom saves create named definitions. A missing named definition is an explicit error, not a switch to Wallpaper or Custom.

Dropdown catalogs have an explicit QML maximum height, constrained further by the runtime viewport, and retain virtualized native keyboard navigation. File Themes start and open from committed palettes without generating unused image colors. Choosing Wallpaper requests its palette on demand. Content-addressed XDG palette caches are shared across selections/restarts for the same image bytes, mode and extractor schema; a per-key lock prevents duplicate concurrent extraction. Cache removal or invalidation permits regeneration, not a different configuration state.

Reference-theme regeneration is explicit: convert all local references to the current complete schema and replace matching reference IDs only. There is no preserve-old-schema branch; unrelated custom Themes and saved recipes remain untouched. Import does not prepare profile/native cache outputs.

Native Quickshell bootstrap exposes a configured module-link location inside its own config root. Preparation atomically links that location to the immutable compiled cache module and imports it relatively, preserving cache ownership of generated colors. Direct file URLs trigger scanner warnings and relative imports escaping the root are blackholed by Quickshell; do not work around that with copied generated config files or fallback palettes.

## Native output-scoped border boundary

The Hyprland adapter consumes the compiled output-palette index through the runtime bundle pointer. Each explicit output gets focused/unfocused workspace-monitor rules; a display without a palette override uses the global border defaults. Group and locked-group decoration and groupbars retain their global policy. Rules follow workspace ownership, not a separate per-monitor compositor-theme object. No daemon, IPC protocol, watcher, focus callback, guessed output order or version-detection branch is added.

The current native target is the installed Hyprland 0.56.2, not an assumption that latest-git wiki semantics match every installed build. That version stores active and inactive border slots separately. The focused rule uses the native gradient projection. The unfocused rule uses a native solid-color pair, assigning the configured inactive color to both slots so it renders when unfocused. Its paired-gradient parser omits inactive OKLab color initialization; therefore output-specific inactive gradients, fractional active angles and gradients exceeding ten stops are explicitly rejected during profile compilation. Supported stops, angles and alpha and all authored Theme source metadata remain preserved; never silently flatten an unsupported source. This is one targeted native API path, not a backwards-compatibility layer. Supporting a newer native border API is an explicit adapter change and must be verified against the actual installed compositor.

The old latest-wiki single-gradient-plus-focus assumption was insufficient on 0.56.2: active colors rendered but inactive windows used the global default. Live rendered-pixel checks now verify two outputs, shared defaults, active gradients with alpha, solid inactive colors, focus changes, window and workspace moves, and reload. The disposable test does not write host configuration or saved test choices and tears down all run-tagged processes.


## Timeline

- time: 2026-10-07T19:20:31
  kind: decision
  summary: "Created this page: Theme profiles bundle wallpapers and palette policy"
  source: "User approved palette editor and wallpaper/theme bundles, 2026-10-07"
  affects: [theme-profile-bundles]

- time: 2026-10-07T19:20:31
  kind: decision
  summary: "Bundle wallpaper selections and palette policy, with a focused preview-first palette editor"
  source: "User: create simple editor and bundle wallpaper/theme, 2026-10-07"
  affects: [theme-profile-bundles]

- time: 2026-10-07T19:46:14
  kind: decision
  summary: "Configuration choices and RGB channels use stable named identities; no magic position indexes except explicit bounds checks or iteration"
  source: "User: do not hardcode indexes like 0 except bounds checks, 2026-10-07"
  affects: [theme-profile-bundles]

- time: 2026-10-07T19:54:20
  kind: decision
  summary: Make stable named identities part of the editor configuration contract
  source: brain update-truth
  affects: [theme-profile-bundles]

- time: 2026-10-07T20:24:09
  kind: decision
  summary: "Palette refresh alone must preserve last confirmed current wallpapers; only successful native bundle activation restores current selections wholesale."
  source: "Save failure can leave current and persisted choices different; explicit native action semantics"
  affects: [theme-profile-bundles]

- time: 2026-10-07T20:30:06
  kind: decision
  summary: Make native-confirmed wallpaper state independent of color-only refresh explicit in the bundle contract.
  source: "Scoped persistence can fail after a successful native wallpaper change, 2026-10-07"
  affects: [theme-profile-bundles]

- time: 2026-10-07T20:53:25
  kind: decision
  summary: "Adopt one wallpaper/color draft with final Save and apply; clarify profile identity versus scope and remove fake state controls."
  source: "User approved deferred wallpaper and colors until final step, 2026-10-07"
  affects: [theme-profile-bundles]

- time: 2026-10-07T20:53:25
  kind: reversal
  summary: "Enter no longer immediately applies/saves the wallpaper; it advances the bundle draft to choosing colors."
  source: "User explicitly selected deferred final commit, 2026-10-07"
  affects: [theme-profile-bundles]

- time: 2026-10-08T00:46:25
  kind: decision
  summary: "Use Theme terminology and one source-first editor with saved themes, Wallpaper and Custom; only Custom asks for a name; remove inline output label and editor scrolling."
  source: "User corrected theme editor model, 2026-10-08"
  affects: [theme-profile-bundles]

- time: 2026-10-08T00:46:25
  kind: reversal
  summary: "Replace the separate Base profile / Colors model with a source-first Theme editor: saved themes, Wallpaper or Custom only, conditional custom name, no inline output label or scrolling."
  source: "User corrected terminology and source hierarchy, 2026-10-08"
  affects: [theme-profile-bundles]

- time: 2026-10-08T01:07:38
  kind: decision
  summary: "Keep the editor content-sized within explicit bounds: no stretched rows or empty footer space while every role/action fits."
  source: "User requests no gaps and complete visible content, 2026-10-08"
  affects: [theme-profile-bundles]

- time: 2026-10-08T01:37:59
  kind: decision
  summary: "Port reference palettes as inactive saved Themes, preserving existing bundles and the active theme."
  source: "User requests 100-themes import and test-env-persistent, 2026-10-08"
  affects: [theme-profile-bundles]

- time: 2026-10-08T02:04:21
  kind: decision
  summary: "Define profile as a Theme storage record and defer catalog validation to selected load/apply; user requires fast metadata-only listing."
  source: brain update-truth
  affects: [theme-profile-bundles]

- time: 2026-10-08T02:10:00
  kind: decision
  summary: "Separate reusable custom config.ini Theme definitions from committed wallpaper/palette profiles; import must not publish profiles."
  source: brain update-truth
  affects: [theme-profile-bundles]

- time: 2026-10-08T02:10:01
  kind: reversal
  summary: "Withdraw eager saved-profile publication for every imported palette; user requires one custom Theme config.ini each and profiles only on final save/apply."
  source: "User corrects 100-themes import boundary and generated-storage model, 2026-10-08"
  affects: [theme-profile-bundles]

- time: 2026-10-08T02:18:23
  kind: decision
  summary: "Flatten reusable Theme config.ini definitions under paths.themes; move generated profiles to separate storage and load palettes on selection only."
  source: brain update-truth
  affects: [theme-profile-bundles]

- time: 2026-10-08T08:36:37
  kind: decision
  summary: "Retain exact Theme identity across restart; bound catalogs and defer unused image colors with locked cache reuse."
  source: "User dropdown, restart selection, and extraction-cache requirements (2026-10-08)"
  affects: [theme-profile-bundles]

- time: 2026-10-09T04:59:21
  kind: decision
  summary: "Approve full named palettes, native gradients and complete compiled profile bundles; begin staged implementation"
  source: "User: now note that, and lets start impl it (2026-10-09)"
  affects: [theme-profile-bundles]

- time: 2026-10-09T04:59:21
  kind: reversal
  summary: Replace lossy thirteen-role-only Theme definitions and copied-object-only profiles with lossless Theme sources and reproducible multi-subsystem profile bundles.
  affects: [theme-profile-bundles]

- time: 2026-10-10T02:43:43
  kind: decision
  summary: "Commit one self-contained INI profile recipe atomically; keep saved full colors and wallpaper choices durable, and compile native subsystem outputs together in XDG cache. This preserves committed colors after cache deletion without copied-object or version directories."
  source: "Approved composition model implementation, 2026-10-10"
  affects: [theme-profile-bundles]

- time: 2026-10-10T03:10:50
  kind: decision
  summary: "Reference-theme import regenerates matching source IDs in the current full-color schema; no preserve-old-format branch or profile compilation. Unrelated custom themes and committed recipes remain untouched."
  source: "User requests updated regeneration script and explicitly rejects backward compatibility, 2026-10-10"
  affects: [theme-profile-bundles]

- time: 2026-10-10T03:19:02
  kind: decision
  summary: "Specify self-contained durable recipes, cached native generations and current-schema-only reference regeneration"
  source: "Approved implementation and user regeneration/no-backward-compatibility requirements, 2026-10-10"
  affects: [theme-profile-bundles]

- time: 2026-10-10T03:21:25
  kind: decision
  summary: "Native Quickshell bootstrap uses an explicit configured in-root module link to the immutable cache generation; this avoids file-URL scanner warnings and root-escaping import blackholes without copying generated colors into config."
  source: "Verified current Quickshell scanner/interceptor source and live nested startup, 2026-10-10"
  affects: [theme-profile-bundles]

- time: 2026-10-10T03:30:26
  kind: decision
  summary: Include the verified in-root native module bridge in the compiled bundle contract
  source: "Quickshell scanner/interceptor source and successful isolated theme-editor/wallpaper runs, 2026-10-10"
  affects: [theme-profile-bundles]

- time: 2026-10-10T04:50:19
  kind: evidence
  summary: "Global Hyprland border defaults do not prove monitor-scoped borders are unsupported: native window rules expose border_color and focus matching, and workspace selectors expose m[monitor]. Their composition is a configuration-only candidate, not yet live multi-monitor verified; it must not be described as a whole-compositor per-output theme API."
  source: "Current official Hyprland window-rule and selector docs, refreshed local wiki c3f93fd, 2026-10-10: https://wiki.hypr.land/configuring/core/rules/window-rules/ and https://wiki.hypr.land/configuring/selectors/"
  affects: [theme-profile-bundles]

- time: 2026-10-10T05:24:47
  kind: decision
  summary: "Implement config-only monitor-scoped active/inactive window borders from explicit per-output profile palettes. Shared global border defaults remain for outputs without overrides. Reuse generated native gradients and output identities; keep groupbars, toolkit themes and lock-screen colors outside this change. Validate focus, output/workspace movement and reload without touching the host session."
  source: "User approved native-rule border integration and requested the cloned wiki, 2026-10-10"
  affects: [theme-profile-bundles]

- time: 2026-10-10T05:51:15
  kind: decision
  summary: "Specify verified native output-scoped borders, preserve global group policy, and make the installed 0.56.2 parser limits explicit without version shims or silent palette changes"
  source: "User approved border integration; refreshed cloned wiki; matching 0.56.2 rule parser and live two-output pixel verification, 2026-10-10"
  affects: [theme-profile-bundles]

- time: 2026-10-27T03:30:58
  kind: decision
  summary: Record the generated default seed and absent-only runtime store seeding
  source: "Default seed redesign, 2026-10-27"
  affects: [theme-profile-bundles]

- time: 2026-10-27T03:30:58
  kind: decision
  summary: Record the generated default seed and absent-only runtime store seeding
  source: "Implemented default seed and staging migration, 2026-10-27"
  affects: [theme-profile-bundles, shipped-default-seed]

- time: 2026-10-30T14:36:42
  kind: evidence
  summary: "Enforce configured store boundaries across script callers: active Profile recipes resolve from paths.profiles; named Theme config.ini identities stay in paths.themes; active resolution and selection reject missing Theme definitions. The save pipeline can compile a new Theme draft before publishing its definition."
  source: "Script audit and isolated Theme/Profile checks, 2026-10-30"
  affects: [theme-profile-bundles]

- time: 2026-11-05T02:02:39
  kind: evidence
  summary: "Audit 2026-11-05 on Hyprland 0.57.1: test-scripts, test-theme-config (500 reference themes, default seed), test-pipelines, dev-lint + test-qml and the nested rendered-pixel test-borders all pass, so the per-output border implementation written for 0.56.2 still works unchanged on 0.57. The 0.56.2-specific restrictions (inactive gradients, fractional angles, >10 stops rejected) are not yet re-evaluated and may be lifted. Findings: scrim, warning and surfaceVariant roles are generated and editable but unused by the shell (overlays use background + opacity); PaletteColorPicker seeds from global Theme.Palette.accent; the shipped default's positive/warning/green slots are not hue-faithful."
  source: "profile audit, 2026-11-05"
  affects: [theme-profile-bundles]

- time: 2026-11-05T02:25:46
  kind: decision
  summary: "Theme editor failure contract: a Source that fails to load keeps the combo highlighted on that candidate (failedCandidateId) so keyboard navigation moves on instead of snapping back; the draft colours, name and source label stay the last valid ones; Save is disabled until a source loads (sourceUnavailable). The failure popup now names the theme definition that failed (Theme definition: <path>), not just the output. Root cause of the reported error: the persistent nested state kept a schema-1 single-section themes/default/config.ini because stage-defaults never rewrites and test-env-clean deliberately preserves every definition; it was backed up and re-seeded from default/theme.ini through stage-defaults, and all 501 saved definitions now pass normalize-custom-colors."
  source: "keyboard arrow error report, 2026-11-05"
  affects: [theme-profile-bundles, isolated-nested-test-environment]
