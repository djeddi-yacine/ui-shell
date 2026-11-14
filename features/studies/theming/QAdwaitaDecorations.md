# QAdwaitaDecorations: Qt Wayland client-side window decoration plugin in Adwaita style

Source: refs/QAdwaitaDecorations (shallow clone; commit 440d4b0, 2026-08-06; branch main). License: LGPL 2.1 "or any later version", `README.md:31-32`, with the file `LICENSE` (text not read). Scope: whole repo (9 tracked files: README.md, LICENSE, CMakeLists.txt, src/CMakeLists.txt, src/qadwaitadecorations.h (124 lines), src/qadwaitadecorations.cpp (954 lines), src/qadwaitadecorationsplugin.h (36 lines), src/qadwaitadecorationsplugin.cpp (30 lines), src/qadwaitadecorations.json (5 lines)). Read in detail: the plugin, the class header, and about 15 ranges of the class implementation.
Id prefix: QAD.

## 1. Purpose and shape
- QAD1.1 A Qt Wayland decoration plugin that draws Adwaita-like client-side window decorations (title bar, buttons, shadows) for Wayland windows. `README.md:1-2`: "Qt decoration plugin implementing Adwaita-like client-side decorations." Language: C++ with Qt Wayland client private API, SVG icons and D-Bus.
- QAD1.2 Top-level layout: `src/` (qadwaitadecorations.cpp/.h: the decoration class; qadwaitadecorationsplugin.cpp/.h: the plugin factory; qadwaitadecorations.json: plugin metadata; src/CMakeLists.txt: target and install); `CMakeLists.txt`; `README.md`; `LICENSE`.
- QAD1.3 Build system: CMake. Qt minimum 6.5.0 for Qt 6 (`CMakeLists.txt:13`) and 5.15.2 for Qt 5 (`CMakeLists.txt:17`). Build switch `USE_QT6` defaults OFF (`CMakeLists.txt:8`). The build needs Qt Gui Private and Wayland Client Private (`CMakeLists.txt:49` `find_package(Qt...Gui ... Private)`; for Qt 6.10 or later also `Qt6GuiPrivate` and `Qt6WaylandClientPrivate` at `CMakeLists.txt:28-29`, `:42-45`). `src/CMakeLists.txt:8-13` links the target to `Qt${QT_VERSION_MAJOR}::WaylandClientPrivate`. Optional XKB common support is looked up at `CMakeLists.txt:57`. Shadow support is enabled when `HAS_QT6_SUPPORT` or `USE_QT6` is set (`CMakeLists.txt:60-63`, compile definition `-DHAS_QT6_SUPPORT` at `:63`).
- QAD1.4 The README states that the library "uses private Qt headers and will likely not be forward nor backward compatible. This library will have to be recompiled with every Qt update." `README.md:4-7` (lines 5-7 for the sentence).

## 2. Theme input (how configuration reaches it)
- QAD2.1 Activation environment variable: `QT_WAYLAND_DECORATION=adwaita` (`README.md:20-23`). For Qt 6 builds that ship the plugin, `QT_WAYLAND_DECORATION=qadwaitadecorations` forces this plugin (`README.md:26-28`).
- QAD2.2 Settings source: the XDG Desktop Portal Settings interface over the session D-Bus. `QAdwaitaDecorations::initConfiguration()` (`src/qadwaitadecorations.cpp:113`) calls `org.freedesktop.portal.Settings.ReadAll` on `/org/freedesktop/portal/desktop` with namespaces `org.gnome.desktop.wm.preferences` and `org.freedesktop.appearance` (`qadwaitadecorations.cpp:120-125`), asynchronously (`:127-131`).
- QAD2.3 Keys read from the ReadAll reply: `org.freedesktop.appearance` / `color-scheme` (`qadwaitadecorations.cpp:136-140`, value 1 means prefer dark, line 140); `org.gnome.desktop.wm.preferences` / `button-layout` (`:142-143`); `titlebar-uses-desktop-font` (`:153-155`); and a title-bar font key (`:158-160`, workaround comment at `:149`).
- QAD2.4 Live updates: the class connects to the portal signal `SettingChanged` (`qadwaitadecorations.cpp:172-175`). `settingChanged(group, key, value)` (`:286-297`) handles `button-layout` (`:288-290`, calls `updateTitlebarLayout`) and `color-scheme` (`:291-295`, calls `updateColors(colorScheme == 1)`).
- QAD2.5 Title-bar font: taken from `QPlatformTheme::TitleBarFont` of the current platform theme (`qadwaitadecorations.cpp:104-106`); fallback `QFont("Sans", 10)` (`:107-108`).
- QAD2.6 Environment variables used by the plugin: `QT_WAYLAND_DECORATION` only (README; the C++ code does not read it, UNVERIFIED: Qt reads it before loading the plugin).
- QAD2.7 Command-line flags: None found.
- QAD2.8 Icon theme input: the icon search uses `QIcon::themeName()`, `QIcon::fallbackThemeName()` and the hard-coded theme `Adwaita` (`qadwaitadecorations.cpp:201-202`), searched over `QIcon::themeSearchPaths()` (theme loop at `:205`, path loop at `:206`, paths starting with `:` skipped at `:207-208`).

