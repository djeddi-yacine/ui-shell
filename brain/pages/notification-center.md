---
id: notification-center
title: "Notifications: shell is the only daemon, read-only popups, rules change presentation"
category: decision
status: active
tags: [notifications, shell]
created: "2026-11-09T04:11:46"
updated: "2026-11-10T03:23:55"
---

<!-- compiled_truth -->
The shell replaces dunst as the only notification daemon (Quickshell NotificationServer). Other daemons owning the bus name are ignored, not handled. History is in-memory; a crash or reload drops notifications (accepted).
Popups are read-only (no actions, no keyboard focus), Escape dismisses; keyboard use belongs to the drawer. Do-not-disturb is manual only; no hidden control flow.
Rules are a hand-written JSON file with a small schema needing no version field; a rule changes presentation, never existence, and shows a visible "rule: X" tag. Sounds are off by default, played by a pw-play script, overridable by rules.
While recording, popup message text is blurred in-shell (Telegram style) and actions hidden; popups still show. Screen-sharing and hiding the drawer during casting are out of scope. The shell's own modules post through an internal path into the same ingest as D-Bus.
Reqs: features/reqs/notifications.md.


## Timeline

- time: 2026-11-09T04:11:46
  kind: decision
  summary: "Created this page: Notifications: shell is the only daemon, read-only popups, rules change presentation"
  source: features/reqs/notifications.md
  affects: [notification-center]

- time: 2026-11-09T04:11:46
  kind: decision
  summary: Owner decisions from the notification brainstorm
  source: features/reqs/notifications.md
  affects: [notification-center]

- time: 2026-11-09T04:17:20
  kind: decision
  summary: "Layout and limits: popups at the focused monitor's right corner, drawer at the right edge, sound only under fullscreen; one popup at a time (newest replaces); unbounded manually cleared history; critical neither bypasses DND nor stays forever; badge counts unread, DND only changes the icon and is not persisted; blur stays on hover and applies to the message everywhere."
  source: features/reqs/notifications.md
  affects: [notification-center]

- time: 2026-11-09T04:28:51
  kind: decision
  summary: "Design drafted: popup dismissed by a dedicated shortcut (not Escape, popups have no focus); rules file is a hand-written QML file; recording hide is an animated spoiler shader with text not drawn; one popup at a time."
  source: features/designs/notifications.md
  affects: [notification-center]

- time: 2026-11-09T07:04:09
  kind: decision
  summary: "Implemented P1-P6. Rules are a QML list in the 'notifications' component settings file (no file watcher; reloaded when the drawer opens), not JSON. Quickshell expireTimeout is raw ms. Drawer-local keys (D, Shift+Delete, 1-9). Spoiler shader replaces blur (make dev-shaders builds the .qsb). Nested sessions rebind notifications/DND to F6/F7 via shell_shortcut_keys (SUPER+SHIFT collides). Nested notify-send test mode (P7) deferred."
  source: features/designs/notifications.md
  affects: [notification-center]

- time: 2026-11-09T16:20:15
  kind: decision
  summary: "Real-host review: left click dismisses a popup (hover holds timer, no swipe); drawer groups per app like dots-hyprland (collapsed two newest, chevron+count expand, clear group, per-item delete); animated item motion; every component has explicit fixed or capped size; images never auto-load, a fixed-size Load image placeholder loads one image per notification, in memory, never in popups. Earlier study wrongly said dots-hyprland has no notification code (corrected, section 8)."
  source: features/reqs/notifications.md
  affects: [notification-center]

- time: 2026-11-10T01:08:53
  kind: decision
  summary: "Stacks are a z-ordered deck: collapsed shows the newest card with up to 2 scaled layers behind it (collapsedStackItems=1, supersedes 2 newest dimmed); expand fans out with one under-damped spring, staggered per card; expand/clear/delete controls are icon-only (SvgIcon moved to shell/components, ShellIconButton added); deletes animate out before the center removes them."
  source: features/designs/notifications.md
  affects: [notification-center]

- time: 2026-11-10T01:48:08
  kind: reversal
  summary: "Full freedesktop spec support per owner: critical notifications no longer auto-expire (reverses 'expire like others'); sender timeout 0 = never; body markup b/i/u/a (img shown as alt text, links http/https/mailto/file only); hints transient, resident, category, action-icons, sound-file/sound-name/suppress-sound; the 'default' action is the click. Read/unread is explicit state (check icon, R key): only the owner or acting on a notification reads it, opening the drawer no longer does; unread drives the badge. Drawer opens and closes in one short time (Motion.drawerDuration)."
  source: refs/notification-spec.html
  affects: [notification-center]

- time: 2026-11-10T02:41:02
  kind: decision
  summary: "Icons are generated QML, not images or boxed buttons: SVG sources in shell/svg, scripts/generate-icons (svgtoqml -c, hash-cached, --check in test-pipelines) writes themable shell/icons/*.qml; components/Icon replaces SvgIcon (no MultiEffect); ShellIconButton is the picture itself (idle text, hover/keyboard control focus role, pressed/selected accent). DND icon = delete-alarm, clear group = remove."
  source: STYLE.md
  affects: [notification-center, mpris-media-control]

- time: 2026-11-10T02:41:02
  kind: decision
  summary: "Deck cards are sized with rounded width/height/x/y, never a scale transform, so the 1px border does not shimmer while moving; clear group/clear all slide the stack out through the right edge while fading, then close the gap (drawer.clearEverything); test-notify gained image-path, image-data, sound-name, sound-file, suppress-sound cases and runs with 1s pauses and a parallel burst."
  source: features/designs/notifications.md
  affects: [notification-center]

- time: 2026-11-10T02:53:21
  kind: decision
  summary: "Rules gain reveal: true, which exempts matching notifications from the recording blur (NotifCard redacts only when NotifCenter.redact and entry.reveal is not true). Redaction stays global otherwise; there is no 'always redact' rule."
  source: features/reqs/notifications.md
  affects: [notification-center]

- time: 2026-11-10T03:17:57
  kind: decision
  summary: "Rules gain appMatch: a case-insensitive regexp over the app name (app and appId stay exact, match is the regexp over summary and body; all set fields must match; an invalid regexp never matches and fails validation). Owner wanted per-app-regexp rules such as reveal without listing every app."
  affects: [notification-center]

- time: 2026-11-10T03:23:55
  kind: reversal
  summary: "Rules are read once, when the shell starts; the reload on drawer open is gone. Owner did not want to open the drawer to load rules while testing; an edit now applies at the next shell start (no watcher). Test cases for rules install a marked file, ask for a restart, and run on the second invocation."
  affects: [notification-center]
