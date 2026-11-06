# Polkit and password prompts: omarchy-askpass, omapin, Quickshell polkit module

Study of three reference projects in `refs/`. Facts only, with file citations. Paths are relative to `refs/` in the repository root unless absolute. Line numbers refer to the files as checked out. No decisions are recorded here.

Note on the requested inputs: `omapin` has no `scripts/`, `bin/` or `docs/` directory. `omarchy-askpass` has `bin/`, `scripts/`, `docs/` (one PNG) and `tests/`. Both have `README.md`, `SECURITY.md`, `manifest.json`.

---

## 1. omarchy-askpass

### 1.1 What it replaces and how it is wired

- **Replaces:** the terminal password prompt of `sudo` when no TTY exists. Wiring is the `SUDO_ASKPASS` environment variable pointing at `bin/askpass`; `sudo -A` selects it (`omarchy-askpass/README.md` lines 32, 45).
- **Helper (`bin/askpass`):**
  - Sets `umask 077` (line 4).
  - Reads sudo's real argv from `/proc/$PPID/cmdline` (line 12) and refuses unless the parent basename is `sudo` or `sudoedit` (line 14).
  - Quotes each argument for display; control and bidi characters are `%q`-escaped so they are visible (lines 15-26).
  - Takes an exclusive `flock` on `$XDG_RUNTIME_DIR/omarchy-askpass.lock` with a wait of `OMARCHY_ASKPASS_TIMEOUT` seconds (lines 30-31).
  - Creates a private directory with `mktemp -d` and a FIFO with `mkfifo -m 600 "$dir/response"` (lines 32, 39).
  - Calls `omarchy-shell askpass request DIR PROMPT REASON CMDLINE` (lines 42-43). Reply must be `ok` (line 44).
  - Reads one line from the FIFO with `read -t` (line 45). Empty line fails (line 46). Otherwise prints the password to stdout (line 47).
- **Shell side (`Askpass.qml`):** an `IpcHandler` with target `askpass` (lines 49-68).
  - `request()` returns `busy` if a request is open or a write is running. It returns `invalid` unless the dir is under `$XDG_RUNTIME_DIR/omarchy-askpass.` with a six-character alphanumeric suffix and the command is non-empty (lines 52-56).
  - Heading is `reason || prompt` (line 58). The command is shown verbatim (line 59). The card is reset and a 120 s `Timer` starts (lines 60-61). Focus goes to the password field (line 62).
  - `dismiss(dir)` closes the request (line 66). Called from the helper's EXIT trap (`bin/askpass` lines 33-35).
- **Dialog:** a `PanelWindow` at `WlrLayer.Overlay`, full-screen anchors, `WlrKeyboardFocus.Exclusive`, namespace `omarchy-askpass`, `ExclusionMode.Ignore` (`Askpass.qml` lines 70-78). Visible only while `requestDir !== ""` (line 72).
- **Answer path:** the card emits `accepted(text)` or `cancelled()` (`AskpassCard.qml` lines 13-14, 72, 120-121). `Askpass.qml` `respond()` sets a `Process` `writer` with `stdinEnabled: true` running `timeout 3s bash -c '...'`. The script re-checks the dir (0700, owned, not a symlink) and FIFO (0600, owned, not a symlink), reads one line from stdin and writes it to `$1/response` (lines 27-29). The secret is written to stdin in `onStarted` (lines 35-41). The card is closed at once (line 32).
- **Timeouts:** the helper waits `OMARCHY_ASKPASS_TIMEOUT` (default 120) for the FIFO read (`bin/askpass` lines 7, 45). The UI `Timer` is fixed at 120000 ms (`Askpass.qml` lines 43-47) and on expiry calls `respond("")`, which is a cancel. The README says the overlay "also expires after 120 seconds" (`README.md` line 55).
- **Cancel:** Escape in the password field and in the command `TextEdit` (`AskpassCard.qml` lines 72, 121). `respond("")` sends `"\n"`, which the helper turns into a failure (`Askpass.qml` line 30, `bin/askpass` line 46).

### 1.2 Security

