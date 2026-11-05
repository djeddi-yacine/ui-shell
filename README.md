# ui-shell

Focused Quickshell UI and Hyprland configuration for a personal desktop. The shell UI lives in `shell/`, compositor policy in `hypr/`, installed runtime helpers in `scripts/`, and development staging in `tools/scripts/stage-config`.

## Requirements

Developed on Arch Linux with Hyprland and Quickshell. Needed on `PATH`: `quickshell`, `hyprland`/`hyprctl`, `hyprpaper`, `app2unit`, `matugen` (4.x), `jq`, `ripgrep`, `python3`, ImageMagick (`magick`), `bubblewrap` (`bwrap`), `flock` (util-linux), `systemd-run`, `foot`, and the Qt 6 tools `qmllint`, `qmltestrunner` and `qmlls` (Arch installs them under `/usr/lib/qt6/bin`; `make dev-lint` takes `QMLLINT=...` for another location, and `.vscode/settings.json` names `qmlls`). The optional Phantomat plugin additionally needs `cmake`, `ninja`, `g++`, `pkg-config` and Hyprland's development headers, built from a checkout in `refs/phantomat` (`refs/` is not tracked; clone reference repositories there, then `make refs-pull` updates them). The Phantomat plugin must match the installed Hyprland version.

## Wallpapers

The project wallpapers in `wallpapers/` are not tracked in git (about 25 MB). `wallpapers/manifest.txt` lists each file with its SHA-512 and download URL, and `tools/scripts/fetch-wallpapers` downloads what is missing or does not match, keeping a file only after its hash agrees (`--check` verifies without downloading). The test runner calls it first, so `make test*` and `make test-env` fetch the images on demand. The images live on a free third-party image host, so if a link ever dies the script says which file failed; replace the file, update its manifest line, and the hash pins whatever you upload.

## Quick start

Run `make test-env` to open the persistent private nested session with popups closed. Nested shortcuts use Ctrl+Alt: Ctrl+Alt+W opens the wallpaper picker, Ctrl+Alt+Space opens the launcher, Ctrl+Alt+Q opens foot, and Ctrl+Alt+Escape exits gracefully from any submap. Production bindings continue to use Super. The nested session's preferences and cache stay under `.test-state/nested/`; run `make test-env-clean` only when deliberately resetting private choices and cache. Cleaning reseeds the private manifest, profile selection, clean default seed, and missing default stores from source defaults while preserving every Theme definition byte-for-byte, including imported and edited definitions. Host configuration/data and source files remain untouched.

`make test-env-persistent` explicitly names that same saved-state session. Run `make test-import-themes` with the persistent session closed to convert the configured `100-themes` collection into inactive palette definitions. It preserves existing committed profiles and selections. Imported Themes appear as palette choices; saving and applying one with the current wallpaper creates a committed profile.

Run `make help` for targets grouped into test environments, checks, and development commands. `make test` runs the test suite. `make dev-run` uses the host display. See [test environments and checks](tests/README.md), [configuration](CONFIGURATION.md), [shell architecture](shell/README.md), and [theme palettes](shell/theme/README.md).

Run `make refs-pull` to update Git repositories directly inside `refs/`. It fast-forwards when possible and merges when needed, even if Git is configured for `ff-only` or rebase. Dirty repositories are skipped; other failures are reported without stopping the remaining pulls. The target returns a failure status if any repository was skipped or failed.

Wallpaper and colors form one draft: open the picker with `Ctrl+Alt+W` in a nested session or `Super+W` in production, choose an image, press Enter or **Choose theme**, choose a Theme palette or wallpaper-derived colors, then **Save and apply**. Back preserves the draft; closing the picker discards it. Nothing changes on the desktop before the final action. See [editor controls and color roles](docs/themes.md).
