# Shell menu (dmenu-style)

* **Author:** djeddi-yacine
* **Date:** 2026-11-10
* **Status:** Draft design. Not reviewed.
* **Requirements:** [../reqs/dmenu-menu.md](../reqs/dmenu-menu.md)
* **Study:** [../studies/dmenu-menu.md](../studies/dmenu-menu.md)

## Overview

A program pipes a list of lines into a small client script, `scripts/menu`. The shell shows the lines in a card styled like the clipboard panel. The user filters and picks one; the client prints that line and exits 0. Esc, a click outside the card, the caller dying or the shell going away ends the call with exit 1 and no output. The first consumer and acceptance test is `uuctl` (from `uwsm`), which calls its menu command 4 to 7 times per run.

The client and the shell talk through a spool directory under `$XDG_RUNTIME_DIR`. There is no socket and no Quickshell IPC. A request is a directory holding the items, a small JSON file and a named pipe. The shell watches the directory, shows the request, and writes the answer into the pipe.

## The Problem

`uuctl` and similar tools need a menu program. `fuzzel`, `rofi` and `bemenu` work, but they do not look like the shell and do not share its theme or keys. The shell has no way for an outside program to ask it for anything, so a menu cannot be built into it today.

## Goals

- Items on stdin, one per line. The chosen line on stdout. Exit codes for choose, cancel, usage error and shell not reachable.
- A card that reuses the existing panel look and the list and search code of the clipboard module.
- `uuctl scripts/menu -p` works end to end, including cancel at every stage.
- Several callers at once: one queue and one tab per app. Ctrl+Left and Ctrl+Right switch tabs.
- Every close path gives the caller exactly one answer.
- Items are never placed in argv, a shell string, a log or an error message.

## Non-Goals

- A command named `dmenu`, `rofi` or `fuzzel`, or any imitation of another program.
- Styling flags (`-fn`, `-nb`, `-nf`, `-sb`, `-sf`). The theme decides the look.
- `-i`, `-l`, `-sep`, NUL input, index or format output, icons, multi-select, custom exit codes.
- Returning typed text that matches no item.
- Several menus open at once. One card is visible; the rest wait.
- Cancelling a request because focus moved. Focus is not a cancel.
- Fixing the "shell crashed and left a stale pid file" case beyond the pid and `comm` check described below.

## Critical User Journeys

1. **One call.** The user runs `uuctl`. The card opens on the launcher screen with the prompt as its title. They type to filter, press Enter on a row. The row's text is returned, the card closes.
2. **A `uuctl` chain.** Stage 1 returns; `uuctl` starts stage 2 within a few milliseconds. The card has started its leave animation; stage 2's request arrives during it and the card enters again from where it is, showing stage 2's list. There is no timer and no fixed gap.
3. **Two apps.** While `uuctl`'s card is open, another program calls the client. Its request waits under its own app name. A tab strip animates in with two tabs. Ctrl+Right shows the second app's list. Answering one request does not touch the other. When one app has no requests left its tab animates out; with one app left the strip animates away.
4. **Cancel.** Esc or a click on the dimmed area answers the current request with "no choice" (exit 1). The next request in that app's queue is shown.
5. **Caller dies.** The user presses Ctrl+C in the terminal running `uuctl`. The client exits and the shell deletes its request. If the request was the visible one, the next one is shown, or the card closes.
6. **No shell.** The shell is not running. The client prints `menu: the shell is not running` on stderr and exits 3 within the time of one process start.

## Technical Plan

### Components

```
 caller (uuctl)                       client scripts/menu                      shell
 ──────────────                       ───────────────────                      ─────
 items on stdin ───────────────────▶  write staging dir:                       MenuState
                                        items, meta, mkfifo result
                                      mv staging → spool/<seq>-<pid> ─────────▶ FolderListModel sees it
                                                                                FileView reads meta, items
                                      exec 3<>result; read -t 1 loop           tail --pid watches client pid
                                                                                card shows, user chooses
                                      ◀─────────────────────────────────────── Process: cat > result ("Y<n>" or "")
 $(…) = chosen line ◀───────────────  prints line, exit 0 (or exit 1)
                                      trap: remove request dir                  removes dir if client died
```

