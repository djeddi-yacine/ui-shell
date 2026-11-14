# qtengine: Qt 6 and Qt 5 platform theme plus widget style, configured by one JSON file

Source: refs/qtengine (shallow clone; commit 1a8b9c5, dated 2026-10-10; branch master). License: LICENSE (BSD 2-Clause License, Copyright (c) 2026, koss). Scope: whole repo (README.md, CMakeLists.txt, Justfile, flake.nix, shell.nix, nix/, src/qt6/, src/qt5/). Source files total about 1,080 lines for Qt 6 and a parallel tree for Qt 5.
Id prefix: QE.

## 1. Purpose and shape
- QE1.1 A Qt 6 (and optionally Qt 5) platform theme plus a widget style, written in C++20 with CMake. It uses the KDE Color Scheme (KColorScheme) format and KDE frameworks; README states the goals as an easy JSON config, Qt5 and Qt6 on one config, KDE app compatibility, and not freezing the Plasma XDG portal. `README.md:3-10`. Build options `BUILD_QT5` and `BUILD_QT6` default ON. `CMakeLists.txt:22-23`.
- QE1.2 Layout:
  - `src/qt6/plugin/`: QPA platform theme plugin `qt6engine-plugin` (class `PlatformTheme`, `main.cpp`, `platformtheme.cpp/.hpp`, `engine.json`).
  - `src/qt6/style/`: Qt widget style plugin `qt6engine-style` (class `ProxyStyle`, `proxystyle.cpp/.hpp`, `plugin.cpp`, `engine.json`).
  - `src/qt6/common/`: shared static library `Qt6EngineCommon` with `common.cpp` (colour-scheme loader), `config/configmanager.*` (JSON config model), `dbus/configwatcher.*` (config change notification).
  - `src/qt5/`: the same four parts for Qt 5, with a Qt5ThemeSupport private dependency.
  - `nix/`: NixOS module (`nix/module.nix`), option schema (`nix/options.nix`), package (`nix/default.nix`), home-manager-style module (`nix/hjem.nix`).
  - `Justfile`: wrappers for configure, build, install, clean.
  - `flake.nix`, `flake.lock`, `shell.nix`: Nix development and packaging entry points.
- QE1.3 Build: `CMakeLists.txt:1-39`. Requires ECM (`CMakeLists.txt:25`), Qt6 min 6.9, Qt5 min 5.15, KF5 min 5.102.0, KF6 min 6.20.0 (`CMakeLists.txt:7-10`). Qt 6 subtree: `find_package(Qt6 ... COMPONENTS Core Gui Widgets DBus)`, optional QuickControls2, `KF6 COMPONENTS Config ColorScheme IconThemes`, and `GuiPrivate` on Qt >= 6.9.0 (`src/qt6/CMakeLists.txt:14-16`). Qt 5 subtree: `Qt5ThemeSupport` with `Private` (`src/qt5/CMakeLists.txt:15`) and KF5 components.
- QE1.4 Plugin install destinations: Qt 6 platform theme to `${PLUGINDIR}/platformthemes` (`src/qt6/plugin/CMakeLists.txt:26`), Qt 6 style to `${PLUGINDIR}/styles` (`src/qt6/style/CMakeLists.txt:16`). PLUGINDIR defaults to `lib/qt6/plugins` unless `QT6_PLUGINDIR` is set (`src/qt6/CMakeLists.txt:1-5`). Qt 5 common library installs to `${QT5_INSTALL_LIBDIR}` (`src/qt5/common/CMakeLists.txt:23`). Output names: `qt6engine-plugin`, `qt6engine-style` (`src/qt6/plugin/CMakeLists.txt:3`, `src/qt6/style/CMakeLists.txt:5`).

## 2. Theme input (how configuration reaches it)
- QE2.1 Config file: JSON. Search order in `findConfig()`:
  1. env `QTENGINE_CONFIG` (path, must exist), `src/qt6/common/config/configmanager.cpp:140-146`.
  2. `$XDG_CONFIG_HOME/qtengine/config.json`, `:148-155`.
  3. `$HOME/.config/qtengine/config.json`, `:157-165`.
  4. each entry of `$XDG_CONFIG_DIRS` (default `/etc/xdg`) plus `/qtengine/config.json`, `:167-177`.
  If none exists, the path is empty and loading fails silently at debug level. `configmanager.cpp:139-179`, `:188-199`.
