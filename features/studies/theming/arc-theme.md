# arc-theme: Arc GTK2/GTK3/GTK4 theme family built with Meson and sassc

Source: refs/arc-theme (shallow clone; commit 94ac8c7; branch master). License: GPL-3.0, `meson.build:5` and `COPYING`. Scope: `meson.build`, `meson_options.txt`, `meson/render-assets.py`, `common/meson.build`, `common/gtk-2.0/`, `common/gtk-3.0/`, `common/gtk-4.0/` (sass and meson). Cinnamon, GNOME Shell, Metacity, Unity, Xfwm, Plank were not studied.
Id prefix: AR.

## 1. Purpose and shape
- AR1.1 Arc is a flat theme with transparent elements for GTK 2, GTK 3, GTK 4 and several shells. `README.md:3`. Supported list: GTK 2, GTK 3, GTK 4, GNOME Shell, Cinnamon, Unity, Metacity, Xfwm, Plank. `README.md:27-38`
- AR1.2 Build language: Meson. Project version is `20221218`. `meson.build:1-3`. Sass is compiled with `sassc` (external program). `meson.build:30-37`
- AR1.3 Four variants: `light`, `darker`, `dark`, `lighter`. `meson.build:13-18` (each with a `-solid` suffix when transparency is off). `meson_options.txt:8-13` (choices list).
- AR1.4 Layout that matters:
  - `common/gtk-2.0/`: rc files per variant (`light/`, `dark/`, `darker/`, `lighter/` each with `gtkrc`), plus `main.rc`, `apps.rc`, `panel.rc`, `menubar-toolbar/`, `xfce-notify.rc`. `common/gtk-2.0/meson.build:37-39`
  - `common/gtk-3.0/sass/`: `gtk.scss.in` template plus partials (`_colors.scss`, `_drawing.scss`, `_common.scss`, `_applications.scss`, `_transparent_widgets.scss`, `_unity.scss`, `_budgie.scss`, `_granite.scss`, `_lightdm.scss`, `_libhandy.scss`, `_colors-public.scss`). `common/gtk-3.0/sass/gtk.scss.in:4-14`
  - `common/gtk-3.0/assets/`: `assets.svg`, `assets.txt`, rendered PNG assets. `common/gtk-3.0/meson.build:3-6,8`
  - `common/gtk-4.0/sass/`: `gtk.scss.in` plus `_colors.scss`, `_libadwaita.scss`, `_libadwaita-defaults.scss`, `_colors-public.scss`, `_common.scss`, `_drawing.scss`. `common/gtk-4.0/sass/gtk.scss.in:4-9`
  - `common/gtk-3.0/thumbnail/`, `meson/`: thumbnails and build helper scripts (`meson/install-file.py`, `meson/render-assets.py`). `meson.build:65`, `meson/render-assets.py:1-4`
- AR1.5 Top-level `meson.build` dispatches each selected theme to a subdir through a map from theme name to directory: `gtk2 -> gtk-2.0`, `gtk3 -> gtk-3.0`, `gtk4 -> gtk-4.0`, etc. `common/meson.build:17-31`

## 2. Theme input (how configuration reaches it)
- AR2.1 Meson options (`meson_options.txt`): `themes` (array; includes `gtk2`, `gtk3`, `gtk4`) at lines 1-6; `variants` (array of light/darker/dark/lighter) at lines 8-13; `transparency` (boolean, default true) at lines 15-20; `cinnamon_version`, `gnome_shell_version` at lines 22-31+.
- AR2.2 `transparency` is substituted into Sass at build time as the string `'true'` or `'false'`. `common/gtk-3.0/meson.build:26,52`, `common/gtk-4.0/meson.build:26`. Sass reads it as `$transparency`. `common/gtk-3.0/sass/gtk.scss.in:2`
- AR2.3 `variant` is substituted as `$variant` into a generated `gtk-<variant>.scss`. `common/gtk-3.0/meson.build:21-29,47-55`
- AR2.4 Sass compiler lookup: `find_program('sassc')`; if the build uses `sassc` option `--line-numbers --style nested` for a debug build, otherwise `--style compact`. `meson.build:30-37`
- AR2.5 No runtime settings file. Selection is done by the desktop through the theme name (`Arc`, `Arc-Dark`, `Arc-Darker`, `Arc-Lighter`, and `-solid` variants). `meson.build:13-18`
- AR2.6 Install prefix and theme directory: `datadir / 'themes' / variant_name`. `meson.build:20-28`

