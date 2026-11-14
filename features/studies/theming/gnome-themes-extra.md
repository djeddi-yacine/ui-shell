# gnome-themes-extra: GTK+ 2 versions of Adwaita, Adwaita-dark and HighContrast, plus the Adwaita GTK+ 2 engine

Source: refs/gnome-themes-extra (shallow clone; commit 7cdb6c7; branch master; last commit 2023-07-15). License: LICENSE file, cited by name only. UNVERIFIED: the license text was not opened in this session. Scope: README.md, themes/ (Adwaita, Adwaita-dark, HighContrast; gtk-2.0 directories, index.theme.in files, adwaita_engine.c, gtkrc, render-assets.sh, the top-level layout). The gtk-3.0 CSS files were only listed, not read. Icon assets were not read.
Id prefix: GE

## 1. Purpose and shape
- GE1.1 The module provides "the GTK+ 2 version of Adwaita", Adwaita-dark, "GTK+ 2 versions of the HighContrast themes", the legacy HighContrast icon theme, and index files for Adwaita outside GNOME (`README.md:4-11`).
- GE1.2 The README says the GTK+ 3 versions of Adwaita and HighContrast "are now part of GTK+ 3 itself" (`README.md:13-17`), and that HighContrastInverse and LowContrast were discontinued (`README.md:16-17`).
- GE1.3 Language: C for the engine (`themes/Adwaita/gtk-2.0/adwaita_engine.c`), plus GTK 2 rc text files (`gtkrc`, `*.rc`) and shell scripts (`render-assets.sh`). Target: GTK+ 2 (`themes/Adwaita/gtk-2.0/adwaita_engine.c:21-27` includes `<gtk/gtk.h>`).
- GE1.4 Top-level layout:
  - `themes/Adwaita/`: GNOME Adwaita, GTK+ 2 engine plus rc files (`gtk-2.0/`), a `gtk-3.0/` CSS directory, and `index.theme.in`.
  - `themes/Adwaita-dark/`: dark variant, GTK+ 2 rc files (`gtk-2.0/`) and a `gtk-3.0/` CSS directory.
  - `themes/HighContrast/`: high-contrast variant with `gtk-2.0/` rc files, `icons/` (legacy HighContrast icon theme), and `create-highcontrast.c` and `create-makefiles.sh` generator files.
  - `configure.ac`, `Makefile.am`, `autogen.sh`, `po/`, `NEWS`: autotools build (not read in full).
- GE1.5 Build: autotools. The Adwaita engine is built as `libadwaita.la` into the GTK+ 2 engines directory (`themes/Adwaita/gtk-2.0/Makefile.am:1-2`). The module is `-module -avoid-version -no-undefined` (`themes/Adwaita/gtk-2.0/Makefile.am:6`) and links `$(GTK2_ENGINE_LIBS)` (`themes/Adwaita/gtk-2.0/Makefile.am:8`).

## 2. Theme input (how configuration reaches it)
- GE2.1 Entry file: GTK+ 2 reads an rc file that includes the theme parts. `themes/Adwaita/gtk-2.0/gtkrc` includes `main.rc`, `apps.rc` and `hacks.rc` (`themes/Adwaita/gtk-2.0/gtkrc:38-40`). The same structure is used by `themes/Adwaita-dark/gtk-2.0/gtkrc`, which also includes `hacks-dark.rc` (`themes/Adwaita-dark/gtk-2.0/gtkrc:38-41`).
- GE2.2 Color declarations: `gtkrc` declares colors with `gtk-color-scheme` strings, one per group, for example `text_color:black` and `base_color:white` (`themes/Adwaita/gtk-2.0/gtkrc:15`), `fg_color:#2e3436` and `bg_color:#e8e8e7` (`themes/Adwaita/gtk-2.0/gtkrc:17`), `selected_bg_color:#4a90d9` (`themes/Adwaita/gtk-2.0/gtkrc:19`), `window_color:#f4f4f4` (`themes/Adwaita/gtk-2.0/gtkrc:29`). The comment at `themes/Adwaita/gtk-2.0/gtkrc:10-12` says colors are declared once and not changed in the theme files.
- GE2.3 Dark values: `themes/Adwaita-dark/gtk-2.0/gtkrc:15` sets `text_color:white` and `base_color:#232729`; `themes/Adwaita-dark/gtk-2.0/gtkrc:17` sets `fg_color:#eeeeec` and `bg_color:#33393b`; `themes/Adwaita-dark/gtk-2.0/gtkrc:19` sets `selected_bg_color:#215d9c`.
- GE2.4 Settings in rc: `gtk-auto-mnemonics = 1` and `gtk-primary-button-warps-slider = 1` (`themes/Adwaita/gtk-2.0/gtkrc:34-35`).
- GE2.5 Theme selection: `index.theme.in` declares `GtkTheme=Adwaita` (`themes/Adwaita/index.theme.in:6`), with `IconTheme`, `CursorTheme` and `CursorSize=24` (`themes/Adwaita/index.theme.in:7-9`). The dark index sets `GtkTheme=Adwaita-dark` (`themes/Adwaita-dark/index.theme.in:6`). The GTK+ 2 engine name is set by the rc file (GE4.1).
- GE2.6 The HighContrast rc names engine `hcengine` in its engine block (`themes/HighContrast/gtk-2.0/gtkrc:13`). The engine module that provides it is not in this repo.

