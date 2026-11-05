---
id: shared-style-and-toolkit-integration
title: Shared style system across QML Qt and GTK
category: decision
status: active
tags: [style, theme, qt, gtk, qml, composition]
created: "2026-09-30T20:10:22"
updated: "2026-11-05T06:33:13"
---

<!-- compiled_truth -->
# Decision

Quickshell behavior and style configuration remain explicit QML composition, never JSON or external JavaScript configuration. A separately versioned INI installation manifest owns runtime command/path roles, wallpaper folder lists and explicit profile selection. INI custom palettes feed native generated QML/Lua through focused renderers. See [[xdg-runtime-and-theme-schema]]. Every user option and policy is visible in static configuration; empty values do not secretly choose modes, and invalid choices do not silently recover to another screen or preset.

## Default configuration model

Every configurable concern has an explicit user-set default and optional overrides. Absence of an override resolves to that configured default; a missing required default or invalid value is an error. Defaults are configuration values, never additional runtime states or recovery modes. This applies project-wide, including wallpaper, colors, monitor values, shell behavior, and style. CONFIGURATION.md is the implementation-facing contract.

## Independent native layers

- Shell config owns behavior; Shape, Density, Typography, Motion, and Interaction each own one style responsibility.
- GeneratedPalette and GeneratedPalettes seed semantic startup colors. ActivePalettes owns native live global/default/output values; hand-written Palette, Style, and MonitorStyle compose them for controls; components receive their owning output's style explicitly.
- hypr/theme/generated.lua contains semantic palette values and compositor-native constants. Appearance and optional Phantomat consumers use named values rather than inline colors.

## Focused generation boundary

Image extraction, cache work, QML rendering, and Hyprland Lua rendering are separate focused tasks. JSON is a private normalized intermediate for Matugen and offline palette-source adapters; Quickshell neither imports nor watches it as configuration. GTK and Qt receive separate concrete adapters when introduced. No custom daemon, IPC protocol, or product shell CLI.

## Active design and input contract

- Exact 90-degree corners and zero rounding apply to every project-owned surface, indicator, and control border. Color themes and monitor overrides cannot change that contract.
- Keyboard is primary. Actions, cancellation, focus, candidate selection, persisted choice, current application, and startup snapshot are explicit. Pointer actions follow the same model.
- Selection, current, pressed, and focus retain distinct output-aligned hard colors on restrained neutral surfaces. Candidate selection uses theme accent/primary; current uses positive/tertiary mixed toward outline at 0.20. Ordinary controls use an explicit outline emphasis with a uniform full-perimeter border; one primary action may use solid emphasis. Thick side strips and asymmetric state borders are rejected. Dropdown option rows are an explicit exception to outlined controls: only their popup frame has a border. Rows mark pointer hover with a readable hover foreground, keyboard candidates with a distinct accent foreground, and the committed choice with a compact marker; no row outline is painted for hover, selection, focus or press. One primary candidate owns the selection accent; moving the candidate clears stale tile focus. Selection and focus never add a second border, widen the perimeter, or change control geometry: one fixed-width border communicates states by color. Selected and current values remain visible during keyboard navigation, with In use as the tile's only native-status marker. The persisted choice is internal and chooses the opening candidate; Save and apply normally makes it equal current. Partial activation is reported explicitly without inventing a confirmed native state. Saved status alone never creates a current border. Separate saved/current badges and decorative Selected/Current sample buttons are omitted. No full-view state-color flooding.
- Border precedence is disabled, pressed, selection, focus, current, hover, normal. Selection dominates focus so keyboard and pointer candidates share the same accent; otherwise focus uses its distinct palette role. The semantic booleans remain independent. Outline hover feedback includes a distinct readable foreground and a restrained neutral-surface tint, including selected and current controls; disabled/pressed behavior overrides it. Border identity remains independent of foreground feedback. Selection and current stay identifiable during hover.
- Native Hyprland hide_on_key_press does not invalidate Qt hover flags. One explicit InputState owned by the shell composition root is required by all surfaces/controls: keyboard activity clears pointer hover, and only genuine movement or a mouse-button event restores it. Initial hover/layout events seed observation without claiming activity. No cursor polling, timeout heuristic, secondary selection model, or device-dependent geometry.
- Opening the picker focuses the persisted choice's grid tile rather than search; Ctrl+F selects search. Enter/Choose theme opens a draft palette stage without applying or persisting. Only final Save and apply commits and activates the bundle; Back retains the draft, while closing the picker discards it. Ctrl+I explains the focused control or semantic color. The output scope stays fixed from the wallpaper stage. Search, thumbnail edges, and necessary target/action controls share exact border-box alignment without reserved space for a second focus outline. The approved minimal-panel contract moves redundant titles, permanent hints, and descriptions into on-demand contextual popups.
- QML owns action keys, picker geometry, preview bounds, border widths, motion enablement, reduced motion, duration, easing, and translation/opacity. Motion is short and interruptible, stopped when hidden. Selection/focus/hover borders use a brief configured color transition, never repeating flashes, scaling, padding changes or doubled outlines. Reduced motion is immediate; presses and disabled states remain immediate.
- Local references inform shared tokens, stable border geometry, and independent focus/candidate/current states. Their framework scope and shapes do not override these requirements.

