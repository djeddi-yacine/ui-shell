# MPRIS media control: media-controller-plugin, omarchy-sonora, omarchy-now-playing, Quickshell Mpris module

Study of three reference projects in `refs/` and the Quickshell MPRIS module in `refs/quickshell/`. Facts only, with file citations. Paths are relative to `refs/` in the repository root unless absolute. Line numbers refer to the files as checked out. No decisions are recorded here. No program was run and no network command was used. Preview images were viewed and described by eye only.

Note on the requested inputs: `media-controller-plugin` has `config/`, `screenshots/` (four PNGs) and `preview.png`; it has no `tests/` directory. `omarchy-sonora` has `preview.png` only. `omarchy-now-playing` has `extras/`, `cava.conf` and `preview.png`. None of the three ships tests. The Quickshell MPRIS directory has no tests and no `docs/` directory; `module.md` is its documentation.

Id prefixes: `MC` = media-controller-plugin, `SN` = omarchy-sonora, `NP` = omarchy-now-playing, `QS` = Quickshell MPRIS module.

---

## 1. media-controller-plugin ("Now Playing for Omarchy")

### 1.1 What it is and how it is wired

- **MC1.1** Plugin id `io.github.superb-striker.media-controller`, version `0.3.1`, MIT. Kinds `service` and `bar-widget`. `keepLoaded: true`. Entry points `Service.qml` (service) and `BarWidget.qml` (bar widget). `manifest.json` 2-17.
- **MC1.2** Description: "Artwork-first MPRIS controls with a hover preview, source switching, and track lists." `manifest.json` 8.
- **MC1.3** Bar widget schema: `width` (int, 0-400, default 0, "0 = automatic") and `fontSize` (int, 0-18, default 0). `manifest.json` 18-43.
- **MC1.4** The service is one instance shared by all bar instances: comment "Omarchy creates one service for all bar instances." `Service.qml` 6. The widget finds it with `bar.shell.serviceFor(moduleName)`. `BarWidget.qml` 8.
- **MC1.5** Files: `BarWidget.qml` (84 lines), `Preview.qml` (488 lines), `Service.qml` (364 lines), `manifest.json`, `README.md`, `config/mpv.conf`, `LICENSE`, `.gitignore` (ignores `__pycache__` and `*.py[cod]`).
- **MC1.6** The README says the plugin needs no extra packages: "the plugin uses Quickshell and the system's existing `busctl` for TrackList. It does not need Python, Rust, `playerctl`, or a separately installed backend." `README.md` 52-55. `playerctl` is named only in that README sentence; no `playerctl` call appears in the code of any of the three projects.

### 1.2 Data source

- **MC2.1** Live player list and state come from Quickshell: `Mpris.players.values` (`Service.qml` 13). Per-player properties (`isPlaying`, `trackTitle`, `trackArtist`, `trackAlbum`, `trackArtUrl`, `position`, `length`, `lengthSupported`, `canSeek`, `canGoNext`, `canGoPrevious`, `canPlay`, `canPause`, `canTogglePlaying`, `metadata`, `dbusName`, `identity`) are read in `rebuild()` (`Service.qml` 108-130).
- **MC2.2** TrackList is not in Quickshell. The README says so: "Because Quickshell does not expose MPRIS TrackList, the service reads that interface through the already-installed `busctl` and watches for changes." `README.md` 104-107. The code comment: "TrackList is absent from Quickshell's MPRIS API." `Service.qml` 299-300.
- **MC2.3** `busctl` calls (each is a separate `Process`, arguments as a list, no shell):
  - `get-property ... HasTrackList` (`Service.qml` 171-172).
  - `get-property ... Tracks` on `org.mpris.MediaPlayer2.TrackList` (242-243).
  - `call ... GetTracksMetadata ao N ids...` (256-258).
  - `get-property ... org.mpris.MediaPlayer2.Player Metadata` (277-278), used to find the current track id.
  - `GoTo` to jump to a track: `busctl --user call <dbusName> /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.TrackList GoTo o <id>` (150-152).
- **MC2.4** A long-running monitor: `busctl --json=short --user monitor --match=type='signal',path='/org/mpris/MediaPlayer2'` (`Service.qml` 301-305). It runs from startup (`running: true`, line 303). Each output line is parsed as JSON. A message on interface `org.mpris.MediaPlayer2.TrackList`, or a `PropertiesChanged` for that interface, schedules a queue refresh (307-315). If the process exits, a 2000 ms timer restarts it (317, 319-324).
- **MC2.5** mpv playlist: a Quickshell `Socket` to `MPV_SOCKET` or `/tmp/mpv-socket` (`Service.qml` 325-327). After connect it sends `observe_property` for `playlist`, `playlist-pos` and `path` (330-331). It parses `property-change` events (334-351). Connection is retried every 2000 ms while the active player is mpv (353-358). `Component.onCompleted` also connects when mpv (363).
- **MC2.6** Artwork: `trackArtUrl` from the player is used first (`Preview.qml` 125, 215). If it is empty and the track URL is a local `file://` path, the service probes sibling image files (see MC6.3).
- **MC2.7** Position: a 1000 ms `Timer` increments `positionTick` (`Service.qml` 223). While the active player is playing, that tick calls `rebuild()` (201). The widget also re-runs `rebuild()` on the player's own `positionChanged` (207).

### 1.3 Player selection

- **MC3.1** The list of "active" players is every player that is playing or paused: `players.filter(p => p.isPlaying || p.playbackState === Paused)` (`Service.qml` 14).
- **MC3.2** The shown player (`activePlayer`) is chosen in this order (16-21):
  1. The player whose `dbusName` equals `org.mpris.MediaPlayer2.` + `preferredSource`, if it is active.
  2. The first active player with `isPlaying`.
  3. The first active player (paused).
  4. `null`.
- **MC3.3** A user choice is "remembered for the current login session" (`README.md` 111). It is stored in a file `$XDG_RUNTIME_DIR/media-controller-plugin-selected` (`Service.qml` 218), written by `selectionFile.setText` (139), read on load (221). `watchChanges: false` (219).
- **MC3.4** Choosing a source: `select-source` returns early unless the player is in the active list (136). If the current player is playing, a different source is chosen, and it can pause, it is paused first (137). Then `preferredSource` and the file are set (138-139).
- **MC3.5** If the preferred player is no longer in `players` at all, the preference is cleared and the file is emptied (`Service.qml` 180-184). If it is present but not active, the preference stays set and selection falls back (16-21).
- **MC3.6** Duplicate labels: when two sources have the same label, the label becomes `label (name)` (115-116).
- **MC3.7** Switching the active player resets queue state and re-runs artwork probing (`Service.qml` 187-196).
- **MC3.8** The proxy player `playerctld` is not filtered out anywhere in `Service.qml`. It would appear in `sources` like any other player (112-119).

### 1.4 What the UI shows

- **MC4.1 Bar chip** (`BarWidget.qml`): a row of three transport glyphs plus the title area. Glyphs: previous `󰒮` (line 39), play/pause `󰏤` when playing and `󰐊` otherwise (44), next `󰒭` (49). The title area is the `Preview` item (53-60). The row spacing is `max(1, round(barSize / 13))` (36).
- **MC4.2 Bar title text** (`Preview.qml` 48-59): `title` plus ` - artist` when artist exists (52), `Text.PlainText` (51), elided right (57), font size `fontPx` (55). Opacity drops to 0.7 while the popup is open (58).
- **MC4.3 Hover preview** (`Preview.qml` 81-96): a `PopupWindow` with width 300 logical px (`hoverPopupWidth`, 24). The content: artwork area 118 dp tall, radius 14 dp (208-209); title in `Style.font.title` bold (250); artist in `Style.font.body`, or "Unknown artist" (258); the progress bar (277-295) and the five-button row (305-333) are shown too. Hidden in hover and shown only when pinned: source chips, album, times and the track list (see 4.4, 4.7, 4.8).
- **MC4.4 Pinned popup** (`Preview.qml` 462-470): width 340 (23), artwork area 164 px (208), title in `Style.font.heading` (250), album in `Style.font.caption` (265-275), elapsed/total times (296-304), full button row (305-333), track list (334-415).
- **MC4.5 Controls in the popup**: previous (38 px, glyph `󰒮`), back 10 s (36 px, glyph `−10`, compact text `Style.font.bodySmall` bold), play/pause (44 px filled circle, glyph size `dp(20)`), forward 10 s (36 px, `+10`), next (38 px, `󰒭`). `Preview.qml` 309-332, glyph sizes 432. The seek step is fixed at 10 (`Service.qml` 129, `Preview.qml` 312, 327). Disabled buttons have opacity 0.32 (425) and `enabled` follows `canGoPrevious`, `canSeek`, `canPlayPause`, `canGoNext`.
- **MC4.6 Progress bar**: 4 px tall, radius 2 (`Preview.qml` 279-280), shown only when `duration > 0` (279). Fill = `position / duration`, clamped (284). Clicking it seeks to `fraction * duration` (289-294, 453-455), only when `canSeek` (291).
- **MC4.7 Source chips**: a horizontal `Flickable` row, shown only when pinned and more than one source (`Preview.qml` 166-170). Chip height 22 px, radius 11, gap 6 (177, 181, 183). Selected chip: fill = foreground colour, text bold (184, 195). Click calls `select-source` (197-201).
- **MC4.8 Track list**: header "TRACK LIST (n)" with a chevron `󰅀` (collapsed) or `󰅃` (expanded) (`Preview.qml` 346-366, 363). Shown only when pinned and `hasQueue` (337). The list is collapsed by default (`queueExpanded: false`, line 36; reset on close, 477). Expanded height is `min(dp(180), count * dp(40))` (372). Rows are 38 px tall with radius 8 (379-380). The current track has a 3 px accent bar on the left and bold text (382-391, 403). Clicking a non-current row plays it: by track id when present (`play-track`), else by index (`play-index`) (406-412, 447-452).
- **MC4.9 Cover art**: the artwork is `Image` with `PreserveAspectCrop` (216), `asynchronous` and `cache` on (217-218). When no image is ready, a placeholder shows glyph `󰝚` at 48 px (227-231) and the text "No artwork" (234-238).
- **MC4.10 Backdrop**: when artwork is ready, the popup background is the artwork blurred with `MultiEffect` (`blur 0.85`, `blurMax 48`, `saturation 0.35`, `brightness -0.35`, `contrast 0.08`, 131-141). A black overlay `#59000000` covers it (143-147). Text colour becomes white (38). Without artwork the background is `#161616` or the bar background (39), and text is the bar foreground (38).
- **MC4.11 Volume**: none. No volume control appears in the three files.
- **MC4.12 Shuffle and loop**: none. `Service.qml` does not read `Shuffle` or `LoopStatus`.
- **MC4.13 Visualizer**: none.
- **MC4.14 Lyrics**: none.
- **MC4.15 Per-player icons**: none. Sources are shown as text chips only. The label is `identity` or `desktopEntry` or the dbus name fragment (`Service.qml` 55-57).