## 3. Color and style model
- GE3.1 Named colors are GTK+ 2 `gtk-color-scheme` entries (GE2.2). The style names in the rc files reference these colors through the GTK+ 2 rc grammar (not read in detail in `main.rc`).
- GE3.2 Dark variant: the same named colors with different values (GE2.3). The dark rc adds `hacks-dark.rc` (GE2.1).
- GE3.3 The engine's `AdwaitaStyle` derives from `GtkStyle` (`themes/Adwaita/gtk-2.0/adwaita_engine.c:40-43`, type registration at `themes/Adwaita/gtk-2.0/adwaita_engine.c:50`). The rc style derives from `GtkRcStyle` (`themes/Adwaita/gtk-2.0/adwaita_engine.c:45-48`, registration in `adwaita_rc_style_class_init` at `themes/Adwaita/gtk-2.0/adwaita_engine.c:219`).
- GE3.4 Shade or mix functions: none in the engine file read (the engine file has 250 lines, and only `draw_box` and `draw_flat_box` overrides and one cairo color for menus are present; see GE4.3).
- GE3.5 Per-state handling is done by the GTK+ 2 pixmap engine rules in `main.rc` (`engine "pixmap"` blocks, first at `themes/Adwaita/gtk-2.0/main.rc:141`; state values such as `state = NORMAL` appear in those blocks). The `main.rc` file has 2554 lines and was not read in full.

## 4. Output and rendering path
- GE4.1 Engine name: `main.rc` loads the in-tree engine as `engine "adwaita" {}` (`themes/Adwaita/gtk-2.0/main.rc:139`). The pixmap engine is a GTK+ 2 built-in and is used in `engine "pixmap" { image { ... } }` blocks (`themes/Adwaita/gtk-2.0/main.rc:141` onward; the first `pixmap` block after the `adwaita` engine line is at line 141).
- GE4.2 Entry points of the engine module: `theme_init` (`themes/Adwaita/gtk-2.0/adwaita_engine.c:235`) registers `AdwaitaRcStyle` and `AdwaitaStyle` types, `theme_exit` is empty, and `theme_create_rc_style` returns a new `AdwaitaRcStyle` object (`themes/Adwaita/gtk-2.0/adwaita_engine.c:247`).
- GE4.3 Overridden draw functions: `style_class->draw_box` and `style_class->draw_flat_box` are set in `adwaita_style_class_init` (`themes/Adwaita/gtk-2.0/adwaita_engine.c:172-177`). The box draw function (`themes/Adwaita/gtk-2.0/adwaita_engine.c:104`) draws a 1-pixel outline only for `GtkMenu` widgets with detail `menu` when the window manager is a fallback (`themes/Adwaita/gtk-2.0/adwaita_engine.c:116-119`, and `wm_is_fallback` at `themes/Adwaita/gtk-2.0/adwaita_engine.c:69`). Other calls chain to the parent class (`themes/Adwaita/gtk-2.0/adwaita_engine.c:129`).
- GE4.4 Flat box: `adwaita_draw_flat_box` (`themes/Adwaita/gtk-2.0/adwaita_engine.c:136`) chains to the parent for the non-menu case (`themes/Adwaita/gtk-2.0/adwaita_engine.c:150`).
- GE4.5 Toplevel tagging hack: when the application name starts with "OpenOffice.org" or "LibreOffice", the toplevel window widget name is set to `openoffice-toplevel` or `libreoffice-toplevel` (`themes/Adwaita/gtk-2.0/adwaita_engine.c:155-163`, helper `do_toplevel_hack` at `themes/Adwaita/gtk-2.0/adwaita_engine.c:53-64`).
- GE4.6 Assets: `render-assets.sh` renders PNG files from `assets.svg` with Inkscape, one per line of `assets.txt`, then compresses them with zopflipng (`themes/Adwaita/gtk-2.0/render-assets.sh:3-8` variables and loop, `themes/Adwaita/gtk-2.0/render-assets.sh:17-21` render and compress). The asset list `themes/Adwaita/gtk-2.0/assets.txt` has 144 lines (count only).
- GE4.7 Assets for external or dark use: `render-assets-external.sh` and `assets-external.txt` exist in the Adwaita and Adwaita-dark gtk-2.0 directories (names only; contents not read).

