# qtcurve: QtCurve widget style family for GTK2 (engine module), Qt4, Qt5 and Qt6 (QStyle plugins)

Source: refs/qtcurve (shallow clone; commit 4d8fc76; branch master). License: COPYING (GNU LGPL, version 2.1 text; `COPYING:1-3`). Source headers also state LGPL 2.1 or 3 or later (`lib/utils/shade.h:2-20`). Scope: whole repo at the level of mechanisms. Read in depth: `gtk2/style/qtcurve.cpp` (entry and type registration), `gtk2/style/helpers.cpp` (colour generation), `gtk2/style/qt_settings.cpp` (config path), `gtk2/common/config_file.cpp` (config reader, partial), `lib/utils/shade.h`, `lib/utils/color.cpp` (shade math), `lib/utils/options.h` (enum), `qt4/style/qtcurve_plugin.*`, `qt5/style/qtcurve_plugin.*`, `qt5/style/qtcurve.h`, `qt5/style/qtcurve.cpp` (init), `qt5/style/qtcurve_api.cpp` (entry points, by name), `qt6/style/qtcurve_plugin.*`, `qt6/style/CMakeLists.txt`, `README.md`, the CMake files for install paths.
Id prefix: QC.

## 1. Purpose and shape
- QC1.1 QtCurve is a set of widget styles written in C and C++. It ships four artifacts: a GTK2 theme engine module (`qtcurve-gtk2`), a Qt4 style plugin, a Qt5 style plugin and a Qt6 style plugin. Each targets its own toolkit version. `CMakeLists.txt:45-46` (ENABLE_QT5, ENABLE_QT6 default On); `gtk2/style/CMakeLists.txt:72` (`add_library(qtcurve-gtk2 MODULE ...)`); `README.md:23` (ENABLE_GTK2).
- QC1.2 Layout: `gtk2/` (`common/`, `style/`, `mozilla/`), `lib/` (`utils/`, `cairo/`, `xcb-defs/`), `qt4/` (`colors`, `common`, `config`, `kwin`, `kwinconfig`, `style`, `themes`), `qt5/` and `qt6/` (`common`, `config`, `kwin`, `kwinconfig`, `style`), `data/` (PNG assets), `tools/`, `test/`, `cmake/`. `README.md` and directory listing.
- QC1.3 Shared code lives in `lib/utils/` (colour math `color.cpp`, shade table `shade.h`, options `options.h`, directory and config paths `dirs.cpp`, X11 helpers `x11*.cpp`, shadow and blur helpers). The toolkit trees include these through their CMake targets.
- QC1.4 Build: CMake. Qt5 KDE integration is optional (`QTC_QT5_ENABLE_KDE`, `CMakeLists.txt:60-63`); Qt6 KDE integration is optional (`QTC_QT6_ENABLE_KDE`, default Off, `CMakeLists.txt:48`). Qt5 KF5 dependencies are listed at `qt5/style/CMakeLists.txt:71-74`.

