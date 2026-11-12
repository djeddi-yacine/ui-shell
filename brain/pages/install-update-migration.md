---
id: install-update-migration
title: "Manual, offline-gated update with releases and migrations"
category: decision
status: active
tags: [install, update, migration]
created: "2026-11-11T02:03:44"
updated: "2026-11-12T08:42:00"
---

<!-- compiled_truth -->
# Decision (settled)

`~/.local/bin/update-ui-shell` (the activator) is run by hand from a TTY with no session, never automatically. It installs tagged releases only (no `main`), shallow-clones under the cache, verifies the SSH-signed tag with `git verify-tag` against a pinned `allowed_signers` before any clone code runs, builds `releases/<tag>/` (read-only, `SHA256SUMS` as a corruption check), rehearses it on a copy of user data, runs migrations, and activates by one atomic rename of `current`. Commands: `--dry-run`, `--tag`, `--rollback`, `--force`. The supported session start is `scripts/start-session`; display-manager login is out of scope.

Four directories: data (releases, `current`), user `$XDG_CONFIG_HOME/user-wm-shell/` (owner-chosen name, old directory never written), state (lock, pending marker, migration markers, snapshots, `allowed_signers`), cache (clone, all generated output stamped with the release id, rehearsal copies). A release-owned `manifest.ini` holds shipped addresses and the reads range; the user's `settings.ini` holds choices only. `update/` ships inside each release, so rollback and pruning work offline.

Crashes: any leftover pending marker refuses (exit 4); phases `started, built, migrating n/m, activating, checking, rolling-back`; only `--force` and `--rollback` mutate; recovery never deletes what `current` or previous resolves to; no `failed` state, no shell notice, `--force` restores no snapshot. Retention is two releases.

Migrations: `migrations/<timestamp>-<slug>` with `shape: N`; one marker per script (checksum and N); current shape = highest N; snapshot (all user config, `cp --reflink=auto`, refuse if space is short) only when N exceeds the previous release's `reads_max`; rollback inside the range is a symlink swap, outside it needs the snapshot. The crossing is frozen and produces shape 1 only; a clean install starts from a shipped baseline.

Phantomat stays an optional setting (library path optional in `settings.ini`), never built or shipped by the updater. Key rotation, typed settings (phase 4) and the render-hash scheme are deferred.

# Facts that shaped it

No production installer exists today (`make dev-stage`, test staging). `prepare-runtime` feeds user data into every generated file, so no output is release-only. `.gitignore:4` is `*` (whitelist). `Generated*.qml` are tracked in `shell/config/`.

# Decided 2026-11-11 (owner)

Shipped themes and profiles use a second read-only search root (`current/default/`, `current/bundled-themes/`); user entries win; the updater never writes user config. The README install section is approved. No fallback for the cache runtime directory: it is a link tree into `current/shell/`, Step 0.1 proves it, and a failed spike stops the plan. The user directory is `user-wm-shell`.

# Open

Step 0.4 write audit and how `settings.ini` overrides reach QML (owner: not yet). Step 0.1 spike unrun. `EGM.md` contracts come from `/egm-bootstrap` after implementation.

Related: [[shipped-default-seed]], [[xdg-runtime-and-theme-schema]].


## Timeline

- time: 2026-11-11T02:03:44
  kind: decision
  summary: "Created this page: Manual, offline-gated update with releases and migrations"
  source: "Install migration design chat, 2026-11-11"
  affects: [install-update-migration]

- time: 2026-11-11T02:03:44
  kind: decision
  summary: "Record the settled constraints of the update workflow; design and reqs still open"
  source: "Install migration design chat, 2026-11-11"
  affects: [install-update-migration]

- time: 2026-11-11T02:06:14
  kind: decision
  summary: "Update runs as one command from a TTY only (user has no greeter); an intent marker before the first change and a completion check after the last detect a crashed update; a forced restart is offered"
  source: "Install migration design chat, 2026-11-11"
  affects: [install-update-migration]

- time: 2026-11-11T02:09:25
  kind: decision
  summary: "Rollback command is in the first version; updates come from tagged releases; Phantomat is an optional user setting (enabled, library path, configuration) that is never built, shipped or path-checked by the updater and never checked when disabled"
  source: "Install migration design chat, 2026-11-11; features/reqs/install-migration.md"
  affects: [install-update-migration]

