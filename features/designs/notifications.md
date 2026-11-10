# Notifications

*   **Author:** djeddi-yacine
*   **Status:** Draft, ready for `egm-review`
*   **Date:** 2026-11-09

Input: [features/reqs/notifications.md](../reqs/notifications.md), which cites
[features/studies/notifications.md](../studies/notifications.md).

--------------------------------------------------------------------------------

## Overview

ui-shell becomes the only notification daemon on the desktop. Apps send
notifications over D-Bus (`notify-send`, chat apps, `grimblast`); today `dunst`
receives them. Dunst is a separate process with its own config and its own look.
This design replaces it with code inside the shell, using Quickshell's
`NotificationServer` (`Quickshell.Services.Notifications`), so notifications
share the shell's theme, panels and state.

Two surfaces show notifications:

*   A **popup**: one at a time, at the right corner of the monitor that has
    focus. It is read-only: it takes no keyboard focus and has no buttons. A dedicated
    shortcut dismisses it, and it leaves by itself after a timeout that depends on urgency.
*   A **drawer** on the right edge: the history of the current session, grouped
    by app. The drawer is the interactive place: it takes focus when opened, it
    is operated by keyboard, it holds the action buttons, and it is where the
    owner clears history by hand.

A bar icon shows the unread count and the do-not-disturb (DND) state. DND is a
manual switch only. A short rules file can mute, hide or play a sound for
chosen apps; a rule changes how a notification is presented, never whether it
exists, and the drawer shows a visible "rule: X" tag. While a screen recording
runs, the message text is blurred everywhere it appears (popup and drawer) and
the action buttons are hidden.

Shell modules (screenshot, recording, polkit) post to the same ingest through
an in-process path, without D-Bus.

## The Problem

*   Dunst is a dependency the shell does not control: a second process, a second
    config file, a look that ignores the shell's themes.
*   The shell has no toast surface. Modules report results through the modal
    `ErrorPopup`, which blocks the screen, so a finished screenshot or a
    recording error has no light-weight way to tell the user.
*   Nothing keeps a record of what was missed, and nothing hides message text
    while the screen is being recorded.

Quickshell can own the notification service, and the shell already has the
pieces around it (panels, theme tokens, global shortcuts, recording state). The
cost is that a shell crash or reload drops notifications; the owner accepts that.

## Goals

*   The shell is the only notification daemon. Another daemon that owns the bus
    name is ignored: no detection, no cutover steps.
*   Popups: one visible at a time at the focused monitor's right corner; a new
    notification replaces the one on screen; timeout by urgency; the timeout
    pauses while the pointer is over the popup; the dismiss shortcut closes it; critical
    notifications obey DND and expire like the others.
*   Under a fullscreen window only the sound plays, no popup.
*   Drawer on the right edge: in-session history with no cap and no expiry,
    cleared by hand; grouped by app; actions; progress bars (`value` hint);
    keyboard operation; it must stay usable with a very large list.
*   Bar icon: unread count; DND changes the icon only. DND does not survive a
    restart.
