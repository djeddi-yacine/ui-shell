# Screen capture and recording

* **Author:** djeddi-yacine
* **Date:** 2026-11-06
* **Status:** brainstorm brief, draft 2. All six review lenses are in; decisions resolved, ready for /egm-draft.

Input: `features/studies/screen-recording.md`. This file records what we need from it.

## Overview

A screenshot action and a screen-recording action that share one launcher but are otherwise separate. Each action has its own keyboard-friendly panel with its own settings, so options from one never leak into the other. The recording panel lets the user choose the capture target (region, window or monitor), desktop audio, microphone, a countdown, and a webcam overlay that is offered only when a camera exists. A button in the bar opens a small popup that shows the state and controls of one domain: whether it is recording, how long, and a Stop control. GPU Screen Recorder (gsr) is the recorder. The code is built so another recorder (for example `wl-screenrec`) could replace it later. The work is built in phases, and a finished phase means one domain is complete and usable alone.

Out of scope: pause and resume, instant replay, streaming, trimming, noise filtering.

## Analysis

The reviewers agree on five problems. They are listed from most to least serious.

1. **A recording cannot be "stateless".** gsr runs for minutes as a long-lived process. "Is it recording", elapsed time and Stop all need state that outlives the panel, the bar popup and even a shell reload. Every reviewer asked who owns that state. A pid file alone is not enough: after a crash or `SIGKILL` the file stays and lies. A read must check that the process behind the pid is still gsr (name and start time) and treat a dead pid as "failed", not "idle". This makes recording the one named exception to the shell's "no daemon" rule (`shell/EGM.md`). The exception should be written down, not hidden.
2. **Late failures have no path to the user.** `ErrorPopup.present` needs a source, a sequence number, a title, a message, an operation, a target and details (`shell/components/EGM.md`). If gsr dies three minutes after start, nothing is watching. Something that stays alive (a process held by the bar popup, or a poll of the state file) must notice, and gsr's stderr must go to a log file in the runtime directory so the error popup has details to show. Stop must send `SIGINT` and wait for exit, because a killed recorder leaves a corrupt MP4.
3. **Region selection needs a pointer, but every action needs a keyboard path** (`STYLE.md`). The panel must hand over to `slurp` and come back with the selection intact if the user cancels. Keyboard-only users need a fallback: the last remembered region or a typed size and position. Window and monitor choice need a stable identity (window address, output name) and a defined outcome when the target disappears before the recording starts.
4. **The domain split is partly false.** Desktop audio, microphone, countdown and webcam all belong to recording, not to capture. Audio plus mic are two sources in one gsr call. The webcam overlay is a separate mpv process in the reference tools, with its own life cycle, and gsr has no webcam compositing, so it would be our own compositor. A phase split by vertical slice (screenshot; record with system audio; then the extras) matches the real dependencies better than a split by domain.
5. **The swappable backend is a name until a second backend exists.** The reference tools use gsr specifics: its stop signal, its flags, its audio model. `wl-screenrec` has no mic mixing and no webcam. A real seam would be one script with `start`, `stop` and `status` plus a small capability description (which targets, audio sources and webcam options this backend supports) that the panel reads and uses to hide unsupported options. Without that, swapping means rewriting QML.

Migration and compatibility (reported by the sixth lens; the portal claim was not checked on this machine):

* **Existing binds (dropped).** This is built for the new shell, not for the host's current Hyprland config, so the host's `grimblast` binds are not a constraint. The shell still needs a CLI entry that keybinds can call, so the actions work without the bar.
* **Portal and permissions.** The reference tools use gsr's portal backend, which shows its own picker and prompts and may duplicate or bypass our target picker. Direct capture needs extra capabilities. Nothing in the repo tests either. A short spike on this machine should come before any schema or interface work.
* **Settings schema.** `shell/config/ComponentSpec.qml` allows two options per component, of kind boolean, integer or choices, and the save and path scripts are hardcoded to four component names. Audio and mic toggles, countdown and a camera device fit that shape; a backend id or a device name does not. Backend-specific values (codec, bitrate) stay out of the saved settings file so a backend swap cannot break it.
* **Backend interface.** Define it from the actions needed (start, stop, status), not from gsr's flags.
* **Webcam detection.** A camera can be plugged in after the panel opens; decide whether detection runs once at open or on a refresh key.
* **Screenshot path.** The grim and slurp route keeps screenshots entirely off gsr.

Smaller points that need an answer before building:

