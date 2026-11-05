# Shell

Focused Quickshell UI for Hyprland.

This directory contains the visual shell only. It is a long-lived QML process composed from small, typed, reusable parts. It is not a desktop-environment backend.

## Boundaries

- QML is the implementation language for shell UI.
- Standalone JavaScript files are not used.
- `hypr/` owns Hyprland Lua policy, keybinds, and autostart.
- Installed `scripts/` contains runtime helpers for deliberate effects such as wallpaper changes and color generation. `tools/scripts/stage-config` is development-only staging code.
- `tests/scripts/` contains test runners, checks, and test-only helpers; they are not installed runtime helpers.
- `qt/` and `gtk/` own toolkit-specific theme output.
- [`STYLE.md`](../STYLE.md) owns shared visual tokens, shapes, density, typography, and motion.
- [`FEATURES.md`](../FEATURES.md) owns the approved feature inventory.
- No custom daemon, IPC protocol, or shell CLI.

## Installed runtime

The runtime package is `$XDG_CONFIG_HOME/ui-shell/{scripts,quickshell,themes,profiles,default,config.ini,hypr}` (defaulting to `$HOME/.config/ui-shell`). Source folders remain `scripts/`, `shell/`, `hypr/`, and the single `default/` seed; staging maps them into that package layout and creates the runtime stores. Schema-2 `config.ini` is a strict installation/path and palette-source manifest, not shell behavior configuration. Its relative paths resolve beside the manifest, and only leading literal `${HOME}` and `${XDG_*_HOME}` tokens are recognized without evaluation. Consumers receive resolved absolute paths and use configured command roles. `[wallpaper_folders]` lists every wallpaper folder with a stable ID; the checked-in manifest uses relative `default` and `wallpapers` entries as explicit choices, not built-in locations. No directory is inferred by the UI.

`[bootstrap]` in `config.ini` declares three installation paths: the runtime QML, wallpaper catalog, and `profileModule` link point under Quickshell. `prepare-runtime` compiles the selected profile to XDG cache, atomically links the configured `profileModule` path to that generation's `quickshell/` directory, and renders `GeneratedRuntime.qml` to import the linked module using an in-root relative path. Generated profile files stay in cache. Runtime JSON/Lua data is written at `${XDG_CACHE_HOME}/ui-shell/runtime/config.{json,lua}`; Bash receives the JSON path through `UI_SHELL_RUNTIME`, while Quickshell uses generated QML and never reads that JSON. Runtime preparation must happen before Quickshell loads its declared runtime module. Consumers resolve bundle projections through the generated runtime and configured command roles; they do not construct generated filenames or cache paths. `make dev-stage` and `make dev-configure` work in the private `.build/home/.config/ui-shell` staging tree, not the host installation.

## Contextual UI

The runner and wallpaper picker must remove redundant component titles, permanent key guides, inline app descriptions, and large Close buttons. Primary views retain only search, candidates, necessary target/action controls and meaningful state. Errors belong in a separate component-scoped popup, not in this layout. Content and control edges share exact alignment axes without outer focus offsets. Escape and outside-click provide dismissal; a popup closes before its parent and returns focus without changing the candidate.

- Ctrl+I — information about the selected candidate or meaningful focused target/control.
- Ctrl+Space — usage and actual configured keybindings for this component.
- Ctrl+E — this component's scoped settings, backed by focused Bash scripts and QML configuration with optional exact-output files.

These contextual popups are implemented. Settings use the keys, XDG paths, Save-only draft commits, per-file locks, revision compare-and-swap, atomic replacement, and live QML reload described in [CONFIGURATION.md](../CONFIGURATION.md). The shared `ErrorPopup.qml` presents each new backend failure once, with action-specific details and explicit Copy for its read-only plain-text diagnostic. `config/ErrorPanels.qml` sets diagnostic dimensions, keys and initial focus. Dismissal restores interrupted focus and preserves selection and settings drafts; scoped settings errors appear above the editor. There is no watcher, IPC, daemon, or JSON shell configuration. [STYLE.md](../STYLE.md) owns presentation and focus behavior; [FEATURES.md](../FEATURES.md) lists the features.

