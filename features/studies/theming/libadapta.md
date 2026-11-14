# libadapta: fork of libadwaita with theme-directory support and a compatibility header

Source: refs/libadapta (shallow clone; commit ac83b1b; branch 1.5.x; last commit 2025-06-08). License: COPYING (read in part; the file is the license text), cited at COPYING. Scope: README.md, meson.build, the three rename/replace scripts at the repo root, src/adap-style-manager.c (theme lookup and loading), src/adap-settings-impl-{portal,gsettings,legacy}.c (theme-name sources), the compat header generator output (src/adw-compat.h, one line), libadapta.syms (file form only). Not studied: the widget sources, the SCSS/CSS data directory, tests, demo, debian packaging.
Id prefix: LP

## 1. Purpose and shape
- LP1.1 libadapta is a C (GObject) library for GTK 4 that is described as "libAdwaita with theme support and a few extra" (`README.md:4`). It "provides the same features and the same look as libAdwaita by default" (`README.md:6`) and "uses the proper window controls" in desktops with theme selection (`README.md:8`).
- LP1.2 The project states that it is a fork and gives its reason: libAdwaita "identifies as a GNOME-only platform library" and declined theming requests for non-GNOME desktops (`README.md:12-26`). This is the README's own account, not verified elsewhere.
- LP1.3 Top-level layout (the parts that matter):
  - `src/`: the `adap-*` widget and style sources, plus `adap-style-manager.c` (theme loading), `adap-settings*.c` (settings backends), and `adw-compat.h`-style generated output.
  - `data/`: stylesheet and resource data (not read).
  - `01_rename.py`, `02_replace.py`, `03_generate_compat_headers.py`: scripts that produce the fork from libadwaita (see section 6).
  - `libadapta.syms`: exported symbol list (about 6 lines, file form only).
  - `tests/`, `demo/`, `examples/`, `doc/`, `po/`, `debian/`, `subprojects/`: not read.
  - `HACKING.md`: build and test instructions, and coding style (`HACKING.md`, start of file).
- LP1.4 Build: meson. Project name `libadapta`, version `1.5.0`, meson minimum `>= 0.59.0` (`meson.build:2-6`). The library version is set separately: `libversion = '0.5.8'` (`meson.build:35`) and `soversion = 0` (`meson.build:37`). The "Before making a release" comment at `meson.build:25` says the libversion must be edited by hand before each release.

## 2. Theme input (how configuration reaches it)
- LP2.1 Theme name source: `adap_settings_get_theme_name` returns the name the style manager uses (`src/adap-style-manager.c:303`). The name comes from a settings backend through the `theme-name` property (`src/adap-settings.c:256`), which is updated by backend signal `theme-name-changed` (`src/adap-settings.c:145`).
- LP2.2 GSettings backend: reads key `gtk-theme` from schema `org.gnome.desktop.interface` (`src/adap-settings-impl-gsettings.c:106`, key check at `src/adap-settings-impl-gsettings.c:108`, value read at `src/adap-settings-impl-gsettings.c:38`).
- LP2.3 Portal backend: reads the `gtk-theme` setting of `org.freedesktop.portal.Settings` (`src/adap-settings-impl-portal.c:231`, change handler at `src/adap-settings-impl-portal.c:137-138`). The constructor is `adap_settings_impl_portal_new` (`src/adap-settings-impl-portal.c:202`).
- LP2.4 Legacy backend: high contrast is inferred from the theme name `HighContrast` or `HighContrastInverse` (`src/adap-settings-impl-legacy.c:35-36`).
- LP2.5 Environment variables: `ADAP_DEBUG_THEMES` turns on theme debug output (`src/adap-style-manager.c:91`, read once at `src/adap-style-manager.c:88-91`). `GTK_THEME` is checked before the Adapta-empty override (see LP3.4).
- LP2.6 Theme search directories, in order (`src/adap-style-manager.c:246-270`):
  1. `$XDG_DATA_HOME/themes/<name>` via `g_get_user_data_dir ()` (`src/adap-style-manager.c:256`).
  2. `~/.themes/<name>` via `g_get_home_dir ()` (`src/adap-style-manager.c:260`).
  3. Each of `g_get_system_data_dirs ()` with subdir `themes` (`src/adap-style-manager.c:264-270`).
- LP2.7 Inside each theme directory the code looks for `libadapta-<MAJOR>.<MINOR>/` (`src/adap-style-manager.c:202`) and in it these files: `base.css` or `base-hc.css` for high contrast (`src/adap-style-manager.c:181-183`), and `defaults-dark.css` or `defaults-light.css` (`src/adap-style-manager.c:186-188`). If no dark variant exists, the lookup falls back to light (the call with `FALSE` in `find_theme_dir_each`).
- LP2.8 Defaults: when the theme is not found, the bundled resources are loaded: `/org/gnome/Adapta/styles/base-hc.css` or `base.css`, and `defaults-dark.css` or `defaults-light.css` (`src/adap-style-manager.c:322-340`).

