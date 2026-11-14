# Darkly: Qt style, Plasma window decoration, colour scheme and Plasma theme (fork of Lightly)

Source: refs/Darkly (shallow clone; commit 473e799, 2026-11-11; branch main; tag v0.5.44 per earlier study notes). License: GNU GPL version 2, `COPYING:7-8` (file `COPYING`). Scope: kstyle/ (Qt style, config, tests), kdecoration/ (window decoration), libdarklycommon/, colors/, desktoptheme/, CMakeLists.txt, kstyle/CMakeLists.txt, kdecoration/CMakeLists.txt, colors/CMakeLists.txt, README.md. Not studied: po/, logos/, flatpak/, nix/, most of kstyle/animations/ and kdecoration/ bodies.
Id prefix: DK.

## 1. Purpose and shape
- DK1.1 Darkly is a Qt widget style, a Plasma window decoration, a colour scheme and a Plasma desktop theme. README: "Forked from the ***lightly*** theme" and "The main goal is to provide a style for **Qt applications**. Other than that we maintain a style for **Plasma window decorations** and a **color scheme**." `README.md` (What to expect section). Languages: C++ with Qt and KDE Frameworks; SVG for the desktoptheme.
- DK1.2 Top-level layout (tracked file counts from `rg --files`): `kstyle/` (104 files: style, animations, config KCM, tests, themerc, kcfg); `kdecoration/` (36 files: decoration, button, settings provider, KCM); `desktoptheme/` (19 files: Plasma SVG theme, `metadata.json.in`); `po/` (12); `logos/` (4); `libdarklycommon/` (3, shared shadow/box helpers); `colors/` (3: `Darkly.colors`, `ExtraDesktop.sh`, CMakeLists); `cmake/` (3); `flatpak/` (3 manifests); `flake.nix`, `nix/` (Nix packaging); `install.sh`, `uninstall.sh`.
- DK1.3 Build system: CMake. Minimums: Qt 6.7.0 (`CMakeLists.txt:17`, `QT_MIN_VERSION`), KF6 6.10.0 (`CMakeLists.txt:14`), Qt5 5.15.2 (`CMakeLists.txt:16`), KF5 5.102.0 (`CMakeLists.txt:13`). Qt5 and Qt6 are selected through `QT_MAJOR_VERSION` (`CMakeLists.txt:54`, `:104`). The style target is `darkly${QT_MAJOR_VERSION}` (`kstyle/CMakeLists.txt:130`). Kirigami2 is required on the Qt5 path (`CMakeLists.txt:78`). The KCM uses Qt Quick components on Qt6 (`kstyle/CMakeLists.txt:63`, `find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets Quick QuickWidgets)`).
- DK1.4 Feature gate: `DARKLY_HAVE_KSTYLE` is set from `KF5FrameworkIntegration_FOUND` (`CMakeLists.txt:88`) or `KF6FrameworkIntegration_FOUND` (`CMakeLists.txt:140`). When it is 0, the base class is `QCommonStyle` (`kstyle/darklystyle.h:68-70`) instead of `KStyle` (`darklystyle.h:71`), and the KStyle-only members are compiled out (`darklystyle.cpp:191`, `:1508`).

## 2. Theme input (how configuration reaches it)
- DK2.1 Style settings: `kstyle/darkly.kcfg` (375 lines) with `<kcfgfile name="darklyrc" />` (`kstyle/darkly.kcfg:6`). Compiled settings class configured by `kstyle/darklystyleconfigdata.kcfgc`. Settings are read through the global config `KSharedConfig` (UNVERIFIED: exact call site for each style key was not traced).
- DK2.2 Decoration settings: `kdecoration/darklysettingsprovider.cpp:36` opens `KSharedConfig::openConfig(QStringLiteral("darklyrc"))`. The decoration and the style share the `darklyrc` file.
- DK2.3 Title-bar colour overrides: `kstyle/darklyhelper.cpp:79-82` read `activeBackground`, `activeForeground`, `inactiveBackground`, `inactiveForeground` from `appGroup`, with `globalGroup` as fallback (`readEntry(..., globalGroup.readEntry(...))`), and the palette Highlight / HighlightedText as final default. Groups are defined earlier in the same function (UNVERIFIED: the group names; lines 79-82 show only the readEntry calls).
- DK2.4 Colour-scheme path from the application: `kstyle/darklyhelper.cpp:71-78` reads the Qt application property `KDE_COLOR_SCHEME_PATH` (`qApp->property("KDE_COLOR_SCHEME_PATH")`). When non-empty it opens that file with `KConfig config(path, KConfig::SimpleConfig)` and reads group `WM`. The enclosing function name was not confirmed (UNVERIFIED).
- DK2.5 Global KDE settings: `KStatefulBrush` and `KColorScheme` are used (`darklyhelper.cpp:104-107`, view focus, hover, negative text, window alternate background).
- DK2.6 Environment variables and command-line flags: None found in the files studied.
- DK2.7 Plasma theme files: `desktoptheme/metadata.json.in` (template) and SVG files under `desktoptheme/widgets/` and `desktoptheme/dialogs/` (for example `desktoptheme/widgets/button.svg`, `desktoptheme/widgets/tabbar.svg`, `desktoptheme/dialogs/background.svg`). The template is processed by CMake (`desktoptheme/CMakeLists.txt`; contents not read).

