# QGnomePlatform: GNOME Qt platform theme and Wayland decoration plugins

Source: refs/QGnomePlatform (git clone; HEAD d86d6ba, dated 2023-08-11; branch master). Citations are `path:line` relative to the repo root.
Id prefix: QG.

## 1. Purpose and shape
- QG.1 The repo ships two Qt plugins: a platform theme (`src/theme/`) and a Wayland window decoration (`src/decoration/`). Shared code is in `src/common/`. Colors are in `src/color-schemes/` (4 `.colors` files). The README is at repo root.
- QG.2 The theme plugin is `QGnomePlatformThemePlugin`, which declares the Qt factory IID `org.qt-project.Qt.QPA.QPlatformThemeFactoryInterface.5.1` and the metadata file `qgnomeplatformtheme.json` (`src/theme/platformplugin.h:31`).
- QG.3 The main theme class is `QGnomePlatformTheme : public QPlatformTheme` (`src/theme/qgnomeplatformtheme.h:28`).
- QG.4 The Qt 6 build wraps a `QGenericUnixTheme` created for `"gnome"` and keeps it in `m_platformTheme` (`src/theme/qgnomeplatformtheme.cpp:90-93`). The theme also forwards some calls to it; the forwarding code was not read (see section 8).
- QG.5 Settings access is a singleton, `GnomeSettings::getInstance()` (`src/common/gnomesettings.cpp:69`).

## 2. Theme input
- QG.6 Plugin keys are `gnome` and `qgnomeplatform` (`src/theme/qgnomeplatformtheme.json:2`; `src/theme/platformplugin.cpp:27-33`). The decoration plugin uses the keys `gnome` and `qgnomeplatform` too (`src/decoration/qgnomeplatformdecoration.json:2`).
- QG.7 `GnomeSettings` chooses a backend in its constructor (`src/common/gnomesettings.cpp:80-101`):
  1. Sandboxed (flatpak or snap) runs use the portal backend `PortalHintProvider` (`gnomesettings.cpp:82-84`). The sandbox check looks for `flatpak-info` in the runtime directory or an environment variable (`gnomesettings.cpp:66`).
  2. `XDG_CURRENT_DESKTOP=x-cinnamon` uses `GSettingsHintProvider` (`gnomesettings.cpp:85-88`).
  3. If the service `org.freedesktop.impl.portal...` is registered on the session bus, the portal backend is used; otherwise GSettings (`gnomesettings.cpp:90-100`).
  4. A `QDBusServiceWatcher` on `org.freedesktop.portal.Desktop` switches the backend when the portal appears (`gnomesettings.cpp:102-114`).
- QG.8 GSettings backend reads two schemas: `org.gnome.desktop.wm.preferences` and `org.gnome.desktop.interface` (`src/common/gsettingshintprovider.cpp:46-47`). Keys read include `gtk-theme`, `color-scheme`, `icon-theme`, `cursor-blink-time`, `cursor-size`, `cursor-theme`, `font-name`, `monospace-font-name`, `titlebar-font`, and `button-layout` (`gsettingshintprovider.cpp:110-130`, `:138-150`).
- QG.9 Portal backend calls `org.freedesktop.portal.Settings.ReadAll` for the namespaces `org.gnome.desktop.interface`, `org.gnome.desktop.wm.preferences` and `org.freedesktop.appearance` (`src/common/portalhintprovider.cpp:60-63`). It uses the same keys; `org.freedesktop.appearance` is checked for availability at `portalhintprovider.cpp:100-101`. Change handling is at `portalhintprovider.cpp:118-136`.
- QG.10 The file chooser portal is used only when the app is not sandboxed and the FileChooser portal reports a version (`src/common/gnomesettings.cpp:141-156`).
- QG.11 Dark variant is decided by the GTK theme name or the appearance hint: the name contains `-dark` or ends in `inverse`, or the appearance is `PreferDark` (`src/common/gnomesettings.cpp:224`, `:384`).
- QG.12 The high-contrast variant is decided by the GTK theme name starting with `highcontrast` (`src/common/gnomesettings.cpp:227-231`).