## 3. Color and style model
- QAD3.1 Colour roles: `enum ColorType` in `src/qadwaitadecorations.h:39-50` with members `Background`, `BackgroundInactive`, `Foreground`, `ForegroundInactive`, `Border`, `BorderInactive`, `Shadow`, `ButtonBackground`, `ButtonBackgroundInactive`, `HoveredButtonBackground`, `PressedButtonBackground`. Stored in `QMap<ColorType, QColor> m_colors` (`src/qadwaitadecorations.h:116`).
- QAD3.2 Colour values: fixed hex values for two modes, set by `QAdwaitaDecorations::updateColors(bool useDarkColors)` (`src/qadwaitadecorations.cpp:181`, map literal at `:186-196`). Dark: Background `#2e2e32` (`:186`), BackgroundInactive `#222226` (`:187`), Foreground `#ffffff` (`:188`), ForegroundInactive `#919193` (`:189`), Border `#3d3d40` (`:190`), BorderInactive `#313135` (`:191`), Shadow `#2e2e32` (`:192`), ButtonBackground `#434347` (`:193`), ButtonBackgroundInactive `#2d2d31` (`:194`), HoveredButtonBackground `#4d4d51` (`:195`), PressedButtonBackground `#6c6c6f` (`:196`). Light values are the second operand of each ternary on the same lines (for example Background `#ffffff` at `:186`, Foreground `#333338` at `:188`, Border `#c8c8c8` at `:190`).
- QAD3.3 Colour derivation: there is no shade or mix computation. The only transform is `makeTransparent(const QColor &color, qreal level)` (`qadwaitadecorations.cpp:376-380`, sets alpha through `setAlphaF(level)` at `:379`). Hover and pressed colours are fixed table entries (QAD3.2).
- QAD3.4 Colour scheme handling: `color-scheme` value 1 selects the dark table; any other value selects the light table (`qadwaitadecorations.cpp:140`, `:294`). Active and inactive windows use separate entries (`Background` vs `BackgroundInactive`, etc.).
- QAD3.5 Per-state handling: the decoration distinguishes active and inactive windows (`BackgroundInactive`, `ForegroundInactive`, `BorderInactive`, `ButtonBackgroundInactive` in QAD3.2), and button hover and pressed states (`HoveredButtonBackground`, `PressedButtonBackground`). Button state to icon selection is `iconFromButtonAndState` (`qadwaitadecorations.cpp:607`).
- QAD3.6 Window-state input: `paint` reads `waylandWindow()->windowStates()` (`qadwaitadecorations.cpp:386`), and the window-maximised check is at `:339`, which drives maximised/fullscreen geometry (UNVERIFIED: the branch body was not read in full).
- QAD3.7 Title-bar geometry constants: `ceButtonSpacing = 12`, `ceButtonWidth = 24`, `ceCornerRadius = 12`, `ceShadowsWidth = 10`, `ceTitlebarHeight = 38`, `ceWindowBorderWidth = 1` (`qadwaitadecorations.cpp:48-53`).

