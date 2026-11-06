# Screen capture and recording

*   **Author:** djeddi-yacine
*   **Status:** Proposed
*   **Date:** 2026-11-06

--------------------------------------------------------------------------------

## Overview

ui-shell gets two new actions: take a screenshot, and record the screen. They
share one launcher entry but are otherwise separate. Each has its own panel
and its own settings, so an option of one never appears in the other. A button
in the bar opens a small popup that shows the state and the controls of one
domain, for example "recording, 02:14, Stop".

GPU Screen Recorder (gsr) does the recording. The shell does not talk to gsr
directly: it calls one script, `scripts/screen-record`, so that another
recorder can replace gsr later by replacing that script.

The work is split into phases. Each phase is a vertical slice: when it is done,
one part of the feature works from start to finish, and later phases only add
to it.

Inputs: `features/studies/screen-recording.md` (what four reference tools do)
and `features/reqs/screen-recording.md` (what we chose and why).

## The Problem

Today screenshots and recordings are started by scripts on keybinds. That has
no way to choose what to capture, to switch the microphone or desktop audio
on and off, to see that a recording is running, or to stop it without
remembering the key. The shell already has panels, popups, a shared settings
popup and an error popup, so a GUI is now possible without building a new
toolkit.

A recording is different from every action the shell has so far. The audio
module only reads and changes state that PipeWire keeps. A recording is a
long-running process (gsr) that must outlive the panel, the bar popup and a
shell reload. So "is it recording", the elapsed time and Stop need state that
the shell itself keeps, and a recorder that dies minutes after it started
needs something watching it, or the user never finds out.

The proposed solution:

*   One script, `scripts/screen-record`, with `start`, `stop`, `status` and a
    list of what the current recorder supports. All gsr details stay inside it.
*   One small state file in the runtime directory that says what is recording
    (process id, start time, target, output path, log path). Every read checks
    that the process behind the id is still the recorder.
*   A shell adapter and bar popup that read that state, show it, and call the
    script for Stop.
*   A recording panel for choices (target, audio, countdown, webcam) and a
    separate, smaller screenshot panel.

## Goals

*   Start a recording of a monitor, a window or a region, chosen from the panel
    with the keyboard as well as the mouse.
*   Switch desktop audio and microphone on or off before recording.
*   Set a countdown before recording starts, and cancel it with Esc.
*   Offer a webcam overlay only when a camera exists.
*   Show, from the bar, whether a recording is running, for how long, and let
    the user stop it, even when the panel is closed or the shell was reloaded.
*   Show an error with the shell's normal error popup when a recording cannot
    start, or dies after it started, with the recorder's own log as details.
*   Take a screenshot (region, window or monitor) and send it to a file, the
    clipboard or both, from a separate panel with its own settings.
*   Let keybinds trigger every action without the bar, through the scripts.
*   Keep settings of each domain separate, in the existing Ctrl+E popup, with
    the shell's usual exit rule for unsaved changes.
*   Let a phase ship alone: after each phase the shell works and the finished
    part is complete.

## Non-Goals

*   Pause and resume, instant replay, streaming, trimming and noise filtering.
*   HDR, upload or sharing, and a list of past recordings.
*   Bitrate in numbers and the other gsr knobs not listed under Goals. (Frame
    rate, quality preset, codec, container and cursor were first out of scope
    and were added later, in Ctrl+E; see the settings paragraph under
    Detailed Implementation.)
*   A QML-level backend interface. The swap point is the script.
*   Recording two monitors at once, or choosing the encoder GPU by hand.
*   Replacing the user's current keybind setup on the host. This is built for
    the new shell.

## Open Questions

*   **Portal and permissions**: gsr's portal mode shows its own picker and
    prompts, and direct capture needs extra capabilities. Does a keyboard target
    picker in the panel work with either? Phase 0 is a spike on this machine to
    answer it, before any design below it is final.
*   **Webcam**: a camera can be plugged in after the panel opens. Is it probed
    once when the panel opens, or again on a refresh key? Which process draws
    the overlay (the reference tools use `mpv`), and how does it stop with the
    recording?
*   **Window identity**: a window can close or move between choosing it and
    pressing Start. What does Start do then: refuse with a message, or record
    the screen area it had?
*   **Free-space limit**: what free space (in MB) is the minimum to start a
    recording?
