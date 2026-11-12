# Omarchy: how it installs, updates and migrates a user's system

Study of the update and migration machinery in `refs/omarchy` (checked out tree reports `4.0.0.alpha` in `refs/omarchy/version:1`). Facts only, each with a source citation. Paths are relative to the repository root, and citations use the form `refs/omarchy/path:start-end`. Line numbers refer to the files as checked out. No decisions are recorded here. Nothing under `refs/` was built or run and no network command was used; only `rg`, `ls`, `wc`, and file reads were used.

Id prefix: `OM`.

Sources read in full or by range: `AGENTS.md`, `CLAUDE.md`, `version`, `docs/update-process.md`, `docs/file-layout.md`, `docs/theming.md`, `docs/testing.md`, `agents/skills/migrations.md`, `plans/backup.md`, `bin/omarchy-update*`, `bin/omarchy-migrate*`, `bin/omarchy-snapshot`, `bin/omarchy-channel-set`, `bin/omarchy-version*`, `bin/omarchy-refresh-*`, `bin/omarchy-reinstall-configs`, `bin/omarchy-hook*`, `bin/omarchy-pkg-add`, `bin/omarchy-pkg-drop`, `bin/omarchy-state`, `bin/omarchy-reinstall-pkgs`, `bin/omarchy-dev-add-migration`, `bin/omarchy-dev-link`, `bin/omarchy-theme-*`, `bin/omarchy-provision-first-run`, `bin/omarchy-upgrade-to-quattro`, `install/helpers/pacman.sh`, `install/config/snapper.sh`, `install/config/all.sh`, `install/post-install/all.sh`, `default/pacman/*`, `default/libalpm/hooks/*.hook`, `test/shell.d/update-sequence-test.sh`, `test/shell.d/migrate-scope-test.sh`, `test/shell.d/migrate-wrapper-test.sh`, `test/shell.d/snapshot-create-test.sh`, several `migrations/*.sh`, and directory listings.

Where the code shows no implementation the entry says "not found", with the search used. `Partial` in the comparison table means some aspect of the feature is present but not the whole.

---

## 1. Source and channels (OM1)

### 1.1 Where the code lives

- **OM1.1** The installed tree is package-owned and lives at `/usr/share/omarchy`. Two Arch packages are built from the one repo: `omarchy` (binaries, install/finalize scripts, migrations, themes, shell) and `omarchy-settings` (everything needed before `omarchy` installs: `/etc/skel`, `/etc` drop-ins, package-owned system files) `refs/omarchy/docs/file-layout.md:5-27`.
- **OM1.2** Runtime code resolves the tree through `$OMARCHY_PATH`, which is set at the top level by the uwsm session environment `refs/omarchy/AGENTS.md:63`. `bin/` commands install to `/usr/bin/omarchy-*` with symlinks in `/usr/share/omarchy/bin/` `refs/omarchy/docs/file-layout.md:74-75`.
- **OM1.3** A dev-linked checkout changes the tree: `/etc/omarchy.conf` is sourced by the env bootstrap and points `OMARCHY_PATH` at a git clone; `omarchy-dev-unlink` resets it to `/usr/share/omarchy`. The dev-link also writes `/etc/sudoers.d/omarchy-dev-path` so `sudo omarchy-*` resolves to the checkout `refs/omarchy/docs/file-layout.md:216-249`; `refs/omarchy/bin/omarchy-dev-link:19-35`; `refs/omarchy/bin/omarchy-dev-unlink:34-40`.
- **OM1.4** `omarchy-dev-link` states it affects only `$OMARCHY_PATH`-resolved trees (`bin/`, `default/`, `shell/`, `themes/`, `applications/`, `config/`); fixed system paths (`/etc/`, `/usr/lib/systemd/`, udev rule bodies, `/etc/skel` after user creation) are not covered, and `omarchy dev pkg-test` must build and install the package for those `refs/omarchy/bin/omarchy-dev-link:32-40`.
- **OM1.5** `omarchy-dev-pkg-test` tags the built package's `pkgver` as `dev.<short-sha>[.dirty]` so `pacman -Q` shows where the installed version came from `refs/omarchy/bin/omarchy-dev-pkg-test:26-28`.

### 1.2 How code is fetched

- **OM1.6** Package channels use pacman repositories from Omarchy's own servers. The stable config defines `[omarchy]` with `Server = https://pkgs.omarchy.org/stable/$arch` and includes `/etc/pacman.d/mirrorlist` `refs/omarchy/default/pacman/pacman-stable.conf:19-29`; the stable mirrorlist is `Server = https://stable-mirror.omarchy.org/$repo/os/$arch` `refs/omarchy/default/pacman/mirrorlist-stable:1`.
- **OM1.7** Package signatures are checked by pacman: `SigLevel = Required DatabaseOptional` and `LocalFileSigLevel = Optional` `refs/omarchy/default/pacman/pacman-stable.conf:15-16`.
- **OM1.8** Omarchy maintains its own keyring. `omarchy-update-keyring` recovers and locally signs key `40DFB630FF42BCFFB047046CF0134EE680CAC571` from `keys.openpgp.org`, runs `pacman -Sy`, installs `omarchy-keyring`, then asserts the key is present with `pacman-key --list-keys` `refs/omarchy/bin/omarchy-update-keyring:11-21`; `refs/omarchy/bin/omarchy-update-keyring:54-55`.
- **OM1.9** The Arch (and Arch Linux ARM) keyrings are refreshed every update by reinstalling them: `archlinux-keyring`, plus `archlinuxarm-keyring` on aarch64 where installed, plus any installed `*-keyring` package listed one-per-line in `/usr/share/omarchy-platform/keyrings` `refs/omarchy/bin/omarchy-update-keyring:23-50`.
- **OM1.10** The dev channel is a git clone: `omarchy-channel-set dev` clones `https://github.com/omacom/omarchy.git` into `$HOME/omarchy` when it is not already a checkout `refs/omarchy/bin/omarchy-channel-set:50-52`; `refs/omarchy/bin/omarchy-channel-set:142`.
- **OM1.11** Dev updates are `git pull --ff-only` on the active checkout's configured upstream branch, resolved with `@{upstream}`; a branch with no upstream is skipped with a warning, and a non-git `OMARCHY_PATH` is an error `refs/omarchy/bin/omarchy-update-dev:7-21`.
- **OM1.12** File copying for the package side is whole-file overwrite from `default/pacman/` templates, not incremental: `omarchy-refresh-pacman` copies `pacman-<channel>.conf` to `/etc/pacman.conf` and `mirrorlist-<channel>` to `/etc/pacman.d/mirrorlist` `refs/omarchy/bin/omarchy-refresh-pacman:45-49`.

### 1.3 Versions

- **OM1.13** `omarchy-version` prints the installed package version from `pacman -Q omarchy-dev` or `pacman -Q omarchy` (whichever is installed), or `dev (<short-hash>)` when `OMARCHY_PATH` is a linked checkout `refs/omarchy/bin/omarchy-version:5-28`.
- **OM1.14** `omarchy-version-branch` prints the checkout's current git branch, or `detached@<short-hash>` when detached, and exits non-zero for a package install `refs/omarchy/bin/omarchy-version-branch:9-18`.
- **OM1.15** The `version` file at the repo root contains `4.0.0.alpha` `refs/omarchy/version:1`. Nothing in the tree reads it: searching the whole tree for `OMARCHY_PATH/version` and `omarchy/version` returns only the install-map row in `refs/omarchy/docs/file-layout.md:87`, and `docs/update-process.md:306-309` states "There is no version file at runtime".
- **OM1.16** `omarchy-version-channel` derives the active channel by grepping `/etc/pacman.d/mirrorlist` for the `stable-mirror`/`rc-mirror`/`mirror` hosts and `/etc/pacman.conf` for the `pkgs.omarchy.org/{stable,rc,edge}` servers, printing `unknown` or `"<mirror> / <pkgs>"` on mismatch `refs/omarchy/bin/omarchy-version-channel:5-29`.

### 1.4 Channels, templates and pinning

