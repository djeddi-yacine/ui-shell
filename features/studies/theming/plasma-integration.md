# plasma-integration: KDE Qt platform theme plugins (Qt 6 and Qt 5)

Source: refs/plasma-integration (git clone; HEAD 862de04, dated 2026-11-10; branch master). Citations are `path:line` relative to the repo root.
Id prefix: PI.

## 1. Purpose and shape
- PI.1 The repo builds Qt platform theme plugins that make Qt applications read KDE settings. The Qt 6 plugin is in `qt6/src/platformtheme/` and the Qt 5 plugin in `qt5/src/platformtheme/`.
- PI.2 The Qt 6 plugin metadata declares one plugin key: `"Keys": [ "kde" ]` (`qt6/src/platformtheme/kdeplatformtheme.json:2`).
- PI.3 The main class is `KdePlatformTheme`, which derives from `QGenericUnixTheme` (`qt6/src/platformtheme/kdeplatformtheme.h:26`).
- PI.4 The Qt 6 directory holds 38 files; the Qt 5 directory holds 30 files (counted with `ls`). Qt 5 has its own copies of the platform theme, hints and dialog helpers, plus `kiodelegate`, `kioopenwith*` and `kdeplatformmessagedialoghelper`, which the Qt 6 tree does not have (file names only; `qt5/src/platformtheme/kiodelegate.cpp` and `kioopenwith.cpp` were not read).
- PI.5 A second class, `KHintsSettings`, holds the KDE settings snapshot used by `KdePlatformTheme` (`qt6/src/platformtheme/khintssettings.cpp:65`).

## 2. Theme input
- PI.6 The input is the KDE configuration: `kdeglobals` (opened through `KSharedConfig`), the `KDE` and `Icons` groups, and the `org.kde.kdeglobals` settings exposed on DBus. `KHintsSettings` falls back to `KSharedConfig::openConfig()` when no config is passed (`khintssettings.cpp:65-68`, `khintssettings.cpp:161`).
- PI.7 Keys read by `KHintsSettings` (Qt 6 tree):
  - `Icons/Theme`, default `breeze` (`khintssettings.cpp:92`).
  - `widgetStyle` in the config group passed in, and `KDE/widgetStyle` for the look-and-feel package case (`khintssettings.cpp:103`, `khintssettings.cpp:108`).
  - `ShowIconsOnPushButtons` (`khintssettings.cpp:116`).
  - `GraphicEffectsLevel`, where any non-zero value sets the general UI effect flag (`khintssettings.cpp:120`).
  - `KDE/AnimationDurationFactor` for the motion preference (`khintssettings.cpp:490`, Qt 6.12 and later only).
- PI.8 Palettes come from `loadPalettes()` (`khintssettings.cpp:425-466`), in this order:
  1. If `mUsePortal` is set and the portal exposes `org.kde.kdeglobals.Colors:View`, a temporary `KConfig` is built and passed to `KColorScheme` (`khintssettings.cpp:430-444`).
  2. Else, if `kdeglobals` has `Colors:View`, that group is used (`khintssettings.cpp:445-446`).
  3. Else, the look-and-feel package at `plasma/look-and-feel/<pkg>/contents/colors` is used (`khintssettings.cpp:447-456`).
  4. Else, `General/ColorScheme` names a `color-schemes/<name>.colors` file, with `BreezeLight` as the default and fallback (`khintssettings.cpp:457-466`).
- PI.9 `mUsePortal` is set from `KSandbox::isInside()` (`khintssettings.cpp:68`). A separate check, `useXdgDesktopPortal()`, reads the environment variable `PLASMA_INTEGRATION_USE_PORTAL` and returns true when it equals 1 (`qt6/src/platformtheme/kdeplatformtheme.cpp:399-402`).
- PI.10 The font inputs are the KDE font settings handled by `KFontSettingsData` (`qt6/src/platformtheme/kfontsettingsdata.cpp`, 170 lines). `font()` builds a cached `QFont` from a built-in `DefaultFontData` table (`kfontsettingsdata.cpp:75-82`). The file also has a portal change slot (`kfontsettingsdata.cpp:135`) and a `readConfigValue` helper (`kfontsettingsdata.cpp:144`).

