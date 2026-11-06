# Screen recording UI study

Scope: the user interface and interaction design of the panels, popups and
indicators in four reference projects cloned into `refs/`. Only UI files were
read (QML, the UI sections of READMEs and the design guide in reel). No code
was run. File paths are relative to each repo under `refs/`.

Repos studied: reel, omarchy-sexy-screenshot, omarec, Better-Recast.

Note on evidence: reel ships a written design system (`docs/design.md`), so its
statements about tokens and motion are quoted from that guide and checked
against `Panel.qml`. Other repos are described from their QML only.

---

## 1. reel

Files: `Panel.qml` (3505 lines), `Countdown.qml`, `Model.js`, `docs/design.md`,
`README.md`.

### 1.1 Main panel layout

- Content box 440 x 410 logical px (`docs/design.md` section 5, "Panel geometry").
- Fixed frame, top to bottom (`docs/design.md` 5, "Fixed frame rule"):
  - Hero row, 22 px high: a recording status pill (fixed 60 x 22 slot), then a
    version pill and a history icon button at the trailing end.
  - 10 px gap.
  - Primary action row, 38 px high: three equal buttons, Record / Pause /
    Discard.
  - Settings tab strip, 30 px high: four equal tabs, Media, Zoom, Output, Keys.
  - A 1 px hairline.
  - Scroll body, which takes the remaining height and is the only part that
    scrolls.
- The Media tab is grouped with section labels: Capture (Countdown, Webcam
  corner, Webcam device, Record the pointer), Audio (Desktop audio, Microphone,
  Noise reduction), Video (Frame rate, Quality, Video codec, Resolution cap,
  Container). See `Panel.qml` lines 91-102 and `docs/design.md` 6.5.1.
- Settings rows are 30 px high with a 24 px square glyph tile, a label and a
  value chip (`docs/design.md` 6.6).
- History rows are 56 px high with an 84 x 48 thumbnail (`docs/design.md` 6.8).

### 1.2 How the target is chosen

- There is no target row in settings. Pressing Record closes the panel, then
  Omarchy's picker runs. The user clicks a window or monitor, or drags an area.
  The panel comment says the picker "owns the screen" (`Panel.qml` 552-553).
- A window is recorded as its visible screen rectangle, so overlapping windows
  can appear in the take (`README.md`, "Usage and keyboard shortcuts").
- `Model.js` lines 350-417 build a preview plan. Portal selections and
  selections that cross monitors get an "unavailable" preview with the reason
  text, for example "Portal capture is chosen in the system picker. An exact
  live preview is unavailable."

### 1.3 Audio, microphone, webcam and countdown

- Presented as value-cycling rows, not as checkboxes:
  - Desktop audio and Microphone cycle On/Off (`Panel.qml` 263-270).
  - Noise reduction cycles Off/On.
  - Webcam corner cycles Off, Small, Medium, Large (`Panel.qml` 273).
  - Webcam device cycles Auto plus every connected camera (`Model.js` 593-630).
  - Countdown cycles 0, 3, 5, 10 (`Panel.qml` 275).
- The summary line reads "System audio + microphone", "System audio",
  "Microphone" or "No audio" (`Panel.qml` 415-421).
- Toggle rows are a 32 x 16 pill (`docs/design.md` 6.6). Cycle rows use a value
  chip plus a chevron.
- Right-click on a cycle row moves backwards; left-click moves forwards
  (`docs/design.md` 6.6).

### 1.4 States

- The bar and panel read a status value from the engine: idle, starting
  (with a `countdown` stage), recording, paused, finalizing (`Model.js` 97-135,
  `Panel.qml` 35-42).
- Idle: hero pill shows a dim dot and "Ready" (`docs/design.md` 6.2).
- Starting with countdown: the countdown ring overlay is shown (see 1.5).
- Recording: accent dot with a live clock. The pill pulses 0.35 to 1.0 over
  900 ms each way (`docs/design.md` 6.2).
- Paused: secondary dot, frozen clock, no pulse. Primary button relabels to
  Resume (`Panel.qml` 1625-1626).
- Finalizing: notice "Saving the take..." (`Panel.qml` 1225).
- Error: shown as a toast with the urgent border and an urgent ink line, for
  example "Could not move that take to the trash." (`Panel.qml` 3427). The bar
  never shows error text (`docs/design.md` 6.1).

### 1.5 Bar indicator and popups

