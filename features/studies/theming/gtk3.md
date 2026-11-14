# gtk3: GTK 3.24 toolkit (branch gtk-3-24), theming machinery only (CSS providers, settings, theme lookup, built-in Adwaita and HighContrast themes)

Source: refs/gtk3 (shallow clone; commit bac4a94 2026-10-29; branch gtk-3-24). License: COPYING (GNU Library General Public License, version 2 text). Scope: gtk/gtkcssprovider.c, gtk/gtksettings.c, gtk/gtksettingsprivate.h, gtk/gtkstyleprovider.h, gtk/gtkstylecontext.c (provider add/remove only), gtk/gtkcssnode.c, gtk/gtkcssselector.c (state names), gtk/gtkcsscolorvalue.c, gtk/gtkhsla.c, gtk/gtkmain.c (GTK_DEBUG table), gtk/theme/Adwaita/, gtk/theme/HighContrast/, gtk/theme/win32/, gdk/wayland/gdkscreen-wayland.c (settings), gdk/x11/gdksettings.c. Widget, rendering and inspector code are out of scope.
Id prefix: G3

## 1. Purpose and shape
- G31.1 GTK 3 is a C toolkit (GObject-based) and the 3.24 maintenance branch. Its CSS engine uses the same `GtkCssNode` / `GtkCssSelector` model that GTK 4 uses, but the public API and file layout are GTK 3 (`gtk_style_context_add_provider_for_screen`, `gtk/gtkstylecontext.c:709`). The provider class is `GtkCssProvider` in `gtk/gtkcssprovider.c`.
- G31.2 Theming-relevant directories:
  - `gtk/gtkcssprovider.c`: provider object, theme file search, named theme loader, `@define-color` parser.
  - `gtk/gtksettings.c`: `GtkSettings` properties, settings.ini loader, theme-name resolution, theme provider wiring.
  - `gtk/gtkcssnode.c`, `gtk/gtkcssselector.c`: node tree and selector matching.
  - `gtk/gtkcsscolorvalue.c`, `gtk/gtkhsla.c`: color values and shade math.
  - `gtk/theme/Adwaita/`, `gtk/theme/HighContrast/`, `gtk/theme/win32/`: built-in theme sources and committed CSS.
  - `gdk/wayland/gdkscreen-wayland.c`, `gdk/x11/gdksettings.c`: backends.
- G31.3 Build: meson (`gtk/meson.build:682-701` generates `gtk.gresources.xml` through `gen-gtk-gresources-xml.py` and includes `theme/Adwaita` and `theme/HighContrast`). The Adwaita theme's build rules are in `gtk/theme/Adwaita/meson.build`.
- G31.4 Differences from GTK 4 in the same subsystems (all from code cited in later sections): no `gtk-interface-color-scheme` / `gtk-interface-contrast` properties; no `prefers-color-scheme` media queries in the built-in wrapper; theme directories are searched as `gtk-3.N` (G32.2) and variant files are `gtk-VARIANT.css` (G32.2); no deprecation call was found in the lines read for `@name` references or for `shade`, `alpha`, `mix`, `lighter`, `darker` (G33.3, G37.6).