- QE2.2 Environment variable that selects the platform theme: `QT_QPA_PLATFORMTHEME=qtengine` (README; also a comment at `src/qt6/plugin/platformtheme.cpp:74`). The plugin key match is case-insensitive: `src/qt6/plugin/main.cpp:24`. Nix module sets it via `variables.QT_QPA_PLATFORMTHEME = "qtengine"` (`nix/module.nix:18`).
- QE2.3 Config keys read by `ConfigManager::loadFromPath()` (`src/qt6/common/config/configmanager.cpp:188-238`):
  - theme.colorScheme (path, `~` expanded) `:213`
  - theme.iconTheme `:214`
  - theme.style `:215`
  - theme.quickStyle `:216`
  - theme.fontFixed.family (default "monospace"), .size (default 11), .weight (default -1) `:218-220`
  - theme.font.family (default "Sans Serif"), .size (11), .weight (-1) (same block, `:222-224`, per header defaults)
  - misc.singleClickActivate (default true), misc.menusHaveIcons (true), misc.shortcutsForContextMenus (true) `:226-228`
  - misc.cursorFlashTime (1000), misc.mouseDoubleClickInterval (400), misc.toolButtonStyle (4), misc.dialogButtonBoxLayout (0), misc.keyboardScheme (2), misc.uiEffects (0), misc.wheelScrollLines (3) `:230-236`
  - misc.dialogTheme (string) `:237`
  Helpers: `getPath` (with `~` expansion via `homeString`), `getString`, `getInt`, `getBool`, `valueAtPath` (dotted path). `configmanager.cpp:26-135`. Defaults in the header: `src/qt6/common/config/configmanager.hpp:21-45`.
- QE2.4 Parsing: `QFile` read as text, `QJsonDocument::fromJson`; on parse error the function returns and keeps previous values. `src/qt6/common/config/configmanager.cpp:189-209`. Top-level must be an object. `:204-208`.
- QE2.5 Singleton: `configManager()` builds a static `ConfigManager` and calls `init()` once. `src/qt6/common/config/configmanager.cpp:240-245`.
- QE2.6 Live reload: `ConfigWatcher` (singleton, `ConfigWatcher::instance()`, `configwatcher.cpp:25`) watches the config path with `QFileSystemWatcher` (`setupFileWatching()` at `src/qt6/common/dbus/configwatcher.cpp:95-110`) and debounces changes (`:43-45`). It registers a session-bus object `/org/qtengine/ConfigWatcher` on service `org.qtengine.ConfigWatcher` (`:21-23`, `:79-90`) so other qtengine processes receive `configChanged` (`:137-162`). On change, `PlatformTheme::onConfigChanged()` reloads config, re-arms the watcher, calls `applySettings()` and `loadDialogTheme()`. `src/qt6/plugin/platformtheme.cpp:271-276`.
- QE2.7 Environment variables used by qtengine (besides QT_QPA_PLATFORMTHEME): `QTENGINE_CONFIG`, `XDG_CONFIG_HOME`, `HOME`, `XDG_CONFIG_DIRS` (`configmanager.cpp:140-177`).
- QE2.8 Qt Quick style: when Widgets and QuickControls2 are both present, `cfg.quickStyle` is passed to `QQuickStyle::setStyle`. `src/qt6/plugin/platformtheme.cpp:51`, `:90-94`.
- QE2.9 No command-line flags are defined by this project. UNVERIFIED: none were searched beyond the source tree.