## 3. Color and style model
- AR3.1 GTK3 colors are Sass variables in `common/gtk-3.0/sass/_colors.scss`, named with the GTK named-color convention (`$base_color`, `$text_color`, `$bg_color`, `$fg_color`, `$selected_bg_color`, `$selected_fg_color`, `$borders_color`, `$link_color`, `$header_bg`, `$header_border`, `$header_fg`, `$dark_sidebar_bg`, `$panel_bg`, `$entry_bg`, `$entry_border`, `$insensitive_*`, `$warning_color`, `$error_color`, `$success_color`, `$destructive_color`, `$suggested_color`, `$drop_target_color`). `_colors.scss:4-70`
- AR3.2 Light/dark selection: `$base_color: if($variant != 'dark', #ffffff, #404552)`; `$bg_color`, `$text_color`, `$fg_color` follow the same pattern. `_colors.scss:4-7`. Variant-specific branches use `@if $variant == 'lighter'` and `@else if`. `_colors.scss:52-62`
- AR3.3 Hard-coded accent: `$selected_bg_color: #5294e2` (blue). `_colors.scss:10`. Derived: `$selected_borders_color: darken($selected_bg_color, 20%)`. `_colors.scss:11`. Link colors: `darken` (light) or `lighten` (dark) of the accent at `_colors.scss:14-17`.
- AR3.4 Status colors are hard-coded: `$warning_color #F27835`, `$error_color #FC4138`, `$success_color #73d216`, `$destructive_color #F04A50`, `$suggested_color #4DADD4`. `_colors.scss:21-29`
- AR3.5 Shade/derivation functions in Sass: `darken`, `lighten`, `mix`, `transparentize`, `saturate`. Examples: `$insensitive_bg_color` uses `mix($bg_color, $base_color, 40%)` (light) or `lighten($bg_color, 2%)` (dark), `_colors.scss:35`; `$insensitive_fg_color` uses `transparentize($fg_color, 0.45|0.55)`, `_colors.scss:34`; `$header_fg` uses `saturate(transparentize(...), 10%)`, `_colors.scss:47-48`.
- AR3.6 Transparency switch: `$selection_mode_bg`, `$dark_sidebar_bg`, `$header_bg` each branch on `$transparency == 'true'` into `transparentize(color, 0.05|0.03)` or the solid color. `_colors.scss:19,38-41,50`
- AR3.7 Per-state handling: Sass drawing mixins in `_drawing.scss`, for example `@mixin entry($t)` (line 10), `@mixin button($t, $actionb_bg, $actionb_fg)` (line 112), `@mixin overshoot($p, $c)` (line 275), and `_solid($c)` (line 4) which creates a solid-color image. `common/gtk-3.0/sass/_drawing.scss:4,10,112,275`. The state branches are inside those mixins (not read in detail).
- AR3.8 GTK4 colors: `common/gtk-4.0/sass/_libadwaita-defaults.scss` declares GTK named colors with `@define-color`, using the Sass variables from `_colors.scss` (for example `@define-color accent_bg_color #{$selected_bg_color};` at line 12; destructive at 17-19; success at 22-24; warning at 26-28; error at 30). `common/gtk-4.0/sass/_libadwaita-defaults.scss:8-30`
- AR3.9 GTK4 palette: `common/gtk-4.0/sass/_libadwaita.scss` defines a `gtkalpha` function (line 1-3, returns `alpha(#{$c},#{$a})`) and a 5-step Adwaita palette (`$blue_1`...). `common/gtk-4.0/sass/_libadwaita.scss:1-12`
- AR3.10 GTK2 colors are `gtk-color-scheme` lines in each variant's `gtkrc`. Light example: `base_color`, `text_color`, `bg_color`, `fg_color`, `tooltip_bg_color`, `selected_bg_color: #5294e2`, `dark_sidebar_bg`, `link_color`, `menu_bg`. `common/gtk-2.0/light/gtkrc:1-14`

