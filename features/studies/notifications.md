# Notifications: caelestia-shell, DankMaterialShell, noctalia, Ambxst, omarchy, dots-hyprland, Quickshell baseline

Study of desktop notification systems in the reference shells under `refs/`, with the Quickshell Notifications service as the baseline. Facts only, with file citations. Paths are relative to `refs/` in the repository root unless absolute. Line numbers refer to the files as checked out. No decisions are recorded here. No program was run and no network command was used.

Id prefixes: `QS` = Quickshell Notifications service (`refs/quickshell/src/services/notifications/`), `CS` = caelestia-shell, `DM` = DankMaterialShell, `NC` = noctalia, `AX` = Ambxst, `OM` = omarchy, `DH` = dots-hyprland.

Correction: an earlier pass recorded `DH` as having no notification code because `dots/` looked empty. It is present under `dots/.config/quickshell/ii/` (paths below are relative to that directory). Section 8 records it; the comparison table in section 7 still shows the old `No` column for `DH`.

---

## 1. Quickshell baseline (QS)

### 1.1 Server and capabilities

- **QS1.1** The server advertises capability flags as Q_PROPERTYs: `persistenceSupported`, `bodyMarkupSupported`, `bodyImagesSupported`, `actionsSupported`, `actionIconsSupported`, `imageSupported`, `inlineReplySupported`, plus `trackedNotifications` and `extraHints`. `src/services/notifications/qml.hpp` 31-74.
- **QS1.2** `GetCapabilities` builds its reply from these flags. `src/services/notifications/server.cpp` 144-166.
- **QS1.3** `Notify` handles incoming notifications. `server.cpp` 177-200.
- **QS1.4** Generation switching for reload: `switchGeneration` `server.cpp` 66-94. `keepOnReload` is a server property, read in the same file's generation logic.
- **QS1.5** `CloseNotification` `server.cpp` 136-140. Removal from the tracked list `deleteNotification` 100-113.

### 1.2 Notification object

- **QS2.1** Urgency defaults to Normal when absent. `src/services/notifications/notification.cpp` 124-126.
- **QS2.2** Image hint precedence (`image-data`, `image_data`, `icon_data`, `image-path`): `notification.cpp` 137-162.
- **QS2.3** Inline reply is sent through the notification object. `notification.cpp` 80-95.
- **QS2.4** Action list is synchronised from the hint/action arrays. `notification.cpp` 173-226.
- **QS2.5** The object exposes `expireTimeout`, `urgency`, `hints`, `actions`, `tracked`, and `dismiss`/`expire`/`close` methods (declared in `qml.hpp`).

---

## 2. caelestia-shell (CS)

### 2.1 Server, persistence, DND

- **CS1.1** Server is a `NotificationServer` in `services/Notifs.qml` 80-100.
- **CS1.2** Persistence: a debounced `Timer` (60-78) writes `notifs.json`. Hints are excluded from the saved data.
- **CS1.3** Do Not Disturb is a boolean in `services/Notifs.qml` 34, toggled and checked at 147-170.
- **CS1.4** IPC entry points begin at `services/Notifs.qml` 170.
- **CS1.5** `popups` is the filtered list `list.filter(n => n.popup)` (`services/Notifs.qml` 21).

### 2.2 Per-notification object and timeouts

- **CS2.1** `services/NotifData.qml` 66-75 sets a close timer. Interval is `expireTimeout > 0 ? ... : default`, so a zero or negative expire value falls to the shell default branch.
- **CS2.2** When expiry is enabled or the window is fullscreen, the `popup` flag is cleared (same timer block, 66-75).
- **CS2.3** Image cache: `services/NotifData.qml` 82-112.
- **CS2.4** Action map: `services/NotifData.qml` 240-250.
- **CS2.5** Config defaults are declared in `plugin/src/Caelestia/Config/notifsconfig.hpp` 12-20.

### 2.3 Popup UI

- **CS3.1** Popup list is a `ListView` in `modules/notifications/Content.qml` 68-78. Removal animation is at 159-166.
- **CS3.2** Hover pauses the timer: `modules/notifications/Notification.qml` 53-57 (`root.modelData.timer.stop()` on enter, restart on exit).
- **CS3.3** Drag and clear logic: `modules/notifications/Notification.qml` 58-71. Middle-button handling in the same file at 49, 61-67 (`acceptedButtons` includes `Qt.MiddleButton`; `onPressed` and `onReleased` branch on `event.button`).
- **CS3.4** Critical urgency colours: `modules/notifications/Notification.qml` 25 and 120.
- **CS3.5** Progress ring: `modules/notifications/Notification.qml` 214.
- **CS3.6** Action invoke: `modules/notifications/Notification.qml` 490.

### 2.4 Sidebar grouping