- time: 2026-11-11T02:11:32
  kind: decision
  summary: "Any refactor is allowed for this phase, including large ones; honest findings about existing parts are wanted; owner still decides architecture and no workarounds"
  source: "Install migration design chat, 2026-11-11; features/reqs/install-migration.md"
  affects: [install-update-migration]

- time: 2026-11-11T02:45:41
  kind: decision
  summary: "Omarchy study reviewed. Migration state is one marker file per migration (checksum as content), not one ledger. First install and the move from today's dev-stage layout is a crossing run by the same update-ui-shell entry, not a migration and not a second command. Seed-once copying into user config is dropped: user settings hold overrides only; files for other programs come from shipped templates with user templates layered first, written only for items on the integration list, with the hash of the last rendered output kept to detect user edits."
  source: "owner chat 2026-11-11; features/studies/omarchy-update.md"
  affects: [install-update-migration]

- time: 2026-11-11T02:47:06
  kind: decision
  summary: "Open decisions answered by the author at the owner's instruction: settings.ini (new, overrides only, same ini parser, config.ini stays the manifest); SSH-signed tags verified with git verify-tag, signer key pinned at first install and rotated only by a release the old key signed; retention of three releases and their snapshots; shell shows a notice when the update marker exists (read-only check); post-activation checks are checksums, read-shell-config and Hyprland --verify-config."
  source: owner chat 2026-11-11
  affects: [install-update-migration]

- time: 2026-11-11T02:59:27
  kind: decision
  summary: "Brainstorm review blocker 1 (owner choice C): release-only generated output is built into the release before SHA256SUMS; user-dependent output (profile bundle, wallpapers, config.lua) is regenerated at shell start into the cache with release-relative links. A release is never written after build. Rejected: all-cache per-release (A), all-at-build (B)."
  source: "egm-brainstorm session 2026-11-11, concepts_brief.md finding 1"
  affects: [install-update-migration]

- time: 2026-11-11T03:04:28
  kind: decision
  summary: "Brainstorm review blocker 2 (owner choice B): each release declares the user-data shapes it reads (reads: [min..max]). Migrations only move data within what the previous release reads, so rollback is a symlink swap with no restore; rollback and pruning refuse targets outside the range. A snapshot is kept only for migrations that cannot be read both ways. Rejected: snapshot-restore as the common path (A), read-time converters with no rewriting (C)."
  source: "egm-brainstorm session 2026-11-11, concepts_brief.md finding 2"
  affects: [install-update-migration]

- time: 2026-11-11T03:29:37
  kind: decision
  summary: "Brainstorm review scope (owner choice C): first version = layout split, release builder with split generation, lock, no-session refusal, checks before swap, atomic rename, --dry-run, --rollback (2 kept), crossing with one-time config copy, plus the pending marker, git verify-tag with pinned key, and per-script migration markers with the runner. Deferred: typed settings schema and deprecation lifecycle (phase 4), render-hash scheme for files for other programs (16b), most per-generation fixtures. Rejected: smallest version (A), all 18 items (B)."
  source: "egm-brainstorm session 2026-11-11, concepts_brief.md finding 9"
  affects: [install-update-migration]

- time: 2026-11-11T03:30:42
  kind: decision
  summary: "Brainstorm review trust (owner choice): a small installed activator verifies the signed tag (git verify-tag) before any clone code runs, takes the lock and does the swap; it changes rarely and is replaced only through a signed release. The signer key is pinned at first install after the user confirms its fingerprint by hand (so the item-3 'without asking the user anything' wording is reworded). Rejected: clone's own code (broken release can break its own update), key shipped inside the activator (rotation needs reinstall)."
  source: "egm-brainstorm session 2026-11-11, concepts_brief.md finding 7"
  affects: [install-update-migration]

