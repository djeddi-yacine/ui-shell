---
id: shell-menu-dmenu
title: "Shell menu: dmenu-style, spool folder plus FIFO, queue and tab per app"
category: decision
status: active
tags: [menu, shell, ipc]
created: "2026-11-10T23:07:17"
updated: "2026-11-11T01:17:48"
---

<!-- compiled_truth -->
The shell gets a dmenu-style menu that other programs call through its own command (not an impersonated dmenu). First consumer and acceptance test: uuctl (uwsm). Transport: a plain-sh client writes a request directory (items, meta JSON with pid/app/prompt, a FIFO named result) into a spool under $XDG_RUNTIME_DIR via atomic rename, then blocks on the FIFO with the shell builtin read; the shell watches the spool (FolderListModel/FileView), shows the card, and writes the answer to the FIFO. No socket, no IpcHandler. Chosen line goes to stdout with exit 0; any non-zero exit means no choice. Several callers: one queue and one tab per app (grouped by meta.app). The shell watches the caller pid (tail --pid) and deletes the request of a dead caller itself, since SIGKILL skips the client's cleanup. This reverses the clipboard non-goal "no IPC/CLI" for the menu only. Menu items may be secrets: never in argv, logs or shell strings. Open: cancel/focus-loss policy, panel group membership, flag set, empty/no-match rules, uuctl session linger, client name and exit codes. Details: features/reqs/dmenu-menu.md.


## Timeline

- time: 2026-11-10T23:07:17
  kind: decision
  summary: "Created this page: Shell menu: dmenu-style, spool folder plus FIFO, queue and tab per app"
  source: features/reqs/dmenu-menu.md
  affects: [shell-menu-dmenu]

- time: 2026-11-10T23:07:22
  kind: decision
  summary: Transport and grouping decided
  source: features/reqs/dmenu-menu.md
  affects: [shell-menu-dmenu]

- time: 2026-11-10T23:07:22
  kind: decision
  summary: "Owner chose option A (spool + FIFO), queue and tab per app, PID tracking; spike verified in scratch"
  source: features/reqs/dmenu-menu.md
  affects: [shell-menu-dmenu]

- time: 2026-11-10T23:11:26
  kind: decision
  summary: "Cancel means exit, focus is not cancel; Ctrl+Left/Right switches app tabs, strip hidden until 2 apps and animated; menu outside panel group; flags -p/--app/-h, unknown flag exit 2; app name from parent comm; client ui-shell-menu exit 0/1/2/3"
  source: features/reqs/dmenu-menu.md
  affects: [shell-menu-dmenu]

- time: 2026-11-10T23:16:25
  kind: decision
  summary: "Design written: client scripts/menu (bash, FIFO read -t loop with shell pid+comm and parent checks, exit 0/1/2/3), MenuState in shell/modules/menu outside PanelGroup, hold 400ms between stages, tab strip with count, card hides while another panel is open; shared WordFilter proposed"
  source: features/designs/dmenu-menu.md
  affects: [shell-menu-dmenu]

- time: 2026-11-10T23:28:13
  kind: reversal
  summary: "The menu has its own MenuSearch instead of a shared WordFilter in shell/components (the test harness copies standalone files; the filter is four lines). The client answers Y<n> (line number), reads the shell pid once and checks its caller's three nearest ancestors."
  affects: [shell-menu-dmenu]

- time: 2026-11-11T00:03:21
  kind: reversal
  summary: "The spool lifecycle no longer follows FolderListModel rows through an Instantiator: a model reset re-created every delegate, so an answered request whose client had not yet removed its directory was admitted again (card closed, reopened, closed) and queued requests dropped out for about 10 ms. The model is now only a change signal; a find reads the spool and MenuState.reconcile keeps one MenuRequest per directory name and never re-admits a known name. MenuQueue owns open/holding: the hold starts before the answered request leaves and ends after the next one is queued."
  source: features/designs/dmenu-menu.md
  affects: [shell/modules/menu/MenuState.qml, shell/modules/menu/MenuQueue.qml]

- time: 2026-11-11T00:15:17
  kind: reversal
  summary: "The 400 ms hold between uuctl stages is removed: it was an implicit timing guess never measured against uuctl's real gap. MenuQueue.open = not empty; the card plays motion.leave() after the last answer (MenuSurface keeps the windows mapped until closed()), MenuPanel keeps showing the last request meanwhile, and a request arriving mid-leave re-enters the card. No timer, no config value."
  affects: [shell/modules/menu, shell/config/Menu.qml]

- time: 2026-11-11T00:22:48
  kind: decision
  summary: "The shell installs the uuctl hook itself: tools/scripts/seed-menu-entry writes the user's uuctl.desktop (Exec=uuctl <staged scripts/menu> -p) only when uuctl is installed and the file is absent, like seed-cliphist-config. nested-session and host-session seed their private data home; make dev-seed-menu seeds the real one. uuctl has no env var or config for its menu: the command line is the only hook."
  affects: [tools/scripts/seed-menu-entry, tools/uuctl.desktop, tests/scripts/nested-session, tests/scripts/host-session]

- time: 2026-11-11T00:33:02
  kind: decision
  summary: "Menu card title row = prompt (action label) with the asking client's pid on the right; tabs hold only the app name. The pid is the client's own, so it changes on each uuctl stage."
  source: owner chat
  affects: [shell/modules/menu]

- time: 2026-11-11T01:17:48
  kind: reversal
  summary: "Caller watch of scripts/menu no longer follows three ancestors: it watches the parent and identical copies above it, and stops at the first other program. The shell launcher's app runner exits after hand-off and used to cancel uuctl a second later."
  source: "owner chat; tests/menu/launch-check"
  affects: [scripts/menu]
