# Clipboard history

* **Author:** djeddi-yacine
* **Date:** 2026-11-10
* **Status:** Draft. Reviewed by seven Goldfish lenses (design, codebase, zoom-out, comprehension, implementation readiness, structural, inventive). Pin, the shortcut, config seeding and unit start are settled (2026-11-10). Refresh, image preview, file entries, delete confirmation and the size cap are settled too. Nothing remains open for the owner; the design can start.

Input: `features/studies/clipboard.md`. This file records what we take from it. Study ids are cited as `DM`, `AX`, `NC`, `OM`, `DH`, `QS` plus a number. Claims marked "verified here" were run on this machine on 2026-11-10 (cliphist 0.7.0, wl-clipboard 2.3.0). Claims marked "to verify" are not proven.

## Overview

The shell gets a clipboard-history surface. The owner presses a shortcut, sees the recent clipboard entries (text and images), searches them, and picks one. Picking an entry puts it back on the clipboard; the owner then presses Ctrl+V (or Ctrl+Shift+V in a terminal) in the window they were using. The surface does not type into other windows.

The shell captures and stores nothing. The package `cliphist` already ships a user unit (`/usr/lib/systemd/user/cliphist.service`, verified here) that runs `wl-paste --watch cliphist store`. That unit does the capture, and `cliphist` keeps the database. The shell is a view over that database: it runs `cliphist list`, `decode`, `delete` and `wipe`, and `wl-copy`. The database path is moved to a RAM-backed directory through cliphist's own config file, so the history disappears on reboot or logout.

This is a separate surface, not a launcher mode. It joins the shell's existing panel group, so opening it closes the other panels.

## Analysis

1. **Pin has no home.** `cliphist` has no pin (verified here: its commands are store, list, decode, delete, delete-query, wipe, version). Every reference that has pin owns its store (DM2.4, AX4.7, NC2.6). The references built on cliphist do not have it (DH4.8, OM4.11). A pin in this design would be state the shell holds itself. A pin keyed by `cliphist` id goes stale, because copying the same content again deletes the old row and creates a new one with a new id (DM2.6 describes the same behaviour in its own store; verified here that duplicates collapse). A pin held as a copy of the content is a second store of possible secrets, with no expiry. Memory-only pins disappear when the shell restarts, which makes them half a feature. Four reviewers called this the largest inconsistency. **Settled: pin is dropped.**
2. **"Memory only" depends on a file that does not exist yet.** `~/.config/cliphist/config` is absent (verified here). Without it, `cliphist` writes to `~/.cache/cliphist/db` on disk. If the unit is enabled before the config exists, every copied password lands in a plaintext file, and `cliphist list` looks the same either way. **Settled: the config is seeded as part of the shell's config.** The surface must still refuse to show history when the configured path is not under the runtime directory.
3. **Super+V is already taken.** `hypr/binds/windows.lua:19` binds it to "Toggle floating", and `hypr/binds/canvas.lua:31` rebinds it when the Canvas plugin is on. `test-hypr-config` only runs `Hyprland --verify-config` and does not detect duplicate chords (`tests/scripts/check-hypr-config:37-39`, `STYLE.md:268`). The new bind would pass the test and silently shadow or be shadowed. **Settled: the floating toggle moves to `Super+Z` (no existing bind uses Z in `hypr/`), and the clipboard takes `Super+V`.** The study's own defaults for this key are AX7.3 (SUPER+V) and OM5.6 (Super+V is paste, Super+Ctrl+V is history).
4. **The list can only refresh by re-reading.** There is no change signal from cliphist and no IPC by decision. The reference that wants live updates adds an IPC call to the watcher (DH1.4), which changes the stock unit. `Quickshell.clipboardText` only fires for text and only while a Quickshell window is focused (QS1.2), so it is not a trigger. Re-listing when the surface opens is the cheapest honest answer, and DM4.13 does the same.
5. **Selecting re-enters the store.** `wl-copy` makes a new selection, the watcher stores it, and `cliphist` moves the entry to the top with a new id. The list order changes after every selection and any state keyed by id goes stale. Closing the surface on select hides this. Everything the shell remembers must be keyed by content, never by id.
6. **Content must never travel through a shell string or argv.** DH5.1 builds `printf '<entry>' | cliphist decode | wl-copy` from the entry text. An entry containing a single quote would run commands, and argv is visible to `ps`. The list line must reach `cliphist decode` and `cliphist delete` only through standard input of a fixed command.
7. **What "the unit is not running" looks like is undefined.** `cliphist list` cannot tell a dead unit from an empty database. The unit is currently `disabled` and `inactive` on this machine (verified here). `systemctl --user` is not reachable inside the repo's test sandbox (`make test-env`, per the readiness review of `tests/scripts/test-nested` and `brain/pages/isolated-nested-test-environment.md`), so a detection based only on systemd would always report "off" in the mandated test environment.
8. **A separate surface duplicates a launcher.** The launcher already has a search field, an animated list and a key flow (`shell/modules/apps/AppPanel.qml`, `AppSearch.qml`, `AppRow.qml`). DH4.1 and AX4.11 run clipboard as a launcher mode. The owner chose a separate surface because the GUI will need changes to add and support new logic. The reviewers accept that only if the reason is written down and the list, search and animation components are reused, not copied.
9. **Image cost.** The list line for an image already carries format, size and dimensions (`[[ binary data … ]]`, DH3.2), so a placeholder costs no decode. A real preview needs `cliphist decode`, and the references park the bytes in a cache file (DH2.5 under `/tmp`). A file in `/tmp` is not guaranteed to be memory-backed. Large images also fill the RAM-backed directory: `cliphist` stores whole entries (a 2 MB text entry was stored whole, verified here) and has a default cap of 750 items.
10. **Password managers.** `wl-paste --watch` sets `CLIPBOARD_STATE=sensitive` for password-manager copies, and `cliphist store` stores nothing in that state (verified here, rc 0, empty list). It also stores nothing for `CLIPBOARD_STATE=clear` (verified here). So the stock unit already drops them. This is the one place the study's references and the stock unit agree (DM6.1, NC6.1, OM6.1). Copies from apps that do not set the hint are stored. Selecting an entry with `wl-copy` carries no hint unless `--sensitive` is passed (the flag exists, verified here); whether to pass it is open. The owner dropped incognito, so the only way to stop capture is to stop the unit.
11. **Search is over the preview only.** `cliphist list` truncates each line (default 100 characters, `-preview-width`). Text beyond that is not searchable. Images are only searchable by their label.
12. **The shell's own conventions already settle part of this.** QML does not run raw commands; a script in `scripts/` does the work and a singleton in `shell/adapters/` runs it through `Process` (`ShotRunner.qml` is the template; the script path comes from `tools/config.ini` through `GeneratedRuntime.commands`). The surface/state/shortcut pattern is `AppState.qml`, `AppSurface.qml` and `ShotShortcut.qml`, registered in `shell/shell.qml` and `hypr/`. Failures use the shared failure shape and reach `ErrorPopup`. All of that is design-stage detail and belongs in `features/designs/clipboard.md`.

