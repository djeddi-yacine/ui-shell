# breeze-gtk: GTK2, GTK3 and GTK4 theme that imitates KDE Breeze, generated from a KDE .colors scheme

Source: refs/breeze-gtk (shallow clone; commit 3acbaab; branch master). License: `LICENSES/BSD-3-Clause.txt` and `LICENSES/CC0-1.0.txt` are present (`LICENSES/`); no file-to-license mapping was found, so which license applies to which file is UNVERIFIED. Scope: whole repo (`CMakeLists.txt`, `cmake/`, `src/`, `README.md`, `TODO`).
Id prefix: BR.

## 1. Purpose and shape
- BR1.1 A GTK theme built to match KDE's Breeze. It targets GTK 2 (pixmap engine), GTK 3 (Sass) and GTK 4 (Sass). `README.md:1-3`
- BR1.2 Stated requirements: GTK+ 3.16 and a pixmap/pixbuf theme engine for GTK 2. `README.md:7-8`
- BR1.3 Build system: CMake (`CMakeLists.txt`), needs Breeze 5.27.80 for its color-scheme data. `CMakeLists.txt:14-15`. Also needs Python 3 with the `cairo` module (`src/render_assets.py:1-2`, `cmake/FindPythonCairo.cmake`), and either `sassc` or `sass` (`src/build_theme.sh.cmake:15-18`). The CMake helper `cmake/FindSass.cmake` and `cmake/FindGTKEngine.cmake` are present (not read).
- BR1.4 Top-level layout (the parts that matter):
  - `src/gtk2/`: static GTK 2 sources (`gtkrc` is generated, widget `rc` files are copied). `src/gtk2/widgets/*`
  - `src/gtk3/`: GTK 3 Sass entry `gtk.scss` and per-widget partials. `src/gtk3/gtk.scss`, `src/gtk3/widgets/`
  - `src/gtk4/`: GTK 4 Sass entry `gtk.scss` and widgets. `src/gtk4/gtk.scss`
  - `src/_colors.scss`: named GTK colors exported to apps. `src/_colors.scss:4-6`
  - `src/_functions.scss`: GTK and Breeze color helper functions. `src/_functions.scss:7-42`
  - `src/render_assets.py`: reads a KDE `.colors` file and writes PNG assets, GTK 2 `gtkrc` and GTK 3 `_global.scss`. `src/render_assets.py:717-862`
  - `src/build_theme.sh.cmake`: shell driver (configured by CMake) that calls the renderer and the Sass compiler and installs the output. `src/build_theme.sh.cmake:1-111`
  - `src/gtk-dark-3.0.css`, `src/gtk-dark-4.0.css`: one-line static dark CSS files copied in as `gtk-dark.css`. `src/CMakeLists.txt:43-44`
  - `src/settings.ini`: GTK settings file installed into each theme. `src/settings.ini:1-4`
  - `TODO`: two items (remove Sass deprecation warnings; build into `${CMAKE_BINARY_DIR}`). `TODO:1-2`

## 2. Theme input (how configuration reaches it)
- BR2.1 Primary input: a KDE color scheme file in the INI-like `.colors` format. The renderer reads it with `ReadKdeGlobals.read_globals`, which walks the sections `Disabled`, `Inactive`, `Button`, `Selection`, `Tooltip`, `View`, `Window`, `WM` and stores keys as `<Section><Key>`. `src/render_assets.py:25-42`
- BR2.2 Command-line flags of the renderer: `-c` (color scheme file), `-a` (assets dir), `-g` (gtk-2.0 dir), `-G` (gtk3 scss dir), `-b` (base `.colors` file). `src/render_assets.py:709` (global.scss help text), `src/render_assets.py:717` (read call), `src/build_theme.sh.cmake:45-46` (call site).
- BR2.3 Driver flags: `-c COLOR_SCHEME`, `-r COLOR_SCHEME_ROOT` (default `/usr/share/color-schemes`), `-t TARGET_DIRECTORY`. `src/build_theme.sh.cmake:53-56,62-85`
- BR2.4 Scheme resolution: if `-c` is empty, use `~/.config/kdeglobals` when present, otherwise `BreezeLight.colors` in the root. `src/build_theme.sh.cmake:91-97`. A name is resolved first in `COLOR_SCHEME_ROOT`, then in `~/.local/share/color-schemes/`. `src/build_theme.sh.cmake:100-107`
- BR2.5 The base scheme (`-b`) is always `BreezeLight.colors` from the root; the renderer reads it as a second file. `src/build_theme.sh.cmake:111`
- BR2.6 CMake-time schemes: `BreezeDark` and `BreezeLight` are generated at build time with `build_theme.sh -c <scheme> -t <dir> -r <BREEZE_COLOR_INSTALL_ROOT>`. `src/CMakeLists.txt:34,42`
- BR2.7 GTK settings file read by GTK: `settings.ini` sets `gtk-cursor-theme-name=breeze_cursors`, `gtk-modules=colorreload-gtk-module`, `gtk-error-bell=0`. `src/settings.ini:1-4`
- BR2.8 GTK 2 `gtkrc` is generated (not copied): `render_assets.py` writes `gtk-color-scheme = "<name>:<hex>"` lines for text, base, insensitive base, fg, bg, selected fg/bg, button fg, tooltip fg and more. `src/render_assets.py:813-827`