- **Memory:** the password lives in the QML `TextInput` text (`AskpassCard.qml` line 109). `respond()` copies it into the `writer.secret` property (`Askpass.qml` line 30). `onExited` clears that property (line 40). No zeroization is attempted. `SECURITY.md` lines 18-20 say this explicitly: "Clearing QML/Bash strings is not guaranteed memory zeroization; swap and core dumps are outside this UI's control."
- **Bash helper memory:** the password is held in the bash variable `password` (`bin/askpass` line 45). It is not wiped.
- **Transport:** the password never goes to argv or env. It goes over helper-to-FIFO-to-sudo (`README.md` lines 97-98, `SECURITY.md` lines 27-29). The UI sends it over the `Process` stdin, not argv (`Askpass.qml` lines 27-29, comment at line 26).
- **Files:** no regular file holds the password. The request dir is `0700`, the FIFO `0600` (`bin/askpass` lines 4, 32, 39; checks in `Askpass.qml` line 28).
- **Logs:** the helper prints only the password to stdout. No logging exists in the repo (`bin/askpass` line 47).
- **Clipboard:** the password field is `TextInput` with `echoMode: TextInput.Password` (`AskpassCard.qml` line 112). The command box is `selectByMouse: true` and `readOnly` (lines 64-66), so the command can be copied and the password field is not selectable in the same way. Qt's Password echo behaviour on copy is Qt behaviour, not checked here.
- **Length:** every character renders as the same bullet `"•"` (`AskpassCard.qml` line 113). The number of bullets therefore shows the password length. The repo does not discuss this.
- **Command text:** argv of sudo is shown in full (`README.md` lines 45-48). Any secret placed in argv is shown on screen (`SECURITY.md` lines 19-20).
- **Shoulder surf and screen capture:** the scrim is `Color.polkit.scrim` over the full screen (`Askpass.qml` line 80). No code asks the compositor to exclude the surface from screencopy or screen recording. A grep for `screencopy`, `screencast`, `ext-image` and `exclu` found only `exclusionMode`.
- **Focus and grabs:** `Exclusive` keyboard focus while the overlay is visible (`Askpass.qml` line 78). Clicking anywhere on the panel refocuses the password field (line 81). Focus is not restored on close.
- **Lock-out and retry:** the UI has no attempt counter and no error state. Retries and lock-out are sudo's policy. `README.md` lines 72-74 say the flow "uses normal sudo policy and timestamp caching".
- **Trust boundary:** the IPC endpoint is not authenticated. A same-user process can spoof a request and its displayed command (`SECURITY.md` lines 8-11; `README.md` lines 102-105). The UI runs unsandboxed in the shared Shell process (`SECURITY.md` lines 11-13).
- **Concurrency:** a second helper call waits on the flock (`bin/askpass` line 31). A UI-side `busy` is returned only if a request is still open (`Askpass.qml` line 53).
- **Failure paths:** if the writer fails, the card is already closed (`Askpass.qml` line 32). The helper then waits up to its timeout. No feedback path exists.

### 1.3 UI layout and visual language

- **Card:** `BorderSurface` (`AskpassCard.qml` line 5). Width is `min(760, panel.width - max(gapsOut, 24) * 2)` (`Askpass.qml` line 86). Height is content plus `Style.spacing.panelPadding` on each side (`AskpassCard.qml` lines 11, 19). Radius `Style.cornerRadius` (line 20). Background `Color.polkit.background` (line 21). Border `Border.surfaceSpec("polkit", "border", Color.polkit.border, max(1, space(2)), "border-alpha")` (line 22). Column spacing `space(16)` (line 28).
- **Heading:** the reason or sudo prompt. `bodySmall`, `menuFamily`, `opacity 0.65`, `Text.PlainText`, max two lines, elide right (lines 30-41).
- **Command box:** `Rectangle` with radius `cornerRadius`, fill `Util.alpha(Color.polkit.text, 0.06)`. Height is `min(contentHeight + space(24), maximumCommandHeight)`, where the maximum is 50 % of the panel height (`Askpass.qml` line 87; `AskpassCard.qml` lines 43-47). A `Flickable` holds a read-only `TextEdit` with `WrapAnywhere`, `PlainText`, font `Style.font.family` at `Style.font.body`, selection colour accent at 0.45 alpha (lines 49-73). Scroll indicator is a 3 px accent pill (lines 76-85).
- **Input row:** height `max(space(42), controlHeight)` (line 12). A lock glyph `""` in accent, 26 px wide, `iconLarge` (lines 93-102). Field gap `space(14)`. Password `TextInput` with `passwordCharacter "•"`, `menuFamily`, `iconLarge` (lines 108-122). Placeholder `"Enter password"` at `opacity 0.36` (lines 124-133).
- **Buttons:** none. Cancel is Escape only.
- **States:** the UI has one look. There is no error, verifying or cancelled state in the card. After Enter or Escape the card closes at once and the panel hides (`Askpass.qml` lines 32, 72). Wrong-password feedback is whatever sudo prints on the terminal, and sudo may call the helper again (not shown in these repos).
- **Animation:** none.
- **Keyboard:** Enter submits (`TextInput.onAccepted`, `AskpassCard.qml` line 120). Escape cancels in both fields (lines 72, 121).
- **Theme tokens used:** `Color.polkit.{scrim, background, border, text, accent}`; `Style.{cornerRadius, space(), spacing.panelPadding, spacing.controlHeight, gapsOut, font.menuFamily, font.family, font.bodySmall, font.body, font.iconLarge}`; `Border.surfaceSpec`; `Util.alpha`. These come from `qs.Commons` and `qs.Ui` (`README.md` lines 121-122).
- **Previews:** `scripts/Preview.qml` renders the real `AskpassCard.qml` offscreen with synthetic data and fixed colours. `scripts/render-previews` runs `qs` with `QT_QPA_PLATFORM=offscreen` and no display (lines 9-28).

### 1.4 Tests