## Output and test policy

Monitor names belong only in static user policy or generated overrides. Runtime screens determine surfaces and picker targets. Wallpaper uses the required registry default plus optional monitor overrides; Shared default is an editable output scope in the picker, distinct from the profile named default. GeneratedPalettes contains required defaultPalette plus byOutput overrides; there is no unassigned-palette policy. Hyprland palette_source explicitly chooses default-wallpaper or output-wallpaper. Monitor configuration uses settings.default plus overrides composed over it. The shipped monitor policy has `overrides = {}` and optional output names are empty; machine-specific values are generated or merged explicitly. See [[shipped-default-seed]]. The picker has strict screen-index/output-name hosting modes; invalid or unavailable explicitly selected screens fail visibly.

Super+W uses the native Hyprland shortcut protocol, not a custom endpoint. Nested Aquamarine windows use the explicit floating centered 1280-by-720 rule; outer runtime rules remain temporary unless saved in that host's config. All nested tests use [[isolated-nested-test-environment]].

Each project shell surface has one motion owner: QML. Native Hyprland layer rules disable compositor animations specifically for the bar, wallpaper-picker and app-launcher namespaces, without disabling other applications' animation. Closing is short, responds immediately and cannot be restarted by repeated cancellation. The picker lazily creates its panel once per used output and explicitly retains it across closes; hidden content stops animation and opening restores saved-candidate focus. Translation/opacity preserve fixed text and border geometry rather than scaling them.

## Minimal-panel refinement

[[contextual-shell-popups]] supersedes the earlier permanently labelled header/footer presentation. Ctrl+I provides candidate/focused-target information; Ctrl+Space provides component-local usage/keybindings; Ctrl+E provides only component-scoped, script-backed settings with explicit defaults and optional per-monitor generated overrides. Escape/outside-click dismiss the topmost popup before the parent and restore focus. Redundant visual labels and large Close buttons must be removed while accessibility semantics and exact target scope remain clear. Runtime errors now belong in their own component-scoped popup with concise explanation, selectable diagnostics and a deliberate Copy action; inline error presentation is pending migration. Dismissal preserves interrupted task state and settings drafts. See [[contextual-shell-popups]] for this approved, not-yet-implemented error model. These changes are implemented and behavior-tested in the isolated session, not a general desktop settings application. See [[contextual-shell-popups]] for the current implemented and verified checkpoint.

## Current color and alignment contract

Search and application rows share exact left/right border-box edges. The outside focus ring and its reserved offsets are removed. Outlined states use the same explicit border width; dropdown rows remain borderless in every state; state changes animate only color using Motion.stateDuration (80 ms) and stateEasing (OutCubic). Selection keeps accent for both pointer and keyboard; focus otherwise uses its distinct semantic color. Reduced motion, presses and disabled states remain immediate. Pixel and geometry regressions passed. The installed-runtime and palette-source model is defined by [[xdg-runtime-and-theme-schema]]; source-tree layout must not leak into runtime consumer addresses. Other features remain outside that migration.

## Provider-independent semantic control colors

ControlColors derives reusable foreground, surface and boundary roles once per owning output style. ControlState resolves input/selection flags from those roles; it does not choose a theme source. Interaction.qml explicitly owns contrast floors (4.5:1 for text, 3:1 for meaningful boundaries), mix ratios, and opaque black/white tonal endpoints. If a source role misses the configured contrast floor, the nearest passing tone toward an explicit endpoint is derived without introducing a fallback theme or runtime recovery state. Hover foreground, keyboard candidate foreground and committed-choice indication must remain distinguishable on the actual surface. Outline text roles meet their floor across normal, hover and pressed neutral surfaces so immediate foreground updates remain readable during surface transitions.

