---
phase: 198-green-bringup
plan: 18
subsystem: testing
tags: [ci, github-actions, measurement, pgbouncer, tier-a-capture, playwright, search-path]

requires:
  - phase: 198-14
    provides: "PgBouncer topology port + static call-site sweep"
  - phase: 198-15
    provides: "stress-router ambient-dependency retirement"
  - phase: 198-16
    provides: "Tier A byte-stability diagnosis (halted before remedy)"
  - phase: 198-17
    provides: "Example app browser E2E diagnosis and fix, plus the 28-failure discovery"
provides:
  - "A measured CI run (33197493051) with per-check results, a pre-push prediction scored against it, and a three-way job comparison against baseline 33138291361 and round-1 33183920952"
  - "GREEN-04 and GREEN-07 statuses set strictly from that measurement, citing the run ID, both REQUIREMENTS.md views in agreement"
  - "A fourth, newly-measured cause for Run test suite (current)'s continued redness: ci.yml's own verify-test job never runs the ALTER DATABASE search_path statement its sibling jobs carry"
affects: [198-VERIFICATION, green-04, green-07, ci-required]

actuals:
  tokens: 24000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Pre-push prediction table scored against the actual run — a prediction later contradicted is treated as evidence about the diagnosis, not noise to explain away"
    - "Three-way job-conclusion comparison (baseline / round 1 / round 2) computed by fetching all three runs' job lists fresh via gh api, not carried from any prior SUMMARY"

key-files:
  created:
    - .planning/phases/198-green-bringup/198-CI-MEASUREMENT.md
  modified:
    - .planning/REQUIREMENTS.md

key-decisions:
  - "GREEN-07 stays Pending: the time clause (13m29s <= 20min) is met but the success clause is not (CI required concluded failure). Per the plan's binding decision rule, a partial improvement is recorded as a partial improvement — not rounded to Complete."
  - "GREEN-04 stays Pending: two of the three test-carrying checks the decision rule names (PgBouncer transaction topology, Run test suite (min)) now succeed, but Run test suite (current) still fails — on a newly-measured third cause, not either of the two previously diagnosed and fixed by 198-14/198-15."
  - "Did not attempt to diagnose or fix the newly-discovered Run test suite (current) cause (missing ALTER DATABASE search_path step in ci.yml:235-240). Out of this plan's files_modified (REQUIREMENTS.md, STATE.md, 198-CI-MEASUREMENT.md only) and its own threat model, which forbids editing .github/ in this task. Recorded as measured fact for the next gap-closure round."
  - "Left WINDOWS.md untouched, per the plan's own acceptance criterion (git diff .planning/WINDOWS.md must be empty) and per CR-03/04/05's explicit carry-forward. The newly-discovered Run test suite (current) cause is recorded in 198-CI-MEASUREMENT.md and REQUIREMENTS.md instead; a follow-up plan should add a WINDOWS.md entry for it alongside the fix."
  - "Did not modify STATE.md, per this run's explicit worktree_execution instruction (the orchestrator owns that write after this agent returns), which supersedes the plan's own files_modified list for this specific dispatch."

requirements-completed: []

coverage:
  - id: D1
    description: "Local pre-flight baseline established and an explicit prediction written before the push (mix test x2 green, anti-laundering caps green, pooled PgBouncer topology sequence green, mix ci.all stops at the documented verify.example deferred item)"
    requirement: "GREEN-07"
    verification:
      - kind: integration
        ref: ".planning/phases/198-green-bringup/198-CI-MEASUREMENT.md — Task 1 section"
        status: pass
    human_judgment: false
  - id: D2
    description: "A real CI run on PR #29 observed to completion and recorded with run ID, head SHA, conclusion, wall-clock, per-check table, prediction scorecard, three-way job comparison, and verbatim failure output for every still-red check"
    requirement: "GREEN-07"
    verification:
      - kind: integration
        ref: "gh run watch 33197493051 --exit-status; gh api repos/szTheory/threadline/actions/runs/33197493051/jobs"
        status: pass
    human_judgment: false
  - id: D3
    description: "GREEN-04 and GREEN-07 set strictly from the measured run, both REQUIREMENTS.md views agreeing row for row, run ID cited in both"
    requirement: "GREEN-07"
    verification: []
    human_judgment: true
    rationale: "The plan's Task 3 is itself a checkpoint:human-verify with gate=blocking-human — the maintainer must confirm the recorded statuses match the measured run and that neither requirement was marked Complete on local-only evidence, per this run's checkpoint protocol (blocking-human is never auto-approved)."

duration: ~50min
completed: 2026-08-28
status: complete
---

# Phase 198 Plan 18: CI Measurement — Gap-Closure Round 2 Summary

