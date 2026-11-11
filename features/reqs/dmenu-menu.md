# Shell menu (dmenu-style)

* **Author:** djeddi-yacine
* **Date:** 2026-11-10
* **Status:** Draft brief. Transport, queueing and caller tracking are decided (2026-11-10); the remaining open decisions are listed at the end.
* **Study:** [../studies/dmenu-menu.md](../studies/dmenu-menu.md)

## Overview

A menu built into the shell that other programs can call. A program sends a list of choices, one per line; the shell shows them in a card styled like the clipboard and launcher panels, the user filters and picks one, and the chosen line goes back to the program. The first program that must work with it is `uuctl` (from `uwsm`, `/usr/bin/uuctl`), which controls user services through a "dmenu-like" menu.

The menu has its own command-line interface. It is not an interceptor named `dmenu` that pretends to be another program.

The reason to build it, and not to point `uuctl` at `fuzzel`, `rofi` or `bemenu`, is visual and theme consistency with the rest of the shell. Everything else about the feature has to be proportional to that reason.

## Analysis

### What `uuctl` actually does (checked in the script)

- It runs the menu command once per stage, 4 to 7 times in one run. Each call is a new process, one after the other.
- It pipes the choices to the menu's stdin and reads the answer from stdout inside `$(...)`. Stdout must carry only the chosen line, unchanged, because `uuctl` splits it afterwards (lines contain spaces and parentheses).
- It adds the prompt as the last argument, so the command must end in `-p`, and the value after `-p` is the prompt text (with a trailing `: `).
- Any non-zero exit means "cancelled". `uuctl` prints "Cancelled" and exits 0. It cannot tell cancel from error.
- For an empty list it sends one empty line.
- The stage variable (`MENU_STAGE`) is not exported, so a custom menu command cannot see which stage it is in. Each call looks like a brand-new caller.
- The call form is `uuctl <our-command> [flags] -p`.

### Contradictions found in the first concept

1. The tab switcher is justified by "several simultaneous calls", but `uuctl`, the first target, never makes two calls at once. No consumer has been named that does.
2. Every module in the shell takes exclusive keyboard focus. Two menus cannot both hold the keyboard, so "several open at once with tabs" becomes "one visible and the others waiting", which is a queue with a user interface.
3. "Own interface, not an interceptor" fits `uuctl`. It does not fit "tested with popular tools": most tools hard-code the name `dmenu` and only work through a symlink or wrapper, which is the interceptor the owner rejected.
4. The shell has no way for an outside program to talk to it today. Every module opens from a global shortcut, and `features/reqs/clipboard.md` lists "IPC or a CLI" as a non-goal. This feature reverses that for the menu, becomes the shell's first IPC, and sets a precedent.
5. The user's focus is also a cancel path. Another panel opening, a screen going away, or a shell reload can close the menu silently, and the caller must still get exactly one answer.
6. "Tab" is ambiguous. It could mean a visible strip, a key that cycles, or one slot per caller. In dmenu itself, Tab copies the selection into the input.

### Strongest counter-arguments

- No new code is needed to make `uuctl` work: it already supports `fuzzel`, `wofi`, `rofi`, `bemenu` and `tofi`. Only the look justifies new code.
- The tab switcher and rofi-style extras (`-format`, icons, `-sep`, NUL mode, exit codes above 10) are a second feature with no evidence of need. Every flag becomes a permanent contract that needs tests.
- Getting a request from a short-lived command into the running shell costs more than the menu itself: a listener, a protocol, a client program (plain `sh` cannot use a unix socket) and a security surface.

### Risks

- **Security.** A socket in `$XDG_RUNTIME_DIR` must be user-only, and any local process could otherwise pop a fake prompt on screen. Items may be secrets: never in argv, never in a shell string, never in logs. The card could be hidden from screen capture, as the clipboard does.
- **Failure paths.** If the shell is not running the client must fail fast with a distinct exit code, or `uuctl` hangs inside `$(...)`. A shell crash or reload during a call must also end the call with a non-zero exit. A stale socket file must be removed on start.
- **One answer exactly once.** Enter, Esc, scrim click, another panel taking over, screen removal, caller death and shell reload must each produce exactly one answer. The clipboard panel's close animation (`motion.leave()` then `closed()`) needs adapting for this.
- **Routing.** Results must be tied to their own connection, never to a "current menu" global.
- **A stuck request blocks everyone behind it.** A waiting menu holds keyboard focus and blocks the user's other panels. It needs a visible count of waiting menus and a way to dismiss.
- **Result rules.** Empty output with exit 0 must never mean cancel. The empty-list case and the "typed text matches nothing" case need a defined behaviour.