The normalized semantic schema and native QML/Lua renderers are the boundary shared by wallpaper and explicit file providers. Custom palette files declare every role and mode; refs/100-themes variants convert offline into that same format. Its selection field is a background tone, not selected text. Positive, warning and negative source fields are mandatory explicit arguments because ANSI color names do not guarantee status semantics. Importing a local palette must not automatically switch the active palette, read TOML at runtime, bundle unlicensed reference assets, or create JSON shell configuration, a daemon or a theme settings application.

## State-invariant item typography

Dropdown options, application labels and wallpaper names always keep the explicit Typography.bodyWeight. Selection, focus, hover, press and committed/current status must not change font weight, size or letter spacing. State belongs in readable colors and compact markers, not bolding or text-metric shifts. Static contextual headings may retain their independently configured emphasis weight.

Dropdowns retain native ComboBox activation and delegate/highlight state, with an explicit ListView that omits Qt Basic's inherited inner and high-contrast row contours. The popup reserves its single border width as padding; option rows never paint another perimeter. Isolated unit and live nested checks verified actual mouse-to-keyboard handoff, unchanged item weight, frame geometry, settings isolation and wallpaper application. Popup capture waits for native opening; asynchronous thumbnail readiness is independent from popup readiness.

The manifest selects a named profile; its file provider chooses a required default palette and optional exact-output QML palettes, while wallpaper providers retain per-image Matugen colors. Profile activation restores wallpaper selections and palette policy together; draft/import/profile loading alone activates nothing. Geometry, typography, density and motion remain independent. The focused Ctrl+T editor reuses sharp native controls, fixed border geometry, preview-only drafts, named scope/mode/RGB identities and scoped errors. Source watching is explicitly disabled by default to prevent generated projections restarting in-flight UI. Hyprland colors remain global; output palette overrides affect QML styles only. See [[theme-profile-bundles]].


## Timeline

- time: 2026-09-30T20:10:22
  kind: decision
  summary: "Created this page: Shared style system across QML Qt and GTK"
  source: STYLE.md and user requirements
  affects: [shared-style-and-toolkit-integration]

- time: 2026-09-30T20:10:30
  kind: decision
  summary: "Recorded the shared style contract, shape presets, composable override layers, and Qt/GTK boundaries."
  source: STYLE.md and user requirements
  affects: [shared-style-and-toolkit-integration]

- time: 2026-09-30T21:42:43
  kind: decision
  summary: Established the file-backed runtime palette boundary and Matugen v4 normalization.
  source: "STYLE.md, installed Matugen 4.2.0, nested Quickshell runtime test"
  affects: [shared-style-and-toolkit-integration]

- time: 2026-09-30T21:57:23
  kind: decision
  summary: Replaced JSON-backed Quickshell configuration with explicit QML configuration and focused renderers.
  source: "User correction: QML is config; JSON is not Quickshell configuration."
  affects: [shared-style-and-toolkit-integration]

- time: 2026-09-30T21:57:23
  kind: reversal
  summary: "Reversed the JSON-watched palette approach: QML now owns all Quickshell configuration."
  source: User correction
  affects: [shared-style-and-toolkit-integration]

