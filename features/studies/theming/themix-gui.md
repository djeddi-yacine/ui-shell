# themix-gui: GTK and Python GUI (oomox lineage) for designing color schemes and exporting them through plugins

Source: refs/themix-gui (shallow clone; commit e733949; branch master). License: GPL-3.0 (`LICENSE:1-2`). Scope: `oomox_gui/` (plugin API, loader, theme model, preset file, export runner, color helpers, image import), `plugins/` (theme_materia, import_from_image, and the plugin list), `pyproject.toml`, `.gitmodules`, `README.md`. Submodule contents were not present in the clone (see GT8).
Id prefix: TG.

## 1. Purpose and shape
- TG1.1 A GUI for designing themes (color schemes) and exporting them with plugins, for example Oomox and Materia GTK themes, icon themes, Base16 app templates. `README.md:6-9`. Import plugins include palette generation from an image, Xresources, and Base16 collections. `README.md:11-14`.
- TG1.2 Language: Python, GTK 3 through PyGObject (`from gi.repository import Gtk` in `plugins/theme_materia/oomox_plugin.py:12` under TYPE_CHECKING; `oomox_gui/export_common.py` uses `Gtk.Dialog`, `Gtk.Box`). Package name `oomox_gui`, version `1.15.1`. `pyproject.toml:2-3`. Plugin API version constant `PLUGIN_API_VER = 1.1`. `oomox_gui/plugin_api.py:27`.
- TG1.3 Build and packaging: `pyproject.toml` (ruff, mypy, pylint config), `Makefile`, `po.mk` (translations), `packaging/`, `dockerfiles/`, `gui.sh` (launcher), `multi_export_cli.sh` (CLI export). Makefile and packaging files were not read.
- TG1.4 Top-level layout:
  - `oomox_gui/`: application (about 30 modules). `oomox_gui/main.py`, `oomox_gui/plugin_api.py`, `oomox_gui/plugin_loader.py`, `oomox_gui/theme_model.py`, `oomox_gui/theme_file.py`, `oomox_gui/export_common.py`, `oomox_gui/color.py`, `oomox_gui/preview.py`, `oomox_gui/multi_export.py`, `oomox_gui/config.py`.
  - `plugins/`: one directory per plugin with `oomox_plugin.py`. Names: `theme_materia`, `theme_arc`, `theme_oomox`, `base16`, `export_oomoxify`, `export_xresources`, `import_from_image`, `import_random`, `import_xresources`, `icons_*` (archdroid, gnomecolors, numix, papirus, suruplus, suruplus_aspromauros).
  - `terminal_templates/`: Base16-style template files for terminal and app colors (about 40 names, for example `tempus_*`, `material`, `basic`). Listed by name only.
  - `scripted_colors/`: scripted palette generators (`random`, `xresources`, `xresources2`, `xresources3`, `xresources-reverse`).
  - `colors/`: preset color schemes (not read).
  - `export_config_examples/`: JSON export config examples, for example `multi_export_oomox_classic.json`.
  - `docs_markdown/`: CLI, manual install, and CSS hacks docs (linked from `README.md:24-26`).