## 4. Output and rendering path
- QAD4.1 Plugin entry point: `class QAdwaitaDecorationsPlugin : public QWaylandDecorationPlugin` (`src/qadwaitadecorationsplugin.h:27`) with `Q_PLUGIN_METADATA(IID QWaylandDecorationFactoryInterface_iid FILE "qadwaitadecorations.json")` (`qadwaitadecorationsplugin.h:30`).
- QAD4.2 Factory: `QAdwaitaDecorationsPlugin::create(system, paramList)` returns `new QAdwaitaDecorations()` when `system` is `"adwaita"`, `"gnome"` or `"qadwaitadecorations"` (`src/qadwaitadecorationsplugin.cpp:23-29`, check at line 26). Metadata `src/qadwaitadecorations.json:2` lists those three keys.
- QAD4.3 Decoration class: `class QAdwaitaDecorations : public QWaylandAbstractDecoration` (`src/qadwaitadecorations.h:35`). Constructor at `src/qadwaitadecorations.cpp:85`. It calls `initConfiguration()` (the portal ReadAll and SettingChanged setup at `:113-175`), then `updateColors(false)` (`:177`) and `updateIcons()` (`:178`).
- QAD4.4 Icon loading: `updateIcons()` (`qadwaitadecorations.cpp:236-244`) loads one SVG per button icon from `buttonMap` (`:55-61`, names such as `window-close-symbolic`, `window-minimize-symbolic`) through `getIconSvg(fullName)` (`:240`), which searches the icon theme directories (QAD2.8). `QtSvg/QSvgRenderer` is included at `qadwaitadecorations.cpp:36`.
- QAD4.5 Paint entry point: `QAdwaitaDecorations::paint(QPaintDevice *device)` (`src/qadwaitadecorations.cpp:383`). Helper functions in the same file: `makeTransparent` (`:376`), `renderFlatRoundedButtonFrame` (`:561`), `renderButtonIcon` (SVG name overload `:572`, enum overload `:595`), `iconFromButtonAndState` (`:607`).
- QAD4.6 Button paint: `QAdwaitaDecorations::paintButton(Button button, QPainter *painter)` (`src/qadwaitadecorations.cpp:620`) chooses the background from the colour table and draws the icon from `m_icons`. Button geometry: `buttonRect(Button button)` at `src/qadwaitadecorations.cpp:300`.
- QAD4.7 Shadow and blur: the background image is produced by drawing a rounded rectangle with `QPainterPath` / `drawRoundedRect(topHalf, ceCornerRadius, ceCornerRadius)` (`qadwaitadecorations.cpp:424`) into a temporary image, then `fillRect(rect, QColor(0, 0, 0, 160))` with `CompositionMode_SourceIn` on a margin-reduced rectangle (`:444-449`). The blur uses Qt's private `qt_blurImage` declared at `qadwaitadecorations.cpp:62-63`, imported with `Q_DECL_IMPORT`.
- QAD4.8 Redraw: `forceRepaint()` (`qadwaitadecorations.cpp:775`) is called after icon and colour changes.
- QAD4.9 Input: mouse handlers per edge, `processMouseTop` (`:788`), `processMouseBottom` (`:869`), `processMouseLeft` (`:906`), `processMouseRight` (`:921`), which hit-test the frame for move, resize and button presses (bodies not read).
- QAD4.10 Title-bar layout: `updateTitlebarLayout(const QString &layout)` (`qadwaitadecorations.cpp:246`) parses the `button-layout` string from the portal (QAD2.4). The parse body was not read.

