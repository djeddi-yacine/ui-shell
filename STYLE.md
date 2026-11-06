# Style

This document defines the visual language shared by the Quickshell UI, Qt applications, and GTK applications.
It is a design contract, not a feature list.

## Active design

The active design uses rectangular surfaces with exact 90-degree corners. Every radius slot is explicitly zero: windows, bars, panels, menus, inputs, buttons, badges, indicators, and focus outlines. Palette changes cannot alter geometry. Qt and GTK adapters must preserve this geometry for controls the project styles.

The opt-in Phantomat canvas follows the same contract. `hypr/user/canvas.lua` owns camera motion, dimensions, and zero HUD/minimap rounding. Selected, hovered and search-matched window outlines honor each window's native rounding, including rules; outline gaps and widths cannot create rounding when that value is zero. `hypr/phantomat.lua` maps the prepared native palette: accent → accent, surface → panel, elevated → card, outline → edge, text → primary text, and text_muted → secondary/tertiary text. It reads the existing generated output palette index and replaces the plugin's full output-color map on reload. Each rendered monitor resolves its own HUD, minimap, grid, labels and overlay colors; unassigned outputs use the configured global default. No output names, second extraction or separate generated hierarchy are introduced. Texture caches and hit testing are output-scoped. Quickshell owns its own surface animations; native chrome animation, distortion, blur and decorative parallax remain disabled in this preset.

Canvas dim overlays use panel, grid marks use secondary text, and hover/search-match outlines use primary text. Icon wells, badges and tuner controls derive from those roles or computed accent contrast, not fixed white/dark paint. Palette changes invalidate both HUD and grid textures, including changes with an unchanged accent.

Keyboard is the primary input device. Every action must have a keyboard path, visible focus, and an explicit cancellation path. Pointer input follows the same action and selection model. Focus, candidate selection, the persistently saved value, the current wallpaper, and the startup snapshot are separate states.

Item typography is invariant across interaction states: normal, hover, selected, focused, pressed and committed choices all keep the configured body weight. No selection-driven bolding, font-size change or letter-spacing shift is allowed. Colors and compact markers communicate state; static headings may use their own typography role.

## Minimal panels and contextual popups

The app runner and wallpaper picker must show the task, not explain their identity repeatedly. Remove redundant titles such as “Applications” and “Wallpapers”, permanent keybind/usage hints, inline app descriptions, and large Close buttons. Primary views retain item names, search, necessary target/action controls and committed-state markers. Errors belong in their own scoped popup, never inserted into the current layout. Accessible names and control semantics stay intact when visual labels are removed. The wallpaper's selected Shared default/display scope must remain identifiable without opening help.

Secondary information is requested through the same shortcuts in each component:

| Shortcut | Popup scope |
|---|---|
| Ctrl+I | Information about the selected candidate or meaningful focused target/control; for example, the selected app's description. |
| Ctrl+Space | Usage and configured keybindings for the active component only. |
| Ctrl+E | Settings for the active component and explicitly identified configuration scope; never a general desktop settings app. |

The owning component resolves the context; mouse hover must not silently replace the keyboard candidate. Popups are on demand, not permanent panels. Escape or an outside click dismisses the topmost popup before its parent. Dismissal restores prior focus and preserves selection; it never launches, applies, or saves anything. Opening help/settings must not leak Return, arrows, or text input to the underlying picker/runner.

`config/Keyboard.qml` declares `popupActionKeys` (Return and keypad Enter) and `popupActionModifiers` (Control). Ctrl+Return or Ctrl+keypad Enter invokes only the explicit primary `Button` of the topmost focused popup, regardless of the focused field. A disabled or busy primary action does nothing; the key is consumed within that popup and never reaches its parent. The actions are Save and apply in the theme editor, Save in component settings, Use color in the RGB chooser, and Dismiss in an error popup. Error Copy remains Ctrl+Shift+C. Information and help popups have no commit action.

Search edges, list/grid edges, essential target/action controls, and popup content use consistent left/right axes and spacing tokens. Outlined controls have one fixed-width perimeter; focus never adds an outside ring, grows the border, or changes dimensions or padding. Foreground feedback is independent of border identity. Dropdown option rows have no border in any state: their popup owns the perimeter. A brief configured color transition may ease outlined states. Keep exact 90-degree corners and the owning output's semantic colors.