- **OM1.17** `omarchy-channel-set <stable|rc|edge|dev>` maps to packages: stable→`omarchy omarchy-settings` on the stable repo, rc→same packages on rc, edge→`omarchy-dev omarchy-settings-dev`, dev→same as edge plus a dev link `refs/omarchy/bin/omarchy-channel-set:108-130`.
- **OM1.18** Each platform has its own pacman.conf and mirrorlist per channel; `install/helpers/pacman.sh` resolves `default/pacman` for x86 and `default/pacman/<platform>/` for `aarch64`/`aarch64-apple` `refs/omarchy/install/helpers/pacman.sh:8-17`. A channel without both files for the platform is refused before anything changes `refs/omarchy/bin/omarchy-channel-set:136-138`.
- **OM1.19** The default channel is stable on x86 and edge on aarch64/aarch64-apple `refs/omarchy/install/helpers/pacman.sh:23-32`.
- **OM1.20** Omarchy publishes aarch64 packages on edge alone so far, so ARM platforms have edge templates only; switching an ARM machine to stable or rc is refused because those templates do not exist `refs/omarchy/docs/update-process.md:292-298`.
- **OM1.21** Channel switching runs the `pre-refresh-pacman` hook once, cold behind the no-update wrapper, after the package config is re-synced and before the refresh transaction `refs/omarchy/docs/update-process.md:276-278`.
- **OM1.22** No tag, commit or version pinning is present. Searching `bin/omarchy-update-dev` and `bin/omarchy-update-available` for `tag|pin|branch|checkout` returns only the `@{upstream}` plumbing and prose. Dev updates fast-forward to whatever the upstream branch now is `refs/omarchy/bin/omarchy-update-dev:14-21`.
- **OM1.23** No checksum or signature verification of the dev checkout is present: `omarchy-update-dev` runs `git pull --ff-only` and nothing else `refs/omarchy/bin/omarchy-update-dev:20-21`, and `omarchy-update-available` uses `GIT_TERMINAL_PROMPT=0` with a 10-second timeout `refs/omarchy/bin/omarchy-update-available:12`.

---

## 2. Update command flow (OM2)

### 2.1 Entry, transcript, lock, pre-checks

- **OM2.1** `omarchy-update` is the user entry point (`omarchy update`), declares `# omarchy:requires-sudo=true`, and uses the `#!/bin/bash -p` form; it refuses an unsafe Bash startup before its first command and sources `omarchy-security-functions` `refs/omarchy/bin/omarchy-update:1-16`.
- **OM2.2** It preserves the caller's PATH for later hook/mise phases, installs sudo cleanup traps, revokes any existing sudo timestamp, and validates the no-update sudo wrapper up front `refs/omarchy/bin/omarchy-update:20-35`.
- **OM2.3** It re-execs itself under `script(1)` on the first pass, writing the whole run to `/tmp/omarchy-update.log` `refs/omarchy/bin/omarchy-update:86-89`.
- **OM2.4** It takes a per-run lock. `omarchy-update-lock run` opens `$XDG_RUNTIME_DIR/omarchy-update.lock` (falling back to `/tmp`), takes `flock -n`, and `exec`s the command with the lock fd exported; a second update prints "An Omarchy update is already running." and exits 1 `refs/omarchy/bin/omarchy-update-lock:9-41`; `refs/omarchy/bin/omarchy-update:91-93`.
- **OM2.5** A pre-check aborts below 10 GiB free on `/`, silently skips when free space cannot be determined, and `OMARCHY_UPDATE_FORCE=1` bypasses it `refs/omarchy/bin/omarchy-update-requires-free-space:8-16`; `refs/omarchy/bin/omarchy-update:99`.
- **OM2.6** Unless `-y` is passed it shows a gum confirmation; cancelling exits 1 `refs/omarchy/bin/omarchy-update-confirm:5-17`. `-y` exports `OMARCHY_UPDATE_UNATTENDED=1` `refs/omarchy/bin/omarchy-update:103`.
- **OM2.7** It prompts for the sudo password once (by running `sudo /usr/bin/true`, not `sudo -v`) and a background keepalive refreshes the timestamp every 60 seconds until the update ends `refs/omarchy/bin/omarchy-update:44-62`; `refs/omarchy/bin/omarchy-update:105-106`.

### 2.2 Ordered steps

The step order is code, `refs/omarchy/bin/omarchy-update:99-173`, and is pinned by a test `refs/omarchy/test/shell.d/update-sequence-test.sh:64-117`.

- **OM2.8** `omarchy-update-pkg-prune` runs before the snapshot: `paccache -rk2` trims the pacman cache to two versions per package, "the only offline downgrade path"; a prune failure only warns `refs/omarchy/bin/omarchy-update-pkg-prune:8-13`; `refs/omarchy/bin/omarchy-update:108-110`.
- **OM2.9** A snapper snapshot is created before package mutation. `omarchy-snapshot create` exits 127 when snapper is absent (silently skipped), fails loudly when snapper is installed but has no configs (pointing at `install/config/snapper.sh`), and the update prints "Continuing the update without a snapshot" and proceeds on any failure other than 127 `refs/omarchy/bin/omarchy-update:112-116`; `refs/omarchy/bin/omarchy-snapshot:16-45`.
- **OM2.10** Sleep/idle inhibition starts (`omarchy-update-stay-awake start`) and is stopped before the reboot prompt `refs/omarchy/bin/omarchy-update:118-119`; `refs/omarchy/bin/omarchy-update:160-166`.
- **OM2.11** Dev checkout first, then keyrings, then system packages: `omarchy-update-dev`, `omarchy-update-keyring`, `omarchy-update-system-pkgs` `refs/omarchy/bin/omarchy-update:120-127`. Migrations ship with the packages installed here, and an upgrade that stops takes the update with it rather than migrating against what is still on disk `refs/omarchy/bin/omarchy-update:124-127`.
- **OM2.12** System packages run through the guard-approved pacman helper: `LC_ALL=C omarchy-update-pacman -Syu --noconfirm --overwrite '/usr/share/omarchy/*'`, with stderr captured to a report; on failure it execs the conflict handler unless already retrying `refs/omarchy/bin/omarchy-update-system-pkgs:16-39`.
- **OM2.13** `omarchy-update-pacman` runs pacman as a PID 1 scope via `systemd-run --scope` when `/run/systemd/system` is a real directory, and directly otherwise, always exporting `OMARCHY_UPDATE_PACMAN=1` (plus any `LC_ALL`) `refs/omarchy/bin/omarchy-update-pacman:14-25`.
- **OM2.14** After packages: `omarchy-migrate`, then `omarchy-update-orphan-pkgs -y`, then `omarchy-update-analyze-logs`, then `omarchy-update-status`, then `omarchy-update-restart --services-only` `refs/omarchy/bin/omarchy-update:129-137`.
- **OM2.15** Orphans are removed noninteractively under `-y` via `omarchy-pkg-drop`; standalone noninteractive runs only report `refs/omarchy/bin/omarchy-update-orphan-pkgs:10-31`.
- **OM2.16** `omarchy-update-analyze-logs` scans `/tmp/omarchy-update.log` and warns if `Updating linux initcpios` appears without `Initcpio image generation successful`; it does not exit non-zero `refs/omarchy/bin/omarchy-update-analyze-logs:5-13`.
- **OM2.17** `omarchy-update-status` rechecks availability and refreshes or clears the shell widget `refs/omarchy/bin/omarchy-update-status:6-12`.
- **OM2.18** The `post-update` hook and mise run with the caller's original PATH so user-installed tools resolve: `PATH="$user_path" omarchy-hook post-update` then `PATH="$user_path" omarchy-update-mise` `refs/omarchy/bin/omarchy-update:139-141`. A failing hook prints "Hook failed:" and does not fail the update `refs/omarchy/bin/omarchy-hook:30-39`.
- **OM2.19** `omarchy-update-mise` runs `MISE_MINIMUM_RELEASE_AGE=0 mise up`, overriding mise's release-age cooldown `refs/omarchy/bin/omarchy-update-mise:5-12`.
- **OM2.20** The update's authorization is revoked, AUR packages are updated with the no-update sudo wrapper (`--sudoloop=false`), then the timestamp is revoked again: AUR builds are third-party PKGBUILD code and never see the update's reusable authorization `refs/omarchy/bin/omarchy-update:143-149`; `refs/omarchy/bin/omarchy-update-aur-pkgs:5-15`.
- **OM2.21** Boot verification is the last sudo-capable step, run cold through the no-update wrapper. `omarchy-update-boot` resolves the `update-verify` lifecycle operation; status 3 (platform boot package not installed) warns that boot files were not verified, any other non-zero fails, and only a resolved operation runs under `sudo` `refs/omarchy/bin/omarchy-update-boot:19-39`.
- **OM2.22** If boot verification failed, the update prints "The update is not finished" and exits 1 without offering a reboot `refs/omarchy/bin/omarchy-update:156-173`.

