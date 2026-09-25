---
phase: 199-decouple
plan: 21
subsystem: testing
tags: [planning-independence, clean-clone, dialyzer, playwright, fail-closed-cleanup]

requires:
  - phase: 199-11
    provides: hardened safe-temp-tree cleanup primitive
  - phase: 199-14
    provides: committed Dialyzer CI topology and measured cold/cache-hit evidence
  - phase: 199-20
    provides: source-only Dialyzer warning ratchet and explicit generic-probe accounting
provides:
  - committed-state verifier that runs the complete aggregate with .planning physically absent
  - mutation-tested restoration and shared-cleanup failure handling
  - live source scanner for planning reads, streams, metadata probes, and directory enumeration
affects: [200-public-surface, 201-rendered-output, 202-release-0.10.0, ci-certification]

actuals:
  tokens: 6404
  tasks: 2
  commits: 11
plan_head_before: 146ed9ddfb4b4707272a41cdd69556f176eeed70

tech-stack:
  added: []
  patterns:
    - exact-HEAD no-local clone certification
    - quarantine-restore-before-contained-cleanup lifecycle
    - positive-control source dependency scanning

key-files:
  created:
    - bin/verify-planning-independent
    - test/threadline/planning_independence_contract_test.exs
  modified:
    - test/threadline/planning_dependency_contract_test.exs
    - mix.exs
    - test/threadline/ci_topology_contract_test.exs
    - examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts

key-decisions:
  - "Certify only an exact committed SHA in a no-local disposable clone; caller-local state never enters the target."
  - "Restore quarantined planning state before delegating all recursive removal authority to bin/safe-temp-tree."
  - "Keep the aggregate identical to the committed CI topology: Dialyzer uses dev artifacts and browser verification uses the desktop/mobile Chromium lane."
  - "Measure related browser geometry in one animation frame so certification retains its ordering threshold without cross-scroll-state flakiness."

patterns-established:
  - "Certification lifecycle: CERTIFIED_SHA -> PLANNING_STATUS=ABSENT -> aggregate -> AGGREGATE_RESULT -> PLANNING_RESTORED -> SAFE_TEMP_TREE_REMOVED."
  - "Restoration failure retains both clone and quarantine and reports a recovery path rather than attempting cleanup."

requirements-completed: [DECOUPLE-01, DECOUPLE-05, DECOUPLE-07, DECOUPLE-08]

coverage:
  - id: D1
    description: "The complete committed mix ci.all product passes in a disposable clone while .planning is physically unavailable."
    requirement: DECOUPLE-01
    verification:
      - kind: integration
        ref: "bin/verify-planning-independent at c45b77128a56a3fec407323b70f28c3a79371e29"
        status: pass
    human_judgment: false
  - id: D2
    description: "Planning restoration precedes contained cleanup on success and forced aggregate failure, while restoration failure preserves recovery artifacts."
    requirement: DECOUPLE-05
    verification:
      - kind: unit
        ref: "test/threadline/planning_independence_contract_test.exs"
        status: pass
      - kind: integration
        ref: "test/threadline/clean_checkout_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "The default source scanner rejects hidden planning reads and metadata probes, with injected-reference positive controls."
    requirement: DECOUPLE-07
    verification:
      - kind: unit
        ref: "test/threadline/planning_dependency_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D4
    description: "The full source-owned analyzer and browser topology remains executable without planning metadata."
    requirement: DECOUPLE-08
    verification:
      - kind: integration
        ref: "mix ci.all inside planning-free committed clone"
        status: pass
    human_judgment: false

duration: 1h 8m
completed: 2026-09-11
status: complete
---

# Phase 199 Plan 21: Planning-Independent Aggregate Certification Summary

**Exact-HEAD clean-clone certification now runs the complete source-owned aggregate with `.planning` absent and restores it before hardened contained cleanup on every safe exit.**

## Performance

- **Duration:** 1h 8m
- **Started:** 2026-09-11T20:35:37Z
- **Completed:** 2026-09-11T21:43:00Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Added `bin/verify-planning-independent`, which clones committed HEAD without local state, proves its SHA, quarantines `.planning`, prepares clean dependencies/PLTs, and runs the complete `mix ci.all` product.
- Proved restoration and cleanup behavior across success, aggregate failure, restoration failure, root/outside/caller/registered-worktree targets, symlink replacement, and caller sentinel controls.
- Kept the planning-dependency scanner live in the default suite and expanded it to detect reads, streams, opens, stats, existence/type probes, and directory enumeration.
- Certified commit `c45b77128a56a3fec407323b70f28c3a79371e29` with `.planning` physically absent: 1534 root tests, 114 example tests, zero Dialyzer errors, and 318 passing browser tests with 26 intentional skips.