## 3. Color and style model
- LP3.1 The style manager holds three providers: `provider` (base CSS), `colors_provider` (defaults CSS), and the accent and font providers inherited from libadwaita (not read). Base CSS and color CSS are separate GtkCssProvider objects, loaded from a path (`src/adap-style-manager.c:313-315`) or from a resource (`src/adap-style-manager.c:326-339`).
- LP3.2 Color names and variables are defined in the CSS files found by LP2.7. Their content (the `@define-color` set) was not read: UNVERIFIED for the exact palette.
- LP3.3 Dark selection: `update_dark` sets `gtk-application-prefer-dark-theme` from `self->dark` on GtkSettings (`src/adap-style-manager.c:292-294`, function `update_stylesheet` starts at `src/adap-style-manager.c:275`; `update_dark` at `src/adap-style-manager.c:373`).

## 4. Output and rendering path
- LP4.1 Call chain for theme loading, in order:
  1. `update_stylesheet` (`src/adap-style-manager.c:275`) reads the theme name from settings (`src/adap-style-manager.c:303`).
  2. `find_theme_dir` searches the directories (`src/adap-style-manager.c:246`, body at `src/adap-style-manager.c:256-270`), using `find_theme_dir_each` (`src/adap-style-manager.c:158`).
  3. On success, `gtk_css_provider_load_from_path` loads the base file and the colors file (`src/adap-style-manager.c:313-315`).
  4. On failure, the resource CSS is loaded (`src/adap-style-manager.c:322-340`).
  5. The fallback theme name `Adapta-empty` is set in `adap_style_manager_constructed` (`src/adap-style-manager.c:408`, value at `src/adap-style-manager.c:433`), and the theme-name notify hook is connected there at `src/adap-style-manager.c:455`.
- LP4.2 Theme-name change: `notify::theme-name` triggers `notify_theme_name_cb` (`src/adap-style-manager.c:402`, connected at `src/adap-style-manager.c:455`).
- LP4.3 Compatibility output: `src/adw-compat.h` (generated) maps libadwaita names to libadapta names, for example `#define adw_settings_get_theme_name adap_settings_get_theme_name` (`src/adw-compat.h:1185`). This is generated output in the tree, not hand-written; see LP6.2.

## 5. Extension and integration points
- LP5.1 Discovery of theme directories: the user data dir, the home `.themes` dir, and the system data dirs (LP2.6). A theme gets libadapta support by providing a `libadapta-<MAJOR>.<MINOR>/` subdirectory (LP2.7).
- LP5.2 The version subdirectory is built from `ADAP_MAJOR_VERSION` and `ADAP_MINOR_VERSION` (`src/adap-style-manager.c:202`). The macro values were not read here: UNVERIFIED for their numbers (they come from the generated config or header).
- LP5.3 Coupling to libadwaita: the API is a copy of libadwaita with renamed symbols (Adw to Adap, see LP6.1). `libadapta.syms` lists the exported symbols (file form only).
- LP5.4 Backend selection among portal, gsettings, legacy, macos and win32 files (`src/adap-settings-impl-*.c`): the selection code was not read: UNVERIFIED for the order.

## 6. Data and tooling
- LP6.1 `01_rename.py`: renames files and directories whose names contain `Adwaita` or `Adw` to `Adapta` or `Adap`, keeping the case pattern (`01_rename.py:5-8` replacement table, `01_rename.py:32` walk loop, rename of files and dirs). It skips `.git` paths.
- LP6.2 `02_replace.py`: replaces text inside files with the same table plus `READAPRITE` to `READWRITE` (`02_replace.py:6-10`). The excluded script names are listed at `02_replace.py:12`. It skips binary files (`02_replace.py:27`) and the `.git` directory (`02_replace.py:35-43`).
- LP6.3 `03_generate_compat_headers.py`: scans the headers for `Adap*` typedefs, `ADAP_*` macros and `adap_*` functions (`03_generate_compat_headers.py:23-128` extraction, with the regular expressions at about lines 31-37). It writes `src/adw-compat.h` with `#define` aliases from Adw names to Adap names (`03_generate_compat_headers.py:130`, write loop at about lines 165-186).
- LP6.4 The HACKING.md file describes running `ninja -C _build test` and the GTK coding style (`HACKING.md`, top sections).
- LP6.5 The README says the compatibility header lets developers switch between libAdwaita and libAdapta "without requiring code changes" (`README.md:10`). The script output was not compared with the header for coverage.

## 7. Facts of note
- LP7.1 The 02_replace.py table includes `READAPRITE` to `READWRITE` (`02_replace.py:9`). This is an unusual entry; its purpose was not found in the files read.
- LP7.2 The fork's default theme name is `Adapta-empty` (`src/adap-style-manager.c:433`), not `Adwaita-empty`.
- LP7.3 The README's question-and-answer section asks "Is it a fork of libAdwaita?" (`README.md:12`); the answer text was not read in full.
- LP7.4 Branch in refs is 1.5.x, and the meson project version is 1.5.0 (`meson.build:4`). The libversion string 0.5.8 (`meson.build:35`) is a separate value.

## 8. Not covered
- Not read: the widget sources (`src/adap-*.c` beyond the style manager and settings), the data/ CSS and SCSS, tests, demo, examples, doc, po, debian, subprojects, the full HACKING.md, the full compat header, libadapta.syms content, the portal and gsettings backend bodies beyond the lines cited, and the macos and win32 backends.
- Partly read: src/adap-style-manager.c (lines 83-105, 158-205, 246-340, 402-460 in part), src/adap-settings-impl-portal.c and -gsettings.c (the lines cited), 01_rename.py, 02_replace.py, 03_generate_compat_headers.py (the first 60 lines and the generation function, not every line), meson.build (lines 1-40).