- `tests/helper.sh` runs with no sudo, no desktop and no credentials. A fake `omarchy-shell` (`tests/fixtures/omarchy-shell`) stands in for the shell. It checks FIFO and dir modes (line 9) and writes a canned answer per `MODE`.
- Checks: exact argv round trip including multiline, quotes, empty arg and control characters, rebuilt with `eval` (lines 15-29); visible controls and no raw bidi in the displayed text (line 30); cancel, timeout and invalid modes fail with no output (lines 33-39); no leftover request dir (line 40); two concurrent requests complete (lines 43-48); a non-sudo parent is rejected (lines 50-54).
- `.github/workflows/check.yml` runs `bash -n` on the scripts and `bash tests/helper.sh` on Ubuntu.
- No QML test exists. Previews are visual only.

### 1.5 Notably clever and notably weak or risky

Clever:
- Reads the real argv of sudo from `/proc`, not a caller string (`bin/askpass` lines 10-12).
- Rejects non-sudo parents (line 14).
- Per-request 0700 dir and one-shot 0600 FIFO, with checks in the UI before writing (`Askpass.qml` line 28).
- Password goes via stdin, not argv (`Askpass.qml` lines 27-29).
- `flock` queue for concurrent sudo calls (`bin/askpass` lines 28-31).
- Previews render the real card (`scripts/Preview.qml`).

Weak or risky:
- UI expiry (120 s fixed) is not tied to `OMARCHY_ASKPASS_TIMEOUT`. A larger env value makes the UI expire first (`Askpass.qml` line 45 against `bin/askpass` line 7).
- No error or retry UI. No cancel button.
- Password in QML heap and bash variables, not wiped (`SECURITY.md` lines 18-20).
- Password length visible as bullets (`AskpassCard.qml` line 113).
- No exclusion from screen capture.
- The IPC endpoint is unauthenticated, and the displayed command can be spoofed by a same-user process (`SECURITY.md` lines 8-11).
- The helper's password read has no length bound (`bin/askpass` line 45).
- Card closes before the write is confirmed; a write failure only shows as the helper timing out.

---

## 2. omapin

### 2.1 What it replaces and how it is wired

- **Replaces:** the GnuPG pinentry. Wiring is `pinentry-program /usr/bin/omapin` in `gpg-agent.conf` (`omapin/README.md` lines 146-150).
- **Assuan side (`src/session.rs`, `src/assuan.rs`):**
  - `serve()` greets with `OK Pleased to meet you, process <pid>` (`session.rs` lines 16-21).
  - Commands: `GETPIN`, `CONFIRM` (with `--one-button` becoming a message), `MESSAGE`, `GETINFO` (`version`, `pid`, `flavor` = `omarchy`, `ttyinfo`), `RESET`, `BYE`. Accepted and ignored: `OPTION`, `SETKEYINFO`, `SETQUALITYBAR*`, `SETGENPIN*`, `SETREPEATOK`, `SETCONSTRAINTS`, `CLEARPASSPHRASE`, `NOP`, `HELP` (`session.rs` lines 49-76).
  - `SET*` values accumulate in `request.rs` `State::apply` (lines 69-95). `SETERROR` and `SETREPEAT` are one-shot (`request.rs` lines 126-131).
  - Input lines are capped at 1002 bytes (`assuan.rs` line 18). Longer lines are consumed and answered with `ERR 83886343 Line too long` (`session.rs` lines 28-30).
- **Shell IPC (`src/shell.rs`, `PinentryService.qml`):**
  - Socket path: `$OMAPIN_SOCKET`, else `$XDG_RUNTIME_DIR/omapin.sock` (`shell.rs` lines 20-28; `PinentryService.qml` lines 78-80).
  - Request: one NDJSON line with `"v":2`, `type` (`getpin`/`confirm`/`message`), and text fields (`request.rs` lines 29-58; `PinentryService.qml` lines 12-14).
  - Response: one NDJSON line `{"result":...}` then the plugin closes the connection (`PinentryService.qml` lines 22-26, 85-90).
- **Dialog (`PinentryService.qml`, `PinentryDialog.qml`):**
  - One request at a time. A second gets `busy` (`PinentryService.qml` lines 47-50).
  - A client that disconnects closes its dialog (`PinentryService.qml` lines 85-90; `PinentryDialog.qml` lines 72-79).
  - `PinentryDialog` is a `PanelWindow` at `WlrLayer.Overlay` with namespace `omapin`, exclusive keyboard while `shown`, `WlrKeyboardFocus.None` otherwise, `ExclusionMode.Ignore` (`PinentryDialog.qml` lines 227-235).
- **Answer path:**
  - The dialog emits `finished(result, pin)` (`PinentryDialog.qml` lines 86-100).
  - The service encodes the PIN with `encodeURIComponent` and writes the reply (`PinentryService.qml` lines 55-71).
  - The binary reads the reply into a zeroized buffer, parses it, percent-decodes the PIN into another zeroized buffer (`shell.rs` lines 102-141).
  - It sends `D` lines percent-encoded (`assuan.rs` lines 215-238), then `OK`. A cancel or timeout becomes an `ERR` with the gpg-error code (`session.rs` lines 88-105).
