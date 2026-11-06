# Authentication dialog (polkit)

* **Author:** djeddi-yacine
* **Date:** 2026-11-06
* **Status:** brainstorm brief, draft 1. All six review lenses are in.

Input: `features/studies/polkit.md`. This file records what we need from it.

## Overview

Our own authentication dialog, replacing `hyprpolkitagent`, which is ugly and shows the password while you type. It takes the shell's theme, appears centred over a dimmed backdrop on the focused screen, and holds the keyboard until you press Enter or Esc. It shows a message, the account it asks for, and one hidden password field. The field shows no characters, no length and no reaction to keys: while it has focus it takes everything you type as the password until Enter.

Quickshell already ships a polkit agent module (`Quickshell.Services.Polkit`, built into the installed Quickshell 0.3.2). It registers with the polkit daemon and delivers each request with its message, identities and prompts, so the agent protocol is solved. The work is the dialog, its theming, and wiring it to that module. The design should not be tied to polkit forever: the dialog's contract is small and generic, so a later `sudo` askpass or pinentry adapter could reuse it. Only the polkit adapter is built now.

The dialog should not appear in screen recordings. A Hyprland layer rule (`no_screen_share`) exists for compositor-based capture. GPU Screen Recorder captures below the compositor, so whether the rule hides the dialog from it is unproven and is treated as a test, not a promise.

## Analysis

Six lenses reviewed the hypothesis. They agree on the following, from most to least serious.

1. **"No retry" does not match how polkit works.** After a wrong password polkit repeats the same flow with a new prompt and sets `failed` and an error message (`refs/quickshell/src/services/polkit/flow.cpp`, `module.md`). "No retry" is therefore something our adapter enforces: on the first failure it cancels the flow. What the user then sees must be decided. Closing silently looks like a bug.
2. **A field with no feedback needs a minimum of safety.** The owner's decision stands (no echo, no length, no per-key reaction), but three things do not reveal anything and prevent real accidents: a static focus mark (a fixed border, so you can tell the field is live); Backspace clearing the whole buffer (a single-character delete is a blind operation); and a "checking" state while polkit verifies, where input is ignored. Two more protect against typing into the wrong place: ignore keys for about 300 ms after the dialog appears, and never submit an empty field on Enter.
3. **The generic part is smaller than "a dialog".** The polkit flow can ask several questions in a row (a password, then a second factor), show information lines, offer a choice between administrator accounts, ask for visible input, or ask for a fingerprint. A dialog fixed to one hidden field breaks on those. The truly generic contract is: a message, an account label, an optional error line, a checking state, `submit(secret)` and `cancel()`. Identities, multi-round prompts and visible-input handling stay in the polkit adapter. Building a framework for askpass and pinentry before they exist would guess the seam wrongly, and both are separate processes with sockets or pipes, which is the kind of long-lived helper the shell avoids.
4. **A request must never be swapped under a half-typed password.** Polkit can send a second request while one is on screen. Requests queue first in, first out; the visible prompt is never replaced; the dialog says whose request it is (the account and the action).
5. **"Hidden from recordings" is unproven.** No file in this repository uses `no_screen_share` yet. The nested session cannot show gsr's capture. It must be verified on the real desktop: record with `scripts/screen-record`, open the dialog with `pkexec`, then look at a frame. If gsr ignores the rule, the design must say so instead of claiming it. The layer namespace the rule matches is also a hidden link between the QML and the Hyprland config; both must read it from one place.
6. **Testing has two halves.** The nested session has a private D-Bus with no host system bus, so the real polkit path cannot run there. The dialog is tested with a fake request (QML tests and nested snapshots); the adapter and the real flow are checked by the owner on the host with `pkexec true`, after stopping `hyprpolkitagent` (only one agent can register per session), and with `hyprpolkitagent` as the way back. "Nothing leaks" cannot be a guarantee: QML and JavaScript strings cannot be wiped. The tests check what can be observed: no `Text` or accessible item carries characters or a length, and a canary password appears in no log, state file or clipboard.
7. **Cost and lifetime.** One window on the focused screen, created only while a request is active, loaded synchronously (a prompt that appears blank and then fills while the keyboard is already grabbed is wrong). No per-monitor surfaces. The idle cost is the listener only. An exclusive keyboard grab can lock the user out if the agent hangs, so Esc always cancels, a finished flow closes the dialog, and a requester that vanishes cancels the request.
8. **Plumbing and conventions.** The pre-1.0 Quickshell polkit imports stay in one adapter file in `shell/adapters`. The visual part lives in `shell/components`, so a later adapter does not import a sibling module. A centred modal is neither a picker nor a popup in `STYLE.md`; it needs its own surface rule (this brief proposes the popup tokens). A single Esc cancels (there is no unsaved work, so the two-press exit rule does not apply) and a cancel must send the cancellation to polkit, not only close the window. The dialog needs an accessible name and role, and the error cannot be signalled by colour alone.

9. **Replacing the running agent is a start-up order problem, not a switch.** `hyprpolkitagent` runs on this host (started by the session; nothing in `hypr/` mentions polkit). Polkit allows one agent per session, so our registration fails if it is already there, and nothing falls back automatically: while the shell is down, restarting or crashed there is no agent, a waiting `pkexec` fails, and later requests fail with no dialog. Who stops `hyprpolkitagent`, what starts our agent, and in what order must be written down, and the dialog layer should tell the user when registration fails (`isRegistered` is available). Three details of the Quickshell module also matter: its default D-Bus path disagrees between `qml.hpp` (`/org/quickshell/Polkit`) and `qml.cpp` (`/org/quickshell/PolkitAgent`), so we set `path` explicitly; `setPath` ignores later changes, so it is never bound to anything dynamic; and polkit itself can cancel a request (a timeout, the requester dying), which must close the dialog, something a fake request will not exercise.
10. **The Hyprland rule is its own rule.** `hypr/rules.lua` already has a layer rule for the shell's namespaces (`no_anim`); `no_screen_share` goes in a separate rule for the dialog's namespace, and that namespace is added to the shared pattern only if the dialog needs `no_anim`.