## 2. Theme input (how configuration reaches it)
- QC2.1 Config file name: `stylerc` (current) and `qtcurvestylerc` (old). `gtk2/common/config_file.cpp:34-35`. The Qt4, Qt5 and Qt6 config readers use the same two names (`qt4/common/config_file.cpp:35-36`, `qt5/common/config_file.cpp:43-44`, `qt6/common/config_file.cpp:43-44`).
- QC2.2 Environment variable `QTCURVE_CONFIG_FILE` overrides the file path. Checked first by `qtcReadConfig`: `gtk2/common/config_file.cpp:1141-1143`; Qt4 `qt4/common/config_file.cpp:1067`; Qt5 `qt5/common/config_file.cpp:1073-1079`; Qt6 `qt6/common/config_file.cpp:1076`. Documented in `README.md:136-142`.
- QC2.3 Environment variable `QTCURVE_CONFIG_DIR` overrides the config directory: `lib/utils/dirs.cpp:149`. Otherwise the directory is the XDG config location plus `qtcurve/` (`lib/utils/dirs.cpp:146-163`). The config file path is built from it at `gtk2/common/config_file.cpp:501`.
- QC2.4 Parser (GTK2 common reader): `loadConfig` reads `key=value` lines into a GHashTable: `gtk2/common/config_file.cpp:569-600`. Typed accessors and the `to*` helpers (`toAppearance`, `toShade`, and others) run from `gtk2/common/config_file.cpp:139-459`. The reader is `qtcReadConfig` at `gtk2/common/config_file.cpp:1137-1151`.
- QC2.5 A system-wide config is read after the defaults: `gtk2/common/config_file.cpp:1775-1785` calls `getSystemConfigFile()` and then `qtcReadConfig(systemFilename, opts, opts)` at `:1784`.
- QC2.6 Qt-side reader is `qtcReadConfig(const QString&, Options*, Options*, bool checkImages)`: `qt5/common/config_file.cpp:1073`. The Qt5 style calls it with a null name to load the default file: `qt5/style/qtcurve.cpp:396`. The Qt5 configuration GUI also calls it: `qt5/config/qtcurveconfig.cpp:1212`, `:2488`, `:2735`. Writing is `qtcWriteConfig(KConfig*, ...)`: `qt5/common/config_file.cpp:2179`.
- QC2.7 Qt-side Qt settings feed the GTK2 engine: `qtSettingsInit()` at `gtk2/style/qt_settings.cpp:1094`. When the active Qt style name begins with the QtCurve theme prefix, the engine resolves a theme file under the KDE home and reads it with `qtcReadConfig(rcFile, &opts, nullptr)`: `gtk2/style/qt_settings.cpp:1176-1187`. Otherwise it reads the default config: `:1189`.
- QC2.8 GTK2 RC input: the engine registers a GtkRcStyle whose `parse` hook is `rc_style_parse` (`gtk2/style/qtcurve.cpp:3260`). It uses a GScanner in a scope named `qtcurve_theme_engine` (`gtk2/style/qtcurve.cpp:3076-3093`). The block grammar and keys it accepts were not traced (UNVERIFIED). The shipped `gtk2/style/gtkrc` is installed at `gtk2/style/CMakeLists.txt:88-89`.
- QC2.9 Qt4 and Qt5 config files are not read through QSettings; they use the key=value reader above. The Qt5 config path also has a KConfig write path (QC2.6).

## 3. Color and style model
- QC3.1 Central options struct `Options` (fields include `contrast`, `darkerBorders`, `highlightFactor`, `shading`, `customShades[]`, `customAlphas`, `titlebarAppearance`, `inactiveTitlebarAppearance`). Declared in `lib/utils/options.h` (struct body not re-read in full; UNVERIFIED for the complete field list). Usage: `gtk2/style/helpers.cpp:98-109`.
- QC3.2 Shading modes: enum `class Shading { Simple, HSL, HSV, HCY }`: `lib/utils/options.h:28-33`.
- QC3.3 Shade table: `qtc_intern_shades[2][11][QTC_NUM_STD_SHADES]` with `QTC_NUM_STD_SHADES` = 6 (`lib/utils/shade.h:29`). Row 0 is the HSV and HSL table and row 1 is the SIMPLE table (`lib/utils/shade.h:31-58`). Contrast level selects the row index `c` in 0..10 (`contrast` in `Options`). Default-level comments are at `lib/utils/shade.h:40` and `:50`.
- QC3.4 Lookup: `qtcShadeGetIntern(c, s, darker, shading)` returns 1.0 for out-of-range input. Otherwise it returns the table value and, when `darker` is set and `s == QTC_STD_BORDER` (5), subtracts 0.1: `lib/utils/shade.h:63-72`, `QTC_STD_BORDER` at `lib/utils/shade.h:60`.
- QC3.5 Shade application: `_qtcShade(ca, cb, k, shading)` at `lib/utils/color.cpp:294-352`. Per mode:
  - Simple (`:302-307`): adds `k - 1` to each RGB channel, clamped to 1.0.
  - HSL (`:309-321`): converts RGB to HSL (`rgbToHsl`, `lib/utils/color.cpp:223`), multiplies lightness and saturation by `k` with bounds 0..1, converts back (`hslToRgb`, `lib/utils/color.cpp:274`).
  - HSV (`:323-341`): converts to HSV, multiplies V by `k`; if V exceeds 1.0, the excess is subtracted from S (floored at 0) and V is set to 1.0.
  - HCY (`:343-352`): if `k > 1`, lightens by `k * (1 + HCY_FACTOR) - 1.0`; otherwise darkens by `1.0 - k * (1 - HCY_FACTOR)`, with `HCY_FACTOR` = 0.15 (`lib/utils/color.cpp:344`).