## Task Commits

Each TDD task was committed through explicit RED and GREEN evidence:

1. **Task 1: Prove one committed aggregate run with planning absent**
   - `d914e5a3` — RED: planning-absence tracer
   - `3a0c1a01` — GREEN: committed aggregate verifier
   - `bfa2cb88` — format-gate repair
   - `17f28dd7` — clean aggregate setup and hidden planning-read repairs
   - `ed8ee783` — dev-surface Dialyzer alignment
   - `d6f3eb57` — committed CI browser-project alignment
2. **Task 2: Harden every failure path and prove the planning scanner remains live**
   - `660c1143` — RED: planning existence-probe blind spot
   - `404dce95` — GREEN: planning metadata-probe detection
   - `b89a88ed` — RED: restoration and mutation controls
   - `553e5972` — GREEN: fail-closed aggregate lifecycle
   - `c45b7712` — stable same-frame browser geometry certification

## TDD Gate Compliance

- **Task 1 RED:** `/tmp/threadline-199-21-task1-red-evidence.json` passed `gsd_run check tdd-red-evidence`; the contract failed because no command yet proved an aggregate run with planning absent.
- **Task 1 GREEN:** the focused contract passed and the tracer gate completed a planning-free full aggregate at `d6f3eb57fe83cd43950596f51f98dd8d3aff5a9b`.
- **Task 2 RED (scanner):** `/tmp/threadline-199-21-task2-scanner-red-evidence.json` passed `gsd_run check tdd-red-evidence`; an injected `File.exists?` planning probe escaped the original scan.
- **Task 2 GREEN (scanner):** the scanner rejected the injected metadata probe and remained clean on the real tracked source tree.
- **Task 2 RED (failure lifecycle):** `/tmp/threadline-199-21-task2-failure-red-evidence.json` passed `gsd_run check tdd-red-evidence`; forced aggregate/restoration/mutation controls exposed missing fail-closed behavior.
- **Task 2 GREEN:** all eight owned contracts passed, the seven-test shared cleanup matrix passed, and the final committed verifier exited zero.
- Refactoring occurred only after the relevant GREEN gate.

## Verification

### Owned contracts

- `mix test test/threadline/planning_independence_contract_test.exs test/threadline/planning_dependency_contract_test.exs --max-failures 1` — **8 tests, 0 failures**.
- `mix test test/threadline/clean_checkout_contract_test.exs --max-failures 1` — **7 tests, 0 failures**.
- Injected planning-read and `File.exists?` controls failed as intended; the unmodified real-source scan passed.
- Forced aggregate failure exited 73 and emitted `AGGREGATE_RESULT=FAIL status=73` before `PLANNING_RESTORED` and cleanup.
- Forced restoration failure exited 74, retained the clone and quarantine, and reported the manual recovery path.
- Symlink replacement exited 75; the original inode was restored, shared cleanup rejected the symlink, and outside/caller sentinels survived.

### Final planning-absent aggregate

The full transcript is retained locally at `/tmp/threadline-199-21-final-certification.log`.

- `CERTIFIED_SHA=c45b77128a56a3fec407323b70f28c3a79371e29`
- `PLANNING_STATUS=ABSENT`
- Root ExUnit: **1534 tests, 0 failures, 1 excluded**.
- Example ExUnit: **114 tests, 0 failures**.
- Dialyzer: **Total errors: 0, Skipped: 0, Unnecessary Skips: 0**.
- Playwright: **344 total; 318 passed, 26 skipped, 0 failed** across desktop Chromium and mobile Chromium.
- Exit status: **0**.
- Terminal order: `AGGREGATE_RESULT=PASS` -> `PLANNING_RESTORED` -> `SAFE_TEMP_TREE_REMOVED`.

The verifier checked `.planning` after quarantine and immediately before aggregate execution. No skip, tag, alternate alias, environment-conditioned bypass, or partial analyzer command was introduced.

## Files Created/Modified

- `bin/verify-planning-independent` — exact-SHA clone, quarantine, setup, aggregate, restoration, and shared-cleanup verifier.
- `test/threadline/planning_independence_contract_test.exs` — happy, failure, restoration, containment, symlink, and sentinel controls.
- `test/threadline/planning_dependency_contract_test.exs` — live planning dependency scanner and positive controls.
- `mix.exs` — aligns the local aggregate with committed dev-Dialyzer and two-project browser CI topology.
- `test/threadline/ci_topology_contract_test.exs` — locks the corrected aggregate topology.
- `test/threadline/removed_artifact_contract_test.exs` — excludes historical planning-only paths from shipped-source executable scanning.
- `test/threadline/operator_surface/stress_ledger_test.exs` — validates evidence references lexically without dereferencing quarantined planning files.
- `test/threadline/main_ci_observer_contract_test.exs` — formatter-only correction surfaced by the aggregate.
- `test/threadline/e2e_preflight_contract_test.exs` — formatter-only correction surfaced by the aggregate.
- `examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts` — samples related geometry atomically without relaxing its ordering contract.

