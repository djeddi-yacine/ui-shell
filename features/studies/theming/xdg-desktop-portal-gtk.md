# xdg-desktop-portal-gtk: GTK backend for xdg-desktop-portal; Settings implementation only (GSettings to portal keys)

Source: refs/xdg-desktop-portal-gtk (shallow clone; commit 5409af7; branch main; date 2026-09-01). License: LGPL-2.1 (`COPYING:1-2`); the source header names Igalia S.L. (2018) and GNOME Foundation (2024) (`src/settings.c:2-3`). Scope: Settings implementation only: `src/settings.c/.h`, `src/meson.build:33-40`, `data/meson.build:33-36`, `data/gtk.portal.in:3`, `meson_options.txt:19-21`. The other portal implementations in this repo (FileChooser, Print, and others) are not studied.
Id prefix: XG.

## 1. Purpose and shape
- XG1.1 A backend that implements `org.freedesktop.impl.portal.Settings` for the GTK desktop, by reading GSettings and turning them into portal values. `src/settings.c:120` (`settings_handle_read_all`), `src/settings.c:185` (`settings_handle_read`). Language: C, GLib/GIO, GSettings. It does not draw anything.
- XG1.2 Process name and bus name: `org.freedesktop.impl.portal.desktop.gtk`, from `data/gtk.portal.in:2`. The backend is a single executable, `xdg-desktop-portal-gtk` (`data/xdg-desktop-portal-gtk.service.in:8-9`).
- XG1.3 Top-level layout (Settings-related):
  - `src/settings.c`: the Settings implementation.
  - `src/settings.h`: header (not read).
  - `src/meson.build`: source list and dependency (`:33-40`; `gsettings-desktop-schemas` at `:35`).
  - `data/gtk.portal.in`: portal registration file. Interfaces line uses the placeholder `@settings_iface@` (`:3`).
  - `data/meson.build`: enables the Settings interface when `get_option('settings').allowed()` (`:34`), adds the XML to the D-Bus list (`:35`), and sets the placeholder (`:36`).
  - `meson_options.txt`: option `settings` of type `feature`, default `auto` (`:19-21`).
  - `COPYING`: LGPL-2.1 text.
- XG1.4 Build system: meson. Declared dependencies in `src/meson.build` (the full list was not read).

## 2. Theme input (how configuration reaches it)
- XG2.1 Input is GSettings, read through `GSettings` objects in a hash table keyed by schema name. Bundle type `SettingsBundle` holds a schema and a settings object (`src/settings.c:44-46`). The bundle keys used are `org.gnome.desktop.interface` (`:96`) and `org.gnome.desktop.a11y.interface` (`:110`).
- XG2.2 Keys read for the appearance namespace:
  - `org.gnome.desktop.interface` `color-scheme` (enum): read at `src/settings.c:99-105` (presence check at `:99`, `g_settings_get_enum` at `:102`).
  - `org.gnome.desktop.a11y.interface` `high-contrast` (boolean): read at `src/settings.c:113-114`.
  - `org.gnome.desktop.interface` `enable-animations` (boolean): read at `src/settings.c:383` (`sync_animations_enabled`, `:378`).
- XG2.3 The presence of each key is checked before use. A missing `color-scheme` maps to value 0 (no preference) (`src/settings.c:99-100`).
- XG2.4 No environment variables, no config files, and no portal-config reads were found in `src/settings.c` (fact of the read ranges; full file not read, UNVERIFIED beyond the cited ranges).
- XG2.5 Dark preference and contrast are not read from settings.ini or kdeglobals. Only GSettings is used (XG2.2).

## 3. Color and style model
- XG3.1 No colors or palettes are produced. The model is the portal's generic variant dict (`a{sa{sv}}`) built by `g_variant_dict_insert_value` (`src/settings.c:171-172`).
- XG3.2 Value mapping for `org.freedesktop.appearance`:
  - `color-scheme` (`u`) = the GSettings enum value cast to uint32 (`get_color_scheme`, `src/settings.c:94-104`).
  - `contrast` (`u`) = 1 when `high-contrast` is true, else 0 (`get_contrast_value`, `src/settings.c:108-117`).
- XG3.3 The enum values are passed through without remapping. GSettings `color-scheme` enum values are assumed to match the portal values 0/1/2 (UNVERIFIED: the enum definition is in the GSettings schema, not in this repo).
- XG3.4 No `accent-color` and no `reduced-motion` keys are produced. A search of `src/settings.c` for `accent` and `reduced` returned no matches (fact of the search).
- XG3.5 No shade derivation, no per-state handling, no backdrop handling in this file.

