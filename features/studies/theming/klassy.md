# klassy: KDE Plasma global theme (Qt style, window decoration, colour schemes, icons, Plasma theme, look-and-feel)

Source: refs/klassy (shallow clone; commit 9b788b2, 2026-09-21; branch plasma6.6). License: per-file SPDX headers and `LICENSES/` directory (BSD-3-Clause, CC0-1.0, GPL-2.0-only, GPL-2.0-or-later, GPL-3.0-only, LicenseRef-KDE-Accepted-GPL, MIT; 7 files). No top-level LICENSE or COPYING file was found (`rg --files` at repo root). Scope: kstyle/ (Qt style, config KCM, system icon generator), kdecoration/ (window decoration), libbreezecommon/, colors/, desktoptheme/, look-and-feel/, layout-templates/, icons/ (directory layout and CMake install only), CMakeLists.txt, README.md. Not studied: screenshots/, po/, most of icons/ content.
Id prefix: KL.

## 1. Purpose and shape
- KL1.1 Klassy is "a theming utility for the KDE Plasma desktop environment" that "consists of a Global Theme which applies several components: Window Decoration, Application Style, Colour Scheme, Plasma style, and Icons" (`README.md`, Overview section). Languages: C++ with Qt and KDE Frameworks; SVG for Plasma artwork; QML-free except the layout and look-and-feel scripts (`layout-templates/*/contents/layout.js`, `look-and-feel/*/contents/layouts/org.kde.plasma.desktop-layout.js`).
- KL1.2 Top-level layout (tracked file counts from `rg --files`): `kstyle/` (178 files: Qt style, `config/` KCM and icon generator, `debug/`, `breeze.kcfg`, `klassy.themerc`); `kdecoration/` (87 files: decoration, button, settings provider, KCM); `libbreezecommon/` (53 files, shared shadow and helper code); `icons/` (3443 files: pre-built `klassy` and `klassy-dark` icon themes); `colors/` (6 `.colors` files plus `ExtraDesktop.sh`); `desktoptheme/` (17 files: `klassy-light` and `klassy-dark` Plasma themes); `look-and-feel/` (25 files: Plasma look-and-feel packages); `layout-templates/` (5 files: bottom and left panel layouts); `po/` (8); `screenshots/` (59); `cmake/`; `install.sh`, `uninstall.sh`; `AUTHORS`.
- KL1.3 Build system: CMake, top-level `CMakeLists.txt`. Target names are suffixed with `${QT_MAJOR_VERSION}`: the style is `klassy${QT_MAJOR_VERSION}` (`kstyle/CMakeLists.txt:124`), the decoration is installed as a KWin plugin (`kdecoration/CMakeLists.txt`, not read in full). The decoration and style share `libbreezecommon/`.
- KL1.4 Relation to Breeze: the source tree is a derivative of Breeze. Class names keep the `Breeze` prefix (`kstyle/breezestyle.h:58-65`, `class Style : public ParentStyleClass`), the plugin key file is `kstyle/breeze.json`, and the decoration factory name stays `breeze.json` (`kdecoration/breezedecoration.cpp:46`). Compare with breeze.md (BR1-BR4). Breeze's own minimums are not repeated here.

## 2. Theme input (how configuration reaches it)
- KL2.1 Style settings: `kstyle/breeze.kcfg:6` declares `<kcfgfile name="klassy/klassyrc"/>`. The installed KCFG is renamed `klassy.kcfg` (`kstyle/CMakeLists.txt:127`). Compiled config class is generated from `kstyle/breezestyleconfigdata.kcfgc:1` (`File=breeze.kcfg`).
- KL2.2 Decoration settings: `kdecoration/breezesettingsprovider.cpp:24` opens `KSharedConfig::openConfig(QStringLiteral("klassy/klassyrc"))`. The style-side provider is `kstyle/breezedecorationsettingsprovider.cpp:22` with the same file.
- KL2.3 Decoration presets: `kdecoration/breezesettingsprovider.cpp:99` and `kstyle/breezedecorationsettingsprovider.cpp:74` open `klassy/windecopresetsrc` (presets config, separate from `klassyrc`).
- KL2.4 Colour scheme input: `kstyle/breezehelper.cpp:99-104` reads the Qt application property `KDE_COLOR_SCHEME_PATH`. If the property is empty or equals `"kdeglobals"`, the style uses `KSharedConfig::openConfig()` (global config). Otherwise it opens the given path with `KConfig::SimpleConfig` (`breezehelper.cpp:103`).
- KL2.5 KWin and KDE global config: `kstyle/breezehelper.cpp:58` opens `kwinrc`; `kstyle/breezestyle.cpp:2301` and `:9061` read `KSharedConfig::openConfig()` and group `KDE` (animation and icon keys, as in Breeze). `kdecoration/breezedecoration.cpp:164` stores the global `kdeglobals` config in `s_kdeGlobalConfig`.
- KL2.6 Command-line flags for the KCM tool: `kstyle/config/main.cpp:92-93` defines option `-g` / `--generate-system-icons`. The option is run from `kstyle/config/main.cpp:158-164`, which loads `InternalSettings` and calls the icon generator (see KL4.6).
- KL2.7 Environment variables: None found in the files studied. Selection is by the `KDE_COLOR_SCHEME_PATH` property (KL2.4), not by an environment variable.

