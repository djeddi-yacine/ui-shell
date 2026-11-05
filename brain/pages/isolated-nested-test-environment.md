---
id: isolated-nested-test-environment
title: Nested tests own their home and XDG state
category: decision
status: active
tags: [tests, isolation, xdg]
created: "2026-10-02T05:15:39"
updated: "2026-11-05T02:07:48"
---

<!-- compiled_truth -->
# Decision

Every nested runtime test owns a private HOME, .config, .cache, .local/share, .local/state, runtime directory, session bus, writable harness and freshly installed ui-shell package. Production consumers resolve paths inside private $XDG_CONFIG_HOME/ui-shell rather than constructing /project addresses. The user's host home and generated selections must not change. Test-created children must disappear on normal exit, failure, interruption, or timeout.

Use Bubblewrap namespaces with read-only installed system files and project wallpaper assets, a single explicitly shared parent Wayland socket, and explicitly selected GPU render-node access or software rendering. Do not silently retry unsandboxed. This is development isolation with a shared display, not a VM or an untrusted-code security guarantee.

Tests use user-owned static configuration for all shared resources, graphics access, entrypoints, readiness deadlines, and artifact retention. Qt input-method selection is also explicit: the private environment defaults to local Compose keyboard input, validates that the configured plugin exists, and does not rely on host or compositor IME services. This verifies normal keyboard/clipboard behavior, not compositor text-input protocol or external IME integration. Production input-method selection is unchanged; unexpected runtime warnings remain fatal rather than being suppressed. The default test_state_mode is ephemeral. Explicit persistent mode retains a dedicated .test-state/<profile> home containing private preferences, the clean default/ seed, Theme definitions and profile recipes. Mount the private ui-shell configuration directory as a directory so config.ini can be atomically replaced by save commits; an individual config.ini bind mount blocks rename with EBUSY. Standalone profiles/ and themes/ remain alongside default/, manifest and component settings. The source tree has no themes/profiles stores; staging installs the clean default seed and seeds default stores only when absent, while tests generate non-default fixtures privately. Applied-wallpaper GUI checks use the project folder rather than the writable default seed. The explicit test_ephemeral_config_parts list overlays fresh scripts/, quickshell/ and hypr/ directories on every run; installed code and generated projections never persist as stale preferences. See [[shipped-default-seed]]. Startup resolves the preserved manifest and rebuilds generated palettes. Unreleased configuration changes have no migration/compatibility layer. Outdated private preferences fail explicitly and must be edited or reset deliberately; tests never automatically convert or copy old configuration namespaces. Runtime sockets, bus, processes, and copied source remain ephemeral. Never persist a stale whole project. Automated checks use ephemeral state independently of interactive preferences. A sibling lock excludes concurrent sessions and cleaning; marked profile data can be reset through make test-env-clean. Diagnostics survive separately in a printed unique /tmp directory.

A started process or a loaded QML configuration is not a passing runtime test. Always inspect the observed symptoms after a run: startup readiness, wallpaper and shell surfaces, relevant logs, a rendered frame when testing visuals, unchanged host state, and child-process cleanup. Bound waits and report failures rather than hiding them behind automatic substitutions.

Development and testing are separate ownership boundaries, not installed shell features. Only runtime helpers belong in scripts/ and the installed ui-shell/scripts directory. Development staging/build tooling belongs in tools/; sandbox/session/check helpers belong in tests/scripts/. Make targets expose that distinction with dev-* for host-display development and test-* for isolated work. The interactive entrypoints make test-env and the explicitly named make test-env-persistent use the same persistent private state. An explicit import step may add converted reference Themes to that state before starting or restarting the session; it must preserve active preferences and existing authored bundles. It launches only the nested session with popups closed: test_open_picker defaults explicitly to 0, and the wallpaper picker opens on demand through its normal controls. The session waits for native exit, without running an automated UI harness or enforcing a test deadline. make test-env-fresh is disposable; make test-env-snapshot and explicit check targets remain bounded diagnostics; make test remains automated checks. Old ambiguous target names have no compatibility aliases before release. Persistent state must not be reset as a side effect of structural cleanup.