## 4. Output and rendering path
- XG4.1 Read path for a `ReadAll` on the appearance namespace:
  1. `settings_handle_read_all` (`src/settings.c:120`) checks `namespace_matches ("org.freedesktop.appearance", ...)` (`:166`).
  2. It inserts `color-scheme` (`:171`) and `contrast` (`:172`) into a `GVariantDict`, then adds the namespace to the builder (`:174`).
- XG4.2 Read path for a single key: `settings_handle_read` (`src/settings.c:185`). For `org.freedesktop.appearance`, branch at `:202`; `color-scheme` returned as `(v)` at `:207`; `contrast` at `:210-213`.
- XG4.3 Change path: `on_settings_changed` (`src/settings.c:267`). For `enable-animations` it calls `sync_animations_enabled` (`:276`) and emits `SettingChanged` (`xdp_impl_settings_emit_setting_changed`, `:278`, `:284`, `:292`). The color-scheme and contrast emits are at `:285-286` (appearance) and `:294` (contrast key name).
- XG4.4 The `enable-animations` value is also exported under `org.gnome.desktop.interface` by `ReadAll` (`:146-148`, key list loop) and `Read` (`:221`). Its change emits are at `:352` and `:371-374` (`set_enable_animations`, `:358`).
- XG4.5 Call chain from GSettings to the portal:
  1. GSettings `changed` signal on the bundle (connected in the setup code; the connect call was not read, UNVERIFIED for line).
  2. `on_settings_changed` (`src/settings.c:267`) selects the key.
  3. `xdp_impl_settings_emit_setting_changed` (`:278`, `:284`, `:292`) emits `SettingChanged` on `org.freedesktop.impl.portal.Settings`.
  4. The frontend `xdg-desktop-portal` relays the change (see `xdg-desktop-portal.md`, XP4.2).

## 5. Extension and integration points
- XG5.1 Selection: the registration file sets `UseIn=gnome` (`data/gtk.portal.in:4`). How the frontend matches `UseIn` against `XDG_CURRENT_DESKTOP` was not read in this study (see `xdg-desktop-portal.md`, XP2.3 for the lookup path).
- XG5.2 Interface registration: the `@settings_iface@` placeholder in `data/gtk.portal.in:3` is replaced by `org.freedesktop.impl.portal.Settings;` only when the option is allowed (`data/meson.build:34-36`).
- XG5.3 Build-time switch: `option('settings')` (`meson_options.txt:19-21`), default `auto`, with `src/settings.c` included under `get_option('settings').allowed()` (`src/meson.build:33`).
- XG5.4 Dependencies that matter for this file: GSettings schema library `gsettings-desktop-schemas` (`src/meson.build:35`) and GLib/GIO. The schemas used are the `org.gnome.desktop.interface` and `org.gnome.desktop.a11y.interface` schemas (XG2.2).
- XG5.5 ABI and version coupling: the D-Bus interface version is the one in `org.freedesktop.impl.portal.Settings` from the frontend repo (see `xdg-desktop-portal.md`, XP5.2). No library ABI.
- XG5.6 Install paths: the service file `data/xdg-desktop-portal-gtk.service.in` uses `@libexecdir@` (`:9`), the `.portal` file is registered by meson (exact install rule not read).

## 6. Data and tooling
- XG6.1 Data files: `data/gtk.portal.in` (portal registration), `data/xdg-desktop-portal-gtk.service.in` (D-Bus service), `data/org.freedesktop.impl.portal.desktop.gtk.service.in` (D-Bus service entry, `Name=` at `:2`), `data/xdg-desktop-portal-gtk.desktop.in.in` (`Exec=@libexecdir@/xdg-desktop-portal-gtk`, `:6`).
- XG6.2 Tests: none located for the Settings path in the search (UNVERIFIED: the file list was not exhausted).

## 7. Facts of note
- XG7.1 The backend reads only two GSettings schemas for Settings (XG2.2). It does not read `accent-color` or `reduced-motion`, which are documented in the frontend (`xdg-desktop-portal.md`, XP3.2).
- XG7.2 A missing `high-contrast` key returns `contrast` = 0 (`src/settings.c:113`, `:116`). A missing `color-scheme` key returns 0 (XG2.3).
- XG7.3 `enable-animations` is exported as a Settings key and is not part of the documented standard keys in the frontend (`data/org.freedesktop.portal.Settings.xml`, XP3.2). The frontend documents that implementations may provide undocumented keys.
- XG7.4 License: LGPL-2.1 (`COPYING:1-2`).

## 8. Not covered
- `src/settings.c` body of `settings_init` and the `changed` signal connection (setup code after line 407).
- `src/settings.h`, the other portal implementations, and the full `src/meson.build`.
- Install rules in `data/meson.build` beyond lines 33-36.
- The consumer of the `UseIn` field.
- No build was run; `refs/` was not modified.