*   **Where files go**: the default folder and file name pattern for recordings
    and screenshots, and whether a screenshot also copies the image or only the
    path to the clipboard.
*   **Screenshot tool**: the reference tools use `grim`, `slurp` and
    `wl-copy`. Is that the chosen set, with no gsr involvement?
*   **Entry points**: the names of the keybind-facing commands, and whether
    the launcher entry is one item with a choice or two items.

### Spike results (phase 0, 2026-11-06, this machine)

*   gsr 6.1.7 is installed. It accepts `-w monitor|region|portal|focused|<window id>`,
    `-region WxH+X+Y`, several `-a` audio inputs, `-o` for the output file,
    `-cursor`, `-f`, `-k`, `-q`, `--list-monitors`, `--list-audio-devices` and
    an `-ipc` socket (`gpu-screen-recorder --help`).
*   `gsr-kms-server` carries `cap_sys_admin`, so direct capture works without the
    portal. A window can only be recorded by id on X11; on Wayland the design
    records the window's rectangle through `-w region -region`.
*   `inotifywait` is not installed; the design does not need it (Quickshell's
    `FileView` watches the state file).
*   `/dev/v4l/by-id` does not exist here (no camera), so the webcam row is
    hidden, as designed.
*   Measured with the real recorder (phase 1 fixes):
    *   An audio source it cannot open (no audio server, no default output) makes
        it exit with an error within about half a second. The script therefore
        resolves audio from `--list-audio-devices` before starting, drops a
        missing source, records without it, and puts a warning in the state
        (the panel greys the audio switch and says why).
    *   It creates the output file at once with only a header (88 bytes) and
        writes in bursts, so a file existing proves nothing. The script treats
        the recorder as recording only after it stayed alive 1.2 s with its file
        present; `kill -0` is not enough because an exited child stays a zombie.
    *   `SIGINT` stops and saves, exit 0, and produced valid files when sent 0.3 s
        after the start; the script still holds a stop back until the recorder
        has settled, and cancelling a settling start deletes the empty file.
    *   Screens are named by `--list-monitors` (for example `HDMI-A-2|1600x900`),
        so the panel uses that list, not `hyprctl`.
    *   Two `-a` options record two separate audio tracks (verified with
        `ffprobe`): desktop audio and microphone.
*   Live recording verified on this machine by `make test-record-live`
    (desktop audio; desktop audio and microphone; stop right after start).

## Critical User Journeys (CUJs)

### CUJ 1: Record a monitor with desktop audio (phase 1)

*   **Given**: the shell is running, gsr is installed, nothing is recording.
*   **When**: the user opens the recording panel from the launcher or the bar,
    chooses a monitor and desktop audio, and presses Start.
*   **Then**: the panel closes, the bar button shows a recording state, and the
    bar popup shows the elapsed time and a Stop control. Stop ends the
    recording, the file plays back with sound, and the bar returns to idle.

### CUJ 2: Stop from the bar after the shell reloads (phase 1)

*   **Given**: a recording is running and the shell is reloaded.
*   **When**: the shell comes back and the user opens the bar popup.
*   **Then**: the popup reads the state file, confirms the recorder is still
    running, shows the real elapsed time, and Stop works.

### CUJ 3: The recorder dies (phase 1)

*   **Given**: a recording is running.
*   **When**: the recorder process exits without the user pressing Stop.
*   **Then**: the watcher sees it, the bar leaves the recording state, and the
    shell's error popup shows what happened, with the recorder's log as
    details and a Copy action. The state file is cleaned up.

### CUJ 4: Choose a region with the keyboard (phase 2)

*   **Given**: the recording panel is open.
*   **When**: the user chooses "Region" and either draws it with the pointer or
    picks the last used region, or types a size and position.
*   **Then**: the panel shows the chosen region. Cancelling the pointer
    selection returns to the panel with the previous choice kept.

### CUJ 5: Microphone and countdown (phase 3)

*   **Given**: the recording panel is open.
*   **When**: the user turns on the microphone, sets a 5 second countdown and
    presses Start.
*   **Then**: a visible countdown runs, Esc cancels it without recording, and
    after it ends the recording includes the microphone as its own audio track.

### CUJ 6: Webcam overlay with and without a camera (phase 4)