The production shell still has no custom daemon, IPC protocol, or product CLI. Test-only native compositor diagnostics do not become its architecture.

Wallpaper application refreshes live output and global palettes after successful persistence. A persistent restart also regenerates startup projections from the saved profile, so both live color changes and retained bundle choices can be inspected. Per-output and global palette sources remain explicit and separate.

The nested entrypoint applies user.nested test-only modifier and shortcut overrides before loading production configuration, then composes the nested output and exit settings. Nested defaults use Alt as the main modifier, Alt+Q for foot, Ctrl as the additional silent-workspace-move modifier, Alt+Ctrl+Tab for window cycling, and Alt+B for workspace layout cycling. These explicit choices avoid duplicate Alt modifiers inside the nested config; they do not isolate input from the host. Production retains its Super-based defaults. Its Alt+Shift+Escape native Hyprland exit binding is universal across nested submaps; production does not receive this test shutdown shortcut. Normal native exit triggers launcher-owned cleanup of Quickshell, Hyprpaper and namespace children, while persistent preferences/cache remain retained. Tests still use start-hyprland. The host harness also owns the original nested window's lifetime: a graceful toplevel close may leave the compositor headless, while force-killing it may trigger a watchdog restart. Closing the original window must terminate the test run rather than adopt a new compositor. A separate native host close-window shortcut is not the nested graceful-exit configuration. Motion diagnostics and QML debugger sockets are confined to the private test namespaces; instrumented Qt frame timings do not measure end-to-end host presentation latency.

Wallpaper directories are listed in the runtime manifest, but sandbox exposure remains separate explicit test configuration. A manifest path never grants access to an arbitrary host folder. File-palette GUI previews use the same standard installed layout. See [[xdg-runtime-and-theme-schema]].

make test-env-clean resets private runtime cache, generated committed profiles, scoped settings and saved selection back to current source defaults, refreshes default/ from the clean seed and recreates missing default stores, but must retain every reusable Theme definition, including imported 100-themes palettes, authored palettes and local edits. Theme definitions are configuration, not disposable runtime artifacts. Reset does not re-import, revalidate or overwrite the retained palette files; close the persistent session before cleaning. Host configuration/data and project sources remain untouched.

Interactive nested sessions and the explicit make test-app-launch check use a test-only runner/config override; production AppRunner.qml and native app2unit service configuration remain unchanged. A filtered xdg-dbus-proxy exposes only the host user manager service, not the host bus or private-manager socket. Native app2unit parses desktop-entry IDs; its test-private systemd-run shim registers a unique scope in a run-owned slice. Manager connection alone unsets XDG_RUNTIME_DIR; native scope environment options restore the private runtime, session D-Bus and original PATH for the app. The scope acknowledges startup promptly while the real application continues on the nested display, in private HOME/XDG/PID/mount/network namespaces. Host activation variables and graphical-session targets are never changed. The proxy filters service names, not manager method arguments, so this is trusted development isolation, not a hostile-code security guarantee. Other automated checks and theme import expose no host manager API.

Every sandbox child inherits a unique UI_SHELL_TEST_PREFIX formed from the explicitly configured test_process_prefix and a fresh run ID. On original host-window close, interruption or final cleanup, a test-only close-session script enumerates the exact prefix-matched process set and signals only those processes, including watchdog, compositor, shell, private D-Bus, wallpaper service and launched apps. Fast iteration explicitly defaults test_shutdown_signal to KILL; users may choose TERM with bounded grace followed by KILL. Fast termination can discard unsaved application work, but must not reset committed persistent preferences or reusable Themes. Production startup and shell components remain unchanged. Cleanup also stops only recorded run-owned scopes and their slice, compares host manager environment digests and protected-file hashes, and rejects leftover tagged processes. Sandbox, proxy and logger waits are bounded. The make test-session-close regression sends a normal close request to the exact run-owned window with a real application still alive, then verifies bounded teardown and clean host state. Retain runnable probes and diagnostic logs, not disposable runtime data. make test-app2unit retains the independent host-registration-before-Bubblewrap proof. A direct host private-manager socket from a private PID namespace still fails with No data available; the filtered bus/native scope environment route is proven instead and needs no private UWSM or journald. See [[application-launcher-boundary]].

