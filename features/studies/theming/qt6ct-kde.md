# qt6ct-kde: Arch packaging of qt6ct 0.11 with a patch that adds KDE color-scheme, icon, font and style integration

Source: refs/qt6ct-kde (git clone; HEAD 8c1003e, dated 2026-08-14; branch master). The repo holds two files: `PKGBUILD` (34 lines) and `qt6ct-shenanigans.patch` (845 lines). The upstream qt6ct tree is not in the repo; the patch is written against it. Citations are `path:line` relative to the repo root. For the patch, the line is a line of `qt6ct-shenanigans.patch`. The patch's file list is in its `diff --git` headers (patch lines 1, 43, 55, 157, 171, 183, 196, 461, 530, 542, 556, 569, 673, 697, 747, 781, 796, 820). Its hunks are not all line-numbered against the same base as the qt6ct tree at HEAD of refs/qt6ct; the study cites patch lines only.
Id prefix: QK6.

## 1. Purpose and shape
- QK6.1 Arch Linux package build recipe. `PKGBUILD:4` `pkgname=qt6ct-kde`; `PKGBUILD:5` `_pkgname=qt6ct`; `PKGBUILD:6` `pkgver=0.11`; `PKGBUILD:7` `pkgrel=8`.
- QK6.2 `PKGBUILD:8` `pkgdesc='Qt 6 Configuration Utility, patched to work correctly with KDE applications'`. `PKGBUILD:10` `url='https://www.opencode.net/trialuser/qt6ct'`. `PKGBUILD:11` `license=(BSD)`. `PKGBUILD:9` `arch=(x86_64)`.
- QK6.3 `PKGBUILD:14-15` `conflicts=($_pkgname)` and `provides=($_pkgname)`: the package replaces plain `qt6ct`.
- QK6.4 Repo contents: `PKGBUILD` and `qt6ct-shenanigans.patch`. No tests, CI or other files.

## 2. Theme input
- QK6.5 KDE color schemes are recognised by `Qt6CT::isKColorScheme`, which returns true when the lower-cased path ends with `.colors`. Declared `qt6ct-shenanigans.patch:166`; defined `:95-99`.
- QK6.6 Color scheme search path: `"/color-schemes"` is added next to the qt6ct path inside the shared-path loop, guarded by `KF_CONFIGCORE_LIB && KF_COLORSCHEME_LIB`. `qt6ct-shenanigans.patch:74-76`.
- QK6.7 The color scheme file filter adds `*.colors` only when both KF macros are defined. `qt6ct-shenanigans.patch:648-654` (`appearancepage.cpp`).
- QK6.8 For `.colors` files the combo label is the `[General] Name` key plus " (KColorScheme)". `qt6ct-shenanigans.patch:659-669`.
- QK6.9 `Qt6CT::resolvePath` now returns early on an empty path. `qt6ct-shenanigans.patch:84-85`.
- QK6.10 The palette read in `readSettings` is now fed from `m_schemePath`, which is empty when `m_isIgnored` is set or `custom_palette` is false. `qt6ct-shenanigans.patch:410-412`.