### 2.3 Restart and reboot requirements

- **OM2.23** `omarchy-update-restart` has three phases: `all` (default), `--services-only`, `--reboot-only` `refs/omarchy/bin/omarchy-update-restart:6-10`.
- **OM2.24** Reboot is offered when a kernel newer than the running one is installed, when `~/.local/state/omarchy/reboot-required` exists, or when the running Hyprland binary is `(deleted)` `refs/omarchy/bin/omarchy-update-restart:22-47`.
- **OM2.25** `restart-*-required` state files cause `omarchy-restart-<service>` to run and the marker to be cleared `refs/omarchy/bin/omarchy-update-restart:49-58`; the state file is `~/.local/state/omarchy/<name>` written by `omarchy-state set` `refs/omarchy/bin/omarchy-state:7-38`.
- **OM2.26** The shell is restarted unconditionally every update; a restart failure only prints its reason `refs/omarchy/bin/omarchy-update-restart:60-65`. `docs/update-process.md:30` states the shell needs no marker and is restarted unconditionally after every update.
- **OM2.27** In unattended mode the reboot prompt prints "Run omarchy-system-reboot when ready." instead of prompting `refs/omarchy/bin/omarchy-update-restart:13-20`. `omarchy-system-reboot` schedules the reboot through the user manager so closing the terminal's scope cannot kill it `refs/omarchy/bin/omarchy-system-reboot:7-11`.

### 2.4 Availability check and widget

- **OM2.28** `omarchy-update-available` checks the active dev checkout against its upstream (fetch, then `rev-list --count HEAD..upstream`) and, for package installs, `omarchy-dev` else `omarchy` via `checkupdates`; exit 0 with the list, non-zero "Omarchy is up to date" otherwise `refs/omarchy/bin/omarchy-update-available:9-44`.
- **OM2.29** The bar widget runs `omarchy-update-available` on a 6-hour interval (`21600000` ms), refreshing on startup, and clicking it launches `omarchy-launch-floating-terminal-with-presentation omarchy-update` `refs/omarchy/shell/plugins/bar/widgets/SystemUpdate.qml:20,41,48,52`.

### 2.5 The raw-pacman guard

- **OM2.30** An ALPM pre-transaction hook `00-omarchy-update-guard.hook` triggers on every package `Upgrade` and runs `omarchy-update-pacman-guard` with `AbortOnFail` `refs/omarchy/default/libalpm/hooks/00-omarchy-update-guard.hook:1-12`.
- **OM2.31** The guard exits 0 when `OMARCHY_UPDATE_PACMAN=1` or `OMARCHY_ALLOW_DIRECT_PACMAN=1` is set; otherwise it detects a direct sync+sysupgrade (from `OMARCHY_PACMAN_CMDLINE` or `/proc/$PPID/cmdline`) and aborts with instructions and exit 1 `refs/omarchy/bin/omarchy-update-pacman-guard:8-64`.

---

## 3. Migrations (OM3)

### 3.1 Location, naming and ordering

- **OM3.1** Migrations live in `migrations/*.sh` in the source tree, installed at `/usr/share/omarchy/migrations/` `refs/omarchy/agents/skills/migrations.md:11-15`; `refs/omarchy/docs/file-layout.md:84`.
- **OM3.2** The runner enumerates them with a glob, `for file in "$MIGRATIONS_DIR"/*.sh`, which the shell sorts lexicographically; it writes `filename<TAB>file<TAB>marker` lines `refs/omarchy/bin/omarchy-migrate:35-45`.
- **OM3.3** Filenames are Unix timestamps in seconds, created by `omarchy-dev-add-migration` from the newest commit date: `migrations/$(git log -1 --format=%cd --date=unix).sh` `refs/omarchy/bin/omarchy-dev-add-migration:32-35`. The checked-out `migrations/` directory contains only 10-digit `.sh` names, e.g. `refs/omarchy/migrations/1778623107.sh` and `refs/omarchy/migrations/1791723398.sh`.
- **OM3.4** Ordering is declared strictly ordered and synchronous; a migration that cannot finish must exit non-zero, remain pending, and stop the queue, and must never mark later migrations complete against state an earlier migration has not established `refs/omarchy/agents/skills/migrations.md:129`.

### 3.2 Applied state and "already ran"

- **OM3.5** Completion state is per-user, one marker file per migration, in `~/.local/state/omarchy/migrations/<migration filename>`. The state dir is `$HOME/.local/state/omarchy/migrations`, overridable with `OMARCHY_MIGRATION_STATE` `refs/omarchy/bin/omarchy-migrate:31-33`; `refs/omarchy/agents/skills/migrations.md:22-26`.
- **OM3.6** A migration is pending exactly when its marker file is absent (`[[ ! -f $marker ]]`) `refs/omarchy/bin/omarchy-migrate:47-56`. It is marked complete by `touch "$marker"` after the migration exits 0 `refs/omarchy/bin/omarchy-migrate:91-96`.
- **OM3.7** `omarchy-migrate --pending` (alias `--check`) prints the pending filenames and exits 0 when any are pending, and stays quiet with exit 1 when none are `refs/omarchy/bin/omarchy-migrate:58-66`; `refs/omarchy/agents/skills/migrations.md:88-106`.
- **OM3.8** Because markers are per-user, every user gets a chance to run every migration `refs/omarchy/agents/skills/migrations.md:28-32`; `refs/omarchy/docs/update-process.md:49-58`.
- **OM3.9** New users do not replay migrations: the package ships `/etc/skel/.local/state/omarchy/migrations/*` so a freshly-created user's markers already exist `refs/omarchy/docs/file-layout.md:87-88`, and `omarchy-provision-user --first-install` marks every shipped user migration as already applied `refs/omarchy/docs/file-layout.md:269-270`.

### 3.3 Running

- **OM3.10** `omarchy-migrate` runs with `set -euo pipefail` `refs/omarchy/bin/omarchy-migrate:6`. Each migration is executed as `bash -euo pipefail "$file"` (dash `e`, `u`, `o pipefail`) with fd 3 closed, not through its executable bit `refs/omarchy/bin/omarchy-migrate:93`; `refs/omarchy/agents/skills/migrations.md:123-124`.
- **OM3.11** Before running anything it waits for an active pacman transaction: if `/var/lib/pacman/db.lck` exists it polls once a second for up to 900 iterations, and on timeout prints that migrations will retry on next login and exits 0 `refs/omarchy/bin/omarchy-migrate:68-81`.
- **OM3.12** The queue is fed on a private file descriptor (`3< <(migration_entries)`), so a migration that reads stdin does not swallow later queue entries; this is asserted by a test `refs/omarchy/bin/omarchy-migrate:88-97`; `refs/omarchy/test/shell.d/migrate-scope-test.sh:79-105`.
- **OM3.13** At the end it dismisses the login-time "Omarchy Migrations" notification `refs/omarchy/bin/omarchy-migrate:99-102`.
- **OM3.14** There is no `--force`; the runner rejects it as an unknown option `refs/omarchy/bin/omarchy-migrate:14-28`; `refs/omarchy/test/shell.d/migrate-wrapper-test.sh:54-58`.

### 3.4 Failure handling

- **OM3.15** A migration that exits non-zero stops the queue: the runner is under `set -e`, so the failing `bash` call aborts the loop, the marker is not written, and every later migration stays pending. A test builds a failing migration and asserts the marker is absent and the following line does not run `refs/omarchy/test/shell.d/migrate-scope-test.sh:56-77`. There is no skip, catch-up, or retry inside one run; retry happens by running `omarchy-migrate` again later.
- **OM3.16** In the update pipeline a migration failure is fatal: after the failing package upgrade, the test asserts `omarchy-migrate`, `omarchy-hook`, `omarchy-update-aur-pkgs` and `omarchy-update-restart` do not run `refs/omarchy/test/shell.d/update-sequence-test.sh:106-117`.

### 3.5 Authoring a migration

`refs/omarchy/agents/skills/migrations.md:107-149` is the authoring guide:

- **OM3.17** Create with `omarchy-dev-add-migration` (default opens `nvim`; `--no-edit` skips) `refs/omarchy/agents/skills/migrations.md:107-119`; `refs/omarchy/bin/omarchy-dev-add-migration:37-41`.
- **OM3.18** File permissions must be `0644`; no shebang line; start with an `echo` describing what it does; use `$OMARCHY_PATH` to reference the Omarchy directory; be idempotent and check existing state before changing it `refs/omarchy/agents/skills/migrations.md:121-128`.
- **OM3.19** A migration may touch user/session state (`~/.config`, `~/.local`, user systemd, browser/editor prefs, DBus/session state) and may perform machine-wide repairs `refs/omarchy/agents/skills/migrations.md:17-20`. It runs as the user; privileged work must invoke the appropriate helper or privilege prompt itself `refs/omarchy/agents/skills/migrations.md:28-32`.
- **OM3.20** Migrations must be idempotent so a machine-wide repair no-ops for other users `refs/omarchy/docs/update-process.md:55-58`.
- **OM3.21** Helpers are recommended: `omarchy-cmd-present`, `omarchy-cmd-missing`, `omarchy-pkg-add`, `omarchy-pkg-drop`, `omarchy-pkg-present`, `omarchy-pkg-missing`; raw `pacman`, `command -v`, and direct config edits are acceptable for one-off repair `refs/omarchy/agents/skills/migrations.md:130-137`.
- **OM3.22** A migration must never restart the shell: `omarchy update` restarts it unconditionally after migrations, and the login-time shell already runs current code `refs/omarchy/agents/skills/migrations.md:133-135`.
- **OM3.23** Example migration body given: `echo`, guard with `[[ -L $theme_link ]] || exit 0`, then `ln -sfn` `refs/omarchy/agents/skills/migrations.md:139-149`.
- **OM3.24** In the checked-out tree, 45 of the migration files contain `sudo ` and 37 reference `omarchy-pkg-add` or `omarchy-pkg-drop` (counted with `rg -l` over `refs/omarchy/migrations/`). This matches the guide's allowance for privileged repairs and helper use.
- **OM3.25** `omarchy-update-system-pkgs`/`omarchy-migrate` do not apply migrations inside pacman; the ALPM hooks that exist are the guard, passwordless-revoke, and Hyprland reload pause/resume, not a migration runner `refs/omarchy/docs/update-process.md:347-351`; `refs/omarchy/default/libalpm/hooks/`.

### 3.6 When migrations run

- **OM3.26** During `omarchy update`: after the package transaction, in the visible update terminal, then `omarchy-hook post-update` `refs/omarchy/agents/skills/migrations.md:36-46`; `refs/omarchy/bin/omarchy-update:129-141`.
- **OM3.27** At login: every graphical login starts `omarchy-migrate-notify.service` after `graphical-session.target`; `omarchy-migrate-notify` exits 0 while held by the update lock, runs `omarchy-migrate --pending`, waits for a live notification server, rechecks the lock, and sends a notification whose click opens a terminal running `omarchy-migrate`. It never runs migrations itself `refs/omarchy/bin/omarchy-migrate-notify:7-44`; `refs/omarchy/agents/skills/migrations.md:48-72`.
- **OM3.28** The notifier refuses to read `/tmp`'s fallback lock path because a shared lock belongs to whoever created it first and honouring it would let one user silence another user's notification `refs/omarchy/docs/update-process.md:205-209`.
- **OM3.29** Login is deliberately the only trigger; a watcher on the packaged directory cannot distinguish a bypassed `pacman -Syu` from the transaction inside a normal update `refs/omarchy/docs/update-process.md:189-193`. The retired unit was `omarchy-update-user-notify.path` `refs/omarchy/docs/update-process.md:193`.
- **OM3.30** Manually, users can run `omarchy-migrate` at any time; already-completed migrations are skipped `refs/omarchy/agents/skills/migrations.md:78-86`.

### 3.7 Tests for migrations

- **OM3.31** Migrations are unit-tested by building the legacy state in a fake `$HOME` and running `bash -euo pipefail "$ROOT/migrations/<ts>.sh"`, asserting the resulting state, running it twice to prove idempotence, and once against non-legacy state to prove user customization is left alone `refs/omarchy/docs/testing.md:126-130`.
- **OM3.32** The migration test is kept while it is being written, if it calls a still-changing helper, or if it is a security-sensitive privileged repair; once a one-shot rewrite has shipped in a tagged release and is frozen, the test is dropped even if the rewrite used sudo, pacman, or limine-mkinitcpio, but the migration itself stays for late-updaters `refs/omarchy/agents/skills/migrations.md:166`; `refs/omarchy/docs/testing.md:130`.
- **OM3.33** Tests of `omarchy-migrate`, the login notifier, and `omarchy-upgrade-to-quattro` stay `refs/omarchy/agents/skills/migrations.md:166`. Present: `refs/omarchy/test/shell.d/migrate-scope-test.sh`, `refs/omarchy/test/shell.d/migrate-wrapper-test.sh`, `refs/omarchy/test/shell.d/migrate-notify-test.sh`.
- **OM3.34** The 4.0 crossing is not a normal migration: `omarchy-upgrade-to-quattro` handles the pre-4 package-layout transition, and the guide says not to add compatibility migrations for old installer layouts `refs/omarchy/agents/skills/migrations.md:168-170`. Clearing a privileged file a retired installer left on disk is the exception and belongs in a migration `refs/omarchy/agents/skills/migrations.md:172-174`.

### 3.8 The 3→4 upgrade command

- **OM3.35** `omarchy-upgrade-to-quattro` is "intentionally self-contained so it can be shipped as a command in Omarchy 3.8.x or run directly with curl | bash on older systems" `refs/omarchy/bin/omarchy-upgrade-to-quattro:14-16`. It runs under `set -euo pipefail`, requires sudo, and has flags `--yes`, `--reboot`, `--dev`, `--channel`, `--user` `refs/omarchy/bin/omarchy-upgrade-to-quattro:1-8`.
- **OM3.36** It normalizes the legacy install's channel unless overridden, mapping `stable|master|main`→stable, `rc`→rc, `edge|dev`→edge `refs/omarchy/bin/omarchy-upgrade-to-quattro:41-52`; `refs/omarchy/bin/omarchy-upgrade-to-quattro:318-333`.
- **OM3.37** Its ordered steps are visible at the end of the file: suppress Hyprland reload, pre-upgrade snapshot, configure pacman channel, install keyrings, remove legacy installer package and limine configs, remove conflicting legacy packages, preserve kernel cmdline root, install quattro packages, install hardware transition packages, normalize limine, verify kernel cmdline root, configure snapper policy, configure lock authentication, migrate 1password/lazydocker packages, clean legacy user paths, apply system transition, apply user transition, user hardware transition, refresh applications, `omarchy-bar defaults`, cleanup retired services, ensure sleep lock, remove retired default packages, final system upgrade, run migrations, post-upgrade update steps, refresh current theme, restore Hyprland reload `refs/omarchy/bin/omarchy-upgrade-to-quattro:2416-2460`.
- **OM3.38** It runs the normal migrator and then fails the upgrade if migrations are still pending or cannot be verified: `omarchy-migrate`, then `omarchy-migrate --pending` (must exit 1) `refs/omarchy/bin/omarchy-upgrade-to-quattro:1260-1275`.
- **OM3.39** It writes completion markers directly (`~/.local/state/omarchy/done/first-run-user`, `finalize-user`) rather than through `omarchy-done`, because a command missing from an older packaged tree would abort the upgrade two thirds of the way through `refs/omarchy/bin/omarchy-upgrade-to-quattro:2303-2312`.

---

## 4. User config versus shipped files (OM4)

### 4.1 Three layers into `$HOME`