The Theme editor uses its visible content's natural height plus normal popup padding, bounded by the explicit maximum and runtime viewport. Conditional Custom controls change that height without stretching rows or adding empty footer space. Invisible shortcut holders must not participate in layout. All color roles and the primary action fit the default test viewport without scrolling.

The three contextual popups are implemented: Ctrl+I information, Ctrl+Space component help, and Ctrl+E component settings. See [CONFIGURATION.md](CONFIGURATION.md) for settings scope and persistence.

## Pickers and popups: surface rules

A **picker** is a full panel (wallpaper, apps, audio, control tuning). A **popup** opens over a
picker (context help/info/settings, errors, the colour picker, combo menus). Both read their
colours from `Theme.Style`/`MonitorStyle`, never from raw `surface`/`elevated`:

| | surface | border | radius |
|---|---|---|---|
| Picker | `pickerSurface` (base surface) | `pickerBorder` (control outline) | `pickerRadius` |
| Popup | `popupSurface` (elevated, one step up) | `popupBorder` (outline made readable on it) | `popupRadius` |

Rules: every picker has the same background; a popup is always lighter than the picker
beneath it, so it never blends in; rows and cards inside a picker use `background` (one
step down) with an outlined border; a new picker or popup uses these tokens or it is a bug.

## Leaving a panel: the exit rule

Esc always leaves. A panel that is only a view closes on one Esc. A panel with unsaved
work (control tuning, the theme editor and its colour picker, the Ctrl+E settings popup) asks first with `Controls.ExitDialog`, where Esc
means "dismiss and quit": leaving takes two Esc presses, and one stray key loses nothing.
"Keep editing" is the default button and a click outside also keeps the work. Wire a panel
with `exit.request(hasUnsavedChanges, focusItem)` and `onConfirmed`; while it is dirty the
panel must not close itself on Esc or an outside click.

## Component-scoped error popup

Runtime operation, validation, loading and settings-conflict errors use the shared `ErrorPopup.qml`. Backend failure signals trigger one popup for each new failure observation. Dismissing a popup does not reopen it for the same failure; a subsequent failure signal presents the new failure. No inline error banner, added error row or error-driven resizing belongs in the runner or picker. A scoped settings error appears above the editor without replacing it. The backend/module still owns error state and intentional retry; the popup presents the specific failure without silently substituting another option.

The popup shows an action-specific operation, clear message, exact target/scope and diagnostic details. The detail block is read-only plain text, selectable and scrollable inside a bounded popup. Copy includes the title, message and complete detail block, even beyond the visible scroll area. Use the owning output's colors, restrained negative-role emphasis, readable contrast, sharp corners and shared spacing; do not flood the view with red.

Provide an explicit, keyboard-accessible **Copy** button that copies the complete presented diagnostic. Copy is deliberate; it never automatically replaces the clipboard. Native Qt text-control copying supplies this action; no clipboard command, daemon or custom IPC is used. Copy must not retry, dismiss, apply or save anything.

The popup is the topmost input scope. Escape, outside-click or dismissal closes only that popup and restores focus to the interrupted control/editor. Preserve the current selection, task scope and unsaved settings draft. Repeated bindings or observations of the same failure do not reopen or stack popups. Retry, when appropriate, remains a separate intentional operation owned by the component.

`config/ErrorPanels.qml` statically configures popup width, diagnostic height, padding, keys and initial focus. The explicit defaults are Dismiss focus, Escape dismissal and Ctrl+Shift+C full Copy. Shared spacing/scrim comes from `ContextPanels.qml`; entry/exit motion comes from `theme/Motion.qml`. Fatal bootstrap/parse failures that prevent any surface from existing remain explicit startup/log errors; the popup is not a recovery mode.

Keyboard focus stays on Dismiss and Copy: Tab and Shift+Tab cycle between those two actions. The popup uses explicit `KeyNavigation.BeforeItem` links; buttons also clear pointer-only feedback when acquiring native Tab/Backtab focus. Panel links use `KeyNavigation.AfterItem` so their `Keys.BeforeItem` input tracking runs before navigation. The read-only diagnostics accept pointer or explicit focus for selection and native Ctrl+C/Ctrl+Shift+C copying; Tab then leaves the diagnostics. The details `ScrollView` and scrollbar do not take focus. Initial focus may be Dismiss or Copy, never the diagnostics.