- time: 2026-11-11T03:34:17
  kind: decision
  summary: "Design draft, crash handling (owner choice A): any leftover pending marker makes the next update-ui-shell run refuse and print phase, target and applied migrations. --force deletes the partial release and restarts from the beginning (applied migrations skipped by their marker files). A marker at activated or checking makes the run re-verify the new release, then clear the marker or roll back. Marker phases: fetched, built, migrating n/m, activated, checking; marker written by temp file, fsync, rename, directory fsync; lock file under XDG_STATE_HOME because a TTY has no XDG_RUNTIME_DIR. Rejected: self-heal before activation (B), always roll back first (C)."
  source: "egm-draft session 2026-11-11, design_draft.md Open Questions: crash windows"
  affects: [install-update-migration]

- time: 2026-11-11T03:35:54
  kind: decision
  summary: "Design draft, first-install bootstrap (decided by the author on the owner's instruction 'leave this to you, state of the art', owner may overturn): scripts/install-activator, run from a checked-out tag after the user verifies its fingerprint against the README, installs ~/.local/bin/update-ui-shell and pins the signer key. User-space, no root; the same step a later PKGBUILD can call. Rejected: Arch package as the only route (needs root and a maintained PKGBUILD, splits ownership), make install from a checkout (a dirty checkout produces a release that matches no tag)."
  source: "egm-draft session 2026-11-11, design_draft.md Open Questions: crossing / first install"
  affects: [install-update-migration]

- time: 2026-11-11T03:41:27
  kind: note
  summary: "Design written to features/designs/install-migration.md. Plan adds scripts/start-session, Step 0 spikes (Quickshell through links, release-only output audit, theme/profile second root); open: shipped themes root vs runner step, read-shell-config defaults block, README edit, link-tree fallback."
  affects: [install-update-migration]

- time: 2026-11-11T04:40:26
  kind: decision
  summary: "Review resolve: generated output all in cache; release-owned manifest.ini + small user config.ini; update/ shipped inside each release; new user-directory name for the crossing; user-edited settings moved out of the release (owner delegated items 2,3,4,9 to me, overturnable). Full list in resolve_decisions.md"
  source: "egm-resolve interactive breakdown, items 1-27"
  affects: [install-update-migration]

- time: 2026-11-11T04:50:12
  kind: decision
  summary: "Align compiled truth with the resolved design (features/designs/install-migration.md) and reqs draft 2; replaces earlier open items"
  source: "egm-resolve session 2026-11-11; resolve_decisions.md"
  affects: [install-update-migration]

- time: 2026-11-11T04:50:12
  kind: reversal
  summary: "Resolve outcomes overturn earlier entries: generated output is all in the cache (not split); retention is two (not three); no shell notice and no failed state; crash rule is refuse-only with no auto re-verify-then-rollback; phases are started/built/migrating/activating/checking/rolling-back; the first-version scope drops --ref main and the fetched phase; manifest.ini is release-owned and settings.ini holds choices only."
  source: egm-resolve 2026-11-11
  affects: [install-update-migration]

- time: 2026-11-11T04:55:58
  kind: decision
  summary: "Owner decided open items: second read-only root, README edit approved, no cache fallback, dir user-wm-shell"
  source: owner chat 2026-11-11
  affects: [install-update-migration]

- time: 2026-11-11T04:55:58
  kind: reversal
  summary: "Per-start-copy fallback for the cache runtime directory removed (owner: no implicit fallbacks); user directory renamed from proposed ui-shell-user to user-wm-shell."
  source: owner chat 2026-11-11
  affects: [install-update-migration]

- time: 2026-11-11T05:00:34
  kind: note
  summary: "Study file renamed features/studies/omarchy-update.md to features/studies/install-migration.md so all three stages share the feature name; earlier entries cite the old path."
  source: owner chat 2026-11-11
  affects: [install-update-migration]

- time: 2026-11-11T05:08:12
  kind: evidence
  summary: "Step 0.1 spike passed (Quickshell 0.3.2, offscreen, throwaway config): link tree with real generated files in config/ and a ProfileBundle link loads; ../config from linked files resolves through the cache path; a repointed current is seen by a new qs, even with same-size same-mtime files. Not tested: real shell tree, QML disk cache (none was written)."
  source: spike run 2026-11-11
  affects: [install-update-migration]

- time: 2026-11-11T05:11:27
  kind: evidence
  summary: "Step 0.4 production write audit: no production script or QML writes into shell/, hypr/ or scripts/ besides prepare-runtime (moves to cache). Gaps: paths.components had no home (now components/ in user dir); read-theme-state and read-wallpaper-selections read paths.hypr/user/monitors.lua (move to paths.userLua). Test sites writing to staged copies listed in design. Read-only-release test still to build; Open Item 2 still open."
  source: audit 2026-11-11
  affects: [install-update-migration]

