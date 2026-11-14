# libadwaita: GTK 4 widget library and Adwaita stylesheet, style manager and settings backends

Source: refs/libadwaita (shallow clone; commit 39fff66; branch main). License: COPYING (GNU Lesser General Public License, version 2.1), cited at COPYING:1. Scope: src/adw-style-manager.c and .h, src/adw-accent-color.c, src/adw-settings*.c (impl-portal, impl-gsettings), src/stylesheet/ (README.md, gtk.scss, _colors.scss, meson.build, adwaita-stylesheet.gresources.xml, file list of widgets/), and the top-level file list. Widget C sources (src/adw-*.c) were not read beyond the file list.
Id prefix: LA

## 1. Purpose and shape
- LA1.1 libadwaita is a GTK 4 library (C, GObject) that ships widgets and an Adwaita stylesheet written in SCSS. The stylesheet is compiled to CSS and loaded as a GTK resource. The LGPL 2.1 text is in COPYING (COPYING:1).
- LA1.2 Layout that matters for theming:
  - `src/adw-style-manager.c` and `.h`: the style manager that owns the stylesheet providers and the color scheme (`src/adw-style-manager.c:228` update_stylesheet).
  - `src/adw-accent-color.c`: fixed accent palette, one hex value per accent color (`src/adw-accent-color.c:43-55`).
  - `src/adw-settings.c`, `src/adw-settings-impl*.c`: the settings abstraction and its backends (portal, gsettings, legacy, android, macos, win32).
  - `src/stylesheet/`: SCSS sources and build files for the Adwaita CSS (`src/stylesheet/README.md:10-13`).
  - `src/adwaita.gresources.xml`: the GResource bundle for widget assets.
  - `src/stylesheet/widgets/`: per-widget SCSS partials (about 45 files, for example `_buttons.scss`, `_header-bar.scss`, `_window.scss`).
- LA1.3 Build: meson. The stylesheet build uses sassc, or a meson subproject of sassc when sassc is not installed (`src/stylesheet/meson.build:7-10`). The GResource bundle is produced by `gnome.compile_resources` (`src/stylesheet/meson.build:81-83`).

## 2. Theme input (how configuration reaches it)
- LA2.1 Color scheme: the style manager reads the color scheme from the settings backend. The portal backend reads the `color-scheme` key of `org.freedesktop.portal.Settings` on bus `org.freedesktop.portal.Desktop`, object path `/org/freedesktop/portal/desktop` (`src/adw-settings-impl-portal.c:16-18`, read call at `src/adw-settings-impl-portal.c:296`, change signal handled at `src/adw-settings-impl-portal.c:160`).
- LA2.2 Accent color: the portal backend reads `accent-color` of type `(ddd)` (`src/adw-settings-impl-portal.c:326`, change handler at `src/adw-settings-impl-portal.c:179`). The gsettings backend reads `color-scheme` (`src/adw-settings-impl-gsettings.c:39`) and an enum `accent-color` (`src/adw-settings-impl-gsettings.c:56-57`) from the interface schema.
- LA2.3 Environment: if Granite is not present and `GTK_THEME` is unset, the style manager sets GtkSettings property `gtk-theme-name` to `Adwaita-empty` (`src/adw-style-manager.c:454-456`). The `GTK_THEME` environment variable is read with `g_getenv` in the same check.
- LA2.4 Application API: `adw_style_manager_set_color_scheme` (`src/adw-style-manager.c:979`), with getters `adw_style_manager_get_dark`, `get_high_contrast`, `get_accent_color`, `get_accent_color_rgba`, `get_document_font_name`, `get_monospace_font_name` (about `src/adw-style-manager.c:934-1182`).
- LA2.5 Fonts: document and monospace font names come from the style manager's settings (`adw_style_manager_get_document_font_name` at `src/adw-style-manager.c:1156`). GtkSettings `gtk-font-name` is also watched (see LA3.5).

## 3. Color and style model
- LA3.1 Stylesheet palette: named colors are GTK `@define-color` entries. `_colors.scss` defines the light values, for example `window_bg_color #fafafb` (`src/stylesheet/_colors.scss:32`), and the dark override `window_bg_color #222226` (`src/stylesheet/_colors.scss:95`).
- LA3.2 Accent derivation in SCSS: `accent_color` is an `oklab(from @accent_bg_color ...)` expression. In the light block it uses `min(l, 0.5)` (`src/stylesheet/_colors.scss:25`), and in the dark block it uses `max(l, 0.85)` (`src/stylesheet/_colors.scss:88`).
- LA3.3 Runtime accent: `generate_accent_css` writes `@define-color accent_bg_color <rgba>` and `@define-color accent_fg_color white` from the selected accent (`src/adw-style-manager.c:150-166`; the foreground line is at `src/adw-style-manager.c:161`). The RGBA comes from `adw_accent_color_to_rgba` (`src/adw-accent-color.c:43`), which maps each accent to a fixed hex value, for example blue `#3584e4` (`src/adw-accent-color.c:53-54`).
- LA3.4 Font CSS: `generate_fonts_css` writes font variables from the style manager fonts (`src/adw-style-manager.c:169`).
- LA3.5 Settings-driven updates: the style manager reacts to `system-supports-color-schemes`, `color-scheme`, `system-supports-accent-colors`, `accent-color`, `high-contrast`, `document-font-name`, `monospace-font-name`, and GtkSettings `gtk-font-name` and `gtk-interface-reduced-motion` (see `src/adw-style-manager.c:410-440` notify callbacks; the full connect list is in the constructor region at `src/adw-style-manager.c:444-540`).
- LA3.6 Stylesheet variants: four variants, light, dark, hc and hc-dark (`src/stylesheet/README.md:10-11`). Dark is selected at runtime by `update_dark` (`src/adw-style-manager.c:327-340`), which sets `gtk-interface-color-scheme` (`src/adw-style-manager.c:265`) and the provider's `prefers-color-scheme` (`src/adw-style-manager.c:262`). Contrast is set in the same update function.
- LA3.7 Shades and mixing: the accent foreground is the constant `white` (`src/adw-style-manager.c:161`). Other shades are computed in SCSS through `oklab(...)` expressions (LA3.2). No C-side lighten/darken function was read.
- LA3.8 Per-state handling (hover, pressed, backdrop, focus): UNVERIFIED: the per-state rules live in `src/stylesheet/widgets/*.scss` and `_common.scss`; these were not read.

