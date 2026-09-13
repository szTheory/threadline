---
id: SEED-006
status: dormant
planted: 2026-09-13
planted_during: v1.41 Phase 201 planning, after Phase 200 closeout
trigger_when: when relevant
scope: unknown
---

# SEED-006: Reduce CI/CD feedback-loop cost and latency without weakening coverage

## Why This Matters

Tiny CI-only changes currently pay the full 15-job matrix on the pull request and
again after squash merge. During the Phase 200 closeout, each iteration spent
roughly 7–11 minutes waiting on database, browser, minimum-runtime, and evidence
lanes even when the changed files could not affect most of those systems. This
slows iteration, burns runner minutes, and makes small reliability fixes
disproportionately expensive.

The optimization must preserve the single `CI required` protection contract and
must not silently shrink what it proves. Faster feedback is valuable only if the
result remains honest and branch protection cannot be laundered by skipped jobs.

## When to Surface

**Trigger:** when relevant

Surface this seed when planning CI/CD work, when runner cost or feedback latency
becomes milestone scope, or before adding another required lane to the aggregate.

## Scope Estimate

**Unknown** — measure runner-minutes and critical-path time first, then plan from
evidence. Candidate areas include change-aware lane selection with explicit
fail-closed classification, avoiding redundant PR/post-merge work where GitHub's
trust model permits it, cache improvements, and eliminating duplicate setup or
test coverage across the current/minimum/browser/evidence lanes.

## Breadcrumbs

- `.github/workflows/ci.yml` — 14 substantive jobs plus the `CI required` aggregate.
- `CONTRIBUTING.md` — documents the aggregate `needs:` roster and coverage promise.
- `test/threadline/ci_topology_contract_test.exs` — guards against silently narrowing that promise.
- `.planning/ROADMAP.md` — Phase 198 Plan 05 and GREEN-07 already establish CI latency as a measured concern.
- GitHub runs `34757305454`, `34757804720`, and `34758908342` — repeated 7–11 minute full matrices observed while landing small branch-protection workflow fixes.

## Notes

- Treat runner cost and wall-clock feedback time as separate metrics.
- Preserve full validation for product/runtime changes and scheduled confidence runs.
- Any path-aware fast path needs a mechanically tested classifier and a conservative
  fallback to the full matrix for unknown changes.
- Do not solve latency by removing a lane from `CI required` without updating and
  reviewing the documented coverage contract in the same change.
