# nwg-look: Go GTK3 settings editor that writes GTK 2/3/4 settings, xsettingsd config and GNOME gsettings values

Source: refs/nwg-look (shallow clone; commit b9cc3e6; branch main). License: MIT (`LICENSE:1`). Scope: whole repo, with the code path in `main.go`, `tools.go`, `uicomponents.go`, `stylepak/`, `stuff/` (desktop file, glade UI), `langs/`, `go.mod`. Not read in detail: `langs/*.json` contents, `stuff/main.glade`, `Makefile`.
Id prefix: NL.

## 1. Purpose and shape
- NL1.1 The program edits GTK theme, icon, cursor, sound, font and toolbar settings and writes them to files and gsettings (`main.go:179-310`, `tools.go:380-522`, `tools.go:586-691`, `tools.go:859-921`). Version constant: `1.2.1` (`main.go:25`).
- NL1.2 Language and toolkit: Go. GUI is GTK 3 through `github.com/gotk3/gotk3` (`go.mod:6`) with a glade layout (`stuff/main.glade`, loaded through `gtk.Builder`, helpers at `tools.go:1427-1525`). Logging: `github.com/sirupsen/logrus` (`go.mod:7`).
- NL1.3 Top-level layout:
  - `main.go`: program settings and GTK config defaults (`programSettingsNewWithDefaults`, `:62`; `gtkConfigPropertiesNewWithDefaults`, `:100`; `gsettingsNewWithDefaults`, `:153`), panels (`displayThemes`, `:179`, through `displayProgramSettingsForm`, `:282`), `main` at `:310`.
  - `uicomponents.go`: list boxes and previews for themes, icon themes, cursor themes, sound themes, widgets, fonts, other settings (`setUpThemeListBox`, `:16`; `setUpCursorThemeListBox`, `:110`; `setUpFontSettingsForm`, `:491`; `setUpOtherSettingsForm`, `:680`).
  - `tools.go`: reading and writing of all config files, gsettings calls, theme discovery, flatpak overrides, language vocabulary.
  - `stylepak/stylepak.go`: install of a user theme for Flatpak apps (`determineInstallAction`, `:56`; `InstallUserTheme`, `:134`).
  - `langs/*.json`: UI strings for 10 languages (`loadVocabulary`, `tools.go:1584`; `detectLang`, `tools.go:1525`).
  - `stuff/`: desktop file, icon, glade file.

## 2. Theme input (how configuration reaches it)
- NL2.1 Config home: `$XDG_CONFIG_HOME`, else `$HOME/.config/` (`tools.go:20-26`, function `configHome`).
- NL2.2 Program preferences: `<config home>/nwg-look/config` (`tools.go:57`); loaded by `loadPreferences` (`tools.go:28`), saved by `savePreferences` (`tools.go:56`).
- NL2.3 GTK 3 settings read on start: `<config home>/gtk-3.0/settings.ini` (`tools.go:72`, function `loadGtkConfig` at `:69`). Keys parsed (`tools.go:94-133`): `gtk-theme-name`, `gtk-icon-theme-name`, `gtk-font-name`, `gtk-cursor-theme-name`, `gtk-cursor-theme-size`, `gtk-toolbar-style`, `gtk-toolbar-icon-size`, `gtk-button-images`, `gtk-menu-images`, `gtk-sound-theme-name`, `gtk-enable-event-sounds`, `gtk-enable-input-feedback-sounds`, `gtk-error-bell`, `gtk-xft-antialias`, `gtk-xft-hinting`, `gtk-xft-hintstyle`, `gtk-xft-rgba`, `gtk-application-prefer-dark-theme`.
- NL2.4 GNOME settings read on start through `gsettings get` (`getGsettingsValue`, `tools.go:367-377`, exec at `:368`; `readGsettings`, `tools.go:172`). Schemas and keys read: `org.gnome.desktop.interface` keys `gtk-theme`, `icon-theme`, `font-name`, `cursor-theme`, `cursor-size`, `toolbar-style`, `toolbar-icons-size`, `font-hinting`, `font-antialiasing`, `font-rgba-order`, `text-scaling-factor`, `color-scheme` (`tools.go:175-281`); `org.gnome.desktop.sound` keys `theme-name`, `event-sounds`, `input-feedback-sounds` (`tools.go:290-312`).
- NL2.5 Theme discovery: `getThemeNames` (`tools.go:1095`), `getIconThemeNames` (`:1149`), `getCursorThemes` (`:1195`), `getSoundThemeNames` (`:1244`). Search dirs: `dataHome()` plus `XDG_DATA_DIRS`, defaulting to `/usr/local/share/:/usr/share/` (`tools.go:1293-1305`, default string at `:1302`).
- NL2.6 Environment: `XDG_CONFIG_HOME`, `XDG_DATA_DIRS`, `HOME`, `GTK2_RC_FILES` (`tools.go:757-760` for the GTK 2 rc path), `GTK_THEME`/`ICON_THEME` used by flatpak overrides (`tools.go:1025`, `:1042`).
- NL2.7 Language: `detectLang` (`tools.go:1525`) picks one of the `langs/*.json` files; `loadVocabulary(lang)` (`tools.go:1584`).

