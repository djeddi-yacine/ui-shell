# crossing

## Overview
The one frozen migration that creates the user directory for the first time: from the development layout when it exists, otherwise from the shipped baseline (a clean install). It handles shape 1 only and is run by `update/run` (the `migrate` phase) like any other migration.

## Interface
- `0001-from-dev-stage RELEASE CONFIG STATE OLD_DIR` [0001-from-dev-stage]: with `OLD_DIR/config.ini` and `OLD_DIR/scripts` present it copies `themes/`, `profiles/`, `components/` and `hypr/user/*.lua` (to `lua/`) once, and translates `config.ini` into `settings.ini`. Without them it seeds the shipped baseline.
- Environment as for every migration: `UI_SHELL_CONFIG_HOME`, `UI_SHELL_STATE_HOME`, `UI_SHELL_RELEASE`, `UI_SHELL_DRY_RUN` (see [../../migrations/EGM.md](../../migrations/EGM.md)).

## Invariants
- The old directory is only read, never changed [0001-from-dev-stage header].
- `settings.ini` is written last, so an interrupted run repeats; once it exists the script does nothing [0001-from-dev-stage header].
- Relative `[wallpaper_folders]` values and the `[phantomat] library` path are made absolute against `OLD_DIR` [0001-from-dev-stage:abs].
- A `hypr/user/*.lua` file identical to the release's `hypr/default/<name>` is not copied [0001-from-dev-stage].
- The whole `themes/`, `profiles/` and `components/` directories of the old layout are copied, so profiles keep every theme they name [0001-from-dev-stage].
- The script is frozen: it is never edited after release (its checksum is stored in the migration marker).
- After it ran, every migration shipped in the release has a marker without having run.

## Side Effects
- Creates and fills `UI_SHELL_CONFIG_HOME` (themes, profiles, components, lua, `settings.ini`) and writes migration markers under `UI_SHELL_STATE_HOME/migrations/`.
- Reads `OLD_DIR`; writes nothing there.

## Verification
- Run: `make test-crossing`