## 4. Output and rendering path
- LA4.1 Input to stylesheet: `constructed` (`src/adw-style-manager.c:444-456`) creates the stylesheet providers and adds them with `gtk_style_context_add_provider_for_display` at `GTK_STYLE_PROVIDER_PRIORITY_THEME` (about `src/adw-style-manager.c:459-472`).
- LA4.2 The main stylesheet is loaded from the resource `/org/gnome/Adwaita/styles/gtk.css` into `self->provider` (`src/adw-style-manager.c:534-535`).
- LA4.3 Updates: `update_stylesheet` (`src/adw-style-manager.c:228`) first adds the animations provider at priority 10000 (`src/adw-style-manager.c:237-238`), whose text is `* { transition: none; }` (`src/adw-style-manager.c:476-477`). It then reloads the accent CSS (`src/adw-style-manager.c:243`) and the fonts CSS (`src/adw-style-manager.c:249`), and sets the color scheme and contrast on the provider and on GtkSettings (`src/adw-style-manager.c:262-265`).
- LA4.4 Stylesheet build: `src/stylesheet/gtk.scss` imports `palette`, `colors`, `drawing`, `common`, `compat-colors` (`src/stylesheet/gtk.scss:1-5`). `gtk.scss` is compiled to `gtk.css` (`src/stylesheet/meson.build:72`). The GResource XML is `src/stylesheet/adwaita-stylesheet.gresources.xml` (`src/stylesheet/meson.build:81-83`).
- LA4.5 Wrappers: GTK adds one include level around the variant files, named `gtk-$variant.css`, which wrap `Adwaita-$variant.css` (`src/stylesheet/README.md:12-13`).
- LA4.6 Widgets: widget rules are selectors on GTK CSS nodes in `src/stylesheet/widgets/*.scss` (not read in detail; see LA8).

## 5. Extension and integration points
- LA5.1 Backends: the settings backend is chosen per platform. The files are `src/adw-settings-impl-portal.c`, `-gsettings.c`, `-legacy.c`, `-android.c`, `-macos.c`, `-win32.c` (file list). The selection code was not read: UNVERIFIED which backend is chosen in which order.
- LA5.2 Toolkit coupling: the library uses GTK 4 APIs (`gtk_css_provider_load_from_string`, `gtk_style_context_add_provider_for_display`, GtkInterfaceColorScheme, GtkInterfaceContrast) (`src/adw-style-manager.c:243`, `src/adw-style-manager.c:265`). The exact GTK minimum version was not read: UNVERIFIED (check meson.build).
- LA5.3 Override hook for GTK theme name: `GTK_THEME` in the environment disables the `Adwaita-empty` override (`src/adw-style-manager.c:454`).
- LA5.4 Accent and font CSS are passed to the GTK provider as text; a consumer can read them only through the style manager API (LA2.4).

## 6. Data and tooling
- LA6.1 Stylesheet sources: `src/stylesheet/*.scss` and `src/stylesheet/widgets/*.scss`, README.md describing the variants (`src/stylesheet/README.md`).
- LA6.2 Build tools: sassc, either installed or built as a meson subproject (`src/stylesheet/meson.build:7-10`). The README asks for a recent sassc (`src/stylesheet/README.md:3`). No other compiler is named in the files read.
- LA6.3 Resources: `src/adwaita.gresources.xml` and `src/stylesheet/adwaita-stylesheet.gresources.xml`.
- LA6.4 Tests and demo app: not read.

## 7. Facts of note
- LA7.1 Accent colors are fixed hex values, one per accent name (`src/adw-accent-color.c:52-55`). No user-defined accent value was found in the code read.
- LA7.2 The Adwaita theme is applied through a GTK resource (`/org/gnome/Adwaita/styles/gtk.css`, LA4.2); the GTK theme name is set to `Adwaita-empty` on startup when Granite is absent (LA2.3), so the GTK theme name does not select the Adwaita look on its own.
- LA7.3 Color-scheme and accent values come from the desktop portal first in this file set (LA2.1, LA2.2); the GSettings path reads the same keys in the interface schema (`src/adw-settings-impl-gsettings.c:39`).
- LA7.4 The high-contrast variants are part of the stylesheet build (LA3.6).

## 8. Not covered
- Not read: the widget C sources (src/adw-*.c beyond the style manager and accent color), the widget SCSS partials (per-state rules), _common.scss, _drawing.scss, _palette.scss, _compat-colors.scss, adw-settings-impl-legacy/android/macos/win32, adw-color-utils.c, the backend selection code, meson.build top-level minimum version, tests, the demo app, and the docs.
- Partly read: src/adw-style-manager.c (lines 141-170, 228-270, 327-340, 444-476, 534-535, 979-1000, the getter list); src/adw-settings-impl-portal.c (lines 16-18, 160, 179, 296, 326); src/stylesheet/_colors.scss (lines 25, 32, 88, 95); src/stylesheet/README.md (lines 10-13).
