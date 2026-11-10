# Clipboard history

*   **Author:** djeddi-yacine
*   **Status:** Draft
*   **Date:** 2026-11-10
*   **Requirements:** [features/reqs/clipboard.md](../reqs/clipboard.md)
*   **Study:** [features/studies/clipboard.md](../studies/clipboard.md)

--------------------------------------------------------------------------------

## Overview

A clipboard-history surface for the shell. `Super+V` opens a card with a search
field and a list of the recent clipboard entries, newest first. Enter puts the
chosen entry back on the clipboard and closes the card; the owner then presses
Ctrl+V in the target window. Delete removes one entry, a confirmed key clears
all of them, and a refresh key re-reads the history.

The shell does not capture anything. The package's own `cliphist.service`
(`wl-paste --watch cliphist store`) stores the history. The shell is a user
interface over `cliphist list`, `decode`, `delete` and `wipe`, plus `wl-copy`
for writing. The history lives in the runtime directory (tmpfs), so it is gone
at logout or reboot.

## The Problem

The desktop has no clipboard history: the clipboard holds one entry and the
next copy replaces it. The reference shells solve this with a daemon, a store
and a panel. The owner already has the daemon and store (`cliphist`) and wants
only the panel, in the shell's own style, with these limits: memory-only
history, no rules or incognito mode, no IPC, no capture code in the shell.

## Goals

*   `Super+V` opens the surface on the launcher's output; `Super+V` again, Esc,
    a click outside the card, or a pick closes it.
*   List `cliphist` entries newest first, with distinct rows for text, file
    paths, images and other binary data.
*   Search by substring over the row text (the `cliphist` preview). Searching
    does not look inside content beyond the preview.
*   Pick = `wl-copy` of the original bytes. Delete one. Clear all after
    confirmation. Refresh on open and on an explicit key.
*   Images: a placeholder row with type and size; the selected image row shows
    an in-memory preview (stage 3).
*   Clear states for: history tool missing, store not in the runtime
    directory, watcher not running, loading, empty, no matches, call failed.
*   The card is excluded from compositor screen sharing with the same layer
    rule as the auth card.
*   The shell never puts clipboard content in argv, a shell string, a log, an
    error detail or a test output.

## Non-Goals

*   Capture, storage, encryption, expiry, dedupe or limits implemented by the
    shell. `cliphist` owns them.
*   Pin, rules, incognito or pause, IPC or CLI, synthesised paste, a launcher
    mode, a fallback when the watcher is off.
*   Starting or stopping the watcher from the shell.
*   Searching inside entries longer than the `cliphist` preview.

## Open Questions

None. The three architecture choices of this draft were decided by the owner on
2026-11-10: wrapper script plus runner, a shared list component, scrim window
plus card window (see Technical Plan).

## Critical User Journeys (CUJs)

1.  **Pick an entry.**
    *   Given: the watcher is running and five texts were copied.
    *   When: the owner presses `Super+V`, types two letters, presses Enter.
    *   Then: the matching entry is on the clipboard, the card is closed, and
        Ctrl+V in another window pastes it. The entry is now at the top of the
        history (the watcher stored the copy again).
2.  **Delete one, clear all.**
    *   Given: the surface is open with a selected row.
    *   When: the owner presses Delete; later presses the clear-all key and
        confirms with Enter.
    *   Then: the row disappears at once; after the confirmed clear the list
        is empty and the empty state shows. Esc at the confirmation cancels it.
3.  **Watcher off.**
    *   Given: the unit is stopped.
    *   When: the owner presses `Super+V`.
    *   Then: the card shows "Clipboard history is off" with the start
        command, not an empty list.
4.  **Image.**
    *   Given: an image was copied.
    *   When: the owner moves the selection to its row.
    *   Then: the row shows "Image, png, 640 x 480, 52 KiB" (from the
        `cliphist` preview) and, after a short delay, a preview. Moving away
        drops the preview. Enter copies the original image.
5.  **Awkward content.**
    *   Given: an entry with a quote, a tab and a newline.
    *   When: it is listed, searched, picked and deleted.
    *   Then: nothing is executed and no error appears.

