# xsettingsd: small X11 daemon that publishes XSETTINGS (theme, font, cursor, DPI) from a text config file

Source: refs/xsettingsd (shallow clone; commit 5416492; branch master; date 2023-04-18). License: BSD-style, "Copyright (c) 2009, Daniel Erat" (`COPYING:1`, redistribution conditions `COPYING:5`); the per-file header is `xsettingsd.cc:1`. The SPDX identifier was not confirmed (UNVERIFIED). Scope: whole repo. The README only redirects to `https://codeberg.org/derat/xsettingsd` (`README.md:1`); the man pages and sources are the reference.
Id prefix: XS.

## 1. Purpose and shape
- XS1.1 A daemon that owns the `_XSETTINGS_S<screen>` selection and publishes settings to X11 clients through the XSETTINGS protocol. It "can serve as an alternative to gnome-settings-daemon for GTK+ applications". `xsettingsd.1` (DESCRIPTION, lines 11-14). Language: C++. Version: `CMakeLists.txt:4` declares `VERSION 1.0.2`; languages: `CXX` only (`CMakeLists.txt:7`).
- XS1.2 Also builds `dump_xsettings`, a client that prints the current settings in the daemon's config format. `dump_xsettings.cc`, `dump_xsettings.1`. Running it while another XSETTINGS manager exists prints that manager's settings (`xsettingsd.1:32-34`).
- XS1.3 Top-level layout:
  - `xsettingsd.cc`: `main`, option parsing, config path selection, X11 setup (`:28` GetFirstReadablePath, `:93-99`).
  - `common.cc`, `common.h`: default config path search (`common.cc:62`).
  - `config_parser.cc/.h`: parser for the config file (`config_parser.cc:46` Parse).
  - `setting.cc/.h`: typed setting classes (`setting.h:24-28`).
  - `settings_manager.cc/.h`: X11 window and selection handling, property writes, event loop (`settings_manager.cc:32`, `:65`, `:107`, `:250`).
  - `data_reader.cc/.h`, `data_writer.cc/.h`: binary encoding of the XSETTINGS property.
  - `dump_xsettings.cc`: the dumper client.
  - `*_test.cc`: `config_parser_test.cc`, `setting_test.cc`, `common_test.cc`.
  - `xsettingsd.1`, `dump_xsettings.1`: man pages. `xsettingsd.service.in`: systemd user unit template (`:1-3`).
  - `CMakeLists.txt`, `SConstruct`: build files.
- XS1.4 Build: CMake 3.15 minimum (`CMakeLists.txt:1`), with `CTest`. Install rules: binaries to bindir, man pages to mandir, systemd user unit to `lib/systemd/user` (`CMakeLists.txt:32-36`). A second build file `SConstruct` also exists (contents not read).
- XS1.5 Dependency on Xlib and the XSETTINGS spec is implied by the calls (`XInternAtom`, `XGetSelectionOwner`, `XSetSelectionOwner`, `XChangeProperty`). The include and link lines in `CMakeLists.txt` were not read (UNVERIFIED).

## 2. Theme input (how configuration reaches it)
- XS2.1 Config file format: one `Name value` pair per line, `#` comments. Parsed by `ConfigParser::Parse` (`config_parser.cc:46`). Example keys: `Net/ThemeName "Human"`, `Xft/Antialias 1`, `Xft/DPI 100352`, `Xft/HintStyle "hintfull"`, `Xft/Hinting 1`, `Xft/RGBA "none"`, `Xft/lcdfilter "none"`. `xsettingsd.1:39-45`. The man page's example block is the key list; no other key list was found in the code (UNVERIFIED).
- XS2.2 Value types are chosen by the first character of the value: a digit or `-` gives an integer, `"` gives a string, `(` gives a color (`config_parser.cc:288-310`; integer at `:296`, string at `:297-301`, color at `:306`). Invalid start characters are an error (`:308-310`).
- XS2.3 Default config file search order (`common.cc:62-90`):
  1. `$HOME/.xsettingsd` (`:66-67`).
  2. `$XDG_CONFIG_HOME/xsettingsd/xsettingsd.conf`, or `$HOME/.config/...` when `XDG_CONFIG_HOME` is unset or empty (`:73-77`).
  3. Each entry of `$XDG_CONFIG_DIRS` (colon-separated), or `/etc` if the variable is unset (`:80-85`), each with `/xsettingsd/xsettingsd.conf` appended (`:89`).
  The first readable path is chosen by `GetFirstReadablePath` (`xsettingsd.cc:28`, call at `:83`).
