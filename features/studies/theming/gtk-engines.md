# gtk-engines: collection of GTK+ engines (Clearlooks, Crux, Glide, HC, Industrial, Mist, Redmond, ThinIce) and their default themes

Source: refs/gtk-engines (shallow clone; commit 6cca0d1; branch master; last commit 2016-04-11). License: COPYING (GNU Lesser General Public License; the title is at COPYING:2). Scope: README, configure.ac, Makefile.am, engines/Makefile.am, engines/engine.symbols, the per-engine Makefile.am and theme_init lines for 4 engines, themes/Makefile.am, themes/GNOME3 rc file lines, the schema/ file list, and the engines/ file counts. Engine C bodies were not read beyond the entry points.
Id prefix: GF

## 1. Purpose and shape
- GF1.1 The README says: "gtk-engines provides a central location for commonly used GTK+ engines. It currently supplies several engines and default themes for those which have one." (`README:4-6`).
- GF1.2 Engines described in the README: Clearlooks (`README:8-15`), Crux (`README:17-22`), Glide (`README:24-25`), HC (`README:27-29`), Industrial (`README:31-33`), LUA, described as experimental and "not compiled by default" (`README:35-38`), Mist (`README:40-41`), Redmond (`README:43-45`), ThinIce (`README:47-49`).
- GF1.3 Toolkit requirement conflict: the README says "GTK+, version 2.12.0 or later" (`README:55-57`), but the build check in configure.ac requires `gtk+-3.0 >= 2.91.0` (`configure.ac:128-129`, error message at `configure.ac:129`). The GTK version used for the install path is read from `gtk+-3.0` (`configure.ac:131`). The package therefore targets GTK+ 3 in its build files, and the README is older.
- GF1.4 Top-level layout (the parts that matter):
  - `engines/`: one directory per engine (`clearlooks`, `crux`, `glide`, `hc`, `industrial`, `mist`, `redmond`, `thinice`), plus `support/` (shared helper library `libsupport.la`, see the LIBADD lines in the engine Makefiles such as `engines/thinice/Makefile.am:21`) and `engine.symbols` (GF5.2). About 66 C and header files are under `engines/`.
  - `themes/`: default theme directories `GNOME3`, `Clearlooks`, `Industrial`, `Redmond`, `Crux`, `Mist`, `ThinIce` (`themes/Makefile.am:3`).
  - `schema/`: GConf-style engine schema templates (GF6.1).
  - `configure.ac`, `Makefile.am`, `autogen.sh`, `git.mk`, `gtk-engines-3.pc.in`: build.
  - `test/`, `po/`, `ChangeLog`, `NEWS`, `MAINTAINERS`, `AUTHORS`: not read.
- GF1.5 Build: autotools, with engine selection flags (GF2.4). The package provides `gtk-engines-3.pc` (`Makefile.am:9`, pkg-config install at `Makefile.am:45-46`).

## 2. Theme input (how configuration reaches it)
- GF2.1 Engine selection is done by the GTK rc file: `engine "<name>"` blocks. Example: the GNOME3 GTK+ 2 theme file uses `engine "clearlooks"` at `themes/GNOME3/gtk-2.0/gtkrc:79` and `:110`. The GTK+ 3 theme directory of GNOME3 is `themes/GNOME3/gtk-3.0/` (listed; `themes/GNOME3/gtk-3.0/gtkrc` was not read).
- GF2.2 Build-time selection: `configure.ac` has `AC_ARG_ENABLE` switches per engine: `clearlooks` (`configure.ac:41`), `crux` (`configure.ac:42`), `hc` (`configure.ac:43`), `industrial` (`configure.ac:44`), `mist` (`configure.ac:45`), `redmond` (`configure.ac:46`), `glide` (`configure.ac:47`), `thinice` (`configure.ac:48`). A global `--disable-all` switch sets the default (`configure.ac:40`).
- GF2.3 Feature switches: `--enable-animation` for Clearlooks (`configure.ac:50`), `--disable-widget-checks` (`configure.ac:51`), `--enable-development` (`configure.ac:53`), `--enable-paranoia` (`configure.ac:55`), `--disable-deprecated` (`configure.ac:57`).
- GF2.4 Environment variables: none found in the files read.
- GF2.5 Engine option values come from the GTK+ rc grammar of each engine. The option parsers were not read (UNVERIFIED for the option list of each engine).

## 3. Color and style model
- GF3.1 Each engine defines its own rc style and style classes. The entry point files show the registration calls, for example `mist_rc_style_register_types` and `mist_style_register_types` (`engines/mist/src/mist.c:9-10`), and `industrial_rc_style_register_types` and `industrial_style_register_types` (`engines/industrial/src/industrial_theme_main.c:40-41`).
- GF3.2 Color, shade and palette handling is engine-specific and was not read.
- GF3.3 Per-state handling: not read.

