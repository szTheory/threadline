# Phase 20 — First external pilot

**Milestone:** v1.5  
**Requirement:** ADOP-03

## Objective

One non-synthetic app (staging or production-like) walks [`guides/production-checklist.md`](../../../guides/production-checklist.md) and records status + evidence in [`guides/adoption-pilot-backlog.md`](../../../guides/adoption-pilot-backlog.md). Triage every **`Issue`** row into a GitHub issue or a scoped v1.6 requirement.

## Success criteria

1. Every checklist **section** in the backlog has a row status other than **`Not run`** for material sections, or explicit **`N/A`** with reason.
2. At least one row is **`OK`** or **`Issue`** with evidence (log excerpt, SQL, PR, or issue link).
3. **ADOP-03** checkbox updated in `.planning/REQUIREMENTS.md` traceability to **Complete**; `/gsd-transition` or milestone close per project habit.

## Risks

- **PgBouncer transaction mode** — highest-risk unknown; capture evidence if actor bridge drops.

## Verification

Host-team sign-off + maintainer review of updated backlog file (commit or attached artifact).