- **OM4.1** Seed: `omarchy-settings` ships static defaults to `/etc/skel/`, and Arch's `useradd -m` copies that tree into a new user's `$HOME` at creation. `/etc/skel` only fires at user creation `refs/omarchy/docs/file-layout.md:33-48`.
- **OM4.2** Finalize: `omarchy-provision-user` runs once per user and does what `/etc/skel` cannot (`$HOME` expansion, live `$OMARCHY_PATH`, runtime detection); it does not copy `~/.config/**`, `~/.bashrc`, `flags.lua`, or the nautilus extensions, which `/etc/skel` already seeded `refs/omarchy/docs/file-layout.md:39-42,253-257`. Idempotency marker `~/.local/state/omarchy/done/finalize-user` `refs/omarchy/docs/file-layout.md:272-273`.
- **OM4.3** Resync: `omarchy-reinstall-configs` is "the explicit, destructive command for an existing user to clobber their configs back to shipped defaults" `refs/omarchy/docs/file-layout.md:43-45`.
- **OM4.4** The shipped user-config source is `config/**`, installed to `/etc/skel/.config/**` (seed) and `/usr/share/omarchy/config/**` (resync source) `refs/omarchy/docs/file-layout.md:90-91`.
- **OM4.5** Current generated theme state lives under `~/.local/state/omarchy/current/`; `~/.config/omarchy/` is kept for files a user may version in a dotfile manager (user themes, hooks, shell layout, plugins, themed template overrides) `refs/omarchy/docs/file-layout.md:63-66`.

### 4.2 Which paths are user-owned, which are overwritten

- **OM4.6** `omarchy-refresh-config <relative-path>` copies `$OMARCHY_PATH/config/<path>` to `~/.config/<path>`. If the user file exists it is first copied to `<file>.bak.<epoch>`; if the backup is byte-identical after the copy it is deleted, otherwise the tool prints "Replaced … with new Omarchy default" and a diff `refs/omarchy/bin/omarchy-refresh-config:20-43`. The argument is only checked with `[[ -e ]]`, so a path containing `..` resolves and copies outside `~/.config` rather than being rejected `refs/omarchy/AGENTS.md:156-160`.
- **OM4.7** The `refresh-` prefix means "copy default config to user's `~/.config/`" `refs/omarchy/AGENTS.md:48`. The shipped refresh commands are `refresh-applications`, `refresh-chromium`, `refresh-config`, `refresh-herdr`, `refresh-hyprland`, `refresh-hyprsunset`, `refresh-limine`, `refresh-pacman`, `refresh-plymouth`, `refresh-sddm`, `refresh-shell`, `refresh-tmux` (from `bin/omarchy-refresh-*` metadata, e.g. `refs/omarchy/bin/omarchy-refresh-hyprland:3`, `refs/omarchy/bin/omarchy-refresh-tmux:3`).
- **OM4.8** `omarchy-refresh-hyprland` overwrites the seven user Hyprland Lua configs via `omarchy-refresh-config` and copies `default/hypr/toggles/flags.lua` over `~/.local/state/omarchy/toggles/hypr/` `refs/omarchy/bin/omarchy-refresh-hyprland:5-14`.
- **OM4.9** `omarchy-refresh-shell` resets `~/.config/omarchy/shell.json` via `omarchy-refresh-config`, then `omarchy-bar defaults`, then restarts the shell `refs/omarchy/bin/omarchy-refresh-shell:8-11`.
- **OM4.10** `omarchy-reinstall-configs` copies the entire `/etc/skel` tree over `$HOME` (`cp -af /etc/skel/. ~/`) then runs `omarchy-refresh-limine`, `omarchy-refresh-plymouth`, and the nvim refresh; the docs call it destructive with no backup: "existing user files copied from `/etc/skel` are clobbered without backup" `refs/omarchy/bin/omarchy-reinstall-configs:12-28`; `refs/omarchy/docs/file-layout.md:395-412`.
- **OM4.11** `omarchy-refresh-pacman` backs up `/etc/pacman.conf` to `.bak` and `/etc/pacman.d/mirrorlist` to `.bak` before copying the channel templates `refs/omarchy/bin/omarchy-refresh-pacman:45-49`.
- **OM4.12** `omarchy-refresh-limine` moves `/boot/limine.conf` to `/boot/limine.conf.bak`, copies the default limine config, and rebuilds with `limine-update` and `limine-snapper-sync` `refs/omarchy/bin/omarchy-refresh-limine:12-19`.
- **OM4.13** `omarchy-refresh-applications` copies `applications/*.desktop` into `~/.local/share/applications/` and runs `update-desktop-database` `refs/omarchy/bin/omarchy-refresh-applications:5-17`.

### 4.3 Layering of defaults and overrides

- **OM4.14** Generated theme files use a template layering: a user template in `~/.config/omarchy/themed/*.tpl` is processed before the built-in `default/themed/*.tpl`, and if a user template has the same output filename the built-in output is skipped `refs/omarchy/docs/theming.md:35-37`.
- **OM4.15** KitKat-style system/user split: Kitty loads `/etc/xdg/kitty/kitty.conf` before `~/.config/kitty/kitty.conf`; the package owns the system file and the user template contains only the active theme include and commented examples `refs/omarchy/docs/file-layout.md:432-435`.
- **OM4.16** Some `/etc` files are owned by upstream Arch packages and cannot be installed over without a file conflict, so their sources ship under `/usr/share/omarchy/etc-overrides/` and the `omarchy-settings` `post_install`/`post_upgrade` scriptlet `cp -f`s them into place; the documented trade-off is that user edits to those files are clobbered on every `omarchy-settings` upgrade `refs/omarchy/docs/file-layout.md:193-204`.
- **OM4.17** The `pre-refresh-pacman` hook lets a user customize `/etc/pacman.conf` (custom repositories, `IgnorePkg`) before the channel refresh's transaction runs; it runs cold behind the no-update wrapper and the timestamp is revoked afterwards `refs/omarchy/bin/omarchy-refresh-pacman:51-59`.

### 4.4 How a user edit is preserved or lost (3→4 upgrade)

- **OM4.18** The upgrade refresh is hash-driven. It ships `known_config_default_hashes`, a table of `action<TAB>relative ~/.config path<TAB>sha256` rows `refs/omarchy/bin/omarchy-upgrade-to-quattro:1556-1561`. `refresh_known_config_defaults` only replaces a file when its current sha256 matches a known shipped default `refs/omarchy/bin/omarchy-upgrade-to-quattro:1821-1831`; `is_known_default_hash` computes and looks up the hash `refs/omarchy/bin/omarchy-upgrade-to-quattro:1709-1714`.
- **OM4.19** Any file about to be replaced is copied to `<file>.omarchy-upgrade-to-quattro.<timestamp>.bak` before removal `refs/omarchy/bin/omarchy-upgrade-to-quattro:1716-1720`; `copy_config_default` skips identical files, backs up, removes, then copies `refs/omarchy/bin/omarchy-upgrade-to-quattro:1787-1801`.
- **OM4.20** New quattro-only entry points older installs cannot have are always written from the default: `hypr/.luarc.json`, `hypr/autostart.lua`, `hypr/bindings.lua`, `hypr/hyprland.lua`, `hypr/input.lua`, `hypr/looknfeel.lua`, `hypr/monitors.lua`, `omarchy/extensions/omarchy-menu.jsonc`, `omarchy/hooks/pre-refresh-pacman.d/add-custom-repo.sample`, `omarchy/shell.json` `refs/omarchy/bin/omarchy-upgrade-to-quattro:1724-1737,1844-1848`.
- **OM4.21** Missing shipped defaults are filled in only when the target does not exist `refs/omarchy/bin/omarchy-upgrade-to-quattro:1803-1819`.
- **OM4.22** Customizable legacy files are preserved: for a retired file, if a backup exists and does **not** match a known default hash, the user override is copied back into place; otherwise the file is removed `refs/omarchy/bin/omarchy-upgrade-to-quattro:2019-2038`.
- **OM4.23** Custom non-Omarchy lines in `~/.config/uwsm/env` are migrated into `~/.config/uwsm/env.d/99-omarchy-upgrade-env` with Omarchy-managed lines replaced by no-op markers; the legacy active file is always removed `refs/omarchy/bin/omarchy-upgrade-to-quattro:1739-1774,2023-2028`.

### 4.5 Deleted and renamed files

