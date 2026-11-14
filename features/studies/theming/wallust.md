# wallust: Rust CLI that extracts a 16-color palette from an image and renders templates, jinja2 or pywal-style, plus hooks

Source: refs/wallust (shallow clone; commit a09480b; branch master). License: MIT (`LICENSE:1`, `Cargo.toml:5`). Scope: whole `src/` tree (config, colors, backends, histogram, themes, template, sequences, args), `Cargo.toml`, `wallust.toml` (default config), `README.md`. Not studied in detail: `src/bin/*`, `benches/`, `tests/`, `docs/`, `book.toml`, `build.rs`, `build.nix`, `default.nix`, `man/`, `completions/`.
Id prefix: WL.

## 1. Purpose and shape
- WL1.1 Crate `wallust` version 4.1.0-alpha (`Cargo.toml:3`). Description: "Generate a 16 color scheme based on an image." (`Cargo.toml:9`). Language: Rust, edition 2021 (`Cargo.toml:4`).
- WL1.2 Targets: not toolkit-specific. It writes text outputs (templates, palette files) and terminal escape sequences (`src/sequences.rs:12`, `unix_term` at `:69`, `windows_term` at `:180`).
- WL1.3 Dependencies that matter: `minijinja` for jinja2 templates (`src/template/mod.rs:17`); `dirs` for the config directory (`src/config.rs:251`); CAM16-UCS color math (documented in `src/config.rs:36-39`).
- WL1.4 Top-level layout (in `src/`):
  - `config.rs`: `Config` struct (`:35`), `Style` (`:112`), config loading (`Config::new`, `:246`), template writing, hooks.
  - `colors.rs`: `Colors` struct, one `Myrgb` per slot (`:23`), `Myrgb` (`:49`), blend and complement helpers (`:105-127`).
  - `backends/`: image readers that feed the histogram (`Backend` enum at `backends/mod.rs:33`; `full.rs`, `resized.rs`, `fast_resize.rs`, `thumb.rs`, `wal.rs`).
  - `histogram/`: palette extraction (`mod.rs`, `kmeans.rs`, `salience.rs`, `ansi.rs`, `util.rs`).
  - `themes.rs`: loading of palette files and built-in themes (`Schemes` enum at `:64`, `search_theme_or_cs` at `:83`, `built_in_theme` at `:261`).
  - `template/`: template rendering (`mod.rs`, `colors.rs` for color value helpers, `pywal.rs` for the pywal syntax, `jinja2.rs`).
  - `sequences.rs`: terminal OSC sequences.
  - `args/`: CLI arguments (`args/mod.rs`, `migrate.rs`).
  - `cache.rs`, `pick.rs`, `main.rs` (entry at `main.rs:14`).

## 2. Theme input (how configuration reaches it)
- WL2.1 Image input: the source image path via CLI; the backend reads it (`src/backends/mod.rs:94`, `open_with_imagers`). The source image is an argument, not read from config (the CLI arg set is in `src/args/mod.rs`, not fully read).
- WL2.2 Palette source selection: `search_theme_or_cs(name, quiet, confpath, schemes)` (`src/themes.rs:83`) reads a named theme or color-scheme file. Formats: `Schemes::Pywal`, `Schemes::TerminalSexy`, `Schemes::Wallust` (`src/themes.rs:64-72`). `try_all_schemes` (`:149`) tries each format.
- WL2.3 Config file: `wallust.toml`. The path is `g.config_dir` if given (`src/config.rs:248-249`, CLI `-C`/`--config-dir` at `src/args/mod.rs:51`), else `dirs::config_dir()` joined with `wallust` (`src/config.rs:251-268`, default file `dir/wallust.toml` at `:268`). A default file is written when missing from the embedded `wallust.toml` (`src/config.rs:290`).
- WL2.4 Config fields (`src/config.rs:35-106`, selected):
  - `threshold` (Delta-E separation, `:39`), `alpha` (`:42`), `check_contrast` (`:46`), `saturation` (`:49`).
  - `templates` (`:61`) map of template name to `Fields`; `hooks` (`:64`) map of name to shell command.
  - `templates_dir` (`:85`), `backend` (`:91`), `style` (`:100`), `palette` (`:106`).
