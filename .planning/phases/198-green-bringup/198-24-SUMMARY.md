---
phase: 198-green-bringup
plan: 24
subsystem: testing
tags: [elixir, ecto, demo-seed, ci, example-app, assertion-hardening]

# Dependency graph
requires:
  - phase: 198-green-bringup
    provides: "198-23's retention_tail.ex cutoff fix (cause group A) and the reusable six-step fix protocol"
provides:
  - "Confirmation that SEED-05, SEED-02/04, SEED-04, WALK-04, D-05, D-13 already pass (13 tests, 0 failures) as a side effect of 198-23"
  - "Three assertion-hardening fixes closing vacuous-pass and literal-pin rot risk in demo_contract_test.exs"
  - "Re-measured mix verify.example: 109 tests, 1 failure, unchanged (delta 0) from plan 198-23's closing count"
affects: [198-25, 198-26, 198-27, 198-28, 198-29]

# Actuals (#2632)
actuals:
  tokens: 4600
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Structural/static teeth proof as a distinct, explicitly-labeled proof class when a runtime red is not reproducible without editing an out-of-scope file"
    - "Preceding non-emptiness assertion paired with every property assertion over a queried row set, to prevent vacuous passes on an empty seed"

key-files:
  created: []
  modified:
    - examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs
    - .planning/audits/198-round4-demo-seed.md

key-decisions:
  - "This plan's chartered clusters (SEED-05, SEED-02/04, SEED-04, WALK-04, D-05, D-13) were already green (13/0) before any edit — a predicted side effect of 198-23's shared cause-group-A fix. Stated honestly rather than fabricating new 'fixes' to look busier than the numbers support."
  - "Proceeded to fix three genuine assertion-rotted weaknesses (WALK-04 literal pin, two D-05 vacuous-pass gaps) that had not yet triggered a failure but matched the exact rot patterns GREEN-04's must-haves name — treated as Rule 2 (missing critical robustness), not scope creep."
  - "WALK-04's fix has no reproducible runtime red (would require editing manifest.ex, out of scope) — documented as a distinct 'static/structural' proof class rather than fabricating a red that doesn't exist."
  - "mix verify.example's after-count (109 tests, 1 failure) is unchanged from plan 198-23's closing count — delta 0, stated plainly rather than claimed as an improvement."

patterns-established:
  - "Pattern: when a plan's target failures are already resolved by a prior plan's shared-cause fix, verify against the plan's own must-haves for rot risk rather than declaring the plan a no-op."

requirements-completed: []  # GREEN-04 remains Pending per D-01 -- this plan produces a readiness signal only; plan 198-29's measured CI run is authoritative.

coverage:
  - id: D1
    description: "SEED-05, SEED-02/04, SEED-04, WALK-04, D-05, D-13 clusters confirmed passing (13 tests, 0 failures) before and after this plan's edits, two consecutive runs"
    verification:
      - kind: integration
        ref: "examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs (13 tests, 0 failures, two consecutive runs, both pre- and post-edit)"
        status: pass
    human_judgment: false
  - id: D2
    description: "WALK-04 redaction_policy assertion reads subject_ref from the manifest-sourced local variable instead of a duplicate inline literal"
    verification:
      - kind: other
        ref: ".planning/audits/198-round4-demo-seed.md#plan-198-24 (static/structural teeth proof)"
        status: pass
    human_judgment: false
  - id: D3
    description: "D-05 backdating tests pair a non-emptiness assertion with the outside-window property assertion, with explicit boundary-comparison semantics stated in source"
    verification:
      - kind: other
        ref: "reproducible mix run script (/tmp/teeth_proof_198_24.exs) demonstrating the old assertion form's vacuous pass and the new guard's correct failure under a simulated seed regression"
        status: pass
    human_judgment: false
  - id: D4
    description: "mix verify.example re-measured twice after this plan's changes: 109 tests, 1 failure both runs, delta 0 vs plan 198-23's closing count, residual failure already dated and unrelated"
    verification:
      - kind: other
        ref: ".planning/audits/198-round4-demo-seed.md#measured-after-count-198-24"
        status: pass
    human_judgment: false
  - id: D5
    description: "GREEN-04 not marked Complete -- only the measured CI run in plan 198-29 (D-01) is admissible evidence"
    verification:
      - kind: integration
        ref: "test/threadline/ci_attestation_contract_test.exs + .planning/audits/ci-attestation-33344382035.json"
        status: pass
    human_judgment: false
    rationale: "Per D-01, no local evidence can satisfy this -- it requires deferring to plan 198-29's CI run, which this SUMMARY does not attempt to substitute for. Discharged by measured CI run 33344382035 per D-01: GREEN-04 is Complete on that run's own job conclusion, not on local evidence."
