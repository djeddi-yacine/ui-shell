# Install, update and migration

* **Author:** djeddi-yacine
* **Date:** 2026-11-11
* **Status:** requirements draft 2, aligned with `features/designs/install-migration.md` after the Goldfish review and its resolution (2026-11-11). Choices marked "delegated" were made by the author on the owner's instruction and the owner may overturn them.

Input: the owner's decisions in chat, recorded in the brain page `install-update-migration`; the study of Omarchy's updater (`features/studies/install-migration.md`, ids `OM<n>`). Facts about today's code come from `tools/scripts/stage-config`, `tools/scripts/stage-defaults`, `CONFIGURATION.md`, `hypr/phantomat.lua`, `scripts/read-shell-config` and `scripts/prepare-runtime`.

## Overview

Today there is no production installer. The only deployment is `make dev-stage` and the test staging, which copy `scripts/`, `shell/` and `hypr/` over a destination in place. Nothing records what was installed, so a file removed from the source stays on disk and a half-finished copy can be loaded by a running shell. User data and shipped code share one tree and are separated by special cases. Generated files are written into the shipped tree at run time.

We need one command, `update-ui-shell`, that installs and updates the shell on any Arch Linux machine in a way that is atomic, checkable and recoverable. The only question it asks is the signer fingerprint at first install.

## What we need

1. **A manual update command.** `~/.local/bin/update-ui-shell` (the activator), run by the user, never automatic. It shallow-clones the repository under the cache directory. It has `--dry-run`, `--tag`, `--rollback` and `--force`.
2. **Tagged releases only.** There is no `main` route; `make dev-release` covers development.
3. **TTY only, no session running.** The change is applied only when the user has no `Hyprland`, `qs` or `quickshell` process and no process uses a file under `releases/`. The scan sees the current user's processes only. The owner has no greeter. The supported start is `scripts/start-session` from a TTY; a display-manager login is out of scope.
4. **Four directories, one path owner each.**
   * Data `$XDG_DATA_HOME/ui-shell/`: `releases/<tag>/` and `current`. Written only by the updater, read-only after the build.
   * User `$XDG_CONFIG_HOME/user-wm-shell/` : `settings.ini`, `themes/`, `profiles/`, `lua/`. Changed by the user and by migrations. The old `$XDG_CONFIG_HOME/ui-shell/` is never written.
   * State `$XDG_STATE_HOME/ui-shell/`: lock, pending marker, migration markers, snapshots, `signer.asc` (the pinned OpenPGP public key).
   * Cache `$XDG_CACHE_HOME/ui-shell/`: the clone, all generated output (stamped with the release id), rehearsal copies. May be cleared at any time.
5. **Checksums.** Every release carries `SHA256SUMS` (excluding itself). It detects corruption, not tampering, because it is built locally. It is checked before and after activation.
6. **Atomic activation.** The release is built beside the old one; `current` changes by one atomic rename as the last step.
7. **Crash detection.** A `flock` stops two updates at once. A durable pending marker `update/pending` is written before the first change, with the target, the previous release, the start time and the phase (`started`, `built`, `migrating n/m`, `activating`, `checking`, `rolling-back`). It is removed last. Any leftover marker makes the next run refuse (exit 4).
8. **Recovery is never automatic.** The refusal names the phase and offers `--force` or `--rollback`. At `activating` or later, `--force` re-runs the post checks read-only and clears the marker on success, or says to use `--rollback`. Recovery never deletes what `current` or the previous release resolves to. There is no `failed` state and no shell notice. `--force` restores no snapshot. There is no resume mode.
9. **Checks before the swap, on a copy.** The release is rehearsed in `cache/.check-<tag>`: user data and markers are copied, migrations run there, and `read-shell-config`, `prepare-runtime` and `Hyprland --verify-config` run against the copy. `--dry-run` runs the same rehearsal.
10. **Migrations.** Executable scripts `migrations/<unix-timestamp>-<slug>` ship in the release, each declaring `shape: N`. One marker file per applied script holds its checksum and `N` (OM3.5). The runner selects by set difference, in timestamp order. A changed applied script stops the update. Migrations change only user data and state and must be idempotent. A non-zero exit stops the update with the marker left in place.
11. **Shape and reads range.** A shape is an integer. The current shape is the highest `N` over the markers. Each release declares `reads_min` and `reads_max` in its `manifest.ini`. When a migration raises the shape above the previous release's `reads_max`, the runner first copies all user config to `snapshots/<migration>/` (`cp --reflink=auto`) and refuses the migration if free space is insufficient.
12. **Rollback in the first version.** `--rollback` runs from `update/` of the active release (no network). Inside the previous release's reads range it is a symlink swap. Outside it, it needs the snapshot, restores it, deletes the markers written after it and warns that later edits are lost; without one it refuses. Retention is two releases.
13. **Pruning.** Beyond two releases, never `current` or the previous one, and never if the current shape would leave the remaining ranges. `chmod -R u+w` before removal.
14. **Manifest ownership.** A release-owned `manifest.ini` holds every shipped address (commands, renderers, bootstrap, wallpaper entries, `paths.userLua`) and the reads range. The user's `settings.ini` holds choices only (theme profile, wallpaper folders, Phantomat settings, overrides of user-edited component options) and may not redefine a shipped address. `read-shell-config` reads both.
15. **Generated output.** All generated output (`config.json`, `config.lua`, the three `Generated*.qml`, the `ProfileBundle` link) is written to the cache runtime directory by `scripts/start-session` before Hyprland starts and by the existing mid-session helpers. `hypr/runtime.lua` fails closed on a missing or different `RELEASE` stamp. The release is never written after the build. Whether the cache directory links into `current/shell/` or copies it is decided by a spike (Step 0.1 of the design).
16. **Phantomat is an optional setting.** `profile.phantomat.enabled` and the mode stay in the profile. The library path is an optional key in `settings.ini`. The updater neither builds nor ships the library. `read-shell-config` stops requiring `paths.phantomatLibrary`.
17. **First install and the crossing.** The same entry handles a clean machine and one with today's dev-stage layout. The crossing is a frozen script that copies user data once into the new user directory and produces shape 1 only. A clean install starts from a shipped baseline.
18. **Trust.** A small installed activator verifies the OpenPGP-signed tag with `git verify-tag` against a pinned `signer.asc`, in a private GnuPG home, in isolation, before any clone code runs. The key is pinned at first install after the user types the fingerprint shown in the README. The fingerprint is trust-on-first-use against the remote, so the user must verify it out of band. The pinned fingerprint is the primary key's: signing subkeys can be renewed or replaced without a new prompt, and a different primary needs `--repin`. The release key is an offline certify-only primary with a 2-year signing subkey.
19. **Integration list.** `~/.local/bin/update-ui-shell`, `uuctl.desktop`, the `cliphist` configuration and `signer.asc`. The updater writes no Hyprland entry file. Seeds run after the post checks; a stale `Exec` in `uuctl.desktop` is rewritten.
20. **Tests.** Install, crossing, update, rollback, crash injection at every phase, signature order, refusals and a read-only release run in the nested sandbox with a local bare repository and throwaway OpenPGP keys.

