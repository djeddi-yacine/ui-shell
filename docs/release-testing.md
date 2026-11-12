# Release testing

How to check a release before and after it is signed. Everything here is run by the owner; nothing
below signs, tags or pushes by itself.

## 1. Gate before tagging (no network, no keys)

```bash
make test            # the whole suite, including test-update, test-activator, test-crash,
                     # test-migrations and test-crossing (throwaway keys and a local bare remote)
make dev-lint        # QML lint with the generated files; must print "QML lint clean"
make dev-check-update  # builds .build/release/dev and rehearses it against a clean settings copy
```

## 2. Rehearse the real signing key without publishing

Use a scratch checkout and a scratch HOME so your real `~/.local`, `~/.config` and `~/.local/state`
are never touched. This signs a **local** tag only.

```bash
scratch=$(mktemp -d)
git clone . "$scratch/repo" && cd "$scratch/repo"
GNUPGHOME=$HOME/.local/share/gnupg/releases git tag -s -m 'rehearsal' v0.0.0-rehearsal
GNUPGHOME=$HOME/.local/share/gnupg/releases git verify-tag v0.0.0-rehearsal   # Good signature, primary F197 7EFA ...
```

`git verify-tag` against a clean keyring (what the activator does) is covered by `make test-activator`;
this step proves your real subkey signs and that `update/signer.asc` is the matching public key
(`gpg --show-keys --with-fingerprint update/signer.asc` prints the README fingerprint). Delete the
scratch directory afterwards.

## 3. First real release (publishes: confirm each step)

1. Commit the work (the repository has no commits of this feature yet) and push `main`.
2. `GNUPGHOME=$HOME/.local/share/gnupg/releases git tag -s -m 'v0.1.0' v0.1.0` then `git push origin v0.1.0`.
   The tag name is final: the activator refuses a republished name.
3. In a **scratch HOME** (no `XDG_*` set), as a stranger would:

   ```bash
   scratch=$(mktemp -d)
   clean() { env -u XDG_DATA_HOME -u XDG_CONFIG_HOME -u XDG_STATE_HOME -u XDG_CACHE_HOME HOME=$scratch "$@"; }
   clean bash update/install-activator            # type the fingerprint from the README
   clean $scratch/.local/bin/update-ui-shell --dry-run
   clean $scratch/.local/bin/update-ui-shell
   ```

   Expect: dry-run changes nothing; the update leaves `current -> releases/v0.1.0`, `settings.ini`
   from the baseline, no pending marker.
4. Then your own machine: `update/install-activator`, `update-ui-shell`. If you used the dev layout,
   the crossing copies `themes/`, `profiles/`, `components/` and edited `hypr/user/*.lua` once and
   leaves the old directory untouched; keep it until the new session has started.
5. Log out, start the session through `scripts/start-session`, and check the shell, the menu, a
   notification, and `update-ui-shell --rollback` followed by another start.

## 4. What to look for

| Symptom | Meaning |
|---|---|
| `Refused: ... is older than the active` | The tag sorts below the active one (`-rc` ranks below its release). |
| exit 4 and `update-ui-shell` hint at session start | A pending marker: an update was interrupted; run `update-ui-shell --force` or `--rollback`. |
| `Migration ... changed after it was applied` | A shipped migration was edited; add a new one instead. |
| signature failure | Wrong pinned key or an unsigned/moved tag; the pinned key is `~/.local/state/ui-shell/signer.asc`. |

Revoked-key signatures and republished tag names are covered by `make test-activator`.