## 4. Output and rendering path
- AR4.1 GTK3 pipeline (`common/gtk-3.0/meson.build`):
  - Asset PNGs from `assets/assets.txt` (names read with `cat`) are created by `subdir('assets')`. `:3-8`
  - A dark stylesheet is always generated from `gtk.scss.in` with `variant: dark` into `gtk-main-dark.css`. `:20-41`
  - Every other requested variant generates `gtk-<variant>.scss` and `gtk-main-<variant>.css` (`gtk-main.css` for light). `:43-65`
  - A GResource XML is generated: asset PNGs `assets/<name>.png` and `@2.png`, plus the variant CSS and `gtk-main-dark.css`. `:69-91`
  - `glib_compile_resources` builds `gtk-<variant>.gresource`. `:102-116`
  - The `.gresource` is installed as `<datadir>/themes/<variant_name>/gtk-3.0/gtk.gresource`. `:119-123`
  - A tiny `gtk.css` is generated and installed. It contains `@import url("resource:///org/gnome/arc-theme/gtk-main.css");`. `:127-137`
  - A `gtk-dark.css` is generated the same way and imports `gtk-main-dark.css`. `:139-` (FIXME at `:139` notes the file is overwritten per variant)
- AR4.2 GTK3 sass entry (`gtk.scss.in`): sets `$variant` and `$transparency` from placeholders (`:1-2`), then imports `_colors`, `_drawing`, `_common`, `_applications`, `_unity`, `_granite`, `_lightdm`, `_transparent_widgets`, `_colors-public`, `_budgie`, `_libhandy` in that order. `gtk.scss.in:4-14`
- AR4.3 GTK4 pipeline (`common/gtk-4.0/meson.build`): same shape as GTK3. Dark stylesheet `gtk-main-dark.css` (`:20-41`); per-variant `gtk-main*.css` (`:43-`); GResource with prefix `/org/gnome/arc-theme` (`:72`); installed `gtk.gresource` to `gtk-4.0/` (`:122`); `gtk.css` imports `resource:///org/gnome/arc-theme/gtk-main.css` (`:127-136`); dark `gtk-dark.css` imports `gtk-main-dark.css` (`:142-145`).
- AR4.4 GTK4 sass entry (`common/gtk-4.0/sass/gtk.scss.in:1-9`): sets `$variant` and `$transparency`, imports `_colors`, `_drawing`, `_common`, `_colors-public`, `_libadwaita`, `_libadwaita-defaults`.
- AR4.5 GTK2 pipeline (`common/gtk-2.0/meson.build`): installs per-variant `gtkrc` plus `apps.rc`, `main.rc`, `panel.rc`, `xfce-notify.rc` to `<datadir>/themes/<variant>/gtk-2.0/`. `:37-39`. Installs `menubar-toolbar/` (`:42-44`). Assets: a script install (`:52-56`) and a menubar-toolbar asset script (`:68-71`); dark menubar assets get `-dark.png` names (`:81-84`).
- AR4.6 GTK2 widget drawing: `main.rc` uses `engine "pixmap"` 24 times and `engine "adwaita"` 2 times. The pixmap engine draws from PNG files in the `assets` directory. `common/gtk-2.0/main.rc:102,550,691,729` (first pixmap occurrences shown). The adwaita engine is referenced at lines 536 and 704.
- AR4.7 Call chain, GTK3 input to pixels: `meson_options.txt` (`transparency`, `variants`) -> `configure_file` of `gtk.scss.in` with `variant`/`transparency`/`sass_path` -> `sassc` -> `gtk-main*.css` -> `glib_compile_resources` -> `gtk-<variant>.gresource` installed -> `gtk.css` loads `resource:///org/gnome/arc-theme/gtk-main*.css` at runtime. `common/gtk-3.0/meson.build:20-137`
- AR4.8 Asset rendering: `meson/render-assets.py` converts SVG (`assets.svg`) to PNG at 1x and 2x for each asset id, using `inkscape` and `oxipng`. `meson/render-assets.py:3-4`, asset list `:19-44`.
- AR4.9 GTK2 colors are read by GTK2 from `gtk-color-scheme` in `gtkrc` (`common/gtk-2.0/light/gtkrc:1-14`).