- **CS4.1** `modules/sidebar/NotifGroup.qml` groups by `appName` (21-28) and sorts critical first (27-28).

### 2.5 Lock screen

- **CS5.1** `modules/lock/NotifDock.qml` and `modules/lock/NotifGroup.qml` exist.
- **CS5.2** `plugin/src/Caelestia/Config/lockconfig.hpp` 19: `hideNotifs = false`.

### 2.6 Not found in CS

- No sound playback code was found in the notification modules.
- No inline reply UI was found.
- No per-app mute was found.

---

## 3. DankMaterialShell (DM)

### 3.1 Server, queue, ingress

- **DM1.1** Server setup `quickshell/Services/NotificationService.qml` 697-708.
- **DM1.2** Ingress from the server `NotificationService.qml` 360-371; enqueue 373-391.
- **DM1.3** Queue: `NotificationService.qml` 46-63. Queue pop and eviction 1196-1223.
- **DM1.4** Queue limits are declared in the same file: `maxVisibleNotifications: 4` (line 46), `enterAnimMs: 400` (48), `maxQueueSize: 32` (52), `maxIngressPerSecond: 20` (53).
- **DM1.5** DND, dedupe and sound handling: `NotificationService.qml` 721-772.
- **DM1.6** Policy block: `NotificationService.qml` 482-531.
- **DM1.7** Expiry timer: `NotificationService.qml` 895-923.
- **DM1.8** Group key: `NotificationService.qml` 1348-1354.
- **DM1.9** History file is named in `NotificationService.qml` line 39. Unread count is computed at 21-35.

### 3.2 Timeouts and settings

- **DM2.1** `quickshell/Common/settings/SettingsSpec.js` 1312-1322: timeouts Low and Normal 5000 ms, Critical 0 (never expires).
- **DM2.2** Dedupe setting at `SettingsSpec.js` 1330.
- **DM2.3** History settings at 1339-1346.
- **DM2.4** DND allows critical at 1360. DND while screen sharing at 1363.
- **DM2.5** Popup position setting `notificationPopupPosition` is in `quickshell/Common/SettingsData.qml` 853.

### 3.3 Popups

- **DM3.1** Position mapping: `quickshell/Modules/Notifications/Popup/NotificationPopupManager.qml` 16-28.
- **DM3.2** Enter and exit animations: `Popup/NotificationPopup.qml` 103-140.
- **DM3.3** Hover pauses the timeout: `Popup/NotificationPopup.qml` 692-699. Timeout progress bar 777-812.
- **DM3.4** Swipe dismissal: `dismissThreshold` at `Popup/NotificationPopup.qml` 588. Swipe threshold `swipeThreshold` is 0.35 in `quickshell/Modules/Notifications/NotificationMetrics.qml` 36.
- **DM3.5** Default-action invoke: `Popup/NotificationPopup.qml` 185-191.

### 3.4 Per-app mute and DND bypass

- **DM4.1** `quickshell/Common/SettingsData.qml`: `addMuteRuleForApp` 3451; `setAppDndBypass` 3510.

### 3.5 Lock screen

- **DM5.1** `quickshell/Modules/Lock/Widgets/LockNotificationsWidget.qml`: mode at line 17, grouping 24-53.

### 3.6 CLI

- **DM6.1** `core/cmd/dms/commands_notify.go` 36-37 defines the notify command.

### 3.7 Not verified in this study

- Sound: DM reads the `suppress-sound` and `sound-name` hints and plays through its audio service. The exact lines for the sound call were not recorded.
- Inline reply: the server advertises the capability. No caller for it was located in the cited range.

---

## 4. noctalia (NC)

### 4.1 D-Bus service and capabilities

- **NC1.1** `src/dbus/notification/notification_service.cpp` 101-110: `Notify` parameters.
- **NC1.2** `GetCapabilities` 438-440.
- **NC1.3** Action invocation: `onInvokeAction` 485-500. `emitActionInvoked` 503-530 handles the `inline-reply::` keys.

### 4.2 Limits and expiry

- **NC2.1** `src/notification/notification_manager.h`: `normalizeNotifyExpireTimeout` 38-48, `kDefaultNotificationTimeout` 30, `kMaxNotificationActions` 34.
- **NC2.2** History cap `src/notification/notification_manager.cpp` 186-187.
- **NC2.3** History file and path at `notification_manager.cpp` 873 and 883.

### 4.3 DND and sound

- **NC3.1** `setDoNotDisturb` `notification_manager.cpp` 817-821.
- **NC3.2** Sound gate `notification_manager.cpp` 436-437.
- **NC3.3** DND policy enum `src/notification/notification.h` 27-31.

### 4.4 Toast UI