## 2. Theme input (how configuration reaches it)
- G32.1 Startup CSS files (class doc). `$XDG_CONFIG_HOME/gtk-3.0/gtk.css` (user override, loaded at USER priority, see G32.7). Then the first existing `THEME/gtk-VERSION/gtk.css` among `XDG_DATA_HOME/themes`, `$HOME/.themes`, `XDG_DATA_DIRS/themes`, `DATADIR/share/themes`. Also `gtk-keys.css` for the key theme (class doc). `gtk/gtkcssprovider.c:62-80`.
- G32.2 Version directory search `_gtk_css_find_theme_dir`: looks in `$dir/$subdir/THEME/gtk-3.N/` for N from the current minor version downward in steps of 2 down to 0 (`gtk/gtkcssprovider.c:2029-2073`; loop `for (i = MINOR; i >= 0; i = i - 2)` directly after the base path is built; search pattern in the comment at 2019-2022). Within each directory the file name is `gtk-VARIANT.css` when a variant is given, else `gtk.css` (`gtk/gtkcssprovider.c:2040-2043`).
- G32.3 Lookup order in `_gtk_css_find_theme`: user data dir, `$HOME/.themes`, each system data dir, then the built-in data dir (`gtk/gtkcssprovider.c:2075-2105`; last call at 2103 uses `_gtk_get_theme_dir`).
- G32.4 Built-in data dir: `_gtk_get_theme_dir` returns `$GTK_DATA_PREFIX/share/themes` when the env var is set, else the compiled data prefix (`gtk/gtkcssprovider.c:1992-2000`).
- G32.5 Named theme loader `_gtk_css_provider_load_named (provider, name, variant)` at `gtk/gtkcssprovider.c:2123`. It first looks for an embedded resource `/org/gtk/libgtk/theme/NAME/gtk-VARIANT.css` (or `.../NAME/gtk.css` when no variant) at lines 2139-2143. If not found, it searches the file locations (G32.3), registers `gtk.gresource` from the theme directory if present (`gtk/gtkcssprovider.c:2155-2164`), then loads the file. If no file is found: with a variant, it retries with no variant; without a variant, it falls back to DEFAULT_THEME_NAME (`gtk/gtkcssprovider.c:2171-2190`). The DEFAULT_THEME_NAME fallback is guarded against infinite recursion.
- G32.6 Cached named provider: `gtk_css_provider_get_named (name, variant)` (`gtk/gtkcssprovider.c:2204-2222`) keeps a static hash of providers keyed by "name" or "name-variant".
- G32.7 `gtk_settings_init` (`gtk/gtksettings.c:300`) loads settings.ini in this order: `DATADIR/share/gtk-3.0/settings.ini` (`gtk/gtksettings.c:345`), `SYSCONFDIR/gtk-3.0/settings.ini` (350), each `$XDG_CONFIG_DIRS/gtk-3.0/settings.ini` (358), and `$XDG_CONFIG_HOME/gtk-3.0/settings.ini` (364). Parser `gtk_settings_load_from_key_file` at `gtk/gtksettings.c:3371`.
- G32.8 User CSS and theme providers are created in `settings_init_style` (`gtk/gtksettings.c:1874`). The user `gtk.css` is read from `$XDG_CONFIG_HOME/gtk-3.0/gtk.css` (path built at line 1886) and added at USER priority (`gtk/gtksettings.c:1900`). The GtkSettings object itself is added at SETTINGS priority (line 1904). The theme provider is added at SETTINGS priority (line 1908) and also re-added by `settings_update_provider` with THEME priority (`gtk/gtksettings.c:3261`, see G32.9).
- G32.9 Theme name resolution `get_theme_name` (`gtk/gtksettings.c:3268-3308`):
  - `GTK_THEME` env (3277-3278). A trailing `:VARIANT` after the last colon is taken as variant (3283-3290).
  - Otherwise `gtk-theme-name` and `gtk-application-prefer-dark-theme` are read (3296-3297). If prefer-dark is TRUE the variant is "dark" (3302-3303).
  - If the name is empty, DEFAULT_THEME_NAME is used (3307).
  - DEFAULT_THEME_NAME = "Adwaita" (`gtk/gtksettingsprivate.h:26`).
- G32.10 Per-theme settings.ini: after the theme loads, `settings_update_theme` (`gtk/gtksettings.c:3311-3334`) reads `THEME_DIR/settings.ini` if it exists (path at 3328-3330), with source THEME.
- G32.11 GTK property defaults relevant to theming, declared in `gtk/gtksettings.c`:
  - `gtk-theme-name`: default DEFAULT_THEME_NAME ("Adwaita"), pspec at 469-473.
  - `gtk-application-prefer-dark-theme`: default FALSE, pspec at 1345-1350.
  - `gtk-key-theme-name`: pspec at 503 (default "Default" set elsewhere; not verified).
  - `gtk-decoration-layout`: pspec at 1626 (default not read).
  - Other appearance properties (font, icon theme, cursor theme, xft-*, enable-animations) are present; not studied in detail.
