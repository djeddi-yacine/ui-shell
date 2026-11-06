---
id: contextual-shell-popups
title: Minimal panels disclose information help and scoped settings on demand
category: decision
status: active
tags: [shell, ux, keyboard, configuration]
created: "2026-10-05T02:03:50"
updated: "2026-11-06T02:41:15"
---

<!-- compiled_truth -->
# Decision

Primary shell panels are minimal, task-focused surfaces. Remove redundant component titles such as Applications/Wallpapers, always-visible usage hints, application descriptions, and large Close buttons from the app runner and wallpaper picker. Keep essential item identity, explicit wallpaper target scope, distinguishable interaction states, and actionable failures presented in their own component-scoped popup rather than inline. Search, content, target/action controls, and popup content share exact border-box alignment with one invariant perimeter; no extra focus outline or reserved focus offset. Sharp corners, shared per-output colors, and short QML-owned motion remain mandatory.

## On-demand contextual controls

- Ctrl+I opens information about the selected candidate or meaningful focused target/control, resolved by the owning component. App descriptions belong here, not in each main list row.
- Ctrl+Space opens usage and actual configured keybindings for the active shell component, not a permanent footer guide or a global help application.
- Ctrl+E opens settings for that component and the explicitly displayed configuration scope, never a full desktop settings application.

Popup focus and keyboard actions stay within the popup. Escape and outside-click dismiss the topmost popup first, then the parent when no popup is open. Dismissal restores prior focus and does not change the candidate, run an application, apply a wallpaper, or write settings. Settings write only through an intentional commit. Accessible names remain even when redundant visual labels are removed.

## Focus ownership

Tab and Shift+Tab transfer focus between controls without retaining the departed control's focus emphasis or changing the selected candidate. The wallpaper grid and application list each own one focus stop; delegates render the owning view's active candidate and never independently steal/retain focus or choose themselves when a scope regains focus. Candidate identity persists independently from the active focus highlight. Search, the wallpaper target and the action remain keyboard-accessible through explicit cyclic QML navigation; list/grid arrows move candidates and return focus to their view. Opening a popup suppresses the underlying candidate's focus emphasis and dismissal restores the interrupted owner without reselection. Launcher Tab/Backtab must never enter the query as text.

Scrollable candidate collections—the application list, wallpaper grid and dropdown option lists—are keyboard-owned. Pointer movement does not add hover styling or clear the active keyboard candidate there. The wheel remains available for scrolling and direct pointer clicks still choose or activate items. Buttons and other hover-enabled controls retain normal pointer hover and click feedback. This is scoped arbitration, not a blanket pointer ban or separate focus system.

Error-popup Tab/Shift+Tab cycle only Copy and Dismiss. Read-only diagnostics are mouse-selectable with native copying and may take deliberate pointer focus, but are not a Tab stop or an initial-focus choice. Tab from pointer-focused diagnostics returns to an action and clears diagnostics focus. This supersedes the initial diagnostics-in-Tab-cycle behavior.

Native keyboard/pointer regressions verify this focus contract in both private Quickshell surfaces, including repeated forward/reverse cycles, retained candidates, no Tab query text, clearing pointer-only hover on hover-enabled controls, keyboard-owned selector stability under pointer movement, and popup restoration. Qt can implicitly assign currentItem focus to a delegate; this must not create an independent focus owner. Diagnostic handoff must not introduce reciprocal native navigation links back into the action cycle.

Focused shared action buttons must explicitly accept the configured Return and keypad Enter keys, independent of the platform Qt button defaults. Pressing arms the visible pressed state; the matching non-repeated release commits exactly once through the native button action. Focus loss, hiding or disabling cancels an armed action. Activation is consumed by the button, never forwarded to the underlying panel. Space remains native, and Tab, Escape and contextual shortcuts keep their existing ownership.

## Scoped persistence

Settings remain QML configuration with explicit user defaults and optional generated overrides. Small focused Bash persistence/generation scripts own file effects; QML owns presentation. Separate component and optional per-monitor files isolate edits; output identity comes from user policy/runtime discovery, not hardcoded hardware. Scope-local locking, a content-revision compare-and-swap check, and atomic replacement protect the same file. Invalid or stale edits report an error, preserving the last valid configuration. User choices live in XDG configuration storage, not the derived cache. No new daemon, IPC control plane, external JavaScript, JSON shell configuration, or generic settings framework is authorized.

## Implementation boundary

The initial scoped keys are launcher showIcons/visibleRows and wallpaper-picker wideColumns/maximumVisibleRows. Existing component QML files remain the required static defaults. Generated QtObject overrides live below the manifest's configured paths.components, normally XDG_CONFIG_HOME/ui-shell/components/{launcher,wallpaper}: Default.qml for shared choices and outputs/{sha256 of exact output name}.qml for per-monitor choices. Undefined properties mean no override, not a recovery mode. Effective order is static QML default, shared generated choice, exact owning-monitor generated choice. The settings scope names the monitor hosting the UI, independent from the wallpaper destination selector. Draft edits do not affect the live UI or filesystem until Save. Successful commits reload the native QML overrides live; reopening also refreshes external changes. No host-test shared state is introduced.

