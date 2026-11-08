---
id: screen-capture-module
title: "Screen capture and recording module: GPU Screen Recorder behind a swappable backend"
category: decision
status: active
tags: [screen-recording, gsr, features]
created: "2026-11-06T03:24:53"
updated: "2026-11-08T05:08:07"
---

<!-- compiled_truth -->
<current best understanding — replace this with the real content>

## Timeline

- time: 2026-11-06T03:24:53
  kind: decision
  summary: "Created this page: Screen capture and recording module: GPU Screen Recorder behind a swappable backend"
  source: created via brain create-page
  affects: [screen-capture-module]

- time: 2026-11-06T03:24:53
  kind: decision
  summary: "Chose gpu-screen-recorder with a composable backend surface; feature catalogue written to features/screen-recording.md"
  source: user request 2026-11-06
  affects: [screen-capture-module]

- time: 2026-11-06T03:55:36
  kind: decision
  summary: "Brainstorm done: vertical-slice phases (spike, script+state+bar popup with monitor recording, window/region, mic+countdown, webcam, screenshot); recording is the one named exception to no-daemon with a runtime-dir state file; backend is one script with capabilities; built for the new shell, not the host config. Brief: features/reqs/screen-recording.md"
  source: user session 2026-11-06
  affects: [screen-capture-module]

- time: 2026-11-06T04:08:53
  kind: decision
  summary: "Design drafted (features/designs/screen-recording.md): state watch is a detached wrapper (gsr's parent) writing the exit result to a runtime-dir state file, shell wakes via inotify (FileView); gsr pid+start time stale-checked on every read; no separate watcher process. Replaces the earlier 'one watcher' idea."
  source: egm-draft 2026-11-06
  affects: [screen-capture-module]

- time: 2026-11-06T04:21:48
  kind: decision
  summary: "Phase 0 and 1 implemented: scripts/screen-record (state file, detached wrapper, SIGINT stop, stale check; 28 fake-recorder checks), RecordState adapter (FileView/inotify), record panel, bar Rec button with popup, Super+R. Spike: gsr 6.1.7 present, gsr-kms-server has cap_sys_admin (direct capture), no window-id capture on Wayland (use region), FileView watches file and directory so atomic rename works. Live recording not yet run."
  source: implementation 2026-11-06
  affects: [screen-capture-module]

- time: 2026-11-06T04:59:30
  kind: decision
  summary: "Recorder-specific logic in scripts/screen-record, learned from measuring gsr 6.1.7: resolve audio from --list-audio-devices before starting and drop missing sources with a warning (gsr exits within 0.5 s on an unopenable -a); recording state only after the recorder survives a 1.2 s settle with its file present (zombie-aware liveness); stops held back until settled; screens named by --list-monitors; desktop and mic as separate -a tracks. Verified live with ffprobe (make test-record-live)."
  source: "user: study the tools, 2026-11-06"
  affects: [screen-capture-module]

- time: 2026-11-06T05:20:12
  kind: decision
  summary: "Scope kept to gsr only (no second recorder). gsr cannot capture a nested session (DRM + privileged helper unreachable in the sandbox), so make test-env runs the recording UI with tests/record/fake-recorder (UI_SHELL_REAL_RECORDER=1 keeps gsr); the real recorder is verified by make test-record-live on the real desktop."
  source: "user: use just gsr; cannot start inside nested, 2026-11-06"
  affects: [screen-capture-module]

- time: 2026-11-06T05:35:08
  kind: decision
  summary: "Phase 2 implemented: window and region targets. gsr takes -w WxH+X+Y (global coords; -region deprecated); windows resolve to a cropped rectangle at the end of the countdown (refused if gone or off-screen); regions via slurp (screen-record pick-region, remembered per session) or typed; panel window hides while slurp runs. Shared Controls.TargetPicker. 67 fake-recorder checks, live window and region recordings verified with ffprobe."
  source: implementation 2026-11-06
  affects: [screen-capture-module]

- time: 2026-11-06T10:00:43
  kind: reversal
  summary: "The nested test session no longer uses the fake recorder (a fake wrote 4 KB zero files the user could not play): with no real screen the panel says gsr sees no screen. Start stays disabled until the user picks a target; the picker never auto-selects. The fake recorder remains only in tests/record for the script's unit tests."
  source: user 2026-11-06
  affects: [screen-capture-module]

- time: 2026-11-06T10:07:18
  kind: decision
  summary: "UI redesign from the reference study: the record key only toggles the panel (no stop-on-same-key, avoiding accidental stops); the panel is state-aware (clock, target, sound, Stop focused while recording; last saved file with Copy path when idle); countdown shown in bar chip and popup with Cancel; bar clock ticks while recording with a fixed-width slot. Presets, per-app audio and key hints skipped."
  source: "user: learn the design from the cloned repos, 2026-11-06"
  affects: [screen-capture-module]

- time: 2026-11-06T10:18:07
  kind: decision
  summary: "Region selection feedback: slurp covers every screen and draws nothing until a drag, so users saw the panel vanish and could not click the bar. pick-region now dims the screens, draws a border and shows the size (slurp -d -b -c -s -w); the bar chip says 'Drag a region · Esc cancels' while picking; a cancel or empty selection leaves a note in the panel; real slurp failures show their message. tests/scripts/run-session has a UI_SHELL_TEST_EXEC hook to run commands inside the nested session."
  source: user report 2026-11-06
  affects: [screen-capture-module]

