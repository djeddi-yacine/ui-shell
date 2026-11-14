# qqc2-desktop-style: QML style (org.kde.desktop) that paints Qt Quick Controls through QStyle

Source: refs/qqc2-desktop-style (shallow clone; commit d6bac58, 2026-11-13; branch master). License: per-file SPDX headers using LICENSES/ texts (for example `plugin/kquickstyleitem.cpp:8`: `LGPL-3.0-only OR GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KFQF-Accepted-GPL OR LicenseRef-Qt-Commercial`). Scope: whole repo, with depth on `plugin/kquickstyleitem.cpp` (+ `_p.h`), `org.kde.desktop/Button.qml`, and `kirigami-plasmadesktop-integration/` (palette bridge). The `tests/` directory and the translation files (`poqm/`) were not read.
Id prefix: QDS.

## 1. Purpose and shape
- QDS1.1 A Qt Quick Controls (QML) style named `org.kde.desktop` that draws the controls with the application's `QStyle` (the widget style) instead of its own QML. Language: C++ (plugin and integration) and QML (control templates). Target: Qt 6 (`CMakeLists.txt:8` sets `REQUIRED_QT_VERSION 6.10.0`; `CMakeLists.txt:26` requires Qt6 Core, Quick, Gui, Widgets, QuickControls2) and KDE Frameworks 6 (`CMakeLists.txt:10` ECM 6.32.0; `CMakeLists.txt:45` KF6 Config and KirigamiPlatform are required; `CMakeLists.txt:48-49` KF6IconThemes and KF6ColorScheme are optional). The README states the style is "not public API" (`README.md:5`).
- QDS1.2 Top-level layout:
  - `plugin/`: C++ QML type `StyleItem` (`KQuickStyleItem`) that calls `QStyle` draw functions. Module `org.kde.qqc2desktopstyle.private` (`plugin/CMakeLists.txt:1`).
  - `org.kde.desktop/`: QML control templates (Button.qml, CheckBox.qml, ComboBox.qml, ... 63 files by `rg --files -g '*.qml'` under that directory) that set `StyleItem` as background or indicator. Module `org.kde.desktop` (`CMakeLists.txt:105`).
  - `kirigami-plasmadesktop-integration/`: a Kirigami platform plugin (`PlasmaDesktopTheme`, `PlasmaDesktopUnits`, animation speed provider) that converts KColorScheme data to a QPalette and to Kirigami theme properties. Installed to `${KDE_INSTALL_PLUGINDIR}/kf6/kirigami/platform` (`kirigami-plasmadesktop-integration/CMakeLists.txt:36`).
  - `tests/`: QML test pages (for example `tests/testBars.qml`). Not read in detail.
  - `CMakeLists.txt`, `KF6QQC2DesktopStyleConfig.cmake.in`: CMake package for the framework (`CMakeLists.txt:70-88`).
  - `metainfo.yaml`, `Mainpage.dox`, `Messages.sh`, `poqm/`, `.kde-ci.yml`, `.gitlab-ci.yml`: metadata, docs and CI. Not read in detail.
- QDS1.3 Build dependencies: declared in `CMakeLists.txt:26, 45, 48-49` and `plugin/CMakeLists.txt:8-15` (Qt Core/Quick/Gui/Widgets and KF6 ConfigCore, KirigamiPlatform). `kirigami-plasmadesktop-integration/CMakeLists.txt:10-19` links KF6::KirigamiPlatform, KF6::ConfigCore, KF6::ColorScheme, KF6::IconThemes (ColorScheme and IconThemes are conditional on the optional packages, `CMakeLists.txt:101`). On Windows `user32` is linked (`kirigami-plasmadesktop-integration/CMakeLists.txt:33`).

