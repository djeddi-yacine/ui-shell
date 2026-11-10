# Notifications

* **Author:** djeddi-yacine
* **Date:** 2026-11-09
* **Status:** brainstorm brief, draft 1. All seven review lenses are in (design, codebase details, zoom-out, comprehension, implementation readiness, structural, inventive catalyst). None was `not run`.

Input: `features/studies/notifications.md`. This file records what we need from it. Several reviewers worked from the study and the concept text only and did not read all of the code; claims marked "to verify" are unproven.

## Overview

The shell becomes the only notification daemon. It claims the D-Bus name through the Quickshell `NotificationServer`, and dunst goes away, along with its separate process and its own config. New notifications appear as popups. A side drawer holds the history of the current session. History is kept in memory only: it is cleared when the shell restarts, and a shell crash drops notifications. That loss is accepted.

Popups time out by urgency and pause while the pointer is over them. Notifications group by app, can carry actions, and can show a progress bar (from the `value` hint). A badge in the bar shows the count. Do-not-disturb (DND) is a manual switch only: nothing turns it on or off by itself.

A plain text rules file matches an app id or a regular expression and can mute, hide, or play a sound. It is not a rule language. Sounds are optional, off by default, played by a small script that calls `pw-play`, and a rule can override the default. While a screen recording runs, popups still show but the message text is blurred with a smooth blur, as in Telegram, and is revealed after the recording stops.

The shell's own modules (screenshot, recording, polkit) post through an internal in-process path, not D-Bus. Popups never take keyboard focus and must not break keyboard shortcuts.

Today no module in `shell/` uses `notify-send`, dunst or a `NotificationServer`. Every module reports failures through the modal `ErrorPopup`, which is not a toast. So there is no old notification code to migrate inside the shell. The one outside caller found is `hypr/profile.lua:49-50` (`grimblast --notify`), which will become an ordinary D-Bus sender.

## Analysis

The lenses agree on the following, from most to least serious.

