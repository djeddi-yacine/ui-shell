# Migrations

A migration changes user data when a release needs it in a new shape. This directory ships
inside every release. Shipped so far: `retire-project-wallpaper-folder` (profiles that select the retired `project` wallpaper folder fall back to the shipped default wallpaper).

## Rules

- A migration is an executable file named `<unix-timestamp>-<slug>`. Both parts are fixed once the
  file is released; two files with one timestamp stop the build.
- The first lines carry a header comment `# shape: N`, the positive integer shape of the user data
  after the script ran. Shape 1 is today's layout.
- The script receives `UI_SHELL_CONFIG_HOME` (the user directory), `UI_SHELL_STATE_HOME`,
  `UI_SHELL_RELEASE` (the release, read-only) and `UI_SHELL_DRY_RUN`. It changes user data and state
  only, never the release, and never anything outside those two directories.
- It must be idempotent: `--force` can run it a second time after a crash.
- A released script is never edited. The runner stores its checksum in the marker; a changed script
  stops the update. Fix a mistake with a new migration.
- Order is by timestamp. A script older than the highest applied one is reported and stops the update.
- A non-zero exit stops the update and leaves the pending marker; the user then runs
  `update-ui-shell --force` or `--rollback`.
- A migration whose shape exceeds the previous release's `reads_max` gets a snapshot of the user
  directory first. Keep `reads_min`/`reads_max` in `manifest.ini` honest: they are the shapes a release can read.