## 3. Color and style model
- QG.13 Palettes come from built-in Adwaita color tables. `loadPalette()` (`src/common/gnomesettings.cpp:271-288`) picks one of `Adwaita::Colors::palette(...)` variants: high contrast (light or inverse) or Adwaita (light or dark), based on the two checks in QG.11 and QG.12.
- QG.14 `QGnomePlatformTheme::palette()` returns the single `GnomeSettings` palette for every palette type (`src/theme/qgnomeplatformtheme.cpp:137-141`, the `Q_UNUSED(type)` shows no per-type handling).
- QG.15 `loadPalette()` also sets the Qt property `KDE_COLOR_SCHEME_PATH` on the application to a `color-schemes/<name>.colors` file found with `QStandardPaths::locate` (`gnomesettings.cpp:259-268`, `:286`). The helper `colorScheme(useHighContrast, useDarkVariant)` picks the file name. The four color files in `src/color-schemes/` are the Adwaita, AdwaitaDark, AdwaitaHighcontrast and AdwaitaHighcontrastInverse variants.
- QG.16 Qt color scheme: for Qt 6.5 and later, `colorScheme()` returns Dark when the GTK theme is a dark variant, otherwise Light (`src/theme/qgnomeplatformtheme.cpp:212-215`).
- QG.17 Appearance (Qt 6 and Qt 5 path) is Dark or Light from `useGtkThemeDarkVariant()` (`src/theme/qgnomeplatformtheme.cpp:217-219`).
- QG.18 Widget style list: `styleNames()` builds an ordered list (`src/common/gnomesettings.cpp:369-431`). The visible steps are: the `QT_STYLE_OVERRIDE` value when set (`:369-377`); a GTK-theme-derived Adwaita style (`:384-403`); a Kvantum theme matched from the GTK theme name, which also writes the Kvantum config (`:409-420`); `adwaita` or `adwaita-dark` (`:424-427`); and finally `fusion` and `windows` (`:431`).
- QG.19 Kvantum matching: `kvantumThemeForGtkTheme()` searches the data directories for a theme matching the GTK theme name (`src/common/gnomesettings.cpp:461-484`). `configureKvantum()` writes the `theme` key of `~/.config/Kvantum/kvantum.kvconfig` with `QSettings` when it differs (`src/common/gnomesettings.cpp:498-504`).
- QG.20 Window decoration colors come from the same dark variant and high-contrast checks, mapped to an `Adwaita::ColorVariant` (`src/decoration/qgnomeplatformdecoration.cpp:643-648`). The TODO at `qgnomeplatformdecoration.cpp:646` says the colors should move to Adwaita-qt.

## 4. Output and rendering path
- QG.21 Theme hooks: `themeHint` (`qgnomeplatformtheme.cpp:122-130`), `font` (`:132-135`), `palette` (`:137-141`), `usePlatformNativeDialog` (`:144-155`), `createPlatformDialogHelper` (`:158-175`), `createPlatformSystemTrayIcon` (`:196-202`), `colorScheme` (`:212-215`), `appearance` (`:217-219`).
- QG.22 `themeHint` asks `GnomeSettings::hint()` first, then falls back to `QPlatformTheme::themeHint` (`qgnomeplatformtheme.cpp:122-130`). `GnomeSettings::hint()` answers `StyleNames` and `IconThemeSearchPaths` itself and otherwise reads the backend's hint table (`gnomesettings.cpp:238-247`).
- QG.23 Dialog helpers: file dialog is the XDG portal helper when `canUseFileChooserPortal()` is true, else `QGtk3FileDialogHelper` (`qgnomeplatformtheme.cpp:161-167`). Font and color dialogs always use `QGtk3FontDialogHelper` and `QGtk3ColorDialogHelper` (`:168-172`). The GTK helpers are in `src/theme/qgtk3dialoghelpers.cpp` and `.h` (classes at `qgtk3dialoghelpers.h:60`, `:85`, `:126`).
- QG.24 Qt Quick Controls: the constructor sets `org.kde.desktop` as the Quick Controls style on Qt 5 when the style is available (`src/theme/qgnomeplatformtheme.cpp:105-114`). On Qt 6 that branch is not compiled. Quick Controls style is skipped when a non-Fusion name is already set (`qgnomeplatformtheme.cpp:101-103`).
- QG.25 Cursor: `GnomeSettings` writes `XCURSOR_SIZE` and `XCURSOR_THEME` environment variables on X11 only (`src/common/gnomesettings.cpp:305-316`).
- QG.26 Decoration: `QGnomePlatformDecoration` draws Adwaita-style title bars and window buttons for Wayland. It exposes button rectangles (`qgnomeplatformdecoration.cpp:97`, `:112`, `:127`), margins (`:146`, `:184`), `paint` (`:197`), mouse and touch handling (`:524-630`, `:677-790`), and `renderButton` (`:788`). `loadConfiguration()` reads colors and settings (`:643`).

