---
id: phantomat-patch-provenance
title: "Phantomat patches live on a fork branch, never in refs/"
category: decision
status: active
tags: [phantomat, git, fork, workflow]
created: "2026-10-27T02:14:31"
updated: "2026-11-05T01:46:53"
---

<!-- compiled_truth -->
# Decision

## Phantomat patches live on a fork branch, never in `refs/`

`refs/` is untracked in this repository: it holds disposable reference checkouts used for study and local builds. The patched Phantomat plugin is the exception to disposal, so its durable home is the personal fork.

- Fork: `djeddi-yacine/phantomat`.
- Published branch: `main` on the fork (`djeddi-yacine/phantomat`), the only branch there. Since 2026-11-05 it is the Hyprland 0.57.x line, fast-forwarded to `de7c458`. The separate fork branches `feature/workspace-bound-canvas` and `compat/hyprland-0.57-render-context-v2` were deleted once both tips were proven inside `fork/main`; the local branches of those names stay as a safety net.
- Base: upstream `kaolti/phantomat` commit `a1e8a08` (`origin/main` stays there; nothing is ever pushed to `origin`). Local `main` is ahead of it and `remote.pushDefault` / `branch.main.pushRemote` are `fork`, so a plain `git push` cannot reach upstream.
- Canvas patch commit: `4099f30` — `feat(canvas): scope canvas rendering and navigation to workspaces`. 21 files, +1963/−448. Tag `pre-0.57-4099f30` on the fork is the last tip for the pre-0.57 (0.56) interface, the fallback for a 0.56 host.
- The 0.57 port is 21 commits on top of `4099f30`: explicit `CRenderContext`, one `SCROLL_OVERVIEW_HOOKS` table, no `#define private public` (private Hyprland state goes through `SPrivateMember` accessors), the lost canvas features re-applied, wobble support, and a clang-format commit. A plugin built for 0.57 refuses to load on a different Hyprland hash, so the 0.56.2 host cannot use it.
- Local-only branches, never pushed: `wip/single-border-attempt` (a superseded experiment) and `experiment/workspace-canvas-nested` (`658bac4`) adds the nested regression test, its Makefile target and shared-fixture slide animations on top of `4099f30`.
- The regression stays experimental because it requires a parent Hyprland session with `grim -T`, `mpv`, ImageMagick and Pillow for `--hud-transition-only`.
- `refs/phantomat` keeps `origin` pointed at `kaolti/phantomat` because `make refs-pull` runs plain `git pull` and `main` tracks `origin/main`. The fork is added as the `fork` remote instead of renaming `origin`.
- Local `main` keeps tracking `origin/main` for pulls (`make refs-pull` merges upstream changes into it) and pushes to `fork`.
- `make dev-build-phantomat` still builds from `refs/phantomat`. A fresh clone of the fork builds the patched plugin from `main`; a clone of upstream does not.

## Boundaries

- No pull request is sent to `kaolti/phantomat`; patches are pushed to the personal fork only.
- Future changes to the plugin are committed on the fork branch, not left as an uncommitted worktree.
- Do not merge the experiment branch into the published branch, and never use `git push --all` or `--mirror`.
- `refs/` stays entirely ignored by this repository. Do not re-include individual reference checkouts or exported patch files.

## Why

The patch set existed only as an uncommitted worktree inside an ignored directory. `git clean`, a re-clone, or disk loss would erase it. A fork push is reviewable, reversible, and survives loss of the local reference checkout without adding `refs/` or patch exports to this repository.

## Loss event: the Hyprland 0.57 port was destroyed (2026-11-04)

The exact failure this page warns about happened. A second agent ("freebuff") ran `git reset --hard` to `ORIG_HEAD` / `origin/HEAD` at 15:30:39, 15:42:37 and 15:43:49 in `refs/phantomat`. The worktree is now clean at upstream `a1e8a08`; the 0.57 port (26 modified files, 4802+/4402−) is gone.

