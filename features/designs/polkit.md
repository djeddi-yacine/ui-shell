# Authentication dialog (polkit)

*   **Author:** djeddi-yacine
*   **Status:** Draft, ready for `egm-review`
*   **Date:** 2026-11-06

--------------------------------------------------------------------------------

## Overview

ui-shell gets its own authentication dialog. When a program needs a privilege
(`pkexec`, installing a package, mounting a disk), polkit asks a registered
"authentication agent" to collect your password. Today that agent is
`hyprpolkitagent`. This design replaces it with a dialog that uses the shell's
theme, shows nothing about the password while you type, and is as small as it
can be: a message, the account it asks for, one hidden field.

Quickshell already contains a polkit agent module (`Quickshell.Services.Polkit`,
built into the installed Quickshell 0.3.2). It registers with the polkit daemon
and hands us each request with its message, accounts and prompts. We do not
write the agent protocol; we write the dialog and the glue to that module.

The dialog itself is a small, generic component (a message, an account label,
an optional error line, a "checking" state, and two actions: submit and
cancel). The polkit-specific part is one adapter file. A later `sudo` askpass
or pinentry adapter could reuse the same dialog, but only the polkit adapter is
built now.

Inputs: `features/studies/polkit.md` (what `omarchy-askpass`, `omapin` and the
Quickshell polkit module do) and `features/reqs/polkit.md` (what we chose and
why).

## The Problem

`hyprpolkitagent` looks out of place and shows the password characters while
you type. Anyone behind you, or any screen share, can read it. We want an agent
that matches the shell and never displays the secret in any form.

Four facts make this harder than it looks:

*   **The secret cannot be fully protected.** QML and JavaScript strings cannot
    be wiped from memory. What we control is what is displayed, logged and
    stored.
*   **Polkit repeats a failed request.** After a wrong password polkit asks
    again inside the same request. "No retry" is therefore something our code
    enforces by cancelling the request on the first failure.
*   **There is exactly one agent per session.** If `hyprpolkitagent` is already
    registered, ours fails to register. While the shell is down or restarting
    there is no agent at all, and a waiting `pkexec` fails.
*   **Recording is out of our hands.** GPU Screen Recorder captures the screen
    below the compositor. A Hyprland layer rule (`no_screen_share`) hides a
    surface from compositor-based capture, but whether it affects gsr is
    unproven.

The proposed solution:

*   A generic dialog component in `shell/components` with a small contract.
*   One polkit adapter in `shell/adapters` that owns every Quickshell polkit
    import, enforces "no retry", queues requests and handles cancellation.
*   One on-demand window on the focused screen, shown only while a request is
    active.
*   A documented hand-over from `hyprpolkitagent` to our agent.

## Goals

*   Show polkit authentication requests in a themed, centred dialog over a
    dimmed backdrop on the focused screen, holding the keyboard until Enter or
    Esc.
*   Show the message and the account always; show an account choice, reachable
    by keyboard, only when polkit offers more than one.
*   Never show characters, length or a per-key reaction in the password field.
    While the field has focus, every key is part of the password until Enter.
    (The one exception is a polkit prompt that asks for visible input: that
    answer field shows what is typed.)
*   Give the three signals that reveal nothing: a static focus mark, Backspace
    clearing the whole field, and a "checking" state that ignores input while
    polkit verifies.
*   Ignore keys for a short moment after the dialog appears and ignore Enter on
    an empty field, so stray keystrokes are not submitted.
*   End the request after one wrong password, say so in plain words, and keep
    the message until a key is pressed.
*   Handle one request at a time, queue the rest, and never replace the visible
    prompt.
*   Close the dialog when polkit cancels the request, when the user presses
    Esc, and when the request completes; Esc cancels with a message to polkit,
    not only a closed window.
*   Make the dialog accessible (name, role, error readable as text and not only
    by colour).
*   Register our agent with an explicit D-Bus path and report a failed
    registration to the user.
