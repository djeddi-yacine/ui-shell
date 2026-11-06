# ui-shell

Focused Quickshell UI and Hyprland configuration for a personal desktop. The shell UI lives in `shell/`, compositor policy in `hypr/`, installed runtime helpers in `scripts/`, and development staging in `tools/scripts/stage-config`.

## Requirements

Developed on Arch Linux with Hyprland and Quickshell. Needed on `PATH`: `quickshell`, `hyprland`/`hyprctl`, `hyprpaper`, `app2unit`, `matugen` (4.x), `jq`, `ripgrep`, `python3`, ImageMagick (`magick`), `bubblewrap` (`bwrap`), `flock` (util-linux), `systemd-run`, `foot`, and the Qt 6 tools `qmllint`, `qmltestrunner` and `qmlls` (Arch installs them under `/usr/lib/qt6/bin`; `make dev-lint` takes `QMLLINT=...` for another location, and `.vscode/settings.json` names `qmlls`). The optional Phantomat plugin additionally needs `cmake`, `ninja`, `g++`, `pkg-config` and Hyprland's development headers, built from a checkout in `refs/phantomat` (`refs/` is not tracked; clone reference repositories there, then `make refs-pull` updates them). The Phantomat plugin must match the installed Hyprland version.

## Wallpapers

The project wallpapers in `wallpapers/` are not tracked in git (about 25 MB). `wallpapers/manifest.txt` lists each file with its SHA-512 and download URL, and `tools/scripts/fetch-wallpapers` downloads what is missing or does not match, keeping a file only after its hash agrees (`--check` verifies without downloading). The test runner calls it first, so `make test*` and `make test-env` fetch the images on demand. The images live on a free third-party image host, so if a link ever dies the script says which file failed; replace the file, update its manifest line, and the hash pins whatever you upload.

## Audio panel

**Super+M** opens the audio control (tabs: Output, Input, Playback, Recording, Cards, Patchbay) and **Super+T** the control tuning; Ctrl+Space inside either lists its keys, Ctrl+I explains it and Ctrl+E opens its options. `make test-env` binds the HOST PipeWire socket, so everything you change in the audio panel (volume, mute, defaults, routing, links) is real (`UI_SHELL_HOST_PIPEWIRE=0 make test-env` keeps audio private); `make test-audio` stresses the same code on a private PipeWire that cannot reach your devices.

## Screen recording

**Super+R** opens the recording panel (choose a screen, a window or a region; desktop audio; countdown; Start); the same key only opens or closes the panel: while a recording runs the panel shows its clock and target with Stop focused, so a stray key press never ends a recording. The bar's **Rec** button shows the countdown and then the elapsed time, and opens a popup with Stop (Cancel during the countdown). After a recording, the panel shows what was saved, with its size and a Copy path button; a save is announced once (the first time the panel shows it) and only while its file still exists, so old or deleted recordings are never mentioned again. The panel has explicit pickers for desktop audio (the default output, a specific output, or one application), the microphone (the default input or a specific one) and the webcam; a pick is remembered for the session, and Ctrl+E only sets where they start. Files go to `<XDG Videos>/records` as mkv with opus audio; screenshots go to `<XDG Pictures>/screenshots`. Ctrl+Space, Ctrl+I and Ctrl+E work as in the other panels; Ctrl+E holds the recording options (countdown, desktop audio, microphone, frame rate, quality, codec, audio codec (opus or aac), bitrate, container, cursor, webcam; audio is always opus). Recording uses GPU Screen Recorder through one script, `scripts/screen-record`; it is the only place that knows the recorder. `make test-record` checks its state machine with a fake recorder (no screen, no GPU). GPU Screen Recorder captures real monitors through the GPU, so it cannot record inside `make test-env` (the panel says it sees no screen there); use `make dev-run` on your real desktop, and `make test-record-live` to check the real recorder. The design and its later phases (window and region targets, microphone, webcam, screenshots) are in `features/designs/screen-recording.md`.

## Screenshot

**Super+P** opens the screenshot panel: choose a screen, a window or a region, choose the clipboard, a file or both (Ctrl+E sets the defaults), and press Capture. The panel hides while the picture is taken so it is not in it, then shows what was saved, with its size and a Copy path button. It uses `grim` and `wl-copy` through one script, `scripts/screen-shot`, and works inside `make test-env` too (a screenshot needs no GPU access). `make test-shot` checks the script with stand-ins; `make test-shot-live` takes real screenshots of this desktop.

## Authentication

When a program needs a privilege (`pkexec`, a package install), the shell shows its own password dialog: a message, the account, one field that shows nothing while you type, and Enter or Esc. A wrong password ends the request. Polkit allows one agent per session, so `hyprpolkitagent` must be stopped first: `systemctl --user stop hyprpolkitagent`, restart the shell, and check with `pkexec true`. To go back, stop the shell and run `systemctl --user start hyprpolkitagent`. If the shell cannot register, the bar shows "No auth agent". Nothing is claimed about screen recordings until `tests/README.md` "Authentication dialog, live" has been run. `make test-auth` checks the layer rule; the dialog and the polkit logic are in `make test-qml`.

## Quick start

Run `make test-env` to open the persistent private nested session with popups closed. Nested shortcuts use Ctrl+Alt: Ctrl+Alt+W opens the wallpaper picker, Ctrl+Alt+Space opens the launcher, Ctrl+Alt+Q opens foot, and Ctrl+Alt+Escape exits gracefully from any submap. Production bindings continue to use Super. The nested session's preferences and cache stay under `.test-state/nested/`; run `make test-env-clean` only when deliberately resetting private choices and cache. Cleaning reseeds the private manifest, profile selection, clean default seed, and missing default stores from source defaults while preserving every Theme definition byte-for-byte, including imported and edited definitions. Host configuration/data and source files remain untouched.

Run `make test-import-themes` with the persistent session closed to convert the configured `100-themes` collection into inactive palette definitions. It preserves existing committed profiles and selections. Imported Themes appear as palette choices; saving and applying one with the current wallpaper creates a committed profile.

Run `make help` for targets grouped into test environments, checks, and development commands. `make test` runs the test suite. `make dev-run` uses the host display. See [test environments and checks](tests/README.md), [configuration](CONFIGURATION.md), [shell architecture](shell/README.md), and [theme palettes](shell/theme/README.md).

Run `make refs-pull` to update Git repositories directly inside `refs/`. It fast-forwards when possible and merges when needed, even if Git is configured for `ff-only` or rebase. Dirty repositories are skipped; other failures are reported without stopping the remaining pulls. The target returns a failure status if any repository was skipped or failed.

Wallpaper and colors form one draft: open the picker with `Ctrl+Alt+W` in a nested session or `Super+W` in production, choose an image, press Enter or **Choose theme**, choose a Theme palette or wallpaper-derived colors, then **Save and apply**. Back preserves the draft; closing the picker discards it. Nothing changes on the desktop before the final action. See [editor controls and color roles](docs/themes.md).