# Metrics
duration: 40min
completed: 2026-08-28
status: complete
---

# Phase 198 Plan 24: Gap-closure round-4 expansion — demo-seed assertion hardening Summary

**Found that all six chartered describe blocks in `demo_contract_test.exs` were already passing (a predicted side effect of plan 198-23's shared root-cause fix), then hardened three genuine vacuous-pass and literal-pin rot risks the plan's must-haves specifically called out, with mix verify.example unchanged at 109 tests / 1 (already-dated, unrelated) failure.**

## Performance

- **Duration:** 40 min
- **Started:** 2026-08-28
- **Completed:** 2026-08-28
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Ran a fresh two-run baseline of `demo_contract_test.exs` (after `mix deps.get` to unblock the worktree's unfetched deps) and found **13 tests, 0 failures on both runs, before any edit** — all six of this plan's chartered describe blocks (SEED-05, SEED-02/04, SEED-04, WALK-04, D-05, D-13) already passed, as plan 198-23's cause-group-A fix predicted.
- Read `demo_contract_test.exs` against this plan's own must-haves and found three genuine `assertion-rotted` weaknesses that had not yet triggered a failure: WALK-04 restated the manifest's declared `subject_ref` as a second, independently hardcoded literal; and both D-05 backdating tests asserted `in_window_count == 0` with no preceding check that the underlying row set was non-empty, meaning a seed regression producing zero rows would pass those tests vacuously.
- Fixed all three: WALK-04 now compares against the manifest-sourced local variable; both D-05 backdating tests (plus the actor_ref test, for consistency) now assert row-set non-emptiness before the property; boundary (`>=` strict-inclusive) and D-13's set-membership-independent-of-order semantics are now stated explicitly in source comments.
- Captured a reproducible red-then-green teeth proof for the D-05 vacuous-pass guard via a `mix run` script against the real sandboxed test DB (deleting all `org_memberships` `AuditChange` rows and showing the old assertion form would pass vacuously while the new guard correctly raises); documented a static/structural proof for WALK-04 since no runtime red is reproducible there without editing the out-of-scope `manifest.ex`.
- Re-measured `mix verify.example` twice from the repository root: **109 tests, 1 failure, both runs** — unchanged (delta 0) from plan 198-23's closing count. The one residual failure is the same already-dated, confirmed-unrelated `Governance.ExportJob` expiry-label bug; no new failure surfaced, so no new `deferred-items.md` entry was needed. Also recorded, as an honest discovery, a non-deterministic Postgrex connection-pool timeout observed on one of six local runs of the target file — same failure class already named `non-deterministic` in plan 198-23's inventory, unrelated to this plan's edits, and cleared on the immediately following runs.

## Task Commits

1. **Task 1+2 (combined — see Deviations): Harden SEED-05/SEED-02/04/WALK-04/D-05/D-13 clusters** - `a49df95a` (fix)
2. **Task 2: Re-measure mix verify.example and record the delta** - `a7a05c30` (docs)

## Files Created/Modified

- `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` - WALK-04 manifest-read fix, D-05 non-emptiness guards, explicit boundary/set-membership comments
- `.planning/audits/198-round4-demo-seed.md` - starting-state measurement, disposition record, red-then-green teeth proofs (runtime + structural), and the after-count re-measurement section

## Decisions Made

- Did not force new "fixes" to make the plan look busier than the real numbers support — the plan's chartered clusters were already green, and this is stated plainly in the audit rather than obscured.
- Proceeded with the three hardening fixes as Rule 2 (missing critical robustness) auto-fixes since they directly matched must-haves named in this plan's own frontmatter, even though no test was currently red for them.
- Combined what the plan split into Task 1 (SEED-05/SEED-02/04/WALK-04) and Task 2 (D-05/D-13) into a single source-edit commit, since the actual diagnosis put all three genuine fixes (WALK-04, and both D-05 clusters) in one coherent pass over the same file in one sitting; Task 2's re-measurement work is its own separate commit, preserving the plan's fix-then-remeasure ordering.
- Treated WALK-04's fix as needing a different proof class (static/structural) than D-05's (runtime red-then-green), rather than fabricating a runtime failure that cannot actually occur without editing an out-of-scope file.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Worktree had unfetched Elixir/Hex dependencies**
- **Found during:** Task 1 (initial baseline measurement attempt)
- **Issue:** `mix test` failed immediately with "the dependency is not available, run mix deps.get" for every declared dependency (phoenix, ecto_sql, postgrex, etc.) in the example app.
- **Fix:** Ran `mix deps.get` in `examples/threadline_phoenix` (fetching already-declared, already-locked dependencies from `mix.lock` — no new or upgraded package, no `mix.exs`/lockfile diff).
- **Files modified:** none tracked by git (deps are gitignored `deps/` output).
- **Verification:** `mix compile --warnings-as-errors` succeeded cleanly afterward; `mix test` ran.
- **Committed in:** N/A (no trackable file change; environment setup only, no dependency version change).

**2. [Rule 1 - Bug] Task organization diverged from the plan's Task 1/Task 2 file split**
- **Found during:** Task 1 (diagnosis)
- **Issue:** The plan structured Task 1 around SEED-05/SEED-02/04/WALK-04 and Task 2 around D-05/D-13, but the actual diagnosis (reading the whole file against the must-haves) found the genuine fixes (WALK-04, D-05 x2) naturally grouped together in one edit pass, with SEED-05/SEED-02/04/SEED-04/D-13 needing no source change at all.
- **Fix:** Landed all source-level test fixes in one commit (`a49df95a`), and the Task-2-specific re-measurement work in a second commit (`a7a05c30`), preserving the plan's fix-then-remeasure sequencing without artificially splitting fixes that belonged together.
- **Files modified:** `demo_contract_test.exs`, `.planning/audits/198-round4-demo-seed.md`
- **Verification:** All Task 1 and Task 2 acceptance criteria (test counts, `@tag :skip` count 0, `ci.yml`/`mix.exs` diffs empty, manifest-read requirement, non-emptiness/boundary/set-membership source checks) verified explicitly, listed per-task in this SUMMARY.
- **Committed in:** `a49df95a`, `a7a05c30`

---

**Total deviations:** 2 auto-fixed (1 Rule 3 — environment setup, 1 Rule 1 — commit organization adjusted to match the real diagnosis).
**Impact on plan:** No scope creep. No seed module needed a content change (all seeded content was already correct); only the test file's assertion robustness and the audit file were touched, exactly as this plan's must-haves anticipated as a possible outcome ("Zero or more of `demo/seed.ex`, ...").

## Issues Encountered

- One non-deterministic `ExUnit.TimeoutError` (Postgrex connection-pool contention during `Reset.run/1`) observed on 1 of 6 local runs of `demo_contract_test.exs` during this plan's verification passes — same failure class already documented as `non-deterministic` in plan 198-23's inventory, not attributable to this plan's edits (the affected test's assertions were not touched), and cleared on the immediately following two consecutive runs used as this plan's official post-fix evidence. Recorded in the audit file per the fix protocol's discovery-logging step; no code change made for it (out of this plan's scope — would require DB pool/timeout tuning, not a `files_modified` candidate).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `demo_contract_test.exs` passes 13/13 on two consecutive runs, with three genuine rot-resistance gaps closed before they could mask a future regression.
- `mix verify.example`'s measured failure count is unchanged (109/1, delta 0) from plan 198-23 — the sole residual failure remains the same already-dated `Governance.ExportJob` expiry-label bug, still out of scope for this plan and still needing a follow-up gap-closure plan.
- GREEN-04 remains **Pending** — this plan is a local readiness signal only, per D-01; the verdict belongs exclusively to plan 198-29's measured CI run.
- No blocker for the rest of gap-closure round 4 (plans 198-25 through 198-28 can proceed independently — this plan touched only `demo_contract_test.exs` and the shared audit file, both read-compatible with sibling plans' own `read_first` needs).

---
*Phase: 198-green-bringup*
*Completed: 2026-08-28*
