# Gradience: GTK and GNOME Shell theme generator from named presets or an image palette

Source: refs/Gradience (shallow clone; commit f965109; branch main). License: GPL-3.0 (`LICENSE:1`, GNU General Public License text). Upstream status: archived as of June 29, 2024 (`README.md:1-2`); a maintainer is sought (`README.md:4-5`). Scope: `gradience/backend/` (theming, models, globals, utils), `gradience/frontend/struct.md` (directory map only), `data/presets/`, `data/shell/templates/`, `README.md`, `meson.build`.
Id prefix: GR.

## 1. Purpose and shape
- GR1.1 Tagline: "Change the look of Adwaita, with ease" (`README.md:14`). The backend writes GTK 3 and GTK 4 `gtk.css` overrides and a GNOME Shell user theme from named presets (`gradience/backend/theming/preset.py:115-139`, `gradience/backend/theming/shell.py:134-150`).
- GR1.2 Language: Python. The backend imports GTK/GLib through `gi` (`gradience/backend/theming/shell.py`, `Gio.Cancellable` at `:56`). Build: Meson (`meson.build`). Dependency list file `requirements.txt` was not read (UNVERIFIED for its contents).
- GR1.3 Frontend directory map, as stated in `gradience/frontend/struct.md:3-8`: `cli/` (CLI over backend functions), `dialogs/`, `schemas/` (color view schemas for option rows), `utils/`, `views/` (widget groups, lists, windows), `widgets/` (custom Adw rows).
- GR1.4 Top-level layout (backend and data):
  - `gradience/backend/theming/preset.py`: GTK apply, restore and reset (`PresetUtils`, `:40`).
  - `gradience/backend/theming/monet.py`: palette from an image (`Monet`, `:35`).
  - `gradience/backend/theming/shell.py`: GNOME Shell theme build and apply (`ShellTheme`, `:40` region; `__init__` at `:55`).
  - `gradience/backend/utils/theming.py`: GTK CSS text generation (`generate_gtk_css`, `:22`).
  - `gradience/backend/models/preset.py`: `Preset` model and JSON I/O (`class Preset`, `:104`).
  - `gradience/backend/globals.py`: directory helpers (`get_gtk_theme_dir`, `:88`; `is_sandboxed`, `:97`).
  - `data/presets/`: `adwaita.json`, `adwaita-dark.json`, `pretty-purple.json`.
  - `data/shell/templates/42/`, `43/`, `44/`: GNOME Shell template sets per shell version.
  - `HACKING.md`, `CHANGELOG.md`, `ROADMAP.md`, `local.sh` at the repo root (names confirmed; contents not read).

## 2. Theme input (how configuration reaches it)
- GR2.1 Preset file: JSON with `name` and `variables` (`data/presets/adwaita.json:2-3`; `"name": "Adwaita"` at `:2`, `"variables"` at `:3`, `"accent_color": "#1c71d8"` at `:4`). The file is 115 lines. `Preset.new` accepts `variables`, `display_name`, `palette`, `custom_css` and `badges` (`gradience/backend/models/preset.py:122`). The JSON load path is `__load_values` (`:176`; body not read).
- GR2.2 Preset constructors and I/O in `gradience/backend/models/preset.py`: `new` (`:122`), `new_from_path` (`:137`), `new_from_resource` (`:158`), `new_from_dict` (`:171`), `get_preset_json` (`:207`), `save_to_file` (`:221`), `validate` (`:252`, with `TODO: Add validation` at `:251`).
- GR2.3 Image input for a generated palette: `Monet.generate_palette_from_image(image_path)` (`gradience/backend/theming/monet.py:38`). SVG input is rendered to PNG through `svg2rlg` and `renderPM.drawToFile` into `$XDG_RUNTIME_DIR/gradience_bg.png` (`monet.py:39-44`). XML input raises `ValueError` (`monet.py:46-48`). The image is resized to 64 pixels wide with LANCZOS (`monet.py:56-62`).
- GR2.4 Palette source: `monet.themeFromImage(monet_img)` (`gradience/backend/theming/monet.py:64`). The `monet` package is not in the repo (UNVERIFIED which package provides it).
- GR2.5 Preset built from a Monet palette: `Monet.new_preset_from_monet` (`gradience/backend/theming/monet.py:68`; body not read).
- GR2.6 Repository presets: `PresetUtils.get_presets_list(repo, full_list)` (`gradience/backend/theming/preset.py:48`; body to `:114` covers built-in and repo presets; details not read).
- GR2.7 Shell version: `ShellTheme.__init__(shell_version=None)` (`gradience/backend/theming/shell.py:55`). When no version is passed, `_detect_shell_version` is called (`:58-59`, function at `:265`). The template directory name is the version (`data/shell/templates/42|43|44`).
- GR2.8 Paths: `get_gtk_theme_dir(app_type)` (`gradience/backend/globals.py:88-95`) maps `gtk4` to `<user_config_dir>/gtk-4.0` and `gtk3` to `<user_config_dir>/gtk-3.0`.
- GR2.9 Settings keys: GTK theme name via `org.gnome.desktop.interface` (`gradience/backend/theming/preset.py:41`, schema ID constant `THEME_GSETTINGS_SCHEMA_ID`). GNOME Shell user theme via schema `org.gnome.shell.extensions.user-theme`, path `/org/gnome/shell/extensions/user-theme/`, key `name` (`gradience/backend/theming/shell.py:66-68`).

