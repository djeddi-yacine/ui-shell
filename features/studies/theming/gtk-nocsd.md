# gtk-nocsd: LD_PRELOAD library that turns off GTK 3, GTK 4, libhandy and libadwaita client-side decorations

Source: refs/gtk-nocsd (shallow clone; commit 5e933b8; branch main). License: GPL-3.0 (`LICENSE:1-2`). Scope: whole repo; the study focuses on `Source/GTK-NoCSD.c` (6462 lines, read by targeted ranges), `README.md`, `Makefile`, and `Source/*.sh`/`Source/*.csh` (listed only).
Id prefix: GN.

## 1. Purpose and shape
- GN1.1 An LD_PRELOAD shared library that disables client-side decorations (CSD) in GTK3, GTK4, libhandy and libadwaita apps, restoring the window manager's server-side titlebar. `README.md:3`, `README.md:8-9`.
- GN1.2 Language: C (`Source/GTK-NoCSD.c`). Targets: GTK 3, GTK 4, libhandy, libadwaita. `README.md:3`, `README.md:11-15` (build deps: GCC, pkg-config, libadwaita, optional make).
- GN1.3 Build: a Makefile (`Makefile`) with `build`, `install`, `uninstall`, `format` (uncrustify), `check` targets. `README.md:24-31`. Manual compile line: `gcc -fPIC -shared ./Source/GTK-NoCSD.c -o libgtk-nocsd.so.0 -Wl,-soname,libgtk-nocsd.so.0 $(pkg-config --cflags libadwaita-1 gobject-2.0 gio-2.0)`. `README.md:47-52`. 32-bit build adds `-m32`. `README.md:57-60`.
- GN1.4 Makefile install paths: `PREFIX ?= /usr/local`, `LIBDIR ?= $(PREFIX)/lib64`, `OPTDIR ?= /opt/gtk-nocsd`, `LICENSEDIR`, `DOCDIR`. `Makefile:24-28`.
- GN1.5 Top-level layout:
  - `Source/GTK-NoCSD.c`: the library (6462 lines). Single source file.
  - `Source/gtk-nocsd.sh`, `Source/gtk-nocsd.csh`: shell wrappers (not read).
  - `Source/Test.c`, `Source/Test.sh`: test program and script (not read).
  - `Makefile`, `Uncrustify.cfg`: build and format configuration.
  - `README.md`, `SingleAppUsage.md`, `SingleSnapUsage.md`: usage docs (only `README.md` read).
  - `Images/`: before and after screenshots.

## 2. Theme input (how configuration reaches it)
- GN2.1 Environment variables read at constructor time through `GET_VARIABLE` / `getenv` in `GTKNoCSDInit`:
  - `GTK-NoCSDAppImage` (AppImage detection). `Source/GTK-NoCSD.c:475`
  - `GTK_CSD` (1 disables the library). `Source/GTK-NoCSD.c:476`; documented at `README.md:143`
  - `XDG_CURRENT_DESKTOP` and `GTK_NOCSD_GNOME` (library is off on GNOME unless `GTK_NOCSD_GNOME=1`). `Source/GTK-NoCSD.c:529-530`; `README.md:146`
  - `GTK_NOCSD_MENU_GROUP`. `Source/GTK-NoCSD.c:561`; `README.md:153`
  - `GTK_OVERLAY_SCROLLING` (parsed as `1`, `0`, or unset). `Source/GTK-NoCSD.c:565-567`; `README.md:144`
  - `GTK_THEME`. `Source/GTK-NoCSD.c:574`
  - `GTK_NOCSD_CSD`, `GTK_NOCSD_CSD_PADDING`, `GTK_NOCSD_NO_CSS`, `GTK_NOCSD_NO_GTK3`, `GTK_NOCSD_NO_GTK4`, `GTK_NOCSD_NO_UNDECORATED`, `GTK_NOCSD_MENU`, `GTK_NOCSD_SCROLL`: `README.md:143-154`. The `GET_VARIABLE` call for `GTKNoCSDNoCSS` is at `Source/GTK-NoCSD.c:555`. The `GTKNoCSDCSDPadding`, `GTKNoCSDNoCSS`, `GTKNoCSDNoGTK3` flags are declared at `Source/GTK-NoCSD.c:328`.