An Alt-based nested modifier does not guarantee host-free keyboard control. Check parent bindings and XKB options before calling shortcuts conflict-free. The current host reserves Alt+0 through Alt+3 for pass-to-OBS shortcuts and has grp:alt_shift_toggle, so those number keys and Alt+Shift chords are not reliable nested controls. Do not mutate host shortcuts to fix test input without approval. A test-only remap must stay explicit in user.nested, preserve production bindings, and be verified with the actual input path; native dispatcher smoke checks alone do not prove physical keys reach the nested compositor.

The user rejected the Alt-only test preset after these host conflicts were confirmed and approved Ctrl+Alt instead. Complete modifier families and action chords are explicit profile data; the nested preset overrides only named production fields and fails on unknown override keys. Input remains subject to any matching parent shortcuts: a native dispatcher smoke check alone must never be claimed as proof of physical keyboard delivery.


## Timeline

- time: 2026-10-02T05:15:39
  kind: decision
  summary: "Created this page: Nested tests own their home and XDG state"
  source: User requires private .config .cache .local and post-run symptom checks
  affects: [isolated-nested-test-environment]

- time: 2026-10-02T05:15:39
  kind: decision
  summary: Established clean-host isolated test state and outcome-based verification
  source: "User: tests own .config .cache .local; always inspect symptoms after a run"
  affects: [isolated-nested-test-environment]

- time: 2026-10-03T03:25:53
  kind: decision
  summary: Align wording with the explicit default-and-override configuration contract.
  source: "User: every configurable concern uses a user-set default, not a recovery state."
  affects: [isolated-nested-test-environment]

- time: 2026-10-04T03:11:47
  kind: decision
  summary: "Add explicit persistent private test home and registry with fresh code on every run, exclusive locking, and reset command."
  source: User wants saved test choices/cache between runs to inspect restarted shell colors and clean state after updates.
  affects: [isolated-nested-test-environment]

- time: 2026-10-04T03:11:47
  kind: reversal
  summary: "Diagnostic-only retention is no longer mandatory: persistent mode explicitly retains private test preferences/cache, while automated checks remain ephemeral."
  source: User requested optional persistence and explicit cleanup.
  affects: [isolated-nested-test-environment]

- time: 2026-10-04T04:28:00
  kind: decision
  summary: Nested configuration explicitly offers graceful native exit without touching the host.
  source: "User requests smooth closing, one animation owner, and explicit graceful nested shutdown."
  affects: [isolated-nested-test-environment]

- time: 2026-10-06T17:45:54
  kind: decision
  summary: Use freshly installed private XDG package and retain only explicit preferences and cache.
  source: User runtime scheme and explicit wallpaper folder list
  affects: [isolated-nested-test-environment]

- time: 2026-10-06T17:58:16
  kind: decision
  summary: "Remove private preference compatibility conversions; obsolete test state must be explicitly edited or reset."
  source: "User: remove defaultFolder; no backward compatibility before release"
  affects: [isolated-nested-test-environment]

- time: 2026-10-06T17:58:16
  kind: reversal
  summary: Unreleased configuration must not retain default-folder inheritance or compatibility migrations.
  source: User explicitly rejected pre-release backward compatibility
  affects: [isolated-nested-test-environment]

- time: 2026-10-07T10:51:05
  kind: decision
  summary: "Separate installed runtime helpers from development and isolated tests, with explicit dev/test entrypoints."
  source: User approved separation after confusion about mixed Make targets and shell scripts.
  affects: [isolated-nested-test-environment]