## 3. Color and style model
- GR3.1 Data model: `variables` (named colors) and `palette` (a dict of dicts). `generate_gtk_css` writes both as `@define-color` lines; palette names are the outer key concatenated with the inner key (`gradience/backend/utils/theming.py:39-40` for variables, `:42-44` for palette).
- GR3.2 `window_bg_color` is read by name and used for the sidebar rule (`gradience/backend/utils/theming.py:48-50`). The full variable list is in `data/presets/adwaita.json` (not enumerated here).
- GR3.3 Shell colors: `_create_theme` converts variables and palette to plain color values with `color_vars_to_color_code` (`gradience/backend/theming/shell.py:146-148`; function body not read).
- GR3.4 Shell template placeholders use `{{name}}`, matched by the regex `{{(.*?)}}` (`gradience/backend/theming/shell.py:167`). Example: `data/shell/templates/44/colors.template:8` is `$_dark_base_color: darken(desaturate({{bg_color}}, 2%), 2%);`. Lines 11-12 and 15 use `if($variant == 'light', ...)` to pick light or dark values. Line 2 of the file says the block "gets @if-ed depending on $variant".
- GR3.5 Light and dark: the shell path takes `theme_variant` in `("light", "dark")` (`gradience/backend/theming/shell.py:135-136`) and the template switches on `$variant` (`colors.template:11`). The GTK path has no variant switch in the code read (UNVERIFIED for GTK-side dark logic).
- GR3.6 Per-state colors (hover, pressed, disabled, focus, backdrop): not found in the ranges read (UNVERIFIED).

## 4. Output and rendering path
- GR4.1 GTK output: `gtk.css` in `<user config>/gtk-3.0/` or `<user config>/gtk-4.0/` (`gradience/backend/globals.py:88-95`).
- GR4.2 GTK call chain, in order (`apply_preset`, `gradience/backend/theming/preset.py:115`):
  1. Theme directory: `get_gtk_theme_dir(app_type)` (`:116`).
  2. For `gtk3`, `set_gtk3_theme()` sets GTK theme `adw-gtk3` through GSettings (`:119-120`; body `:43-46`; sandboxed GSettings class at `:44`).
  3. If `gtk.css` exists, it is read (`:126`) and copied to `gtk.css.bak` (`:132-134`). A missing file logs a warning (`:130`).
  4. `generate_gtk_css(app_type, preset)` output is written to `gtk.css` (`:136-138`).
- GR4.3 Generated file content (`gradience/backend/utils/theming.py:22-50`): a header comment (`:27-35`), one `@define-color` per variable (`:39-40`), one `@define-color` per palette entry (`:42-44`), the `custom_css` entry for the app type (`:46`), and a `.navigation-sidebar { background-color: <window_bg_color>; }` rule (`:48-50`).
- GR4.4 Restore and reset: `restore_preset(app_type)` (`gradience/backend/theming/preset.py:140`, reads the `.bak` file at `:145`) and `reset_preset(app_type)` (`:156`). Bodies beyond the first lines were not read.
- GR4.5 Shell call chain, in order:
  1. `apply_theme_async` (`gradience/backend/theming/shell.py:113`) runs `_apply_theme_thread` (`:122`), which calls `apply_theme(parent, theme_variant, preset)` (`:134`).
  2. `_create_theme` converts the preset (`:146`).
  3. `_insert_variables` fills the template set using the `{{...}}` regex (`:165-167`).
  4. `_compile_sass` compiles Sass to CSS (`:216`).
  5. `_recolor_assets` recolors SVG assets (`:227`).
  6. `_set_shell_theme` resets the `name` key (`:256`), then sets `gradience-shell` through the sandboxed GSettings branch (`:258-260`) or the normal branch (`:263`).
