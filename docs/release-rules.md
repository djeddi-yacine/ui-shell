# Release rules

What every release must satisfy so that `update-ui-shell` can install it, and so that a user on any
earlier release can reach it. Each rule names where it is enforced. A release that breaks one is
refused by the updater, or worse, strands users; fix the release, never the check.

Run `make test` and `make dev-check-update` before tagging (they enforce most rules), then follow
`docs/release-testing.md`.

## 1. The tag

1. **Annotated and signed** with the pinned release key (primary `F197 7EFA 4568 E387 9A3A  3A12 5789 D9D1 5BF7 7066`,
   a signing subkey of it). The activator runs `git verify-tag` against the key pinned at install time
   and refuses anything else (`update/activator:tag_verifies`).
2. **The signing subkey is valid.** It must not be expired or revoked. The current subkey expires
   2028-11-10: before then, add a new signing subkey to the same primary, replace `update/signer.asc`
   in a release, and tell users to run `update/install-activator` again (same primary, no prompt).
   A different primary is a re-pin that every user must confirm by hand (`--repin`), so avoid it.
3. **The name is final.** The tag name matches `^[A-Za-z0-9][A-Za-z0-9._+-]*$`, has no `..`, and does
   not end in `.tmp`. A tag object republished under another name is refused, and an existing tag is
   never moved: fix a bad release with a new tag.
4. **It sorts above every released tag** under `sort -V`. The activator refuses a tag older than the
   active release (`-rc` ranks below its release). Use `vMAJOR.MINOR.PATCH`.
5. **It names the cloned commit** and is pushed with `main` at that commit; the tag is signed on the
   commit that is in the public history.

## 2. The tree at the tag

6. **The parts exist:** `update/ scripts/ shell/ hypr/ migrations/ default/ wallpapers/ bundled-themes/`
   plus `tools/manifest.ini` and `tools/settings.ini` (`update/build-release`).
7. **No symlinks** inside those parts and **no newline in any file name** (`update/build-release`).
   The repository holds no runtime links; the release layout creates them.
8. **No file outside `SHA256SUMS`.** The release is built read-only and verified by `sha256sum --check
   --strict`; nothing may be written into it at run time (`update/check-release`).
9. **`update/signer.asc`** holds exactly one usable public key with a signing subkey
   (`update/install-activator`).
10. **The default settings are valid**: `tools/settings.ini` is the baseline of a clean install, and
    `scripts/read-shell-config` must accept the release with it.

## 3. It must start

11. `scripts/prepare-runtime` runs against a clean scratch home and `Hyprland --verify-config` passes
    on `hypr/hyprland.lua` with the generated runtime (`update/check-release`, run by `--dry-run` and
    again after activation).
12. Everything the shell needs from the user lives in the four roots (data, `~/.config/user-wm-shell`,
    state, cache). A release never writes into its own tree and never into another release.
13. `scripts/start-session` is the only supported start; it regenerates the runtime when the `RELEASE`
    stamp changes. Do not add another entry point that skips it.

## 4. User data and migrations

14. `tools/manifest.ini` states `reads_min` and `reads_max`: the shapes of user data this release can
    read. Keep them true; pruning and snapshots depend on them (`update/prune`, `update/run-migrations`).
15. **A change of user data shape needs a migration** in `migrations/` named `<unix-timestamp>-<slug>`,
    executable, with a `# shape: N` header, idempotent, touching only `UI_SHELL_CONFIG_HOME` and
    `UI_SHELL_STATE_HOME`. Details: `migrations/README.md`.
16. **A released migration is never edited, renamed or removed.** Its checksum is stored in the marker; a
    changed script stops the update. Fix a mistake with a new migration with a later timestamp.
17. **Timestamps only grow.** A migration older than the highest one applied is reported and stops
    the update; two files with one timestamp stop the build.
18. **The previous release must still be able to run** on the migrated data if its `reads_max` covers
    the new shape; otherwise the update takes a snapshot first. Never raise the shape without a
    migration and a snapshot path that `--rollback` can restore.

## 5. The updater itself

19. **The protocol between the installed activator and `update/run` is stable.** An old installed
    activator runs the new release's `update/run` with `UI_SHELL_UPDATE_{MODE,TAG,CLONE,DATA,CONFIG,STATE,CACHE}`;
    a release may add variables or modes but must keep the old ones working. The activator replaces
    itself only after a successful update, so a release that breaks this strands every earlier install.
20. **`update/lib` is inlined** into the installed activator (`ui_compose_activator`); keep the
    `source "$here/lib" # inline-lib` line exactly.
21. **Exit codes keep their meaning:** 0 done or current, 1 failed with state intact, 2 usage, 3 refused,
    4 pending marker. The session start hint and the docs rely on them.
22. **`--rollback` works on the new release.** `update/rollback` ships in every release and must restore
    the previous release and any snapshot; test it (`make test-crash`, `make test-migrations`).

## 6. Before the tag is pushed

23. `make test`, `make dev-lint`, `make dev-shellcheck` and `make dev-check-update` pass on the tagged commit.
24. The signing rehearsal in `docs/release-testing.md` section 2 succeeds with the real subkey.
25. After pushing, `make dev-update` passes against the public repository, and for any release after
    the first, an upgrade from the previous tag passes too (kept `--home`, see `docs/release-testing.md`).