## 3. Color and style model
- BR3.1 The KDE scheme is loaded as a flat dictionary `_colors` keyed by section and key (for example `WindowBackgroundNormal`, `SelectionBackgroundNormal`, `ViewBackgroundNormal`). `src/render_assets.py:717`
- BR3.2 Color wrapper class `Color(colordict, name, name2=None, amount=0)` holds `rgb`, `html` and alpha-based variants. `src/render_assets.py:43-53` (class at line 43, constructor at line 44). Named roles used by the renderer include `window_bg`, `window_fg`, `view_bg`, `selection_bg`, `selection_fg`, `button_fg`, `tooltip_fg`, `border_color`, `check_color`, `progressbar` mix inputs. `src/render_assets.py:719-743`
- BR3.3 Derivation formulas in `Color` (all in `src/render_assets.py`):
  - `_mix(color, mix_color, amount)`: per-channel `color*amount + mix*(1-amount)`. `:76-80`
  - `_lighter`, `_darker`: shade functions. `:82-95` (`_darker` at line 88)
  - `_desaturate`: `:97-101`
  - `_intensity_effect`, `_color_effect`, `_contrast_effect`: state-based adjustments. `:103-141` (the state strings are the KDE effect names `Disabled`, `Inactive`, and so on)
  - `gradient(state, alpha)`: builds a two-stop gradient using `_darker(self.rgb, 0.10)` or `0.03`. `:149-166` (stops at `:152` and `:160`)
- BR3.4 Gradient and state colors for GTK 3 are emitted as Sass variables: names starting with `Disabled` or `Inactive` are written as raw values; `DisabledColor` and `InactiveColor` are written as `rgb(...)`; keys whose value matches `R,G,B` are written as `rgb(...)`. `src/render_assets.py:855-862`
- BR3.5 Sass color helpers in `src/_functions.scss`:
  - GTK wrappers: `gtk($str)` `:10`, `gtkalpha($c,$a)` `:15`, `gtkshade($c,$a)` `:20`, `gtkmix($c1,$c2,$m)` `:25`, `gtkoverlay` `:29`, `gtkoverlayalpha` `:34`. These are the GTK 3 `alpha()/shade()/mix()` equivalents.
  - Role functions: `internal_b_color` `:46` (base), `internal_s_color` `:65` (selection), `internal_v_color` `:81` (view), `internal_w_color` `:97-105` (window: normal returns `$WindowBackgroundNormal`, text returns `$WindowForegroundNormal`), `internal_t_color` `:107` (text), `internal_tooltip` `:125`, `internal_button_gradient` `:141`.
  - State functions: `internal_insensitive($c)` `:265-273`, `internal_backdrop($c)` `:275`, `internal_Contrast($c, $state)` `:289`, `internal_Color($c, $state)` `:382`, and `internal_Intensity` / `internal_Contrast` chain used by `internal_insensitive`. `src/_functions.scss:265-273`
  - Color maps for effects: `src/_functions.scss:230` (comment "Color maps for color effect functions").