*   Test the dialog with a fake request, and give the owner an exact live check
    with `pkexec` on the host.
*   Find out, by a live test, whether the `no_screen_share` layer rule hides the
    dialog from gsr, and say the result honestly in the docs.

## Non-Goals

*   Sudo askpass and pinentry adapters, retry inside the dialog, fingerprint or
    security-key flows.
*   Showing characters, dots or length in any form.
*   Writing the polkit agent protocol (Quickshell's module does it).
*   Any claim that the secret is wiped from memory, or that gsr cannot see the
    dialog, before it is tested.
*   Automatic fallback to `hyprpolkitagent` (two agents cannot run together, so
    the way back is a documented manual step), and changing the login start-up
    in this version.

## Decisions from the owner

*   **Wrong password**: the dialog says "Wrong password" and stays until a key
    is pressed (or Esc), then closes. The request has already ended.
*   **Visible prompts**: for the rare polkit prompt that asks for visible input,
    that one answer field shows what is typed. The password field never does.
*   **Timeout**: none. Esc always works and polkit's own cancel closes the
    dialog.
*   **Recording**: if `no_screen_share` does not hide the dialog from gsr, the
    recording script does nothing; the dialog shows no password characters or
    length, so the secret is not exposed.
*   **Hand-over**: manual swap for now. The design documents the steps; the
    login start-up is not changed until the dialog is proven.
*   **Systemd**: a unit for the shell is allowed (it does not break the "no
    daemon" rule), and the owner wants a target for things that need the shell
    running. That is a separate later feature. The agent runs inside the
    Quickshell process, so it needs no unit of its own.

## Decided by the author (mechanical)

*   The input guard after the dialog appears is 300 ms, a config value that can
    be tuned.
*   Information lines and further hidden questions from the same request are
    shown in the same dialog; a request the dialog cannot handle (for example a
    fingerprint prompt) is cancelled with a message.
*   The dialog card uses the popup surface tokens on the dimmed backdrop.
*   The window is two layers: a full-screen dimming layer (`ui-shell-auth-scrim`, captured) and a card-sized layer (`ui-shell-auth`, exclusive keyboard, `no_screen_share`). Chosen by the owner after the nested test showed a full-screen hidden layer blacks out the whole capture. In captures the card is a black rectangle on the dimmed desktop.
*   The namespace `ui-shell-auth` is written in two places (QML and `hypr/rules.lua`), as for the other shell namespaces, and a test fails when they differ. The owner chose this over a single generated source.

## Critical User Journeys (CUJs)

### CUJ 1: Authenticate once (phase 2)

*   **Given**: our agent is registered; a program asks for a privilege that
    needs the user's password.
*   **When**: the request arrives.
*   **Then**: the dialog appears on the focused screen with the message and the
    account, and the field has focus. The user types the password (nothing
    changes on screen) and presses Enter. The dialog shows "checking", then
    closes, and the program continues.

### CUJ 2: Wrong password (phase 2)

*   **Given**: the dialog is open.
*   **When**: the user submits a wrong password.
*   **Then**: the adapter cancels the request instead of letting polkit ask
    again; the dialog says the password was wrong and closes. The program that
    asked fails with an authorisation error.

### CUJ 3: Cancel (phase 1)

*   **Given**: the dialog is open.
*   **When**: the user presses Esc.
*   **Then**: the request is cancelled in polkit and the dialog closes. Esc
    works in every state, including while checking.

### CUJ 4: Typing blind (phase 1)

*   **Given**: the dialog has just appeared while the user was typing elsewhere.
*   **When**: keys arrive in the first moment, or Enter is pressed with nothing
    typed.
*   **Then**: those keys are ignored and nothing is submitted. After the
    guard, typing is accepted; Backspace empties the whole field.

### CUJ 5: More than one request (phase 2)

*   **Given**: one dialog is open and half-typed.
*   **When**: a second request arrives.
*   **Then**: the visible dialog does not change; the second request waits and
    appears after the first ends.

### CUJ 6: Several accounts (phase 2)

*   **Given**: polkit offers more than one administrator account.
*   **When**: the dialog opens.
*   **Then**: it shows which account is selected and lets the user choose
    another by keyboard before typing; with one account there is no choice
    control.

### CUJ 7: Polkit cancels (phase 2)

*   **Given**: the dialog is open.
*   **When**: polkit cancels the request (a timeout, or the program that asked
    ended).
*   **Then**: the dialog closes by itself, and the next queued request, if any,
    is shown.

### CUJ 8: The agent cannot register (phase 2)

*   **Given**: `hyprpolkitagent` or another agent already holds the session.
*   **When**: the shell starts.
*   **Then**: a small entry in the bar says the authentication agent is not
    active, and clicking it explains why, so a failed `pkexec` is not a mystery.

### CUJ 9: Recording while a dialog is up (phase 0)

*   **Given**: a recording is running and a request arrives.
*   **When**: the dialog is shown.
*   **Then**: the dialog never shows characters or length; whether it is
    hidden from the recording is the result of the live test, documented as is.

## Technical Plan

### Architecture

```
polkitd ──D-Bus──> Quickshell.Services.Polkit (PolkitAgent, AuthFlow)
                          │   only shell/adapters/PolkitAuth.qml imports it
                          ▼
              PolkitAuth (adapter)                     bar chip
   state: active, phase, displayed snapshot  ──────>  "agent not active"
                          │ binds
                          ▼
         modules/auth  (Loader, active only while a request is shown)
              PanelWindow: layer Overlay, exclusive keyboard,
              namespace ui-shell-auth, dimmed backdrop
                          │ contains
                          ▼
              components/SecretDialog  (generic, no polkit import)
   in:  message, account, accounts, prompt, error, checking, visibleEcho
   out: submitted(secret), cancelled(), accountChosen(index)
```

Data flows one way. The adapter turns polkit state into dialog inputs, and the
dialog's three signals into calls on the polkit flow. The dialog never sees an
`AuthFlow`, so a later askpass adapter can drive it the same way.

### The dialog (`SecretDialog`)

A card with the popup surface tokens, centred on a dimmed backdrop. Top to
bottom: the message, the account line, one field, one status line.

*   **Hidden field.** It is not a `TextInput` with password echo, because
    bullets reveal the length. The dialog holds the secret in a plain buffer,
    fed by key events, and no `Text`, tooltip or accessible value ever reads it.
    The field is a fixed-size box with a static focus border; it never changes
    when a key arrives. It exposes the accessible role "password edit" with no
    value.
*   **Keys.** Printable keys append to the buffer. Backspace empties the whole
    buffer. Enter submits when the buffer is not empty and the input guard has
    passed. Esc cancels. Control chords and paste are ignored, so a stray
    shortcut cannot leak into or out of the secret.
*   **Input guard.** A one-shot timer (`Config.Auth` value, 300 ms) starts when
    the dialog appears or a new prompt starts; keys arriving before it ends are
    dropped.
*   **Checking.** After Enter the dialog moves to a checking state: the field is
    dimmed, the status line says "Checking", and all keys except Esc are
    dropped. After submit the buffer is overwritten with empty text on a
    best-effort basis.
*   **Error line.** Shown as text with an icon, not by colour alone. For a wrong
    password the dialog enters a "failed" state: the line says "Wrong
    password" and the next key press of any kind closes the dialog.
*   **Visible echo.** When the prompt asks for visible input, the field turns
    into a normal visible text field for that prompt only.
*   **Account.** One account is shown as plain text. When there are several, a
    keyboard-reachable selector (Left/Right while the field is empty) picks the
    account and emits `accountChosen`.

### The adapter (`PolkitAuth`)

The only file that imports `Quickshell.Services.Polkit`. It owns one
`PolkitAgent` with `path` set to `/org/quickshell/PolkitAgent` once, never bound
to anything. Quickshell's own default path disagrees between its header and
source, so we do not rely on it.

Phases and transitions:

| Phase | Entered when | Dialog shows |
|---|---|---|
| idle | no active flow | nothing (window not loaded) |
| prompt | flow starts, or `isResponseRequired` with a new `inputPrompt` | message, account, field |
| checking | `submitted` was emitted | "Checking" |
| failed | `authenticationFailed` | "Wrong password"; the next key closes |
| refused | the flow needs something unsupported (a fingerprint prompt) | message that says so; the next key cancels |

*   **Snapshot.** When a flow starts the adapter copies message, account list
    and prompt into a `displayed` snapshot. The dialog reads only the snapshot,
    so the visible text cannot change under a half-typed secret.
*   **Queue.** Quickshell queues requests itself and starts the next flow when
    the current one completes, so first-in-first-out and "never replace the
    visible prompt" need no extra code. The adapter only has to finish or cancel
    the current flow.
*   **No retry.** `authenticationFailed` fires inside the module right before it
    creates a fresh session (`flow.cpp`, `completed`). If the adapter cancelled
    inside the handler, the module would still create the new session after the
    handler returns. The adapter therefore defers the cancel by one event-loop
    turn and checks the phase afterwards. Phase 0 must confirm that this ends
    the request and polkit does not prompt again.
*   **Cancel.** Esc calls `cancelAuthenticationRequest()`. When polkit cancels
    the request (`authenticationRequestCancelled`, or `isCancelled`), the adapter
    goes idle and the window unloads.
*   **Multi-round.** A second hidden question re-enters the prompt phase.
    `supplementaryMessage` shows as an info line, or as the error line when
    `supplementaryIsError` is set.
*   **Registration.** `isRegistered` is exposed as `agentActive`. When it is
    false the bar shows a small "Auth ✕" chip; clicking it explains that another
    agent (normally `hyprpolkitagent`) holds the session.

### The window (`modules/auth`)

A `Loader` that is active only while the adapter has a flow. It holds one
`PanelWindow` (not a `Variants`) on the focused screen: layer Overlay, keyboard
focus exclusive, namespace `ui-shell-auth`, and a full-screen backdrop coloured
by the existing `scrimColor` helper. It loads synchronously, so the dialog is
complete before it takes the keyboard.

### Hyprland rules

`hypr/rules.lua` gets a separate layer rule for `ui-shell-auth` with
`no_screen_share`, and the namespace is added to the shared `no_anim` pattern.
A check in the test suite compares the namespace string in QML with the one in
`rules.lua`, so the two cannot drift. Whether `no_screen_share` hides the dialog
from gsr is decided in phase 0 and written down as found; the owner's rule for a
negative result is "do nothing".

### Start-up and hand-over

Polkit allows one agent per session, so the swap is manual in this version:
stop `hyprpolkitagent`, start the shell, run `pkexec true`. If the shell cannot
register, the bar chip says so. The way back is to start `hyprpolkitagent` again.
The steps go in `tests/README.md` and `README.md`. The login start-up is not
changed.

### Configuration (`Config.Auth`)

Input guard duration, card width, field height, and the checking and failed
texts. All visual values come from `Theme.Density`, `Typography`, `Shape` and
`Motion`; no literals in components.

### Testing

*   **`tests/tst_SecretDialog.qml`.** Types a canary password, then asserts that
    no `Text` or accessible item holds a character or a length; Backspace
    empties; empty Enter does nothing; keys inside the guard are dropped; Esc
    cancels in every state; keys during checking are dropped; the buffer is
    empty after submit.
*   **Adapter tests with a fake flow object.** Cover the phase table, deferred
    cancel after failure, polkit-side cancel, multi-round prompts and an
    unsupported prompt.
*   **Nested preview.** An env switch opens the dialog with a fake request for
    screenshots.
*   **Namespace check.** QML namespace equals `rules.lua` namespace.
*   **Owner live checks on the host.** `pkexec true` after stopping
    `hyprpolkitagent`: success, wrong password, Esc, two requests, and a
    recording frame with the dialog open.
*   **Leak canary.** A fixed password typed in a live run appears in no log, state
    file or clipboard.

### Phases

0. Spike: does `no_screen_share` hide a layer from gsr; does our agent register
   once `hyprpolkitagent` is stopped; does the deferred cancel end the request.
1. `SecretDialog`, `modules/auth` and the fake-request tests.
2. The adapter, the bar chip and the live check.
3. Hand-over documentation.

## Alternatives Considered

### A generic secret-prompt framework now (askpass, pinentry and polkit behind one abstraction)

Rejected. Only one consumer exists, so the seam would be a guess. Askpass and
pinentry are separate processes that talk over pipes or sockets, which adds
long-lived helpers the shell avoids. The dialog contract is kept small
(message, account, error line, checking state, submit, cancel), so extracting
more later is cheap.

### Binding the dialog directly to Quickshell's polkit objects, with no adapter

Rejected. The Quickshell polkit module is version 0.1 and its API will move.
One adapter file confines a break to one place, and lets the dialog be tested
with a fake flow instead of a live polkit daemon.

### One dialog window per monitor (the shell's usual `Variants`)

Rejected. A full-screen layer per monitor sits idle for a feature used a few
times a day, and a request has one focus. One on-demand window on the focused
screen costs nothing while idle.

### Loading the dialog asynchronously like the other panels

Rejected. A blank dialog that fills in later, while it already holds the
keyboard, risks typing a password into an unfinished or spoofed view. The window
loads synchronously.

### Dots, a per-key pulse or a length hint

Rejected by the owner. Any per-key reaction leaks length or timing. The static
focus border and the checking state are the only signals.

### A password `TextInput` with echo mode "Password"

Rejected. The bullets show how many characters were typed. A key-fed buffer that
no `Text` reads avoids that.

### Retry inside the dialog (polkit's own behaviour)

Rejected by the owner. The dialog reports the failure and the request ends. This
needs the adapter to cancel the flow, because polkit would otherwise prompt
again.

### Reusing `PanelContext` and `ErrorPopup` as the dialog

Partly rejected. They give the surface, the popup look and error presentation,
but not the dim backdrop, the exclusive keyboard or the hidden field. Those are
added, and the tokens are reused.

### Automatic fallback to `hyprpolkitagent`, or changing login start-up now

Rejected for this version. Two agents cannot hold one session, so an automatic
fallback would need the shell to supervise another process. The swap is manual
and documented until the dialog is proven on the host.

### A timeout on the dialog

Rejected by the owner. Esc always works and a polkit-side cancel closes the
dialog, so a timeout adds a way to lose a half-typed password for no gain.

## Detailed Implementation

No code here; names and contracts only. Paths are relative to the repository
root. Follow the existing module pattern (see `shell/modules/shot/`).

### New files

*   `shell/components/SecretDialog.qml`: the generic dialog. Inputs: `message`,
    `account`, `accounts`, `prompt`, `error`, `checking`, `failed`,
    `visibleEcho`. Signals: `submitted(secret)`, `cancelled()`,
    `accountChosen(index)`. Holds the key-fed buffer, the input guard timer and
    the key rules from the Technical Plan. Needed so the hidden field and its
    tests do not depend on polkit.
*   `shell/adapters/PolkitSource.qml`: the only importer of
    `Quickshell.Services.Polkit`. A `Singleton` that owns the `PolkitAgent`
    (path set once to `/org/quickshell/PolkitAgent`) and exposes `flow` and
    `agentActive`. Kept this thin so the rest of the adapter can run without
    Quickshell.
*   `shell/adapters/PolkitAuth.qml`: the adapter logic, an ordinary component
    (not a singleton) with a `source` property that supplies `flow` and
    `agentActive`. Exposes `active`, `phase`, `displayed` (snapshot),
    `agentActive`, and the actions `submit(secret)`, `cancel()`,
    `selectAccount(index)`, `dismissFailure()`. Defers the cancel after a
    failure and closes on polkit-side cancel. Tests give it a fake source; the
    shell gives it `PolkitSource`. Exact fields are listed under
    "Contracts" below.
*   `shell/config/Auth.qml`: tokens for the module: `inputGuardMs` (300), card
    width, field height, status texts. Needed because components take no
    literals.
*   `shell/modules/auth/AuthSurface.qml`: the `Loader` plus one `PanelWindow` on
    the focused screen (layer Overlay, exclusive keyboard, namespace
    `ui-shell-auth`, backdrop from `scrimColor`), synchronous load.
*   `shell/modules/auth/AuthDialog.qml`: wires the adapter to `SecretDialog`
    (snapshot in, signals out).
*   `shell/modules/auth/qmldir`, `shell/modules/auth/EGM.md`: registration and
    the module contract (interface, invariants, side effects).
*   `shell/modules/bar/AuthChip.qml`: a chip with the text "No auth agent",
    visible only when `agentActive` is false and the shell has been up for the
    start-up grace period (no flash while the agent registers). Click opens an
    inline `PopupWindow`, as `RecordButton.qml` does, with a short explanation
    that another agent (normally `hyprpolkitagent`) holds the session. Placed
    at the right end of `Bar.qml`.
*   `tests/tst_SecretDialog.qml`: canary-password tests listed in the Technical
    Plan.
*   `tests/tst_PolkitAuth.qml`: adapter phase tests against a fake flow object.
*   `tests/auth/FakeSource.qml` and `tests/auth/FakeFlow.qml`: a fake source and
    a fake flow with the same property and signal names as `AuthFlow`, for the
    adapter tests and the nested preview.
*   `tests/scripts/check-auth`: reads the `namespace` property of
    `AuthSurface.qml` (the window lives there; the string is not repeated in
    `AuthDialog`) and fails unless `hypr/rules.lua` contains it in both rules.

### Modified files

*   `shell/shell.qml`: import `modules/auth` and instantiate `AuthSurface` once
    (not in a `Variants`) under a `Loader` on `Config.Config.authEnabled`. The
    auth dialog is not part of the panel mutual-exclusion `Connections`: it is
    modal and appears over whatever is open.
*   `shell/modules/auth/AuthState.qml`: a `Singleton` (like `ShotPanelState`)
    holding the adapter instance and the preview switch. The preview env
    `UI_SHELL_OPEN_AUTH` is read here, not in `shell.qml`, and swaps the real
    source for the fake one.
*   `shell/modules/bar/Bar.qml`: place `AuthChip` (the bar has no `qmldir`; its
    parts are used by file name).
*   `shell/adapters/qmldir`, `shell/components/qmldir`, `shell/config/qmldir`:
    register `PolkitAuth`, `SecretDialog` and `Auth`.
*   `shell/config/Config.qml`: add `authEnabled` (true), the module switch the
    `Loader` in `shell/shell.qml` reads, like the other modules.
*   `hypr/rules.lua`: add `auth` to the alternation in the `shell-owns-motion`
    pattern (`...|record|shot|auth)$`), and a new rule named `auth-not-shared`
    with `match = { namespace = "^ui-shell-auth$" }` and `no_screen_share =
    true`. The namespace therefore appears twice in this file.
*   `tests/scripts/check-qml`: append `tst_SecretDialog` and `tst_PolkitAuth` to
    its hard-coded suite list, or the new suites never run.
*   `tests/targets.mk`: add `test-auth` to `.PHONY` and `test-help`, give it a
    recipe that runs `tests/scripts/check-auth` (the namespace check; the two
    suites run under `test-qml`), and add it to the `test` aggregate.
*   `tests/scripts/test-nested`: forward `UI_SHELL_OPEN_AUTH` to the nested
    session.
*   `tests/README.md`: add the owner live check
    (stop `hyprpolkitagent`, run `pkexec true` for success, wrong password,
    Esc, two requests, a recording frame, and how to restore `hyprpolkitagent`).
*   `README.md`: the feature, the one-agent-per-session limit and the manual
    swap.
*   `STYLE.md`: the new surface rule for a centred modal (popup tokens, dimmed
    backdrop, exclusive keyboard, Esc cancels with one press).
*   `shell/EGM.md`, `shell/adapters/EGM.md`, `shell/components/EGM.md`,
    `shell/config/EGM.md`, `shell/modules/EGM.md`,
    `shell/modules/bar/EGM.md`: add the new files to each contract.
*   Brain: update `brain/pages/polkit-auth-dialog.md` through the `brain` CLI
    when phase 0 results arrive (screen-share result, deferred-cancel result).

### Contracts

*   **Phases:** `idle`, `prompt`, `checking`, `failed`, `refused`.
*   **`displayed` snapshot:** `message`, `actionId`, `accounts` (list of
    `{id, label}`), `selectedIndex`, `prompt`, `visibleEcho`, `info`,
    `infoIsError`.
*   **`SecretDialog` inputs:** `message`, `accounts`, `selectedIndex`, `prompt`,
    `visibleEcho`, `info`, `error`, `checking`, `failed`, `refused`. Signals:
    `submitted(secret)`, `cancelled()`, `accountChosen(index)`,
    `keyAfterFailure()`.
*   **`selectAccount(i)`:** sets the flow's selected identity. The module then
    recreates the session and polkit prompts again, so the adapter returns to
    `prompt` and the dialog clears its buffer.
*   **After a wrong password:** the adapter enters `failed`, defers
    `cancelAuthenticationRequest()` by one event-loop turn, ignores
    `isResponseRequired` from the fresh session while `failed`, keeps the
    snapshot on screen, and goes `idle` only on `dismissFailure()` (any key).
*   **`Config.Auth` tokens:** `inputGuardMs`, `cardWidth`, `fieldHeight`,
    `scrimOpacity`, `startupGraceMs`, `checkingText`, `failedText`,
    `refusedText`. The dialog uses `inputGuardMs` as a config value, not a
    literal.
*   **Spike outcomes (phase 0):** if `no_screen_share` does not hide the dialog
    from gsr, the owner's rule applies (do nothing) and the docs say so. If the
    deferred cancel does not end the request, stop and return to the owner with
    options. The spike changes nothing in the repository.

### Order of work

1.  Phase 0 spike (owner on the host; no repository files): the three
    questions from the Technical Plan.
2.  Phase 1 (builds and tests with no polkit): `Auth.qml`, `SecretDialog.qml`,
    `PolkitAuth.qml`, fakes in `tests/auth/`, auth module, `AuthState.qml`,
    registration (`qmldir` files, `shell.qml`, `Config.qml`), `rules.lua`,
    namespace check, test wiring, `tst_SecretDialog.qml`, `tst_PolkitAuth.qml`,
    `STYLE.md`.
3.  Phase 2: `PolkitSource.qml`, `AuthChip.qml`, live check steps in
    `tests/README.md`.
4.  Phase 3: `README.md` hand-over steps and contract updates.

### Checks before each phase is called done

*   `make test-auth` passes; existing suites still pass.
*   The owner confirms the visual check (dialog look) and the live `pkexec`
    check; neither is claimed from the nested session.
*   `make test-hypr-config` passes after the `rules.lua` edit.
*   No literal colours or sizes in the new components; durations come from
    `Config.Auth` or `Theme.Motion`.