### 1.5 Layout and visual language

- **MC5.1** Scale: all sizes go through `dp(v) = max(1, round(v * layoutScale))` (`Preview.qml` 26). `layoutScale = max(fontPx / 12, Style.font.body / 12, barSize / 26)` (16).
- **MC5.2** Font size for the bar text: `settings.fontSize` if above 0, else `max(1, Style.font.body - 1)` (15).
- **MC5.3** Automatic title width: `min(dp(150), availableWidth * 0.10)` (21), where `availableWidth` is the host window width (19-20). A non-zero `settings.width` overrides it (22).
- **MC5.4** Popup corners: radius `dp(18)` (114), border `dp(1)` in `Qt.alpha(popupForeground, 0.16)` (116-117). Padding `dp(16)` (164). Column spacing `dp(12)` pinned, `dp(10)` hover (165).
- **MC5.5** Colour tokens are the shell's `bar.foreground`, `bar.background`, `bar.fontFamily`, `Style.font.{body, bodySmall, caption, heading, title}`, `Style.bar.sizeHorizontal`. Literal colours: `white`, `#161616`, `#59000000`. Alpha values used with `Qt.alpha`: 0.07, 0.10, 0.13, 0.14, 0.16, 0.36-0.78 (for text tiers 0.4, 0.42, 0.5, 0.58, 0.7, 0.72, 0.78).
- **MC5.6** Hover and pinned differ in size only: title heading vs title, artwork 118 vs 164, popup width 300 vs 340 (`Preview.qml` 23-24, 208, 250).

### 1.6 Keyboard and mouse

- **MC6.1** Bar title area: enter opens the hover preview (`Preview.qml` 66-69). Exit schedules close after 240 ms (70, 72-80, 459-461). Pointing-hand cursor (65).
- **MC6.2** Click on the title area or the popup pins it (`openPinned`, 155-157, 462-470). Pinning requests the bar popout slot (466-467). Unpinning releases it (473-474).
- **MC6.3** Escape closes the pinned popup (`Keys.onEscapePressed`, line 120). Clicking outside closes it through `HyprlandFocusGrab` (106-110; `onCleared` line 109). `grabFocus` is on while pinned (97). The `HyprlandFocusGrab` is Hyprland-specific: `import Quickshell.Hyprland` (line 6).
- **MC6.4** Transport buttons in the bar: left click only, through `MouseArea` (`BarWidget.qml` 77-82).
- **MC6.5** No scroll wheel handler, no middle-click handler, no right-click handler appear in `BarWidget.qml` or `Preview.qml`.
- **MC6.6** No keyboard shortcuts are defined beyond Escape.

### 1.7 Config options

- **MC7.1** Two settings: `width` and `fontSize`, both default 0 (automatic) (`manifest.json` 24-27, 28-43). `README.md` 79-84 says to remove or zero old explicit values such as 180/12.
- **MC7.2** mpv: optional `config/mpv.conf` sets `input-ipc-server=/tmp/mpv-socket` and `cover-art-auto=exact` (`config/mpv.conf` 1-3). `README.md` 86-100 explains the socket and `MPV_SOCKET`.
- **MC7.3** No IPC handler. `Service.qml` has no `IpcHandler`.

### 1.8 Idle cost

- **MC8.1** Always-on `Timer` at 1000 ms (`Service.qml` 223, `running: true`). Each tick increments a number. `rebuild()` runs on each tick only while the active player is playing (201). Cost when nothing plays: one timer wake per second with a counter change.
- **MC8.2** Always-on `busctl --user monitor` process on all signals under `/org/mpris/MediaPlayer2` (`Service.qml` 301-305). Each line is parsed as JSON in JS (307-308).
- **MC8.3** mpv reconnect `Timer` at 2000 ms, only while the active player is mpv (353-358). The timer is `running: root.isMpv`.
- **MC8.4** Queue refresh: a 180 ms debounce `Timer` (224) starts a chain of up to four `busctl` processes (161-175, 242-279). It runs on track or metadata changes of the active player (`Service.qml` 204-205) and on any TrackList signal from the monitor (314).
- **MC8.5** Artwork probing: a single `Image` element is pointed at up to 45 candidate URLs in turn (39-40, 84-91, 225-232). It is only active when there is no `trackArtUrl`.
- **MC8.6** Bar rebuild on each position tick while playing (`Service.qml` 201), and on player property signals (204-214).

### 1.9 Error and empty states

- **MC9.1** No player: `emptyState()` sets `available: false` (`Service.qml` 44-49, 110). The bar widget is `visible: hasPlayer` (`BarWidget.qml` 29), width 0 (30). The preview is also hidden (`Preview.qml` 44-45).
- **MC9.2** Player with no title: the title falls back to `label(p)` (`Service.qml` 123; 55-57). The popup shows "Unknown artist" when there is no artist (`Preview.qml` 258). Album is hidden when empty (269).
- **MC9.3** Invalid JSON from `busctl` or the mpv socket: `console.warn` and `null` returned (`Service.qml` 50-53). Missing or wrong `type` in the reply ends the chain (238-240, 251-252, 266-267).
- **MC9.4** A non-zero exit from any `busctl` step ends the chain and the queue stays empty (238-240, 250-252, 265-267, 285-296).
- **MC9.5** A track without a title in the track list falls back to the URL basename or "Unknown track" (`Service.qml` 272-273, 341).
- **MC9.6** Duration unknown: `durationFor` returns the last known length for the same source and track, else 0 (92-107). With duration 0 the progress bar hides (`Preview.qml` 279).
- **MC9.7** Seek is refused when `canSeek` is false or duration is 0 (`Preview.qml` 453-458; `Service.qml` 146-147).
- **MC9.8** Player closed mid-selection: the `Connections` on `activePlayer` are re-bound when the active player changes (`Service.qml` 202-215).
- **MC9.9** Popup closes if the source stops being eligible (`Preview.qml` 47).

### 1.10 Security and privacy facts

- **MC10.1** Shell-outs: `busctl` only (see MC2.3, MC2.4). Arguments are passed as an array, so no shell is involved (`Service.qml` 150-151, 171-172, 242-243, 256-258, 277-278, 301-305).
- **MC10.2** Track ids used in `GoTo` must appear in the list the service read (`Service.qml` 148-149). The `play-index` path rejects non-integers and out-of-range values (153-155).
- **MC10.3** Artwork from the player's `trackArtUrl` (and from `file://` probing) is loaded by the `Image` element (`Preview.qml` 125, 215). The code does not check the URL scheme for that path. Remote URLs would load through Qt's image loader; the code does not restrict this.
- **MC10.4** Local file probing: only when the track URL is a `file://` path or a plain absolute path. The candidate file names are built from the track file's directory and stem plus fixed names (`Service.qml` 58-62, 71-91). Paths are split and each segment is `encodeURIComponent`-ed (89).
- **MC10.5** The mpv socket default is `/tmp/mpv-socket` (`Service.qml` 327). The client writes JSON commands to whatever socket is at that path (156-158).
- **MC10.6** The selected source name is stored in `$XDG_RUNTIME_DIR` (or `/tmp` if unset) (`Service.qml` 218).
- **MC10.7** Track titles and artists are displayed with `Text.PlainText` (`Preview.qml` 51, 190, 246, 257, 267, 398), so markup in metadata is not interpreted.

### 1.11 Tests and previews

- **MC11.1** No automated tests. The README lists two checks: `omarchy plugin validate .` and `qmllint -I /usr/share/omarchy/shell BarWidget.qml Preview.qml Service.qml` (`README.md` 115-120).
- **MC11.2** Previews: `preview.png` (713x523) shows the hover preview over a wallpaper: artwork, title "Doechii - STANKAPOO (Audio)", artist, a progress bar at about 89 %, and a white pause disc with -10 / +10 buttons. `screenshots/compact-bar.png` (678x40) shows the bar chip at its compact size: prev, pause, next glyphs, then the title. `screenshots/kew-track-list.png` (694x1080) shows the pinned popup with source chips "kew" (selected) and "Firefox", the artwork, progress 0:24 / 2:01, a play button, and an expanded "TRACK LIST (20)" with the first row highlighted. `screenshots/firefox-source.png` (686x715) shows the pinned popup with Firefox selected, a video thumbnail, title "You installed Omarchy, Now Wh..." and time 0:05 / 18:28. `screenshots/hover-preview.png` is the same file size as `preview.png` (322839 bytes); it was not separately described.

### 1.12 Code quality facts

- **MC12.1** Three QML files: `Service.qml` 364 lines, `Preview.qml` 488 lines, `BarWidget.qml` 84 lines (plus `manifest.json`).
- **MC12.2** `Service.qml` holds state, shell-outs, the mpv socket, the artwork probe and the action dispatcher in one `Item`. Actions are dispatched by string in `send()` (`Service.qml` 131-160).
- **MC12.3** Layout code in `Preview.qml` is one large `PopupWindow` with inline `component` definitions (`MediaButton`, line 419).

---

## 2. omarchy-sonora

### 2.1 What it is and how it is wired

- **SN1.1** Plugin id `io.github.tasosk7.sonora`, version `0.1.0`, MIT. Description: "A Sonora-styled mini player for the bar: animated waveform, cover art, and a Now Playing card with seek, shuffle, repeat and volume, over MPRIS." `manifest.json` 3-8.
- **SN1.2** Kinds `service` and `bar-widget`, `keepLoaded: true`, entry points `Service.qml` and `BarWidget.qml`. `manifest.json` 9-17.
- **SN1.3** Bar widget defaults and schema (`manifest.json` 24-70): `maxLabelWidth` 180 (integer, 60-600, step 10); `hideWhenUnavailable` true; `showArtist` true; `showCover` true; `showProgress` true.
- **SN1.4** Service is one shared `Item` (`Service.qml` 6-8). The widget reads it with `bar.shell.serviceFor(moduleName)` (`BarWidget.qml` 16).
- **SN1.5** The widget reads its own config entry from `bar.shell.barConfig` first, then falls back to injected `settings` (`BarWidget.qml` 25-50), with a comment about plugin reloads (25-29).
- **SN1.6** Files: `Service.qml` 292 lines, `BarWidget.qml` 844 lines, `manifest.json` 72 lines, `README.md` 94 lines, `preview.png`, `LICENSE`. No tests, no config directory.
- **SN1.7** The README says: "No other dependencies: playback state and controls go through the MPRIS player Sonora already registers on the session bus." `README.md` 27-28.

### 2.2 Data source

