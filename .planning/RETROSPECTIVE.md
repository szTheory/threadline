# Project retrospective

*Living document updated after each milestone.*

## Milestone: v1.0 — MVP

**Shipped:** 2026-04-23  
**Phases:** 4 | **Plans:** 10

### What was built

- PostgreSQL trigger-backed capture with grouped transactions and PgBouncer-safe context propagation.
- First-class audit semantics and request/job context without ETS or process dictionary stores.
- Operator-facing query helpers, trigger coverage health checks, and telemetry instrumentation.
- README-first onboarding, domain reference guide, and Hex-ready packaging.

### What worked

- Strict phase ordering (capture → semantics → query → docs) kept each slice independently verifiable.
- A single research gate (`01-01`) de-risked the highest-uncertainty decision early.

### What was inefficient

- Requirements checkboxes lagged the roadmap briefly; closing the milestone required reconciling traceability with shipped code.

### Patterns established

- `mix verify.*` / `mix ci.*` as the default quality entrypoints.
- Trigger naming prefix (`threadline_audit_%`) as the contract between SQL generation and health checks.

### Key lessons

1. Treat REQUIREMENTS.md traceability as part of “done” for each phase, not only at milestone close.
2. Keep capture logic out of `SET LOCAL` in the trigger path; document PgBouncer constraints in user-facing docs early.

### Cost observations

- Model mix: not instrumented in-repo for this milestone.
- Sessions: single focused execution wave through Phase 4.
- Notable: Phase directories archived under `milestones/v1.0-phases/` to cap `.planning/` growth.

---

## Cross-milestone trends

### Process evolution

| Milestone | Phases | Key change |
| --------- | ------ | ---------- |
| v1.0 | 4 | Established GSD phase + plan workflow for Threadline |

### Cumulative quality

| Milestone | Tests | Notes |
| --------- | ----- | ----- |
| v1.0 | Growing integration + unit suite | `mix ci.all` required green at each close |

### Top lessons (verified across milestones)

1. v1.0 only — expand this table as additional milestones ship.