## 2. Theme input (how configuration reaches it)
- QDS2.1 Style selection is done by the application, not by the style itself. The README gives the code: call `QQuickStyle::setStyle("org.kde.desktop")` if `QT_QUICK_CONTROLS_STYLE` is empty (`README.md:15-30`, code block). The style is also picked "automatically" on Plasma when Breeze and Plasma Integration are installed (`README.md:11`). The README says the application must be a `QApplication` (`README.md:32`).
- QDS2.2 Android example in the README selects `org.kde.breeze` instead (`README.md:37-40`), per the `Q_OS_ANDROID` branch.
- QDS2.3 Widget style name for the non-QApplication path: `KSharedConfig::openConfig()` (kdeglobals) group `[KDE]`, key `widgetStyle`, default `"Fusion"`. Read in the `KQuickStyleItem` constructor (`plugin/kquickstyleitem.cpp:106`; branch at 150-182): kdeglobals opened at line 163, `cg.readEntry("widgetStyle", defaultStyleName)` at 166; fallback to `Fusion` at 168; `::exit` if no style can be created (lines 170-172).
- QDS2.4 Palette, fonts and frame contrast come from the Kirigami platform theme, not from the style itself. `KQuickStyleItem::initStyleOption()` attaches `Kirigami::Platform::PlatformTheme` with `qmlAttachedPropertiesObject` (`plugin/kquickstyleitem.cpp:224-229`, cast at 227), then connects `colorsChanged` to copy the palette into the option and call `polish()` (lines 230-236).
- QDS2.5 The platform theme is provided by the factory and plugin metadata in `kirigami-plasmadesktop-integration/`: `kirigamiplasmafactory.h:18` `Q_PLUGIN_METADATA(IID PlatformPluginFactory_iid FILE "kirigamiplasmaintegration.json")`; `kirigamiplasmafactory.cpp:19-22` `createPlatformTheme(parent)` returns `new PlasmaDesktopTheme(parent)`. The JSON file `kirigami-plasmadesktop-integration/kirigamiplasmaintegration.json` is an empty object `{}` (1 line).
- QDS2.6 KColorScheme input: `PlasmaDesktopTheme` uses `KColorScheme` objects, which read the KDE color scheme set in the KDE configuration (the reader is in KF6 ColorScheme, an external dependency; not in this repo). Usage: `plasmadesktoptheme.cpp:19` (include), `:29-31` (fields `palette`, `selectionScheme`, `scheme`), `:36-37`, `:68-69` (refresh of `buttonScheme` and `viewScheme`).
- QDS2.7 Environment variables read in the studied code: none directly. `QT_QUICK_CONTROLS_STYLE` appears only in the README example (`README.md:23`, `README.md:43`).

## 3. Color and style model
- QDS3.1 Two layers. (a) `KQuickStyleItem` holds a `QStyleOption*` (`plugin/kquickstyleitem_p.h:514` member `m_styleoption`, type set per element in `initStyleOption` and the setters). (b) `PlasmaDesktopTheme` (a `Kirigami::Platform::PlatformTheme` subclass) exposes colors as Kirigami theme properties and one `QPalette`.
- QDS3.2 Colour sets. `PlasmaDesktopTheme::StyleSingleton::loadColors(ColorSet, ColorGroup)` maps Kirigami color sets to `KColorScheme::ColorSet`: Button, Selection, Tooltip, View, Complementary, Header, Window (`kirigami-plasmadesktop-integration/plasmadesktoptheme.cpp:74-110`, mapping at 84-107).
- QDS3.3 `loadColors` builds a `QPalette` for each of Active, Inactive and Disabled (`plasmadesktoptheme.cpp:112-133`). Role mapping from the KColorScheme of the chosen set:
  - WindowText, Text, ButtonText, ToolTipText: `scheme.foreground()` (lines 114, 117, 119, 123).
  - Window, Base, Button, ToolTipBase: `scheme.background()` (115-116, 118, 122).
  - Highlight: `selectionScheme.background()`; HighlightedText: `selectionScheme.foreground()` (120-121).
  - Light, Midlight, Mid, Dark, Shadow: `scheme.shade(KColorScheme::{Light,Midlight,Mid,Dark,Shadow}Shade)` (125-129).
  - AlternateBase: `background(AlternateBackground)` (131); Link and LinkVisited: `foreground(LinkText)` and `foreground(VisitedText)` (132-133).
  The `KColorScheme::shade` and `background`/`foreground` implementations are in KF6 ColorScheme (not in this repo; UNVERIFIED how they compute the shades).