### Request layout

The spool is `$XDG_RUNTIME_DIR/ui-shell/menu/`, mode 0700, created by the shell at start. Inside it:

| Path | Written by | Content |
|---|---|---|
| `.shell` | shell, at start, replaced atomically | `<pid>` of the shell process. Removed on a clean exit when possible. |
| `<seq>-<clientpid>/items` | client | the items exactly as read from stdin, mode 0600 |
| `<seq>-<clientpid>/meta` | client | `{"pid": <client pid>, "app": "<name>", "prompt": "<text>"}` built with `jq --arg`, never by string concatenation |
| `<seq>-<clientpid>/result` | client | FIFO, mode 0600; the shell writes one line |
| `.new-*` | client | staging directories, ignored by the shell (hidden names) |

`<seq>` is the zero-padded nanosecond time (`date +%s%N`), so directory names sort in arrival order. The client creates `.new-<seq>-<pid>`, fills it, then renames it with `mv -T`. The rename is atomic, so the shell never sees a half-written request. Spike result: the shell sees the directory only after the rename.

### The client contract (`scripts/menu`, bash)

Usage: `menu [-p <prompt>] [--app <name>] [-h] [--]`. `bash` is used (not `sh`) for `read -t -u` on the FIFO.

- `-p` sets the prompt. `uuctl` appends `-p` as the last argument with the prompt as the value after it. A trailing `-p` with no value is a usage error (exit 2).
- `--app` overrides the app name. Default: the content of `/proc/$PPID/comm`, read with the `read` builtin. Empty or unreadable: `unknown`.
- Any other flag: `menu: unknown option <flag>` on stderr, exit 2.
- Standard input is copied to `items` with `cat`, so the items never appear in argv or in a variable. If the copy is zero bytes the client exits 1 without creating a request. If it exceeds `maxItemBytes` (default 8 MiB, constant at the top of the script) the client exits 2 with a message.
- Before creating anything: the spool directory must exist, `.shell` must hold a pid, `/proc/<pid>` must exist and `/proc/<pid>/comm` must be `quickshell`. Otherwise exit 3.
- After the rename the client opens the FIFO with `exec 3<>result` (read-write, so it does not block waiting for a writer) and loops on `read -r -t 1 -u 3 reply`:
  - a line arrived: leave the loop;
  - timeout (status above 128): run the liveness check (below) and read again.
- **Liveness check** each second: the shell pid (read from `.shell` once, at start, so a restarted shell never answers the requests of the one before it) is alive and its `comm` is `quickshell`; and the client's parent still exists, together with each parent above it that is an identical copy of it (same command line, taken with `ps -o ppid=` at start), because a `$(...)` subshell is such a copy and outlives a caller killed with SIGKILL. The walk stops at the first process that is another program: a launcher shim above the caller (the shell's own app runner ends right after the hand-off) may end while the caller carries on. Shell gone: print `menu: the shell stopped` and exit 3. Any caller process gone: exit 1.
- Reply `Y<n>`: print line `<n>` of `items` (counted from 1, read from the file the client wrote) followed by one newline, exit 0. Any other reply, including the empty line: exit 1 and print nothing.
- A `trap` on `EXIT INT TERM HUP` removes the request directory. SIGKILL cannot run it; the shell removes the directory then.

Exit codes: 0 chosen; 1 no choice; 2 usage error or input too large; 3 shell not reachable.

A chosen line is returned byte for byte plus one newline; `Y` is only a protocol marker and is removed. An item that is itself empty is returned as an empty line with exit 0 (this is what `uuctl` sends for an empty list, and it decides what `uuctl` does next).

### Shell state (`MenuState`)

A singleton `QtObject`, as for `ClipboardState` and `AuthState`, not a member of the `PanelGroup`.

