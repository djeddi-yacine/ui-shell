# Screen recording feature catalogue

This is a catalogue for later selection, not a plan. Each feature listed below is
stated only as the repository's code or README shows it, with the source file in
parentheses, so features can be picked one by one when deciding what to build.
Ids (for example `reel-01`) are stable tags for referring to a feature.

## reel (io.github.tahadx.reel)

Backend and deps: `gpu-screen-recorder` for capture, `ffmpeg`/`ffprobe` for the save pass, Omarchy's `omarchy-capture-region` and `slurp` for area picking, `grim` for still previews, `mpv` for history playback and the webcam overlay, `wl-clipboard` for path copy, `omacut` optional, LocalSend via `omarchy share`. Engine is a Rust crate (`crates/reel`) shipped as a static binary (README.md; docs/reference.md). Feature count: 40.

- reel-01: Capture a window, monitor, or dragged area through Omarchy's picker (README.md; crates/reel/src/target.rs)
- reel-02: Window target recorded as its visible screen rectangle, not an isolated surface (README.md)
- reel-03: Countdown before recording, 0-60 s, default 0 (docs/reference.md; crates/reel/src/cli.rs)
- reel-04: Countdown footage kept as `-untrimmed` and trimmed in the save pass (docs/reference.md; crates/reel/src/paths.rs; crates/reel/src/commands.rs)
- reel-05: Video only; no still-image capture mode in the panel (README.md). Still preview only via `reel preview` (docs/reference.md)
- reel-06: Desktop audio, on by default (docs/reference.md, `--desktop-audio`)
- reel-07: Microphone audio, off by default, alias `--mic` (docs/reference.md)
- reel-08: Microphone noise reduction, FFmpeg based, save pass only, off by default (docs/reference.md "Save pass"; README.md)
- reel-09: Pointer capture toggle; `cursor` on keeps baked pointer plus telemetry (docs/reference.md; crates/reel/src/recorder.rs)
- reel-10: Hardware cursor forced while cursor is off so the pointer is not baked in (crates/reel/src/recorder.rs `HardwareCursor`)
- reel-11: FPS choice 30 / 60 / 120, default 60 (docs/reference.md; crates/reel/src/config.rs)
- reel-12: Quality presets very_low / low / medium / high / very_high / ultra, default very_high (docs/reference.md; crates/reel/src/recorder.rs `quality_preset`)
- reel-13: Codec choice auto / h264 / hevc / av1, with AV1 QP scaling (docs/reference.md; crates/reel/src/recorder.rs `quality_qp_override`)
- reel-14: Resolution cap 3840x2160 / 2560x1440 / 1920x1080 / 1280x720 or native `0x0` (docs/reference.md)
- reel-15: Container MP4 or MKV, default MP4 (docs/reference.md; crates/reel/src/config.rs)
- reel-16: Webcam corner overlay, sizes small/medium/large, camera picker by stable `/dev/v4l/by-id` path (docs/reference.md; crates/reel/src/webcam.rs)
- reel-17: Pause and resume without ending the file, via engine socket (README.md; crates/reel/src/recorder.rs)
- reel-18: Manual zoom during a take: touchpad pinch, `Ctrl+Alt` binds, `Ctrl+Alt+Scroll`, pan keys, zoom depth 1.5x-3x (README.md; crates/reel/src/zoom.rs)
- reel-19: Zoom is only active while recording; pause or stop resets to 1x (README.md)
- reel-20: Save pass: drops first frame, mutes PipeWire pop, normalizes audio, partial stream-copy head trim (docs/reference.md "Save pass"; crates/reel/src/finalize.rs)
- reel-21: History list with previews and recent takes, default 8 (docs/reference.md; crates/reel/src/commands.rs; Panel.qml)
- reel-22: History actions: open in mpv, cut in Omacut, share via LocalSend, trash (`gio trash`), copy path via `wl-copy`, open folder (README.md; crates/reel/src/commands.rs; Panel.qml)
- reel-23: Drag a take row out to another app (README.md)
- reel-24: Save path: `~/Videos/Reel` default, `--output-dir` override (docs/reference.md)
- reel-25: File naming: `reel-` prefix or `--filename-prefix`, timestamp suffix (docs/reference.md; crates/reel/src/paths.rs)
- reel-26: Desktop notifications for errors and state, suppressed by `REEL_NO_NOTIFY` (crates/reel/src/util.rs `notify`)
- reel-27: Hotkeys offered by installer, opt-in written to `~/.config/hypr/bindings.lua` (README.md; docs/bindings.md; install.sh)
- reel-28: Hotkey set: Super+R toggle, Super+Shift+R panel, Super+Alt+O pause, zoom and pan binds (README.md)
- reel-29: Replay buffer: none (no instant-replay mode found in README.md or docs/reference.md)
- reel-30: Bar mark showing recording, paused, and saving states (README.md)
- reel-31: Keyboard-first panel with vim-style and arrow navigation (README.md)
- reel-32: Settings UI tabs Media, Zoom, Output, Keys inside the panel (CLAUDE.md; Panel.qml)
- reel-33: CLI with start, toggle, stop, pause, resume, status, recent, trash, config, preview, webcams, doctor (docs/reference.md; crates/reel/src/cli.rs)
- reel-34: Self-update: `reel update`, `Shift+U`, hourly update check via git origin (README.md; docs/reference.md)
- reel-35: Diagnostics via `reel doctor` (docs/reference.md)
- reel-36: Live state file for the bar at `$XDG_RUNTIME_DIR/reel/state.json` (docs/reference.md)
- reel-37: HDR: not found in code or docs (grep for hdr returned no match)
- reel-38: Upload or streaming to a service: none; sharing is LocalSend only (README.md)
- reel-39: Annotation or editing: none in the engine; only trim via Omacut (README.md)
- reel-40: Preview still of the focused monitor via grim (docs/reference.md; crates/reel/src/cli.rs)

