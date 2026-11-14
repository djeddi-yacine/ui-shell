# qt5ct-kde: Arch packaging of qt5ct 1.8 with a patch that adds KDE color-scheme and icon support

Source: refs/qt5ct-kde (git clone; HEAD 6ca1388, dated 2024-10-25; branch master). The repo holds two files: `PKGBUILD` (36 lines) and `qt5ct-shenanigans.patch` (308 lines). The upstream qt5ct source tree is not in the repo, so the patch is the only source of code. Citations are `path:line` relative to the repo root; for the patch, the line is a line of `qt5ct-shenanigans.patch`. The patch header states its base as upstream qt5ct "revision 690" (SVN).
Id prefix: QK5.

## 1. Purpose and shape
- QK5.1 The repo is an Arch Linux package build recipe. `PKGBUILD:5` sets `pkgname=qt5ct-kde`; `PKGBUILD:6` sets `_pkgname=qt5ct`; `PKGBUILD:7` sets `pkgver=1.8`; `PKGBUILD:8` sets `pkgrel=15`.
- QK5.2 `PKGBUILD:9` sets `pkgdesc` to "Qt5 Configuration Utility, patched to work correctly with KDE applications". `PKGBUILD:10` sets `arch=(x86_64)`. `PKGBUILD:11` sets `url='https://qt5ct.sourceforge.io/'`. `PKGBUILD:12` sets `license=(BSD)`.
- QK5.3 `PKGBUILD:15-16` declare `conflicts=($_pkgname)` and `provides=($_pkgname)`, so this package replaces the plain `qt5ct` package.
- QK5.4 Repo contents: `PKGBUILD`, `qt5ct-shenanigans.patch`. No other files, tests or CI config.

## 2. Theme input
- QK5.5 The patch adds a second shared search directory for color schemes: `p + "/color-schemes"` next to the existing `p + "/qt5ct/colors"` inside the `GenericDataLocation` loop. `qt5ct-shenanigans.patch:134` (hunk header at `:130`, file `src/qt5ct-common/qt5ct.cpp`, which begins at `:117`).
- QK5.6 The upstream system-wide entry `QT5CT_DATADIR"/qt5ct/colors"` is kept unchanged. `qt5ct-shenanigans.patch:136` (context line).
- QK5.7 The file filter in the color scheme list changes from `*.conf` to `*.conf` plus `*.colors`. `qt5ct-shenanigans.patch:75-76` (file `src/qt5ct/appearancepage.cpp`, which begins at `:41`).
- QK5.8 A new static helper `Qt5CT::isKColorScheme(filePath)` returns true when the lower-cased path ends with `.colors`. Declared at `qt5ct-shenanigans.patch:163` (`src/qt5ct-common/qt5ct.h`, begins at `:155`); defined at `qt5ct-shenanigans.patch:142-144`.
- QK5.9 For a `.colors` file, the combo-box label is read from the `[General]` group key `Name` (fallback: file base name) and suffixed with " (KColorScheme)". `qt5ct-shenanigans.patch:83-87`.

## 3. Color and style model
- QK5.10 For a `.colors` file, palette creation is delegated to KDE: `Qt5CT::loadColorScheme` returns `KColorScheme::createApplicationPalette(KSharedConfig::openConfig(filePath))` before the INI path. `qt5ct-shenanigans.patch:149-150`.
- QK5.11 Non-`.colors` files keep the upstream `QSettings` INI path. The patch adds no change to that code.
- QK5.12 Include additions: `KSharedConfig` and `KConfigGroup` in `appearancepage.cpp` (`qt5ct-shenanigans.patch:49-50`); `KSharedConfig` and `KColorScheme` in `qt5ct.cpp` (`qt5ct-shenanigans.patch:125-126`); `QQuickStyle` in `qt5ctplatformtheme.cpp` (`qt5ct-shenanigans.patch:188`); `KIconEngine` and `KIconLoader` in the same file (`qt5ct-shenanigans.patch:196-197`).
- QK5.13 A "Create a Copy" action is stored in a new member `m_copyColorSchemeAction` (`qt5ct-shenanigans.patch:59`, from `menu->addAction` in the `appearancepage.cpp` menu setup). The member is declared at `qt5ct-shenanigans.patch:102` in `appearancepage.h`.
- QK5.14 `AppearancePage::updateActions` hides the copy action when the current combo entry is a KDE scheme: `m_copyColorSchemeAction->setVisible(!Qt5CT::isKColorScheme(...))` at `qt5ct-shenanigans.patch:67` (function starts at `:65`).
- QK5.15 `Qt5CTPlatformTheme::readSettings` clears a new member `m_schemePath` at `qt5ct-shenanigans.patch:251`, and assigns it only inside the `custom_palette` branch at `qt5ct-shenanigans.patch:259`. The member is declared at `qt5ct-shenanigans.patch:305` (`src/qt5ct-qtplugin/qt5ctplatformtheme.h`, begins at `:281`).

