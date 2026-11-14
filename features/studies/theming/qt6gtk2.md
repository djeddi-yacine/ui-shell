# qt6gtk2: GTK+ 2 integration for Qt 6 (QStyle plugin and QPlatformTheme plugin)

Source: refs/qt6gtk2 (shallow clone; commit b574ba5, 2024-08-14; branch master). License: GNU GPL version 2 (`COPYING:1-3`, text "GNU GENERAL PUBLIC LICENSE, Version 2, June 1991"). Scope: whole repo (`src/qt6gtk2-style/`, `src/qt6gtk2-qtplugin/`, `qt6gtk2.pri`, `qt6gtk2.pro`, `README.md`, `ChangeLog`, `qt6gtk2_release.sh`).
Id prefix: Q6G.

## 1. Purpose and shape
- Q6G1.1 A C++ project that builds two Qt 6 plugins so that Qt 6 applications use GTK+ 2 for style and platform-theme services. Language: C++17 (`qt6gtk2.pri:7`, `CONFIG += hide_symbols c++17`). Qt 6 only: `qt6gtk2.pri:17-19` errors out when `QT_MAJOR_VERSION` is not 6. README "Requirements" (`README.md:5-10`) lists "GNU Linux or FreeBSD", "qtbase >= 6.0.0 (with private headers)", "GTK+ 2.0", and "libX11".
- Q6G1.2 Two plugins: style plugin, target `qt6gtk2-style` (`src/qt6gtk2-style/qt6gtk2-style.pro:4`), and platform-theme plugin, target `qt6gtk2` (`src/qt6gtk2-qtplugin/qt6gtk2-qtplugin.pro:3`). README "Files and directories" names them `libqt6gtk2-style.so` and `libqt6gtk2.so` (`README.md:39-42`).
- Q6G1.3 Top-level layout: `qt6gtk2.pro` (TEMPLATE subdirs; `SUBDIRS += src/qt6gtk2-qtplugin src/qt6gtk2-style`, `qt6gtk2.pro:3`); `qt6gtk2.pri` (shared qmake settings and install paths); `src/qt6gtk2-style/` (GTK style plugin); `src/qt6gtk2-qtplugin/` (GTK platform-theme plugin and GTK dialog helpers); `ChangeLog`; `AUTHORS`; `README.md`; `qt6gtk2_release.sh` (runs `git archive` on tag `0.3` into an xz tarball, `qt6gtk2_release.sh:3-10`).
- Q6G1.4 Build system: qmake. System libraries are declared with `link_pkgconfig` and `PKGCONFIG += gtk+-2.0 x11` in `src/qt6gtk2-style/qt6gtk2-style.pro:21-23` and `src/qt6gtk2-qtplugin/qt6gtk2-qtplugin.pro:19-21`. Qt modules: `QT += core-private gui-private widgets-private` (`src/qt6gtk2-style/qt6gtk2-style.pro:5`) and `QT += core-private gui-private` (`src/qt6gtk2-qtplugin/qt6gtk2-qtplugin.pro:5`).

## 2. Theme input (how configuration reaches it)
- Q6G2.1 No configuration file is read. GTK 2 settings are read live from `GtkSettings` via `gtk_settings_get_default()` and `g_object_get`, for example `gtk-icon-sizes` (`src/qt6gtk2-style/qgtkstyle.cpp:557-559`) and `gtk-alternative-button-order` (`src/qt6gtk2-style/qgtkstyle.cpp:750`).
- Q6G2.2 Platform-theme helper `static QVariant gtkSetting(const gchar *propertyName)` (`src/qt6gtk2-qtplugin/qt6gtk2theme.cpp:32`) returns a GTK setting as a QVariant. Property names requested by `Qt6Gtk2Theme::themeHint`: `gtk-cursor-blink` and `gtk-cursor-blink-timeout` (`qt6gtk2theme.cpp:72`), `gtk-cursor-blink-time` (`:73`), `gtk-entry-password-hint-timeout` (`:78`), `gtk-button-images` (`:80`), `gtk-enable-accels` (`:82`), `gtk-icon-theme-name` (`:84`), `gtk-fallback-icon-theme` (`:86`). The font name `gtk-font-name` is requested in `gtkFontName()` (`qt6gtk2theme.cpp:99-101`).
- Q6G2.3 Style-side theme name: `QGtkStylePrivate::getThemeName()` (`src/qt6gtk2-style/qgtkstyle_p.cpp:359-366`) reads the `gtk-theme-name` property of `gtk_settings_get_default()` (`:363-365`). It is used to detect theme changes (Q6G7.5).
- Q6G2.4 Toolbar style is read from a GTK toolbar widget property `toolbar-style` (`src/qt6gtk2-style/qgtkstyle.cpp:765`; also `src/qt6gtk2-style/qgtkstyle_p.cpp:102`).
- Q6G2.5 Tooltip style: `gtk_rc_get_style_by_paths(gtk_settings_get_default(), "gtk-tooltips", "GtkWindow", ...)` (`src/qt6gtk2-style/qgtkstyle.cpp:396`), and a second call with the same first arguments at `:505`. This uses the GTK 2 RC-style mechanism.
- Q6G2.6 Environment variables: the README tells the user to set `QT_QPA_PLATFORMTHEME=gtk2` (`README.md:29`, `:33`) and says `QT_STYLE_OVERRIDE` should be removed (`README.md:45`). In code, the only environment read found in `src/` is `qgetenv("KDE_SESSION_VERSION")` (`src/qt6gtk2-style/qgtkstyle_p.cpp:389`). `QT_QPA_PLATFORMTHEME` is not read in `src/`; UNVERIFIED that Qt reads it, since the code path inside Qt was not studied.
- Q6G2.7 Font: `updateTheme` obtains the GTK font with `QGtkStylePrivate::getThemeFont()` (`src/qt6gtk2-style/qgtkstyle_p.cpp:495`; definition at `:528`, body not read).
- Q6G2.8 Platform-theme font name: `Qt6Gtk2Theme::gtkFontName()` (`src/qt6gtk2-qtplugin/qt6gtk2theme.cpp:99-101`).

