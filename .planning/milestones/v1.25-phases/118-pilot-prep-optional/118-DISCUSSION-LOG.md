# Phase 118: Pilot Prep (Optional) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 118-pilot-prep-optional
**Areas discussed:** Backlog evidence refresh, Evaluator one-pager placement, One-pager content & STG boundaries, Doc-contract enforcement
**Mode:** User requested all areas + subagent research + one-shot locked recommendations (no further Q&A)

---

## Research synthesis (four parallel subagents + prompts/)

Cross-cutting themes from `prompts/threadline-elixir-oss-dna.md`, `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md`, and ecosystem peers (Ecto, Oban, Carbonite, django-auditlog, Searchkick):

- **Lock commands, not counts** — Elixir OSS documents named gates (`mix test`, `mix test.ci`), not ExUnit totals.
- **Split capture vs host proof** — Carbonite/django-auditlog: library proves substrate; host proves actor, topology, jobs.
- **README-as-map** — depth in task-shaped guides (Phase 117); avoid fifth hub or wide README matrices.
- **Honest CI-class vs host-class** — Threadline vocabulary is a strength; do not let stale counts or fictional examples read as STG attestation.

---

## Area 1: Backlog evidence refresh (PILOT-01)

| Option | Description | Selected |
|--------|-------------|----------|
| A) Hardcode updated counts (705) | Replace 136 with current total | |
| B) Commands only | No numbers; cite `mix ci.all` | Partial |
| **C) Hybrid: commands + contract-lock aliases** | Entrypoints in prose; refute stale counts in tests | ✓ |

**User's choice:** C (research recommendation; user delegated all decisions).
**Notes:** Stale L5 and incomplete L133 vs `mix.exs` `ci.all`. Do not add 705 — will rot. Align with STG “OK = reproducible pointer.”

---

## Area 2: Evaluator one-pager placement (PILOT-02)

| Option | Description | Selected |
|--------|-------------|----------|
| A) New README `## Evaluating Threadline 0.6.0` band | Full one-pager in README | |
| B) Expand Start here Evaluating subsection | Inline essay under routing list | |
| **C) `guides/evaluating-threadline.md` + README link** | Split guide + map discovery | ✓ |

**User's choice:** C.
**Notes:** Reconciles subagent placement (guide) with content outline (8 sections in guide, not README). Start here bullet + Documentation list entry. ExDoc extra.

---

## Area 3: One-pager content & STG boundaries

| Approach | Description | Selected |
|----------|-------------|----------|
| Duplicate STG tables in README/guide | Full rubric copy | |
| **Link to adoption-pilot-backlog markers** | STG-HOST-TOPOLOGY-TEMPLATE + STG-AUDITED-PATH-RUBRIC | ✓ |
| Hybrid 1-row example | Risk: fictional ExampleCloud read as certification | |

**User's choice:** Link-only + locked 8-section guide outline; must-have sentences from 117/CONTRIBUTING/adoption-pilot.
**Notes:** Footguns documented: test counts as proof, CI topology ≡ prod, Evidence plane ⇒ compliance, false STG attestation.

---

## Area 4: Doc-contract enforcement

| Option | Description | Selected |
|--------|-------------|----------|
| A) Extend adoption_pilot_doc_contract_test only | PILOT-01 only | Partial |
| **B) adoption_pilot + evaluating_threadline + readme link asserts** | Two doc surfaces, two contract modules + README link | ✓ |
| C) Docs-only | No new contracts | |

**User's choice:** B (hybrid A + new evaluating module + readme extension).
**Notes:** Reject numeric locks and paragraph snapshots. Do not duplicate ci_topology ordering tests.

---

## Claude's Discretion

- Exact guide headings and optional 3-column evidence stub table.
- CONTRIBUTING `verify.example` mention (optional).
- ci_topology file list hygiene (separate commit unless alias changes).

## Deferred Ideas

- Full README evaluator band — Phase 118 rejected
- Hardcoded test counts in any adopter path — rejected permanently for this phase
