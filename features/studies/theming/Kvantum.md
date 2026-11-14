# Kvantum: SVG-and-kvconfig widget style for Qt 6, Qt 5 and Qt 4, with a theme manager GUI

Source: refs/Kvantum (git clone; HEAD 7ffda1b, dated 2026-10-31; branch master). Project root for citations is `refs/Kvantum/Kvantum/` (the repo has one nested `Kvantum/` directory). Citations below are `path:line` relative to `refs/Kvantum/` unless the path starts with `Kvantum/`, which is relative to the repo root. In this study `style/` means `Kvantum/style/`.
Id prefix: KV.

## 1. Purpose and shape
- KV.1 Repo contents: `Kvantum/style/` (widget style plugin), `Kvantum/kvantummanager/` (theme manager GUI), `Kvantum/kvantumpreview/` (preview app), `Kvantum/themes/` (theme folders and color files), `Kvantum/color/` (one KDE color file), `Kvantum/doc/` (PDF and sample theme), plus `CMakeLists.txt`, `kvantum.pro`, `INSTALL.md`, `README.md`, `ChangeLog`, `NEWS`. Counted: 320 files.
- KV.2 Four build targets: the style plugin, the manager, the preview, and the theme set. The Qt major version is chosen in `Kvantum/style/CMakeLists.txt`: Qt 6 by default (`:8-9`), Qt 5 when `ENABLE_QT5` is set (`:17`), Qt 4 when `ENABLE_QT4` is set (`:22-23`). Options are declared at `Kvantum/CMakeLists.txt:10-13` (`ENABLE_QT4`, `ENABLE_QT5`, `WITHOUT_KF`, `WITHOUT_X11`).
- KV.3 Plugin name and keys: the style is named `kvantum` and `kvantum-dark`. `Kvantum/style/kvantum.json:2` lists the keys. `Kvantum/style/KvantumPlugin.cpp:22-30` returns `new Style(false)` or `new Style(true)` for them. Plugin metadata: `Kvantum/style/KvantumPlugin.h:26` (IID `org.qt-project.Qt.QStyleFactoryInterface`, file `kvantum.json`).
- KV.4 Source split: Qt 6 builds `Kvantum/style/*.cpp` (list at `Kvantum/style/CMakeLists.txt:85-97`). Qt 5 builds the parallel `Kvantum/style/qt5/*` set (list at `:99-112`). Qt 4 has its own tree under `Kvantum/style/qt4/`. About 17,000 lines per main class file (`Kvantum/style/Kvantum.cpp` 17,066 lines; `Kvantum/style/qt5/Kvantum5.cpp` 16,906 lines).
- KV.5 Qt 6 target is a `SHARED` library named `kvantum` (`Kvantum/style/CMakeLists.txt:125`).

## 2. Theme input
- KV.6 A theme is an `.svg` file plus a `.kvconfig` file, both named after the theme. `Kvantum/style/Kvantum.cpp:447-448` loads the built-in fallback SVG `:/Kvantum/default.svg` and config `:/Kvantum/default.kvconfig` (`Kvantum/style/Kvantum.cpp:446` constructs the config).
- KV.7 Theme directory test: a folder counts as a theme folder when `<name>/<name>.kvconfig` or `<name>/<name>.svg` exists under a `.../Kvantum` path or a `.../Kvantum/<name>` layout (`Kvantum/style/Kvantum.cpp:451-466`).
- KV.8 User theme path: `$XDG_CONFIG_HOME/Kvantum/<theme>/<theme>.kvconfig` and `<theme>.svg` (`Kvantum/style/Kvantum.cpp:515-520`). Other search paths are listed at `:532` and `:554-566` (`~/.themes/<name>/Kvantum/`).
- KV.9 The active theme is chosen from `$XDG_CONFIG_HOME/Kvantum/kvantum.kvconfig` key `theme` (`Kvantum/style/Kvantum.cpp:172` file path; `:193-194` key read). If that file is missing, the code searches `ConfigLocation` folders for another `Kvantum/kvantum.kvconfig` (`:173-186`). An `[Applications]` group maps an application name to a theme (`:200`). The application name check excludes `kvantummanager` and `kvantumpreview` (`:197`).
- KV.10 Dark variant: `Style::Style(bool useDark)` (`Kvantum/style/Kvantum.cpp:150`) passes `useDark` into `setTheme` (`:231`, definition at `:470`). For a dark theme the code looks for `<name>Dark` (`:504` and `:511-541`).
- KV.11 Config file format: INI read through `QSettings` (`Kvantum/style/themeconfig/ThemeConfig.cpp:82`). Lookup is `getValue(group, key)` (`:85-100`), with an optional inheritance chain `getValue(group, key, inherits)` (`:102-`).
- KV.12 Default theme keys (`Kvantum/style/themeconfig/default.kvconfig`): 41 section headers. Examples: `[%General]` at `:1` with `respect_DE=true` (`:5`), `x11drag=true` (`:6`), `composite=true` (`default.kvconfig:12`), `splitter_width=7`. Section headers include `[GeneralColors]` (`:22`), `[Hacks]` (`:43`), `[PanelButtonCommand]` (`:46`), `[Window]` (`:354`).
- KV.13 Naming mismatch to note: the file header is `[%General]` (`default.kvconfig:1`), but the code reads group `General` (`ThemeConfig.cpp:617`, `:723`, `:734`). UNVERIFIED how QSettings decodes the `%` prefix on group names.

