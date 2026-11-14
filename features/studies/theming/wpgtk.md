# wpgtk: Python GTK and CLI manager that wraps pywal, generates color schemes, and rewrites user template files

Source: refs/wpgtk (shallow clone; commit 42853aa; branch master). License: GPL-2.0 (`LICENSE:1-2`; README badge `README.md:5`). Scope: whole repo (`wpgtk/` package, `wpgtk/misc/`, `completions/`, `pyproject.toml`, `README.md`). The GUI modules (`wpgtk/gui/*`) were listed but not read.
Id prefix: WG.

## 1. Purpose and shape
- WG1.1 A color-scheme manager that uses pywal as its color generator, with a GUI, a template system, and presets. `README.md:13,15,17`. Describes itself as "GTK+ theme/wallpaper manager which uses pywal as its core". `pyproject.toml:20`.
- WG1.2 Language: Python. Requires Python >= 3.5. `pyproject.toml:14`. Depends on `pywal>=3.3.0`. `pyproject.toml:17`. Build: setuptools (`pyproject.toml:2`), version read from `wpgtk.data.config.__version__` (`pyproject.toml:6`).
- WG1.3 Targets: GTK 3 (through `gsettings` and `settings.ini`), xsettings (xfconf and xsettingsd), and many desktop components (xrdb, tint2, polybar, waybar, dunst, openbox, i3, kitty, sway). `wpgtk/data/reload.py:13-137`. The GUI is GTK (`wpgtk/gui/`, not read).
- WG1.4 Top-level layout:
  - `wpgtk/__main__.py`: CLI entry point (not read).
  - `wpgtk/data/`: core logic. `color.py` (palette math, template rewrite), `config.py` (paths and settings), `files.py` (file and template management), `keywords.py` (keyword sections), `reload.py` (desktop reload calls), `themer.py` (theme create, set, delete, import, export), `util.py` (HLS math, subprocess helpers), `sample.py`.
  - `wpgtk/gui/`: GTK windows and widgets (`theme_picker.py`, `color_grid.py`, `keyword_grid.py`, `template_grid.py`, `option_grid.py`, `color_picker.py`, `keyword_dialog.py`, `util.py`). Not read.
  - `wpgtk/misc/`: default `wpg.conf`, `wpgtk.desktop`, `wpg-install.sh`.
  - `completions/bash/wpg`, `completions/zsh/_wpg`: shell completion.
  - `MANIFEST.in`, `pyproject.toml`: packaging.

## 2. Theme input (how configuration reaches it)
- WG2.1 Base paths (XDG-aware): `CACHE` from `XDG_CACHE_HOME` or `~/.cache` (`wpgtk/data/config.py:12`); `CONFIG` from `XDG_CONFIG_HOME` or `~/.config` (`:13`); `WPG_DIR = <CONFIG>/wpg` (`:16`); `WALL_DIR = <WPG_DIR>/wallpapers` (`:21`); `FORMAT_DIR = <CACHE>/wal` (`:24`); `OPT_DIR = <WPG_DIR>/templates` (`:25`).
- WG2.2 Settings file: INI format, section `[settings]`, parsed into a `settings` object in `wpgtk/data/config.py` (parse code not read). The shipped default is `wpgtk/misc/wpg.conf`. Keys in `[settings]` (`wpg.conf:1-14`):
  - `set_wallpaper` (`:2`), `gtk` (`:3`, controls GTK3 reload, see WG4.5), `active` (`:4`, index into pywal color list; `0` or below means random 9-14, see WG4.3), `light_theme` (`:5`), `editor` (`:6`), `execute_cmd` and `command` (`:7-8`), `backend` (`:9`, default `wal`), `alpha` (`:10`), `smart_sort` (`:11`), `auto_adjust` (`:12`), `reload` (`:13`), `terminal` (`:14`).
  - `[keywords]` section (`wpg.conf:16`): keyword-to-color mapping. Managed by `wpgtk/data/keywords.py`.
- WG2.3 Pywal input: `get_pywal_dict(wallpaper, is_file)` (`wpgtk/data/color.py:19-`) reads `light_theme` and `alpha` from settings (`:21-22`) and asks pywal for the palette. The pywal call body was not read beyond `:22`.
- WG2.4 Keyword configuration: `keywords.py` functions `create_keywords_section`, `update_value`, `create_pair`, `remove_pair` (`wpgtk/data/keywords.py:13,41,52,66`), which edit the `[keywords]` section per theme.
- WG2.5 Template input: files named `<name>.base` in `OPT_DIR` (`wpgtk/data/color.py:180`, `wpgtk/data/files.py:73-96`). A template is any text file the user adds (`add_template`, symlink created at `wpgtk/data/files.py:90`).
- WG2.6 Environment: `XDG_CACHE_HOME`, `XDG_CONFIG_HOME` (`wpgtk/data/config.py:12-13`).
- WG2.7 Color-scheme files: JSON from pywal or a user colorscheme (`get_color_list(filename, json=False)`, `wpgtk/data/color.py:34`; `import_theme(wallpaper, json_file, theme)`, `wpgtk/data/themer.py:83`).