## 3. Color and style model
- DK3.1 Colour scheme file: `colors/Darkly.colors`, with `[General] ColorScheme=Darkly` and `Name=Darkly` at lines 105-107. Installed by `colors/CMakeLists.txt:1`.
- DK3.2 Palette model: as in Breeze, the style works on `QPalette` roles (`Window`, `WindowText`, `Base`, `Button`, `ButtonText`, `Highlight`, `HighlightedText`, `Text`) and groups `Active`, `Inactive`, `Disabled` (for example `darklyhelper.cpp:182`, `darklyhelper.cpp:190-194`, `darklyhelper.cpp:230`).
- DK3.3 Stateful brushes: `_viewFocusBrush`, `_viewHoverBrush`, `_viewNegativeTextBrush`, `_windowAlternateBackgroundBrush` set from `KStatefulBrush` (`darklyhelper.cpp:104-107`).
- DK3.4 Shade and mix formulas. Darkly uses fixed mix factors with `KColorUtils::mix(a, b, t)` and does not read a frame-contrast value. Each factor is a literal in the source:
  - frame outline = mix(Window, WindowText, 0.25) (`darklyhelper.cpp:127`);
  - frame background = mix(Window, Base, 0.3) (`darklyhelper.cpp:182`);
  - hover-blend colours = mix(hover colour, WindowText or ButtonText, 0.15) (`darklyhelper.cpp:157`, `:163`, `:169`);
  - slider/button outline = mix(Button, ButtonText, 0.3) (`darklyhelper.cpp:230`);
  - sunken background = mix(Button, ButtonText, 0.2) when sunken, else Button (`darklyhelper.cpp:262`);
  - arrow colour = mix(Text, Base, arrowShade) and similar pairs (`darklyhelper.cpp:190-194`).
  Breeze uses `frameContrast()` for the frame factor (see BR3.4 in breeze.md); Darkly does not (`rg` for frameContrast in kstyle/ returned no match).
- DK3.5 Per-state handling: outline and background functions in `kstyle/darklyhelper.cpp` take `mouseOver`, `hasFocus`, `opacity` and an animation mode (for example the frame outline comment "frame outline color, using animations" at `darklyhelper.h:112`, hover outline at `:119` and `:125`, focus outline at `:122`). The blend uses `KColorUtils::mix(focus, hover, opacity)` (`darklyhelper.cpp:136`, `:208`, `:235`, `:268`).
- DK3.6 Animations: `kstyle/animations/` has per-widget engines and data classes (for example `darklywidgetstateengine`, `darklyscrollbarengine`, `darklyspinboxengine`, `darklytabbarengine`, `darklybusyindicatorengine`, `darklydialengine`, `darklyheaderviewengine`, `darklystackedwidgetengine`, `darklytoolboxengine`). These supply the `opacity` used in DK3.5. Engine internals were not read (see section 8).
- DK3.7 Shadows and blur: `ShadowHelper` is constructed with the helper (`kstyle/darklystyle.cpp:180`, `new ShadowHelper(this, *_helper)`) and `BlurHelper` with the style (`darklystyle.cpp:183`). Shadow and blur sources are in `kstyle/darklyshadowhelper.h`, `kstyle/darklyblurhelper*` (UNVERIFIED: exact blur file names), `kstyle/darklymdiwindowshadow.cpp`, `kstyle/darklyframeshadow.h`, `libdarklycommon/`.