- G32.12 Wayland settings (gdk): the Settings portal is queried when `gdk_should_use_portal()` is true. Constants at `gdk/wayland/gdkscreen-wayland.c:709-711` (bus name, object path, interface). Proxy creation and initial ReadAll call at 722-760. Changes are received in `settings_portal_changed` (674-700) and applied with `apply_portal_setting` (639).
- G32.13 Wayland fallback table `translations[]` at `gdk/wayland/gdkscreen-wayland.c:525-545` (schema, key, GtkSettings property, default value). Relevant entries: `org.gnome.desktop.interface gtk-theme` -> `gtk-theme-name` default "Adwaita" (line 526); `gtk-key-theme` -> `gtk-key-theme-name` default "Default" (527); `icon-theme` -> `gtk-icon-theme-name` default "gnome" (528); `cursor-theme` -> `gtk-cursor-theme-name` default "Adwaita" (529); `cursor-size` -> `gtk-cursor-theme-size` default 32 (530); `enable-animations` -> `gtk-enable-animations` default TRUE (line ~536 in the same table).
- G32.14 The table in G32.13 contains no entry mapping `org.freedesktop.appearance color-scheme` (searched: no `color-scheme` or `prefer-dark` string in `gdk/wayland/*.c`). So the portal color-scheme is not consumed by GTK 3.24 in this branch (see G37.1).
- G32.15 X11 settings: the XSettings name table in `gdk/x11/gdksettings.c:25-62`. Entries include `Net/ThemeName` -> `gtk-theme-name` (line 33), `Gtk/FontName` -> `gtk-font-name` (36), `Gtk/CursorThemeName` -> `gtk-cursor-theme-name` (41), `Gtk/ColorPalette` -> `gtk-color-palette` (35), `Gtk/ColorScheme` -> `gtk-color-scheme` (43, a separate property name not used for dark/light selection in gtksettings.c as read).
- G32.16 Environment variables: `GTK_THEME` (G32.9), `GTK_DATA_PREFIX` (G32.4), `GTK_DEBUG` (parsed at `gtk/gtkmain.c:658`; flag table `gtk_debug_keys` at `gtk/gtkmain.c:170-190`, entries include `no-css-cache` (184), `interactive` (188), `size-request`, `baselines`, `pixel-cache`). `GTK_DEBUG` is also checked at `gtk/gtksettings.c:3494` to record the origin of settings values.