- **SN2.1** Quickshell `Mpris.players.values` (`Service.qml` 16). Derived state: `available`, `playing`, `title`, `artist`, `album`, `artUrl`, `hasTrack`, `length`, `position`, `canSeek`, `canNext`, `canPrevious`, `volume`, `volumeSupported`, `shuffleSupported`, `loopSupported` (36-55).
- **SN2.2** `length` and `position` return 0 unless `lengthSupported` / `positionSupported` (44-45). `canSeek` also requires `length > 0` (46).
- **SN2.3** Shuffle and loop are not read from Quickshell. The service reads them over D-Bus with `busctl` (`Service.qml` 57-60, 71-90). The comment says Sonora "doesn't emit PropertiesChanged for Shuffle or LoopStatus, so the values cached by Quickshell's MPRIS client go stale." (57-60). This is the project's claim; see Section 8 for what was not verified.
- **SN2.4** Shuffle and loop writes: `Quickshell.execDetached` with `busctl --user set-property <bus> /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player <name> <type> <value>` (`Service.qml` 106-110).
- **SN2.5** Volume: Quickshell's `player.volume` setter (`Service.qml` 218-224). Sonora's own player volume, not system volume (`BarWidget.qml` 802).
- **SN2.6** Position: Quickshell's `position`, plus a 1 s nudge (see SN8.3).
- **SN2.7** Cover art: `player.trackArtUrl` (`Service.qml` 41), passed to `Image` as `source` (`BarWidget.qml` 310, 509, 639).

### 2.3 Player selection

- **SN3.1** Single-player service: `findPlayer(players)` returns the first player for which `isSonora()` is true (`Service.qml` 29-34). `isSonora` is true when the dbus name starts with `org.mpris.mediaplayer2.sonora`, or identity is `sonora`, or desktop entry is `sonora` (19-27).
- **SN3.2** No switching between players. No remembered selection. Other players are ignored.
- **SN3.3** When Sonora is not running, `available` is false and the bar widget is hidden by default (`BarWidget.qml` 70; `manifest.json` 26 `hideWhenUnavailable: true`).

### 2.4 What the UI shows

- **SN4.1 Bar** (`BarWidget.qml` 299-409): in order, a cover thumbnail (only when `showCover`, Sonora running, art URL set, and not vertical; 304-312), a five-bar waveform (314-326), and a title row (328-408). Title is bold `Style.font.body`, the artist follows in a dimmer colour (342-358). The artist is hidden when `showArtist` is false (354).
- **SN4.2 Bar waveform**: five bars, base heights `[0.3, 0.64, 1.0, 0.64, 0.3]` (`BarWidget.qml` 99). Animated while playing and the card is closed (`active: root.playing && !root.popupOpen`, 320). Each bar bounces with its own duration (116, 121). Settles back in 220 ms when stopped (131).
- **SN4.3 Bar progress**: a 2 px hairline under the widget, shown when `showProgress`, Sonora running, not vertical, card closed, and length > 0 (412-430). Its fill has a 900 ms width behaviour (428).
- **SN4.4 Title scrolling** (marquee): text wider than `maxLabelWidth` scrolls. A pause of 1800 ms, a scroll at about 28 ms per px (minimum 2000 ms), a pause, and back (373-393, 382, 390). A gradient fades the clipped right edge (397-407).
- **SN4.5 Card** (`BarWidget.qml` 463-843): a `PopupCard` with fixed content width `Style.space(300)` (470). Contents from top:
  - Header: a white circle with a black mini waveform, the label "NOW PLAYING" / "PAUSED" / "SONORA" (571), and a glyph button `󰏌` that focuses Sonora (580-590).
  - Large art with a soft drop shadow and rounded corners `Style.space(10)` (594-650). Placeholder waveform when there is no art (618-633).
  - Title in `Style.font.subtitle` bold, centred (653-667); artist in `Style.font.body` (669-679). Title says "Sonora is not running" when unavailable (661), artist line says "Click the art to launch it" (673).
  - Scrubber (683-720): slim slider, elapsed time on the left, remaining time with a leading minus on the right (701-718).
  - Transport (723-800): shuffle glyph `󰒞` or `󰒝` with a dot when on (727-736); previous `󰒮` (742-747); white disc 48 px with `󰏤` or `󰐊` (750-779); next `󰒭` (781-786); repeat glyph `󰑖` or `󰑘` (track) with a dot when on (789-799).
  - Volume row (803-840): icon `󰝟` at 0, `󰖀` below 0.5, `󰕾` otherwise (812); slider; percent text (829-839). Shown only when `volumeSupported` (806).
  - Backdrop: the cover art blurred (`blur 1.0`, `blurMax 64`, `saturation 0.15`, `opacity 0.55`) over base `#0e0e0e` and a gradient of black at 0.35 / 0.5 / 0.78 (481-533). Source is decoded at 256x256 (`sourceSize`, 512-513).
- **SN4.6 Visualizer**: the five bars in the logo are the only "visualizer" (not a spectrum analyser). It is animated, not driven by audio data.
- **SN4.7 Shuffle/loop**: shuffle is a toggle; loop cycles none, playlist, track (`Service.qml` 234-239; the card glyph shows track vs not, `BarWidget.qml` 792-797).
- **SN4.8 Lyrics, track list, source list, per-player icons**: none.

### 2.5 Layout and visual language

- **SN5.1** Spacing via `Style.space(n)` throughout (for example `Style.space(14)` at `BarWidget.qml` 71, `Style.space(7)` at 302, `Style.space(18)` card inset at 477, `Style.space(300)` card width at 470, `Style.space(48)` play disc at 753).
- **SN5.2** Fonts: `Style.font.body` (bar), `Style.font.subtitle` (title in card), `Style.font.caption` (times, 574), `Style.font.iconLarge` (glyph buttons, 255), `Style.font.body + 2` (shuffle, loop, 785-794). The card uses `textFont`: "Inter" if installed, else bar font (59-60).
- **SN5.3** Literal colours: `#ffffff` (disc, thumb, knob), `#000000` (glyph in the logo), `#0e0e0e` (backdrop base), `rgba(1,1,1,0.66)` for idle glyphs (271), `rgba(1,1,1,0.55)` for times (706). Bar colour: `root.bar.barForeground` when playing, `Qt.darker(..., 1.6)` when not (321).
- **SN5.4** Slim slider: track 3 px, 5 px when hovered (196); knob 12 px (210-211); hit area extended 4 px above and below (224-225); hover animation 120 ms (199, 218).
- **SN5.5** Glyph button: hover scale 1.08, pressed 0.9, 90 ms scale animation (272-273).
- **SN5.6** Disabled controls: opacity 0.3 (263) or 0.35 for the disc (757).

### 2.6 Keyboard and mouse

- **SN6.1** Bar (`BarWidget.qml` 432-459): left click play/pause (449); if Sonora is not running, left click focuses or launches Sonora (444-446). Middle click: next (448). Right click: toggles the card (439-441). Wheel up: previous; wheel down: next (451-455). Hover shows a tooltip with the summary (456-458). Pointing-hand cursor (435).
- **SN6.2** Card: click the art or the top-right glyph focuses Sonora and closes the card (`BarWidget.qml` 586-589, 645-648).
- **SN6.3** Scrubber: drag to scrub; the seek is sent on release only (`BarWidget.qml` 233-246, 694). Position text shows the drag value while dragging (705, 714).
- **SN6.4** Volume: drag sends `setVolume` on each move (`BarWidget.qml` 826, `Service.qml` 218-224).
- **SN6.5** No keyboard handler in the card. Keys are only reachable through the IPC handler (see SN7).

### 2.7 Config options

- **SN7.1** The five settings in SN1.3 (`manifest.json` 24-70). `README.md` 63-90 describes changing them with `omarchy bar set`, or by editing `~/.config/omarchy/shell.json`.
- **SN7.2** IPC target `sonora` (`Service.qml` 275-291): `status` (JSON), `playPause`, `play`, `pause`, `stop`, `next`, `previous`, `seek <seconds>` (relative), `volume <0-100>`, `shuffle`, `repeat` (returns the new loop mode), `focus`, `ping`. Replies are `"ok"` or `"unavailable"`, except `status` and `repeat`.
- **SN7.3** `README.md` 48-61 lists the same commands and a `shell toggle` for the card.

### 2.8 Idle cost

- **SN8.1** `Timer` every 3000 ms, `triggeredOnStart: true`, running while Sonora is available (`Service.qml` 92-98). Each tick runs `refreshOptions()` (71-74), which starts `busctl get-property Shuffle LoopStatus` unless the previous one is still running (72). So a `busctl` child process starts every 3 s while Sonora runs.
- **SN8.2** Settle `Timer` 250 ms after a write (100-104, 109).
- **SN8.3** Position nudge: `Timer` every 1000 ms, running while playing and position is supported, calls `player.positionChanged()` (`Service.qml` 112-119). Comment: "MPRIS doesn't push position updates while playing; nudge the binding once a second so progress displays keep moving." (112-113).
- **SN8.4** OSD wait `Timer` 120 ms, up to 10 attempts (`Service.qml` 140-156).
- **SN8.5** Waveform animations run only while playing and the card is closed (`BarWidget.qml` 320, 564, 631).
- **SN8.6** Marquee animation runs while text is wider than the clip and the card is closed (360-361, 373-393).
- **SN8.7** Child processes: `busctl` (polling and writes), `omarchy-launch-or-focus` (focus, `Service.qml` 243), and `shell.summon("omarchy.osd", ...)` for OSD (130).

### 2.9 Error and empty states

- **SN9.1** Not running: `available` false, card says "Sonora is not running" (`BarWidget.qml` 661); bar widget hidden if `hideWhenUnavailable` (70); clicking the bar focuses or launches Sonora (444-446).
- **SN9.2** Track without title: "Nothing playing" in the card (`BarWidget.qml` 661). Bar label is empty and hidden (`Service.qml` 38; `BarWidget.qml` 334).
- **SN9.3** No art: placeholder waveform in the card (618-633) and no thumbnail in the bar (311).
- **SN9.4** Shuffle or loop not supported: buttons greyed (`BarWidget.qml` 734, 797). Volume row hidden (806).
- **SN9.5** No length: scrubber hidden (`BarWidget.qml` 686), progress line hidden (413).
- **SN9.6** `busctl` reply parse: fewer than two lines leaves the state as it was (`Service.qml` 82-83). Loop text is matched with `indexOf` (86-87).
- **SN9.7** `busctl` failures are not reported. `Process` stdout is collected and ignored when short (80-89).
- **SN9.8** Summary when no title: "Sonora" or "Sonora is not running" (`Service.qml` 123-124).

### 2.10 Security and privacy facts

- **SN10.1** `busctl` and `omarchy-launch-or-focus` are invoked through `Process` and `Quickshell.execDetached` with argument arrays (`Service.qml` 78, 107-109, 243). No shell string.
- **SN10.2** Bus name for writes is `player.dbusName` when present, else the constant `org.mpris.MediaPlayer2.sonora` (62-63).
- **SN10.3** Art URL is used as `Image.source` without checks (`BarWidget.qml` 310, 509, 639). The code does not restrict it to local paths.
- **SN10.4** Text is shown with `Text.PlainText` (`BarWidget.qml` 343, 352, 570, 660, 672).