- **Timeouts:**
  - `SETTIMEOUT` is capped at 86400 s (`request.rs` lines 9-11, 88-93). A bad value is an `ERR`.
  - The dialog's own `Timer` answers `timeout` (`PinentryDialog.qml` lines 63-66, 116-120).
  - The binary's read deadline is the dialog timeout plus 5 s (`shell.rs` lines 17-18, 82-85). If it expires or the dialog is gone, `dialog_failed()` returns `Timeout` or `Operation cancelled` (`session.rs` lines 139-144).
  - With no `SETTIMEOUT`, there is no timeout (`shell.rs` line 84; `SECURITY.md` lines 44-46).
- **Cancel:**
  - Escape in a field or on the card gives `cancel` (`PinentryDialog.qml` lines 188-193, 266-274).
  - Confirm dialogs have a `notok` button and a `cancel` button (lines 330-341).
  - Disconnect cancels (`PinentryService.qml` lines 85-90).
- **Fallback (`src/fallback.rs`, `src/main.rs`):** if `OMAPIN_SOCKET` is unset and `WAYLAND_DISPLAY` is unset, the binary skips the shell (`main.rs` lines 35-38). If `connect` fails it `exec`s `pinentry-gnome3` when `WAYLAND_DISPLAY` or `DISPLAY` is set, otherwise `pinentry-curses`. `OMAPIN_FALLBACK` overrides (`fallback.rs` lines 8-19). This happens before any output to gpg-agent (`main.rs` lines 15-19).

### 2.2 Security

- **Memory:**
  - `secret::harden()` sets non-dumpable and `mlockall(MCL_CURRENT | MCL_FUTURE)` (`src/secret.rs` lines 6-9). Best effort.
  - The response buffer is a fixed 64 KiB `Zeroizing<Vec<u8>>` with no `BufReader` (`shell.rs` lines 102-106).
  - The decoded PIN is `Zeroizing` (`shell.rs` lines 131-135). The encoded data and each `D` line are `Zeroizing` (`assuan.rs` lines 218-220).
  - Responses go through `File` on fd 1 unbuffered (`main.rs` lines 21-23; `assuan.rs` lines 183-197).
- **Inside the shell:** the PIN is in a `TextInput` (`PinentryDialog.qml` line 171) and in JS strings. `finish()` sets its parameter `pin = ""` (`PinentryService.qml` line 68), which drops a reference and does not wipe. `clearInputs()` empties the fields (`PinentryDialog.qml` lines 81-84). `SECURITY.md` lines 40-43 and `README.md` lines 86-88 state this trade-off.
- **Transport:** the PIN goes over the Unix socket inside JSON, percent-encoded, so no JSON unescape is needed (`shell.rs` lines 43-45; `PinentryService.qml` line 62). It never goes to argv or env. `OMAPIN_SOCKET` is read from the environment (`shell.rs` line 21).
- **Peer check:** the binary calls `SO_PEERCRED` and refuses a socket owned by another uid (`shell.rs` lines 31-41). The QML side has no peer check and sets no socket permissions. The file is only protected by the runtime directory (`PinentryService.qml` lines 78-80; `README.md` line 79).
- **Files and logs:** none. Only the protocol goes to stdout. Error output goes to stderr only on fatal startup failure (`main.rs` line 17). The test `never_prints_anything_but_protocol_lines` covers this (`tests/assuan.rs` lines 415-426).
- **Clipboard:** `echoMode: Password` (`PinentryDialog.qml` line 181). `inputMethodHints` has `ImhSensitiveData | ImhNoPredictiveText | ImhNoAutoUppercase` (line 183). No `selectByMouse` on the field.
- **Length:** each character is one `"•"` (`PinentryDialog.qml` line 182), so the bullet count shows the PIN length (same as askpass).
- **Display spoofing:** texts from gpg-agent go through `sanitize_display` (strips control and bidi, keeps newline and tab) (`assuan.rs` lines 146-152, applied in `request.rs` lines 69-79). The dialog renders them with `textFormat: Text.PlainText` (`PinentryDialog.qml` lines 197, 289, 300, 363).
- **Injection:** `response_line()` turns control characters into spaces so a message cannot start a new Assuan line (`assuan.rs` lines 154-171). Tested (`assuan.rs` tests, `tests/assuan.rs` line 258).
- **Shoulder surf and capture:** full-screen `Overlay` scrim with `Color.polkit.scrim` (`PinentryDialog.qml` lines 237-240). No screencopy or screen-recording exclusion. The grep above found none in this repo.
- **Focus and grabs:** `Exclusive` keyboard focus while shown (`PinentryDialog.qml` line 234). `keyCatcher` takes Escape and Enter before the field (lines 265-274). Clicks refocus (lines 242-245, 258).
- **Lock-out and retries:** no attempt counter in the plugin or binary. The card's remaining tries reach the user through `SETERROR` text, for example `Bad PIN (2 tries left)` (`Justfile` line 48). `SECURITY.md` lines 18-20 note that a misread PIN uses up a try.
- **Denial of service:** request size limit 65536 bytes (`PinentryService.qml` lines 19, 32-35); binary response limit 64 KiB (`shell.rs` line 15); Assuan line limit 1002 bytes (`assuan.rs` line 18). `SECURITY.md` lines 47-49 list a same-user endless-line attack as out of scope.
- **Version fail-closed:** the plugin refuses any `v` other than 2 (`PinentryService.qml` lines 18, 43). The binary sends 2 and parses `v` only in the request (`request.rs` lines 5-7).
- **Trust boundary:** same-user processes are out of scope (`SECURITY.md` lines 36-39). The socket accepts only the user's uid on the binary side.