## 5. Extension and integration points
- GE5.1 Engine discovery is by GTK+ 2 at runtime. The engine library is `libadwaita.la` installed into `$(libdir)/gtk-2.0/$(GTK2_VERSION)/engines` (`themes/Adwaita/gtk-2.0/Makefile.am:1-2`). The theme directory is `$(datadir)/themes/Adwaita/gtk-2.0` (`themes/Adwaita/gtk-2.0/Makefile.am:9`).
- GE5.2 ABI: the engine uses GTK+ 2 types and functions (`GtkStyle`, `GtkRcStyle`, `gtk_widget_set_name`, `gtk_window_get_window_type`) (`themes/Adwaita/gtk-2.0/adwaita_engine.c:24`, `:58-63`, `:155-163`). It also includes `gdk/gdkx.h` (`themes/Adwaita/gtk-2.0/adwaita_engine.c:27`).
- GE5.3 The index files (`index.theme.in`) make Adwaita selectable as a GTK metatheme (`themes/Adwaita/index.theme.in:1-9`).

## 6. Data and tooling
- GE6.1 Generators: `themes/HighContrast/create-highcontrast.c` and `themes/HighContrast/create-makefiles.sh` (names only; contents not read).
- GE6.2 `render-assets.sh` (GE4.6) needs Inkscape and zopflipng at fixed paths `/usr/bin/inkscape` and `/usr/bin/zopflipng` (`themes/Adwaita/gtk-2.0/render-assets.sh:3-4`).
- GE6.3 Theme subdirectories are built with autotools (`themes/Makefile.am` was not read).

## 7. Facts of note
- GE7.1 The README states the module does not include GTK+ 3 Adwaita (GE1.2); the gtk-3.0 directories in this repo were listed but not read.
- GE7.2 The engine code includes a hack for OpenOffice and LibreOffice toplevel windows (GE4.5), described in the source as "totally awful" (`themes/Adwaita/gtk-2.0/adwaita_engine.c:159`).
- GE7.3 The engine draws only menu outlines in a non-composited window manager fallback (GE4.3).
- GE7.4 The file `themes/Adwaita/gtk-2.0/gtkrc:4-5` states that the file is the GTK+ 2 version of Adwaita that tries to look like the GTK+ 3 version.

## 8. Not covered
- Not read: LICENSE text (first lines), main.rc (lines 1-138 and 142-2554), apps.rc, hacks.rc, hacks-dark.rc, the HighContrast rc files beyond line 13, the Adwaita-dark and HighContrast engine references, the gtk-3.0 CSS (listed only), the icon directories, the po/ translations, configure.ac and the top-level build files (not read), create-highcontrast.c and create-makefiles.sh.
- Read partly: themes/Adwaita/gtk-2.0/adwaita_engine.c (lines 21-27, 40-64, 69-70, 104-177, 190-250 in part), themes/Adwaita/gtk-2.0/gtkrc (1-40), themes/Adwaita-dark/gtk-2.0/gtkrc (15-19, 38-41), themes/Adwaita/index.theme.in and themes/Adwaita-dark/index.theme.in (heading lines), themes/Adwaita/gtk-2.0/render-assets.sh (all 24 lines).
