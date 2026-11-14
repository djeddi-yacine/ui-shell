# gtk3-classic: patch series on top of the GTK 3.24.52 source tree, restoring a pre-CSD look and behaviour

Source: refs/gtk3-classic (shallow clone; commit 6bcabbe; branch master). License: GPL-2.0 (`COPYING:1-2`). Scope: whole repo, with patch contents read by hunk (the `.patch` files, `series`, `PKGBUILD`, `README.md`, `README.Patches.md`, `README.Variables.md`, `settings.ini`, `smaller-adwaita.css`, `scripts/`). Patch hunks are cited as `<patch file>:<line>` (line numbers in the patch file, not in GTK source).
Id prefix: GC.

## 1. Purpose and shape
- GC1.1 Patches that restore GTK 3's pre-CSD look and feel for non-GNOME desktops (XFCE, MATE and others), with disabled client-side headers on X11, classic dialogs and file-browser changes. `README.md:9-15`. It is not a fork of GTK. `README.md:25-26`.
- GC1.2 Target: GTK 3 only. The package pins `_gtkver=3.24.52`. `PKGBUILD:9`. The GTK source is downloaded from the GNOME GitLab archive. `PKGBUILD:84`.
- GC1.3 Build system: Arch `PKGBUILD` (makepkg). `prepare()` unpacks, applies the patch series, and rewrites a theme CSS file. `PKGBUILD:133-141`. `build()` runs `arch-meson` on the patched tree. `PKGBUILD:143-148`. Packages produced: `gtk3-classic`, with `gtk3-mushrooms` as an alias name. `PKGBUILD:11-27`.
- GC1.4 Top-level layout:
  - `series`: ordered list of patch file names applied in order. `series:1-32`
  - `*.patch` (about 31 files): patches against GTK 3.24.52, named `<area>__<topic>.patch` (areas: appearance, csd, file-chooser, fixes, popovers, treeview, window, notebook, other, gtk+-atk-bridge). `series:1-32`
  - `*.disabled-patch`: one patch kept out of the series (`fixes__too-large-menu-covers-bar.disabled-patch`; series line 17 comments out `fixes__too-large-menu-covers-bar.patch`). `series:17`
  - `smaller-adwaita.css`: CSS appended to GTK's Adwaita contained-window CSS. `PKGBUILD:139-140`
  - `settings.ini`: default GTK settings (theme, icon theme, font). `settings.ini:1-4`
  - `gtk-remove-immodules-cache.hook`, `gtk-query-immodules-3.0.hook`: pacman hooks, fetched by URL in the PKGBUILD. `PKGBUILD:89-93`
  - `scripts/refresh-patches.sh`, `scripts/create-ubuntu-package.sh`, `scripts/ci-check-checksums.py`: maintenance scripts (not read in detail).
  - `README.md`, `README.Patches.md`, `README.Variables.md`: docs.
- GC1.5 Packaging note: the README links an Ubuntu package path (`scripts/create-ubuntu-package.sh`). Contents not read.

