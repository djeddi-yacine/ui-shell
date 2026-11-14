# kde-gtk-config: KDE Plasma service that writes GTK 2/3 settings, colors and window-decoration CSS from KDE configuration

Source: refs/kde-gtk-config (shallow clone; commit c25e15b; branch master; date 2026-11-13). License: per-file SPDX, `kded/gtkconfig.cpp:5` (`GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL`); license texts in `LICENSES/` (BSD-2-Clause, BSD-3-Clause, CC0-1.0, GPL-2.0-only, GPL-2.0-or-later, GPL-3.0-only, LicenseRef-KDE-Accepted-GPL). Scope: `CMakeLists.txt`, `kded/` (core, `config_editor/`, `scss/`), `kded-xsettingsd/`, `color-reload-module/`, `window-decorations-reload-module/`, `gtk3proxies/` (names only), `kconf_update/` (names only).
Id prefix: KG.

## 1. Purpose and shape
- KG1.1 A KDED (KDE daemon) module, `GtkConfig`, that watches KDE settings and writes GTK 2 and GTK 3 configuration files. `kded/gtkconfig.cpp:30` (`K_PLUGIN_CLASS_WITH_JSON(GtkConfig, "gtkconfig.json")`), `kded/gtkconfig.h:18-20` (`KDEDModule`, `Q_OBJECT`). C++ with Qt and KDE Frameworks; GTK 2 and GTK 3 are written, GTK 4 handling was not located (UNVERIFIED).
- KG1.2 Build: CMake, minimum 3.16. Declares project `kde-gtk-config`. `CMakeLists.txt:1-3`. Dependencies: ECM (`CMakeLists.txt:13`), Qt6 DBus and Svg (`:28`), KF6 ColorScheme, CoreAddons, Config, GuiAddons, DBusAddons, WindowSystem (`:29`), PkgConfig (`:30`), KDecoration3 (`:31`), GSettingSchemas (`:32`), Sass (`:33`), XSettingsd optional (`:34`, `:42-43`). The read of these lines is from the survey; the exact `find_package` lines were not re-opened in this pass.
- KG1.3 Top-level layout:
  - `kded/`: core module, `config_editor/` (writers), `scss/` (window-decoration CSS build), `kwin_bridge/`, `gsd-manager/` (contents not read). `kded/CMakeLists.txt:1-4, :26`.
  - `kded-xsettingsd/`: second KDED module, `gtkconfig_xsettings`, installed under the `kded-x11` plugin dir. `kded-xsettingsd/CMakeLists.txt:5`, `:46`.
  - `color-reload-module/`: GTK 3 GTK_MODULES plugin (`colorreload-gtk3-module`). `color-reload-module/CMakeLists.txt:1`.
  - `window-decorations-reload-module/`: GTK 3 GTK_MODULES plugin (`window-decorations-gtk3-module`). `window-decorations-reload-module/CMakeLists.txt:1`.
  - `gtk3proxies/`: `gtk3_preview` executable and `preview.ui`, installed to libexec and `kcm-gtk-module`. `gtk3proxies/CMakeLists.txt:5-7`.
  - `kconf_update/`: config migration files (`gtkconfig.upd`, `gtktheme.cpp`, `remove_deprecated_gtk4_option_v2.cpp`). Contents not read.
  - `LICENSES/`: license texts.