- QC3.6 Wrappers: `qtcShade(const QColor*, QColor*, k, shading)` at `lib/utils/color.h:286-294` and the internal call at `:294`. The `k == 1.0` case returns the input unchanged (`lib/utils/color.cpp:298-300`).
- QC3.7 GTK2 palette generation: `shadeColors(base, vals)` at `gtk2/style/helpers.cpp:97-112` fills `QTC_NUM_STD_SHADES` shades of a base colour. It uses custom shade factors when `USE_CUSTOM_SHADES(opts)` is set, otherwise `qtcShadeGetIntern(opts.contrast, i, opts.darkerBorders, opts.shading)` (`:103-105`). It also computes highlight variants with `highlightFactor` (`:107-109`).
- QC3.8 GTK2 palette set-up: `generateColors()` at `gtk2/style/helpers.cpp:1207` calls `shadeColors` for window, button and other roles from the Qt-side palette in `qtSettings.colors[PAL_ACTIVE][...]`: `gtk2/style/helpers.cpp:1209-1212`. Qt-side palette source is `qt_settings.cpp` (QC2.7).
- QC3.9 Qt-side shade calls: `qt5/style/qtcurve.cpp:4162` and `:4168` (`qtcShade(..., opts.shading)`). Qt6 uses the same shared call (`qt6/style/qtcurve.cpp`, not re-read for line numbers; UNVERIFIED for exact line).
- QC3.10 Per-state handling: the GTK2 draw functions take `GtkStateType state` (for example `gtk2/style/drawing.h:98-103` for entry and progress; `:139-144` for splitter and sidebar button). The Qt5 entry points take `QStyle::State` through the option structure (`qt5/style/qtcurve_api.cpp:2067`, `:2193`). Dedicated per-state colour tables beyond this were not traced (UNVERIFIED for the complete mapping).
- QC3.11 Qt-side style-name and palette feed: `Style::init(bool initial)` at `qt5/style/qtcurve.cpp:386` and `qt6/style/qtcurve.cpp` (init line not re-read). Qt4 init at `qt4/style/qtcurve.cpp:924`.

## 4. Output and rendering path
Input to pixels, GTK2 engine (order of calls):
- QC4.1 `theme_init(GTypeModule*)` is exported at `gtk2/style/qtcurve.cpp:3292`. It initialises Xlib (`:3294`), registers the RC style type (`:3295`) and the style type (`:3296`).
- QC4.2 `rc_style_register_type` (`gtk2/style/qtcurve.cpp:3268`) registers `GTK_TYPE_RC_STYLE` as `QtCurve::RcStyle` through `g_type_module_register_type` (`:3283`). `rc_style_class->parse = rc_style_parse` is set at `:3260`.
- QC4.3 `style_register_type` (`gtk2/style/qtcurve.cpp:3169`) registers `GTK_TYPE_STYLE` through `g_type_module_register_type` (`:3184`).
- QC4.4 `style_class_init` (`gtk2/style/qtcurve.cpp:3042`) assigns the GtkStyleClass draw callbacks, lines `:3049-3070`: `realize`, `unrealize`, `init_from_rc`, `draw_resize_grip`, `draw_expander`, `draw_arrow`, `draw_tab`, `draw_shadow`, `draw_box_gap`, `draw_extension`, `draw_handle`, `draw_box`, `draw_flat_box`, `draw_check`, `draw_slider`, `draw_option`, `draw_shadow_gap`, `draw_hline`, `draw_vline`, `draw_focus`, `draw_layout`, `render_icon`.
- QC4.5 Each callback forwards into the drawing layer. Declarations are in `gtk2/style/drawing.h` (for example `drawBorder` at `:59`, `drawEntryField` at `:98`, `drawProgress` at `:102`, `drawSelection` at `:123`, `drawTab` at `:163`, `renderIcon` at `:180`). Definitions are in `gtk2/style/drawing.cpp` (not re-read).
- QC4.6 Colours come from `generateColors` / `shadeColors` (QC3.7, QC3.8) and are applied through the GtkStyle colour arrays inside those draw functions.
- QC4.7 Qt5 path: `StylePlugin::create(key)` (`qt5/style/qtcurve_plugin.cpp:120-142`) creates `Style` when the key lowercased equals `qtcurve`. `Style::init` (`qt5/style/qtcurve.cpp:386`) loads options (`:396`). Then the QStyle hooks run: `Style::polish(QApplication*)` (`qt5/style/qtcurve_api.cpp:165`), `Style::unpolish` (`:866`), `Style::pixelMetric` (`:1526`), `Style::drawPrimitive` (`:2067`), `Style::drawControl` (`:2193`).
- QC4.8 Qt4 path: the same shape with `BaseStyle` = `QCommonStyle` (`qt4/style/qtcurve.h:63`), class `Style` (`:65`), `Style::init` (`qt4/style/qtcurve.cpp:924`).
- QC4.9 Qt6 path: `Style` derives from `KStyle` when KDE support is on, otherwise `QCommonStyle` (`qt6/style/qtcurve.h:40-46`).
- QC4.10 No generated theme files are written by the style at run time. `qt5/style/CMakeLists.txt` contains a `DEPENDS` rule that builds PNG header files from `data/*.png` at build time (`qt5/style/CMakeLists.txt:44-46`). Exported `.themerc` files are written by the Qt config GUI (QC6.2).
- QC4.11 Assets: PNG files under `data/` are converted to headers at build time (QC4.10). Icons for GTK2 are shipped as `icons3` and `icons4` next to the gtkrc (`gtk2/style/CMakeLists.txt:88-89`).