## 5. Extension and integration points
- AR5.1 No plugin API. Extension is by GTK named colors (`@define-color` in GTK4 `_libadwaita-defaults.scss`, `gtk-color-scheme` in GTK2) and by the GResource path `/org/gnome/arc-theme`. `common/gtk-3.0/meson.build:72`, `common/gtk-4.0/sass/_libadwaita-defaults.scss:8-14`
- AR5.2 GTK version coupling: GTK3 and GTK4 CSS are compiled into GResources and loaded through `resource:///` URIs, so the theme depends on GTK's resource loader. `common/gtk-3.0/meson.build:129`, `common/gtk-4.0/meson.build:129`. GTK2 uses classic rc files. `common/gtk-2.0/main.rc`.
- AR5.3 The GTK4 Sass uses `alpha()` in `gtkalpha` (line 2 of `_libadwaita.scss`), not `color-mix()`. `common/gtk-4.0/sass/_libadwaita.scss:1-3`. This is a Sass-side fact; how GTK4 treats `alpha()` is not verified here.
- AR5.4 Install paths: `<prefix>/<datadir>/themes/Arc[-variant][-solid]/gtk-2.0|gtk-3.0|gtk-4.0/`. `meson.build:20-28`, `common/meson.build:17-31`
- AR5.5 Discovery: the theme name is the directory name under `themes/`. `meson.build:13-18`

## 6. Data and tooling
- AR6.1 Sass sources: GTK3 and GTK4 directories listed in AR1.4.
- AR6.2 Assets: each GTK directory has `assets/assets.svg` and `assets/assets.txt`. `common/gtk-3.0/assets/assets.svg`, `common/gtk-3.0/assets/assets.txt` (listing only).
- AR6.3 Build tools: `meson` (>= 0.53.0), `sassc`, `inkscape` (>= 1.0), `oxipng`, `glib-compile-resources`. `meson.build:4`, `meson/render-assets.py:3-4`, `common/gtk-3.0/meson.build:106-107`
- AR6.4 Build helpers: `meson/install-file.py` (install script used with `meson.add_install_script`), `meson/render-assets.py` (dist-time SVG to PNG). `meson.build:65`, `common/gtk-3.0/meson.build:119-122`
- AR6.5 Thumbnails: `common/gtk-3.0/thumbnail/light.png`, `dark.png`. (file listing only)
- AR6.6 Docs: `README.md`, `INSTALL.md`, `HACKING.md`, `AUTHORS`, `COPYING` at the repo root.

## 7. Facts of note
- AR7.1 README says the project has been unmaintained since May 2017 by the original author, and this fork aims to keep it updated. `README.md:5,7`
- AR7.2 Known build-time caveat in `gtk-3.0/meson.build`: the dark CSS file is overwritten for subsequent variants (FIXME). `common/gtk-3.0/meson.build:139`
- AR7.3 A TODO about GResource generation: "use gnome.compile_resources()". `common/gtk-3.0/meson.build:101`
- AR7.4 `_transparent_widgets.scss` has a commented-out nemo fix at line 1 (`//.nemo-window GtkEventBox`). `common/gtk-3.0/sass/_transparent_widgets.scss:1`
- AR7.5 Versioning: Meson project version is `20221218`, while the last commit in the clone is dated 2025-10-18. `meson.build:3`
- AR7.6 License GPL-3.0. `meson.build:5`, `COPYING`

## 8. Not covered
- The body of `_common.scss`, `_applications.scss`, `_drawing.scss` mixins, and `_colors-public.scss` was not read; per-widget state rules are not described.
- GTK2 `main.rc` body was not read beyond engine lines.
- The GNOME Shell, Cinnamon, Metacity, Unity, Xfwm, Plank outputs were not studied.
- The `gtk-4.0/sass/_colors.scss` values were not compared to GTK3 values (both are 110 lines; contents not diffed).
- The Meson install scripts (`meson/install-file.py`) were not read.
- No build was run.
