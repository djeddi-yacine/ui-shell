# xdg-desktop-portal-gnome: GNOME backend for xdg-desktop-portal; Settings implementation only (GSettings and libadwaita to portal keys)

Source: refs/xdg-desktop-portal-gnome (shallow clone; commit fd1e79f; branch main; date 2026-11-12). License: LGPL-2.1 (`COPYING:1-2`); source header names Igalia S.L. (2018) and GNOME Foundation (2024) (`src/settings.c:2-3`). Scope: Settings implementation only: `src/settings.c`, `src/meson.build` (dependency lines), `data/meson.build:23-28`, `data/gnome.portal.in:3-4`. Filechooser and other implementations in this repo are not studied.
Id prefix: XN.

## 1. Purpose and shape
- XN1.1 A backend that implements `org.freedesktop.impl.portal.Settings` for GNOME. It reads GSettings and converts a few values through libadwaita (accent color). `src/settings.c:212` (`settings_handle_read_all`), `src/settings.c:288` (`settings_handle_read`). Language: C, GLib/GIO, GSettings, libadwaita. Nothing is drawn.
- XN1.2 The Settings sources include the libadwaita dependency: `libadwaita-1` is declared at `src/meson.build:69-70` and listed among the deps at `:91`. GSettings schemas come from `gsettings-desktop-schemas >= 47.alpha` (`src/meson.build:87`).
- XN1.3 Top-level layout (Settings-related):
  - `src/settings.c`: the Settings implementation (`:1-3` headers, `:46-49` bundle type).
  - `src/meson.build`: dependencies (`:69-70` libadwaita, `:87` gsettings-desktop-schemas, `:91` in deps list, `:126` `settings.c` in sources).
  - `data/meson.build`: `org.freedesktop.impl.portal.Settings` in the GNOME interface list (`:23`), and the `PORTALS` placeholder filled from that list (`:28`).
  - `data/gnome.portal.in`: registration; `Interfaces=@PORTALS@;` (`:3`), `UseIn=gnome` (`:4`).
  - `meson_options.txt`, `COPYING`, `README.md`, `NEWS`, `demo/`, `subprojects/`: not read for Settings.
- XN1.4 Build: meson.

## 2. Theme input (how configuration reaches it)
- XN2.1 Input is GSettings. Bundles are stored in a table keyed by schema name (`src/settings.c:46-49`, `SettingsBundle` with `schema` and `settings`). The schemas the code uses:
  - `org.gnome.desktop.interface` (`:99`, `:160`, `:169`, `:238`, `:243`, `:397`, `:405`, `:411`, `:421`, `:449`, `:502`, `:527`).
  - `org.gnome.desktop.a11y.interface` (`:116` high-contrast lookup area; the bundle list at `:446`).
  - `org.gnome.desktop.a11y` (listed at `:445`).
  - `org.gnome.desktop.calendar`, `org.gnome.desktop.input-sources` (listed at `:447-448`, not used in Settings code read).
  The full schema list is at `src/settings.c:445-449`, built in `init_settings_table` (`:441`).
- XN2.2 Keys read:
  - `org.gnome.desktop.interface` `color-scheme` (enum): `src/settings.c:97-105` (presence check `:102`, enum read `:105`).
  - `org.gnome.desktop.a11y.interface` `high-contrast` (boolean): `src/settings.c:111-119` (`get_contrast`, has_key `:116`, read `:117`).
  - `org.gnome.desktop.interface` `reduced-motion` (enum): `src/settings.c:131-137` (`get_reduced_motion_value`, read `:137`). The schema key is read through `g_settings_get_enum` in that function.
  - `org.gnome.desktop.interface` `accent-color` (enum): `src/settings.c:167-173` (`get_accent_color`, switch at `:173`).
  - `org.gnome.desktop.interface` `gtk-theme` (string): `src/settings.c:151-158` (`get_theme_value`), used at `:243-245` and `:340-343`, and in change signals at `:421-422`.
  - `org.gnome.desktop.interface` `enable-animations` (boolean): `src/settings.c:238-239`, `:332-333`, `:397-398`, `:502-503`, `:527-528`.
  - `org.gnome.fontconfig` namespace: `src/settings.c:257` (ReadAll branch).
- XN2.3 Environment variables and config files: none read in the Settings code (fact of the ranges read; not exhaustive, UNVERIFIED).

## 3. Color and style model
- XN3.1 No palette is produced. Values are variants in a generic dict. Appearance values:
  - `color-scheme` (`u`): the GSettings enum cast to uint32 (`get_color_scheme`, `src/settings.c:97-108`).
  - `contrast` (`u`): 1 if `high-contrast` is true, else 0 (`get_contrast`, `:111-121`; `get_contrast_value`, `:123-128`).
  - `reduced-motion` (`u`): from GSettings enum `reduced-motion` (`get_reduced_motion_value`, `:130-148`). If the key is absent, the function returns 0 (UNVERIFIED: the exact return line was not read).
  - `accent-color` (`(ddd)`): RGB triple (`get_accent_color`, `:167-209`). The GSettings enum `accent-color` is mapped to a libadwaita accent (`ADW_ACCENT_COLOR_*`) through a switch (`:173-203`): BLUE, TEAL, GREEN, YELLOW, ORANGE, RED, PINK, PURPLE, SLATE; the `default` label maps to BLUE (`:202-203`). The result is converted with `adw_accent_color_to_rgba` (`:206`) and returned as `(ddd)` from `color_rgba.red/green/blue` (`:208`).
