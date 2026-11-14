# qt6ct: Qt 6 configuration tool, platform theme plugin, proxy style and config GUI

Source: refs/qt6ct (shallow clone; commit 55dba87, dated 2024-03-14; branch master). License: COPYING (BSD-style, Copyright (c) 2020-2024, Ilya Kotov), cited. Scope: whole repo; the translation files (src/qt6ct/translations/*.ts, desktop-translations/*) were listed but not read. Repo also contains colors/ and qss/ data files.
Id prefix: Q6.

## 1. Purpose and shape
- Q6.1 Qt 6 configuration tool for desktops without Qt integration. It provides a QPA platform theme plugin (`qt6ct`), a widget style plugin (`qt6ct-style`), a shared library (`qt6ct-common`) and a configuration GUI (`qt6ct`). `README:1-4`. Languages: C++ with Qt Widgets, qmake and CMake builds. Requires qtbase >= 6.0.0 and qtsvg (runtime) per `README:9-13`.
- Q6.2 Layout that matters:
  - `src/qt6ct-common/`: `qt6ct.cpp/.h`, shared paths, colour-scheme loader, style-instance registry. Built as library `qt6ct-common`.
  - `src/qt6ct-qtplugin/`: `qt6ctplatformtheme.cpp/.h`, `main.cpp`, `qt6ct.json`. Platform theme plugin, built as `qt6ct-qtplugin`.
  - `src/qt6ct-style/`: `qt6ctproxystyle.cpp/.h`, `plugin.cpp`, `qt6ct.json`. Style plugin, built as `qt6ct-style`.
  - `src/qt6ct/`: GUI application (`main.cpp`, `mainwindow.*`, pages `appearancepage`, `fontspage`, `iconthemepage`, `interfacepage`, `qsspage`, `troubleshootingpage`, `paletteeditdialog`, `qsseditordialog`, `fontconfigdialog`, `previewform.ui`, `qt6ct.desktop`).
  - `colors/`: seven sample colour schemes (`simple.conf`, `airy.conf`, `sand.conf`, `ia_ora.conf`, `waves.conf`, `dusk.conf`, `darker.conf`).
  - `qss/`: five stylesheet snippets (`sliders-simple.qss`, `tooltip-simple.qss`, `scrollbar-simple.qss`, `fusion-fixes.qss`, `traynotification-simple.qss`).
  - `utils/update_ts.sh`, `utils/update_tx.sh`: translation maintenance scripts.
  - `CMakeLists.txt` (top level), `qt6ct.pro`, `qt6ct_release.sh`, `test.sh`, `ChangeLog`.
- Q6.3 Build: top-level `CMakeLists.txt`. CXX standard 17 (`CMakeLists.txt:15`), visibility hidden (`:17-19`), AUTOMOC/AUTORCC/AUTOUIC on (`:20-22`). Plugin directory from `qtpaths --plugin-dir` (`CMakeLists.txt:54-57`). Data installed to `${CMAKE_INSTALL_DATADIR}/qt6ct` for `qss` and `colors` (`:75-76`). Plugin install: `platformthemes` (`src/qt6ct-qtplugin/CMakeLists.txt:13`), `styles` (`src/qt6ct-style/CMakeLists.txt:14`), library to `${CMAKE_INSTALL_LIBDIR}` (`src/qt6ct-common/CMakeLists.txt:30`). Library SOVERSION from version variables (`src/qt6ct-common/CMakeLists.txt:12-13`).
- Q6.4 qmake build: `qmake DISABLE_WIDGETS=1` builds the platform plugin without QtWidgets; `qmake PLUGINDIR=<path>` sets plugin install path. `README:42-43`.

## 2. Theme input (how configuration reaches it)
- Q6.5 Environment variable selecting the plugin: `QT_QPA_PLATFORMTHEME=qt6ct` (or `qt5ct`). Plugin key match is case-insensitive: `src/qt6ct-qtplugin/main.cpp:53-54` (`key.toLower()` compared to "qt6ct" or "qt5ct", then `new Qt6CTPlatformTheme()`). README instructions: `README:30-35`, `README:48-50`.
- Q6.6 Main configuration file: INI format read with `QSettings(filePath, QSettings::IniFormat)`. Path: `Qt6CT::configFile()` = `<ConfigLocation>/qt6ct/qt6ct.conf` (`src/qt6ct-common/qt6ct.cpp:58-65`). Global default is copied on first run: `Qt6CT::initConfig()` searches `GenericConfigLocation` for `qt6ct/qt6ct.conf` and copies it if the user file does not exist (`src/qt6ct-common/qt6ct.cpp:45-56`). Called from the plugin constructor (`src/qt6ct-qtplugin/qt6ctplatformtheme.cpp:61`) and GUI `src/qt6ct/main.cpp:52`.
- Q6.7 Keys read by the platform theme `readSettings()` (`src/qt6ct-qtplugin/qt6ctplatformtheme.cpp:251-346`):
  - group `Appearance`: `style` (default "Fusion", `:258`); `color_scheme_path` (`:259`); `custom_palette` (bool, default false, `:260`); `icon_theme` (`:265`); `standard_dialogs` (default "default", `:271`).
  - group `Fonts`: `general` and `fixed` as QFont strings, default current application font (`:281-285`).
  - group `Interface`: `double_click_interval` (`:290`), `cursor_flash_time` (`:292`), `show_shortcuts_in_context_menus` (default true, `:293`), `buttonbox_layout` (`:295`), `keyboard_scheme` (`:296-297`), `menus_have_icons` (default true, sets `Qt::AA_DontShowIconsInMenus` inverted, `:298`), `toolbutton_style` (default `Qt::ToolButtonFollowStyle`, `:299`), `wheel_scroll_lines` (default 3, `:300`), `gui_effects` (string list: General, AnimateMenu, FadeMenu, AnimateCombo, AnimateTooltip, FadeTooltip, AnimateToolBox; `:302-323`), `stylesheets` (list of paths, `:326-327`).
  - group `Troubleshooting` (read only when not an update): `ignored_applications` (list of application paths, `:335`), `force_raster_widgets` (`:336-340`).
- Q6.8 Keys read by the proxy style `reloadSettings()` (`src/qt6ct-style/qt6ctproxystyle.cpp:39-57`): `Interface/dialog_buttons_have_icons` (`:41`), `Interface/activate_item_on_single_click` (`:42`), `Interface/underline_shortcut` (`:43`), `Appearance/style` (default "fusion", lowercased; falls back to "fusion" if it is "qt6ct-style" or not in `QStyleFactory::keys()`, `:46-48`).
- Q6.9 Keys written by the GUI (the GUI is the only writer): `Appearance/style`, `custom_palette`, `color_scheme_path`, `standard_dialogs` (`src/qt6ct/appearancepage.cpp:107-111`); `Appearance/icon_theme` (`src/qt6ct/iconthemepage.cpp:71`); `Fonts/general`, `Fonts/fixed` (`src/qt6ct/fontspage.cpp:63-65`); `Interface/*` keys (`src/qt6ct/interfacepage.cpp:71-105`); `Interface/stylesheets` (`src/qt6ct/qsspage.cpp:81`); `Troubleshooting/*` (`src/qt6ct/troubleshootingpage.cpp:50-57`); window geometry under `SettingsWindow/`, `QSSEditor/`, `PaletteEditor/` groups (`src/qt6ct/mainwindow.cpp:85`, `src/qt6ct/qsseditordialog.cpp:74`, `src/qt6ct/paletteeditdialog.cpp:105`).
- Q6.10 Environment variables read by qt6ct code: none found directly in qt6ct-common or qt6ct-qtplugin besides those used by Qt itself (`QT_QPA_PLATFORMTHEME` is documented only). `resolvePath()` expands `~` and `$VAR/` tokens (see Q6.13). UNVERIFIED: no other `qgetenv` use was checked in the GUI tree.
- Q6.11 Path search for user and shared data:
  - user colour schemes: `<ConfigLocation>/qt6ct/colors` (`src/qt6ct-common/qt6ct.cpp:108-110`).
  - shared colour schemes: `<GenericDataLocation>/qt6ct/colors` for each data location plus `QT6CT_DATADIR "/qt6ct/colors"` (`:113-122`), where `QT6CT_DATADIR` defaults to `/usr/share` (`src/qt6ct-common/qt6ct.cpp:41`).
  - user stylesheets: `<ConfigLocation>/qt6ct/qss` (`:91-93`); shared stylesheets: `<GenericDataLocation>/qt6ct/qss` plus `QT6CT_DATADIR "/qt6ct/qss"` (`:96-106`).
  - icon paths: `~/.icons` plus `<GenericDataLocation>/icons`, filtered to existing dirs (`:68-89`).
- Q6.12 The plugin checks the Qt version: the plugin refuses to load if `QLibraryInfo::version()` major/minor differs from the build (`src/qt6ct-qtplugin/main.cpp:46-50`, message "qt6ct is compiled against incompatible Qt version").
- Q6.13 Path and colour helper implementations:
  - `Qt6CT::resolvePath(path)`: replaces `~` with HOME, then expands `$NAME/` tokens with `qgetenv`, using regex `\$([A-Z_]+)\/`. `src/qt6ct-common/qt6ct.cpp:125-144`.
  - `Qt6CT::loadColorScheme(filePath, fallback)`: reads `[ColorScheme]` group with keys `active_colors`, `inactive_colors`, `disabled_colors` (comma lists of colour strings). `src/qt6ct-common/qt6ct.cpp:146-185`.

## 3. Color and style model
- Q6.14 Colour scheme file format (INI): section `[ColorScheme]`, three comma-separated lists `active_colors`, `inactive_colors`, `disabled_colors`. Each list has one `#AARRGGBB` (or `#RRGGBB`) entry per `QPalette::ColorRole`, in enum order. Example: `colors/airy.conf:1-3`. Items are parsed with `QColor(string)` (`src/qt6ct-common/qt6ct.cpp:177-181`).
- Q6.15 Role count handling: if a list has exactly `QPalette::Accent` entries (qtbase 6.6+), the Highlight value is appended as the Accent value. `src/qt6ct-common/qt6ct.cpp:157-166`. A list must have at least `QPalette::NColorRoles` entries for all three groups, otherwise the fallback palette is returned (`:168-176`, `:183-184`).
- Q6.16 Palette model: a `QPalette` built with `setColor(group, role, color)` for each of Active, Inactive, Disabled and each role `< NColorRoles` (`src/qt6ct-common/qt6ct.cpp:176-181`). The fallback is the widget style's standard palette (see Q6.18).
- Q6.17 Palette selection in the platform theme: `palette(SystemPalette)` returns `m_palette` if `m_usePalette` is true, else the generic Unix palette (`src/qt6ct-qtplugin/qt6ctplatformtheme.cpp:93-97`). `m_palette` is loaded in `readSettings()` only when `color_scheme_path` is non-empty and `custom_palette` is true (`:259-263`), with the fallback `*QPlatformTheme::palette(SystemPalette)` (`:263`). Path passed through `resolvePath` (`:262`).
- Q6.18 Palette application in `applySettings()`: if `m_palette` is null it becomes `qApp->style()->standardPalette()` (`src/qt6ct-qtplugin/qt6ctplatformtheme.cpp:185-186`); on update with `m_usePalette`, `qApp->setPalette(*m_palette)` (`:188-189`); each widget also gets `setPalette` (`:221-222`). Palette is disabled for apps listed in `ignored_applications` (`:335`, `:153-155`) and when the app sets `Qt::AA_SetPalette` (`:163-166`).
- Q6.19 Style: the proxy style base is picked from `Appearance/style`. `src/qt6ct-style/qt6ctproxystyle.cpp:46-55` (`setBaseStyle(QStyleFactory::create(style))`).
- Q6.20 Style hints overridden by `Qt6CTProxyStyle::styleHint()`: `SH_DialogButtonBox_ButtonsHaveIcons`, `SH_ItemView_ActivateItemOnSingleClick`, `SH_UnderlineShortcut`. Value 0 or 1 from the config tristate; otherwise the base style value. `src/qt6ct-style/qt6ctproxystyle.cpp:59-86`.
- Q6.21 Dark/light: not handled. UNVERIFIED: no colour-scheme-mode detection was found in the qt6ct sources; the palette is whatever the scheme file declares.
- Q6.22 Per-state handling: the three palette states Active, Inactive, Disabled come from separate lists in the scheme file (Q6.14). No hover, pressed or focus derivation is performed in qt6ct code.
- Q6.23 Shade derivation: none in qt6ct code. The only derived value is Accent = Highlight for a 21-entry list (Q6.15).

## 4. Output and rendering path
- Q6.24 Platform theme plugin: `class Qt6CTPlatformThemePlugin : QPlatformThemePlugin`, `Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QPA.QPlatformThemeFactoryInterface.5.1" FILE "qt6ct.json")` (`src/qt6ct-qtplugin/main.cpp:35-38`). Metadata file: `src/qt6ct-qtplugin/qt6ct.json`. `create()` returns `new Qt6CTPlatformTheme()` for "qt6ct" or "qt5ct" (`src/qt6ct-qtplugin/main.cpp:53-54` per grep line 11 of the function).
- Q6.25 Theme class `Qt6CTPlatformTheme` (declared in `src/qt6ct-qtplugin/qt6ctplatformtheme.h:44`, `class Qt6CTPlatformTheme : public QObject, public QGenericUnixTheme`). Constructor (`src/qt6ct-qtplugin/qt6ctplatformtheme.cpp:59`, body to about :76): `initConfig`, `readSettings()`, queued `applySettings`, queued `createFSWatcher` (widgets build), `setFont(m_generalFont)`, and checks for the `qt6ct-style` proxy style (`:73`, logs `qCCritical` at `:74` if absent).
- Q6.26 Overrides in the platform theme: `palette()` (`:93-97`), `font()` returns `m_fixedFont` for FixedFont and `m_generalFont` otherwise (`:99-104`), `themeHint()` (`:106-138`) for CursorFlashTime, ToolButtonStyle, SystemIconThemeName, StyleNames, IconThemeSearchPaths (`Qt6CT::iconPaths()`), DialogButtonBoxLayout, KeyboardScheme, UiEffects, WheelScrollLines, ShowShortcutsInContextMenus. `fileIcon()` at `:141-148`. Dialog helpers forwarded to a secondary theme chosen by `standard_dialogs` (`:81-90`, `:271-279`).
- Q6.27 applySettings call chain (`src/qt6ct-qtplugin/qt6ctplatformtheme.cpp:151-229`): font, palette, style sheets (`qApp->setStyleSheet(m_userStyleSheet + appStyleSheet)`, `:191-206`), icon theme update (`QIconLoader::instance()->updateSystemTheme()`, `:212`), dispatch `QEvent::...` to widgets and per-widget palette (`:215-223`).
- Q6.28 Stylesheet path: `loadStyleSheets(paths)` concatenates files, then strips `//` comments via regex `//.*\n` (`src/qt6ct-qtplugin/qt6ctplatformtheme.cpp:354-371`). The concatenated text is prepended to the application stylesheet (comment at `:193-194`).
- Q6.29 Style plugin: `class Qt6CTStylePlugin : QStylePlugin`, `Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QStyleFactoryInterface" FILE "qt6ct.json")` (`src/qt6ct-style/plugin.cpp:35`). `create()` returns the proxy style for keys "qt6ct-style" or "qt5ct-style" (`src/qt6ct-style/plugin.cpp:43`). Metadata: `src/qt6ct-style/qt6ct.json:2` (`"Keys": [ "qt6ct-style", "qt5ct-style" ]`).
- Q6.30 Proxy style class: `Qt6CTProxyStyle` derives from `QProxyStyle`, registers itself in `Qt6CT::styleInstances` in its constructor (`src/qt6ct-style/qt6ctproxystyle.cpp:33-37`), and is reloaded via `Qt6CT::reloadStyleInstanceSettings()` (`src/qt6ct-common/qt6ct.cpp:197-200`) which the theme calls on update (`src/qt6ct-qtplugin/qt6ctplatformtheme.cpp:182`).
- Q6.31 Call chain from environment to pixels, in order:
  1. `QT_QPA_PLATFORMTHEME=qt6ct` selects plugin key (Q6.5).
  2. Qt loads `platformthemes/libqt6ct-qtplugin.so`, `create()` checks Qt version (Q6.12).
  3. `Qt6CTPlatformTheme` constructor reads `qt6ct.conf` (Q6.7).
  4. `applySettings()` sets font, palette, stylesheet, icon theme (Q6.27).
  5. Qt picks widget style from `themeHint(StyleNames)`. The StyleNames list is `{"qt6ct-style"}` at `src/qt6ct-qtplugin/qt6ctplatformtheme.cpp:121-122` (case label on line 121).
  6. `QStyleFactory::create("qt6ct-style")` creates `Qt6CTProxyStyle` (Q6.29, Q6.30); the base style is from `Appearance/style` (Q6.19).
  7. Drawing is done by the base style (Fusion by default); the proxy overrides only the style hints in Q6.20.

## 5. Extension and integration points
- Q6.32 Plugin interfaces: QPA platform theme (IID `org.qt-project.Qt.QPA.QPlatformThemeFactoryInterface.5.1`, `src/qt6ct-qtplugin/main.cpp:37-38`) and Qt style factory (IID `org.qt-project.Qt.QStyleFactoryInterface`, `src/qt6ct-style/plugin.cpp:35`).
- Q6.33 Install destinations: `${PLUGINDIR}/platformthemes/libqt6ct-qtplugin` (`src/qt6ct-qtplugin/CMakeLists.txt:13`) and `${PLUGINDIR}/styles/libqt6ct-style` (`src/qt6ct-style/CMakeLists.txt:14`). PLUGINDIR from `qtpaths --plugin-dir` (`CMakeLists.txt:54`). qmake `PLUGINDIR` override (`README:43`).
- Q6.34 ABI coupling: the plugin refuses to load on a different Qt major.minor (Q6.12). The shared library `qt6ct-common` has a SOVERSION equal to the major version (`src/qt6ct-common/CMakeLists.txt:13`). Class `Qt6CT` is exported with `QT6CT_EXPORT`. `src/qt6ct-common/qt6ct.h:52`.
- Q6.35 Qt5 compatibility: the platform theme also answers to key "qt5ct" (`src/qt6ct-qtplugin/main.cpp:53`) and the style to "qt5ct-style" (`src/qt6ct-style/plugin.cpp:43`). The config path is the same (`qt6ct/qt6ct.conf`).
- Q6.36 Test harness: `test.sh` symlinks the built style into `src/qt6ct/styles/`, sets `QT_QPA_PLATFORMTHEME=qt6ct`, `QT_QPA_PLATFORM_PLUGIN_PATH=src/qt6ct-qtplugin`, `LD_LIBRARY_PATH=src/qt6ct-common`, and runs the GUI (`test.sh:1-13`).
- Q6.37 Config GUI is itself a Qt application that uses the same `Qt6CT` helpers and config path (`src/qt6ct/main.cpp:52`).

## 6. Data and tooling
- Q6.38 Config file: `qt6ct.conf` (INI). Keys listed in Q6.7-Q6.9. A sample file is not in the repo; the GUI writes it.
- Q6.39 Colour schemes: `colors/*.conf` (7 files), format in Q6.14. Installed to `${CMAKE_INSTALL_DATADIR}/qt6ct/colors` (`CMakeLists.txt:76`).
- Q6.40 Stylesheets: `qss/*.qss` (5 files), installed to `${CMAKE_INSTALL_DATADIR}/qt6ct/qss` (`CMakeLists.txt:75`).
- Q6.41 GUI pages: Appearance (style, palette file, dialogs), Fonts (general, fixed, font dialog `fontconfigdialog.*`), Icon theme (`iconthemepage.*`, reads icon theme folders with `index.theme`-style groups "Icon Theme" at `src/qt6ct/iconthemepage.cpp:155` and `:206` ("Icon Theme" group name only; the `index.theme` file name is used at `src/qt6ct/iconthemepage.cpp:126`)), Interface (`interfacepage.*`), Style sheets (`qsspage.*`, `qsseditordialog.*`), Troubleshooting (`troubleshootingpage.*`). Palette editor: `paletteeditdialog.*`, writes the `[ColorScheme]` group (`src/qt6ct/appearancepage.cpp:401-414`).
- Q6.42 Preview: `src/qt6ct/previewform.ui` (Qt Designer form).
- Q6.43 Translations: `src/qt6ct/translations/*.ts` (about 40 locales) and `desktop-translations/*.desktop.in`, managed by `utils/update_ts.sh`, `utils/update_tx.sh`.
- Q6.44 Tests: no unit tests in the tree. `test.sh` is a manual run script (Q6.36).

## 7. Facts of note
- Q6.45 README lists Wayland usage: `QT_QPA_PLATFORM=wayland` with `QT_QPA_PLATFORMTHEME=qt6ct` (`README:48-50`).
- Q6.46 README gives a debug logging switch: "By default, debug messages from platform plugin are disabled" (`README:52-57`, section "Debug Messages"). The test script uses `QT_LOGGING_RULES="qt6ct.debug=true"` (`test.sh:8`).
- Q6.47 The qt6ct troubleshooting tab can ignore the platform theme per application by path (`ignored_applications`, Q6.7, `src/qt6ct-qtplugin/qt6ctplatformtheme.cpp:335`).
- Q6.48 Known fragile points in code: `loadStyleSheets` calls `file.open(QIODevice::ReadOnly)` without checking the return value and then `readAll()` (`src/qt6ct-qtplugin/qt6ctplatformtheme.cpp:362-363`). When the `qt6ct-style` proxy style is not in `QStyleFactory::keys()`, the constructor logs `qCCritical` (`src/qt6ct-qtplugin/qt6ctplatformtheme.cpp:73-74`).
- Q6.49 The palette loader treats any count below `NColorRoles` as an error and falls back silently (no log in that branch). `src/qt6ct-common/qt6ct.cpp:168-176`.
- Q6.50 `qt6ct` changes Qt settings only if `QGuiApplication::desktopSettingsAware()` is true (`src/qt6ct-qtplugin/qt6ctplatformtheme.cpp:62`, `:153`).

## 8. Not covered
- Translation (.ts) contents and desktop translation files.
- The GUI page implementation bodies beyond the key writes listed (interfacepage, appearancepage tab logic, fontconfigdialog, previewform).
- `qt6ct_release.sh`, `ChangeLog`, `qt6ct.pro`, `qt6ct-common/qt6ct-common.pro`, `qt6ct-qtplugin/qt6ct-qtplugin.pro` and `qt6ct-style/qt6ct-style.pro` (qmake details).
- The QGenericUnixTheme base class and its theme hints (qtbase).
- The `qt6ct.desktop` file contents.
- Icon theme parsing details in `iconthemepage.cpp` beyond the group names.
- Whether `qt6ct-common` is loaded as a shared library by the plugin at runtime (only the link directory is shown in `test.sh`).