* No free-space guard: auto-pause is out of scope, so a long recording on a full disk fails late. Check free space at start and refuse below a threshold.
* The bar popup needs elapsed time. Derive it from the start time in the state file and tick once per second only while the popup is visible; do not start a process per tick.
* The webcam overlay costs CPU on top of the GPU encode. If kept, offer one fixed size only. Camera detection should happen when the panel opens, not at install time.
* Two monitors or two GPUs: pick the encoder device once with a detect step and record one output at a time.
* Fixed defaults for codec and bitrate avoid giant files; decide whether quality is exposed at all.
* A countdown needs a visible indicator and Esc must cancel it. `sleep N` before gsr is enough as the mechanism.
* Esc order and the exit rule apply as in the audio panel; use Ctrl+I, Ctrl+Space and Ctrl+E rather than new key schemes. The Ctrl+Space help should say why the webcam row is missing when there is no camera.
* The screenshot action is about 40 lines on `grim`, `slurp` and `wl-copy`. A full panel for it may be more than it deserves.
* Target picking duplicated across two panels will go stale; share one picker component and keep separate settings.
* Testing without a screen: fake the backend for state, stale-pid and crash tests, and add an optional live check that validates the output file with `ffprobe`. The audio test works only because PipeWire can run privately; gsr needs a compositor.

## Goals vs. Non-Goals

* **In-Scope Goals:**
  * Recording with target choice (region, window, monitor) from a keyboard-reachable panel.
  * Desktop audio and microphone control.
  * Countdown.
  * Webcam overlay, offered only when a camera exists (phase to be decided, see below).
  * A screenshot action that shares the launcher.
  * A bar button and popup per domain with state and Stop.
  * Settings isolated per domain through the Ctrl+E popup.
  * A recorder backend behind one script seam.
* **Out-of-Scope Non-Goals:** pause and resume, instant replay, streaming, trimming, noise filtering, HDR, upload and sharing, a recording history list.

## Alternatives Weighed

* **Everything in one app-sized panel (as OBS or Better-Recast do):** rejected. It mixes screenshot, recording, replay and streaming settings, which is the leakage the user wants to avoid.
* **Full panel for screenshots:** challenged by the YAGNI review. Not yet decided; see the open decisions.
* **Phases by domain (capture, audio, countdown, webcam):** challenged. Audio, countdown and webcam attach to recording, so they do not finish "alone". Vertical slices are proposed instead.
* **A QML-level backend interface:** challenged. A script contract (`start`, `stop`, `status`, capability list) is cheaper and survives a backend swap.
* **Poll `pgrep gpu-screen-recorder` for state:** rejected. It cannot tell our recording from another one and cannot give start time, target or output path.
* **Rebuilding target selection in QML:** rejected in favour of handing off to `slurp`, which already selects region, window and monitor.

## Key Decisions & Staging for Next Steps

Settled by the user's answers:

* Separate actions sharing a launcher, separate settings per domain.
* All three target types, chosen from the panel with keyboard access.
* Controls for desktop audio, microphone, countdown and webcam overlay (webcam only when present).
* A bar button with a popup showing state and controls for that domain.
* Done means one finished domain per phase, composable.
* GPU Screen Recorder, behind a swappable backend.

Resolved from the user's stated principles (isolated domains, vertical slices, keyboard access, new shell only). Reopen any of these if wrong:

1. Recording is the one named exception to "no daemon". State file in the runtime directory (pid, start time, target, output path, log path) with a stale-pid check on every read.
2. A wrapper script (gsr's parent) writes the exit result to the state file, and the shell wakes on `inotify` and shows failures in the shared error popup. No separate watcher process (changed during design drafting; see `features/designs/screen-recording.md`). Stop sends `SIGINT` and waits.
3. The backend is one script, `scripts/screen-record` (`start`, `stop`, `status`, capabilities), tested first with a fake backend. The panel reads the capabilities and hides what the backend cannot do. No QML backend interface.
4. Region: hand off to `slurp`, keep the selection on cancel. Keyboard-only fallback: the remembered last region or a typed size and position.
5. Phases are vertical slices, each usable alone:
   * Phase 0: spike on this machine for gsr portal behaviour and permissions, and extend the component-settings spec and scripts to cover new components.
   * Phase 1: `screen-record` script, state file, watcher, bar button and popup (state, elapsed time, Stop); monitor recording with desktop audio.
   * Phase 2: window and region targets, with the shared picker.
   * Phase 3: microphone and countdown.
   * Phase 4: webcam overlay, only when a camera exists.
   * Phase 5: screenshot action with its own small panel (mode and where the result goes), on `grim`, `slurp` and `wl-copy`; it can be built earlier because it does not depend on gsr.
6. Screenshot stays a separate action with its own panel and settings, as the user asked, but stays small. It shares the launcher and the target picker.
7. Codec, bitrate and fps use fixed defaults in the first release. Settings stay within the two-options-per-component limit of the settings spec.
8. The webcam overlay is kept but built last (phase 4).
9. A CLI entry point (`scripts/screen-record`, and a matching screenshot script) so keybinds can trigger the actions.
10. A free-space check at start refuses to record below a threshold.
