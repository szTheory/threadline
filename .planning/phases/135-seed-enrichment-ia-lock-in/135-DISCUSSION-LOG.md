# Phase 135: Seed Enrichment & IA Lock-In - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-03
**Phase:** 135-seed-enrichment-ia-lock-in
**Areas discussed:** Edge-state reachability, Actor identity spread, Op/table diversity, IA lock-in artifact
**Mode:** Advisor (minimal_decisive calibration; `opinionated` vendor philosophy). User directed deep parallel subagent research across all four areas, asking for one coherent, decisive, ecosystem-grounded recommendation set.

---

## Edge-state reachability

| Option | Description | Selected |
|--------|-------------|----------|
| (A) One rich seed; states via sparse-org + filter/scope selection, documented as recipes | Single seed path = zero drift; matches existing arch; every "empty" maps to a real operator moment | ✓ (with C) |
| (B) `--profile empty\|dense` flags swapping datasets | "Empty" reachable in one command, but forks the seed path → rot; non-idiomatic; "demo data that lies" trap | |
| (C) Dedicated intentionally-empty org/scope | Honest empty scoped views; `offboarded-co` already does this | ✓ (part of A) |

**User's choice:** Lock the researched recommendation — (A)+(C): one deterministic seed, states *selected* via sparse org + filters + scoped login, documented as per-state recipes in DEMO-MANIFEST + doc-contract test. No profile flags.
**Notes:** Research surfaced exactly one genuinely seed-unreachable state — Coverage fully-covered/all-empty (trigger-registration dependent) — deferred to render-phase 138.

---

## Actor identity spread

| Option | Description | Selected |
|--------|-------------|----------|
| A. Realistic-skewed + deliberate edge coverage | Humans dominate; one small intentional cluster each for service_account/job/system/anonymous; reads as a real audit log | ✓ |
| B. Even split across all 6 kinds | Guarantees visibility but looks synthetic; recreates the "looks broken" F-202 perception | |
| C. Humans-only (just fix null actors) | Smallest diff but leaves machine/system/anonymous kinds unreachable — under-delivers the value prop | |

**User's choice:** Lock Option A — realistic-skewed (~70% user / 15% admin / 5% service_account / 5% job / 3% system / 2% anonymous), with named non-human actor literals and a deliberate public-ticket-form unknown cluster.
**Notes:** Research found the root cause of "unknown everywhere": `Personas.run` writes null-actor, un-backdated setup rows that sort to the top of the default window. Fix = give setup tx an admin actor + backdate. Constraint: no `:integration` kind (would fail ActorRef validation = library change).

---

## Op/table diversity

| Option | Description | Selected |
|--------|-------------|----------|
| A. Keep epoch-anchored variety only | Minimal change, but variety lands out-of-window → default screenshots still look all-INSERT | |
| B. Wall-clock in-window variety pack + filler op-mix shift | Guarantees ≥1 UPDATE + ≥1 DELETE + rich diff + redacted field above the fold; reuses proven idiom; deterministic | ✓ |
| C. Rewrite filler to a global 50/35/15 ratio | "Clean" headline ratio, but invisible in the default 24h window; large diff; over-engineered | |

**User's choice:** Lock Option B — small wall-clock in-window variety pack (~5/4/2 I/U/D) + filler shift (~55/35/10), rich before/after + `[REDACTED]` on `ticket_replies`, real DELETEs across three tables, in-window guarantee asserted.
**Notes:** Two load-bearing code realities overturned the working "global 50/35/15": only `ticket_replies` stores `changed_from` (rich diff source); default Timeline window is 24h off wall-clock now (epoch-anchored data is invisible). INSERT-shows-values *render* (F-201) deferred to 138.

---

## IA lock-in artifact

| Option | Description | Selected |
|--------|-------------|----------|
| A. Append "Locked IA" section to v1.31-UI-AUDIT.md | Single artifact later phases open, but **forks** the IA into two files → creates the drift the milestone forbids; wrong altitude | |
| B. Lock the existing v1.31-PERSONAS-IA.md + cross-link from audit | Reuses the canonical artifact; right altitude; zero duplication | ✓ |
| C. Doc-contract test asserting IDs present + referenced | Machine-checkable; matches Threadline's doc-contract culture; hollow without a locked doc | ✓ (as B+C-lite) |

**User's choice:** Lock B+C-lite — status-lock the **existing** `v1.31-PERSONAS-IA.md` (P1–P5, J1–J11, EF1–EF5), add a one-line pointer from the audit doc, add a ~15-assertion doc-contract test.
**Notes:** Research discovered the canonical artifact already exists with zero ID drift — so the original working assumption (append to audit) was wrong and would have forked the IA. Reconcile the brief's "J1–J10" → **J1–J11** (J11 = P5 first-mount).

---

## Claude's Discretion

- Exact in-window hour offsets; exact filler ratio within ~50–60/30–40/10–15; seed-module decomposition (extend Anchors/Filler vs new VarietyPack module) — provided determinism + the in-window guarantee hold.
- Final actor-id literal strings (suggested `service_account/zendesk-sync`, `job/oban-retention-purge`, `system/trigger-backfill`).

## Deferred Ideas

- F-201 render (inserted values for INSERT) → Phase 138.
- F-703 render (op/table/change-count on Actor rows) → Phase 138.
- F-103 render (op-chip in row_history_component) → Phase 136/138.
- F-204 Home resume-row render → Phase 139 (data seeded here).
- Coverage fully-covered/all-empty state → Phase 138 (trigger-registration dependent).
- True populated-but-zero empty-as-diagnostic renders (Evidence/Exports/Retention) → per-screen phase 137 if still wanted.