- Bar mark: a drawn screen outline with a centre dot, not a font glyph
  (`docs/design.md` 6.1). Idle shows the mark only. Update available adds a
  4.5-unit accent dot. Target picking shows a target glyph. Countdown shows the
  number. Recording shows a dot plus the clock in urgent colour. Paused shows a
  dim pause glyph with no clock. Saving shows a dim save glyph.
- Recording width is the measured clock width plus `Style.space(30)`. The
  pulse runs only while recording or capturing (`docs/design.md` 6.1).
- Bar tooltip text: "Reel - recording 00:00 - right-click to pause", or
  "Reel - paused at ... - right-click to resume" (`Panel.qml` 466-471).
- Countdown is a separate non-focusable overlay window named `reel-countdown`
  (`Countdown.qml`, `docs/design.md` 6.12). It reads `state.json` to follow the
  recorder's clock. It shows a 200 px circle, a 3 px accent arc, the number in
  accent at display size x 2.2, and the label "Recording starts". Its input
  mask is empty so it never blocks the desktop.
- Toast: a one-line message at the bottom of the panel, 1900 ms lifetime, with a
  bottom progress bar and a 3 px leading bar. It is the only overshoot animation
  in the product (`docs/design.md` 6.10 and 8).

### 1.6 Keyboard flow and focus