- QDS3.4 Caching: results are stored in `m_cache`, a hash keyed by `(Kirigami::Platform::PlatformTheme::ColorSet, QPalette::ColorGroup)` (`plasmadesktoptheme.cpp:178`), checked at 77-78 and inserted at 136. `refresh()` clears the cache and rebuilds the button and view schemes (`plasmadesktoptheme.cpp:65-72`).
- QDS3.5 Per-state handling by color group. `PlasmaDesktopTheme::syncColors()` (`plasmadesktoptheme.cpp:261`) picks the group: `colorGroup()` first; if the parent item is not enabled, `QPalette::Disabled` (line 274); if the window is not active and is exposed, `QPalette::Inactive` (line 280). `loadColors` then supplies the colors (`plasmadesktoptheme.cpp:284`, `const auto colors = s_style->loadColors(colorSet(), group);`). The same pattern appears in the second sync function at lines 329-331 and 335 (`syncFrameContrast`, line 316).
- QDS3.6 Semantic colors and decorations set by `syncColors()` (`plasmadesktoptheme.cpp:289-313`): text colors (Normal, Inactive, Active, Link, VisitedLink, Negative, Neutral, Positive at 289-297), background colors (NormalBackground, AlternateBackground, Highlight, Active, Link, VisitedLink, Negative, Neutral, Positive at 300-308), `setHoverColor` from `decoration(HoverColor)` (line 311), `setFocusColor` from `decoration(FocusColor)` (line 312), `setFrameContrast(KColorScheme::frameContrast())` (line 313).
- QDS3.7 Light and dark: no direct branch on `Qt::ColorScheme` or a dark/light variant was found in `plasmadesktoptheme.cpp` (rg for `colorScheme`, `ColorScheme::`, `dark`, `Dark` returned only KColorScheme calls). The light or dark look comes from the KColorScheme data (UNVERIFIED in detail; the scheme reader is outside this repo).
- QDS3.8 Font: `kquickstyleitem.cpp` takes Qt application font names per element, for example `qApp->font("QPushButton")` (line 279), `qApp->font("QAbstractItemView")` (325), `qApp->font("QHeaderView")` (374), `qApp->font("QToolButton")` (430), `qApp->font("QMenuBar")` (551), and `qApp->font("QMiniFont")` / `"QSmallFont"` (1732-1734). The `QFont` is a QML property (`plugin/kquickstyleitem_p.h:71`).
- QDS3.9 Shape and metrics come from `QStyle` (`subControlRect`, `hitTestComplexControl`, `QStyle::CT_*` calls) inside the style, not from this repo (`plugin/kquickstyleitem.cpp:1054, 1067, 1078, 1342, 1351, 1370`, `1124`).

## 4. Output and rendering path
- QDS4.1 Call chain, from QML to pixels (ordered):
  1. A control template, for example `org.kde.desktop/Button.qml`, sets `background: StylePrivate.StyleItem { elementType: "button" ... }` (`org.kde.desktop/Button.qml:47-49`). The `StyleItem` type is `KQuickStyleItem` registered as `StyleItem` (`plugin/kquickstyleitem_p.h:47, 50` with `QML_NAMED_ELEMENT(StyleItem)`).
  2. Setting `elementType` runs `KQuickStyleItem::setElementType` (`plugin/kquickstyleitem.cpp:1573`). It emits `elementTypeChanged` (line 1581), deletes the old option (lines 1582-1585) and maps the string to `m_itemType`: "menu" (1588), "tab" (1602), "slider" (1615), "combobox" (1619), "button" (1625), "checkbox" (1627), "edit" (1631), "scrollbar" (1635), and others further down.
  3. Property changes such as `sunken`, `hover`, `hasFocus`, `active`, `on` (`plugin/kquickstyleitem_p.h:54-62`) set state flags. Each property setter updates the `QStyleOption` and calls `polish()` or `update()` (not read line by line).
  4. Before painting, `initStyleOption()` (`plugin/kquickstyleitem.cpp:224`) makes sure the palette and theme are attached. The palette is copied into the option at line 984 (`m_styleoption->palette = m_theme->palette();`) and at 235 in the color-change handler.
  5. `KQuickStyleItem::paint(QPainter *painter)` (`plugin/kquickstyleitem.cpp:1724`) calls `initStyleOption()` (1726), sets the font for menu items (1732-1734), then switches on `m_itemType`. For Button it calls `KQuickStyleItem::style()->drawControl(QStyle::CE_PushButton, m_styleoption, painter)` (1743). For item rows, it draws into a `QPixmap` that is cached with `QPixmapCache` (1746-1760) and draws the result with `PE_PanelItemViewRow` into `pixpainter` (1754).
  6. `KQuickStyleItem::style()` (`plugin/kquickstyleitem.cpp:33-40`) returns the internal `s_style` (`QStyleFactory` instance) when set, otherwise `qApp->style()`. The `QStyle` is therefore the application's widget style inside a QApplication.
- QDS4.2 Style option types used per element: `QStyleOptionButton` (created at 251-253 under `case Button`), `QStyleOptionMenuItem` (checked in `paint` at 1727), and others selected by `qstyleoption_cast`. The full set was not enumerated.
- QDS4.3 Draw functions called in this file: `drawControl` (CE_PushButton 1743, CE_ItemViewItem 1766), `drawPrimitive` (PE_PanelItemViewRow 1754), and complex-control hit tests and rectangles (`hitTestComplexControl`, `subControlRect`). The rest of the file (2242 lines) was only sampled.
- QDS4.4 No SVG or pixmap theme assets were found in this repo; the painting is delegated to the widget style.