- **NC4.1** `src/shell/notification/notification_toast.cpp`: `pauseTimeout` 1403-1409; `resetPopupHover` 1372-1381; `enforceMaxVisible` 1533-1537.
- **NC4.2** Critical progress accent 350-351.
- **NC4.3** Inline reply UI at roughly 74-98, 1107 and 2707.

### 4.5 Configuration

- **NC5.1** `src/config/config_types.h` 829-852 `NotificationConfig`: position `top_right` (835), offsets (844-845), `collapseOnDismiss` (847), `keepDismissedInHistory` (848), `historyRetentionHours` (849), `maxVisible` (850).
- **NC5.2** Schema reference `src/config/config_schema.cpp` 311.
- **NC5.3** User documentation `docs/user/services/notifications.mdx`: layer, offsets, monitors, history retention, `max_visible` at 43-64; filters 66-95.

### 4.6 Bar indicator

- **NC6.1** `src/shell/bar/widgets/notification_widget.cpp`: DND glyph line 68; unread count 83-90.

### 4.7 Test tooling

- **NC7.1** `tools/notifications-test.sh` (68 lines). `tools/notifications-inline-reply-test.sh` (33 lines).
- **NC7.2** Unit tests: `tests/notification_dnd_test.cpp`, `notification_filter_test.cpp`, `notification_history_dismiss_test.cpp`, `notification_history_utf8_test.cpp`, `notification_internal_history_test.cpp`.

---

## 5. Ambxst (AX)

### 5.1 Service

- **AX1.1** `modules/services/Notifications.qml`: `NotifTimer` 104-127; `NotificationServer` 307-316; expire mapping 340-342; send timer 381-383.
- **AX1.2** Silent mode: lines 143-146. Silent toggle exposed by `modules/widgets/defaultview/NotificationIndicator.qml` 63 and 74.
- **AX1.3** Grouping 264-289. Summary limit about 198-216.
- **AX1.4** Persistence: `FileView` path `~/.cache/ambxst/notifications.json` at line 162.
- **AX1.5** Group pause: `pauseGroupTimers` 498-506.

### 5.2 UI

- **AX2.1** `modules/notifications/NotificationGroup.qml`: hover pause 104-110; drag confirm threshold `dragConfirmThreshold` 54.
- **AX2.2** `modules/notifications/NotificationAppIcon.qml`: icon fallback chain 41-48 and 75.
- **AX2.3** `modules/notch/NotchNotificationView.qml`: popup list cycling 31 and 69-117.

### 5.3 Backend

- **AX3.1** `backend/pkg/svc/notify/notify.go`: send 99-112; `cacheImage` 160; `SendFallback` 357.
- **AX3.2** Tests `notify_test.go` and `notify_e2e_test.go` in the same directory.

### 5.4 Not found in AX

- No inline reply UI was found.

---

## 6. omarchy (OM)

### 6.1 Documentation

- **OM1.1** `docs/notifications.md`: daemon description; toast lifecycle 15-30; silencing 40-62; sender contract 63-100.

### 6.2 Service

- **OM2.1** `shell/plugins/notifications/Service.qml`: `NotificationServer` 979-991; durations 102-115; DND bypass 128-135; settings persistence 857-871; history replay 658 and 716; lifetime ticking 1063-1085.

### 6.3 Card

- **OM3.1** `shell/plugins/notifications/components/NotificationCard.qml`: click `MouseArea` 78-90; hover close 199-225.

### 6.4 Indicator

- **OM4.1** `shell/plugins/bar/indicators/Dnd.qml` is the DND indicator (22 lines, whole file).

### 6.5 Tests

- **OM5.1** `test/shell.d/notifications-test.sh` (775 lines). `test/shell.d/notification-send-test.sh` (199 lines).

### 6.6 Not found in OM

- No sound playback code was found in the notification service.
- No inline reply UI was found.

---

## 7. Comparison

Yes means the feature is present in the cited code. No means nothing was found in the cited paths. Partial means some part is present.