## 3. Color and style model
- Q6G3.1 Style class: `class QGtkStyle : public QCommonStyle` (`src/qt6gtk2-style/qgtkstyle_p.h:49`). Private data: `class QGtkStylePrivate : public QCommonStylePrivate` (`src/qt6gtk2-style/qgtkstyle_p_p.h:120`). Event filter: `class QGtkStyleFilter : public QObject` (`qgtkstyle_p_p.h:109`). Scheduler: `class QGtkStyleUpdateScheduler : public QObject` (`qgtkstyle_p_p.h:197`).
- Q6G3.2 Colours come from GTK widgets, not from a colour file. `QGtkStyle::standardPalette()` (`src/qt6gtk2-style/qgtkstyle.cpp:320`) starts from `QCommonStyle::standardPalette()` (`:324`). When a GTK widget is available, it takes `GtkWidget *gtkButton = d->gtkWidget("GtkButton")` (`:327`) and the base, text and selected/active entry colours from `gtk_widget_get_style(gtkEntry)`, e.g. `gtkEntryStyle->base[GTK_STATE_NORMAL]` and `->text[GTK_STATE_NORMAL]` (`:336-344`). The background is read from the GTK style: `gdkBg = style->bg[GTK_STATE_NORMAL]` (`:331`).
- Q6G3.3 Local colour variables `bg, base, text, fg, highlight, highlightText, inactiveHighlight, inactiveHighlightedText` are declared at `src/qt6gtk2-style/qgtkstyle.cpp:330`. The mapping of each variable to a QPalette role was not traced (UNVERIFIED).
- Q6G3.4 Tooltip: `gtk_rc_get_style_by_paths` for "gtk-tooltips" at `src/qt6gtk2-style/qgtkstyle.cpp:396` (Q6G2.5). The surrounding palette assignment was not traced (UNVERIFIED).
- Q6G3.5 Palette merge: `palette = palette.resolve(standardPalette())` at `src/qt6gtk2-style/qgtkstyle.cpp:417`.
- Q6G3.6 Shade derivation: no local lighten, darken or mix function was found in the files read. GTK 2 supplies the shaded colour arrays on `GtkStyle` (`bg`, `fg`, `base`, `text`, and others), which the style reads from GTK widgets (Q6G3.2). UNVERIFIED for the rest of the tree.
- Q6G3.7 Per-state handling: the painter passes GTK state values (for example `GTK_STATE_NORMAL`) into each `gtk_paint_*` call (`src/qt6gtk2-style/qgtk2painter.cpp:136`, `:201`, `:254`). The mapping from Qt state flags to GTK states was not traced (UNVERIFIED).