- **OM4.24** Package-owned files are removed by pacman itself. The plocate drop-in example states "Pacman removes those retired files; no new state migration is needed" `refs/omarchy/docs/file-layout.md:212`.
- **OM4.25** User copies under `~/.config` are not tracked or removed by pacman; the quattro upgrade names retired relative paths in the same hash table with action `retire` and a `systemd/user/*` blanket, removing or keeping them per OM4.22 `refs/omarchy/bin/omarchy-upgrade-to-quattro:1722,1776-1785`.
- **OM4.26** Legacy UI configs replaced by the shell (`waybar`, `swayosd`, `mako`, `walker`) are moved to `.omarchy-upgrade-to-quattro.<ts>.bak` rather than deleted, and legacy Hyprland `.conf` files are intentionally left in place `refs/omarchy/bin/omarchy-upgrade-to-quattro:2008-2017`.
- **OM4.27** The legacy user checkout `~/.local/share/omarchy` is moved to `~/.local/share/omarchy.omarchy-upgrade-to-quattro.<ts>.bak` (kept for inspection/rollback) and a compat symlink makes the stale path resolve to the package tree for the live session `refs/omarchy/bin/omarchy-upgrade-to-quattro:1088-1102`.
- **OM4.28** Legacy user command shims that pointed into the old checkout are removed from `~/.local/bin` `refs/omarchy/bin/omarchy-upgrade-to-quattro:992-1010`.
- **OM4.29** Retired default packages are removed in a dependency-aware way, with a preflight `pacman -Rs --print`, a batch `pacman -Rns`, and named fallback groups; anything still required is left installed with a warning `refs/omarchy/bin/omarchy-upgrade-to-quattro:863-990`.

---

## 5. Packages and system changes (OM5)

### 5.1 Package install and removal

- **OM5.1** The main system transaction is `omarchy-update-pacman -Syu --noconfirm --overwrite '/usr/share/omarchy/*'` because `/usr/share/omarchy` is wholly Omarchy's and files can land there unowned `refs/omarchy/bin/omarchy-update-system-pkgs:21-27`.
- **OM5.2** The conflict handler is invoked on failure. It moves unowned conflicting files under `/var/lib/omarchy/replaced` mirroring their full path, re-checks each against the live database with `pacman -Qo`, moves all of them or none, lets a platform boot package veto a takeover via `omarchy-lifecycle-dispatch update-takeover`, retries the upgrade once with `OMARCHY_UPDATE_RETRY=1`, and restores anything the retry did not claim `refs/omarchy/bin/omarchy-update-system-pkgs-when-conflicted:26-126`.
- **OM5.3** Package-vs-package conflicts (`unresolvable package conflicts detected`) are handed to an interactive pacman run rather than guessed at; under `-y` or without a terminal it reports and skips instead of blocking `refs/omarchy/bin/omarchy-update-system-pkgs-when-conflicted:64-82`.
- **OM5.4** `omarchy-pkg-add` installs missing packages with `pacman -S --noconfirm --needed` (directly as root, else `sudo`), then verifies each with `pacman -Q` and exits 1 if one did not register `refs/omarchy/bin/omarchy-pkg-add:8-24`.
- **OM5.5** `omarchy-pkg-drop` removes installed named packages with `sudo pacman -Rns --noconfirm`, ignoring ones that are not installed `refs/omarchy/bin/omarchy-pkg-drop:22-31`.
- **OM5.6** `omarchy-reinstall-pkgs` resets the repository to the platform's default channel, runs `omarchy-update-pacman -Suu --noconfirm` (downgrade-capable), then installs the composed default package set `refs/omarchy/bin/omarchy-reinstall-pkgs:11-20`.
- **OM5.7** A platform's default package set is composed from `install/omarchy-base.packages`, then `install/omarchy-aarch64.packages` on any ARM machine, then `install/omarchy-<platform>.packages`, with x86-only base packages in `install/omarchy-x86_64-only.packages` `refs/omarchy/docs/file-layout.md:379-383`.

### 5.2 Config files outside `$HOME`

- **OM5.8** `/etc/**` drop-ins Omarchy owns outright ship through `omarchy-settings`, including `mkinitcpio.conf.d/`, `limine-entry-tool.d/`, `NetworkManager/`, `sudoers.d/`, `sysctl.d/`, `tmpfiles.d/`, and `profile.d/omarchy.sh` `refs/omarchy/docs/file-layout.md:104-111`.
- **OM5.9** Files under `/etc/` owned by upstream packages (`/etc/skel/.bashrc`, `nsswitch.conf`, `security/faillock.conf`, `cups/cups-browsed.conf`, `plymouth/plymouthd.conf`) ship under `omarchy-settings`'s `etc-overrides/` and are `cp -f`'d into place by `post_install`/`post_upgrade`, clobbering user edits on every `omarchy-settings` upgrade `refs/omarchy/docs/file-layout.md:110-111,193-204`.
- **OM5.10** The quattro upgrade writes `/etc` files directly as root (resolved.conf.d, docker/daemon.json, sddm.conf.d, `state.conf`, PAM edits) and removes retired units and udev rules under `/etc` `refs/omarchy/bin/omarchy-upgrade-to-quattro:1421-1533`.

### 5.3 Services, hooks and sudo

- **OM5.11** ALPM hooks installed by the package: the update guard (`00-omarchy-update-guard.hook`, PreTransaction, AbortOnFail), passwordless revoke on `omarchy-settings` changes (`05-…`, AbortOnFail), and Hyprland config reload pause/resume (`10-…` PreTransaction, `90-…` PostTransaction) `refs/omarchy/default/libalpm/hooks/00-omarchy-update-guard.hook:1-12`; `refs/omarchy/default/libalpm/hooks/05-omarchy-passwordless-revoke.hook:1-13`; `refs/omarchy/default/libalpm/hooks/10-omarchy-hyprland-reload-pause.hook:1-13`; `refs/omarchy/default/libalpm/hooks/90-omarchy-hyprland-reload-resume.hook:1-13`.
- **OM5.12** The reload guard disables live Hyprland reloads while `/usr/share/omarchy/default/hypr/**` is replaced, then resumes, forces one `hyprctl reload`, and restores the session's previous `misc.disable_autoreload` and `debug.suppress_errors` values `refs/omarchy/docs/update-process.md:109-115`.
- **OM5.13** Service changes during the 3→4 upgrade: enable `cups.service`, `avahi-daemon.service`, `linux-modules-cleanup.service`, `docker.socket`, `systemd-resolved.service`, `NetworkManager.service`, `bluetooth.service`, `power-profiles-daemon.service`, `sddm.service`; disable `iwd.service`, `docker.service`, and several retired units `refs/omarchy/bin/omarchy-upgrade-to-quattro:1441-1458`.
- **OM5.14** The upgrade deliberately does not add the user to the `docker` group because it is root-equivalent and opt-in `refs/omarchy/bin/omarchy-upgrade-to-quattro:1413-1415`.
- **OM5.15** The `pre-refresh-pacman` hook is user code, run cold behind the no-update wrapper with the timestamp revoked after `refs/omarchy/bin/omarchy-refresh-pacman:51-59`.
- **OM5.16** Privileged commands declare `# omarchy:requires-sudo=true` (`refs/omarchy/bin/omarchy-update:7`, `refs/omarchy/bin/omarchy-snapshot:5`, `refs/omarchy/bin/omarchy-update-keyring:4`, `refs/omarchy/bin/omarchy-refresh-pacman:4`, `refs/omarchy/bin/omarchy-reinstall-pkgs:4`). The repo's escalation line is drawn by whether the caller has a terminal to enter a password in `refs/omarchy/AGENTS.md:91-94`.
- **OM5.17** System upgrades run pacman through `sudo env OMARCHY_UPDATE_PACMAN=1 systemd-run --scope --quiet --collect pacman ...` so the ALPM guard allows the Omarchy-owned flow `refs/omarchy/docs/update-process.md:87-104`; the helper also runs pacman directly on unbooted systems `refs/omarchy/docs/update-process.md:97-99`.

---

## 6. Themes and generated/derived files (OM6)