Launch progress belongs only to the app being handed off, not a footer or new status row. Reserve a fixed trailing indicator slot in every launcher row so panel, search, list and label geometry do not change between idle, pending, success and failure. A small filled circular progress glyph is allowed without rounding control corners. Its pulse animates opacity only, stops when hidden or no longer pending, and becomes a steady dot under reduced motion. The indicator follows the launched desktop-entry identity rather than a movable candidate; accessible busy/status information remains available without extra visible text. Errors still open the existing scoped popup.

## Error presentation contract

Runtime failures must not insert error content into the main panel or scoped editor. A reusable component-scoped error popup shows an action-specific title, a clear message and bounded selectable plain-text diagnostics with exact operation/target/scope. A deliberate keyboard-accessible Copy button copies the complete presented diagnostic using native Qt text-control clipboard copying, with no automatic clipboard replacement, command, daemon or custom IPC.

The popup is the topmost input scope. Escape/outside-click/dismissal restore the interrupted control/editor without closing the parent, applying/saving, changing the candidate/current value or discarding a settings draft. Re-observing the same failure must not reopen or stack it; a new failure is presented once. Backends/modules own error state and intentional retry; components own presentation. Shared sharp geometry, output-aligned readable colors, restrained negative emphasis and static QML sizing/motion/key policy apply. Fatal bootstrap failures with no usable surface remain explicit startup/log errors, not a recovery mode.

The shared error popup is implemented for app2unit, wallpaper generation/render/apply/save, unavailable wallpaper choices, and scoped settings loading/saving/conflicts. Settings errors overlay the existing editor rather than replacing its draft. Presentation follows new failure events, not error-property bindings; each producer supplies an explicit monotonically increasing failure sequence so dismissal survives repeated observations. A confirmed wallpaper apply followed by failed persistence reports that the live wallpaper changed while the saved choice did not. Full Copy includes the title, message and all diagnostic details, even outside the visible scroll area. Explicit static defaults focus Dismiss, use Escape to dismiss and Ctrl+Shift+C for full Copy; normal Qt selection/copy remains native. The popup reuses the shared shape, motion and output style.

## Status

The minimal launcher/picker views, contextual popups, bounded scoped settings and separate error presentation are implemented. Isolated checks cover real app2unit rejection, settings read failure and stale-save conflicts, every wallpaper pipeline stage including failed process start, unchanged primary geometry, preserved drafts/candidates, interrupted-focus restoration and no duplicate reopening. Complete native Copy and no automatic clipboard replacement were verified only inside the private nested display, including a long plain-text diagnostic. No host clipboard or application service was used. The isolated make test, launcher-smoke and nested-smoke runs passed, including state-color/geometry regressions, popup input isolation, settings persistence/conflicts and real wallpaper application. Test teardown reported unchanged protected host files and no remaining test children. Popup captures now wait for the native opened state and a render cycle for draft changes; live frames verify visible information/settings content and the borderless dropdown inside its single frame. Asynchronous picker previews may still be loading in an early information frame; this does not imply missing popup content. Runtime command roles and component storage paths follow [[xdg-runtime-and-theme-schema]] without changing the contextual UI contract. The focus-only verification passed 97 QML JUnit cases and both live smoke checks; retained frames were inspected and private-test teardown again proved unchanged protected host files and no remaining children. The current pointer/keyboard contract has focused offscreen selector tests and a live launcher handoff regression; the live wallpaper gate confirms direct tile activation and the apply flow. See the project test documentation for current artifact/report paths. Unrelated features remain out of scope.

## Popup primary actions

Ctrl+Return and Ctrl+keypad Enter activate the explicit primary button of the topmost focused popup, regardless of which field currently has focus. The shared key policy remains native QML configuration. Theme editing uses Save and apply, scoped settings use Save, color selection uses Use color, and error presentation uses Dismiss; Ctrl+Shift+C remains the explicit full-diagnostic Copy shortcut. Information/help popups have no primary commit action. Disabled or busy actions do not run, and nested color/error/dropdown focus must never activate an underlying Save. Primary actions must remain visible at the normal desktop/test viewport without scrolling to reach them.


## Timeline

- time: 2026-10-05T02:03:50
  kind: decision
  summary: "Created this page: Minimal panels disclose information help and scoped settings on demand"
  source: "User requested removal of redundant labels and Ctrl+I Ctrl+Space Ctrl+E popups"
  affects: [contextual-shell-popups]

- time: 2026-10-05T02:05:49
  kind: decision
  summary: Record minimal primary UI and contextual popups with component and monitor scoped persistence
  source: "User design contract; documentation-only request"
  affects: [contextual-shell-popups]

