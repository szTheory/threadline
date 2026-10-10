---
phase: 241-operational-evidence-and-policy-inspection
plan: "02"
subsystem: ui/operations
tags: [phoenix, liveview, evidence, proof-history, playwright, tdd]
requires:
  - phase: 240-connected-investigation-and-recovery
    provides: established operator context and recovery conventions
  - phase: 241-operational-evidence-and-policy-inspection
    provides: selected-schema unavailable-versus-empty state pattern from plan 01
provides:
  - retryable evidence-read failure state distinct from no-match and disabled access
  - selected subject/reference preserved through latest-to-history navigation
  - bounded evidence projection and recorded-snapshot claim boundary regression coverage
affects: [241-operational-evidence-and-policy-inspection, operator-evidence]
actuals:
  tokens: 7425
  tasks: 2
  commits: 4
plan_head_before: 3d723d9727faf7cd40ed53e9484997cfa76e0754
plan_head_after: c00cb3bff7f7abde8fd6d392ed7bdbf26c95c6f2
tech-stack:
  added: []
  patterns:
    - database connection failures map to unavailable only at the evidence read boundary
    - keep selected subject/reference context while evidence is loading, unavailable, or empty
    - preserve the fixed approved record projection and separate summary status from proof assessment
key-files:
  created:
    - .planning/phases/241-operational-evidence-and-policy-inspection/241-02-TDD-RED.json
    - .planning/phases/241-operational-evidence-and-policy-inspection/241-02-TDD-RED-NOMATCH.json
  modified:
    - lib/threadline/operator_surface/live/evidence_live.ex
    - test/threadline/operator_surface/live/evidence_live_test.exs
    - examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts
key-decisions:
  - "Rescue only DBConnection.ConnectionError at the evidence database-read boundary; leave unrelated errors visible for diagnosis."
  - "A successful empty lookup is scoped to the selected reference and does not imply absence of underlying activity."
  - "Proof history remains a view of recorded snapshots, not a claim of total capture completeness."
patterns-established:
  - "Keep read failure, disabled access, and successful no-match as separate evidence states."
  - "Verify sensitive host fields stay outside both rendered output and browser-visible attributes."
requirements-completed: [UIO-03]
coverage:
  - id: D1
    description: "Operators can distinguish unavailable evidence, disabled access, and a scoped no-match while following the selected subject/reference from latest evidence into bounded proof history."
    requirement: UIO-03
    verification:
      - kind: unit
        ref: "mix test test/threadline/operator_surface/live/evidence_live_test.exs (14 tests)"
        status: pass
      - kind: automated_ui
        ref: "Playwright operator-route-states.spec.ts, desktop-chromium and mobile-chromium (2 tests)"
        status: pass
    human_judgment: false
duration: 12min
completed: 2026-10-10
status: complete
---

# Phase 241 Plan 02: Evidence Availability and Proof History Summary

**Evidence reads now distinguish a retryable outage from a scoped no-match while preserving the selected reference and bounded proof-history claims.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-10-10T17:24:16Z
- **Completed:** 2026-10-10T17:36:28Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- A database connection failure renders a retryable unavailable state with the selected subject/reference intact; unrelated exceptions still propagate for diagnosis.
- Successful empty lookups use the approved subject/reference-scoped copy, separate from unavailable and disabled-access states.
- Evidence cards preserve the allowlisted projection, distinguish `summary_status` from proof assessment, and state that proof applies to recorded snapshots rather than total capture completeness.
- The mounted browser journey follows the latest projection to the same exact-reference history and checks long identifiers, narrow layouts, status meaning, and sensitive-field absence.

## Task Commits

Each task was committed atomically:

1. **Task 1: Give evidence reads a distinct retryable unavailable state** - `4b890ca6` (test), `5f782ca2` (test), `b0dc6828` (fix)
2. **Task 2: Prove latest evidence returns to the same subject-reference history** - `c00cb3bf` (test)

The plan metadata commit is separate.

## Files Created/Modified

- `lib/threadline/operator_surface/live/evidence_live.ex` - adds the narrow retryable database-read failure branch and approved unavailable/no-match copy.
- `test/threadline/operator_surface/live/evidence_live_test.exs` - covers unavailable, selected-reference retention, scoped no-match copy, and sensitive-field canaries.
- `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts` - covers the mounted latest-to-history route, responsive values, status boundaries, and rendered canary absence.
- `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts`, `operator-prove-mobile.spec.ts`, and `operator-responsive-mobile-first.spec.ts` - update selectors to the approved “View proof history” control label.
- `241-02-TDD-RED.json` and `241-02-TDD-RED-NOMATCH.json` - preserve machine-validated failing-test evidence for both new behaviors.

## Decisions Made

- Only `DBConnection.ConnectionError` at the evidence read boundary becomes an unavailable state; other errors are not hidden.
- A no-match result speaks only about the selected Threadline subject/reference.
- History and proof assessment remain bounded to recorded evidence and do not assert overall capture completeness.

## TDD Gate Compliance

- Both RED records passed `gsd-tools check tdd-red-evidence` with `RED_EVIDENCE_OK`.
- The normal focused ExUnit command passed after implementation: 14 tests, 0 failures.

## Deviations from Plan

### Browser invocation and existing selector updates

The plan's canonical `mix verify.example_browser` wrapper runs package-install commands, which are excluded by threat T-241-SC. The mounted desktop/mobile journey was run directly with the already-cached Playwright installation against the isolated loopback example server; no packages were installed. Three existing browser selectors were also updated to match the required “View proof history” label and were exercised in their focused desktop/mobile/responsive tests.

**Total deviations:** 1 verification invocation adjustment and 1 directly required browser-selector update.
**Impact on plan:** No product scope expanded; the required mounted journey and affected existing browser checks passed using cached dependencies.

## Verification

- Focused ExUnit: `MIX_DEPS_PATH=<cached-deps> MIX_BUILD_PATH=<phase-worktree-build> mix test test/threadline/operator_surface/live/evidence_live_test.exs` — **14 tests, 0 failures**.
- `mix format --check-formatted` for `evidence_live.ex` and `evidence_live_test.exs` — **passed**.
- E2E TypeScript: `./node_modules/.bin/tsc --noEmit --project tsconfig.json` — **passed**.
- Mounted Playwright route journey on desktop and mobile Chromium — **2 passed**.
- Existing affected browser checks: mobile evidence/redaction case **1 passed**, desktop export-context case **1 passed**, responsive route matrix **8 passed**.
- RED evidence classifier — **both records passed** as expected failing tests.
- Phase Wave 1 `mix ci.all` remains pending for the parent orchestrator, who will run it using an isolated temporary PostgreSQL 15 cluster and a no-install browser-cache path. This plan executor did not run the alias or install packages.

## Issues Encountered

- The full phase CI gate is intentionally left to the parent orchestrator, which has a supported PostgreSQL 15 and no-install browser-cache path. The focused ExUnit, formatting, TypeScript, and mounted browser checks above passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 241-02 is complete. Plan 241-03 is next in Wave 2 after the parent completes the required Wave 1 `mix ci.all` gate on PostgreSQL 15 with the no-install browser-cache path.

---
*Phase: 241-operational-evidence-and-policy-inspection*
*Completed: 2026-10-10*

## Self-Check: PASSED

- Summary exists at the expected plan path.
- Task commits `4b890ca6`, `5f782ca2`, `b0dc6828`, and `c00cb3bf` are ancestors of execution HEAD; the measured plan commit count is 4.
- Coverage classification passes and auto-covers D1 with passing unit and desktop/mobile browser evidence.
