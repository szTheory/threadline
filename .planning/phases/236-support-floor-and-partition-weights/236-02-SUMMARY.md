---
phase: 236-support-floor-and-partition-weights
plan: 02
subsystem: ci
tags: [elixir, postgresql, exunit, test-partitions]
requires:
  - phase: 236-01
    provides: PostgreSQL 15 minimum, source-derived support policy, and guide contract.
provides:
  - A contract that requires exactly one sorted weight for every discovered test file.
  - A complete 265-file partition-weight inventory.
  - PostgreSQL 15 partitioned-suite and aggregate CI evidence.
affects: [237-upgrade-guide-and-1-0-0]
actuals:
  tokens: 11193
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns:
    - Compare the committed partition-weight paths with the same nonhidden find inventory used by the runner.
    - Measure tests excluded from the ordinary suite through their actual CI topology before recording a weight.
key-files:
  created: []
  modified:
    - test/threadline/ci_topology_contract_test.exs
    - test/threadline/ci_workflow_parity_contract_test.exs
    - test/threadline/guides/upgrade_path_contract_test.exs
    - test/partition_weights.txt
    - .planning/phases/236-support-floor-and-partition-weights/236-VALIDATION.md
    - .planning/phases/236-support-floor-and-partition-weights/236-01-PLAN.md
    - .planning/phases/236-support-floor-and-partition-weights/236-02-PLAN.md
key-decisions:
  - "Keep the runner's median fallback and exactly-once assignment behavior unchanged; the new contract governs committed measurements only."
  - "Measure the normally excluded PgBouncer test through its real transaction-pooling setup and record its observed 113.5 ms as 114 ms."
requirements-completed: [CI-01, FLOOR-01, FLOOR-02]
coverage:
  - id: D1
    description: Every discovered test file has one unique, sorted integer weight, and an omitted real path is named by the failing contract.
    requirement: CI-01
    verification:
      - kind: unit
        ref: test/threadline/ci_topology_contract_test.exs#committed partition weights cover the complete test inventory
        status: pass
      - kind: integration
        ref: DB_HOST=127.0.0.1 DB_PORT=55433 mix verify.test_partitioned (265 files; 3,051 tests; 0 failures)
        status: pass
    human_judgment: false
  - id: D2
    description: The sorted weights file covers all 265 test paths, including the PgBouncer-only topology file.
    requirement: CI-01
    verification:
      - kind: integration
        ref: bin/ci-test-partitions --write-weights (264 standard-suite paths) plus measured PgBouncer topology module (114 ms)
        status: pass
      - kind: unit
        ref: test/threadline/ci_topology_contract_test.exs#committed partition weights cover the complete test inventory
        status: pass
    human_judgment: false
  - id: D3
    description: The source-derived PostgreSQL 15 floor, adopter guide, weights, and complete verification gate are proven against PostgreSQL 15.18.
    requirement: FLOOR-01
    verification:
      - kind: integration
        ref: "SHOW server_version_num = 150018; final mix ci.all exit 0; root 32 properties + 3,051 tests/0 failures (3 excluded), example 132/0, Dialyzer passed, browser 317 passed/26 skipped (1 flaky passed on retry)"
        status: pass
    human_judgment: false
  - id: D4
    description: The single support-policy table remains aligned with Mix, .tool-versions, CI, README, and the Unreleased PostgreSQL 14 upgrade action.
    requirement: FLOOR-02
    verification:
      - kind: unit
        ref: test/threadline/guides/upgrade_path_contract_test.exs (2 tests; 0 failures)
        status: pass
      - kind: integration
        ref: mix ci.all (exit 0)
        status: pass
    human_judgment: false
---

# Phase 236 Plan 02 Summary

**Every one of the 265 discovered test files now has a measured partition weight, and the full gate passes on PostgreSQL 15.18.**

## Performance

- **Duration:** 62 min
- **Started:** 2026-10-07T16:57:30Z
- **Completed:** 2026-10-07T17:59:44Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added a pure inventory contract that rejects malformed, duplicate, unsorted, missing, and stale weight rows. Its omission mutation removes a real discovered path and asserts that the error names that path.
- Regenerated 264 ordinary-suite measurements and separately timed the normally excluded PgBouncer topology module at 113.5 ms. The final file has 265 sorted paths and passes the inventory contract.
- Passed the four-partition suite on PostgreSQL 15.18 (3,051 tests, 0 failures) and the final complete `mix ci.all` gate (exit 0): root 32 properties + 3,051 tests (0 failures, 3 excluded), example 132 tests (0 failures), Dialyzer clean, and browser 317 passed/26 skipped with one flaky case passing on retry.
- Closed the roadmap's same-commit CI/topology-contract criterion in `5895d39d`; its deletion mutation failed before the CI pointer was added, and the focused topology/parity contracts passed afterward (74 tests, 0 failures).
- Recorded the PostgreSQL version, partition counts, aggregate gate results, and Nyquist task statuses in `236-VALIDATION.md`.