### 2.3 UI layout and visual language

- **Card:** `BorderSurface` width `min(420, max(260, panel.width - gapsOut*2))` (`PinentryDialog.qml` line 43), centred (line 252), with horizontal shake offset (line 253). Radius `cornerRadius`. Background `Color.polkit.background`. Border `Border.surfaceSpec("polkit", "border" or "border-error", ..., "border-alpha")` (line 38). Padding `panelPadding` (line 256). Content spacing `space(10)` (line 284).
- **Title pill:** a rectangle above the card, 28 px high, width text plus 24 px capped at the panel width, `bodySmall`, centred, elide middle. Default text `GnuPG` (lines 352-375). Bottom margin `space(10)` (line 357).
- **Description:** `bodySmall`, `foreground`, plain text, hidden if empty (lines 286-295).
- **Error text:** `bodySmall`, `textError`, shown when `localError || error` is set (lines 42, 297-306).
- **PIN field (`PinField` component):** height `max(42, controlHeight)` (line 40). Icon glyph U+F023 in accent (or `textError` while flashing), 26 px, `iconLarge` (lines 156-165). Password `TextInput` with bullets, `iconLarge`, `menuFamily`, selection accent at 0.45 (lines 171-194). Placeholder is the prompt with trailing colon removed, `opacity 0.36` (lines 196-208). A 2 px by 24 px cursor bar shows only when the field is focused and empty (lines 210-217).
- **Repeat field:** a second `PinField` shown when `SETREPEAT` was given (lines 318-323). Mismatch sets `localError` to `repeatError` or `"Passphrases don't match"`, clears the repeat field and triggers feedback (lines 86-95).
- **Buttons (confirm and message only):** right-aligned row, spacing `controlGap`. Order: `notok` (if labelled), `cancel`, `OK` (`selected: true`). Labels default to `Cancel` and `OK` (lines 325-348). `Button` comes from `qs.Ui`, `bordered: true`.
- **Animation:**
  - Shake: 35 ms to -8, 50 ms to +8, 55 ms to 0 (`PinentryDialog.qml` lines 136-141).
  - Failure flash: border and text switch to error colours for 1200 ms (`errorTimer`, lines 129-134).
  - Close: `closing` keeps the panel visible for 300 ms but no fade is drawn (lines 122-127, 229).
- **States:**
  - Idle: placeholder and cursor bar.
  - Typing: bullets.
  - Verifying: not shown. After `respond()` the dialog closes at once (line 98).
  - Wrong PIN: `SETERROR` text and flash and shake (`triggerFailureFeedback`, lines 109-114).
  - Mismatch: `repeatError` text and repeat cleared (lines 89-95).
  - Cancelled or timed out: dialog hides, the binary returns an error.
  - No countdown is shown for the timeout.
- **Keyboard:** Enter submits or moves from the first to the repeat field when it is empty (`PinentryDialog.qml` lines 312-315, 270-272). Escape cancels in every field (lines 188-193, 267-268, 189). On confirm dialogs Enter is OK. Tab is not handled.
- **Theme tokens used:** `Color.polkit.{scrim, background, text, accent, textError, border, borderError}`; `Style.{cornerRadius, space(), spacing.panelPadding, spacing.controlHeight, spacing.controlGap, gapsOut, font.menuFamily, font.bodySmall, font.iconLarge}`; `Border.surfaceSpec`; `Util.alpha`. Properties are bound to these tokens so they follow theme changes live (`README.md` lines 8-10).

### 2.4 Tests

- **Unit tests (in `src/`):** 24 `#[test]` functions across `request.rs` (6), `assuan.rs` (10), `shell.rs` (7) and `secret.rs` (1). `lib.rs`, `main.rs`, `session.rs` and `fallback.rs` have none.
- **Integration (`tests/assuan.rs`):** 21 tests run the real binary against a fake dialog that scripts answers. They cover PIN round trip (including tricky and 1000+ byte PINs), repeat, cancel, timeout, busy, malformed and oversized replies, injection, confirm and message mapping, GETINFO, unknown commands, line length, EOF, vanished dialog, fallback when socket is missing and outside Wayland, and that only protocol lines reach stdout.
- **Plugin (`tests/plugin.rs`):** one `#[ignore]` test. It starts a real Quickshell instance built in a temp directory from `dev/shell.qml` and checks protocol refusals, timeout, busy, disconnect freeing the dialog and timeout capping. Run with `just test-plugin` inside a Wayland session. Not run in CI (`Justfile` lines 19-22).
- **Fuzz (`fuzz/fuzz_targets/`):** `assuan_session`, `dialog_response`, `data_encoding`, with seeds in `fuzz/seeds/`. The session target asserts every reply line is valid Assuan and every dialog request is valid JSON with no hidden characters (`assuan_session.rs` lines 1-7, 61-99).
- **CI (`.github/workflows/`):** `ci.yml` runs `cargo test --locked`, `cargo fmt --check` and clippy with `-D warnings` (lines 20-33). Also `cargo-deny.yml`, `codeql.yml`, `scorecard.yml`, `fuzz.yml`. `CONTRIBUTING.md` lines 22-30 require tests with every change.

