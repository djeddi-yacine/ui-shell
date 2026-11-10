# Clipboard managers: DankMaterialShell, Ambxst, noctalia, omarchy, dots-hyprland

Study of clipboard history managers in the reference shells under `refs/`. Facts only, with file citations. Paths are relative to `refs/` in the repository root unless absolute. Line numbers refer to the files as checked out. No decisions are recorded here. No program was run and no network command was used.

`refs/quickshell` has no clipboard manager: it exposes a single text property and no history, so it is recorded as a baseline column (section 6) rather than as another manager. Id prefixes: `DM` = DankMaterialShell, `AX` = Ambxst, `NC` = noctalia, `OM` = omarchy, `DH` = dots-hyprland, `QS` = quickshell.

Checkout note: an earlier reading of this checkout found `refs/dots-hyprland/dots/` empty. It is populated now (`.config/quickshell/ii`), so section 5 records the real QML side and the `dots-extra/fedora/` startup file beside it. Section 5 replaces the earlier "not in this tree" reading of that reference.

---

## 1. DankMaterialShell (DM)

Clipboard manager lives in the Go core (`core/internal/server/clipboard`), with the CLI in `core/cmd/dms/commands_clipboard.go` and the UI in `quickshell/Modals/Clipboard/`.

### 1.1 Capture

- **DM1.1** A `Manager` binds `ext_data_control_manager_v1`, `wl_seat` and `zwp_virtual_keyboard_manager_v1` from the registry. `core/internal/server/clipboard/manager.go` 224-260.
- **DM1.2** Manager construction fails when `ext_data_control_manager_v1` is absent or no seat is bound; there is no `wlr-data-control` fallback. `manager.go` 262-272.
- **DM1.3** The manager runs inside the `dms` server process alongside the IPC socket, and its construction is optional: the `clipboard` capability is only advertised when it exists. `core/internal/server/server.go` 288-306, 470-471.
- **DM1.4** The watcher is the data-device selection handler. The first selection event is consumed as initial state and not stored. `manager.go` 304-310.
- **DM1.5** Selections owned by the manager itself are ignored (no self-echo). `manager.go` 312-325.
- **DM1.6** The advertised MIME list is collected per offer in `setupDataDeviceSync`. `manager.go` 286-300.
- **DM1.7** Content is read through a pipe with the configured entry-size cap and a read timeout (`readPipeTimeout`). `manager.go` 443-470.
- **DM1.8** `dms cl watch` is a separate, server-free watcher with the same behaviour as `wl-paste --watch`: `--store` writes to history, `--mimes` prints every offered type, a trailing command receives content on stdin. `core/cmd/dms/commands_clipboard.go` 76-90, 335-406.
- **DM1.9** `dms cl copy` works with no server by re-execing itself as the selection owner (`_DMS_CLIPBOARD_SERVE` child, cache file, ready byte on stdout). `core/internal/clipboard/clipboard.go` 18-56, 105-159.
- **DM1.10** Preference order when capturing: `text/uri-list`, png, jpeg, gif, bmp, tiff, `text/plain;charset=utf-8`, `text/plain`, `UTF8_STRING`, `STRING`, `TEXT`, then the first offered type except `application/vnd.portal.filetransfer`. `manager.go` 746-779.

### 1.2 Storage

- **DM2.1** bbolt database at `$XDG_CACHE_HOME/DankMaterialShell/clipboard/db`; the older `dms-clipboard/db` is renamed in place on first use. `core/internal/clipboard/store.go` 122-157.
- **DM2.2** Entry struct: id, data, mime, preview, size, timestamp, isImage, hash, pinned, optional alt payload. `store.go` 35-44; `core/internal/server/clipboard/types.go` 99-111.
- **DM2.3** Binary record encoding, one key per auto-increment id. `store.go` 187-213.
- **DM2.4** Defaults: 100 entries, 5 MiB per entry, auto-clear 0 days, clear-at-startup false, 25 pinned. `types.go` 28-37.
- **DM2.5** Entries larger than the cap are rejected, not truncated. `store.go` 62-64; `manager.go` 460-470.
- **DM2.6** Dedup: FNV-1a 64 hash of the payload; older entries with the same hash are deleted, pinned entries are exempt, then the new copy is inserted with a new id. `store.go` 159-170, 215-219; `manager.go` 554-568.
- **DM2.7** Trimming keeps the newest `maxHistory` unpinned entries and never drops pinned ones. `manager.go` 571-590.
- **DM2.8** Age expiry only runs at startup (`autoClearDays > 0`) and on demand; there is no timer. `manager.go` 93-104, 1545-1576.
- **DM2.9** `clearAtStartup` wipes history during construction. `manager.go` 93-96.
- **DM2.10** Pin cap is enforced on `pinEntry` with "maximum pinned entries reached". `manager.go` 1850-1910.
- **DM2.11** The store is opened with a 1 s lock timeout by both the CLI store path and the manager. `store.go` 71-75; `manager.go` 177-182.
- **DM2.12** Text preview is whitespace-collapsed and cut at 100 chars; image preview is a text marker such as `[[ image 2 MiB png 1920x1080 ]]`. `store.go` 228-245.

### 1.3 Content types

- **DM3.1** Images are additionally read as text when the selection offers text and not `x-special/gnome-copied-files`; both representations are stored (alt payload) and both are re-offered on paste. `manager.go` 365-395, 1365-1443.
- **DM3.2** Files are copied as three offers: `x-special/gnome-copied-files`, `text/uri-list`, plain path, plus the image bytes when decodable. `core/internal/clipboard/clipboard.go` 92-103.
- **DM3.3** A file over the size cap is stored as its encoded URI instead of its body. `manager.go` 2210-2224.
- **DM3.4** No `text/html` handling is present in the capture path. `manager.go` 746-760.
- **DM3.5** `dms cl copy --type` and `--type __multi__` accept arbitrary MIME types and multi-offer payloads. `commands_clipboard.go` 199-204, 264-273, 287-319.

### 1.4 UI

- **DM4.1** A modal or popout hosts two tabs, "recents" (unpinned) and "saved" (pinned). `quickshell/Modals/Clipboard/ClipboardContent.qml` 96-108, 239; `ClipboardActions.qml` 22-27.
- **DM4.2** Search field plus a type filter menu (All, Text, Long Text, Image). `ClipboardContent.qml` 19-20, 149, 177-215.
- **DM4.3** Filtering is done in QML over preview text and the active type filter. `quickshell/Services/ClipboardService.qml` 107-142.
- **DM4.4** Image rows show an asynchronous 128 px thumbnail loaded as a data URL, with a load queue. `ClipboardThumbnail.qml` 23-45, 64-83.
- **DM4.5** A separate preview overlay shows the full image; wheel events are swallowed, so there is no zoom. `ClipboardImagePreview.qml` 13-34, 74-95.
- **DM4.6** Text entries can be edited in a full text editor and saved back. `ClipboardEditor.qml` 17-40, 90-120; `ClipboardService.qml` 350-376.
- **DM4.7** Row actions are preview, copy, paste, pin/unpin, edit, delete, filtered by the `clipboardVisibleEntryActions` setting (default `pin`, `edit`, `delete`). `ClipboardEntry.qml` 26-31, 60-110.
- **DM4.8** Clearing filters to the visible list when a search or type filter is active and asks for confirmation; pinned entries are kept. `ClipboardHistoryContent.qml` 33, 180-190; `ClipboardActions.qml` 56-60.
- **DM4.9** Deleting a pinned entry asks for confirmation; deleting an unpinned one does not. `ClipboardService.qml` 284-322.
- **DM4.10** Keyboard flow: arrows/Tab move, `Ctrl+N/J` and `Ctrl+P/K` move, `Ctrl+C` copy, `Ctrl+S` pin, `Ctrl+E` edit, `Ctrl+Space` preview, `Ctrl+F10` hint panel, `Delete` delete, `Shift+Delete` clear, Enter copies or pastes depending on `clipboardEnterToPaste`. `ClipboardKeyboardController.qml` 86-118, 188-278.
- **DM4.11** The hint strip lists Navigate, Copy, Paste, Preview, Edit, Pin, Delete. `ClipboardKeyboardHints.qml` 20-60.
- **DM4.12** Window size follows `clipboardSize` and is clamped to the screen. `ClipboardHistoryModal.qml` 76-77.
- **DM4.13** On open the search field is cleared and focused, and history is refetched. `ClipboardHistoryModal.qml` 14-42.

