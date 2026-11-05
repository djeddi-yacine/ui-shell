---
id: wallpaper-cache-identity
title: "Wallpaper palettes are cached by content hash, mode and key schema only"
category: decision
status: active
tags: [wallpaper, cache, matugen, profiles]
created: "2026-10-27T02:45:04"
updated: "2026-11-05T02:10:59"
---

<!-- compiled_truth -->
# Decision

## Wallpaper palettes are cached by content hash, mode and key schema only

A wallpaper-derived palette is addressed by:

`<sha256>-<mode>-v2`

- `sha256` is the hex SHA-256 of the image bytes.
- `mode` is `dark` or `light`.
- `v2` is the palette-key schema. Change it when the hash input, mode set or key grammar changes.

The cache path is `$XDG_CACHE_HOME/$cache_namespace/$palette_key/colors.json`. The key deliberately contains **no wallpaper filename and no extractor name**. The old `<sha256>-matugen4-<mode>-v2` shape identified the extractor, not the image, and made cache directories look like they named a wallpaper. `matugen4` is not part of palette identity.

## Compatibility

Old `matugen4` keys are rejected by selection readers and require reselection. There is no dual reader, alias, cache-directory rename or migration. The repository is pre-release and its existing policy is to fail clearly rather than silently convert old contracts. The checked-in default profile uses the new keys.

## Why this shape

- The profile recipe already stores the folder ID and filename; repeating the filename in the cache key adds a second identity that can disagree.
- Content addressing stays stable when a folder moves: only the configured folder path changes, not the image bytes or the key.
- A raw filename would need sanitizing for path safety and case/Unicode rules, without improving uniqueness.
- Keeping the mode and a trailing schema makes stale or incomplete palettes fail validation instead of being treated as valid.

## Consumers

`cache-wallpaper-colors`, `render-wallpaper-selection`, `read-theme-state`, `read-wallpaper-selections`, and `select-theme-profile` all construct or validate the same key. Their contract tests derive it independently from the image bytes. Any future key change must update all five together and bump the trailing schema.


## Timeline

- time: 2026-10-27T02:45:04
  kind: decision
  summary: "Created this page: Wallpaper palettes are cached by content hash, mode and key schema only"
  source: "Wallpaper cache key decision, 2026-10-27"
  affects: [wallpaper-cache-identity]

- time: 2026-10-27T02:45:04
  kind: decision
  summary: "Define the wallpaper palette cache key as sha256-mode-v2, reject old matugen4 keys, and keep filenames and extractor names out of identity."
  source: "Implemented and verified in scripts/ and tests/, 2026-10-27"
  affects: [wallpaper-cache-identity]

- time: 2026-11-05T02:10:59
  kind: evidence
  summary: "Wallpaper palette roles come from scripts/extract-colors, which maps Material roles directly: positive=tertiary (used for the 'current' control state), warning=secondary (unused), negative=error; ANSI green/yellow are tertiary and no terminal config in this repo consumes them. Making status colours hue-faithful would change the generator output, so the palette key schema (hardcoded as -v2 in about eight scripts and tests plus the default seed) would need a v3 bump; deferred pending the user's decision."
  source: "profile audit, 2026-11-05"
  affects: [wallpaper-cache-identity]
