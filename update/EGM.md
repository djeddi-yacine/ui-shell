# update

## Overview
The install, update and rollback machinery. `activator` is installed once as `~/.local/bin/update-ui-shell` and runs the whole flow under a lock: refusals, a shallow clone, `git verify-tag` against the pinned key, one `run` call per phase, a process recheck, the rename of `current`, and self-update. Releases are built read-only under `DATA_DIR/releases/<tag>`; user data lives in the separate user directory (`ui_config_name=user-wm-shell`) and is changed only by migrations. The crossing from the development layout is in [./crossing/EGM.md](./crossing/EGM.md); migration rules are in [../migrations/EGM.md](../migrations/EGM.md).

## Interface
- `activator` [activator]: the installed program (`update-ui-shell [--tag TAG | --dry-run | --rollback | --force]`). Exit codes: 0 done or already current, 1 failed with state intact, 2 usage, 3 refused, 4 pending marker.
- `install-activator` [install-activator]: run once from a checked-out tag; prints the signer's primary fingerprint, waits for the user to type the one the README shows, pins `update/signer.asc` (mode 0600) and installs the activator. A different primary is refused unless `--repin`. Exit 0 done, 1 failed, 2 usage, 3 refused.
- `run` [run]: update logic of a verified clone, one phase per call (`UI_SHELL_UPDATE_MODE` = `build`, `check`, `migrate`) with `UI_SHELL_UPDATE_{TAG,CLONE,DATA,CONFIG,STATE,CACHE}`.
- `rollback` [rollback]: `--rollback` body, run from the active release with the lock held; exits 0 done, 1 failed with the marker left, 3 refused.
- `run-migrations [--list|--baseline] RELEASE CONFIG STATE PREVIOUS_READS_MAX [PENDING_FILE]` [run-migrations]: applies migrations without a marker, in timestamp order. Exit 0 done, 1 stopped, 2 usage.
- `snapshot save|restore NAME CONFIG STATE` [snapshot]: exit 0 done, 1 failed, 2 usage, 3 refused (no space, no snapshot).
- `prune DATA_DIR STATE_DIR` [prune]: removes releases other than `current` and `previous`, leftover `*.tmp` releases and orphan snapshots; exit 3 while a process uses the release tree or when the data shape would lie outside every remaining range.
- `process-guard` [process-guard]: exit 0 when no Hyprland, `qs`, `quickshell` or release user exists, else exit 1 with one `pid name reason` line per finding.
- `build-release CLONE TARGET TAG` [build-release], `assemble-shipped` [assemble-shipped] (the read-only `shipped/` themes and profiles), `check-release RELEASE_DIR SCRATCH_DIR` [check-release] (rehearsal against a scratch copy of user data).
- `seed-cliphist-config` [seed-cliphist-config] with `cliphist-config`; `seed-menu-entry SOURCE_ROOT MENU DATA_HOME` [seed-menu-entry] with `uuctl.desktop`: seed user files only when absent or stale.
- `lib` [lib]: sourced, never executed. Shared definitions: `ui_config_name`, `ui_version_sort`, `ui_valid_path`, `ui_valid_tag`, the marker (`ui_marker_write`, `ui_marker_read`), the key helpers (`ui_key_load`, `ui_key_signs`, `ui_key_format`, `ui_key_export`), `ui_crash_point`, `ui_link_tag`, `ui_link_set`, `ui_write_atomic`.
- `signer.asc` [signer.asc]: the public release key (the pinned primary is published in the README).
- `crossing/` [./crossing/EGM.md].

## Invariants
- The pinned key's primary must have signed the tag; expired, revoked, bad and other-key signatures refuse with exit 3, and the signed tag object must name the requested tag (a republished tag name is refused) [activator:tag_verifies].
- Nothing of a clone runs before its tag verifies [activator].
- A release is never changed after its final rename and holds no symlink; `current` and `previous` are the only links changed, by rename [build-release, lib:ui_link_tag].
- A pending marker (phase `started`, `built`, `migrating n/m`, `activating`, `checking`, `rolling-back`) blocks the next update with exit 4 until `--force` or `--rollback` [lib:ui_phases, activator].
- An older tag than the active one and a re-update to an existing release tag are refused; `-rc` ranks below its release [lib:ui_version_sort, activator].
- The updater never writes user configuration except through migrations; release trees are read-only [build-release, run-migrations].
- Prune and update refuse while a process uses the release tree [process-guard, prune].
- `lib` has one definition of the marker and the validated `UI_SHELL_UPDATE_*` environment, shared by `activator` and `run` [lib].

## Side Effects
- Network: a shallow clone of the repository named in `activator` (tests override it only with `UI_SHELL_UPDATE_TEST=1`).
- Disk: `DATA_DIR/releases/<tag>[.tmp]`, `current`, `previous`, the pinned key in the state directory, the pending marker, migration markers, `STATE/snapshots/`, the activator copy in `~/.local/bin`, cache clones and `.check-<tag>` scratch directories (removed on exit).
- Seeds `~/.config/cliphist/config` and the user's `uuctl.desktop` entry only when absent or stale.
- Takes a lock for the whole run; `gpgconf --kill all` for its private keyring after verification.

## Verification
- Run: `make test-update test-activator test-crash test-migrations test-crossing`