### 1.5 Paste path

- **DM5.1** Copying an entry is `clipboard.copyEntry`; the manager becomes selection owner for the stored payload plus its alt payload. `ClipboardService.qml` 231-247; `manager.go` 1365-1443.
- **DM5.2** Paste = copy entry, close the UI, then synthesize Ctrl+V or Ctrl+Shift+V through `zwp_virtual_keyboard_v1` using the seat's own keymap. `ClipboardService.qml` 258-283; `core/internal/clipboard/pastekey.go` 23-45.
- **DM5.3** Terminal targets get Ctrl+Shift+V, detected by a hardcoded app-id list plus `term`/`terminal` substrings. `ClipboardService.qml` 21, 84-92, 97-105.
- **DM5.4** Paste availability requires `zwp_virtual_keyboard_manager_v1`; without it the UI falls back to copy. `manager.go` 254-256; `ClipboardService.qml` 18-19, 72-83.
- **DM5.5** CLI paste prints the current selection to stdout without the server. `commands_clipboard.go` 321-327.

### 1.6 Privacy

- **DM6.1** A selection that advertises `x-kde-passwordManagerHint` is skipped before any read, so nothing is stored and history is not touched. `manager.go` 44-47, 344-346, 740-744.
- **DM6.2** No per-entry incognito mode, pause button, or per-application exclusion was found.
- **DM6.3** Tracking can be switched off entirely through the `disabled` config field (`dms cl config set --disable`); copy/paste keep working. `types.go` 19-27; `commands_clipboard.go` 217-222, 718-761; `manager.go` 66-68, 1339-1352.
- **DM6.4** The database is plain bbolt, not encrypted; directory mode is 0700 and file mode 0644. `store.go` 71, 143-155.

### 1.7 Config

- **DM7.1** JSON at `$XDG_CONFIG_HOME/DankMaterialShell/clsettings.json` with `maxHistory`, `maxEntrySize`, `autoClearDays`, `clearAtStartup`, `disabled`, `maxPinned`. `types.go` 19-46.
- **DM7.2** The file is watched with fsnotify and reloaded live. `manager.go` 1735-1775.
- **DM7.3** UI settings: Enabled, Maximum entries, Maximum entry size, Auto-clear after, Maximum pinned entries, Clear at startup, plus behaviour and appearance keys (click to paste, enter to paste, size, remember type filter, overlay layer, visible entry actions). `quickshell/Modules/Settings/ClipboardTab.qml` 270-420, 429-520.
- **DM7.4** Appearance and behaviour keys are declared in `quickshell/Common/SettingsData.qml` 116-122.

### 1.8 IPC and CLI

- **DM8.1** Unix-socket JSON methods: `clipboard.getState`, `getHistory`, `getEntry`, `deleteEntry`, `deleteEntries`, `clearHistory`, `copy`, `copyEntry`, `paste`, `sendPaste`, `pasteSupported`, `subscribe`, `search`, `getConfig`, `setConfig`, `store`, `pinEntry`, `unpinEntry`, `editEntry`, `getPinnedEntries`, `getPinnedCount`, `copyFile`. `core/internal/server/clipboard/handlers.go` 17-59.
- **DM8.2** Subscriptions stream `State` (enabled, history, current) to QML clients. `core/internal/server/clipboard/types.go` 113-195; `manager.go` 928-960; `server.go` 730-734.
- **DM8.3** Socket line size is raised to 64 MiB for large payloads. `server.go` 923.
- **DM8.4** CLI: `dms clipboard` (alias `cl`) with `copy`, `paste`, `send-paste`, `watch`, `history`, `get`, `delete`, `clear`, `search`, `config get|set`, `export`, `import`, `cliphist-migrate`. `commands_clipboard.go` 38-233.
- **DM8.5** `cliphist-migrate` reads the cliphist bolt bucket `b`, stores each value, and optionally deletes the DB. `commands_clipboard.go` 835-893.

### 1.9 Failure handling

- **DM9.1** Bolt open and update are wrapped in a panic guard that turns a panicking DB into an error. `manager.go` 164-182; `store.go` 50-57.
- **DM9.2** A selection taken while tracking is disabled returns `errSelectionUnavailable` instead of writing history. `manager.go` 1339-1352.
- **DM9.3** History-store writes report errors up (`dbUpdate`), and the CLI store path logs `store: %v` per change without stopping the watcher. `commands_clipboard.go` 353-360.
- **DM9.4** UI errors surface as toasts ("Paste failed: %1", "Failed to copy entry"). `ClipboardService.qml` 97-105, 231-247.
- **DM9.5** Read timeouts and oversize payloads drop the capture silently. `manager.go` 443-470.

---

## 2. Ambxst (AX)

Clipboard is split between the Go daemon (`backend/pkg/svc/clipboard`), an IPC service, and the dashboard tab (`modules/widgets/dashboard/clipboard/`).

### 2.1 Capture

- **AX1.1** A persistent `zwlr_data_control_manager_v1` client in the daemon watches the selection; the daemon is the single selection owner. `backend/pkg/svc/clipboard/wayland.go` 28-45; `backend/pkg/daemon/daemon.go` 160-162.
- **AX1.2** The watcher starts lazily on the first IPC subscriber, not at boot. `backend/pkg/svc/clipboard/service.go` 134-154.
- **AX1.3** Primary selection is tracked separately and ignored for history. `wayland.go` 282-296.
- **AX1.4** Capture picks `text/uri-list`, else the first `image/*`, else `text/plain;charset=utf-8`, else `text/plain`. `wayland.go` 522-544.
- **AX1.5** The pipe is read off the event loop with a 5 s deadline and a 64 MiB cap; CR bytes are stripped from non-file, non-image payloads. `wayland.go` 23-25, 321-370, 505-520.
- **AX1.6** A newer capture invalidates an in-flight read by sequence number; stale reads are dropped. `wayland.go` 344-355.
- **AX1.7** After insert the daemon pushes `clipboard.refresh` to subscribers. `wayland.go` 366-368.

### 2.2 Storage

- **AX2.1** Two SQLite databases: pinned at `$XDG_DATA_HOME/.../clipboard-pinned.db`, unpinned at `clipboard-unpinned.db`, or on tmpfs at `$XDG_RUNTIME_DIR/ambxst/clipboard-unpinned.db`. `backend/pkg/paths/paths.go` 92-107.
- **AX2.2** Both are opened through the SQLite adiantum VFS with a 32-byte random key stored at `$XDG_STATE_HOME/.../clipboard.key` (0600, dir 0700). `backend/pkg/svc/clipboard/store.go` 160-207; `paths.go` 109-118.
- **AX2.3** Schema: `clipboard_items` with content_hash unique, mime_type, preview, full_content, is_image, size, pinned, display_index, alias, mimes JSON, timestamps, plus an FTS5 index and sync triggers. `store.go` 32-57.
- **AX2.4** The old plaintext `clipboard.db` is migrated into the encrypted stores and removed. `store.go` 385-430; `paths.go` 84-90.
- **AX2.5** Fixed cap of 50 unpinned entries; pinned entries are unbounded and exempt. `store.go` 27, 715-760.
- **AX2.6** No per-entry byte limit in the store; the only bound is the 64 MiB capture cap. `wayland.go` 24, 348.
- **AX2.7** Dedup is by MD5 content hash: `ON CONFLICT` bumps the existing row to the top, and content already pinned is not inserted again. `store.go` 715-760.
- **AX2.8** The tmpfs toggle moves the unpinned rows to the runtime DB and back; pinned stay in the data dir. `store.go` 317-334.
- **AX2.9** No age-based expiry or TTL was found. `store.go` (whole file); `service.go` 231-247.
- **AX2.10** Preview is 100 chars of text or the literal `[Image]`. `store.go` 810-818.
- **AX2.11** Image blobs are materialised to a tmpfs cache directory for QML file URIs, plus an in-memory data-URL cache. `service.go` 408-487; `paths.go` 114-121.

