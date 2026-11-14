# pywal16: Python tool that derives a 16-color palette from an image and writes it into per-application template files

Source: refs/pywal16 (shallow clone; commit 9f34fbf; branch master). License: MIT (`LICENSE.md:1`). Scope: whole repo, with the code path `pywal/` (colors, export, theme, util, settings, reload, sequences, backends) and packaging (`setup.py`, `MANIFEST.in`). Templates were listed, not read in full.
Id prefix: PW.

## 1. Purpose and shape
- PW1.1 Python package named `pywal`, a fork of pywal targeting pywal 16 (`setup.py`, `pywal/`). It takes a wallpaper image, produces a 16-color palette plus background and foreground, and exports that palette to files and escape sequences (`pywal/colors.py:36-66`, `pywal/export.py:329-345`).
- PW1.2 Entry point: console script `wal` maps to `pywal.__main__:main` (`setup.py:42`).
- PW1.3 Top-level layout:
  - `pywal/colors.py`: palette generation entry (`get`, `:509`), shade and contrast adjustments (`:85-365`), cache naming (`:402`), palette dict (`colors_to_dict`, `:36`).
  - `pywal/backends/`: image-to-palette backends (`wal`, `colorthief`, `colorz`, `haishoku`, `okthief`, `schemer2`, `fast_colorthief`, `modern_colorthief`, `wallust`), listed by `list_backends` (`colors.py:17-23`).
  - `pywal/export.py`: template engine and export loop (`template`, `:212`; `every`, `:329`).
  - `pywal/templates/`: built-in template files (many files, for example `colors.sh`, `colors.json`, `colors.Xresources`, `colors-alacritty.toml`, `colors-rofi-dark.rasi`, `colors.qml`, `colors-vscode.json`).
  - `pywal/theme.py`: theme files (`parse`, `:98`; `file`, `:134`; `save`, `:188`; theme listing `:15-134`).
  - `pywal/reload.py`: per-application reload functions (`tty`, `xrdb`, `i3`, `bspwm`, `kitty`, `polybar`, `sway`, `firefox`, `waybar`, `mako`, `nvim`, `env`; `:15-129`).
  - `pywal/sequences.py`: OSC escape sequences for terminals (`create_sequences`, `:42`; `send`, `:81`).
  - `pywal/settings.py`: directory constants (`:21-25`).
  - `pywal/wallpaper.py`, `pywal/image.py`, `pywal/util.py`, `pywal/__main__.py`.
  - `tests/`, `data/`, `CHANGELOG.md`, `README.md`.

## 2. Theme input (how configuration reaches it)
- PW2.1 Primary input: an image path. `colors.get(img, light, backend, cache_dir, sat, **kwargs)` (`pywal/colors.py:509-516`). The path is normalized by `normalize_img_path` (`:26`).
- PW2.2 Backend selection by name: `get(img, light, backend="wal")`; a missing backend falls back to `wal` (`pywal/colors.py:509-580`, fallback logic in the function body). `wal` is `pywal/backends/wal.py`, and its `get` is at `:139`.
- PW2.3 Keyword options passed through `get`: `c16` (16-color mode: lighten or darken), `cst` (contrast ratio), `sat` (saturation amount). `pywal/colors.py:509-580` (docstring lists `c16`, `cst`), `saturate_colors` (`:260`), `ensure_contrast` (`:270`).
- PW2.4 Light or dark: boolean `light` (CLI flag mapping not read in `__main__.py`).
- PW2.5 Environment variables: `PYWAL_CACHE_DIR` overrides the cache directory (`pywal/settings.py:24`). `XDG_CACHE_HOME` (`:21`) and `XDG_CONFIG_HOME` (`:22`) set the default base directories.
- PW2.6 Config directory: `CONF_DIR = <XDG config>/wal` (`pywal/settings.py:25`). User templates are read from `<CONF_DIR>/templates` (`pywal/export.py:335`).
- PW2.7 Cached palette: `cache_fname` (`pywal/colors.py:402`) builds the path, called inside `get` at `:533` and `:538`. A cached JSON is reused when its `checksum` matches `util.get_img_checksum` (`pywal/colors.py:39`, `util.py:260`); the comparison is in `get` after those calls.

## 3. Color and style model
- PW3.1 Palette dict (`colors_to_dict`, `pywal/colors.py:36-66`) with keys:
  - `checksum`, `wallpaper`, `alpha` (`util.Color.alpha_num`, `:34` in `pywal/util.py`),
  - `special`: `background` = color 0, `foreground` = color 15, `cursor` = color 15,
  - `colors`: `color0` to `color15`.
