# materia-theme: Material Design GTK2/3/4 and shell theme, Sass templates plus a preset-driven recolor script

Source: refs/materia-theme (shallow clone; commit d7f59a3; branch master). License: GPL-2.0 (COPYING), project metadata says GPLv2+ (`meson.build:4`). Scope: root `meson.build`, `meson_options.txt`, `change_color.sh`, `scripts/mix.sh`, `src/_theme.scss`, `src/_theme-color.template.scss`, `src/_theme-color.scss`, `src/_color-palette.scss`, `src/gtk-2.0/`, `src/gtk-3.0/` (meson and sass entry, `_public-colors.scss`), `src/gtk-4.0/` (meson and sass entry). GNOME Shell, Chrome, Cinnamon, Metacity, Unity, Xfwm, Plank were not studied.
Id prefix: MA.

## 1. Purpose and shape
- MA1.1 Materia is a Material Design theme for GNOME/GTK desktops. It supports GTK 2, GTK 3, GTK 4 and several other shells. `README.md:5,7`
- MA1.2 Language and build: Meson (`meson.build:1-7`, version string `20210322`, `meson.build:3`), Sass (dart-sass >= 1.23.0, with npm fallback), and a Bash recolor script (`change_color.sh`). `meson.build:20-34`, `change_color.sh:1`
- MA1.3 Top-level layout:
  - `src/_color-palette.scss`: Material palette (`$red-50` ...). `src/_color-palette.scss:1-5`
  - `src/_theme.scss`: shared sizes, radii, durations, flags. `src/_theme.scss:1-40`
  - `src/_theme-color.template.scss` and `src/_theme-color.scss`: color roles with `%TOKEN%` placeholders (template) and the resolved roles (committed file). `src/_theme-color.template.scss:61-65`, `src/_theme-color.scss:61-65`
  - `src/_shadow.scss`: shadow mixins (not read).
  - `src/gtk-2.0/`: `gtkrc-light`, `gtkrc-dark`, `main.rc`, `apps.rc`, `hacks.rc`, `main.rc.hidpi`, `assets.txt`, `render-asset.sh`, `render-assets.sh`, `meson.build`.
  - `src/gtk-3.0/`: `gtk.scss.in`, `gtk-dark.scss.in`, `sass/_common.scss`, `sass/_drawing.scss`, `sass/_public-colors.scss`, `sass/apps/_*.scss` (per-app partials), `assets/`, `icons/`, `meson.build`, `render-assets.sh`.
  - `src/gtk-4.0/`: `gtk.scss.in`, `gtk-dark.scss.in`, `sass/_common.scss`, `sass/_drawing.scss`, `sass/_gtk.scss`, `meson.build`.
  - `src/index.theme.in`: index template. `src/meson.build:5-9`
  - `scripts/mix.sh`, `scripts/darker.sh`: color helper scripts used by `change_color.sh`. `change_color.sh:8-13`
- MA1.4 Build matrix: options `colors` (default, light, dark), `sizes` (default, compact), and `theme_name` (default `Materia`). `meson_options.txt:1-20`. The root loops over colors x sizes and emits theme records. `meson.build:36-56`