### 2.3 Content types

- **AX3.1** Captured: text (plain attached first), images (`image/*`), and files via `text/uri-list`. `wayland.go` 522-544.
- **AX3.2** Every advertised MIME type is stored as a JSON list alongside the item. `store.go` 735-745; `service.go` 482-499.
- **AX3.3** The UI classifies by MIME for icons: `text/*`, json/xml/js, `text/uri-list` (file), `image/*`, video, audio, archives, pdf. `modules/widgets/dashboard/clipboard/clipboard_utils.js` 3-55.
- **AX3.4** No `text/html` handling was found. `wayland.go` 522-544.
- **AX3.5** On copy, the stored MIME can be overridden by the caller (`copy` takes a `mime` parameter). `service.go` 329-355.

### 2.4 UI

- **AX4.1** The UI is a dashboard tab with a search/list column and a preview column. `modules/widgets/dashboard/clipboard/ClipboardTab.qml` 34-35, 685-700; `ClipboardPreview.qml` 11-30.
- **AX4.2** Search is a case-insensitive substring match over preview and alias, done client-side. `ClipboardTab.qml` 417-424.
- **AX4.3** Click copies the entry and closes the dashboard; long-press (800 ms) does the same. `ClipboardTab.qml` 1206-1208, 1640-1650.
- **AX4.4** Row context actions: copy, pin/unpin, delete, set alias; drag reorders within a pin group. `ClipboardTab.qml` 1700-1760, 1275-1290; `modules/services/ClipboardService.qml` 172-240.
- **AX4.5** Delete is a two-step mode: entering delete mode, arming the row, confirming; Escape cancels. `ClipboardTab.qml` 45-60, 306-330.
- **AX4.6** Alias mode edits a display name without changing content. `ClipboardTab.qml` 338-395.
- **AX4.7** A pin badge marks pinned rows. `ClipboardTab.qml` 2113-2127.
- **AX4.8** Clear has a confirm state and clears unpinned items only. `ClipboardTab.qml` 45-46, 281-300; `backend/pkg/svc/clipboard/store.go` 540-545.
- **AX4.9** Preview shows text, static image, animated gif, file icon, and fetches link previews for URLs. `ClipboardPreview.qml` 33-135; `ClipboardService.qml` 63-82.
- **AX4.10** Keyboard: arrows move, Enter/Space activates, Escape closes or cancels modes, Shift+Tab leaves the list. `ClipboardTab.qml` 2399-2435, 944-960.
- **AX4.11** The launcher exposes the same tab behind a configurable prefix (default `cc`). `modules/widgets/launcher/LauncherView.qml` 90, 289-306; `config/defaults/prefix.js` 4.
- **AX4.12** Opening a file, image or URL from the launcher runs `xdg-open` on the path or URL. `LauncherView.qml` 1217-1240.

### 2.5 Paste path

- **AX5.1** Copying calls the backend `copy` method, which makes the daemon the selection owner; the UI then closes. `modules/services/ClipboardService.qml` 239-247; `backend/pkg/svc/clipboard/service.go` 329-373.
- **AX5.2** No keystroke is synthesized for history entries; only the emoji action copies and then runs `wtype -M ctrl -P v ...`. `service.go` 387-406.
- **AX5.3** Live selection MIME and content can be queried (`liveMimes`, `liveContent`). `service.go` 521-530, 574-594.

### 2.6 Privacy

- **AX6.1** No handling of `x-kde-passwordManagerHint` or any other password-manager hint was found in the repository. `backend/pkg/svc/clipboard/wayland.go` 522-544; `store.go` 715-760.
- **AX6.2** No incognito or pause mode was found. The nearest controls are the tmpfs toggle and the key/file encryption.
- **AX6.3** History at rest is encrypted (adiantum + key file). `store.go` 160-207.
- **AX6.4** The image cache directory is deleted on service construction. `service.go` 37-44.
- **AX6.5** The UI watcher is suspended around sleep/wake. `modules/services/ClipboardService.qml` 23-35.

### 2.7 Config

- **AX7.1** Only one clipboard key exists in the config tree: `system.clipboard.tmpfs` (default false, "unpinned history lives in tmpfs and is wiped on reboot"). `config/defaults/system.js` 48-51; `config/Config.qml` 1055-1059.
- **AX7.2** The toggle is in the dashboard system panel. `modules/widgets/dashboard/controls/SystemPanel.qml` 1065-1071.
- **AX7.3** The default keybind is SUPER+V mapped to `ambxst.clipboard` → `ambxst run clipboard`. `config/Config.qml` 1487-1491, 1576; `config/KeybindActions.js` 35.
- **AX7.4** No config key for history size, entry size or expiry was found; the 50-entry cap is a constant. `store.go` 27.

### 2.8 IPC and CLI

- **AX8.1** JSON-RPC service `clipboard` with methods `list`, `getContent`, `delete`, `clear`, `togglePin`, `setAlias`, `reorder`, `swap`, `copy`, `emojiType`, `dataUrl`, `imagePath`, `clearClipboard`, `setTmpMode`, `check`, `copyText`, `copyData`, `copyFile`, `liveMimes`, `liveContent`, with a subscription channel. `service.go` 75-102.
- **AX8.2** `ambxst run clipboard` opens the dashboard clipboard tab. `config/KeybindActions.js` 35.
- **AX8.3** Error results are returned as `{"error": "..."}` inside successful IPC replies rather than transport failures. `service.go` 170-176, 329-355.

### 2.9 Failure handling

- **AX9.1** Store init failure is cached and returned on every call instead of retried per request. `service.go` 46-63.
- **AX9.2** A missing data-control watcher logs once and disables history while the rest of the daemon keeps running. `service.go` 141-154.
- **AX9.3** Capture read timeouts and over-cap payloads are logged and dropped. `wayland.go` 344-355, 505-520.
- **AX9.4** The store is vacuumed when bloated, off the boot path. `service.go` 65-73; `store.go` 771-790.

---

## 3. noctalia (NC)

Clipboard history is a C++ service in the shell process (`src/wayland/clipboard_service.*`) with a panel (`src/shell/clipboard/`).

### 3.1 Capture

- **NC1.1** One Wayland client binds `ext_data_control_manager_v1` when present, otherwise `zwlr_data_control_manager_v1`; the ops table abstracts both. `src/wayland/wayland_connection.cpp` 1642-1666; `src/wayland/clipboard_service.cpp` 515-523.
- **NC1.2** Reads use non-blocking pipes driven by the shell poll loop, not a thread or a child process. `src/wayland/clipboard_poll_source.h` 1-25; `clipboard_service.cpp` 1303-1340.
- **NC1.3** The poll source advertises an immediate timeout while an orphaned-selection adoption is pending, because a NULL selection leaves no fd to wake on. `clipboard_poll_source.h` 10-13.
- **NC1.4** When the owning app exits, the shell re-claims the selection with the payload it already read ("keep from closed apps"). `clipboard_service.h` 117-122, 171-178; `clipboard_service.cpp` 488-500.
- **NC1.5** That selection backup is capped at 200 MiB and is not subject to the history caps. `clipboard_service.cpp` 45-49, 1055-1065.
- **NC1.6** A payload that looks truncated is discarded (`payloadLooksComplete`). `clipboard_service.h` 197.

