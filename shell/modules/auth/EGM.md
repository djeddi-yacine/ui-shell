# auth

## Overview
The authentication dialog: shows polkit password requests in the shell's own theme, one at a time, over a dimmed backdrop on the focused screen. Design: `features/designs/polkit.md`.

## Interface
- `AuthState` (singleton): `auth` (the `Adapters.PolkitAuth` instance), `preview`, `agentEnabled`, `source`; env `UI_SHELL_OPEN_AUTH=1` (once) or `loop` swaps the real polkit source for a fake request (`PreviewFlow`: the password `0` succeeds, anything else fails, Esc cancels; with `UI_SHELL_OPEN_AUTH=loop` a new one appears 1.5 s after each ends), `UI_SHELL_AUTH_AGENT=0` (the nested session default) registers no agent [auth/AuthState.qml].
- `AuthSurface`: two windows on the focused screen, mapped only while `auth.active`: a full-screen dimming layer (`ui-shell-auth-scrim`, layer Top, no keyboard, visible to screen capture) and a card-sized layer (`ui-shell-auth`, exclusive keyboard, hidden from screen capture by `no_screen_share`). The dialog is built synchronously with the card [auth/AuthSurface.qml].
- `AuthDialog`: `Controls.SecretDialog` wired to the adapter snapshot and actions [auth/AuthDialog.qml].

## Invariants
- The namespaces appear in `AuthSurface.qml`, `Config.Auth.namespace` and `hypr/rules.lua` (the exact `no_screen_share` rule for the card; both names in the `no_anim` pattern); `tests/scripts/check-auth` fails if they differ.
- A capture of the nested session shows the dimmed desktop with a black rectangle where the card is, so the card's look cannot be checked from a snapshot; `UI_SHELL_OPEN_AUTH=1 make test-env-snapshot` passes because the dimmed desktop is in the frame.
- The window is not in a `Variants` and not part of the panel mutual exclusion in `shell/shell.qml`; it is modal.
- The dialog never shows characters, length or a per-key reaction (see `components/SecretDialog`).

## Side Effects
- While active it holds exclusive keyboard focus; Esc always cancels the request in polkit.
- Registers a polkit agent through `Adapters.PolkitSource` at shell start.

## Verification
- Run: `make test-qml` (tst_SecretDialog, tst_PolkitAuth), `make test-auth`, `make test-hypr-config`; live check in `tests/README.md` ("Authentication dialog, live").