### 2.5 Notably clever and notably weak or risky

Clever:
- PIN percent-encoded inside the JSON reply, so the binary never unescapes JSON and never makes a scratch copy (`shell.rs` lines 43-45; `CHANGELOG.md` 0.2.0).
- Protocol version pinning on both sides, so mismatched halves fail closed (`request.rs` lines 5-7; `PinentryService.qml` line 43).
- Zeroized fixed-size read buffer and unbuffered writes (`shell.rs` lines 102-106; `assuan.rs` lines 183-197).
- The first connection doubles as the availability check (`shell.rs` lines 65-69; `CHANGELOG.md` 0.1.1).
- Fallback decided before anything is written to gpg-agent (`main.rs` lines 15-19).
- Disconnect equals cancel, and the answer is the close of the connection (`PinentryService.qml` lines 22-26, 85-90).
- `#![forbid(unsafe_code)]` (`main.rs` line 1; `lib.rs` line 4).
- Fuzzing wired into CI, with the bug that prompted it recorded (`CHANGELOG.md` 0.2.1).

Weak or risky:
- JS heap and QML `TextInput` hold the PIN and cannot be wiped (`SECURITY.md` lines 40-43). `finish()`'s `pin = ""` is a no-op for wiping.
- The QML side does not check the peer's uid (`PinentryService.qml` lines 78-80), unlike the binary (`shell.rs` lines 31-41).
- No timeout by default (`SETTIMEOUT` absent or 0). A hung shell keeps gpg-agent waiting (`SECURITY.md` lines 44-46; `shell.rs` line 84).
- Bullet count shows PIN length (`PinentryDialog.qml` line 182).
- No screen-capture exclusion.
- The plugin's `keepLoaded: true` (`manifest.json` line 23) keeps the service resident.
- A same-user process can open the socket and display a look-alike overlay (`SECURITY.md` lines 36-39).
- The plugin leaves `dialog.open(req)` with a `Timer`-based timeout (`PinentryDialog.qml` lines 63-66), so a long `SETTIMEOUT` keeps the overlay open for up to a day (max 86400 s).

---

## 3. Quickshell polkit module (`refs/quickshell`)

### 3.1 Presence and build

- Source directory exists: `src/services/polkit/` with `agentimpl.{hpp,cpp}`, `flow.{hpp,cpp}`, `identity.{hpp,cpp}`, `listener.{hpp,cpp}`, `session.{hpp,cpp}`, `qml.{hpp,cpp}`, `gobjectref.hpp`, `module.md`, `CMakeLists.txt`, `test/manual/agent.qml`.
- Built only when `SERVICE_POLKIT` is set (`src/services/CMakeLists.txt`, the `if (SERVICE_POLKIT)` block).
- Requires `glib-2.0`, `gobject-2.0`, `polkit-agent-1` and `polkit-gobject-1` through pkg-config (`src/services/polkit/CMakeLists.txt` lines 2-5). QML module `Quickshell.Services.Polkit`, version `0.1` (line 13).
- `module.md`: name `Quickshell.Services.Polkit`, description `Polkit Agent`.
- `docs/`: the checkout has no `docs/` directory. `module.md` is the documentation. `changelog/v0.3.0.md` line 14 says "Added support for creating Polkit agents."
- The only test is a manual one (`test/manual/agent.qml`). No automated test exists.

### 3.2 QML types, properties and signals as found

`PolkitAgent` (QML element, `qml.hpp`):
- Property `path`: QString, read and write. Default set in `qml.cpp` line 14 is `/org/quickshell/PolkitAgent`. The comment in `qml.hpp` says the default is `/org/quickshell/Polkit`. The two disagree.
- Property `isRegistered`: bool, read-only, bindable, notify `isRegisteredChanged`.
- Property `isActive`: bool, read-only, bindable, notify `isActiveChanged`.
- Property `flow`: AuthFlow*, read-only, bindable, notify `flowChanged`.
- Signal `authenticationRequestStarted()`.
- Signals `isRegisteredChanged()`, `isActiveChanged()`, `flowChanged()`.
- The doc comment on `authenticationRequestStarted` refers to `@@state`. No such property exists in `qml.hpp`.