### 2.11 Tests and previews

- **SN11.1** No tests. No lint or validation command is documented.
- **SN11.2** `preview.png` (73249 bytes, 520x880) shows, at the top centre, a small pink-outlined bar chip with a thumbnail, the waveform, "EARNË IT" in bold and "Yeat" dimmer. Below, the Now Playing card: header "NOW PLAYING" with the logo and an open glyph, large grey blurred-art cover, title "EARNË IT", artist "Yeat", progress line near the middle, times "1:12" and "-1:18", shuffle (with dot), previous, a white pause disc, next, repeat (off glyph), and a volume slider at 67 %.
  - Note: `README.md` 7 embeds `preview.png` as "The Sonora bar widget and its Now Playing card".

### 2.12 Code quality facts

- **SN12.1** `Service.qml` 292 lines; `BarWidget.qml` 844 lines, which includes four inline `component` definitions (`Waveform` 79, `RoundedArt` 140, `SlimSlider` 175, `GlyphButton` 252). The card is about 380 lines of the widget file (463-843).
- **SN12.2** Actions are dispatched through `runAction(name, showFeedback)` (`Service.qml` 167-200) and an IPC handler that calls the same functions.
- **SN12.3** Inline comments explain intent for most non-obvious choices (for example 58-60, 136-137, 202-203).

---

## 3. omarchy-now-playing ("Media Now Playing")

### 3.1 What it is and how it is wired

- **NP1.1** Plugin id `mrjohnnycake.now-playing`, version `1.0.0`, MIT. Description: "Omarchy MPRIS now playing bar plugin with cava visualization." `manifest.json` 3-8.
- **NP1.2** Kinds `service` and `bar-widget`, `keepLoaded: true`, entry points `Service.qml` and `BarWidget.qml` (`manifest.json` 9-17). `omarchy.clonedFrom: "omarchy.media"` (24-26). Bar widget `allowMultiple: false` (22). No settings schema.
- **NP1.3** The README says it "replaces Omarchy's built-in Media bar widget with a keyboard-first version" (`README.md` 7-9). "Enabling Media Now Playing puts it in the built-in Media widget's place in the bar and switches off the built-in media service" (42-44).
- **NP1.4** The bar widget reads its service with `bar?.shell?.firstPartyServiceFor("omarchy.media")` (`BarWidget.qml` 11). The plugin's own `Service.qml` is not referenced by that name in the widget. How the two are connected is not shown in these files (see Section 8). The shell-side lookup exists in `refs/omarchy/shell/shell.qml` 907-911 (`serviceFor`, `firstPartyServiceFor`).
- **NP1.5** Files: `Service.qml` 523 lines, `BarWidget.qml` 467 lines, `MediaModel.js` 142 lines, `cava.conf` 20 lines, `extras/media-key.sh` 73 lines, `README.md` 146 lines, `manifest.json`, `preview.png`, `LICENSE`. No tests.
- **NP1.6** `MediaModel.js` has a CommonJS export block (`MediaModel.js` 122-141) that is guarded by `typeof module !== "undefined"`. No test uses it in this repo.
- **NP1.7** Prerequisite: `cava`, "which draws the visualizer. It isn't installed with Omarchy by default" (`README.md` 29-34).

### 3.2 Data source

- **NP2.1** Players: `Mpris.players.values` (`Service.qml` 17).
- **NP2.2** Audio streams: `Pipewire.nodes.values` (18). A node is a playback stream when `isStream` is true and it matches `isPlaybackStream` (`MediaModel.js` 37-45) and `audio` is set (`Service.qml` 19-26). `PwObjectTracker { objects: root.playbackStreams }` (456) keeps those nodes tracked.
- **NP2.3** Matching a player to a stream: both labels are normalised (lower case, prefixes `pipewire alsa [` and `alsa playback [` removed, non-alphanumerics removed) (`MediaModel.js` 47-54), then a substring match in either direction (74-89). The stream label is `application.name`, else node description, else `media.name`, else `node.name` (56-64).
- **NP2.4** cava: `cava -p <plugin>/cava.conf` as a `Process`, running only while the active player is playing and the bar is not vertical (`BarWidget.qml` 73-94, 75). Output is parsed line by line (78-86).
- **NP2.5** Player-derived fields: title, artist, album, `trackArtUrl`, `identity` / `desktopEntry` (`Service.qml` 31-35).
- **NP2.6** Position: Quickshell `position` and `length`, with a 1 s polling `Timer` (see NP8.2).
- **NP2.7** Desktop entries for icons: `DesktopEntries.byId`, `DesktopEntries.heuristicLookup`, and a case-insensitive name match over `DesktopEntries.applications` (`BarWidget.qml` 47-60). Icon path through `bar.shell.appLibrary.iconSource` when present (65), else `Quickshell.iconPath` (66-69).

### 3.3 Player selection

- **NP3.1** Every player with metadata (`hasMetadata`: title, artist, identity or desktop entry) is a "source" (`MediaModel.js` 7-9; `Service.qml` 131-149). Sources are sorted: playing first, then non-proxy before proxy, then play-start order for playing players, then label (`Service.qml` 138-146).
- **NP3.2** Play-start order: `syncPlayingOrder()` gives each newly playing player a serial number, and keeps it while it plays (`Service.qml` 104-129). It is re-run on `onPlayersChanged` (438) and by one `Connections` per player on `isPlayingChanged` (440-447). The comment says this replaces a 500 ms poll (433-436).
- **NP3.3** The active player (`selectActivePlayer`, `Service.qml` 194-232):
  1. If the user-preferred player is playing and has metadata, it wins (211, 228).
  2. Otherwise the oldest playing player that has a playback stream (`oldestPlayingPlayer(true)`, 166-192), non-proxy first, then a proxy.
  3. Otherwise the oldest playing player without a stream (`oldestPlayingPlayer(false)`).
  4. Otherwise the preferred player, a stream player, a track-metadata player, a controllable player, or an identity-only player, in that order (231).
- **NP3.4** The preferred player is stored in memory as `preferredPlayerKey` (`Service.qml` 12). It is set by `runAction` (427), by `switchSource` (336), and by `selectPlayer` (287-292). It is cleared when that player disappears (125). Nothing writes it to a file.
- **NP3.5** Player key is `dbusName`, then desktop entry, then identity (`MediaModel.js` 91-94).
- **NP3.6** Source switching: `switchSource(delta, transferPlayback)` steps through `sourceCyclePlayers` (players that have metadata and are playing or can play, `MediaModel.js` 29-31; `Service.qml` 151-164) with wrap-around (`Service.qml` 316-349). With transfer, if the current player was playing, the next one is started and the current one paused (338-342).
- **NP3.7** A proxy player (`playerctld`) is detected by dbus name or desktop entry (`MediaModel.js` 1-5) and ordered last. It is not excluded from sources.
- **NP3.8** Actions target the active player unless another is needed: `playerForAction` returns the targeted key first, then for pause/playPause the oldest playing player, then the active player if it can handle the action, then the first source that can (`Service.qml` 351-368).

### 3.4 What the UI shows

- **NP4.1 Bar** (`BarWidget.qml` 131-202): play/pause glyph `󰏤` or `󰐊` (136-148; colour bar foreground when playing, darker 1.5 when not, 141), the playing app's icon (14 px, 151-168), then the title with a scrolling label (170-201).
- **NP4.2 Bar label text**: `title + "  ·  " + artist` (`BarWidget.qml` 181). Label is `Text.PlainText` (180). The label scrolls continuously, even when it fits (187-199). Scroll speed is about 15 ms per px (193). Width capped at `maxLabelWidth` 180 (23, 172).
- **NP4.3 Bar underline**: 2 px high bar under the label showing progress, accent fill, background at 0.2 opacity (204-225). Shown when `hasProgress` (length supported and above zero, 25, 210).
- **NP4.4 Cava visualizer**: 16 vertical bars drawn behind the label (`BarWidget.qml` 73, 101-129). Layer opacity 0.35 (108). Bar fill `Color.accent` (123). Bar height = level from cava, animated 60 ms (120, 125). Shown when cava has levels (107). The levels are normalised 0-100 to 0-1 (83).
- **NP4.5 Popup** (`BarWidget.qml` 238-466), width `Style.space(320)` (244):
  - Row: 64 px square art (`BorderSurface`, 256-261) with the track art or a 󰝚 glyph at `Style.font.displayLarge` (272-279); title in `Style.font.subtitle` bold, elided (286-295); artist in `bodySmall` (297-306); album in `caption` (308-317).
  - Progress: 4 px bar with accent fill (327-344); elapsed and total in `caption` (346-368). Shown when `hasProgress` (325).
  - Source list (371-464), shown when more than one source: a separator (371-374), then a row per source (385-462) with a play/pause glyph (412), the source's app icon 20 px (421-431), title (438-447, bold when selected, 444) and a detail line with artist or identity (449-458). The selected row has a selected fill and border (398-399).
- **NP4.6 Key colour tokens**: `root.bar.foreground`, `root.bar.barForeground`, `Color.accent`, `Style.selectedFillFor`, `Style.normalFillFor`, `Border.controlSpec`, `Border.none()`. Font: `root.bar.fontFamily`.
- **NP4.7 Shuffle and loop**: none.
- **NP4.8 Volume and seek controls**: none in the popup. Seek is not offered.
- **NP4.9 Lyrics, track list**: none.

### 3.5 Layout and visual language

- **NP5.1** Bar: `implicitHeight: barSize` (`BarWidget.qml` 98). Row spacing `Style.space(6)` (134). Glyph and label `Style.font.body` (143, 184). Icon 14 px (`Style.space(14)`, 159-160).
- **NP5.2** Visualizer and underline are placed by reading `row` and `scrollClip` geometry (103-107, 205-210).
- **NP5.3** Popup spacing `Style.space(10)` (250), art 64 px, progress bar 4 px.
- **NP5.4** No literal colour values in the widget; all colours come from `bar` and `Color`/`Style` tokens. The cava bar colour is `Color.accent` (123).
- **NP5.5** The popup width is `contentWidth: popup.fittedContentWidth(Style.space(320))` (244).

### 3.6 Keyboard and mouse

