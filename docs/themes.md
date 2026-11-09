# Themes and committed profiles

A Theme definition is one schema-2 `config.ini`. `[palette]` contains mode and explicit shell color roles; `[colors]` preserves the complete named source palette; `[hyprland]` preserves native active/inactive border expressions. The default is `themes/default/config.ini`; authored definitions use `themes/<name>/config.ini`; imported reference variants use the flat path `themes/<slug>-<variant>/config.ini`. A Theme defines colors only. Wallpaper selection, shape, density, typography, motion, and shell behavior remain independent.

The source tree has no checked-in `themes/` or `profiles/` runtime stores. It does ship `bundled-themes/`: the 500 reference Themes of [100-themes](https://github.com/bjarneo/100-themes) by Bjarne Øverli, converted once and credited in `bundled-themes/CREDITS.md`. `stage-defaults` adds any missing bundled Theme to the runtime store (existing ones are never touched), so every environment, including `make test-env-host`, has them without importing. Its single seed is `default/`, containing the default wallpaper and the Theme and profile generated from it. Development staging installs that seed as `default/` and seeds the runtime stores only when they are absent; user-created and imported Themes, profiles, and selections are never rewritten. `tools/scripts/generate-default` regenerates both checked-in default files from `default/default.png`, and `tools/scripts/stage-defaults` owns the clean seed installation used by staging, tests, and private state. Tests generate any non-default Theme or profile fixture locally.

The wallpaper picker and palette chooser form one draft. Browsing or choosing a Theme reads only that Theme's palette; it does not save a profile or change the desktop. Back preserves the draft, while closing the picker discards it. Only final **Save and apply** commits and activates the chosen wallpaper and palette together.

A profile is one durable schema-2 recipe at `profiles/<id>/profile.ini`, selected through `[theme] profile` and stored under configured `paths.profiles`. It contains full palette data and wallpaper choices, optional named Theme identity, and scoped overrides in the INI itself; there are no `objects/`, `versions/`, or `wallpapers.lua` sidecars. Opening and canceling the picker creates no profile. The shipped `default/profile.ini` uses `source = file`, references `themes/default/config.ini`, selects `folder = default`, `path = default.png`, and carries the same full palette snapshot as `default/theme.ini`. The private test environment may retain older unreleased choices; reset that private state explicitly with `make test-env-clean`, preserving imported Theme definitions.

The profile's `[theme] definition` stores the optional selected Theme path relative to the config root; `[definition_overrides]` records output-specific Theme identities. `[palette_outputs]` maps each palette scope to its exact output. Full scoped palette inputs live in `[palette.<scope>]`, `[colors.<scope>]`, and `[hyprland.<scope>]`; wallpaper selections live separately in `[wallpaper.<scope>]`. The editor restores named choices and committed full palettes after restart. An empty definition explicitly denotes a palette snapshot without a named definition; wallpaper source has no definition. Saved Custom colors become a named reusable Theme. File Themes need no wallpaper-color extraction to start or open the editor. Choosing Wallpaper extracts its palette only on a cache miss; subsequent requests reuse the same content-addressed palette.

## Palette roles

Each `[palette]` section has these thirteen opaque `#RRGGBB` values:

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

Extra or missing shell roles, duplicate sections or keys, and malformed values are rejected. `[colors]` requires the 25 named slots shown in `default/theme.ini`, and accepts additional named opaque hex slots. It retains `red`, `orange`, `brown`, the other ANSI slots, `bright_*`, and background/foreground shades. These names are slots, not guarantees of hue or status meaning. `[hyprland]` requires `active_border` and `inactive_border`; a multi-stop expression retains opacity and its optional `deg` angle. The Lua renderer converts it into the compositor's native gradient table. `mode` is palette metadata; it does not invert colors or choose shape, density, typography, or motion.

Import, native preview, draft copying, custom editing, save and restart all carry the complete named theme. Editing one shell role does not erase untouched source colors or native border settings. The script save boundary receives one named theme-data object, not thirteen positional colors. JSON is private process data, never authored Quickshell configuration. Schema 1 is no longer accepted; unreleased files are updated explicitly, not silently migrated.

## Approved profile compilation model

A profile composes wallpaper choices, a named Theme or wallpaper-derived source, explicit output overrides and enabled subsystem targets. The durable recipe belongs in `$XDG_CONFIG_HOME/ui-shell/profiles/<id>/`. Its reproducible compiled bundle belongs in `$XDG_CACHE_HOME/ui-shell/profiles/<id>/<build-key>/` and contains the full resolved palette, native Quickshell colors, Hyprland colors and wallpaper configuration. Future Qt/GTK targets get their own renderers.

Profile compilation writes a complete generation beneath `${XDG_CACHE_HOME}/ui-shell/profiles/<id>/<build-key>/`. It includes the resolved global and default/output palettes, recipe state and wallpaper data, native Quickshell modules, Hyprland colors and output Lua, Hyprpaper configuration, the wallpaper Lua projection, and `checksums.sha256`. The key includes recipe bytes, selected/configured inputs, and helper/renderer bytes. A valid checksummed generation is reused; missing or invalid cache data is rebuilt from the durable recipe and other inputs. `[paths] profileCache` configures the cache root. `[bootstrap] runtime` and `wallpaperCatalog` are installation metadata; configured `profileModule` is the in-Quickshell link location that `prepare-runtime` atomically points at the generation's `quickshell/` directory. Generated files remain in cache, and the generated runtime imports the linked module relatively within the Quickshell root. Required Quickshell, Hyprland, and Hyprpaper renderers and any optional GTK/Qt renderer receive `INPUTS_JSON OUTPUT_DIRECTORY`; the compiler stages all targets before atomically publishing the generation.

`bundle.hyprOutputPalettes` points to the generated `hyprland/outputs.lua` index. Each entry records the exact output, a stable hashed rule identity and the relative native palette file. `hypr/borders.lua` registers focused/unfocused window rules using workspace monitor filters (`m[output]`). Ordinary ungrouped window borders follow their workspace's output. Outputs without an explicit palette use the global border defaults. Group and locked-group decoration, groupbars and other compositor colors retain their global policy; this is not a whole-compositor per-monitor theme. Exact output port names cannot contain whitespace or brackets, which the native workspace filter syntax cannot represent. The current target, [Hyprland 0.56.2](https://github.com/hyprwm/Hyprland/blob/v0.56.2/src/desktop/rule/windowRule/WindowRule.cpp), stores separate active/inactive slots. A native gradient fills the active slot; the unfocused rule uses a solid-color pair to initialize both slots with the configured inactive color, including alpha. This build's paired-gradient parser does not initialize its inactive gradient color data, so output-specific inactive gradients, fractional active angles and more than ten stops are rejected before publication. Theme source metadata is preserved, never flattened to work around that limit. The newer cloned wiki's single-gradient-plus-focus recipe does not set this build's inactive slot. Save and apply and session startup use the same generated index; there is no version shim, focus callback, watcher or theme daemon.

The coordinator resolves sources, reuses cached extraction, invokes separate configured renderers, publishes a complete generation and applies native consumers. Installation bootstrap is separate. Cache cleaning never removes authored/imported Themes or saved choices. Native application failures remain visible; publishing complete files does not promise simultaneous application across processes.

## Reference palette import

The importer is maintainer automation only: `make dev-bundle-themes POSITIVE=green WARNING=yellow NEGATIVE=red` runs it and refreshes `bundled-themes/`. Runtime and tests never read `refs/`.

The offline importer converts `SLUG/VARIANT/colors.toml` definitions into flat Theme `config.ini` directories beneath the configured theme root. Status roles are explicit caller choices because ANSI names do not guarantee positive, warning, or negative semantics. The high-level command takes the resolved runtime, reference root, and three source status field names:

```sh
make dev-import-themes POSITIVE=green WARNING=yellow NEGATIVE=red
make test-import-themes
```

The development target depends on `dev-stage`, resolves the staged manifest directly, and invokes the importer without `prepare-runtime` or profile compilation. Nested import exits before runtime preparation, so it generates no cache or profile bundle. Both use the same five-argument wrapper and strict seven-argument converter. The converter validates and renders all discovered references before publishing, then overwrites only matching flat reference Theme IDs. Unrelated/custom Theme IDs and all profile recipes remain untouched. There is no legacy importer compatibility path. See [the palette format and renderer](../shell/theme/README.md).

Reference palettes remain subject to their original licensing and attribution requirements. Local conversion does not grant redistribution rights.
