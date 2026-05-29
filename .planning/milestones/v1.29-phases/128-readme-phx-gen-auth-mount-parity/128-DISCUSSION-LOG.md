# Phase 128: README + phx-gen-auth Mount Parity - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-28
**Phase:** 128-README + phx-gen-auth Mount Parity
**Areas discussed:** README ecto_repos placement, README trigger SSOT, phx-gen-auth authorize_fn shape, doc-contract strictness (all four — user requested full research synthesis)

---

## README Quick Start `ecto_repos` placement

| Option | Description | Selected |
|--------|-------------|----------|
| A — New step 2 "Configure Threadline" | Separate numbered step; renumber install → step 3; mirrors getting-started §2/§3 | ✓ |
| B — Expand existing step 2 | Config block first inside "Install and migrate"; no renumbering | |
| C — One-liner + link only | Minimal pointer to getting-started §2 | |
| D — Callout box between steps | High visibility but not part of numbered checklist | |

**User's choice:** Auto-resolved via research synthesis (user requested one-shot recommendations, no further input)
**Notes:** Option A chosen for structural parity with Phase 123 getting-started spine. Option B was strong alternate (lower diff); rejected because phase name is "parity." Option C fails correct-by-default (install succeeds, ops tasks fail later). Prior art: Oban/LiveDashboard put config before commands.

---

## README trigger table SSOT

| Option | Description | Selected |
|--------|-------------|----------|
| A — Multi-table + cross-link | Keep `users,posts,comments`; add SSOT links | |
| B — Single `posts` + cross-link | Match getting-started §4 fiction | ✓ |
| C — Pointer-only | No inline command in README | |
| D — Placeholder `your_table` | Generic non-runnable example | |

**User's choice:** Auto-resolved via research synthesis
**Notes:** Option B aligns with locked getting-started contract, example app, WALKTHROUGH, and README query examples. Option A highest copy-paste footgun despite cross-link. Carbonite/pgAudit pattern: one concrete table in entry docs.

---

## phx-gen-auth mount `authorize_fn` shape

| Option | Description | Selected |
|--------|-------------|----------|
| A — Full scope-first | `assigns[:current_scope].user` in authorize | ✓ (inside callback) |
| B — Hybrid current_user case | Match example router only | |
| C — Minimal is_admin on current_user | Shortest but wrong assign for 1.8 | |
| D — Callback ref `&MyApp.Audit.authorize_operator/1` | Match getting-started §9 mount dialect | ✓ (mount shape) |

**User's choice:** Auto-resolved via research synthesis
**Notes:** D+A combined: function-ref mount + scope-first user resolution inside module. Rejects inline `current_user.role` primary example. sigra example router unchanged (different lane).

---

## Doc-contract strictness

| Option | Description | Selected |
|--------|-------------|----------|
| README A — Scoped ordering test | Quick Start slice; literal before install | ✓ |
| README B — Presence only | Rejected — README-02 requires placement | |
| README C — Full step structure lock | Rejected — README is map not spine | |
| phx-gen-auth A+D — Replace legacy + semantic literals | Scope-first literals + refute bad patterns | ✓ |
| phx-gen-auth B — Dual assertions | Rejected — allows contradictory docs | |
| phx-gen-auth C — Full normalized block | Rejected — whitespace brittle | |

**User's choice:** Auto-resolved via research synthesis
**Notes:** Two-tier model from Phase 123 CFG work. Section-scoped slices before global binary.match.

---

## Claude's Discretion

- Step 2 heading exact wording
- Fixture module naming for authorize_operator
- Optional ordering assertion in phx-gen-auth surface section

## Deferred Ideas

- WALKTHROUGH truth → Phase 129
- Nyquist 125 → Phase 130
- sigra router scope-first migration → out of scope (different lane)
