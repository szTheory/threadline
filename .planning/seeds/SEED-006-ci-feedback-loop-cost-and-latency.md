---
id: SEED-006
status: closed
planted: 2026-09-13
planted_during: v1.41 Phase 201 planning, after Phase 200 closeout
scope: unknown
closed_on: 2026-09-29
closed_during: v1.43 Phase 222
closed_reason: >-
  Measured, not worth it — 0 of 28 merged PRs strict-inert in the rolling 30
  days, against a gate needing >=20% of PRs and >=10% of billed PR minutes.
decision: .planning/phases/222-seed-006-change-aware-lanes-conditional/222-DECISION.md
reopen_when: >-
  strict inert share >= 5 of the last 20 merged PRs, by a freshly collected
  snapshot run through `python3
  .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py
  --last 20`, or a new required lane moves the ci.yml critical path past the
  Browser E2E bound (about 550 s, run 36455432448)
audit_acknowledged:
  milestone: v1.41
  at: 2026-09-25
  status: dormant
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

## Outcome

**CLOSE.** Phase 222 re-measured the strict fail-closed inert-PR share on a fresh
snapshot: 0 of 28 merged PRs in the rolling 30-day gate window. Both parts of the
D-02 build gate failed at 0.0% (need >=20% of PRs and >=10% of billed PR
runner-minutes) — see
`.planning/phases/222-seed-006-change-aware-lanes-conditional/222-DECISION.md`
for the full gate, the ceiling row, and the honesty note on the thresholds.

This seed reopens only on a numeric trigger: strict inert share reaching >=5 of
the last 20 merged PRs (re-measured with the 222 tooling's `--last 20` mode), or
a new required lane pushing the `ci.yml` critical path past the Browser E2E
bound. Absent one of those, the change-aware classifier and `verify-change-scope`
job described above stay unbuilt.

The nested `audit_acknowledged` block above is the historical v1.41 audit record
(status `dormant` at that time) and is left unchanged; it intentionally differs
from this seed's current top-level `status: closed`.