## Goals vs. Non-Goals

* **In-Scope Goals:**
  * A separate surface, opened by one shortcut, listing the cliphist history newest first.
  * Text and image entries. Images show as a placeholder built from the list line and are never decoded for the list. Other entry kinds (files, HTML) are not special-cased (see Decided 17).
  * Search over the visible preview text.
  * Pick an entry: it is placed on the clipboard with `wl-copy`, the surface closes, the owner pastes by hand.
  * Delete one entry, clear all entries.
  * A full keyboard flow, in the style of the other panels.
  * History is memory-only: the database lives under the runtime directory and is gone after reboot or logout.
  * An explicit refresh key while the surface is open.
  * A clear, one-line state when history is unavailable (unit off, database unsafe, command failed), different from "empty" and from "no matches".
  * The shell captures nothing and stores nothing durable.
* **Out-of-Scope Non-Goals:**
  * Pin (dropped by the owner: `cliphist` has no pin and a pin would be a second store).
  * Rules to bypass the store by app or regexp (dropped by the owner: it would mean changing the store logic; also `wl-paste --watch` gives no source app).
  * Incognito or pause (dropped by the owner).
  * IPC or a CLI for the surface (dropped by the owner).
  * Encryption (the owner does not need it).
  * Our own cap, expiry or dedupe settings. `cliphist` caps (`max-items`) and dedupes; the owner removes entries by hand.
  * Pasting into the focused window, with a synthetic keystroke (`wtype`, virtual keyboard): DM5.2, NC5.2 and OM5.4 do this; we do not.
  * Any capture code, watcher, daemon or fallback when the unit is not running.
  * Starting, enabling or restarting the unit from the shell. The owner starts it by hand.

## Alternatives Weighed

* **Native data-control daemon in the shell (DM1.x, NC1.x).** Rejected by the owner: no new background code, and the package already ships the capture service. Quickshell has no data-control binding anyway (QS2.x).
* **Own watcher started by the shell, or `exec-once` lines (DH1.1).** Rejected by the owner: the stock unit does this.
* **Store on disk with encryption (AX2.2, AX2.4).** Rejected by the owner: memory-only is wanted and encryption is not needed.
* **Clipboard as a launcher mode (DH4.1, AX4.11).** Rejected by the owner: the GUI will need changes for new logic. The reviewers' objection stands (duplicated list, search and key flow) and is recorded as a condition: reuse the launcher's list and animation components.
* **`Quickshell.clipboardText` as the read/write path (QS1.x).** Rejected: text only, empty unless a Quickshell window is focused (QS1.2), no history. `wl-copy` is used for writing.
* **Synthesised paste (DM5.2, NC5.2, OM5.4).** Rejected by the owner: set the clipboard, paste by hand.
* **Rules, incognito, IPC.** Dropped by the owner during brainstorming (see Non-Goals).

