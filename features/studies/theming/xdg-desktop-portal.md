# xdg-desktop-portal: D-Bus frontend that merges Settings from backend implementations (Settings portal only)

Source: refs/xdg-desktop-portal (shallow clone; commit 632a43d; branch main; date 2026-11-12). License: LGPL-2.1-or-later, per-file SPDX (`desktop-portal/settings.c:1`, `data/org.freedesktop.portal.Settings.xml`); license texts in `LICENSES/` (GPL-2.0-or-later, LGPL-2.1-or-later, MIT, LicenseRef-sil-open-font-license-1.1, CC0-1.0). Scope: Settings portal only: `desktop-portal/settings.c/.h`, `data/org.freedesktop.portal.Settings.xml`, `data/org.freedesktop.impl.portal.Settings.xml`, `doc/portals.conf.rst.in`, `tests/test_settings.py`, and the portal-config lookup in `desktop-portal/xdp-portal-config.c` (only the parts that select Settings implementations). The rest of the repo (other portals) is not studied.
Id prefix: XP.

## 1. Purpose and shape
- XP1.1 The frontend service `org.freedesktop.portal.Desktop` exports the Settings interface `org.freedesktop.portal.Settings`. It does not hold values itself; it reads and merges them from backend implementations that export `org.freedesktop.impl.portal.Settings`. `data/org.freedesktop.portal.Settings.xml:61`, `data/org.freedesktop.impl.portal.Settings.xml:62`. Language: C, GLib/GIO, with the Dex futures library ((`dex_await_boxed`, `desktop-portal/settings.c:128`; `dex_await`, `dex_future_allv`, `:380`).
- XP1.2 Settings object: `XdpSettings`, a GObject final type (`desktop-portal/settings.c:32`, `:39`). Created by `xdp_settings_new` (`:337`). Set up by `init_settings` (`:399`), which exports the portal with `xdp_context_take_and_export_portal` (`:422`).
- XP1.3 Top-level layout (Settings-related only):
  - `desktop-portal/settings.c`: the portal implementation (merge, read, changed relay).
  - `desktop-portal/xdp-portal-config.c`: reads `portals.conf` files and finds the Settings backend for the current desktop (`:909-912`).
  - `data/org.freedesktop.portal.Settings.xml`: frontend D-Bus interface with documentation of standard keys.
  - `data/org.freedesktop.impl.portal.Settings.xml`: backend D-Bus interface.
  - `doc/portals.conf.rst.in`: documentation for portal backend selection (not read in detail).
  - `tests/test_settings.py`, `tests/templates/settings.py`: tests (see section 6).
- XP1.4 Build: meson (`meson.build` at repo root; the Settings-specific entries were not searched beyond the file list, UNVERIFIED for the build rule text).

## 2. Theme input (how configuration reaches it)
- XP2.1 Input is not read from files by this service. It asks backends over D-Bus. `ReadAll` calls each impl's `ReadAll` (`desktop-portal/settings.c:128-137`), `Read` and `ReadOne` forward to impls (`:147`, `:189`).
- XP2.2 Backend selection: `init_settings` calls `xdp_portal_config_find_all (config, SETTINGS_DBUS_IMPL_IFACE)` (`desktop-portal/settings.c:408`). Proxies are created by `create_impl_proxies` (`:412`, definition at `:360`). If none can be created, it logs "Not providing Settings portal: No working backend" (`:416`). The service is created with `xdp_settings_new` (`:420`) and exported (`:422`).
- XP2.3 `portals.conf` lookup: directories from `$XDG_CONFIG_HOME`, `$XDG_CONFIG_DIRS`, `$XDG_DATA_HOME`, `$XDG_DATA_DIRS` and `${datadir}` (`desktop-portal/xdp-portal-config.c:332-375`; the `XDG_DATA_HOME` path at `:348`, system data dirs at `:352-355`, datadir at `:363`). The per-desktop file is `<desktop>-portals.conf`, where desktop names come from `XDG_CURRENT_DESKTOP` (`:455-458`, `:121`, `:126-131`, `:136`). The fallback is `portals.conf` (`:475`).
- XP2.4 Environment variable read: `XDG_CURRENT_DESKTOP` (`desktop-portal/xdp-portal-config.c:121`). Other lookups are via GLib (`g_get_system_data_dirs`, `:353`).
- XP2.5 Per-interface selection rule: `xdp_portal_config_find_all` loops over config entries and skips any that prefer `none` for the interface (`desktop-portal/xdp-portal-config.c:909-925`; helper `portal_config_interface_prefers_none` defined at `:640`). Its selection order was not read beyond the first loop (UNVERIFIED for the full order logic).

## 3. Color and style model
- XP3.1 The portal holds no colors or palettes. It stores a generic namespace/key/variant model: `a{sa{sv}}`, a dict of namespace to dict of key to variant. `data/org.freedesktop.portal.Settings.xml:71-74` (ReadAll signature `a{sa{sv}}`). Merged with `GHashTable` keyed by namespace, each value a `GVariantDict` (`desktop-portal/settings.c:46-81`, `merged_to_variant` at `:84-107`).
- XP3.2 Standard keys documented in the frontend interface (`data/org.freedesktop.portal.Settings.xml`):
  - `org.freedesktop.appearance` `color-scheme` (`u`): 0 no preference, 1 prefer dark, 2 prefer light; unknown is 0 (`:22-30`).
  - `org.freedesktop.appearance` `accent-color` (`(ddd)`): sRGB in [0,1]; out-of-range treated as unset (`:33-36`).
  - `org.freedesktop.appearance` `contrast` (`u`): 0 normal, 1 higher contrast (`:39-46`).
  - `org.freedesktop.appearance` `reduced-motion` (`u`): 0 no preference, 1 reduced motion (`:49-56`).
  The document also says implementations may provide other keys, which are undocumented (`:16-18`).
- XP3.3 The portal does not validate or convert these values. It merges variants as received (`desktop-portal/settings.c:75`, `g_variant_dict_insert_value`). The documented semantics are enforced by the backends (section 4 of this study), not here.
- XP3.4 Light and dark: represented only as the `color-scheme` value (XP3.2). No derivation of shades, no per-state handling (hover, pressed, focus) exists in this service (fact of the file read).
- XP3.5 Priority: the merge order is set by `ReadAll`'s loop, which walks impls from the last index to the first (`desktop-portal/settings.c:126`, `size_t j = self->impls->len - i - 1`). Since `merge_impl_settings` overwrites with `g_variant_dict_insert_value` (`:75`), the value from the impl at index 0 is merged last and wins for a shared key. Index order follows the `impl_configs` order from `portals.conf` (XP2.2, UNVERIFIED for the exact ordering in `xdp_portal_config_find_all`).

## 4. Output and rendering path
- XP4.1 The portal's output is D-Bus, not drawing. The call chain for a `ReadAll` from an application:
  1. Application calls `org.freedesktop.portal.Settings.ReadAll` (`data/org.freedesktop.portal.Settings.xml:71`). Handler: `settings_handle_read_all` (`desktop-portal/settings.c:110`).
  2. The handler creates a merged hash table (`:118-119`), then awaits `ReadAll` on each backend proxy in reverse index order (`:126-128`).
  3. Each result is merged with `merge_impl_settings` (`:46`, call at `:135`).
  4. The merged table is converted to `(a{sa{sv}})` (`merged_to_variant`, `:84`) and returned (`:140-141`).
- XP4.2 Change propagation: backends emit `SettingChanged` (`data/org.freedesktop.impl.portal.Settings.xml:100`). The portal's handler `on_impl_settings_changed` re-emits it on the frontend (`desktop-portal/settings.c:266-280`, emit at `:279`).
- XP4.3 Before re-emitting a change, the portal checks higher-priority backends (`desktop-portal/settings.c:240`, comment "Check if any higher priority impl provides this key; suppress if so"). The fiber that performs the check is `settings_changed_fiber` (`:230`). The emit is at `:259`.
- XP4.4 Backend implementations in this family (outside this repo) provide the values. Two sibling repos in this study set show what they read: `xdg-desktop-portal-gtk` (GSettings `org.gnome.desktop.interface` `color-scheme`, and `org.gnome.desktop.a11y.interface` `high-contrast`; see `xdg-desktop-portal-gtk.md`) and `xdg-desktop-portal-gnome` (adds `reduced-motion` and `accent-color`; see `xdg-desktop-portal-gnome.md`).

## 5. Extension and integration points
- XP5.1 Backend discovery: backends register a D-Bus name and interface, and are selected via `portals.conf` (XP2.3). The backend's `.portal` file lists `Interfaces=`, which is read by `xdp_portal_config_find_all` (`desktop-portal/xdp-portal-config.c:909`). The file format is in `doc/portals.conf.rst.in` (not read in detail).
- XP5.2 Backend interface: `org.freedesktop.impl.portal.Settings` at object path `DESKTOP_DBUS_PATH` (`desktop-portal/settings.c:376`, `xdp_dbus_impl_settings_proxy_new_future`). Methods: `ReadAll` (`data/org.freedesktop.impl.portal.Settings.xml:72`), `Read` (`:79`), `ReadOne`; signal `SettingChanged` (`:100`). The backend XML is the contract for implementers.
- XP5.3 Frontend interface versions: the document says it "describes version 2 of this interface" (`data/org.freedesktop.portal.Settings.xml:59`).
- XP5.4 Install locations and generated code: not read (UNVERIFIED).
- XP5.5 Behaviour for missing backends: if the service cannot create any proxy, the Settings portal is not exported (XP2.2).
- XP5.6 No toolkit ABI coupling: the interface is D-Bus; toolkits call it over the bus. GTK and Qt clients are outside this repo.

## 6. Data and tooling
- XP6.1 Interface files: `data/org.freedesktop.portal.Settings.xml` (frontend) and `data/org.freedesktop.impl.portal.Settings.xml` (backend). Both carry LGPL-2.1-or-later SPDX headers (`data/org.freedesktop.impl.portal.Settings.xml:3`).
- XP6.2 Tests: `tests/test_settings.py` (Python D-Bus tests with mocked backends). It builds fixture dictionaries with `org.freedesktop.appearance` keys: `color-scheme` values 1, 2, and 99 (an out-of-range value), `accent-color` as `(0.0, 0.1, 0.33)` and an out-of-range `(11.11, 22.22, 33.33)`, and `contrast` 0 (`tests/test_settings.py:12-41`, `:61-64`). Assertions were not read in full (UNVERIFIED for the expected results).
- XP6.3 Test helper: `tests/templates/settings.py` (contents not read).

## 7. Facts of note
- XP7.1 The portal does not validate values. An out-of-range `color-scheme` (99) is accepted in the test fixture (`tests/test_settings.py:38-41`), so the documented "unknown is 0" rule is the backend's job (XP3.3).
- XP7.2 Failure mode: a `ReadAll` call that fails on one backend logs a warning and continues with the others (`desktop-portal/settings.c:134`, `g_warning ("Failed to ReadAll() from Settings implementation: %s", ...)`).
- XP7.3 The `Read` and `ReadOne` paths use `XDP_SETTINGS` objects; their error-handling branches were not read (UNVERIFIED).
- XP7.4 License: LGPL-2.1-or-later for the Settings sources and interfaces (XP6.1). The LICENSES directory also holds GPL-2.0-or-later and MIT texts for other files in the repo.

## 8. Not covered
- Other portals in the repo (FileChooser, Screenshot, and others).
- `desktop-portal/settings.c` bodies at 147-229 (`settings_handle_read`, `settings_handle_read_one`) and the `on_impl_settings_changed` body beyond the lines cited.
- `desktop-portal/xdp-portal-config.c` ordering logic beyond `find_all` lines 909-925.
- `doc/portals.conf.rst.in` and `tests/test_settings.py` assertions.
- Build rules and install paths in meson files.
- No build was run; `refs/` was not modified.