*   Manual DND with no automatic control flow of any kind.
*   Rules file written as a QML object (owner's choice) with a small schema that
    needs no version field: match by app id or regular expression; effects
    mute, hide, sound. First match wins; a bad file keeps the last good set and
    reports one clear error; a missing file means no rules. Every effect is
    visible as a "rule: X" tag.
*   Optional sound, off by default, played by a small script that calls
    `pw-play` (argument array, one at a time, a message if `pw-play` is missing);
    a rule can turn it on.
*   Recording spoiler (the owner's "blur"): the message text is replaced by a moving-noise shader, like Telegram's spoiler, in popup and drawer while
    `RecordState` says a recording is active; action buttons are hidden; the
    spoiler also stays on while hovered; it is applied at creation so the first
    popup after recording starts is already blurred.
*   Internal path for shell modules through the same ingest as D-Bus, tagged by
    origin.
*   A test sender script and a stress test, in the style of the launcher's.

## Non-Goals

*   Inline reply, lock-screen display, persistent history, screen-sharing
    handling, hiding the drawer during casting (later), automatic DND, a rule
    language, a framework for other senders.
*   Actions on popups (popups are read-only).
*   A startup check for another daemon.
*   Keeping notifications across a shell crash or reload.

## Open Questions

*   **Timeouts per urgency.** Set in `Config.Notifications` (2.5, 4, 8 s, cap
    15 s) and honouring a sender's own `expireTimeout` when it gives one.
*   **Where actions live.** Popups are read-only, so actions are only in the
    drawer. Does a notification with an action but no drawer open still need a
    way to reach that action by shortcut (invoke the newest notification's
    default action)?
*   **What `keepOnReload` does** to tracked notifications when the shell
    hot-reloads, and whether that counts as a restart. To verify in Quickshell.
*   **How `expireTimeout` values 0 and -1 reach QML**, and whether the `value`
    and other hints arrive. To verify.
*   **Fullscreen detection** for "only the sound plays": which Quickshell/Hyprland
    property reports a fullscreen window on the focused monitor. To verify at
    implementation.
*   **Spoiler shader build step.** A `.qsb` shader needs `qsb` at build or a
    committed binary. To settle in the implementation plan.

## Critical User Journeys (CUJs)

### CUJ 1: A message arrives while working

*   **Given**: The shell is running, DND is off, no recording, a terminal has
    focus.
*   **When**: An app sends a normal-urgency notification.
*   **Then**: One popup appears at the right corner of the focused monitor. The
    terminal keeps keyboard focus. The popup leaves after its timeout, or when
    the dismiss shortcut is pressed. The notification stays in the drawer as unread and the
    bar icon shows the count.

### CUJ 2: A burst of notifications

*   **Given**: A popup is on screen.
*   **When**: Ten more arrive in one second.
*   **Then**: Only the newest popup is visible. All ten appear in the drawer in
    arrival order. The unread count reflects all of them.

### CUJ 3: Reading and clearing history

*   **Given**: Several unread notifications from two apps.
*   **When**: The user opens the drawer by shortcut, moves through groups and
    items by keyboard, activates an action, then clears one group and later all.
*   **Then**: The drawer takes focus on open and returns it on close; the unread
    count drops as items are seen; the action runs; cleared items are gone and
    nothing is removed that the user did not clear.

### CUJ 4: Manual do-not-disturb

*   **Given**: DND is turned on from the bar icon or a shortcut.
*   **When**: Notifications arrive, including a critical one.
*   **Then**: No popup and no sound for any of them; all are kept in the drawer
    and counted; the bar icon shows DND. Turning DND off changes nothing else.

### CUJ 5: Recording hides text

*   **Given**: A screen recording is running, a popup is on screen.
*   **When**: A new notification arrives, and the drawer is open.
*   **Then**: Both popup and drawer show the message text blurred and no action
    buttons; hovering does not reveal the text. When the recording stops the
    text is clear again.

### CUJ 6: A rule applies visibly

*   **Given**: The rules file hides one app and plays a sound for another.
*   **When**: Each app sends a notification.
*   **Then**: The hidden app's notification shows no popup, appears in the
    drawer tagged "rule: <name>", and is counted in the unread number. The other
    app's notification plays the sound once and shows a normal popup.

### CUJ 7: A shell module reports a result

*   **Given**: The user takes a screenshot with the shell.
*   **When**: The capture succeeds or fails.
*   **Then**: The module posts through the internal path; the popup and drawer
    entry look like any other notification and obey DND and rules in the same way.

## Technical Plan (Architecture)

### Facts checked in Quickshell 0.3.2 (Qt 6.12)

*   `NotificationServer` (`Quickshell.Services.Notifications`) advertises almost
    nothing by default. We set `bodySupported`, `actionsSupported` and
    `imageSupported` true, and leave `bodyMarkupSupported`, `bodyHyperlinksSupported`,
    `inlineReplySupported` and `persistenceSupported` false
    (`refs/quickshell/src/services/notifications/qml.hpp:27-69`).
*   `keepOnReload` defaults to true: on a Quickshell reload the tracked
    notifications are re-emitted with `lastGeneration` set
    (`qml.hpp:27-30`, `notification.hpp:81-82`). A reload therefore keeps the
    list; a crash or full restart drops it, as the owner accepted.
*   A notification is kept only if `tracked` is set true in `onNotification`
    (`qml.hpp:117-119`). `expireTimeout`, `urgency`, `actions`, `image`, `resident`,
    `transient` and the whole `hints` map are readable properties
    (`notification.hpp:72-118`), so the `value` hint for progress arrives in
    `hints`. `expireTimeout` is a `qreal` holding the raw D-Bus milliseconds
    (`notification.cpp:115`), so 0 and -1 reach `NotifSource` unchanged; the
    adapter maps them (item 1).
*   `QtQuick.Effects` is already used in the repo (`shell/components/SecretDialog.qml`),
    but the owner chose a custom `ShaderEffect` for the spoiler.

### Layers

Follows the repo split: source adapter, logic singleton, module UI.

```text
 apps over D-Bus                 shell modules (shot, record, polkit)
        |                                   |
  NotifSource (adapter)            NotifFeeds (connects their signals)
   only importer of the                      |
   Notifications module                      |
        \__________ ingest(origin, data) ____/
                         |
                    NotifCenter (logic singleton)
        entries, rules, DND, unread, timeouts, popup choice
           |                |                 |
     NotifPopupSurface   NotifDrawer      NotifChip (bar)
     (layer shell,       (panel, in       (unread count,
      no focus)           PanelGroup)      DND icon)
```

*   **`NotifSource`** (adapter singleton, `shell/adapters/`): owns the
    `NotificationServer`, sets `tracked = true`, converts each notification into
    a plain entry object (`id`, `appName`, `appId` from `desktopEntry`, `summary`,
    `body`, `icon`, `image`, `urgency`, `expireTimeout`, `actions`, `progress`
    from `hints.value`, `origin: "dbus"`) and calls `NotifCenter.ingest`. It
    forwards `invoke` and `dismiss` back to the live `Notification`. Nothing
    else imports the notifications module.
*   **`NotifCenter`** (logic singleton, `shell/modules/notifications/`): makes
    no UI. It holds the entries (newest first, no cap), the unread count, DND,
    the `redact` flag, the current popup entry, and the timers. `ingest`
    handles `replaces_id` and progress updates in place, applies the rules,
    decides popup / sound / count, and starts the timeout. A fake source can
    feed it in tests.
*   **`NotifRules`**: loads the rules file and answers `match(entry)` with the
    first matching rule.
*   **`NotifFeeds`**: connects `ShotRunner.captured`/`failed` and
    `RecordState.failed`/saved to `NotifCenter.ingest` with `origin: "internal"`,
    so the notifications module does not import the recorder. `shell.qml` binds
    `NotifCenter.redact` to `RecordState.active`.
*   **`NotifPopupSurface`**: one layer-shell window per screen, namespace
    `ui-shell-notif`, `WlrLayer.Top`, `keyboardFocus: None`, the same as
    `AuthSurface` (`modules/auth/AuthSurface.qml:32-35`). Only the screen with
    focus shows the popup. The input region covers the card only.
*   **`NotifDrawer`** (panel on the right edge, state `NotifState` with a
    writable `open`, added to the existing `PanelGroup` so it excludes the
    other panels): `ListView` over a `ScriptModel`, with a section per app
    (grouping), unread marker, action buttons, progress bar and the "rule: X"
    tag. Only visible rows are built, so unbounded history stays usable.
*   **`NotifSpoiler`**: replaces the message text, drawn with a `ShaderEffect`
    that renders moving noise inside the text's box. When `redact` is true
    the real `Text` is not drawn at all, and the actions row is not built.
    Applied on creation from the same binding. Hover does not change it.
*   **`NotifChip`** (bar): bell icon, unread count, DND changes the icon only.
    Click opens the drawer.
*   **`NotifShortcut`** (`GlobalShortcut`s, like `AppShortcut.qml`): open or
    close the drawer, toggle DND, dismiss the popup.
*   **Sound**: `scripts/notify-sound` takes the sound file as one argument, runs
    `pw-play` through an argument array, allows one instance at a time and a
    cooldown, and prints one line on a missing `pw-play`. Sound is off by
    default (config); a rule can turn it on.
*   **Rules file**: the existing component-settings store, as a new component
    `notifications`. The file is `<components dir>/notifications/Default.qml`
    (path from `scripts/component-settings-path`), a plain QML object with one
    property `rules`: an array of data objects (`name`, `app`, `appId`, `match`
    regexp, `mute`, `hide`, `sound`). First match wins. A load or validation
    error keeps the last good set and shows one error; a missing file means no
    rules.

### Behaviour decisions

*   **Timeouts** (set during implementation; `Config.Notifications` is the
    authority): low 2.5 s, normal 4 s, critical 8 s. A sender's `expireTimeout`
    above 0 is used, capped at 15 s. Quickshell reports it in milliseconds; the
    adapter maps 0 and -1 to "no value", which
    uses the urgency default. **Superseded** (see "As built, revision 2"): a critical
    notification and a sender timeout of 0 never expire. The timer pauses while the pointer is over the popup
    and resumes with the remaining time.
*   **One popup**: a new entry replaces the visible one at once. The replaced
    entry stays in the drawer as unread.
*   **Mute / hide / DND** (all keep the entry in the drawer and the unread
    count):

    | Effect | Popup | Sound | Drawer tag |
    | --- | --- | --- | --- |
    | mute | shown | none | `rule: name` |
    | hide | not shown | none | `rule: name` |
    | DND | not shown | none | none (bar icon shows DND) |

*   **Fullscreen**: when a fullscreen window is on the focused monitor, the popup
    is not shown and the sound plays (if enabled).
*   **Dismiss**: a dedicated shortcut (`action_mod + BACKSPACE`, that is
    SUPER+SHIFT+BACKSPACE; no existing bind uses it) closes the popup. Decided by the
    owner: a popup has no focus, so it cannot receive Escape, and a global
    Escape binding would steal Escape from every app. Escape stays untouched.
*   **Polkit prompts** are not notifications and are never affected.
*   **Rules never remove**: a rule changes the popup and the sound only.


### As built, revision 2

This section records where the code left the plan above. The plan stays as the history; where they differ, this section wins. Decisions are also in the brain page `notification-center`.

*   **Deck.** A collapsed stack is a z-ordered deck (`NotifStack.qml`): the newest card on top, up to `deckDepth` layers behind it, each `deckPeek` lower and `deckScaleStep` narrower, shaded toward the background by `deckShade`. Only the newest card is keyboard-visible while collapsed (`collapsedStackItems` = 1). Expanding fans the deck into a list with one `Motion.stackSpring` spring (`morph`), each card starting `stackStagger` after the one above. A card's border is drawn at whole pixels: the layers are sized by `width`/`height`/`x`/`y` (rounded), never by a `scale` transform, because a scaled or half-pixel rectangle shimmers while it moves.
*   **Removal motion.** A deleted card slides right (`leaveSlide`) and fades, then the entry leaves the centre. "Clear group", Shift+Delete and "Clear all" slide the stack out through the right edge while it fades; the gap closes over the second half so the stacks below do not jump. The drawer's `clearEverything()` animates the drawn stacks and clears the others at once. With motion off, everything is immediate.
*   **Drawer timing.** `NotifSurface` keeps the window up while `reveal > 0`; backdrop, drawer opacity and a right-margin slide (`drawerSlide`) share one `Motion.drawerDuration`.
*   **Read state replaces seen.** `read` per entry; `setRead`, `toggleRead`, `markGroupRead`, `markAllRead`. Opening the drawer reads nothing; acting on a notification does. Card check button, `R` (current), `Shift+R` (all), header "mark all read". Unread drives the bar chip and the drawer title. An unread card has a dot in the urgency colour and bold summary; a read card sinks toward the surface and uses `textMuted`.
*   **Freedesktop spec 1.2.** Body markup `<b> <i> <u> <a href>` (`NotifMarkup.js`: `toStyled`, `toPlain`, `openable`; `<img>` shows its alt text; links open only http, https, mailto, file). Capabilities: body, body-markup, body-hyperlinks, actions, action-icons, icon-static, persistence. Hints read: `value`, `category`, `transient` (popup only, not in history), `resident` (an action keeps it, marked read), `action-icons`, `sound-file`, `sound-name`, `suppress-sound`. The `default` action is the click, not a button. `timeoutFor`: critical 0 (never), a sender 0 never, else the per-urgency fallback capped at `maxTimeoutMs`. **This reverses the earlier "critical expires like the others".** Deliberate gap: an expired popup stays open on the bus (in history) rather than sending NotificationClosed(expired).
*   **Sound.** `soundFor(e)`: a rule's sound, then `suppress-sound`, `sound-file` (a `file://` URL, decoded), `sound-name`, then the configured default. `scripts/notify-sound` takes an absolute file or a freedesktop sound-theme name (searches `sounds/*/stereo/NAME.{oga,ogg,wav}`); an unknown name exits 2.
*   **Icons.** Header and stack controls are icon-only `ShellIconButton`s (no box): DND (`do-not-disturb`), clear all (`clear-all`), mark all read (`check`), expand (`expand-more`, turned by `morph * 180` degrees), clear group (`remove`), delete (`close`). The pictures are QML generated from `shell/svg` (see `STYLE.md`, Icons). Colours come only from theme tokens.
*   **Tests.** `tst_NotifCenter` (timeouts, read state, transient, sound hints, default action, collapsed deck), `tst_NotifMarkup`, `tst_NotifCard`, `tst_NotifRules`; `make test-notifications` (nested real D-Bus session); `make test-notify` sends every case to a running shell, now including `image-path`, `image-data` (a raw 2x2 RGBA over `busctl`), `sound-name`, `sound-file` and `suppress-sound`, with a 1 s pause between cases (`NOTIFY_CASE_PAUSE`) and a parallel burst.
*   **Redaction.** While `RecordState.active`, `NotifCenter.redact` is true and every `NotifCard` replaces summary and body with `NotifSpoiler` bars (no text, image or action is created). A rule with `reveal: true` sets `entry.reveal` at ingest and exempts that notification. `make test-notify` has `redaction` and `redaction held` cases that fake a recording with a stand-in recorder state file.
*   **Not verified automatically.** Motion, colours and sound are checked by eye and ear on the host (the offscreen runner has no GPU or audio).

## Alternatives Considered

### Alternative A: Keep dunst and restyle it

*   **Pros**: Mature, no code to write, survives a shell crash or reload.
*   **Cons**: A second process and a second config file; no integration with
    themes, panels, recording state or DND state.
*   **Reason for Rejection**: Rejected by author: the separate process and
    config are the reason for this feature.

### Alternative B: Persist history to disk

*   **Pros**: History survives restarts and crashes. caelestia-shell,
    DankMaterialShell, noctalia and Ambxst all do it (study CS1.2, DM1.9, NC2.3, AX1.4).
*   **Cons**: Message text, which can include one-time codes, is stored on disk;
    needs a format, a size policy and a migration path.
*   **Reason for Rejection**: Rejected by author: history is in memory only and
    the loss on a crash is accepted.

### Alternative C: Rules that can drop a notification

*   **Pros**: Simplest way to silence a noisy app.
*   **Cons**: A dropped notification leaves no trace, which breaks the rule of
    no hidden control flow.
*   **Reason for Rejection**: Rejected by author: a rule changes the popup and
    the sound only; the entry stays in the drawer with a "rule: X" tag.

### Alternative D: Rules file as JSON or INI

*   **Pros**: JSON was the owner's first choice and has no code execution. INI
    follows `CONFIGURATION.md`, which says JSON is an intermediate, and reuses
    `read-ini`.
*   **Cons**: JSON needs an exception to the configuration rule. INI has no
    lists, so several app ids need a comma-separated value.
*   **Reason for Rejection**: Rejected by author: the owner chose a QML file.
    This costs a documented exception, user-edited code in the shell, and a
    guard that keeps the last good rule set when the file fails to load.

### Alternative E: Real blur of the message text

*   **Pros**: `MultiEffect` is already in the repo; no shader build step.
*   **Cons**: The real text stays in the scene graph, and a weak blur on small
    text can stay readable.
*   **Reason for Rejection**: Rejected by author: the owner chose the animated
    spoiler (Telegram style), where the text is not drawn at all.

### Alternative F: Placeholder bars instead of text

*   **Pros**: Cheapest option; no readable text exists.
*   **Cons**: Does not look like Telegram's effect.
*   **Reason for Rejection**: Rejected by author: the spoiler shader was chosen.

### Alternative G: Popups take keyboard focus to receive Escape

*   **Pros**: Escape dismisses the popup directly.
*   **Cons**: A popup would steal input from the focused app, and a global
    Escape binding would take Escape from every app.
*   **Reason for Rejection**: Rejected by author: popups are read-only and take
    no focus; keyboard control belongs to the drawer and a dedicated dismiss
    shortcut.

### Alternative H: Hide popups from the recording instead of obscuring text

*   **Pros**: Recording shows no notification at all.
*   **Cons**: The effect on the recorder is unproven; the owner wants the popup
    visible to the user while recording.
*   **Reason for Rejection**: Rejected by author: popups stay visible, only the
    message text is obscured.

### Alternative I: Critical notifications bypass do-not-disturb or never expire

*   **Pros**: Common in other shells (DankMaterialShell never expires critical
    notifications, study DM2.1).
*   **Cons**: Contradicts "no hidden control flow": DND would not mean DND.
*   **Reason for Rejection**: Rejected by author: critical notifications follow
    DND. **Reversed later**: they do not auto-expire (freedesktop spec); DND still
    applies. See "As built, revision 2".

### Future Improvements

*   **The idea**: Hide the drawer from screen capture while casting (owner: later).
*   **The idea**: A persistent history store, if the in-memory loss ever hurts.
*   **The idea**: Actions on popups, if read-only popups prove too limiting.

--------------------------------------------------------------------------------

## Detailed Implementation Plan

Paths are relative to the repository root. "EGM.md" files are updated whenever
the interface they describe changes (AGENTS.md rule).

### Phasing

"Shippable" means: the repository builds and `make test-qml` passes. A part of
an item that belongs to a later phase carries the tag `[P<n>]`; an untagged part
belongs to the first phase listed for the item. Status is tracked by `git
status` and the brain page, not in this file.

| Phase | Adds | Stubs left until later |
| --- | --- | --- |
| P1 | items 1, 2, 3 (without rules and sound), 10 (types that exist), 11 (all but `spoilerSpeed`), 14, 18 (`tst_NotifCenter`, `FakeSource`) | `rules` is null, no `soundRequested` emitter |
| P2 | items 5, 6 (plain text), 8, 9 (`NotifShortcut`), 12, 13 (source, shortcuts, surfaces, `PanelGroup`), 16 | `redact` and `fullscreen` stay false; the drawer header shows no rule error |
| P3 | item 4 (`NotifMatch`, `NotifRules`, `ComponentSpec`, settings path), item 13 (`NotifRules` instance and `rules` binding), `tst_NotifRules`, item 19 wiring | none |
| P4 | item 15 (script, role, `NotifSound`), the `soundRequested` emit in item 3 | none |
| P5 | item 9 `NotifFeeds`, item 13 `fullscreen` binding | none |
| P6 | item 7, item 13 `redact` binding, item 11 `spoilerSpeed`, `tst_NotifCard` | none |
| P7 | item 17 (nested test), the nested-session wiring in item 19 | none |

Item 20 (docs and `EGM.md`) is finished with each phase for the files it adds.
Item 21 changes no file.

### Target Files to Create/Modify

#### 1. `shell/adapters/NotifSource.qml` (Create)

*   **Type / Scope**: Singleton adapter; the only importer of
    `Quickshell.Services.Notifications` (same role as `PolkitSource.qml`). It
    never imports the notifications module: the center takes it as an injected
    `source` (see item 3), so unit tests can pass a fake.
*   **Proposed Changes**: Declare one `NotificationServer` with `keepOnReload: true`,
    `bodySupported`, `actionsSupported`, `imageSupported` true and markup,
    hyperlinks, inline reply and persistence false. The whole `hints` map is
    readable on a notification, so `extraHints` is not set. `onNotification` sets `tracked = true`, keeps
    the object in an `id -> Notification` map (the only place a Quickshell
    object lives), and emits `received(entry)`. The entry (the one schema; item 3 adds center fields) has `id`, `appName`,
    `appId`, `summary`, `body`, `icon`, `image`, `urgency` (`low|normal|critical`),
    `expireTimeout` in milliseconds (Quickshell stores the raw D-Bus
    milliseconds unchanged, `notification.cpp:111-115`; the adapter passes
    values above 0 through and sends 0 for 0 and -1, which the center treats as
    "no value" and uses the urgency default), `actions` as `{identifier, text}`, `progress` (`hints.value` or -1),
    `origin: "dbus"` and `generation`. `generation` is the Quickshell
    `lastGeneration` flag: true when the notification is re-emitted after a
    reload. Signals: `received(entry)` (once per new object), `updated(entry)`
    (any property change on a tracked object) and `closed(int id)` (the sender
    or Quickshell closed it). Quickshell's `Notify` handles `replaces_id` by
    finding the tracked object with that id, calling `updateProperties` on it,
    emitting no new `notification` signal and returning the same id
    (`refs/quickshell/src/services/notifications/server.cpp:187-199`). So a
    replacement is an `updated` for the same id, never a `received`. Per-object hooks: an `Instantiator` over `server.trackedNotifications`
    creates a `Connections` per object; any change of `appName`, `summary`,
    `body`, `appIcon`, `image`, `urgency`, `expireTimeout`, `actions` or `hints`
    emits `updated`; `closed` fires from the object's `closed(reason)` signal,
    and also for the adapter's own `dismiss()` (the center ignores it by id: the
    entry is already removed). Tracked objects are released only by a center
    `clear*`/`remove` that calls `dismiss`; expiry and user dismissal keep the
    entry and its tracked object by design, so the map grows with history. The
    four capability flags set to false are `bodyMarkupSupported`,
    `bodyHyperlinksSupported`, `inlineReplySupported` and `persistenceSupported`.
    The `hints` map is readable on a `Notification` (`hints` property in
    `refs/quickshell/src/services/notifications/notification.hpp`). Functions:
    `invoke(id, identifier)` calls the action's `invoke()`; `dismiss(id)` calls
    `dismiss()` and drops the map entry.

#### 2. `shell/adapters/qmldir` and `shell/adapters/EGM.md` (Modify)

*   **Type / Scope**: Module registration and contract.
*   **Proposed Changes**: Register `NotifSource` . The contract lists the
    entry shape and the three signals, and states that nothing else imports the
    notifications module. Which call reaches the sender is fixed by this table:

    | Event | Popup | Drawer entry | Sender (`NotifSource.dismiss`) |
    | --- | --- | --- | --- |
    | Popup timer expires | removed | kept | not called |
    | User dismiss shortcut | removed | kept | not called |
    | Sender closes (`closed`) | removed if shown | kept; entry field `closed` set true, card shows "closed" and its action buttons are disabled | not called |
    | `clear(id)` / `clearGroup` / `clearAll` | removed if shown | removed | called per D-Bus entry |

#### 3. `shell/modules/notifications/NotifCenter.qml` (Create)

*   **Type / Scope**: Logic singleton, no UI, testable with a fake source. The
    seam: `property var source`, set once in `shell.qml` to `Adapters.NotifSource`.
    A `Connections` block maps `received` to `ingest`, `updated` to `update` and
    `closed` to the table in item 2. The center calls `source.invoke` and
    `source.dismiss`; nothing else.
*   **Properties**:
    *   `entries` (newest first, no cap); `popup` (entry shown or null);
        `popupHovered`; `dnd` (false at start, never saved).
    *   Bound from `shell.qml`: `redact`, `fullscreen`, `drawerOpen` (from
        `NotifState.open`), `rules` (a `NotifRules` instance, or null for none).
    *   Computed over `entries`: `unread` (count with `seen` false, hidden and
        DND ones included) and `suppressed` (count with `hidden` true; shown in
        the drawer header as "N hidden by rules").
*   **Entry fields** (the schema is item 1; the center adds): `seen`, `hidden`
    (a matching rule has `hide`), `muted` (a matching rule has `mute`), `tag`
    ("rule: NAME" or ""), `time` (ms since epoch at arrival), `closed` (false
    until the sender closes it). DND sets neither `hidden` nor `muted`: DND is
    read from `dnd` at the moment of the decision.
*   **Functions**: `ingest`, `update`, `show`, `dismissPopup`, `markSeen(id)`,
    `markAllSeen()`, `remove(id)`, `clear(id)`, `clearGroup(app)`, `clearAll()`,
    `setDnd(bool)`, `invoke(id, action)`; signal `soundRequested(string path)`.
*   **Ingest order**: (1) dedupe; (2) `rules.match(entry)` gives a rule or null,
    which sets `hidden`, `muted` and `tag`; (3) store at the front, `seen` is
    `drawerOpen`; (4) popup decision; (5) sound decision.
*   **Dedupe**: an entry whose `id` is held and whose `generation` is true was
    re-emitted after a reload: ignored (no popup, no unread change, no sound).
    An entry whose `id` is held and `generation` is false goes to `update`. An
    entry with a new `id` and `generation` true (the center lost its state in the
    reload) is stored as seen, with no popup and no sound.
*   **Update**: replaces the fields in place (position unchanged, `seen`,
    `hidden`, `muted`, `tag` and `time` unchanged; rules are not re-run). If the
    entry is not `hidden`, DND is off and `fullscreen` is false, it becomes the
    popup again and its timer restarts at the full time. No sound on update.
*   **Popup**: shown unless DND, `hidden` or `fullscreen`; critical entries follow
    DND. A new popup replaces the visible one at once. Timeout is the sender's
    `expireTimeout` when it is above 0, capped at `maxTimeoutMs`, else the
    default of its urgency (low, normal, critical; critical entries expire like
    the others). A `Timer` runs while `popup` is set and `popupHovered` is false;
    on hover it stores the remaining milliseconds, and on leave it restarts with
    that remainder. Expiry sets `popup` to null and keeps the entry.
    `dismissPopup()` does the same, does not mark the entry seen, and is a no-op
    when `popup` is null.
*   **Sound** (the one authority): `soundRequested(path)` is emitted only if
    not DND, not `muted`, not `hidden`, and either the matching rule has a
    `sound` (plays even when `soundEnabled` is false) or `soundEnabled` is true
    and `soundFile` is a non-empty absolute path (otherwise skip, silently).
    Fullscreen does not stop it. The 500 ms cooldown lives only in
    `scripts/notify-sound`.
*   **Edge cases**: a new `id` with `generation` false is the normal arrival and
    goes through the ingest order. `update` for an unknown id is ignored. `update`
    for a `closed` entry is ignored. `show(entry)` sets `popup` to the entry and
    restarts the timer (used by `ingest` and `update`); a new popup starts
    un-hovered (`popupHovered` is reset to false). `remove(id)` deletes one entry
    and, for D-Bus entries, calls `source.dismiss(id)`; it is the same as
    `clear(id)`. `invoke(id, action)` calls `source.invoke`, then marks the entry
    seen and, if it is the popup, sets `popup` to null; the entry stays (resident
    notifications are not special-cased).
*   **Internal posts**: `function post(summary, body, urgency)` builds the full
    entry (fields listed in item 9, `id` from the negative counter, `time` now)
    and calls `ingest`, so rules, DND, popup and sound policy are the same as
    for D-Bus entries (a critical failure still obeys DND).
*   **Other rules**: D-Bus ids are kept; internal entries take ids counting down
    from -1; `invoke` on an internal entry is a no-op, `closed` never applies to
    them and `clear*` never calls `source.dismiss` for them. `markAllSeen()`
    runs when the drawer opens.

#### 4. Rules through component settings (Create / Modify)

*   **Type / Scope**: Rules stored as a component settings file. The rules file
    is user-edited QML loaded by `QmlSettingsFile`'s `Loader`, the same way as
    every other component settings file; the user's own code runs in the shell
    as it does for those files.
*   **Files**:
    *   Create `shell/modules/notifications/NotifMatch.js`: starts with
        `.pragma library`; one function `match(rule, entry)` returning true or
        false, no QML imports.
    *   Create `shell/modules/notifications/NotifRules.qml` (`QtObject`):
        `required property var file` (a `QmlSettingsFile { component:
        "notifications"; scope: "default"; outputName: "" }` created in
        `shell.qml`, so the module never imports adapters); `readonly property var
        rules: file.values.rules || []`; `readonly property string error:
        file.error`; `function match(entry)` loops `rules`, calls `Matcher.match(rule,
        entry)` (`import "NotifMatch.js" as Matcher`) and returns the first
        matching rule or null. It has no `refresh()`.
    *   Modify `shell/config/ComponentSpec.qml`: add `notifications: [ { key:
        "rules", kind: "rules", fallback: [] } ]` and a `rules` branch in `valid`, placed before the integer fallback at the
        end of the function: `if (option.kind === "rules") return
        ComponentSpec.validRules(value)`, where `validRules(value)` returns an
        empty string when valid, else the first problem as text (for
        example `rule 2: unknown key "colour"`); `valid` returns
        `validRules(value) === ""`. In `QmlSettingsFile.accept` (today: `options.every(...)` then
        `finish(qsTr("Invalid QML settings values: %1").arg(path))`), find the first
        option that fails with `options.find(...)`; when its kind is `rules`,
        compute `why = ComponentSpec.validRules(item[option.key])` and call
        `finish(qsTr("Invalid QML settings values: %1 (%2)").arg(path).arg(why))`;
        other kinds keep the current message. A missing `rules` property is valid
        and gives `[]`. Nothing iterates `ComponentSpec.components` to list all
        components (`ComponentSettingsEditor.qml:21`, `ComponentSettings.qml:31` and
        `QmlSettingsFile.qml:51` look up one component by name; checked with `rg
        "components\[" shell` in round 8), so the new entry adds no editor row.
    *   Modify `scripts/component-settings-path`: add `notifications` to the
        component whitelist on line 8, and extend line 9 so `notifications` is
        refused for scope `output` (as `controls` is). `read-component-settings` needs no change (it calls the
        resolver). `save-component-settings` needs no change: rules are never
        written by the shell.
    *   Create `tests/tst_NotifRules.qml` (matcher and validator cases) and extend
        `tests/scripts/check-component-settings` for the new component name.
*   **Rule semantics**: every set field must match (AND); unset fields are
    ignored; `app` and `appId` compare exactly; `match` is a string compiled with
    `new RegExp(value, "i")` and tested on summary and body (a rule with an
    empty string in a field is invalid only for `name`; an empty `app`, `appId`
    or `match` counts as unset); a rule with none of `app`, `appId`, `match` set never matches (even with
    `mute` or `hide`); `app` compares `entry.appName`, `appId` compares
    `entry.appId`; `match` is tested on `summary + "\n" + body`; an empty `sound`
    is unset; `name` may repeat (the first match still wins);
    `sound` is an absolute path to a sound file used instead of
    `soundFile` for that entry (precedence is in item 3); `mute` and `hide` may both be set and `hide` wins for the popup; first match
    wins.
*   **Validation (`valid` for kind `rules`)**:
    *   the value is an array;
    *   each item is an object with only the keys `name`, `app`, `appId`,
        `match`, `mute`, `hide`, `sound`;
    *   `name` is required and a non-empty string; `app`, `appId`, `match`, `sound` are strings;
    *   `sound`, when set, is an absolute path ending in `.wav`, `.ogg` or `.oga`
        (relative paths are rejected);
    *   `mute` and `hide` are booleans;
    *   `match` compiles with `new RegExp(value, "i")`.
    `validRules` returns one of these exact strings (the first problem):
    `rules is not an array`, `rule N is not an object`, `rule N: unknown key
    "K"`, `rule N: name is required`, `rule N: K must be a string`, `rule N: K
    must be true or false`, `rule N: sound must be an absolute .wav, .ogg or .oga
    path`, `rule N: match is not a valid regular expression` (N counts from 1).
    `ComponentSpec.valid` returns true for `undefined`, so a file without
    `rules` is valid.
    An invalid file keeps the last good `values` (already how `QmlSettingsFile`
    works), and its `error` text shows in the drawer header for as long as it
    is non-empty (a refresh that gives the same text changes nothing on screen). A missing file means
    no rules.
*   **Refresh**: `QmlSettingsFile` refreshes itself when it completes loading
    (start). The single other owner is `shell.qml`: a `Connections` on
    `NotifState` calls `file.refresh()` whenever `open` becomes true; a saved edit applies at the next drawer open. There is no file watcher.
*   **Location**: `<components dir>/notifications/Default.qml`, from
    `component-settings-path`. The file has one property, `property var rules: [
    { name: "...", app: "...", mute: true } ]`.

#### 5. `shell/modules/notifications/NotifState.qml`, `NotifSurface.qml`, `NotifDrawer.qml` (Create)

*   **Type / Scope**: Drawer open state, one layer-shell surface per screen, and
    the panel content.
*   **Proposed Changes**:
    *   `NotifState` (singleton): `open` (bool), `screenName` (string);
        `show(screen)`, `toggle(screen)`; joins the `PanelGroup` in `shell.qml`
        so opening it closes the other panels.
    *   `NotifSurface` (one per screen from a `Variants` over
        `Quickshell.screens`) is visible when `NotifState.open` and
        `NotifState.screenName === modelData.name`. `NotifShortcut` sets
        `screenName` from `Hyprland.focusedMonitor.name` when it toggles. The
        surface covers the screen with a dim `Rectangle` (`backdropOpacity`)
        and a `MouseArea` that closes the drawer; the drawer sits on the right
        edge at `drawerWidth`. Keyboard focus is `Exclusive` while visible; the
        window-wide Escape `Shortcut` closes it.
    *   `NotifDrawer`: header (title with unread count and DND state, DND
        button, Clear all, rules `error`), an empty-state label, and a `ListView`
        over a `ScriptModel` keyed by `id` whose input is `entries` stably sorted by
        app (groups ordered by the newest entry in each, entries newest first inside
        a group), with `section.property: "appName"`,
        a "Clear group" button per section, `cacheBuffer: 0`, `reuseItems: true`,
        and `NotifCard` delegates. `markAllSeen()` runs on open; an entry arriving
        while open is stored as seen by `ingest` (item 3).
    *   Focus: on open the drawer root takes focus and `ListView.currentIndex`
        is 0 (newest). Section headers are not focusable; Up and Down move over
        entries only and cross sections. Keys while the drawer is open:

        | Key | Effect |
        | --- | --- |
        | Up, Down | move `currentIndex` |
        | Enter | run the first action of the current entry (nothing if none) |
        | 1 to 9 | run the nth action of the current entry |
        | Delete | clear the current entry |
        | Shift+Delete | clear the group of the current entry |
        | Ctrl+Shift+Delete | clear all |
        | D | toggle DND |
        | Escape | close the drawer |
        | Tab, Shift+Tab | cycle the header buttons (DND, Clear all) and the list |

        After a clear, `currentIndex` stays at the same position (or the last
        entry); with no entries focus stays on the root and the empty-state label
        shows. These keys exist only while the drawer is open (handled by its
        `Keys` on the focused root, no global shortcut), so they cannot collide
        with compositor binds. "Group of the current entry" is `clearGroup(entry.appName)`.

#### 6. `shell/modules/notifications/NotifCard.qml` (Create)

*   **Type / Scope**: Shared card content for popup and drawer.
*   **Layout contract**: a `ColumnLayout` using the `style` object passed in
    (`spacingTight`, `text`, `textMuted`, `surfaceVariant`, `accent`, as the
    existing card does). Rows: app name (muted) with the "rule: X" tag appended;
    summary (bold, at most 2 lines, elided); body (plain text, at most 4 lines,
    elided); a 4 px progress bar when `progress >= 0`; relative time (`now`,
    `N min ago`, `N h ago`, or a date after 24 h) at the bottom right; an action
    row when `showActions` is true. A `closed` entry shows the text "closed" in
    the muted colour and disables its action buttons. Critical urgency draws the
    app name in the `style` accent colour. The icon comes from `entry.image` if
    non-empty, else `entry.icon` resolved as an icon name or file path, else no
    icon (the row has no placeholder).
*   **Redaction**: when `NotifCenter.redact` is true, summary and body are not
    created: the card shows one `NotifSpoiler` of one line height in place of the
    summary and one of two line heights in place of the body, both the full card
    width, where a line height is `FontMetrics.height` of the card font. The size
    does not depend on the real text, so no text length leaks and no hidden
    `Text` is needed. The action row is not created. Popups already on screen when
    recording starts or stops switch at once because the card binds to `redact`.

#### 7. `shell/modules/notifications/NotifSpoiler.qml` and `shell/modules/notifications/shaders/{spoiler.frag,spoiler.frag.qsb,spoiler.frag.sha256}` (Create) [P6]

*   **Type / Scope**: `ShaderEffect` that fills a rectangle with moving noise.
*   **Properties** (all declared on `NotifSpoiler`, passed to the shader as
    uniforms): `time` (float, seconds, from a `NumberAnimation` on a `real`
    that loops only while the item is visible, speed `Config.Notifications.spoilerSpeed`),
    `tint` (vec4, `Theme` text colour at 0.35 alpha), `ratio` (float, `width /
    height`). Fallback: the effect is `visible` only when `status !==
    ShaderEffect.Error`; a sibling `Rectangle` of colour `tint` is shown when it
    is, so redaction still hides the area.
*   **Shader** (`spoiler.frag`, `#version 440`): `layout(std140, binding = 0)
    uniform buf { mat4 qt_Matrix; float qt_Opacity; float time; float ratio; vec4
    tint; };` with `layout(location = 0) in vec2 qt_TexCoord0` and `layout(location
    = 0) out vec4 fragColor`. `hash(vec2 p)` is `fract(sin(dot(p, vec2(127.1,
    311.7))) * 43758.5453)`; value noise `n` bilinearly interpolates `hash` over
    the integer grid of `uv = qt_TexCoord0 * vec2(ratio, 1.0) * 12.0 + time *
    vec2(0.6, 0.3)`. Output `tint * smoothstep(0.35, 0.65, n) * qt_Opacity`
    (premultiplied alpha).
*   **Build**: `make dev-shaders` (a new `.PHONY` target in `tools/development.mk`,
    also listed in `dev-help`; edit the `.PHONY` line 16 and the `dev-help` text at line 18) fails with the message `qsb not found: install qt6-shadertools` if `qsb` is missing,
    otherwise runs `qsb --qt6 --glsl "100es,120,150" --hlsl 50 --msl 12 -o
    spoiler.frag.qsb spoiler.frag` run inside `shell/modules/notifications/shaders/`, and writes
    `spoiler.frag.sha256` as the bare hex hash from `sha256sum spoiler.frag | cut
    -d" " -f1`. Both outputs are committed so a normal run needs no build
    tool. `NotifSpoiler` loads the `.qsb` through
    `Qt.resolvedUrl("shaders/spoiler.frag.qsb")`.
*   **Stale check** (the only rule; item 19 refers here): `tests/scripts/check-qml`
    fails when `cat spoiler.frag.sha256` differs from `sha256sum spoiler.frag | cut -d" " -f1`
    (no hash logic exists in `check-qml` today; add this one step). A
    `.qsb` built by another Qt version is accepted; the hash is the contract.
*   **Test**: `tst_NotifCard` covers the fallback by loading the spoiler with a
    missing `.qsb` URL (the `shaderSource` property is overridable).

#### 8. `shell/modules/notifications/NotifPopupSurface.qml` (Create)

*   **Type / Scope**: One layer-shell window per screen, namespace
    `ui-shell-notif`, `WlrLayer.Top`, `keyboardFocus: None`.
*   **Proposed Changes**: Shows `NotifCenter.popup` only when
    `Hyprland.focusedMonitor.name === modelData.name`, from a `Variants` over
    `Quickshell.screens` in `shell.qml`. It ignores `NotifState.open` (a popup
    can show while the drawer is open). Anchored top and right of the screen
    with margin `popupMargin`, width `popupWidth`, height from the card. When
    `Hyprland.focusedMonitor` is null no screen shows a popup. `shell.qml`
    owns the loading state (the surface cannot, since it does not exist while
    inactive). `LazyLoader` is new to this repo (the auth surface is declared
    directly at `shell.qml:65`; the only other lazy pattern is `Loader`): import
    `Quickshell`, declare `LazyLoader { activeAsync: NotifCenter.popup !== null
    || popupExiting }`. `shell.qml` holds `property bool popupExiting` and
    `property var popupLast`; a `Connections` on `NotifCenter` (`onPopupChanged`)
    sets `popupLast` to the new popup when it is non-null, and when it becomes
    null sets `popupExiting = true` and starts a `popupOutDuration` `Timer` that
    clears it. The surface takes `required property var entry` bound to
    `popupLast`, so the card stays alive for the exit animation. The input
    region (`Region`) covers the card only; hover sets `popupHovered`. Enter and
    exit use `Theme.Motion` (scale and fade), and layer rules do not animate it
    (`no_anim`, item 16). The popup has no backdrop.

#### 9. `shell/modules/notifications/NotifShortcut.qml` [P2], `NotifFeeds.qml` [P5] (Create)

*   **Type / Scope**: Global shortcuts and the internal poster.
*   **Proposed Changes**:
    *   `NotifShortcut`: three `GlobalShortcut`s: `notifications` (toggle drawer
        on the focused monitor), `notifications-dnd` (toggle DND),
        and `notifications-dismiss` (dismiss popup). Clearing has no
        global shortcut: it lives in the drawer's own keys (item 5). The component
        takes `required property var center` (set in `shell.qml` to `NotifCenter`)
        and `required property var state` (`NotifState`). Calls: `notifications`
        sets `state.screenName` from `Hyprland.focusedMonitor.name` (nothing if
        null) then `state.toggle(name)`; `notifications-dnd` calls
        `center.setDnd(!center.dnd)`; `notifications-dismiss` calls
        `center.dismissPopup()`.
    *   `NotifFeeds`: properties `center`, `shotRunner` and `recordState` (type `var`), set
        in `shell.qml`, so the module imports no adapters. Two `Connections`
        blocks (a `var` property cannot take `on<Signal>` handlers directly):
        `shotRunner.captured(result)` posts summary "Screenshot saved", body
        `result.file`, urgency normal; `shotRunner.failed(failure)` and
        `recordState.failed(failure)` post summary `failure.title`, body
        `failure.message`, urgency critical; `recordState.lastResultChanged` posts
        "Recording saved" with body `lastResult.output` when `lastResult` is
        non-null and its `id` differs from private `lastRecordId`, which starts as
        the id of the `lastResult` at load.
    *   Fields of every internal entry: `origin: "internal"`, `appName`
        "ui-shell", `appId` "ui-shell", `icon` "", `image` "", `actions` [],
        `progress` -1, `expireTimeout` 0, `generation` false; `id` from the
        center's negative counter.
    *   Notes: the panels' own status text stays, so a duplicate is accepted.
        `ShotRunner.buffered` is not posted. `ErrorPopup` stays modal for errors
        that block the user. `RecordState.qml` is unchanged.

#### 10. `shell/modules/notifications/qmldir`, `EGM.md` (Create)

*   **Type / Scope**: Module registration and contract (interface, invariants,
    side effects: popups never take focus, no rule removes an entry, DND is
    manual, redaction is derived from one binding).
*   **Proposed Changes**: Register every module type: `NotifCenter`, `NotifState`,
    `NotifCard`, `NotifDrawer`, `NotifSurface`, `NotifShortcut`,
    `NotifPopupSurface`, and later `NotifRules`, `NotifSound`, `NotifFeeds`,
    `NotifSpoiler`.

#### 11. `shell/config/Notifications.qml`, `Config.qml`, `qmldir`, `EGM.md` (Create / Modify)

*   **Type / Scope**: Behaviour constants and the enable flag.
*   **Proposed Changes**: `Notifications` singleton, each property once:
    `enabled` true; timeouts `lowTimeoutMs` 2500, `normalTimeoutMs` 4000,
    `criticalTimeoutMs` 8000, `maxTimeoutMs` 15000; `soundEnabled` false,
    `soundFile` "", `popupNamespace` `ui-shell-notif`,
    `popupWidth` 360, `popupMargin` 16 (top-right corner of the focused monitor); `drawerWidth` 400,
    `backdropOpacity` 0.4, `drawerNamespace` `ui-shell-notif-drawer`; shortcut
    ids `notifications`, `notifications-dnd`, `notifications-dismiss`; and
    `spoilerSpeed` 1.0 [P6]. `Config.notificationsEnabled` is a readonly
    property set from `Notifications.enabled`. Update the interface list in
    `config/EGM.md`.

#### 12. `shell/modules/bar/NotifChip.qml`, `Bar.qml`, `EGM.md` (Create / Modify)

*   **Type / Scope**: Bar indicator.
*   **Proposed Changes**: Bell icon (`notifications` theme icon; `notifications-disabled` for DND) at the bar icon size, with the unread count capped at "9+"; a different icon for
    DND; click toggles the drawer. Shown only when `notificationsEnabled`. Placed in `Bar.qml` just before
    `AuthChip`, reading `unread` and `dnd` from `NotifCenter` only.

#### 13. `shell/shell.qml` and `shell/EGM.md` (Modify)

*   **Type / Scope**: Composition.
*   **Proposed Changes**: Per part: [P2] set
    `Notif.NotifCenter.source = Adapters.NotifSource`; load `NotifShortcut`; add
    `Variants` for the popup and drawer surfaces; add `Notif.NotifState` to the
    existing `PanelGroup` (a modification of its member list, not of
    `PanelGroup.qml`); bind `NotifCenter.drawerOpen` to `NotifState.open`. [P3]
    create the `QmlSettingsFile` and `NotifRules` instance, set
    `NotifCenter.rules`, and call `file.refresh()` on `NotifState.open`. [P5]
    load `NotifFeeds` with `shotRunner` and `recordState`; bind
    `NotifCenter.fullscreen` as below. [P6] bind `NotifCenter.redact` to `Adapters.RecordState.active`; the fullscreen binding is `Hyprland.focusedMonitor.activeWorkspace.hasFullscreen`
    (`HyprlandWorkspace.hasFullscreen`, present in the installed Quickshell
    qmltypes at `Quickshell/Hyprland/_Ipc`; `false` when either object is null; the
    binding lives in `shell.qml` so the center stays free of Hyprland imports).

#### 14. `shell/theme/Motion.qml` (Modify)

*   **Type / Scope**: Popup motion.
*   **Proposed Changes**: Add `popupInDuration` 180 ms and `popupOutDuration` 120 ms,
    and update `shell/theme/EGM.md`. The spoiler needs no Motion entry
    (`Notifications.spoilerSpeed` controls it).

#### 15. `scripts/notify-sound`, `shell/modules/notifications/NotifSound.qml`, `tools/config.ini`, `scripts/read-shell-config`, `scripts/render-runtime-config` (Create / Modify)

*   **Type / Scope**: Bash helper. Takes one absolute sound file, validates it,
    runs `pw-play` through an argument array, one instance at a time with a
    cooldown, one error line when `pw-play` is missing. Contract: exit 0 on
    played or skipped by cooldown (500 ms); exit 2 when the file argument is missing,
    not an absolute path, not a readable regular file, or not `.wav`, `.ogg` or
    `.oga`; exit 3 and print `notify-sound: pw-play not found` when `pw-play` is
    missing. Create `scripts/notify-sound` (mode 0755; checked into git with the exec bit). The role is `notifySound`
    (`[commands]` keys are camelCase). Modify `tools/config.ini` (`notifySound =
    scripts/notify-sound`), `scripts/read-shell-config` (add
    `{k:"notifySound",s:"notify-sound"}` to the default list and `"notifySound"`
    to the `exact([...])` key list) and `scripts/render-runtime-config` (mirror the key list), and
    `tests/scripts/check-runtime-config` and `tests/scripts/check-defaults`
    when they list roles (add `notifySound`). `NotifSound.qml` (`QtObject` in the module, imports `Quickshell.Io` only) has `required property string command` and `function play(path)` that starts a `Process` with `command: [root.command, path]`; its `onExited` logs the code through `console.warn` when non-zero. [P4] `shell.qml` creates `Notif.NotifSound { id: sound; command: GeneratedRuntime.commands.notifySound }` and a `Connections { target: Notif.NotifCenter; function onSoundRequested(path) { sound.play(path) } }`. QML starts it through
    `GeneratedRuntime.commands.notifySound` with `Process` and an argv array.
    `Config.Notifications.soundFile` must already be absolute (a relative one is
    skipped, item 3). The script exits non-zero on bad input; `NotifSound` logs
    `console.warn("notify-sound exit " + code)` and does nothing else.

#### 16. `hypr/profile.lua`, `hypr/binds/shell.lua`, `hypr/rules.lua`, `tests/scripts/check-hypr-config` (Modify)

*   **Type / Scope**: Hyprland policy.
*   **End state**: `hypr/profile.lua` `shell_shortcuts` has three notification
    entries with targets `ui-shell:notifications`, `ui-shell:notifications-dnd`
    and `ui-shell:notifications-dismiss`. Production keys: `action_mod`
    (SUPER+SHIFT) with B, D and BACKSPACE (free: `layout_mod` is SUPER there).
    The nested profile (`hypr/user/nested.lua`, where `action_mod` equals
    `layout_mod` and B is `layout_cycle_key`) collides on B and D, so it
    overrides the drawer and DND chords with `shifted + F6` and `shifted + F7`
    (F6 and F7 are unused in `hypr/`); BACKSPACE stays. If the profile merge does
    not accept a nested `shell_shortcuts` override, add fields
    `notifications_key` and `notifications_dnd_key` read by `hypr/binds/shell.lua`
    (as `layout_cycle_key` is). `hypr/binds/shell.lua` binds them with
    `profile.action_mod`. `hypr/rules.lua` adds `notif|notif-drawer` (namespaces
    `ui-shell-notif`, `ui-shell-notif-drawer`) to the existing `no_anim`
    pattern string. The `grimblast --notify` line stays: it is an ordinary D-Bus
    sender.
*   **Checks**: `tests/scripts/check-hypr-config` asserts that every
    `shell_shortcuts` target has a bind and, for the production and the nested profile separately, that no two binds
    share a key chord (every new chord is checked, not only D).

#### 17. `tests/notifications/shell.qml` (Create) [P7]

*   **Type / Scope**: Nested-session test in the style of `tests/launcher/`. It
    uses the real `NotifSource` and real D-Bus, so it needs no fake source.
*   **Mechanisms**:
    *   The test shell sets `NotifCenter.source = Adapters.NotifSource`, loads
        `NotifSurface`, `NotifPopupSurface` and `NotifShortcut`, and prints
        log lines `notif-test: popups=N unread=N delegates=N open_ms=N` that
        `tests/scripts/run-session` greps. Binds come from the nested Hyprland
        config.
    *   Open time: from the `NotifState.toggle()` call to the first
        `ListView` delegate `Component.onCompleted` plus `Qt.callLater`. This
        measures the model and layout, not the GPU frame; the test fails above
        400 ms (provisional; a change goes into the brain page with the new
        measurement).
    *   Delegates: `ListView.contentItem.children.length` is counted and must stay
        under 60 with 2000 entries (the visible rows plus a margin; `cacheBuffer:
        0`, `reuseItems: true`, `ScriptModel` keyed by `id`, item 5).
    *   Focus: popups are layer surfaces, not windows. The check compares
        `hyprctl activewindow -j` address before and after a popup, and
        `hyprctl layers -j` must list the namespace `ui-shell-notif`.
    *   Keys: `hyprctl dispatch global ui-shell:notifications` (and `-dnd`,
        `-dismiss`) for the shortcuts; the in-drawer keys by `wtype`; Escape through
        `wtype -k Escape` (a new tool check in `run-session`, which fails with a
        clear message if `wtype` is missing).
*   **Sends**: `notify-send` for every urgency, a 100-notification burst, a
    progress update (`-h int:value:40`) and a `replaces_id` update (`-r`).
*   **Asserts**: one popup at a time; the active window address is unchanged
    after a popup; unread count; DND; hover pause (the test shell sets
    `popupHovered` directly); the update arrives for the same entry without a
    new entry; redaction on and off.

#### 18. `tests/tst_NotifCenter.qml`, `tests/tst_NotifRules.qml`, `tests/tst_NotifCard.qml`, `tests/notifications/FakeSource.qml` (Create)

*   **Type / Scope**: qmltestrunner unit tests with a fake source.
*   **Proposed Changes**: `tests/notifications/FakeSource.qml` (create; the repo
    keeps fakes per feature, like `tests/mpris/FakeSource.qml`) has the same
    surface as `NotifSource`: signals `received(var entry)`, `updated(var
    entry)`, `closed(int id)`, and functions `invoke(id, identifier)` and
    `dismiss(id)` that record their calls in `calls`. [P1]
    `tst_NotifCenter` (ordering, update in place and its popup and timer reset,
    timeouts, DND, fullscreen, internal ids, seen and clear, the flag table
    for `hidden`, `muted` and `suppressed`, the dedupe cases, keyboard clear
    functions; exists in part). [P3] `tst_NotifRules` (matcher, validator, a bad
    file keeps the last good set; no DND or popup logic). [P6] `tst_NotifCard`
    (a redacted card has no `Text` with the summary or body and no action row;
    the spoiler fallback).

#### 19. Test wiring (Create / Modify)

*   **Type / Scope**: Script checks, nested-session modes, suite lists, targets.
*   **Proposed Changes** (each file; phase in brackets):
    *   Create `tests/scripts/check-notifications` [P3]: first the settings
        path for the `notifications` component (accepted for scope `default`,
        refused for `output`); from P4 also `notify-sound` with a fake
        `pw-play` (exit 0 played, 0 on cooldown, 2 bad file, 3 missing
        `pw-play`).
    *   Modify `tests/scripts/check-qml` [P3 for `tst_NotifRules`, P6
        for `tst_NotifCard`]: add the suites. The stale-shader check is the hash rule of item 7.
    *   Modify `tests/scripts/nested-session` [P7]: add `notifications` to
        the mode whitelist (line 56) and the error text (line 61).
    *   Modify `tests/scripts/run-session` [P7]: add `notifications` to the
        accepted-mode check (line 73) and a branch like the `launcher` one
        (lines 20-23, 45) that copies `tests/notifications/shell.qml` to the
        shell directory and kills it on cleanup; fail on `ERROR|WARN.*qml` in the
        shell log; require `notify-send`.
    *   Modify `tests/targets.mk` [P3]: add `test-notifications` to `.PHONY`
        and `test-help`, and to the `test` aggregate; the recipe runs
        `check-notifications`, and from P7 `@bash "$(TEST_RUNNER)"
        notifications ephemeral`.
    *   Modify `tests/README.md` [P3]: describe the target.

#### 20. `CONFIGURATION.md`, `FEATURES.md`, `STYLE.md`, `README.md` (Modify)

*   **Type / Scope**: Docs.
*   **Proposed Changes**: `CONFIGURATION.md`: document the rules file as a hand-written QML
    component file, with an example to copy, with its location and the rule "a rule never removes
    an entry". `FEATURES.md:20-22`: once the feature ships, mark done and drop the
    hypridle part (DND is manual only). `STYLE.md`: add a "Popups and focus" paragraph under the layer-shell section, and a note at line 263 that the `notifications` component has one option (`rules`) with no Ctrl+E editor row and a hand-written file. `shell/config/EGM.md` (lines 10 and 19: the `ComponentSpec` option kinds and the `notifications` entry) and `shell/adapters/EGM.md` (line 17: `QmlSettingsFile` error text) are updated for the new kind.
    Root `README.md`: module list. `shell/modules/EGM.md`, `shell/adapters/EGM.md`
    and `shell/theme/EGM.md` are updated for the new module, `NotifSource` and the
    Motion entries.

#### 21. Brain (CLI only)

*   **Type / Scope**: `brain update-truth` records a settled fact and `brain append-timeline`
    records a decision change or reversal on `notification-center`, when a decision
    in this plan changes during implementation (no file change).

### Verification Plan

*   **Compilation/Build**: `make dev-shaders` succeeds; `make test-notifications` runs
    `check-notifications` [P3] and, from [P7], the nested session, which fails
    on a log line matching `ERROR|WARN.*qml`.
*   **Unit Tests**: `make test-qml` (new `tst_Notif*.qml` plus lint).
*   **Static Analysis & Linting**: the existing qmllint run inside `make test-qml`;
    `shellcheck` on `scripts/notify-sound`; the check prints "skipped:
    shellcheck missing" when absent.
*   **CUJ to test**:

    | Journey | Covered by |
    | --- | --- |
    | Notification arrives, shows once, times out | `tst_NotifCenter` (ordering, timeouts) |
    | Burst keeps one popup, newest wins | `tst_NotifCenter`; [P7] nested burst |
    | Progress / `replaces_id` update in place | `tst_NotifCenter` (update case); [P7] nested `-r` send |
    | DND, fullscreen, mute, hide matrix | `tst_NotifCenter` (flag table); `tst_NotifRules` (matcher only) |
    | Drawer open, seen, clear, large list | `tst_NotifCenter`, nested 2000-entry run |
    | Redaction hides text | `tst_NotifCard`; host check: the pattern covers the text during a recording |
    | Sound script contract and cooldown | `check-notifications` |
    | Keyboard: drawer, DND, dismiss, clear, Escape, in-drawer keys | `tst_NotifCenter` (functions); [P7] nested run (three globals via `hyprctl dispatch global`, drawer keys and Escape via `wtype`); host check (key table of item 5) |
    | Reload keeps the list, re-emitted entry ignored | `tst_NotifCenter` (generation case) |
    | Regexp edge cases (invalid, empty, case) | `tst_NotifRules` |
    | Rule error shown in the drawer header | `tst_NotifRules` (error text), owner host check (header text) |

*   **Test Coverage Requirement**: every row of the mute / hide / DND matrix has an automated
    test; each CUJ in the table has the test or host check named in its row.
*   **E2E/Integration**: `make test-notifications` (script check) and a nested
    run that sends real D-Bus notifications with `notify-send`; then a live
    check on the host, run by the owner (not automated): popup corner, drawer,
    spoiler during a real recording, and sound. Pass criteria: the popup
    appears in the top-right of the focused monitor; Escape and a backdrop click
    close the drawer and the previous window regains focus; with a recording
    running the message text is covered by the moving pattern and returns after
    stop; the configured sound plays once per notification and not during DND; the
    drawer keys of item 5 behave as in the table; a bad rules file shows its error
    text in the drawer header; hidden entries show "N hidden by rules".

--------------------------------------------------------------------------------

*Drafted with EGM*
