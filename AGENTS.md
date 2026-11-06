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
## Feature workflow (EGM)

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