- A single cursor state lives on the panel root (`docs/design.md` 7, "One
  cursor"). Hover and keyboard move the same cursor, so only one highlight is
  visible.
- Keys: r record/stop, p pause/resume, d discard (press twice), shift+h
  history, 1 to 4 jump to a settings tab, s focus tabs, arrows and j/k move,
  h/l cycle an option, enter/space activate, o open folder, c copy path, a
  actions menu, x trash, u share, t cut in Omacut, q close, esc back then close
  (`docs/design.md` 7, "Keyboard" table).
- Escape cancels the picker or countdown but never stops an active take
  (`Panel.qml` 1049; `docs/design.md` 7).
- The panel can be closed during a take without stopping it (`docs/design.md`
  10).
- The filename prefix field blocks single-key shortcuts while it has focus
  (`docs/design.md` 7, "Keyboard" rules).
- The panel's keyboard overlay is a KeyboardPanel with a PanelKeyCatcher
  (`Panel.qml` 1411).

### 1.7 Visual language

- Monochrome. Colour comes from the Omarchy theme; reel adds no hues
  (`docs/design.md` 2, principle 1).
- Alpha ladder on the theme foreground: rest fill 0.04, hover 0.08, selected
  0.14, pressed 0.22, hairline 0.12, strong border 0.24, body at rest 0.72
  (`docs/design.md` 3, "Alpha ladder"). Implemented as aliases on the root
  (`Panel.qml` 80-90).
- Accent is a signal only (live state, the primary action, active tab, cursor).
  Urgent is for destructive or failing states.
- Radius is `Style.cornerRadius` for rows, buttons and menus. Pills are used
  only for toggles and the status pill (`docs/design.md` 5, "Surfaces").
- The primary Record button is the only gradient, a two-stop accent shade with a
  top highlight (`docs/design.md` 5).
- Shadows only on floating layers (toast, take menu, countdown).
- Typography: caption 10, bodySmall 11, body 12, title 14, heading 16, display
  24 (`docs/design.md` 4). Section labels are caption, dim, bold, not
  uppercase.
- Motion: 60 to 240 ms, OutCubic/InCubic, plus the toast OutBack
  (`docs/design.md` 8). Infinite loops only for the pulse and the bar dot,
  disabled under `Style.reduceMotion`.

### 1.8 Empty and unavailable states

- Empty history: a 46 px circle icon, the heading "No takes yet", and the line
  "Record something and it will appear here." No action button
  (`docs/design.md` 6.9).
- No camera: Webcam device shows "Auto"; a camera that was unplugged shows its
  name with the suffix "(unplugged)" (`Model.js` 624-630). The camera list is
  re-probed when the panel opens and once a second when the panel is shown
  (`Panel.qml` 1092-1107, 3355-3366).
- No webcam device list at all is not given separate text; the row simply has
  only Auto.
- Portal and cross-monitor selections show an "unavailable" live preview with a
  reason (`Model.js` 350-417).
- The bar tooltip never shows errors (`docs/design.md` 6.1).

### 1.9 Settings presentation

- Inline in the panel, in four fixed tabs. A new setting must fit a tab, and
  reel says a fifth tab is not allowed (`docs/design.md` 6.5.1).
- Each tab opens at the top. The selected tab is not persisted (`docs/design.md`
  6.5).
- No presets. Settings are saved on change to a `reel.json`, with a toast on
  failure (`Panel.qml` 3443).

### 1.10 Notable points

- Clever: one cursor for hover and keyboard (`docs/design.md` 7). The panel's
  input mask shrinks to zero while a take row is dragged, so the drop reaches
  the window below and the drag never opens the take (`Panel.qml` 1415-1420;
  `docs/design.md` 6.8).
- Clever: Discard is a two-step action that relabels itself to "Discard?"
  instead of opening a dialog (`docs/design.md` 6.3).
- Clever: the status pill reserves a fixed 60 px slot so the clock does not move
  the header (`docs/design.md` 6.2).
- Clever: the design guide is detailed enough to review against. Its rules are
  checkable (for example the alpha ladder and the "no spinners" rule).
- Bad: `Panel.qml` is 3505 lines in one file. Every row, tab and toast lives in
  one component.
- Bad: the scrollbar is hidden and the body auto-scrolls when the pointer sits
  within 64 px of an edge, with no visible indicator (`docs/design.md` 7,
  "Scrolling"). Discoverability depends on the user knowing it is there.
- Bad: the Record button forces a full picker step, so there is no way to
  start a fixed-target recording from the panel alone.

---

## 2. omarchy-sexy-screenshot

Files: `Panel.qml` (390 lines), `README.md`, `manifest.json`.

### 2.1 Main panel layout

- One vertical list in a KeyboardPanel, width `fittedContentWidth(320)`, height
  capped at 560 (`Panel.qml` 290-296).
- Grouped under three section headers: SCREENSHOT (Smart capture, Region,
  Window, Fullscreen, Copy only, Save to disk), MORE (Extract text, QR code,
  Color picker), RECORD (Record region, Record fullscreen, Pin window + desktop
  audio, With desktop audio, With desktop + mic, and With webcam when a camera is
  present). The section header appears only on the first row of its group
  (`Panel.qml` 43-70, 102-107).
- Each row is 34 px high (`Panel.qml` 216-221 in the row delegate).

### 2.2 How the target is chosen

- No target picker inside the panel. The target is set by the command:
  smart, region, window, fullscreen. The window and region choices are made by
  Omarchy's own capture tools (`Panel.qml` 43-70, `README.md` table).
- Pinned window recording uses the desktop portal. The user picks a window in
  the share picker, then can switch workspaces (`README.md`, "Using it").

### 2.3 Audio, microphone and webcam

- Presented as separate action rows, not switches: "With desktop audio", "With
  desktop + mic", "With webcam" (`Panel.qml` 70-80, `recordCommands` 52-58).
- There is no stored state. Each row runs a different command.
- The webcam row appears only when `omarchy-hw-webcam` exits with code 0
  (`Panel.qml` webcamProc, 221-226 region).

### 2.4 States

- Idle: the record rows are shown, and the bar icon is the camera glyph
  (`Panel.qml` 80-120 and bar button).
- Recording: the record rows are replaced by one row, "Stop recording" (or
  "Stop pinned recording" for pinned), with an urgent icon and hint `r`. The bar
  icon becomes a different glyph (U+F0EC2) and shows the active tint
  (`Panel.qml` 80-99 and the BarIconButton block).
- The recording state is polled from the pinned helper's `--status` output every
  2 seconds, with a 1 second retry on first load (`Panel.qml` statusProc,
  recordPollTimer).
- Pinned and classic are distinguished in the tooltip only.

### 2.5 Bar indicator and popup

- Bar chip: a camera glyph in the bar's foreground. While recording it swaps to a
  different glyph and sets `active` (`Panel.qml` bar button block).
- Tooltip text: "Screenshot - click for options, right-click to capture", or
  "Recording - click for options, click Stop in the panel", or the pinned
  variant (`Panel.qml` bar button block).
- No timer and no elapsed time is shown anywhere.
- The popup opens on left-click and closes on Escape. Right-click captures
  immediately, and middle-click captures fullscreen (`Panel.qml` bar button).

### 2.6 Keyboard flow, shortcuts and focus

- `j` and `k` or the arrow keys move the cursor. Enter or Space runs the row
  under the cursor (`README.md`, "In the panel").
- Single letters run a row directly without moving the cursor. Digits 1 to 4 are
  the screenshot modes. Letters: y copy, s save, t text, q QR, p colour picker,
  r record region or stop, f record fullscreen, w pinned (`README.md` table;
  `Panel.qml` `runHint`, 128-134).
- The panel closes before a capture so it is not in the shot. The delay is
  configurable: `closeDelayMs`, default 300 ms, clamped to 100-1000
  (`Panel.qml` `launch`, `captureTimer`; `README.md` Settings).
- Hover and keyboard share one cursor (`Panel.qml` `cursorFromPointer`, the
  `containsMouse` handler).

### 2.7 Visual language

- Rows are CursorSurface components. Icons are Style.font.icon, labels are
  Style.font.body, hints are Style.font.caption in a dimmed colour
  (`Panel.qml` row delegate).
- The dimmed colour is `Qt.darker(foreground, 1.55)`, not an alpha token
  (`Panel.qml` line 36).
- The Stop row's icon is urgent. Other icons use the foreground.
- No animation is specific to this plugin. Motion comes from the shared kit.

### 2.8 Empty and unavailable states

- No camera: the webcam row is hidden. There is no message.
- Unknown IPC mode returns the string "error: unknown mode: <name>"
  (`Panel.qml` `screenshot` and `record`). This is an IPC result, not a UI state.
- Recording state not yet known: the list shows the non-recording rows.

### 2.9 Settings presentation

- None in the UI. Settings are set from the command line only:
  `closeDelayMs` and `rightClickAction` (`README.md`, "Settings").

### 2.10 Notable points

- Clever: the panel closes first and only then runs the capture after a delay,
  so the popup never appears in the screenshot (`Panel.qml` `launch`).
- Clever: the Stop row replaces the record rows in place, so there is always one
  obvious stop control while recording.
- Clever: letter keys run an action at once, which suits a menu that is used
  many times a day.
- Bad: `r` means "record region" when idle and "stop" when recording. The
  visible list also changes length while recording, which moves rows under the
  pointer.
- Bad: no feedback during a capture other than the icon change. No elapsed
  time, no indication that audio is captured.
- Bad: audio choices are one-shot commands, so the user cannot see what the
  next recording will capture.

---

## 3. omarec (OMARec Studio)

Files: `BarWidget.qml` (662 lines), `Service.qml` (384 lines), `README.md`.

### 3.1 Main panel layout

- A single "Studio" panel with a header row: title "OMARec" and a hero line
  (`BarWidget.qml` 298-330). The hero line reads "Live - <camera>" or
  "Ready - portrait 8:9 - medium" (`BarWidget.qml` `heroMeta`).
- Start / Stop bordered button at the right of the header. It is disabled while
  busy or picking (`BarWidget.qml` 330-340).
- A warning line, urgent colour, shown only when there is a message
  (`BarWidget.qml` 344-355).
- Sections in this order, each with an uppercase label (`BarWidget.qml`
  362-660): DEVICE, SIZE, FRAMING, ROUNDING, POSITION, PREVIEW, then a reset row
  and a footer hint.
- Segmented controls (SIZE, FRAMING, ROUNDING) sit in a rounded group with a
  4 percent foreground fill (`BarWidget.qml` 425-516).
- POSITION is a 2 by 2 grid of bordered buttons (`BarWidget.qml` 541-566).
- PREVIEW is a box with a rectangle drawn to the true overlay size on a 16:9
  screen (`BarWidget.qml` 571-602; the proportions mirror `bin/omarec`).

### 3.2 How the target is chosen

- There is no screen target. The overlay sits on a screen corner, chosen with
  the POSITION grid. The camera is chosen with the DEVICE row, which opens a
  picker (`BarWidget.qml` 387-415).

### 3.3 Audio, microphone and webcam options

- No audio or microphone options. This is a camera overlay only; the footer says
  "OMARec is a live camera overlay only - it never records." (`BarWidget.qml`
  650-653).
- The camera appears as a row with a camera glyph and its name, or "None
  selected" (`BarWidget.qml` 387-398).
- Size, framing, rounding and position are segmented or grid options, not
  switches.

### 3.4 States

- Off/idle: camera glyph in the bar; panel reads "Ready - <orientation> <ratio>
  - <size>" (`BarWidget.qml` `heroMeta`).
- Busy: hero button shows "..." and the hero line reads "Working..." (`BarWidget.qml`
  320-330).
- Live: LIVE pill in the bar; panel hero line reads "Live - <camera>" and the
  button reads "Stop" (`BarWidget.qml` 330, 183-222).
- Degraded (CLI missing dependencies): bar pill is dimmed; panel warning line
  shows the first line of the CLI error (`BarWidget.qml` 350, 56, 67;
  `Service.qml` 143-151).
- Service not loaded: the bar icon dims to 0.4 opacity and the tooltip says the
  service is not loaded (`BarWidget.qml` 61, 236-239, 63-65).
- Picking: warning line reads "Choose a camera..." and the Start button is
  disabled (`BarWidget.qml` 349-351).

### 3.5 Bar indicator and popup

- Idle: camera glyph at 0.85 opacity in the bar foreground (`BarWidget.qml`
  231-240).
- Live: a LIVE pill, accent fill, dot plus the word LIVE, letter spacing 1.2
  (`BarWidget.qml` 183-222). The pill width is measured from its text plus
  `Style.space(30)`, so it does not jitter (`BarWidget.qml` 56-59, 175-181).
- Left-click opens or closes the panel. Right-click toggles the overlay
  directly, unless busy (`BarWidget.qml` 280-296).
- Tooltip: "OMARec - live on <camera>", "OMARec - off", "OMARec - working...",
  or "OMARec - degraded: <hint>" (`BarWidget.qml` 63-70).
- The bar widget hides when idle if `showWhenIdle` is off, but never while live,
  so a live overlay can always be stopped (`BarWidget.qml` 27-40).

### 3.6 Keyboard flow, shortcuts and focus

- There are no keyboard shortcuts (`README.md`, "Panel & controls").
- Arrow keys move one cursor through a flat list of 17 named stops:
  toggle, camera-pick, the three sizes, two orientations, five roundings, four
  positions and reset (`BarWidget.qml` `nav`, `moveCursor`). Enter activates
  the stop under the cursor (`BarWidget.qml` 272, `activateCursor`).
- Hover calls the same `setCursor` as the keyboard, so there is one highlight
  (`BarWidget.qml` 337-340, 412, 563, 643).

### 3.7 Visual language

- Colours come from the theme: foreground, accent, urgent, with the dim colour
  `Qt.darker(foreground, 1.55)` (`BarWidget.qml` 37-48).
- Hover and selected fills come from `Style.hoverFillFor` and
  `Style.selectedFillFor` (`BarWidget.qml` 47-48).
- Section labels are uppercase, which the other plugins avoid.
- Radius is `Style.cornerRadius` for groups and the preview box. The LIVE pill
  is a full-height radius (`BarWidget.qml` 202).
- The README says the QML has no animations (README, "Lightweight").

### 3.8 Empty and unavailable states

- No camera selected: "None selected" in the DEVICE row (`BarWidget.qml` 396).
- No webcam found: the README troubleshooting section says "No webcam devices
  found" and points to `v4l2-ctl`. The panel itself does not show this text; the
  DEVICE row shows "None selected" and the picker is the only way out.
- Missing dependencies: the warning line names the first line of the CLI error
  (`BarWidget.qml` 350).

### 3.9 Settings presentation

- All settings are inline in the one panel. There are no tabs, no presets and no
  separate settings page.
- Changes apply at once. Each change restarts the overlay with the same camera
  and the new shape (`README.md`, "Troubleshooting").
- "Reset to defaults" is the last row (`BarWidget.qml` 610-640).

### 3.10 Notable points

- Clever: the PREVIEW box draws the overlay at its true relative size, shape and
  corner. The fractions mirror the geometry in the CLI (`BarWidget.qml`
  `previewGeom`, 83-118 region).
- Clever: the LIVE pill is measured from its text, so its width is correct for
  any camera label.
- Clever: a live overlay can always be stopped because the bar widget is forced
  visible while live (`BarWidget.qml` 27-40).
- Clever: serialised restarts, so a panel click and a terminal command converge
  on the latest setting (`README.md`, "Troubleshooting").
- Bad: uppercase section labels are a different style from the other repos.
- Bad: the Start button is disabled while picking, and the only explanation is a
  warning line that appears in a different place.
- Bad: no keyboard shortcuts at all. Everything is reached through the cursor.

---

## 4. Better-Recast

Files: `Panel.qml` (2632 lines), `BarWidget.qml` (418 lines),
`PresetsSection.qml`, `RecentRecordings.qml`, `TrimTool.qml`, `Config.js`,
`README.md`.

### 4.1 Main panel layout

- One ScrollView wraps the whole panel. The header, mode switch, primary button
  and every section scroll together (`Panel.qml` 526-560). This is the main
  structural difference from reel.
- Top to bottom (`Panel.qml` line references are to the Column inside the
  ScrollView):
  - Header row: "Better Recast" title at title size, with a live state label on
    the right in caption bold (`Panel.qml` 554-590).
  - Mode switch: three equal buttons, Record, Stream, Replay (`Panel.qml`
    592-640).
  - Update notice for gpu-screen-recorder, a 24 px row in urgent with "tap to
    update" in accent (`Panel.qml` 641-668).
  - Primary action, full width, 1.4 times the control height, title size
    (`Panel.qml` 670-700).
  - Replay row (save and stop buffer) and pause row (`Panel.qml` 708-767).
  - Error banner (`Panel.qml` 794-830).
  - Sections with uppercase labels: CAPTURE (846), DETECTED HARDWARE (954),
    STREAM (1057), REPLAY (1258), SETTINGS (1398), RECORDING OSD (1830),
    OUTPUT (1899), then POST-RECORDING with presets, trim, last clip and the
    recent list (2078-2110).
  - Advanced encoder profile, behind a button labelled "Advanced (encoder)" or
    "Hide advanced" (`Panel.qml` 2122 onwards).
- Settings use a two-column GridLayout: a right-aligned muted label on the left,
  the control on the right, spacing 10 by 8 (`Panel.qml` 846-870).

### 4.2 How the target is chosen

- Target is a dropdown with three options: "Window / portal", "Monitor",
  "Region" (`Panel.qml` 858-890).
- Monitor adds a second dropdown whose options are built from the live monitor
  list, labelled with name and resolution (`Panel.qml` `monitorOptions`).
- Region shows a button "Pick region" or "Re-pick region" and the saved geometry
  as text, or "No region selected" when none is saved. The button calls
  `omarchy-capture-region smart --match-monitor` (`Panel.qml` around 900-935).
- Saved regions are also listed in the presets section with a Capture button
  (`PresetsSection.qml` 153-198).

### 4.3 Audio, microphone and webcam options

- Audio is a ToggleSwitch row, "Audio", that sets `audioEnabled` (`Panel.qml`
  1505-1520).
- Mic is a second ToggleSwitch row (`Panel.qml` 1521-1535). Cursor is a third
  (`Panel.qml` 1537-1550).
- Audio devices is a sub-block, visible only when audio is on (`Panel.qml`
  1556-1572). It has a Desktop dropdown and a Mic dropdown, then Desktop volume
  and Mic volume as PanelSlider rows with a percentage readout
  (`Panel.qml` 1573-1680).
- Per-application sources are appended to the device list with the suffix
  " (app)" (`Panel.qml` `audioDeviceOptions`, 371-391).
- Codec, bitrate and noise gate appear in the same block (`Panel.qml`
  1683-1758).
- No webcam option was found in these files.

### 4.4 States

- The state label in the header (`Panel.qml` `stateLabel`, 287-300):
  - "REC" plus elapsed while recording, "LIVE" plus elapsed when streaming.
  - "PAUSED" plus elapsed while paused.
  - "STARTING..." and "STOPPING...".
  - "ERROR".
  - "Ready to go live" for stream, or "Idle".
- The primary button reads, depending on state (`Panel.qml` 685-700): "Starting
  in N...", "Starting...", "Stopping...", "Start buffer", "Resume" or "Stop" or
  "Stop stream", "Save replay", "Go live" or "Record".
- Countdown: the primary button shows "Starting in N..." while the countdown is
  pending. The number comes from the service (`Panel.qml` 181-186, 685-686).
- Paused: the pause row shows "Resume". Saving path: "Saving to:" followed by the
  recording file path (`Panel.qml` 744-756).
- Streaming: "Streaming to <platform> - <kbps> kbps CBR" in caption muted
  (`Panel.qml` 770-776). If no URL or key is set: "Set a stream URL and key below,
  then press Go live." (`Panel.qml` 779-786).
- Error: a banner in urgent at 0.16 alpha with the message and a dismiss mark
  (`Panel.qml` 794-830). The banner shows any non-empty error, not only the error
  state, so refusals such as a disk guard or a bad trim range are visible.

### 4.5 Bar indicator and popup

- Bar glyph per state (`BarWidget.qml` 221-233): idle video glyph in the bar
  foreground, record glyph in accent while recording, a pause glyph in muted
  while paused, a broadcast glyph in urgent while streaming, and no glyph in
  replay mode.
- While recording, the elapsed time sits next to the glyph and is hidden on a
  vertical bar (`BarWidget.qml` 311-318). In streaming mode, a "LIVE" word in
  urgent sits beside it (`BarWidget.qml` 321-328).
- Glyph colour changes over 160 ms (`BarWidget.qml` 301-304).
- Tooltip: "Recording - <elapsed>" with click hints. Update availability is
  appended to the tooltip (`BarWidget.qml` 235-240).
- Left-click toggles recording directly. Right-click opens the panel
  (`BarWidget.qml` 333-350). This is the reverse of reel and omarec, where
  left-click opens the panel.
- The count-up timer ticks once a second while recording or while the countdown
  is pending (`Panel.qml` 200-210, `BarWidget.qml` 270-275). The bar widget polls
  state every 5 seconds (`BarWidget.qml` 400-402).
- Recording OSD: a settings section labelled RECORDING OSD exposes "Show
  indicator" and "Position" (top-right, top-center, bottom-right) and says the
  indicator is "A small dot with the elapsed time, shown only while recording,
  streaming or buffering replay." (`Panel.qml` 1825-1885; options in `Config.js`
  84-85). The code that draws the OSD is not in these files.