- time: 2026-11-11T07:34:53
  kind: decision
  summary: "Owner decided (2026-11-11) for Build Step 3: the cache runtime tree uses layout A (directory links for unchanged shell dirs, real config/ with per-file links); prepare-runtime writes a generated config/qmldir (release qmldir plus the three Generated* singleton lines); tests that import shell/config build the cache tree in their sandbox with the real prepare-runtime."
  source: chat
  affects: [install-update-migration]

- time: 2026-11-11T08:49:39
  kind: decision
  summary: "Build step 4 done: update/{lib,run,build-release,check-release,process-guard} and make test-update"
  affects: [install-update-migration]

- time: 2026-11-11T09:20:11
  kind: decision
  summary: Shipped second search root built
  affects: [install-update-migration]

- time: 2026-11-11T09:29:52
  kind: decision
  summary: "Step 5 built: activator, install-activator, rollback, crash paths"
  affects: [install-update-migration]

- time: 2026-11-11T09:45:28
  kind: decision
  summary: "Step 6: migration runner, snapshot, prune, rollback restore"
  affects: [install-update-migration]

- time: 2026-11-11T09:51:20
  kind: decision
  summary: "Step 7: crossing from the development layout"
  affects: [install-update-migration]

- time: 2026-11-11T10:24:07
  kind: decision
  summary: "Step 8: seeds in update/, dev release, user-profile materialization"
  affects: [install-update-migration]

- time: 2026-11-11T10:26:01
  kind: decision
  summary: "Step 9 docs done; signer key still deferred"
  affects: [install-update-migration]

- time: 2026-11-11T22:02:42
  kind: reversal
  summary: "Signer key: OpenPGP replaces SSH"
  affects: [install-update-migration]

- time: 2026-11-12T00:19:45
  kind: decision
  summary: dev-lint lints a scratch copy of shell/ with the generated singletons overlaid
  affects: [install-update-migration]

- time: 2026-11-12T01:28:28
  kind: decision
  summary: "Activator refusals covered: revoked key, republished tag name"
  affects: [install-update-migration]

- time: 2026-11-12T01:54:09
  kind: decision
  summary: "Open Item 2: shell/config constants are fixed per release"
  affects: [install-update-migration]

- time: 2026-11-12T07:49:02
  kind: decision
  summary: "Release rules written to docs/release-rules.md: tag, tree, startability, migrations, updater protocol stability, pre-push gate"
  affects: [install-update-migration]

- time: 2026-11-12T07:59:19
  kind: decision
  summary: "Releases are cut by make release-patch|minor|major (tools/scripts/release): VERSION = latest released version; gate, signed tag, then sandbox proofs (fresh install; previous tag updates to new and rolls back) BEFORE the push; failure before push undoes commit and tag. make test-release covers it with a throwaway key"
  affects: [install-update-migration]

- time: 2026-11-12T08:08:40
  kind: decision
  summary: "Release tooling never hardcodes machine-specific setup (owner instruction): RELEASE_GNUPGHOME is required with no default, RELEASE_SIGNING_KEY is optional (else the single usable signing key in that home), the script shows the signing key, requires its primary to equal the pinned update/signer.asc key, and asks to confirm before signing; a wrong key is fixed by setting the env again. The repository user.signingkey is no longer used. Docs use $RELEASE_GNUPGHOME."
  source: owner chat
  affects: [install-update-migration]

- time: 2026-11-12T08:42:00
  kind: decision
  summary: "Release proofs now cover user data and the hard path: dev-update plants a user-directory file and a state file before an update and fails if the update or rollback changes them (settings.ini is reported, since a migration may rewrite it); tests/scripts/check-rich-release installs a candidate with a migration, reads_max 2 and a changed activator over a real previous release, checks the migration marker, the snapshot, the activator self-update and the rollback restore, then runs the whole release script on it. The v0.1.0 to v0.2.0 upgrade proved only signing, pinning, swap and rollback because no shipped part differed."
  source: owner chat
  affects: [install-update-migration]