- **NP6.1** Left click on the widget toggles the dropdown (`BarWidget.qml` 231-233). Right click and middle click are not accepted (`acceptedButtons: Qt.LeftButton`, 231).
- **NP6.2** Hover shows a tooltip "title — artist" (234). Leave hides it (235).
- **NP6.3** The README says: "Keyboard first: the only mouse action is opening the dropdown. Play/pause, next, previous and source switching are left to your keybinds." (`README.md` 22-23).
- **NP6.4** Keybind path: `omarchy-shell media <action>`, with the action names `playPause`, `next`, `previous`, `play`, `pause`, `sourceNext`, `sourcePrevious`, `sourceSwitch`, `sourceSwitchPrevious`, `status`, `ping` (`Service.qml` 476-522). Replies are `"ok"` or `"unhandled"`, except `status` (JSON) and `ping`.
- **NP6.5** Standalone key script `extras/media-key.sh` (see NP10.3): actions `playPause|next|previous|sourceSwitch|sourceSwitchPrevious` (`media-key.sh` 7, 11).
- **NP6.6** Keybind example in the README binds `XF86Audio*` keys to `mediaKey .. " next"` etc. (`README.md` 76-98).
- **NP6.7** Source rows in the popup have no click handler (`BarWidget.qml` 385-462 contains no `MouseArea`). `selectPlayer` exists in `Service.qml` (287-292) but no widget code calls it. The README says the dropdown lists "Every open media source, with its app icon and the active one highlighted" (`README.md` 20-21); it does not say rows are clickable.

### 3.7 Config options

- **NP7.1** None in the manifest. `manifest.json` has no `schema`.
- **NP7.2** Visualizer settings in `cava.conf` (bars 16, framerate 30, autosens 1, input pipewire, source auto, raw output to `/dev/stdout`, ASCII, `;` as the bar delimiter, newline frame delimiter, mono; `cava.conf` 4-20).
- **NP7.3** Hard-coded values in `BarWidget.qml`: `cavaBarCount: 16` (73), `opacity: 0.35` (108), `maxLabelWidth: 180` (23). The README says these are edited in the file (`README.md` 111-113).
- **NP7.4** Edits are overwritten by `omarchy plugin update` (`README.md` 115).

### 3.8 Idle cost

- **NP8.1** Cava process: runs while the active player is playing and the bar is horizontal (`BarWidget.qml` 75, 88-94). Stops on pause. Output is read continuously while it runs (92).
- **NP8.2** `Timer` 1000 ms, `triggeredOnStart`, running while there is progress and the active player is playing (`BarWidget.qml` 38-45). It calls `positionChanged()` (44). Comment: "MPRIS position is not pushed; poll it while playing for the bar underline and dropdown." (38).
- **NP8.3** Scroll animation: `NumberAnimation` on `labelText.x`, runs continuously while the label has text, the popup is closed and the bar is horizontal (187-199).
- **NP8.4** Track OSD `Timer` 120 ms, up to 10 attempts, only while a pending OSD exists (`Service.qml` 254-285, 449-454).
- **NP8.5** Play-order is reactive, not polled (`Service.qml` 433-447). The code comment says this replaced a 500 ms poll.
- **NP8.6** `PwObjectTracker` on playback streams (456).

### 3.9 Error and empty states

- **NP9.1** No player or no metadata: `hasMedia` is false and the widget is hidden (`BarWidget.qml` 96-98; `Service.qml` 30). Note that `hasMedia` is a string or boolean expression, not a strict boolean (`Service.qml` 30; `BarWidget.qml` 15).
- **NP9.2** Title empty: the bar label is hidden (`BarWidget.qml` 176, `visible: !root.bar.vertical && root.title !== ""`), even when an artist exists. The popup shows "Nothing playing" when the title is empty (288).
- **NP9.3** No art: placeholder glyph 󰝚 (272-279).
- **NP9.4** No length: progress underline and popup progress hidden (`BarWidget.qml` 210, 325; `README.md` 140-141).
- **NP9.5** cava missing or failing: the widget shows nothing special. `onRunningChanged` clears the levels when the process stops (`BarWidget.qml` 93). No `onExited` error text, no stderr handling.
- **NP9.6** Stale preferred player: cleared when it disappears (`Service.qml` 125).
- **NP9.7** Source-switch with no sources: returns false (`Service.qml` 318). IPC returns `"unhandled"` (`Service.qml` 503-509).
- **NP9.8** Action not supported by the chosen player: `handled` stays false and the OSD is still scheduled (`Service.qml` 370-431, 428-429), with the label of the attempted action.

### 3.10 Security and privacy facts

- **NP10.1** Art: `trackArtUrl` is used as `Image.source` in the popup (`BarWidget.qml` 268). No scheme check.
- **NP10.2** Desktop-entry icon values: a value starting with `/` becomes `file://<value>` (`BarWidget.qml` 68); `file://` and `image://` pass through (67); other names go to `Quickshell.iconPath` (69).
- **NP10.3** `extras/media-key.sh` (73 lines, bash): tries `omarchy-shell media "$action"` first (19), then uses `busctl --user list` (27-28) and `busctl --user get-property` / `call` for each MPRIS player (31-38). Players are matched with `awk` on the bus list and `playerctld` is excluded there (28). The script exits 0 when no player is found (29).
- **NP10.4** `cava` is started with an argument list (`BarWidget.qml` 90). The config path is resolved from the plugin folder with `Qt.resolvedUrl` and `decodeURIComponent` (74).
- **NP10.5** Pipewire node labels are read for matching (`MediaModel.js` 56-64) and never shown in the UI.
- **NP10.6** Text is shown with `Text.PlainText` (`BarWidget.qml` 138, 180, 287, 298, 353, 362, 439, 450).
- **NP10.7** The visualizer reacts to all audio on the default output, not just the active player (`README.md` 137-138).

### 3.11 Tests and previews

- **NP11.1** No tests in the repo.
- **NP11.2** `preview.png` (800x450, about 127 KB) shows, at the top centre, the bar chip, and a dropdown with the album art "Codeine" by Jason Isbell and the 400 Unit, album "Here We Rest", a progress line with 0:05 and 5:44, one row for Spotify (playing, with pause glyph, highlighted) and a second row for "Brave Origin" (paused, with play glyph) showing two sources in the list. (Image as viewed.)

### 3.12 Code quality facts

- **NP12.1** The logic is split out: `MediaModel.js` (142 lines) holds pure helpers. `Service.qml` (523 lines) holds state and actions. `BarWidget.qml` (467 lines) holds the bar, popup and cava process.
- **NP12.2** `Service.qml` has wrapper functions that only call into `MediaModel.js` (`Service.qml` 37-96).
- **NP12.3** `hasMedia` (`Service.qml` 30) can evaluate to a string (`activePlayer.trackTitle || activePlayer.trackArtist`).

---

## 4. Quickshell Mpris module (exact API)

Source: `refs/quickshell/src/services/mpris/`. Files: `player.hpp` (504 lines), `player.cpp` (501), `watcher.hpp` (59), `watcher.cpp` (119), `module.md` (7), `CMakeLists.txt` (45), two XML interface files (24 and 6 lines). No tests, no `docs/`.

### 4.1 Module and types

- **QS1.1** Module `Quickshell.Services.Mpris`, version 0.1, description "Mpris Service" (`module.md` 1-2; `CMakeLists.txt` 31-32). The quickshell target links it at `CMakeLists.txt` 45. Whether the parent `src/services/CMakeLists.txt` gates it behind an option was not checked.
- **QS1.2** Singleton `Mpris` (QML name, `watcher.hpp` 47-48). Property `players`: `UntypedObjectModel*`, constant (`watcher.hpp` 50-51). Its type is `ObjectModel<MprisPlayer>` (`watcher.hpp` 49-50, 56). `ObjectModel` exposes `values` (`core/model.hpp` 45).
- **QS1.3** Element `MprisPlayer`: `QML_ELEMENT` and `QML_UNCREATABLE("MprisPlayers can only be acquired from Mpris")` (`player.hpp` 228-229). Players are obtained only from `Mpris.players`.
- **QS1.4** Enum `MprisPlaybackState` (singleton, `QML_SINGLETON`): `Stopped = 0`, `Playing = 1`, `Paused = 2` (`player.hpp` 20-34, enum at 26-30). `toString` at `player.cpp` 31-38.
- **QS1.5** Enum `MprisLoopState`: `None = 0`, `Track = 1`, `Playlist = 2` (`player.hpp` 38-52, enum at 44-48). `toString` at `player.cpp` 40-47.
- **QS1.6** Wire mapping of enums: `"Playing"`, `"Paused"`, `"Stopped"` (`player.cpp` 467-482); `"None"`, `"Track"`, `"Playlist"` (484-499). An unknown `PlaybackStatus` string is a D-Bus error (471-472, 489).

### 4.2 Properties (`player.hpp`)

Format: name, type, access, notify signal, line.

- `canControl` bool, read-only, bindable, `canControlChanged` (90). Bound to `CanControl` (`player.hpp` 476).
- `canPlay` bool, read-only (91). Value = `canControl && CanPlay` (`player.cpp` 65).
- `canPause` bool (92). Value = `canControl && CanPause` (66).
- `canTogglePlaying` bool (93). Value = `canPause` if playing, else `canPlay` (71-73).
- `canSeek` bool (94). Value = `canControl && CanSeek` (67).
- `canGoNext` bool (95). Value = `canControl && CanGoNext` (68).
- `canGoPrevious` bool (96). Value = `canControl && CanGoPrevious` (69).
- `canQuit` bool (97). From the `org.mpris.MediaPlayer2` interface `CanQuit` (432).
- `canRaise` bool (98). `CanRaise` (433).
- `canSetFullscreen` bool (99). `CanSetFullscreen` (435).
- `identity` string (101). `Identity` (430).
- `desktopEntry` string (103). `DesktopEntry`, optional (431).
- `dbusName` string, constant (105). Returns the service name (`address()`, `player.cpp` 172).
- `position` real (seconds), read/write, `positionChanged` (139). See QS1.12 and QS1.13 for the update model.
- `positionSupported` bool, notify `positionSupportedChanged` (140). True once the `Position` property has been read (`player.cpp` 194; `properties.cpp` 221).
- `length` real, notify `lengthChanged` (143). Returns the track length or the position when length is not supported (`player.cpp` 238-244).
- `lengthSupported` bool, bindable (144). True when `mpris:length` is present and not -1 (`player.cpp` 96-103).
- `volume` real, read/write (148). Defaults to 1 (`player.hpp` 455; doc 145).
- `volumeSupported` bool (149). True when `Volume` exists (`player.cpp` 246).
- `metadata` QVariantMap, bindable (158). Raw metadata.
- `uniqueId` quint32, bindable (163). Incremented on each track change (`player.cpp` 308).
- `trackTitle` string, bindable (168). From `xesam:title` (`player.cpp` 75-77).
- `trackArtist` string, bindable (173). From `xesam:artist`, a list joined with ", " (83-86).
- `trackArtists` string, deprecated alias of `trackArtist` (175).
- `trackAlbum` string, bindable (180). From `xesam:album` (79-81).
- `trackAlbumArtist` string, bindable (185). From `xesam:albumArtist` (88-90).
- `trackArtUrl` string, bindable (187). From `mpris:artUrl` (92-94).
- `playbackState` enum, read/write (194). Bound to `PlaybackStatus` (`player.hpp` 485; `player.cpp` 374-389 for side effects).
- `isPlaying` bool, read/write (199). `bIsPlaying` = `playbackState == Playing` (`player.cpp` 105-107).
- `loopState` enum, read/write (203). `LoopStatus` (486).
- `loopSupported` bool (204). True when `LoopStatus` exists (`player.cpp` 391).
- `rate` real, read/write (211). `Rate` (487).
- `minRate` real (212). `MinimumRate` (488).
- `maxRate` real (213). `MaximumRate` (489).
- `shuffle` bool, read/write (217). `Shuffle` (490).
- `shuffleSupported` bool (218). True when `Shuffle` exists (`player.cpp` 427).
- `fullscreen` bool, read/write (222). `Fullscreen` (434).
- `supportedUriSchemes` list of strings (224). `SupportedUriSchemes` (436).
- `supportedMimeTypes` list of strings (226). `SupportedMimeTypes` (437).