- time: 2026-11-06T10:24:48
  kind: decision
  summary: "Root cause of the hung region selection: slurp reads stdin to EOF before opening anything when stdin is not a terminal, and the shell starts it with a pipe on stdin. pick-region now gives slurp </dev/null. Found by launching the selection from the shell in the nested session (UI_SHELL_RECORD_ACTION=pick) and reading the slurp process (wchan anon_pipe_read, no layer surface). Regression test: pick-region must return with the caller's stdin held open."
  source: user report 2026-11-06
  affects: [screen-capture-module]

- time: 2026-11-06T10:37:56
  kind: reversal
  summary: "Video settings (fps, quality, codec, container, cursor) are now options of the record component in Ctrl+E (earlier a non-goal). The shared settings popup was generalised to any number of options (ComponentSpec choices may be strings with labels; editor drafts keyed by option; scrolling list). gsr measured: h264/hevc/vp9 work, av1 falls back to h264 with a warning (reported in state), vp8 refused."
  source: "user: where are bitrate, fps ...; you choose where, 2026-11-06"
  affects: [screen-capture-module]

- time: 2026-11-06T10:50:15
  kind: decision
  summary: "Audio codec fixed to opus (explicit -ac opus). Bitrate added as a Ctrl+E option: auto (from quality preset) or a fixed 2.5-80 Mbps list, passed as -bm cbr -q KBPS. Verified live: opus audio stream; static screens under-use a CBR target (8000 kbps asked, ~4.3 Mbps overall)."
  source: user 2026-11-06
  affects: [screen-capture-module]

- time: 2026-11-06T11:10:03
  kind: decision
  summary: "Status 2026-11-06: phases 0-2 done and verified live with gsr (targets: screen/window/region; settings in Ctrl+E: countdown, desktop audio, fps, quality, codec, bitrate, container, cursor; audio fixed to opus). UI follows the reference study (state-aware panel, bar clock/countdown, last result with Copy path). Shared fixes along the way: slurp needs </dev/null, hover rules unified (pointer hover shows only while the pointer is active, never selects), no literals in components. Next: phase 3 (microphone, Esc-cancellable countdown), phase 4 webcam, phase 5 screenshot."
  source: user 2026-11-06
  affects: [screen-capture-module]

- time: 2026-11-06T11:17:55
  kind: decision
  summary: "Phases 3 and 4 implemented. Phase 3: microphone as a second audio track (panel switch + Ctrl+E), countdown visible and Esc-cancellable with the panel leaving 1 s before the recorder starts (verified live). Phase 4: webcam overlay = mpv window (app id ui-shell-webcam) placed by a Hyprland window rule from profile.webcam_overlay, started before the countdown and removed on every exit; offered only with a camera and the player. Real camera untested (none here)."
  source: "user: continue next phases, 2026-11-06"
  affects: [screen-capture-module]

- time: 2026-11-06T11:24:27
  kind: decision
  summary: "Phase 5 implemented: screenshot panel (Super+P) on scripts/screen-shot (grim + wl-copy), Adapters.ShotRunner, modules/shot, Config.Shot, shot settings (clipboard/file); shares target lists and region selection with recording; the panel hides while capturing. wl-copy keeps inherited pipes open, so its output is silenced or callers hang. Works in the nested session. All five phases done."
  source: "user: continue next phases, 2026-11-06"
  affects: [screen-capture-module]

- time: 2026-11-06T11:41:06
  kind: decision
  summary: "Defaults: container mkv, audio opus (explicit), recordings in <XDG Videos>/records, screenshots in <XDG Pictures>/screenshots (XDG dirs resolved from the environment, xdg-user-dir, then the plain home folder). Audio sources are explicit choices: default, a specific output's monitor, or one application for desktop audio; default or a specific input for the microphone."
  source: user 2026-11-06
  affects: [screen-capture-module]

- time: 2026-11-06T11:59:01
  kind: decision
  summary: "Audio codec is a Ctrl+E option (opus default, aac), passed explicitly as -ac. The Saved line is news only: a saved recording or screenshot is announced once (the first time the panel shows it) and never again, and only while its file still exists (a finished recording whose file was deleted is reported as idle; screenshots are verified with test -e)."
  source: user 2026-11-06
  affects: [screen-capture-module]

- time: 2026-11-06T12:08:33
  kind: decision
  summary: "Committed and pushed: all five phases (recording targets, audio/mic/webcam pickers, codec/bitrate/container options, countdown, webcam overlay, screenshots) plus the shared work done along the way (settings popup for N options, unified hover rules, no-literals token rule, exit dialog, picker/popup surface tokens). Defaults: mkv, opus, <XDG Videos>/records, <XDG Pictures>/screenshots. Known gaps: real camera untested (none on the dev machine), gsr cannot record the nested test session, device picks are per session (the settings file holds no device ids), free-form bitrate and save-folder options not offered."
  source: user 2026-11-06
  affects: [screen-capture-module]

- time: 2026-11-08T04:43:17
  kind: decision
  summary: "Black recordings under make test-env-host are expected: bwrap sets no-new-privileges so gsr-kms-server loses cap_sys_admin and KMS capture fails (drmfb handle is NULL); audio still works. Verified with setpriv --no-new-privs. Decision: keep the sandbox, document the limit; test recording on a normal session."
  affects: [screen-capture-module]

- time: 2026-11-08T05:08:07
  kind: decision
  summary: "Window screenshots use grim -T <Hyprland stableId> (foreign-toplevel capture; no portal, no QML): the old rectangle capture showed whatever was on the active workspace, not the chosen window. A picked region is captured at once into a buffer and the button becomes Save (screen-shot capture --buffer / commit). screen-shot waits for the ui-shell-shot layer to leave before grim."
  affects: [screen-capture-module]
