# Theme palettes and control colors

QML owns shell behavior and style. Theme definitions are complete colors-only schema-2 data: one `config.ini` per Theme, with explicit shell roles in `[palette]`, full named slots in `[colors]`, and native border expressions in `[hyprland]`. The default is `themes/default/config.ini`; authored definitions use `themes/<name>/config.ini`; imported reference definitions use the flat path `themes/<slug>-<variant>/config.ini`.

Theme definitions do not include wallpaper selections or shell style. A profile is one durable schema-2 recipe at `profiles/<id>/profile.ini`, selected through `[theme] profile` under configured `paths.profiles`. It stores full colors, wallpaper choices, optional named Theme identity, and scoped overrides in that INI; there are no `objects/`, `versions/`, or `wallpapers.lua` sidecars. Opening or canceling the picker creates no profile. Theme catalog discovery scans only `config.ini` metadata; selecting a Theme validates only its palette. The catalog uses a fast Python metadata scan, and the native dropdown is virtualized and inactive while closed. `Density.menuMaximumHeight` caps menus at 288 pixels, with `menuViewportMargin` keeping them inside smaller windows.

Profiles persist the optional named definition in `[theme] definition` and output-specific identities in `[definition_overrides]`, using config-root-relative paths. `[palette_outputs]` maps each palette scope to its exact output. Full scoped color inputs live in `[palette.<scope>]`, `[colors.<scope>]`, and `[hyprland.<scope>]`; wallpaper selections live separately in `[wallpaper.<scope>]`. An empty definition explicitly means a palette snapshot without a reusable definition; `source = wallpaper` means image-derived colors. Newly saved Custom colors name their generated definition. The editor restores this identity and its owned committed colors without rereading the definition or generating image colors. Missing named definitions are reported as errors, not replaced with another source.

Wallpaper palettes are content-addressed in the configured XDG cache namespace by image bytes, extractor schema/version, and dark/light mode. A valid entry is reused across selection and restart; a per-key lock prevents concurrent duplicate extraction. File Themes do not generate unused image colors at startup or when opening the editor. Choosing Wallpaper requests its palette on demand. Clearing the cache, changing the image/mode, or an invalid cache entry requires extraction again.

## Palette schema

Every definition contains a `[palette]` section with `schema = 2`, `mode = dark` or `mode = light`, and these thirteen opaque `#RRGGBB` shell roles. They are not a replacement for the complete `[colors]` palette:

| Role | Purpose |
| --- | --- |
| `background` | Main background |
| `surface` | Control and panel surface |
| `surfaceVariant` | Alternate surface |
| `elevated` | Raised surface |
| `text`, `textMuted` | Main and subdued foregrounds |
| `accent` | Primary selection and accent |
| `positive`, `warning`, `negative` | Explicit semantic status colors |
| `outline` | Neutral control boundary |
| `focus` | Keyboard focus |
| `scrim` | Dimming overlay |

The schema-2 intermediate contains mode, thirteen explicit shell roles, the complete `colors` map and native `hyprland` border settings. Generated QML exposes the whole record as `colorData`, named slots as `colors`, native settings as `hyprland`, and the shell roles as typed color properties. `Palette.colors.red` and `Palette.colors.bright_cyan`, for example, remain available to native QML bindings. Wallpaper-derived and imported/authored themes use the same complete contract. The editor saves this record intact, including slots it does not currently display.

## Control color API

`Style.controls` and each output's `MonitorStyle.controls` expose a typed `ControlColors` instance built from that style's palette. Components receive their owning style explicitly. Use its named roles (`surface`, `hoverSurface`, `pressedSurface`, `outline`, `selection`, `current`, `hover`, `pressed`, `focus`, and matching text roles) rather than deriving colors in controls.

Qt's own default controls read palette roles, not these typed colors. `ControlPalette` is the one place that maps a style's `ControlColors` onto Qt palette roles (`window`, `windowText`, `highlight`, `light`/`midlight` for item feedback, `dark` for borders, ...); declare it inside a control or popup (`Theme.ControlPalette { palette: root.palette; colors: root.style.controls }`) and everything below it that inherits the palette is themed. `ContextPopup` and `ShellTextField` do this. Qt's built-in Cut/Copy/Paste menu is a popup and does **not** inherit its editor's palette, so every text editor gives itself the themed menu: `ContextMenu.menu: ShellEditingMenu { editor: root; style: root.style }`. A new text control must do the same, or its menu is white.

`Interaction.qml` owns static policy and colour math: emphasis names, state-layer amounts (hover 0.08, focus 0.10, pressed 0.14), container tints, the disabled 38%/12% rule, contrast floors (text 4.5:1, boundaries 3:1), and OKLab helpers (`toOklch`, `fromOklch`, `distance`). `readable()` fixes contrast by shifting OKLCH lightness at constant hue and chroma, so corrected colours never fade to grey; `onFill(fill, tint)` returns hue-tinted near-black or near-white content for a coloured fill. QML names such as `onPrimary` collide with signal handlers, so content roles are named `primaryText` and `containerText`.