## Technical Plan

### Components

```
 Super+V ──▶ hyprland global ──▶ ClipboardShortcut ──▶ ClipboardState.open
                                                            │
                          ┌─────────────────────────────────┴───────────┐
                          ▼                                             ▼
              ClipboardSurface                                   (PanelGroup:
   scrim window  ui-shell-clipboard-scrim                        closes other
   card  window  ui-shell-clipboard  (no_screen_share)           panels)
                          │
                    ClipboardPanel ── ClipboardSearch (filter)
                          │        └─ ShellListView ── ClipboardRow
                          ▼
                 ClipboardRunner (singleton, adapters/)
                          │  Process, stdin = one list line
                          ▼
                 scripts/clipboard  status|list|copy|delete|wipe|image
                          │
                          ▼
              cliphist (list/decode/delete/wipe)   wl-copy
                          ▲
          wl-paste --watch cliphist store  (stock unit, owner starts it)
```

### Decision 1: wrapper script plus runner (owner)

`scripts/clipboard` is a bash script like `scripts/screen-shot`. It owns every
call to `cliphist` and `wl-copy`, all timeouts, the availability checks and the
JSON the shell reads. `Adapters.ClipboardRunner` is a QML singleton like
`ShotRunner`; it starts the script and parses its output. Rejected by the
author: QML starting `cliphist` directly (no shell-level test target, command
flags spread over QML); a Python helper (no other script in `scripts/` needs
Python).

### Decision 2: shared list component (owner)

The launcher's list (the `ListView` with `add`, `displaced`, `move`, `remove`
transitions and `reuseItems: false`, `AppPanel.qml`) moves to
`shell/components/ShellListView.qml`. `AppPanel` and `ClipboardPanel` both use
it. Rejected by the author: copying the transitions into the clipboard panel
(two copies of the motion). Risk: a bug in the extraction hits the launcher;
`make test-launcher`, `make test-motion` and `make test-qml` must pass
unchanged.

### Decision 3: scrim window plus card window (owner)

`no_screen_share` on a full-screen layer would blank the whole screen in a
capture. The surface therefore follows the auth dialog (`AuthSurface.qml`):
`ui-shell-clipboard-scrim` is a full-screen layer on `WlrLayer.Top` with no
keyboard focus; a click on it closes the panel. `ui-shell-clipboard` is a
card-sized layer on `WlrLayer.Overlay` with `Exclusive` keyboard focus. The
card window has a fixed size from the start (width `Config.Clipboard.width`,
height from the visible-rows setting) and holds the panel directly, not through
a loader, so it never maps half-built. Rejected by the author: a single
card-only window (no outside click, no dimming).

### The script contract

`scripts/clipboard <verb>`; the verb is the only argument. A list line (the
`cliphist list` line, `ID<TAB>preview`) comes on standard input where a verb
needs an entry. Content is never an argument and never expanded in a command
string.

| Verb | Standard input | Standard output | What it does |
| --- | --- | --- | --- |
| `status` | none | `{"state": S}` | Checks the environment. |
| `list` | none | `{"state":"ok","items":[...]}` or `{"state":S}` | Reads the history. |
| `copy` | one list line | none | Decodes the entry and serves it with `wl-copy`. |
| `delete` | one list line | none | Deletes that entry. |
| `wipe` | none | none | Deletes all entries (`cliphist wipe`). |
| `image` | one list line | `{"mime":M,"data":BASE64}` | Decodes an image entry for the preview. |

`S` is one of `ok`, `no-cliphist`, `no-wl-clipboard`, `store-outside-runtime`,
`watcher-off`. The checks, in this order: `cliphist`, `wl-copy` and
`timeout` exist; the store path printed by `cliphist version` starts with
`$XDG_RUNTIME_DIR/` (otherwise history could be on disk: acceptance check 6);
a process matching `wl-paste` with `--watch` and `cliphist` and `store` is
running for this user. Only `ok` allows `list` and every action.