## 3. Color and style model
- KL3.1 Colour scheme files: `colors/KlassyLight.colors` (`[General] ColorScheme=KlassyLight`, `Name=Klassy Light`, lines 109-110), `colors/KlassyDark.colors`, `colors/OpalFruitsLight.colors` (`ColorScheme=OpalFruitsLight`, `Name=Opal Fruits Light (Klassy)`, lines 134-135), `colors/OpalFruitsDark.colors` (lines 144-145). `colors/ExtraDesktop.sh` is also present (not read).
- KL3.2 Palette model: same QPalette roles and colour groups as Breeze (`Window`, `WindowText`, `Base`, `Button`, `ButtonText`, `Highlight`, `HighlightedText`; groups `Active`, `Inactive`, `Disabled`). The Klassy helper is `kstyle/breezehelper.h` (459 lines) and `kstyle/breezehelper.cpp` (2017 lines).
- KL3.3 Frame contrast: `kstyle/breezehelper.cpp:105-108`. On Qt 6 (`QT_VERSION >= 6.0.0`) `_contrastBias = KColorScheme::frameContrast();` (line 106). On Qt 5 it is the literal `_contrastBias = 0.2;` (line 108). This is the frame factor used by `frameIntensityBias()` (see BR3.4 for the Breeze header).
- KL3.4 Shade and mix formulas: `KColorUtils::mix` and `KColorUtils::lighten` are used in about 47 places in `kstyle/breezehelper.cpp` (`rg` count). Literal constants: `arrowShade = 0.15` (`breezehelper.cpp:48`), `highlightBackgroundAlpha = Metrics::Blend_Value` (`breezehelper.cpp:50`), and `Blend_Value = 0.3` (`kstyle/breezemetrics.h:170`). The exact formula bodies match the Breeze pattern cited in BR3.5 (UNVERIFIED for every call site in klassy; the counts and the constants above were checked).
- KL3.5 Decoration colour generation: `kstyle/config/systemicongenerator.cpp:47-52` calls `decorationColorsLight.generateDecorationAndButtonColors(QApplication::palette(), m_internalSettings, ...)` with fixed colours `#232629` and `#dee0e2` (`systemicongenerator.cpp:49-52`). The dark set is built the same way at `systemicongenerator.cpp:58-60`. The `DecorationColors` type is used at `systemicongenerator.h:24`; its definition file was not located (UNVERIFIED).
- KL3.6 Button icon scales: `kstyle/config/systemicongenerator.h:28` holds scales `{1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, 3}` and `:29` holds icon sizes `{16, 18, 20, 22, 24, 32, 48}`. Icon types are listed in `m_iconTypes` (`systemicongenerator.h:37-40` and following), mapping `DecorationButtonType` values to names such as `application-menu-symbolic` (line 38) and `window-pin-symbolic` (line 40).
- KL3.7 Per-state handling: the same hover, focus, frame and arrow helpers as Breeze exist in the Klassy helper (names not enumerated in this study; UNVERIFIED for the Klassy-specific functions).

