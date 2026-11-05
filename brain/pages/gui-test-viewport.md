---
id: gui-test-viewport
title: GUI checks use a deterministic private viewport
category: decision
status: active
tags: [tests, gui, viewport]
created: "2026-11-01T01:30:24"
updated: "2026-11-01T01:30:30"
---

<!-- compiled_truth -->
# Decision

GUI checks that assert layout or capture pixels must not depend on the host-tiled size of the nested Wayland window. The nested compositor's Wayland output inherits the host window geometry; on a tiled host it can shrink to a narrow tile (observed 384x407), which makes a 1280x720 layout assertion fail for reasons unrelated to the shell.

The theme-editor check creates a private headless output inside the nested session, waits for it to report at least 720x720, and targets that output for the editor and its `grim` captures. The default Aquamarine headless output is 1280x720. `check-borders` already uses the same headless-output mechanism for a secondary output. The output exists only in the disposable nested session; the host display, window layout, and configuration are not touched.

Keep host-sized outputs for checks whose purpose is the real nested window. Do not weaken layout assertions to accommodate an accidental small host tile; give the check a known viewport instead. See [[isolated-nested-test-environment]] and [[theme-profile-bundles]].


## Timeline

- time: 2026-11-01T01:30:24
  kind: decision
  summary: "Created this page: GUI checks use a deterministic private viewport"
  source: "Theme editor test host-window size investigation, 2026-11-01"
  affects: [gui-test-viewport]

- time: 2026-11-01T01:30:30
  kind: decision
  summary: Theme-editor GUI checks target a private 720p headless output because the host-tiled nested window size is not stable.
  source: "Observed 384x407 host tile vs 1280x720 headless output; make test-profiles pass"
  affects: [gui-test-viewport]