- XN3.2 Contrast override of theme: when `high-contrast` is on, `get_theme_value` returns the string `HighContrast` instead of the GSettings theme name (`src/settings.c:157-158`).
- XN3.3 Color mapping is by fixed switch statement (XN3.1). The accent palette values are those in libadwaita (`adw_accent_color_to_rgba`, external library, not in this repo).
- XN3.4 Light and dark: only the `color-scheme` enum value is passed (XN3.1). No shade derivation, no per-state handling (hover, pressed, focus, backdrop) in this file.

## 4. Output and rendering path
- XN4.1 ReadAll on the appearance namespace: `settings_handle_read_all` (`src/settings.c:212`) calls `namespace_matches` (`:267`), then inserts `color-scheme` (`:272`), `contrast` (`:273`), `accent-color` (`:274`) and `reduced-motion` (`:275`) into the dict, and returns the namespace in the builder.
- XN4.2 Read on a single key: `settings_handle_read` (`src/settings.c:288`). Appearance branch returns `(v)` values: `color-scheme` (`:310`), `contrast` (`:316`), `accent-color` (`:322`), `reduced-motion` (`:328`). `org.gnome.desktop.interface` branch handles `enable-animations` (`:332-333`) and `gtk-theme` (`:339-343`).
- XN4.3 Change path: `on_settings_changed` (`src/settings.c:390`) runs for each subscribed key. It emits `SettingChanged` for `enable-animations` (`:397-398`), for `color-scheme` (`:405-409`, call `get_color_scheme` at `:409`), for `accent-color` (`:411-415`), and for `gtk-theme` (`:421-422`). `reduced-motion` emit is at `:437`. The emit call is `xdp_impl_settings_emit_setting_changed` (not separately numbered in this pass; its presence at each branch is verified by the `g_variant_new_variant` lines).
- XN4.4 Animations: `set_enable_animations` (`src/settings.c:499`) and `sync_animations_enabled` (`:519`) read `enable-animations` from GSettings (`:527-528`). `animations_enabled_changed` (`:535`) receives a callback from `ShellIntrospect` (the GNOME Shell introspection interface, outside this repo).
- XN4.5 Font: `fontconfig_changed` (`src/settings.c:483`) handles a `FcMonitor` change event for `org.gnome.fontconfig` (the namespace reported at `:257`).
- XN4.6 Call chain for a color-scheme change:
  1. GSettings `changed` for `color-scheme` on `org.gnome.desktop.interface`.
  2. `on_settings_changed` (`src/settings.c:390`) matches the namespace and key.
  3. `get_color_scheme` (`:97`) reads the enum.
  4. `xdp_impl_settings_emit_setting_changed` emits `SettingChanged` on `org.freedesktop.impl.portal.Settings` with `g_variant_new_variant` (`:409`).
  5. The frontend relays the change (see `xdg-desktop-portal.md`, XP4.2).

## 5. Extension and integration points
- XN5.1 Selection: `data/gnome.portal.in:4` sets `UseIn=gnome`. The list of interfaces is built from `gnome_portal_interfaces` (`data/meson.build:7-23`, Settings at `:23`) and substituted into `Interfaces=` (`data/meson.build:28`; `data/gnome.portal.in:3`).
- XN5.2 Shell coupling: `ShellIntrospect` is used for the animations setting (`src/settings.c:535`). The introspection interface is provided by GNOME Shell and is outside this repo (UNVERIFIED: the D-Bus name and methods were not read).
- XN5.3 libadwaita coupling: the accent code depends on `adw_accent_color_to_rgba` (`src/settings.c:206`) and on libadwaita's accent enum names (`ADW_ACCENT_COLOR_*`, `:173-204`). The libadwaita version was not pinned in the code read (`src/meson.build:69-70` has a dependency name; the version string was not read).
- XN5.4 GSettings schema version: `gsettings-desktop-schemas >= 47.alpha` (`src/meson.build:87`). This is the minimum declared in this repo.
- XN5.5 Interface version: the frontend version rules apply (see `xdg-desktop-portal.md`, XP5.3).

## 6. Data and tooling
- XN6.1 Data files: `data/gnome.portal.in` (portal registration, `:3-4`), `data/meson.build` (interface list `:7-28`).
- XN6.2 Tests and demos: `demo/` exists in the tree (contents not read). No Settings test file was located in the search (UNVERIFIED).
- XN6.3 Translations: `po/` (not read).

## 7. Facts of note
- XN7.1 `accent-color` is derived, not read as a color: the enum (`accent-color`) is mapped to a fixed libadwaita accent (XN3.1). An unknown enum value maps to BLUE (`src/settings.c:202-203`).
- XN7.2 When high contrast is on, the GTK theme name returned is the string `HighContrast` (XN3.2), not the GSettings `gtk-theme` value.
- XN7.3 Reduced motion and high contrast are exported as separate keys (`reduced-motion` and `contrast`) (XN3.1).
- XN7.4 License: LGPL-2.1 (`COPYING:1-2`).

## 8. Not covered
- `src/settings.c` lines 41-96 (bundle helpers and `namespace_matches` body beyond line 70), 441-482 (table init body beyond the schema list), 542-end (`settings_init`).
- `ShellIntrospect` interface and its D-Bus definitions.
- `data/meson.build` lines before 7 and install rules.
- `demo/`, `po/`, and `subprojects/` contents.
- No build was run; `refs/` was not modified.