Roles on `ControlColors` (all derived from the thirteen palette roles at runtime, so generated, imported and custom themes behave identically): `surface`, `hoverSurface`, `focusSurface`, `pressedSurface`; `primary`, `primaryText`, `primaryHover`, `primaryFocus`, `primaryPressed`; `container`, `containerHover`, `containerPressed`, `containerText`; `currentContainer`, `currentText`; `text`, `muted`, `hoverText`; `outline`, `focus`, `current`; `disabledText`, `disabledSurface`, `disabledBorder`. `ControlState` combines them: precedence disabled → pressed → selected → focused → current → hover → normal, and `solid` (filled primary) or `outline` (neutral, tonal selection) emphasis. State is fill + foreground; the border only draws the keyboard-focus ring (`Interaction.borderStates`, overridable per control); geometry never changes. Amounts are overridable per style with `controlTuning` (`ControlColors.knobNames`); body text aims for 7:1 and settles at 4.5:1 only when the hue cannot reach it. `Style.textMuted` is the verified `muted` role.

Components do not instantiate `ControlState` themselves: `components/ShellControlState.qml` takes the owning `style`, the Qt `control` (hover, press, focus and enabled follow it, hover only while the pointer is the active input) and the `emphasis`, and any flag a control computes differently is overridden on the instance. Rows and tiles omit `control` and set the flags. A new control is `ShellControlState` + `ShellControlBackground` + `visual.foreground`, with no per-control colour code. Foreground tint encodes engagement: rest neutral, hover a hint (`hoverTextMix`), pressed/selected strongly accent-hued (`activeTextMix`), so the two never read alike.

`ControlPalette` maps the same roles onto Qt's palette, including the `disabled` group, so Qt's default controls and menus show unavailable entries in `disabledText`.

The model's amounts are not hand-written: `GeneratedControlTuning.qml` (rendered by `scripts/render-control-tuning`, which owns the schema) supplies defaults, `ControlTuning` merges them with the saved user file and the panel's live draft, and `Interaction` exposes the result. Regenerate the seed with `scripts/render-control-tuning > shell/theme/GeneratedControlTuning.qml`; `make test-pipelines` fails if it is stale. The panel (`modules/tuning/`, Super+T; its editor is `components/ControlTuningEditor`) builds its rows from the schema and persists through `adapters/ControlTuningStore`.

Control modes (tonal, wash, ink, hush, cursor, neon) are behaviour profiles held as data in `scripts/control-model/` (`knobs.json`, `behavior.json`, `modes.json`) and rendered by `scripts/render-control-tuning`: numeric presets plus a per-state, per-channel role table and flags (hover, focus visibility, resting border, marker, animation). `ControlTuning.behavior` is the active profile and `ControlState` interprets it; `ControlColors.roles` is the vocabulary a profile can name; `tst_ModeGallery` saves `mode-gallery.png` comparing them on three palettes.

Review a colour change visually with `make test-qml`: `tst_StateGallery` saves `state-gallery.png` (20 imported palettes × emphasis × state) into the test artifacts, and `tst_ControlColors` asserts contrast and distinguishability on all of them.

## Offline import of 100-themes palettes

The converter reads reference TOML locally using Python's standard `tomllib` parser and retains every named hex slot and both native border expressions. ANSI palette names do not imply status semantics, so callers choose the source fields for positive, warning, and negative explicitly. For example:

```bash
make dev-import-themes POSITIVE=green WARNING=yellow NEGATIVE=red
```

The development target depends on `dev-stage`, resolves the staged manifest directly, and invokes the five-argument wrapper with `refs/100-themes` and explicit status mappings. It does not prepare runtime or compile profiles. The nested target invokes the same wrapper and exits before runtime preparation, so no cache or profile bundle is generated. The wrapper delegates to the strict seven-argument converter. It validates and renders the discovered reference set before publishing, then regenerates matching flat reference Theme IDs; changed matching files are replaced. Unrelated/custom Theme IDs and all profile recipes remain untouched. No legacy importer interface or compatibility path is supported.

The high-level importer accepts:

```text
bash tools/scripts/import-reference-themes RESOLVED_RUNTIME REFERENCE_ROOT POSITIVE_FIELD WARNING_FIELD NEGATIVE_FIELD
bash tools/scripts/import-theme-colors REFERENCE_ROOT DESTINATION NORMALIZER RENDERER POSITIVE_FIELD WARNING_FIELD NEGATIVE_FIELD
```

Theme config files are published as flat `SLUG-VARIANT/config.ini` entries beneath resolved `paths.themes`. Source files remain read-only. Status mappings are required choices, not inferred from ANSI names.

The renderer interfaces remain:

```text
scripts/normalize-theme-colors INPUT_TOML OUTPUT_JSON POSITIVE_FIELD WARNING_FIELD NEGATIVE_FIELD
scripts/render-theme-colors INPUT_JSON OUTPUT_INI
scripts/render-shell-colors INPUT_JSON OUTPUT_QML
```

The JSON is an intermediate only. The converter validates and renders all discovered inputs before publishing; changed matching reference files are atomically replaced. Failed input validation preserves published outputs. It does not overwrite unrelated Theme IDs or profiles.
