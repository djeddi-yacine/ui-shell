# matugen: Rust CLI that derives Material You and base16 schemes from an image or color and renders templates from them

Source: refs/matugen (shallow clone; commit e5eac08; branch main). License: GPL-2.0-or-later (`Cargo.toml:9`); the license text is GPL v2 (`LICENSE:1-2`). Scope: `src/` (scheme, color, template, util, filters, wallpaper, exec, main), `matugen-parser/src/` (template expression engine), `Cargo.toml`, `README.md`. Not studied: `material-colors/`, `assets/`, `example/`, `module.nix`, `default.nix`, `compare-script.ts`.
Id prefix: MG.

## 1. Purpose and shape
- MG1.1 "A cross-platform material you and base16 color generation tool" (`README.md:6`). The crate is named `matugen`, version 4.2.0 (`Cargo.toml:2-3`), description "A material you and base16 color generation tool with templates" (`Cargo.toml:5`). Language: Rust (edition and toolchain not checked).
- MG1.2 Toolkit targets: not toolkit-specific. It writes files from templates. It also sets wallpapers through `src/wallpaper/` (`unix.rs`, `macos.rs`, `windows.rs`; bodies not read).
- MG1.3 Dependencies that define the color math: `material-colors` 0.4.0 with `image` and `serde` features (`Cargo.toml:65`); `palette` 0.7.6 (`Cargo.toml:88`); `image` 0.25.2 without default features (`Cargo.toml:66`). Optional features: `web-image` (reqwest), `dump-json` (serde_json), `jxl-image` (jxl-oxide) (`Cargo.toml:28-30`).
- MG1.4 Top-level layout (names that matter):
  - `src/scheme.rs`: scheme type enum and scheme collection (`SchemeTypes`, `:18`).
  - `src/smart_scheme.rs`: automatic scheme selection from image colorfulness (`detect_variant`, `:55`; `get_smart_opts`, `:79`).
  - `src/color/`: source color extraction (`color.rs`), base16 generation (`base16.rs`), backends (`backend/wal.rs`), quantizer (`quantizer_kmeans.rs`), formats (`format.rs`, `parse.rs`).
  - `src/template.rs` and `src/template_util/`: template loading, per-template scheme selection, hooks.
  - `src/filters/`: template filter functions (`colortransform.rs`, `set.rs`, `string.rs`).
  - `src/util/config.rs`: configuration file loading. `src/util/arguments.rs`: CLI definitions.
  - `src/exec/`: command execution helpers (`command.rs`, not read in detail).
  - `matugen-parser/src/`: template language parser and evaluator (`engine/parser.rs`, `engine/resolve.rs`, `engine/replace.rs`, `filters/`, `color/`).

## 2. Theme input (how configuration reaches it)
- MG2.1 Source color: image path, image URL (feature `web-image`), or a color string. `get_source_color` (`src/color/color.rs:164`), `get_source_color_from_image` (`:208`), `get_source_color_from_web_image` (`:337`), `get_source_color_from_color` (`:344`).
- MG2.2 Scheme mode: `mode` CLI argument with default `"dark"` (`src/util/arguments.rs:53-62`, `default_value` at `:60`).
- MG2.3 Configuration file: loaded by `ConfigFile::read(args)` (`src/util/config.rs:68`). A custom path comes from the `args.config` argument (`:69-72`). The default location comes from `ProjectDirs::from("com", "InioX", "matugen")` (`src/util/config.rs:54-66`, function `get_proj_path`; config dir and cache dir via `ProjectDirsTypes`, `:49-52`).
- MG2.4 Command-line overrides: `ConfigFile::parse_cli_overrides` (`src/util/config.rs:113`).
- MG2.5 Lightness adjustment for dark and light: `adjust_color_lightness_dark` (`src/color/color.rs:113`) and `adjust_color_lightness_light` (`:129`). The dark function's comment (`:114`) describes an affine transform with a clamp.
- MG2.6 Custom colors: `make_custom_color` (`src/color/color.rs:384`), `get_custom_color_schemes` (`src/scheme.rs:104`), `to_custom_color` (`src/color/color.rs:94`).
- MG2.7 Base16 backend choice: `base16::Backend` enum with a single variant `Wal` (`src/color/base16.rs:29-30`, constructor `:34-37`).

## 3. Color and style model
- MG3.1 Scheme types (`src/scheme.rs:18-30`): `SchemeContent` (default), `SchemeExpressive`, `SchemeFidelity`, `SchemeFruitSalad`, `SchemeMonochrome`, `SchemeNeutral`, `SchemeRainbow`, `SchemeTonalSpot`, `SchemeVibrant`, `SchemeSmart`.
- MG3.2 Each non-smart type maps to a `material_colors::dynamic_color::Variant` (`src/scheme.rs:34-46`). `SchemeSmart` maps to `None` (`:45`) and is resolved at run time.
- MG3.3 Smart selection: `detect_variant(colorfulness)` (`src/smart_scheme.rs:55-62`). Colorfulness below 6.0 gives Monochrome, 6.0 to under 20.0 gives Neutral, 20.0 to under 70.0 gives TonalSpot, and 70.0 or more gives Vibrant. Colorfulness is computed in `get_smart_opts` (`:79`; formula not read).
- MG3.4 Material scheme: `material_colors::scheme::Scheme` (imported at `src/scheme.rs:6`). Scheme object construction and the Material tone calculations are in the external `material-colors` crate (not in the repo).
- MG3.5 Base16: `generate_base16_scheme_from_palette` (`src/color/base16.rs:51`) and `generate_base16_scheme_from_color` (`:81`). Gray ramp: `interpolate_grays(base00, base05, dark)` (`:129`). Hue shift: `drag_hue(source_hue, target_hue, amount)` (`:45`).
- MG3.6 Color transforms exposed to templates: `lighten` (`src/filters/colortransform.rs:74`) and `saturate` (`:120`). The other filter names were not enumerated (UNVERIFIED for the full filter list).
- MG3.7 Light and dark: the `mode` value selects the dark or light path in `generate_base16_schemes` and the lightness adjusters (MG2.2, MG2.5). Per-state colors (hover, pressed, disabled, focus): not found in the read ranges (UNVERIFIED).