- time: 2026-10-07T20:24:09
  kind: decision
  summary: "test-env opens the interactive nested wallpaper picker without automated UI harness or deadline; bounded diagnostics remain test-env-snapshot and explicit check targets."
  source: "User: test-env should launch wallpaper picker, just the nested session, 2026-10-07"
  affects: [isolated-nested-test-environment]

- time: 2026-10-07T20:30:06
  kind: decision
  summary: "Interactive test-env has no automated harness/deadline; retained profiles and live palette refresh replace separate registry and restart-only state."
  source: "User requested nested picker only; profile bundle and live-color contracts, 2026-10-07"
  affects: [isolated-nested-test-environment]

- time: 2026-10-07T20:37:26
  kind: decision
  summary: Correct test-env to nested session only with wallpaper picker closed by default.
  source: "User correction: make test-env should not open wall picker, 2026-10-07"
  affects: [isolated-nested-test-environment]

- time: 2026-10-07T20:37:27
  kind: reversal
  summary: "The previous interpretation that test-env should auto-open the picker was wrong; the user requires the nested session only."
  source: "User correction, 2026-10-07"
  affects: [isolated-nested-test-environment]

- time: 2026-10-08T01:13:50
  kind: decision
  summary: "Choose private Qt Compose input explicitly and reject missing plugins, without host IME services or warning suppression; keep the compositor-IME verification boundary clear."
  source: "Warning-free live editor verification and clean private input contract, 2026-10-08"
  affects: [isolated-nested-test-environment]

- time: 2026-10-08T01:37:59
  kind: decision
  summary: Expose persistent testing explicitly and install reference Themes only through an explicit isolated import.
  source: "User requests 100-themes import and test-env-persistent, 2026-10-08"
  affects: [isolated-nested-test-environment]

- time: 2026-10-08T07:44:26
  kind: decision
  summary: "Persistent save requires a directory-mounted manifest/profile store with explicit fresh-code overlays; file mounts block atomic commit."
  source: "Confirmed persistent native save failure: config.ini file bind returned EBUSY; user requests saving verification without removing isolation."
  affects: [isolated-nested-test-environment]

- time: 2026-10-08T08:02:37
  kind: decision
  summary: "Clean resets runtime choices and cache but retains imported and authored Theme definitions and edits; reusable palettes are configuration."
  source: "User: the clean target must not delete the generated 100 themes."
  affects: [isolated-nested-test-environment]

- time: 2026-10-08T08:02:37
  kind: reversal
  summary: "Withdraw whole-private-home deletion semantics for test-env-clean: imported and authored Theme definitions must survive reset unchanged."
  source: User explicitly requires retaining the generated 100-themes collection.
  affects: [isolated-nested-test-environment]

- time: 2026-10-09T02:38:17
  kind: evidence
  summary: "UWSM is an installed candidate for native nested-session startup, environment finalization and shutdown. It needs an existing systemd user manager reachable on its session bus; it does not provide isolation or create that manager. Any test integration must keep UWSM, manager, application units and bus inside the private sandbox, with no host activation-environment imports or host session shutdown. This route is evaluated, not yet integrated or proven."
  source: "User proposal 2026-10-09; installed UWSM sources and upstream README https://github.com/Vladimir-csp/uwsm; scoped Luna dependency review"
  affects: [isolated-nested-test-environment]

- time: 2026-10-09T02:50:11
  kind: evidence
  summary: "Bounded bubblewrap probe verified a distinct PID namespace, private /home/test and /run/test, no host user/system bus sockets, and a functioning private systemd user manager with manager-owned classic D-Bus. A real transient service executed successfully with private HOME/XDG. Actual uwsm start -g -1 -D Hyprland -e reached its startup wrapper but failed with Failed to create stream fd: No such file or directory because systemd-cat requires a journal socket absent from this sandbox. UWSM is not integrated; full startup still needs a private journal. Installed dbus-broker also requires a journal, whereas classic dbus-daemon works without one. No host D-Bus or activation environment was borrowed. Application-launcher app2unit handoff and actual compositor startup remain unproven in this route."
  source: 2026-10-09 actual isolated UWSM attempt and native systemd service probe
  affects: [isolated-nested-test-environment]