## Refactoring policy

Any refactor is allowed, including large ones, wherever it gives the install, update and migration system a better design. The owner chose this because the phase is sensitive. Honest findings are wanted, including "this existing part is the wrong shape". Two limits stay: no workaround or degraded code, and the owner decides architecture.

Refactors this phase has already accepted: all generated output moves to the cache; shipped addresses move to a release-owned manifest; user-edited values move out of the release into `settings.ini`; user Lua moves from `hypr/user/` to the user directory with defaults in `hypr/default/`; the three tracked `Generated*.qml` files are removed from `shell/config/`; seed scripts move under `update/`.

## Goals vs. non-goals

In scope: items 1 to 20.

Not in scope: automatic or background updates; applying an update while a session runs; starting from a display manager; building or shipping Phantomat; a graphical update flow; other distributions; resuming an interrupted update; automatic fallback or rollback after a crash; a `failed` marker state and a shell notice; signer-key rotation; retention above two; typed settings with a deprecation lifecycle (phase 4); the render-hash scheme for files for other programs (16b); config directories reached through symlinks; most per-generation fixtures (one fixture covers the crossing and the update/rollback round trip).

## Phases

1. User, data, state and cache layout; the release builder; `manifest.ini` and `settings.ini`; generated output in the cache; user Lua moved out of `hypr/`; `scripts/start-session`.
2. The updater: activator, lock and marker, rehearsal, atomic swap, post checks, pruning, `--rollback`, `--dry-run`, `--force`.
3. The migration runner, markers, snapshots and fixtures; the crossing.
4. Settings as typed data with the deprecation lifecycle. Component property names stay frozen until then.

## Alternatives weighed

* **In-place sync driven by a checksum manifest.** Not atomic; needs stale-file and user-edit handling; no cheap rollback.
* **Apply at the next boot through a user unit.** Unattended apply; "never automatic" was a constraint.
* **A single `flock` for crash detection.** The kernel releases it on a crash.
* **Generated output split into release-built and user-dependent.** `prepare-runtime:18-23` puts user data into every generated file, so nothing is release-only.
* **One user-owned `config.ini` for all addresses.** Every release that adds a command would need a rewrite of about 50 entries.
* **Rollback, verify and prune from the clone.** The cache may be cleared; rollback would need the network.
* **Convert the old directory in place.** The old layout dies before `current` exists.
* **User-edited baseline files kept inside the release.** Conflicts with a read-only checksummed tree.
* **Snapshot restore as the common rollback path; read-time converters only; self-heal after a crash; signer key shipped in the activator; an Arch package as the only route.** See the design's Alternatives for the reasons.

## Key decisions already made

* Manual command, TTY only, no session, tagged releases, `--dry-run`, `--rollback` in the first version.
* One rule for crashes: any leftover marker refuses; mutations only through `--force` and `--rollback`.
* One marker file per migration; shape is the highest recorded `N`.
* Release-owned manifest plus user settings; all generated output in the cache; `update/` shipped inside each release; a new user-directory name.
* Signed tags checked by a small activator with a pinned key confirmed by hand.
* Phantomat is an optional user setting.

## Implementation status

Phases 1 to 3 are implemented and tested (2026-11-11). Interpretive choices made during implementation: a one-line `RELEASE` file, `settings.baseline.ini` for clean installs, `shipped/` replacing `bundled-themes/` inside a release, a `previous` link beside `current`, rollback restoring the earliest snapshot whose shape exceeds the target's `reads_max`, and re-updating to an existing release tag being refused. The release signing key is not decided, so `update/signer.pub` does not exist yet.

## Open decisions

Decided by the owner (2026-11-11): shipped themes and profiles use a second read-only search root; the README install section is approved; there is no per-start-copy fallback, and a failed Step 0.1 spike stops the plan; the user directory is `user-wm-shell`.

Still open:

* Step 0.4 audit: how `settings.ini` values reach QML without editing `shell/config/*.qml`.