## 5. Extension and integration points
- QG.27 Two plugin factories: `QGnomePlatformThemePlugin` (`src/theme/platformplugin.h:28-35`) and `QGnomePlatformDecorationPlugin` (`src/decoration/decorationplugin.h:30-32`).
- QG.28 Integration with the GTK stack: the constructor calls `gtk_init(nullptr, nullptr)` (`src/common/gnomesettings.cpp:80`), installs a GTK log handler (`src/theme/qgnomeplatformtheme.cpp:82`), and uses `g_type_ensure` for Pango types (`qgnomeplatformtheme.cpp:87-88`).
- QG.29 The theme exposes Kvantum integration through the `kvantum` and `kvantum-dark` style names (`gnomesettings.cpp:418-420`).
- QG.30 Change notification: GSettings `changed` signals and portal setting changes are routed to `GnomeSettings` handlers for cursor, font, icon theme, theme and hints (`gnomesettings.cpp:177-181`, `:289-358`).

## 6. Data and tooling
- QG.31 Build files: `CMakeLists.txt`, `src/CMakeLists.txt`, `src/theme/CMakeLists.txt`, `src/decoration/CMakeLists.txt`, `src/common/CMakeLists.txt`, `src/color-schemes/CMakeLists.txt`, and `cmake/modules/FindGSettingSchemas.cmake`.
- QG.32 No test directory exists in the repo (`rg --files` listing shows none).
- QG.33 Runtime data: the color files in `src/color-schemes/` and the Kvantum config written by `configureKvantum()`.

## 7. Facts of note
- QG.34 The theme's dark-mode result depends on the GTK theme name, not on a single color-scheme key. The color-scheme key is read by the backends (`gsettingshintprovider.cpp:110`, `portalhintprovider.cpp:118`), but `useGtkThemeDarkVariant()` checks the name and the appearance hint (`gnomesettings.cpp:214-225`).
- QG.35 Font and color dialogs never use the portal; only the file dialog can (`qgnomeplatformtheme.cpp:161-172`).
- QG.36 The palette is one set per variant: `palette(type)` ignores the palette type (`qgnomeplatformtheme.cpp:137-141`).
- QG.37 Writing the Kvantum config is a side effect of reading the style list: `styleNames()` calls `kvantumThemeForGtkTheme()` and that calls `configureKvantum()` (`gnomesettings.cpp:409-415`).

## 8. Not covered
- QG.38 Not read: `src/theme/qgtk3dialoghelpers.cpp` and `qxdgdesktopportalfiledialog.cpp` bodies, `src/theme/qgnomeplatformtheme.cpp:144-200` details (dialog and tray helpers), and the `QGenericUnixTheme` forwarding.
- QG.39 Not read: `src/common/hintprovider.cpp` in full (only `setFonts`, `setCursorSize`, `setCursorTheme`, `setCursorBlinkTime` headers were seen), `gnomesettings.cpp:289-358` bodies, `gnomesettings.cpp:436-460` (`xdgIconThemePaths`), and `gnomesettings.cpp:461-484` (Kvantum search) beyond the first lines.
- QG.40 Not read: the decoration drawing internals (`qgnomeplatformdecoration.cpp:197-523`, `:788-815`) and the `Adwaita::Colors` source, which is not in this repo.
- QG.41 Not read: the four `.colors` files (contents), `cmake/modules/FindGSettingSchemas.cmake`, `README.md`.
- QG.42 UNVERIFIED: whether `StyleNames` list steps 2 and 4 in `styleNames()` (`gnomesettings.cpp:384-403`, `:421-427`) are reached on every path; the branch conditions were only partly read.