- time: 2026-09-30T22:53:58
  kind: decision
  summary: Added the focused generated Lua palette adapter for Hyprland and Phantomat.
  source: "User requirement: generated.lua holds explicit constants instead of inline values."
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-02T04:22:28
  kind: decision
  summary: "Established sharp geometry, primary keyboard control, explicit motion and reference-based control composition."
  source: User design requirements and local reference inspection
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-02T04:51:50
  kind: decision
  summary: "Made shared control states and runtime monitor discovery explicit, with static user-owned output policy."
  source: User requirements for aligned states and scalable monitor configuration
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-02T05:29:08
  kind: decision
  summary: Require visible static policy and solid distinct active-state fills with independent focus
  source: "User: no hidden defaults/fallback options; active state has a hard color distinct from hover"
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-02T05:34:52
  kind: reversal
  summary: "Refined active emphasis: solid distinct colors remain, but borders and compact markers may replace whole-control fills according to explicit component policy"
  source: "User: do not let state colors take the whole view; highlighting borders is sometimes enough"
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-02T05:46:30
  kind: decision
  summary: Use explicit restrained outline/marker/solid emphasis rather than flooding active areas
  source: User UI/UX refinement and latest-reference requirement
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-02T06:15:33
  kind: reversal
  summary: "Use uniform full-perimeter state borders instead of thick left-side strips; keyboard and pointer share selection geometry, with hover visually subordinate and focus independent."
  source: "User correction: borders must be consistent on every side and keyboard selection must be at least as polished as pointer hover."
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-02T06:17:27
  kind: decision
  summary: "Unify keyboard/pointer candidate borders and remove asymmetric state strips; make hover subordinate without hiding persistent assignment state."
  source: User design correction and inspection of refreshed Omarchy controls
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-02T06:37:07
  kind: decision
  summary: Status labels distinguish saved and confirmed current wallpaper
  source: Explicit live Apply requirement
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-02T06:45:34
  kind: decision
  summary: Current border uses tertiary theme hue instead of selection accent
  source: "User: active must not equal selected; use existing theme options"
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-02T06:59:00
  kind: decision
  summary: Single Enter commit and saved-tile initial focus with aligned picker layout
  source: User requirements for complete selection action and keyboard-first opening
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-02T07:06:14
  kind: decision
  summary: "Exactly one candidate focus ring; saved/current tile hover is independent of border identity"
  source: User found duplicate selection outlines and missing hover on saved/current wallpaper
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-02T07:20:02
  kind: decision
  summary: Explicit shared input activity prevents hidden-cursor ghost hover
  source: "User reported hidden cursor retaining hover; native hide-on-keypress config and Qt hover behavior"
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-03T03:05:21
  kind: decision
  summary: "Show only Current on wallpaper tiles; keep the persisted startup preference internal because Set wallpaper applies and saves together."
  source: "User questioned duplicate Saved and Current indicators; picker commit flow confirms their intended relation."
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-03T03:18:52
  kind: decision
  summary: "Adopt user-set defaults and optional overrides throughout configuration; remove recovery/missing-assignment modes."
  source: "User: everything needing fallback must instead have a default; CONFIGURATION.md and migrated Lua/QML/scripts."
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-04T04:28:00
  kind: decision
  summary: "QML exclusively owns shell layer motion; sharp geometry and input stay immediate."
  source: "User requests smooth closing, one animation owner, and explicit graceful nested shutdown."
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-04T04:28:00
  kind: reversal
  summary: "Replace panel scaling and stacked compositor fades with QML-owned translation/opacity; retain lazily loaded picker panels."
  source: "User: disable duplicate Hyprland layer animation and give one side full control."
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-05T02:06:29
  kind: decision
  summary: Move redundant panel labels and permanent hints into contextual popups
  source: User minimal UI and documentation requirements
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-05T02:06:30
  kind: reversal
  summary: "Replace permanent title/help/description/Close presentation with minimal panels and on-demand context, help and scoped settings"
  source: User explicitly rejected repetitive labels and big Close buttons
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-05T03:04:38
  kind: decision
  summary: "Replace double focus outlines with fixed-width single borders and brief state-color transitions; remove focus-space alignment offsets."
  source: "User correction: search/selection rectangle axes must align and selected state must change color instead of widening or doubling borders."
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-05T03:04:38
  kind: reversal
  summary: "Supersede the independent outside focus-ring presentation: one invariant border conveys selection/focus by distinct colors, preserving alignment across all input states."
  source: User explicitly rejected widening/doubled selected borders in favor of color animation.
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-05T03:13:33
  kind: decision
  summary: "Record single-border motion tokens, tested aligned geometry and stopped checkpoint; remove stale pending-implementation status."
  source: User border/color-animation correction and request to note everything and stop.
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-05T07:44:13
  kind: decision
  summary: "Resume scoped semantic colors: foreground-led borderless dropdown options and an explicit offline palette-provider boundary."
  source: "User color/contrast and dropdown foreground corrections, 2026-10-05"
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-05T07:44:13
  kind: reversal
  summary: "Dropdown option rows no longer paint state outlines; hover and keyboard candidates use distinct readable foreground colors while the popup alone owns its border."
  source: "User: row outlines mix with the dropdown frame; hover should mark the option."
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-05T07:56:21
  kind: decision
  summary: "Keep item typography invariant: remove selection/current-driven font weight changes from dropdowns, applications and wallpapers."
  source: User explicitly rejected selection font bolding.
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-05T08:19:33
  kind: decision
  summary: "Verify foreground-led dropdowns with one explicit popup frame, native input and invariant item typography; retain the offline palette boundary."
  source: "User contrast/hover and no-bolding requirements; native Qt Basic source and isolated QML/GUI regressions."
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-05T08:25:01
  kind: decision
  summary: "Record popup-only runtime error presentation as the new minimal-layout contract; implementation remains pending."
  source: User error UX model change and STYLE.md.
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-06T17:45:54
  kind: decision
  summary: "Separate QML behavior from INI deployment and file-palette data, preserving semantic control design."
  source: User runtime scheme and explicit wallpaper folder list
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-07T20:20:26
  kind: decision
  summary: Compose native live profile palettes with the unchanged sharp style axes
  source: "User approved palette editor and rejected positional choice identities, 2026-10-07"
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-08T00:00:30
  kind: decision
  summary: Replace immediate wallpaper commit with the approved wallpaper/color draft flow and explicit labels
  source: "User-approved final Save and apply workflow, 2026-10-07"
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-08T00:00:30
  kind: reversal
  summary: "Enter advances the draft rather than applying; saved profiles load as draft bases, and final Save and apply is the only UI commit."
  source: "User explicitly chose deferred wallpaper and colors until final save, 2026-10-07"
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-27T03:30:58
  kind: decision
  summary: Keep shipped monitor/output defaults empty and machine values explicit
  source: "Default seed redesign, 2026-10-27"
  affects: [shared-style-and-toolkit-integration]