### 4.3 Methods

- `raise()` (`player.hpp` 237; `player.cpp` 123-130). Requires `canRaise`; otherwise a warning and no call.
- `quit()` (241; `player.cpp` 132-139). Requires `canQuit`.
- `openUri(uri)` (246; `player.cpp` 141). No capability check.
- `next()` (250; 143-150). Requires `canGoNext`.
- `previous()` (254; 152-159). Requires `canGoPrevious`.
- `seek(offset)` (261; 161-169). Requires `canSeek`. Offset is seconds; converted to microseconds (`offset * 1000 * 1000`, line 167).
- `play()` (263; 357). Equivalent to `playbackState = Playing`.
- `pause()` (265; 358).
- `stop()` (267; 359).
- `togglePlaying()` (272; 361-367). Calls `pause()` if playing, else `play()`.
- `isValid()` (274; 171) and `address()` (275; 172).
- Setters (not Q_INVOKABLE): `setPosition(real)` (298; 196-217), `setVolume` (305; 248-261), `setPlaybackState` (318; 322-355), `setPlaying` (321; 369-372), `setLoopState` (325; 393-411), `setRate` (330; 413-425), `setShuffle` (334; 429-442), `setFullscreen` (337; 444-452).

### 4.4 Signals

Declared in `player.hpp` 347-404:

- `trackChanged()` (359). Emitted when `mpris:trackid`, `xesam:url` or `xesam:title` changes (`player.cpp` 276-302, 306-307).
- `postTrackChanged()` (365). Emitted after the track properties update (319).
- `ready()` (367, marked `QSDOC_HIDE`). Emitted after `GetAll` completes (`player.cpp` 454-459).
- `canControlChanged`, `canPlayChanged`, `canPauseChanged`, `canTogglePlayingChanged`, `canSeekChanged`, `canGoNextChanged`, `canGoPreviousChanged`, `canQuitChanged`, `canRaiseChanged`, `canSetFullscreenChanged` (368-377).
- `identityChanged` (378), `desktopEntryChanged` (379).
- `positionChanged` (380), `positionSupportedChanged` (381), `lengthChanged` (382), `lengthSupportedChanged` (383), `volumeChanged` (384), `volumeSupportedChanged` (385).
- `metadataChanged` (386), `uniqueIdChanged` (387), `trackTitleChanged` (388), `trackArtistChanged` (389), `trackAlbumChanged` (390), `trackAlbumArtistChanged` (391), `trackArtUrlChanged` (392).
- `playbackStateChanged` (393), `isPlayingChanged` (394), `loopStateChanged` (395), `loopSupportedChanged` (396), `rateChanged` (397), `minRateChanged` (398), `maxRateChanged` (399), `shuffleChanged` (400), `shuffleSupportedChanged` (401), `fullscreenChanged` (402), `supportedUriSchemesChanged` (403), `supportedMimeTypesChanged` (404).
- Private slots: `onGetAllFinished`, `onExportedPositionChanged`, `onSeek(qlonglong)` (`player.hpp` 407-409). `onSeek` is connected to the `Seeked` D-Bus signal (`player.cpp` 110, 236).

### 4.5 Watcher (`watcher.cpp`)

- **QS4.1** The watcher is a singleton created on first use (`watcher.cpp` 110-113).
- **QS4.2** If the session bus is not connected, it logs a warning and stays inert (27-30).
- **QS4.3** Watched name pattern: `addWatchedService("org.mpris.MediaPlayer2*")` (line 41), with registration and unregistration watch modes (37-39).
- **QS4.4** Existing players are found by listing bus names and filtering by prefix `org.mpris.MediaPlayer2` (47-55).
- **QS4.5** A new registration with that prefix creates an `MprisPlayer` (57-64, 90-108). A duplicate is skipped (91-94). An invalid player (not valid on D-Bus) is deleted (96-101).
- **QS4.6** Unregistration disconnects, removes from the map and from the ready list, and calls `deleteLater()` (66-76).
- **QS4.7** A player is added to the model when `ready` fires (78-81). `players()` returns the ready list (88).
- **QS4.8** The model is `ObjectModel<MprisPlayer>` named `readyPlayers` (`watcher.hpp` 42).

### 4.6 D-Bus interfaces used

- **QS5.1** Player object: service = bus name, path `/org/mpris/MediaPlayer2`, interface `org.mpris.MediaPlayer2.Player`, session bus (`player.cpp` 49-58). Methods used: `OpenUri`, `SetPosition`, `Seek`, `Next`, `Previous`, `Stop`, `Play`, `Pause` (`org.mpris.MediaPlayer2.Player.xml` 3-18). `PlayPause` is declared in the XML (13) but `togglePlaying()` calls `pause()` or `play()` (`player.cpp` 361-367).
- **QS5.2** App object: same service and path, interface `org.mpris.MediaPlayer2`, methods `Raise` and `Quit` (`org.mpris.MediaPlayer2.xml` 2-29).
- **QS5.3** Signal `Seeked(x Position)` (`org.mpris.MediaPlayer2.Player.xml` 20-22).
- **QS5.4** Properties are read with `Get` and `GetAll`, and tracked with `PropertiesChanged` (`dbus/properties.cpp` 137-139, 161-169, 234-244, 312-335). A `Set` is used to write (268-280).
- **QS5.5** Each property is declared with a `required` flag. `PlaybackStatus` is `true` (`player.hpp` 485); `Position`, `Volume`, `LoopStatus`, `Rate`, `Shuffle` and the app properties are `false` (482-490, 430-437). The effect of the flag on a missing property was not traced in `dbus/properties.cpp`.

### 4.7 Position and time

- **QS6.1** No timer or polling loop exists in the module. The position is refreshed only when a `Get` is requested (`dbus/properties.hpp` 182, `requestUpdate()`; `dbus/properties.cpp` 234-244).
- **QS6.2** Position refresh requests happen at: track change (`player.cpp` 312, `pPosition.requestUpdate()`), a playback state change (377 and 381, the latter 100 ms later with `QTimer::singleShot`), and a track change that happened before the state change (387).
- **QS6.3** `Seeked` updates the position directly (`player.cpp` 236, 227-230).
- **QS6.4** Reading `position` extrapolates: `positionMs()` adds the elapsed time since `lastPositionTimestamp` times the rate (`player.cpp` 174-185). When paused it uses `pausedTime` (178-179). When stopped it returns 0 (176, 189).
- **QS6.5** `positionChanged` is emitted when the stored position is updated: `onPositionUpdated()` (219-225) and `setPosition(qlonglong)` (227-230). The header says the signal is not emitted on each tick, and gives a `FrameAnimation` or `Timer` snippet to emit it manually (`player.hpp` 111-138).
- **QS6.6** `setPosition` uses `SetPosition(trackId, us)` when `mpris:trackid` is known, else a relative `Seek` computed from the current position (`player.cpp` 207-216).
- **QS6.7** `lastPositionTimestamp` is set with `currentDateTimeUtc()` (221), and `positionMs()` uses `currentDateTime()` (179). Both are absolute instants, so the difference is computed across the two clocks without a local-time offset.

### 4.8 Track change rules

- **QS7.1** A track change is detected when any of `mpris:trackid`, `xesam:url` or `xesam:title` changes (`player.cpp` 266-302). Artist or album changes alone do not emit `trackChanged` (the properties still update, 315).
- **QS7.2** `uniqueId` increments on track change (308). It is documented as not the same as `mpris:trackid` (`player.hpp` 159-162).
- **QS7.3** `trackChangedBeforeState`: if the track changes before the playback state, the metadata is re-requested on the next state change (`player.cpp` 385-388).

### 4.9 Documented warnings in the header

- `player.hpp` 81-86: support for MPRIS functionality "varies wildly by player". The TrackList and Playlist interfaces are not implemented.
- `player.hpp` 111-113: `position` "usually will not update reactively".
- `player.hpp` 161-162: `uniqueId` is not `mpris:trackid`.
- `player.hpp` 347-365: `postTrackChanged` happens before some players update art URLs.

---

## 5. Side-by-side comparison table

Columns: the three projects and whether the Quickshell module itself offers the feature. "Yes" means the module exposes it. "No" means the module does not expose it. "Own code" means the project implements it itself.