## Decisions Made

- Used `git clone --no-local` and detached the exact recorded SHA so the certification target cannot inherit caller-local objects or uncommitted state.
- Made `bin/safe-temp-tree` the sole recursive cleanup authority; the verifier only owns quarantine/restoration sequencing.
- Prepared npm dependencies and the dev Dialyzer PLT explicitly because a genuinely fresh clone has neither.
- Matched `mix ci.all` to the checked-in CI lane rather than broadening browser projects or typechecking a different Mix environment.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Corrected pre-existing formatter drift exposed by the full aggregate**
- **Found during:** Task 1
- **Issue:** Two existing contract files failed the committed format gate in a clean clone.
- **Fix:** Applied formatter-only changes.
- **Files modified:** `test/threadline/main_ci_observer_contract_test.exs`, `test/threadline/e2e_preflight_contract_test.exs`
- **Committed in:** `bfa2cb88`

**2. [Rule 1/3 - Correctness] Removed hidden planning dereferences and supplied clean-clone prerequisites**
- **Found during:** Task 1
- **Issue:** Historical removed-artifact paths and stress-ledger evidence references still dereferenced `.planning`; clean npm dependencies and PLTs were also absent by design.
- **Fix:** Kept historical paths lexical, stopped stress-ledger physical planning reads, and added explicit npm/dev-PLT preparation.
- **Files modified:** `bin/verify-planning-independent`, `test/threadline/removed_artifact_contract_test.exs`, `test/threadline/operator_surface/stress_ledger_test.exs`
- **Committed in:** `17f28dd7`

**3. [Rule 1 - Correctness] Aligned aggregate analyzer and browser commands with the committed CI product**
- **Found during:** Task 1
- **Issue:** Dialyzer was invoked from the test environment and the browser alias expanded beyond the locked desktop/mobile CI lane.
- **Fix:** Run Dialyzer with `MIX_ENV=dev` and select exactly the two committed Chromium projects.
- **Files modified:** `mix.exs`, `test/threadline/ci_topology_contract_test.exs`, `bin/verify-planning-independent`
- **Committed in:** `ed8ee783`, `d6f3eb57`

**4. [Rule 1 - Bug] Eliminated a cross-scroll-state browser geometry race without weakening its threshold**
- **Found during:** Task 2 final aggregate
- **Issue:** Sequential visibility/box calls could measure verdict and reference positions from different scroll states; one full run failed both attempts despite the layout contract being intact.
- **Fix:** Assert both elements visible, then sample both bounding rectangles in a single browser evaluation frame.
- **Files modified:** `examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts`
- **Verification:** Focused test passed 3/3; subsequent full 344-case lane passed 318 with 26 intentional skips.
- **Committed in:** `c45b7712`

**Total deviations:** 4 auto-fixed (2 Rule 1, 1 Rule 3, 1 combined Rule 1/3).
**Impact on plan:** Every change was required for the exact committed aggregate to be truthful in a clean planning-free clone. No gate was weakened and no remote workflow was published or dispatched.

## Preserved Evidence and Scope Boundaries

- Plan 199-14's measured source SHA `a4f21e7e`, runs `34642915672` / `34643744220`, jobs `103406722917` / `103410179816`, and nine-minute timeout remain unchanged.
- No `.github/workflows` file changed, and no additional remote run was published or dispatched.
- Plan 199-20's 15 generic spec-less probes remain explicitly flagged and unresolved; this integration proof does not claim otherwise.

## Authentication Gates

None. Hex reported an expired user session but continued successfully against public locked dependencies; no private resource or manual authentication was required.

## Known Stubs

None. The created and modified files contain no goal-blocking placeholder, TODO, FIXME, empty-data, or unwired-component stub.

## Threat Flags

None. All new filesystem trust-boundary behavior is covered by the plan's threat register; no network endpoint, auth path, schema, or additional file-access surface was introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 199's final certification is complete. Phase 200 can proceed from a source-owned, planning-independent aggregate while preserving the explicit 15-probe limitation recorded by Plan 199-20.

## Self-Check: PASSED

- All ten implementation files exist at committed SHA `c45b7712`.
- All eleven implementation commits resolve from ledger base `146ed9ddfb4b4707272a41cdd69556f176eeed70`.
- All three RED evidence files pass the GSD RED-evidence check.
- Final aggregate evidence proves `.planning` absent and exits zero before restoration and contained cleanup.

---
*Phase: 199-decouple*
*Completed: 2026-09-11*