- GR4.6 Shell reset: `reset_theme_async` (`gradience/backend/theming/shell.py:281`), `reset_theme` (`:287`), `_reset_theme_thread` (`:293`).
- GR4.7 Shell output directory: `~/.local/share/themes/gradience-shell/gnome-shell` (`gradience/backend/theming/shell.py:96`). Working copies of the templates are placed under `~/.cache/gradience/gradience-shell/<version>` (`:84`).
- GR4.8 Template files per shell version: `data/shell/templates/44/` contains `check-box.template`, `colors.template`, `gnome-shell.template`, `palette.template`, `panel.template`, `switches.template`. The 42 and 43 sets were listed but not read (UNVERIFIED for their contents).

## 5. Extension and integration points
- GR5.1 Presets from repositories: `gradience/backend/preset_downloader.py` and `gradience/backend/models/repo.py` (named in the code path; not read).
- GR5.2 Plugins: `gradience/frontend/views/plugins_list.py` and `plugin_row.py` exist (names only; plugin model not read, UNVERIFIED).
- GR5.3 Installed paths: GTK CSS in the user config directories (GR2.8); the GNOME Shell theme under `~/.local/share/themes/gradience-shell` (GR4.7), selected by the user-theme `name` key (GR2.9).
- GR5.4 Shell-version coupling: template directories `42`, `43`, `44`, selected by `_detect_shell_version` (`shell.py:265`).
- GR5.5 Flatpak coupling: `is_sandboxed()` (`gradience/backend/globals.py:97`) chooses `FlatpakGSettings` in `preset.py:44` and the sandboxed key write in `shell.py:258`.
- GR5.6 CLI: `gradience/frontend/cli/` wraps the backend (file `cli.in` exists; not read).

## 6. Data and tooling
- GR6.1 Presets: `data/presets/adwaita.json`, `adwaita-dark.json`, `pretty-purple.json`.
- GR6.2 Shell templates: `data/shell/templates/42|43|44/`.
- GR6.3 Docs: `README.md`, `HACKING.md`, `CHANGELOG.md`, `ROADMAP.md`, `gradience/frontend/struct.md`.
- GR6.4 Build: `meson.build` and the `po/` translations directory (`po/*.po` present; `.pot` not checked).
- GR6.5 Tests: none checked (UNVERIFIED).

## 7. Facts of note
- GR7.1 Archived as of June 29, 2024 (`README.md:1-2`).
- GR7.2 The Monet path rejects XML input with a `TODO` about a custom exception (`gradience/backend/theming/monet.py:47-48`).
- GR7.3 Each GTK apply overwrites `gtk.css.bak` with the previous `gtk.css` when that file exists (`gradience/backend/theming/preset.py:132`, mode `"w"`).
- GR7.4 Logging calls in several places pass `exc=` to `logging.error` (for example `gradience/backend/theming/monet.py:53` and `gradience/backend/theming/shell.py:221`). The standard `logging` API does not take that keyword; run-time behaviour was not traced (UNVERIFIED).
- GR7.5 GTK 3 output sets the GTK theme to `adw-gtk3` (`gradience/backend/theming/preset.py:46`). See the adw-gtk3 study (`features/studies/theming/adw-gtk3.md`).
- GR7.6 `Preset.validate` has a `TODO: Add validation` (`gradience/backend/models/preset.py:251`).

## 8. Not covered
- `gradience/frontend/` views, widgets and dialogs (only the directory map in `struct.md` was read).
- `gradience/backend/preset_downloader.py`, `gradience/backend/models/repo.py`, `gradience/backend/exceptions.py`.
- Bodies of `Preset.__load_values`, `Preset.validate`, `restore_preset`, `reset_preset`, `color_vars_to_color_code`, `_recolor_assets`, `_compile_sass`, `_detect_shell_version`, `Monet.new_preset_from_monet`.
- The `monet` Python package and `requirements.txt`.
- Shell template contents beyond the lines cited in GR3.4; the 42 and 43 template sets.
- `data/style.css`, `data/*.gschema.xml.in`, `po/`, `build-aux/`.
- No build or run was done; `refs/` was not modified.