### Ideal Final Result (minimal, agreed by most reviewers)

A thin client, run as `<command> -p "Prompt: "`, reads lines from stdin to the end, shows one card on the launcher screen styled like the clipboard panel, filters while typing, and prints the chosen line plus a newline with exit 0. Esc, scrim click or caller death prints nothing and exits non-zero. "Shell not reachable" has its own exit code and a message on stderr. Concurrent callers wait in a first-in-first-out queue, one visible at a time. `uuctl <command> -p` works end to end, including cancel at every stage. This is a recommendation of the reviewers, not a decision: the owner has asked for a tab-like switch, and that point is open below.

## Goals vs. Non-Goals

* **In-Scope Goals:**
  - Items on stdin, one per line; chosen line on stdout; exit code for choose and cancel.
  - A shell-styled card that reuses the existing panel look and keyboard handling.
  - Works as the full menu command for `uuctl`, end to end.
  - Several calls at once handled cleanly, with a switch between them (exact form open).
  - A clean, documented command interface of its own.
* **Out-of-Scope Non-Goals (proposed, not yet confirmed):**
  - A command named `dmenu`, `rofi` or `fuzzel` that imitates another program.
  - Styling flags such as `-fn`, `-nb`, `-nf`, `-sb`, `-sf`: the shell theme decides the look.
  - Features beyond the first version until a real consumer needs them: icons, `-format`, index output, custom exit codes, multi-select.

## Alternatives Weighed

Transport (the main cost driver). Each has a reason it might be rejected:

- **Quickshell `IpcHandler` with `qs ipc call`.** Least code. Arguments are strings only, so large lists hit the argument size limit; a call returns at once with exit 0, so choice and cancel need a second channel; no signal when the caller dies. Whether `qs ipc call` can block was not verified.
- **Quickshell `SocketServer` with a small client.** The open connection is the unit of work, so close means cancel and routing is per connection. Most new code, a new protocol and security surface, and the client is a problem because plain `sh` cannot speak a unix socket (needs `socat`/`ncat`, a compiled helper or Python). Half-close and mid-call disconnect handling in Quickshell were not verified.
- **A separate Quickshell instance per call.** No IPC and no daemon. Start-up cost is paid 4 to 7 times per `uuctl` run, and the shell's shared state is lost.
- **Spool files plus a FIFO.** Racy, no connection identity, weak cancel and death detection.
- **Wrap an existing `fuzzel`.** Rejected by the owner's intent: no shell integration.

Several calls at once:

- **Queue only.** Smallest; fits exclusive focus and `uuctl`. A blocked caller has no visible state unless a badge is added.
- **Queue plus a tab strip shown only when more than one call is pending.** One menu is visible, so focus still works. Adds state and a focus model that behaves differently under load, with no real consumer yet.
- **Truly several open menus.** Conflicts with exclusive focus.
- **Reject while busy.** Simplest, but not "several calls".

Chains of calls from one program (`uuctl` stages): use the parent process or process group with a short linger to keep one slot, or an explicit session id. PID checks fail across wrapper scripts and a linger adds delay. Without either, the card may flicker between stages.

Focus loss: cancel (fuzzel) can strand the queue; no cancel (bemenu, rofi) is simplest; hide without cancel risks a caller that looks hung.

Flag tiers: Tier 0 is `-p`, stdin, stdout, exit codes. Tier 1 adds `-i`, `-l`, preselect, `-sep`/NUL, run-nothing-if-empty. Tier 2 (index, icons, exit codes above 10, typed-text return, multi-select) waits for a consumer.

## Key Decisions & Staging for Next Steps

### Decided