## 5. Extension and integration points
- QAD5.1 Plugin install: `install(TARGETS qadwaitadecorations DESTINATION ${QT_PLUGINS_DIR}/wayland-decoration-client)` (`src/CMakeLists.txt:26`). Qt loads it through the `wayland-decoration-client` plugin directory when `QT_WAYLAND_DECORATION` names one of the keys in QAD4.2.
- QAD5.2 Plugin interface: `QWaylandDecorationPlugin` / `QWaylandDecorationFactoryInterface_iid` (QAD4.1), a Qt private Wayland client interface.
- QAD5.3 Portal dependency: the plugin requires a running `org.freedesktop.portal.Desktop` service on the session bus that implements `org.freedesktop.portal.Settings` (QAD2.2, QAD2.4). Without it, the code path still sets defaults (`updateColors(false)` at the constructor, QAD4.3).
- QAD5.4 ABI and version coupling: uses private Qt headers and `Qt::WaylandClientPrivate` (QAD1.3). The README says it must be recompiled with every Qt update (QAD1.4). Qt 6.5.0 and Qt 5.15.2 minimums (QAD1.3).
- QAD5.5 Qt 5 path: when built against Qt 5, the README recommends Qt 6 backports and links a Fedora patch (`README.md:8`; the URL is in the README and is not reproduced here). Code guards in the constructor: `HAS_QT6_SUPPORT` at `qadwaitadecorations.cpp:87`, `QT_VERSION >= 0x060000` at `:88`, log "Using Qt6 version" (`:89`), log "Using Qt5 version with Qt6 backports" (`:91`), log "Using Qt5 version" (`:94`). Further `HAS_QT6_SUPPORT` guards at `:310` and `:317`.
- QAD5.6 Environment selection: `QT_WAYLAND_DECORATION` (QAD2.1).

## 6. Data and tooling
- QAD6.1 Icons: SVGs are not shipped in this repo; the plugin reads them from the active icon theme (QAD2.8, QAD4.4).
- QAD6.2 Plugin metadata: `src/qadwaitadecorations.json` (QAD4.2).
- QAD6.3 Build files: `CMakeLists.txt` and `src/CMakeLists.txt` (QAD1.3, QAD5.1).
- QAD6.4 Tests and translations: none in the tracked file list.

## 7. Facts of note
- QAD7.1 The README warns that the library depends on private Qt headers and must be rebuilt for every Qt update (QAD1.4).
- QAD7.2 The plugin is a decoration for Wayland only: it derives from `QWaylandAbstractDecoration` (QAD4.3) and the Qt private Wayland client classes (QAD1.3).
- QAD7.3 Settings are read through the XDG Portal, not through GSettings or the `dconf` file directly (QAD2.2). The code calls the portal method `ReadAll` and the signal `SettingChanged` (QAD2.2, QAD2.4).
- QAD7.4 Colours are a fixed table for light and dark (QAD3.2). The derivation rules are not present in the code.
- QAD7.5 The title-bar font is taken from the platform theme, with a hard-coded fallback of Sans 10 (QAD2.5).
- QAD7.6 Qt 6 includes its own version of this decoration (`README.md:26`). The README tells users to set `QT_WAYLAND_DECORATION=qadwaitadecorations` to force this plugin in that case (`README.md:26-28`).
- QAD7.7 The code uses a private Qt symbol `qt_blurImage` (QAD4.7). This is an additional ABI dependency beyond the headers.

## 8. Not covered
- Not read: the body of `paint` (`qadwaitadecorations.cpp:383-560`), `paintButton` (`:620-774`), and the mouse handlers (`:788-954`) beyond the signatures cited.
- Not read: `updateTitlebarLayout` body (`:246-285`) and `settingChanged` beyond the lines cited.
- Not read: `getIconSvg` beyond line 215 (the file-match condition after `QFileInfo`).
- Not read: `README.md:9-18` and `README.md:33` onwards (only the lines cited).
- Not read: the full `CMakeLists.txt` option list beyond the lines cited.
- Not verified: the exact function that calls the three constructor steps (QAD4.3).
- Not verified: the body of `buttonRect` line numbers (QAD4.6).
- Spot-check: the following citations were re-read in this session and confirmed: `src/qadwaitadecorationsplugin.cpp:23-29`, `src/qadwaitadecorations.cpp:186-196`, `src/qadwaitadecorations.cpp:286-297`, `src/qadwaitadecorations.cpp:123`, `src/qadwaitadecorations.cpp:376-379`, `src/qadwaitadecorations.cpp:48-53`, `src/qadwaitadecorations.cpp:300`, `src/qadwaitadecorations.cpp:177-178`, `src/qadwaitadecorations.json:2`, `src/CMakeLists.txt:26`, `CMakeLists.txt:13`, `CMakeLists.txt:17`, `README.md:20-28`.
