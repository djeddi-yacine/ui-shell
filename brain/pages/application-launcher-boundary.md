---
id: application-launcher-boundary
title: Application launcher stays a native catalog and app2unit handoff
category: decision
status: active
tags: [shell, launcher, devices]
created: "2026-10-05T01:31:52"
updated: "2026-11-09T02:30:20"
---

<!-- compiled_truth -->
# Decision

The application launcher owns only installed-app discovery, fast keyboard-first search, a single candidate, and launch handoff. Native Quickshell DesktopEntries supplies the live catalog; app2unit is the only real runner. It receives desktop-entry IDs rather than reinterpreted Exec command strings, delegating native quoting, supported field codes, working directories, and terminal handling to app2unit. Successful handoff closes the panel; failure remains visible. No history database, command runner, calculator, provider framework, daemon, or custom IPC is included.

Device identity belongs to user configuration, never reusable components. Runtime screen discovery is composed with explicit user defaults and optional generated overrides. Generated overrides are preferred for machine-specific choices; absence means use the declared default, not a fallback mode. Invalid or unavailable exact targets are errors and never switch outputs silently. Per-output palettes remain separate from launcher host selection. The shipped runner is the explicit `app2unit` command resolved from PATH, and no hardware output name is committed as a default; generated user policy supplies host-specific values. See [[shipped-default-seed]].

Quickshell alone owns entry/exit motion for shell layers. Keyboard selection and focus stay immediate and distinct from hover, using the shared sharp-corner theme. Production AppRunner.qml remains unaware of sandboxing; production config invokes native app2unit in service mode. Tests adapt their environment and staged QML runner config, never the production component.

Interactive nested sessions use tests/scripts/run-app2unit with the same desktop-entry ID, prompt successful handoff and nonzero/stderr failure contract. Native app2unit owns parsing and terminal handling; only its systemd-run transport is adapted with a test-private PATH shim. A filtered host user-manager proxy registers run-owned scopes/slices while native scope environment options restore the private runtime, session D-Bus and original PATH. Applications stay inside the nested session namespaces and display. No host manager environment imports, graphical target changes, private UWSM setup, redundant production wrapper, daemon or product IPC is added.

make test-app-launch has passed a real nested GUI launch through the unchanged production AppRunner, private app environment and scope-membership checks, and missing-desktop-entry failure. It captures the live window and checks exact-unit/process/host-state cleanup. make test-launcher remains native app2unit dry-run/UI coverage; make test-app2unit retains the standalone scope-before-Bubblewrap proof. These do not prove production service-mode launching or terminal behavior. The manager proxy filters names rather than method arguments, so test applications must be trusted. See [[isolated-nested-test-environment]].


## Timeline

- time: 2026-10-05T01:31:52
  kind: decision
  summary: "Created this page: Application launcher stays a native catalog and app2unit handoff"
  source: User launcher request and generated device override requirement
  affects: [application-launcher-boundary]

- time: 2026-10-05T01:32:07
  kind: decision
  summary: Keep launcher focused and device choices in explicit user defaults plus generated overrides
  source: "User requirements; local Quickshell and app2unit source"
  affects: [application-launcher-boundary]

- time: 2026-10-05T01:41:46
  kind: decision
  summary: "Delegate supported desktop-entry semantics to app2unit; do not emulate unsupported fields"
  source: Installed app2unit parser and isolated launcher test
  affects: [application-launcher-boundary]

- time: 2026-10-09T03:11:13
  kind: decision
  summary: "Record passed host-registration/sandboxed-app scope proof, retained test and narrow exception; ordinary launcher/session targets unchanged"
  source: "2026-10-09 make test-app2unit native run; /tmp/ui-shell-app2unit.Bt0ZvR/probe.log"
  affects: [application-launcher-boundary]

- time: 2026-10-09T03:22:20
  kind: reversal
  summary: "Test integration must not change AppRunner.qml or add sandbox-aware production logic. The nested session supplies an explicit test-only runner adapter/config override, preserving the same desktop-entry ID input, prompt successful handoff and nonzero/stderr failure contract as production app2unit service mode. Test-only host registration, sandboxing, nested display/environment and scoped cleanup belong in tests/scripts/. Production remains native app2unit; no redundant production wrapper, custom product daemon or IPC protocol is required."
  source: "User 2026-10-09: test environment must adapt; shell logic must not be tied to it"
  affects: [application-launcher-boundary]

- time: 2026-10-09T03:43:41
  kind: decision
  summary: "Record test-only native manager proxy and passed real GUI launch; production runner unchanged"
  source: "2026-10-09 make test-app-launch /tmp/my-shell-test.kLCLCf; user environment-only boundary"
  affects: [application-launcher-boundary]

- time: 2026-10-12T02:44:50
  kind: decision
  summary: "Keep the first filtered app visibly marked as the launch candidate while search owns text focus; list focus remains separate and modal popups suppress the underlying candidate marker."
  source: "User request to fix missing first-result selection; verified by nested launcher regression and captured filtered-result frame."
  affects: [application-launcher-boundary]

- time: 2026-10-27T03:30:58
  kind: decision
  summary: Resolve app2unit from PATH and keep hardware output defaults empty
  source: "Default seed redesign, 2026-10-27"
  affects: [application-launcher-boundary]

- time: 2026-10-27T03:30:58
  kind: decision
  summary: Resolve app2unit from PATH and keep hardware output defaults empty
  source: "Implemented default seed and staging migration, 2026-10-27"
  affects: [application-launcher-boundary, shipped-default-seed]

- time: 2026-11-09T02:30:20
  kind: decision
  summary: "App search results animate via ScriptModel (identity diff) plus add/move/displaced/remove transitions (Theme.Motion.list*), as in refs/nixnew; rows are not pooled."
  affects: [application-launcher-boundary]
