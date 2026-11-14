# lxappearance: C GTK 2 or GTK 3 settings dialog that writes gtkrc-2.0, GTK 3 settings.ini and live GtkSettings properties, with a plugin loader

Source: refs/lxappearance (shallow clone; commit dc5d5b3; branch master). License: GPL-2.0 (`COPYING:1-2`). Scope: whole repo, with the code path in `src/` (lxappearance.c, color-scheme.c, plugin.c, icon-theme.c, cursor-theme.c, widget-theme.c, font.c, other.c, utils.c), `configure.ac` (build selection), `data/` (desktop, pkg-config and glade templates). Not read: `ChangeLog`, `NEWS`, `TODO`, `man/`, `po/`.
Id prefix: LA.

## 1. Purpose and shape
- LA1.1 The program is a GTK theme switcher dialog that edits to pick GTK widget theme, icon theme, cursor theme, font, color scheme and sound/other settings (`src/lxappearance.c`, `src/*-theme.c`, `src/font.c`, `src/other.c`, `src/color-scheme.c`). Language: C. Toolkit: GTK 2 (default) or GTK 3, chosen at configure time (`configure.ac:60-63`, `enable_gtk3` branch; `CFLAGS` gets `-DENABLE_GTK3` at `:60`). Minimum versions: `gtk+-3.0 >= 3.0.0` or `gtk+-2.0 >= 2.12.0` (`configure.ac:61-63`).
- LA1.2 Build dependencies: `x11` (`configure.ac:55`), GTK (`:66`), `gmodule` for plugins (`:89`), optional `dbus-1 >= 0.95` (`:80`). Build system: autotools (`configure.ac`, `Makefile.am` files in `src/`, `data/`, `data/ui/`).
- LA1.3 Top-level layout:
  - `src/lxappearance.c`: main program, GTK settings read (`settings_init`, `:570`), file writers (`lxappearance_save_gtkrc`, `:268`; `lxappearance_save_lxsession`, `:477`), apply handler (`:540-550`), `reload_all_programs` (`:239`).
  - `src/color-scheme.c`: GTK 2 `gtk-color-scheme` editor (color buttons, hash-table I/O).
  - `src/icon-theme.c`, `src/cursor-theme.c`, `src/widget-theme.c`, `src/font.c`, `src/other.c`: one page each.
  - `src/plugin.c`, `src/plugin.h`: loader for `.so` plugins.
  - `src/utils.c`: shared helpers.
  - `data/ui/lxappearance.glade`: UI layout (GtkBuilder).
  - `data/lxappearance.desktop.in`, `data/lxappearance.pc.in`: desktop entry and pkg-config file templates.

## 2. Theme input (how configuration reaches it)
- LA2.1 Startup values: `settings_init()` reads `gtk-theme-name`, `gtk-font-name`, `gtk-icon-theme-name`, `gtk-cursor-theme-name`, `gtk-cursor-theme-size` from `gtk_settings_get_default()` (`src/lxappearance.c:570-578`).
- LA2.2 Existing gtkrc: `gtk_rc_get_default_files()` lists the rc files (`src/lxappearance.c:288`). The first file under `$HOME` is used; if none, `~/.gtkrc-2.0` is used (`src/lxappearance.c:293-300`).
- LA2.3 GTK 2 color scheme: read from `~/.gtkrc-2.0` through `gtkrc_file_get_color_scheme(gtkrc_file, app.color_scheme_hash)` (`src/lxappearance.c:646-647`, comment at `:642`). Color scheme string parsed by `color_scheme_str_to_hash` (`src/color-scheme.c:51-69`).
- LA2.4 GTK 3 settings file: `$XDG_CONFIG_HOME/gtk-3.0/settings.ini` (built from `g_get_user_config_dir()` plus `gtk-3.0`, `src/lxappearance.c:386-387`).
- LA2.5 Environment variables: `HOME` and the XDG config dir through GLib (`g_get_home_dir`, `g_get_user_config_dir`). `XDG_CONFIG_HOME` is honoured by GLib, not read directly in the code shown.
- LA2.6 lxsession: `lxappearance_save_lxsession` (`src/lxappearance.c:477`) is called when `app.use_lxsession` is set (`:544-545`). The file it writes was not read (UNVERIFIED for the path).
- LA2.7 Plugins: directory `PLUGIN_DIR` = `PACKAGE_LIB_DIR"/lxappearance/plugins"` (`src/plugin.c:28`), with `PACKAGE_LIB_DIR` defined from `libdir` (`src/Makefile.am:7`).

## 3. Color and style model
- LA3.1 Color scheme (GTK 2 only in the code path shown): `app.color_scheme_hash` is a `GHashTable` of `name -> color string` (`src/color-scheme.c`, `color_scheme_str_to_hash` at `:51`, serialize loop at `:45-47`). The editor has eight color buttons (`src/color-scheme.c:99`, loop `i < 8`), each mapped to a color name (table not read).
- LA3.2 Color parsing and formatting: `gdk_color_parse(color_str, &clr)` (`src/color-scheme.c:108`) and `gtk_color_button_get_color` (`:75`). Color is stored as a string.
- LA3.3 Live color scheme update: a color change sets the `gtk-color-scheme` property on the default `GtkSettings` (`src/color-scheme.c:82`).
- LA3.4 Color-scheme written to gtkrc: `gtk-color-scheme="%s"` in the GTK 2 rc output (`src/lxappearance.c:370`) and `gtk-color-scheme=%s` in the second output path (`:451`).
- LA3.5 No palette derivation or shade functions (lighten, darken, mix) were found in the read files (UNVERIFIED for the full `src/` tree; `other.c` and `font.c` were not read in full).
- LA3.6 Light and dark: none in the code read.
- LA3.7 Per-state colors (hover, pressed, disabled, focus): none. The color buttons are set insensitive when a name is missing (`src/color-scheme.c:115-118`).