## 3. Color and style model
- QK6.11 `Qt6CT::loadColorScheme` changed signature: `static std::optional<QPalette> loadColorScheme(const QString &filePath)` (`qt6ct-shenanigans.patch:101` definition, `:167` declaration). It returns `std::nullopt` for an empty path (`:103-104`).
- QK6.12 For `.colors` files it returns `KColorScheme::createApplicationPalette(KSharedConfig::openConfig(filePath))` (`qt6ct-shenanigans.patch:107-109`, guarded by the KF macros).
- QK6.13 For INI color scheme files, the new code returns `std::nullopt` when any of the active, inactive or disabled lists has fewer than `QPalette::NColorRoles` entries (`qt6ct-shenanigans.patch:126-129`). The upstream fallback branch (`customPalette = fallback`, removed at `:147`) is gone. Callers now use `.value_or(palette())` (`:613`, `:640`).
- QK6.14 The `qt6ct` palette member is now `std::optional<QPalette> m_palette` (`qt6ct-shenanigans.patch:514`). `QPlatformTheme::palette(SystemPalette)` returns `&*m_palette` only when it is set (`:312-313`). The old code returned `&m_palette` only when `!m_isIgnored`.
- QK6.15 Qt 6.5+ only: `Qt6CTPlatformTheme::colorScheme()` is overridden (`qt6ct-shenanigans.patch:277-306`, guard `QT_VERSION >= 6.5.0` at `:277`). It derives Dark or Light from the window text and window lightness of a palette, using `m_style->standardPalette()` when widgets are built. A re-entrancy guard `m_inColorScheme` (declared `:522`) prevents recursion; the comment at `:280-281` names the recursion path.
- QK6.16 `m_style` is now a `std::unique_ptr<QStyle>` declared under `#ifdef QT_WIDGETS_LIB` (`qt6ct-shenanigans.patch:524-526`). The application style is created in a single-shot timer at startup (`:251-254`).
- QK6.17 Fonts: the fallback for `general` and `fixed` is now `*QGenericUnixTheme::font(SystemFont)` and `FixedFont`, not `QGuiApplication::font()` (`qt6ct-shenanigans.patch:436-439`). The constructor initializes the same members in its initializer list (`:233-235`).
- QK6.18 The font dialog strips a regular-weight style name ("Regular", "Normal", "Book", "Roman") before saving (`qt6ct-shenanigans.patch:722-727`, in `src/qt6ct/fontspage.cpp`, which begins at `:697`). The read default uses `QFontDatabase::systemFont` (`:741-743`).

## 4. Output and rendering path
- QK6.19 Icons: with KF6 IconThemes, `createIconEngine` returns `new KIconEngine(iconName, KIconLoader::global())` (`qt6ct-shenanigans.patch:322-326`, guard `KF_ICONTHEMES_LIB`). Header declaration at `:489-491`.
- QK6.20 Application style: when widgets are built, the constructor schedules `QStyleFactory::create("qt6ct-style")` through `QTimer::singleShot(0, ...)` and then calls `applySettings()` (`qt6ct-shenanigans.patch:248-254`). With Qt Quick Controls 2, it sets `org.kde.desktop` unless the user set a style (`:257-258`).
- QK6.21 The application event filter is installed in the constructor (`qt6ct-shenanigans.patch:269`). The filter handles `KDE_COLOR_SCHEME_PATH` (`:448-460`). The constructor sets that property before startup when the scheme is KDE (`:245-246`).
- QK6.22 `applySettings` sets `KDE_COLOR_SCHEME_PATH` for a KDE scheme and clears it otherwise when `m_update` is set (`:336-339`).
- QK6.23 Repaint path: the patch replaces `QIconLoader::instance()->updateSystemTheme()` and `QGuiApplication::setPalette(...)` (removed, upstream `:360-361`) with `QWindowSystemInterface::handleThemeChange()` (`:362`). Widgets get `ApplicationFontChange` and `ThemeChange` as posted events instead of `sendEvent` (`:374-380`).
- QK6.24 `qt_app_fonts_hash()` cache is cleared when present (`qt6ct-shenanigans.patch:351-352`), using `qt6ct` private-include `<private/qapplication_p.h>` (`:207`).