## 3. Color and style model
- WG3.1 A color scheme is an ordered list of 16 hex colors (pywal's color0 to color15). `shuffle_colors` assumes indices 0-7 for background and 8-15 for foreground. `wpgtk/data/color.py:68-77`.
- WG3.2 Light or dark decision: `is_dark_theme(color_list)` returns true when the lightness of `color_list[7]` (foreground) is greater than the lightness of `color_list[0]` (background), using `util.get_hls_val(..., "light")`. `wpgtk/data/color.py:59-65`.
- WG3.3 HLS helpers in `wpgtk/data/util.py`: `get_distance` (`:9`), `get_hls_val` (`:17`), `set_hls_val` (`:25`), `hex_to_hls` (`:35`), `hls_to_hex` (`:41`), `alter_brightness(hex, amount, sat)` (`:50-56`). The formula in `alter_brightness`: lightness `l = max(min(l + amount, 255), 1)`, and saturation `s = min(max(s - sat, -1), 0)`. `wpgtk/data/util.py:50-56`. The HLS scale (0-255) is not verified in this study.
- WG3.4 Keyword colors (active, inactive, front, back, glyph): `keyword_colors(hexc, is_dark_theme)` `wpgtk/data/color.py:220-237`:
  - dark theme: active = lightness * -0.20 applied to the color; inactive = lightness * -0.45. `:225-229`
  - light theme: active = lightness * 0.30; inactive = the color itself. `:225-229`
  - `newfront` = active, `newback` = inactive, `newglyph` = inactive with brightness -15. `:230-236`
- WG3.5 Color dictionary assembly: `get_color_dict(pywal_colors, colorscheme)` (`wpgtk/data/color.py:240-`) reads the `keyword_set` from settings, picks the base color index (`active`), and builds a dictionary of keyword to color. Body partly read (`:240-247`).
- WG3.6 Smart sort and auto-adjust: `smart_sort(colors)` (`wpgtk/data/color.py:114`), `auto_adjust(colors)` (`:152`). Bodies not read.
- WG3.7 Icon colors: `add_icon_colors(colors)` (`wpgtk/data/color.py:194`), regex `(.*)=(.*)$` at `:197` on a color-file line. Body not read.
- WG3.8 Per-state colors (hover, pressed, disabled): not found in the read ranges. The "active" and "inactive" pair (WG3.4) is the only state split found.

## 4. Output and rendering path
- WG4.1 Output is text files written from `.base` templates. The keyword dictionary is substituted with Python `str.format_map`. `wpgtk/data/color.py:95-101` (`tmp_data.format_map(colors)`); write to the target at `:103-105`.
- WG4.2 Template skip rule: a `.base` whose first line contains `wpgtk-ignore` is not rewritten. `wpgtk/data/color.py:98-99`.
- WG4.3 Error handling in template write: a missing key is logged (`KeyError`, `:107-108`), a missing base file is logged (`IOError`, `:110-111`).
- WG4.4 Template rewrite driver `change_templates(colors)`: lists `OPT_DIR` files matching `.*\.base$` (`wpgtk/data/color.py:177-192`, list at `:180`), starts one thread per template calling `change_colors` (`:186`).
- WG4.5 Call chain from a wallpaper to applied theme (in order):
  1. Palette from pywal, read by `get_pywal_dict` (`wpgtk/data/color.py:19`).
  2. Keyword colors built from the palette (`get_color_dict`, `wpgtk/data/color.py:240`; `keyword_colors`, `:220`).
  3. `apply_colorscheme(color_dict)` (`wpgtk/data/color.py:275-`): runs an icon step if `FILE_DIC["icon-step2"]` exists, then calls `change_templates(color_dict)` (`:277-283`).
  4. Each `.base` template is rewritten to its target (WG4.1).
  5. Reload of desktop components: `reload.all()` (`wpgtk/data/reload.py:138-`) calls `xrdb`, `tint2`, `dunst`, `openbox`, `i3`, `kitty`, `sway`, `polybar`, `waybar`, and `gtk3` when `settings.gtk` is true (`:138-150`).
- WG4.6 GTK 3 reload (`wpgtk/data/reload.py:69-137`): reads `<CONFIG>/gtk-3.0/settings.ini` (`:70`), refreshes the GTK theme through `gsettings set org.gnome.desktop.interface gtk-theme` (`:73-75`) and through `xfconf-query -c xsettings -p /Net/ThemeName` (`:79-81`), with a 0.1 second pause between the blank and the new value.
- WG4.7 xsettingsd reload (`wpgtk/data/reload.py:54-67`): writes a temp file containing `Net/ThemeName "<theme>"` and calls `timeout 0.2s xsettingsd -c <tmp>` (`:58-64`).
- WG4.8 Xrdb, tint2, polybar, waybar, dunst, openbox reloads: `wpgtk/data/reload.py:13-48`. Bodies not read.

## 5. Extension and integration points
- WG5.1 User templates: any `<file>.base` in `<CONFIG>/wpg/templates`, written to its target name with `.base` removed. `wpgtk/data/color.py:177-192`, `wpgtk/data/files.py:73-96`.
- WG5.2 Template placeholders are Python format fields (`{name}`), keys from the keyword dictionary (`wpgtk/data/color.py:101`).
- WG5.3 Pywal backend: `backend = wal` in settings (`wpg.conf:9`); other backends are not described in the read code.
- WG5.4 Reload hooks: `settings.reload` and `settings.gtk` gate the reload calls (`wpgtk/data/reload.py:138-150`). `wpg.conf:3,13`.
- WG5.5 Command hook: `execute_cmd` and `command` (`wpg.conf:7-8`). Use in code not read (UNVERIFIED).
- WG5.6 Editor hook: `editor` setting (`wpg.conf:6`). Use in code not read.
- WG5.7 Icon step hook: `FILE_DIC["icon-step2"]`, run with `Popen` when the file exists (`wpgtk/data/color.py:277-279`). Mechanism and file location not read (UNVERIFIED).
- WG5.8 Package install: `wpgtk/misc/wpg-install.sh`, `wpgtk/misc/wpgtk.desktop` (not read).

## 6. Data and tooling
- WG6.1 Config and template store: `<CONFIG>/wpg/` (`wpgtk/data/config.py:16`), wallpapers (`:21`), templates (`:25`), cache (`:24`).
- WG6.2 Shipped default config: `wpgtk/misc/wpg.conf` (`:1-16`).
- WG6.3 Shell completion: `completions/bash/wpg`, `completions/zsh/_wpg` (not read).
- WG6.4 Logging: `setup_log()` in `wpgtk/data/util.py:59` (body not read).
- WG6.5 Subprocess helpers: `silent_call` (`wpgtk/data/util.py:70`), `silent_Popen` (`:75`), `get_pid` (`:80`).
- WG6.6 Tests: none found in the file list (not searched exhaustively).
- WG6.7 Docs: `README.md`; the wiki is referenced (`README.md:19-22`) and not in the repo.

## 7. Facts of note
- WG7.1 README warns users updating from versions older than 6.0.0 must update their templates to the new format. `README.md:24`.
- WG7.2 A template with `wpgtk-ignore` on its first line is skipped (WG4.2).
- WG7.3 Missing template keys are logged and the file is not written (WG4.3). `wpgtk/data/color.py:107-108`.
- WG7.4 Template rewrite runs one thread per template (`wpgtk/data/color.py:186`).
- WG7.5 The `active` setting value 0 or less selects a random color from index 9 to 14 (`wpgtk/data/color.py:243-244`, expression `randint(9, 14)` at line 244). Default `active = 0` (`wpg.conf:4`).
- WG7.6 README says wpgtk ships the presets that pywal ships (`README.md:17`).

## 8. Not covered
- `wpgtk/gui/*` (GUI modules) were listed, not read.
- `wpgtk/data/themer.py` bodies (`set_theme`, `create_theme`, `import_theme`, `export_theme`) were listed by name only.
- `wpgtk/data/sample.py`, `wpgtk/data/config.py` settings parser, `wpgtk/data/files.py` bodies beyond `add_template`, and `wpgtk/data/reload.py` bodies for i3, kitty, sway, tint2, polybar, waybar, dunst, openbox, xrdb.
- `get_pywal_dict` body beyond line 22, `smart_sort`, `auto_adjust`, `add_icon_colors` bodies.
- `wpgtk/misc/*` and `completions/*` contents.
- No build or run was done; `refs/` was not modified.
