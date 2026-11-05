---
id: shipped-default-seed
title: One clean shipped default seed
category: decision
status: active
tags: [default, staging, tests, config]
created: "2026-10-27T03:28:00"
updated: "2026-10-30T14:36:42"
---

<!-- compiled_truth -->
# Decision

The source tree ships exactly one default seed: `default/` contains `default.png`, `theme.ini`, and `profile.ini`, and nothing else. The source tree has no `themes/` or `profiles/` stores. Runtime `themes/` and `profiles/` remain user-owned XDG stores for created and imported data; they are never populated from a checked-in second copy.

`tools/scripts/generate-default` is the development-only generator. It derives both `default/theme.ini` and `default/profile.ini` from `default/default.png` through the same runtime extractor and renderers. The profile records `source = file`, `definition = themes/default/config.ini`, `folder = default`, `path = default.png`, `fit_mode = cover`, an empty output scope, and full palette snapshots from the same JSON as the Theme. The wallpaper palette key is `<sha256>-<mode>-v2`. Runtime staging never generates or rewrites defaults, so the shipped Theme and profile cannot drift from the wallpaper.

`tools/scripts/stage-defaults` is the single seed-installation boundary for staging, tests, and private state. It rejects any source seed whose entries differ from the three expected regular files, cleanly replaces the destination `default/`, and seeds `themes/default/config.ini` and `profiles/default/profile.ini` only when those files are absent. Existing user stores always win. `tools/scripts/stage-config` calls it, refreshes runtime code and the clean seed, and preserves `hypr/user/monitors.lua` across restages.

No host-specific values ship as defaults. `hypr/user/monitors.lua` declares the required policy shape with `overrides = {}`; `tools/scripts/generate-monitor-overrides` prints an explicit override table for host-specific review and merge. `shell/config/Outputs.qml` keeps the optional picker output name empty, and `shell/config/AppLauncher.qml` invokes `app2unit` from PATH rather than an absolute host path. Machine-specific output names and generated overrides belong in user policy or optional generated files, never in reusable defaults.

Tests generate their own non-default fixtures in private state and never depend on source `themes/` or `profiles/`. GUI checks that need a different applied wallpaper select the configured `project` folder, not the writable staged `default/` seed. A read-only external asset check must not treat staged `default/` as an external asset root. `tests/scripts/check-defaults` verifies the exact seed, deterministic regeneration, profile/Theme coherence, clean replacement, absent-only store seeding, preserved monitor policy, and empty shipped overrides.

Related: [[xdg-runtime-and-theme-schema]], [[theme-profile-bundles]], [[wallpaper-source-and-generation]], [[isolated-nested-test-environment]], [[application-launcher-boundary]].


## Timeline

- time: 2026-10-27T03:28:00
  kind: decision
  summary: "Created this page: One clean shipped default seed"
  source: "Default seed redesign, 2026-10-27"
  affects: [shipped-default-seed]

- time: 2026-10-27T03:29:59
  kind: decision
  summary: "Define one clean default seed with deterministic generation, absent-only store seeding, empty host defaults and private test fixtures"
  source: "Default seed redesign and verification, 2026-10-27"
  affects: [shipped-default-seed]

- time: 2026-10-27T03:29:59
  kind: decision
  summary: "Adopt default/ as the only shipped seed: generate Theme/profile from default.png, stage cleanly, seed runtime stores only when absent, keep host monitor/output values empty, and generate test fixtures privately"
  source: "Implemented and verified default seed, staging, and fixture migration, 2026-10-27"
  affects: [shipped-default-seed, theme-profile-bundles, wallpaper-source-and-generation, isolated-nested-test-environment]

- time: 2026-10-30T14:36:42
  kind: evidence
  summary: "Verified the default/ source seed remains distinct from runtime Theme and Profile records: staging refreshes the seed and seeds themes/default and profiles/default only when absent."
  source: "Script audit and isolated defaults checks, 2026-10-30"
  affects: [shipped-default-seed]