- time: 2026-10-09T03:03:48
  kind: reversal
  summary: "User approved a narrow host-manager exception for a retained app2unit scope smoke test: share only the systemd private socket, retain private HOME/XDG/session D-Bus/PID/network, create only run-owned transient units, and never import test environment into or start/stop the host graphical session. Verify before changing ordinary nested targets; retain reproducible test code rather than deleting it as runtime cleanup."
  source: "User 2026-10-09: reuse host session for app2unit; ok, just be fast"
  affects: [isolated-nested-test-environment]

- time: 2026-10-09T03:11:13
  kind: decision
  summary: "Record passed host-registration/sandboxed-app scope proof, retained test and narrow exception; ordinary launcher/session targets unchanged"
  source: "2026-10-09 make test-app2unit native run; /tmp/ui-shell-app2unit.Bt0ZvR/probe.log"
  affects: [isolated-nested-test-environment]

- time: 2026-10-09T03:36:06
  kind: evidence
  summary: "Native systemd 262 proxy probe passed with private PID/mount/network namespaces. Unsetting XDG_RUNTIME_DIR only for manager connection permits filtered user-bus transport; scope --setenv restores private runtime and D-Bus for the child. Direct host-private-socket mount remains invalid. Integrate only through test runner/config; production remains unchanged."
  source: "2026-10-09 bounded probe /tmp/ui-shell-proxy.kWsr8z; systemd v262 src/shared/bus-util.c"
  affects: [isolated-nested-test-environment]

- time: 2026-10-09T03:43:41
  kind: decision
  summary: "Record test-only native manager proxy and passed real GUI launch; production runner unchanged"
  source: "2026-10-09 make test-app-launch /tmp/my-shell-test.kLCLCf; user environment-only boundary"
  affects: [isolated-nested-test-environment]

- time: 2026-10-09T03:58:02
  kind: evidence
  summary: "Host window-close with a real sandboxed app reproduced shutdown timeout: start-hyprland logged Hyprland exit not-cleanly, restarting and launched another compositor. The wrapper restart policy, not remaining host app units, kept the test alive. Nested tests need one-shot compositor lifetime and bounded teardown waits."
  source: 2026-10-09 make test-session-close /tmp/my-shell-test.Xem6E3/launcher.log and close-processes.log
  affects: [isolated-nested-test-environment]

- time: 2026-10-09T04:18:52
  kind: reversal
  summary: "Keep start-hyprland, as the user requests. Fast test iteration may KILL only the exact run-prefixed sandbox process set. Host-window lifetime triggers prefix cleanup, including watchdog and apps; do not replace production startup or adopt a restarted compositor as a new test session. Graceful host close can otherwise leave a headless compositor alive; watchdog force-close can restart it."
  source: "User 2026-10-09: loop prefix-matched processes, kill for fast iteration, keep start-hyprland; /tmp/my-shell-test.bMHv06 and Xem6E3 evidence"
  affects: [isolated-nested-test-environment]

- time: 2026-10-09T04:20:28
  kind: decision
  summary: "Keep start-hyprland with prefix-owned fast teardown on original window close; record passed live close regression"
  source: "User fast-iteration and prefix requirements; make test-session-close /tmp/my-shell-test.E5COvD"
  affects: [isolated-nested-test-environment]

- time: 2026-10-10T16:06:12
  kind: decision
  summary: "Nested sessions use an explicit user-configured Alt main modifier, with Alt+Q for foot; production keeps Super. This separates test shortcuts from host shortcuts without changing host configuration."
  source: "User nested keyboard request, 2026-10-10"
  affects: [isolated-nested-test-environment]

- time: 2026-10-10T16:15:01
  kind: decision
  summary: "Replace nested Super shortcuts with explicit Alt defaults and collision-free secondary bindings; production unchanged."
  source: "User nested Alt request, 2026-10-10"
  affects: [isolated-nested-test-environment]