## 2. Theme input (how configuration reaches it)
- KG2.1 Input is KDE configuration, watched through `KConfigWatcher` on four files: kdeglobals, kwinrc, kcminputrc, and the Breeze settings. `kded/gtkconfig.cpp:49-52`. Change handlers: `onKdeglobalsSettingsChange` (`:305`), `onKWinSettingsChange` (`:371`), `onKCMInputSettingsChange` (`:390`), `onBreezeSettingsChange` (`:402`).
- KG2.2 Values come from `ConfigValueProvider` (`kded/configvalueprovider.cpp`). Font, icon, cursor, sound, icon-on-button and menu, and toolbar values are read from it, for example `iconThemeName()` (`:127`), `cursorThemeName()` (`:133`), `cursorSize()` (`:151`), `toolbarStyle()` (`:169`).
- KG2.3 Plasma colors are read through `KColorScheme` (include at `kded/configvalueprovider.cpp:15`) in `ConfigValueProvider::colors()` (`:278`). The function builds a table of `KColorScheme` objects per palette state (active, inactive, disabled) and role (view, window, button, selection, tooltip, complementary, header). `kded/configvalueprovider.cpp:278-300`.
- KG2.4 Environment variables read: `GTK2_RC_FILES` selects the GTK 2 rc file, first entry only (`kded/config_editor/gtk2.cpp:41`). Default path `~/.gtkrc-2.0` (`:43`). `GTK_USE_PORTAL` appears in a condition that also tests for Wayland (`kded/gtkconfig.cpp:45`); the branch body was not read.
- KG2.5 Config directories: `<GenericConfigLocation>/gtk-<N>.0` for N = 2, 3 (`kded/config_editor/utils.cpp:45-49`). The GTK 3 settings file is `gtk-3.0/settings.ini` (`kded/config_editor/settings_ini.cpp:51`).
- KG2.6 Dark-theme name derivation: `Utils::gtk2ThemeName` appends or strips suffixes (`-dark`, `-Dark`, ` dark`, ` Dark`, `dark`, `Dark`) when dark is preferred. `kded/config_editor/utils.cpp:60-75`.
- KG2.7 Dark preference: written to `gtk-application-prefer-dark-theme` in settings.ini (`kded/gtkconfig.cpp:218`) and to the GSettings key `color-scheme` under `org.gnome.desktop.interface` with enum 1 (prefer dark) or 2 (prefer light) (`kded/gtkconfig.cpp:220-222`).
- KG2.8 Keys written to GTK settings: `gtk-theme-name` (`kded/gtkconfig.cpp:69`, `:82`), `gtk-font-name` (`:110`, `:113`), `gtk-icon-theme-name` (`:119`, `:121`), `gtk-sound-theme-name` (`:127`), `gtk-cursor-theme-name` (`:143`, `:145`), `gtk-cursor-theme-size` (`:151`, `:153`), `gtk-xft-dpi` (`:266`). The same key is written to three sinks: GTK 2 rc (`Gtk2ConfigEditor`), GSettings (`GSettingsEditor`, where applicable) and settings.ini (`SettingsIniEditor`).
- KG2.9 Keys written to XSettings by `kded-xsettingsd/gtkconfig-xsettings.cpp`: `Net/ThemeName` (`:46`, dark name derived via `Utils::gtk2ThemeName`), `Gtk/FontName` (`:52`), `Net/IconThemeName` (`:58`), `Net/EnableEventSounds` (`:70`), `Gtk/CursorThemeName` (`:76`), `Gtk/CursorThemeSize` (`:88`, scaled by `xwaylandScale`), `Gtk/ButtonImages` (`:94`), `Gtk/MenuImages` (`:100`).
- KG2.10 The GTK 3 theme name is also stored in GSettings key `gtk-theme` (`kded/gtkconfig.cpp:81`).

## 3. Color and style model
- KG3.1 Color model: a flat `QMap<QString, QColor>` of named colors, keys suffixed `_breeze` (for example `theme_bg_color_breeze`, `theme_fg_color_breeze`, `theme_selected_bg_color_breeze`, `insensitive_bg_color_breeze`). `kded/configvalueprovider.cpp:347-348`, `:352-354`, `:401-406`. The map is returned by `colors()` (`:278`).
- KG3.2 Roles covered by the keys seen: window fg/bg, view bg, selection fg/bg, hover-selected bg, unfocused and insensitive variants (for example `theme_unfocused_bg_color_breeze` `:377`, `insensitive_unfocused_selected_fg_color_breeze` `:433`). The full key list was not read.
- KG3.3 Border derivation: `KColorUtils::mix(background, foreground, bias)` with `bias = frameContrast()`, where `frameContrast()` returns `KColorScheme::frameContrast()`. `kded/configvalueprovider.cpp:281`, `:319-321`, `:504-507`. Lines 319-333 mix window, inactive, disabled and tooltip border colors this way. The mix ratio is whatever `KColorUtils::mix` defines (external, not read).
- KG3.4 Per-state handling: active, inactive, and disabled palette states from `KColorScheme(QPalette::Active|Inactive|Disabled, ...)`. `kded/configvalueprovider.cpp:284-300`. Backdrop is represented as "inactive" in the table; no separate backdrop key was found (UNVERIFIED).
- KG3.5 Window-decoration colors and button images are a separate path: `saveWindowDecorationsToAssets` (`kded/config_editor/custom_css.cpp:19`) and `window_decorations.css` (`:41-50`), built from `kded/scss/window_decorations.scss` by `kded/scss/build_decorations_css.sh` (`kded/scss/CMakeLists.txt:1-6`). The SCSS contents were not read.
- KG3.6 Light and dark: the dark preference is a boolean (KG2.7). The color map is computed from the current KDE color scheme, so the color values follow KDE's active scheme. No separate dark palette was located (UNVERIFIED).