## 2. Theme input (how configuration reaches it)
- MA2.1 Meson options (`meson_options.txt`): `theme_name` (string, `Materia`) at lines 1-6; `colors` (array: default, light, dark) at lines 8-13; `sizes` (array: default, compact) at lines 15-20; `gnome_shell_version` at 22-26; `gtk4_version` at 28-.
- MA2.2 Meson-to-Sass mapping per theme: `scss_dark_theme` is `true` only for `color == 'dark'`; `scss_light_topbar` is `true` only for `light`; `scss_compact` is `true` for `compact`. `meson.build:42-44`. These values are injected into Sass through `configure_file` (see MA4.2).
- MA2.3 Preset input for the recolor script: `change_color.sh THEME` loads a shell file with variables. The name is resolved as `$SRC_PATH/../colors/$THEME` (the colors directory is outside this repo) or as a path if it contains `/` or `.`. `change_color.sh:101-111`. Usage text gives the preset keys: `ROUNDNESS`, `BG`, `FG`, `HDR_BG`, `HDR_FG`, `SEL_BG`, `MATERIA_VIEW`. `change_color.sh:25`
- MA2.4 Preset variables read by the script (defaults in brackets): `BG`, `FG`, `SEL_BG`, `MENU_BG`/`HDR_BG`, `MENU_FG`/`HDR_FG`, `TXT_BG`/`MATERIA_VIEW`, `BTN_BG`/`MATERIA_SURFACE`, `GNOME_SHELL_PANEL_OPACITY` [0.6], `MATERIA_PANEL_OPACITY` [0.6], `MATERIA_STYLE_COMPACT` [False], `MATERIA_COLOR_VARIANT`, `SPACING` [3], `ROUNDNESS` [4], `MATERIA_SELECTION_OPACITY` [0.32], `TERMINAL_COLOR4..12` with defaults. `change_color.sh:119-144`
- MA2.5 Other inputs: `OPTION_GTK2_HIDPI` (default False, `-d/--hidpi`), `OPTION_FORCE_INKSCAPE` (default True, `-i/--inkscape`), `TARGET_DIR` (`-t`, default `$HOME/.themes`), `OUTPUT_THEME_NAME` (`-o`, default `oomox-$THEME`), `CUSTOM_PATHLIST` (`-p`). `change_color.sh:21-64,97-98,146-147`
- MA2.6 Environment variables: `DEBUG` (keeps the temp dir), `EXPORT_QT5CT` (set implicitly when a qt5ct path is in the path list), `XDG_CONFIG_HOME`. `change_color.sh:90-95,227-229,278`
- MA2.7 Variant auto-detection when `MATERIA_COLOR_VARIANT` is empty: dark if `BG` is dark (`is_dark`), else `default` if `HDR_BG` is dark, else `light`. `change_color.sh:165-177`. `is_dark` checks whether `darker(BG, 88)` equals `000000`. `change_color.sh:14-18`
- MA2.8 Theme name for meson options: the GTK theme is named by `theme_name` plus `-light` or `-dark`, plus `-compact` (color_suffix and size_suffix). `meson.build:39-40,47-48`

## 3. Color and style model
- MA3.1 Material palette in `src/_color-palette.scss`: per-hue steps named `$<hue>-<step>` (for example `$red-50: #ffebee` at line 5), based on the 2014 Material palette. `src/_color-palette.scss:1-3,5-12`
- MA3.2 Color roles are Sass variables in `src/_theme-color.scss` (in the template, with `%TOKEN%` placeholders):
  - surfaces: `$surface-z0`, `$surface-z1`, `$surface-z8`, `$surface-switch-thumb`, `$on-surface` (`_theme-color.scss:61-65`; template `:61-65` with `%BG%`, `%MATERIA_VIEW%`, `%MATERIA_SURFACE%`, `%FG%`)
  - primary: `$primary-on-light: #1967d2`, `$primary-on-dark: #8ab4f8`, `$primary`, `$on-primary` (`_theme-color.scss:67-70`)
  - error, warning, success, visited: each with `-on-light`, `-on-dark`, base, and `on-` pair (`_theme-color.scss:72-90`)