| Feature | QS | CS | DM | NC | AX | OM | DH |
|---|---|---|---|---|---|---|---|
| Notification server on D-Bus | Yes (QS1.1-1.3) | Yes (CS1.1) | Yes (DM1.1) | Yes (NC1.1) | Yes (AX1.1) | Yes (OM2.1) | No |
| Capabilities advertised | Yes (QS1.2) | Partial | Partial | Yes (NC1.2) | Partial | Partial | No |
| Persistence of history | Not in baseline | Yes (CS1.2) | Yes (DM1.9) | Yes (NC2.3) | Yes (AX1.4) | Yes (OM2.1) | No |
| Urgency-aware timeouts | Yes (QS2.1) | Yes (CS2.1) | Yes (DM2.1, critical 0) | Yes (NC2.1) | Yes (AX1.1) | Yes (OM2.1) | No |
| Hover pauses timeout | No | Yes (CS3.2) | Yes (DM3.3) | Yes (NC4.1) | Yes (AX2.1) | Yes (OM3.1) | No |
| Critical never expires | Not verified | Not verified | Yes (DM2.1) | Not verified | Not verified | Not verified | No |
| Grouping by app | No | Yes (CS4.1) | Yes (DM1.8) | Not verified | Yes (AX1.3) | Not verified | No |
| DND | Not in baseline | Yes (CS1.3) | Yes (DM1.5) | Yes (NC3.1) | Yes (AX1.2) | Yes (OM2.1) | No |
| Per-app mute or bypass | No | No | Yes (DM4.1) | Yes (NC5.3 filters) | No | Partial (OM2.1 bypass) | No |
| Actions and click | Yes (QS2.4) | Yes (CS3.6) | Yes (DM3.5) | Yes (NC1.3) | Yes (AX2.1) | Yes (OM3.1) | No |
| Inline reply | Yes (QS2.3) | No | Not verified | Yes (NC4.3) | No | No | No |
| Swipe dismissal | No | Partial (CS3.3 drag) | Yes (DM3.4) | Not verified | Yes (AX2.1 drag) | Not verified | No |
| Progress bar | Not verified | Yes (CS3.5) | Yes (DM3.3) | Yes (NC4.2) | Not verified | Not verified | No |
| Image handling | Yes (QS2.2) | Yes (CS2.3) | Not verified | Not verified | Yes (AX3.1 cacheImage) | Not verified | No |
| Sound | No | No | Yes (DM1.5, unverified lines) | Yes (NC3.2) | No | No | No |
| Lock screen widget | No | Yes (CS5.1) | Yes (DM5.1) | Not verified | No | Not verified | No |
| Bar indicator | No | Not verified | Not verified | Yes (NC6.1) | Yes (AX1.2) | Yes (OM4.1) | No |
| Test scripts | No | No | No | Yes (NC7.1) | Yes (AX3.2 Go tests) | Yes (OM5.1) | No |

## 8. dots-hyprland (DH), `refs/dots-hyprland/dots/.config/quickshell/ii/`

Read in a later pass, only the group, item, expand button and list view.

### 8.1 Grouping and stacking
- **DH1.1** `modules/common/widgets/NotificationListView.qml` lists one `NotificationGroup` per app name (model `Notifications.appNameList`, 14-16).
- **DH1.2** `NotificationGroup.qml` 17-19: `expanded` starts false; `multipleNotifications` is true when count is above 1.
- **DH1.3** Collapsed, the group shows the two newest items only: model `slice().reverse().slice(0, 2)` at 241; the second item is drawn at opacity 0.5 when the count is above 2 (249).
- **DH1.4** Collapsed card height is capped: `Math.min(80, row.implicitHeight + padding * 2)` at 140; expanded it is the full content height. The height change animates (`Behavior on implicitHeight`, 142-145).
- **DH1.5** Expanded shows every item of the group, newest first (241).
- **DH1.6** A group of several shows the app name as the header and a count; a single notification shows its summary as the header (`showAppName`, topRow).

### 8.2 Expand button
- **DH2.1** `NotificationGroupExpandButton.qml`: a pill button (radius full), fixed `implicitHeight` = font size + 8 (13), `implicitWidth` at least 30 (14). It holds the count (only when above 1) and a chevron (`keyboard_arrow_down`).
- **DH2.2** The chevron rotates 180 degrees when expanded, animated (`Behavior on rotation`, 40-43).
- **DH2.3** Right click anywhere on the group also toggles it (`NotificationGroup.qml` 89-90).

### 8.3 Dismissal
- **DH3.1** Middle click dismisses a group (`NotificationGroup.qml` 94-95) or an item (`NotificationItem.qml` 74-75).
- **DH3.2** Horizontal drag beyond 70 px dismisses with a slide-off animation (`NotificationGroup.qml` 24, 56-71); neighbours follow at 0.3 and 0.1 of the drag (28-32).
- **DH3.3** Popups: hover cancels the timeout, leaving restarts it (`onContainsMouseChanged`, 44-52).
- **DH3.4** Clear all: `Notifications.discardAllNotifications()` in `modules/ii/sidebarRight/notifications/NotificationList.qml` 67.

### 8.4 Images and motion
- **DH4.1** The image is shown in the app icon slot; for a group of several the group icon shows no image, and an item's image is drawn only when expanded (`NotificationItem.qml` 99).
- **DH4.2** Every size, spacing, rotation and opacity change uses a `Behavior` with a shared animation preset (`elementMove`, `elementMoveFast`), so the list moves instead of jumping.
- **DH4.3** Nothing there gates image loading behind a user action.
