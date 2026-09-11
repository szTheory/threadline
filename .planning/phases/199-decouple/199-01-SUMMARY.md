---
phase: 199-decouple
plan: "01"
subsystem: testing
tags: [elixir, exunit, mechanical-checker, fail-closed, explicit-inputs]

requires: []
provides:
  - Repository-independent MechanicalChecker.run/1 requiring explicit scorecard and floor inputs
  - Distinct fail-closed errors for absent, unreadable, empty, and malformed scorecard corpora
affects: [199-02, 199-05, 199-08, verify-mechanical]

actuals:
  tokens: 4340
  tasks: 2
  commits: 4
plan_head_before: dac2925dd82bd8b671b5fa3637d514edbc75465c

tech-stack:
  added: []
  patterns: [explicit evidence inputs, validate-before-evaluate, actionable tagged errors]

key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/mechanical_checker.ex
    - test/threadline/operator_surface/mechanical_checker_test.exs

key-decisions:
  - "MechanicalChecker owns evaluation only; repository fixture discovery remains at test and tooling edges."
  - "Corpus availability and parse failures use distinct tagged tuples with absolute paths, repository_only: false, and one recovery call."

patterns-established:
  - "Explicit-input boundary: callers must provide both scorecard_dir and mechanical_floors."
  - "Non-vacuity gate: validate a non-empty decoded corpus before running mechanical arithmetic."

requirements-completed: [DECOUPLE-01]

coverage:
  - id: D1
    description: "MechanicalChecker evaluates a caller-supplied synthetic scorecard and has no repository evidence defaults."
    requirement: DECOUPLE-01
    verification:
      - kind: integration
        ref: "test/threadline/operator_surface/mechanical_checker_test.exs#run/1 over an all-passing scorecard returns {:ok, []}"
        status: pass
      - kind: other
        ref: "source scan for repository locators and implicit floor loading"
        status: pass
    human_judgment: false
  - id: D2
    description: "Missing inputs and absent, unreadable, empty, or malformed corpora fail closed with actionable tagged errors."
    requirement: DECOUPLE-01
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/mechanical_checker_test.exs#invalid-input and invalid-corpus cases"
        status: pass
      - kind: integration
        ref: "mix test test/threadline/operator_surface/mechanical_checker_test.exs --max-failures 1 (27 tests, 0 failures)"
        status: pass
    human_judgment: false

duration: 11 min
completed: 2026-09-11
status: complete
---

# Phase 199 Plan 01: Fail-Closed Mechanical Checker Summary

**Explicit-input mechanical evaluation that rejects missing, empty, unreadable, and malformed evidence before any corpus can pass vacuously**

## Performance

- **Duration:** 11 min
- **Started:** 2026-09-11T03:10:23Z
- **Completed:** 2026-09-11T03:21:24Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Removed the runtime module's repository-relative scorecard and ledger defaults; `run/1` now requires both explicit inputs through `Keyword.fetch/2`.
- Added distinct, actionable tagged errors for absent, unreadable, empty, and malformed scorecard corpora, all carrying the expanded path and `repository_only: false`.
- Preserved MODE-A/MODE-B arithmetic and violation tuples while proving a clean corpus and real violations execute non-vacuously.

## Task Commits

Each task followed a RED→GREEN TDD cycle:

1. **Task 1 RED: Require explicit mechanical evidence inputs** - `02a6fd4d` (test)
2. **Task 1 GREEN: Require explicit mechanical evidence** - `f168951c` (feat)
3. **Task 2 RED: Cover invalid mechanical corpora** - `18679898` (test)
4. **Task 2 GREEN: Fail closed on invalid scorecard corpora** - `7f87e5f5` (feat)

## Files Created/Modified

- `lib/threadline/operator_surface/mechanical_checker.ex` - Explicit input contract, validated corpus loading, error taxonomy, and unchanged evaluation pipeline.
- `test/threadline/operator_surface/mechanical_checker_test.exs` - Synthetic clean/violation controls plus missing-input and adversarial corpus coverage.

## Decisions Made

- Kept repository path knowledge out of the shipped checker. Current repository-owned tests supply the existing corpus and decoded floors explicitly until later Phase 199 adapter/migration plans move that responsibility.
- Used stable tags (`missing_input`, `missing_corpus`, `unreadable_corpus`, `empty_corpus`, `malformed_scorecard`) so callers can distinguish recovery paths without parsing prose.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced unsupported `mix test -x` verification flag**

- **Found during:** Baseline verification before Task 1
- **Issue:** The installed Mix 1.19.5 CLI rejects `-x` as an unknown option, so the literal plan command could not execute any tests.
- **Fix:** Used `--max-failures 1`, the supported fail-fast equivalent, while keeping the same test file and failure semantics.
- **Files modified:** None
- **Verification:** `mix test test/threadline/operator_surface/mechanical_checker_test.exs --max-failures 1` completed with 27 tests and 0 failures.
- **Committed in:** No source change required

---

**Total deviations:** 1 auto-fixed (1 blocking verification-command correction).
**Impact on plan:** No product or test scope changed; the corrected command exercises the exact planned suite.

## Issues Encountered

- Repository-wide `mix verify.format` remains red on four pre-existing Phase 198 test files outside this plan. Neither plan-owned file has formatter drift; direct `mix format --check-formatted` over both passes. The unrelated paths are recorded in `deferred-items.md` and were not modified.

## TDD Gate Compliance

- **Task 1 RED:** `RED_EVIDENCE_OK` — the explicit-scorecard-input test failed because the old checker returned `{:ok, []}` from its hidden default.
- **Task 1 GREEN:** Focused suite passed before commit `f168951c`.
- **Task 2 RED:** `RED_EVIDENCE_OK` — the empty-corpus test failed because the old loader passed with `{:ok, []}`.
- **Task 2 GREEN:** Focused suite passed before commit `7f87e5f5`.
- **Commit order:** `test → feat → test → feat`; no refactor commit was needed after the green implementation.

## Verification

- `mix test test/threadline/operator_surface/mechanical_checker_test.exs --max-failures 1` — **PASS**, 27 tests, 0 failures.
- `mix format --check-formatted lib/threadline/operator_surface/mechanical_checker.ex test/threadline/operator_surface/mechanical_checker_test.exs` — **PASS**.
- Runtime source scan for repository locators, implicit floor loading, and fail-open evidence-loader branches — **PASS**.
- `mix verify.format` — **FAIL outside plan scope** on four unchanged Phase 198 test files; recorded in the phase deferred-items register.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for Plan 199-02 to introduce repository-owned Elixir evidence adapters and update remaining callers to the explicit contract.
- No blocker exists in the checker itself; the pre-existing repository-wide formatter drift remains independently deferred.

## Self-Check: PASSED

- Both modified implementation/test files and this summary exist on disk.
- All four TDD task commits are present in git history.
- Coverage metadata classifies both deliverables as fully automated and passing.

---
*Phase: 199-decouple*
*Completed: 2026-09-11*