## Principles

- Prefer a small, coherent visual system over decorative variety.
- Components consume semantic tokens; they do not invent raw colors, spacing, or corner radii.
- Themes change values, not component structure.
- Shapes, density, typography, motion, and color are independent axes that can be composed.
- Toolkit-specific differences belong in `qt/` and `gtk/`, not in the shared style vocabulary.
- QML singleton files are the shell's configuration. Generated QML palette files are not hand-edited.

## Style dimensions

- theme — semantic color roles and optional wallpaper-derived colors
- shape — corner treatment and component radius mapping
- density — spacing, control heights, and information density
- typography — UI, monospace, icon, size, weight, and line-height tokens
- motion — duration, easing, transition, and reduced-motion policy
- elevation — surface layering, borders, scrims, and shadows

## Theme tokens

Themes provide semantic roles rather than component-specific colors:

- background — desktop and shell background
- surface — primary shell surface
- surface-variant — secondary or recessed surface
- elevated — menus, popovers, and raised surfaces
- text — primary readable text
- text-muted — secondary and disabled text
- accent — active and selected state
- positive — success state
- warning — warning state
- negative — error and destructive state
- outline — borders and separators
- focus — keyboard focus indication
- scrim — modal and overlay dimming

A reusable Theme defines colors only: complete named palette slots, explicit shell roles and native subsystem color settings. A schema-2 profile recipe stores full palette snapshots, wallpaper choices, optional named Theme identity and scoped overrides in one durable `profiles/<id>/profile.ini`; the UI keeps the simple Theme editor workflow without exposing profile-storage controls. QML owns behavior and the independent style axes. Applying the selected recipe restores wallpaper selections and colors together, without changing geometry, motion or interaction policy. Importing a palette alone never activates it. Saved recipes retain exact Theme identities for the default and each explicit output, so restarting restores the source label from saved identity, not list position or guessed color matches. File Themes open from their owned colors; image-derived palettes are requested only when needed and reused from the content-addressed XDG cache. Native consumers load generated QML/Lua from the complete prepared cache generation; JSON remains an intermediate and is not user configuration.

The Ctrl+T Theme editor keeps the same sharp fixed-width borders and shared axes. Semantic role labels, hex values and named RGB channels make colors identifiable without relying on swatches alone. Drafts color only the preview; the real controls retain the active output's readable theme. Choose theme advances the wallpaper draft without applying it. The picker captures its target internally and the editor retains it without showing a monitor name or scope label. One Source dropdown offers installed saved Themes, Wallpaper, and Custom. Saved Theme and Wallpaper choices load draft values; only Custom shows a Theme name and permits color edits. Save and apply is the single bundle commit action. Back or dismissing the editor preserves the draft and restores picker focus; closing the picker discards it. Ctrl+I explains each focused control/color and Ctrl+Space discloses keys; errors retain the last valid draft above the editor with deliberate Copy. Ctrl+Enter continues to invoke the topmost panel's explicit primary action. Named identities determine dropdown choices and initial channel focus, not magic list positions.

The editor has no ScrollView or scrollbar; every role and primary action fits the normal 1280×720 test viewport. Dimensions remain bounded by the runtime viewport and explicit `config/ThemeEditor.qml` size/margin options. Imported 100-themes colors can be converted and installed as saved Themes through the existing independent scripts; they are not another editor source.

Every interactive component distinguishes normal, hover, pressed, focused, selected, current, and disabled states. State is carried by **fill, foreground and border together**, never by the border alone, and each state is a Material-3-style derivation from the palette rather than a hand-picked colour. `theme/Interaction.qml` assigns `outline` emphasis (a neutral surface whose selection becomes a tonal container) to ordinary controls, selector rows, wallpaper tiles, list rows and bar entries; primary actions (Save, Choose theme, Apply) use `solid`. Unknown modes are errors. Selection uses the same full-perimeter geometry for keyboard and pointer input, never a thicker strip on one side. A dropdown row omits the border rather than nesting outlines inside its popup, and communicates state through its fill instead.

`theme/ControlColors.qml` derives every control role once per owning style/output from the thirteen palette roles; `ControlState.qml` resolves interaction flags from those roles. The system is derived at runtime from the existing roles, so wallpaper-generated, imported and custom themes get identical behaviour and the palette schema does not grow:

