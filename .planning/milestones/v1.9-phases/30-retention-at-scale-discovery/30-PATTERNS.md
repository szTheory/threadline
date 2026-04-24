# Phase 30 — Pattern map

Analogs for documentation edits (from completed v1.9 phases).

| Target | Role | Closest analog | Notes |
|--------|------|----------------|-------|
| `guides/production-checklist.md` | Operator gates + links | Phase 28 plans (`28-01` / `28-02`) — telemetry + health bullets in §6, trigger coverage in §1 | Extend §4 in place; match checklist tone (imperative bullets). |
| `guides/domain-reference.md` | Canonical semantics + hub | Phase 29 `## Audit indexing (integrator-owned)` — thin pointer H2 | New hub H2 is **links-only**, same depth. |
| `README.md` | Discovery | Phase 29 README one-liner pattern (indexing) deferred to 30 per `29-CONTEXT` | Single paragraph; link to `domain-reference.md` anchor, not duplicate guides. |
| `29-01-PLAN.md` | Plan structure | This phase’s `30-0*-PLAN.md` | Frontmatter, `## Threat model`, tasks with `<read_first>`, `<action>`, `<acceptance_criteria>`. |

**Code excerpts to respect (names only in prose):**

- `Threadline.Retention.purge/1`, `Threadline.Retention.Policy` — `lib/threadline/retention.ex` header `@moduledoc`.
- Mix task flags — first 40 lines of `lib/mix/tasks/threadline.retention.purge.ex`.

## PATTERN MAPPING COMPLETE