- WL2.5 CLI overrides: `Config::customs_cli` (`src/config.rs:399`).
- WL2.6 Style: `Style::Dark` (default) and `Style::Light` (`src/config.rs:112-116`, `#[default]` at `:113`).
- WL2.7 Backend selection: `Backend` enum with variants `Full`, `Resized`, `Wal`, `Thumb`, `FastResize` (`src/backends/mod.rs:33-51`). The default is `FastResize` (`#[default]` at `src/backends/mod.rs:46`, variant at `:47`). Option names are in `#[clap(...)]` attributes.
- WL2.8 Histogram settings: `KmeansConfig` (`src/config.rs:127`), `SalienceConfig` (`:120`), `PrettyConfig` (`:144`). Palette selection enum `histogram::Palette` (used at `src/config.rs:106`; definition not read).
- WL2.9 Environment: `dirs::config_dir()` (XDG on Linux, via the `dirs` crate; `src/config.rs:251`).

## 3. Color and style model
- WL3.1 Palette struct `Colors` (`src/colors.rs:23-48`): fields `cursor`, `background`, `foreground`, then `color0` through `color15`. Each field is `Myrgb` (`src/colors.rs:49`), a wrapper around `palette::Srgb` (`:49`).
- WL3.2 Color math helpers: `Myrgb::complementary` (`src/colors.rs:105`), `blend(a, b)` (`:118`), `blend_alpha(a, b)` (`:127`).
- WL3.3 Palette extraction (`src/histogram/`): colors are converted to CIE Lab (`bytes_to_lab`, `src/histogram/kmeans.rs:17`), grouped by k-means (`kmeans`, `:25`) or by histogram gather (`gather`, `src/histogram/mod.rs:585`). Separation uses a Delta-E threshold (`merge_de`, `src/histogram/mod.rs:540`; `collapse_sub_jnd`, `:421`). Config doc at `src/config.rs:36-38` says colors closer than the threshold are folded into the dominant survivor, and interpolated when fewer than six remain.
- WL3.4 Interpolation and salience: `interpolate_spec` (`src/histogram/salience.rs:472`), `mod_best_effort` (`:502`), `mod_similar` (`:598`). The bodies were not read in detail.
- WL3.5 Contrast check: `check_contrast` flag (`src/config.rs:46`; the W3C contrast calculation is described in the doc comment at `:44-45`, body not read).
- WL3.6 Light and dark: `Style` (WL2.6) selects the variant. The code path that uses `style` to choose lightness was not traced (UNVERIFIED).
- WL3.7 Per-state colors (hover, pressed, disabled, focus): none found in the read ranges (UNVERIFIED).

## 4. Output and rendering path
- WL4.1 Call chain, in order:
  1. Config load: `Config::new` (`src/config.rs:246`).
  2. Image read: `backend.main()` returns a function (`src/backends/mod.rs:53`), called on the image path; `open_with_imagers` (`:94`).
  3. Palette extraction: `histogram` (kmeans or gather; WL3.3).
  4. Palette to `Colors` (`src/colors.rs:23`).
  5. Template write: `Config::write_entry(wal_str, colors, quiet)` (`src/config.rs:363`) iterates `self.templates`. For each entry it calls `write_template(config_dir, templates_header, values, quiet, env_vars)` (`src/template/mod.rs:139`).
  6. Per-template rendering: if the `pywal` field is true, `render_pywal` (`src/template/mod.rs:69`, syntax in `src/template/pywal.rs:48`); otherwise `render_jinja` (`src/template/mod.rs:40`), which renders through a `minijinja` environment with the path loader set to the config dir (`:145`).
  7. Sequences: `sequences` (`src/sequences.rs:12`) writes escape sequences to terminals (`unix_term`, `:69`; `windows_term`, `:180`).
  8. Hooks: `Config::run_hooks` (`src/config.rs:435`) runs each hook through `sh -c` (`Command::new("sh").arg("-c")`, `:444`). `run_templated_hooks` (`src/config.rs:453`) renders each command through jinja2 before running it.