## 3. Color and style model
- KV.14 Colors are read from `[GeneralColors]` into `color_spec` by `ThemeConfig::getColorSpec()` (`Kvantum/style/themeconfig/ThemeConfig.cpp:1038-1125`). First key read: `window.color` (`:1043`). Other keys include `base.color`, `alt.base.color`, `button.color`, `highlight.color`, `text.color`, `link.color`, and `inactive.*` variants (`:1046-1125`).
- KV.15 Each element's geometry and color come from its own section: `frame_spec`, `interior_spec`, `indicator_spec`, `label_spec`, `size_spec`, `theme_spec`, `color_spec`, `hacks_spec` are typedef structs in `Kvantum/style/themeconfig/specs.h` (closing lines `:226`, `:258`, `:316`, `:347`, `:361`, `:369`, `:379`, `:418`). Lookup functions: `getFrameSpec` (`ThemeConfig.cpp:137`), `getInteriorSpec` (`:259`), `getIndicatorSpec` (`:308`), `getLabelSpec` (`:350`), `getSizeSpec` (`:526`).
- KV.16 Frame element keys: `frame.element`, `frame.top`, `frame.bottom`, `frame.left`, `frame.right` (`default.kvconfig:46-51` for `[PanelButtonCommand]`); code reads `frame.element` at `ThemeConfig.cpp:167`.
- KV.17 The palette is forced onto the app: `Style::polish(QApplication*)` builds `app->palette()`, calls `polish(palette)` and `app->setPalette(palette)` (`Kvantum/style/polishing.cpp:1022-1048`). `Style::polish(QPalette&)` is at `:1055`. Colors are set per role and per group (`Active`, `Inactive`, `Disabled`) at `polishing.cpp:123-132`.
- KV.18 Base palette: `Style::standardPalette()` (`Kvantum/style/polishing.cpp:1203`) uses `cspec_.windowColor`, `inactiveWindowColor`, `baseColor`, and `inactiveBaseColor` (`:1212-1229`).
- KV.19 `respect_DE`: when set, `Kvantum/style/Kvantum.cpp:237-247` reads `XDG_CURRENT_DESKTOP`. On `gnome` or `pantheon` it sets `iconless_pushbutton`, `iconless_menu` and disables `blurring` (`:238-246`).
- KV.20 KDE color file: the manager collects `<theme>.colors` (and `<name>Dark.colors`) paths for a theme (`Kvantum/kvantummanager/KvantumManager.cpp:690`, `:701`). The repo ships `Kvantum/color/Kvantum.colors`, installed to the KDE color directory for Qt 6 (`Kvantum/style/CMakeLists.txt:179`; `Kvantum/color/README:1`). The style sources do not read `.colors` files (search of `Kvantum/style` for `.colors` returned only comments at `polishing.cpp:457`).

## 4. Output and rendering path
- KV.21 SVG element lookup: each element name is sent to `QSvgRenderer::elementExists` and `render(painter, element)` (`Kvantum/style/rendering.cpp:57`, `:94`, `:112`). Drawing wrapper: `drawSvgElement` (`rendering.cpp:30-40`) renders into a transparent `QPixmap` at the device pixel ratio.
- KV.22 Element name suffixes: a state suffix is mapped to `-normal` when the state-specific element is missing: `-toggled`, `-pressed` and `-focused` all fall back to `-normal` (`rendering.cpp:60-62`). `-inactive` is removed as a fallback (`:57-58`, `:71`). A `-pattern` suffix selects a tiled pattern (`:94`, `:112`).
- KV.23 Missing theme elements fall back to the built-in SVG: `defaultRndr_` is used when the theme renderer lacks the element (`rendering.cpp:71-73`).
- KV.24 Per-application hooks: the style checks application names for behaviour switches (`Kvantum/style/polishing.cpp:1022-1040`: names `dolphin` at `:1028`, `kvantummanager` and `Kvantum Manager` at `:1036`, plasma names at `:1040`; `pcmanfm-qt`, `soffice.bin` and `krita` are checked in the same branch chain). Opaque apps are listed in `[%General] opaque=` (`default.kvconfig:20`).
- KV.25 Event handling is in `Kvantum/style/eventFiltering.cpp` (1,649 lines); animation is in `Kvantum/style/animation/animation.cpp`; blur is in `Kvantum/style/blur/blurhelper.cpp`; window drag is in `Kvantum/style/drag/windowmanager.cpp`. Each is a separate file in the Qt 6 source list (`Kvantum/style/CMakeLists.txt:85-97`).