| Feature | media-controller-plugin (MC) | omarchy-sonora (SN) | omarchy-now-playing (NP) | Quickshell module |
|---|---|---|---|---|
| Player data source | Quickshell `Mpris.players` (`Service.qml` 13) | Quickshell `Mpris.players` (`Service.qml` 16) | Quickshell `Mpris.players` (`Service.qml` 17) | Yes (`watcher.hpp` 47-57) |
| Other data source | `busctl` for TrackList, Metadata, and a `busctl monitor` (`Service.qml` 171, 301) | `busctl` for Shuffle and LoopStatus (`Service.qml` 78) | Pipewire nodes for stream matching (`Service.qml` 18); `cava` process (`BarWidget.qml` 90) | No (Pipewire is a separate module) |
| Which player is shown | Active (playing or paused), user choice first, then first playing (`Service.qml` 14-21) | First player that is Sonora (`Service.qml` 29-34) | Oldest playing with a stream, proxy last, user choice first (`Service.qml` 194-232) | No |
| Switching sources | Chip row, pinned popup only (`Preview.qml` 166-205) | None | Keybind `sourceSwitch` (`Service.qml` 316-349); no popup click | No |
| Remembered choice | File in `$XDG_RUNTIME_DIR`, session only (`Service.qml` 218-221) | Not applicable | In memory only; no file write found (`Service.qml` 12) | No |
| Bar chip contents | Prev, play/pause, next glyphs, then title and artist (`BarWidget.qml` 38-60) | Waveform, cover thumb, title and artist (`BarWidget.qml` 304-358) | Play glyph, app icon, title and artist with cava (`BarWidget.qml` 136-201) | No |
| Hover | Opens the preview (`Preview.qml` 66-69) | Tooltip with summary (`BarWidget.qml` 456-458) | Tooltip with title and artist (`BarWidget.qml` 234) | No |
| Click (left) | Pins the preview (`Preview.qml` 155-157); bar transport buttons act (`BarWidget.qml` 77-82) | Play/pause; if not running, focus (`BarWidget.qml` 444-449) | Opens or closes the dropdown (`BarWidget.qml` 233) | No |
| Middle click | Not handled | Next (`BarWidget.qml` 448) | Not handled (only left accepted, line 231) | No |
| Scroll wheel | Not handled | Previous and next (`BarWidget.qml` 451-455) | Not handled | No |
| Right click | Not handled | Toggles the card (`BarWidget.qml` 439-441) | Not handled | No |
| Keyboard in popup | Escape closes (`Preview.qml` 120) | None | None | No |
| Popup type | `PopupWindow` with `HyprlandFocusGrab` (`Preview.qml` 81-110) | `PopupCard` (`BarWidget.qml` 463) | `PopupCard` (`BarWidget.qml` 238) | No (module has no UI) |
| Cover art | Yes, from `trackArtUrl` or local file probe (`Preview.qml` 212-220; `Service.qml` 71-91) | Yes, `trackArtUrl`, with blurred backdrop (`BarWidget.qml` 504-524) | Yes, 64 px in dropdown (`BarWidget.qml` 262-270) | Yes, `trackArtUrl` property (`player.hpp` 187) |
| Blurred backdrop | Yes, `MultiEffect` (`Preview.qml` 131-142) | Yes, `MultiEffect` (`BarWidget.qml` 517-522) | No | No |
| Progress bar | Yes, clickable to seek when `canSeek` (`Preview.qml` 277-295) | Yes, scrubber in card, seek on release (`BarWidget.qml` 688-694) and bar hairline (412-430) | Yes, underline in bar and dropdown bar (`BarWidget.qml` 204-225, 321-344) | `position`, `length` (`player.hpp` 139, 143) |
| Elapsed and total times | Pinned only (`Preview.qml` 296-304) | Yes, elapsed and minus remaining (`BarWidget.qml` 701-718) | Yes, in dropdown (`BarWidget.qml` 346-368) | Via properties |
| Seek step buttons | Back 10 s, forward 10 s (`Preview.qml` 311, 327) | None (click or drag only) | None | `seek(offset)` (`player.hpp` 261) |
| Absolute seek | Click on progress bar (`Preview.qml` 453-454) | Drag scrubber (`BarWidget.qml` 694) | None | `position` setter (`player.hpp` 139, 196-217) |
| Volume control | None | Sonora volume slider (`BarWidget.qml` 803-840) | None | `volume` setter (`player.hpp` 148) |
| Shuffle | None | Toggle, via busctl writes (`Service.qml` 226-231) | None | `shuffle` setter (`player.hpp` 217) |
| Loop | None | Cycle none, playlist, track (`Service.qml` 234-239) | None | `loopState` setter (`player.hpp` 203) |
| Track list | Yes, from TrackList via busctl, and from mpv socket (`Preview.qml` 334-415; `Service.qml` 161-296, 325-351) | None | None | No (TrackList not implemented, `player.hpp` 85-86) |
| Jump to track | Yes, `GoTo` via busctl; mpv `playlist-play-index` (`Service.qml` 148-158) | None | None | No |
| Visualizer | None | Animated five-bar logo, not audio-driven (`BarWidget.qml` 79-137) | cava, 16 bars (`BarWidget.qml` 73-129) | No |
| Lyrics | None | None | None | No |
| Per-player icons | None (text only, `Service.qml` 55-57) | None | Yes, from desktop entries (`BarWidget.qml` 47-70) | `desktopEntry` string only (`player.hpp` 103) |
| Stream or app matching | None | None | Pipewire node name substring match (`MediaModel.js` 74-89) | No |
| Proxy (playerctld) handling | None | None | Ordered last (`MediaModel.js` 1-5) | No |
| Play or pause | `togglePlaying` (`Service.qml` 143) | `togglePlaying` / `play` / `pause` (`Service.qml` 175-180) | `playerForAction` then `play` / `pause` (`Service.qml` 370-431) | Yes (`player.hpp` 263-272) |
| Next and previous | Yes (`Service.qml` 144-145) | Yes (`Service.qml` 190-196) | Yes (`Service.qml` 378-391) | Yes (`player.hpp` 250, 254) |
| Raise window | None | Focus via `omarchy-launch-or-focus` (`Service.qml` 243) | None | Yes, `raise()` (`player.hpp` 237) |
| Quit player | None | None | None | Yes, `quit()` (`player.hpp` 241) |
| Open URI | None | None | None | Yes, `openUri()` (`player.hpp` 246) |
| External IPC | None | `IpcHandler` target `sonora` (`Service.qml` 275-291) | `IpcHandler` target `media` (`Service.qml` 476-522) | No |
| Keybind example | None | Yes, in README (`README.md` 61) | Yes, in README (`README.md` 76-98) and `media-key.sh` | No |
| Config options | Two: width, fontSize (`manifest.json` 28-43) | Five (`manifest.json` 31-70) | None (`manifest.json` has no schema) | No |
| Hide when empty | Yes (`BarWidget.qml` 29) | Yes, default (`BarWidget.qml` 70) | Yes (`BarWidget.qml` 96) | No |
| Idle timers | 1000 ms always (`Service.qml` 223); 2000 ms mpv reconnect (353); 180 ms debounce (224) | 3000 ms busctl poll (`Service.qml` 92); 1000 ms position nudge (114); 250 ms settle (100) | 1000 ms position poll while playing (`BarWidget.qml` 39); 120 ms OSD (`Service.qml` 449) | None (signal driven) |
| Child processes at idle | `busctl monitor` (always, `Service.qml` 301) | `busctl` every 3 s while Sonora runs (`Service.qml` 72-74) | `cava` while playing (`BarWidget.qml` 88-94) | None |
| Tests shipped | No | No | No | No (`test/manual/` exists for polkit only) |
| Preview images | `preview.png` and 4 screenshots | `preview.png` | `preview.png` | None |
| Lines of code | Service 364, Preview 488, Bar 84 | Service 292, Bar 844 | Service 523, Bar 467, JS 142 | player.cpp 501, player.hpp 504, watcher 119 + 59 |

---

## 6. Patterns worth knowing

Facts only: what several of the projects do the same way.

- **P1 Quickshell as the player source.** All three read `Mpris.players.values` and per-player properties (MC `Service.qml` 13; SN `Service.qml` 16; NP `Service.qml` 17).
- **P2 A once-a-second position refresh while playing.** Each project forces the bar to re-read `position` once a second while playing: MC through a 1000 ms tick that calls `rebuild()` while playing (`Service.qml` 201, 223); SN through `player.positionChanged()` every 1000 ms (`Service.qml` 114-119); NP through `positionChanged()` every 1000 ms (`BarWidget.qml` 38-45). Each cites the same reason: Quickshell does not push position updates.
- **P3 Re-check after an action.** SN (`Service.qml` 136-156) and NP (`Service.qml` 254-285) both wait for the track metadata to change after next or previous, polling in 120 ms steps up to 10 times, before showing the OSD. MC does not show an OSD.
- **P4 Relative seek.** SN seeks by computing `target - position` and calling `player.seek` (`Service.qml` 204-209). MC calls `p.seek(delta)` for the 10 s buttons (`Service.qml` 146). Quickshell's `seek` takes a relative offset in seconds (`player.hpp` 255-261).
- **P5 Art from `trackArtUrl`.** All three use the `trackArtUrl` value directly as an image source (MC `Preview.qml` 125, 215; SN `BarWidget.qml` 310, 509, 639; NP `BarWidget.qml` 268).
- **P6 Hidden when empty.** All three hide the bar item when no player is present (MC `BarWidget.qml` 29; SN `BarWidget.qml` 70 by default; NP `BarWidget.qml` 96).
- **P7 Text as plain text.** All three set `textFormat: Text.PlainText` on player-supplied strings (MC `Preview.qml` 51, 190, 246, 257; SN `BarWidget.qml` 343, 352, 660, 672; NP `BarWidget.qml` 180, 287, 298).
- **P8 Keep the plugin loaded.** All three manifests set `keepLoaded: true` (MC `manifest.json` 13; SN `manifest.json` 13; NP `manifest.json` 13).
- **P9 Pointing-hand cursor on clickable parts.** All three set `Qt.PointingHandCursor` on clickable areas (MC `Preview.qml` 65, 199; SN `BarWidget.qml` 228, 435; NP `BarWidget.qml` 230).
- **P10 Shell-outs use argument arrays.** MC `Service.qml` 150, 171, 242, 256, 277; SN `Service.qml` 78, 107, 243; NP `BarWidget.qml` 90 (`cava`), `media-key.sh` (busctl). None builds a shell string.
- **P11 Shared service, per-bar widget.** MC (`Service.qml` 6) and SN (`Service.qml` 6-8) describe the service as one instance shared across bar instances. NP's widget reads a service the same way (`BarWidget.qml` 11).
- **P12 Cover art shown in a popup with a fixed-size square or card.** MC uses a 118 or 164 px rounded rectangle (`Preview.qml` 208-209); SN a large rounded square at full card width (`BarWidget.qml` 594-640); NP a 64 px square (`BarWidget.qml` 256-261).
- **P13 Scroll for long titles.** SN marquee (`BarWidget.qml` 373-393) and NP continuous scroll (`BarWidget.qml` 187-199) both move the title. MC truncates with ElideRight (`Preview.qml` 57). The NP and SN marquees both use `NumberAnimation` on `x`.
- **P14 Progress as a thin bar.** All three use a thin bar for progress (MC 4 px `Preview.qml` 279; SN 2 px hairline `BarWidget.qml` 419; NP 2 px and 4 px `BarWidget.qml` 210, 329).
- **P15 Theme tokens for text sizes.** MC, SN and NP all draw text sizes from `Style.font.*` (for example MC `Preview.qml` 250, SN `BarWidget.qml` 664, NP `BarWidget.qml` 291).
- **P16 IPC for keybinds in two projects.** SN (`Service.qml` 275-291) and NP (`Service.qml` 476-522) both expose an `IpcHandler` with transport methods and return string replies.
- **P17 `busctl` for what Quickshell does not expose.** MC for TrackList and Metadata; SN for Shuffle and LoopStatus. Each comment or README gives the reason (MC `README.md` 104-107; SN `Service.qml` 57-60).

---

## 7. Pitfalls observed

Facts the code shows. No recommendations.