## 4. Output and rendering path
- KL4.1 Plugin entry point: the style is `StylePlugin` in `kstyle/breezestyleplugin.cpp`, with `create(key)` returning `new Style` for `key` equal to "klassy" case-insensitively (`breezestyleplugin.cpp:16-22`). `keys()` returns `"Klassy"` (`breezestyleplugin.cpp:25-27`).
- KL4.2 Style class: `class Style : public ParentStyleClass` (`kstyle/breezestyle.h:65`), base class `QCommonStyle` when the KF integration gate is off, `KStyle` otherwise (`breezestyle.h:58-60`, same pattern as Darkly DK1.4).
- KL4.3 Style file: `kstyle/breezestyle.cpp` (9116 lines), which is the largest source file in the repo; draw functions and polish logic were not read (see section 8).
- KL4.4 Window decoration plugin: `K_PLUGIN_FACTORY_WITH_JSON(KlassyDecoFactory, "breeze.json", registerPlugin<Klassy::Decoration>(); registerPlugin<Klassy::Button>();)` (`kdecoration/breezedecoration.cpp:46`). The metadata file `kdecoration/breeze.json` has `"Name": "Klassy"` (line 5).
- KL4.5 Icon generator: `SystemIconGenerator::generate()` (`kstyle/config/systemicongenerator.cpp:33`) returns early if the button icon style is `StyleSystemIconTheme` (`systemicongenerator.cpp:35-36`). Otherwise it calls `addSystemScales()` (`:39`), reads the task-manager type and side via `PlasmaTools::taskManagerTypeAndSide` (`:41`), and writes under `QStandardPaths::GenericDataLocation` plus `/icons` (`systemicongenerator.cpp:43`), with the light set at `/icons/klassy` (`:45`) and the dark set at `/icons/klassy-dark` (`:58`). Theme display names are `Klassy` and `Klassy Dark` (`:56`, `:69`).
- KL4.6 Generator trigger: from the KCM binary, through the `--generate-system-icons` flag (KL2.6), at `kstyle/config/main.cpp:158-164`; the output line is `i18n("klassy and klassy-dark system icons generated.")` (`main.cpp:164`).
- KL4.7 Icon theme directory writer: `generateIconThemeDir(themeDirPath, themeName, inherits, decorationColors)` (`systemicongenerator.cpp:72-77`) uses `QDir` and writes `index.theme` through `KConfig` (`systemicongenerator.cpp:82`).
- KL4.8 Pre-built icon themes: `icons/klassy/` and `icons/klassy-dark/` (1721 tracked files each). `icons/CMakeLists.txt` installs both directories to `${KDE_INSTALL_DATADIR}/icons` (`icons/CMakeLists.txt:1-4`).
- KL4.9 Plasma desktop theme: `desktoptheme/klassy-light/` and `desktoptheme/klassy-dark/` contain `metadata.json`, `plasmarc`, `colors`, and SVG widgets (for example `desktoptheme/klassy-dark/widgets/panel-background.svgz`, `desktoptheme/klassy-light/widgets/scrollbar.svgz`), with variants `opaque/`, `translucent/`, `solid/` (file list from `rg --files desktoptheme`).
- KL4.10 Look-and-feel packages: `look-and-feel/org.kde.klassylightleftpanel.desktop/`, `look-and-feel/org.kde.klassydarkleftpanel.desktop/`, `look-and-feel/org.kde.klassydarkbottompanel.desktop/`. Each has `metadata.json`, `contents/defaults`, `contents/layouts/org.kde.plasma.desktop-layout.js`, and `contents/plasmoidsetupscripts/org.kde.plasma.battery.js`.
- KL4.11 Layout templates: `layout-templates/org.kde.klassy.plasma.desktop.bottomPanel/` and `...leftPanel/`, each with `metadata.json` and `contents/layout.js`.

## 5. Extension and integration points
- KL5.1 Qt style plugin: `install(TARGETS klassy${QT_MAJOR_VERSION} DESTINATION ${KDE_INSTALL_QTPLUGINDIR}/styles/)` (`kstyle/CMakeLists.txt:124`). Theme file `klassy.themerc` installed to `${KDE_INSTALL_DATADIR}/kstyle/themes` (`kstyle/CMakeLists.txt:125`). KCFG installed as `klassy.kcfg` (`kstyle/CMakeLists.txt:127`).
- KL5.2 Decoration plugin: KWin loads the factory from `kdecoration/breezedecoration.cpp:46`. Install path is in `kdecoration/CMakeLists.txt` (not read).
- KL5.3 Icon themes: `${KDE_INSTALL_DATADIR}/icons/klassy` and `klassy-dark` (KL4.8), and user-generated copies under `GenericDataLocation/icons` (KL4.5).
- KL5.4 Colour schemes: installed by `colors/CMakeLists.txt` (not read). Selected through the Plasma colour-scheme mechanism and by the `KDE_COLOR_SCHEME_PATH` property (KL2.4).
- KL5.5 Shared library: `libbreezecommon/` (53 tracked files) is compiled into both the style and the decoration (`kstyle/CMakeLists.txt` target list not read in full; UNVERIFIED for the decoration target).
- KL5.6 ABI and version coupling: the style uses KColorScheme, KColorUtils, KSharedConfig, KConfig, and the KF framework integration gate (KL3.3, KL4.2). Qt 5 and Qt 6 builds are selected by `QT_MAJOR_VERSION` (KL1.3). Version minimums were not read in `CMakeLists.txt` (UNVERIFIED).
- KL5.7 Environment-variable selection: None found in the files studied.