**Pushed the round-2 gap-closure commits to PR #29, watched CI run `33197493051` to completion (13m29s, concluded `failure`), and found that fixing 198-14/198-15's two diagnosed causes closed 2 more of the original 7 red jobs (PgBouncer transaction topology, Run test suite (min)) — but also unmasked a third, previously-unreachable cause inside `Run test suite (current)`: its own database-prep step never runs the `ALTER DATABASE ... SET search_path` statement its sibling jobs carry, so `ThreadlinePhoenixWeb.WalkthroughHappyPathTest` fails with `undefined_table` on `audit_transactions`.**

## Performance

- **Duration:** ~50 min (including two ~44s local `mix test` runs, a ~2min local pooled-PgBouncer sequence, a full local `mix ci.all` to its documented stopping point, the push, and a 13m29s CI run watched to completion in the foreground)
- **Completed:** 2026-08-28T18:20Z
- **Tasks:** 3 of 3 (Task 3 is a `checkpoint:human-verify` with `gate="blocking-human"` — the write-the-record half is done and committed; the human-confirmation half is reported below, not auto-approved)
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments

- Established a written, dated local baseline (`mix test` twice — 1412/0 both runs; anti-laundering caps 25/0; `mix verify.format`/`mix verify.credo` clean; the pooled PgBouncer sequence green through a real transaction pool; `mix ci.all` stopping exactly at the documented `verify.example` deferred item, 109 tests/8 failures) and an explicit per-check prediction table, written and committed **before** the push.
- Pushed `f748e43d` (carrying 198-14 through Task 1 of this plan) to `ci/198-gap-closure`, PR #29's existing branch — no direct push to `main` was attempted, and branch protection / the live ruleset (`enforcement: active`, `bypass_actors: []`) were verified byte-identical before and after via both `git diff` and a live `gh api` read.
- Watched CI run `33197493051` to completion in the foreground: **conclusion `failure`, wall-clock 13m29s** (time clause met; success clause not).
- Recorded the full per-check table (all 14 checks, `CI required` called out separately), the prediction scorecard (11/14 correct — the one wrong prediction, `Run test suite (current)`, is explained by root-cause evidence, not just marked wrong), the three-way job comparison against baseline `33138291361` and round-1 `33183920952`, and verbatim failure output for all three still-red checks.
- **Measured answer to "how many of the 7 originally-red jobs are green now": 4 of 7.** Round 1 (198-08..13) fixed 2 (`Compile without optional deps`, `Mechanical checker`); this round (198-14/198-15) fixed 2 more (`PgBouncer transaction topology`, `Run test suite (min)`). 3 remain red: `Run test suite (current)` (newly-measured third cause), `Tier A capture lane` (198-16's diagnosed, forbidden-remedy halt, unchanged), `Example app browser E2E` (198-17's diagnosed 5/33 fix confirmed holding — the two fixed specs pass in this run — plus 5 of the 28-discovered pre-existing failures now surfacing for real, confirmed by exact name match against `deferred-items.md`/`WINDOWS.md` #8).
- Set GREEN-04 and GREEN-07 in `.planning/REQUIREMENTS.md` strictly from this measurement, both the checkbox list and the status table updated in agreement, both citing run `33197493051`. Neither was rounded to Complete.

## Task Commits

Each task was committed atomically:

1. **Task 1: Local pre-flight — establish exactly what is being pushed and what it does not prove** - `f748e43d` (docs)
2. **Task 2: Push the branch, watch the run to completion, and record it** - `7fe1e2a2` (docs)
3. **Task 3: Set GREEN-04 and GREEN-07 from the measurement** - `b7de3f51` (docs)

**Plan metadata:** committed alongside this SUMMARY.

## Files Created/Modified

- `.planning/phases/198-green-bringup/198-CI-MEASUREMENT.md` — new; local pre-flight baseline, honest limits, pre-push prediction, run ID/head SHA/conclusion/duration, per-check table, prediction scorecard, three-way job comparison, verbatim failure output for every still-red check
- `.planning/REQUIREMENTS.md` — GREEN-04 and GREEN-07 checkbox entries and status-table rows updated from the measured run, citing run `33197493051`, both views agreeing row for row

## The new discovery — Run test suite (current)'s third cause

`Run test suite (current)` was red in the baseline, red in round 1, and is still red now — but not for either of the two causes 198-14 and 198-15 diagnosed and fixed. In every prior CI run, this job's `mix verify.test` step (which is what both the pgbouncer file and the stress-router ambient dependency broke) failed *first*, and GitHub Actions' default sequential-step semantics meant the job never proceeded to its later, `if: matrix.lane == 'current'`-gated steps (`mix verify.threadline`, `mix verify.example`, `mix verify.doc_contract`). With `mix verify.test` now passing (confirmed: `Run test suite (min)`, which runs only that step, is green), the job advanced far enough to reach `mix verify.example` — and failed there, 9/9 on `ThreadlinePhoenixWeb.WalkthroughHappyPathTest`, all `** (Postgrex.Error) ERROR 42P01 (undefined_table) relation "audit_transactions" does not exist`.

The cause, read directly from `.github/workflows/ci.yml`: this job's own database-prep step (`:235-240`, "Ensure threadline_phoenix_test database exists") runs `createdb` only — it never runs the `ALTER DATABASE threadline_phoenix_test SET search_path TO "$user", public, threadline;` statement that the equivalent prep steps in the `verify-example-browser` job (`:346-355`) and the `verify-capture` job (`:500-509`) both carry. This is the exact GREEN-04 defect class (an unprefixed read against Threadline's owned schema) in a fourth location, previously invisible because it was always masked by an earlier failure in the same job.