## 2. Theme input (how configuration reaches it)
- GC2.1 Environment variable `GTK_CSD`: `0` disables CSD (X11 only), `1` forces CSD or enables client shadow. `README.Variables.md:26-29`. Read by the CSD patch: `patch csd__disabled-by-default.patch:9-16` (X11 check and `g_getenv("GTK_CSD") == FALSE` condition).
- GC2.2 `GTK_OVERLAY_SCROLLING`: the default-settings patch changes the test from `== "0"` to `!= "1"`. `other__default-settings.patch:9-10`. The branch body was not read. The variable is not listed in `README.Variables.md`.
- GC2.3 `GTK_USE_IEC_UNITS=1`: file chooser uses IEC units (1024 bytes). `README.Variables.md:30`.
- GC2.4 GSettings schema default changed from `'recent'` to `'cwd'` in `org.gtk.Settings.FileChooser.gschema.xml` (the hunk's file name is in the patch header; the schema key name was not read). `other__default-settings.patch:35-36` (patch hunk, schema file in the patched GTK tree).
- GC2.5 Print preview command default changed from `evince` to `atril`. `other__default-settings.patch:22-23`.
- GC2.6 Default GTK settings file shipped by the package: `settings.ini` sets `gtk-icon-theme-name = Adwaita`, `gtk-theme-name = Adwaita`, `gtk-font-name = Cantarell 11`. `settings.ini:1-4`. The PKGBUILD does not show where this file is installed (UNVERIFIED in this study; `PKGBUILD` install step not read).
- GC2.7 Other inputs read by patched code are not listed in this study (UNVERIFIED).

## 3. Color and style model
- GC3.1 Styling is done by replacing the Adwaita contained-window CSS, not by a new color model. `PKGBUILD:139-140` appends `smaller-adwaita.css` (98 lines) to `gtk/theme/Adwaita/gtk-contained.css` and `gtk-contained-dark.css` after deleting them. `PKGBUILD:139`
- GC3.2 The file `smaller-adwaita.css` was not read in detail beyond its line count (98 lines). The selectors it sets are UNVERIFIED.
- GC3.3 Some patches change widget styling in C code: `appearance__buttons-menus-icons.patch` (touches `gtk/gtkbutton.c`, `gtk/gtkmenuitem.c`), `popovers__color-chooser.patch` (`gtk/gtkcolorswatch.c`), `treeview__alternating_row_colours.patch` (header lines not in `b/` form; file list UNVERIFIED). Hunks were not read in detail.
- GC3.4 Dark-mode handling: none specific in the patches read. The `appearance__fix_black_border.patch` (`gtk/gtkwindow.c`) hunks were not read (UNVERIFIED).

## 4. Output and rendering path
- GC4.1 Output is a patched GTK 3 build (`libgtk-3.so`), not a theme. `PKGBUILD:27`. The patches change GTK source files directly.
- GC4.2 Call chain for the CSD change (in order):
  1. `GTK_CSD` is read by the patched `gtk/gtkwindow.c`. `csd__disabled-by-default.patch:9-10`
  2. On X11 displays, the `gtk-csd` and `solid-csd` style classes are removed from the widget style context. `csd__disabled-by-default.patch:11-13`
  3. `priv->client_decorated` is set to `FALSE`. `csd__disabled-by-default.patch:14`
  4. Other CSD changes are in `csd__clean-headerbar.patch` (`gtk/gtkheaderbar.c`, `gtk/gtkwindow.c`) and `csd__server-side-shadow.patch` (`gtk/gtkwindow.c`). Hunks not read (UNVERIFIED).
- GC4.3 Dialogs: `appearance__message-dialogs.patch` changes `gtk/gtkdialog.c`, `gtk/gtkmessagedialog.c` and `gtk/ui/gtkmessagedialog.ui`. The file list is from the patch headers (`+++ b/...`). Hunks not read.
- GC4.4 File chooser: `file-chooser__places-sidebar.patch`, `file-chooser__show-recent.patch`, `file-chooser__typeahead.patch`, `file-chooser__file_units.patch`, `file-chooser__eject-button.patch`, and `popovers__file-chooser-list.patch`. Each changes `gtk/gtkfilechooserwidget.c` and/or `gtk/gtkplacessidebar.c`. Hunks not read.
- GC4.5 Scrolling and notebook: `notebook_wheel_scroll.patch` changes `gtk/gtknotebook.c`. Hunks not read.
- GC4.6 Accessibility bridge: three patches (`gtk+-atk-bridge-gtkaccessibility.patch`, `gtk+-atk-bridge-meson.build.patch`, `gtk+-atk-bridge-meson_options.txt.patch`) change ATK bridge build files. Hunk content not read.
- GC4.7 Wayland: `fixes__wayland_dialogs_header_setting.patch` changes `gdk/wayland/gdkscreen-wayland.c`. Hunk not read.
- GC4.8 The PKGBUILD applies the series with a patch loop in `prepare()`. The loop body (lines 133-138) was not read in detail (UNVERIFIED).

## 5. Extension and integration points
- GC5.1 Applied at build time, not at run time. `series` is the apply order. `series:1-32`
- GC5.2 Package provides and replaces: the package declares `provides`/`replaces` for `gtk3`, `gtk3-typeahead`, `gtk3-print-backends`, `libgtk-3.so`, and conflicts with `gtk3` package names. `PKGBUILD:18-27`. Exact arrays partly read (UNVERIFIED for the full set).
- GC5.3 Upstream version coupling: the patches are written against GTK 3.24.52 (`PKGBUILD:9`). The README states the patches will be rolled forward with new GTK 3 releases. `README.md:28-30`.
- GC5.4 Hooks installed by package: `gtk-query-immodules-3.0.hook`, `gtk-remove-immodules-cache.hook` (`PKGBUILD:89-93`).
- GC5.5 Contributing: `README.md` section on contributing patches (not read).

## 6. Data and tooling
- GC6.1 Patches: about 31 `.patch` files plus one `.disabled-patch`. `series:1-32`
- GC6.2 Patch maintenance: `scripts/refresh-patches.sh`, `scripts/ci-check-checksums.py` (not read).
- GC6.3 CI: badge links to a GitHub Actions workflow (`README.md:5`). Workflow file not in the clone listing (UNVERIFIED).
- GC6.4 Docs: `README.Patches.md` (patch list), `README.Variables.md` (env vars), `README.md` (overview).

## 7. Facts of note
- GC7.1 README warns the patched library is unsupported and that running on GNOME is not recommended. `README.md:13-15`, `README.md:33-34`.
- GC7.2 The `GTK_CSD` check in the CSD patch compares a pointer result with `FALSE` (`g_getenv("GTK_CSD") == FALSE`), which is true when the variable is unset. `csd__disabled-by-default.patch:10`. Facts as written.
- GC7.3 `fixes__too-large-menu-covers-bar.patch` is disabled in the series (`series:17`) and kept as `.disabled-patch`.
- GC7.5 License: GPL-2.0 (`COPYING:1-2`). GTK itself is LGPL; the patched tree is GTK source, and its license terms are not restated in this repo (UNVERIFIED).

## 8. Not covered
- The bodies of most patch hunks (only file lists and some hunks were read).
- `smaller-adwaita.css` selectors (only its line count, 98, was checked).
- `scripts/*` bodies, the PKGBUILD `prepare()` loop and `package_*` install steps beyond lines 133-148.
- `README.Patches.md` full list and the contributing section.
- No build was run; `refs/` was not modified.