### 4.6 Keyboard flow, shortcuts and focus

- Enter activates the primary action (`Panel.qml` 528-531, `onActivateRequested`
  calls `toggleRecording`).
- `s` saves a replay clip in replay mode (`Panel.qml` `onTextKey`).
- The key catcher is blocked while a number field or text field has focus, so
  typing an "s" does not trigger a shortcut (`Panel.qml` 536-545).
- Global hotkeys are documented in `README.md`: SUPER+ALT with R toggle, S save
  replay, P pause, O open the clip.
- No list cursor was found in these files. Keyboard use is limited to Enter and
  S.

### 4.7 Visual language

- Components come from the shared kit: Button (with a selected state and
  accent), ToggleSwitch, Dropdown, PanelSlider, PanelSectionHeader, and a
  PanelKeyCatcher (`Panel.qml`).
- Colours: foreground, accent, urgent, muted (`Panel.qml`, `root.muted`).
- Typography: title for the header, caption for labels and state, body for
  buttons (`Panel.qml` 554-590, 1388-1400).
- Error banner fill is urgent at 0.16 alpha (`Panel.qml` 797).
- Section headers are uppercase, unlike reel's rule.
- Motion is minimal: the glyph colour fades in 160 ms and there is a one-second
  timer for the clock.

### 4.8 Empty and unavailable states