## 3. Color and style model
- PI.11 Palettes are `QPalette` objects keyed by `QPlatformTheme::Palette`. `KdePlatformTheme::palette()` returns `m_hints->palette(type)`, and falls back to `QPlatformTheme::palette(type)` when that is null (`qt6/src/platformtheme/kdeplatformtheme.cpp:104-112`).
- PI.12 The Qt color scheme is derived, not read directly. `KdePlatformTheme::colorScheme()` returns `m_hints->colorScheme()` (`kdeplatformtheme.cpp:114-117`). `determineColorScheme()` takes the gray value of the system palette's window color: below 192 is `Dark`, otherwise `Light`; the code comment says it matches `xdg-desktop-portal-kde` (`khintssettings.cpp:469-486`).
- PI.13 The color scheme is re-evaluated on change. The `KColorScheme` frame contrast case is mentioned in a comment (`khintssettings.cpp:258`), and the new value is compared with the stored one (`khintssettings.cpp:262-264`).
- PI.14 Motion preference is read from `AnimationDurationFactor`, compiled only under `QT_VERSION >= 6.12.0` (`khintssettings.cpp:488-490`; `kdeplatformtheme.cpp:120-124`).
- PI.15 Widget style and Qt Quick style are set from KDE settings. `setQtQuickControlsTheme()` reads `KDE/widgetStyle` (default `breeze`), chooses `org.kde.union` for `union` when installed, and otherwise `org.kde.desktop` when `/org/kde/desktop` exists (`kdeplatformtheme.cpp:370-398`). It does nothing if the user already set a Quick Controls style, except that the default `Fusion` value is overridden unless `QT_QUICK_CONTROLS_STYLE` is set (`kdeplatformtheme.cpp:374-376`).

## 4. Output and rendering path
- PI.16 The theme hooks the Qt platform API through `themeHint`, `palette`, `font`, `colorScheme`, `motionPreference` (6.12+), `fileIcon`, `keyBindings`, `usePlatformNativeDialog`, `createPlatformDialogHelper`, `createPlatformSystemTrayIcon`, `createPlatformMenuBar`, and `createIconEngine` (`kdeplatformtheme.cpp:85`, `:95`, `:104`, `:114`, `:120`, `:126`, `:185`, `:273`, `:327`, `:355`, `:360`, `:174`).
- PI.17 Icons: `createIconEngine()` returns a new `KIconEngine` built from `KIconLoader::global()` (`kdeplatformtheme.cpp:174-176`). The Icon theme name is the `Icons/Theme` value (`khintssettings.cpp:92`).
- PI.18 Dialogs: `usePlatformNativeDialog()` returns true for file, message and color dialogs (`kdeplatformtheme.cpp:273-275`). The file dialog is a KDE helper (`kdeplatformfiledialoghelper.cpp`) or, when the XDG portal is used, `qxdgdesktopportalfiledialog.cpp`.
- PI.19 Wayland and X11 extras: on the `wayland` platform name, a `KWaylandIntegration` object is created (`kdeplatformtheme.cpp:56-58`). On X11 an `X11Integration` object is created and initialized (`kdeplatformtheme.cpp:61-64`, guarded by `WITH_X11`).
- PI.20 Application-wide settings are applied at startup. The constructor calls `loadSettings()` (`kdeplatformtheme.cpp:53`), sets `Qt::AA_DontUseNativeMenuBar` to false (`kdeplatformtheme.cpp:67`), sets the Quick Controls theme (`:68`), installs `KIO` UI delegate factories (`:70-74`) and sets a default font for `KCountryFlagEmojiIconEngine` (`:76`).