**Not fixed in this plan** — `files_modified` for 198-18 is `REQUIREMENTS.md`, `STATE.md`, and `198-CI-MEASUREMENT.md` only, and this plan's own threat model forbids editing `.github/` here. Recorded as measured fact, with the exact file/line citation, for the next gap-closure round.

## Decisions Made

- **GREEN-07 decision rule applied literally.** `CI required` concluded `failure`, so GREEN-07 stays Pending regardless of the time clause being comfortably met (13m29s vs. the 20-minute bound) — the plan is explicit that a partial improvement is recorded as a partial improvement, never rounded up.
- **GREEN-04 decision rule applied literally.** The rule names the two `Run test suite` lanes and `PgBouncer transaction topology` as the minimum set that must all conclude success. Two of three do; `Run test suite (current)` does not, on a distinct, newly-measured cause. GREEN-04 stays Pending.
- **WINDOWS.md left untouched**, per the plan's own acceptance criterion. The new `Run test suite (current)` discovery is recorded in `198-CI-MEASUREMENT.md` and `REQUIREMENTS.md` instead; the next gap-closure plan should both fix it and add its own WINDOWS.md entry (this plan intentionally does not pre-empt that).
- **STATE.md left untouched**, per this specific worktree run's explicit instruction that the orchestrator owns that write after the agent returns — this supersedes the plan's own `files_modified` list, which named `STATE.md`, for this dispatch.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fetched root and example-app dependencies in this fresh worktree**
- **Found during:** Task 1 setup
- **Issue:** Neither `deps/` nor `examples/threadline_phoenix/deps` was populated; `mix test` initially failed one test (`stress_router_test.exs`, ambient-dependency class) before `examples/threadline_phoenix`'s deps were fetched.
- **Fix:** `mix deps.get` (root) and `MIX_ENV=test mix deps.get` (example app) — both already-declared dependencies per the respective lockfiles; the Rule 3 package-install exclusion does not apply.
- **Files modified:** none tracked (both `deps/` directories are gitignored).
- **Verification:** subsequent `mix test` runs (twice) returned 1412/0.
- **Committed in:** N/A (environment setup only).

---

**Total deviations:** 1 auto-fixed (Rule 3 — blocking environment setup, already-declared dependencies).
**Impact on plan:** None beyond enabling the local baseline. No scope creep.

## Issues Encountered

None beyond the new CI discovery documented above (which is measured fact recorded per the plan's design, not an issue with this plan's own execution).

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- **GREEN-07 remains Pending.** `CI required` failed on 3 of 12 dependencies. The time clause is not the blocker — the success clause is.
- **GREEN-04 remains Pending**, now for exactly one measured, precisely-located cause: `.github/workflows/ci.yml:235-240` needs the same `ALTER DATABASE ... SET search_path` statement its sibling jobs (`:346-355`, `:500-509`) already carry.
- **Next action, named plainly:** a follow-up gap-closure plan should (a) add the missing `ALTER DATABASE` statement to `ci.yml`'s `verify-test` job's db-prep step, (b) continue to leave `Tier A capture lane` alone (198-16's remedy remains forbidden this milestone) and `Example app browser E2E`'s remaining ~23 undiagnosed failures alone (198-17's discovery, still out of scope), and (c) push and re-measure. Until that lands, GREEN-04 and GREEN-07 both stay Pending.
- No blockers for a follow-up plan — this worktree's local state (deps fetched) is disposable/gitignored.

---
*Phase: 198-green-bringup*
*Completed: 2026-08-28*

## Self-Check: PASSED

- FOUND: .planning/phases/198-green-bringup/198-CI-MEASUREMENT.md
- FOUND commits: f748e43d, 7fe1e2a2, b7de3f51 (git log --oneline)
- CONFIRMED: `.planning/REQUIREMENTS.md`'s checkbox list and status table agree row for row for GREEN-04 and GREEN-07, both citing run 33197493051
- CONFIRMED: `git diff --exit-code .github/rulesets/ .github/workflows/branch-protection.yml .planning/WINDOWS.md` passes (empty)
- CONFIRMED: `git diff .planning/ROADMAP.md` is empty (no success-criterion wording change)