- No recordings: "No recordings in the output folder yet." (`RecentRecordings.qml`
  51-52).
- No presets: "No presets yet - set the options how you like them, name it below
  and save." (`PresetsSection.qml` 117).
- Stream not configured: "Set a stream URL and key below, then press Go live."
  (`Panel.qml` 779-786).
- GPU detection: the hardware footer reads "Detecting..." until the probe
  returns, then "Detected" (`Panel.qml` 2490-2502).
- No monitor or no audio device: the dropdowns are simply empty. `audioDeviceOptions`
  returns an empty list with no placeholder text (`Panel.qml` 371-391).
- No region: "No region selected" (`Panel.qml` around 900-935).

### 4.9 Settings presentation

- Inline. Everything sits in one long panel as sections.
- Mode-specific sections are hidden by mode: stream fields appear only in stream
  mode, replay fields only in replay mode, and encoder fields are hidden in
  stream mode (`Panel.qml` 1055, 1256, 1466-2387 `visible: !root.isStream`).
- Presets are a separate section in POST-RECORDING. Each preset stores a named
  configuration, and "Apply", "Delete" and "Save current" act on it. Presets
  live in `~/.local/state/pix-recast/presets.json` so a plugin update keeps them
  (`README.md`; `PresetsSection.qml` 71-140).