## 3. Color and style model
- QE3.1 Colours are not stored in qtengine's own format. The colour scheme is a KDE `.colors` file (KColorScheme), set by `theme.colorScheme`. The plugin opens it with `KSharedConfig::openConfig(filePath)`, calls `reparseConfiguration()`, and converts it with `KColorScheme::createApplicationPalette(config)` into a `QPalette`. `src/qt6/common/common.cpp:8-11`. Declared as `Style::loadColorScheme` at `src/qt6/common/common.hpp:8`.
- QE3.2 Palette storage: `std::optional<QPalette> mPalette` in the theme. `src/qt6/plugin/platformtheme.hpp:58`. Set in `applySettings()`: empty colorScheme resets it, otherwise `Style::loadColorScheme(cfg.colorScheme)`. `src/qt6/plugin/platformtheme.cpp:222-223`.
- QE3.3 Fonts: `QFont(cfg.font, cfg.fontSize, cfg.fontWeight)` for the system font and `QFont(cfg.fontFixed, cfg.fontFixedSize, cfg.fontFixedWeight)` for the fixed font, `src/qt6/plugin/platformtheme.cpp:220-221`. Font weight is passed as the raw integer from the config.
- QE3.4 Colour-scheme propagation: the path is also stored as the application dynamic property `KDE_COLOR_SCHEME_PATH` so KColorScheme in the process uses it (`src/qt6/plugin/platformtheme.cpp:88`, `:227-231`). An event filter re-applies settings if another component clears that property (KColorSchemeManager case). `src/qt6/plugin/platformtheme.cpp:262-269`.
- QE3.5 Style-level colour and state: the style itself does not compute colours. `ProxyStyle` only overrides one style hint: `SH_ItemView_ActivateItemOnSingleClick` returns `cfg.singleClickActivate`; everything else goes to `QProxyStyle`. `src/qt6/style/proxystyle.cpp:32-45`.
- QE3.6 Derived shades, hover, pressed, disabled, focus and backdrop: none computed by qtengine. They come from KColorScheme (inside `createApplicationPalette`) and from the base Qt style. UNVERIFIED: the KColorScheme internal formulae were not in this repo.
- QE3.7 Dark/light: not handled by qtengine code. The palette is whatever the .colors file declares. UNVERIFIED: no colour-scheme-mode (dark vs light) logic was found in `src/`.

## 4. Output and rendering path
- QE4.1 Platform theme plugin: `class QtEngineThemePlugin : QPlatformThemePlugin`, `Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QPA.QPlatformThemeFactoryInterface.5.1" FILE "engine.json")`, `create(key, params)` returns `new PlatformTheme()` for key "qtengine". `src/qt6/plugin/main.cpp:14-30`. Metadata key list: `src/qt6/plugin/engine.json:2`.
- QE4.2 Theme class: `class PlatformTheme : public QGenericUnixTheme` (`src/qt6/plugin/platformtheme.hpp:22-24`). Constructor (`src/qt6/plugin/platformtheme.cpp:76-111`) initialises the fonts from the generic Unix theme, calls `applySettings()` when `QGuiApplication::desktopSettingsAware()`, sets `KDE_COLOR_SCHEME_PATH`, optionally sets the QuickControls style, loads the dialog theme, installs an event filter, and connects `ConfigWatcher` on a queued connection.
- QE4.3 Overrides on the QPA theme:
  - `palette(SystemPalette)` returns `mPalette` if set, else the generic palette. `src/qt6/plugin/platformtheme.cpp:113-116`.
  - `font(SystemFont | FixedFont)` returns `mFont` or `mFixedFont`. `:118-121`.
  - `themeHint()` maps: CursorFlashTime, MouseDoubleClickInterval, ToolButtonStyle, SystemIconThemeName (= theme.iconTheme), StyleNames (= {"qtengine"}), IconThemeSearchPaths (`iconPaths()`), DialogButtonBoxLayout, KeyboardScheme, UiEffects, WheelScrollLines, ShowShortcutsInContextMenus, ShowIconsInMenus. `src/qt6/plugin/platformtheme.cpp:141-158`. Others fall back to `QGenericUnixTheme::themeHint`.
  - `iconPaths()`: `~/.icons` plus `<GenericDataLocation>/icons`, filtered to existing directories. `src/qt6/plugin/platformtheme.cpp:123-139`.
  - `fileIcon()` uses `QMimeDatabase` icon names; `createIconEngine()` returns `KIconEngine(iconName, KIconLoader::global())`. `src/qt6/plugin/platformtheme.cpp:161-175`.
  - Dialogs: `usePlatformNativeDialog` and `createPlatformDialogHelper` delegate to an optional secondary theme loaded from `misc.dialogTheme` (`QPlatformThemeFactory::create(name)`), ignored if the name is "qtengine" or if the app is an xdg-desktop-portal backend. `src/qt6/plugin/platformtheme.cpp:177-210`.