Each item: `line` (the whole list line, kept so it can be sent back), `id`,
`kind` (`text`, `file`, `image`, `binary`), `text` (the row text), `detail`
(for images and binary data: the type and size as `cliphist` printed them;
otherwise empty). Kind rules, applied to the preview:

*   `[[ binary data SIZE EXT WxH ]]`: `image` when `EXT` is `png`, `jpg`,
    `jpeg`, `bmp`, `gif`, `webp` or `tiff`; otherwise `binary`.
*   text beginning `file://`: `file`. The URL is percent-decoded and a leading
    `$HOME` is shown as the literal `$HOME`. Display only.
*   anything else: `text`.

Rules the script keeps (conditions from the requirements):

*   **Stale-entry check.** `copy`, `delete` and `image` first list the history
    and require a line equal to the one received, byte for byte. If none is,
    the script exits 3 and does nothing. A recycled id can therefore never
    act on a different entry. The comparison uses a bash variable, not an
    argument and not a file.
*   **Timeouts.** Every `cliphist`, `wl-copy` and `wl-paste` call runs under
    `timeout` (`CLIPBOARD_TIMEOUT`, default 5 seconds). Exit code 5 means timed
    out.
*   **`wl-copy` detach.** `wl-copy` stays alive to serve the clipboard. It is
    started with all its descriptors redirected, as `scripts/screen-shot` does,
    so it does not hold the runner's pipes open.
*   **No content in messages.** stderr carries fixed strings only. The JSON is
    built with `jq` reading the list from standard input; the only `--arg`
    values are `$HOME` and fixed words.
*   **Image size cap.** `image` refuses entries above `CLIPBOARD_IMAGE_LIMIT`
    (8 MiB) with exit 6; the row then keeps its placeholder.
*   Exit codes: 0 done, 2 usage, 3 entry changed, 4 unavailable, 5 timed out,
    6 too large.

### Seeding the cliphist config

`tools/cliphist-config` is the template: `db-path`, `max-items 80`. The
template holds `@RUNTIME_DIR@` for the path, and
`tools/scripts/seed-cliphist-config SOURCE CONFIG_HOME` writes
`$CONFIG_HOME/cliphist/config` with the runtime directory filled in, only when
that file is absent (user-edited files win, the rule of
`brain/pages/shipped-default-seed.md`). The path is
`$XDG_RUNTIME_DIR/ui-shell/clipboard/db`; `cliphist` creates the directories
(checked on 2026-11-10). The script runs from `stage-config` and from
`tests/scripts/test-nested` state initialisation, where `CONFIG_HOME` is the
private home's `.config`. The stock unit reads the default config path, so it
finds the seed without a drop-in. `max-items 80` is the chosen value: 80 rows
is a few screens, far below the default 750, and the store is in RAM.

The runtime directory at seed time is written into the file. If
`XDG_RUNTIME_DIR` differs later (a different user id), the script's
`store-outside-runtime` check catches it.

### Shell state and the runner

`Adapters.ClipboardRunner` (singleton):

*   Properties: `state` (the script's state string, `loading` until the first
    answer), `items` (list of item objects), `busy`, `imagePreview` (a data
    URL for one entry, or empty), `imageFor` (the `line` it belongs to).
*   Functions: `refresh()`, `copy(item)`, `remove(item)`, `wipe()`,
    `loadImage(item)`, `dropImage()`.
*   Signals: `copied()`, `failed(failure)`.
*   Two `Process` objects: a reader for `list` and `image` (one at a time), and
    an actor for `copy`, `delete` and `wipe`. A verb that needs an entry
    writes the `line` to the process input and closes it. A new reader call
    while one runs is ignored; a late answer for a different `imageFor` is
    discarded.
*   Exit-code mapping: 3 asks for a refresh and shows "That entry changed, the
    list was refreshed"; 4 sets the unavailable state; 5 and 6 produce a
    failure object for `ErrorPopup`; any other non-zero exit is a failure with
    the fixed text "The clipboard command failed". Failure objects follow the
    shape of `ShotRunner` (`source: "clipboard"`) and never include the line.