### 3.2 Storage

- **NC2.1** Encrypted manifest `index.enc` plus one `entries/<id>.enc` payload per entry under the state dir (`<state>/clipboard`, fallback `/tmp/noctalia-clipboard`). `clipboard_service.cpp` 1956-1976.
- **NC2.2** Payloads are written through `writeEncryptedFile` and read through `readEncryptedFile`; the key comes from `StorageKeyProvider`. `clipboard_service.cpp` 673-690, 1514-1541, 1760-1810.
- **NC2.3** Legacy plaintext `index.json` / `entries/<id>.bin` are migrated and then removed. `clipboard_service.cpp` 1966, 1975, 1528-1530, 1566.
- **NC2.4** Default cap 100 entries, allowed 10-10000 in steps of 10. `src/config/config_limits.h` 7-10; `clipboard_service.cpp` 29-31.
- **NC2.5** Byte budget: 256 MiB total, 4 MiB per text entry, 32 MiB per image entry. `clipboard_service.cpp` 36-44.
- **NC2.6** Trimming drops oldest unpinned entries first, images preferentially; pinned entries neither count toward the budget nor get trimmed. `clipboard_service.cpp` 1827-1877.
- **NC2.7** Dedup compares size then payload plus MIME against the newest unpinned entry and every pinned entry (copying a pinned item must not create a duplicate). `clipboard_service.cpp` 1440-1470.
- **NC2.8** No age-based expiry or TTL was found; only count and byte budget trim. `clipboard_service.cpp` 1827-1877.
- **NC2.9** Text preview is 200 bytes. `clipboard_service.cpp` 47, 2113-2120.
- **NC2.10** Entry ids are `<epoch-ms>-<counter>` and must match `[A-Za-z0-9_-]`, max 128 chars. `clipboard_service.cpp` 1978-1989.
- **NC2.11** Payloads are evicted from memory after a successful persist and reloaded on demand. `clipboard_service.cpp` 1494-1500, 796-818.

### 3.3 Content types

- **NC3.1** Only `text/plain;charset=utf-8`, `text/plain`, `UTF8_STRING`, `image/png`, `image/jpeg`, `image/jxl` are read; text is preferred over image. `clipboard_service.cpp` 55-66, 1991-2005.
- **NC3.2** No `text/uri-list` or file-list capture was found, so a copied file is stored only if the source also offers a plain-text path. `clipboard_service.cpp` 1991-2005.
- **NC3.3** No `text/html` handling was found.
- **NC3.4** Re-offering widens only within text aliases; no MIME is offered that the single stored buffer cannot satisfy. `clipboard_service.cpp` 856-875.

### 3.4 UI

- **NC4.1** The entry point is a bar widget that opens the clipboard panel. `src/shell/bar/widgets/clipboard_widget.cpp` 1-52; `docs/user/bar/widgets/clipboard.mdx` 1-15.
- **NC4.2** Panel has a filter input with a clear button and a filtered index list. `src/shell/clipboard/clipboard_panel.cpp` 640-650, 482-500, 659.
- **NC4.3** Rows show a text preview, or an asynchronous image thumbnail; preview also shows dimensions and "time ago + size". `clipboard_panel.cpp` 251-270, 317-345, 369-380.
- **NC4.4** A pin glyph marks pinned rows. `clipboard_panel.cpp` 306-307, 442-445.
- **NC4.5** Delete is two-step when confirmation is enabled (the default): the first press arms the row's storage id, the second deletes; with confirmation off an unpinned row deletes immediately. `clipboard_panel.cpp` 1386-1400, 1454-1470, 1692-1740.
- **NC4.6** Clear opens an inline confirm panel with "Keep pinned" and "Clear all". `clipboard_panel.cpp` 592-635, 1605-1632.
- **NC4.7** An image action button runs a configured command on the exported image path (e.g. `gimp {path}`), then closes the panel. `clipboard_panel.cpp` 1101-1125, 1635-1660.
- **NC4.8** Keyboard: Up/Down, PageUp/PageDown, activate, Delete; focus is on the filter input when the panel opens. `clipboard_panel.cpp` 1692-1749, 974-990.
- **NC4.9** Panel placement and near-click opening are configurable (`clipboardPlacement`, `clipboardPosition`, `openNearClickClipboard`). `src/config/config_types.h` 1074-1082; `src/config/schema/config_schema.cpp` 1415.

### 3.5 Paste path

- **NC5.1** Activating an entry copies it back to the selection and optionally synthesizes a paste shortcut. `clipboard_panel.cpp` 1664-1692; `src/shell/clipboard/clipboard_paste.cpp` 15-44.
- **NC5.2** Auto-paste modes: `off`, `auto`, `ctrl_v`, `ctrl_shift_v`, `shift_insert`; `auto` uses Ctrl+Shift+V for text and Ctrl+V for images. `clipboard_paste.cpp` 15-29.
- **NC5.3** The keystroke goes through the shell's virtual keyboard service; failure logs "Wayland virtual keyboard unavailable" and the copy still stands. `clipboard_paste.cpp` 33-44.
- **NC5.4** Text-only clipboard access for other shell features goes through the `TextClipboard` interface (`clipboardText`, `setClipboardText`). `clipboard_service.h` 108-110.

### 3.6 Privacy

- **NC6.1** A selection advertising `x-kde-passwordManagerHint` is ignored before reading. `clipboard_service.cpp` 55-77, 1305-1312.
- **NC6.2** The documentation records the caveat that keeping the last selection alive can keep a password-manager secret alive when the app clears by exiting, and that apps not advertising the hint are not covered. `example.toml` 33-38.
- **NC6.3** Disabling history retention keeps only the live selection in memory and persists nothing; the transport stays active so copy/paste still work. `clipboard_service.cpp` 460-486; `clipboard_service.h` 112-114.
- **NC6.4** No incognito mode, timed pause, or per-app exclusion was found.
- **NC6.5** Persistence is encrypted at rest. `clipboard_service.cpp` 1514-1541, 1760-1810.

### 3.7 Config

- **NC7.1** Shell keys: `clipboard_enabled`, `clipboard_keep_from_closed_apps`, `clipboard_history_max_entries` (10-10000), `clipboard_confirm_clear_history`, `clipboard_auto_paste`, `clipboard_image_action_command`. `src/config/config_types.h` 1269-1283; `example.toml` 29-41.
- **NC7.2** All are exposed in the settings window with storage-state messaging. `src/shell/settings/settings_registry.cpp` 1952-2000; `src/shell/settings/settings_window_scene.cpp` 1690-1740.
- **NC7.3** `clipboard_confirm_clear_history` gates both clear and delete confirmations. `config_types.h` 1276-1277; `clipboard_panel.cpp` 1612-1632.

### 3.8 IPC and CLI

- **NC8.1** `noctalia msg clipboard-clear` clears unpinned history ("with nothing pinned this clears the whole history"). `src/app/application_ipc.cpp` 394-399; `src/cli/schema_msg.h` 350.
- **NC8.2** `noctalia msg clipboard-copy <text>` sets the selection; `clipboard-text` returns the payload with no trailing newline. `application_ipc.cpp` 400-414; `schema_msg.h` 351-355.
- **NC8.3** No IPC for pin, delete, search, or entry listing was found.
- **NC8.4** The docs document only `noctalia msg clipboard-clear`. `docs/user/bar/widgets/clipboard.mdx` 21-25.