- QE4.4 applySettings() order: font and palette load; `Qt::AA_DontShowIconsInMenus` from menusHaveIcons; KDE_COLOR_SCHEME_PATH; on a later update (`mUpdate`): icon theme reload (`QIconLoader::instance()->updateSystemTheme()` and `KIconLoader::global()->newIconLoader()`), `QWindowSystemInterface::handleThemeChange()`, `QApplication::setFont(mFont)`, post `QEvent::ThemeChange` to all widgets, and if style changed and current style is qtengine, re-create the style. `src/qt6/plugin/platformtheme.cpp:212-260`.
- QE4.5 Style plugin: `class StylePlugin : QStylePlugin`, `Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QStyleFactoryInterface" FILE "engine.json")`, `create("qtengine")` returns `new ProxyStyle()`. `src/qt6/style/plugin.cpp:8-16`. Metadata: `src/qt6/style/engine.json:2`.
- QE4.6 ProxyStyle: a `QProxyStyle` whose base style is `theme.style` (QStyleFactory key, case-insensitive) unless it is empty or "qtengine", in which case the base is "Fusion". Failure to create falls back to Fusion. `src/qt6/style/proxystyle.cpp:16-29`.
- QE4.7 Call chain, in order:
  1. Process starts with QT_QPA_PLATFORMTHEME=qtengine; Qt loads `platformthemes/qt6engine-plugin.so`, which calls `QtEngineThemePlugin::create("qtengine")` (QE4.1).
  2. `PlatformTheme` constructor reads config through `configManager()` (QE2.5) and calls `applySettings()` (QE4.4).
  3. Qt sets the widget style from `QPlatformTheme::StyleNames` = {"qtengine"} (QE4.3, `desktopStyleKey()` in qtbase, see the qtbase study QB2.9).
  4. `QStyleFactory::create("qtengine")` loads `styles/qt6engine-style.so` (QE4.5), which creates `ProxyStyle` (QE4.6) on the base style.
  5. `ProxyStyle` delegates all drawing to the base style (QProxyStyle behaviour), except the overridden style hint in QE3.5.
- QE4.8 No SVG, pixmap, QSS or generated theme file is written. The colour and font state live in memory only.

## 5. Extension and integration points
- QE5.1 Plugin interfaces: `QPlatformThemePlugin` (IID `org.qt-project.Qt.QPA.QPlatformThemeFactoryInterface.5.1`) and `QStylePlugin` (IID `org.qt-project.Qt.QStyleFactoryInterface`). `src/qt6/plugin/main.cpp:16-18`, `src/qt6/style/plugin.cpp:10`.
- QE5.2 Discovery: Qt's QFactoryLoader finds `platformthemes/` and `styles/` under the Qt plugin path (installed to `lib/qt6/plugins` by default, `src/qt6/CMakeLists.txt:1-5`). Key match: "qtengine" (plugin key from `engine.json`).
- QE5.3 Dependency on private Qt: `Qt6::GuiPrivate` is found (`src/qt6/CMakeLists.txt:14-16`) and linked by the plugin (`src/qt6/plugin/CMakeLists.txt:17-19`). The plugin includes `private/qiconloader_p.h` (`src/qt6/plugin/platformtheme.cpp:57`) and `private/qgenericunixtheme_p.h` or, as fallback, `private/qgenericunixthemes_p.h` (`:63-66`). Qt5 build uses `Qt5ThemeSupport Private` (`src/qt5/CMakeLists.txt:15`). So the plugin is tied to the Qt private ABI of its build version.
- QE5.4 Version coupling: Qt >= 6.9 for the Qt 6 build (`CMakeLists.txt:8`, `src/qt6/CMakeLists.txt:21`), KF6 >= 6.20 (`CMakeLists.txt:10`). Qt 5 >= 5.15, KF5 >= 5.102 (`CMakeLists.txt:8-9`).
- QE5.5 DBus: the plugin exports its config watcher on the session bus (QE2.6) and consumes it. Interface name `org.qtengine.ConfigWatcher`, object `/org/qtengine/ConfigWatcher`. `src/qt6/common/dbus/configwatcher.cpp:21-23`.
- QE5.6 NixOS: `nix/module.nix` sets `QT_QPA_PLATFORMTHEME` (`:18`); `nix/options.nix` defines a freeform config with `configFormat.type` and declared sub-options (`nix/options.nix:33-42`). `nix/default.nix` passes `-DQT6_PLUGINDIR=${qt6Packages.qtbase.qtPluginPrefix}` and `-DQT5_PLUGINDIR=...` (`nix/default.nix:33-36`), and the Qt 5 part goes to a separate `qt5` output (`nix/default.nix:16`).

