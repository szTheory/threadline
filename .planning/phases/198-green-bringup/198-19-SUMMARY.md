---
phase: 198-green-bringup
plan: 19
subsystem: testing
tags: [ci, ecto, elixir, postgres, static-analysis, regex]

requires:
  - phase: 198-green-bringup (rounds 1-2)
    provides: the measured GREEN-04 gap (CI run 33197493051) and CR-01/CR-02 findings from 198-REVIEW.md
provides:
  - "verify-test job's current lane now prepares the example-app database identically to its two siblings"
  - "call-site sweep closes CR-01 (fully-qualified receiver blind spot) and CR-02 (insert_all blind spot)"
  - "round-3 local pre-push readiness signal recorded in 198-CI-MEASUREMENT.md"
affects: [198-20, 198-21, 198-22]

actuals:
  tokens: 5500
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "CI db-prep steps across sibling jobs kept byte-identical in shape (createdb + ALTER DATABASE ... SET search_path)"
    - "Static regex sweep receiver-shape widening: word-character-only negative lookbehind + CamelCase module-chain alternation"

key-files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - test/threadline/storage_schema_call_site_contract_test.exs
    - .planning/phases/198-green-bringup/198-CI-MEASUREMENT.md

key-decisions:
  - "Task 1 acceptance criterion 'mix verify.example completes with 0 failures' is UNMET as literally worded — verify.example still fails on a separate, pre-existing, already-acknowledged, non-deterministic example-app demo-seed content defect (deferred-items.md, Plan 198-12). The specific defect this task targets (undefined_table on audit_transactions) IS fully eliminated (0 occurrences across 3 independent local verify.example runs)."
  - "in_scope_count baseline was measured before editing the detector (208) and after (270) to prove the widening admits real call sites; offense_count stayed 0 in both."
  - "CR-01 fix narrows the negative lookbehind from (?<![\\w.]) to (?<![\\w]) and adds a CamelCase module-chain alternation in front of the literal Repo, rather than any file-based or name-based exemption (D-05 no-escape-hatch honored)."

requirements-completed: [GREEN-04]

coverage:
  - id: D1
    description: "verify-test job's current lane sets threadline on the example-app database search_path, matching its two sibling jobs exactly"
    requirement: "GREEN-04"
    verification:
      - kind: other
        ref: "grep -v '^\\s*#' .github/workflows/ci.yml | grep -c 'ALTER DATABASE' == 3, and grep -c '...threadline_phoenix_test SET search_path TO' == 3"
        status: pass
      - kind: other
        ref: "local end-to-end: DB_HOST=localhost mix verify.example against a freshly recreated threadline_phoenix_test — 0 undefined_table occurrences across 3 independent runs (vs. the prior 9-failure undefined_table class)"
        status: pass
      - kind: other
        ref: "idempotency: db-prep step body run twice consecutively, both exit 0, SHOW search_path output byte-identical"
        status: pass
    human_judgment: false
  - id: D2
    description: "Static call-site sweep closes CR-01 (fully-qualified Threadline.Test.Repo.* receiver blind spot) and CR-02 (insert_all/insert_or_update/stream blind spot), still rejecting mid-identifier receivers (MyRepo., some_repo.)"
    requirement: "GREEN-04"
    verification:
      - kind: unit
        ref: "test/threadline/storage_schema_call_site_contract_test.exs (22 tests, includes 8 new CR-01/CR-02 fixtures)"
        status: pass
      - kind: other
        ref: "red-then-green teeth proof: reverting @call_regex alone fails 3 CR-01 fixtures; reverting @ecto_functions alone fails 3 CR-02 fixtures; both applied together, 0 failures"
        status: pass
      - kind: other
        ref: "real-tree sweep: in_scope_count 208 (pre-fix) -> 270 (post-fix), offense_count 0 in both"
        status: pass
    human_judgment: false
  - id: D3
    description: "Round-3 local pre-push readiness signal recorded in 198-CI-MEASUREMENT.md, explicitly marked inadmissible as GREEN-04/GREEN-07 proof"
    requirement: "GREEN-04"
    verification:
      - kind: other
        ref: ".planning/phases/198-green-bringup/198-CI-MEASUREMENT.md Round 3 section"
        status: pass
    human_judgment: false

duration: 55min
completed: 2026-08-28
status: complete
---

# Phase 198 Plan 19: Round-3 GREEN-04 Gap Closure Summary

**Fixed the `verify-test` current-lane's missing search_path statement and closed the static sweep's two receiver-shape blind spots (CR-01 fully-qualified `Threadline.Test.Repo.*`, CR-02 `insert_all`), both proven red-then-green locally.**

## Performance

- **Duration:** ~55 min
- **Started:** 2026-08-28T18:20Z (approx)
- **Completed:** 2026-08-28T19:14:45Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- `.github/workflows/ci.yml`'s `verify-test` job current lane now runs the same `ALTER DATABASE threadline_phoenix_test SET search_path TO "$user", public, threadline;` statement its two siblings (`verify-example-browser`, `verify-capture`) already carry. All three `ALTER DATABASE` occurrences in the workflow now name the example-app database, confirmed by matching grep counts (3 == 3).
- The static call-site sweep in `test/threadline/storage_schema_call_site_contract_test.exs` now detects the fully-qualified module-chain receiver form (`Threadline.Test.Repo.delete_all(...)`, CR-01) and `insert_all`/`insert_or_update`/`insert_or_update!`/`stream` calls (CR-02) as offenses when unprefixed, while continuing to reject mid-identifier receivers (`MyRepo.`, `some_repo.`). `in_scope_count` over the real tree increased from 208 to 270 with `offense_count` staying at 0 in both.
- Round-3 local pre-push readiness signal appended to `.planning/phases/198-green-bringup/198-CI-MEASUREMENT.md`, with the inadmissibility of local evidence for GREEN-04/GREEN-07 stated explicitly and plan 198-21's measured CI run named as the authority.