## 4. Output and rendering path
- MG4.1 Template definition (`src/template.rs:36-51`): `input_path`, `output_path`, `mode`, `colors_to_compare`, `compare_to`, `pre_hook` (`:42`), `post_hook` (`:43`), `input_path_modes`, expression and block delimiters (`:45-48`), `index`, `type` (`:50`), `enabled` (`:51`).
- MG4.2 Call chain, in order:
  1. CLI parse and config load: `ConfigFile::read` (`src/util/config.rs:68`).
  2. Source color: `get_source_color` (`src/color/color.rs:164`).
  3. Scheme generation: `get_schemes` (`src/scheme.rs:177`) and `generate_dynamic_scheme` (`src/color/color.rs:372`). Base16 schemes via `generate_base16_schemes` (`src/color/base16.rs:153`).
  4. Template run: `TemplateFile::new` (`src/template.rs:82`) and `TemplateFile::generate` (`:90`). Called from `run_in_term` (`src/main.rs:562`; `run_in_term` at `:517`).
  5. Per-template scheme selection: `template.r#type` maps `SchemeSmart` to the detected variant (`src/template.rs:178-183`), cached per type in `scheme_cache` (`:71`, `:183-194`).
  6. Context: `change_scheme_type` replaces the `colors`, `base16` and `palettes` keys in the engine context with the selected scheme (`src/template.rs:474-493`).
  7. Expression evaluation: the `matugen-parser` crate (`matugen-parser/src/engine/parser.rs`, `resolve.rs`, `replace.rs`) resolves template expressions. Filters from `matugen-parser/src/filters/` and `src/filters/` run on values.
  8. Hooks: `format_hook` (`src/template.rs:498`) handles `pre_hook` and `post_hook`. The command execution used for hooks was not traced (UNVERIFIED).
- MG4.3 Output path: `output_path` (`src/template.rs:38`), type `OutputPath` (`:57`). Relative output resolution through `get_absolute_path` (`src/template.rs:625`).
- MG4.4 Image output of palette swatches: `src/util/color.rs` (`show_color`, referenced from `src/main.rs:37`; body not read).

## 5. Extension and integration points
- MG5.1 User templates: the template list comes from the config file (MG2.3). Template files are arbitrary text with matugen expression syntax (`matugen-parser`).
- MG5.2 Hooks: `pre_hook` and `post_hook` strings per template (`src/template.rs:42-43`). Run semantics not traced (UNVERIFIED).
- MG5.3 Custom colors per template or in the config: `make_custom_color` (`src/color/color.rs:384`) and `get_custom_color_schemes` (`src/scheme.rs:104`).
- MG5.4 Backends for base16: enum `base16::Backend` with `Wal` only (`src/color/base16.rs:29-30`). The `PaletteBackend` trait (`:41-43`) extracts a palette from an image; `src/color/backend/wal.rs` implements it.
- MG5.5 Install: `module.nix` and `default.nix` exist (not read). Installation paths for config and cache come from `ProjectDirs` (MG2.3).
- MG5.6 Version coupling: the `material-colors` crate version is pinned at 0.4.0 (`Cargo.toml:65`). The Material variants used by MG3.2 are defined by that crate.

## 6. Data and tooling
- MG6.1 Templates and example configuration: `example/` directory (not read).
- MG6.2 Helper scripts: `compare-script.ts` at repo root (not read); `package.json` and `pnpm-lock.yaml` exist (not read).
- MG6.3 Tests: `src/` contains `#[cfg(test)]` code, for example in `src/smart_scheme.rs` (test asserts at `:129-130`). Other test locations not checked.
- MG6.4 Docs: `README.md`, `CHANGELOG.md`.

## 7. Facts of note
- MG7.1 Smart scheme thresholds are fixed in code (`src/smart_scheme.rs:55-62`).
- MG7.2 The `mode` CLI default is dark (`src/util/arguments.rs:60`).
- MG7.3 Base16 supports only the `Wal` backend in this commit (`src/color/base16.rs:29-30`).
- MG7.4 `SchemeContent` is the default scheme type (`src/scheme.rs:19-20`).
- MG7.5 License: GPL-2.0-or-later (`Cargo.toml:9`), GPL v2 text (`LICENSE:1-2`).

## 8. Not covered
- `material-colors` crate (external, not in the clone); Material tone math.
- `src/color/quantizer_kmeans.rs` and `src/color/color.rs` bodies beyond the function headers.
- `matugen-parser` parser and evaluator bodies.
- Hook command execution (`src/exec/`), wallpaper setting (`src/wallpaper/`), `src/util/color.rs`.
- Template files under `example/`; `module.nix`, `default.nix`, `compare-script.ts`, `assets/`.
- No build or run was done; `refs/` was not modified.
