# menu (Program Menu)

## Overview
Overlay card that lets other programs ask the user to choose one line from a list. A program runs `scripts/menu` (items on standard input, the chosen line on standard output); the script writes a request directory into a spool under `$XDG_RUNTIME_DIR`, and this package reads the spool, shows the request, and answers on a named pipe. There is no socket and no Quickshell IPC; the lines travel through files only. Package URI `UiShell.Menu` ([qmldir]).

## Interface
- `MenuState` singleton: `spool`, `queue`, `blockers`, `blocked`, `open`, `screenName`, `requests`, `ready`, `visibleRequest`; `admit(request)`, `discard(request, reason)`, `reconcile(output)`, `requestScan()`, `choose(index)`, `cancel()`, `finish(shown, text)` [MenuState.qml:MenuState]
- `MenuSearch` singleton: `matches(lines, query)` returns indexes into `lines` [MenuSearch.qml:matches]
- `MenuQueue`: `entries`, `current`, `apps`, `visible`, `empty`, `open`; `add(entry)`, `remove(id)`, `cycle(step)` [MenuQueue.qml:MenuQueue]
- `MenuRequest`: `fileName`, `filePath`, `app`, `prompt`, `lines`, `callerPid`, `answered`, `broken`, `wellNamed`; signals `ready()`, `rejected()`, `callerGone()`; `reply(text)` [MenuRequest.qml:MenuRequest]
- `MenuSurface`: per-screen `Scope` with a scrim `PanelWindow` (namespace `Config.Menu.scrimNamespace`) and a card `PanelWindow` (namespace `Config.Menu.namespace`); `modelData`, `inputState`, `shown`, `mapped` [MenuSurface.qml:MenuSurface]
- `MenuPanel`: `screenName`, `inputState`, `shown`, `query`, `selectedIndex`, `request`, `held`, `content`, `title`, `lines`, `matches`, `hasRequest`, `contextOpen`, `entryView`, `pageSize`; `select(index)`, `moveSelection(delta)`, `answer()`, `activate()`, `forget()`, `leave()`, `showHelp()`, `handleKey(event)`; signal `closed()` [MenuPanel.qml:MenuPanel]
- `MenuRow`: `line`, `style`, `inputState`, `selected`, `candidateVisible`; signals `chosen()`, `activated()` [MenuRow.qml:MenuRow]
- `MenuTabs`: `style`, `apps`, `current`, `wanted`, `reveal`; signal `picked(name)` [MenuTabs.qml:MenuTabs]
- Request format written by `scripts/menu`: directory `<nanoseconds>-<client pid>` holding `items`, `meta` (JSON `{pid, app, prompt}`, `pid` is the client's own) and the named pipe `result`. The client builds it in a dot-named staging directory `.new-<id>` and publishes it with one atomic `mv -T`; the scan skips dot-names [MenuRequest.qml:wellNamed, meta, items; MenuState.qml:scan; scripts/menu].
- Client `scripts/menu [-p <prompt>] [--app <name>] [-h] [--]`: choices on standard input (at most 8 MiB), chosen line on standard output; exit 0 chosen, 1 no choice (cancelled, empty input, caller ended, answer pipe broke), 2 usage error or input too large, 3 shell not reachable. `app` defaults to `/proc/$PPID/comm`, else `unknown` [scripts/menu].
- The shell chooses the output through `Config.Outputs.launcherScreen` when the card opens [MenuState.qml:onOpenChanged].

## Invariants
- The spool is a directory named by `Config.Menu.spoolSubdirectory` under `$XDG_RUNTIME_DIR`, mode 700, emptied at start; `.shell` holds the shell's process id and is written only after the spool is ready [MenuState.qml:prepare].
- The spool listing is the single truth: `FolderListModel` is only a change signal; `reconcile` keeps one `MenuRequest` per directory name for as long as the directory exists and never admits a known name again, so an answered request is not shown twice [MenuState.qml:reconcile, listingChanges].
- A directory whose name does not match `^[0-9]+-[0-9]+$` is never read; it is discarded [MenuRequest.qml:wellNamed; MenuState.qml:reconcile].
- A request is admitted only when `meta` is valid (integer `pid` ≥ 1, string `app`, string `prompt`) and `items` was read; otherwise it is rejected and its directory removed [MenuRequest.qml:meta.onLoaded, admit, reject].
- An empty `app` is shown as `unknown` [MenuRequest.qml:meta.onLoaded].
- Requests are queued oldest first, grouped one tab per app; the visible request is the oldest of `current`; `current` changes only when its last request leaves, then to the first remaining app or `""` [MenuQueue.qml:visible, remove].
- Lines are matched by a substring search where every space-separated word must occur, case-insensitively; the sender's order is kept [MenuSearch.qml:matches].
- A request is answered once: `Y<n>` (the line counted from 1) or an empty line for no choice; `answered` blocks a second reply [MenuRequest.qml:reply; MenuState.qml:choose, cancel].
- Nothing is answered while no line matches; Enter does nothing then [MenuPanel.qml:answer].
- The card is open while any request waits (`queue.open`); there is no timer. After the last answer the windows stay mapped until the card's leave animation ends, and the panel keeps showing the last request meanwhile; a request that arrives during the leave brings the card back [MenuQueue.qml:open; MenuSurface.qml:mapped; MenuPanel.qml:held, content].
- The scrim and the card are separate windows so only the card (namespace `Config.Menu.namespace`) can be hidden from screen capture; the scrim (layer `Top`, no keyboard focus) cancels the visible request when clicked; the card (layer `Overlay`) has `Exclusive` keyboard focus only while shown [MenuSurface.qml].
- While any panel in `blockers` is open the card is hidden: `shown` turns false, keyboard focus is released and the windows leave and unmap. `MenuState.choose` and `cancel` return without answering while `blocked`, so nothing is answered, not even by the scrim during the leave animation [MenuState.qml:blocked, choose, cancel; MenuSurface.qml:shown].
- A request whose client process (`meta.pid`) is gone is dropped and its directory removed [MenuRequest.qml:watch; MenuState.qml:discard].
- The client waits on the answer pipe and gives up (exit 1) when the process it waits for ends: its parent plus every parent above it whose `/proc/<pid>/cmdline` is identical, stopping at the first different program, so a launcher or wrapper that exits early never cancels the request. It exits 3 when the shell stops [scripts/menu].
- The client trusts only a spool that is a directory owned by the user with mode 700, and a `.shell` pid whose `comm` is `qs` or `quickshell` [scripts/menu:shell_alive].
- The card's title is the prompt without its trailing space and colon, with `pid <n>` of the asking client dimmed on its right (hidden when there is no pid); a tab carries only the app name, and a count when several requests wait [MenuPanel.qml:title, menuTitle; MenuTabs.qml].
- Lines render as `PlainText`; items may be secrets and are never placed in an argument, log or message by this package. Logs carry request names and reasons only [MenuPanel.qml; MenuRow.qml; MenuState.qml:discard, cancel].

## Side Effects
- Process `prepare` creates and empties the spool and writes `.shell` (`sh`, `mkdir`, `chmod`, `find`, `rm`, `mv`) [MenuState.qml:prepare].
- Process `scan` runs `find` on the spool after every change [MenuState.qml:scan].
- Per request: `tail --pid=<caller> -s 0.2 -f /dev/null` (caller watch) and `sh -c 'cat > "$1/result"'` (the answer) [MenuRequest.qml:watch, writer].
- `discard` runs `rm -rf` on the request directory and logs `Menu: request <name> dropped: <reason>` (`unreadable request`, `its caller process ended`, `not a request name`) [MenuState.qml:discard].
- `cancel` logs `Menu: request <id> answered with no choice` [MenuState.qml:cancel]; a failed `prepare` logs a warning and no request is shown [MenuState.qml:prepare].
- Client `scripts/menu`: creates the staging and request directories and the named pipe, runs `jq`, `mkfifo`, `mv`, `ps`, `kill -0`, `sed`, and removes its directories on exit [scripts/menu].
- Env: `UI_SHELL_OPEN_MENU=1` queues one preview request that needs no program and writes no file [MenuState.qml:Component.onCompleted].
- Layer-shell windows: scrim (`Top`) and card (`Overlay`, exclusive keyboard focus while shown) [MenuSurface.qml].
- Registers no global shortcut: the card opens only when a request arrives.

## Verification
- Run: `make test-qml`, `make test-menu`, `make test-menu-session`, `make test-menu-stress`