## 4. Output and rendering path
- DK4.1 Plugin entry point: `class StylePlugin : public QStylePlugin` (`kstyle/darklystyleplugin.h:28`) with `Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QStyleFactoryInterface" FILE "darkly.json")` (`darklystyleplugin.h:32`). Metadata file `kstyle/darkly.json` contains `{ "Keys": [ "Darkly" ] }`.
- DK4.2 Factory: `StylePlugin::create(key)` returns `new Style` when `key.toLower() == "darkly"` (`kstyle/darklystyleplugin.cpp:30-34`). `StylePlugin::keys()` returns `"Darkly"` (`darklystyleplugin.cpp:39-41`). Lower-casing of the key is applied (compare Breeze, which uses a case-insensitive compare; see BR4.2).
- DK4.3 Style class: `class Style : public ParentStyleClass` (`kstyle/darklystyle.h:76`), with the base chosen at `darklystyle.h:68-71`. Custom elements include `SH_ArgbDndWindow` and `CE_CapacityBar` (`kstyle/darklystyle.cpp` constructor, under `DARKLY_HAVE_KSTYLE`, `darklystyle.cpp:1508-1512`); `CE_CapacityBar` maps to `drawProgressBarControl` (`darklystyle.cpp:1508-1512` region).
- DK4.4 Helper object: the style owns `_helper` (`darklystyle.cpp` member list) and passes it to the shadow helper (`darklystyle.cpp:180`). The helper class is `kstyle/darklyhelper.h` (515 lines) and `kstyle/darklyhelper.cpp` (2171 lines).
- DK4.5 Drawing path: Qt calls the style's overrides (`drawPrimitive`, `drawControl`, `drawComplexControl`; UNVERIFIED: the override list was not enumerated, `kstyle/darklystyle.h` is 680 lines). The style file is `kstyle/darklystyle.cpp` (9066 lines); colour values come from the helper functions in DK3.4-DK3.5.
- DK4.6 Window decoration: `K_PLUGIN_FACTORY_WITH_JSON(DarklyDecoFactory, "darkly.json", registerPlugin<Darkly::Decoration>(); registerPlugin<Darkly::Button>();)` (`kdecoration/darklydecoration.cpp:54`). The decoration plugin metadata file is `kdecoration/darkly.json`. The decoration class is in `kdecoration/darklydecoration.cpp` (1185 lines); the button class is in `kdecoration/darklybutton.cpp` (443 lines), which uses `KDecoration3::ColorGroup` / `ColorRole` / `DecorationButtonType` (`darklybutton.cpp:34-36`).
- DK4.7 Decoration settings object: `kdecoration/darklysettingsprovider.cpp:36` (DK2.2).
- DK4.8 Config KCM: `kstyle/config/darklystyleconfigmodule.cpp` and `kstyle/config/darklystyleconfig.cpp` with UI `kstyle/config/ui/darklystyleconfig.ui`, plugin metadata `kstyle/config/darklystyleconfig.json`. Decoration KCM: `kdecoration/config/kcm_darklydecoration.json`, and desktop service `kdecoration/config/darklydecorationconfig.desktop` (installed as `kservices6`, `kdecoration/CMakeLists.txt:43`).

## 5. Extension and integration points
- DK5.1 Qt style plugin: target `darkly${QT_MAJOR_VERSION}`, installed to `${LIB_TARGET}` (`kstyle/CMakeLists.txt:130`). Selected by name "Darkly" (DK4.2).
- DK5.2 Theme file: `kstyle/darkly.themerc` installed to `${KDE_INSTALL_DATADIR}/kstyle/themes` when not building for flatpak (`kstyle/CMakeLists.txt:132-134`).
- DK5.3 Decoration plugin: installed to `${KDE_INSTALL_PLUGINDIR}/${KDECORATION_PLUGIN_DIR}` (`kdecoration/CMakeLists.txt:42`), with the decoration config desktop file at `kservices6` (`kdecoration/CMakeLists.txt:43`).
- DK5.4 Colour scheme install: `colors/CMakeLists.txt:1` (`install(FILES Darkly.colors ...`; destination not read).
- DK5.5 Application-set colour scheme path: the `KDE_COLOR_SCHEME_PATH` property (DK2.4) lets the application point the style to a `.colors` file.
- DK5.6 ABI and version coupling: uses KDecoration3, KColorScheme, KColorUtils, KStatefulBrush, KSharedConfig (`darklyhelper.cpp:104-107`; `darklybutton.cpp:24`, `:34-36`). Minimum versions in DK1.3. Build-time gate DK1.4 couples the style to the presence of KF framework integration.
- DK5.7 Environment-variable selection: None found in the files studied. Selection is by style name "Darkly" (DK4.2) and by decoration plugin id from `kdecoration/darkly.json`.