*   **Given**: the recording panel is open.
*   **When**: a camera exists, then it does not.
*   **Then**: with a camera the webcam row is offered and the overlay appears in
    the recording. Without one the row is hidden, and the Ctrl+Space help says
    why.

### CUJ 7: Take a screenshot (phase 5)

*   **Given**: the screenshot panel is open.
*   **When**: the user chooses a target and a destination and confirms.
*   **Then**: the panel closes first so it is not in the picture, and the image
    reaches the chosen destination.

## Technical Plan (Architecture)

### Pieces

```
 keybind / launcher / bar button
            |
            v
   QML panel (record or screenshot)        QML bar popup (state, Stop)
            |                                        ^
            | start/stop (adapter runs script)       | reads state
            v                                        |
   scripts/screen-record  ---writes--->  $XDG_RUNTIME_DIR/ui-shell/record/state.json
        (wrapper, parent of gsr)   |                 ^ inotify wake (FileView)
            |                      +--log--> record.log
            v
   gpu-screen-recorder (writes the video file)
```

*   **`scripts/screen-record`** is the only place that knows gsr. It has four
    commands: `capabilities` (JSON: targets, audio sources, webcam), `start`,
    `stop`, and `status`.
*   **State file** `$XDG_RUNTIME_DIR/ui-shell/record/state.json`, written
    atomically (write a temporary file, then rename). Fields: `state`
    (`starting`, `recording`, `finished`, `failed`), `recorderPid`,
    `recorderStart` (the process start time from `/proc/<pid>/stat`), `started`
    (wall clock), `target`, `audio`, `output`, `log`, `exitCode`, `message`.
*   **Log** `record.log` in the same directory: gsr's stderr, kept for the
    error popup details.
*   **Adapter** `shell/adapters/RecordState.qml`: watches the state file with
    Quickshell's `FileView` (inotify, no polling), re-checks the recorder on
    every read, and exposes `state`, `elapsed`, `error`, `start()`, `stop()`.
*   **Bar button and popup** read the adapter. The popup ticks a one-second
    timer for the elapsed time only while it is visible.
*   **Panels** (`modules/record`, `modules/shot`) call the adapter and the
    scripts. They hold no recording state of their own.

### State and stop rules

1.  `start` checks free space first and refuses to start below the configured
    minimum. It then starts the countdown (a plain `sleep`), and only then
    starts gsr. Esc during the countdown calls `stop`, which cancels it.
2.  `start` runs detached (`setsid`) so a shell reload does not kill it. It is
    gsr's parent: it writes `recording` with gsr's pid and start time, waits
    for gsr, then writes `finished` or `failed` with the exit code. This is the
    one allowed long-lived process, named as the exception to "no daemon".
3.  `stop` sends `SIGINT` to gsr and waits until it exits, so the video file is
    finalised. It never sends `SIGKILL`.