## 6. Data and tooling
- KL6.1 Settings schema: `kstyle/breeze.kcfg` (KL2.1), `kdecoration/breezesettingsdata.kcfg` (UNVERIFIED: whether it is present in klassy; not read).
- KL6.2 Icon generator: `kstyle/config/systemicongenerator.cpp` and `.h`, invoked by the KCM binary (KL4.5-KL4.7).
- KL6.3 KCM: `kstyle/config/breezestyleconfigmodule.cpp`, `breezestyleconfig.cpp`, `ui/breezestyleconfig.ui`, `ui/klassystyleconfig.qrc`, `klassy-settings.qrc`, `klassystyleconfig.json`, `klassy-settings.desktop`, `sc-apps-klassy-settings.svgz`. The style KCM file names keep the `breeze` prefix.
- KL6.4 Debug tool: `kstyle/debug/breezewidgetexplorer.cpp` and `.h` (not read).
- KL6.5 Tests: none found under `kstyle/` or `kdecoration/` in the file list (UNVERIFIED: tests directory was not searched).
- KL6.6 Packaging: `install.sh`, `uninstall.sh`, `KlassyConfig.cmake.in`, `cmake/`.

## 7. Facts of note
- KL7.1 The icon set is generated at runtime from the current palette (KL4.5) and is also shipped pre-built (KL4.8). The generator returns early when the button icon style is system-theme (KL4.5).
- KL7.2 The frame contrast value differs by Qt major version: `KColorScheme::frameContrast()` on Qt 6, literal `0.2` on Qt 5 (KL3.3).
- KL7.3 Presets live in `klassy/windecopresetsrc`, a file separate from `klassy/klassyrc` (KL2.3).
- KL7.4 The style and decoration both read `klassy/klassyrc`, so the decoration and style share settings (KL2.1-KL2.2).
- KL7.5 Plugin names: style key "Klassy" (KL4.1), decoration name "Klassy" (KL4.4). Both keep the Breeze source naming in file names (KL1.4).

## 8. Not covered
- Not read: `kstyle/breezestyle.cpp` draw and polish bodies (9116 lines); only lines 2301 and 9061 were read.
- Not read: `kstyle/breezehelper.cpp` mix call sites other than the ones cited (KL3.4).
- Not read: `kdecoration/breezedecoration.cpp` body, `kdecoration/CMakeLists.txt`, `kstyle/CMakeLists.txt` beyond lines 124-127, `libbreezecommon/` contents, `colors/CMakeLists.txt`.
- Not read: `kstyle/config/systemicongenerator.cpp` beyond lines 33-50 and 72-82, and the dark icon output path.
- Not read: `desktoptheme/*/metadata.json`, `look-and-feel/*/metadata.json`, `layout-templates/*/contents/layout.js`.
- Not read: `icons/klassy/` content and index files; `screenshots/`; `po/`.
- Not verified: the `DecorationColors` struct location (KL3.5); presence or absence of `kdecoration/breezesettingsdata.kcfg` (KL6.1).
- Spot-check: the following citations were re-read in this session and confirmed: `kstyle/breeze.kcfg:6`, `kstyle/breezehelper.cpp:99-108`, `kstyle/breezestyleplugin.cpp:16-27`, `kdecoration/breezedecoration.cpp:46`, `kdecoration/breeze.json:5`, `kstyle/config/systemicongenerator.cpp:33-36`, `kstyle/config/main.cpp:158-164`, `colors/KlassyLight.colors:109-110`, `colors/OpalFruitsDark.colors:144-145`, `kstyle/breezemetrics.h:170`.