## 6. Data and tooling
- QE6.1 Config schema and reference: README points to an external wiki for all options (`README.md:120`, https://github.com/kossLAN/qtengine/wiki/Config-Options) and gives an example JSON block after it (`README.md:120-146`). The AUR and NixOS docs mention `/etc/qtengine/config.example.json`, which is not in this repo (`README.md:82`). UNVERIFIED: no config.example.json exists in the clone.
- QE6.2 Nix module options: `nix/options.nix` (config as freeform JSON type). `nix/module.nix` sets env var and writes the config.
- QE6.3 Justfile recipes: configure (Ninja), build, release, install, clean (`Justfile:1-47`). Creates `compile_commands.json` symlink (`Justfile:24`).
- QE6.4 Tests: none found in the tree (no test directory or test target in the listed files).
- QE6.5 Docs: `README.md` only. No man pages in the tree.
- QE6.6 Generators and templates: none found.

## 7. Facts of note
- QE7.1 The README requires building both Qt5 and Qt6 builds for the theme to work with both toolkit generations: "You will also need a Qt5 AND Qt6 build of your theme for things to work!" `README.md` (note near the end, before Credits).
- QE7.2 Credits: the README names hyprqt6engine and qt6ct as the foundation. `README.md` (Credits section).
- QE7.3 `misc.singleClickActivate` defaults to true in code (`src/qt6/common/config/configmanager.cpp:226`) and is documented in the nix example set to false. Both values exist in the sources cited.
- QE7.4 Config is re-read only on the file-watch or DBus signal; there is no polling. `src/qt6/common/dbus/configwatcher.cpp:43-45`, `:95-110`.
- QE7.5 `getPath` applies `homeString` (`~` and `~/` expansion, no-op when HOME is empty) to both the default and the value. `src/qt6/common/config/configmanager.cpp:39-51`, `:53-67`. The only key read through `getPath` is `theme.colorScheme` (`:213`).
- QE7.6 Dialog-theme fallback is skipped when the config name is "qtengine" or when running as an xdg-desktop-portal backend. `src/qt6/plugin/platformtheme.cpp:196-200`.
- QE7.7 The Qt 5 and Qt 6 trees are copies of the same design (same file names and config code); differences observed are the private-library dependency (`src/qt5/CMakeLists.txt:15`) and the install variables. UNVERIFIED: a line-by-line diff was not run.

## 8. Not covered
- Full Qt 5 source (src/qt5/*.cpp) was located and checked for IID, plugin install and private dependency, not read line by line.
- The KColorScheme internals (createApplicationPalette, shade formulae) inside KDE Frameworks, which are not in this repo.
- The nix/hjem.nix and nix/default.nix bodies beyond the cmake flags and the qt5 output.
- flake.nix, shell.nix, flake.lock.
- The qt6 configwatcher.cpp lines 79-94 and 137-182 in detail (registration and remote connection logic).
- The README wiki content (external, not in repo).