- GN2.2 The library sets `GTK_CSD=0` in its own environment so applications that check the variable see it. `Source/GTK-NoCSD.c:570-571`
- GN2.3 Built-in CSS: loaded from the library, not from a file on disk. `GTKNoCSDLoadCSS` loads CSS for GTK 3 and GTK 4, globally or per display. `Source/GTK-NoCSD.c:2612-2613`. Called from `GTKNoCSDDoSettings`. `Source/GTK-NoCSD.c:2721,2726`.
- GN2.4 Per-display settings: `GTKNoCSDDoSettings(GdkDisplay*)` applies all global or per-display configuration. `Source/GTK-NoCSD.c:2636-2637`.
- GN2.5 No config file is read by the library (UNVERIFIED for the shell wrappers, which were not read).

## 3. Color and style model
- GN3.1 The library does not define colors. Styling is limited to CSS that loads through `GTKNoCSDLoadCSS` (contents of the CSS string not read beyond its signature, `Source/GTK-NoCSD.c:2612`).
- GN3.2 Style classes manipulated: the code calls GTK style-context functions and checks classes via `GTKNoCSDHasClass`. `Source/GTK-NoCSD.c:1649`. The class names used are UNVERIFIED in this study beyond the function names.
- GN3.3 Shade or mix formulas: none found in the read ranges.
- GN3.4 Per-state handling: unrealize and map hooks (`GTKNoCSDUnrealize` `:1700`, `GTKNoCSDWindowMap` `:2064`) act on window state. Their bodies were not read.

## 4. Output and rendering path
- GN4.1 The library changes widget tree and window properties at run time; it writes no files.
- GN4.2 Load and init (in order):
  1. The dynamic loader runs the constructor `GTKNoCSDInit`. `Source/GTK-NoCSD.c:463-464`. `GTKNoCSDMain` is a separate default-visibility entry point. `Source/GTK-NoCSD.c:192-196`
  2. The init code sets up a crash handler (`GTKNoCSDAction`, `:102`), saves arguments (`GTKNoCSDSaveArguments`, `:31`), and can unload the library from `LD_PRELOAD` (`GTKNoCSDUnsetLDPreload`, `:146`). `Source/GTK-NoCSD.c:24` (section header "Start up").
  3. dlsym is found by walking the dynamic-linker segments (`GTKNoCSDGetDL` `:349`, `GTKNoCSDGetLDAndLibC` `:407`, `GTKNoCSDInitDL` `:434`). Stored pointers for `dlsym`, `dlopen`, `dlclose`, `dladdr` are declared at `Source/GTK-NoCSD.c:333-336`.
  4. Environment variables are read (GN2.1).
  5. Libraries are located (`GTKNoCSDGetLibrary` `:1031`, `GTKNoCSDGetLinkedLibraries` `:1066`), with adwaita and handy type/symbol loaders (`GTKNoCSDGetAdwTypes` `:1095`, `GTKNoCSDGetHdyTypes` `:1109`, `GTKNoCSDGetAdwSymbols` `:1117`, `GTKNoCSDGetHdySymbols` `:1152`).
  6. Function pointers for GTK are resolved (`GTKNoCSDGetReferences` `:1166`; example loads `LOAD_SYMBOL(Library, gtk_window_set_decorated)` at `:1379` and `gtk_window_set_titlebar` at `:1418`, `gtk_header_bar_pack_start/end` at `:1478-1479`).
  7. Hooks are installed (`GTKNoCSDHooker` `:2245`) for window and widget events.
- GN4.3 GTK entry points wrapped by macro: `FUNCTION(...)` declarations for GTK types and functions, for example `gtk_window_get_type` `:602`, `gtk_header_bar_get_type` `:604`, `gtk_file_chooser_dialog_get_type` `:612`, `gtk_popover_menu_get_type` `:616`. `Source/GTK-NoCSD.c:602-618`. The `FUNCTION` helper at `Source/GTK-NoCSD.c:649,739,972-973` defines the `o_<name>` pointers.
- GN4.4 Window decoration change: `GTKNoCSDMagic(GtkWindow*, size_t)` is the main window-rewrite routine. `Source/GTK-NoCSD.c:2741`. It is called on map (`:2064` path) and from the recall timer (`GTKNoCSDRecall` `:1622`, which calls `GTKNoCSDMagic` at `:1625`). Inside Magic, `gtk_window_set_decorated` and `gtk_window_set_titlebar` are used (lines not traced in detail, UNVERIFIED).
- GN4.5 Window content and headerbar: `GTKNoCSDWindowSetChild` `:2086`, `GTKNoCSDSetHeaders` `:2202`, `GTKNoCSDWindowGetChild` `:2078`. The controls are moved into window content (README wording at `README.md:9`). Exact moves not traced (UNVERIFIED).
- GN4.6 Application signal hooks: `GTKNoCSDWindowAdded` `:2041`, `GTKNoCSDApplicationChanged` `:2048`, `GTKNoCSDDoApplicationName` `:1707`.
- GN4.7 File chooser: `GTKNoCSDSetUpFileChooser` `:2451`.
- GN4.8 Menu export (`GTK_NOCSD_MENU`): `GTKNoCSDMenuHook` `:1165` (declared), `GTKNoCSDMenuCollect` `:3356`, `GTKNoCSDMenuAppendButton` `:3374` and `:3428`, `GTKNoCSDMenuPages` `:3510`.
- GN4.9 Dialogs and shortcuts window: `GTKNoCSDUpdateDialog` `:2560`, `GTKNoCSDHandleShortcutsWindow` `:2022`.