## 2. Theme input (how configuration reaches it)
- TG2.1 Config directories: `PLUGINS_DIR` = `<OOMOX_ROOT>/plugins/`, `TERMINAL_TEMPLATE_DIR` = `<OOMOX_ROOT>/terminal_templates/`, `USER_PLUGINS_DIR` = `<USER_CONFIG_DIR>/plugins/`, `USER_PALETTE_PATH` = `<USER_CONFIG_DIR>/recent_palette.json`. `oomox_gui/config.py:19-21,22-24,40-42,43-45`.
- TG2.2 User preset (color scheme) files: one `KEY=value` line per key, written in sorted key order, with `NAME` quoted. Keys beginning with `_` and the key `NOGUI` are skipped on write. `oomox_gui/theme_file.py:101-120` (write loop at `:119`, `NAME` set at `:104`).
- TG2.3 Preset lookup: `get_presets()` groups presets by directory. `oomox_gui/theme_file.py:67-95`. User path: `get_user_theme_path(name)`. `oomox_gui/theme_file.py:97`. Preset import and removal: `oomox_gui/theme_file.py:123-133`.
- TG2.4 Theme value parsing: `parse_theme_value` reads `colorscheme[key]`, applies fallback key, fallback value, or fallback function, then converts by declared type (`bool`, `int`, `float`, `options`). `oomox_gui/theme_file_parser.py:31-56`. Bool parsing: `str_to_bool` (lowercase `true`) at `:27-28`.
- TG2.5 Input sources (import plugins): image palette (`plugins/import_from_image/ima.py:148` `get_hex_palette(image_path, use_whole_palette)`, uses PIL at `ima.py:3`); Xresources (`plugins/import_xresources/`); random (`plugins/import_random/`); presets and user files (see TG2.2-2.3). `README.md:11-14`.
- TG2.6 Theme option model (inputs the user edits): a base list of values with `key`, `type`, `options`, `fallback_key`, `fallback_value`, `fallback_function`. Example entries: `BG` `oomox_gui/theme_model.py:165`, `FG` `:170`, `SEL_BG` `:187`. 37 entries have `"type": "color"` (count from `rg -c`, `oomox_gui/theme_model.py`). `oomox_gui/theme_model.py:17-38` (TypedDicts `Option`, `ThemeModelValue`, `ThemeModelSection`, `ThemeModel`).
- TG2.7 Plugins add their own option sections: the Materia plugin defines `theme_model_gtk` (`plugins/theme_materia/oomox_plugin.py:124`) and `theme_model_options` (`:139`), with keys such as `TXT_BG`, `BTN_BG`, `MATERIA_SELECTION_OPACITY`, `MATERIA_PANEL_OPACITY`, `MATERIA_STYLE_COMPACT` (`:126,132,141,148,155`).
- TG2.8 Merge of base model and plugin models: `merge_model_with_plugin` and `merge_model_with_plugins`, `oomox_gui/theme_model.py:53` and `:94`. Top-level merge filters by `THEME_STYLE` (`:119-126`). Result is cached (`CachedThemeModel`, `oomox_gui/theme_model.py:569-581`).
- TG2.9 Environment and CLI: `gui.sh` (launcher, not read), `multi_export_cli.sh` and `oomox_gui/multi_export_cli.py` (CLI export; not read). Documented in `docs_markdown/CLI.md` (not read).

## 3. Color and style model
- TG3.1 Colors are hex strings (`HexColor`) in the theme dictionary. Conversion to GDK: `convert_theme_color_to_gdk(theme_color) -> Gdk.RGBA`, `oomox_gui/color.py:148-159`. Mixing: `mix_gdk_colors(c1, c2, ratio)` `oomox_gui/color.py:161-172`, `mix_theme_colors(...)` `oomox_gui/color.py:173-`. Mixing formula body was not read (UNVERIFIED).
- TG3.2 Channel helper class with `length = 3` and `RED=0`, `GREEN=1`, `BLUE=2` (`oomox_gui/color.py:12-15`).
- TG3.3 Theme roles are named keys in the preset file (`BG`, `FG`, `SEL_BG`, `TXT_BG`, `BTN_BG`, `HDR_BG`, and terminal `TERMINAL_COLOR*` keys). The full list is in `oomox_gui/theme_model.py` (only `BG`, `FG`, `SEL_BG` lines were read) and in the Materia plugin (`plugins/theme_materia/oomox_plugin.py:124-160`).
- TG3.4 Dark/light: determined by the Materia export script (`change_color.sh` in the submodule, not present, see GT8.1). Not determined in this repo's Python code (no dark/light switch found in the read ranges).
- TG3.5 Per-state colors (hover, pressed, disabled): not read (UNVERIFIED).
- TG3.6 Preview: `oomox_gui/preview.py`, `oomox_gui/preview_icons.py`, `oomox_gui/preview_terminal.py` render previews; plugin hooks `preview_transform_function` and `preview_before_load_callback` (`oomox_gui/plugin_api.py:89-112` for theme plugins, `:132-139` for icon plugins). Bodies not read.