## 4. Output and rendering path
- GF4.1 Common entry sequence, as seen in four engines:
  1. `theme_init (GTypeModule *module)` is exported (`engines/clearlooks/src/clearlooks_theme_main.c:31`, `engines/mist/src/mist.c:7`, `engines/crux/src/crux-main.c:13`, `engines/industrial/src/industrial_theme_main.c:38`).
  2. `theme_init` registers the rc style and style types (Mist at `engines/mist/src/mist.c:9-10`).
  3. `theme_exit` (`engines/clearlooks/src/clearlooks_theme_main.c:38`, `engines/mist/src/mist.c:14`, `engines/crux/src/crux-main.c:20`, `engines/industrial/src/industrial_theme_main.c:45`).
  4. `theme_create_rc_style` returns the rc style object (`engines/clearlooks/src/clearlooks_theme_main.c:43`, `engines/mist/src/mist.c:19`, `engines/crux/src/crux-main.c:25`, `engines/industrial/src/industrial_theme_main.c:50`).
- GF4.2 Built library names (one per engine, from the engine Makefile.am files):
  - Clearlooks: `libclearlooks.la` (`engines/clearlooks/Makefile.am:26`).
  - HC: `libhcengine.la` (`engines/hc/Makefile.am:27`).
  - Industrial: `libindustrial.la` (`engines/industrial/Makefile.am:28`).
  - ThinIce: `libthinice.la` (`engines/thinice/Makefile.am:6`).
  - Crux: `libcrux-engine.la` (`engines/crux/Makefile.am:6`).
  - Redmond: `libredmond95.la` (`engines/redmond/Makefile.am:29`).
  - Glide: `libglide.la` (`engines/glide/Makefile.am:26`).
  - Mist: `libmist.la` (`engines/mist/Makefile.am:6`).
  Each is installed through `engine_LTLIBRARIES`, and most link `libsupport.la` and `$(GTK_LIBS)` (for example `engines/mist/Makefile.am:19`, `engines/glide/Makefile.am:37`).
- GF4.3 Exported symbol list: `engines/engine.symbols` lists `g_module_check_init`, `theme_init`, `theme_exit` and `theme_create_rc_style` (`engines/engine.symbols:1-4`).
- GF4.4 Theme files that use the engines are in `themes/` (GF1.4). The GNOME3 GTK+ 2 rc uses `engine "clearlooks"` (GF2.1).

## 5. Extension and integration points
- GF5.1 Discovery: the GTK rc file names the engine, and GTK loads the module by that name from the engines directory. The install directory is set per engine: `enginedir = $(libdir)/gtk-3.0/$(GTK_VERSION)/engines` in the Mist, Redmond, ThinIce and HC Makefile.am files (`engines/mist/Makefile.am:4`, `engines/redmond/Makefile.am:27`, `engines/thinice/Makefile.am:4`, `engines/hc/Makefile.am:25`). The line was not checked in the other engine Makefiles: UNVERIFIED for those.
- GF5.2 Exported entry points are the four symbols in GF4.3. The `g_module_check_init` symbol is the GLib module hook.
- GF5.3 Build coupling: `configure.ac` requires `gtk+-3.0 >= 2.91.0` (GF1.3), and the engine install paths use `gtk-3.0` (GF5.1).
- GF5.4 The `gtk-engines-3.pc` file exposes the package to pkg-config (`Makefile.am:9`, `Makefile.am:46`).

## 6. Data and tooling
- GF6.1 Schemas: `schema/` contains `clearlooks.xml.in.in`, `crux-engine.xml.in.in`, `glide.xml.in.in`, `hcengine.xml.in.in`, `industrial.xml.in.in`, `mist.xml.in.in`, `redmond95.xml.in.in`, `thinice.xml.in.in`, and `Makefile.am` (file list only; contents not read).
- GF6.2 Engine test directory: `test/` (name only; not read).
- GF6.3 Helpers: `git.mk` (included by `engines/Makefile.am`, git helper; contents not read).

## 7. Facts of note
- GF7.1 The LUA engine is described in the README as experimental and not compiled by default (`README:35-38`). No `lua` directory exists under `engines/` in this tree (checked against the `engines/` listing).
- GF7.2 The README and configure.ac disagree on the GTK version (GF1.3).
- GF7.3 The `hc` engine is built as `libhcengine.la` (GF4.2), while its schema file is `hcengine.xml.in.in` (GF6.1).
- GF7.4 Licence: LGPL (`COPYING:2`). The engine headers and sources carry their own headers (not read).

## 8. Not covered
- Not read: the bodies of all engines (only entry points for four engines and the Mist rc registration lines), engines/support/, engines/engine.symbols beyond line 4, themes/ directories (only themes/Makefile.am:3 and the GNOME3 gtkrc engine lines), schema bodies, test/, po/, ChangeLog, NEWS, autogen.sh, git.mk, gtk-engines-3.pc.in, configure.ac lines outside 2, 40-57, 128-131.
- Read partly: README (lines 4-56), configure.ac (lines 2, 40-57, 128-131), engines/Makefile.am (lines 1-2), engines/*/Makefile.am (the library lines named in GF4.2), the four theme_init entry files (lines named), themes/GNOME3/gtk-2.0/gtkrc (lines 79, 110 only).