- MA3.3 Dark/light decision is per color, using `_is-dark($color)`, which computes perceived brightness with the W3C AERT weights (299, 587, 114) and threshold 128. `src/_theme-color.scss:19-23`
- MA3.4 `on($color)` picks black or white text for a background (`$on-dark: #fff`, `$on-light: #000`), using `_is-dark` and returns `rgba(contrast, .87)` unless saturation > 50% or alpha < 1. `src/_theme-color.scss:26-39`
- MA3.5 `highlight($color)` returns `rgba(white, .4 | .2 | .05)` by lightness thresholds at 80% and 40%. `src/_theme-color.scss:42-50`
- MA3.6 `opacify($color, $on)` blends a translucent color onto a background with `color.mix`. `src/_theme-color.scss:53-55`
- MA3.7 Helper `gtkalpha($color, $alpha)` returns `alpha(color, a)` as a string (GTK3 syntax). `src/_theme-color.scss:9-11`, also in template `src/_theme-color.template.scss:9-11`
- MA3.8 Per-state colors: a `disabled()` function is referenced (`theme-color.disabled(theme-color.$on-surface)` in `src/gtk-3.0/sass/_public-colors.scss:40`). Its definition was not read (UNVERIFIED in this study).
- MA3.9 Named GTK colors exported to GTK3: `src/gtk-3.0/sass/_public-colors.scss` defines `@define-color theme_fg_color`, `theme_text_color`, `theme_bg_color`, `theme_base_color`, `theme_selected_bg_color`, `theme_selected_fg_color`, `insensitive_bg_color`, `insensitive_fg_color`, `insensitive_base_color`, `theme_unfocused_*` from the `theme-color` roles. Lines 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56.
- MA3.10 GTK2 colors: `gtkrc-light` has `gtk-color-scheme = "base_color:#ffffff"`, `text_color:#212121`, `bg_color:#f9f9f9` and more. `src/gtk-2.0/gtkrc-light:15-18`. (The dark rc file uses the same key set; dark values not read.)
- MA3.11 Light/dark selection in the sass sources is by `$dark-theme` (set per build by Meson, see MA4.2) and `_is-dark` on the color token; the template uses `if(_is-dark(%BG%), %BG%, %FG%)` in one place (`src/_theme-color.template.scss:118`).

## 4. Output and rendering path
- MA4.1 Two generation paths exist:
  - Path A (committed sources, Meson): Sass in `src/` is compiled from the committed `_theme-color.scss` by `meson`. Entry: `meson.build` -> `src/gtk-3.0/meson.build` and `src/gtk-4.0/meson.build`.
  - Path B (`change_color.sh`): copies the tree to a temp dir, substitutes colors into the sources, then calls Meson and installs. `change_color.sh:156-161,303-311`
- MA4.2 Path A, GTK3 Sass per theme (`src/gtk-3.0/meson.build`):
  - Dependency list of Sass files `:1-19`.
  - Each `theme` in the matrix gets `gtk` and (if not a dark color) `gtk-dark` variants `:24-31`.
  - Assets and icons are installed unchanged with `install_subdir` `:33-41`.
  - `configure_file` substitutes `dark_theme`, `light_topbar`, `compact`, `current_source_dir` into `gtk.scss.in` / `gtk-dark.scss.in`. `:47-61`
  - `sass` compiles each `.scss` to `.css` with `--no-source-map` (`meson.build:21`). `src/gtk-3.0/meson.build:64-71`
  - The CSS is copied to `<theme_dir>/gtk-3.0/gtk.css` or `gtk-dark.css` by a `sh -c cp` install script. `:73-79`