## 4. Output and rendering path
- TG4.1 Plugin contract. Base class `OomoxPlugin(ABC)` with `name`, `display_name`, `export_text` (`oomox_gui/plugin_api.py:30-60`). Subclasses:
  - `OomoxThemePlugin` `oomox_gui/plugin_api.py:62` (has `description`, `gtk_preview_dir`, `export_dialog`, `preview_transform_function`)
  - `OomoxIconsPlugin` `oomox_gui/plugin_api.py:115`
  - `OomoxExportPlugin` `oomox_gui/plugin_api.py:141`
  - `OomoxImportPlugin` `oomox_gui/plugin_api.py:158` (`read_colorscheme_from_path`, `user_theme_dir`)
  - `OomoxImportPluginAsync` `oomox_gui/plugin_api.py:188`
- TG4.2 Version gate: `supported_plugin_api_min = 1.0` and `supported_plugin_api_max = 1.2` (`oomox_gui/plugin_api.py:33-34`). Constructor raises `RuntimeError` if `PLUGIN_API_VER` is outside `[min, max)` (`:35-45`).
- TG4.3 Discovery and load order: `PluginLoader.init_plugins` lists `PLUGINS_DIR` then `USER_PLUGINS_DIR` (`oomox_gui/plugin_loader.py:75-82`, dirs from `oomox_gui/config.py:19-42`). Each directory is loaded by `load_plugin(name, path)` (`oomox_gui/plugin_loader.py:55-73`), which imports `oomox_plugin.py` and reads its `Plugin` class (`:56-60`). A plugin is registered in `_ALL_PLUGINS` and in one registry per type by `issubclass` checks (`:64-72`). Load errors are caught and reported (`:88` onward).
- TG4.4 Plugin class convention: each `oomox_plugin.py` defines a class named `Plugin` (for example `plugins/theme_materia/oomox_plugin.py:91`, `class Plugin(OomoxThemePlugin)`). `load_plugin` reads `plugin_module.Plugin` (`oomox_gui/plugin_loader.py:58`).
- TG4.5 Materia export call chain (in order):
  1. The export dialog collects options (`MateriaThemeExportDialog`, `plugins/theme_materia/oomox_plugin.py:22-26`).
  2. The current colors are saved to a temp preset file by `save_colorscheme` (`oomox_gui/export_common.py:354`, `oomox_gui/theme_file.py:101-120`).
  3. `do_export` builds the command `bash <THEME_DIR>/change_color.sh --hidpi <bool> --target <dir> --output <name> <temp file>` (`plugins/theme_materia/oomox_plugin.py:27-38`), where `THEME_DIR` is `plugins/theme_materia/materia-theme/` (`:18-19`).
  4. The command is run with `subprocess.Popen` and stdout captured in a thread (`oomox_gui/export_common.py:318-330`).
  5. The temp file is removed after export (`oomox_gui/export_common.py:361-362`).
- TG4.6 Theme output is produced by the external script in the Materia submodule. The GTK2, GTK3 and other outputs are described in the Materia study (`features/studies/theming/materia-theme.md`) and are not restated here.
- TG4.7 Icon output: icon plugins use SVG templates and `preview_transform_function(svg_template, colorscheme)` (`oomox_gui/plugin_api.py:132`). Icon plugin files are submodules (see GT8.2).
- TG4.8 Base16 output: `terminal_templates/*` files are templates rendered by the Base16 plugin (`plugins/base16` is a submodule, not present). Rendering function not read (UNVERIFIED).
- TG4.9 GTK preview CSS: `plugins/theme_materia/gtk_preview_css/theme.css` and `checkbox-checked.svg.template` are present in the clone. Their use is in `gtk_preview_dir` (`oomox_gui/plugin_api.py:71`), not traced.