`AuthFlow` (`QML_UNCREATABLE`, `flow.hpp`):
- Properties, all read-only with constant value unless noted:
  - `message`: QString, CONSTANT.
  - `iconName`: QString, CONSTANT.
  - `actionId`: QString, CONSTANT.
  - `cookie`: QString, CONSTANT.
  - `identities`: list of Identity, CONSTANT.
  - `selectedIdentity`: Identity*, read and write, notify `selectedIdentityChanged`.
  - `isResponseRequired`: bool, notify `isResponseRequiredChanged`.
  - `inputPrompt`: QString, notify `inputPromptChanged`.
  - `responseVisible`: bool, notify `responseVisibleChanged`.
  - `supplementaryMessage`: QString, notify `supplementaryMessageChanged`.
  - `supplementaryIsError`: bool, notify `supplementaryIsErrorChanged`.
  - `isCompleted`: bool, notify `isCompletedChanged`.
  - `isSuccessful`: bool, notify `isSuccessfulChanged`.
  - `isCancelled`: bool, notify `isCancelledChanged`.
  - `failed`: bool, notify `failedChanged`.
- Methods: `Q_INVOKABLE submit(value: QString)` and `Q_INVOKABLE cancelAuthenticationRequest()`.
- Signals: `authenticationSucceeded()`, `authenticationFailed()`, `authenticationRequestCancelled()`, plus the `*Changed` signals listed above.

`Identity` (`QML_UNCREATABLE`, `identity.hpp`):
- `id`: quint32, CONSTANT. Uid or gid.
- `string`: QString, CONSTANT. The user or group name.
- `displayName`: QString, CONSTANT.
- `isGroup`: bool, CONSTANT.
- No methods or signals.

`Session` is not a QML type (`session.hpp` has no `QML_ELEMENT`).

### 3.3 Mechanism as found

- **Registration:** `componentComplete()` takes over or creates the single `PolkitAgentImpl` (`qml.cpp` lines 8-16; `agentimpl.cpp` `tryTakeoverOrCreate`). `registerComplete` sets `isRegistered` (`agentimpl.cpp` `registerComplete`).
- **Subject and register:** `polkit_unix_session_new_for_process(getpid())`, then `polkit_agent_listener_register` with the path and `POLKIT_AGENT_REGISTER_FLAGS_NONE` (`listener.cpp` `qs_polkit_agent_register`, `register_cb`).
- **Incoming requests:** `initiate_authentication` dedupes identities by `polkit_identity_hash`, copies the strings, keeps the GTask and cancellable (`listener.cpp`). `initiateAuthentication` queues the request; the first one becomes active and emits `authenticationRequestStarted` (`agentimpl.cpp`).
- **Session:** `AuthFlow` builds a `Session` for the selected identity with the cookie (`flow.cpp` `setupSession`). `Session::initiate` calls `polkit_agent_session_initiate` (`session.cpp`).
- **Prompts:** `request(message, echo)` sets `isResponseRequired`, `inputPrompt`, `responseVisible` (`flow.cpp` `request`). `submit` calls `polkit_agent_session_response` and clears those (`flow.cpp` `submit`, `session.cpp` `respond`).
- **Messages:** `show-error` and `show-info` set `supplementaryMessage` and `supplementaryIsError` (`flow.cpp` `showError`, `showInfo`).
- **Outcome:** `completed(gainedAuthorization)`. Success: `isCompleted`, `isSuccessful`, `GTask` returns true, `authenticationSucceeded` (`flow.cpp` `completed`). Cancelled by user or agent: `isCompleted` without success (`flow.cpp`). Otherwise `failed` is set, `authenticationFailed` is emitted and a new session starts for the same identity (`flow.cpp`).
- **Cancel from daemon:** `authentication_cancelled_cb` calls `cancelAuthentication`, which cancels the active flow or removes a queued request with `POLKIT_ERROR_CANCELLED` (`listener.cpp`, `agentimpl.cpp` `cancelAuthentication`).
- **Queue:** one active flow at a time. The next queued request starts when `isCompleted` changes (`agentimpl.cpp` `finishAuthenticationRequest`).
- **Identity switch:** setting `selectedIdentity` cancels the current session and starts a new one (`flow.cpp` `setSelectedIdentity`).
- **Identity types:** only unix user and unix group are kept. Others return null (`identity.cpp` `fromPolkitIdentity`).
- **Unregister:** on path change or destruction, all requests are cancelled and the listener unregistered (`agentimpl.cpp` `cancelAllRequests`, `setPath`).

---

## 4. Polkit vs these tools

Facts you can verify in the repos.

