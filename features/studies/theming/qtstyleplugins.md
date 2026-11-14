# qtstyleplugins: Qt5-era style and platform-theme plugins (GTK2 style, GTK2 platform theme, Cleanlooks, Plastique, Motif/CDE, BB10)

Source: refs/qtstyleplugins (shallow clone; commit 335dbec, 2017-03-11; branch master). License: no LICENSE or LGPL file at the top level of the tree (`ls` checked). Source headers state `$QT_BEGIN_LICENSE:LGPL21$` (`src/plugins/styles/gtk2/qgtkstyle.cpp:8`, `src/plugins/platformthemes/gtk2/qgtk2theme.cpp:8`) or `$QT_BEGIN_LICENSE:LGPL$` (`src/plugins/styles/cleanlooks/qcleanlooksstyle.cpp:8`, `src/plugins/styles/plastique/qplastiquestyle.cpp:8`, `src/plugins/styles/motif/qmotifstyle.cpp:8`). The GTK2 platform theme header names `LICENSE.LGPLv3` and `LGPL_EXCEPTION.txt` (`src/plugins/platformthemes/gtk2/qgtk2theme.h:21`, `:28`); those files are not present at the top level. Scope: the whole `src/` tree at the level of plugin mechanisms; `bb10style` is listed in the layout but not studied in depth.
Id prefix: QS.

## 1. Purpose and shape
- QS1.1 The repo is a set of Qt plugins written in C++ with qmake project files. The Qt version it targets is set by the qmake conditions in QS1.3 and QS7.4. The commit at HEAD is "Fix plastique, cleanlooks and motif animation timer" (`git log -1 --format=%s`). Each plugin's `.pro` file sets `PLUGIN_TYPE` and `PLUGIN_CLASS_NAME` (see QS5.2).
- QS1.2 Top-level layout: `qtstyleplugins.pro` (root qmake project), `src/` (`src.pro:2` SUBDIRS = plugins), `src/plugins/` (`plugins.pro:2` SUBDIRS = platformthemes styles), `src/plugins/platformthemes/gtk2/` (GTK2 platform theme), `src/plugins/styles/` (`styles.pro`, with subdirs `cleanlooks`, `motif`, `plastique`, `bb10style`, `gtk2`, and `shared`). No README, docs, tests or generator scripts are present in the tree (`rg --files` listing).
- QS1.3 Build conditions (qmake): `styles.pro:2-5` always builds cleanlooks, motif and plastique. `styles.pro:7-10` adds bb10style only for Qt 5.7 or later. `styles.pro:12-14` adds gtk2 only when `packagesExist(gtk+-2.0 x11)`. `src/plugins/platformthemes/platformthemes.pro:3-5` adds the GTK2 platform theme when `packagesExist(gtk+-2.0)`.
- QS1.4 Build dependencies: GTK 2 through pkg-config. `src/plugins/styles/gtk2/gtk2.pro:8-9` (`link_pkgconfig`, `PKGCONFIG += gtk+-2.0 x11`) and `src/plugins/platformthemes/gtk2/gtk2.pro:9-11` (`PKGCONFIG += gtk+-2.0`). The Qt modules: `gtk2.pro:6` (style) uses `core-private gui-private widgets-private`; platform theme `gtk2.pro:3` uses `core-private gui-private`. Plastique (`plastique.pro:6`) uses `core-private gui-private widgets`. Cleanlooks (`cleanlooks.pro:6`) and Motif (`motif.pro:6`) use `core gui widgets`.