The reusable popup receives the failed operation, message, target and details from its owning adapter/module. Details are selectable and scrollable; Copy includes the title, message and all details. Tab/Shift+Tab cycle only Dismiss and Copy; pointer or explicit diagnostic focus still allows native text copying, then Tab leaves the details. The scroll view does not take focus, and initial focus is Dismiss or Copy. The default full-Copy key is Ctrl+Shift+C; Escape dismisses only the error. No clipboard utility is used. A dismissed failure stays dismissed until a new failure signal. See [STYLE.md](../STYLE.md#component-scoped-error-popup) for the focus and presentation contract.

## Structure

```text
shell/
├── shell.qml          # Small bootstrap and composition root
├── qmldir             # QML module and singleton declarations
├── config/             # Explicit shell-behavior QML singletons
├── theme/              # Explicit style QML and generated palette QML
├── surfaces/           # Per-monitor layer-shell windows and surface hosts
├── modules/            # Feature-level compositions: bar, notifications, picker, ...
├── components/         # Reusable controls, primitives, and delegates
├── adapters/           # Narrow Quickshell/Hyprland/system bindings
├── assets/             # Icons, images, fonts, and static resources
└── tests/              # Small QML tests for config, state, and components
```

Directories appear when they contain real code. Do not create empty scaffolding for speculative features.

## Responsibilities

### `shell.qml`

Bootstrap only. It imports the shell module, creates the top-level composition, and provides screen/output context. It must not contain feature logic, large item trees, dialogs, delegates, or service implementations.

### `config/`

Owns explicit QML configuration for shell behavior and module composition. It exposes narrow typed properties to consumers. It does not load JSON as shell configuration.

Configuration chooses known modules by stable IDs. It must not load arbitrary source paths or turn the shell into a plugin marketplace.

### `theme/`

Owns the QML side of [`STYLE.md`](../STYLE.md): semantic colors, shape slots, spacing, typography, elevation, and motion. `GeneratedPalette.qml` and `GeneratedPalettes.qml` seed startup colors. `ActivePalettes.qml` holds live global/default/output palettes after explicit profile/wallpaper actions. `Palette.qml`, `Shape.qml`, `Density.qml`, `Typography.qml`, and `Motion.qml` remain independently composed configuration. Components consume tokens; they do not define raw visual values.

Configuration follows [`CONFIGURATION.md`](../CONFIGURATION.md): defaults are explicit user values; optional overrides inherit them. `ActivePalettes.forOutput(name)` resolves an output override or the required default palette. Invalid choices and missing required defaults are errors. For isolated runtime and visual checks, see [`tests/README.md`](../tests/README.md) in the project root.

`ControlColors.qml` derives readable interaction roles once per owning style/output; `ControlState.qml` consumes that typed palette and resolves input flags. `Interaction.qml` exposes contrast floors, mixes and marker policy. Every Theme is one schema-2 colors-only `config.ini` under configured `paths.themes`: shell roles, complete named slots and native Hyprland borders. The shipped default is generated from `default/default.png` into `default/theme.ini` and staged as `themes/default/config.ini` only when that store is absent; authored definitions use `themes/<name>/config.ini`. The offline reference importer converts color definitions only. A profile recipe at `profiles/<id>/profile.ini` contains durable full color snapshots, wallpaper choices, optional named Theme identity, and scoped overrides. Save and apply commits it; opening or canceling creates none. Generated color and native projections come from a complete cached generation selected through the generated runtime bootstrap. See [theme/README.md](theme/README.md) for the format and import command.

Avoid QML property names beginning with `on` followed by a capital letter. Use names such as `textOnSurface` or `surfaceForeground` instead.

### `surfaces/`

Owns layer-shell windows and monitor-aware hosting. Each surface has one responsibility: bar surface, notification surface, picker surface, and so on. Surface geometry, focus, exclusive zones, and screen selection stay at this boundary.

### `modules/`

Owns feature composition. A module may combine components and adapters, but it should not become a general-purpose service container. Optional or expensive modules are loaded only when needed.

The wallpaper module keeps separate responsibilities: `PickerSurface` hosts the window, `PickerPanel` coordinates the wallpaper/color draft, `PickerState` owns the persisted startup preference, last known applied choice, and startup snapshot, `PickerHeader` owns output selection, `WallpaperTile` renders one candidate, and `PickerFooter` advances with Choose theme. Enter and Choose theme open the theme editor without changing wallpaper or palette state. A currently applied image is marked In use; the selected candidate is only a draft.

`modules/themes/ThemeEditorPopup.qml` owns the popup/error/help composition; `ThemeEditor.qml` owns the Theme draft. `components/PaletteColorField.qml` owns one semantic hex/swatch control and `PaletteColorPicker.qml` owns named RGB editing. `adapters/ThemeProfiles.qml` invokes configured helper roles and loads native QML snapshots. `config/ThemeEditor.qml` exposes geometry, semantic roles, keys and named initial choices. The existing `profiles/` storage names remain implementation details; user-facing wallpaper and palette bundles are Themes. No component rebuilds script paths from the project layout.

The editor has no ScrollView or scrollbar and fits the normal 1280×720 default viewport with its primary action visible. Height follows visible content plus normal padding, without stretched rows or unused footer space; the configured maximum and runtime viewport bound it. Monitor dimensions and names are not hardcoded. The picker-captured target remains internal; no monitor name or scope label is shown, and palette selection does not change it. Theme selection reads and validates only the chosen palette; imported definitions use the same catalog. Save and apply remains the sole profile creation/update and activation step; Back preserves the draft. Ctrl+Enter invokes the topmost popup's explicit primary action.

### `components/`

Owns reusable visual pieces. A component exposes explicit `required property` inputs and emits intentional signals. It should not discover unrelated global state or spawn processes.

### `adapters/`

Owns narrow bindings to Quickshell, Hyprland, Wayland, and required system APIs. One adapter owns one external concern. Adapters expose typed read-only state and small actions to modules; they do not become a generic event bus.

## Composition model

The intended flow is:

```text
Config.qml + theme singletons ──→ surfaces/ ──→ modules/ ──→ components/
Matugen cache intermediate ─→ focused renderers ─→ GeneratedPalette.qml / GeneratedPalettes.qml ─┘
                                                adapters/ ───────────────┘
```

The wallpaper picker lists images from every configured `[wallpaper_folders]` directory and opens on the persisted candidate. Folder ID plus filename identifies a choice, including duplicate filenames across folders; Ctrl+I exposes its folder. The saved default wallpaper and each optional monitor override must declare a folder ID. Missing or unknown IDs are errors; no folder is inferred. Its Shared default target edits the configured wallpaper baseline; a named display edits that display's override. Enter or Choose theme advances the candidate and fixed scope into the theme editor without applying anything. Ctrl+F focuses search; browsing does not change the wallpaper. A matching live wallpaper has the In use marker. The final Save and apply action owns bundle persistence, native wallpaper application, and palette refresh. Current state tracks startup assignments and this shell's confirmed applications; external changes are not watched.

`scripts/apply-wallpaper` owns the live update, requires an explicit Hyprland session and fit mode, and rejects disconnected exact targets. Hyprpaper encodes Shared default as an empty output; it updates displays without an override. `select-wallpaper` owns committed wallpaper selection, while palette caching and each renderer remain separate. The final Save and apply action sequences configured roles and refreshes native QML colors for `ActivePalettes`. Theme definitions provide palette colors; wallpaper-derived palettes use the selected image. Palette-dependent image caches live under the `ui-shell` XDG cache namespace. A failure reports which final-commit stages completed.

Ctrl+T opens the same editor from the picker. Theme palette and Wallpaper-derived choices update the draft only; Back preserves it and Escape cancels when the picker closes. Only Save and apply creates or updates and activates the committed wallpaper/palette profile. The target captured by the picker is retained internally through editing without an inline scope label. Selection uses stable IDs/paths and named channel focus, never magic choice indexes. Source watching is explicitly disabled in `config/Config.qml` so generated projections do not restart the shell mid-operation; live data is loaded by revision. See [the Theme workflow](../docs/themes.md).

`Super+W` opens it using the native Hyprland shortcut protocol, with no shell command or custom IPC endpoint. The bar button provides the same action. See `config/Keyboard.qml` for panel keys and `config/WallpaperPicker.qml` for dimensions, output policy, and shortcut identity.

QML alone owns shell-surface motion: `hypr/rules.lua` excludes the bar, picker, and application launcher namespaces from compositor animations. `theme/Motion.qml` declares entry/exit budgets and translation/opacity; selection and focus use the configured brief border-color transition without changing geometry; reduced motion is immediate. `config/WallpaperPicker.qml` explicitly controls asynchronous first loading and panel retention. A hidden retained picker stops animation and reopens on the saved candidate without rebuilding its controls/previews. Repeated Escape does not restart its 80 ms closing transition.

`config/Outputs.qml` is the user-owned static picker-host policy. `pickerTargetMode` must explicitly be `screen-index` (an exact zero-based runtime index) or `output-name` (an exact output name); an invalid mode or unavailable screen is an error. Connected outputs are discovered at runtime; override names are data, not required component names. `hypr/user/monitors.lua` sets `palette_source.kind` to `default-wallpaper` or `output-wallpaper`; output mode requires a matching saved wallpaper override.

`theme/Interaction.qml` explicitly chooses neutral `outline` or filled `solid` emphasis per control role. `ControlState.qml` keeps selection, current, hover, pressed, and focus roles separate. Ordinary controls and tiles retain one invariant perimeter; no asymmetric strip or outside focus ring is painted. Hover changes the semantic foreground on hover-enabled controls, independently of border identity. Selection uses primary/accent; current uses positive/tertiary. Scrollable candidate collections (launcher rows, wallpaper tiles, and dropdown options) are keyboard-owned: pointer movement does not add a second hover candidate or hide the keyboard candidate. Wheel scrolling and direct pointer activation remain available; buttons retain normal hover and click feedback. Dropdown rows have no borders: `ShellComboOption` marks the keyboard candidate with `selectionText` and the committed choice with a compact marker. The native popup alone owns their perimeter and native activation commits the value. Controls require their owning output's style and emphasis policy; no component silently chooses a preset. Typography, control padding, responsive grid thresholds, and bounded previews remain in their respective theme/config files.

Dropdown options, runner labels and wallpaper names keep the configured body weight in every state; selection/current/hover never bold text or change its metrics. Static contextual headings retain their independent typography role.

Use direct typed properties and QML bindings. Avoid hidden global mutation, duplicated watchers, and generic message buses.

`shell.qml` explicitly owns the shared `InputState` and passes it through surfaces/modules to every control as a required input. Keyboard input clears pointer-hover presentation; `PointerTracker` resumes it only on movement or a mouse-button event, not a stale hover flag or layout change. This prevents ghost hover when Hyprland hides the cursor on keypress. Scrollable selector candidates ignore pointer hover and remain keyboard-owned; pointer clicks still choose/activate and wheel events still scroll. Hover remains available to buttons and other hover-enabled controls. The input state does not own another selection, poll the cursor, or call an external service.

`ShellButton` owns focused action activation: `config/Keyboard.qml` explicitly declares `buttonActivationKeys` (Return/keypad Enter) and `buttonActivationModifiers` (NoModifier). Press arms the existing pressed appearance; release invokes the native button action once, without forwarding activation to its parent. Focus loss, hiding or disabling cancels the press. Space remains native. This applies consistently to Save, Copy, Dismiss and all other shared buttons, with no popup-specific Enter handling.

Popup primary actions use the separate `popupActionKeys` (Return/keypad Enter) and `popupActionModifiers` (Control) policy in `config/Keyboard.qml`. Ctrl+Return or Ctrl+keypad Enter activates the explicit primary button of only the topmost focused popup, even while a field has focus. Disabled/busy actions are blocked and the key cannot leak to a parent. Theme Save and apply, settings Save, RGB Use color, and error Dismiss are primary actions; error Copy remains Ctrl+Shift+C. Information/help popups have no primary action.

Style composition follows [`STYLE.md`](../STYLE.md): color, shape, density, typography, motion, and elevation are independent QML singletons. A future component override is its own explicit QML component, never an untyped generic merge.

## Application launcher

`Super+Space` or the bar's Apps button opens the launcher. It focuses search, selects one candidate, and resets the query on reopening. Type to filter, Up/Down to choose, PageUp/PageDown to move one visible page, Enter to launch, and Escape to close. A click uses the same candidate and launch action. Search ranks exact, prefix, substring, then fuzzy subsequence matches over the explicitly configured fields; no external search process runs on a keypress.

The current compact layout uses single-line rows, optional icons, item names, and a configured visible-row count. Descriptions are available through Ctrl+I; the minimal view has no redundant title, permanent hints, or Close button. Padding, gaps and row borders remain explicit options. Paging derives its step from the actual viewport. Fsel informed the compact list, not the catalog implementation; shrinking rows cannot fix missing entries.

Starting an application shows a filled dot only in that application's trailing row slot, never a footer. The slot remains reserved while idle, so pending/error/success cannot resize the panel or shorten a label. `AppLauncher.launchIndicatorSize` controls its diameter; `Motion.launchPulse*` controls its opacity-only pulse. Reduced/disabled motion keeps it steady, and hidden/pooled/off-viewport rows stop animation. The native progress control and row description expose launch status to accessibility. The indicator follows the runner's desktop-entry target, not the current candidate.

`modules/apps/AppCatalog` adapts the native live `DesktopEntries` catalog; `AppSearch` owns indexing/ranking; `AppState` owns open/output state; `AppSurface` hosts a runtime output; `AppPanel` coordinates keyboard interaction; `AppRow` renders one candidate. `adapters/AppRunner` owns only app2unit handoff. The launcher does not execute desktop entries itself, parse Exec strings, record history, or run arbitrary commands.

`config/AppLauncher.qml` explicitly declares executable/arguments, searchable fields, hidden IDs, geometry, keys, loading/retention, icons, and the `showIcons`/`visibleRows` settings defaults. Set `showIcons: false` for text-only rows: their icon space disappears and no icon image is requested. `defaultIcon` is the user-declared icon for entries whose icon is unavailable. Qt's platform theme selects the icon theme; Quickshell also accepts the explicit `QS_ICON_THEME` environment variable. The private test declares its theme in `tests/nested.conf` rather than borrowing host Qt settings.

The real runner is `app2unit`, resolved from PATH and explicitly configured for service mode, `app-graphical.slice`, and graphical-session binding. The shell remains responsive while handoff runs; success closes once, and failure remains visible. Native Quickshell IDs have exactly one `.desktop` suffix removed; the adapter restores it, including double-suffix filenames. app2unit owns quoting, supported field-code expansion and working-directory/terminal behavior. The installed parser rejects `%k`; the shell reports that error without introducing another runner. `Terminal=true` requires `xdg-terminal-exec`, which is not currently installed. Real launch also needs a systemd user manager with the graphical session's environment and active graphical-session target.

`config/Outputs.qml` declares required launcher host defaults. `GeneratedLauncherOutput.qml` can override the mode and exact target independently of wallpaper/palette selection. Generate it with `bash scripts/render-shell-launcher-output shell/config/GeneratedLauncherOutput.qml screen-index <index>` or `output-name <name>`. User-supplied names are data; no hardware name lives in launcher components. Unavailable exact targets are errors. See [CONFIGURATION.md](../CONFIGURATION.md).

`components/PanelMotion` supplies the shared short, interruptible translation/opacity transitions. The launcher layer namespace `ui-shell-app-launcher` is excluded from compositor animations alongside the bar/picker. The candidate uses the shared opaque accent border while its view owns focus; hover feedback remains independent. The panel loads asynchronously on first use and is retained after closing according to its explicit options.

Tab/Shift+Tab transfer one focus stop between launcher Search and Applications, or between picker Search, Target, Wallpapers and Choose theme. The navigation links are declared explicitly in QML. Rows/tiles are not separate Tab stops: the content view owns focus, and a candidate keeps its identity without retaining its focus emphasis when another control/popup is active. Qt's implicit `currentItem` delegate focus is cleared too. Returning to the view does not reselect an old item. Arrows focus the view; launcher typing focuses search; Tab never inserts query text. Geometry, font weight and both border-box axes remain unchanged. Read-only error diagnostics are pointer-selectable; only Copy/Dismiss participate in its Tab cycle.

## QML rules

- Keep files focused and shallow.
- Extract each screen, surface, panel, control, delegate, and reusable object into its own file.
- Keep `shell.qml` as a bootstrap file.
- Prefer declarative bindings over imperative assignments.
- Use `Loader` for optional or expensive UI; keep inactive loaders inactive.
- Use `QtQuick.Controls` for standard controls instead of rebuilding them from primitives.
- Do not mix `anchors` and `Layout.*` on one item.
- Keep delegates small and use required typed model properties.
- Stop animations and timers when content is not visible.
- Animate transform/opacity where possible; avoid animated layout geometry.
- Do not use `Canvas` for frequently repainted or animated content.
- Set image `sourceSize` and load large images asynchronously.
- Keep accessibility and keyboard-first interaction intentional; focus has a distinct color on the same fixed-width border; selection, current and fill remain separate semantic states.
- Preserve the shared sharp-corner contract: all style radius slots remain zero.
- Use `qsTr()` for user-visible text.
- Do not add `.js` files or move feature logic into JavaScript.

## Performance rules

The shell runs continuously. Every new component must justify its CPU, memory, process, timer, image, and rendering cost.

- Prefer event-driven or file-watched updates over polling.
- Never spawn a process from every widget.
- Keep generated QML palette files small.
- Lazy-load menus, pickers, notifications, and other transient surfaces.
- Disable expensive effects when hidden.
- Keep one source of truth for each external state value.

## Omarchy lessons adopted

Omarchy is the primary structural reference. We adopt its useful ideas:

- one long-lived Quickshell host
- a shallow shell bootstrap
- clear separation between host, surfaces, modules, components, and shared tokens
- explicit entrypoints and configuration data
- per-monitor composition
- shared style tokens instead of scattered visual constants
- feature modules that can be loaded independently

We deliberately do not copy its broader desktop-environment surface, CLI/IPC control plane, JavaScript-heavy patterns, or unrestricted plugin model.

## Adding a feature

1. Add the feature and its system dependency to [`FEATURES.md`](../FEATURES.md).
2. Decide which boundary owns it: `hypr/`, `scripts/`, `state/`, `adapters/`, `modules/`, or `components/`.
3. Define the smallest explicit QML config contract and typed inputs.
4. Reuse existing theme tokens and controls.
5. Keep the feature loadable without creating unrelated global state.
6. Add the smallest meaningful test or visual verification step.

If a feature needs a new daemon, IPC protocol, CLI, broad service registry, or large settings surface, stop and review the scope before writing it.