## 6. Data and tooling
- DK6.1 Settings schema: `kstyle/darkly.kcfg` (DK2.1), `kstyle/darklystyleconfigdata.kcfgc`.
- DK6.2 Tests: `kstyle/tests/` with `styleconfig_test.cpp`, `blurhelper_test.cpp`, `opaqueinactivewindows_test.cpp`, `dolphinviewopacity_test.cpp`, and `kstyle/tests/CMakeLists.txt`.
- DK6.3 Translations: `kstyle/config/Messages.sh` and `po/` (12 tracked files).
- DK6.4 Packaging: `flatpak/org.kde.KStyle.Darkly5.json`, `flatpak/org.kde.KStyle.Darkly6.9.json`, `flatpak/org.kde.KStyle.Darkly6.10.json`; `flake.nix`, `nix/`; `install.sh`, `uninstall.sh`.
- DK6.5 Shared library: `libdarklycommon/` (3 tracked files; not read).
- DK6.6 Plasma theme template: `desktoptheme/metadata.json.in` (DK2.7).

## 7. Facts of note
- DK7.1 Fork origin: the README states the project is "Forked from the ***lightly*** theme" (`README.md`, What to expect section).
- DK7.2 The style does not depend on `frameContrast()`; mix factors are literals (DK3.4). Breeze reads the factor from KColorScheme (BR3.4).
- DK7.3 The base class depends on the build: `QCommonStyle` when KF framework integration is absent (DK1.4), `KStyle` otherwise.
- DK7.4 Qt Quick is used by the KCM on Qt 6 (`kstyle/CMakeLists.txt:63`). The style plugin itself is a QWidget style.
- DK7.5 License GPL-2.0 (`COPYING:7-8`). The file `COPYING` is GPL text; no per-file SPDX headers were checked (UNVERIFIED).
- DK7.6 A GTK companion project is referenced in the README (`README.md`, GTK style section); it is not in this repo.

## 8. Not covered
- Not read: `kstyle/darklystyle.cpp` bodies (9066 lines); only the constructor members at 180-183, the DARKLY_HAVE_KSTYLE sites at 191 and 1508-1512, and the event filter area at 71-78 were read.
- Not read: `kstyle/animations/*` (engine internals), `kstyle/darklyshadowhelper.cpp`, `kstyle/darklymdiwindowshadow.cpp`, `kstyle/darklyframeshadow.h`, `kstyle/darklymnemonics.cpp`, `kstyle/darklywindowmanager.h`, `kstyle/darklytileset.cpp`.
- Not read: `kdecoration/darklydecoration.cpp` body and `darklybutton.cpp` body beyond the lines cited.
- Not read: `colors/Darkly.colors` colour values; `desktoptheme/` SVG contents; `kstyle/darkly.themerc`; `cmake/`; `libdarklycommon/`; `po/`; the Nix and flatpak packaging beyond file names.
- Not verified: the exact function that contains the `KDE_COLOR_SCHEME_PATH` read (DK2.4) and the group names around `darklyhelper.cpp:79-82` (DK2.3).
- Not verified: the override list of Qt drawing functions in Darkly (DK4.5).
- Spot-check: the following citations were re-read in this session and confirmed: `COPYING:7-8`, `CMakeLists.txt:17`, `kstyle/CMakeLists.txt:130`, `kstyle/darklystyleplugin.cpp:30-34`, `kstyle/darklyhelper.cpp:127`, `kstyle/darklyhelper.cpp:182`, `kstyle/darklyhelper.cpp:230`, `kstyle/darklyhelper.cpp:262`, `kstyle/darklystyle.cpp:180`, `kdecoration/darklydecoration.cpp:54`, `kdecoration/darklysettingsprovider.cpp:36`, `colors/Darkly.colors:107`.