- WL4.2 Template variables for jinja2 come from `TemplateFields::to_hash` (`src/template/mod.rs:92`) and `minijinja::Value::from(self)` (`:59`). Colour value helpers in `src/template/colors.rs`: `rgb` (`:10`), `hexa` (`:18`), `rgba` (`:24`), `xrgba` (`:31`), `xrgb` (`:40`), `strip` (`:46`), `red`/`green`/`blue` (`:53-61`), float channels `redf`/`greenf`/`bluef` (`:71-73`).
- WL4.3 Pywal-compatible template functions: `get_func(fname, value, alpha)` (`src/template/pywal.rs:25`).

## 5. Extension and integration points
- WL5.1 User templates: `templates` table in `wallust.toml` (`src/config.rs:61`). Each `Fields` entry names a template file and a target path, relative to `templates_dir` (`src/config.rs:85`).
- WL5.2 Templating languages: jinja2 (default) and pywal (per-entry `pywal` flag; `src/template/mod.rs:165-168`).
- WL5.3 Hooks: `[hooks]` table, each value a shell command (`src/config.rs:64`, `run_hooks` `:435`). `run_templated_hooks` (`:453`) adds jinja2 rendering of the command string.
- WL5.4 Palette file formats as inputs: pywal JSON, terminal.sexy JSON, and wallust's own cache (`src/themes.rs:64-72`).
- WL5.5 Backend selection by name or option (WL2.7).
- WL5.6 Version and feature coupling: `minijinja` and `dirs` crate versions (`Cargo.toml`, not read).

## 6. Data and tooling
- WL6.1 Default config: `wallust.toml` at the repo root, embedded into the binary with `include_bytes!` (`src/config.rs:290`).
- WL6.2 JSON schema generator: `src/bin/jsonschema.rs` (not read). A cargo feature named `schema` enables `schemars::JsonSchema` derives on config types (the attribute lines were not located; UNVERIFIED for which types).
- WL6.3 Man pages and completions: `man/`, `completions/` (names only; `src/bin/man.rs`, `src/bin/completions.rs`).
- WL6.4 Docs: `docs/` and `book.toml` (not read). The `V3` constant holds the v4 documentation link (`src/config.rs:242`), used in the migration error message (`src/config.rs:301`).
- WL6.5 Tests: `tests/` and `benches/` directories (not read).

## 7. Facts of note
- WL7.1 The default backend is `FastResize` (`src/backends/mod.rs:46-47`). Its doc comment says it fails on some images where `resized` works (`src/backends/mod.rs:44-45`).
- WL7.2 The `Wal` backend uses ImageMagick `convert` (`src/backends/mod.rs:39-41` doc comment).
- WL7.3 Hooks are started with `spawn()` and the returned `Child` is discarded without a wait (`src/config.rs:444`).
- WL7.4 License MIT (`LICENSE:1`).

## 8. Not covered
- Bodies of `histogram/salience.rs` (beyond the three named functions), `histogram/ansi.rs`, `histogram/util.rs`.
- Bodies of backend readers (`backends/full.rs`, `resized.rs`, `fast_resize.rs`, `thumb.rs`, `wal.rs`).
- `src/args/*` CLI definitions beyond the `-C` flag; `src/cache.rs`; `src/pick.rs`.
- `src/template/jinja2.rs`; `src/template/pywal.rs` bodies beyond `get_func` and `render`.
- `src/config.rs` bodies for `write_entry` and `run_templated_hooks` beyond the cited lines.
- Build, tests and docs directories. No build or run was done; `refs/` was not modified.