## 4. Output and rendering path
- QK5.16 Icons: `Qt5CTPlatformTheme::createIconEngine` is no longer commented out. It returns `new KIconEngine(iconName, KIconLoader::global())`. Definition at `qt5ct-shenanigans.patch:227-230`. The header declaration is `qt5ct-shenanigans.patch:290`.
- QK5.17 In `applySettings`, for a KDE scheme the plugin sets the dynamic property `KDE_COLOR_SCHEME_PATH` on `qApp` to the scheme path. Otherwise, when `m_update` is set, it clears the property. `qt5ct-shenanigans.patch:239-242`.
- QK5.18 Widget style: when `hasWidgets()` is true and `QQuickStyle::name()` is empty or "Fusion", the constructor calls `QQuickStyle::setStyle("org.kde.desktop")`. `qt5ct-shenanigans.patch:208-211` (inside `#ifdef QT_WIDGETS_LIB`, hunk at `:202`).
- QK5.19 An event filter is installed on the application instance in the constructor. `qt5ct-shenanigans.patch:219`.
- QK5.20 `eventFilter` calls `applySettings()` when a `DynamicPropertyChange` for `KDE_COLOR_SCHEME_PATH` makes the property empty and `m_schemePath` is a KDE scheme. Definition at `qt5ct-shenanigans.patch:271-280`. Declared `protected` at `qt5ct-shenanigans.patch:294-295`.

## 5. Extension and integration points
- QK5.21 New `find_package` calls in the top-level CMake file: `Qt5` with `QuickControls2` (`qt5ct-shenanigans.patch:10`), and `KF5Config`, `KF5ConfigWidgets`, `KF5IconThemes` (`qt5ct-shenanigans.patch:12-14`). Hunk header at `:5`.
- QK5.22 Link targets added: `qt5ct` links `KF5::ConfigCore` (`qt5ct-shenanigans.patch:38`); `qt5ct-common` links `KF5::ConfigCore` and `KF5::ConfigWidgets` (`qt5ct-shenanigans.patch:115`); `qt5ct-qtplugin` links `Qt5::QuickControls2` and `KF5::IconThemes` (`qt5ct-shenanigans.patch:176`).
- QK5.23 `PLUGINDIR` is computed by `qtpaths --plugin-dir` only when it is not already set. `qt5ct-shenanigans.patch:22-25` (the original `execute_process` at `:22` is replaced by an `if(NOT PLUGINDIR)` guard).
- QK5.24 Packaging names no KF5 or QuickControls2 package. `PKGBUILD:13` `depends=(qqc2-desktop-style5)`; `PKGBUILD:14` `makedepends=(cmake qt5-tools)`. The KF5 packages the patch requires are not named in either array. UNVERIFIED: whether they arrive transitively through `qqc2-desktop-style5`.

## 6. Data and tooling
- QK5.25 Source: `PKGBUILD:17-18` lists the upstream tarball `https://downloads.sourceforge.net/project/$_pkgname/$_pkgname-$pkgver.tar.bz2` and `$_pkgname-shenanigans.patch`.
- QK5.26 Checksums: `PKGBUILD:19-20`, one SHA-256 per source entry, in the same order as `source`.
- QK5.27 `prepare()` applies the patch with `patch -d $_pkgname-$pkgver -p1 < $_pkgname-shenanigans.patch` (`PKGBUILD:22-24`; comment "The magic" at `:23`). `build()` runs `cmake -B build -S $_pkgname-$pkgver -DCMAKE_INSTALL_PREFIX=/usr` and `cmake --build build` (`PKGBUILD:26-30`). `package()` runs `DESTDIR="$pkgdir" cmake --install build` and installs `COPYING` as the license file (`PKGBUILD:32-36`).
- QK5.28 The patch is in git-style `Index:` format with SVN-style `(revision 690)` and `(working copy)` labels. Ten files are touched; their `Index:` headers are at patch lines 1, 29, 41, 93, 106, 117, 155, 167, 180 and 281.

## 7. Facts of note
- QK5.29 The patch adds a hard link-time dependency on KDE frameworks (KColorScheme, KConfig, KIconThemes) in `qt5ct-common` and `qt5ct-qtplugin`, as shown in QK5.22 and the includes in QK5.12.
- QK5.30 `Qt5CTPlatformTheme::createIconEngine` returns a KDE icon engine unconditionally. The patch has no fallback branch (`qt5ct-shenanigans.patch:227-230`).
- QK5.31 A comment at `qt5ct-shenanigans.patch:268-270` describes the case in which KColorSchemeManager resets the application color scheme and `KColorScheme` then reads kdeglobals. The `eventFilter` in QK5.20 is the code that responds to it.
- QK5.32 Ownership lines are `PKGBUILD:1-3` (maintainer and contributor comments). They are not used by the build.
- QK5.33 The patch adds no tests and no documentation.

## 8. Not covered
- QK5.34 Upstream qt5ct source is not in the repo. Behaviour of unpatched code is known only from surrounding context lines in the patch.
- QK5.35 Build results, installed file lists and runtime behaviour were not checked. No commands were run inside `refs/`.
- QK5.36 Behaviour of KColorScheme, KIconLoader and KIconEngine was not read; only their call sites in the patch are cited.
- QK5.37 Whether the `sha256sums` values match the upstream tarball was not checked.
