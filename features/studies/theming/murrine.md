# murrine: GTK+ 2 engine (Murrine) with rc-file options, drawing code and a blur helper set

Source: refs/murrine (shallow clone; commit f96e446; branch master; last commit 2016-03-21). License: COPYING.2.1 (GNU Lesser General Public License, version 2.1; the file header is at COPYING.2.1:2-3) and COPYING. Scope: README, configure.ac, Makefile.am, schema/, src/murrine_theme_main.c, src/murrine_rc_style.c (option table and parser entry points), src/murrine_style.c (class setup and widget-state helpers), src/murrine_types.h (style enum), and the file list of src/. Drawing bodies (src/murrine_draw.c, src/murrine_draw_rgba.c, the blur files) were listed, not read.
Id prefix: MU

## 1. Purpose and shape
- MU1.1 Murrine is a GTK+ 2 theme engine. The README says "This is Murrine GTK+ engine. This source code provides only the engine, get the themes @ gnomelook.org" (`README:1`). Language: C (`src/*.c`).
- MU1.2 Targeted toolkit: GTK+ 2. `configure.ac:42` requires `gtk+-2.0 >= 2.18.0`. The install path is `$(libdir)/gtk-2.0/$(GTK_VERSION)/engines` (`Makefile.am:6`).
- MU1.3 Version: `AC_INIT([murrine], [0.98.2])` (`configure.ac:1`).
- MU1.4 Top-level layout:
  - `src/`: engine source (animation, theme entry point, rc style parser, style class, drawing, blur helpers, cairo support).
  - `schema/`: GConf-style engine option schema template `murrine.xml.in.in` (`schema/murrine.xml.in.in:2`).
  - `po/`, `AUTHORS`, `ChangeLog`, `NEWS`, `TODO`, `MAINTAINERS`, `CREDITS`: documentation and translations (not read).
  - `murrine.pc.in`, `murrine.doap`: pkg-config and project metadata (not read).
  - `autogen.sh`, `configure.ac`, `Makefile.am`: autotools build.
- MU1.5 Build: autotools. Requires pixman: `PKG_CHECK_MODULES(pixman,[pixman-1],...)` with an error message when missing (`configure.ac:45`). The engine module `libmurrine.la` is built with `-module -avoid-version -no-undefined` (`Makefile.am:7`, `Makefile.am:38`), linked with `$(GTK_LIBS) $(pixman_LIBS) -lm` (`Makefile.am:39`).

## 2. Theme input (how configuration reaches it)
- MU2.1 Entry: the engine exports `theme_init` (`src/murrine_theme_main.c:25-26`, with the `G_MODULE_EXPORT` attribute at line 25), `theme_exit` (`src/murrine_theme_main.c:34`), and `theme_create_rc_style` (`src/murrine_theme_main.c:39-41`, returns a `MurrineRcStyle` object).
- MU2.2 Rc-file options: the GTK+ 2 rc file sets an engine block with options. The parser is `murrine_rc_style_parse` (installed at `src/murrine_rc_style.c:244`, `rc_style_class->parse`). The option names are listed in the `theme_symbols[]` table starting at `src/murrine_rc_style.c:99`, for example `animation` (`src/murrine_rc_style.c:101`), `arrowstyle`, `border_colors`, `border_shades`, `colorize_scrollbar`, `contrast`, `focus_color`, `gradient_colors`, `gradient_shades`, `glow_shade`, `highlight_shade`, `menustyle`, `prelight_shade`, `progressbarstyle`, `reliefstyle` and others. About 53 entries are in the table (count from grep; the table was not read line by line).
- MU2.3 Option types: the parser helpers read boolean values (`theme_parse_boolean`, `src/murrine_rc_style.c:259`), colors (`src/murrine_rc_style.c:284`, `GdkColor`), shades (`src/murrine_rc_style.c:326`), integers (`src/murrine_rc_style.c:349`) and gradients (`src/murrine_rc_style.c:372`, `src/murrine_rc_style.c:428`). The enum and numeric helpers beyond these were not read.
- MU2.4 Defaults: the rc style sets `murrine_rc->rgba` to FALSE at `src/murrine_rc_style.c:205` (the enclosing function was not identified).
- MU2.5 Schema: `schema/murrine.xml.in.in` declares the engine `murrine` (`schema/murrine.xml.in.in:2`) and options with types and defaults, for example boolean `animation` default TRUE (`schema/murrine.xml.in.in:13`), enumeration `arrowstyle` default 0 (`schema/murrine.xml.in.in:19`), boolean `colorize_scrollbar` default TRUE (`schema/murrine.xml.in.in:33`).
- MU2.6 Environment variables and file paths: none found in the files read.

## 3. Color and style model
- MU3.1 Style classes: `MurrineStyle` (derived from `GtkStyle`) is defined with `G_DEFINE_DYNAMIC_TYPE (MurrineStyle, murrine_style, GTK_TYPE_STYLE)` (`src/murrine_style.c:71`). Its class has `style_functions[MRN_NUM_DRAW_STYLES]` (`src/murrine_style.h:99`).
- MU3.2 Two draw styles: `MRN_STYLE_MURRINE = 0` and `MRN_STYLE_RGBA = 1` (`src/murrine_types.h:28-29`). Both are registered in the class init (`src/murrine_style.c:2868` and `src/murrine_style.c:2870`, registration functions in `src/murrine_draw.c:3684` and `src/murrine_draw_rgba.c:2298`).
- MU3.3 Composited RGBA selection: `murrine_widget_is_rgba` returns TRUE only if the screen is composited and the visual is 32-bit with masks `0xff0000`, `0x00ff00`, `0x0000ff` (`src/murrine_style.c:94-112`; the compile-time guard is `HAVE_RGBA` at `src/murrine_style.c:104`).
- MU3.4 RC option names for shades and colors are listed in `theme_symbols` (MU2.2), including `highlight_shade`, `prelight_shade`, `glow_shade`, `lightborder_shade`, `border_shades`, `gradient_shades`, `gradient_colors`, `border_colors`, `focus_color`, `default_button_color`. Their numeric semantics were not read.
- MU3.5 Shade and mix functions: not read (drawing bodies are in `src/murrine_draw.c`, 3724 lines, and `src/murrine_draw_rgba.c`).
- MU3.6 Per-state handling: the draw functions take a `GtkStateType` argument (signature macro `DRAW_ARGS` used at `src/murrine_style.c:787`). The per-state logic is in the drawing files (not read).