## 5. Extension and integration points
- PI.21 Plugin loading follows the Qt platform-theme mechanism through `kdeplatformtheme.json` and the `Keys` entry `kde` (`qt6/src/platformtheme/kdeplatformtheme.json:2`).
- PI.22 `KHintsSettings` listens on DBus for `org.kde.kdeglobals` changes (`khintssettings.cpp:161`) and for portal setting changes (`khintssettings.cpp:331`). Setting names are built as `org.kde.kdeglobals.<group>` (`khintssettings.cpp:161`).
- PI.23 The settings-changed handler reacts to `ColorScheme`, `KDE/widgetStyle`, `Icons/Theme`, and the toolbar style (`khintssettings.cpp:333`, `:337`, `:340`, `:346`). The Icon change path is at `khintssettings.cpp:352`.
- PI.24 DBus connection setup happens in `delayedDBusConnects()` (`khintssettings.cpp:189-200`, including the DBus includes at `khintssettings.cpp:28-30`).
- PI.25 The Qt 6 platform theme depends on KDE frameworks by include: `KConfigGroup` (`kdeplatformtheme.cpp:36`), `KSharedConfig`, `KIconLoader`, and `KIO`. The KDE-specific Quick Controls style names are `org.kde.desktop` and `org.kde.union`.
- PI.26 `KHintsSettings::updateQtSettings()` and `updateCursorTheme()` are separate update paths (`khintssettings.cpp:381`, `khintssettings.cpp:495`).

## 6. Data and tooling
- PI.27 Build metadata and the plugin entry: `kdeplatformtheme.json`, `config-platformtheme.h.cmake`, and `CMakeLists.txt` in each Qt tree. The CMake files were not read for this study.
- PI.28 Extra files in the Qt 6 tree: `mono_font.pl`, `mono_font.upd`, `renderer.kcfg`, `renderersettings.kcfgc`, `qtquickrenderersettings.cpp`, and `org.kde.StatusNotifierWatcher.xml`. Their roles were not read (see section 8).
- PI.29 No test directory is present under `qt6/src/platformtheme/` or `qt5/src/platformtheme/` (file lists from `ls`).

## 7. Facts of note
- PI.30 Portal mode is selected by `KSandbox::isInside()` for palettes (`khintssettings.cpp:68`), and by the `PLASMA_INTEGRATION_USE_PORTAL` environment variable for the dialog helper (`kdeplatformtheme.cpp:399-402`). The two checks are separate code paths.
- PI.31 The color scheme is a derived value: a gray threshold of 192 on the system window color (`khintssettings.cpp:469-486`). It is not read from a `ColorScheme` key in the Qt 6 path.
- PI.32 Qt Quick style selection reads `KDE/widgetStyle` and defaults to `breeze` (`kdeplatformtheme.cpp:370-398`), so a KDE widget style name is also used for Quick Controls.
- PI.33 The default `Icons/Theme` is `breeze` (`khintssettings.cpp:92`).
- PI.34 `DefaultFontData` is a built-in table in `kfontsettingsdata.cpp`; the table's contents were not read.

## 8. Not covered
- PI.35 Not read: `kwaylandintegration.cpp`, `x11integration.cpp`, the file dialog implementations, `kdeplatformsystemtrayicon.cpp`, `qdbusmenubar.cpp`, and the Qt 5 tree in detail (only its file names were listed).
- PI.36 Not read: `kfontsettingsdata.cpp` beyond `font()`, `delayedDBusConnects()` and the portal slot; the `DefaultFontData` values; `khintssettings.cpp` lines outside the ones cited above.
- PI.37 Not read: `kdeplatformtheme.cpp:126-172` (font mapping and `loadSettings()` body), and `kdeplatformtheme.cpp:185-272` (key bindings).
- PI.38 Not read: the CMake files, `mono_font.pl`, `mono_font.upd`, `renderer.kcfg`, `renderersettings.kcfgc`, and the Qt 5 sources.
- PI.39 UNVERIFIED: whether `KIconEngine` in the Qt 6 tree and the KDE icon loader have other icon-theme fallbacks; not checked.