## Task Commits

1. **Task 1: Require measured weights for every test file and regenerate them** — RED contract `d782a54f`; complete measured weights `036d614e`.
2. **Task 2: Prove the complete gate against PostgreSQL 15 and record it** — validation evidence is committed with the plan summary and close-out metadata.

Additional corrective commits required by the full gate: `18d44e20` (update two stale PostgreSQL 14 parity assertions), `05cad81a` (remove two Credo warnings in the Plan 01 guide contract), and `d6ad94d8` (replace machine-specific plan paths with the repository's documented placeholder).

## Files Created or Modified

- `test/threadline/ci_topology_contract_test.exs` — inventory parser, exact path-set checks, malformed/duplicate/order checks, and omission control.
- `test/partition_weights.txt` — complete sorted measurements for 265 test files.
- `test/threadline/ci_workflow_parity_contract_test.exs` — minimum-lane parity contract now expects PostgreSQL 15.
- `test/threadline/guides/upgrade_path_contract_test.exs` — Credo-safe existence checks for the source-derived guide contract.
- `236-VALIDATION.md` — PostgreSQL 15 execution evidence and passing Nyquist map.
- `236-01-PLAN.md`, `236-02-PLAN.md` — portable GSD execution references.

## Decisions Made

- The partition runner's median fallback and `verify_assignment` exactly-once invariant remain unchanged; the new test checks committed measurement completeness separately.
- The default writer cannot time `pgbouncer_topology_test.exs` because that file is excluded unless PgBouncer topology mode is enabled. It was measured through the project's transaction-pooling setup instead of assigning a guessed value.

## Deviations from Plan

### Auto-fixed Issues

**1. Existing CI parity assertions still required PostgreSQL 14**
- **Found during:** Task 1's full traced weight run.
- **Issue:** Two `ci_workflow_parity_contract_test.exs` assertions contradicted Plan 01's new PostgreSQL 15 minimum and caused the full run to fail.
- **Fix:** Updated the minimum-row expected value and fixture to PostgreSQL 15.
- **Verification:** The parity contract passed (49 tests, 0 failures) and the final full gate passed.
- **Committed in:** `18d44e20`.

**2. Credo rejected two count expressions in the new guide contract**
- **Found during:** The first aggregate-gate attempt.
- **Fix:** Replaced existence counts with `Enum.any?/2` predicates.
- **Verification:** `mix verify.credo` passed with no issues; the guide contract passed.
- **Committed in:** `05cad81a`.

**3. Repository hygiene rejected concrete home paths in the plan execution references**
- **Found during:** The second aggregate-gate attempt.
- **Fix:** Replaced the machine-specific path segment with `/Users/<user>` as prescribed by `CONTRIBUTING.md`.
- **Verification:** `mix verify.repo_hygiene` reported 4,667 tracked text files clean.
- **Committed in:** `d6ad94d8`.

**4. The default timing run omits the PgBouncer-only test file**
- **Found during:** Weight inventory comparison after the canonical writer completed.
- **Fix:** Ran the two tests through the project's transaction-pooling PgBouncer setup against the PostgreSQL 15 server and recorded the observed 113.5 ms module time as 114 ms.
- **Verification:** Both topology tests passed; final inventory contract found all 265 paths.
- **Committed in:** `036d614e`.

**Total deviations:** 4 necessary corrections or measurement accommodations.
**Impact on plan:** The additions close existing parity, lint, hygiene, and measurement gaps required for the planned full gate. Runner behavior and phase scope stayed unchanged.

## Issues Encountered

- Port 55432 was occupied by an unrelated PostgreSQL 16 container, so the isolated PostgreSQL 15 service used port 55433. A fresh `/private/tmp` `TMPDIR` avoided a pre-existing shared-temp path collision in one clean-checkout test. The final aggregate command exited 0.
- An intermediate aggregate rerun had a desktop stress-route login timeout on both attempts; that case passed alone, the full browser gate passed on rerun, and the subsequent integrated `mix ci.all` passed. The final browser run reported one flaky case that passed on retry (317 passed, 26 skipped).
- TDD RED evidence is recorded in `.planning/tmp/236-02-red.json`; `gsd-tools check tdd-red-evidence` returned `RED_EVIDENCE_OK` for the exact inventory contract before the weight file was regenerated.

## User Setup Required

None. The PostgreSQL 15 and PgBouncer containers were started for verification; the PostgreSQL 15 service remains running for local reuse.

## Next Phase Readiness

Phase 236's support-floor and partition-weight deliverables are ready for phase-level review and verification. All three requirements have passing automated evidence, with no manual-only checks.

---
*Phase: 236-support-floor-and-partition-weights*
*Completed: 2026-10-07*