## 4. Output and rendering path
Style plugin, input to pixels, in call order:
- Q6G4.1 `QStyle *Qt6Gtk2StylePlugin::create(const QString &key)` (`src/qt6gtk2-style/plugin.cpp:36`) compares `QLibraryInfo::version()` with `QT_VERSION_MAJOR`/`QT_VERSION_MINOR` (`:38-39`), prints `qCritical` and returns `nullptr` on mismatch (`:41`). It returns `new QGtkStyle` for keys `gtk2`, `qt6gtk2`, `qt5gtk2` (`:45-46`).
- Q6G4.2 `QGtkStyle::QGtkStyle()` (`src/qt6gtk2-style/qgtkstyle.cpp:290`) calls `d->init()` (`:294`). `QGtkStylePrivate::init()` is defined at `src/qt6gtk2-style/qgtkstyle_p.cpp:161`, and calls `initGtkWidgets()` (`:163`).
- Q6G4.3 `QGtkStylePrivate::initGtkWidgets()` is defined at `src/qt6gtk2-style/qgtkstyle_p.cpp:249`. Named GTK widgets are looked up through `QGtkStylePrivate::gtkWidget(path)` (`src/qt6gtk2-style/qgtkstyle_p.cpp:174`). The widget map structure was not traced (UNVERIFIED).
- Q6G4.4 GTK initialisation: `gtk_init (nullptr, nullptr)` at `src/qt6gtk2-style/qgtkstyle_p.cpp:269`, with the Xlib error handler saved and restored around it (`XSetErrorHandler(nullptr)` at `:267`, restore at `:271`). The same save/restore pattern is in the platform theme (Q6G7.4).
- Q6G4.5 Style entry points: `QGtkStyle::polish(QPalette &)` (`qgtkstyle.cpp:410`), `polish(QApplication *)` (`:423`), which installs `d->filter` with `qApp->installEventFilter` (`:436`), `polish(QWidget *)` (`:458`), and `pixelMetric` (`:492`).
- Q6G4.6 Draw entry points: `drawPrimitive` (`src/qt6gtk2-style/qgtkstyle.cpp:841`), `drawComplexControl` (`:1438`), `drawControl` (`:2616`).
- Q6G4.7 `class QGtk2Painter : public QGtkPainter` (`src/qt6gtk2-style/qgtk2painter_p.h:42`) draws through GTK 2 `gtk_paint_*` functions. Each draw is wrapped in `DRAW_TO_CACHE(draw_func)` (macro at `src/qt6gtk2-style/qgtk2painter.cpp:66`). Verified call sites: `gtk_paint_box_gap` (`:136`), `gtk_paint_box` (`:201`), `gtk_paint_hline` (`:254`), `gtk_paint_vline` (`:284`), `gtk_paint_expander` (`:313`), `gtk_paint_focus` (`:336`), `gtk_paint_resize_grip` (`:361`). Each call is guarded by `QPixmapCache::find` (e.g. `:135`) and stored with `QPixmapCache::insert` (e.g. `:150`).
- Q6G4.8 `QPixmap QGtk2Painter::renderTheme(uchar *bdata, uchar *wdata, const QRect &rect) const` (`src/qt6gtk2-style/qgtk2painter.cpp:39`) reads the GTK output buffer per pixel (`bdata[index + GTK_BLUE]`, `:43`) and builds the QPixmap. `DRAW_TO_CACHE` calls `renderTheme` (`:97`, `:100`).
- Q6G4.9 Asset selection: no SVG or PNG theme assets are used by these files. Icons come through the Qt icon loader (`#include <private/qiconloader_p.h>`, `src/qt6gtk2-style/qgtkstyle_p.cpp:45`) and the `gtk-icon-theme-name` setting (Q6G2.2).
- Q6G4.10 Compile-time switch: `DEFINES += QT_NO_ANIMATION` (`src/qt6gtk2-style/qt6gtk2-style.pro:7`). The `#ifndef QT_NO_ANIMATION` blocks in `src/qt6gtk2-style/qgtkstyle.cpp` start at `:3476`, `:3480` and `:3485`.

Platform theme plugin, input to Qt services:
- Q6G4.11 `class Qt6Gtk2Theme : public QGnomeTheme` (`src/qt6gtk2-qtplugin/qt6gtk2theme.h:28`). `Qt6Gtk2Theme::themeHint` (`src/qt6gtk2-qtplugin/qt6gtk2theme.cpp:67`) maps Qt theme hints to GTK settings (Q6G2.2). `usePlatformNativeDialog` (`:107`) and `createPlatformDialogHelper` (`:121`) choose GTK dialog helpers (e.g. `new Qt6Gtk2ColorDialogHelper` at `:125`).

