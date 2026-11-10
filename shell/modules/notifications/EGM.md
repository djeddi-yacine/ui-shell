# notifications

## Overview
The shell is the notification daemon: it claims the D-Bus name through `Adapters.NotifSource`, shows one popup at a time, and keeps this session's history in a right-edge drawer, one stack per app. Design: `features/designs/notifications.md`.

## Interface
- `NotifCenter` (singleton, logic only): `entries` (newest first, no cap), `groups` (one `{appName, items}` per app, ordered by the newest item), `unread`, `suppressed`, `dnd`, `redact`, `fullscreen`, `popup`, `popupHovered`, `expandedApps`, `source` and `rules` (both set once by `shell.qml`; fakes in tests); functions `ingest`, `update`, `post` (internal entries), `soundFor`, `setRead`, `toggleRead`, `markGroupRead`, `markAllRead`, `isExpanded`, `toggleGroup`, `visibleItems`, `visibleEntries`, `loadImage`, `clear`, `clearGroup`, `clearAll`, `setDnd`, `dismissPopup`, `invoke`, `invokeDefault`, `lookup`, `buttonActions`, `timeoutFor`; signal `soundRequested(path)` [NotifCenter.qml].
- `NotifState` (singleton): `open`, `screenName`, `show`, `toggle`; a member of the panel group [NotifState.qml].
- `NotifPopupSurface`: one window per screen, mapped only on the focused monitor, `keyboardFocus` none, input region is the card [NotifPopupSurface.qml].
- `NotifSurface` / `NotifDrawer`: full-screen backdrop plus the drawer; exclusive focus while open; Escape and a click outside close it. Drawer-local keys (only while open): `D` do not disturb, `R` / `Shift+R` read toggle / mark all, `Shift+Delete` clear stack, `Ctrl+Shift+Delete` clear all, `1`-`9` the selected card's actions, arrows, Space (expand), Return, Delete [NotifSurface.qml, NotifDrawer.qml].
- `NotifStack`: one app's stack: a header (app, expand chevron when more than one card, clear group) over its cards. Collapsed, the cards are a deck (newest on top, up to `deckDepth` layers peeking `deckPeek` behind, smaller and shaded); expanding fans it into a list with one spring (`Theme.Motion.stack*`), each card a beat after the one above. `dismiss(id)` removes one card with a slide, `clearAll()` slides and fades the whole stack out, then clears it. A stack fades itself in (`entrance`) when it arrived within `Config.Notifications.arrivalWindowMs`; older ones just appear [NotifStack.qml].
- `NotifCard`: shared card (popup read-only, drawer interactive); actions only when `showActions`; read toggle, delete and image button only when `interactive` [NotifCard.qml].
- `NotifRules` / `NotifMatch.js`: the owner's rules from component settings; first matching rule wins [NotifRules.qml, NotifMatch.js].
- `NotifSound`: plays a file through the configured notify-sound script [NotifSound.qml].
- `NotifFeeds`: posts the shell's own screenshot and recording results into `NotifCenter.post` [NotifFeeds.qml].
- `NotifSpoiler`: moving-noise shader hiding one block of text; falls back to a flat tint when the shader is missing [NotifSpoiler.qml, shaders/spoiler.frag].
- `NotifMarkup.js`: `toStyled`, `toPlain`, `openable` for the spec's body markup [NotifMarkup.js].
- `NotifShortcut`: global shortcuts named by `Config.Notifications.shortcutDrawer`, `shortcutDnd`, `shortcutDismiss` [NotifShortcut.qml].

## Rules
Fields of a rule: `name`, matchers `app` (exact app name), `appId` (exact), `appMatch` (case-insensitive regexp over the app name), `match` (regexp over summary and body), and effects `hide`, `mute`, `sound`, `reveal`. Every matcher that is set must match; a rule with no matcher never matches; an invalid regexp never matches [NotifMatch.js:match]. `reveal` exempts a notification from the recording blur [NotifCenter.qml:ingest]. Rules are read once when the shell starts; changing the file takes effect after a restart [shell/shell.qml].

## Invariants
- Only `adapters/NotifSource.qml` imports the Quickshell notification module; this module never holds a Quickshell object.
- Every decision (popup, DND, timeout, unread, rules, sound) is in `NotifCenter`; UI files only bind to it.
- DND and fullscreen never remove an entry; they only suppress the popup (and the sound under DND). A hidden or muted entry makes no sound.
- A transient notification is only a popup; it never reaches the history.
- A replayed notification from before a reload (`generation` set) goes to history already read, with no popup and no sound.
- Read state is the owner's: only `setRead`, `toggleRead`, mark-all, or acting on a notification changes it. Acting on a non-resident notification closes it.
- Internal entries get negative ids, so they never collide with D-Bus ids.
- Redaction (`NotifCenter.redact` and not `entry.reveal`) never creates the text items, and the spoiler's size never depends on the hidden text.
- An image never loads until the owner asks (`loadImage`); popups show none.
- Timeouts: critical never expires; `0` never; the sender's value is capped by `maxTimeoutMs`; `-1` picks by urgency.
- A card or stack fades in only when it just arrived; the drawer's list only moves and removes rows.
- Namespaces are in `Config.Notifications` and `hypr/rules.lua` (both in the `no_anim` pattern).

## Side Effects
- Owns the `org.freedesktop.Notifications` bus name while the shell runs.
- The drawer holds exclusive keyboard focus while open.
- Runs the notify-sound script as a process per sound.
- Opens a body link externally only when `Markup.openable` allows it.

## Verification
- `make test-qml` (`tst_NotifCenter`, `tst_NotifCard`, `tst_NotifMarkup`, `tst_NotifRules`); `make test-notifications` (nested session, real D-Bus); `make test-notify` sends numbered cases to a running shell (`tests/README.md`).