- `Quickshell.processId` is written to `.shell` at start by a `FileView` with atomic writes. Starting with a spool that holds old request directories removes them first (their clients are gone or will see exit 3/1 within a second; the shell cannot answer them).
- A `FolderListModel` (`Qt.labs.folderlistmodel`, directories only) is used only as the signal that the spool changed. It is not the source of truth: a reset of that model re-creates every row, which re-admitted an answered request whose client had not yet removed its directory (the card closed, reopened and closed again). On each change a `find` reads the spool afresh (names only), and `reconcile` keeps exactly one `MenuRequest` per directory name for as long as the directory exists: new names get an object, names that left get theirs destroyed and are taken out of the queue, and a name already known is never admitted again. A change during a read schedules one more read. A name that scripts/menu never makes, or a request whose `meta` is invalid JSON or whose `pid` is not a positive integer, is deleted and ignored (no answer: the client's own parent and shell checks end it).
- `MenuRequest` holds: `id`, `app`, `prompt`, `items` (array of strings), `dir`, a `Process` named `watch` running `tail --pid=<pid> -s 0.2 -f /dev/null`, and a `Process` named `reply`. `command` is set first and `running` turned on afterwards, because a binding order bug in the spike made `tail --pid=0` run.
- When `watch` exits the client is gone; the shell calls `drop()`, which removes the directory with `rm -rf -- <dir>` through a `Process` (the directory path is built from a name that passed `^[0-9]+-[0-9]+$` and never from item text).
- `answer(line)` and `cancel()` write through `reply`: `sh -c 'cat > "$1/result"' menu <dir>`, with `Y<n>\n` or `\n` supplied on stdin by `Process.write()`. Item text only ever goes through stdin. Both are guarded by an `answered` flag so a request is answered once.
- Groups: `apps` is a list of `{name, requests[]}` ordered by the first request's arrival. `current` is the app shown. The visible request is the first of `current`'s queue. When `current`'s queue empties the shell moves to the next app, or the card leaves.
- `open` is true while any request exists. `screenName` is `Config.Outputs.launcherScreen(Quickshell.screens)` evaluated at the time the card opens.
- `UI_SHELL_OPEN_MENU=1` opens a preview request with fixed fake items (for a look and for tests); it creates no files in the spool.

### Closing and hand-over

There is no timer. When the last request is answered the queue is empty, `open` turns false and `MenuSurface` starts the card's leave animation (`motion.leave()`); the windows stay mapped until it ends. During it the panel keeps showing the last request, as it was, with input ignored. A request that arrives in that time makes `open` true again; the surface calls `activate()`, which resets the motion and enters again, so a `uuctl` chain shows one card that fades out and back in with the next list, however long the gap. If another app has a request, it is shown immediately and the card does not leave.

### The card

`MenuSurface` follows `ClipboardSurface` exactly: a scrim window (layer `Top`, no keyboard focus, click means cancel the visible request) and a card window (layer `Overlay`, `Exclusive` keyboard focus while visible). The card's namespace is `ui-shell-menu` and the scrim's is `ui-shell-menu-scrim`. The card is requested to be hidden from screen capture, because items can be secrets: a `no_screen_share` rule in `hypr/rules.lua` like the clipboard's. Whether `gpu-screen-recorder` honours it is the same untested fact as for the clipboard.

`MenuPanel` contains, top to bottom: the tab strip (height 0 with one app; a tab is the app name, with a count when several requests wait), the title row (the prompt as the title, in the title size and semi-bold, without its trailing space and colon, and `pid <n>` of the asking client dimmed on the right, hidden when there is none), the search field, the list, and a footer with `n/m` matches. The list uses the clipboard row look. It reuses `ClipboardSearch` through a shared copy (see Decision 2). Keys: typed text filters; Up/Down/PageUp/PageDown move; Home/End jump; Enter answers with the selected row; Esc cancels; Ctrl+Left/Ctrl+Right switch the app tab and wrap; Ctrl+Space lists keys (the existing help component). Enter with no matching row does nothing. Rows render as `PlainText`, one line, elided.

The tab strip animates in when the second app appears and out when only one is left, through the existing `Motion` tokens (`motion.enter()` / `motion.leave()`), never instantly. Each tab shows the app name and, when its queue holds more than one request, a count.

Closing: the card's close path calls `MenuState.cancel()` for the visible request and nothing else. It does not use the clipboard's `closed()` signal for the answer: the answer is already written before the animation, so the caller is released immediately and the animation can run after.

### Decisions

**Decision 1: where the client finds the shell.** The shell writes its own pid; the client trusts a `.shell` file only if `/proc/<pid>/comm` is `quickshell`. Fails when pid reuse gives another process the same name (the check then passes and the client waits; the liveness loop cannot tell). This is accepted: a second quickshell process on the same runtime directory is not a case the shell supports.

**Decision 2 (reversed during implementation): the menu has its own search.** The design first shared one filter through `shell/components/WordFilter.qml`. The existing test harness (`tests/scripts/check-qml`) copies standalone files into a private tree, so a shared singleton needs more harness change than the four-line filter it would remove. `MenuSearch` (`shell/modules/menu/MenuSearch.qml`) returns indexes into the request's lines and has its own tests; the clipboard module is untouched.

**Decision 3: the card does not join the panel group.** A pending request must never be cancelled silently. Cost: the user can open the app launcher over a waiting menu, since global shortcuts still work; the menu card keeps exclusive keyboard focus only while it is visible and the other panel also maps, so which gets keys depends on the compositor. The menu card therefore hides itself (without answering) while another group panel is open and returns when it closes. This hide-and-return rule is implemented in `MenuSurface` by reading the `open` state of the panel group members.

### Configuration (`Config.Menu`)

`namespace`, `scrimNamespace`, `cardWidth`, `cardHeight`, `outerMargin`, `panelPadding`, `rowHeight`, `scrimOpacity`, `previousTabKey` (`Qt.Key_Left` with `Qt.ControlModifier`), `nextTabKey`, `emptyText`, `noMatchText`, `tabAnimationMilliseconds` (taken from the `Motion` tokens, not new numbers), and the keys of the list as in `Config.Clipboard`. The client's `maxItemBytes` is a constant in the script and is not read from config.

### Tests

- `tests/scripts/check-menu` (bash, no session): runs the client against a fake shell implemented as a shell loop in the test (it watches the spool, writes `.shell` with the test shell's pid and a stand-in `comm` check through an overridable `UI_SHELL_MENU_COMM_ROOT` that defaults to `/proc`). Cases: choose returns the exact bytes plus newline; cancel exit 1 and empty stdout; empty stdin exit 1 and no request created; unknown flag exit 2; missing trailing prompt value exit 2; input over the cap exit 2; no `.shell` exit 3; shell pid dead exit 3; shell dies mid-wait exit 3 within 2 s; parent killed with SIGKILL exit 1 and no leftover `cat` or client process; two clients at once get their own answers; items containing a marker string appear in no argv (stand-in `jq`, `cat` and `mkfifo` log their arguments); the request directory is removed in every case but SIGKILL.
- `tests/tst_MenuState.qml` (`make test-qml`): grouping per app, FIFO order inside an app, `answer` once only, drop on watcher exit, tab count and wrap.
- `tests/menu/uuctl-run` (by hand, in `make test-env`): a script that runs `uuctl scripts/menu -p` with `uuctl`'s state directory in scratch; the owner checks a full run and a cancel at each stage on screen. This is the acceptance test.
- Layer namespace: `make test-hypr-config` gains the two new namespaces.

### Staging

1. Client and its test (no QML).
2. `MenuState` and its test.
3. Surface, panel, tabs, keys.
4. Hyprland rules, docs, `uuctl` run on screen.

## Alternatives Considered

- **Quickshell `IpcHandler` with `qs ipc call`:** Rejected by author: arguments are strings only so large lists hit the argument limit, items would pass through argv (the secrets rule forbids that), the call returns at once so choice and cancel need a second channel, and nothing reports the caller's death.
- **`SocketServer` with a client:** Rejected by author: plain `sh` cannot speak a unix socket, so the client needs `socat` or a compiled helper, and a new protocol and security surface for no gain over a spool directory that the shell already reads with built-in types.
- **One Quickshell instance per call:** Rejected by author: start-up cost 4 to 7 times per `uuctl` run, no shared tab or queue state.
- **D-Bus:** Rejected by author: Quickshell cannot export a method from QML.
- **The shell launches the caller:** Rejected by author: it makes the shell the parent of arbitrary programs and does not fit `uuctl`, which is started by the user.
- **Pretending to be `dmenu`:** Rejected by author (owner): the menu has its own interface.
- **Cancel on focus loss:** Rejected by author (owner): focus is only focus until a cancel.
- **Joining the panel group:** Rejected by author: a request would be cancelled silently by an unrelated panel. The card hides and returns instead.
- **A heartbeat file written every second by the shell:** Rejected by author: constant writes for what a pid and `comm` check plus the client's own one-second loop already gives.
- **A linger keyed on process group or an explicit session id for `uuctl`:** Rejected by author: the parent process name already gives one app for all stages, and the leave animation covers the gap; an explicit id needs `uuctl` to export one, which it does not.
- **Tier 1 and tier 2 flags:** Rejected by author: no consumer needs them; every flag would be a permanent contract with tests.

## Detailed Implementation Plan

### New files

- `scripts/menu`: the client described above. Bash, `set -u`, absolute-safe paths, every external command called with `--`.
- `tests/scripts/check-menu`: the client test.
- `tests/tst_MenuState.qml`: state tests.
- `tests/menu/uuctl-run`: manual acceptance script.
- `shell/modules/menu/MenuSearch.qml`: the word-by-word filter, with `tests/tst_MenuSearch.qml` (Decision 2).
- `shell/config/Menu.qml`: constants listed under Configuration.
- `shell/modules/menu/MenuState.qml`: singleton, spool watching, groups, answering.
- `shell/modules/menu/MenuRequest.qml`: one request (meta, items, watch and reply processes).
- `shell/modules/menu/MenuSurface.qml`: scrim and card windows.
- `shell/modules/menu/MenuPanel.qml`: tab strip, prompt, search, list, footer, keys.
- `shell/modules/menu/MenuTabs.qml`: the animated tab strip.
- `shell/modules/menu/MenuRow.qml`: or a reuse of `ClipboardRow` through a shared base; decided when the code is read.
- `shell/modules/menu/qmldir`: `module UiShell.Menu`.
- `shell/modules/menu/EGM.md`: created with `/egm-bootstrap` only, not by hand.

### Modified files

- `shell/shell.qml`: import `modules/menu`, add `Menu.MenuSurface` in a `Variants` over `Quickshell.screens`, like the clipboard.
- `shell/config/qmldir`: register `Menu`.
- `hypr/rules.lua`: add `menu` and `menu-scrim` to the `shell-owns-motion` namespace list and a `menu-not-shared` rule for `^ui-shell-menu$`.
- `tests/targets.mk`: `test-menu` target, added to `.PHONY`, to the help text and to `test`.
- `tests/README.md`, `README.md`, `FEATURES.md`: describe the menu and how to call it (`uuctl <path>/scripts/menu -p`).
- `shell/modules/EGM.md`: add the `menu` entry (through `/egm-bootstrap`).
- `shell/config/EGM.md`, `shell/components/EGM.md`: contract updates for `Menu` (through `/egm-bootstrap`).
- `tests/nested.conf`: bind nothing new; the nested session already has the runtime directory. To check when implementing.

### Deleted files

None.

### Order of work

1. `scripts/menu` and `tests/scripts/check-menu`; run it.
2. `MenuSearch` and `MenuQueue` with their tests; run `make test-qml`.
3. `Config.Menu`, `MenuRequest`, `MenuState`, `tst_MenuState.qml`.
4. `MenuSurface`, `MenuPanel`, `MenuTabs`, `MenuRow`, `qmldir`, `shell.qml`.
5. Rules, `targets.mk`, docs.
6. `/egm-bootstrap` for the new and changed directories.
7. Owner runs `tests/menu/uuctl-run` in `make test-env`.

### Unverified (to check while implementing, not assumed)

- `read -t -u` on a FIFO opened `<>` returns the line and times out as expected on this bash.
- The parent-change check with `ps -o ppid=` notices a SIGKILLed parent when the client runs inside `$(...)`.
- `/proc/<pid>/comm` of the Quickshell process is `quickshell` and not `qs`.
- `uuctl`'s parent process name for the client is `uuctl` (its shebang may make it `sh`).
- Two windows hiding and returning while another group panel opens: whether the compositor gives keys to the right one.
- `gpu-screen-recorder` and `no_screen_share` (carried over from the clipboard).