## 3. Color and style model
- NL3.1 No color model: the program does not hold palettes, colors or shades. It stores names and values for theme, icon, cursor, sound, font and toolbar settings in struct `gsettingsValues` (default constructor `main.go:153`) and `gtkConfigProperties` (`main.go:100`). The struct field list was not read in full.
- NL3.2 Live preview: selecting a theme sets the property on the running GTK settings object, for example `gtkSettings.SetProperty("gtk-theme-name", n)` (`uicomponents.go:35`, `:39`), `gtk-cursor-theme-name` (`:134`, `:139`), `gtk-font-name` (`:302`), `gtk-cursor-theme-size` (`:481`). The UI preview is therefore the live GTK settings of the program itself.
- NL3.3 Color scheme: a combo box sets `gsettings.colorScheme` (`uicomponents.go:315-319`) and `org.gnome.desktop.interface color-scheme` is written in `applyGsettings` (`tools.go:476`). The values offered were not read (UNVERIFIED).
- NL3.4 Dark-mode GTK 3 flag: `gtk-application-prefer-dark-theme` is parsed as a config key (`tools.go:133`); its write path was not traced (UNVERIFIED).
- NL3.5 Light and dark variant handling: none in code read beyond NL3.3 and NL3.4.
- NL3.6 Per-state colors: none (no color values in the program).

## 4. Output and rendering path
- NL4.1 Apply sequence (button handler, `main.go:484-510`): the handler calls, in order:
  1. `applyGsettings()` (`main.go:485`; body `tools.go:380-520`).
  2. `saveGsettingsBackup()` (`main.go:486`; `tools.go:326`).
  3. Optional exports controlled by preference flags, in this order: `saveGtkIni3()` (`main.go:489`), `saveGtkRc20()` (`:492`), `saveIndexTheme()` (`:495`), `saveXsettingsd()` (`:498`), `linkGtk4Stuff()` then `saveGtkIni4()` (`:501-502`).
  4. Flatpak overrides: `overrideFlatpakGTKTheme()` (`main.go:508`; `tools.go:1022`).
- NL4.2 GNOME settings output: `applyGsettings` runs `gsettings set` for each key (`tools.go:385` for `gtk-theme`, `:393` `icon-theme`, `:401` `cursor-theme`, `:412` `cursor-size`, `:420` `font-name`, `:428` `font-hinting`, `:436` `font-antialiasing`, `:444` `font-rgba-order`, `:452` `text-scaling-factor`, `:460` `toolbar-style`, `:468` `toolbar-icons-size`, `:476` `color-scheme`). Sound settings use schema `org.gnome.desktop.sound` (`tools.go:484-513`: `theme-name` `:487`, `event-sounds` `:500`, `input-feedback-sounds` `:513`).
- NL4.3 GTK 3 output: `saveGtkIni3` writes `<config home>/gtk-3.0/settings.ini` (`tools.go:586-590`, path at `:587`). Preserved lines from the old file are appended (comment at `tools.go:677`).
- NL4.4 GTK 4 output: `saveGtkIni4` writes `<config home>/gtk-4.0/settings.ini` (`tools.go:691-694`, path at `:692`).
- NL4.5 GTK 2 output: `saveGtkRc20` writes `$GTK2_RC_FILES` if set, else `$HOME/.gtkrc-2.0` (`tools.go:756-762`), with an `include` of `$HOME/.gtkrc-2.0.mine` (`tools.go:771`). Lines are filtered by `isSupported` (`tools.go:727`).
- NL4.6 GTK 4 CSS: `linkGtk4Stuff` (`tools.go:924`) creates symbolic links with `ln -s` from the selected theme directory into `<config home>/gtk-4.0/`: `gtk-4.0/gtk.css` (`tools.go:953`), `gtk-4.0/gtk-dark.css` (`:963`), `gtk-4.0/assets` (`:973`), and `assets` at the config root (`:983`). Existing links are removed by `clearGtk4Symlinks` (`tools.go:997-1013`, `rm` at `:1007`, `:1013`).
- NL4.7 xsettingsd output: `saveXsettingsd` writes `<config home>/xsettingsd/xsettingsd.conf` (`tools.go:859-862`, path at `:860`). Lines written: `Net/ThemeName`, `Net/IconThemeName`, `Gtk/CursorThemeName`, `Net/SoundThemeName` (`tools.go:868-871`).
- NL4.8 Index theme: `saveIndexTheme` (`tools.go:1056`) writes the cursor index theme file (body not read).
- NL4.9 Flatpak: `overrideFlatpakGTKTheme` runs `flatpak override --user --env GTK_THEME=<theme>` (`tools.go:1022-1025`); `unsetFlatpakGTKTheme` runs `--unset-env GTK_THEME` (`:1031-1033`); icon theme equivalents at `:1039-1048`.
- NL4.10 Flatpak theme install: `stylepak.InstallUserTheme(theme, runner)` (`stylepak/stylepak.go:134`) with `determineInstallAction` (`:56`) and `removeStaleThemes` (`:73`). Caller in the program was not traced (UNVERIFIED).

