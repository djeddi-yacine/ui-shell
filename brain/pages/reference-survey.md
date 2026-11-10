---
id: reference-survey
title: Reference repository survey
category: reference
status: active
tags: [quickshell, hyprland, composition, ipc]
created: "2026-09-30T04:43:21"
updated: "2026-11-10T04:17:25"
---

<!-- compiled_truth -->
# Reference survey findings

The nine reports in refs/analysis compare Caelestia shell, Omarchy, DankMaterialShell, Phantomat, end-4 dots-hyprland, Hyprland wiki, Ambxst, Noctalia, and qtengine. They are historical evidence, not permission to import those projects' broader desktop scope.

## Reference freshness contract

Before learning from any cloned reference or wiki, inspect its branch/tracking state and local modifications, then pull the tracked branch. Reference refresh allows fast-forwards and merge commits, not an ff-only restriction or automatic rebase. Use `make refs-pull` to refresh the Git checkouts directly inside `refs/`. Preserve dirty checkouts by skipping them, continue updating the remaining repos, and report skipped or failed pulls with a failure status. Never automatically stash, reset, overwrite, or change branches. Report unavailable network access or merge conflicts rather than treating old source as current. Re-read the relevant source after updates, and check guidance against the installed target runtime version before adopting new APIs.

## Cross-cutting evidence

- Keep QML/Quickshell as composition and presentation: screen-scoped surfaces, reusable widgets, lazy loaders, typed models, and shared theme/config tokens.
- Keep one authoritative owner for each external capability; widgets should not independently reconstruct compositor, audio, media, or notification state.
- Prefer native event subscriptions with an initial snapshot/reconciliation over tight product polling. Consider reconnects, compositor restarts, stale results, and version drift.
- Use explicit configuration for layout, theme, enabled modules, and user policy. Reference preset values remain reference material; the user's explicit default-and-override contract governs this project.
- Some reference projects justify daemons and custom IPC for their wider desktop scope. That is historical analysis, not this project's architecture: the active shell forbids a custom daemon, custom IPC control plane, or product CLI.
- Compositor rendering, low-level input forwarding, and transformed window lifecycle behavior belong in compositor plugins or native integrations, not shell composition.

Implementation claims must be checked against fresh source and the installed Quickshell/Hyprland versions. Active project decisions are in [[shell-scope-and-layout]], [[shared-style-and-toolkit-integration]], and [[wallpaper-source-and-generation]].


## Timeline

- time: 2026-09-30T04:43:21
  kind: decision
  summary: "Created this page: Reference repository survey"
  source: "refs/analysis/*.md"
  affects: [reference-survey]

- time: 2026-09-30T04:43:33
  kind: decision
  summary: Captured the first cross-repository survey as evidence for later architecture decisions.
  source: "refs/analysis/*.md"
  affects: [reference-survey]

- time: 2026-10-02T05:40:58
  kind: decision
  summary: Require fast-forward refresh before learning from reference repos or wiki
  source: "User: always pull latest changes while learning from refs or wiki"
  affects: [reference-survey]

- time: 2026-10-03T03:25:53
  kind: decision
  summary: Align wording with the explicit default-and-override configuration contract.
  source: "User: every configurable concern uses a user-set default, not a recovery state."
  affects: [reference-survey]

- time: 2026-10-10T15:35:28
  kind: reversal
  summary: "Replace the fast-forward-only refresh policy with merge-allowed pulls; preserve dirty checkouts."
  source: "User requests a refs Make target without ff-only, 2026-10-10"
  affects: [reference-survey]

- time: 2026-10-10T15:35:28
  kind: decision
  summary: Document merge-allowed reference refresh and preservation of dirty repositories.
  source: "User request and verified refs-pull target, 2026-10-10"
  affects: [reference-survey]

- time: 2026-11-10T04:17:25
  kind: reversal
  summary: "Correct the earlier reading that refs/dots-hyprland/dots/ is empty: the checkout is populated (.config/quickshell/ii), so the clipboard study now records its real Quickshell side (cliphistService, Cliphist.qml, launcher integration)."
  source: features/studies/clipboard.md checkout note
  affects: [reference-survey]