- BR3.6 Light/dark handling: the dark theme is a separate CMake target built from the `BreezeDark` scheme, not a Sass switch. `src/CMakeLists.txt:33-34`. The static dark CSS files are copied on top. `src/CMakeLists.txt:43-44`
- BR3.7 Named GTK colors exported to other apps (`@define-color`): `theme_fg_color_breeze`, `theme_text_color_breeze`, `theme_bg_color_breeze`, `theme_base_color_breeze`, `theme_view_hover_decoration_color_breeze`, `theme_hovering_selected_bg_color_breeze`, `theme_selected_bg_color_breeze`, `theme_selected_fg_color_breeze`, `theme_view_active_decoration_color_breeze`, `insensitive_selected_bg_color_breeze`, `insensitive_bg_color_breeze`, `insensitive_fg_color_breeze`, `insensitive_base_color_breeze`. `src/_colors.scss:12-60`. Each value comes from `internal_*_color`, marked `// KCM'd` in the source.
- BR3.8 Per-state handling: insensitive (`Disabled`) via `internal_insensitive`; backdrop via `internal_backdrop`; hover via `internal_v_color(hover)` and `internal_s_color(hover)` (`src/_colors.scss:28,32`); active decoration via `internal_v_color(active)` (`src/_colors.scss:44`).

## 4. Output and rendering path
- BR4.1 Call chain, KDE scheme to installed theme (in order):
  1. CMake runs `build_theme.sh` with a scheme name and target. `src/CMakeLists.txt:33-34,41-42`
  2. `render_theme` makes a temp dir with `gtk-2.0`, `gtk-3.0`, `gtk-4.0` (`create_folders`, lines 4-11), copies `gtk2/*` into `gtk-2.0/` `src/build_theme.sh.cmake:44`
  3. `render_assets.py` reads the scheme and writes PNG assets into `assets/`, `gtkrc` into `gtk-2.0/` and `_global.scss` into the gtk3 directory. `src/build_theme.sh.cmake:45-46`, `src/render_assets.py:813,855`
  4. `build_sass gtk3/gtk.scss ... gtk-3.0/gtk.css` with `sassc` or `sass`. `src/build_theme.sh.cmake:47` (function at `:13-20`)
  5. `build_sass gtk4/gtk.scss ... gtk-4.0/gtk.css`. `src/build_theme.sh.cmake:48`
  6. `rm -f _global.scss`, then `install_theme` moves `assets`, `gtk-2.0`, `gtk-3.0`, `gtk-4.0` into the target. `src/build_theme.sh.cmake:49-50` (function at `:22-39`)
- BR4.2 GTK 3 Sass entry imports the generated `global` (from `_global.scss`), `../functions`, `../colors`, then widget partials. `src/gtk3/gtk.scss:5-7,9-10`
- BR4.3 GTK 3 widget coverage (file names in `src/gtk3/widgets/`): buttons, entries, menus, scrollbars, scales, switches, headerbar, treeview, lists, notebook, tooltips, dialogs, infobar, calendar, sidebar, pathbar, assistant, window decorations, and app-specific partials for Firefox and Chromium (`src/gtk3/applications/_firefox.scss`, `_chromium.scss`). Also `_libhandy.scss` and `_app_notifications.scss`.
- BR4.4 GTK 2 widgets: per-widget `rc` directories under `src/gtk2/widgets/` (menu, notebook, default, misc, entry, toolbar, progressbar, scrollbar, styles, range, buttons). They refer to the PNG assets by name; the assets are rendered by `render_assets.py` (for example `button`, `togglebutton`, `scale-slider`, `scale-trough`, `tab`, `spinbutton`, `notebook`, window control buttons). `src/render_assets.py:398-420,423-435,245-347`. Exact `rc` reference lines were not checked (UNVERIFIED).
- BR4.5 GTK 4 output: `gtk-4.0/gtk.css` is compiled from `src/gtk4/gtk.scss` by the same `build_sass` function. `src/build_theme.sh.cmake:48`. The contents of `src/gtk4/` were not read (UNVERIFIED).
- BR4.6 Asset rendering: `render_assets.py` draws with a Cairo wrapper class (surface size, `background`, `line`, `rounded_rectancle`, `circle`, `arrow`, `tab`, `spinbutton`, `notebook`, window-control glyphs). `src/render_assets.py:170-349`. Checks and item renderers `check_items` `:353`, `buttons` `:398`, `togglebuttons` `:411`, `scale_slider` `:423`, `scale_trough` `:432`.
- BR4.7 Asset selection: the `check_items` helper picks `@2.png` or `.png` file endings by a scale argument (the HiDPI variant). `src/render_assets.py:353-359`.

