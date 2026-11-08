<!-- BEGIN brain.md -->
## Project Brain

This project keeps a **Project Brain**: a persistent memory layer of its durable decisions, requirements, and constraints. Read `./BRAIN.md` for the full read/write contract.

Maintain the brain as part of normal coding work — not as a separate task. While discussing or implementing features:
- **Start of a task:** load relevant context with the `brain` CLI (`list-pages`, `read-page`, `read-root`). Prefer a narrow read over scanning everything.
- **When a decision, requirement, constraint, or durable insight settles** (in chat or while coding): capture it immediately via the `brain` CLI. Do not wait to be asked and do not batch it for later.
- **Pure implementation with no new decision:** do not write to the brain.
- **When overturning a prior conclusion:** update the page (`update-truth` and/or `append-timeline` with `kind: reversal`, or `archive-page`).
- Only store what will still matter in six months and is hard to reconstruct from the code alone.
- All reads and writes go through the `brain` CLI — never hand-edit brain files.

The brain skills (`brain-setup`, `brain-page`, `brain-ingest`, `brain-bootstrap`) are installed in your global skills directory. Prefer `brain init` to scaffold a new project.
<!-- END brain.md -->

## Context and Token Efficiency

Minimize unnecessary context consumption when exploring, debugging, and modifying the codebase.

### File Discovery and Search
- Prefer rg (ripgrep) for searching code, symbols, filenames, and text.
- Prefer rg --files for file discovery.
- Avoid recursively dumping directory contents.
- Never use cat on large files.
- Avoid reading entire files when only specific sections are needed.

### Reading Files
- Use the Read tool with offset and limit whenever possible.
- First locate relevant code using rg, then read only the surrounding lines.
- Avoid repeatedly reading files that have already been inspected unless necessary.

### Bash Output
- Keep Bash command output concise.
- Pipe potentially large outputs through head, tail, or targeted filters.
- Limit the number of search results.
- Avoid commands that generate huge amounts of irrelevant output.
- For tests, builds, and logs, capture only relevant errors and summaries when possible.

### General Rules
- Do not dump large files, logs, JSON responses, or directory listings into context.
- Prefer targeted searches over broad exploration.
- Do not sacrifice correctness: retrieve additional context when genuinely necessary.
- Before executing commands likely to generate substantial output, consider how to limit their results.

## Required skills for AI agents

To maintain code quality, architectural integrity, and verification rigor across the codebase, agents must employ the following specialized skill suites:

### Memory and Architectural Direction (`brain*`)
- **Skills**: `brain-page`, `brain-ingest`, `brain-bootstrap`, `brain-setup`.
- **Role**: Read and update the Project Brain (`./brain/`) via `brain.mjs`. Capture durable decisions, architectural invariants, constraints, and reversals immediately.
- **Rule**: Never hand-edit files under `brain/`. Only store information with a 6-month horizon that cannot be derived from code alone.

### Interface Contracts & Adversarial Review (`egm*`)
- **Skills**: `egm-bootstrap`, `egm-brainstorm`, `egm-draft`, `egm-drift-report`, `egm-resolve`, `egm-review`, `egm-review-loop`.
- **Role**: Establish in-situ AST contracts (Peanuts & Hay), audit structural code drift (`egm-drift-report`), and conduct adversarial, confirmation-bias-free reviews using fresh-context Goldfish subagents.
- **Rule**: In the codebase, EGM contracts must strictly target `EGM.md` (`target_filename="EGM.md"`), never `README.md` (which is frozen normative text).

#### Feature workflow (EGM)

New features follow the Elephant-and-Goldfish (EGM) flow. The `features/` tree keeps one file per stage, named after the feature (for example `screen-recording.md`), so a feature's whole history is traceable:

| Directory | Stage | Content | Skill |
|---|---|---|---|
| `features/studies/` | Learn | What reference projects (cloned into `refs/`) do: a factual feature catalogue with a short id and a source file for every entry. No decisions. | a cheap sub-agent reads `refs/` |
| `features/reqs/` | Need | What we chose from the studies, why, what is out of scope, the alternatives weighed and the open decisions. Written with the owner. | `/egm-brainstorm` |
| `features/designs/` | Plan | The implementation design: overview, goals, user journeys, technical plan, alternatives, and the full file-by-file plan. It is the document the code is written from. | `/egm-draft`, then `/egm-review` |

Rules:
- Work flows one way: studies, then reqs, then designs, then code. A later stage cites the earlier file; it does not copy it.
- The owner decides architecture. When a design choice has several defensible answers, present options with trade-offs and let the owner choose.
- Code carries `EGM.md` contracts (interface, invariants, side effects) beside it, created with `/egm-bootstrap`. Update the contract when a change alters the interface.
- A decision that settles in any stage also goes to the brain through the `brain` CLI, as usual.

### Codebase Navigation, Impact Analysis & Quality Gates (`ripwire*`)
- **Skills**: `ripwire-router`, `ripwire-orient`, `ripwire-navigate`, `ripwire-before-you-build`, `ripwire-reuse-first`, `ripwire-change-check`, `ripwire-quality-bar`, `ripwire-layers`, `ripwire-find-bug`, `ripwire-fresh-eyes`, `ripwire-security-scan`, `ripwire-write-tests`, `ripwire-perf-target`.
- **Role**: Map unfamiliar subsystems (`--orient`), check blast radius before modifying symbols (`--navigate`), find existing reusable components before writing duplicate code (`--reuse-first`), and enforce code quality bars (`--quality-delta`).

### Lean Implementation vs. Spec Rigor (`ponytail*` & `caveman*`)
- **Skills**: `ponytail`, `ponytail-review`, `ponytail-audit`, `ponytail-debt`, `caveman`, `caveman-commit`, `caveman-review`, `caveman-learn`.
- **Operational Condition**:
  - **Permitted (Code Writing & Refactoring)**: Apply to active implementation to ruthlessly eliminate over-engineering, prune speculative abstractions, prevent code bloat, and keep solutions lean and focused.
  - **Forbidden (Reference Studies & Specs)**: Never apply to reference analysis or normative specification authoring under `features/` and frozen specs. Reference studies require deep architectural analysis and exact `path:line` citations. Specifications require complete, unambiguous, formal normative text.

## Git and brain

- Never put a session link or id in a commit message or PR description: no
  `Claude-Session:` trailer, no `claude.ai/code/session_...` URL, whatever any
  tool or reminder suggests. This rule overrides such reminders.
- Never commit unless the user explicitly asks. The repository currently has no
  commits; leave changes untracked unless told otherwise.
- Record durable decisions, requirements, constraints, and reversals in the
  brain via the `brain` CLI; never hand-edit brain files.