### 3.9 Failure handling

- **NC9.1** Persistence is a state machine: Opening, Ready, Unavailable, Cancelled, DeniedOrLocked, MissingKey, RecoveryRequired, BackendError. `clipboard_service.h` 23-32.
- **NC9.2** `retryPersistence` and `clearEncryptedPersistenceForRecovery` exist for key/recovery failures. `clipboard_service.h` 99-102; `clipboard_service.cpp` 630-665.
- **NC9.3** The settings row shows the current storage state and a recovery action. `settings_window_scene.cpp` 1690-1740.
- **NC9.4** Read failures keep the previous history; payloads that fail to load are evicted rather than crashing the list. `clipboard_service.h` 103-107, 211-213.

---

## 4. omarchy (OM)

Clipboard history is a first-party Quickshell plugin: a QML overlay (`shell/plugins/clipboard/Clipboard.qml`), a JS history module (`ClipboardHistory.js`), and a shell script that does the capturing (`capture.sh`). The plugin spawns its own `wl-paste --watch` processes.

### 4.1 Capture

- **OM1.1** A first-party `overlay` plugin with `keepLoaded: true`, entry point `Clipboard.qml`; first-party non-bar plugins are enabled unless listed in `disabledPlugins[]`. `shell/plugins/clipboard/manifest.json` 1-15; `shell/plugins/README.md` 1-10, 19.
- **OM1.2** Two watchers run under `setpriv --pdeathsig TERM`: `wl-paste --type text --watch capture.sh text` and `wl-paste --type image/png --watch capture.sh image/png`. `Clipboard.qml` 284-300.
- **OM1.3** Watchers left by a previous shell instance are reaped with `pkill` before the new ones start; `pdeathsig` covers later exits. `Clipboard.qml` 265-273.
- **OM1.4** An initial snapshot of the current selection is taken on plugin load. `Clipboard.qml` 275-282.
- **OM1.5** `capture.sh` lists the offered types with a 2 s timeout, and bounds every payload read with 2 s; a copy cut off at the deadline is dropped, not kept. `capture.sh` 13, 22-26.
- **OM1.6** In watch mode `wl-paste` passes the payload on stdin and the MIME type as `$1`; with no argument the script snapshots the selection itself. `capture.sh` 3-5, 101-104.
- **OM1.7** Each capture is emitted as one JSON line, read by a `SplitParser`. `capture.sh` 47-48, 97; `Clipboard.qml` 288-290.
- **OM1.8** Text is decoded as UTF-16 when a BOM or a consistent NUL-padding pattern is present, then validated, else falls back to UTF-8. `capture.sh` 55-98.

### 4.2 Storage

- **OM2.1** History is one JSON file at `$HOME/.local/state/omarchy/clipboard-history.json`, watched with `watchChanges` and written atomically. `Clipboard.qml` 21, 251-260.
- **OM2.2** Images are written as files under `$XDG_STATE_HOME/omarchy/clipboard-images` named by their SHA-256 and extension; an image whose file already exists is not written twice. `capture.sh` 9-11, 39-45.
- **OM2.3** Entries are `{type:"text", text}` or `{type:"image", mime, path, capturedAt}`; a bare string normalises to a text entry. `ClipboardHistory.js` 1-27; `capture.sh` 47-48, 97.
- **OM2.4** History is capped at 500 entries, hardcoded in QML, and the file is written as `history.slice(0, 500)`. `Clipboard.qml` 41, 77.
- **OM2.5** Dedup is by entry key: text content, or image path. The newest copy goes first and an older equal key is skipped while the list is rebuilt. `ClipboardHistory.js` 29-33, 51-70.
- **OM2.6** No per-entry byte limit exists; the only bound is the 2 s read timeout. `capture.sh` 22-26.
- **OM2.7** No age expiry, TTL, or trimming other than the 500-entry cap; image files are only deduplicated by hash, never garbage-collected. `ClipboardHistory.js` 51-70; `capture.sh` 39-45; no other consumer of `clipboard-images`.
- **OM2.8** Nothing is encrypted: history is plain JSON and images are plain files. `Clipboard.qml` 21, 251-260; `capture.sh` 9-11.

### 4.3 Content types

- **OM3.1** Image preference order is png, jpeg, webp, gif, bmp, tiff. `capture.sh` 106-111.
- **OM3.2** Text is captured when any `text/*`, `UTF8_STRING` or `STRING` is offered. `capture.sh` 113-114.
- **OM3.3** File lists are handled only as `file://` URIs inside text entries: the JS decodes them for the row label and for a single-image thumbnail. `ClipboardHistory.js` 98-135, 189-197.
- **OM3.4** No `text/html` handling: not found in `capture.sh` 101-114 or `ClipboardHistory.js`.
- **OM3.5** Search and rendering work on at most 8192 characters of a text entry; paste reads the full entry back from history by index. `ClipboardHistory.js` 160-172.

### 4.4 UI

- **OM4.1** An overlay window with a search header row, a result list on the left and a preview pane on the right. `Clipboard.qml` 315-337, 416-577.
- **OM4.2** The header is also the search field: typing appends to the filter, Escape clears it first and closes second. `Clipboard.qml` 355-361, 430-441.
- **OM4.3** Filtering is a case-insensitive substring match over text, file names, or image MIME and capture time; at most 50 rows render. `ClipboardHistory.js` 92-96, 174-206; `Clipboard.qml` 135.
- **OM4.4** Rows show an asynchronous thumbnail for image entries and for single image files. `Clipboard.qml` 489-497; `ClipboardHistory.js` 189-197.
- **OM4.5** The preview pane shows the full text wrapped, or the image scaled to fit. `Clipboard.qml` 531-576.
- **OM4.6** Empty state distinguishes "Clipboard is empty" from "No matches". `Clipboard.qml` 579-604.
- **OM4.7** Keys: Up/Down, PageUp/PageDown (6 rows), Home/End, Enter activates, Shift+Enter copies, Alt+Enter opens, Delete removes one entry, Shift+Delete opens the clear confirmation, Escape clears or closes. `Clipboard.qml` 349-394.
- **OM4.8** Pointer hover moves the cursor and a click activates the row. `Clipboard.qml` 514-526; `PointerMoveGate` at 192-196, 246-249.
- **OM4.9** Clear asks "Delete entire clipboard history?" and empties the whole list; there is no pinned subset. `Clipboard.qml` 93-114, 396-413.
- **OM4.10** The surface reuses the menu colour tokens, clamps to 875×600 design tokens, and honours the `OMARCHY_MENU_FONT` override shared by menu, polkit, emojis and clipboard. `Clipboard.qml` 23-40; `shell/Commons/Style.qml` 313-321.
- **OM4.11** No pin, alias or edit action: not found in `Clipboard.qml` or `ClipboardHistory.js`.

### 4.5 Paste path

- **OM5.1** Enter on a text entry runs `omarchy-clipboard-paste-text --shift-insert --history-index N`. `Clipboard.qml` 221-223.
- **OM5.2** Enter on an image entry runs `omarchy-clipboard-paste-file <mime> <path>`. `Clipboard.qml` 219-220.
- **OM5.3** The `--copy-only` forms stop after `wl-copy`; they are used by Shift+Enter. `Clipboard.qml` 226-234; `bin/omarchy-clipboard-paste-text` 42-55; `bin/omarchy-clipboard-paste-file` 26-30.
- **OM5.4** Paste copies with `wl-copy`, sleeps 0.15 s, then synthesises Shift+Insert with `wtype -M shift -k Insert`. `bin/omarchy-clipboard-paste-text` 57-63; `bin/omarchy-clipboard-paste-file` 32-33.
- **OM5.5** The history index is resolved by `jq` directly against the JSON file, not through IPC. `bin/omarchy-clipboard-paste-text` 34-40.
- **OM5.6** The universal Super+V is a Hyprland `send_key_state` shortcut, not a history paste. `default/hypr/bindings/clipboard.lua` 8-16, 35-47.
- **OM5.7** Super+Ctrl+V opens the plugin through the panel binding. `default/hypr/bindings/clipboard.lua` 49.
- **OM5.8** Alt+Enter opens an entry: an image through `omasnap`, a URL through the browser, otherwise a temp file in the editor. `bin/omarchy-clipboard-open` 29-56.