## 4. Output and rendering path
- KG4.1 Input to output, in order:
  1. A KDE config change triggers a handler (`kded/gtkconfig.cpp:350-351` calls `setColors()` when `ColorScheme` or `AccentColor` changes).
  2. `GtkConfig::setColors()` adds the GTK 3 module `colorreload-gtk-module` to `gtk-modules` and calls `m_gsdManager->modulesChanged()` if present. `kded/gtkconfig.cpp:270-275`.
  3. After 200 ms (`:276`, `QTimer::singleShot(200, ...)`), `ConfigValueProvider::colors()` is called and the map is passed to `CustomCssEditor::setColors`. `kded/gtkconfig.cpp:277-279`.
  4. `CustomCssEditor::setColors` runs `addImportStatementsToGtkCssUserFile()` (`kded/config_editor/custom_css.cpp:119-121`), then `modifyColorsCssFile()`.
  5. `modifyColorsCssFile` writes `<config>/gtk-3.0/colors.css` (path at `custom_css.cpp:90`), one line per entry: `@define-color <name> <#rrggbb>;` (`:97`).
  6. The GTK 3 process loads the module `colorreload-gtk3-module`, which watches `<user config>/gtk-3.0/colors.css` with a `GFileMonitor` (`color-reload-module/reloader.c:38-49`, path at `:39-40`, signal `changed` at `:49`).
  7. On change, `reload_colours()` (`reloader.c:17`) removes the old `GtkCssProvider`, creates a new one, adds it with `GTK_STYLE_PROVIDER_PRIORITY_USER+1` (`:26-29`), and loads the file (`gtk_css_provider_load_from_file`).
- KG4.2 Import of colors into GTK CSS: `addImportStatementsToGtkCssUserFile()` (`kded/config_editor/custom_css.cpp:53`) writes import statements into `gtk.css` (path at `:56`). The exact import text was not read (UNVERIFIED).
- KG4.3 Window decorations: `addWindowDecorationsCssFile()` copies `/themes/Breeze/window_decorations.css` into the config directory (`custom_css.cpp:41-50`). `addGtkModule("window-decorations-gtk-module")` is called from `setCustomClientSideDecorations` (`:126-130`). The GTK 3 module `window-decorations-gtk3-module` is built from `window-decorations-reload-module/` (`CMakeLists.txt:1`). Its source was not read.
- KG4.4 GTK modules are added by string: `addGtkModule` reads `gtk-modules` from settings.ini, returns if the name is present, otherwise appends with `:` as separator (`kded/config_editor/custom_css.cpp:104-117`, `SettingsIniEditor::setValue(..., 3)` for GTK 3).
- KG4.5 Breeze GTK theme itself is not generated here. The theme name is written (KG2.8) and the GTK theme is expected to be installed separately (UNVERIFIED: no theme generation code located in this repo).
- KG4.6 The GTK 3 preview executable (`gtk3proxies/preview3.c`, `gtk3proxies/preview.ui`) is launched by `ThemePreviewer::showGtk3App` (`kded/themepreviewer.cpp:21`) through `GtkConfig::showGtkThemePreview` (`kded/gtkconfig.cpp:93-97`). The preview source was not read.

## 5. Extension and integration points
- KG5.1 KDED plugin registration: `K_PLUGIN_CLASS_WITH_JSON(GtkConfig, "gtkconfig.json")` (`kded/gtkconfig.cpp:30`). Installed as `${KDE_INSTALL_PLUGINDIR}/kf6/kded` (`kded/CMakeLists.txt:50`). The JSON metadata file was not read.
- KG5.2 XSettings KDED plugin: `gtkconfig_xsettings` installed to `${KDE_INSTALL_PLUGINDIR}/kf6/kded-x11` (`kded-xsettingsd/CMakeLists.txt:46`). The class `GtkConfigXSettings` writes settings through `XSettingsEditor::setValue` (`kded-xsettingsd/gtkconfig-xsettings.cpp:46`, `:52`). Its use of `ConfigValueProvider` was not checked.
- KG5.3 D-Bus: service `org.kde.GtkConfig` at object `/GtkConfig`, exporting scriptable slots (`kded/gtkconfig.cpp:42-43`). Signal `gtk2ThemeChanged` emitted from `setGtk2Theme` (`:73`). Scriptable method `setGtkTheme` (`kded/gtkconfig.h:51`).
- KG5.4 GTK 3 module discovery: the modules are named in the `gtk-modules` key of settings.ini (KG4.4). GTK loads them from that key; the load mechanism is in GTK and is not in this repo.
- KG5.5 Module install paths: `color-reload-module/CMakeLists.txt:16` and `window-decorations-reload-module/CMakeLists.txt:16` (install rules, destinations not read).
- KG5.6 Version coupling: KF6 and Qt6 (KG1.2). KDecoration3 is required (`CMakeLists.txt:31`). The GTK 3 and GTK 2 version targets are fixed by `gtk-<N>.0` paths (KG2.5). No minimum GTK version was located (UNVERIFIED).
- KG5.7 Wayland: under Wayland, the XSettings path is skipped unless `GTK_USE_PORTAL=1` (`kded/gtkconfig.cpp:45`). The branch body was not read beyond its condition.
- KG5.8 Config migration: `kconf_update/gtkconfig.upd`, `kconf_update/gtktheme.cpp`, `kconf_update/remove_deprecated_gtk4_option_v2.cpp` (names only, not read). The name `remove_deprecated_gtk4_option` suggests a GTK 4 option was once written (UNVERIFIED).