| Role | Derivation |
| --- | --- |
| state layers | `text` washed over the surface: hover 8%, focus 10%, pressed 14% |
| `primary` / `primaryText` | accent made readable (3:1) on the surface; content is near-black or near-white carrying the accent's hue, verified 4.5:1 on the rest, hover, focus and pressed fills |
| primary states | the primary moves **away from its content colour** (darker under light text, lighter under dark text), so contrast only grows as feedback deepens |
| `container` / `containerText` | the surface stepped 0.10 in OKLab lightness away from rest and tinted with 40% of the accent's chroma (a clean tone, not an sRGB wash, which turns muddy on dark surfaces); text is `text` mixed 55% toward accent, verified 4.5:1 on container, hover and pressed |
| `currentContainer` / `currentText` | the same tonal step in the positive hue, for the committed item |
| `muted` | `textMuted` verified 4.5:1 on every surface text can sit on; `style.textMuted` resolves to it |
| disabled | content = 38% text, container and border = 12% text; deliberately below `muted`, never confused with enabled |

Contrast fixes shift OKLCH lightness and keep hue and chroma (reducing chroma only to stay in gamut), so a corrected colour stays in its family instead of fading to grey. Text is held to 4.5:1 and boundaries to 3:1; when no tone can reach a floor on an arbitrary mid-tone palette the most readable extreme is used and nothing throws. Disabled content is exempt from contrast by design. See [the palette API](shell/theme/README.md).

