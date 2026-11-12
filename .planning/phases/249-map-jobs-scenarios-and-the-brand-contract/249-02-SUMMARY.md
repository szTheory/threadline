---
phase: 249-map-jobs-scenarios-and-the-brand-contract
plan: "02"
subsystem: demo-fixtures
tags: [elixir, phoenix, ecto, postgresql, demo-fixtures, walkthrough]

requires: []
provides:
  - Corrected preceding-Tuesday anchor across the manifest, walkthrough filters, and generated export CSV.
  - A reset-only clean E2E setup recipe with the existing production guard and advisory-lock protections retained.
affects: [phase-249-plan-03, demo-seed-workflows, walkthrough-fixtures]

actuals:
  tokens: 2295
  tasks: 3
  commits: 7
  plan_head_before: fc6afadfcb0634f5df78e52e52d5220e08ef420c
  plan_head_after: b6fdf6cf570467d06a99174dad98842c7af5f5a9

tech-stack:
  added: []
  patterns:
    - Exact literal calendar assertions pin the source and documentation independently.
    - A source-recipe test isolates E2E clean setup and uses an in-memory duplicate-seed negative control.

key-files:
  created: []
  modified:
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/manifest.ex
    - examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_test.exs
    - examples/threadline_phoenix/DEMO-MANIFEST.md
    - examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_contract_test.exs
    - examples/threadline_phoenix/WALKTHROUGH.md
    - examples/threadline_phoenix/test/threadline_phoenix/walkthrough_doc_contract_test.exs
    - examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs
    - examples/threadline_phoenix/e2e/run-e2e.sh
    - examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs

key-decisions:
  - "Keep the fixed May 27 2026 12:00Z epoch and private fixture identities; correct only the preceding Tuesday anchor to May 26 2026 14:30Z."
  - "Use mix demo.reset for clean setup; document mix demo.seed as a separate guarded in-place operation without a general idempotence promise."

requirements-completed: [ADM-06, ADM-07]

coverage:
  - id: D1
    description: "The source and manifest agree on the real Tuesday anchor while preserving the Wednesday epoch and fixture identities."
    verification:
      - kind: unit
        ref: "mix test test/threadline_phoenix/demo_manifest_test.exs test/threadline_phoenix/demo_manifest_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Walkthrough date filters and the generated downloadable CSV use the corrected instant."
    verification:
      - kind: integration
        ref: "mix test test/threadline_phoenix/walkthrough_doc_contract_test.exs test/threadline_phoenix/demo_contract_test.exs test/threadline_phoenix_web/walkthrough_happy_path_test.exs test/threadline_phoenix_web/walkthrough_evidence_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "The E2E clean-setup region runs reset once, and the contract rejects an injected second seed command."
    verification:
      - kind: unit
        ref: "mix test test/threadline_phoenix/demo_manifest_contract_test.exs test/threadline_phoenix/demo_reset_test.exs test/threadline_phoenix/demo/advisory_lock_pinning_test.exs"
        status: pass
      - kind: other
        ref: "bash -n examples/threadline_phoenix/e2e/run-e2e.sh"
        status: pass
    human_judgment: false
  - id: D4
    description: "Direct seeding remains a separate guarded in-place operation; the existing repeat test is limited to its fixture sequence not raising."
    verification:
      - kind: unit
        ref: "mix test test/threadline_phoenix/demo_manifest_contract_test.exs test/threadline_phoenix/demo_reset_test.exs test/threadline_phoenix/demo/advisory_lock_pinning_test.exs"
        status: pass
      - kind: integration
        ref: "mix test test/threadline_phoenix/demo_contract_test.exs"
        status: pass
    human_judgment: false

duration: 20min
completed: 2026-11-11
status: complete
---

# Phase 249 Plan 02: Map jobs, scenarios and the brand contract Summary

**Corrected the Tuesday anchor through the manifest, walkthrough and generated export, and made E2E clean setup reset once while retaining guarded direct seeding.**

## Performance