*   The command path comes from `Config.GeneratedRuntime.commands.clipboard`
    (new command key `clipboard`, default `scripts/clipboard`).

State keyed by content: the panel remembers the selected row by its `line`
(not by `id`). After a refresh the selection moves to the row with the same
line, or to the first row if it is gone.

### Search

`ClipboardSearch.qml` (a singleton with one function, `results(items, query)`)
lowercases the query, splits it on whitespace, and keeps the items whose
`text` contains every token as a substring. Order is the input order (newest
first). It does not use `AppSearch`: the launcher scorer sorts by name and
accepts a character subsequence, which would match almost any long text and
would lose the recency order.

### Panel behaviour

`ClipboardPanel` follows `AppPanel`: `activate()` clears the query, calls
`ClipboardRunner.refresh()`, focuses the search field and starts the
`PanelMotion` enter. Views, by `runner.state` and the filter result:

| Condition | Shown |
| --- | --- |
| `loading` | "Reading clipboard history…" |
| `no-cliphist` | "cliphist is not installed" |
| `no-wl-clipboard` | "wl-clipboard is not installed" |
| `store-outside-runtime` | "The history store is not in the runtime directory. Run the seed (see README)." No history is read. |
| `watcher-off` | "Clipboard history is off. Start it with: systemctl --user start cliphist" |
| `ok`, no items | "Nothing copied yet" |
| `ok`, items, no match | "No matching entries" |
| `ok`, matches | the list |

Keys (all in `Config.Clipboard`, values are fixed there, not derived):

*   Up, Down, PageUp, PageDown: move selection (as the launcher).
*   Enter or keypad Enter: copy the selection, then close on `copied()`.
*   Delete: delete the selected entry (no confirmation); the row leaves with
    the list's remove transition, the selection stays at the same index.
*   Shift+Delete: arm clear all. The panel shows a confirmation strip
    ("Clear all N entries? Enter to confirm, Esc to cancel"); Enter runs
    `wipe`, Esc cancels. While armed, every other key is ignored.
