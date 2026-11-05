---
id: shell-architecture-and-omarchy-boundary
title: Shell structure adopts Omarchy boundaries without its desktop scope
category: decision
status: active
tags: [shell, omarchy, quickshell, qml, composition]
created: "2026-09-30T20:40:02"
updated: "2026-09-30T20:40:10"
---

<!-- compiled_truth -->
# Decision

Use a small, composable Quickshell architecture informed by Omarchy, without reproducing its desktop-environment breadth.

## Adopted patterns

- One long-lived Quickshell host with a shallow bootstrap.
- Explicit boundaries for config, theme, state, surfaces, modules, components, adapters, assets, and tests.
- Per-monitor surface composition.
- Stable module IDs and explicit configuration data.
- Shared visual tokens instead of scattered constants.
- Lazy loading for optional and transient modules.

## Rejected scope

- No custom daemon, IPC control plane, or shell CLI.
- No unrestricted plugin marketplace or arbitrary source loading.
- No JavaScript source files or JavaScript-based feature models.
- No broad desktop service catalog merely because the reference has one.

## Rationale

Omarchy demonstrates how a long-lived Quickshell host can remain expandable when responsibilities are explicit. Our shell keeps the same structural discipline while remaining a focused visual layer with file-backed generated state and QML composition.


## Timeline

- time: 2026-09-30T20:40:02
  kind: decision
  summary: "Created this page: Shell structure adopts Omarchy boundaries without its desktop scope"
  source: shell/README.md and refs/omarchy
  affects: [shell-architecture-and-omarchy-boundary]

- time: 2026-09-30T20:40:10
  kind: decision
  summary: Recorded which Omarchy shell patterns this project adopts and which desktop-environment scope it rejects.
  source: shell/README.md and refs/omarchy
  affects: [shell-architecture-and-omarchy-boundary]