- The menu has its own command interface; no program is impersonated. (Owner.)
- `uuctl` is the first consumer and the first acceptance test. (Owner.)
- The look follows the existing panels, with room for what the menu needs. (Owner.)
- Several calls at once must be supported, with a clean tab-like switch. (Owner. Exact meaning open.)
- Return value and cancel behaviour follow the study: chosen line to stdout with exit 0; non-zero means no choice. (Owner delegated to the study.)
- **Transport: spool folder plus a FIFO per request (option A).** The client is a plain `sh` script. It writes `items` and `meta` (JSON: pid, app, prompt) into a hidden staging directory, makes a FIFO `result`, renames the directory atomically into the spool under `$XDG_RUNTIME_DIR`, and blocks reading the FIFO. The shell watches the spool, shows the request, and writes the answer to the FIFO. No socket and no `IpcHandler`. (Owner: "A is the call".)
- **Several calls: one queue per app, one tab per app.** Requests are grouped by the `app` field of `meta`. (Owner.)
- **Caller tracking by PID.** The shell watches the caller pid and removes the request when the caller dies. (Left to the author by the owner; chosen here.)
- Reversal of the clipboard requirement "no IPC or CLI": it applies to this menu only. To be written into the design.
- `shell/modules/menu/EGM.md` must come from `/egm-bootstrap`, not by hand.

### Spike findings (scratch, offscreen Quickshell 0.3.2, real shell untouched)

- `FolderListModel` sees a new request directory only after the atomic rename. `FileView` reads `meta` and `items`.
- The answer is written by a `Process` (`cat > result`), so the UI never blocks. Choose returned the line byte for byte with exit 0; cancel (empty write) gave exit 1 and no stdout; the request directory was removed.
- Caller death: `tail --pid=<pid> -f /dev/null` as a `Process` exits after the caller is killed with SIGKILL. `command` must be set before `running` is turned on. With SIGKILL the client's cleanup trap cannot run, so the shell must delete the stale directory itself.
- The client must wait with the shell builtin `read` on the FIFO. A `cat` child outlives a killed client and keeps the pipe open.
- Not yet verified: the shell-side cleanup of dead-caller directories, two concurrent clients with per-app grouping, very large lists, spool permissions (0700 and owner check), and behaviour inside the real shell or the nested test session.

### Decided on 2026-11-10 (second round)

- **Cancel means exit.** Esc, scrim click, caller death and shell reload end the call with exit 1 and no stdout. Focus loss is not a cancel: the menu stays until one of those happens. (Owner.)
- **Tab switch.** Ctrl+Left and Ctrl+Right move between app tabs. The strip is not visible while only one app has requests. When a second app appears, the strip animates in; it does not appear instantly. It animates out when back to one. (Owner.)
- **Panel group: outside it.** Like the auth dialog, the menu does not join the panel group, so another panel opening never cancels a pending request silently. (Author's choice, delegated by the owner.)
- **Flags.** Only `-p <prompt>`, `--app <name>` (overrides the tab name) and `-h`. `--` ends flags. Any other flag fails loudly with exit 2 and a message on stderr. No styling flags, no `-i`, `-l`, `-sep`, index or format output. (Author's choice.)
- **Result rules.** Empty stdin (zero bytes) exits 1 without showing anything. A blank line is an item and shows as an empty row (this is what `uuctl` sends for an empty list). Typed text that matches nothing leaves Enter doing nothing; the menu never returns the typed text. Matching reuses the clipboard word-by-word case-insensitive filter, history order kept. (Author's choice.)
- **Tab identity for `uuctl` chains.** The app name is the `comm` of the client's parent process (`/proc/$PPID/comm`). `uuctl` calls the menu inside `$(...)`, which is a subshell of `uuctl`, so every stage maps to one app. There is no timed hold between stages: an answered card plays its leave animation, and a request that arrives during it brings the card back (reversal: a fixed hold was an implicit timing guess; the real `uuctl` gap was never measured). (The `comm` assumption is unverified.)
- **Client.** Named `ui-shell-menu`, plain `sh`. Exit codes: 0 chosen, 1 no choice (cancel, empty input), 2 usage error, 3 shell not reachable (spool directory missing). (Author's choice.)

### Open

1. Shell-crash detection: a crashed shell leaves the spool directory behind, so the client would wait forever. A heartbeat file the shell touches and the client checks is the candidate; not designed or tested.
2. Which exact words the tab strip shows (app name only, plus a count of waiting calls?).
3. Acceptance: `uuctl` alone, or named tools with versions.

### Unverified

- Quickshell `IpcHandler` and `SocketServer` behaviour on the installed version (none are used in the repo or in `refs/`).
- Reviewers could not read `shell/modules/apps/`; reuse claims rest on the clipboard module only.

### Acceptance checks (proposed)

- `uuctl <command> -p` completes a full run, with cancel tested at every stage.
- Chosen line returned byte for byte plus one newline; nothing else on stdout.
- No shell running: fast failure with the distinct exit code and a stderr message.
- Caller killed mid-menu: the entry leaves the queue.
- Two clients at once: isolated results.