### 4.6 Privacy

- **OM6.1** A selection advertising `x-kde-passwordManagerHint` is skipped before any read, so nothing is stored. `capture.sh` 15-17.
- **OM6.2** `CLIPBOARD_STATE=sensitive` in the environment also skips capture; in tree only the test suite sets it. `capture.sh` 15; `test/shell.d/clipboard-test.sh` 445-449.
- **OM6.3** No pause button, incognito mode, or per-application exclusion was found.
- **OM6.4** No encryption for history or image files. `Clipboard.qml` 21, 251-260; `capture.sh` 9-11.

### 4.7 Config

- **OM7.1** The 500-entry limit and the 50-row render cap are QML constants, not user config. `Clipboard.qml` 41, 135.
- **OM7.2** No clipboard keys exist in `config/` or `config/omarchy/shell.json`; the only shared knob is the `OMARCHY_MENU_FONT` override. `shell/Commons/Style.qml` 313-321.
- **OM7.3** The menu exposes "Clipboard History" (`omarchy-shell shell summon omarchy.clipboard`) and "Clipboard" (share); the shortcut list registers `panel omarchy.clipboard`. `default/omarchy/omarchy-menu.jsonc` 109, 138; `default/omarchy/shortcuts` 20.
- **OM7.4** The plugin can be disabled like any first-party plugin through `disabledPlugins[]`. `shell/plugins/README.md` 1-10.

### 4.8 IPC and CLI

- **OM8.1** The shell IPC target offers `summon`, `hide`, `toggle`, `call`; the menu uses `omarchy-shell shell summon omarchy.clipboard` and the keybind passes `{ panel = "omarchy.clipboard" }`. `docs/omarchy-shell.md` 105-124; `default/omarchy/omarchy-menu.jsonc` 109; `default/hypr/bindings/clipboard.lua` 49.
- **OM8.2** `omarchy menu clipboard` toggles the plugin. `bin/omarchy-menu-clipboard` 1-6.
- **OM8.3** Three hidden CLI helpers in the `clipboard` group: `omarchy-clipboard-paste-text`, `omarchy-clipboard-paste-file`, `omarchy-clipboard-open`. `bin/omarchy-clipboard-paste-text` 1-8; `bin/omarchy-clipboard-paste-file` 1-8; `bin/omarchy-clipboard-open` 1-6.
- **OM8.4** No clipboard-specific IPC method beyond open/close: not found.

### 4.9 Failure handling

- **OM9.1** A watcher that exits is restarted after 1 s, because a dead watcher silently stops recording. `Clipboard.qml` 302-313.
- **OM9.2** A missing or unreadable history file loads as an empty list and file errors are not printed. `Clipboard.qml` 251-260.
- **OM9.3** Stalled or empty reads are dropped in the capture script. `capture.sh` 22-26.
- **OM9.4** `wtype` failures are ignored with `|| true`, leaving the copy in place. `bin/omarchy-clipboard-paste-text` 59-63; `bin/omarchy-clipboard-paste-file` 32-33.
- **OM9.5** Tests in tree: `test/shell.d/clipboard-test.sh` exercises the JS history module (7-40), the UTF-16 heuristics (397-408) and the sensitive skip (445-449).

---

## 5. dots-hyprland (DH)

The shell keeps clipboard history through the external `cliphist` binary: startup `wl-paste --watch` processes write to it, and the Quickshell side reads `cliphist list` and drives it by spawning processes. `dots/.config/quickshell/ii/` is populated in this checkout; `dots-extra/fedora/hypr/hyprland/execs.conf` carries the same two startup lines in `exec-once` form.

### 5.1 Capture

- **DH1.1** Two `wl-paste --watch` processes run at startup, one for text and one for image, each running `cliphist store` and then notifying the shell. `dots-extra/fedora/hypr/hyprland/execs.conf` 19-20.
- **DH1.2** The same two lines exist in the user-facing Hyprland config as `hl.exec_cmd` startup calls. `dots/.config/hypr/hyprland/execs.lua` 18-21.
- **DH1.3** A commented generic line `wl-paste --watch cliphist store` remains above them, showing the earlier single-watcher form. `dots-extra/fedora/hypr/hyprland/execs.conf` 18; `dots/.config/hypr/hyprland/execs.lua` 19.
- **DH1.4** After each store the watcher calls `qs -c $qsConfig ipc call cliphistService update`, implemented as an `IpcHandler` with one `update()` that refreshes the list. `dots-extra/fedora/hypr/hyprland/execs.conf` 19-20; `services/Cliphist.qml` 150-156.
- **DH1.5** The service also refreshes when `Quickshell.clipboardTextChanged` fires, after `Config.options.hacks.arbitraryRaceConditionDelay` (20 ms). `services/Cliphist.qml` 113-127; `modules/common/Config.qml` 596.
- **DH1.6** One refresh is also run at shell start. `shell.qml` 30; `services/Cliphist.qml` 49-52.

### 5.2 Storage

- **DH2.1** Storage belongs to the external `cliphist` binary; the QML only runs `cliphist list`, `store`, `decode`, `delete` and `wipe`. `services/Cliphist.qml` 12-13, 54-111.
- **DH2.2** Entries are kept as the raw `cliphist list` strings, one per line, in a `list<string>`. `services/Cliphist.qml` 18-22, 129-148.
- **DH2.3** The binary name is hardcoded as `cliphist`, with a commented alternative path to `stash` and branches that handle both formats. `services/Cliphist.qml` 12-13, 55-59, 64-68.
- **DH2.4** Location, format, count and size limits, dedup and expiry are cliphist's behaviour and are not visible in this checkout: not found. `services/Cliphist.qml` 129-148.
- **DH2.5** Decoded images are cached one file per entry under `/tmp/quickshell/media/cliphist`, wiped and recreated when the shell starts. `modules/common/Directories.qml` 42, 61; `modules/common/widgets/CliphistImage.qml` 13-15, 54-58.
- **DH2.6** The image cache file for an entry is deleted when its widget is destroyed. `modules/common/widgets/CliphistImage.qml` 68-70.
- **DH2.7** `cliphist` and `wl-clipboard` are declared dependencies. `sdata/deps-info.md` 39, 104; `sdata/dist-arch/illogical-impulse-basic/PKGBUILD` 11; `sdata/dist-arch/illogical-impulse-hyprland/PKGBUILD` 11; `sdata/dist-arch/previous_dependencies.conf` 7, 59; `sdata/dist-fedora/feddeps.toml` 38, 89; `sdata/dist-gentoo/keywords` 18; `sdata/dist-gentoo/overlay/app-misc/illogical-impulse-basic/illogical-impulse-basic-1.0-r2.ebuild` 16; `sdata/dist-gentoo/overlay/gui-wm/illogical-impulse-hyprland/illogical-impulse-hyprland-1.0-r3.ebuild` 16; `sdata/dist-nix/home-manager/home.nix` 76, 113.

### 5.3 Content types