**Channel rule.** Fill and foreground carry every interaction state; the border carries one thing, keyboard focus. Hover, pressed, selected and current never draw or recolour a perimeter, so pressing Space on a combo box or button only deepens its fill. The focus ring is drawn whenever a control has keyboard focus, whatever else it is (a selected, focused row keeps its container fill and adds the ring, which is also what keeps a keyboard cursor visible at 3:1). Focus is shown only while the keyboard is the active input (Material's focus-visible): clicking a control focuses it without drawing a ring, and the next Tab or arrow key reveals it. Text inputs always show focus. Emphasis `flat` (bar entries, menu and list rows) has no resting border at all; `outline` shows a quiet `outline` border at rest. This is a declared policy, not scattered code: `Interaction.borderStates` (default `["focus"]`) lists the states that also paint a border, and `ControlState.borderStates` overrides it per control.

Every foreground is computed against the exact fills it can sit on, not a generic surface. Body text aims for 7:1 (`Interaction.preferredTextContrast`) and settles for the 4.5:1 floor only when the hue cannot reach it; muted text sits at 4.5:1, so hierarchy survives in every theme.

State precedence is disabled → pressed → selected → focused → current → hover → normal. Outline controls: hover washes the neutral surface; focus uses the focus layer; selected is the tonal container with `containerText`; current is the positive container and marker; pressed deepens the container. Solid controls: normal is the primary fill; hover, focus, selected and pressed apply deeper primary layers. Disabled controls suppress hover/press feedback. Geometry never changes.

**Tuning model.** The model is isolated and generated. `scripts/render-control-tuning` owns every knob (key, group, label, range, step, default) and renders `shell/theme/GeneratedControlTuning.qml` (committed seed; a test fails if it drifts from the script). `Theme.ControlTuning` layers three sources: the generated defaults, the user's saved file (`components/controls/Default.qml`, written through the same locked, revision-checked path as other component settings) and the tuning panel's unsaved draft, so every control recolours while a slider moves. **Super+T** toggles the tuning panel, its own module (`shell/modules/tuning/`: surface, state, shortcut and panel, like the launcher and the picker; the card docks at the bottom edge and a mask lets the shell above stay visible and usable while you preview). Mode buttons, Reset mode and Save sit in it; Esc discards. Ranges are bounded so every legal combination keeps text readable. Per-style overrides remain available through `Style.controlTuning` / `MonitorStyle.controlTuning`; unknown keys are errors. **Modes are behaviour profiles, not palettes.** A mode in `scripts/render-control-tuning` is two things: numeric knob presets, and a *behaviour profile*. The profile says, for every state (normal, hover, focus, select, current, pressed, disabled) of each family (`outline`, `solid`), which colour role is painted into each channel (fill, foreground, border), plus flags: `hover` (`pointer` or `none`, a keyboard-first mode can ignore the mouse entirely), `focusVisible` (`keyboard` or `always`), `focusRing`, `restingBorder` (`outline` or `none`), `currentMarker` and `animate`. `ControlState` interprets the active profile and hard-codes nothing, so a mode can make selection a fill, an outline, or text only, with or without a hover state, border or marker. The generator validates every role name and flag, so a typo fails at generation time. Modes: **Tonal** (soft accent wash, the default), **Wash** (Omarchy-style: neutral washes keeping the surface tint, accent only in text, no selection border), **Ink** (high legibility: 10:1 text, borders on hover, selection and pressed, focus always shown), **Hush** (no resting border, no marker, instant), **Cursor** (keyboard-first: hover ignored, the selected row outlined instead of filled, instant) and **Neon** (full-chroma fills with accent borders on hover, selection and pressed). The panel's mode row previews a mode live (numbers and behaviour), sliders fine-tune the numbers ("modified" is shown), and Save stores the mode name plus only the knobs that differ from its preset. Tests cover every role of every mode and readable text in every mode on all imported palettes. **Per-surface mode.** `Style.controlMode` / `MonitorStyle.controlMode` give one surface its own mode (behaviour and numeric preset), under `controlTuning` and over the global mode; `Config.barControlMode` sets it for the bar (empty follows the global mode), as Omarchy gives each surface its own tokens. To add a knob, a mode, a state role or an emphasis, edit the data in `scripts/control-model/` (`knobs.json`, `behavior.json`, `modes.json`; the script only validates, resolves and renders it, and a test proves a new mode and emphasis need JSON alone). Emphasis, state precedence and the role vocabulary are data too; the only code that must change is `ControlColors.roles` when a genuinely new colour role is introduced (a test enforces that the vocabulary and the provided roles match). To add a knob, add one entry to the data, regenerate the seed and use it in `ControlColors`: the popup picks it up from the schema.

Dropdown rows use these explicit meanings, without painting any row outline:

| Meaning | Presentation |
| --- | --- |
| Normal option | Readable `text` foreground on a neutral surface |
| Pointer hover | Neutral hover layer and `hoverText`, including the committed option |
| Keyboard candidate | Tonal container fill with `containerText`, unchanged body weight |
| Committed choice | `currentContainer` fill, `currentText` and a reserved 4 px marker; the marker remains while hovered or navigated, with unchanged body weight |

Pointer activity suppresses the keyboard-candidate presentation; genuine keyboard input restores it and clears stale hover. Native ComboBox activation alone commits a choice. Tiles retain one compact “In use” marker for the last confirmed native wallpaper. Persisted startup preference is not another badge; it supplies the opening candidate. The candidate stays a draft until final Save and apply. Selected filenames use the semantic foreground, so hover is not masked by a hardcoded accent. The tonal container is a restrained wash, not accent flooding; only primary actions are filled with the full accent.

## Shapes

`Shape.qml` declares the active `sharp90deg` geometry. Its named slots `surfaceRadius`, `controlRadius`, `inputRadius`, `menuRadius`, `badgeRadius`, and `indicatorRadius` are individually set to `0`. Every outlined state, including focus, uses the same 1-logical-pixel border on all four sides. Dropdown rows keep zero border width in every state and reserve the same marker slot for every option. Tiles and ordinary controls share `ShellControlBackground`; there are no left-edge state strips. No outer focus outline or reserved focus offset changes alignment.

Components consume these named slots. Color themes cannot select rounded geometry. Component and monitor overrides must preserve the active sharp contract. Border widths are invariant across states: outlined controls use `borderWidth`, dropdown rows use zero. Focus changes color, never offsets or geometry.

## Composition and overrides

Style composition has explicit inputs: a user-set default, optional output overrides, independent shape/density/typography/motion singletons, and the owning style passed into each component. `MonitorStyle` combines an output's palette with those shared axes. Components receive their emphasis mode explicitly. Future overrides must name the properties they own. See [CONFIGURATION.md](CONFIGURATION.md) for the project-wide default-and-override contract.

Every configurable concern has a user-set default. An absent output override uses `ActivePalettes.defaultPalette`, seeded from generated startup colors; there is no additional missing-assignment mode or runtime state. Invalid settings and missing required defaults are errors. The exact picker screen choice and compositor/global palette source remain independent explicit settings.

The shell's configuration is explicit QML: `Config.qml` chooses shell behavior; `Shape.qml`, `Density.qml`, `Typography.qml`, and `Motion.qml` choose independent style axes; `GeneratedPalette.qml` supplies semantic colors. A private JSON file may exist only between focused generation scripts; Quickshell never reads or watches it as configuration.

## Typography and density

- Use named typography roles such as `ui`, `ui-emphasis`, `caption`, `mono`, and `icon`.
- Keep font family, size, weight, and line height tokenized.
- Use a spacing scale instead of arbitrary margins.
- Density presets may change spacing and control sizes without changing component structure.
- Text should remain readable before visual effects are applied.

`Typography.qml` uses system Sans Serif and Monospace, a 12 pt base and a 1.2 scale: body 12 pt, caption 10 pt, title 17.28 pt. `Density.qml` declares 12 px spacing, 36 px controls, 12 px horizontal/6 px vertical control padding, and a 32 px bar. Fonts are not downloaded.

The picker contract aligns search, previews, and essential output/action controls on common axes, with explanations moved to contextual popups. The grid compensates for cell gaps so its outer tile edges align with other controls. `shell/config/WallpaperPicker.qml` declares density, responsive thresholds and bounded previews; scoped settings can override the column and visible-row limits. Thumbnail filenames and the optional In use marker remain meaningful item/state information, not repeated panel headings. Filtering must not continually resize the panel.

## Motion and surfaces

- Motion is short, purposeful, and interruptible.
- No animation should be required for basic usability.
- Reduced-motion mode disables or shortens nonessential transitions.
- Prefer clean surfaces, restrained borders, and a small elevation scale over constant shadows or blur.
- Focus and disabled states must remain visible in every theme and shape preset.

`Motion.qml` declares enabled and reduced-motion switches, panel entry/exit motion, and the state-color transition policy. The state transition uses `stateDuration` and `stateEasing` (80 ms, `OutCubic`); reduced motion makes it immediate. State changes affect only fill, foreground and border color and never dimensions or padding. Panel entry translates 8 px to rest with opacity 0.92 → 1; exit translates 4 px and fades out. There is no scale animation: text, border widths and layout geometry remain unchanged. Repeated cancellation does not restart exit. Hidden surfaces stop their animations and reset visual properties.

There is one animation owner per shell surface. `hypr/rules.lua` disables compositor motion (`no_anim = true`) specifically for the `ui-shell-bar`, `ui-shell-wallpaper-picker`, and `ui-shell-app-launcher` layer namespaces; QML alone owns their entry/exit. Other applications retain their compositor animations. `WallpaperPicker.qml` explicitly chooses asynchronous first loading and retention after close. A surface creates its panel only on first use, then retains that panel's controls and bounded previews until the output/shell is destroyed. Reopening resets search and focuses the saved candidate without rebuilding the tree. This trades a small bounded retained UI for avoiding repeated construction and cancelled thumbnail loads.

Use solid semantic surfaces and restrained borders. Keep blur, shadows, bounce, elastic motion, rotating decorations, and animated layout geometry disabled. Images decode asynchronously at explicitly bounded sizes.

## Keyboard contract

The application launcher shares the same sharp geometry, per-output palette and `PanelMotion` controller. Its layer namespace is `ui-shell-app-launcher`, also excluded from compositor animations. `shell/config/AppLauncher.qml` declares geometry, row density, keys and `showIcons`; disabling icons removes their space and image requests. Search and rows share an alignment axis. One fixed perimeter border changes color for candidate, hover, pressed, and focus states. Opening focuses search; arrows move the candidate, Enter hands the selected desktop ID to app2unit, and Escape closes. Query changes never resize the panel. Loading/retention are explicit options, and hidden panels stop motion.

Launch progress has no footer or extra row. Each app row reserves the same trailing `AppLauncher.launchIndicatorSize` slot, so its label and the panel/search/list retain identical bounds while idle, starting, successful or failed. Only the exact launched desktop-entry identity shows a filled circular dot; this progress glyph is not rounded control geometry. It uses the owning output's readable control foreground and pulses opacity only, through `Motion.launchPulseDuration`, `launchPulseEasing` and explicit minimum/maximum opacity. Reduced motion or disabled motion leaves a steady dot. Hidden, pooled and off-viewport indicators stop animating. Native accessible launch status remains available without visible status text; failures use the existing scoped error popup.

`shell/config/Keyboard.qml` owns action keys; `WallpaperPicker.qml` owns picker geometry and preview limits. Configured keys are Escape to cancel, Return or keypad Enter to advance the wallpaper draft to Choose theme, arrows to move the candidate, Tab/Shift+Tab to traverse controls, and Ctrl+F to focus search. Ctrl+I opens contextual information, Ctrl+Space opens component help, and Ctrl+E opens scoped settings. Opening clears the filter, selects the persisted startup choice and focuses the grid, not search. A saved image absent from the catalog produces an explicit message instead of choosing another image. Text fields retain ordinary text-editing keys; Down leaves search for the grid and chooses the first tile only when there is no candidate. Arrows move the grid's candidate; Tab does not choose another tile. Enter opens the palette editor and may create the draft image's cached colors, but never changes the selected profile, saved wallpaper or native wallpaper. The editor previews the pending image and colors. Save and apply publishes a revision-checked bundle and then activates it through the native APIs, closing the picker on success. Preflight failure leaves the desktop unchanged; failure after durable selection reports partial activation explicitly. Tiles display only In use; the persisted value remains internal and supplies the opening candidate. Focus uses the same fixed perimeter border as other control states.

Each content view owns exactly one keyboard focus stop: launcher Tab cycles Search → Applications → Search; picker Tab cycles Search → Target → Wallpapers → Choose theme → Search, and Shift+Tab reverses those paths. The native QML navigation links are explicit in the owning components. Delegates are not independent Tab stops and never choose themselves on focus restoration. Candidate identity remains stored when the view loses focus, but its accent border/foreground clears until that view regains focus; hover and the current-wallpaper marker remain independent. Opening a popup clears the underlying candidate's focus emphasis. Arrows return focus to the owning list/grid; typing returns the launcher to search. Tab/Backtab are navigation, never query text. Returning to a view restores the same candidate without stale per-item focus or reselection. None of these transitions changes border thickness, font weight, padding, or layout axes.

Focused shared buttons, including Save, Copy and Dismiss, use `Keyboard.buttonActivationKeys` (Return and keypad Enter) and `buttonActivationModifiers` (NoModifier). Keypad identity is not a shortcut modifier. Pressing shows the existing pressed color; the matching non-repeated release commits exactly once through the native button action. Holding Enter never commits on press or repeats the action. Losing focus, disabling or hiding the button cancels the armed action. Both activation events stay within the button, never invoking a parent launcher/picker action. Native Space and pointer activation remain unchanged; Tab, Escape and contextual shortcuts retain their own handlers.

The project Hyprland binding `Super+W` opens the picker through Quickshell's native Hyprland global-shortcut protocol. The named binding lives in `hypr/profile.lua` and `hypr/binds/shell.lua`; the matching QML shortcut identity lives in `WallpaperPicker.qml`. These paired shortcut identities must be edited together.

Input activity is explicit UI state, not a second selection model. `shell.qml` owns one `components/InputState.qml`, initially in keyboard mode, and passes it to every surface and control. Keypress handlers clear pointer hover before native control handling; `PointerTracker.qml` restores it only for changed scene coordinates or pressed mouse buttons. Initial hover-entry/layout events merely seed the previous position. This matters because Hyprland's explicit `hide_on_key_press = true` does not send Qt a pointer-leave event. A stationary hidden cursor cannot retain hover tint. Selection colors, candidate identity and border geometry do not vary by input device. No cursor polling or expiry timer is used.

## User output policy

Hardware names belong in user-owned static configuration or saved selection data. `hypr/user/monitors.lua` holds the required `default` monitor values and optional hardware overrides composed over them. Its explicit `palette_source.kind` chooses `default-wallpaper` or `output-wallpaper`; output mode requires a named saved wallpaper override. `shell/config/Outputs.qml` explicitly selects the picker entrypoint with `pickerTargetMode`: `screen-index` uses the exact zero-based `pickerScreenIndex`, and `output-name` uses the exact `pickerOutputName`. An invalid mode or unavailable target is an error.

The shell creates surfaces and picker targets from `Quickshell.screens`, reacting to connected outputs. A display without an override uses the configured default wallpaper and default palette; it needs no extra state or hard-coded component. The picker’s Shared default target edits this baseline; a named display target writes that display’s override. Ctrl+I explains the picker target instead of a permanent instructional footer. The editor retains that captured target internally without an inline monitor-name or scope label. Applying Shared default updates displays that inherit it and preserves explicit overrides. Saved wallpaper and palette maps contain output names as data. Per-output widgets receive their resolved palette through `MonitorStyle`, including their control-state colors. Tiles show the startup assignment or a subsequently confirmed native application as “In use”. The persisted choice supplies the opening candidate; after successful Save and apply it normally equals the current value, so it is not duplicated as a second tile marker. External changes made outside this shell are not watched. Active shell/Hyprland palettes are regenerated at session startup.

Usage guides belong in the component's Ctrl+Space popup, not its permanent layout. The popup describes the actual configured actions; key changes must not leave stale help. Future features must declare their keyboard actions before adding pointer affordances.

Native Hyprland window borders use the compiled output palette index, with focused/unfocused workspace-monitor rules per explicit output. Each rule applies only to ungrouped windows so group and locked-group colors retain their global policy. Outputs without overrides use the global border defaults. Output identities come from the profile, never component code. The current target is the installed Hyprland 0.56.2: a native gradient fills its active slot; a solid-color pair fills both slots for the unfocused rule. Active gradients retain their stops, alpha and supported integer angles. This build's paired-gradient parser does not initialize its inactive gradient color data, so output-specific inactive gradients, fractional active angles and more than ten stops are rejected before publication instead of silently changing colors. Solid inactive colors retain alpha. This border adapter does not imply per-output toolkit, groupbar or lock-screen colors. There is no version-detection branch, focus callback, watcher or compatibility layer.

## Local reference patterns

Omarchy's `shell/Ui/Button.qml` separates pressed, focus, keyboard cursor, hover, and selected states, and reserves border space to avoid focus-driven layout jumps. Its image picker centralizes keyboard handling and explicitly focuses the selection surface. We adopt the state distinction and stable geometry in small QML controls.

Caelestia's `components/controls/StyledTextField.qml` consumes shared typography, padding, and animation tokens. We keep this token composition with rectangular backgrounds and ordinary labels. The reference's floating-label shapes and curved outlines do not define this project's geometry.

## Toolkit integration

- `shell/` consumes the shared style vocabulary through QML singleton tokens.
- `qt/` maps the shared tokens to Qt palette, widget, and application-theme integration.
- `gtk/` maps the shared tokens to GTK settings, CSS, and application-theme integration.
- Qt and GTK adapters may approximate a shared token when their toolkits expose different capabilities.
- Qt and GTK adapters must not introduce a second independent theme vocabulary.
- Each subsystem gets its own focused renderer script when its real adapter is introduced; every renderer writes its output atomically from one extracted semantic palette.

## Folder responsibilities

- `hypr/` — Hyprland Lua configuration and policy
- `shell/` — Quickshell QML composition and visual components
- `scripts/` — Bash generation and system-side effects
- `qt/` — Qt theme integration and generated toolkit assets
- `gtk/` — GTK theme integration and generated toolkit assets

## Adding a shell module

Every module (launcher, wallpaper picker, control tuning, audio) has the same parts: a state singleton, a shortcut, a surface (a layer-shell window, exclusive keyboard, namespace `ui-shell-<name>`, listed in `hypr/rules.lua`) and a panel. The panel follows the shared contract:

- **Keys, information and options live in the context popup, not on screen.** Ctrl+Space lists the keys (the panel's `bindings`), Ctrl+I shows information, Ctrl+E opens the component's settings. Use `PanelContext`; a panel without component settings passes `settings: null`. No permanent key hints, usage text or repeated identity titles.
- **Options are data.** A component's two Ctrl+E options are one entry in `shell/config/ComponentSpec.qml` plus a `scripts/render-<component>-settings` renderer (registered as an optional command in the manifest). The editor, the settings adapter and the file reader all read the spec.
- **Load the panel asynchronously** (`Config.<Module>.asynchronousPanelLoad`, true): popups created in the same frame as the window's first layout distort it.
- **One shortcut per module, checked against the existing binds** (`hypr/binds/*.lua`), since `test-hypr-config` does not detect duplicates. Taken `SUPER` keys include A, D, F, G, L, P, S, V, X, W, Space, Return, Tab; the shell modules use Space (launcher), W (wallpaper), T (tuning) and M (audio).