## 5. Extension and integration points
- QDS5.1 Style name and module URI: the QML module is `org.kde.desktop` version 1.0 (`CMakeLists.txt:105`); the style name used by applications is `org.kde.desktop` (`README.md:9`).
- QDS5.2 Kirigami platform plugin discovery: installed under `${KDE_INSTALL_PLUGINDIR}/kf6/kirigami/platform` (`kirigami-plasmadesktop-integration/CMakeLists.txt:36`). The plugin is a Qt plugin with `Q_PLUGIN_METADATA(IID PlatformPluginFactory_iid FILE "kirigamiplasmaintegration.json")` (`kirigamiplasmafactory.h:18`); the factory class is `KirigamiPlasmaFactory` deriving from `Kirigami::Platform::PlatformPluginFactory` (`kirigamiplasmafactory.h:14`). The loader is in KirigamiPlatform (external).
- QDS5.3 The QML module `org.kde.desktop` depends on `org.kde.qqc2desktopstyle.private` and `org.kde.desktop.private` (`CMakeLists.txt:105`), and on the external modules Kirigami and QtQuick.Templates (imports in `org.kde.desktop/Button.qml:9-12`).
- QDS5.4 Binary coupling: the plugin targets a minimum Qt 6.10.0 and KF6 6.32 for ECM (`CMakeLists.txt:8, 10`). It uses `Kirigami/Platform/PlatformTheme` headers (`plugin/kquickstyleitem.cpp:26`) from the KF6 KirigamiPlatform package.
- QDS5.5 Non-QApplication mode: when the engine runs without a QApplication, the style uses its own internal `QStyle` from `s_style` (`plugin/kquickstyleitem.cpp:150-175`). The comment at lines 135-149 lists which `qApp` functions are safe without a QApplication (`qApp->style()` is not).

## 6. Data and tooling
- QDS6.1 `tests/`: QML test pages (for example `tests/testBars.qml`, `tests/testComboBox.qml`, `tests/HeaderViews.qml`). Not run or read.
- QDS6.2 `kirigami-plasmadesktop-integration/autotests/`: C++ and QML tests for text-field context menu and animation speed (`autotests/TextFieldContextMenuTest.cpp`, `autotests/animationspeedmodifiertest.cpp`).
- QDS6.3 `Messages.sh` and `poqm/`: translation extraction and compiled catalogs (`CMakeLists.txt:199` installs them via `ecm_install_po_files_as_qm(poqm)`).
- QDS6.4 `Mainpage.dox`: doxygen mainpage (not read).

## 7. Facts of note
- QDS7.1 README limitation: the style "has a noticeable performance impact on mobile systems like Plasma Mobile and Android" (`README.md:51`), and the README recommends the Breeze QML style on those platforms (`README.md:53`). Section heading "Differences from QQC2 Breeze Style" at `README.md:49`.
- QDS7.2 README: "This framework has no public API, applications should not (and cannot) use it directly" (`README.md:5`).
- QDS7.3 Hard exit on failure: when no QStyle can be created in the non-QApplication path, the code calls `::exit(EXIT_FAILURE)` (`plugin/kquickstyleitem.cpp:170-173`).
- QDS7.4 Comment about unsafe `qApp->style()` use outside QApplication (`plugin/kquickstyleitem.cpp:135-149`).
- QDS7.5 Known open or hacky items in code comments: `// DAVE - QQC1 code does this, but if you look at QComboBox this doesn't make sense` (`plugin/kquickstyleitem.cpp:664`); `// TODO: emulate QSplitter::handleWidth using contentWidth or a custom property?` (`plugin/kquickstyleitem.cpp:1325`).
- QDS7.6 Known behaviour noted in code: the palette does not include the client's own `palette` override (`plugin/kquickstyleitem.cpp:978-983`, comment says it "can't read and write it from c++" and must be handled in QML).
- QDS7.7 Licence: the repo ships LICENSES texts for GPL-2.0-only, GPL-3.0-only, LGPL, LicenseRef-KFQF-Accepted-GPL, LicenseRef-Qt-Commercial and others (`LICENSES/` directory).

## 8. Not covered
- Not read: the 2242-line `plugin/kquickstyleitem.cpp` in full (sampled at the lines cited); `plugin/itembranchindicators.cpp` (113 lines); `plugin/kquickpadding_p.h`; `kirigami-plasmadesktop-integration/animationspeedprovider.cpp`, `plasmadesktopunits.cpp`; all `org.kde.desktop/*.qml` except `Button.qml` lines 47-49.
- External, not in this repo (UNVERIFIED here): KF6 ColorScheme (`KColorScheme` shade and background computation and the color scheme file lookup), KF6 KirigamiPlatform (`Kirigami::Platform::PlatformTheme` and the platform loader), and the Breeze style used on Plasma.
- The `org.kde.breeze` QML style named in the README is a separate repository and was not studied.
- Tests and CI files were not run.
