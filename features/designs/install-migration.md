# Install, update and migration

*   **Author:** djeddi-yacine
*   **Status:** Resolved against the Goldfish review (2026-11-11), awaiting owner approval
*   **Date:** 2026-11-11

--------------------------------------------------------------------------------

Predecessors: `concepts_brief.md` (brainstorm), `features/reqs/install-migration.md` (requirements draft 1), `features/studies/install-migration.md` (study of Omarchy's updater, ids `OM<n>`), brain page `install-update-migration`.

## Overview

The shell is a Quickshell/QML desktop shell with Hyprland configuration, run on Arch Linux. It has no installer. The only deployment is `make dev-stage` and the test staging, which copy `scripts/`, `shell/` and `hypr/` into `$XDG_CONFIG_HOME/ui-shell/` beside the user's own files.

This design adds one manual command, `update-ui-shell`, that installs and updates tagged releases. Each release is built into its own directory and is read-only after the build. A symlink, `current`, names the active release and changes by one atomic rename as the last step. User data lives in a different directory that only versioned migrations change. A lock and a pending marker detect an update that crashed. `--rollback` returns to the previous release.

The command is for the owner and for any other Arch user of the shell. It runs from a TTY with no shell and no Hyprland session running.

### Terms

*   **Release**: one tagged version of the shell, built under `$XDG_DATA_HOME/ui-shell/releases/<tag>/`. Its id is its tag.
*   **Active release**: the release `current` points at. **Previous release**: the release active before the last successful update. At most these two are kept.
*   **Path owner**: the one program allowed to write a directory. The updater owns the data and state directories; migrations (and the user, by hand) own the user directory; the shell at start owns the cache. **Project owner**: the person who maintains the shell and decides its architecture; "the owner" in this document means that person.
*   **Shape**: a positive integer naming the layout of user data. A migration declares the shape it produces. The current shape is the highest shape recorded in the migration markers.
*   **Reads range**: `reads_min` and `reads_max` in a release's `manifest.ini`: the shapes that release can read.
*   **Pending marker**: the file `update/pending` in the state directory, written when an update starts and removed when it ends.
*   **Crossing**: the one-time script that moves a machine from today's `make dev-stage` layout into the new layout.
*   **Activator**: the small installed program `update-ui-shell`.

## The Problem

Four things are wrong with the copy-over-a-directory model.

1.  **Nothing records what was installed.** A file deleted from the source stays on disk. A half-finished copy can be loaded by a running shell.
2.  **User data and shipped code share one tree.** `themes/`, `profiles/`, `config.ini`, `hypr/user/*.lua` and component override files sit beside `hypr/`, `scripts/` and `shell/`. `tools/scripts/stage-config` protects them with special cases (the `restore_policy` trap that preserves `hypr/user/monitors.lua`, refusals on symlinked directories). Each new user file needs another special case.
3.  **The shipped tree is written at run time.** `scripts/prepare-runtime` writes `GeneratedRuntime.qml`, `GeneratedWallpapers.qml` and the `ProfileBundle` link inside the Quickshell root, and `scripts/render-shell-launcher-output` writes `GeneratedLauncherOutput.qml` into `shell/config/`. A tree that is checksummed and read-only cannot hold them. Some user-edited files also live in the shipped tree (`hypr/profile.lua`, the baseline options in `shell/config/*.qml`).
4.  **A change in the shape of user data has no path.** If a release renames a theme key, the user's files break, and there is no way back to a release that still understands them.

Other Arch users will run the shell, so an update that fails half-way must be detectable and recoverable without knowing the code.

## Goals

*   One command, `update-ui-shell`, installs the first release and updates later ones from tagged releases, run by hand, never automatically.
*   An update is applied only from a TTY with no session process running and nothing running from inside the release tree.
*   Releases are read-only after the build and covered by `SHA256SUMS`. Activation is one atomic rename of `current`.
*   All generated output is written to the cache at shell start, stamped with the release id. The release tree is never written after the build.
*   A release declares the shapes it reads. A migration moves data only within what the previous release still reads, unless it takes a snapshot first. `--rollback` is a symlink swap when the current shape is in the previous release's range.
*   A crashed update leaves a pending marker. The next run refuses, names the phase, and offers `--force` or `--rollback`.
*   Migrations are scripts `migrations/<unix-timestamp>-<slug>` shipped in each release. One marker file per applied script holds its checksum and shape. The runner selects scripts by set difference against the markers.
*   Release tags are verified by `git verify-tag` against a pinned OpenPGP signer key (the primary key's fingerprint), in the activator, before any code from the clone runs.
*   `--dry-run` rehearses the update on a copy and prints the plan. It changes nothing the shell reads.
*   A machine with today's `make dev-stage` layout and a clean machine use the same entry. The old directory is never written.
*   Phantomat stays an optional setting. The updater neither builds nor ships the library.
*   The nested sandbox (`make test-env`) tests the updater: install, crossing, update, rollback and every failure case in the Verification Plan.

## Non-Goals

*   Automatic or background updates, and applying an update while a session runs.
*   Starting the shell from a display manager. The only supported start is `scripts/start-session` from a TTY.
*   Building or shipping the Phantomat library.
*   A graphical update flow, and distributions other than Arch.
*   Resuming an interrupted update. `--force` starts again from the beginning. `--force` restores no snapshot.
*   Automatic fallback after a failed boot, an automatic rollback after a crash, a `failed` marker state, and a shell notice for a leftover marker. The refusal on the next run is the only signal.
*   Automatic rotation of the signer's primary key. Renewing or replacing a signing subkey of the same primary needs no prompt (`update/install-activator` refreshes the pin); a different primary needs `update/install-activator --repin` and the typed fingerprint.
*   Typed settings with a schema and deprecation lifecycle (requirements phase 4). Component property names stay frozen until then.
*   The render-hash scheme for files written for other programs (requirements item 16b). The integration list is short and hard-coded.
*   Config directories reached through symlinks. They stay unsupported, as the existing symlink refusals in the scripts already state.
*   Most per-generation fixture homes. The first version has one fixture for the crossing and the update and rollback round trip.
*   Retention above two releases.

## Critical User Journeys (CUJs)

### CUJ 1: First install on a clean machine

*   **Given**: An Arch machine with the shell's dependencies, no `$XDG_DATA_HOME/ui-shell`, no `$XDG_CONFIG_HOME/user-wm-shell`, and a TTY with no Hyprland running.
*   **When**: The user checks out a tag, runs `update/install-activator`, confirms the signer fingerprint by typing the one the README shows, then runs `update-ui-shell`.
*   **Then**: `releases/<tag>/` exists with a matching `SHA256SUMS`, `current` points at it, the user directory holds the shipped baseline `settings.ini` and empty `themes/` and `profiles/` plus the shipped defaults, every shipped migration has a marker, and `scripts/start-session` starts the shell.

### CUJ 2: Move from the `make dev-stage` layout

*   **Given**: Today's staged layout at `$XDG_CONFIG_HOME/ui-shell/` with themes, profiles, `config.ini` and `hypr/user/*.lua`.
*   **When**: The user runs `update-ui-shell`.
*   **Then**: The crossing copies user data once into `$XDG_CONFIG_HOME/user-wm-shell/`; the normal update flow then builds the first release and activates it. The old directory is not written and stays until the user removes it. A failure before the final rename leaves the old layout working.

### CUJ 3: A normal update

*   **Given**: A release is active and a new tag exists.
*   **When**: The user stops the session, switches to a TTY, runs `update-ui-shell --dry-run`, reads the plan, then runs `update-ui-shell`.
*   **Then**: The release is built, rehearsed on a copy of user data, pending migrations run in timestamp order with one marker each, `current` is renamed, post checks pass, and the pending marker is removed.

### CUJ 4: Crash in the middle of an update

*   **Given**: An update was killed after migration 2 of 3.
*   **When**: The user runs `update-ui-shell`.
*   **Then**: It refuses with exit code 4, prints the phase, the target and the applied migrations, and names `--force` (restart) and `--rollback` (when the shape range allows).

### CUJ 5: Rollback

*   **Given**: The new release is active and the shell misbehaves.
*   **When**: The user logs out and runs `update-ui-shell --rollback` from a TTY.
*   **Then**: `current` points at the previous release. If the current shape is outside that release's reads range and no snapshot exists for the migration that raised it, the command refuses and says which shape and which range.

### CUJ 6: Signature check fails

*   **Given**: The tag was altered, unsigned, or signed by another key.
*   **When**: The user runs `update-ui-shell`.
*   **Then**: It exits 3 before any file of the clone runs. Nothing changes under the data, user, state or cache directories: the pending marker written at step 3 is removed and the clone is deleted.

### CUJ 7: A session is running

*   **Given**: Hyprland, `qs` or `quickshell` runs, or any process uses a file under `releases/`.
*   **When**: The user runs `update-ui-shell` (or `--rollback`).
*   **Then**: It exits 3, lists each offending pid, command name and reason, and changes nothing.

## Technical Plan (Architecture)

### Command surface

| Invocation | Effect | Exit codes |
|---|---|---|
| `update-ui-shell` | Update to the newest tag, or install if no `current` exists. | 0 done or already current; 1 failed with state intact; 3 refused; 4 pending marker present |
| `update-ui-shell --tag TAG` | Update to one tag. Older than active is refused. | same |
| `update-ui-shell --dry-run` | Rehearse on a copy and print the plan. Takes the lock, writes no pending marker, changes nothing the shell reads. | 0, 1, 3 |
| `update-ui-shell --rollback` | Swap `current` to the previous release as described in Rollback. | 0, 1, 3, 4 |
| `update-ui-shell --force` | After a pending marker: delete the partial target and start again. | 0, 1, 3 |
| `update/install-activator` | Pins the signer key and installs `~/.local/bin/update-ui-shell`. Run once from a checked-out tag. | 0, 1, 2, 3 |

Exit codes are disjoint: 0 done, 1 failed with state intact, 2 usage error, 3 refused (session running, bad signature, older tag, rollback outside range), 4 pending marker present.

### Layout

Four directories, each with one owner. The updater writes nothing outside them except the integration list below.

```text
$XDG_DATA_HOME/ui-shell/                owner: the updater
  releases/<tag>/                       read-only after build; contains SHA256SUMS
    update/ scripts/ shell/ hypr/ migrations/ default/ bundled-themes/ wallpapers/ manifest.ini
  current -> releases/<tag>             the only mutable pointer; swapped by rename
$XDG_CONFIG_HOME/user-wm-shell/         owner: migrations and the user
  settings.ini  themes/  profiles/  lua/ (monitors, nested, canvas)
  components/                           saved component settings, written by the Settings UI
$XDG_STATE_HOME/ui-shell/               owner: the updater
  update/lock  update/pending
  migrations/<timestamp>-<slug>         one marker per applied migration (checksum, shape)
  snapshots/<migration>/                only for a migration that cannot be read both ways
  signer.asc                            pinned OpenPGP public key (armored), mode 0600
$XDG_CACHE_HOME/ui-shell/               owner: the shell at start and the updater for scratch
  clone/                                shallow clone of the repository
  runtime/                              all generated output, stamped with RELEASE
  .check-<tag>/                         rehearsal copy
~/.local/bin/update-ui-shell            the activator
```

The old `$XDG_CONFIG_HOME/ui-shell/` is never written by the new code. `user-wm-shell` is the name the owner chose (2026-11-11).

### The activator and the release

The **activator** is installed once by `update/install-activator` from a checked-out tag, after the user confirms the signer fingerprint by hand. Its jobs, in order:

1.  Take the lock (`flock` on `update/lock`, shared with `scripts/start-session`).
2.  Refuse if a pending marker exists, or a session process exists.
3.  Clone the tag shallowly into `cache/clone/` and run `git verify-tag --raw` in isolation against a private GnuPG home that holds only `signer.asc`; the status output must show a valid signature whose primary fingerprint is the pinned one and no expired, revoked or bad signature. No file of the clone runs before this passes.
4.  Run the update logic of the verified clone (`update/run`) once per phase with `UI_SHELL_UPDATE_MODE` set to `build`, `migrate` or `check`. The other `UI_SHELL_UPDATE_*` names are `TAG`, `CLONE`, `DATA`, `CONFIG`, `STATE` and `CACHE`; the repository URL is a constant in the activator, not an environment value.
5.  Re-run the process check, create the symlink `current.new` to the new release, then rename it onto `current`.
6.  If the verified clone carries a newer `update/activator`, replace `~/.local/bin/update-ui-shell` by the same atomic rename.

`--rollback` and pruning run `update/` from the active release, so they work when the cache is cleared.

A release is identified by its tag. Tags are ordered with version sort. Installing a tag older than the active one is refused: use `--rollback`. `manifest.ini` of a release lists every shipped address (commands, renderers, bootstrap targets, wallpaper entries, `paths.userLua`) and `reads_min`, `reads_max`.

### Update flow

```text
update-ui-shell
  1. take the lock; refuse if update/pending exists
  2. refuse if a session process exists (Process detection)
  3. write update/pending {target, previous, start, phase=started}        atomic write
  4. clone tag; git verify-tag (on failure: remove update/pending and the clone, exit 3)   phase=started
  5. build releases/<tag>.tmp; write SHA256SUMS; rename to releases/<tag> phase=built
  6. rehearsal in cache/.check-<tag>: copy user data and markers, run migrations there,
     run read-shell-config, prepare-runtime and Hyprland --verify-config against the copy
  7. run migrations on real user data in timestamp order, one marker each phase=migrating n/m
     (snapshot first when the migration's shape exceeds previous reads_max)
  8. re-run the process check; write phase=activating; rename current.new -> current
  9. post checks: SHA256SUMS, read-shell-config                           phase=checking
 10. remove update/pending; prune beyond two releases
 11. run the integration seeds; a failing seed prints its reason and the command exits 1,
     with the update complete and no pending marker
```

`--dry-run` stops after step 6, deletes the rehearsal copy, and prints the release id, files added, removed and changed, pending migrations, and shapes.

### Crash handling

The pending marker is written by temp file, `fsync`, rename, then `fsync` of the directory. It holds the target, the previous release, the start time and the phase.

| Phase | Written when | State on disk if the process dies here |
|---|---|---|
| `started` | step 3 | possibly a clone; nothing else |
| `built` | after step 5 | complete release directory, not active |
| `migrating n/m` | before each migration | n-1 markers written, user data possibly mid-migration |
| `activating` | before the rename | `current` may or may not point at the target |
| `checking` | after the rename | `current` points at the target |
| `rolling-back` | start of `--rollback` | snapshot possibly half-restored, `current` not yet swapped |

One rule: any leftover marker makes the next run refuse (exit 4) and print the phase, the target and the applied migrations. Recovery never deletes the directory that `current` or `previous` resolves to. `--force` compares `readlink current` with the target: if `current` already names the target (phases `activating`, `checking`), it re-runs the post checks read-only and clears the marker when they pass; when they fail it leaves the marker and says to run `--rollback`. Otherwise it deletes `releases/<tag>.tmp` and the partial target, and restarts at step 1; applied migrations are skipped by their markers and migrations must be idempotent. Stray `releases/*.tmp` directories are removed at the start of any run.

### Generated output

All generated output is written to `$XDG_CACHE_HOME/ui-shell/runtime/` by `scripts/start-session` (before Hyprland starts) and by the existing mid-session helpers (`select-theme-profile`, `refresh-theme`, `prepare-palettes`). It includes `config.json`, `config.lua`, `GeneratedRuntime.qml`, `GeneratedWallpapers.qml`, `GeneratedLauncherOutput.qml` and the `ProfileBundle` link. A `runtime/RELEASE` stamp holds the release id; `scripts/start-session` regenerates when it differs from `current`, and `hypr/runtime.lua` fails closed with a message naming `start-session` when the stamp is missing or differs. Absolute paths in generated files point through `current`, never a resolved release directory, so a swap changes what they reach. The three `Generated*.qml` files leave `shell/config/` (see Files modified); the shell imports them from the cache.

The cache directory is a tree of links into `current/shell/` with these files beside the links. Step 0.1 proves this before any code is written. There is no fallback: if the step fails, the plan stops and the owner decides.

### Paths and settings

`manifest.ini` (release-owned, read-only) holds shipped addresses. `settings.ini` (user-owned) holds only user choices: theme profile, wallpaper folders, Phantomat settings, and override values for user-edited component options. `scripts/read-shell-config` reads both and fails if `settings.ini` redefines a shipped address. The audit in Step 0.4 lists every write site under the release and moves each user-edited value into `settings.ini`. User Lua loads through `hypr/userlua.lua` only (see Files modified); `paths.userLua` in `manifest.ini` names the user directory. `paths.components` names `components/` in the user directory, where `scripts/save-component-settings` writes the settings saved from the UI (`scripts/component-settings-path:19-33`); it is never inside the release.

### Migrations and shape ranges

A migration is an executable `migrations/<unix-timestamp>-<slug>` in the release. Its header declares `shape: N`. It receives `UI_SHELL_CONFIG_HOME`, `UI_SHELL_STATE_HOME`, `UI_SHELL_RELEASE` (read-only) and `UI_SHELL_DRY_RUN`. It must be idempotent and change only user data and state. The runner selects scripts by set difference against the marker files, in timestamp order. The marker records the script checksum and `N`. A script whose checksum differs from its marker stops the update; the fix is a new migration. A marker whose script is absent from the release is reported and kept. Two scripts with one timestamp stop the build. A non-zero exit stops the update with the phase marker left in place.

The current shape is the highest `N` over the markers. When `N` exceeds the previous release's `reads_max`, the runner first copies all of user config to `snapshots/<migration>/` with `cp --reflink=auto`, and refuses the migration if free space is insufficient. This is the only free-space check.

### Rollback

`--rollback` runs from `update/` of the active release, so it needs no network and no clone. Steps:

1.  Take the lock; refuse if a pending marker exists (exit 4) or a session process exists (exit 3).
2.  Require a previous release; otherwise refuse (exit 3).
3.  Write the pending marker with `phase=rolling-back`, the active release as `previous` and the previous release as target.
4.  Compare the current shape with the target's reads range. Inside the range: go to step 6. Outside: require a snapshot for the migration that raised the shape; without one, remove the marker and refuse (exit 3), naming the shape and the range.
5.  Restore the snapshot, delete the migration markers written after it, and print that edits made since the update are lost.
6.  Re-run the process check, swap `current` to the target by rename, and make the former active release the new previous release.
7.  Run the post checks (`SHA256SUMS`, `read-shell-config`), remove the pending marker.

Pruning refuses to remove a release if the current shape would then lie outside the remaining releases' ranges.

### The crossing

The crossing is the frozen script `update/crossing/0001-from-dev-stage`. It runs from the verified clone only when no `current` exists and a directory `$XDG_CONFIG_HOME/ui-shell/` with `config.ini` and `scripts/` is found. It copies `themes/`, `profiles/`, component overrides and `hypr/user/*.lua` (to `lua/`) once into `$XDG_CONFIG_HOME/user-wm-shell/`, translates the old `config.ini` into `settings.ini`, writes a marker for every migration shipped in the release, and never writes the old directory. It handles shape 1 only. A clean install runs the same entry: there is no old directory, so the shipped baseline `settings.ini` and defaults are written instead, followed by the same markers.

### Process detection

`update/process-guard` scans `/proc` for processes of the current user only. It reports a process named `Hyprland`, `qs` or `quickshell`, and any process whose working directory, open file or mapped file is under `$XDG_DATA_HOME/ui-shell/releases/`; "running from inside the release tree" means that. An unreadable entry counts as in use. The check runs at step 2 and again before the rename at step 8, under the lock, because the lock stops a second update but not a session that started during the build. The scan sees only processes of the current user. The abort at step 8 leaves user data safe only for migrations the previous release reads; for a migration that raised the shape beyond that, the user then runs `--rollback`, which restores the snapshot.

### Session start

`scripts/start-session` is the only supported start. It takes the lock shared with the activator and refuses while `update/pending` exists, validates `settings.ini`, regenerates the cache runtime when the stamp differs, and `exec`s Hyprland with the active release's configuration. It exists because `hypr/runtime.lua` reads `runtime/config.lua` while Hyprland parses its configuration, before any shell code can regenerate it.

### Trust

The threat boundary: a tampered or substituted release, and a corrupted download. Not covered: a compromised signer key, and a user who confirms a wrong fingerprint. `git verify-tag` runs in an isolated process with only `signer.asc` imported into a temporary GnuPG home, never the user's keyring. `SHA256SUMS` is a corruption and bit-rot check, not an authenticity check, because it is built locally. Tags only: there is no `main` route. The first tag is verified with the key pinned at install; the README shows the fingerprint to compare.

### Integration list

Every path the updater writes besides the data, user, state and cache directories, plus the one state file written by the installer. Seeds run after the post checks pass and write only when absent unless the rule says otherwise.

| Path | Source | Rule |
|---|---|---|
| `~/.local/bin/update-ui-shell` | `update/activator` | atomic rename; replaced only by a verified release |
| `$XDG_DATA_HOME/applications/uuctl.desktop` | `update/seed-menu-entry`, from `update/uuctl.desktop` | only when `uuctl` is installed; an existing file with a stale `Exec` is rewritten to `current/scripts/menu` |
| `cliphist` configuration | `update/seed-cliphist-config` | fails when `XDG_RUNTIME_DIR` is unset (a TTY may lack it), says why, and is run again by `scripts/start-session` |
| Hyprland entry | none | the updater writes no entry file; `scripts/start-session` starts `Hyprland --config` with `current/hypr/hyprland.lua` |
| `$XDG_STATE_HOME/ui-shell/signer.asc` | `update/install-activator` | mode 0600; refreshed (merged, revocations kept) by a key of the same primary, replaced by a different primary only with `--repin` and the typed fingerprint |

### Phantomat

`profile.phantomat.enabled` and the mode stay in the profile. The library path is an optional key in `settings.ini`. `scripts/read-shell-config` stops requiring `paths.phantomatLibrary` (it is in the `exact()` key list at `:35`; the reader ships in the release, and `settings.ini` is a new file, so no user data needs a migration). When the profile enables Phantomat and the key is absent, `hypr/phantomat.lua` asserts with a message naming the key. Only the `mode` assertion in `hypr/phantomat.lua` moves behind the enabled check (`:4-9`; the canvas require is `:120`).

## Alternatives Considered

### Alternative A: In-place sync driven by a checksum manifest

*   **Pros**: No release directories and no `current` symlink. Smaller disk footprint.
*   **Cons**: A crash leaves a mix of old and new files. Each file needs stale-file and user-edit handling. Rollback has no cheap form.
*   **Reason for Rejection**: Rejected by author: atomic activation and a cheap rollback are the main goals, and a directory swap gives both.

### Alternative B: Apply the update at the next boot through a user unit

*   **Pros**: The update is staged while the desktop runs, so there is no TTY step.
*   **Cons**: The apply step runs unattended; a failure shows up as a broken session with no operator.
*   **Reason for Rejection**: Rejected by author: "never automatic" is a constraint. It stays possible later because the apply step is a function the unit could call.

### Alternative C: A single `flock` for crash detection

*   **Pros**: No marker file to write.
*   **Cons**: The kernel releases the lock when the process dies, so a crash leaves no trace.
*   **Reason for Rejection**: Rejected by author: the lock stops two updates at once and the durable pending marker detects a crash.

### Alternative D: One ledger file for applied migrations

*   **Pros**: One file to read; a high-water mark is a single number.
*   **Cons**: A crash while writing can damage the record of every migration. A high-water mark cannot represent a script merged late with an older timestamp.
*   **Reason for Rejection**: Rejected by the owner: one marker per migration is more explicit and a crash cannot damage the others.

### Alternative E: A second installed command for the first install

*   **Pros**: Installer and updater stay separate programs.
*   **Cons**: Two commands to document and keep consistent; the user must know which applies.
*   **Reason for Rejection**: Rejected by author: the same `update-ui-shell` entry handles a machine with no `current`.

### Alternative F: Seed-once copying into user config

*   **Pros**: Simple. It is what `tools/scripts/stage-defaults` does today.
*   **Cons**: After copying, the updater cannot tell whether the user edited the file, so a later shipped default never reaches the user.
*   **Reason for Rejection**: Rejected by author: shipped addresses live in the release-owned `manifest.ini`; the user's `settings.ini` holds choices only.

### Alternative G: Generated output split into release-built and user-dependent

*   **Pros**: Release-only output is checksummed with the release.
*   **Cons**: `scripts/prepare-runtime:18-23` feeds the user's profile and theme into the catalog and `GeneratedRuntime.qml`, so no generated file is release-only. The split reduces to "everything regenerated" with extra rules.
*   **Reason for Rejection**: Rejected by the owner: all generated output lives in the cache.

### Alternative H: Generate everything at build time into the release

*   **Pros**: Every file is covered by `SHA256SUMS`.
*   **Cons**: Output that depends on the user's themes, profiles and wallpaper folders is stale after the first edit, and a rebuild breaks read-only.
*   **Reason for Rejection**: Rejected by the owner: it cannot hold user-dependent output.

### Alternative I: Snapshot restore as the common rollback path

*   **Pros**: One path for rollback. No reads-range metadata.
*   **Cons**: Edits made after the update are lost on every rollback; a snapshot is needed for every release rollback can reach.
*   **Reason for Rejection**: Rejected by the owner: ranges make rollback a symlink swap; snapshots only for shape-raising migrations.

### Alternative J: Read-time converters, user config never rewritten

*   **Pros**: Nothing to restore and no runner for reshaping files.
*   **Cons**: Old-shape readers stay in the code for as long as rollback can reach them, and a format change still needs a migration.
*   **Reason for Rejection**: Rejected by the owner as the common path. A release may still use it inside its reads range.

### Alternative K: The clone's own code does verification and the swap

*   **Pros**: No installed component to maintain.
*   **Cons**: A broken release can break its own update path, and nothing trusted exists to run `git verify-tag` before clone code executes.
*   **Reason for Rejection**: Rejected by the owner: a small installed activator verifies the tag first.

### Alternative L1: Signer key shipped inside the activator

*   **Pros**: No fingerprint prompt.
*   **Cons**: Rotating the key means reinstalling the activator, and a leaked activator copy carries the trust root.
*   **Reason for Rejection**: Rejected by the owner.

### Alternative L2: An Arch package as the only install route

*   **Pros**: `pacman` updates the activator.
*   **Cons**: Needs root and a maintained PKGBUILD; splits the install between two owners.
*   **Reason for Rejection**: Rejected by author: `update/install-activator` serves user-space installs and is the step a PKGBUILD could call later.

### Alternative M1: The smallest possible version

*   **Pros**: Least code to keep correct.
*   **Cons**: Defers the pending marker, signing and the migration runner until the first real migration, so that release lands several untested pieces at once.
*   **Reason for Rejection**: Rejected by the owner: the first version is the smallest version plus the marker, signed tags and the runner.

### Alternative M2: All 18 requirements items at once

*   **Pros**: The full scope is built once.
*   **Cons**: Highest cost; typed settings and the render-hash scheme pay off only after the first real shape change.
*   **Reason for Rejection**: Rejected by the owner: they are deferred.

### Alternative N: Self-heal or automatic rollback after a crash

*   **Pros**: Fewer commands after a crash.
*   **Cons**: The updater deletes or reverts without being asked; a wrong phase label turns self-healing into data loss, and a rollback can be refused by the shape range.
*   **Reason for Rejection**: Rejected by the owner: any leftover marker refuses and `--force` restarts.

### Alternative O: Generated QML as a module on `QML_IMPORT_PATH`, no link tree

*   **Pros**: No cache link tree; avoids the root-escape import pattern Quickshell blackholes (`scripts/prepare-runtime:26-33`).
*   **Cons**: Unproven; depends on how `hypr/session/commands.lua:13-14` passes the Quickshell path.
*   **Reason for Rejection**: Rejected by author: the owner wants no implicit fallbacks. The link tree is the design; Step 0.1 proves it, and a failure stops the plan.

### Alternative P: One shared manifest owned by the user (old `config.ini` stays)

*   **Pros**: One file; no new settings file.
*   **Cons**: Shipped addresses (about 48 paths, `[commands]` and `[profile_renderers]` resolve against `$root`, `scripts/read-shell-config:28,42`) would be rewritten by the crossing and by every release that adds a command, and a defaults block would be needed.
*   **Reason for Rejection**: Rejected by the owner: a release-owned `manifest.ini` plus a small `settings.ini`.

### Alternative Q: Rollback, verify and prune run from the clone

*   **Pros**: No `update/` inside the release.
*   **Cons**: The clone sits in a cache that may be cleared; `--rollback` would then need a network fetch.
*   **Reason for Rejection**: Rejected by the owner: `update/` ships inside each release.

### Alternative R: Convert the old directory in place

*   **Pros**: One directory.
*   **Cons**: The old layout stops working as soon as `config.ini` is rewritten, before `current` exists; old `scripts/`, `quickshell/` and `hypr/` trees stay inside the user directory.
*   **Reason for Rejection**: Rejected by the owner: a new user-directory name.

### Alternative S: Keep user-edited baseline files inside the release

*   **Pros**: No new override mechanism.
*   **Cons**: Conflicts with a read-only checksummed tree (`CONFIGURATION.md:62`, `tests/scripts/nested-session`'s `sed -i` on a staged `AppLauncher.qml`).
*   **Reason for Rejection**: Rejected by the owner: user-edited values move to `settings.ini`.

## Detailed Implementation

Citations were checked against the repository on 2026-11-11 (`rg` and direct reads); line numbers move with edits. No code is given. Contracts (`EGM.md`) for new directories are created with `/egm-bootstrap`, never by hand.

### Step 0: Facts that decide the plan

Findings already recorded (reads, 2026-11-11):

*   **0.2 Which output is release-only: none.** `scripts/prepare-runtime:18-23` takes the user's profile and theme into the bundle, the catalog and the runtime files; `:38` renders `GeneratedRuntime.qml` from that JSON. Nothing is release-only, so all generated output is cache output.
*   **0.3 Theme and profile roots.** `tools/scripts/stage-defaults:26-44` copies the shipped default theme, default profile and bundled reference themes into the user's `themes/` and `profiles/` when absent. The updater may not write user config, so the readers (`scripts/read-theme-profile`, `scripts/theme-catalog`) accept a second read-only search root `current/default/` and `current/bundled-themes/`; user entries with the same id win. Decided by the owner (Open Item 1).

Prerequisites still to run before code, each as a throwaway test outside the repository with a recorded result:

1.  **0.1 Quickshell through links.** Check that `qs --path <cache runtime directory>` loads `shell.qml`, resolves relative imports and the `ProfileBundle` module through a tree of links into `current/shell/` with the generated QML as real files beside them, and that after `current` is repointed a new `qs` sees the new files. Pass: loads and resolves. Fail: stop and report to the owner. There is no automatic fallback.
    **Result (2026-11-11): pass.** Throwaway config outside the repository, Quickshell 0.3.2, `QT_QPA_PLATFORM=offscreen`, private `XDG_*` directories. Two layouts both passed: (A) directory links for `components/` plus a real `config/` holding per-file links, a real generated file and the `ProfileBundle` link; (B) per-file links only. A file reached through a link that imports `../config` resolves to the cache's `config/` (the real generated file and the `ProfileBundle` link), not to the release's own `config/`. After `current` was repointed with `mv -T`, a new `qs` loaded the new release's files, also when the old and new file had the same size and mtime. Limits: the real shell tree was not loaded; the throwaway run wrote no QML disk-cache file, so stale compiled-cache behaviour is untested. `update/build-release` therefore does not preserve source mtimes (see its row); the real shell must be checked once through links when Phase 1 first runs it.
2.  **0.4 Write audit of the release.** List every write site under the shipped tree (`rg` for `sed -i`, redirects and `mv` into `shell/`, `hypr/`, `scripts/` from every script and test) and move each user-edited value into `settings.ini`. Add a test that runs the shell and the test suite with the release mounted read-only and fails on any write.
    **Production audit (2026-11-11, reads only):** no production script or QML file writes into `shell/`, `hypr/` or `scripts/`. The only writer was `scripts/prepare-runtime` (generated QML and the `ProfileBundle` link), which moves to the cache. `rg` for `sed -i`, `setText`, `writable` and redirects or `mv` into those trees found nothing else in `scripts/`, `tools/scripts/` or `shell/`. Writers of user data already target user paths: `save-theme-profile`, `select-theme-profile`, `publish-theme-bundle` (`paths.themes`, `paths.profiles`, `profileCache`) and `save-component-settings` (`paths.components`). Gaps found: (1) `paths.components` had no home in the layout; it is now `components/` in the user directory. (2) `read-theme-state:22` and `read-wallpaper-selections:6` read `paths.hypr + "/user/monitors.lua"`; they move to `paths.userLua`. Write sites in tests, all on a staged copy, that must be redirected to the user directory or a scratch copy: `tests/scripts/nested-session:20` (`sed -i` on staged `AppLauncher.qml`, the case Open Item 2 waits on), `tests/scripts/check-defaults:40-44`, `tests/scripts/check-theme-profiles:191`, `tests/scripts/test-nested:385` (reads `hypr/user/nested.lua`). Still to do: the read-only run of the shell and the test suite that fails on any write.

### Files created

| File | Purpose |
|---|---|
| `update/activator` | The installed program. Interface: the verbs in the command surface. The repository URL is a constant in the file. Jobs: lock, refuse on a pending marker or a session, clone, `git verify-tag`, call `update/run` per phase, process recheck, rename, self-update. It also runs `--rollback`, `--force` and pruning from `update/` of the active release. Uses `bash`, `git`, `coreutils`, `jq`, `flock`. |
| `update/install-activator` | Run by the user from a checked-out tag. Prints the signer fingerprint, waits for the user to type the fingerprint shown in the README, writes `$XDG_STATE_HOME/ui-shell/signer.asc` (mode 0600) and installs the activator. The key file is `update/signer.asc`. The fingerprint is the primary key's, typed in any case with or without spaces. A key of the same primary refreshes the pin without a prompt; a different primary is refused unless `--repin` is given. |
| `update/run` | Update logic, called by the activator with the lock held. No arguments; the activator sets `UI_SHELL_UPDATE_MODE` (`build`, `migrate`, `check`), `UI_SHELL_UPDATE_TAG`, `UI_SHELL_UPDATE_CLONE`, `UI_SHELL_UPDATE_DATA`, `UI_SHELL_UPDATE_CONFIG`, `UI_SHELL_UPDATE_STATE` and `UI_SHELL_UPDATE_CACHE` (absolute, validated like `scripts/read-shell-config:9-16`). `build` covers step 5, `check` step 6 and 9, `migrate` step 7; the activator does steps 1 to 4, 8 and 10. |
| `update/lib` | Shared functions: atomic marker write (temp, `fsync`, rename, directory `fsync`), phase names, path validation, logging. One file so activator and runner cannot disagree on the marker format. |
| `update/build-release` | Builds `releases/<tag>.tmp` from the clone: copies `update/ scripts/ shell/ hypr/ migrations/ default/ bundled-themes/ wallpapers/` (the seeds live in `update/`), never `tests/`, `refs/`, `features/`, `brain/`, `tools/`. Fills the wallpaper-folder entries of `manifest.ini` with the release paths. No symlinks inside the release. Does not preserve source mtimes: every copied file gets the build time, so a compiled-QML cache keyed on size and mtime cannot match a file of another release (Step 0.1 caveat). Writes `manifest.ini` and `SHA256SUMS` (sorted, relative paths, excludes itself). Stops if the target directory already exists. `chmod -R a-w` last. |
| `update/check-release` | `RELEASE_DIR SCRATCH_DIR`. Verifies `SHA256SUMS`, runs `read-shell-config` on the scratch settings and `prepare-runtime` with `UI_SHELL_RUNTIME*` pointed at the scratch directory, then `Hyprland --verify-config`. Writes nothing the running release reads. |
| `update/run-migrations` | The runner described in Migrations. Honours `UI_SHELL_DRY_RUN=1` by listing only. |
| `update/process-guard` | The `/proc` scan, one entry. Exit 0 when clear; otherwise prints pid, command name and reason. |
| `update/rollback` | The rollback flow. |
| `update/prune` | Removes releases beyond two (never `current`, never previous), `*.tmp` directories and orphan snapshots. Runs `chmod -R u+w` before `rm`. Calls `process-guard`. |
| `update/snapshot` | Copies all of user config with `cp --reflink=auto` to `snapshots/<migration>/`, and restores it. |
| `update/seed-menu-entry`, `update/uuctl.desktop`, `update/seed-cliphist-config` | The integration seeds, moved from `tools/scripts/` because the release must carry them. |
| `update/crossing/0001-from-dev-stage` | The crossing (see Technical Plan). Idempotent. |
| `migrations/README.md` | The migration interface text, so the first author has the rules in the tree. The directory has no migration in the first version. |
| `scripts/start-session` | The session entry (see Session start). |
| `hypr/userlua.lua` | `load(name)`: validates `name` against `[a-z_]+`, takes the user Lua directory from the runtime manifest (`paths.userLua`, not `os.getenv`), `loadfile`s the user file and otherwise `hypr/default/<name>.lua`. No merging. A user file that errors stops Hyprland's parse with the path in the message. |
| `tests/scripts/check-update` | Fixtures: clean install, update, no-op update, dry-run changes nothing, refused while a fake `qs` runs, refused with leftover marker, `--force` restart, rollback within range, rollback outside range with and without snapshot. |
| `tests/scripts/check-crossing` | Fixture of today's layout (monitors policy, custom theme, component override): crossing and update; every user file arrives byte-identical; old tree untouched; second run is a no-op. |
| `tests/scripts/check-crash` | `UI_SHELL_UPDATE_CRASH_AT=<phase>` (read only when `UI_SHELL_UPDATE_TEST=1`) kills `update/run` at each phase in the table, including between a migration and its marker and between the rename and the `checking` write; asserts the recovery text and that `--force` never deletes what `current` or `previous` resolves to. |
| `tests/scripts/check-activator` | Throwaway OpenPGP keys: good tag passes; unsigned tag, wrong-key tag, altered tag and a tag signed by an expired signing key refuse; refresh of the same primary and `--repin`; a tag whose scripts would write a canary file refuses before the canary exists. |
| `tests/scripts/check-release-readonly` | Runs the suite against a read-only release (Step 0.4). |
| `tests/fixtures/update/` | Fixture homes and a local bare repository with signed tags built at run time; nothing signed is committed. |
| `update/EGM.md`, `migrations/EGM.md` | Contracts, created by `/egm-bootstrap` with `target_filename="EGM.md"` after the code exists. |

### Files modified

| File | Change and reason |
|---|---|
| `scripts/read-shell-config` | Reads `manifest.ini` and `settings.ini`; `paths.phantomatLibrary` leaves the `exact()` key list (`:35`); fails if `settings.ini` redefines a shipped address; reuses `:9-16` for root validation. |
| `scripts/read-theme-state`, `scripts/read-wallpaper-selections` | Read the monitor policy through `paths.userLua` instead of `paths.hypr + "/user/monitors.lua"` (`read-theme-state:22`, `read-wallpaper-selections:6`). |
| `tools/config.ini` | Replaced by two shipped templates: `manifest.ini` (release-owned) and a baseline `settings.ini`. |
| `scripts/prepare-runtime` | Writes all generated output and the profile module link into the cache runtime directory. The ownership test at `:25-27` is rewritten against the cache runtime root. Writes the `RELEASE` stamp. |
| `scripts/compile-theme-profile` | Reuses the generation publish pattern at `:75-82`; no change in behavior; checked for writes into the release. |
| `scripts/read-theme-profile`, `scripts/theme-catalog` | Accept the read-only second root (Step 0.3). |
| `scripts/render-shell-launcher-output` | Writes to the cache runtime path. CONFIGURATION.md examples updated. |
| `hypr/runtime.lua` | Fails closed on a missing or mismatched `RELEASE` stamp, with a message naming `scripts/start-session`. |
| `hypr/session/commands.lua` | `:13-14` takes `runtime.paths.quickshell` from the runtime file; no change other than verifying it follows the cache path. |
| `hypr/monitors.lua:1`, `hypr/nested.lua:12`, `hypr/wallpaper.lua:4`, `hypr/phantomat.lua:120` | Replace the four `require("user.*")` calls with `userlua.load`. `phantomat.lua` moves its `mode` assertion behind the enabled check (`:4-9`). |
| `hypr/user/{canvas,monitors,nested}.lua` | Moved with `git mv` to `hypr/default/`. `hypr/user/` is deleted. Contents unchanged. |
| `tools/scripts/stage-config` | Development staging. Deletes the `restore_policy` trap (`:9-37`). Builds the dev release as links to the working tree under `.build/` (no `chmod`), so `make dev-*` does not depend on the updater. Keeps the wallpaper asset links. Copies `wallpapers/` into the release shape. |
| `tools/scripts/stage-defaults` | Becomes the dev-only seed for `settings.ini`; no copy into user config in production. |
| `tools/scripts/seed-menu-entry`, `tools/scripts/seed-cliphist-config`, `tools/uuctl.desktop` | `git mv` into `update/`; `menu=` (line 12) becomes `${data_home}/ui-shell/current/scripts/menu`; stale `Exec` is rewritten. |
| `tools/development.mk` | `dev-stage`, `dev-configure`, `dev-run`, `dev-verify-hypr`, `dev-seed-menu` keep their names. New: `dev-release` (build a release from the working tree under `.build/`), `dev-check-update`. `dev-lint` stays; its warning count is part of the Verification Plan. |
| `tests/targets.mk` | New `test-update`, `test-crossing`, `test-crash`, `test-activator`, `test-release-readonly`; added to `test` and `test-help`. |
| `tests/scripts/test-nested:55,385`, `tests/scripts/test-state:147`, `tests/scripts/check-defaults:30-44`, `tests/scripts/check-theme-profiles:31,191`, `tests/scripts/check-wallpaper-folders:21`, `tests/scripts/check-hypr-config:28`, `tests/scripts/nested-session:10`, `tests/scripts/host-session:45`, `tests/scripts/check-runtime-config:20`, `tests/scripts/check-menu:248,253` (seed path and the `Exec` assertion), `tests/nested.conf:87-88` | Follow the moves: `hypr/user/*.lua` to `hypr/default/*.lua`; `check-defaults` loses "user policy survives staging" (replaced by a `userlua` test: user file wins, absent falls back); staging calls use the new `stage-config`; `nested-session` applies its `sed -i` to a scratch copy, not the release; `nested.conf:87-88` loses the three `Generated*` paths. Each edit is checked by running the named test before and after. |
| `shell/config/GeneratedLauncherOutput.qml`, `GeneratedRuntime.qml`, `GeneratedWallpapers.qml`, `shell/config/qmldir:16-18` | The three files are tracked (`git ls-files`). Deleted with `git rm`. The `qmldir` entries are removed and the shell imports the cache copies by the path from Step 0.1. |
| `README.md` | Install section: fingerprint, `update/install-activator`, `update-ui-shell` options, TTY and no-session rule, `scripts/start-session` as the only start. README is frozen normative text; the owner approved this edit (2026-11-11). Lines 26-31 (the menu section) already name staged paths and are updated too. |
| `CONFIGURATION.md` | Line 15 (installed package layout), 17 (manifest seed), 19 (dev staging), 21 and 23 (profile and cache paragraphs), 60 and 72 (`hypr/user/monitors.lua` to the `lua/` directory), 62 (user-editable baseline to `settings.ini`), 80-85 (launcher output now in the cache), plus a new paragraph with the migration contract. |
| `tests/scripts/check-theme-profiles:296`, `tests/scripts/check-qml:42`, `tests/scripts/check-runtime-config`, `tests/picker-apply/shell.qml:58,79,93-97,239`, `tests/tst_OutputPalette.qml`, `tests/tst_ThemeEditor.qml`, `tests/tst_LauncherOutput.qml`, `tests/launcher/shell.qml`, `tests/theme-editor/shell.qml` | Follow the cache move: `package.preload["user.canvas"]` becomes the `userlua` name; `check-qml:42` and every `ShellConfig.Generated*` import read the cache copies by the Step 0.1 path; `picker-apply` compares `Quickshell.shellDir` with the cache runtime root. Each test is run before and after. |
| `tools/scripts/generate-monitor-overrides:4`, `tests/scripts/test-nested:385` | Comment and `nested.lua` read move from `hypr/user/` to the user `lua/` directory and `hypr/default/`. |
| `docs/themes.md:5,55`, `shell/README.md:12,23`, `shell/theme/README.md:58`, `tests/README.md:25,162`, `STYLE.md:10,221` | Updated paths only. Each is checked with `rg` for the old names after the change. |
| `.gitignore` | Whitelists the new top-level paths (`update/`, `migrations/`). No `.build/` line (`.gitignore:4` is `*`). |
| `features/reqs/install-migration.md` | Updated to match this design. |
| `brain/pages/install-update-migration.md` | Compiled truth updated to match this design, through the `brain` CLI. |

### Files deleted

| File | Reason |
|---|---|
| `hypr/user/` | Moved to `hypr/default/`. |
| `restore_policy` trap in `tools/scripts/stage-config` | No user data in the staged tree. |

### Build order

1.  Step 0 prerequisites 0.1 and 0.4; record results in the brain page.
2.  `hypr/userlua.lua`, the move to `hypr/default/`, and the test edits that follow it. Verify: `make test-hypr-config`, `check-defaults`, the userlua check.
3.  `read-shell-config`, the two templates, `prepare-runtime`, `scripts/start-session` and the cache runtime directory. Verify: `make test-theme-config`, `test-pipelines`, `test-sandbox`; then `make test-env` boots from the new layout (the owner checks the screen after this step; the exact steps are given at that point).
4.  `update/lib`, `build-release`, `check-release`, `process-guard`. Verify with `check-update` clean install and dry-run.
5.  `update/run`, the activator, `install-activator`, the marker, crash and rollback paths. Verify: `check-update`, `check-crash`, `check-activator`.
6.  `update/run-migrations`, `snapshot`, `prune`, `migrations/README.md`. Verify with a migration that exists only in the fixture repository.
7.  `update/crossing/0001-from-dev-stage`. Verify: `check-crossing`.
8.  `stage-config` and `development.mk` switch to the dev release; remaining test edits; integration seeds.
9.  Documentation, `/egm-bootstrap` contracts, reqs and brain updates.

Steps 2 and 3 end with the named tests green and the shell starting in `make test-env`. Steps 4 to 7 add tests together with the code they cover and end with those tests green plus the existing suite. Step 8 ends with the full `make test`.

### Verification Plan

All update tests run in a bubblewrap sandbox with a private `HOME` and XDG roots, a local bare repository as the remote, and throwaway OpenPGP keys in a private GnuPG home. None touches the real `~/.local`, `~/.config` or the owner's `qs`.

| Case | Assertion |
|---|---|
| Clean install | `current` points at the tag; `SHA256SUMS` verifies; baseline settings written; markers for shipped migrations seeded; `read-shell-config` passes. |
| Crossing | Every user file present and byte-identical in the new place; old tree untouched; second run is a no-op; a crash injected mid-copy leaves the old layout working and a re-run completes. |
| Update | New tag builds beside the old; `current` changes by rename; old release unchanged byte for byte. The rename itself is atomic by `rename(2)`; the test checks that `current` is a valid link before and after, not during. |
| Dry-run | Writes no pending marker and no file under any of the four directories except `cache/.check-<tag>`, which it removes (before and after `find` listing with hashes). |
| Refusals | Fake `qs`; a process with cwd inside `releases/`; unreadable `/proc` entry; leftover marker; bad, missing or wrong-key signature; older tag: each refuses with its exit code and changes nothing. |
| Signature order | A tag whose scripts write a canary: with a bad signature the canary never exists. |
| Crash injection | One run per phase in the table, plus a kill between a migration and its marker and between the rename and the `checking` write: next run refuses with the right text; `--force` ends consistent; with `current` already on the target and passing checks the marker is cleared; with failing checks it names `--rollback`; `current` and previous directories survive every case. |
| Failed checks | A release whose `hyprland.lua` fails `--verify-config`: refused in the rehearsal with `current` and user data unchanged. A failure injected after the rename leaves `current` on the target and the marker in place. |
| Migrations | Out-of-order timestamp, duplicate timestamp, changed applied script, removed script with marker, non-idempotent script run twice by `--force`, non-zero exit. |
| Rollback | Inside the reads range: symlink swap only. Outside without snapshot: refused. Outside with snapshot: restored, markers after it deleted, warning printed. |
| Pruning | Never removes `current` or the previous release; refuses while a process uses a candidate; refuses if the shape would leave the remaining ranges. |
| Idempotency | Two updates in a row; the second says "already current" and changes nothing. |
| Read-only release | `check-release-readonly` runs the shell start and the suite with the release read-only; any write fails the test. |
| Static | `bash -n` on every new script. `shellcheck` is not installed on this machine (`command -v shellcheck` printed nothing): report that instead of skipping it silently. `make dev-lint` printed 77 `Warning` lines on 2026-11-11 (the earlier "about 61" was wrong); the count must not exceed 77. |
| Existing suite | `make test` passes after build step 8 with only the test edits listed in Files modified. |

Visual and session checks that cannot run in the sandbox (the shell starts from `current` on the real display) are listed for the owner with exact steps after the change, not assumed.

### Open Items for the Section Gate

Decided by the owner on 2026-11-11:

1.  **Shipped themes and profiles.** A second read-only search root (Step 0.3); user entries win; the updater never writes user config.
3.  **`README.md` edit.** Approved.
4.  **Step 0.1 fallback.** None. The link tree is the design; a failed spike stops the plan.
5.  **User directory name.** `user-wm-shell`.

Decided by the owner on 2026-11-12:

2.  **Override mechanism for constants in `shell/config/*.qml`.** None: they are fixed per release. User-tunable options already reach QML through `settings.ini` and the editable `components/` store (`ComponentSettings`). The nested-session test no longer edits `AppLauncher.qml`; it puts a stand-in `app2unit` on the session's PATH instead.