- time: 2026-10-27T03:30:58
  kind: decision
  summary: Keep shipped monitor/output defaults empty and machine values explicit
  source: "Implemented default seed and staging migration, 2026-10-27"
  affects: [shared-style-and-toolkit-integration, shipped-default-seed]

- time: 2026-11-05T02:10:59
  kind: decision
  summary: "All thirteen shell roles are now exposed on Style and MonitorStyle (added surfaceVariant, warning, scrim). Modal and panel overlays (wallpaper picker, app launcher, ContextPopup) dim with the scrim role at their configured opacity instead of the background colour, so the editor's Scrim role has a visible effect. PaletteColorPicker seeds from its owning style, so no QML outside theme/ reads the global palette. warning and surfaceVariant have no QML consumer yet."
  source: "profile audit follow-up, 2026-11-05"
  affects: [shared-style-and-toolkit-integration, theme-profile-bundles]

- time: 2026-11-05T02:25:46
  kind: decision
  summary: "Qt's default controls are themed through one adapter: theme/ControlPalette.qml maps a style's ControlColors onto Qt palette roles and is declared inside ContextPopup and ShellTextField. Qt 6.12's built-in Cut/Copy/Paste menu is a popup that does not inherit its editor's palette (verified: it stayed white), so every text editor owns a themed menu, components/ShellEditingMenu.qml, built on Qt's TextEditingContextMenu and assigned via ContextMenu.menu. Tests assert the real menu object's palette (ShellTextField, ErrorPopup) and the role mapping across all imported palettes (ControlColors). New text controls must use ShellEditingMenu."
  source: "context menu theming, 2026-11-05"
  affects: [shared-style-and-toolkit-integration]

- time: 2026-11-05T02:50:39
  kind: reversal
  summary: "Control state colour is no longer border-only. State is fill + foreground + border, derived Material-3 style at runtime from the 13 palette roles (state layers 8/10/14%, hue-tinted primaryText, tonal container for selection, positive container for current, disabled 38%/12%). Contrast fixes shift OKLCH lightness at constant hue/chroma instead of mixing toward black/white (which produced grey). style.textMuted resolves through verified muted role. Qt palette gets a disabled group. No palette schema change. Rejected: adding container roles to the schema (would bump the palette key and diverge generated vs imported themes)."
  source: "colour system rework 2026-11-05; STYLE.md, shell/theme/README.md, tests/tst_ControlColors.qml, tests/tst_StateGallery.qml"
  affects: [shell/theme, STYLE.md]

- time: 2026-11-05T02:59:45
  kind: decision
  summary: "Channel rule: fill+foreground carry all interaction states; border is only the keyboard-focus ring (Interaction.borderStates, default [focus], overridable per ControlState). Body text aims 7:1, falls back to 4.5:1; muted at 4.5. Amounts overridable per style via controlTuning (unknown keys error)."
  source: "tests/tst_ControlState.qml, tst_ControlColors.qml"
  affects: [shared-style-and-toolkit-integration]