## 5. Extension and integration points
- BR5.1 Install layout: `<themes>/Breeze/` and `<themes>/Breeze-Dark/` under `${KDE_INSTALL_FULL_DATAROOTDIR}/themes/`, each with `assets/`, `gtk-2.0/`, `gtk-3.0/`, `gtk-4.0/`, and `settings.ini`. `src/CMakeLists.txt:49-52`. Manual install: copy the directories to `~/.themes` or `/usr/share/themes` (`README.md:11-16`).
- BR5.2 Theme discovery: GTK finds the theme by directory name under the themes path (the README instructs to pick "GNOME Application Style" in Plasma, `README.md:18`). Discovery mechanism inside GTK not verified in this repo.
- BR5.3 KDE integration: Plasma's `kde-gtk-config` applies the GTK theme. `README.md:18`. The repo does not contain that code.
- BR5.4 Toolkit version coupling: GTK 3.16 minimum (`README.md:7`). GTK 4 CSS is built with the same Sass toolchain. No pinned GTK 4 version found in the repo (UNVERIFIED).
- BR5.5 Build-time coupling to KDE data: `find_package(Breeze 5.27.80)` (`CMakeLists.txt:14`), and the Breeze color-scheme path `BREEZE_COLOR_INSTALL_ROOT` (`src/CMakeLists.txt:34,42`).
- BR5.6 Colorreload GTK module: `settings.ini` loads `colorreload-gtk-module` (`src/settings.ini:3`). The module source is not in this repo; its behavior is UNVERIFIED.
- BR5.7 Environment: the driver reads `HOME` (`src/build_theme.sh.cmake:93-94,103`). No other environment variable was found in the driver.

## 6. Data and tooling
- BR6.1 Templates: `src/build_theme.sh.cmake` is a CMake `configure_file` template (variables `@Python3_EXECUTABLE@` at `:45`). Configured by `src/CMakeLists.txt:5`.
- BR6.2 Scheme data: KDE `.colors` files (BreezeLight, BreezeDark, or the user's `kdeglobals`). Not in this repo; read at build time.
- BR6.3 Generators: `src/render_assets.py` (asset PNGs, `gtkrc`, `_global.scss`).
- BR6.4 Sass sources: `src/gtk3/`, `src/gtk4/`, `src/_functions.scss`, `src/_colors.scss`.
- BR6.5 Tests: none found in the repo (not searched exhaustively).
- BR6.6 Docs: `README.md` (install and Plasma setup), `TODO`.
- BR6.7 CMake helpers: `cmake/FindGTKEngine.cmake`, `cmake/FindSass.cmake`, `cmake/FindPythonCairo.cmake` (not read).

## 7. Facts of note
- BR7.1 The GTK 3 and GTK 2 colors are both derived from one KDE scheme, through `render_assets.py`. `src/render_assets.py:717,813,855`
- BR7.2 Color derivation happens in Python (Cairo PNG drawing and `Color` math) for GTK 2 assets and in Sass for GTK 3/4 CSS. `src/render_assets.py:76-166`, `src/_functions.scss:265-273`
- BR7.3 The GTK 2 colors use `gtk-color-scheme` lines written by the generator, not hand-written values. `src/render_assets.py:813-827`
- BR7.4 README states the KDE setting "apply colors to non-Qt applications" must be disabled. `README.md:19`
- BR7.5 Known open item in `TODO`: remove Sass deprecation warnings. `TODO:1`
- BR7.6 Light and dark themes are produced from different scheme inputs at build time (`BreezeLight` / `BreezeDark`), not at runtime. `src/CMakeLists.txt:34,42`
- BR7.7 The `_global.scss` file is deleted after the GTK 2 and GTK 3 steps, so only the compiled CSS is installed. `src/build_theme.sh.cmake:51`

## 8. Not covered
- The contents of `src/gtk4/` (widgets and `gtk.scss`) were not read.
- The full bodies of `src/gtk2/widgets/*` and most `src/gtk3/widgets/*` partials were not read.
- `src/_functions.scss` beyond the listed lines (for example `internal_Intensity` and the effect maps at lines 230-264) were not read.
- `render_assets.py` drawing bodies (`Canvas` methods, lines 170-349) and the per-state effect bodies (lines 103-141) were only listed, not read in full.
- The `cmake/` helper modules were not read.
- The `colorreload-gtk-module` and its source were not found in this repo.
- No build was run; no output was produced.
