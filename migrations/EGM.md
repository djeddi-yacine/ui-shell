# migrations

## Overview
Ships inside every release. A migration changes user data when a release needs it in a new shape. The prose rules are in [README.md](./README.md) (kept as written); this contract states them as invariants. The first version ships no migration here: the first user directory is created by [../update/crossing/EGM.md](../update/crossing/EGM.md).

## Interface
- A migration is an executable file `<unix-timestamp>-<slug>` with a header comment `# shape: N` (positive integer, the shape of user data after it ran) [README.md].
- Environment passed by `update/run-migrations`: `UI_SHELL_CONFIG_HOME`, `UI_SHELL_STATE_HOME`, `UI_SHELL_RELEASE` (read-only) and `UI_SHELL_DRY_RUN` [README.md].
- Marker per applied migration: `STATE/migrations/NAME` with `checksum=` and `shape=` [../update/run-migrations].

## Invariants
- Both parts of the file name are fixed once released; two files with one timestamp stop the build [README.md].
- A released script is never edited; a changed checksum stops the update [README.md].
- Order is by timestamp; a script older than the highest applied one is reported and stops the update [README.md].
- A script changes user data and state only, never the release and never anything outside those two directories [README.md].
- A script is idempotent: `--force` can run it a second time after a crash [README.md].
- A migration whose shape exceeds the previous release's `reads_max` gets a snapshot of the user directory first [README.md].
- A non-zero exit stops the update and leaves the pending marker [README.md].

## Side Effects
- Scripts here run only through `update/run-migrations`; they mutate the user directory and write markers under the state directory.

## Verification
- Run: `make test-migrations`