- XS2.4 Command-line: `-c` / `--config=FILE` overrides the search (`xsettingsd.cc:66`; man page `xsettingsd.1:21-22`).
- XS2.5 Environment variables read: `HOME`, `XDG_CONFIG_HOME`, `XDG_CONFIG_DIRS` (`common.cc:66`, `:73`, `:80`). No other environment variable was located.
- XS2.6 Reload: `SIGHUP` is caught by `HandleSignal` (`xsettingsd.cc:23`, registration at `:99`). The event loop comments that SIGHUP interrupts `select()` with EINTR to reload the config (`settings_manager.cc:113-114`). The reload entry point is `SettingsManager::LoadConfig` (`settings_manager.cc:48-51`), which increments `serial_` (`:56`).
- XS2.7 No gsettings, portal, kdeglobals, or GTK settings.ini reads exist in this repo. Any such bridge is outside it (UNVERIFIED: only the files listed in XS1.3 were searched).

## 3. Color and style model
- XS3.1 Setting types, `enum Type` in `setting.h:24-28`: `TYPE_INTEGER = 0`, `TYPE_STRING = 1`, `TYPE_COLOR = 2`.
- XS3.2 Classes: `IntegerSetting` (`setting.h:64`), `StringSetting` (`setting.h:87`), `ColorSetting` (`setting.h:105`). The base is `Setting` (`setting.h:22`). `SettingsMap` holds them by name (`setting.h:137`).
- XS3.3 Color values are four 16-bit channels: `ColorSetting(red, green, blue, alpha)` (`config_parser.cc:306`; parse via `ReadColor`, `:304`, defined at `config_parser.cc:412`). Serialized by `ColorSetting::WriteBody` (`setting.cc:62`). Syntax of the color literal was not read beyond the error text at `config_parser.cc:438-444` (UNVERIFIED).
- XS3.4 No color derivation (lighten, darken, mix), no light or dark logic, and no per-state handling exist in this codebase. The daemon publishes the values it reads. This is a fact from the file list (XS1.3); no such function names were found in the search.
- XS3.5 Font, DPI and hinting are integer or string settings (`xsettingsd.1:40-45`). No metric or scaling logic was found beyond storing the value.

## 4. Output and rendering path
- XS4.1 Input to output, in order:
  1. Config file is read and parsed into a `SettingsMap` (`settings_manager.cc:48-51`, `config_parser.cc:46`).
  2. X11 init: `InitX11(screen, true)` is called from `main` (`xsettingsd.cc:96`), which creates the manager window and the `_XSETTINGS_S<screen>` selection (`settings_manager.cc:289-307`, `:65` InitX11).
  3. Ownership: `XSetSelectionOwner` on the selection atom (`settings_manager.cc:307`), then a `MANAGER` client message is sent to the root window (`:330-332`) so clients learn of the new owner.
  4. The settings are written into the `_XSETTINGS_SETTINGS` property on the manager window (atom `settings_manager.cc:73`; write `:250` WriteProperty; `:256` writes `serial_` as a 32-bit integer). The property is set by `XChangeProperty` (`:269`).
  5. Clients read the property and react to property-change notifications. Client-side behaviour is outside this repo.