## 5. Extension and integration points
- Q6G5.1 Style plugin: `class Qt6Gtk2StylePlugin : public QStylePlugin` (`src/qt6gtk2-style/plugin.cpp:27`), with `Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QStyleFactoryInterface" FILE "qt6gtk2.json")` (`plugin.cpp:30`). Keys in `src/qt6gtk2-style/qt6gtk2.json:2`: `"gtk2", "qt6gtk2", "qt5gtk2"`.
- Q6G5.2 Platform theme plugin: `class Qt6Gtk2ThemePlugin : public QPlatformThemePlugin` (`src/qt6gtk2-qtplugin/main.cpp:26`), with `Q_PLUGIN_METADATA(IID QPlatformThemeFactoryInterface_iid FILE "qt6gtk2.json")` (`main.cpp:29`). `create(key, params)` is at `main.cpp:35`, matches `gtk2` or `qt6gtk2` (and `qt5gtk2`) at `:38` and returns `new Qt6Gtk2Theme` at `:39`. Keys in `src/qt6gtk2-qtplugin/qt6gtk2.json:2` are identical to Q6G5.1.
- Q6G5.3 Install paths: `qt6gtk2.pri:22-24` sets `PLUGINDIR = $$[QT_INSTALL_PLUGINS]` if it is empty. Style plugin: `target.path = $$PLUGINDIR/styles` (`src/qt6gtk2-style/qt6gtk2-style.pro:25`). Platform theme: `target.path = $$PLUGINDIR/platformthemes` (`src/qt6gtk2-qtplugin/qt6gtk2-qtplugin.pro:23`).
- Q6G5.4 Discovery: Qt loads each plugin by key through its factory (Q6G5.1, Q6G5.2). The platform theme is selected by `QT_QPA_PLATFORMTHEME` (README, Q6G2.6). The style is selected by name or by `QT_STYLE_OVERRIDE`; the README says to unset `QT_STYLE_OVERRIDE` (`README.md:45`). The Qt-side selection code was not read (UNVERIFIED).
- Q6G5.5 Version gate: the style plugin refuses to load when the Qt major or minor version differs from the build (`src/qt6gtk2-style/plugin.cpp:38-41`). ChangeLog 0.2 records "Added Qt version checking" (`ChangeLog:8`). The platform theme plugin has no such check in `main.cpp:35-41` as read.
- Q6G5.6 Private-header coupling (Qt private headers, not stable API):
  - Style: `private/qcommonstyle_p.h` (`src/qt6gtk2-style/qgtkstyle_p_p.h:44`), `private/qapplication_p.h` (`src/qt6gtk2-style/qgtkstyle.cpp:23`; `qgtkstyle_p.cpp:44`), `private/qstyleanimation_p.h` (`qgtkstyle.cpp:51`), `private/qiconloader_p.h` (`qgtkstyle_p.cpp:45`), `private/qhexstring_p.h` (`qgtkpainter.cpp:25`, `qgtk2painter.cpp:30`, `qstylehelper_p.h:42`), `private/qmath_p.h` and `private/qstyle_p.h` (`qstylehelper.cpp:24-25`).
  - Platform theme: `private/qgenericunixthemes_p.h` (`src/qt6gtk2-qtplugin/qt6gtk2theme.h:24`), `private/qguiapplication_p.h` (`src/qt6gtk2-qtplugin/qt6gtk2dialoghelpers.cpp:30`).
  - README requires "qtbase >= 6.0.0 (with private headers)" (`README.md:8`). Breakage across Qt releases was not checked (UNVERIFIED).
- Q6G5.7 GTK 2 and X11 headers are included directly: `#include <gtk/gtk.h>` (`src/qt6gtk2-style/qgtkglobal_p.h:39`; `src/qt6gtk2-qtplugin/qt6gtk2dialoghelpers.cpp:34`; `src/qt6gtk2-qtplugin/qt6gtk2theme.cpp:26`), and `#include <X11/Xlib.h>` (`src/qt6gtk2-style/qgtkstyle_p.cpp:69`; `src/qt6gtk2-qtplugin/qt6gtk2theme.cpp:28`). `src/qt6gtk2-style/qgtkstyle_p.cpp:64` is `#error "cannot include <X11/Xlib.h> before this file"`.
- Q6G5.8 Dialog helpers in the platform theme plugin: `Qt6Gtk2ColorDialogHelper : public QPlatformColorDialogHelper` (`src/qt6gtk2-qtplugin/qt6gtk2dialoghelpers.h:40`), `Qt6Gtk2FileDialogHelper : public QPlatformFileDialogHelper` (`:65`), `Qt6Gtk2FontDialogHelper : public QPlatformFontDialogHelper` (`:104`). Their GTK 2 dialog implementations were not read (UNVERIFIED).