## 2. Theme input (how configuration reaches it)
- QS2.1 GTK2 style and GTK2 platform theme read the active GTK 2 theme from `GtkSettings` through `gtk_settings_get_default()`, not from files. Style theme name: `QGtkStylePrivate::getThemeName()` reads property `gtk-theme-name` (`src/plugins/styles/gtk2/qgtkstyle_p.cpp:368-377`, property read at `:374`).
- QS2.2 Platform theme reads GTK settings by property name through a helper `gtkSetting(const gchar *propertyName)` (`src/plugins/platformthemes/gtk2/qgtk2theme.cpp:47-55` as the function body start; `:45` defines `QGtk2Theme::name = "gtk2"`). Keys requested: `gtk-icon-theme-name` (`qgtk2theme.cpp:72`), `gtk-fallback-icon-theme` (`:74`), `gtk-font-name` (`:84`).
- QS2.3 GTK 2 is initialised inside the style: `gtk_init(NULL, NULL)` at `src/plugins/styles/gtk2/qgtkstyle_p.cpp:276`, preceded by a save and reset of the X error handler (`:273-275`). Refusal of initialisation under setuid is coded at `:268-271` area.
- QS2.4 Optional Ubuntu symbol: `ubuntu_gtk_set_use_overlay_scrollbar` is resolved with `QLibrary::resolve(QLS("gtk-x11-2.0"), ...)` at `src/plugins/styles/gtk2/qgtkstyle_p.cpp:279`. This is the only runtime library lookup for GTK in this path; the rest is link-time through pkg-config (QS1.4).
- QS2.5 Qt-side palette: `QGtkStyle::standardPalette()` (`src/plugins/styles/gtk2/qgtkstyle.cpp:331`) and `QGtkStyle::polish(QPalette &palette)` (`:421`) compute the palette from the GTK style. Application-level polish at `:434` and `:454`; widget-level at `:469` and `:495`.
- QS2.6 UNVERIFIED: whether Cleanlooks, Plastique and Motif read any configuration input. Their source files were not searched for QSettings or file reads.
- QS2.7 Plugin selection by Qt is by key only (QS5.3); no environment variable was found in the code read.

## 3. Color and style model
- QS3.1 GTK2 style class: `class QGtkStyle : public QCommonStyle` (`src/plugins/styles/gtk2/qgtkstyle_p.h:59-61`). Private data: `class QGtkStylePrivate : public QCommonStylePrivate` (`src/plugins/styles/gtk2/qgtkstyle_p_p.h:140`). Painting helper: `class QGtkPainter` (`src/plugins/styles/gtk2/qgtkpainter_p.h:59`) and `class QGtk2Painter : public QGtkPainter` (`src/plugins/styles/gtk2/qgtk2painter_p.h:54`).
- QS3.2 GTK2 colours come from real GTK widgets. The style creates GTK widgets once and keeps a map from a widget path string to the widget: `QGtkStylePrivate::gtkWidget(path)` (`src/plugins/styles/gtk2/qgtkstyle_p.cpp:184-192`) and `gtkStyle(path)` (`:194`). Initialisation helpers: `initGtkMenu` (`:214`), `initGtkTreeview` (`:245`), `initGtkWidgets` (`:259`). A popup window is created for the widget set at `:284` (`gtk_window_new(GTK_WINDOW_POPUP)`).
- QS3.3 The style reads GTK style colour arrays from the widget style (`gtk_widget_get_style` used at `src/plugins/styles/gtk2/qgtkstyle.cpp:337` and `:867`; the helper `gtkStyle()` is called at `:84`).
- QS3.4 Cleanlooks class: `class QCleanlooksStyle : public QProxyStyle` (`src/plugins/styles/cleanlooks/qcleanlooksstyle.h:54-56`).
- QS3.5 Plastique class: `class QPlastiqueStyle : public QProxyStyle` (`src/plugins/styles/plastique/qplastiquestyle.h:54-56`).
- QS3.6 Motif class: `class QMotifStyle : public QCommonStyle` (`src/plugins/styles/motif/qmotifstyle.h:57-59`). CDE: `class QCDEStyle : public QMotifStyle` (`src/plugins/styles/motif/qcdestyle.h:52-54`).
- QS3.7 Shared helpers in `src/plugins/styles/shared/` (`qstylehelper.cpp`, `qstylehelper_p.h`, `qstylecache_p.h`, `qhexstring_p.h`, `shared.pri`). Included by Cleanlooks, Plastique and GTK2 through `include(../shared/shared.pri)` (`cleanlooks.pro:12`, `plastique.pro:12`, `gtk2.pro:15`). Function bodies were not read (UNVERIFIED for specific shade formula).
- QS3.8 Per-state handling and shade derivation: not traced in this study (UNVERIFIED for the exact mapping of Qt states to GTK states).
- QS3.9 Animation: the commit subject refers to a timer fix in plastique, cleanlooks and motif (commit subject, QS1.1). Timer code was not read.