- What was lost: the whole 0.57 render-context port plus the follow-up canvas fixes (per-monitor `overview_client_scale`, exact drops, raise-on-drop, press-time selection, in-scene selection outline, hover suppression while dragging, `navigator:drag_behavior`) that had been built and manually verified hours earlier.
- Why git cannot recover it: the work was never committed, so it was never a git object. `git fsck --lost-found` only shows the old `9d42c22`; the reflog only carries commit resets; `git stash` was never used.
- Recovery investigated and stopped: opencode snapshot repos (none track `refs/phantomat`), opencode message store, freebuff session logs, `.build/obj` and `.so` (debug info, no source text). The user called off further recovery.
- What survives: `.build/phantomat/spatialoverview.so` and `.build/obj/*.o` built from the ported tree (05:10–05:35), the design decisions recorded in [[phantomat-canvas-geometry]] and [[phantomat-toggle-and-focus]], and the pre-0.57 branch `4099f30` on the fork.

## Rules adopted after the loss

- Commit and push on the fork branch as soon as a port or feature builds and passes a manual check. Never let verified work sit uncommitted for hours in an ignored worktree.
- Before any `git reset`, `git checkout`, `git clean` or branch switch in `refs/phantomat`, commit to a throwaway branch (or `git stash`) so the work is a git object.
- A second agent sharing this checkout must be told not to reset `refs/phantomat`; the port is authored work, not disposable reference material.


## Timeline

- time: 2026-10-27T02:14:31
  kind: decision
  summary: "Created this page: Phantomat patches live on a fork branch, never in refs/"
  source: "Phantomat commit and fork push, 2026-10-27"
  affects: [phantomat-patch-provenance]

- time: 2026-10-27T02:14:38
  kind: decision
  summary: "Record the fork branch, base commit, and remote layout that make the patched plugin durable outside ignored refs/."
  source: "Phantomat commit 9d42c22 pushed to djeddi-yacine/phantomat, 2026-10-27"
  affects: [phantomat-patch-provenance]

- time: 2026-10-27T02:29:14
  kind: decision
  summary: "Replace the published commit with a 21-file version that excludes the nested regression; keep that regression on local branch experiment/workspace-canvas-nested and force-push the clean commit."
  source: "Amended commit 4099f30 force-pushed to djeddi-yacine/phantomat, 2026-10-27"
  affects: [phantomat-patch-provenance]

- time: 2026-10-30T15:08:44
  kind: evidence
  summary: "Clean rebuild and nested launch against Hyprland 0.57.0 expose an API mismatch: the cached plugin fails to load with undefined IPassElement::discard(), while a full source rebuild fails on removed Workspace.hpp and IHyprRenderer::m_renderData APIs. The external stale plugin artifact was removed; the fork branch remains unchanged."
  source: "make test-env-phantomat, clean plugin rebuild, Hyprland 0.57.0 headers, and startup logs, 2026-10-30"
  affects: [phantomat-patch-provenance, phantomat-overview-boundary]

- time: 2026-10-30T15:18:20
  kind: evidence
  summary: "Fetched danihenrique/main at d447421 for comparison: it adds optional native-workspace canvas isolation and a broad feature/test set, but still targets the old Hyprland ABI (Workspace.hpp, no-context IPassElement methods, and IHyprRenderer::m_renderData), so it does not fix the clean build failure on installed Hyprland 0.57.0. Only a remote-tracking ref was added; the active workspace-bound branch remains unchanged."
  source: "Local inspection of refs/phantomat danihenrique/main, its README/tests and installed Hyprland 0.57 headers, 2026-10-30"
  affects: [phantomat-patch-provenance, phantomat-overview-boundary]

- time: 2026-10-30T15:49:46
  kind: evidence
  summary: "Started local API compatibility branch compat/hyprland-0.57-render-context on top of workspace-bound canvas; refreshed Hyprland source headers and confirmed installed 0.57.0. Ported renderer passes to explicit CRenderContext, replaced several workspace/window/keybind/event APIs, and mapped layer fullscreen flags to LayerFlags. Current rebuild is narrowed to compile errors in modifier-mask typing, wallpaper blur texture handling, decoration callback signatures, and a few workspace/logging calls; no tests or nested run yet."
  source: "Local Phantomat and Hyprland source inspection plus make build, 2026-10-30"
  affects: [phantomat-patch-provenance, phantomat-overview-boundary]