- **Neither omarchy-askpass nor omapin is a polkit agent.** Askpass is a `SUDO_ASKPASS` helper (`omarchy-askpass/README.md` line 45). Omapin is an Assuan pinentry (`omapin/README.md` lines 32-39). Neither registers on D-Bus. `omapin/Cargo.toml` lists only `nix`, `serde`, `serde_json`, `zeroize` (and `tempfile` for tests), with no D-Bus crate. `omarchy-askpass` has no dependency manifest and no D-Bus code in its files.
- **Omapin and askpass both use the Omarchy shell's own polkit styling.** Omapin's comment refers to `/usr/share/omarchy/shell/plugins/polkit/PolkitAgent.qml` (`omapin/PinentryDialog.qml` lines 7-9), which is not in these repos. The real Omarchy polkit agent is therefore not in the refs and cannot be checked here.
- **What a polkit authentication agent needs that askpass and pinentry do not** (each item is what the Quickshell module implements, cited above):
  1. Register an object at a D-Bus path that implements `org.freedesktop.PolicyKit1.AuthenticationAgent`, with a session subject from logind (`listener.cpp` `polkit_unix_session_new_for_process` and `polkit_agent_listener_register`). Neither askpass nor omapin does this.
  2. Receive `BeginAuthentication`-style requests carrying action id, message, icon name, cookie and identity list, then answer or cancel them (`listener.cpp` `initiate_authentication`, `AuthRequest::complete`, `AuthRequest::cancel`).
  3. Handle the cookie: pass it to the session for the daemon to match (`session.cpp` constructor; `flow.cpp` `setupSession`). Askpass and omapin have no cookie.
  4. Map identities to users or groups and let the user choose one (`identity.cpp`; `flow.cpp` `setSelectedIdentity`).
  5. Run the PAM conversation: `request` (prompt and echo flag), `show-error`, `show-info`, `completed`, and `polkit_agent_session_response` (`session.cpp`, `flow.cpp`). The PAM and helper side is inside libpolkit-agent, which these repos do not contain. Sudo's askpass path does this for sudo, not via polkit.
  6. Queue requests and handle daemon cancel versus user cancel (`agentimpl.cpp`).
  7. Re-create the session after a failed attempt (`flow.cpp` `completed`).
  8. Unregister cleanly when the path changes or the agent is destroyed (`agentimpl.cpp` `cancelAllRequests`, `setPath`).
- **The repos do not cover** the polkit agent protocol on D-Bus, the libpolkit-agent PAM conversation, the policy file format, or the Omarchy polkit dialog itself. Quickshell's module is the only polkit code in this set.

---

## 5. Patterns worth adopting

1. Pass secrets via stdin or a one-shot 0600 FIFO, never argv or env (`omarchy-askpass`, `README.md` lines 97-98; `Askpass.qml` lines 27-29).
2. Read the caller's real argv from `/proc/$PPID/cmdline` instead of trusting a caller-supplied display string (`omarchy-askpass`, `bin/askpass` lines 10-12).
3. Put each request in a private 0700 directory and check owner, mode and symlinks before writing (`omarchy-askpass`, `Askpass.qml` line 28).
4. Serialise prompts with `flock` so concurrent requests queue instead of clobbering each other (`omarchy-askpass`, `bin/askpass` lines 28-31; `tests/helper.sh` lines 43-48).
5. Strip control and bidi characters from text supplied by others, and render it as plain text (`omapin`, `assuan.rs` lines 146-152; `PinentryDialog.qml` line 197).
6. Version the wire protocol and refuse other versions, so mismatched halves fail closed (`omapin`, `PinentryService.qml` line 43; `request.rs` lines 5-7).
7. Percent-encode the secret inside the JSON reply so no unescape copy exists (`omapin`, `shell.rs` lines 43-45; `PinentryService.qml` line 62).
8. Use fixed zeroized buffers for the read path and unbuffered writes for the answer (`omapin`, `shell.rs` lines 102-106; `assuan.rs` lines 183-197).
9. Treat client disconnect as cancel and deliver the answer by closing the connection (`omapin`, `PinentryService.qml` lines 22-26, 85-90).
10. Fuzz the parsers and encoder, with seeds, in CI (`omapin`, `fuzz/fuzz_targets/*.rs`; `.github/workflows/fuzz.yml`).
11. Render the real card offscreen with synthetic data for previews (`omarchy-askpass`, `scripts/Preview.qml`; `scripts/render-previews`).
12. Build the dialog only from the shell's theme tokens (`Color.polkit.*`, `Style.*`, `Border.surfaceSpec`) so it follows theme changes live (`omarchy-askpass`, `AskpassCard.qml`; `omapin`, `PinentryDialog.qml`).

Total patterns listed: 12.

## 6. Patterns to avoid

- An unauthenticated IPC socket in a shared process, with no peer check on the receiving side (`omarchy-askpass`, `SECURITY.md` lines 8-11; `omapin`, `PinentryService.qml` lines 78-80).
- Claiming secrets are wiped while they sit in QML strings or JS (`omapin`, `PinentryService.qml` line 68; `omarchy-askpass`, `SECURITY.md` lines 18-20).
- A UI timeout hard-coded separately from the env-configured timeout (`omarchy-askpass`, `Askpass.qml` line 45 against `bin/askpass` line 7).
- Timeout 0 meaning "wait forever" with no fallback (`omapin`, `shell.rs` line 84; `SECURITY.md` lines 44-46).
- Bullet masks that show the password length (`omarchy-askpass`, `AskpassCard.qml` line 113; `omapin`, `PinentryDialog.qml` line 182).
- Exclusive-keyboard overlays with no visible cancel control, where Escape is the only way out (`omarchy-askpass`, `AskpassCard.qml`).
- Unbounded password reads from stdin (`omarchy-askpass`, `bin/askpass` line 45; compare `omapin` `assuan.rs` line 18 and `PinentryService.qml` line 19).
- Overlays that take `Overlay` layer and exclusive keyboard without any capture exclusion (both repos).
- A `path` default written in two places that disagree (`quickshell`, `qml.hpp` against `qml.cpp` line 14).