## Task Commits

1. **Task 1: current-lane db-prep step search_path fix** - `aff59c5a` (fix)
2. **Task 2: close CR-01/CR-02 in the call-site sweep** - `584e41cc` (fix)
3. **Task 3: round-3 measurement artifact** - `0a408a50` (docs)

## Files Created/Modified

- `.github/workflows/ci.yml` - `verify-test` job's current-lane db-prep step gains the `ALTER DATABASE` statement (job `id:` `verify-test` and job `name:` `Run test suite` unchanged)
- `test/threadline/storage_schema_call_site_contract_test.exs` - `@call_regex` receiver clause widened, `@ecto_functions` extended, 8 new behaviour fixtures, strengthened real-tree non-vacuity assertion, moduledoc updated
- `.planning/phases/198-green-bringup/198-CI-MEASUREMENT.md` - new Round 3 section

## Decisions Made

- **`mix verify.example` does not reach literal 0 failures locally, and that is honestly reported rather than papered over.** Task 1's acceptance criterion text asked for `DB_HOST=localhost mix verify.example` to complete with 0 failures after the fix. Measured reality: across 3 independent local `verify.example` runs (one during Task 1, one standalone check, one inside the Task 3 `mix ci.all` run), the specific defect this plan's Task 1 targets — `Postgrex.Error 42P01 (undefined_table)` on `audit_transactions` — occurred **zero times**, confirming the fix works. But each run still showed 8-9 unrelated failures, all `ThreadlinePhoenix.DemoContractTest` / `ThreadlinePhoenixWeb.WalkthroughHappyPathTest` content-assertion mismatches (`Ecto.NoResultsError`, count mismatches) against `mix demo.seed`-generated data — a separate, pre-existing, non-deterministic defect class (failing test names differ run-to-run) already acknowledged in `deferred-items.md`'s Plan 198-12 entry as "the recurring 'example precommit demo-seed/walkthrough failures' pattern already acknowledged & deferred across Phases 177, 179, 180, and 182." Per the honesty requirement, this is recorded as the true state rather than silently declaring the acceptance criterion met.
- **`in_scope_count` baseline measured before touching the detector** (208, via a standalone script requiring the compiled test module) to make the "strictly increases" must_have falsifiable rather than asserted from memory. Post-fix: 270.
- **CR-01/CR-02 fixes proven red-then-green by literal revert-and-rerun**, not `git stash` (forbidden in worktree mode per destructive_git_prohibition). Each fix (regex change, ecto_functions change) was individually reverted via a temporary in-place edit, the failing fixtures captured, then restored from a saved copy of the fully-fixed file.

## Deviations from Plan

### Auto-fixed Issues

None — no Rule 1/2/3 auto-fixes were needed beyond what the plan already specified.

### Notable non-deviation: Task 1's literal acceptance criterion partially unmet

This is not a deviation in the Rule 1-4 sense (nothing was auto-fixed or architecturally changed) — it is an honest measurement discrepancy documented per the Decisions Made section above and the plan's own honesty_requirement. The defect Task 1 targets (`undefined_table`) is fully fixed and verified eliminated. A separate, already-deferred defect class (demo-seed content non-determinism) remains and was correctly identified as out of this plan's scope per Task 3's read_first instructions, which explicitly anticipated this exact failure mode ("If mix ci.all fails only at verify.example on the already-deferred example-app DemoContractTest demo-seed assertions, record that as the known, previously-acknowledged deferral").

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** None — the plan's real target (the `undefined_table` search_path bug and the CR-01/CR-02 sweep blind spots) is fully addressed and proven locally. The pre-existing demo-seed content flakiness is orthogonal, already tracked, and explicitly out of scope.

## Issues Encountered

- Root project dependencies (`deps/`, `_build/`) were not yet fetched/compiled in this fresh worktree. Ran `mix deps.get` and `mix compile --warnings-as-errors` before any test/measurement work — both succeeded cleanly (one warning surfaced from the `sweet_xml` dependency itself, not project code, unrelated to this plan).
- `mix verify.example`'s failure set is non-deterministic across runs (different `DemoContractTest`/`WalkthroughHappyPathTest` tests fail each time, 8-9 failures). This is consistent with the demo-seed content class already documented as flaky/order-dependent in `deferred-items.md` and is not caused by this plan's changes — confirmed by the complete absence of `undefined_table` errors in every run.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `.github/workflows/ci.yml`'s search_path fix and the sweep's CR-01/CR-02 closure are both committed and locally proven (red-then-green for the sweep; end-to-end + idempotent for the CI step).
- GREEN-04 is **NOT** marked Complete by this plan — per the plan's own success criteria, that verdict awaits the measured CI run in plan 198-21.
- Ready for plan 198-20 (decision checkpoint) and 198-21 (push + measured CI run).

## Self-Check: PASSED

- `.github/workflows/ci.yml` — FOUND
- `test/threadline/storage_schema_call_site_contract_test.exs` — FOUND
- `.planning/phases/198-green-bringup/198-CI-MEASUREMENT.md` — FOUND
- `.planning/phases/198-green-bringup/198-19-SUMMARY.md` — FOUND
- Commit `aff59c5a` (Task 1) — FOUND in `git log --oneline --all`
- Commit `584e41cc` (Task 2) — FOUND
- Commit `0a408a50` (Task 3) — FOUND
- Commit `f1af9a68` (Summary) — FOUND

---
*Phase: 198-green-bringup*
*Completed: 2026-08-28*