## 5. Extension and integration points
- QC5.1 GTK2: the engine is a GTK2 module. Installed to `${GTK2_LIBDIR}/gtk-2.0/${GTK2_BIN_VERSION}/engines` (`gtk2/style/CMakeLists.txt:85-86`). The module exports `theme_init`, `theme_exit` (`gtk2/style/qtcurve.cpp:3300`), `theme_create_rc_style`, and `g_module_check_init` (`gtk2/style/qtcurve.cpp:3314`). The last one checks the GTK version at load time via `gtk_check_version(...)`.
- QC5.2 GTK2 theme directory: `GTK2_THEME_DIR` defaults to `${GTK2_PREFIX}/share/themes/QtCurve` (`CMakeLists.txt:219`). Installed files: `gtkrc`, `icons3`, `icons4`, `kdeglobals` under `${GTK2_THEME_DIR}/gtk-2.0` (`gtk2/style/CMakeLists.txt:88-89`), and `map_kde_icons.pl` (`:87`).
- QC5.3 Qt5 and Qt4 plugin install: the shared object goes to `${QTCURVE_STYLE_DIR}` (`qt5/style/CMakeLists.txt:82`; `qt4/style/CMakeLists.txt:86`, `:88`). `qtcurve.themerc` goes to `${DATA_INSTALL_DIR}/kstyle/themes` for Qt4 (`qt4/style/CMakeLists.txt:65`) and is installed by `qt5/style/CMakeLists.txt:91-92`.
- QC5.4 Qt discovery: Qt loads the plugin by key. Qt5 and Qt6 use `Q_PLUGIN_METADATA(IID QStyleFactoryInterface_iid FILE "qtcurvestyle.json")` (`qt5/style/qtcurve_plugin.h:32-34`, `qt6/style/qtcurve_plugin.h:32-34`). The JSON declares `"Keys": ["QtCurve"]` (`qt5/style/qtcurvestyle.json:2`, `qt6/style/qtcurvestyle.json:2`). The match is case-insensitive (`qt5/style/qtcurve_plugin.cpp:129` / `qt6/style/qtcurve_plugin.cpp:129`).
- QC5.5 Qt4 registration: `Q_EXPORT_PLUGIN2(Style, StylePlugin)` at `qt4/style/qtcurve_plugin.cpp:141`. Class `StylePlugin : public QStylePlugin` at `qt4/style/qtcurve_plugin.h:28`.
- QC5.6 ABI and private-header coupling, Qt6: `qt6/style/CMakeLists.txt:52-56` adds `${Qt6Widgets_PRIVATE_INCLUDE_DIRS}` and `${Qt6Gui_PRIVATE_INCLUDE_DIRS}` to the include path. The Qt6 style therefore compiles against Qt private headers.
- QC5.7 Qt5 and Qt6 KDE coupling: when the KDE option is on, the base class becomes `KStyle` (`qt5/style/qtcurve.h:40-46`, `qt6/style/qtcurve.h:40-46`). Otherwise `QCommonStyle`.
- QC5.8 GTK2 build dependency: GTK2 headers (`gtk/gtk.h`) and `gdk` are used throughout `gtk2/style/`. Configure-time checks are in `gtk2/style/CMakeLists.txt:77` (`qtc_gtk2_check_on_hdr`, `qtc_gtk2_check_x_on_hdr`). Exact GTK2 version floor was not traced (UNVERIFIED).
- QC5.9 Qt5 and Qt6 ship a KWin decoration in `kwin/` and `kwinconfig/` (directories listed in QC1.2); their interface was not studied (see Section 8).