- time: 2026-10-10T16:44:50
  kind: decision
  summary: "Correct keyboard-isolation claim: host-reserved Alt digits and Alt+Shift are not reliable nested input"
  source: "User correction and read-only host binds/XKB options, 2026-10-10"
  affects: [isolated-nested-test-environment]

- time: 2026-10-10T16:44:50
  kind: reversal
  summary: "Alt main modifier does not isolate test keyboard input: host pass-to-OBS binds claim Alt+0 through Alt+3, and host XKB reserves Alt+Shift for language switching. Keep host unchanged; agree on explicit test-only remapping before changing controls."
  source: "User keybinding report; hyprctl -j binds and input:kb_options read-only inspection, 2026-10-10"
  affects: [isolated-nested-test-environment]

- time: 2026-10-10T16:48:42
  kind: decision
  summary: "Mark Alt-only nested preset rejected; replacement is pending, not silently applied"
  source: "User: ALT is not the right option, 2026-10-10"
  affects: [isolated-nested-test-environment]

- time: 2026-10-10T16:48:43
  kind: reversal
  summary: "User rejects Alt-only nested input after host conflicts; keep host unchanged and choose explicit replacement controls."
  source: "User: good mate, so ALT is not the right option i think, 2026-10-10"
  affects: [isolated-nested-test-environment]

- time: 2026-10-10T16:59:19
  kind: decision
  summary: "Approve explicit Ctrl+Alt nested keymap with separate Ctrl+Shift actions; keep host and production unchanged"
  source: "User approved Ctrl+Alt nested modifier, 2026-10-10"
  affects: [isolated-nested-test-environment]

- time: 2026-10-11T00:44:36
  kind: decision
  summary: "Replace obsolete pending recommendation with the approved explicit Ctrl+Alt contract"
  source: "User approval and implemented scoped keymap, 2026-10-10"
  affects: [isolated-nested-test-environment]

- time: 2026-10-12T02:54:25
  kind: decision
  summary: "Make test-env-phantomat reuse the persistent private home/cache and nested-session lifecycle of test-env, with Phantomat loaded dormant; do not apply an extra Quickshell bar-visibility mutation."
  source: "User request: test-env-phantomat should be test-env plus the plugin enabled; implementation, 2026-10-12"
  affects: [isolated-nested-test-environment]

- time: 2026-10-27T03:30:58
  kind: decision
  summary: Stage the clean default seed and generate non-default test fixtures privately
  source: "Default seed redesign, 2026-10-27"
  affects: [isolated-nested-test-environment]

- time: 2026-10-27T03:30:58
  kind: decision
  summary: Stage the clean default seed and generate non-default test fixtures privately
  source: "Implemented default seed and staging migration, 2026-10-27"
  affects: [isolated-nested-test-environment, shipped-default-seed]

- time: 2026-10-30T14:57:39
  kind: decision
  summary: "Keep test-env launcher-only; split automated checks into independent disposable targets for sandbox, Hyprland parsing, QML, theme/config, and generated pipelines. QML palettes are generated inside each QML run."
  source: "User requirement, implementation, and isolated target verification, 2026-10-30"
  affects: [isolated-nested-test-environment, shell-scope-and-layout]

- time: 2026-11-01T01:30:34
  kind: decision
  summary: "Layout-sensitive GUI checks use a private 720p headless output; the host-tiled nested window size is not a stable viewport. See gui-test-viewport."
  source: "Theme editor test host-window size investigation, 2026-11-01"
  affects: [gui-test-viewport]

- time: 2026-11-05T02:07:48
  kind: decision
  summary: "Host side of the nested tests: the host Hyprland (0.56.2, ~/dotfiles/hypr/conf/windowrule.conf) has a rule 'nested-hyprland-test' matching class ^(aquamarine)$ that opens the nested window floating on workspace 2 with 'silent' (no workspace switch). The harness still floats, sizes and centres the window by PID through hyprctl. This lives in the user's dotfiles, not in this repository."
  source: "user request, 2026-11-05"
  affects: [isolated-nested-test-environment]