- **OM6.1** `omarchy-theme-set <name>` builds a clean staging directory at `~/.local/state/omarchy/current/next-theme`: copy the first-party theme from `themes/<name>/`, overlay `~/.config/omarchy/themes/<name>/`, optionally generate `colors.toml` from `alacritty.toml`, run `omarchy-theme-set-templates` to render templates, then move the staging theme to `~/.local/state/omarchy/current/theme`, write `current/theme.name`, and notify the shell `refs/omarchy/docs/theming.md:19-28`.
- **OM6.2** Template rendering only happens when the staged theme has `colors.toml`; existing files are never overwritten by a template, so a hand-written `themes/<name>/shell.toml` or `hyprland.lua` wins over the generated one `refs/omarchy/docs/theming.md:30-33`.
- **OM6.3** After activation, `omarchy-theme-set` fires the `theme-set` hook and dispatches a parallel retint of running apps (the `post_theme_commands` list); runs serialize on a `flock` `refs/omarchy/docs/theming.md:39-45`.
- **OM6.4** `omarchy-theme-refresh` re-renders the current theme: it reads `~/.local/state/omarchy/current/theme.name` and runs `OMARCHY_THEME_SKIP_BACKGROUND=1 omarchy-theme-set "<name>"` `refs/omarchy/bin/omarchy-theme-refresh:5-9`.
- **OM6.5** Migrations are the update-path hook for theme regeneration: e.g. `refs/omarchy/migrations/1788281348.sh:11` and `refs/omarchy/migrations/1787481315.sh:25` both call `omarchy-theme-refresh`. Nothing in `bin/omarchy-update` itself calls it; the pipeline list in `refs/omarchy/bin/omarchy-update:99-173` contains no theme step.
- **OM6.6** The 3→4 upgrade refreshes the current theme itself: `refresh_current_theme_after_upgrade` resolves the name (falling back to "Tokyo Night"), runs `OMARCHY_THEME_HEADLESS=1 omarchy-theme-set`, writes a legacy `hyprland.conf` theme shim, restarts the terminal, and re-applies the browser colour (`omarchy-theme-set-browser`), because headless theme-set skips live post hooks `refs/omarchy/bin/omarchy-upgrade-to-quattro:2358-2413`.
- **OM6.7** Git-installed themes are updated with `git -C <theme> pull` by `omarchy-theme-update` `refs/omarchy/bin/omarchy-theme-update:5-10`. Installed themes are filtered at staging time so a cloned theme cannot ship code (`*.lua`, terminal configs, `vscode.json`) `refs/omarchy/docs/theming.md:53-59`.
- **OM6.8** Generated/derived user files rebuilt after an update include application launchers (`omarchy-refresh-applications`) and the default bar (`omarchy-bar defaults`), both run by the 3→4 upgrade with a warning on failure `refs/omarchy/bin/omarchy-upgrade-to-quattro:2443-2446`.
- **OM6.9** Update-installed QML routinely replaces the running shell's files, so the shell is restarted every update; a restart failure is tolerated because the next update or login gets a fresh shell `refs/omarchy/bin/omarchy-update-restart:60-65`.
- **OM6.10** Theme colors are keyed from `colors.toml` and referenced by `{{ key }}` placeholders in `.tpl` templates; `omarchy-theme-set-templates` does the substitution `refs/omarchy/docs/theming.md:71-135`.

---

## 7. Safety: atomicity, crash detection, rollback, snapshots, verification (OM7)

### 7.1 Concurrency and locks

- **OM7.1** A single per-user `flock` on `$XDG_RUNTIME_DIR/omarchy-update.lock` (fallback `/tmp`) prevents overlapping updates; the second run exits 1 with "An Omarchy update is already running." `refs/omarchy/bin/omarchy-update-lock:33-38`.
- **OM7.2** The migration runner has no lock of its own; it only waits for the pacman lock (`/var/lib/pacman/db.lck`) `refs/omarchy/bin/omarchy-migrate:68-81`. Searching `refs/omarchy/bin/omarchy-migrate` for `flock` returns nothing.
- **OM7.3** The update lock file's existence is also the signal the login notifier and the sleep inhibitor use to stay silent while an update is in progress `refs/omarchy/bin/omarchy-migrate-notify:7-18`; `refs/omarchy/docs/update-process.md:195-215`.

### 7.2 Snapshots and rollback

- **OM7.4** A snapper snapshot is taken before the package transaction, skipped silently when snapper is absent (exit 127), and a failure of any other kind warns and continues `refs/omarchy/bin/omarchy-update:112-116`; `refs/omarchy/bin/omarchy-snapshot:16-45`. The 3→4 upgrade takes the same snapshot with the same 127 handling `refs/omarchy/bin/omarchy-upgrade-to-quattro:722-728`.
- **OM7.5** Snapshot restore is a separate explicit command: `omarchy-snapshot restore` runs `sudo limine-snapper-restore` `refs/omarchy/bin/omarchy-snapshot:46-48`. "Snapshots can be selected during boot" `refs/omarchy/bin/omarchy-snapshot:44`.
- **OM7.6** Snapper is configured with `install/config/snapper.sh`: it creates the root config if absent, installs `default/snapper/root`, writes `/etc/conf.d/snapper`, disables `snapper-timeline.timer`, and enables `snapper-cleanup.timer` and `limine-snapper-sync.service` `refs/omarchy/install/config/snapper.sh:5-24`.
- **OM7.7** There is no update rollback command. Searching `bin/` for `rollback|roll back|revert` returns no system-update rollback verb; the matches are the factory-reset lifecycle op `reset-rollback` (`refs/omarchy/bin/omarchy-lifecycle-dispatch:31`), a sleep-inhibitor launch rollback (`refs/omarchy/bin/omarchy-update-stay-awake:182`), and unrelated code. Recovery from a bad update is via the boot-time snapper restore or by re-running.
- **OM7.8** The 3→4 upgrade keeps the old git checkout as a `.omarchy-upgrade-to-quattro.<ts>.bak` directory "for inspection/rollback" `refs/omarchy/bin/omarchy-upgrade-to-quattro:1088-1102`.
- **OM7.9** Package-cache downgrade capability is preserved: `paccache -rk2` keeps two versions per package, described as "the only offline downgrade path" `refs/omarchy/bin/omarchy-update-pkg-prune:8-12`.

### 7.3 Crash and partial-update detection

- **OM7.10** `omarchy-update` itself keeps no persisted phase/resume state. Searching `refs/omarchy/bin/omarchy-update` for `resume|state|marker|done` returns only unrelated comments. Failure handling is the ERR message ("Something went wrong during the update") and the EXIT cleanup, which revokes sudo and stops stay-awake `refs/omarchy/bin/omarchy-update:95-97`; `refs/omarchy/bin/omarchy-update:73-84`.
- **OM7.11** The 3→4 upgrade tracks `upgrade_started`/`upgrade_completed` in memory and, on a non-zero exit after mutation began, prints "Upgrade incomplete - do NOT reboot." and says a rerun is safe and resumes the remaining steps; the state is not written to disk `refs/omarchy/bin/omarchy-upgrade-to-quattro:357-383`.
- **OM7.12** Sleep inhibition starts with the lock descriptor closed and revalidates the recorded PID, start time, owner and random token before each signal, so an update killed before cleanup does not leave the inhibitor holding the flock `refs/omarchy/docs/update-process.md:211-215`.
- **OM7.13** The 3→4 upgrade refuses to run the reboot when `root=` could not be confirmed in the boot entries, so a half-migrated boot cannot be rebooted into `refs/omarchy/bin/omarchy-upgrade-to-quattro:2470-2478`; `refs/omarchy/bin/omarchy-upgrade-to-quattro:654-684`.

### 7.4 Verification

- **OM7.14** Boot verification is the update's final gate: `omarchy-update-boot` runs the platform's `update-verify` lifecycle operation, warns when the boot package is absent (status 3), fails on any other non-zero, and the update exits 1 without a reboot prompt on failure `refs/omarchy/bin/omarchy-update-boot:19-39`; `refs/omarchy/bin/omarchy-update:151-173`.
- **OM7.15** Log analysis is a best-effort verification of the transcript, checking only for initramfs generation failure `refs/omarchy/bin/omarchy-update-analyze-logs:5-13`.
- **OM7.16** The update transcript for debugging is `/tmp/omarchy-update.log`, produced by the `script(1)` re-exec `refs/omarchy/bin/omarchy-update:86-89`; `refs/omarchy/docs/update-process.md:169-170`.

### 7.5 Known limitations stated in docs or visible in code