4.  A read is only trusted after the stale check: the state says `recording`,
    but `/proc/<recorderPid>` must exist and its start time must equal
    `recorderStart`. If not, the reader reports `failed` ("the recorder
    stopped without reporting") instead of `recording`. A wrapper killed by
    logout or `SIGKILL` is therefore found on the next read.
5.  Starting while the state is `starting` or a valid `recording` is refused.
    A stale file is replaced.

### Failure path

When the state becomes `failed`, or the stale check fails, the adapter builds
the failure object the shared `ErrorPopup` requires (source `record`, a rising
sequence number, title, message, operation, target, details). The details are
the last lines of `record.log`. Copy works as for every other error.

### Backend seam

`scripts/screen-record capabilities` prints JSON such as
`{ "targets": ["monitor","window","region"], "audio": ["desktop","mic"],
"webcam": true }`. The panel shows only what the backend supports. Replacing
gsr means replacing this script. Codec, bitrate and frame rate are fixed
inside it, so the saved settings hold no backend-specific values.

### Targets

*   **Monitor**: chosen by output name from `hyprctl monitors`.
*   **Window**: chosen by window address from `hyprctl clients`, recorded as
    that window's rectangle at start. If the address no longer exists at start,
    Start refuses with a message.
*   **Region**: `slurp` returns the rectangle. The panel hands over to `slurp`
    and keeps the previous choice if `slurp` is cancelled. For keyboard-only
    use, the panel also accepts the last region or a typed `WxH+X+Y`.
*   A shared picker component supplies target choice to both panels.

### Screenshot

`scripts/screen-shot` runs `grim` (with `slurp` for a region) and `wl-copy`.
It is independent of gsr and the state file. The screenshot panel closes first
(a short delay, as in the reference tools) so it is not in the picture.

### Shell structure

Both domains follow the module pattern used by the audio module:
`modules/record/` and `modules/shot/`, each with a state singleton, a shortcut,
a layer-shell surface that loads its panel asynchronously, and a panel; plus a
`Config.<Domain>` singleton. Only one panel is open at a time, as today. The
bar popup is not a panel: it can open while a panel is closed and does not
close other panels. Every panel uses `PanelContext` for Ctrl+I, Ctrl+Space and
Ctrl+E, and `ExitDialog` for unsaved settings.

### Settings

Each domain registers up to two options in `shell/config/ComponentSpec.qml`
(for example recording: countdown seconds, save folder choice; screenshot:
destination). The component-settings scripts are hardcoded to four names today
and must learn the new component names. Backend-specific values are not saved.

### Webcam (phase 4)

The overlay is a separate process the script starts and stops with the
recording; its pid is part of the state file so Stop ends both. The camera list
comes from `/dev/v4l/by-id`, read when the panel opens.

### Decision recorded for the owner to confirm

*   **State watch**: wrapper plus `inotify` (Option B). Chosen by the author on
    the owner's request for the lowest CPU and a safe design; reverse it if a
    kernel-level process watcher (`pidfd`) turns out to be needed after the
    phase 0 spike.

### Testing

*   A fake backend (a script that sleeps, writes a file and honours `SIGINT`)
    drives the state machine tests: start, stop, double start, stale pid after
    `SIGKILL`, crash with a non-zero exit, countdown cancel, low free space.
*   An optional live check records one second with gsr and validates the output
    with `ffprobe`. It needs a compositor and is not part of the default run.
*   QML tests cover the adapter parsing and the popup states, in the same style
    as the other `tests/tst_*.qml` files.

## Alternatives Considered

Each option below was weighed during brainstorming (`features/reqs/screen-recording.md`) or while drafting this plan, and rejected.

*   **One large panel for everything (as OBS and Better-Recast do).** Rejected:
    it mixes screenshot, recording, replay and streaming settings in one place,
    which is the leakage between domains the owner wants to avoid. Two panels
    with separate settings stay small and can ship independently.
*   **Phases split by domain (capture, audio, countdown, webcam).** Rejected:
    audio, countdown and webcam all belong to recording, so none of them is
    finished without the recording in place, and desktop audio plus microphone
    are two sources in one gsr call. Vertical slices (a recording that works
    end to end, then more targets, then more options) match the real
    dependencies and each slice is usable alone.
*   **A backend interface in QML.** Rejected: with one backend the interface
    would be guesswork, and gsr details (stop signal, flags, audio model) would
    leak into it. A script with `start`, `stop`, `status` and `capabilities` is
    the swap point; replacing gsr means replacing the script.
*   **Finding out whether a recording runs with `pgrep gpu-screen-recorder`.**
    Rejected: it cannot tell the shell's recording from another gsr process,
    and it gives no start time, target, output path or log.
*   **Polling the state on a timer (option A in the plan discussion).**
    Rejected: a recorder that dies while the popup is hidden would go unnoticed
    until the next time someone looks, which defeats a failure alert. It also
    spends a process spawn per tick.
*   **One watcher process using `pidfd` and `inotify` (option C).** Rejected
    for the first version: it adds a second long-lived process to a shell that
    says "no daemon", and needs a helper because bash cannot wait on a `pidfd`.
    It stays available if the phase 0 spike shows that the wrapper approach
    misses real cases.
*   **Rebuilding region, window and monitor selection in QML.** Rejected: `slurp`
    already selects regions, and `hyprctl` already lists windows and monitors.
    The panel hands over to `slurp` and offers a typed or remembered region for
    keyboard-only use.
*   **A full panel for screenshots only if it is cheap.** Kept as a small
    panel, as the owner asked for separate actions with their own settings; it
    reuses the shared picker and `PanelContext`, and its script is about as
    short as a keybind script.
*   **Saving codec, bitrate and frame rate in the settings.** Rejected for the
    first release: backend-specific values would make a backend swap break the
    saved file. Fixed defaults live inside the script.

## Detailed Implementation

This list follows the audio module, which was added the same way, so every
integration point below has a working example in the repository. Phases are
vertical slices; each phase lists only what it adds. No code is written in this
document. Paths are relative to the repository root.

### Phase 0: spike and groundwork (no user-visible feature)

*   `features/designs/screen-recording.md` (this file): record the spike
    results in Open Questions: does gsr's portal mode conflict with a keyboard
    target picker, which capabilities direct capture needs, what the
    start-time check in `/proc/<pid>/stat` returns for gsr on this machine,
    whether `FileView` with `watchChanges` wakes on an atomic rename.
*   `shell/config/ComponentSpec.qml`: allow the new component names (`record`,
    `shot`) with their option lists. Today it has `launcher`, `wallpaper` and
    `audio`. This is the data the settings popup renders from.
*   `scripts/component-settings-path` and `scripts/save-component-settings`:
    both hardcode the allowed component names; add `record` and `shot` so a
    settings file can be located and saved. Without this the Ctrl+E popup
    rejects the new domains.
*   `scripts/read-shell-config`: add the new optional command keys
    (`screenRecord`, `screenShot`, `renderRecordSettings`, `renderShotSettings`)
    to the defaulted list and to the exact-key check, as was done for
    `audioGraph`. This lets older installed manifests keep loading.
*   `tools/config.ini`: map the same command keys to their scripts, so the
    runtime knows where each script is.
*   `tests/scripts/check-component-settings`: add cases for the two new
    components (valid values saved, invalid values rejected, the stale
    revision conflict), so the generalised scripts stay correct.

### Phase 1: recording script, state, bar popup, monitor with desktop audio

New files:

*   `scripts/screen-record`: the backend script. Commands `capabilities`,
    `start`, `stop`, `status`. Owns every gsr flag, the fixed codec, bitrate
    and frame rate, the free-space check, the countdown (`sleep`), detached
    start (`setsid`), the atomic state file, the log, `SIGINT` stop with wait,
    and the stale check. Why: it is the one place that must change to swap
    recorders.
*   `scripts/render-record-settings`: writes the saved recording options (for
    example countdown seconds) into a generated QML settings file, like
    `scripts/render-audio-settings`. Why: the settings popup saves through
    generated files, not through QML.
*   `shell/adapters/RecordState.qml`: reads the state file with `FileView`
    (`watchChanges`), runs the stale check on every read, builds the failure
    object for `ErrorPopup`, exposes `state`, `elapsed`, `error`, `start()` and
    `stop()`, and runs the script through the same keyed-process pattern as
    `AudioGraph.qml`. Why: panels and the bar popup must share one source of
    truth.
*   `shell/adapters/qmldir`: register `RecordState` (modified).
*   `shell/config/Record.qml`: singleton with panel width and height, margins,
    padding, `asynchronousPanelLoad`, the shortcut app id and name, the
    minimum free space in MB, the state directory name, and the elapsed-time
    tick. Why: the project keeps tunables in `config/`, not in components.
*   `shell/config/qmldir` and `shell/config/Config.qml`: register `Record` and
    add `screenRecordEnabled` (modified), as `audioControlEnabled` exists.
*   `shell/modules/record/RecordState.qml` (module state singleton; name it
    `RecordPanelState` to avoid clashing with the adapter), `RecordShortcut.qml`,
    `RecordSurface.qml` (async loader, layer-shell namespace
    `ui-shell-record`), `RecordPanel.qml`, `qmldir`, and `EGM.md`. The panel in
    this phase has a monitor list (keyboard and mouse), a desktop audio
    switch, and Start. It uses `PanelContext` for Ctrl+I, Ctrl+Space and Ctrl+E,
    and `ErrorPopup` for failures.
*   `shell/modules/bar/RecordButton.qml` and `RecordPopup.qml`: the bar button
    (idle or recording mark) and its popup (state, elapsed time, target, audio
    sources, Stop). The popup ticks a one-second timer only while visible.
    Why: the owner asked for a per-domain state popup in the bar.
*   `shell/modules/bar/Bar.qml` (modified): add the button, gated by
    `Config.screenRecordEnabled`, as the Apps button is gated today.
*   `shell/shell.qml` (modified): load the shortcut and surface, add the
    mutual-exclusion `Connections` entry for the new state singleton, and
    create the adapter once at shell scope so the bar popup works while no
    panel is open.
*   `shell/theme/EGM.md`, `shell/modules/EGM.md`, `shell/adapters/EGM.md`,
    `shell/config/EGM.md`, `shell/EGM.md` (modified): add the new contracts and
    side effects (a long-lived wrapper process, the runtime-directory state
    file).
*   `hypr/profile.lua` (modified): a `screen_record` key (key and target, as
    `audio_control`). `hypr/binds/shell.lua` (modified): the bind that fires the
    global shortcut. `hypr/rules.lua` (modified): add `ui-shell-record` to the
    namespace regex.
*   `tests/scripts/check-screen-record`: fake-backend state machine tests (see
    Testing). Registered in `tests/targets.mk` as `test-record` (modified), and
    documented in `tests/README.md` (modified).
*   `tests/record/fake-recorder`: the fake backend (sleeps, writes a file,
    handles `SIGINT`, can be told to exit non-zero).
*   `tests/tst_RecordState.qml`: adapter parsing, the stale and failed cases and
    the failure object shape. Added to the list in `tests/scripts/check-qml`
    (modified).
*   `tests/scripts/test-nested` (modified): pass `UI_SHELL_OPEN_RECORD` and a
    preview state variable so the panel and popup can be rendered headlessly.
*   `README.md` and `STYLE.md` (modified): document the recording panel and
    name the state file as the one allowed exception to "no daemon".

Done when: CUJ 1, 2 and 3 pass, `make test-qml` and `make test-record` pass,
and a one second live recording validates with `ffprobe`.

### Video settings (added after phase 2)

Frame rate (24 to 144), quality preset (medium to ultra), codec (automatic, h264, hevc, av1, vp9), a fixed bitrate from a list (2.5 to 80 Mbps; it replaces the quality preset with constant-bitrate encoding), container (mp4, mkv) and cursor are options of the `record` component, edited in Ctrl+E next to the countdown and desktop audio. To hold seven options the shared settings popup now lists any number of options from `Config.ComponentSpec` (scrolling when long); choices can be strings with labels; `scripts/render-record-settings` takes all seven values; `screen-record start` takes them as flags and maps them to the recorder. Measured on this GPU: h264, hevc and vp9 work, av1 makes gsr fall back to h264 with a warning (the script puts that warning in the state), vp8 is refused with an error. Audio is always opus (explicit `-ac opus`; not an option). Not offered: free-form bitrate, resolution cap, colour range, audio codec and the save folder (the folder needs a path option kind the settings spec does not have yet).

### Explicit device pickers (added after phase 5)

Desktop audio, microphone and webcam are pickers, not on/off switches: Off, the default device, and every device the recorder can use (`screen-record audio-sources`: outputs' monitors and applications for desktop audio, inputs for the microphone; `cameras` for the webcam). The script takes `--desktop-audio no|default|device:ID|app:NAME` and `--microphone no|default|device:ID` (`yes` still means default); a chosen device that has vanished is dropped with a warning. Picks are kept for the session; Ctrl+E booleans only decide the starting pick. Defaults: mkv container, opus audio, `<XDG Videos>/records` and `<XDG Pictures>/screenshots`. Verified live: a specific output with a specific input gave two audio tracks; one application gave one.

### UI patterns adopted from the references

From `features/studies/screen-recording-ui.md`: the countdown is shown where the user looks (bar chip and popup, with Cancel; reel, Better-Recast); the bar clock slot has a fixed width and ticks while a recording runs (reel); the panel is the domain's control centre and shows the live state with Stop focused, and the global key only toggles the panel, so one key never means two things (the pattern sexy-screenshot gets wrong); the last saved file is shown with its size and a Copy path button; panel sections stay fixed while only long lists scroll (reel). Skipped for now: presets (Better-Recast), per-application audio sources (Better-Recast), single-key action hints (against the shell's no-permanent-hints rule).

### Phase 2: window and region targets (implemented)

Built as designed, with these measured details: the recorder takes `-w WxH+X+Y` (global layout coordinates; `-region` is deprecated), a window is recorded as its rectangle resolved at the end of the countdown and cropped to the screens, a vanished window or a region outside every screen is refused with a clear message, a region is selected by `slurp` through `screen-record pick-region` (remembered for the session in the state directory) or typed as `WxH+X+Y`, and the panel's window hides while `slurp` runs but the panel keeps its choices. `TargetPicker` is pure presentation, shared with the later screenshot panel.

*   `shell/components/TargetPicker.qml` (new, registered in
    `shell/components/qmldir`): the shared picker for monitor, window and
    region used by both domains. Lists windows from `hyprctl clients` and
    monitors from `hyprctl monitors`, keeps a stable identity (address, output
    name), and offers the typed or remembered region.
*   `shell/adapters/TargetSource.qml` (new, registered in `qmldir`): runs the
    listing commands and the `slurp` hand-over and keeps the previous choice
    when `slurp` is cancelled.
*   `scripts/screen-record` (modified): accept `monitor:NAME`,
    `window:ADDRESS` and `region:WxH+X+Y`; refuse a window that no longer
    exists.
*   `shell/modules/record/RecordPanel.qml` (modified): use the picker.
*   `tests/tst_TargetPicker.qml` (new): keyboard navigation, cancelled
    selection keeps the previous value, vanished window message.
*   `tests/scripts/check-screen-record` (modified): window and region cases.

### Phase 3: microphone and countdown (implemented)

Built with these details: the microphone is a second `-a default_input` track (verified live: two audio streams); it is a panel switch and a Ctrl+E option, unavailable (with a reason line) when gsr lists no input; the countdown is shown in the panel, the bar chip and the popup, a cancel during it deletes nothing because nothing was recorded, and with a countdown the panel stays open (Esc cancels) and leaves one second before the recorder starts so it is not in the first frames. Verified live: a 3 s countdown delayed the first frame and the file holds only the recording.

*   `scripts/screen-record` (modified): microphone as a second audio track,
    `--countdown N`, cancel through `stop`.
*   `shell/modules/record/RecordPanel.qml` (modified): microphone switch,
    countdown row, a visible countdown, Esc cancels it.
*   `shell/config/ComponentSpec.qml` (modified): `record` options (countdown
    seconds, and one more such as the audio default).
*   `scripts/render-record-settings` (modified): write both options.
*   `tests/scripts/check-screen-record` and `tests/tst_RecordState.qml`
    (modified): microphone flag, countdown cancel, and settings round trip.

### Phase 4: webcam overlay (implemented)

The overlay is `mpv` showing the camera (`av://v4l2:<by-id path>`) in a small floating window with the app id `ui-shell-webcam`; a Hyprland window rule (`hypr/rules.lua`, sizes in `hypr/profile.lua` `webcam_overlay`) floats, pins and places it in the bottom-right corner without taking focus. Because it is part of the screen, any target that contains it records it. `screen-record cameras` lists the by-id `*-video-index0` nodes; the overlay starts before the countdown (so the user can frame themselves) and the wrapper removes it on every way out; a status read also removes an overlay whose wrapper died. The panel offers a Webcam switch only when a camera and the player exist, and says why otherwise; Ctrl+E has a `webcam` default. Verified: 95 script checks with a fake camera directory and a fake player, and the window rule and mpv arguments in the nested session with a test video source (floating, pinned, 320x180 at the corner). Not verified: a real camera (none on this machine) and the first camera is always used.


### Phase 5: screenshot panel (implemented)

`scripts/screen-shot capture TARGET [--copy] [--save] [--delay]` (grim, wl-copy; a window's rectangle comes from `screen-record window-region`), `Adapters.ShotRunner`, `modules/shot`, `Config.Shot`, the `shot` settings component (clipboard, file) and `Super+P`. The panel hides while the picture is taken. Two findings: `wl-copy` forks and keeps its inherited pipes open while it serves the clipboard, so a caller that waits for the output pipe to close hangs (the script now silences it); and a screenshot, unlike a recording, works in the nested test session. Verified live with real grim and wl-copy: region and window sizes exact, clipboard holds a PNG.


### Brain

Phase 1 adds a timeline entry on `screen-capture-module` for the state-file
exception and the wrapper design; each later phase adds an entry only if a
decision settles. All through the `brain` CLI.