## 5. Extension and integration points
- NL5.1 Theme directories: GTK themes are looked up in the data directories (NL2.5). The program does not install themes except through `stylepak` (NL4.10).
- NL5.2 Compositor or desktop integration: the program writes files that other programs read (GTK 2/3/4 settings files, xsettingsd config, gsettings). No plugin interface.
- NL5.3 Environment-driven paths: NL2.1, NL2.6.
- NL5.4 Preferences that switch exports: boolean flags read in the apply handler (`main.go:488-510`, flags `preferences.ExportSettingsIni`, `ExportGtkRc20`, `ExportIndexTheme`, `ExportXsettingsd`, `ExportGtk4Symlinks`). The definition of the flag struct was not read.
- NL5.5 Build-time: `Makefile` (not read) and `go.mod:1-8`.
- NL5.6 Desktop entry and icon: `stuff/nwg-look.desktop`, `stuff/nwg-look.svg`.

## 6. Data and tooling
- NL6.1 Config files written: `gtk-3.0/settings.ini`, `gtk-4.0/settings.ini`, `~/.gtkrc-2.0`, `xsettingsd/xsettingsd.conf`, `nwg-look/config` (preferences, NL2.2), gsettings backup (`saveGsettingsBackup`, `tools.go:326`).
- NL6.2 Language files: `langs/*.json` (10 files: cs_CZ, es_ES, en_US, ja_JP, ko_KR, pl_PL, pt_BR, ru_RU, tr_TR, zh_CN).
- NL6.3 Glade layout: `stuff/main.glade` (loaded through the builder; helpers `getWindow`, `getButton` etc. at `tools.go:1427-1525`).
- NL6.4 Tests: none found in the file list (not searched exhaustively).
- NL6.5 Docs: `README.md`.

## 7. Facts of note
- NL7.1 Settings are applied with `gsettings set`, which requires the GNOME `gsettings` binary and its schemas (`tools.go:368`, `:385`).
- NL7.2 GTK 2 file path defaults to `~/.gtkrc-2.0`, overridden by `GTK2_RC_FILES` (`tools.go:757-762`).
- NL7.3 The GTK 4 CSS is installed as symbolic links into the config directory (NL4.6), not as copies.
- NL7.4 The apply handler always runs `applyGsettings` first (`main.go:485`), then the export steps in a fixed order (NL4.1).
- NL7.5 Two other call sites run the same apply sequence (`main.go:347-365`, `main.go:384-398`); their context (for example CLI or startup) was not read (UNVERIFIED).
- NL7.6 License MIT (`LICENSE:1`).

## 8. Not covered
- `main.go` bodies of panel builders (`:179-310`) and the preferences struct; `programSettings` fields.
- `uicomponents.go` preview builders (`setUpWidgetsPreview`, `:210`; `setUpIconsPreview`, `:333`; `setUpCursorsPreview`, `:396`; `setUpSoundsPreview`, `:573`).
- `tools.go` bodies of `saveIndexTheme`, `saveGsettingsBackup`, `isSupported`, and the `getThemeNames` family beyond their headers.
- `stylepak/helpers.go` and the rest of `stylepak/stylepak.go`.
- `langs/*.json` contents, `stuff/main.glade`, `Makefile`, `tools.go` build tags.
- No build or run was done; `refs/` was not modified.