## 5. Extension and integration points
- GN5.1 Activation: `LD_PRELOAD=/path/libgtk-nocsd.so application`. `README.md:124`. Global: profile export (`README.md:132`), `environment.d` (`README.md:135-136`), Flatpak override (`README.md:205-211`).
- GN5.2 Install location: default `/usr/local/lib64`, plus `/opt/gtk-nocsd/libgtk-nocsd.so` for Flatpak sandboxes. `Makefile:24-27`; `README.md:66,191`.
- GN5.3 Soname: `libgtk-nocsd.so.0` (`README.md:43,49-50`).
- GN5.4 ABI and version coupling: the library resolves GTK, libadwaita and libhandy symbols at run time with dlsym, rather than linking them (`Source/GTK-NoCSD.c:1051,1060`, `:1305`, `:1325`). Minimum GTK version: not stated in the README (UNVERIFIED).
- GN5.5 GTK check: `o_gtk_check_version` is looked up with `RTLD_DEFAULT` (`Source/GTK-NoCSD.c:1305`).
- GN5.6 Apps that use `gapplication launch` may drop LD_PRELOAD (`README.md:135`).
- GN5.7 GTK 4 and libadwaita: enabled by default (`GTK_NOCSD_NO_GTK4` disables it, `README.md:151`).

## 6. Data and tooling
- GN6.1 Build: `Makefile` (targets listed at `README.md:26-31`).
- GN6.2 Formatting: `Uncrustify.cfg` with the `format` target (`README.md:30`).
- GN6.3 Static check: `check` target checks for high glibc symbol dependencies (`README.md:31`). Makefile recipe not read.
- GN6.4 Test program: `Source/Test.c` and `Source/Test.sh` (not read).
- GN6.5 Docs: `README.md`, `SingleAppUsage.md`, `SingleSnapUsage.md` (only `README.md` read).
- GN6.6 Packaging references: AUR, COPR, Debian, Ubuntu, Void and others, all listed in `README.md:68-117`.

## 7. Facts of note
- GN7.1 The README says the library is for GTK3 and GTK4 apps with libadwaita and libhandy, and it says the default CSD look "looks off everywhere else". `README.md:3,8`.
- GN7.2 Disabled by default on GNOME. `README.md:146`.
- GN7.3 The README warns about a previously compromised third-party package (`README.md:75`). The claim is quoted only; it is not verified here.
- GN7.4 A code comment states that musl does not run constructors for custom entry points, and the library handles this case in `GTKNoCSDMain`. `Source/GTK-NoCSD.c:196-199`. The crash handler is at `Source/GTK-NoCSD.c:102`.
- GN7.5 Known issues or TODO comments in the source: not searched exhaustively (UNVERIFIED).
- GN7.6 License: GPL-3.0 (`LICENSE:1-2`).

## 8. Not covered
- Most of `Source/GTK-NoCSD.c` (6462 lines) was not read; only the constructor, env-variable block, dlsym/ld setup headers, symbol-loader headers, the CSS loader and settings function headers, the window map and hooker names, and the GTK symbol list were checked.
- `GTKNoCSDMagic` body (`:2741-3343`) was not read.
- `Source/gtk-nocsd.sh`, `Source/gtk-nocsd.csh`, `Source/Test.sh`, `Source/Test.c`, `Uncrustify.cfg`, `SingleAppUsage.md`, `SingleSnapUsage.md` were not read.
- The CSS content loaded by `GTKNoCSDLoadCSS` was not read.
- The exact GTK, libadwaita and libhandy versions the code supports were not verified.
- No build was run; `refs/` was not modified.