## 4. Output and rendering path
- MU4.1 Call chain for a widget draw, in order (as far as read):
  1. GTK+ 2 loads the module, calls `theme_init` (`src/murrine_theme_main.c:26`), which registers `MurrineRcStyle` and `MurrineStyle` types (`src/murrine_theme_main.c:29-30`).
  2. The rc parser sets fields from the option table (`src/murrine_rc_style.c:244`, table at `src/murrine_rc_style.c:99`).
  3. `murrine_style_init_from_rc` copies rc settings into the style (`src/murrine_style.c:2847` assignment, function body at `src/murrine_style.c:2432`).
  4. Each GtkStyle draw vfunc is replaced in `murrine_style_class_init` (`src/murrine_style.c:2840`): `draw_arrow` (`src/murrine_style.c:2848`) through `draw_vline` (`src/murrine_style.c:2866`), covering the draw_layout, draw_box, draw_box_gap, draw_check, draw_expander, draw_extension, draw_flat_box, draw_focus, draw_handle, draw_hline, draw_option, draw_resize_grip, draw_shadow, draw_shadow_gap, draw_slider and draw_tab hooks. `init_from_rc` is set at `src/murrine_style.c:2847` and `render_icon` at `src/murrine_style.c:2860`.
  5. The draw function (for example `murrine_style_draw_box`, `src/murrine_style.c:787`) chooses the style function set by `MRN_STYLE_MURRINE` or `MRN_STYLE_RGBA` (`src/murrine_style.c:2868-2870`) and calls into `src/murrine_draw.c` or `src/murrine_draw_rgba.c`.
- MU4.2 Animation: a `animation` rc option (MU2.2) and a `src/animation.c` file (326 lines, not read) provide the animation path. The `--enable-animation` configure switch is named in the README build line (`README:5`).
- MU4.3 Blur helpers: `src/gaussian-blur.c`, `src/stack-blur.c`, `src/raico-blur.c`, `src/exponential-blur.c` are present (file list). Which one the drawing code calls was not read.
- MU4.4 Output is GTK+ 2 cairo drawing (`src/cairo-support.c`, file list). No generated files are involved in the path read.

## 5. Extension and integration points
- MU5.1 Discovery: GTK+ 2 loads the module named in the rc file's `engine "murrine"` block. The module file is `libmurrine.la` installed into the GTK+ 2 engines directory (`Makefile.am:6-7`).
- MU5.2 Entry symbols exported: `theme_init`, `theme_exit`, `theme_create_rc_style` (`src/murrine_theme_main.c:25-41`). The GTK+ 2 engine interface is these three symbols; `-no-undefined` is set (`Makefile.am:38`).
- MU5.3 ABI: depends on GTK+ 2 private-looking headers through `GTK_LIBS` and on `pixman-1` (`configure.ac:42-45`).
- MU5.4 Schema consumers: `schema/murrine.xml.in.in` describes the option set for GConf-based configuration tools (the consumer was not read; UNVERIFIED which tool reads it).

## 6. Data and tooling
- MU6.1 Schema template: `schema/murrine.xml.in.in`, with `schema/Makefile.am` (`configure.ac:76-77` lists the generated schema outputs).
- MU6.2 Build: `autogen.sh` and `configure.ac` (`configure.ac:1`, `configure.ac:42-53`).
- MU6.3 Docs: `README`, `NEWS`, `ChangeLog`, `TODO` (names only; contents not read except README:1-9).
- MU6.4 Tests: none found in the file list.

## 7. Facts of note
- MU7.1 The README says the source "provides only the engine", and themes are obtained elsewhere (`README:1`). No theme files are in this repo.
- MU7.2 The engine prints no banner: the version printf in `theme_init` is commented out (`src/murrine_theme_main.c:28`, text reads "Murrine 0.91.x Development Snapshot"). `configure.ac:1` declares version 0.98.2.
- MU7.3 Configure: `GTK_VERSION` is derived from `gtk+-2.0` (`configure.ac:53`).
- MU7.4 License: LGPL 2.1 (`COPYING.2.1`); COPYING is also present (its header not read in this session: UNVERIFIED for the exact version).

## 8. Not covered
- Not read: src/murrine_draw.c (3724 lines), src/murrine_draw_rgba.c, src/murrine_style.c beyond lines 71, 94-112, 787-790, 2432, 2840-2876, src/murrine_rc_style.c beyond lines 28, 94-101, 159, 205, 237-244, 259-325, src/animation.c, the blur files, src/support.c, src/cairo-support.c, src/stack-blur.c, po/, schema body beyond line 2-33, COPYING body, ChangeLog, TODO, autogen.sh.
- Read partly: src/murrine_theme_main.c (full, 55 lines), src/murrine_types.h (lines 28-29 and the header).