1. **Visible popups, no focus theft, and keyboard actions pull against each other.** Popups use a layer-shell surface with keyboard focus `None`, as the auth scrim does (`modules/auth/AuthSurface.qml:35`); the other surfaces take `Exclusive` focus only while visible. Keyboard control then goes through global shortcuts (the existing `GlobalShortcut` pattern in `modules/*/Shortcut.qml`): dismiss the newest, invoke its default action, dismiss all, open the drawer. Hover-pause has no keyboard twin, so a shortcut should pause timers too. The drawer is opened by the user and may take focus on demand, with Esc to close. Notifications can arrive while record or shot hold exclusive focus; popups must still never take it. The popup input area covers the cards only.
2. **Another daemon already owning the bus name is the main operational hazard.** If dunst or mako runs, the claim may fail without a visible sign. How Quickshell behaves here is unverified. Needed: a startup check and a visible state (such as `serverActive`) shown on the bar chip and in the log. The cutover (stop and disable dunst, leave its config alone) and the way back (re-enable dunst) are written down. `tests/scripts/host-session` already knows two shells fight over this name.
3. **Rules and "hide" collide with the owner's ban on hidden control flow.** Proposed resolution: a rule changes presentation, never existence. A hidden or muted notification still lands in the drawer with a visible "rule: X" tag, and the badge shows a "suppressed N" count. Polkit prompts are never muted or hidden. The comprehension lens notes that mute, hide and DND are undefined; section Key Decisions fixes a table.
4. **Blur is weaker than it sounds.** It is a visual layer over text that still exists. It must be derived from one binding (`RecordState.active`, already a singleton) and applied when the popup is created, so a popup that appears in the first moment of recording is not clear. The scope must cover popups, the drawer, and any tooltip or label that repeats the text. Blur on small text can stay legible; a placeholder may be safer. Revealing after stop must handle popups still on screen. Whether a layer-shell popup is captured by the recorder at all is unverified (the polkit brief records the same doubt about `no_screen_share`). The notification module must not import the recorder; a binding sets a `redact` flag.
5. **Resources need caps.** In-session history has no natural limit. A looping sender would grow history and slow the drawer. Needed: a history cap with oldest-out eviction, a maximum visible popup count with a queue, a rate limit, a bounded image size, and in-place updates for `replaces_id` and progress.
6. **The rules file is the largest scope risk and a frozen public contract.** The zoom-out lens calls it the biggest over-engineering risk. If kept: location and format chosen before the first release, a version marker, first match wins, an invalid line or regexp keeps the last good set and reports one actionable error, a missing file means no rules. `appName` is sender-chosen, so rules are convenience, not security.
7. **The sound script needs a firm contract.** Arguments are an argv array, never a shell string. Concurrency limit of one, a cooldown, and a clear message if `pw-play` is missing. "Default off" is global; a rule can turn it on.
8. **The internal path must be the same entry as the D-Bus path.** One ingest function with an origin tag (`dbus` or `internal`), so internal posts look identical and shared policy applies, while stating which origins are exempt from DND and rules. Existing signals (`ShotRunner.captured/failed`, `RecordState.failed`) can feed it without the modules importing the notification module. One error channel should be chosen between this path and `ErrorPopup`; migration is gradual.
9. **Structure follows the repo's source, logic, UI split.** A `NotifSource` adapter singleton is the only importer of `Quickshell.Services.Notifications` (like `PolkitSource`). A logic-only `NotifCenter` on an injected source owns the model, rules, DND, timeouts, history and unread count, so tests can use fakes. The module holds shortcuts, the popup surface and the drawer. The bar badge binds only to the center. All decisions live in the center, none in UI files. Popup windows load lazily; the server itself is eager. The drawer is a panel in the panel group; popups stay outside it, as auth does.
10. **Quickshell facts to verify before the design:** what `keepOnReload` does to tracked notifications on reload (and whether a reload counts as a restart); whether `expireTimeout` 0 and -1 arrive untouched; whether the `value` and extra hints reach QML; whether text blur is feasible and what it costs; behaviour when the name is taken.

## Goals vs. Non-Goals

* **In-Scope Goals:**
  * The shell is the only notification daemon (dunst removed).
  * Popups with urgency timeouts, hover pause and progress bars, read-only (actions live in the drawer). A dedicated shortcut dismisses the popup; Escape is not used because popups take no focus.
  * A side drawer with in-session history, grouped by app, with no cap, cleared by hand.
  * A bar badge and a manual DND switch whose state is always visible.
  * A simple rules file (mute, hide, sound) with visible effects.
  * Optional sounds through a small `pw-play` script.
  * Hide message text with an animated spoiler shader (Telegram style) while a recording runs, lifted after it stops. Chosen during drafting instead of a real blur.
  * An internal in-process path for shell modules, through the same ingest as D-Bus.
  * Popups never steal focus; keyboard control by global shortcuts.
  * A test sender (`notify-send` or `gdbus` script with urgency, actions, progress) and a stress test, in the style of the launcher's.
* **Non-Goals:**
  * Inline reply (do not advertise it).
  * Lock-screen display.
  * Persistent history, across restarts or crashes.
  * Screen-sharing handling.
  * Automatic DND, or any automatic control flow.
  * A rule language.
  * A framework for other senders.

## Alternatives Weighed

* **Keep dunst, restyle it.** Rejected by the owner: separate process, separate config.
* **Persist history to disk** (caelestia, DankMaterialShell, noctalia, Ambxst do). Rejected: in-session only, crash loss accepted.
* **Rules that drop a notification.** Rejected: hidden loss. Rules only change presentation and leave a trace.
* **Rules file format.** Line text, JSON, or a QML config object. Open (see decisions).
* **Blur vs a placeholder.** Blur is the owner's choice (smooth, Telegram-style); a placeholder is the fallback if blur proves legible or costly.
* **Hiding popups from the recording instead of blurring.** A layer excluded from capture is possible, but its effect on the recorder is unproven, and the owner wants popups visible to the user.
* **Keyboard handling through focus** (popups take focus). Rejected: it steals input; global shortcuts instead.
* **Critical notifications under DND.** Either bypass (common elsewhere) or follow DND. Open.