## omarchy-sexy-screenshot (unicadesign.sexy-screenshot)

Backend and deps: stock Omarchy binaries only (`omarchy-capture-screenshot`, `omarchy-capture-text`, `omarchy-capture-qr`, `omarchy-capture-screenrecording`, `omarchy-capture-screenrecording-with-webcam`, `hyprpicker`, `omarchy-hw-webcam`), plus `gpu-screen-recorder` portal backend and `jq`/`hyprctl` for pinned window recording (README.md; manifest.json; scripts/pinned-window-record). Feature count: 21.

- sexy-01: Bar icon opens a capture panel (README.md; Panel.qml)
- sexy-02: Right-click bar icon runs a configurable screenshot mode: smart, region, windows, fullscreen (manifest.json `rightClickAction`)
- sexy-03: Middle-click fullscreen screenshot (README.md)
- sexy-04: Smart screenshot (`omarchy-capture-screenshot`) (Panel.qml)
- sexy-05: Region, window, and fullscreen screenshot modes (Panel.qml)
- sexy-06: Copy-only screenshot to clipboard, no file (README.md; Panel.qml `copy`)
- sexy-07: Save fullscreen to disk and skip the editor (README.md; Panel.qml `save`)
- sexy-08: OCR text extraction via `omarchy-capture-text` (README.md; Panel.qml)
- sexy-09: QR code decode via `omarchy-capture-qr` (README.md; Panel.qml)
- sexy-10: Color picker via `hyprpicker -a` (README.md; Panel.qml)
- sexy-11: Classic region and fullscreen video recording via `omarchy-capture-screenrecording` (Panel.qml)
- sexy-12: Desktop audio and microphone recording rows (Panel.qml `--with-desktop-audio`, `--with-microphone-audio`)
- sexy-13: Webcam recording row, shown only when a camera exists (README.md; Panel.qml)
- sexy-14: Pinned window recording via gpu-screen-recorder portal, window survives workspace switch, with desktop audio (README.md; scripts/pinned-window-record)
- sexy-15: Recording state shown by a lit icon and a Stop recording action (README.md)
- sexy-16: Panel closes before capture so it is not in the shot; configurable delay `closeDelayMs` 100-1000 ms, default 300 (manifest.json; README.md)
- sexy-17: Keyboard navigation in the panel with number and letter shortcuts (README.md)
- sexy-18: Settings UI: two keys in the bar widget schema (manifest.json)
- sexy-19: IPC commands: capture, screenshot modes, record region/fullscreen/pinned, stop, status (README.md)
- sexy-20: Hotkeys: none set by the plugin; actions are reached through the bar and IPC (README.md)
- sexy-21: Pinned recording stop path and log in `$XDG_RUNTIME_DIR` (scripts/pinned-window-record)