- MA4.3 GTK3 entry (`src/gtk-3.0/gtk.scss.in:1-9`): `@use`s the shared `theme` module with `$dark-theme`, `$light-topbar`, `$compact` and `$toolkit: "gtk3"`, then `sass/common`, `sass/apps`, `sass/public-colors`.
- MA4.4 GTK4 entry (`src/gtk-4.0/gtk.scss.in:1-9`): same `theme` module with `$toolkit: "gtk4"`, then `sass/gtk` (with `$version: @version@`), `sass/common`, and `../gtk-3.0/sass/public-colors`.
- MA4.5 GTK4 version gate: `src/gtk-4.0/meson.build:3-17` takes `gtk4_version` from the option, or from `gtk4-launch --version` (the next even minor version is used when the minor is odd), or falls back to `4.0`. `src/gtk-4.0/sass/_gtk.scss:1` declares `$version: 4.0 !default;` and at line 2118 branches on `gtk.$version >= 4.2`. The other branch points were not read.
- MA4.6 GTK2 (`src/gtk-2.0/meson.build:10-28`): installs assets `assets/` from the directory, `gtkrc` + `theme['color']` (renamed to `gtkrc`, so `gtkrc-light` or `gtkrc-dark` becomes `gtkrc`) and the rc files. `src/gtk-2.0/meson.build:16-19`
- MA4.7 GTK2 widget drawing: `main.rc` has `engine "pixmap"` in 16 places and `engine "adwaita" {}` at line 137, with the comment "This needs to go before pixmap because we need to override some stuff" (line 136). `src/gtk-2.0/main.rc:133-137` (pixmap count from `rg -c`). The GTK2 asset set is rendered from SVG by `render-assets.sh` (`change_color.sh:295-297`).
- MA4.8 Asset rendering (`change_color.sh`): `./render-assets.sh gtk2-light|gtk2-dark` (line 295-297) and `./render-assets.sh gtk` (line 301). `FORCE_INKSCAPE` and `GTK2_HIDPI` are passed in as env vars. Script bodies not read in detail.
- MA4.9 Path B token substitution (`change_color.sh`):
  - Step 1: derive variant (MA2.7). `:165-177`
  - Step 2: replace hard-coded Materia default hex values in the source with tokens such as `%SEL_BG%`, `%FG%`, `%BG%`, `%HDR_BG%`, `%MATERIA_SURFACE%`. Two sed branches for light (`:183-203`) and dark (`:205-217`). The sed also replaces `Materia` with `%OUTPUT_THEME_NAME%` (`:202,216`).
  - Step 3: corner radius: `sed` sets `$corner-radius` in `src/_theme.scss` from `ROUNDNESS` (`:225`).
  - Step 4: `mv src/_theme-color.template.scss src/_theme-color.scss` (`:231`), so the template becomes the active color file.
  - Step 5: fill tokens with `sed` using the computed values; derived tokens are `%BG2%` = `darker BG`, `%SEL_BG2%` = `darker SEL_BG -20`, `%HDR_BG2%`, `%HDR_BG3%` (`:234-260`).
  - Step 6: pick `COLOR_SUFFIX` (`-light`, `-dark`, or empty) and `SIZE_SUFFIX` (`-compact`, or empty). `:262-290`
  - Step 7: render GTK2 and GTK3 assets, then `meson _build -Dprefix=$tempdir -Dcolors=... -Dsizes=...`, `meson install`, and move `share/themes/Materia<suffix>` to `$TARGET_DIR/$OUTPUT_THEME_NAME`. `:293-311`
- MA4.10 Derived tokens in the template use `darker` (a shell helper, `scripts/darker.sh`, not read) and `mix` (`scripts/mix.sh`, `mix_channel` at `scripts/mix.sh:5-16`, `mix` at `:18-`). `change_color.sh:136-137` uses `mix` for `INACTIVE_FG` and `INACTIVE_MATERIA_VIEW`.
- MA4.11 Call chain, preset to pixels (Path B, GTK3): preset file (`BG`, `FG`, `SEL_BG`, ...) -> `sed` token substitution in `src/` (`change_color.sh:182-260`) -> template `_theme-color.scss` filled -> `meson` + `sass` compile of `gtk.scss.in` (`src/gtk-3.0/meson.build:64-71`) -> `gtk.css` installed under `share/themes/...` (`:73-79`) -> moved to `TARGET_DIR` (`change_color.sh:305-311`).