- time: 2026-10-05T02:27:27
  kind: decision
  summary: Bound initial component options and explicit scoped QML persistence with live commits
  source: Approved popup contract and native Quickshell source inspection
  affects: [contextual-shell-popups]

- time: 2026-10-05T03:13:33
  kind: decision
  summary: "Record implemented contextual controls, verified behavior, stable-capture caveat and user-requested stopping point."
  source: "User: note everything and stop here for now; completed isolated tests and inspected retained frames."
  affects: [contextual-shell-popups]

- time: 2026-10-05T07:44:13
  kind: decision
  summary: "The user resumed scoped dropdown/color work; preserve minimal panel and popup behavior."
  source: "User color/contrast and dropdown foreground corrections, 2026-10-05"
  affects: [contextual-shell-popups]

- time: 2026-10-05T08:19:34
  kind: decision
  summary: "Verify settled contextual/settings content and the foreground-led dropdown while preserving component scope, native behavior and focus isolation."
  source: "Isolated launcher and wallpaper smoke tests; inspected retained frames, 2026-10-05."
  affects: [contextual-shell-popups]

- time: 2026-10-05T08:25:01
  kind: decision
  summary: "Approve component-scoped error popups with clear details and explicit Copy; preserve task/drafts and mark inline errors pending migration."
  source: "User: note the new error model; no inline errors in the current scope."
  affects: [contextual-shell-popups]

- time: 2026-10-05T08:25:01
  kind: reversal
  summary: "Supersede inline operation/validation/conflict error presentation: errors belong in a scoped popup with a deliberate full-diagnostic Copy action."
  source: "User error-presentation model change, 2026-10-05."
  affects: [contextual-shell-popups]

- time: 2026-10-06T17:45:54
  kind: decision
  summary: Scoped persistence uses configured ui-shell storage and command roles without expanding the settings model.
  source: User runtime scheme and explicit wallpaper folder list
  affects: [contextual-shell-popups]

- time: 2026-10-07T09:47:26
  kind: decision
  summary: "Complete the approved error-popup model with scoped event-driven failures, retained drafts and private native clipboard verification."
  source: "User go; isolated make test, launcher-smoke and nested-smoke; inspected retained error frames."
  affects: [contextual-shell-popups]

- time: 2026-10-07T10:13:10
  kind: decision
  summary: "Make focus ownership exclusive across launcher picker and error actions; preserve candidates independently of Tab focus"
  source: "User focus fixes and launcher Tab clarification, 2026-10-07"
  affects: [contextual-shell-popups]

- time: 2026-10-07T10:13:11
  kind: reversal
  summary: "Read-only error diagnostics leave the Tab cycle; only Copy and Dismiss are action focus stops, while native mouse selection remains available."
  source: "User requested focus cleanup for error popup, wallpaper picker and app launcher, 2026-10-07"
  affects: [contextual-shell-popups]

- time: 2026-10-07T10:40:59
  kind: decision
  summary: "Verify exclusive focus ownership and action-only error navigation; record Qt implicit-focus/backlink hazards"
  source: "User focus contract; native private launcher/picker tests and QML regressions, 2026-10-07"
  affects: [contextual-shell-popups]

- time: 2026-10-07T11:25:44
  kind: decision
  summary: "Make focused button activation explicit and release-owned; prevent repeated commits and parent key leakage"
  source: "User requested focused Save/Copy Enter fix, 2026-10-07"
  affects: [contextual-shell-popups]

- time: 2026-10-07T11:54:53
  kind: decision
  summary: "Keep launcher launch feedback row-local and geometry-invariant, with motion preference respected"
  source: "User requested removal of Starting footer and row-local animated circle, 2026-10-07"
  affects: [contextual-shell-popups]

- time: 2026-10-08T00:35:45
  kind: decision
  summary: "Require visible popup primary actions and scoped configurable Ctrl+Enter activation without parent leakage."
  source: "User requests taller editor and Ctrl+Enter for every popup primary button, 2026-10-08"
  affects: [contextual-shell-popups]

- time: 2026-10-12T02:21:19
  kind: decision
  summary: Make scrollable popup selectors keyboard-owned while retaining pointer activation and scrolling
  source: "User input-modality request; offscreen selector tests and isolated launcher/wallpaper runs, 2026-10-12"
  affects: [contextual-shell-popups]

- time: 2026-11-06T02:35:50
  kind: decision
  summary: "Exit rule: Esc always leaves. View-only panels close on one Esc; panels with unsaved work (tuning, theme editor) show ExitDialog, where Esc means dismiss-and-quit, so leaving takes a double Esc and a stray key loses nothing. Keep editing is the default button. Documented in STYLE.md."
  source: user request 2026-11-06
  affects: [contextual-shell-popups]

- time: 2026-11-06T02:41:15
  kind: decision
  summary: "ExitDialog also guards the Ctrl+E component settings popup (draft vs file) and the theme editor's colour picker (changed channels not yet used). View-only panels stay one-Esc."
  source: user request 2026-11-06
  affects: [contextual-shell-popups]