Not present in code or README: annotation, HDR, cloud upload, replay buffer, pause/resume (grep and reading found none for these).

## omarec (io.github.theneovimmer.omarec, "OMARec Studio")

Backend and deps: `mpv` renders the overlay, `v4l2-ctl`, `jq`, `hyprctl`. Optional `omarchy-notification-send`, `omarchy-menu-select`. No recording backend: the plugin never records (README.md; bin/omarec). Feature count: 12.

- omarec-01: Live floating camera preview overlay, always on top, bottom-right default (README.md; bin/omarec)
- omarec-02: Webcam selection and remembered device (README.md; bin/omarec `pick-device`)
- omarec-03: Overlay size small / medium / large (README.md; bin/omarec `resize`)
- omarec-04: Framing portrait 8:9 or landscape 16:9 (README.md; bin/omarec `orientation`)
- omarec-05: Corner rounding 0-20 px (README.md; bin/omarec `rounding`)
- omarec-06: Screen corner position, four corners (README.md; bin/omarec `position`)
- omarec-07: Hot restart of overlay on every visual change (README.md "Troubleshooting")
- omarec-08: Bar icon toggle, left-click panel, right-click overlay, LIVE pill (README.md)
- omarec-09: CLI with on, off, toggle, status, check, devices, get-all --json, reset (README.md; bin/omarec)
- omarec-10: Persisted settings in `~/.local/state/omarec/omarec.conf` (README.md; omarec.conf)
- omarec-11: Test script exercising the CLI contract without a camera (tests/run.sh; README.md)
- omarec-12: Recording, audio, and file output: none (README.md says "It never records")

## Better-Recast (pix.recast)

Backend and deps: `gpu-screen-recorder` (GPU encoders NVENC, VAAPI, QuickSync, CPU x264 fallback), `python3` for `scripts/gsr-ipc.py`, `ffmpeg` for audio filters and trim, `wl-copy` for path copy (README.md; scripts/gsr-ipc.py; Config.js; RecentRecordings.qml). Feature count: 34.

- br-01: Record desktop to MKV or MP4, default MKV (README.md; Config.js `container`)
- br-02: WebM, FLV, MOV container options listed in config (Config.js line 51)
- br-03: Streaming mode to RTMP, presets for TikTok, Twitch, YouTube, custom, with CBR (README.md; Config.js `streamPlatform`)
- br-04: Stream key passed by env var to GSR (README.md "Performance")
- br-05: Instant replay: circular buffer 2 s to 86400 s, RAM or disk storage (README.md; Config.js `replaySeconds`, `replayStorage`)
- br-06: Save replay clip with hotkey or CLI `saveReplay` (README.md; scripts/gsr-ipc.py `save-replay`)
- br-07: Region capture: whole screen, one display, or a remembered region (README.md)
- br-08: Per-application audio capture (README.md; Service.qml `listAppAudioProc`)
- br-09: Separate mic and desktop volume sliders, restored on stop (README.md)
- br-10: Audio codecs AAC, Opus, PCM (README.md "Audio"; Config.js `audioCodec`)
- br-11: Noise gate and filtering via FFmpeg `afftdn`, `agate` (README.md; Config.js `audioNoiseGate`)
- br-12: Video codec choice including HEVC, H.264, AV1, VP9, VP8 (Config.js `codec`; README.md GPU table)
- br-13: Bitrate modes auto / qp / vbr / cbr (Config.js `bitrateMode`)
- br-14: FPS up to 240 (README.md "Three modes")
- br-15: Resolution scaling (Config.js `resolution`)
- br-16: Color range limited / full (Config.js `colorRange`)
- br-17: Pause and resume via gsr IPC socket (Service.qml `pause()`; scripts/gsr-ipc.py `set-paused`)
- br-18: Pre-roll countdown 0 / 3 / 5 / 10 s (README.md "Settings"; Config.js `countdown`)
- br-19: Floating recording OSD, position configurable (Config.js `osdEnabled`, `osdPosition`)
- br-20: Presets saved in `~/.local/state/pix-recast/presets.json` (README.md; PresetsSection.qml)
- br-21: Recent recordings list with trim and open-in-folder (README.md; RecentRecordings.qml)
- br-22: Path copy action via `wl-copy` (RecentRecordings.qml)
- br-23: Trim tool with precise option and CLI `trim 00:05 00:30` (README.md; TrimTool.qml)
- br-24: Save path via `fileNameTemplate` with strftime tokens, default `screenrecording-%Y%m%d_%H%M%S` (README.md; Config.js)
- br-25: Date-organised folders option `organizeByDate` (README.md)
- br-26: Minimum free disk guard, default 2000 MB, auto-pause on low space (README.md; Config.js)
- br-27: Automatic GPU and encoder detection (README.md; GpuProbe.js; scripts/recast-doctor.sh)
- br-28: Hotkeys: Super+Alt+R toggle, S save replay, P pause, O open clip, Hyprland and Omarchy Lua forms (README.md "Hotkeys")
- br-29: CLI: toggle, record, stop, pause, resume, saveReplay, openClip, openFolder, trim, status (README.md)
- br-30: Settings UI in the floating panel and via `shell.json` (README.md "Settings"; Panel.qml)
- br-31: Dual GPU handling and GPU update check for gpu-screen-recorder (Service.qml; tests/dual-gpu.test.js)
- br-32: Better Bar REC/PAUSED chip integration (README.md)
- br-33: Doctor script for diagnostics (scripts/recast-doctor.sh)
- br-34: HDR: not found in code or README (grep for hdr returned no match in Config.js or Service.qml)