## 5. Extension and integration points
- QK6.25 Writes into KDE configuration: `AppearancePage::writeSettings(KSharedConfigPtr)` writes `[KDE] widgetStyle=qt6ct-style` to `kdeglobals` (`qt6ct-shenanigans.patch:596-603`). `IconThemePage::writeSettings(KSharedConfigPtr)` writes `[Icons] Theme` from the selected tree item (`:765-775`). The base class gets a virtual no-op overload (`src/qt6ct/tabpage.h`, `:840-841`).
- QK6.26 `MainWindow` opens `kdeglobals` once on Apply and passes the handle to each page's `writeSettings(config)` (`qt6ct-shenanigans.patch:804-806` and `:813-815`).
- QK6.27 The `qt6ct-style` proxy style uses `QStyleFactory::create(style) ?: new QCommonStyle` as its base, with a comment "nullptr == infinite recursion" (`qt6ct-shenanigans.patch:551-552`, file `src/qt6ct-style/qt6ctproxystyle.cpp`, which begins at `:542`). The style target no longer defines `USE_WIDGETS` globally (`:537`).
- QK6.28 Build: `src/qt6ct` and `src/qt6ct-style` are added only when `Qt6Widgets_FOUND` (`qt6ct-shenanigans.patch:36-39`). The Qt 6 widgets requirement is made optional (`:14-15`, `:17-18`).
- QK6.29 KF6 is optional: `find_package(KF6Config)`, `KF6ColorScheme`, `KF6IconThemes` at `qt6ct-shenanigans.patch:21-23`, with no REQUIRED keyword. Each dependent target uses `$<TARGET_NAME_IF_EXISTS:...>` and `$<TARGET_EXISTS:...>` so the build works without them (`:52-53`, `:180-181`, `:565-566`).
- QK6.30 The `.pro` file for the plugin adds `widgets-private` to `QT` (`qt6ct-shenanigans.patch:191-192`). The `.pro` build is part of the patch, not just CMake.

## 6. Data and tooling
- QK6.31 Source: `PKGBUILD:16-17` `source=(git+https://www.opencode.net/trialuser/qt6ct#tag=$pkgver ...)`. The upstream is a git clone at tag `$pkgver` (0.11). The `refs/qt6ct` repo in this project is a different upstream (see its own study, `features/studies/theming/qt6ct.md`).
- QK6.32 Checksums: `PKGBUILD:18-19`, one SHA-256 per source entry. The git source has no checksum line of its own.
- QK6.33 Build: `prepare()` runs `patch -d $_pkgname -p1 < $_pkgname-shenanigans.patch` (`PKGBUILD:21-23`; comment "The magic" at `:22`). `build()` runs `cmake -B build -S $_pkgname -DCMAKE_INSTALL_PREFIX=/usr` and `cmake --build build` (`PKGBUILD:25-29`). `package()` runs `DESTDIR="$pkgdir" cmake --install build` and installs `COPYING` as the license (`PKGBUILD:31-34`).
- QK6.34 Make dependencies: `PKGBUILD:13` `makedepends=(cmake git qt6-tools)`. Runtime: `PKGBUILD:12` `depends=(qqc2-desktop-style)`. The KF6 packages used by the patch are not named.
- QK6.35 The patch uses git-style `diff --git a/... b/...` headers (not SVN), so it is applied with `-p1` as written.

## 7. Facts of note
- QK6.36 The patch's `qt6ct-common` palette loader changed from a fallback to an optional return. Any caller that does not handle `std::nullopt` gets a different palette than before (`qt6ct-shenanigans.patch:126-129`, `:613`, `:640`).
- QK6.37 `Qt6CTPlatformTheme::colorScheme` contains a comment that describes a recursion between `QPlatformTheme::palette`, `initializeSystemPalette`, `qt_fusionPalette` and `colorScheme` (`qt6ct-shenanigans.patch:280-281`). The `m_inColorScheme` flag is the only guard.
- QK6.38 `KDE_COLOR_SCHEME_PATH` is set on `qApp` before the QPA startup functions run (comment at `qt6ct-shenanigans.patch:244`).
- QK6.39 A Qt 6.5-only block and the Qt 6.10 private-component block in `CMakeLists.txt` are both present (`:17-18`, `:277`).
- QK6.40 The patch adds no test code and no documentation changes.

## 8. Not covered
- QK6.41 Upstream qt6ct 0.11 source is not in the repo; unpatched behaviour is known only from context lines.
- QK6.42 No build, install or runtime run was done. No commands were run inside `refs/`.
- QK6.43 The behaviour of KColorScheme, KIconEngine and KSharedConfig is not read; only their call sites are cited.
- QK6.44 Whether the two SHA-256 values match the upstream content is not checked.
- QK6.45 Qt private APIs used by the patch (`qapplication_p.h`, `qt_app_fonts_hash`, `QApplicationPrivate::scene_list`) are cited as used, not verified against Qt sources.