- time: 2026-11-05T03:13:05
  kind: decision
  summary: "Focus ring is focus-visible only (keyboard active; text inputs always); new flat emphasis (no resting border) for bar entries and menu/list rows; muted text aims 5.5:1; control wiring unified in ShellControlState."
  source: "user feedback: mouse click drew borders"
  affects: [shared-style-and-toolkit-integration]

- time: 2026-11-05T03:18:29
  kind: decision
  summary: "Focus ring requires an active window (bar buttons keep focus items while launcher owns keyboard); outline border blends text colour (outlineTextMix 0.45) so borders share the labels' tonal family."
  source: user feedback
  affects: [shared-style-and-toolkit-integration]

- time: 2026-11-05T03:24:37
  kind: decision
  summary: "Tonal containers built by OKLab tone step (containerShift/containerChroma/currentShift) instead of sRGB accent wash, which looked muddy; solid focus ring is primaryText (label colour), not white text colour."
  source: "user feedback: white Save border, muddy dropdown layer"
  affects: [shared-style-and-toolkit-integration]

- time: 2026-11-05T03:38:32
  kind: decision
  summary: "Control colour model isolated and generated: scripts/render-control-tuning owns schema+defaults and renders theme/GeneratedControlTuning.qml (committed seed, drift-tested); Theme.ControlTuning merges defaults, saved user file (components/controls/Default.qml via save-component-settings, now N-valued) and the live draft of the schema-driven tuning popup (Ctrl+Shift+T). Ranges bounded so legal values keep text readable."
  source: "user request: generated knobs + tuning popup"
  affects: [shared-style-and-toolkit-integration]

- time: 2026-11-05T05:44:16
  kind: decision
  summary: "Control modes: named presets over the tuning knobs (tonal default, wash = Omarchy-style neutral washes + accent text, ink, hush, neon), declared in render-control-tuning, chosen in the tuning popup mode row; saved as mode name + overrides vs preset. New knob currentChroma. tonal() keeps the surface tint when little hue is wanted. Modes tested for readability on 20 palettes."
  source: "refs/omarchy shell.toml.tpl + 100-themes palettes.mjs survey"
  affects: [shared-style-and-toolkit-integration]

- time: 2026-11-05T05:53:03
  kind: decision
  summary: "Modes are behaviour profiles: each mode = numeric knob preset + per-state/per-channel colour-role table (outline/solid families) + flags (hover pointer|none, focusVisible, focusRing, restingBorder, currentMarker, animate). ControlState interprets ControlTuning.behavior (active/draft mode) and hard-codes no state; generator validates roles and flags. Interaction.borderStates removed. Added cursor mode (hover ignored, outlined selection)."
  source: "user: modes must change behaviour, not only colours"
  affects: [shared-style-and-toolkit-integration]

- time: 2026-11-05T06:00:01
  kind: decision
  summary: "Control model is data: scripts/control-model/{knobs,behavior,modes}.json (vocabulary, flags, precedence, emphasis registry, per-family state specs); render-control-tuning only validates/resolves/renders. ControlState has no hard-coded states/emphasis/precedence. New mode+emphasis proven JSON-only by pipeline test; vocabulary vs ControlColors.roles enforced by test."
  source: self-audit of modularity
  affects: [shared-style-and-toolkit-integration]

- time: 2026-11-05T06:11:02
  kind: decision
  summary: "Per-surface control mode: ControlColors.mode (Style/MonitorStyle.controlMode, Config.barControlMode) selects its own behaviour profile + preset under per-style tuning. Rejected hover:cursor flag: popups already single-highlight, cursor mode ignores hover."
  source: "user: more, creative but lean"
  affects: [shared-style-and-toolkit-integration]

- time: 2026-11-05T06:33:13
  kind: decision
  summary: "Tuning is its own module like launcher and picker: modules/tuning (TuningState, TuningShortcut, TuningSurface with click-through mask, TuningPanel docked bottom), Config.Tuning, Config.controlTuningEnabled, Hyprland bind SUPER+T, layer namespace ui-shell-control-tuning, mutual exclusion with launcher/picker. Removed from PickerPanel and ControlTuningPopup."
  source: "user: build like lego, own picker"
  affects: [shared-style-and-toolkit-integration]