- **Duration:** About 20 minutes; preparation began before the first retained task timestamp.
- **Started:** 2026-11-11T19:25:49-05:00 (first task commit; earlier setup and reading were not timestamped).
- **Completed:** 2026-11-12T00:42:56Z.
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Corrected the fixed preceding-Tuesday instant to May 26 2026 14:30Z while retaining the May 27 2026 12:00Z epoch and stable semantic fixture identities.
- Updated walkthrough date consumers and verified the real completed export file contains the exact corrected CSV timestamp.
- Removed the E2E runner's duplicate seed command; documented reset as clean setup and direct seed as a separate guarded in-place operation.
- Added a source-recipe negative control for duplicate seeding and an explicit production refusal check for direct seed.

## Task Commits

1. **Task 1: Correct calendar anchor and manifest contract** - `eb5bddfe` (test), `bac9cbdd` (fix).
2. **Task 2: Reconcile walkthrough and export consumers** - `418b8484` (test), `dd124f05` (docs).
3. **Task 3: Make reset the sole clean setup** - `27af9090` (test), `491834d5` (test), `b6fdf6cf` (fix).

**Plan metadata:** this summary is committed separately after its contents are written; the metadata commit is reported by the executor.

## Files Created/Modified

- `examples/threadline_phoenix/lib/threadline_phoenix/demo/manifest.ex` - corrected the Tuesday anchor.
- `examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_test.exs` - pins the exact instant and weekday.
- `examples/threadline_phoenix/DEMO-MANIFEST.md` - corrected the calendar row and clean/direct seed recipes.
- `examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_contract_test.exs` - covers date and recipe contracts.
- `examples/threadline_phoenix/WALKTHROUGH.md` - aligned date filters and appendix timestamps.
- `examples/threadline_phoenix/test/threadline_phoenix/walkthrough_doc_contract_test.exs` - pins walkthrough dates and epoch.
- `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` - checks generated export CSV bytes.
- `examples/threadline_phoenix/e2e/run-e2e.sh` - invokes reset once before entering the browser runner.
- `examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs` - checks reset-only recipe, duplicate-seed negative control, and direct-seed production guard.

## Decisions Made

- The fixed epoch and semantic fixture identities remain stable; only the preceding-Tuesday anchor and its exact consumers changed.
- Clean setup uses `mix demo.reset`, which already truncates and reseeds. Direct `mix demo.seed` remains available as a guarded in-place operation. The existing reset-then-seed regression proves only that its fixture sequence does not raise, not general idempotence.

## Verification

- Task 1 focused calendar tests: 14 tests, 0 failures.
- Task 2 walkthrough, export, and flow tests: 39 tests, 0 failures; the test reads the generated CSV bytes after reset.
- Task 3 manifest, reset, and advisory-lock tests: 17 tests, 0 failures.
- Direct-seed production guard test: 5 tests, 0 failures (4 excluded by the line-targeted run).
- Example formatter check passed for both modified ExUnit files.
- Example `mix compile --warnings-as-errors` passed.
- `bash -n examples/threadline_phoenix/e2e/run-e2e.sh` passed. The E2E/browser runner was not executed.
- Checks used the task-owned PostgreSQL 15.17 service and partition `p24902`; the shared PostgreSQL port 5432 was not used. Root and example lockfile hashes remained unchanged.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

- The first dependency-restore attempt used `mix -C`, which this installed Mix version does not support. Dependency restoration succeeded when run from the example project directory using the existing locked dependencies; no lockfile changed.
- The first calendar-test draft called an unavailable weekday helper. It was corrected to `Date.day_of_week/1` before accepting the intended red run; the focused suites then passed.
- Test-first runs intentionally failed on the old calendar/documentation and duplicate-seed contracts before the implementation commits. Final focused runs passed. Existing shape-fixture migration module redefinition warnings appeared during ExUnit runs; the warning-as-error example compile passed.

## User Setup Required

None - no external service configuration is required.

## Next Phase Readiness

Plan 02 outputs are ready for the remaining phase work. No runtime brand, font, style, artwork, public API, route, or schema scope changed. Browser acceptance was not claimed. The parent owns shared STATE.md, ROADMAP.md, and REQUIREMENTS.md updates; none were edited here.

## Self-Check: PASSED

- All nine task files exist.
- All seven task commits are ancestors of the final task-code HEAD.
- The evaluation-scope resolver found seven commits for plan 249-02 on this branch.
- The task-level focused tests and plan verification checks passed.

---
*Phase: 249-map-jobs-scenarios-and-the-brand-contract*
*Completed: 2026-11-11*