- Platform defaults for streaming can be reset with a button labelled "Reset to
  <platform> defaults" (`Panel.qml` 1229).
- Advanced encoder settings sit behind a button toggle.

### 4.10 Notable points

- Clever: optimistic configuration updates. The panel shows the new value at
  once, keeps a pending map, and drops an override after 5 seconds if the
  service never confirms (`Panel.qml` 40-70).
- Clever: the tick timer runs only while a take or a countdown is up, and the
  displayed count only moves forward within a take (`Panel.qml` 200-212).
- Clever: stream keys are passed as environment variables, so they do not show in
  process lists or logs (`README.md`, Performance).
- Clever: the audio device dropdown merges hardware sources and per-application
  sources in one list.
- Clever: the primary button carries the countdown text, so no extra overlay is
  needed for the pre-roll.
- Bad: one 2632-line Panel with every section in one scroll region. The mode
  switch and the primary action scroll away with the settings.
- Bad: left-click starts or stops recording straight from the bar. Right-click
  opens the panel. This makes an accidental start easy.
- Bad: the RECORDING OSD exists as a setting but its rendering code is not in
  these files, so the setting cannot be verified from this checkout.
- Bad: no empty text for audio devices or monitors. The user sees an empty
  dropdown.
- Bad: the stream and replay sections are hidden by mode, which hides the
  settings a user may need to change before switching mode.