- **PF1 Always-on timer in MC.** `Service.qml` 223 runs a 1000 ms timer even when no player exists. It increments a counter and only calls `rebuild()` while playing (201). The wake-up itself does not depend on playback.
- **PF2 Permanent `busctl monitor` in MC.** `Service.qml` 301-305 watches all signals on `/org/mpris/MediaPlayer2` for every player, and parses each line as JSON (307-308). If the monitor exits, it restarts after 2000 ms (317, 319-324).
- **PF3 Track-list refresh chain in MC.** A track change or metadata change starts a chain of up to four `busctl` processes (`Service.qml` 161-175, 242-279). A `refreshPending` flag and a 180 ms debounce handle overlaps (161-166, 176-179, 224). A failure in any step ends the chain without a retry (238-240, 250-252, 265-267).
- **PF4 Position drift is not corrected by MC.** MC displays `p.position`, which Quickshell extrapolates from the last known position and rate (`player.cpp` 174-185). MC refreshes the display once a second while playing (`Service.qml` 201). A player that sends no position updates for long periods is extrapolated until its next update.
- **PF5 SN's 3 s `busctl` poll.** `Service.qml` 92-98 starts `busctl get-property` every 3 s while Sonora is running (72). The guard at line 72 only prevents overlap. The project comment says Shuffle and LoopStatus go stale in Quickshell's cache (57-60), but Quickshell does provide `shuffle` and `loopState` properties and setters (`player.hpp` 203, 217; `player.cpp` 393-411, 429-442). This is a difference between the code and its stated reason; the reason itself is not verified here.
- **PF6 SN optimistic toggle.** `toggleShuffle` flips `_shuffle` before the write (`Service.qml` 228). The result is confirmed only by the next read, 250 ms after the write (106-110) or by the 3 s poll. There is no rollback path if the write fails. `execDetached` gives no error (107).
- **PF7 SN loop parse.** The loop value is read from the text after the second line of `busctl` output, lower-cased, and matched with `indexOf` (`Service.qml` 85-87). A reply in another format would fall back to `"none"`.
- **PF8 SN OSD fallback.** After 10 attempts at 120 ms, the OSD is shown even if the track did not change (`Service.qml` 148). The message uses the current summary, which may still be the old track (133, 125).
- **PF9 SN seek uses extrapolated position.** `seekTo` computes the relative offset from `player.position` (`Service.qml` 208-209), which is Quickshell's extrapolated value (`player.cpp` 174-185).
- **PF10 SN card position text.** The elapsed time text reads `root.sonora.position` directly (`BarWidget.qml` 705), while the scrubber value is bound to the same property (692). Both update only when `positionChanged` is emitted, which the 1000 ms nudge does (`Service.qml` 114-119).
- **PF11 MC source chips do not include proxy filtering.** `playerctld` would appear as a source (`Service.qml` 112-119). Nothing in the file checks for it.
- **PF12 MC preferred-source persistence.** If the preferred player is present but not active, the preference stays and selection falls back to another player (`Service.qml` 16-21, 181-184). When the preferred player becomes active again it is shown again without any user action. The code does not clear the preference in this case.
- **PF13 MC active-player switching.** The active player is any playing or paused player (14), and the first playing player wins when no preference is set (19). When two players alternate between playing and paused, the chosen player can change (by code path, not by measurement). Each change resets the queue and re-probes artwork (187-196).
- **PF14 MC mpv default socket.** The default path is `/tmp/mpv-socket` (`Service.qml` 327). The code writes JSON commands to it (156-158) and reads from it (334-351) without any ownership check. `README.md` 93 gives the same path.
- **PF15 MC artwork probe cost.** Up to 45 candidate URLs are tried one after another through one `Image` (`Service.qml` 84-91, 225-232). The probe restarts on each metadata change (204, 71-74).
- **PF16 MC duration fallback.** Firefox may omit `mpris:length` after a seek. `durationFor` keeps the last known value for the same track (`Service.qml` 95-107). The comment says that without this, "Quickshell then exposes position as length, which makes the progress bar appear full" (95-96). This matches the Quickshell fallback at `player.cpp` 238-244.
- **PF17 NP scroll always on.** The label scrolls even when it fits (`BarWidget.qml` 187-199). The comment states this is deliberate (187).
- **PF18 NP popup source rows are not clickable.** `BarWidget.qml` 385-462 shows rows but has no `MouseArea`. `selectPlayer` exists in `Service.qml` 287-292 but is not called from the widget.
- **PF19 NP cava failure is silent.** `cava` is started as a `Process` (`BarWidget.qml` 88-94). No `onExited` or error output is handled. The visualizer just does not show levels.
- **PF20 NP cava runs on the bar's own timer.** `cavaProcess` is running while `cavaActive` is true (`BarWidget.qml` 75, 91), which is every time the active player is playing. It stops on pause (`README.md` 139).
- **PF21 NP play-order gap.** `syncPlayingOrder` is run on player-list changes and on `isPlayingChanged` (`Service.qml` 438, 440-447). Play-order is therefore updated only when the set of players or a playing flag changes; it does not track metadata changes.
- **PF22 NP `media-key.sh` busctl per player.** Each action calls `busctl get-property` for each player to find the state (`media-key.sh` 31-34, 49). With many players this is several process starts per key press.
- **PF23 NP `media-key.sh` source switch.** `sourceSwitch` pauses the playing player and then sends Play to the next one without checking its `CanPlay` (`media-key.sh` 70-71). The bash fallback has no error handling besides the redirects (`>/dev/null 2>&1`, line 37).
- **PF24 NP `hasMedia` type.** `hasMedia` is built from `trackTitle || trackArtist`, which can be a string (`Service.qml` 30; `BarWidget.qml` 15). It is used as a boolean in `visible: hasMedia` (`BarWidget.qml` 96).
- **PF25 NP `Service.qml` wrappers.** Most helper functions in `Service.qml` only call `MediaModel.js` (37-96), so each rule is reached through one extra function call.
- **PF26 QS loop-state setter.** `setLoopState` warns when the value is out of range but does not return (`player.cpp` 404-407). It then sets `bLoopState` and calls `pLoopStatus.write()` (409-410).
- **PF27 QS `openUri` and `setFullscreen` have no capability check.** `openUri` calls `DBusMprisPlayer::OpenUri` directly (`player.cpp` 141). `setFullscreen` checks `canSetFullscreen` (445) and not `canControl`. `setVolume`, `setLoopState` and `setShuffle` check `canControl` (`player.cpp` 248-252, 394-397, 435-438).
- **PF28 QS artist-only changes do not emit `trackChanged`.** A change in `xesam:artist` or `xesam:album` alone does not emit `trackChanged` or increment `uniqueId` (`player.cpp` 276-308). The property signals still fire through the bindings (315). Clients that key their track logic on `trackChanged` see no event for those changes.
- **PF29 QS D-Bus property handling for position.** `Position` is not `required` (`player.hpp` 482), so the player is treated as position-unsupported when it is absent (`player.cpp` 194). In that case `position` returns 0 (188) and `length` returns the position (240). Projects that show a bar from `length` then show a full bar (see PF16).
- **PF30 QS watcher wildcard.** The watcher adds the service name `org.mpris.MediaPlayer2*` (`watcher.cpp` 41). The matching behaviour of that string in `QDBusServiceWatcher` is not checked in this study (see Section 8). Only the prefix filter on the bus name list (50) is visible in the code.
- **PF31 QS `ready` gating.** A player becomes visible in `Mpris.players` only after its initial `GetAll` completes (`player.cpp` 119-120, 454-459; `watcher.cpp` 78-81). A player that never completes `GetAll` is not in the list.
- **PF32 Art URL timing.** The module's own header says some players update art slightly after `postTrackChanged` (`player.hpp` 361-364). All three projects read `trackArtUrl` when the bound property changes, so they will show the new value when it arrives, not at `postTrackChanged`.

---

## 8. Facts that could NOT be determined from the files

- **U1** Whether `QDBusServiceWatcher` honours the wildcard `org.mpris.MediaPlayer2*` added at `watcher.cpp` 41 for players registered after startup. The code filters existing names by prefix (47-55), but the live matching was not checked.
- **U2** How a plugin's `Service.qml` is connected to the shell service id `omarchy.media` that `omarchy-now-playing`'s `BarWidget.qml` 11 looks up. The README says the plugin replaces the built-in service (`README.md` 42-44), but the mapping code is not in the three repos. The shell's `serviceFor` and `firstPartyServiceFor` helpers exist in `refs/omarchy/shell/shell.qml` 907-911; the plugin loading path was not read.
- **U3** The shell's base types used by all three widgets: `BarWidget`, `PopupCard`, `PopupWindow` helpers such as `fittedContentWidth` and `requestPopout`, `bar.showTooltip`, `bar.releasePopout`, `shell.summon`, `shell.serviceFor`, `Style.*`, `Color.*`, `Border.*`, `BorderSurface`, `PanelSeparator`, `DesktopEntries`, `bar.shell.appLibrary`. Their definitions live in the Omarchy shell, which is only partly read here. The actual pixel values of `Style.font.*`, `Style.space()` and `Color.accent` were not resolved.
- **U4** Whether Sonora emits `PropertiesChanged` for `Shuffle` and `LoopStatus`. SN `Service.qml` 57-60 says it does not. No Sonora source is in `refs/`.
- **U5** Whether `kew` exposes TrackList and whether the jump-to-track action works. MC `README.md` 25-26 says it does. No kew source is in `refs/`.
- **U6** Whether mpv's MPRIS interface exposes `Position`, `Shuffle`, `LoopStatus` as the code expects. Not checked.
- **U7** The exact output format of `busctl --json=short` for `get-property` and `call` (MC `Service.qml` 171-172, 242-243, 256-258, 277-278). The parsers assume fields `type`, `data`, `payload`. Not checked against `busctl` source.
- **U8** Whether `busctl --user monitor` produces one JSON object per line when `--json=short` is used (MC `Service.qml` 304-305, 307-308). Not checked.
- **U9** The real CPU, wake-up or memory cost of any of the three plugins. No run or measurement was done.
- **U10** Whether Qt's image loader fetches remote URLs from `trackArtUrl` in each of the three projects (MC `Preview.qml` 125, 215; SN `BarWidget.qml` 310, 509, 639; NP `BarWidget.qml` 268). The code does not restrict the scheme, but the loader's behaviour was not tested.
- **U11** What `HyprlandFocusGrab` does when Hyprland is not the compositor (MC `Preview.qml` 106-110). Not checked.
- **U12** Whether `cava`'s output format in `cava.conf` matches what `BarWidget.qml` 78-86 parses at runtime. Not run.
- **U13** How `ObjectModel.values` orders players and whether the order is stable across player restarts. The watcher inserts players when they become ready (`watcher.cpp` 78-81); the ordering semantics of `insertObject` in `core/model.hpp` were not read.
- **U14** Whether `playerctld` appears in `Mpris.players` on a typical system, and therefore whether the MC source chip row would show it. Not run.
- **U15** Whether `omarchy plugin validate` and `qmllint` pass on the three projects. Not run (no network or run commands were allowed, and these were not needed for the reading).
- **U16** Whether `media-key.sh` works with the built-in `omarchy-shell media` reply `unhandled` for every action. Only the code paths were read.
- **U17** The actual visual result of the three previews beyond the description given in Sections 1.11, 2.11 and 3.11. The PNG files were viewed by eye only.