## Key Decisions & Staging

**Decided (from the owner's concept):** shell-only daemon; in-memory history; manual DND only; rules change presentation not existence; sounds default off; no focus theft; internal path separate from D-Bus.

**Decided by the owner (brainstorm, 2026-11-09):**

- Rules are hand-written by the owner, so they are not hidden control flow; every rule effect still shows a visible "rule: X" tag.
- A shell crash or reload dropping notifications is accepted.
- Popups are read-only: no actions, no keyboard focus. Escape dismisses them. Keyboard operation belongs to the drawer.
- Recording blur covers the message text only and hides the action buttons. It is the same in-shell blur, not a layer-shell effect. Hiding the drawer during casting is a later extension, out of scope now.
- Another daemon (dunst, mako) owning the bus name is not handled: treat it as if it does not exist. No startup check, no cutover docs.
- The rules file is a hand-written QML file (chosen during drafting, with a documented exception to the INI convention).


**Terms to fix in the design (comprehension lens):**

| Term | Popup | Drawer history | Badge | Sound |
| --- | --- | --- | --- | --- |
| mute (proposed) | shown | kept | counted | none |
| hide (proposed) | not shown | kept, tagged | counted as suppressed | none |
| DND (proposed) | not shown | kept | counted | none |

**Open for the owner:**

1. Layout: popup corner and drawer edge (the study shows top-right as common), which monitor shows popups, behaviour under fullscreen, and whether `Placement.qml` modes apply.
2. Do critical notifications bypass DND? Do they ever expire (DankMaterialShell: never)?
3. Timeout values per urgency, the maximum visible count, and the history cap.
4. Rules file location and format, and whether to ship rules in stage one.
5. What the badge counts (unread or total) and how it shows DND.
6. Whether a DND flag survives a restart (proposed: no).
7. Blur scope: body only, or title, icon and image as well, and whether hovering reveals it.
8. Whether a hot reload of the shell counts as a restart (`keepOnReload`).

**Proposed stages (each shippable):**

1. `NotifSource`, `NotifCenter`, one popup list, urgency timeouts, bus-name check, test sender. Tests with fakes.
2. Popup behaviour: hover pause, actions, progress, critical handling, dismissal, keyboard shortcuts.
3. Drawer, grouping, history cap, bar badge.
4. Manual DND, then the rules file.
5. Sound script.
6. Internal posting; migrate record and shot results; decide the `ErrorPopup` boundary.
7. Recording blur.

Each new directory gets an `EGM.md`; `adapters/EGM.md` and `modules/EGM.md` are updated. A hyprland layer rule for the popup namespace is a separate rule, added to the `no_anim` pattern in `hypr/rules.lua` only if needed. Each stage's decisions also go to the brain through the `brain` CLI. `FEATURES.md:20-22` already lists a notification system and should be checked against this scope.

**Decided by the owner (layout and limits, 2026-11-09):**

- Popups appear at the right corner of the monitor that has focus; the drawer opens at the right edge.
- Under a fullscreen window, only the sound plays (no popup).
- Critical notifications do not bypass do-not-disturb, and they expire like any other notification.
- At most one popup is visible. On a burst, the newest replaces the one on screen.
- History has no cap and no expiry; the owner clears it by hand. (The "looping sender grows history" risk is accepted; the drawer must stay usable with a large list.)
- The bar badge counts unread notifications; do-not-disturb changes only the bar icon.
- Do-not-disturb does not survive a restart.
- A blurred message stays blurred while hovered, and the blur applies to the message everywhere it appears (popup and drawer).
- Still unset: timeout length per urgency (to be proposed in the design).


**Decided by the owner (real-host review, 2026-11-09; studied in `features/studies/notifications.md` section 8):**

- A left click on a popup dismisses it. Hover still holds the timer. No drag-swipe.
- The drawer shows one stack per app, like dots-hyprland (DH1.1-DH1.5): collapsed shows the two newest items, the second dimmed; a chevron button with the count expands it; a single-item stack has no chevron. Each stack has "clear group"; each item has its own delete button.
- Motion between items is smooth: stack height, chevron, item insert, remove and reorder are all animated (DH4.2).
- Every component has an explicit, fixed or capped size: buttons, popup and card heights, text line counts, image slot. Nothing sizes by a default.
- An image is never loaded automatically. A card with an image shows a fixed-size "Load image" placeholder button; clicking loads that one image. The choice is per notification and in memory. Popups never load images.

## Addendum: z-ordered deck (second review)

- A collapsed stack is a deck: the newest card on top, up to two layers behind it, each lower and smaller. This replaces "two newest, the second dimmed"; keyboard visits only the newest card while collapsed (`collapsedStackItems` = 1).
- Expanding fans the deck into a list with one under-damped spring (a small bounce), each card a beat after the one above; collapsing folds it back.
- Expand chevron, clear group and per-item delete are icon-only. Deleting a card or a group animates out first.
- Open: visual check on the host (`make test-env-host`, dunst stopped, then `make test-notify`).

## Addendum: spec coverage, read state, drawer timing (third review)

- Support the freedesktop Notifications spec (1.2) fully. Source: `refs/notification-spec.html` (a redirect stub; the text is at specifications.freedesktop.org/notification/latest-single/).
  - Critical never expires by itself. This reverses the earlier "expire like any other"; DND still applies. A sender timeout of 0 means never, -1 means the server's per-urgency default.
  - Body markup `<b> <i> <u> <a href> <img>`: `<img>` is shown as its alt text and never loaded; links open only http, https, mailto, file.
  - Hints: transient (popup only, not in history), resident (action keeps it), category (shown as its class), action-icons, sound-file, sound-name (freedesktop sound theme), suppress-sound. The "default" action is what a click does, not a button.
  - Capabilities advertised: body, body-markup, body-hyperlinks, actions, action-icons, icon-static, persistence.
  - Deliberate gap: a notification expiring from the popup stays open on the bus (in history) rather than sending NotificationClosed(expired).
- Read/unread is explicit: a check button (icon `check`) and the R key toggle it; Shift+R and a header button mark all read. Acting on a notification reads it. Opening the drawer does not. Unread drives the bar badge and the drawer title.
- Drawer open and close take one short time (`Motion.drawerDuration`).
- Header and stack controls are icon-only: DND, clear all, mark all read, expand, clear group, delete. Colours come only from theme tokens (urgency dot, read cards sink toward the surface, deck layers shaded toward the background, critical keeps a negative border).

## Addendum: icons as QML, pixel-exact cards, clear motion (fourth review)

- Icons are not images and not inside a button: SVG sources live in `shell/svg/`, `scripts/generate-icons` produces themable QML in `shell/icons/`, and an icon-only control is the picture itself (no box). Idle is the full text colour, hover or keyboard selection the control focus role, pressed or selected the accent.
- Do not draw a bordered card through a scale transform or at half pixels: the 1px outline shimmers while it moves. Deck layers are sized by rounded geometry.
- Clearing a stack or everything slides it out through the right edge while it fades, then closes the gap.
- The "clear group" icon is `remove` (replaces the bin).
- `make test-notify` also covers an embedded image (`image-path`, `image-data`) and the sound hints (`sound-name`, `sound-file`, `suppress-sound`), and runs faster.


## Addendum: per-rule exemption from the recording blur

- A rule may set `reveal: true`: matching notifications keep their text while a recording runs (an app whose text is safe to show). Redaction is otherwise global; there is no rule that blurs when not recording.
- A rule may match the app name by regular expression with `appMatch` (case-insensitive; `app` and `appId` stay exact, `match` stays the regexp over summary and body). All fields a rule sets must match; an invalid regexp never matches and fails validation.
