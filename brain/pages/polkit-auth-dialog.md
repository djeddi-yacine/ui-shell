---
id: polkit-auth-dialog
title: "Authentication dialog replaces hyprpolkitagent, one on-demand themed window"
category: decision
status: active
tags: [polkit, security, dialog]
created: "2026-11-06T12:31:14"
updated: "2026-11-06T13:48:00"
---

<!-- compiled_truth -->
<current best understanding — replace this with the real content>

## Timeline

- time: 2026-11-06T12:31:14
  kind: decision
  summary: "Created this page: Authentication dialog replaces hyprpolkitagent, one on-demand themed window"
  source: created via brain create-page
  affects: [polkit-auth-dialog]

- time: 2026-11-06T12:31:14
  kind: decision
  summary: "Brainstorm done with six lenses: no retry is enforced by the adapter (polkit re-prompts), Backspace clears all, static focus mark, checking state, 300 ms input guard, FIFO queue never replacing the visible prompt, on-demand window with synchronous load, explicit D-Bus path, manual agent swap with documented start-up order, no_screen_share to be verified live before any claim."
  source: egm-brainstorm 2026-11-06
  affects: [polkit-auth-dialog]

- time: 2026-11-06T12:41:04
  kind: decision
  summary: "Design drafted in features/designs/polkit.md. Owner decisions: wrong password stays until a key is pressed; visible field only for visible-input prompts; no timeout; no recording rule if no_screen_share fails; manual swap from hyprpolkitagent; namespace kept in two places with a check test. Adapter defers cancel after failure (to confirm in phase 0)."
  source: features/designs/polkit.md
  affects: [polkit-auth-dialog]

- time: 2026-11-06T12:46:21
  kind: decision
  summary: "Owner allows a systemd unit for the shell (not a rule violation) and wants a systemd target for things that need quickshell running. Decided: keep the manual hyprpolkitagent swap for polkit now; the shell unit + target becomes its own later feature. The agent lives inside the Quickshell process, so a separate agent unit would be a second Quickshell."
  source: chat
  affects: [polkit-auth-dialog]

- time: 2026-11-06T12:56:25
  kind: decision
  summary: "Review (stage 9) fixes applied; adapter test seam = injectable source (PolkitSource + PolkitAuth with fakes). Owner approved all fixes and asked to start implementing."
  source: features/designs/polkit.md
  affects: [polkit-auth-dialog]

- time: 2026-11-06T13:01:53
  kind: decision
  summary: "Implemented phases 1-3 in code: SecretDialog, PolkitAuth (injectable source), PolkitSource, auth module, AuthChip, rules.lua (auth-not-shared, no_anim), tests (make test-qml passes incl. 14 dialog + 13 adapter tests; make test-auth, make test-hypr-config pass). Not yet verified: the dialog look (nested preview) and the live pkexec / gsr checks, which need the owner on the host."
  source: shell/modules/auth/EGM.md
  affects: [polkit-auth-dialog]

- time: 2026-11-06T13:20:00
  kind: decision
  summary: "Finding: Hyprland no_screen_share on the full-screen auth layer blacks out the WHOLE captured frame in screencopy (nested harness frame was 1 colour). So the rule works for compositor capture; gsr (KMS) still untested. A full-screen layer means a recording shows a black screen while the dialog is up; alternative is a small card-only keyboard layer plus a separate dimming layer that is not hidden. Open decision for the owner. Also: UI redesigned (display-size title, account chip, lock mark and status inside the field, explicit size fix)."
  source: chat
  affects: [polkit-auth-dialog]

- time: 2026-11-06T13:48:00
  kind: decision
  summary: "Owner chose: dimmed screen with a black hole where the card is. Implemented as two layers (ui-shell-auth-scrim captured, ui-shell-auth card hidden with no_screen_share, exclusive keyboard). Nested snapshot confirms the hole; gsr still untested."
  source: shell/modules/auth/EGM.md
  affects: [polkit-auth-dialog]
