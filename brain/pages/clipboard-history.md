---
id: clipboard-history
title: "Clipboard history: view over stock cliphist, memory-only, separate surface"
category: decision
status: active
tags: [clipboard, shell]
created: "2026-11-10T14:16:06"
updated: "2026-11-10T16:32:16"
---

<!-- compiled_truth -->
The shell captures and stores nothing for clipboard history. The store is the package's own cliphist.service (wl-paste --watch cliphist store); the shell is a UI over cliphist list/decode/delete/wipe plus wl-copy. cliphist's config sets db-path to the runtime directory, so history is memory-only (gone at reboot/logout); no encryption. The config file is seeded as part of the shell's config. The owner starts the unit by hand; the shell never starts, enables or restarts it and has no fallback when it is off. Tests and the nested environment run the same command in the background with the pre-made config. The surface is separate from the launcher and joins the panel group. Selecting sets the clipboard (wl-copy); the owner pastes by hand. Images show as placeholders from the list line and are not loaded. Dropped: pin, rules, incognito, IPC/CLI, own expiry/dedupe settings. Shortcut: Super+V; the floating-window toggle moves to Super+Z.


## Timeline

- time: 2026-11-10T14:16:06
  kind: decision
  summary: "Created this page: Clipboard history: view over stock cliphist, memory-only, separate surface"
  source: features/reqs/clipboard.md
  affects: [clipboard-history]

- time: 2026-11-10T14:16:06
  kind: decision
  summary: Owner decisions from the clipboard brainstorm
  source: features/reqs/clipboard.md
  affects: [clipboard-history]

- time: 2026-11-10T14:23:10
  kind: decision
  summary: "Refresh on open plus an explicit key; image preview in memory only; file entries shown as paths with HOME shortened; confirm only for clear all; small max-items seeded; the surface must never be captured by the recorder (whether no_screen_share holds for gpu-screen-recorder is untested); config seeded with the shell; owner starts the unit; pin dropped; floating toggle moves to Super+Z"
  source: features/reqs/clipboard.md
  affects: [clipboard-history]

- time: 2026-11-10T14:25:28
  kind: decision
  summary: "Select uses plain wl-copy (no --sensitive): the re-store moves the entry to the top, accepted. Hide from capture with the no_screen_share layer rule anyway; if gpu-screen-recorder ignores it, no fallback. No open points left in the reqs."
  source: features/reqs/clipboard.md
  affects: [clipboard-history]

- time: 2026-11-10T14:33:59
  kind: decision
  summary: "Design (features/designs/clipboard.md): backend is a bash wrapper scripts/clipboard plus an Adapters.ClipboardRunner singleton (like screen-shot); the launcher list with its transitions is extracted into a shared components/ShellListView used by both panels; the surface is a full-screen scrim window plus a card-sized window (ui-shell-clipboard) carrying no_screen_share, mirroring the auth dialog, because the rule on a full-screen layer would blank the whole capture; cliphist max-items 80; copy/delete/image verify the received list line against a fresh list and refuse on mismatch."
  source: features/designs/clipboard.md
  affects: [clipboard-history]

- time: 2026-11-10T14:52:50
  kind: decision
  summary: "Panel built as wrapper script + ClipboardRunner + shared ShellListView; tested via fakes (make test-clipboard) and tst_ClipboardSearch; no panel-level QML test (needs Quickshell types); config seeded by make dev-seed-clipboard and nested-session; Super+V clipboard, float toggle moved to Super+Z; awk is a required tool"
  source: tests/scripts/check-clipboard
  affects: [clipboard-history]

- time: 2026-11-10T15:59:03
  kind: decision
  summary: "Shift+Enter on a copied-file entry copies the file's content (text or picture, single file under HOME, size-limited by CLIPBOARD_FILE_LIMIT, default 8 MiB); Enter still pastes the address. Explicit key, no setting; script verb copy-content refuses anything else with exit 7."
  source: "owner choice A in chat; scripts/clipboard"
  affects: [clipboard-history]

- time: 2026-11-10T16:32:16
  kind: decision
  summary: "Enter (and Shift+Enter) closes the panel at once instead of waiting for wl-copy; a copy that fails afterwards reopens the panel and shows the error (ClipboardState.lateFailure)."
  source: "owner request in chat; shell/modules/clipboard"
  affects: [clipboard-history]