## 6. Data and tooling
- QC6.1 Config editor (Qt5): `qt5/config/qtcurveconfig.cpp`, a Qt widget application that reads and writes the config with `qtcReadConfig` and `qtcWriteConfig` (QC2.6). The Qt4 counterpart is under `qt4/config/`.
- QC6.2 Theme export: a theme `qtc_<name>.themerc` is written by the configuration GUI and installed to `<kde prefix>/share/apps/kstyle/themes/` (`README.md:91`, `:110-123`).
- QC6.3 Config format: plain `key=value` text (`gtk2/common/config_file.cpp:569-600`). Presets are read by the same reader (`qt5/config/qtcurveconfig.cpp:2488`, `:2735`).
- QC6.4 Build-time asset generation: a qt-dump-png tool converts PNGs to C headers (`qt5/style/CMakeLists.txt:44-46`).
- QC6.5 Icon mapping script: `gtk2/style/map_kde_icons.pl` (installed at `gtk2/style/CMakeLists.txt:87`). Its body was not read (UNVERIFIED for behaviour).
- QC6.6 Tests: directory `test/` (listed at top level). Not read (UNVERIFIED for content).
- QC6.7 Docs: `README.md` (top-level). Mozilla CSS templates: `gtk2/mozilla/QtCurve.css.in`, `gtk2/mozilla/QtCurve-KDEButtonOrder.css.in` (names only, not read).

## 7. Facts of note
- QC7.1 The GTK2 engine and the Qt styles share one shading implementation in `lib/utils/color.cpp` and one table in `lib/utils/shade.h`. Qt5 and Qt6 use the same `qtcShade` wrapper (QC3.6, QC3.9).
- QC7.2 The GTK2 engine reads Qt-side KDE/Qt settings as well as its own config (QC2.7). The read path is in `gtk2/style/qt_settings.cpp`.
- QC7.3 `g_module_check_init` makes the GTK2 module reject a GTK build whose version check fails (QC5.1).
- QC7.4 `QTCURVE_CONFIG_FILE` is documented as a testing aid (`README.md:136-142`).
- QC7.5 `qtcReadConfig` returns early for the default file and reads `QTCURVE_CONFIG_FILE` first (QC2.2). The function then falls back to the default path (`gtk2/common/config_file.cpp:1143-1149`).
- QC7.6 The Qt6 style compiles against Qt private headers (QC5.6). This is a build-time coupling to Qt internals.
- QC7.7 The Qt4 plugin uses `Q_EXPORT_PLUGIN2`, the Qt4 plugin macro (QC5.5). Qt5 and Qt6 use `Q_PLUGIN_METADATA` (QC5.4).
- QC7.8 Qt5 and Qt6 class `Style` inherits `KStyle` only when the KDE option is on (QC5.7). Without it the class is a plain `QCommonStyle`.
- QC7.9 The GTK2 `qt_settings.cpp` path depends on KDE home conventions (`getKdeHome()`, `gtk2/style/qt_settings.cpp:1178`).
- QC7.10 Licence: LGPL 2.1 text (`COPYING:1-3`). Source headers add "version 2.1 ... or version 3, or any later version accepted by the membership of KDE e.V." (`lib/utils/shade.h:2-20`).

## 8. Not covered
- Qt5 and Qt6 KWin decoration code (`qt5/kwin/`, `qt6/kwin/`, `qt5/kwinconfig/`, `qt6/kwinconfig/`).
- The bodies of `gtk2/style/drawing.cpp`, `gtk2/style/window.cpp`, `gtk2/style/scrollbar.cpp`, `gtk2/style/tab.cpp`, and the other per-widget files beyond their names.
- The complete `Options` struct (`lib/utils/options.h`) and the full key list read by `config_file.cpp` (only the reader structure and a few keys were confirmed).
- The full colour-state mapping for each widget type (QC3.10 is partial).
- `lib/utils/color.cpp` helpers other than `_qtcShade`, `rgbToHsl`, `hslToRgb` (for example `_qtcColorLighten`, `_qtcColorDarken`, `qtcColorTintHelper`).
- Qt6 `qtcurve.cpp` line numbers for shade calls and `Style::init`.
- Qt4 and Qt6 config readers beyond the path-selection lines.
- `test/`, `tools/`, the Qt4 and Qt5 configuration widgets beyond the call sites, and `map_kde_icons.pl`.
- GTK2 minimum version and the `.pl` script behaviour (UNVERIFIED).
- The `data/` assets beyond the generation rule.