## 5. Extension and integration points
- MA5.1 Plugin/extension: no plugin API. Extension is by preset files (outside this repo, `colors/` dir) and by the `CUSTOM_PATHLIST` option that changes which files get tokens. `change_color.sh:86-88`
- MA5.2 Install layout: `datadir/themes/Materia[-light|-dark][-compact]/` with `gtk-2.0/`, `gtk-3.0/`, `gtk-4.0/`, `index.theme`. `meson.build:9-10,47-48`, `src/meson.build:5-15`
- MA5.3 Index file: `src/index.theme.in` with `Name` `Materia` and `Comment=A Material Design theme`. `src/index.theme.in:4`. The per-theme `index.theme` is configured with `theme_name` (`src/meson.build:2-9`).
- MA5.4 Optional qt5ct palette export: when the path list contains a qt5ct file, the script moves `src/qt5ct_palette.conf` into `$XDG_CONFIG_HOME/qt5ct/colors/$OUTPUT_THEME_NAME.conf`. `change_color.sh:277-282`. The file itself is not in the default PATHLIST (`:70-85`).
- MA5.5 Version coupling: GTK3 uses the `gtk3` toolkit mode of the shared Sass module; GTK4 uses `$version` for version-conditional rules. `src/gtk-3.0/gtk.scss.in:5`, `src/gtk-4.0/gtk.scss.in:5,7`, `src/gtk-4.0/sass/_gtk.scss:1,2118`.
- MA5.6 Sass compiler coupling: dart-sass >= 1.23.0 (module system); Ruby Sass or older versions cause an npm install. `meson.build:23-34`

## 6. Data and tooling
- MA6.1 Sass sources: `src/gtk-3.0/sass/`, `src/gtk-4.0/sass/`, shared `src/_*.scss`.
- MA6.2 Meson build: root `meson.build`, `src/*/meson.build`.
- MA6.3 Shell tools: `change_color.sh` (recolor and install driver), `scripts/mix.sh` (`mix`), `scripts/darker.sh` (not read), `snapshot.sh` (not read), `render-assets.sh` at root and in `src/gtk-2.0/`, `src/gtk-3.0/`. `change_color.sh:8-13,292-301`
- MA6.4 Assets: SVG sources with `assets.txt` lists in `src/gtk-2.0/assets.txt`, `src/gtk-3.0/assets.txt`. Icons: `src/gtk-3.0/icons/radio-mixed-symbolic.svg`.
- MA6.5 Tools needed: `bc` (`scripts/mix.sh:9`), `sed`, `meson`, `ninja`, `sass`, `inkscape` (`FORCE_INKSCAPE` option, `change_color.sh:98`), `oxipng`/`optipng` (not verified in this study).
- MA6.6 Packaging: `package.json` and `package-lock.json` at the root (used for the npm fallback). `meson.build:31-33`
- MA6.7 Tests: none found.

## 7. Facts of note
- MA7.1 The recolor script contains a date-dependent easter egg: on April 1 with the `no-jokes` argument it overwrites colors. `change_color.sh:112-116`. Noted here for completeness; it does not affect the normal path.
- MA7.2 The token substitution is textual: it is a `sed` on hard-coded Materia default hex values (for example `#8ab4f8`, `#1967d2`, `#f9f9f9`, `#212121`). Any source file with those values is rewritten, so the source default values are part of the mechanism. `change_color.sh:184-217`
- MA7.3 `change_color.sh` does not run the preset through a parser; it `source`s the file as shell (`change_color.sh:102,106`).
- MA7.4 `ROUNDNESS` changes only `$corner-radius` in `src/_theme.scss`. Spacing is commented as not implemented. `change_color.sh:225`, `change_color.sh:221-222`
- MA7.5 TODO in repo: `TODO.md` exists (not read).
- MA7.6 Dark variant has no `gtk-dark` file when the color is `dark`. `src/gtk-3.0/meson.build:28-31`
- MA7.7 Version string `20210322` for the project. `meson.build:3`
- MA7.8 README and INSTALL mention dart-sass as a dependency. `INSTALL.md:10`

## 8. Not covered
- The per-app partials in `src/gtk-3.0/sass/apps/`, `_common.scss`, `_drawing.scss`, `src/gtk-4.0/sass/_common.scss` and `_drawing.scss`, and `src/_shadow.scss` were not read.
- `src/_theme-color.scss` lines 91-275 (remaining role definitions) and the body of `disabled()` were not read.
- `scripts/darker.sh`, `snapshot.sh`, `render-assets.sh` bodies, and `src/gtk-2.0/main.rc` (other than engine lines) were not read.
- GNOME Shell, Chrome, Cinnamon, Metacity, Unity, Xfwm, Plank outputs were not studied.
- No preset file was checked; the `colors/` directory is not in this repository.
- No build was run.