## 5. Extension and integration points
- TG5.1 User plugins: any directory under `USER_PLUGINS_DIR` with an `oomox_plugin.py` is loaded. `oomox_gui/config.py:40-42`, `oomox_gui/plugin_loader.py:75-82`.
- TG5.2 Plugin base classes to subclass: see TG4.1.
- TG5.3 Plugin API version coupling: the constant is `PLUGIN_API_VER = 1.1` (`oomox_gui/plugin_api.py:27`), and plugins declare supported ranges (min 1.0, max 1.2 by default, `oomox_gui/plugin_api.py:33-34`).
- TG5.4 Export delegation: theme plugins invoke external shell scripts (Materia: `change_color.sh`, TG4.5). No GObject registration macro is used.
- TG5.5 Submodule-based plugins: `.gitmodules` declares 12 submodules, including `plugins/theme_materia/materia-theme` (`https://github.com/nana-4/materia-theme.git`), `plugins/icons_archdroid/archdroid-icon-theme`, and others. Full list not printed in this study.
- TG5.6 Installation paths: not read (packaging files not read).
- TG5.7 Python and GTK coupling: PyGObject with GTK 3 classes (`Gtk.Dialog`, `Gtk.Box`, `oomox_gui/export_common.py:58-62`). Minimum versions not found in read ranges (UNVERIFIED).

## 6. Data and tooling
- TG6.1 Preset format: `KEY=value` text (TG2.2). Examples in `colors/` and `export_config_examples/` (not read).
- TG6.2 Templates: `terminal_templates/` (Base16-style), `plugins/theme_materia/gtk_preview_css/` (preview CSS and SVG template).
- TG6.3 Scripts: `scripted_colors/*` (palette generators), `gui.sh`, `multi_export_cli.sh`, `maintenance_scripts/` (not read).
- TG6.4 Tests: none found in the read ranges (not searched exhaustively).
- TG6.5 Lint and type config: `pyproject.toml:6-170` (autopep8, mypy, ruff, pylint sections).
- TG6.6 Translations: `po/*.po` (fr, pt_PT, nl_NL, es, it, pt_BR) and `po.mk`. `oomox_gui/i18n.py` (not read).
- TG6.7 Docs: `docs_markdown/` (CLI, manual install, CSS hacks), `README.md`.

## 7. Facts of note
- TG7.1 Plugin load errors are caught and shown per plugin, the loader does not stop. `oomox_gui/plugin_loader.py:87-88` (`except Exception as exc`, line 88).
- TG7.2 The Materia plugin's `do_export` hard-codes `bash` as the interpreter. `plugins/theme_materia/oomox_plugin.py:31`.
- TG7.3 The preset writer skips keys starting with `_` and the `NOGUI` key. `oomox_gui/theme_file.py:110-117`.
- TG7.4 The image import uses PIL (`plugins/import_from_image/ima.py:3`). Other image libraries not listed.
- TG7.5 The README describes the project as a successor of Oomox (`README.md:6-7`) and links to the Oomox theme repository.
- TG7.6 Several plugin directories are empty in this clone because their git submodules are not checked out (see GT8).

## 8. Not covered
- GT8.1 Submodule not checked out: `plugins/theme_materia/materia-theme/` (empty directory). The script `change_color.sh` and the Materia GTK sources are not in this clone. The Materia study (`features/studies/theming/materia-theme.md`) covers the upstream repo.
- GT8.2 Other submodule directories are empty in this clone: `plugins/base16/`, `plugins/theme_oomox/`, and icon submodules (for example `plugins/icons_archdroid/archdroid-icon-theme`). Their `oomox_plugin.py` files are not present, so their plugin classes were not read.
- The `oomox_gui` modules not read in detail: `main.py`, `preview.py`, `multi_export.py`, `theme_model.py` (beyond the listed lines), `color.py` (mix bodies), `settings.py`, `migrations.py`, `shortcuts.py`.
- `plugins/theme_arc/oomox_plugin.py` (read only by name in the listing).
- `scripted_colors/*`, `terminal_templates/*`, `colors/*`, `export_config_examples/*` (listed only).
- `Makefile`, `packaging/`, `dockerfiles/`, `gui.sh`, `multi_export_cli.sh`, `maintenance_scripts/`, `docs_markdown/*`.
- No build or run was done; `refs/` was not modified.