- **OM7.17** Pacnew/pacsave handling is missing: "Package-backed Omarchy should warn about or help process `.pacnew` and `.pacsave` files after updates." `refs/omarchy/docs/update-process.md:381-383`.
- **OM7.18** The pacman guard's scope is a stated concern: it may block legitimate package-manager frontends or maintenance flows `refs/omarchy/docs/update-process.md:374-379`.
- **OM7.19** User edits to `etc-overrides/` files are clobbered on every `omarchy-settings` upgrade `refs/omarchy/docs/file-layout.md:203-204`.
- **OM7.20** `omarchy-reinstall-configs` clobbers `/etc/skel`-copied user files without backup `refs/omarchy/docs/file-layout.md:409-412`.
- **OM7.21** The aarch64 platform limitation is stated: Omarchy publishes aarch64 packages on edge alone so far, so stable/rc templates are absent and a channel change to those is refused `refs/omarchy/docs/update-process.md:292-298`.
- **OM7.22** `plans/backup.md` is a design plan (Revision 2) for an opt-in restic backup feature; it states Omarchy has "no answer" for disk death/theft/deletion and that `install/user/...`/timers are not shipped yet ("Fully opt-in: no packages installed, no units enabled, no scheduled work, no widget until *Setup > Backup* runs") `refs/omarchy/plans/backup.md:5-14,120-123`. It is a plan, not the update pipeline.
- **OM7.23** The `pre-upgrade` snapshot is best-effort, not a guarantee: a snapshot failure other than the missing-snapper 127 continues the update/upgrade `refs/omarchy/bin/omarchy-update:112-116`; `refs/omarchy/bin/omarchy-upgrade-to-quattro:722-728`.
- **OM7.24** The state/coordination file table (lock, stay-awake state, transcript, current theme, migration markers, reboot/restart markers) documents who owns each file `refs/omarchy/docs/update-process.md:20-30`.

---

## 8. Per-section "not found" (OM8)

Each entry names the search used and the result.

- **OM8.1** Update lock: found. `omarchy-update-lock` takes a `flock` on `$XDG_RUNTIME_DIR/omarchy-update.lock` `refs/omarchy/bin/omarchy-update-lock:33-38`.
- **OM8.2** Migration lock: not found. `rg -n "flock|lock" refs/omarchy/bin/omarchy-migrate` returns only the pacman `db.lck` wait, so a standalone `omarchy-migrate` has no lock of its own `refs/omarchy/bin/omarchy-migrate:68-81`.
- **OM8.3** Dry-run: not found. `rg -in "dry.run|dryrun|--dry|--simulate|--pretend"` over `bin/ migrations/ install/ docs/ plans/` returns only `yt-dlp --simulate` in `refs/omarchy/bin/omarchy-chromium-ytdlp-host:89`, which is unrelated.
- **OM8.4** Checksum or signature verification of the dev git update: not found. `rg -n "tag|pin|checksum" refs/omarchy/bin/omarchy-update-dev refs/omarchy/bin/omarchy-update-available` returns no verification step; the update is `git pull --ff-only` `refs/omarchy/bin/omarchy-update-dev:20-21`. Package channels do verify signatures via pacman `SigLevel` `refs/omarchy/default/pacman/pacman-stable.conf:15-16`.
- **OM8.5** Tag/branch pinning of the runtime: not found. `bin/omarchy-update-dev` follows whatever the upstream branch is; no tag or commit is selected `refs/omarchy/bin/omarchy-update-dev:14-21`.
- **OM8.6** Update rollback command: not found. `rg -in "rollback|revert" refs/omarchy/bin/` finds no system-update rollback verb (only factory-reset `reset-rollback`, sleep-inhibitor rollback, and unrelated code); recovery is boot-time snapper restore `refs/omarchy/bin/omarchy-snapshot:46-48`.
- **OM8.7** Persisted resume/phase state for a package update: not found. `rg -n "resume|state|marker|done" refs/omarchy/bin/omarchy-update` returns only comments; the 3→4 upgrade's `upgrade_started`/`upgrade_completed` are in-memory `refs/omarchy/bin/omarchy-upgrade-to-quattro:357-383`.
- **OM8.8** Runtime read of the `version` file: not found. `rg -n "OMARCHY_PATH/version|omarchy/version"` over the tree matches only `refs/omarchy/docs/file-layout.md:87`; `omarchy-version` derives from `pacman -Q` or git `refs/omarchy/bin/omarchy-version:5-28`.
- **OM8.9** Checksum verification of the `/etc/skel` resync: not found. `omarchy-reinstall-configs` uses `cp -af /etc/skel/. ~/` with no verification `refs/omarchy/bin/omarchy-reinstall-configs:19`.
- **OM8.10** Migration ordering by an explicit index or manifest: not found. Order is the shell glob sort of `migrations/*.sh` `refs/omarchy/bin/omarchy-migrate:40-44`; the guide asserts strict ordering but no separate order file exists `refs/omarchy/agents/skills/migrations.md:129`.
- **OM8.11** Rollback/undo of a migration that already ran: not found. There is no un-apply path; the guide's rerun procedure is to delete the marker and run the migrator `refs/omarchy/agents/skills/migrations.md:159-164`.
- **OM8.12** Automatic `.pacnew`/`.pacsave` processing: not found. Stated as missing `refs/omarchy/docs/update-process.md:381-383`.

---

## 9. Comparison and summary table

Facts only, by channel/source. Blank means the code shows nothing for that cell in the cited files.

| Aspect | stable / rc (package) | edge (package) | dev (git link) | 3→4 upgrade |
| --- | --- | --- | --- | --- |
| Tree location | `/usr/share/omarchy` `refs/omarchy/docs/file-layout.md:70-88` | same | `~/omarchy` clone via `/etc/omarchy.conf` `refs/omarchy/bin/omarchy-channel-set:50-52` | same as target channel |
| Packages | `omarchy omarchy-settings` `refs/omarchy/bin/omarchy-channel-set:109-116` | `omarchy-dev omarchy-settings-dev` `refs/omarchy/bin/omarchy-channel-set:117-120` | `edge` packages + link `refs/omarchy/bin/omarchy-channel-set:121-124` | installs `omarchy-keyring`, settings, `omarchy-nvim`, `omarchy`, `fakeroot`, `pacman-contrib` `refs/omarchy/bin/omarchy-upgrade-to-quattro:789-796` |
| Repo server | `pkgs.omarchy.org/stable` + `stable-mirror` `refs/omarchy/default/pacman/pacman-stable.conf:19-29` | `pkgs.omarchy.org/edge` + `mirror` `refs/omarchy/docs/update-process.md:285-298` | `github.com/omacom/omarchy.git` `refs/omarchy/bin/omarchy-channel-set:52` | per channel `refs/omarchy/bin/omarchy-upgrade-to-quattro:318-333` |
| Signature check | pacman `SigLevel = Required DatabaseOptional` `refs/omarchy/default/pacman/pacman-stable.conf:15-16` | same | none found (OM8.4) | pacman SigLevel for packages |
| Version source | `pacman -Q omarchy` `refs/omarchy/bin/omarchy-version:20-28` | `pacman -Q omarchy-dev` `refs/omarchy/bin/omarchy-version:20-28` | `dev (<hash>)` `refs/omarchy/bin/omarchy-version:8-18` | legacy channel detected, then package version |
| Update mechanism | `pacman -Syu` via `omarchy-update-pacman` `refs/omarchy/bin/omarchy-update-system-pkgs:26-27` | same | `git pull --ff-only` `refs/omarchy/bin/omarchy-update-dev:20-21` | self-contained script `refs/omarchy/bin/omarchy-upgrade-to-quattro:14-16` |
| Pre-update snapshot | snapper, skip on 127 `refs/omarchy/bin/omarchy-update:112-116` | same | same | same `refs/omarchy/bin/omarchy-upgrade-to-quattro:722-728` |
| Migrations | per-user after packages `refs/omarchy/bin/omarchy-update:129` | same | same | runs `omarchy-migrate`, fails if still pending `refs/omarchy/bin/omarchy-upgrade-to-quattro:1260-1275` |
| User config refresh | only via explicit refresh commands / resync `refs/omarchy/bin/omarchy-refresh-config:20-43` | same | same | hash-matched refresh with `.bak`, retired-file removal `refs/omarchy/bin/omarchy-upgrade-to-quattro:1821-1848,2019-2038` |
| Rollback | boot-time snapper restore `refs/omarchy/bin/omarchy-snapshot:46-48`; cache keeps 2 versions `refs/omarchy/bin/omarchy-update-pkg-prune:8-12` | same | same | old checkout kept `.bak` `refs/omarchy/bin/omarchy-upgrade-to-quattro:1088-1102` |