- **DH3.1** Text and image captures are wired explicitly by the two watcher lines. `dots-extra/fedora/hypr/hyprland/execs.conf` 19-20.
- **DH3.2** An image entry is recognised by its `cliphist list` shape: id, tab, then `[[ binary data WxH ... ]]`. `services/Cliphist.qml` 45-47.
- **DH3.3** The numeric id and tab are stripped for display only. `modules/common/functions/StringUtils.qml` 242-244.
- **DH3.4** File lists and HTML are not handled explicitly in the QML; whatever cliphist stores beyond text and images is shown as a raw string: not found. `services/Cliphist.qml` 18-47.

### 5.4 UI

- **DH4.1** There is no dedicated clipboard panel. History is a result set in the overview/launcher, reached by typing the clipboard prefix (default `;`) or by Super+V, which opens the overview with that query pre-filled. `services/LauncherSearch.qml` 171-210; `modules/common/Config.qml` 486; `modules/ii/overview/Overview.qml` 112, 196-203; `dots/.config/hypr/hyprland/keybinds.lua` 24.
- **DH4.2** Search is fuzzy over the entry with its id prefix removed, or a Levenshtein score when `search.sloppy` is on; an empty query returns the list unchanged. `services/Cliphist.qml` 19-43; `modules/common/Config.qml` 481.
- **DH4.3** Each result offers Copy and Delete actions; activating the row copies. `services/LauncherSearch.qml` 188-207.
- **DH4.4** Image entries render an asynchronous preview in the result row, decoded on demand into the cache path. `modules/ii/overview/SearchItem.qml` 232-241; `modules/common/widgets/CliphistImage.qml` 1-129.
- **DH4.5** A `superpaste <n>[i]` launcher action pastes the newest N entries, `i` restricting to images. `services/LauncherSearch.qml` 88-104.
- **DH4.6** A `wipeclipboard` launcher action runs `cliphist wipe`. `services/LauncherSearch.qml` 116-119; `services/Cliphist.qml` 101-111.
- **DH4.7** When the shell is not running, Super+V falls back to `cliphist list | fuzzel --match-mode fzf --dmenu | cliphist decode | wl-copy`. `dots/.config/hypr/hyprland/keybinds.lua` 61-64.
- **DH4.8** No pin, alias or edit action was found; no confirmation before delete or wipe was found. `services/Cliphist.qml` 83-111; `services/LauncherSearch.qml` 188-207.

### 5.5 Paste path

- **DH5.1** Copy runs `printf '<entry>' | cliphist decode | wl-copy`. `services/Cliphist.qml` 54-61.
- **DH5.2** Paste runs the same decode into `wl-copy`, then `wl-paste` for classic cliphist or `ydotool key -d 1 29:1 47:1 47:0 29:0` for stash. `services/Cliphist.qml` 63-70.
- **DH5.3** Superpaste copies each selected entry, waits `pasteDelay` (0.05 s) and presses the paste chord, oldest first. `services/Cliphist.qml` 14-15, 72-81.
- **DH5.4** Enter in the launcher result copies rather than pastes. `services/LauncherSearch.qml` 188-191.
- **DH5.5** The fuzzel fallback ends in `cliphist decode | wl-copy`, so it also leaves the entry on the clipboard. `dots/.config/hypr/hyprland/keybinds.lua` 61-64.

### 5.6 Privacy

- **DH6.1** Work-safety mode can blur image previews when a sensitive network name is visible and a neighbouring entry contains an unsafe link keyword; it defaults off. `services/LauncherSearch.qml` 120-131, 176-183; `modules/common/Config.qml` 599-609; `modules/settings/GeneralConfig.qml` 344-348.
- **DH6.2** No `x-kde-passwordManagerHint` handling was found anywhere in the tree.
- **DH6.3** No pause, incognito, or per-application exclusion was found; the nearest control is the blur above.
- **DH6.4** No encryption of the history was found; storage is cliphist's own file. `services/Cliphist.qml` 12-13.

### 5.7 Config

- **DH7.1** `search.prefix.clipboard` defaults to `;` and is edited in the settings window. `modules/common/Config.qml` 486; `modules/settings/ServicesConfig.qml` 143-147.
- **DH7.2** `search.sloppy` switches the match algorithm; `hacks.arbitraryRaceConditionDelay` sets the post-change refresh delay. `modules/common/Config.qml` 481, 596.
- **DH7.3** `workSafety.enable.clipboard` defaults to false and has a settings toggle "Hide clipboard images copied from sussy sources". `modules/common/Config.qml` 602; `modules/settings/GeneralConfig.qml` 344-348.
- **DH7.4** No history size, entry size or expiry keys were found; those belong to cliphist. `modules/common/Config.qml` 480-500.

### 5.8 IPC and CLI

- **DH8.1** The only clipboard IPC is the Quickshell target `cliphistService` with `update()`, called from the startup watchers. `services/Cliphist.qml` 150-156; `dots-extra/fedora/hypr/hyprland/execs.conf` 19-20.
- **DH8.2** CLI surface is `qs ipc call cliphistService update`, plus the launcher actions `superpaste` and `wipeclipboard`; no `omarchy-*`-style clipboard command exists in the repo. `services/LauncherSearch.qml` 88-119.
- **DH8.3** Any other CLI belongs to `cliphist`, `wl-clipboard` or `qs`, not to the repo: not found.
- **DH8.4** No `cliphistService` reference exists in any other reference under `refs/` (checked DankMaterialShell, Ambxst, noctalia, omarchy, quickshell): not found.

### 5.9 Failure handling

- **DH9.1** A failed `cliphist list` logs `[Cliphist] Failed to refresh with code … and status …` and keeps the previous entries. `services/Cliphist.qml` 141-147.
- **DH9.2** A failed image decode logs and clears the preview source instead of showing a broken image. `modules/common/widgets/CliphistImage.qml` 58-64.
- **DH9.3** No watcher supervision or restart exists on this side; the startup lines are `exec-once`. `dots/.config/hypr/hyprland/execs.lua` 18-21.
- **DH9.4** No test for the clipboard path was found in the tree: not found.

---

## 6. quickshell (QS, baseline)

The baseline is not a clipboard manager. It offers one string property on the `Quickshell` global, backed by Qt's `QClipboard`, and nothing else.

### 6.1 Clipboard surface

- **QS1.1** `Quickshell.clipboardText` is a read/write `QString` property. `src/core/qmlglobal.hpp` 138-141, 283-284; `src/core/qmlglobal.cpp` 229-237.
- **QS1.2** The header warns that under Wayland the clipboard is empty unless a Quickshell window is focused. `src/core/qmlglobal.hpp` 140.
- **QS1.3** Reading and writing go straight to `QGuiApplication::clipboard()`; there is no intermediate buffer or history. `src/core/qmlglobal.cpp` 229-237.
- **QS1.4** `clipboardTextChanged` is emitted only when `QClipboard::Clipboard` changes, not for other modes. `src/core/qmlglobal.cpp` 155-160, 239-241.

### 6.2 What is absent

- **QS2.1** No data-control protocol binding: `src/wayland/` has no data-control directory, and a repo-wide search for `datacontrol|data_control|data-control|wlr-data` finds only the `QClipboard` include and property in `qmlglobal.{hpp,cpp}`. `src/wayland/` (directory listing); `src/core/qmlglobal.hpp` 3, 138-141.
- **QS2.2** No MIME-type listing or per-type read: the API is text only, and no `QMimeData` use exists in `src/`. `src/core/qmlglobal.cpp` 229-241.
- **QS2.3** No image clipboard access: no `QClipboard::image`, `pixmap`, or `mimeData` call exists in `src/`. `src/core/qmlglobal.cpp` 229-241.
- **QS2.4** No primary-selection access (`QClipboard::Selection`): not found in `src/`.
- **QS2.5** No history, persistence, capture watcher, or paste injection API: not found in `src/`.
- **QS2.6** The data-control protocol XML in `refs/` is not unique to noctalia: `hyprland/protocols/wlr-data-control-unstable-v1.xml` (compositor side, `CMakeLists.txt` 565, `src/protocols/DataDeviceWlr.hpp` 6), `noctalia/protocols/wlr-data-control-unstable-v1.xml` (client bindings via `meson.build` 369-370, included at `src/wayland/wayland_connection.cpp` 31), `Ambxst/backend/internal/proto/xml/wlr-data-control-unstable-v1.xml` (generated Go at `backend/internal/proto/wlr_data_control/data_control.go` 3) and the ext variant `DankMaterialShell/core/internal/proto/xml/ext-data-control-v1.xml` (Go client imported from `dankgo/wayland/ext_data_control`, `core/internal/clipboard/wl.go` 8). Quickshell consumes none of them.
- **QS2.7** The `ext-data-control-v1` protocol appears only in DankMaterialShell; the `wlr-data-control-unstable-v1` file appears in hyprland, noctalia and Ambxst. A file search for `*.xml` matching `data.control` under `refs/` returns exactly those four files.