- XS4.2 Event loop: `RunEventLoop` (`settings_manager.cc:107`) drains X events with `XPending`/`XNextEvent` (`:115-117`) and switches on event type, including `MappingNotify` (`:120`).
- XS4.3 Replace behaviour: `ManageScreen(..., replace_existing_manager)` is called with `true` from `main` (`xsettingsd.cc:98`, value from `:96`). Whether a previous owner is replaced is decided in `ManageScreen` (`settings_manager.cc:279`; full logic not read).
- XS4.4 The XSETTINGS property is bounded: `kMaxPropertySize = (2 << 15)` (`settings_manager.cc:30`).

## 5. Extension and integration points
- XS5.1 Integration is by file and by X11 selection only. There is no plugin interface, no hook, and no shared library output in this repo. The consumers are X11 clients that read XSETTINGS (GTK 2 and GTK 3 read it; the GTK side is not in this repo).
- XS5.2 Installed paths: binaries to `${CMAKE_INSTALL_BINDIR}` (`CMakeLists.txt:32`), man pages to `${CMAKE_INSTALL_MANDIR}/man1` (`:33`), user unit to `lib/systemd/user` (`:36`).
- XS5.3 Service unit: `xsettingsd.service.in` is configured into `xsettingsd.service` (`CMakeLists.txt:35`). Its ExecStart line is `xsettingsd.service.in:6` (`ExecStart=@CMAKE_INSTALL_FULL_BINDIR@/xsettingsd`). The unit has `PartOf=graphical-session.target` (`xsettingsd.service.in:3`).
- XS5.4 Version and ABI: no library ABI (executables only). X11 protocol coupling through Xlib (XS1.5). No minimum toolkit version is implied by this repo.

## 6. Data and tooling
- XS6.1 Data format: the config file (XS2.1). The on-wire format is the XSETTINGS binary blob written by `data_writer.cc` and read by `data_reader.cc` (names only; their bodies were not read, UNVERIFIED for field layout).
- XS6.2 Tests: `config_parser_test.cc`, `setting_test.cc`, `common_test.cc` (names only; contents not read). CTest is enabled at `CMakeLists.txt:11`.
- XS6.3 Tools: `dump_xsettings` (XS1.2), with man page `dump_xsettings.1`.
- XS6.4 Docs: `xsettingsd.1` (daemon), `dump_xsettings.1`, and `README.md` (redirect only).

## 7. Facts of note
- XS7.1 The README states the project moved to Codeberg (`README.md:1`). The upstream URL in `CMakeLists.txt:6` is `https://github.com/derat/xsettingsd`; the two URLs differ.
- XS7.2 Config path search includes `$HOME/.xsettingsd` as the first candidate (`common.cc:66-67`), before the XDG locations.
- XS7.3 The daemon is single-screen per process: `InitX11(screen, ...)` is given one screen number from `main` (`xsettingsd.cc:96`). Multi-screen handling was not read (UNVERIFIED).
- XS7.4 Parser comments indicate known error paths only (`config_parser.cc:438-444`). No TODO or FIXME was found in the files read beyond the SIGHUP race note at `settings_manager.cc:138`.
- XS7.5 Race note: a TODO says there is a small race condition involving SIGHUP (`settings_manager.cc:138`). The rest of the note was not read (UNVERIFIED).
- XS7.6 License: BSD-style (XS intro). The SPDX identifier was not confirmed.

## 8. Not covered
- `data_reader.cc`, `data_writer.cc` bodies (field layout of the XSETTINGS blob).
- `settings_manager.cc` lines 65-106 and 169-249 (window creation and destroy) and 279-end (ManageScreen body).
- `setting.cc` color parse and `ReadColor` body; the full `config_parser.cc` body (only key dispatch lines were read).
- `xsettingsd.service.in` ExecStart line; `SConstruct` contents; CMake link and include lines beyond the install rules.
- `dump_xsettings.cc` body; test sources.
- No build was run; `refs/` was not modified.
