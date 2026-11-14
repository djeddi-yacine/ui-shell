# libadwaita-without-adwaita: AUR packaging for a libadwaita build with one patch that respects the system GTK theme

Source: refs/libadwaita-without-adwaita (shallow clone; commit c66ee82; branch master; last commit 2026-08-12). License: none in this repo; the packaged software is libadwaita under LGPL-2.1-or-later as declared in PKGBUILD (`PKGBUILD:13`). Scope: whole repo (PKGBUILD, the patch file, .gitignore, .SRCINFO).
Id prefix: LW

## 1. Purpose and shape
- LW1.1 This repo is packaging only: an Arch Linux AUR build script (PKGBUILD) and one patch. It builds libadwaita from its upstream git repository with the patch applied (`PKGBUILD:4-10`, `PKGBUILD:37-51`). The description says "patched to respect system theme" (`PKGBUILD:10`).
- LW1.2 Top-level files: `PKGBUILD` (build script), `0001-respect_system_theme.patch` (the patch, 74 lines), `.SRCINFO` (generated metadata), `.gitignore`. No C, SCSS or other source files are in the repo.
- LW1.3 Package identity: `_pkgname="libadwaita-without-adwaita"`, `pkgname="$_pkgname-git"` (`PKGBUILD:6-7`), version pattern `pkgver=1.10.r162.g0d9b6d4` (`PKGBUILD:8`), `pkgrel=1` (`PKGBUILD:9`). The `pkgver()` function derives the version from `git describe` of the upstream checkout (`PKGBUILD:60-68`).
- LW1.4 Dependencies: runtime `fribidi`, `glib2`, `graphene`, `gtk4-git` (an AUR package), `pango` (`PKGBUILD:15-21`). Build-time: `git`, `glib2-devel`, `gobject-introspection`, `meson`, `sassc`, `vala` (`PKGBUILD:22-29`).
- LW1.5 Provides and conflicts: `provides` lists `libadwaita=1:<pkgver without the git suffix>` and `libadwaita-1.so`; `conflicts=('libadwaita')` (`PKGBUILD:31-35`).

## 2. Theme input (how configuration reaches it)
- LW2.1 The patch changes how the GTK theme name is set at startup. It is a GSettings-based input: it reads key `gtk-theme` and key `color-scheme` from schema `org.gnome.desktop.interface` (patch lines 9-12 and 64-65 as added lines; see LW4.2 for the hunk map).
- LW2.2 The patched code falls back to `Adwaita-empty` when the `gtk-theme` value is NULL (patch line 15, added in hunk 1).
- LW2.3 The patch sets the dark preference from the theme name (substring `-dark` or `-Dark`) or from `color-scheme` equal to `prefer-dark` (patch line 18).
- LW2.4 The `GTK_THEME` environment variable and Granite presence are still checked before the logic runs (patch line 61, the `if (self->display && !adw_is_granite_present () && !g_getenv ("GTK_THEME"))` condition).

## 3. Color and style model
- LW3.1 None in this repo. The color model is that of upstream libadwaita; the repo contains no color code.

## 4. Output and rendering path
- LW4.1 Build flow: `prepare()` applies the patch to the upstream checkout with `patch -Np1 -F100 -i ../0001-respect_system_theme.patch` (`PKGBUILD:49-51`), links the `ministream` subproject (`PKGBUILD:53`), and removes a `_min_version` constraint from `meson.build` when `_build_force` is true (`PKGBUILD:55-57`, sed at `PKGBUILD:56`).
- LW4.2 Patch hunks (one file touched: `src/adw-style-manager.c`):
  - Hunk 1, `@@ -465,6 +465,23 @@` (patch line 4): adds a new static function `adw_style_manager_theme_changed` (patch lines 8-23). It reads `gtk-theme` and `color-scheme` from a GSettings object, and sets `gtk-theme-name` and `gtk-application-prefer-dark-theme` on the GtkSettings of the display (patch lines 20-22).
  - Hunk 2, `@@ -471,27 +471,6 @@` (patch line 28): removes the old block in `adw_style_manager_constructed` that set `gtk-theme-name` to `Adwaita-empty` and created the base, accent and fonts CSS providers when Granite is absent and `GTK_THEME` is unset (patch lines 32-51 as removed lines).
  - Hunk 3, `@@ -570,7 +566,18 @@` (patch line 56): adds a block that, when the display exists and Granite is absent and `GTK_THEME` is unset, looks up schema `org.gnome.desktop.interface` with `g_settings_schema_source_lookup`, creates a GSettings object, calls `adw_style_manager_theme_changed` once, and connects its `changed` signal to the same function (patch lines 60-70).
- LW4.3 Effect (as stated by the patch): the GTK theme name follows the desktop `gtk-theme` setting instead of being fixed to `Adwaita-empty`. The providers that hunk 2 removed are no longer created in that branch; the patch does not add them back in the lines shown (the replacement at patch line 60-70 has no provider creation). UNVERIFIED: whether the base, accent and fonts providers are created elsewhere in the patched tree; the upstream tree was not checked.
- LW4.4 The patch is applied with fuzz `-F100` (`PKGBUILD:51`). This allows the hunks to apply to a moving upstream checkout.

## 5. Extension and integration points
- LW5.1 The package provides `libadwaita-1.so` and the `libadwaita` package name (`PKGBUILD:31-35`), so it replaces libadwaita for packages that depend on it.
- LW5.2 Dependency on an AUR package: `gtk4-git` (`PKGBUILD:19`).
- LW5.3 Source pins: the upstream source is the libadwaita git repository at `https://gitlab.gnome.org/GNOME/libadwaita.git` with no commit pin (`PKGBUILD:39`, sha256 `SKIP`, `PKGBUILD:44`). The `ministream` subproject is taken from `https://gitlab.gnome.org/sp1rit/ministream.git` (`PKGBUILD:41`).
- LW5.4 The patch file has a sha256 pin (`PKGBUILD:45`). The patch file is not verified against the hash in this session: UNVERIFIED (the hash was not recomputed).

## 6. Data and tooling
- LW6.1 Build options passed to meson: `-Dexamples=false` and `-Dtests=false` (`PKGBUILD:72-73`), with `arch-meson` for the build (`PKGBUILD:76`) and `meson install` for packaging (`PKGBUILD:81`).
- LW6.2 Version derivation: `git describe --long --tags --abbrev=7 --exclude='*[a-zA-Z][a-zA-Z]*'` plus sed edits (`PKGBUILD:62-65`).
- LW6.3 `.SRCINFO` mirrors the PKGBUILD metadata (generated file; not compared line by line).

## 7. Facts of note
- LW7.1 Name and intent: the package name says "without adwaita" and the description says it respects the system theme (`PKGBUILD:6`, `PKGBUILD:10`). The patch changes the default theme behaviour of upstream libadwaita (see LW4.2).
- LW7.2 The patch code checks a GSettings string value for NULL and falls back to `Adwaita-empty` (patch lines 14-15). UNVERIFIED: whether `g_settings_get_string` can return NULL for this key; not checked, and the code was not run.
- LW7.3 The license field is `LGPL-2.1-or-later` (`PKGBUILD:13`).
- LW7.4 The `ministream` subproject is linked into the upstream tree (`PKGBUILD:53`); its contents were not read.

## 8. Not covered
- Not read: the upstream libadwaita tree (not in this repo), the full PKGBUILD header comments (lines 1-3 are empty maintainer fields), .SRCINFO and .gitignore contents, the ministream subproject.
- Read in full: PKGBUILD (82 lines), 0001-respect_system_theme.patch (the added and removed lines and the three hunk headers).