## 6. Data and tooling
- Q6G6.1 Build files: `qt6gtk2.pro`, `qt6gtk2.pri`, `src/qt6gtk2-style/qt6gtk2-style.pro`, `src/qt6gtk2-qtplugin/qt6gtk2-qtplugin.pro`. Intermediate output directories: `.build/ui`, `.build/moc`, `.build/obj`, `.build/rcc` (`qt6gtk2.pri:2-5`).
- Q6G6.2 Packaging: `qt6gtk2_release.sh` sets `VERSION=0.3` (`:3`) and `NAME=qt6gtk2` (`:5`), then runs `git archive` on the tag and writes `extras/package/sources/$TARBALL.tar.xz` (`:9-10`). It packages a tag; it does not build.
- Q6G6.3 Metadata: `src/qt6gtk2-style/qt6gtk2.json` and `src/qt6gtk2-qtplugin/qt6gtk2.json` (Q6G5.1, Q6G5.2). Release notes: `ChangeLog` (Q6G7.3). `AUTHORS` exists; its content was not read.
- Q6G6.4 Not present in the tree: tests, generator scripts, templates, or a theme-file format (`rg --files` on the repo root was not run exhaustively; UNVERIFIED for files outside the directories listed in Section 1).

## 7. Facts of note
- Q6G7.1 README "Requirements": "GNU Linux or FreeBSD", "qtbase >= 6.0.0 (with private headers)", "GTK+ 2.0", "libX11" (`README.md:7-10`).
- Q6G7.2 README: "Environment variable `QT_STYLE_OVERRIDE` should be removed before usage." (`README.md:45`).
- Q6G7.3 ChangeLog: 0.1 "inital release" (sic, `ChangeLog:5`); 0.2 "Added Qt version checking" (`:8`), "Added preview support to the file dialog" (`:9`), "Added "gtk2" platform theme key" (`:10`); 0.3 "Added Qt 6.8 support" (`:13`), "Fixed dock widget buttons size for Qt 6.7 or higher" (`:14`), "Improved GTK settings support" (`:15`).
- Q6G7.4 The platform theme saves the Xlib error handler, calls `gtk_init`, and restores the handler. The code comment says `gtk_init` resets the handler (`src/qt6gtk2-qtplugin/qt6gtk2theme.cpp:58-64`: comment `:58-59`, save `:60`, `gtk_init` `:62`, restore `:64`).
- Q6G7.5 Theme-change refresh: GTK's `style-set` signal is connected at `src/qt6gtk2-style/qgtkstyle_p.cpp:289` to `gtkStyleSetCallback` (`:89`), which posts `updateTheme` to the scheduler as a queued call (`:96`). `QGtkStyleUpdateScheduler::updateTheme` (`:490`) clears `QPixmapCache` (`:493`), updates the font (`:495`), and when `gtk-theme-name` has changed (`:499`), re-reads the palette (`:501`) and calls `initGtkWidgets()` (`:504`).
- Q6G7.6 A `notify::toolbar-style` handler is connected at `src/qt6gtk2-style/qgtkstyle_p.cpp:320`.
- Q6G7.7 `QGtkStyleFilter::eventFilter` handles `QEvent::ApplicationPaletteChange` (`src/qt6gtk2-style/qgtkstyle_p.cpp:135`). The code that would apply a custom palette hash is commented out (`:137-139`, as read).
- Q6G7.8 `CONFIG += hide_symbols` is set in `qt6gtk2.pri:7`. Whether this limits exported symbols to the plugin factory was not checked (UNVERIFIED).
- Q6G7.9 The only license file is GPL v2 (`COPYING`). The repo does not state provenance for code derived from Qt sources; whether any file derives from Qt's LGPL sources was not checked (UNVERIFIED).

## 8. Not covered
- Full bodies of `src/qt6gtk2-style/qgtkstyle.cpp` (about 3,500 lines), `qgtkstyle_p.cpp`, `qgtk2painter.cpp` and `qgtkpainter.cpp`, beyond the lines cited above.
- The widget list created in `initGtkWidgets` (Q6G4.3) and the lookup container type.
- The Qt-state-to-GTK-state mapping in `QGtk2Painter` (Q6G3.7).
- The body of `QGtkStylePrivate::getThemeFont()` (`qgtkstyle_p.cpp:528`).
- Dialog helper bodies in `src/qt6gtk2-qtplugin/qt6gtk2dialoghelpers.cpp`.
- The `QGnomeTheme` base class (external to the repo, from Qt).
- `AUTHORS`, and the README sections other than Requirements, Installation and the file list.
- Behaviour of `make install INSTALL_ROOT` (README only; not traced).
- Whether Qt itself reads `QT_QPA_PLATFORMTHEME` or `QT_STYLE_OVERRIDE` (Qt code is not in the repo).