---

## Patterns worth adopting

1. Reel uses a single cursor state for hover and keyboard, so exactly one highlight is ever visible (reel, `docs/design.md` section 7).
2. Reel keeps the status, primary actions and settings tabs fixed while only the body scrolls, so layout never jumps (reel, `docs/design.md` section 5).
3. Reel closes its panel before the picker and during a take so the panel is not captured, and sexy-screenshot does the same with a configurable close delay (reel, `Panel.qml` 552-553; sexy-screenshot, `Panel.qml` `launch`).
4. Sexy-screenshot runs an action at once when its single-key hint is pressed, without moving the cursor first (sexy-screenshot, `Panel.qml` `runHint`).
5. Reel shows the countdown as a separate, non-focusable overlay that follows the recorder's state file and says "Recording starts", not "Recording" (reel, `Countdown.qml`, `docs/design.md` 6.12).
6. Reel's bar mark changes its shape per state while the clock slot is measured in advance, so nothing shifts when recording starts (reel, `docs/design.md` 6.1-6.2).
7. Omarec draws its live preview at the real footprint of the overlay, with the same proportions as the CLI geometry (omarec, `BarWidget.qml` `previewGeom`).
8. Omarec's LIVE pill is sized from its own text, so the bar width stays correct for any label and does not jitter (omarec, `BarWidget.qml` 56-59, 175-181).
9. Better-Recast applies setting changes at once and reverts them after 5 seconds if the service never confirms, so the panel does not lie for long (Better-Recast, `Panel.qml` 40-70).
10. Better-Recast stores named presets outside the plugin folder so an update never wipes them, and it lets a preset carry a saved region (Better-Recast, `README.md`, `PresetsSection.qml`).
11. Better-Recast lists hardware sources and per-application audio sources in one device dropdown, marking the app entries with "(app)" (Better-Recast, `Panel.qml` 371-391).
12. Better-Recast puts the countdown into the primary button text ("Starting in N...") instead of adding a second overlay (Better-Recast, `Panel.qml` 685-686).