- PW3.2 Color class: `Color` in `pywal/util.py:31` holds hex strings and an `alpha_num` default of `"100"` (`:34`). `saturate` is at `pywal/util.py:194`.
- PW3.3 Darken: `util.darken_color(color, amount)` (`pywal/util.py:305`) computes `int(col * (1 - amount))` per RGB channel. Used with amount 0.25 in `shade_darken` (`pywal/colors.py:85-102`).
- PW3.4 Lighten: `util.lighten_color(color, amount)` (`pywal/util.py:311`) computes `int(col + (255 - col) * amount)` per channel. Used with amount 0.25 in `shade_lighten` (`pywal/colors.py:104-123`).
- PW3.5 Other shade functions: `shade_foxify_darken` and `shade_foxify_lighten` use `util.foxify_color` (`pywal/util.py:317`) with amount -0.25 (`pywal/colors.py:125-163`), `shade_16` builds 16 colors from a chosen method (`:165`), `generic_adjust` (`:210`), `binary_luminance_adjust` (`:365`).
- PW3.6 Light and dark: the `light` flag selects a different branch in each shade function (for example `if light:` at `pywal/colors.py:88`).
- PW3.7 Per-state colors (hover, pressed, disabled, focus): none found in the read ranges (UNVERIFIED).

## 4. Output and rendering path
- PW4.1 Call chain, in order (`pywal/colors.py` and `pywal/export.py`):
  1. Palette: `colors.get` (`:509`), backend `get` (`pywal/backends/<name>.py`), then `saturate_colors` (`:260`), `ensure_contrast` (`:270`), `colors_to_dict` (`:36`), cache write (`util.save_file_json`).
  2. Export: `export.every(colors, output_dir)` (`pywal/export.py:329`) writes color images (`generate_color_images`, `:310`), flattens the dict (`flatten_colors`, `:257`), and walks the system and user template directories (`:334-340`).
  3. Each template file goes through `template(colors, input_file, output_file)` (`pywal/export.py:212`). Markers are parsed (`parse_marker`, `:130`) and executed against the palette (`execute_marker`, `:180`). Replacement is line by line (`:233-239`).
  4. Brace escape: `{{` and `}}` are turned into `{` and `}` after substitution (`pywal/export.py:251-252`).
  5. Output is saved with `util.save_file` (`pywal/export.py:254`).
- PW4.2 Terminal escape sequences: `sequences.create_sequences(colors, vte_fix)` builds OSC sequences for colors 0-15 and the special colors (`pywal/sequences.py:42-79`). `send(colors, ...)` writes them to the terminal ttys (`:81`).
- PW4.3 Application reload: `reload.env` and related functions in `pywal/reload.py` run the reload commands for each app (for example `xrdb` at `:24`, `i3` at `:33`, `kitty` at `:45`, `polybar` at `:72`, `sway` at `:83`, `waybar` at `:95`, `nvim` at `:123`). The bodies were not read in full (UNVERIFIED for each command).
- PW4.4 `reload.colors` is deprecated and only prints the sequences file (`pywal/reload.py:101-110`, deprecation log at `:105-106`).
- PW4.5 Template files that generate CSS or QML: `pywal/templates/colors-yasb.css`, `colors-nqq.css`, `colors.qml`, `colors-rofi-dark.rasi` and `colors-rofi-light.rasi` (names only; contents not read).

## 5. Extension and integration points
- PW5.1 Backends: any module under `pywal/backends/` (not starting with `__`) is a backend (`list_backends`, `pywal/colors.py:17-23`). Import is dynamic: `__import__("pywal.backends.%s" % backend)` (`pywal/colors.py`, inside `get`). Missing dependencies fall back to `wal` (PW2.2).
- PW5.2 User templates: any file under `<CONF_DIR>/templates` is exported with the same engine as the built-in templates (`pywal/export.py:329-343`).
- PW5.3 Installed template path: `MANIFEST.in:1` (`include pywal/templates/*`) and `include_package_data=True` (`setup.py:69`).
- PW5.4 Cache and output directories are environment-driven (PW2.5).
- PW5.5 Backend dependencies are optional at install time (`pywal/colors.py`, the `ImportError` branch). The packages each backend needs are not listed in `setup.py` (UNVERIFIED; `setup.py` install_requires not read).

## 6. Data and tooling
- PW6.1 Templates: `pywal/templates/` (built-in) and `<CONF_DIR>/templates` (user). Template markers use `{name}` and function forms (`pywal/export.py:36-180`).
- PW6.2 Theme files: `theme.file`, `theme.parse`, `theme.save`, `theme.list_themes` (`pywal/theme.py:15-188`). The theme format is the palette JSON (`theme.py:98-119`; body not read).
- PW6.3 Tests: `tests/` directory (not read).
- PW6.4 Changelog and README: `CHANGELOG.md`, `README.md`.

## 7. Facts of note
- PW7.1 `reload.colors` is marked deprecated in code (`pywal/reload.py:101-106`).
- PW7.2 The cache check compares the stored checksum with the image checksum; a mismatch regenerates the palette (`pywal/colors.py`, inside `get`).
- PW7.3 `ensure_contrast` takes the image path as an argument, so contrast can depend on the image (`pywal/colors.py:270`).
- PW7.4 License MIT (`LICENSE.md:1`), copyright line `LICENSE.md:3`.

## 8. Not covered
- Bodies of most backends (`pywal/backends/*.py` except the `wal` entry at `:139`).
- `pywal/util.py` helpers beyond `Color` (`:31-34`), `darken_color`, `lighten_color`, `foxify_color` (names only).
- `pywal/theme.py` bodies beyond the function headers.
- `pywal/reload.py` command bodies beyond the first lines.
- `setup.py` install_requires and the CLI argument parser (`pywal/__main__.py`).
- Template file contents (names only).
- No build or run was done; `refs/` was not modified.