## Feature matrix

Legend: yes = present in the repo's code or README; no = not found. Feature rows use the short names above; the matrix is intentionally conservative and only marks what the cited files show.

| Feature | reel | omarchy-sexy-screenshot | omarec | Better-Recast |
| --- | --- | --- | --- | --- |
| Region capture | yes | yes (screenshot and record) | no | yes |
| Window capture | yes | yes (screenshot; pinned record) | no | no |
| Screen / monitor capture | yes | yes | no | yes |
| Still image capture | no (preview only) | yes | no | no |
| Video capture | yes | yes | no | yes |
| Desktop audio | yes | yes | no | yes |
| Microphone audio | yes | yes | no | yes |
| Per-application audio | no | no | no | yes |
| Microphone noise reduction | yes | no | no | yes (noise gate) |
| H.264 / HEVC / AV1 | yes | no (stock tool) | no | yes |
| VP8 / VP9 | no | no | no | yes (config) |
| Frame rate choice | yes (30/60/120) | no | no | yes (to 240) |
| Quality presets | yes | no | no | yes (bitrate modes) |
| Resolution cap or scale | yes | no | no | yes |
| MP4 container | yes | no | no | yes |
| MKV container | yes | no | no | yes |
| WebM / FLV / MOV | no | no | no | yes (config) |
| Countdown | yes | no | no | yes |
| Pointer / cursor control | yes | no | no | no |
| HDR | no | no | no | no |
| Pause and resume | yes | no | no | yes |
| Replay buffer | no | no | no | yes |
| Streaming (RTMP) | no | no | no | yes |
| Webcam overlay | yes (in recording) | yes (row in recording) | yes (live overlay only) | no |
| Zoom during take | yes | no | no | no |
| Annotation or editing | no | no | no | no (trim only) |
| Trim | yes (via Omacut) | no | no | yes |
| Clipboard copy | yes (path only) | yes (image copy) | no | yes (path only) |
| Save path setting | yes | no (stock dirs) | no | yes |
| File naming template | yes (prefix) | no | no | yes |
| Notifications | yes | no (stock tools) | yes (optional) | yes |
| Hotkeys offered | yes | no | no | yes |
| Settings UI | yes | yes (small) | yes | yes |
| Upload / share | yes (LocalSend) | no | no | yes (streaming) |
| Recording history | yes | no | no | yes |
| OCR text extraction | no | yes | no | no |
| QR decode | no | yes | no | no |
| Color picker | no | yes | no | no |
| Self-update check | yes | no | no | no |
| Replay / clip save | no | no | no | yes |

## Feature count per repo

- reel: 40 features
- omarchy-sexy-screenshot: 21 features
- omarec: 12 features
- Better-Recast: 34 features