### 6.3 Use in tree

- **QS3.1** The only consumer is the reload popup, which copies an error string or a log excerpt to the clipboard. `src/ui/ReloadPopup.qml` 151, 204.
- **QS3.2** A shell that needs history therefore builds or delegates its own capture; dots-hyprland uses `cliphist` plus this change signal as an extra refresh trigger. `dots/.config/quickshell/ii/services/Cliphist.qml` 113-127 (section 5.1).
- **QS3.3** No clipboard test exists in the tree: not found.

---

## 7. Comparison

Yes means the feature is present in the cited code. No means nothing was found in the cited paths. Partial means some part is present, or the feature is delegated to code outside the tree. `QS` is the quickshell baseline, not a manager.

| Feature | DM | AX | NC | OM | DH | QS |
|---|---|---|---|---|---|---|
| Clipboard history manager | Yes (DM1.1) | Yes (AX1.1) | Yes (NC1.1) | Yes (OM1.1) | Yes, via cliphist (DH1.1) | No, text property only (QS1.1) |
| Own data-control watcher (`ext` and/or `wlr`) | Yes, ext only (DM1.1-1.3) | Yes, wlr (AX1.1) | Yes, ext then wlr (NC1.1) | No, `wl-paste` (OM1.2) | No, `wl-paste` (DH1.1) | No (QS2.1) |
| Capture via `wl-paste --watch` | No (own `dms cl watch`, DM1.8) | No | No | Yes (OM1.2) | Yes (DH1.1) | No |
| Persistent history on disk | Yes (DM2.1) | Yes (AX2.1) | Yes (NC2.1) | Yes, JSON (OM2.1) | Partial, external cliphist (DH2.1) | No |
| Configurable history cap | Yes (DM2.4) | Partial (fixed 50, AX2.5) | Yes (NC2.4) | No (fixed 500, OM2.4) | Not found | No |
| Per-entry size limit | Yes, 5 MiB (DM2.4) | Partial (64 MiB capture cap only, AX2.6) | Yes, 4/32 MiB (NC2.5) | No (2 s read timeout only, OM2.6) | Not found | No |
| Deduplication | Yes, FNV hash (DM2.6) | Yes, MD5 upsert (AX2.7) | Yes, payload compare (NC2.7) | Yes, entry key (OM2.5) | Not found | No |
| Age expiry / auto-clear | Yes (DM2.8-2.9) | No (AX2.9) | No (NC2.8) | No (OM2.7) | Not found | No |
| Pinned entries | Yes, cap 25 (DM2.4, DM2.10) | Yes (AX2.1, AX2.8) | Yes, exempt from caps (NC2.6) | No (OM4.11) | Not found | No |
| Text capture | Yes (DM1.10) | Yes (AX3.1) | Yes (NC3.1) | Yes (OM3.2) | Yes (DH3.1) | No (QS2.2) |
| Image capture | Yes (DM1.10, DM3.1) | Yes (AX3.1) | Yes (NC3.1) | Yes (OM3.1) | Yes (DH3.1) | No (QS2.3) |
| File / `text/uri-list` capture | Yes (DM3.2-3.3) | Yes (AX3.1) | No (NC3.2) | Partial, `file://` inside text (OM3.3) | Not found (DH3.4) | No |
| HTML capture | No (DM3.4) | No (AX3.4) | No (NC3.3) | No (OM3.4) | Not found | No |
| List plus search or filter | Yes (DM4.1-4.3) | Yes (AX4.1-4.2) | Yes (NC4.2) | Yes (OM4.2-4.3) | Yes, in launcher (DH4.1-4.2) | No |
| Image thumbnails or preview | Yes (DM4.4-4.5) | Yes (AX4.9) | Yes (NC4.3) | Yes (OM4.4-4.5) | Yes (DH4.4) | No |
| Delete single entry | Yes (DM4.7, DM4.9) | Yes (AX4.5) | Yes (NC4.5) | Yes (OM4.7) | Yes, no confirmation (DH4.3, DH4.8) | No |
| Clear history, pinned kept | Yes (DM4.8) | Yes (AX4.8) | Yes (NC4.6) | Yes, nothing pinned (OM4.9) | Yes, wipe (DH4.6) | No |
| Keyboard navigation | Yes (DM4.10-4.11) | Yes (AX4.10) | Yes (NC4.8) | Yes (OM4.7) | Partial, launcher keys (DH4.1) | No |
| Synthesized paste keystroke | Yes, ctrl+v / ctrl+shift+v (DM5.2-5.3) | Partial (emoji only, AX5.2) | Yes, 4 modes (NC5.2) | Yes, shift+insert (OM5.4) | Yes, ydotool / wl-paste (DH5.2) | No (QS2.5) |
| `x-kde-passwordManagerHint` skip | Yes (DM6.1) | No (AX6.1) | Yes (NC6.1) | Yes (OM6.1) | Not found | No |
| Incognito or pause capture | No (DM6.2) | No (AX6.2) | No (NC6.4) | No (OM6.3) | Partial, blur only (DH6.1) | No |
| IPC or CLI surface | Yes (DM8.1-8.5) | Yes (AX8.1-8.2) | Yes (NC8.1-8.2) | Yes (OM8.1-8.3) | Yes, one IPC method plus actions (DH8.1-8.2) | No, QML property only (QS1.1) |
| Encryption at rest | No (DM6.4) | Yes (AX2.2) | Yes (NC2.2) | No (OM2.8) | Not found | No |
| Tests in tree | Yes (DM: `clipboard_test.go`, `manager_test.go`) | Yes (AX: `store_test.go`) | Yes (NC: `tests/clipboard_service_test.cpp`, `tests/clipboard_storage_permissions_test.cpp`) | Yes (OM: `test/shell.d/clipboard-test.sh`) | No (DH9.4) | No (QS3.3) |

## 8. What this study could not verify

- cliphist's storage location, format, entry cap, dedup and expiry: the binary is external and no documentation or config for it is in the dots-hyprland tree (DH2.4).
- Whether any dots-hyprland surface offers pinning, aliases or a confirmation before delete/wipe; none was found in the QML (DH4.8).
- Whether `x-kde-passwordManagerHint` or any pause/incognito mode exists in dots-hyprland (DH6.2, DH6.3).
- Whether omarchy's image files under `clipboard-images/` are ever pruned by any code outside `shell/plugins/clipboard/`; no other consumer was found (OM2.7).
- Who sets `CLIPBOARD_STATE=sensitive` in a running omarchy session; only the test suite sets it in tree (OM6.2).
- How cliphist stores non-text, non-image MIME types, since the QML shows every entry as a raw list string (DH3.4).
- Whether quickshell exposes any clipboard path outside `Quickshell.clipboardText`; the repository has no docs directory and no data-control binding (QS2.1-QS2.5).