## Key Decisions & Staging

**Decided (from the owner)**
1. The store is the stock `cliphist.service`. The shell writes no capture code.
2. `cliphist` config file sets `db-path` to a memory-backed path. History is lost at reboot or logout. Encryption is not needed.
3. Expiry and dedupe are manual or `cliphist`'s own. No settings of ours.
4. The surface is separate from the launcher.
5. Selecting sets the clipboard and the owner pastes by hand.
6. No rules, no incognito, no IPC or CLI.
7. If the unit is not running there is no fallback and no workaround.
8. Images are never loaded for the list; a placeholder is shown.
9. The scope is everything else the study offers except IPC/CLI and pin: search, delete one, clear all, keyboard flow.
10. Pin is dropped.
11. The floating-window toggle moves from `Super+V` to `Super+Z`; the clipboard surface takes `Super+V`.
12. The `cliphist` config (with `db-path` under the runtime directory) is seeded as part of the shell's config.
13. The owner starts the unit by hand. Tests and the nested environment start the same command (`wl-paste --watch cliphist store`) in the background with the pre-made config, so they do not depend on systemd.
14. Refresh: the list is read when the surface opens, and an explicit refresh key re-reads it while open. Nothing refreshes by itself.
15. Image preview, if shown, stays in memory only: the decoded bytes are held by the shell as a data URL for one entry at a time and dropped when selection moves or the surface closes. No file is written.
16. The surface asks to be hidden from capture with the same Hyprland layer rule the auth card uses (`no_screen_share`, `hypr/rules.lua`). The owner knows `gpu-screen-recorder` may ignore it and wants it anyway: no fallback, no refusal to open while recording. The docs say what was measured, not what was hoped.
20. Selecting runs a plain `wl-copy`, with no `--sensitive`. The watcher stores the copy again, so the picked entry moves to the top with a new id. This is accepted. No extra mechanism.
17. A file entry shows as its path text, with the home directory shown as `$HOME` instead of the full path. This is display only; picking the entry copies the original bytes. Other kinds (HTML and so on) are shown as their preview text.
18. Clear all asks for confirmation. Deleting one entry does not.
19. A small `max-items` is seeded in the cliphist config. The number is chosen in the design (reviewers suggested 50 to 100).

**Verified here (2026-11-10)**
* The unit exists, runs `wl-paste --watch cliphist store`, is `disabled` and `inactive`.
* `cliphist` reads a plain `key value` config; `db-path` and `max-items` work.
* `CLIPBOARD_STATE=sensitive` and `=clear` make `cliphist store` store nothing.
* Identical content is stored once. `delete` and `decode` work from a list line.
* `wl-copy` has `--sensitive` and `--type`.
* The user runtime directory is tmpfs, 3.2 GB.
* The keys V is already bound (see Analysis 3).

**Open for the owner**
None.

**Conditions carried into the design** (reviewer findings accepted as constraints; none changes the owner's decisions)
* Content reaches `cliphist` and `wl-copy` only through standard input of a fixed command; never in argv or a shell string.
* All shell-side state is keyed by content, never by `cliphist` id.
* Every `cliphist` call has a timeout (a lock collision with the watcher can hang a call).
* Empty states are distinct: history unavailable, empty, no matches.
* Search is documented as preview-only.
* Tests use a fake command with canned list lines (including quotes, tabs and newlines) and a scratch config path, so no test touches the owner's real history. Whether `make test-env` runs a real watcher is a design question.
* Reuse the launcher's list, search and animation components and the panel group; the surface must not copy them.
* No clipboard text in error details or logs.

**Proposed stages**
1. Surface, shortcut, list from `cliphist list`, search, select (copy), close, unavailable states, tests with a fake.
2. Delete one and clear all.
3. Image placeholder rows and, the in-memory on-demand preview (Decided 15).

Decisions that settle go into the brain through the `brain` CLI. The code that follows gets `EGM.md` contracts through `/egm-bootstrap`, not by hand.

## Acceptance checks

1. With the unit running and the config in place, copy five different texts; open the surface; the five appear newest first.
2. Search narrows the list; clearing the search restores it; a search with no hit shows "no matches", not "empty".
3. Pick an entry, press Ctrl+V in another window; that text is pasted. The surface closed on pick.
4. Copy an image; it shows as a placeholder with its size; picking it and pasting in an image-capable app works.
5. Delete one entry; it is gone after reopening. Clear all; the list is empty.
6. Stop the unit; the surface shows an "off" state, not an empty list. Remove the config or point `db-path` outside the runtime directory; the surface refuses to show history.
7. Copy from a password manager; the entry is not in the list.
8. Reboot; the history is empty.
9. An entry containing a quote, a tab and a newline is listed, picked and deleted without error and without running any command.
10. The old floating-window bind (or the chosen new one) still works after the shortcut is added.
11. Recorder check (on a normal session, not `make test-env`): start a recording with the surface open and look at the result. Write down whether the surface is visible. Either outcome is accepted; the finding goes into the design and the docs.