## 4. Output and rendering path
Input to pixels, GTK2 style (ordered):
- QS4.1 `QGtkStyle::polish(QApplication*)` (`src/plugins/styles/gtk2/qgtkstyle.cpp:434`) and `polish(QWidget*)` (`:469`) prepare widgets. The style is built from a GTK style object reached through `gtkStyle()` (QS3.2, QS3.3).
- QS4.2 `QGtkStyle::drawPrimitive` (`src/plugins/styles/gtk2/qgtkstyle.cpp:855`), `drawComplexControl` (`:1447`) and `drawControl` (`:2630`) are the draw entry points. They delegate to `QGtkPainter` / `QGtk2Painter`.
- QS4.3 `QGtk2Painter` calls GTK 2 paint functions by name, for example `gtk_paint_check`, `gtk_paint_expander`, `gtk_paint_extension`, `gtk_paint_flat_box`, `gtk_paint_focus`, `gtk_paint_handle`, `gtk_paint_hline`, `gtk_paint_option`, `gtk_paint_resize_grip`, `gtk_paint_shadow`, `gtk_paint_slider`, `gtk_paint_vline` (`src/plugins/styles/gtk2/qgtk2painter.cpp`, names listed by `rg`; line numbers not individually re-read).
- QS4.4 `QGtk2Painter::renderTheme(uchar *bdata, uchar *wdata, const QRect &rect)` (`src/plugins/styles/gtk2/qgtk2painter.cpp:51`) converts the GTK-rendered pixel buffer (BGRA, reads `GTK_BLUE` channel at `:55-57`) into a QPixmap, using an alpha flag (`m_alpha`).
- QS4.5 Cleanlooks and Plastique are QProxyStyle subclasses (QS3.4, QS3.5). Motif and CDE derive from QCommonStyle (QS3.6). Their draw overrides are in `qcleanlooksstyle.cpp`, `qplastiquestyle.cpp`, `qmotifstyle.cpp` and `qcdestyle.cpp`; these were not read (UNVERIFIED for which functions are overridden).
- QS4.6 Generated or bundled assets: BB10 PNG assets under `src/plugins/styles/bb10style/bright/` and `.../dark/` are referenced by `.qrc` files (`bb10lightstyle.qrc`, `qbb10brightstyle.qrc`, `qbb10darkstyle.qrc`). Cleanlooks, Plastique and Motif draw procedurally (UNVERIFIED for the full set).

## 5. Extension and integration points
- QS5.1 Platform theme plugin: `class QGtk2ThemePlugin : public QPlatformThemePlugin` (`src/plugins/platformthemes/gtk2/main.cpp:39`), with `Q_PLUGIN_METADATA(IID QPlatformThemeFactoryInterface_iid FILE "gtk2.json")` (`main.cpp:42`). The plugin's class name is set by `PLUGIN_CLASS_NAME = QGtk2ThemePlugin` (`src/plugins/platformthemes/gtk2/gtk2.pro:24`) and the type is `PLUGIN_TYPE = platformthemes` (`gtk2.pro:22`).
- QS5.2 Style plugins: each `plugin.cpp` declares a `QStylePlugin` subclass with `Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QStyleFactoryInterface" FILE "<name>.json")`:
  - GTK2: `class QGtk2StylePlugin : public QStylePlugin`, `plugin.cpp:39-42`, JSON `gtk2.json`.
  - Plastique: `class QPlastiqueStylePlugin`, `plugin.cpp:47-50`, JSON `plastique.json`.
  - Motif: `class QMotifStylePlugin`, `plugin.cpp:48-51`, JSON `motif.json`.
  - Cleanlooks: `class QCleanlooksStylePlugin`, `plugin.cpp:47-50`, JSON `cleanlooks.json`.
  - Build variables `PLUGIN_TYPE = styles` and `PLUGIN_CLASS_NAME` per `.pro` (for example `gtk2.pro:2-3`, `motif.pro:2`, `cleanlooks.pro:2-3`, `plastique.pro` similar).