*   F5 or Ctrl+R: refresh.
*   Esc: dismiss the error popup, then the context popup, then the
    confirmation, then the panel (the launcher's order).
*   Printable keys go to the search field (as the launcher).
*   The keys list opens through `PanelContext` with the launcher's help key
    (`Config.Keyboard.helpKey`) and shows the bindings above. This panel has no
    settings component and no information popup.

Rows (`ClipboardRow`): a fixed height. `text` rows show one line with an
elision at the end; `file` rows show the shortened path; `image` and `binary`
rows show a small kind icon and the `detail` text. Text from the clipboard is
rendered as plain text (`Text.PlainText`), never as rich text, so HTML in the
clipboard is not interpreted.

Image preview (stage 3): when the selected row has `kind: "image"`, a timer
(`Config.Clipboard.previewDelayMilliseconds`, 200) calls
`runner.loadImage(item)`. The answer sets `imagePreview` to
`data:MIME;base64,DATA`. A preview area below the list shows it with
`Image { source: imagePreview; asynchronous: true }`. Selection change, close
and refresh call `dropImage()`. The QML engine's image cache may hold decoded
pixels: the `Image` sets `cache: false`.

### Hyprland and shortcuts

*   `hypr/profile.lua` `shell_shortcuts` gets `clipboard = { key = "V", target =
    "ui-shell:clipboard" }`.
*   `hypr/binds/shell.lua` binds it the way the other entries are bound.
*   `Super+V` is currently "Toggle floating" in `hypr/binds/windows.lua:19` and
    "Toggle floating or Canvas pin" in `hypr/binds/canvas.lua:31`. Both move to
    `Super+Z` (the owner's decision). `rg` over `hypr/` found no other `Z` bind
    on 2026-11-10. The implementer re-runs that search, and also reads
    `hypr/user/nested.lua` and `hypr/nested.lua` for overrides.
*   `hypr/rules.lua`: `clipboard` and `clipboard-scrim` join the `no_anim`
    namespace pattern, and a new layer rule `clipboard-not-shared` matches
    `^ui-shell-clipboard$` with `no_screen_share = true`, with a comment like
    the auth rule's. Whether `gpu-screen-recorder` honours it is not known
    (acceptance check 11); the result is written to `shell/modules/clipboard`
    docs and the README, whichever way it goes.
*   The existing test `make test-hypr-config` does not detect duplicate chords
    (`tests/scripts/check-hypr-config:37-39`). Acceptance check 10 is done by
    hand (`rg 'V"' hypr/`) and this design does not extend that test.

### Configuration

`shell/config/Clipboard.qml` (singleton): `shortcutAppId`, `shortcutName`,
`placement`, `asynchronousPanelLoad`, `retainPanelAfterClose`, `width`,
`visibleRows`, `rowHeight`, `rowSpacing`, `panelPadding`, `sectionSpacing`,
`iconSize`, `previewHeight`, `previewDelayMilliseconds`, the key values listed
above, and `scrimOpacity` (taken from `Config.ContextPanels.scrimOpacity`).
`shell/config/Config.qml` gets `clipboardEnabled: true`. `tools/config.ini`
gets `clipboard = scripts/clipboard` in `[commands]`, and
`scripts/read-shell-config` lists the `clipboard` command in both places where
`screenShot` is listed (the defaults map and the exact-keys check).

### Tests

*   `tests/clipboard/bin/cliphist` and `tests/clipboard/bin/wl-copy`: small bash
    fakes. The fake `cliphist` answers `version`, `list` (canned lines read
    from a file named by `FAKE_CLIPHIST_LIST`, including a line with a quote,
    a tab inside the preview, a `file://` line and a `[[ binary data ... png ... ]]`
    line), `decode`, `delete`, `wipe`, and records the verbs it received in a
    log file inside the test's scratch directory. The fake `wl-copy` writes the
    bytes it received to a file in the scratch directory. A fake `pgrep`
    (or `FAKE_WATCHER=on|off`) is not needed: the script looks for the watcher
    through `pgrep`, which the test puts a stub in front of on `PATH`.
*   `tests/scripts/check-clipboard` runs the script against the fakes:
    each state of `status`; `list` JSON (kinds, `$HOME` shortening, the quoted
    and tabbed line unchanged in `line`); `copy`, `delete`, `image` with the
    right entry; the stale-entry exit 3 when the list changed; timeout exit 5
    with a fake that sleeps; the 8 MiB cap exit 6; that no argv of any fake
    call contained the content marker; that stderr holds no content marker.
*   `tests/tst_ClipboardSearch.qml`: tokens, case, order, empty query, no hit,
    quotes and tabs.
*   `tests/tst_ClipboardPanel.qml`: with a `tests/clipboard/FakeRunner.qml`
    (modelled on `tests/mpris/FakeRunner.qml`): every row of the state table;
    Enter calls `copy` with the selected item and closes on `copied`; Delete
    calls `remove` and keeps the index; Shift+Delete arms, Esc cancels, Enter
    confirms and calls `wipe`; selection is restored by `line` after a refresh;
    image preview is requested after the delay and dropped on selection change.
*   `make test-clipboard` (new target in `tests/targets.mk`) runs
    `check-clipboard`; `make test` includes it. The QML tests run in
    `make test-qml`.
*   `make test-env` starts `wl-paste --watch cliphist store` in the background
    with the private home's seeded config, next to the shell, and stops it with
    the sandbox. `make test-env-host` does not start a watcher: it uses the
    owner's real unit (the owner starts it) and the real store.
*   No test touches the owner's real history: the fakes run with a scratch
    `PATH`; the nested environment has its own home and runtime directory.

### Staging

1.  Stage 1: script verbs `status`, `list`, `copy`; seed; runner; surface,
    shortcut, panel, search, row, states; keys; Hyprland edits; the shared
    list extraction; tests for these.
2.  Stage 2: script verbs `delete`, `wipe`; Delete and clear-all with
    confirmation; their tests.
3.  Stage 3: script verb `image`; image rows; the preview; their tests.

## Alternatives Considered

*   **Native data-control daemon in the shell.** Rejected by author: no new
    background code; the package ships the capture service; Quickshell has no
    data-control binding.
*   **Own watcher started by the shell or by `exec-once`.** Rejected by author:
    the stock unit does this.
*   **Disk store with encryption.** Rejected by author: memory-only history is
    wanted.
*   **Clipboard as a launcher mode.** Rejected by author: the panel needs its
    own logic and keys. The duplicated list is avoided through Decision 2.
*   **`Quickshell.clipboardText`.** Rejected: text only, empty unless a
    Quickshell window has focus, no history.
*   **Synthesised paste.** Rejected by author.
*   **Rules, incognito, IPC, pin.** Dropped by author.
*   **QML starting `cliphist` directly; Python helper; copied list transitions;
    single card-only window.** Rejected by author, reasons under Decisions 1
    to 3.
*   **`AppSearch` for filtering.** Rejected by author: sorts by name and
    accepts character subsequences.
*   **Selecting with `wl-copy --sensitive`.** Rejected by author (requirements
    Decided 20): the copy is stored again and moves to the top; no extra
    mechanism.

## Detailed Implementation Plan

Every file the work touches. "New" means created. `EGM.md` files are created or
updated with `/egm-bootstrap` (`target_filename="EGM.md"`), never by hand.

### New files

*   `scripts/clipboard`: the backend described above. All `cliphist`, `wl-copy`
    and `timeout` use; `status`, `list`, `copy`, `delete`, `wipe`, `image`.
*   `tools/cliphist-config`: the config template (`db-path`, `max-items 80`).
*   `tools/scripts/seed-cliphist-config`: writes the config into a given
    config home when absent.
*   `shell/adapters/ClipboardRunner.qml`: the runner singleton.
*   `shell/components/ShellListView.qml`: the shared animated list.
*   `shell/config/Clipboard.qml`: panel settings and keys.
*   `shell/modules/clipboard/ClipboardState.qml`: `open`, `screenName`, `show()`,
    env `UI_SHELL_OPEN_CLIPBOARD=1` like the other states.
*   `shell/modules/clipboard/ClipboardShortcut.qml`: `GlobalShortcut`
    `ui-shell:clipboard`, toggles.
*   `shell/modules/clipboard/ClipboardSurface.qml`: the scrim window and the
    card window.
*   `shell/modules/clipboard/ClipboardPanel.qml`: search field, states,
    list, confirmation strip, preview, keys.
*   `shell/modules/clipboard/ClipboardRow.qml`: one row.
*   `shell/modules/clipboard/ClipboardSearch.qml`: the filter singleton.
*   `shell/modules/clipboard/qmldir`: registers the module.
*   `shell/modules/clipboard/EGM.md`: module contract (via `/egm-bootstrap`).
*   `tests/clipboard/bin/cliphist`, `tests/clipboard/bin/wl-copy`,
    `tests/clipboard/bin/pgrep`: fakes.
*   `tests/clipboard/list.txt`: canned list lines.
*   `tests/clipboard/FakeRunner.qml`: runner stand-in for panel tests.
*   `tests/scripts/check-clipboard`: script test.
*   `tests/tst_ClipboardSearch.qml`, `tests/tst_ClipboardPanel.qml`: QML tests.

### Modified files

*   `shell/modules/apps/AppPanel.qml`: replace the inline `ListView` and its
    transitions with `ShellListView`; behaviour unchanged.
*   `shell/components/qmldir`: register `ShellListView`.
*   `shell/components/EGM.md`: add `ShellListView` (via `/egm-bootstrap`).
*   `shell/adapters/qmldir`: register `ClipboardRunner` as a singleton.
*   `shell/adapters/EGM.md`: add `ClipboardRunner` (via `/egm-bootstrap`).
*   `shell/config/qmldir`: register `Clipboard`.
*   `shell/config/Config.qml`: add `clipboardEnabled`.
*   `shell/config/EGM.md`: add `Clipboard.qml` (via `/egm-bootstrap`).
*   `shell/shell.qml`: import the module, add `Clipboard.ClipboardShortcut`
    next to the other shortcuts, add `Clipboard.ClipboardState` to the
    `PanelGroup` list, add a `Variants` for `Clipboard.ClipboardSurface`
    gated by `clipboardEnabled`.
*   `shell/EGM.md`, `shell/modules/EGM.md`: list the new module (via
    `/egm-bootstrap`).
*   `scripts/read-shell-config`: add the `clipboard` command key in the
    defaults list and in the exact-keys list.
*   `tools/config.ini`: add `clipboard = scripts/clipboard` under `[commands]`.
*   `tools/scripts/stage-config`: call `seed-cliphist-config` after the
    defaults seed.
*   `tests/scripts/test-nested`: seed the private home's cliphist config, and
    start and stop the background `wl-paste --watch cliphist store`.
*   `tests/targets.mk`: `test-clipboard` target, help line, `.PHONY`, and
    inclusion in `test`.
*   `hypr/profile.lua`: add `clipboard` to `shell_shortcuts`.
*   `hypr/binds/shell.lua`: bind it.
*   `hypr/binds/windows.lua`, `hypr/binds/canvas.lua`: floating toggle and
    Canvas pin move from `Super+V` to `Super+Z`.
*   `hypr/rules.lua`: namespaces in `no_anim`; new `clipboard-not-shared` rule.
*   `STYLE.md` (SUPER key list near line 268): `V` becomes clipboard, `Z`
    becomes floating.
*   `README.md`, `shell/README.md`, `tests/README.md`, `FEATURES.md`: describe
    the feature, the start command for the unit, the seed, `make
    test-clipboard`, and the screen-share finding once measured.

### Deleted files

None.

### Order of work

1.  `ShellListView` extraction and launcher regression run.
2.  Stage 1 as listed under Staging, tests first for the script and the search.
3.  Stage 2, stage 3.
4.  Hyprland edits and `STYLE.md`.
5.  `/egm-bootstrap` for the `EGM.md` files, then the documentation.
6.  Acceptance checks 1 to 11 of the requirements. Checks 1 to 6 and 9 need
    `make test-env` (visual parts are asked of the owner with exact steps);
    7 and 11 need the real session.

### Reconciliation with the requirements

*   Every Decided item 1 to 20 is carried; Decided 19's number is 80.
*   Added by this design, not in the requirements: the stale-entry check, the
    image size cap (8 MiB), the preview delay (200 ms), the key assignments,
    the `store-outside-runtime` check (from acceptance check 6), the
    seed script as a separate tool, and the scrim-plus-card build (owner
    decision, recorded above).
*   Wording note: the requirements say the surface is "hidden from capture";
    only the card is, because of the layer-rule behaviour on full-screen
    layers.

### Changes made during implementation

Recorded after the design was written; the code is the source of truth.

*   **Seeding:** `make dev-seed-clipboard` writes `~/.config/cliphist/config`
    only if absent; `make test-env` and `make test-env-host` seed a private copy.
*   **No-tool state:** the script also needs `jq`, `pgrep`, `base64`, `awk`,
    `realpath`, `stat` and `grep`; a missing one reports `no-tool`.
*   **Watchers in tests:** the nested session starts the text and image
    `wl-paste --watch cliphist store` watchers and stores sample entries;
    the host session starts them only if none run and stops them on exit.
*   **Preview:** closed by default; Space or a right click on a row toggles it
    with the list-move animation; images load only while it is open.
*   **Scrim:** its opacity follows the card so both fade together.
*   **Bar button:** a clipboard button in the bar, shown when
    `Config.clipboardEnabled` is true.
*   **Copy as content:** Shift+Enter on a single copied-file entry copies the
    file's text or picture (`clipboard copy-content`, exit 7 when refused,
    limited to files under `$HOME`, `CLIPBOARD_FILE_LIMIT` default 8 MiB).
    Enter still pastes the address.
*   **Canvas pin:** moved from `Super+V` to `Super+Z`, as planned.
