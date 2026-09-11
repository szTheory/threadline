---
phase: 199-decouple
plan: "07"
subsystem: testing
tags: [exunit, git-index, sha256, fixtures, integrity]
requires: []
provides:
  - Git-index-derived sorted SHA-256 manifest contract for the operator-surface evidence corpus
  - Positive controls for tracked mutation, ignored-output independence, required roots, structured files, and dataset joins
affects: [199-08, fixture-migration, operator-surface-evidence]
actuals:
  tokens: 2462
  tasks: 2
  commits: 4
plan_head_before: 7fac4ba353b319d43681c6cc1acca1fff96ec58c
tech-stack:
  added: []
  patterns: [synthetic Git repository fixtures, tracked-membership manifests, mutation-positive controls]
key-files:
  created:
    - test/threadline/operator_surface/operator_surface_fixture_contract_test.exs
  modified: []
key-decisions:
  - "Manifest membership comes only from git ls-files; filesystem presence alone never grants evidence authority."
  - "Generated critic-score bytes remain invisible to integrity manifests until explicitly promoted into the Git index."
patterns-established:
  - "Synthetic-first fixture integrity: establish tracked membership, byte identity, structure, and joins before binding the contract to the live corpus."
requirements-completed: [DECOUPLE-02]
coverage:
  - id: D1
    description: "A real temporary Git repository proves sorted tracked-only SHA-256 manifest semantics, including the tracked critic-scores skeleton and exclusion of ignored output."
    requirement: DECOUPLE-02
    verification:
      - kind: integration
        ref: "test/threadline/operator_surface/operator_surface_fixture_contract_test.exs#manifest is derived from tracked evidence entries only"
        status: pass
    human_judgment: false
  - id: D2
    description: "Mutation controls prove tracked byte drift and broken joins are detected while ignored score creation, mutation, and removal leave the manifest byte-identical."
    requirement: DECOUPLE-02
    verification:
      - kind: integration
        ref: "mix test test/threadline/operator_surface/operator_surface_fixture_contract_test.exs"
        status: pass
    human_judgment: false
duration: 6 min
completed: 2026-09-11
status: complete
---

# Phase 199 Plan 07: Synthetic Fixture Integrity Contract Summary

**A Git-backed synthetic corpus now locks tracked-only, byte-exact manifest semantics and exercises the failure modes needed before the live fixture migration.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-09-11T04:34:33Z
- **Completed:** 2026-09-11T04:40:32Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Built a temporary repository containing representative ledger, scorecard, ARIA, golden, refute, tracked skeleton, and ignored generated-score entries.
- Derived deterministic dataset-relative manifest rows exclusively from `git ls-files`, with lowercase SHA-256 over each tracked file's exact bytes.
- Added positive controls proving tracked byte drift and explicit score promotion change the manifest, while ignored score churn does not.
- Added fail-closed validation for missing roots, required entries, malformed structured data, empty scorecard sets, ARIA pairs, and ledger/golden/refute references.

## Task Commits

Each task followed its own RED → GREEN cycle:

1. **Task 1 RED: tracked manifest contract** — `720cbc55` (`test`)
2. **Task 1 GREEN: Git-index manifest implementation** — `409f316f` (`feat`)
3. **Task 2 RED: mutation and join controls** — `c7161f9c` (`test`)
4. **Task 2 GREEN: corpus integrity validation** — `29e40ab4` (`feat`)

No refactor commit was needed; the GREEN implementations were already narrow test helpers.

## Files Created/Modified

- `test/threadline/operator_surface/operator_surface_fixture_contract_test.exs` — synthetic Git corpus, tracked manifest helper, structural/join validator, and mutation controls.

## Decisions Made

- Git index membership is the authority boundary; recursive filesystem enumeration is deliberately absent.
- Relative paths, rather than absolute temporary paths, are manifest identities so Plan 199-08 can compare pre/post-move corpora.
- The required critic-scores skeleton is immutable evidence, while ignored generated JSON is excluded until `git add --force` explicitly promotes it.

## TDD Gate Compliance

- **Task 1 RED:** `RED_EVIDENCE_OK`; the named manifest test failed on `[]` versus six indexed entries.
- **Task 1 GREEN:** targeted contract passed, then the tracer feedback rerun passed before Task 2 began.
- **Task 2 RED:** `RED_EVIDENCE_OK`; the named corpus-validation test failed because the placeholder returned `:ok` for an absent root.
- **Task 2 GREEN:** all four targeted tests passed.
- **Commit order:** `test → feat → test → feat`, verified from Git history.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced unsupported `mix test -x` option with supported fail-fast invocation**

- **Found during:** Task 1 RED verification
- **Issue:** The plan's command ends in `-x`, but the installed Mix test task rejects `-x` as an unknown option before discovering any test.
- **Fix:** Used `--max-failures 1` for intentional RED runs and the plain targeted `mix test` command for final GREEN verification.
- **Files modified:** None; execution-command correction only.
- **Verification:** Four tests ran and passed with zero failures; both RED records passed `gsd-tools check tdd-red-evidence`.
- **Committed in:** No source change required; recorded in `.planning/WINDOWS.md` entry 26.

---

**Total deviations:** 1 auto-fixed (1 blocking command correction).
**Impact on plan:** Verification retained the intended targeted and fail-fast semantics; product scope and fixture contract were unchanged.

## Issues Encountered

- The repository-local untracked `.tool-versions` selects Node only, so bare `mix` could not choose an installed Elixir/OTP pair. Verification ran with the already-installed `ASDF_ELIXIR_VERSION=1.19.5-otp-27` and `ASDF_ERLANG_VERSION=27.3.4.15`; the user-owned file was not modified.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 199-08 can bind this synthetic oracle to the live five-root migration and compare byte manifests across `git mv`.
- No live destination assertion was introduced early, and no corpus path or fixture byte was changed by this plan.

## Self-Check: PASSED

- Created contract file exists.
- All four RED/GREEN task commits exist.
- Targeted suite passes with 4 tests and 0 failures.
- Formatting check passes.
- No goal-blocking stubs or new unmodeled threat surface were found.

---
*Phase: 199-decouple*
*Completed: 2026-09-11*