## 6. Data and tooling
- KG6.1 Templates and generated files: `window_decorations.css` from `kded/scss/window_decorations.scss` via `kded/scss/build_decorations_css.sh` (`kded/scss/CMakeLists.txt:1-6`). `colors.css` is generated by code (`custom_css.cpp:87-101`), not from a template.
- KG6.2 Config editors (writers), in `kded/config_editor/`:
  - `gtk2.cpp`: regex-replace of `key = value` lines in the GTK 2 rc file (`replaceValueInGtkrcContents`, `:16-35`); the key is prepended if absent (`:33`).
  - `settings_ini.cpp`: writes GTK 3 settings.ini files (path built at `:51`, `setValue` at `:65`, `unsetValue` at `:89`).
  - `gsettings.cpp`: GSettings writer; checks schema and key existence (`:28-31`), `setValue` (`:34`), `setValueAsEnum` (`:64`).
  - `xsettings.cpp`: edits an xsettingsd config text (`replaceValueInXSettingsdContents`, `:22`; `setValue` `:86`; `unsetValue` `:113`).
  - `custom_css.cpp`: colors.css, gtk.css import lines, window-decoration CSS, and module list (KG4.1-KG4.4).
  - `utils.cpp`: config directory and file read helpers (`:45-49`, `:51`), dark-name derivation (`:60`).
- KG6.3 GTK 3 preview: `gtk3proxies/preview3.c` and `gtk3proxies/preview.ui` (KG4.6). Not read.
- KG6.4 Tests and docs: not located in the survey (UNVERIFIED).

## 7. Facts of note
- KG7.1 Color update is delayed by a fixed 200 ms timer before colors are written (`kded/gtkconfig.cpp:276`). The comment says the delay lets the `gtk-modules` change reach the GTK app first (`:275`).
- KG7.2 The GTK 2 writer deletes and recreates the rc file on every write (`kded/config_editor/gtk2.cpp:48-49`, `gtkrc.remove()` then `gtkrc.open(WriteOnly)`).
- KG7.3 `ConfigValueProvider::colors()` computes many KColorScheme entries from the current scheme on every call (`kded/configvalueprovider.cpp:278-300`).
- KG7.4 GSettings enum values are hard-coded integers with a comment linking to `gdesktop-enums.h` (`kded/gtkconfig.cpp:219-221`).
- KG7.5 Per-file SPDX headers name three licenses, and the `LICENSES/` directory holds seven texts (GPL-2.0-only, GPL-2.0-or-later, GPL-3.0-only, LicenseRef-KDE-Accepted-GPL, BSD-2-Clause, BSD-3-Clause, CC0-1.0). `kded/gtkconfig.cpp:5`.
- KG7.6 The `kded/gtkconfig.cpp` settings path depends on KDE Frameworks (`KConfigWatcher`, `KWindowSystem`, `KColorScheme`). Those are external libraries and are not in this repo.

## 8. Not covered
- `kded/kwin_bridge/`, `kded/gsd-manager/`, and `kded/config_editor/` body of `xsettings.cpp` beyond its function list.
- `window-decorations-reload-module/reloader.c` body and `scss/window_decorations.scss` contents.
- `kconf_update/*` contents, `gtkconfig.json` metadata, `gtk3proxies/*` contents.
- `kded/gtkconfig.cpp:45` branch body, `ConfigValueProvider` lines 33-278 and 300-347 (only the color table start and one full line range were read).
- GTK 4 handling (the name of a removed GTK 4 option appears only in a file name).
- No build was run; `refs/` was not modified.