## 4. Output and rendering path
- LA4.1 Apply handler (`src/lxappearance.c:540-550`): on `GTK_RESPONSE_APPLY`, the program calls, in order:
  1. `lxappearance_save_lxsession()` when `app.use_lxsession` (`:544-545`).
  2. `lxappearance_save_gtkrc()` (`:546`).
  3. `reload_all_programs()` (`:548`).
  4. `app.changed = FALSE` (`:550`).
- LA4.2 GTK 2 output, `lxappearance_save_gtkrc()` (`src/lxappearance.c:268-476`):
  1. Writes the header comment and `include "~/.gtkrc-2.0.mine"` (`:303-308`).
  2. Writes `gtk-theme-name` (`:313`), `gtk-icon-theme-name` (`:316`), `gtk-font-name` (`:319`), `gtk-cursor-theme-name` (`:322`), `gtk-cursor-theme-size` (`:326`).
  3. Writes `gtk-color-scheme` (`:370`).
  4. Saves the file with `g_file_set_contents` (`:379`) to the first `$HOME` rc file or `~/.gtkrc-2.0` (`:293-300`).
- LA4.3 GTK 3 output, inside the same function (`src/lxappearance.c:386-412`, GTK 3 branch): writes `settings.ini` in `gtk-3.0` with `gtk-theme-name` (`:399`), `gtk-icon-theme-name` (`:402`), `gtk-font-name` (`:405`), `gtk-cursor-theme-name` (`:408`), `gtk-cursor-theme-size` (`:412`). The `#ifdef` guard around this branch was not confirmed (UNVERIFIED).
- LA4.4 Live update (no restart): `icon-theme.c:144` sets `gtk-icon-theme-name`, `cursor-theme.c:83` sets `gtk-cursor-theme-name`, `cursor-theme.c:99` sets `gtk-cursor-theme-size`, and `color-scheme.c:82` sets `gtk-color-scheme`, all with `g_object_set(gtk_settings_get_default(), ...)`.
- LA4.5 Program reload: `reload_all_programs()` (`src/lxappearance.c:239`; body not read in full).
- LA4.6 Font: the font page edits the default font through the same `gtk-font-name` key (LA4.2 and LA4.3). The page code in `src/font.c` was not read in full.

## 5. Extension and integration points
- LA5.1 Plugins are shared objects loaded at start: `plugins_init(builder)` (`src/plugin.c:43`). It opens each file ending in `.so` (`:51`) in `PLUGIN_DIR` (`:45`) with `g_module_open` (`:54`), finds `plugin_load` (`:61`) and `plugin_unload` (`:68`), and calls `load(LXAppearance*, GtkBuilder*)`. Function types at `src/plugin.c:30-31`.
- LA5.2 Plugin teardown: `plugins_finalize` (`src/plugin.c:81`) calls the unload function and closes the module (`:87-89`).
- LA5.3 Plugin ABI: the plugin receives the `LXAppearance` struct pointer and the `GtkBuilder` (`src/plugin.c:30`). The header that defines the struct is `src/lxappearance.h` (struct fields not read). Plugins are coupled to the same GTK major version as the build (UNVERIFIED for any plugin in this repo; none is in the tree).
- LA5.4 Install paths: `PACKAGE_LIB_DIR` from `libdir` (`src/Makefile.am:7`). The pkg-config file is generated from `data/lxappearance.pc.in` (`prefix` at `:1`, `libdir` at `:3`, `includedir` at `:4`).
- LA5.5 Version coupling: GTK 2 (`gtk+-2.0 >= 2.12.0`) or GTK 3 (`>= 3.0.0`) selected at configure time (LA1.1). `DENABLE_GTK3` switches code paths (`configure.ac:60`).

## 6. Data and tooling
- LA6.1 UI: `data/ui/lxappearance.glade` (GtkBuilder), `data/ui/about.glade.in`.
- LA6.2 Desktop entry: `data/lxappearance.desktop.in`.
- LA6.3 Makefiles: `Makefile.am` files in `src/`, `data/`, `data/ui/`.
- LA6.4 Tests: none found in the file list.
- LA6.5 Docs: `README`, `man/` (not read).

## 7. Facts of note
- LA7.1 GTK 2 rc output starts with an `include` of `~/.gtkrc-2.0.mine` so that the user's own file wins (`src/lxappearance.c:303-308`).
- LA7.2 The GTK 2 path and the GTK 3 path are written in one function (LA4.2, LA4.3) and share the same key names.
- LA7.3 Color-scheme support is only in the GTK 2 path as read (LA3.1, LA3.4). The `gtk-color-scheme` property is set live (LA3.3).
- LA7.4 `dbus-1` is optional (`configure.ac:80`).
- LA7.5 License: GPL-2.0 (`COPYING:1-2`).

## 8. Not covered
- `src/font.c`, `src/other.c`, `src/widget-theme.c`, `src/utils.c` bodies (headers only).
- `reload_all_programs` body (`src/lxappearance.c:239`) and `lxappearance_save_lxsession` body (`:477`).
- The `#ifdef` structure around the GTK 3 branch (LA4.3).
- `src/lxappearance.h` struct fields and `src/plugin.h`.
- `ChangeLog`, `NEWS`, `TODO`, `man/`, `po/`.
- No build or run was done; `refs/` was not modified.