- QS5.3 Keys (what Qt matches when selecting a style or platform theme): `gtk2.json` contains `"Keys": [ "gtk2" ]` for both the style and the platform theme (`src/plugins/styles/gtk2/gtk2.json`, `src/plugins/platformthemes/gtk2/gtk2.json`). `cleanlooks.json` `["cleanlooks"]`, `motif.json` `["motif", "cde"]`, `plastique.json` `["plastique"]`.
- QS5.4 Private-header coupling: the GTK2 style includes Qt private headers: `qgtkstyle.cpp:35` (`private/qapplication_p.h`), `:63` (`private/qstyleanimation_p.h`), `:66` (`private/qstylehelper_p.h`); `qgtkstyle_p_p.h:57` (`private/qcommonstyle_p.h`); `qgtk2painter.cpp:42` (`private/qhexstring_p.h`). The GTK2 platform theme includes `private/qgenericunixthemes_p.h` (`src/plugins/platformthemes/gtk2/qgtk2theme.h:37`), and `QGtk2Theme : public QGnomeTheme` (`qgtk2theme.h:41`). `qgtk2dialoghelpers.cpp:42` includes `private/qguiapplication_p.h`. These are Qt-internal headers and depend on the Qt version the plugin is built against (UNVERIFIED for specific version floor beyond the qmake conditions in QS1.3).
- QS5.5 Platform theme class coupling: `QGtk2Theme` derives from `QGnomeTheme`, a private class in Qt (`qgenericunixthemes_p.h`, QS5.4).
- QS5.6 Install and discovery: the `.pro` files use the `qt_plugin` mechanism. Install destination is set by Qt's plugin path (`PLUGIN_TYPE` values `styles` and `platformthemes`); explicit `target.path` lines were not found in the read files (UNVERIFIED for final install path).
- QS5.7 No environment variable selects these plugins in the code read. Selection is by Qt's style or platform-theme name (QS5.3).

## 6. Data and tooling
- QS6.1 Build: qmake project files (`*.pro`, `*.pri`). Root: `qtstyleplugins.pro`; subprojects listed in QS1.2.
- QS6.2 Resource files: `.qrc` for BB10 styles (`src/plugins/styles/bb10style/bb10lightstyle.qrc`, `qbb10darkstyle.qrc`, `qbb10brightstyle.qrc`).
- QS6.3 JSON plugin metadata: `*.json` per plugin (QS5.3).
- QS6.4 Tests, examples and documentation: none found in the tree (`rg --files` listing; UNVERIFIED for hidden directories).
- QS6.5 Git metadata: 167 tracked files (`git ls-files | wc -l`).

## 7. Facts of note
- QS7.1 The GTK2 style and platform theme need GTK 2 headers and libraries at build time (QS1.4) and expect GTK 2 at run time (`gtk_init` at `qgtkstyle_p.cpp:276`).
- QS7.2 `gtk_init` is wrapped with an X error-handler save and reset (`qgtkstyle_p.cpp:273-275`) because GTK installs its own handler.
- QS7.3 The GTK2 style refuses to initialise GTK for setuid processes, with a message that points to `gksudo` or `kdesudo` (`qgtkstyle_p.cpp:268-271` area).
- QS7.4 Qt 5.7 or later is required for the BB10 style (`styles.pro:7`).
- QS7.5 The GTK2 platform theme reads `gtk-icon-theme-name`, `gtk-fallback-icon-theme` and `gtk-font-name` (QS2.2). Other theme hints are not read by this file.
- QS7.6 The style key for Motif includes an alias `cde` (`src/plugins/styles/motif/motif.json`, QS5.3).
- QS7.7 The GTK2 style refers to an Ubuntu-specific symbol (QS2.4).
- QS7.8 Several Qt private modules are required (QS5.4). The code depends on Qt internals across versions.

## 8. Not covered
- The bodies of `qgtkstyle.cpp` draw functions beyond the entry-point line numbers (QS4.2).
- The bodies of `qgtk2painter.cpp` and `qgtkpainter.cpp` beyond `renderTheme` (QS4.4) and the list of GTK paint call names (QS4.3).
- The Cleanlooks, Plastique and Motif draw code and their shade or colour formulas (QS3.4 to QS3.6, QS4.5).
- The shared helpers in `src/plugins/styles/shared/` beyond their file names (QS3.7).
- The animation timer fix in the HEAD commit (QS3.9); the diff was not read.
- The `bb10style` sources.
- The GTK2 platform theme dialog helpers in `qgtk2dialoghelpers.cpp` beyond the include on line 42.
- Install paths and the full qmake `target.path` logic (QS5.6).
- Whether the license text files named in QS-header are shipped with the source archive (not in the top-level tree).
