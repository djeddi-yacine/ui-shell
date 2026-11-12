# tools/scripts

## Overview

Development-time commands of the shell. None of them ships in a release (`tools/` is outside the release parts in
`update/build-release`) and no runtime code calls them; they are run from a checkout, by `make` targets
(`tools/development.mk`, `tests/targets.mk`) or by the tests. Runtime scripts live in `../../scripts`. Scripts that
read or write shell runtime pieces take the checkout (or a staging directory) as an argument and call the runtime
scripts from there.

## Interface

Release and update proofs

- `release patch|minor|major [--plan] [--no-test] [--no-gate] [--no-push] [--no-public] [--yes]` — bump `VERSION`, sign
  the tag, prove install and previous-to-new upgrade plus rollback in the sandbox, push.
  Needs `RELEASE_GNUPGHOME`; optional `RELEASE_SIGNING_KEY`, `RELEASE_SIGNER_KEY`, `RELEASE_REMOTE`, `RELEASE_BRANCH`.
- `dev-update [--repo] [--from] [--to] [--steps] [--fingerprint] [--home] [--keep] [--no-net] [--signer-key]` —
  install and update like a stranger inside a Bubblewrap sandbox (steps `install,dry-run,update,again,rollback`).
- `dev-release SOURCE_ROOT BUILD_DIR [--check]` — build a read-only release into `BUILD_DIR/release/dev`; `--check`
  rehearses it against a scratch user directory.

Staging and defaults

- `stage-config SOURCE_ROOT DESTINATION` — install `scripts/`, `shell/`, `hypr/`, defaults and the manifest into a
  separate staging root; adds the dev-only `project = wallpapers` folder to the staged manifest and links wallpaper
  folder directories.
- `stage-defaults SOURCE_ROOT DESTINATION` — install the `default/` seed and the missing `bundled-themes/` entries;
  existing themes and profiles are never replaced.
- `generate-default DEFAULT_DIRECTORY` — regenerate `default/theme.ini` and `default/profile.ini` from
  `default/default.png` with the runtime renderers.

Themes, icons, wallpapers, monitors

- `import-theme-colors REFERENCE_ROOT DESTINATION NORMALIZER RENDERER POSITIVE WARNING NEGATIVE` — convert reference
  `*/colors.toml` palettes into `DESTINATION/<id>/config.ini`.
- `import-reference-themes RESOLVED_RUNTIME REFERENCE_ROOT POSITIVE WARNING NEGATIVE` — run `import-theme-colors` with
  the normalizer and renderer roles of a resolved runtime.
- `bundle-reference-themes GENERATED_THEMES REFERENCE_ROOT BUNDLE_DIRECTORY` — copy generated themes into the
  checked-in `bundled-themes/`.
- `generate-icons [--check]` — convert `shell/svg/*.svg` into `shell/icons/*.qml` with `svgtoqml`; `--check` exits 1
  when a file is missing or out of date.
- `fetch-wallpapers [--check]` — download the test wallpapers listed in `wallpapers/manifest.txt` and verify SHA-512.
- `generate-monitor-overrides [MONITORS_JSON]` — print Lua monitor overrides from `hyprctl -j monitors` or a JSON file.
- `lint-qml SOURCE_ROOT RUNTIME_CONFIG_DIR QMLLINT` — lint `shell/` QML on a scratch copy with generated singletons
  overlaid, ignoring the warnings listed in `tools/qmllint-upstream.txt`.

## Invariants

- Every script runs under `set -euo pipefail` (the Python `generate-icons` exits non-zero on any refusal) and exits 2 on
  a usage error.
- `release`: refuses a dirty tree, a `VERSION` that disagrees with the newest local tag, a tag that exists locally or on
  the remote, and a signing key whose primary is not the one pinned by the signer key file; asks before signing unless
  `--yes`; removes the release commit and the tag again if anything fails before the push (`release:undo`).
- `release` has no default key home: `RELEASE_GNUPGHOME` must be set. Only secret keys that can sign themselves
  (lowercase `s`, not a stub, not expired or revoked) are candidates.
- `dev-update` writes only inside the sandbox home; a local `--repo` is bound read-only.
- `dev-release` requires `BUILD_DIR` inside `SOURCE_ROOT`.
- `stage-config` and `stage-defaults` refuse a destination equal to the source or `/`; `stage-defaults` requires
  `default/` to hold exactly `default.png`, `profile.ini` and `theme.ini`, all regular files, and refuses symlinked
  `themes/` or `profiles/` stores.
- `import-theme-colors` converts every palette before publishing any output, so invalid input leaves existing outputs
  unchanged; it refuses symlinked destinations, duplicate theme IDs, unsupported palette paths and a destination that
  overlaps the reference root.
- `fetch-wallpapers` keeps a download only after its SHA-512 matches the manifest line; only `https` URLs are used.
- `generate-icons` accepts only plain white shapes; any other colour or element is refused.
- `generate-monitor-overrides` output is host-specific and is never committed as a default.

## Side Effects

- `release`: edits and commits `VERSION`, creates a signed tag (asks for the key passphrase), pushes `main` and the tag
  atomically to the remote, runs `make` gate targets and sandbox installs under `.build/`.
- `dev-update` (and the `release` proofs that call it): runs `bwrap` and clones `--repo`; the network is used only when `--repo` is a URL and `--no-net` is not given.
- `dev-release`: removes and recreates `BUILD_DIR/release/dev`.
- `stage-config`, `stage-defaults`: write the destination directory (`scripts/`, `shell/`, `hypr/`, `default/`,
  `manifest.ini`, `settings.ini` once, theme and profile seeds, asset symlinks).
- `generate-default`: overwrites `default/theme.ini` and `default/profile.ini`.
- `bundle-reference-themes`, `import-theme-colors`: write theme `config.ini` files under the destination.
- `generate-icons`: rewrites `shell/icons/*.qml`.
- `fetch-wallpapers`: downloads with `curl` into `wallpapers/`.
- `generate-monitor-overrides`: reads `hyprctl`; prints to stdout only.
- `lint-qml`: temporary scratch directory; prints warnings.

## Verification

- Run: `make test` (focused: `make test-release test-rich-release test-update`, `make dev-shellcheck`,
  `make dev-lint`, `tools/scripts/generate-icons --check`).