- time: 2026-11-04T03:32:13
  kind: evidence
  summary: "The Hyprland 0.57 port exists only as uncommitted work: refs/phantomat is on local compat/hyprland-0.57-render-context at 4099f30 with 26 modified files (4802+/4402-), latest edit 2026-11-04 02:36; the plugin that ran the 6-client nested canvas verification was built from that dirty tree (.build/phantomat/spatialoverview.so, 02:37). Nothing on this branch is committed or pushed. The published fork branch feature/workspace-bound-canvas is still 4099f30 (pre-0.57 ABI); experiment/workspace-canvas-nested stays at 658bac4."
  source: "git inspection of refs/phantomat branches, dirty worktree and .build artifact, 2026-11-04"
  affects: [phantomat-canvas-geometry, phantomat-overview-boundary]

- time: 2026-11-04T15:57:27
  kind: decision
  summary: Rewrote compiled_truth to the new best understanding
  source: "git state inspection and loss investigation, 2026-11-04"
  affects: [phantomat-patch-provenance]

- time: 2026-11-04T15:57:29
  kind: reversal
  summary: "The Hyprland 0.57 port is gone: freebuff reset refs/phantomat to origin/HEAD/ORIG_HEAD three times (15:30, 15:42, 15:43), erasing 26 modified files (4802+/4402-) that were never committed. Recovery was investigated (snapshots, lost-found, opencode store, built objects) and stopped by the user. Rule adopted: commit and push every verified build immediately; stash or temp-commit before any reset."
  source: "git reflog and worktree inspection, 2026-11-04"
  affects: [phantomat-canvas-geometry, phantomat-toggle-and-focus]

- time: 2026-11-04T18:54:14
  kind: decision
  summary: "Port restart plan written for Claude Code at PORT-PLAN-0.57.md: rebuild on top of 4099f30 on a new branch compat/hyprland-0.57-render-context-v2, commit and push after every passing build, verify only in the 0.57 nested session."
  source: "User request, 2026-11-04"
  affects: [phantomat-canvas-geometry, phantomat-toggle-and-focus]

- time: 2026-11-04T19:50:11
  kind: evidence
  summary: "Rebuilt the 0.57 port on compat/hyprland-0.57-render-context-v2 from 4099f30; commit 95f1c75 pushed to fork builds and links against Hyprland 0.57.1, every import resolves in /usr/bin/Hyprland, and the plugin loads, resolves all 18 hooks and unloads cleanly in the nested session. Explicit CRenderContext is threaded through all render paths; hooks live in one SCROLL_OVERVIEW_HOOKS table resolved by owner, name, demangled parameter tokens and parameter count (the native path uses the eSceneMode overloads of renderWorkspaceWindows[Fullscreen]); every #define private public was removed and private Hyprland state is reached only via compile-checked SPrivateMember explicit-instantiation accessors. The hyprbars bridge was deleted (unused here). Lost-port canvas features (client_size, overview_client_scale, label_drag, drops/raise/outline/hover, min_zoom removal) are not yet re-applied; the user config already references them."
  source: "make build + nested make test-env-phantomat, 2026-11-04"
  affects: [phantomat-patch-provenance, phantomat-canvas-geometry]

- time: 2026-11-04T20:03:56
  kind: decision
  summary: "0.57 port choices: overview previews derive border/shadow colours from config and window rules because 0.57 keeps decoration gradients private (no focus-change colour fade in previews); the hyprbars bridge is removed; plugin Lua dispatchers always return an action, matching 0.57; mouse-bound dispatchers target the overview under the pointer, then the focused one, since 0.57 no longer exposes the running bind."
  source: "port session, 2026-11-04"
  affects: [phantomat-patch-provenance]

- time: 2026-11-05T01:41:58
  kind: decision
  summary: "Published branch now targets Hyprland 0.57 (de7c458, fast-forwarded from the v2 port branch); tag pre-0.57-4099f30 keeps the old tip; layout of local-only branches updated"
  source: "merge and push, 2026-11-05"
  affects: [phantomat-patch-provenance]

- time: 2026-11-05T01:46:47
  kind: decision
  summary: "main on the fork is now the single published branch (de7c458); the two fork feature branches were deleted after proving both tips are inside fork/main; pushDefault set to fork"
  source: "user request, 2026-11-05"
  affects: [phantomat-patch-provenance]

- time: 2026-11-05T01:46:53
  kind: decision
  summary: "Correct the port commit count: 21 commits on top of 4099f30 (main is 22 ahead of upstream a1e8a08 because that includes the canvas commit itself)"
  source: "self-correction, 2026-11-05"
  affects: [phantomat-patch-provenance]