Count: 12.

## Patterns to avoid

- Putting the whole panel in one scroll region, so the mode switch and the primary action scroll away with the settings (Better-Recast, `Panel.qml` 526-560).
- Left-click starts or stops a recording straight from the bar, with the panel only on right-click, which makes an accidental start easy (Better-Recast, `BarWidget.qml` 333-350).
- Reusing one key for two actions depending on state, and changing the list length while recording so rows move under the pointer (sexy-screenshot, `Panel.qml` 80-99).
- Hiding a whole block of settings when a feature is off, with no line saying why, and no empty-state text when a list has no entries (Better-Recast, `Panel.qml` 1556-1572; `audioDeviceOptions`).
- Advertising a setting whose rendering is not in the code (Better-Recast's RECORDING OSD, `Panel.qml` 1825-1885; the drawing code is absent from these files).
- A monolithic panel file of several thousand lines (reel, `Panel.qml` 3505 lines; Better-Recast, `Panel.qml` 2632 lines).
- Hiding a scrollbar and auto-scrolling at the edges with no visible cue (reel, `docs/design.md` section 7, "Scrolling").
- Offering settings only through a command line with no UI, and hiding a row silently when hardware is absent (sexy-screenshot, `README.md` "Settings"; `Panel.qml` webcam row).
- Using uppercase section labels in a plugin that otherwise uses sentence case (omarec, `BarWidget.qml` 362-660; reel's `docs/design.md` 4 forbids this).