## Goals vs. Non-Goals

* **In-Scope Goals:**
  * A themed, simple authentication dialog for polkit requests, replacing `hyprpolkitagent`.
  * A hidden field with no characters, no length and no per-key reaction; a static focus mark; Backspace clears the whole field; a checking state; no stray or empty submit.
  * The message and the account always visible; an account choice, reachable by keyboard, only when polkit offers more than one.
  * A loud, plain failure message after a wrong password, and then the request ends (no retry in the dialog).
  * One request at a time, queued, never replaced.
  * A small generic dialog contract (message, account, error line, checking state, submit, cancel) in `shell/components`, and one polkit adapter in `shell/adapters`.
  * Tests with a fake request, and an owner-run live check with `pkexec`.
  * A verified answer to whether the dialog is hidden from compositor capture and from gsr.
  * A written start-up and swap procedure for the agent (who stops `hyprpolkitagent`, who starts ours, in what order), a visible message when registration fails, and an explicit D-Bus path.
* **Out-of-Scope Non-Goals:**
  * Sudo askpass and pinentry adapters (the contract allows them later).
  * Retry inside the dialog, fingerprint or security-key flows, showing characters, dots or length in any form.
  * Reimplementing the polkit agent protocol (Quickshell's module does it).
  * A guarantee that the secret is wiped from memory (impossible in QML) or that gsr cannot see the dialog (unproven).

## Alternatives Weighed

* **A framework for secret prompts now (askpass, pinentry, polkit behind one abstraction).** Rejected: one consumer exists, so the seam would be a guess; askpass and pinentry add helper processes and sockets. The contract is kept small so extraction later is cheap.
* **Binding the dialog directly to Quickshell's polkit objects with no adapter.** Rejected: the module is version 0.1 and its API will move; one adapter file keeps a break to one place and lets the dialog be tested with a fake.
* **One dialog surface per monitor (the shell's usual `Variants`).** Rejected: a full-screen layer per monitor idles for a feature used a few times a day, and a request has one focus. One on-demand window on the focused screen.
* **Loading the dialog asynchronously like the other panels.** Rejected: a blank dialog that fills later, with the keyboard already grabbed, is a spoofing and typo risk.
* **Dots, a per-key pulse or a length hint.** Rejected by the owner: no reaction at all; the focus mark and the checking state are the only signals.
* **Retry inside the dialog (polkit's own behaviour).** Rejected by the owner: the dialog reports the failure and the request ends.
* **Reusing `PanelContext` and `ErrorPopup` as the dialog.** Partly rejected: they give the surface, the popup look and error presentation, but not the dim backdrop, the exclusive keyboard or the hidden field; those are added.

## Key Decisions & Staging for Next Steps

Settled by the owner:

* Replace `hyprpolkitagent`; theme from the shell; centred modal on the focused screen over a dimmed backdrop.
* Hidden field, no characters, no length, no per-key reaction; focus means everything typed is the password until Enter.
* No retry. The asked account is shown (the owner left the exact wording to the design).
* Enter submits, Esc cancels, no other input methods now.
* Design not limited to polkit; only polkit is built.
* Keep or hide in recordings by a Hyprland rule; hiding the secret itself is what matters most.
* Test in the nested session; the real agent is exercised on the host only with `hyprpolkitagent` as the way back.

Proposed by the review, awaiting the owner's decision:

1. The dialog contract: message, account, error line, checking state, `submit(secret)`, `cancel()`, in `shell/components` (`SecretDialog`); everything polkit-specific in one `shell/adapters` file.
2. Backspace clears the whole field; a static focus border; a checking state; ignore keys for about 300 ms after showing; Enter on an empty field does nothing.
3. After a wrong password: the adapter cancels the flow, the dialog shows "Wrong password" for a moment, then closes. (Owner to confirm the wording and whether it should stay until a key is pressed.)
4. Prompts that ask for visible input (`responseVisible`) are refused with a clear message instead of being shown, so the dialog never shows characters.
5. Multi-round and information prompts are shown as lines in the dialog; a request that needs something the dialog cannot do is cancelled with a message.
6. The surface follows the popup tokens (`popupSurface`, `popupBorder`, `popupRadius`) on the dimmed backdrop; a single Esc cancels and tells polkit.
7. One on-demand window, synchronous load, FIFO queue, the visible prompt never replaced; no timeout in the first version, but Esc always works and a vanished requester cancels the request.
8. The layer namespace and its Hyprland rule come from one source (`hypr/profile.lua` and the shell config); a live test decides whether the capture claim is made.
9. Testing: QML tests and nested snapshots with a fake request (observable-surface leak checks, no "nothing leaks" claim); an owner-run live check with exact steps for `pkexec true` after stopping `hyprpolkitagent`; a live recording check with gsr.
11. Agent hand-over: our agent registers at login before `hyprpolkitagent`, which is no longer started; until then the swap is manual, and `hyprpolkitagent` is the documented way back. The adapter sets the D-Bus `path` explicitly, never rebinds it, and closes the dialog when polkit cancels a request. The dialog layer reports a failed registration (`isRegistered` false).
12. Staging: phase 0 spike (does `no_screen_share` hide a layer from gsr, and can our agent register next to or instead of `hyprpolkitagent`); phase 1 the dialog and fake-request tests; phase 2 the polkit adapter and the live check; phase 3 migration (start-up and removal of `hyprpolkitagent`).