## 3. Color and style model
- G33.1 Named colors: `@define-color NAME VALUE;` parsed by `parse_color_definition` (`gtk/gtkcssprovider.c:1069-1090`, keyword check at 1076). Values are stored in the provider's symbolic color table (not re-read beyond 1090).
- G33.2 Named color references: `_gtk_css_color_value_parse` (`gtk/gtkcsscolorvalue.c:794`) accepts `@name` (the `@` is consumed at line 813; the name is passed to `_gtk_css_color_value_new_name`). Built-in keywords `currentColor` and `transparent` are handled at 799-812 region before the `@` branch (`gtk/gtkcsscolorvalue.c:802-811`).
- G33.3 Color function names recognized by the parser: `names[]` at `gtk/gtkcsscolorvalue.c:799-800` lists `rgba`, `rgb`, `lighter`, `darker`, `shade`, `alpha`, `mix`, and a win32 symbolic color name. Function dispatch in `_gtk_css_color_value_parse_function` (`gtk/gtkcsscolorvalue.c:639`).
- G33.4 Shade math: the `sym_col`/shade value resolves through `_gtk_hsla_init_from_rgba` then `_gtk_hsla_shade` then `_gdk_rgba_init_from_hsla` (`gtk/gtkcsscolorvalue.c:181-191`). `_gtk_hsla_shade` (`gtk/gtkhsla.c:187-200`) keeps hue, multiplies lightness and saturation by factor, clamps both to [0,1] (lines 196-199 for lightness; saturation clamp follows, not re-read in full).
- G33.5 `alpha()`, `mix()`, `lighter()`, `darker()`, `shade()` are implemented in the same file (function names at `gtk/gtkcsscolorvalue.c:799-800`); their exact bodies were not read.
- G33.6 Light and dark: there is no separate color scheme property. The theme name plus the variant string selects the file (`gtk-dark.css`, `gtk-contained-dark.css`, etc.; G32.2, G34.3). The `dark` variant comes from `gtk-application-prefer-dark-theme` or `GTK_THEME=name:dark` (G32.9).
- G33.7 State pseudo-classes in CSS: state names table `gtk_css_pseudoclass_name` at `gtk/gtkcssselector.c:672-691` contains `active`, `hover`, `focus`, `backdrop`, `checked`, and others. Selector-side state table at `gtk/gtkcssselector.c:1128` (first entry `active`).
- G33.8 Node model: `gtk/gtkcssnode.c` defines the CSS node type and state tracking, with `GTK_CSS_NODE_GET_CLASS (cssnode)->get_style_provider` (line 121) and `queue_validate` (line 143). Function bodies were not read beyond those lines.
- G33.9 CSS node names: each widget class calls `gtk_widget_class_set_css_name` (85 call sites in gtk/*.c). Examples: `gtk/gtkbutton.c:634` sets "button"; base `GtkWidget` sets "widget" at `gtk/gtkwidget.c:3733`.

## 4. Output and rendering path
- G34.1 Input to pixels:
  1. `gtk_css_provider_load_from_path` (`gtk/gtkcssprovider.c:1912`), `gtk_css_provider_load_from_data` (1831), `gtk_css_provider_load_from_resource` (1945) parse text.
  2. `@define-color` entries are stored (G33.1); `@name` references are resolved in the color parser (G33.2).
  3. Selectors match CSS nodes (`gtk/gtkcssselector.c`, state table G33.7).
  4. Matches are applied through `GtkStyleProvider` at the provider's priority (G35.1).
  5. Rendering is outside scope (Cairo drawing via the theme code paths of each widget).
- G34.2 Provider added to screen: `gtk_style_context_add_provider_for_screen` at `gtk/gtkstylecontext.c:709`. `settings_update_provider` (`gtk/gtksettings.c:3243-3262`) replaces the previous theme provider with the new one at THEME priority (3261).
- G34.3 Built-in Adwaita theme: `gtk/theme/Adwaita/gtk.css` is a one-line wrapper: `@import url("resource:///org/gtk/libgtk/theme/Adwaita/gtk-contained.css");` (line 1). The compiled `gtk-contained.css` and `gtk-contained-dark.css` are committed in the tree (`gtk/theme/Adwaita/`). The SCSS sources are `gtk-contained.scss` (light, `$variant: 'light'`) and `gtk-contained-dark.scss` (dark). The shared partials are `_colors.scss` (78 lines), `_colors-public.scss`, `_common.scss` (4858 lines), `_drawing.scss` (615 lines).
- G34.4 Adwaita build (`gtk/theme/Adwaita/meson.build`): the `scss_files` list (`_colors-public.scss`, `_colors.scss`, `_common.scss`, `_drawing.scss`) is used as `depend_files`; the build runs `sassc` with `sassc_opts` for `gtk-contained.scss` (output `gtk-contained.css`) and for each variant in `theme_variants = ['dark']` (output `gtk-contained-dark.css`). `build_by_default: true`.
- G34.5 Generation script for the committed CSS: `gtk/theme/Adwaita/parse-sass.sh` runs `sassc -M -t compact` on `gtk-contained.scss` and `gtk-contained-dark.scss` (script lines 1-15 region).
- G34.6 HighContrast theme: `gtk/theme/HighContrast/gtk.css`, `gtk-contained.css`, `gtk-inverse.css`, `gtk-contained-inverse.css` and SCSS `gtk-contained.scss`, `gtk-contained-inverse.scss`, partial `_colors-hc.scss`; build rules in `gtk/theme/HighContrast/meson.build` (not read in detail). Its sources are a separate SCSS tree, not the Adwaita partials.
- G34.7 Windows theme: `gtk/theme/win32/gtk.css` and `gtk-win32-base.css`, used by the win32 build (not read in detail). The `GTK_WIN32_THEME_SYMBOLIC_COLOR_NAME` entry at `gtk/gtkcsscolorvalue.c:800` is the link between the parser and this theme.
- G34.8 Gresource embedding: `gtk/meson.build:682-701` registers the theme subdirs and the generated `gtk.gresources.xml`.

## 5. Extension and integration points
- G35.1 Priorities (`gtk/gtkstyleprovider.h`): FALLBACK = 1 (line 49), THEME = 200 (57), SETTINGS = 400 (68), APPLICATION = 600 (76), USER = 800 (87). The GTK theme provider uses THEME (`gtk/gtksettings.c:3261`); the settings object and the per-settings provider use SETTINGS (1904, 1908); the user `gtk.css` uses USER (1900).
- G35.2 Custom themes are directories with `gtk.css` or `gtk-VARIANT.css`, optionally with `gtk.gresource` (G32.5) and `settings.ini` (G32.10). Install locations: `$XDG_DATA_HOME/themes`, `$HOME/.themes`, `$XDG_DATA_DIRS/themes`, `$GTK_DATA_PREFIX/share/themes`.
- G35.3 Versioning: theme directories are keyed by `gtk-3.N`, searched from the running minor version downward (G32.2). The theme file name uses only the variant suffix, not the version (G32.2).
- G35.4 Key themes: `gtk-keys.css` per key theme name (class doc, `gtk/gtkcssprovider.c:77-78`); key theme name property at `gtk/gtksettings.c:503`, read at 3346.
- G35.5 Named theme API: `gtk_css_provider_get_named` (`gtk/gtkcssprovider.c:2204`) is a cached loader that other code paths can use.

## 6. Data and tooling
- G36.1 Theme sources: `gtk/theme/Adwaita/_*.scss`, `gtk-contained*.scss`; `gtk/theme/Adwaita/assets.txt` and `render-assets.sh` (not run); `gtk/theme/HighContrast/*` (same layout).
- G36.2 Build rules: `gtk/theme/Adwaita/meson.build` (sassc), `gtk/theme/HighContrast/meson.build`, root `gtk/meson.build:682-701`.
- G36.3 Generation helpers: `gtk/theme/Adwaita/parse-sass.sh` (sassc), `gtk/theme/HighContrast/parse-sass.sh`.
- G36.4 Docs: `gtk/theme/Adwaita/README` (not read); general docs under `docs/`.

## 7. Facts of note
- G37.1 No portal color-scheme: GTK 3.24 has no property or code path that maps `org.freedesktop.appearance color-scheme` to a theme variant in this branch (searched: no `color-scheme` or `prefer-dark` string in `gdk/wayland/*.c` or `gtk/*.c` except the X11 `Gtk/ColorScheme` XSettings name at `gdk/x11/gdksettings.c:43`). Dark selection therefore depends on the theme name, `GTK_THEME` variant, or `gtk-application-prefer-dark-theme` (G32.9).
- G37.2 `gtk-application-prefer-dark-theme` is a normal (not deprecated in code) property here; default FALSE (`gtk/gtksettings.c:1345-1350`).
- G37.3 Unknown theme names fall back to the variant-less name, then to DEFAULT_THEME_NAME (`gtk/gtkcssprovider.c:2171-2190`). The infinite-loop guard is at line 2186.
- G37.4 Theme name default is "Adwaita" (`gtk/gtksettingsprivate.h:26`), and the Wayland fallback table uses "Adwaita" (`gdk/wayland/gdkscreen-wayland.c:526`). GTK 4 uses "Default" for the same role (`gtk` GTK4 study, G42.8).
- G37.5 The committed CSS in `gtk/theme/Adwaita/` (`gtk-contained.css`, `gtk-dark.css`, `gtk.css`) are checked-in build artifacts (`gtk/theme/Adwaita/gtk.css` is one line). Note that `gtk/theme/Adwaita/gtk-dark.css` exists alongside `gtk-contained-dark.css`; their relation was not verified.
- G37.6 The `@define-color` symbol set and CSS color functions include deprecated-in-GTK4 functions as normal functions here: `lighter`, `darker`, `shade`, `alpha`, `mix` appear in the same names table (G33.3); no deprecation warnings were found in the lines read.
- G37.7 License: LGPL-2 text in COPYING (`COPYING:1-2`).

## 8. Not covered
- Not read: `gtk/gtkcssnode.c` bodies beyond lines 121-143; `gtk/gtkcssselector.c` matching code; `gtk/gtkcsscolorvalue.c` shade/alpha/mix bodies and the `_gtk_css_color_value_new_name` resolution path; `gtk/gtkcssnodestylecache.c`; the HighContrast and win32 SCSS and build files in detail; the full `gtk-contained` variant list (only the `dark` variant is in `theme_variants`); the settings property defaults beyond those listed; the X11 XSettings client; GDK portal property change handler bodies beyond the function names; GTK 3 inspector.
- All citations were re-read for the lines in G32.5, G32.9, G32.13, G33.4, G34.3, G35.1 before writing. UNVERIFIED items are not marked individually where the value is only the file name and no line was read.