## 5. Extension and integration points
- KV.26 Theme authoring: `Kvantum/doc/Theme-Config.pdf` and `Kvantum/doc/Theme-Making.pdf` are documents, not parsed by the build. `Kvantum/doc/Theme-Config` is UTF-8 text (checked with file(1); not read).
- KV.27 Manager GUI: `Kvantum/kvantummanager/KvantumManager.cpp` (3,018 lines) with `KvCommand.cpp` (undo commands, 259 lines) and `svgicons.cpp` (104 lines). Entry point `main` at `Kvantum/kvantummanager/main.cpp:27`. Startup help text at `:42-43`.
- KV.28 The manager writes the global theme file: `$XDG_CONFIG_HOME/Kvantum/kvantum.kvconfig` key `theme` is set to the chosen theme, or `Default#`, or removed (`Kvantum/kvantummanager/KvantumManager.cpp:881-899`; second file reference at `:996`).
- KV.29 Preview app: `Kvantum/kvantumpreview/` (`main.cpp`, `KvantumPreview.h`, `KvantumPreviewBase.ui`). Its build file is `Kvantum/kvantumpreview/CMakeLists.txt`.
- KV.30 Dependencies: Qt 6 `Core Gui Widgets Svg` (`Kvantum/style/CMakeLists.txt:9`). X11 is required unless `WITHOUT_KF` is set (`:10-11`). The code defines `NO_KF` and `NO_X11` when the options are set (`Kvantum/style/CMakeLists.txt:76-81`).

## 6. Data and tooling
- KV.31 Shipped themes: `Kvantum/themes/kvthemes/<Name>/<Name>.kvconfig` folders and `Kvantum/themes/colors/*.colors` files. A combined count of 38 `.kvconfig` files was found under `Kvantum/themes/kvthemes/` and `Kvantum/style/themeconfig/`. The build of themes is `Kvantum/themes/CMakeLists.txt`.
- KV.32 Build tools: CMake for the Qt 6/5 builds and `kvantum.pro` / `style/style.pro` for qmake. `Kvantum/style/style.pro:27` sets `TARGET = kvantum`.
- KV.33 Qt 6 style install directory: `Kvantum/style/CMakeLists.txt:34-40` gets the plugin install directory from `Qt6::qmake`, then `KVANTUM_STYLE_DIR` is `<plugin dir>/styles/` (`:40`). Qt 5 path at `:58`, Qt 4 path at `:67`.
- KV.34 No test files were found in the repo (file-name search for "test").

## 7. Facts of note
- KV.35 Config keys are case-sensitive strings read with `getValue`. The style reads `General` where the default theme file header says `%General` (KV.13).
- KV.36 The `Style` class is a `QCommonStyle` subclass (`Kvantum/style/Kvantum.h:89`), not a `QProxyStyle`.
- KV.37 The Qt 6 and Qt 5 sources are parallel copies of the same logic (for example `Kvantum/style/polishing.cpp` 1,394 lines and `Kvantum/style/qt5/polishing5.cpp`). Differences between the copies were not diffed.
- KV.38 Lookup fallback uses `QFile::exists` checks at each candidate path (KV.7 to KV.9), not a manifest.

## 8. Not covered
- KV.39 `eventFiltering.cpp`, `animation.cpp`, `blurhelper.cpp`, `windowmanager.cpp`, `viewItems.cpp`, `standardIcons.cpp`, `shortcuthandler.cpp` were not read in full; only the filenames are cited.
- KV.40 The Qt 4 and Qt 5 trees were not compared with Qt 6 line by line.
- KV.41 The manager's full GUI logic (3,018 lines) was sampled at the cited lines only.
- KV.42 The PDF documents were not read; `Kvantum/doc/Theme-Config` was not read.
- KV.43 No build or run was done. No commands were run inside `refs/`.
