---
phase: 241-operational-evidence-and-policy-inspection
plan: "01"
subsystem: ui/operations
tags: [phoenix, liveview, operator-ui, coverage, schema, playwright]
requires:
  - phase: 238-current-main-preview-and-acceptance-baseline
    provides: source-bound route and state acceptance baseline
  - phase: 239-investigation-entry-and-transaction-composition
    provides: shared operator presentation patterns
  - phase: 240-connected-investigation-and-recovery
    provides: established operator context and recovery conventions
provides:
  - truthful selected-schema coverage outcomes and a retry path
  - safe schema-qualified migration guidance with exact-name manual fallback
  - mounted browser coverage for the uncovered-schema remediation journey
affects: [241-operational-evidence-and-policy-inspection, operator-coverage]
actuals:
  tokens: 9125
  tasks: 2
  commits: 3
plan_head_before: 888e429a24577b38862bf945d95e6d782e36f338
plan_head_after: f03354d8595856d8f1094e1a855222dce8ce1331
tech-stack:
  added: []
  patterns:
    - selected-schema reads distinguish healthy, confirmed-empty, stale, and unavailable outcomes
    - migration commands are generated only for safe schema and table identifiers
key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/components/surface_header.ex
    - lib/threadline/operator_surface/coverage/on_mount.ex
    - lib/threadline/operator_surface/live/coverage_live.ex
    - lib/threadline/operator_surface/presentation.ex
    - test/threadline/operator_surface/live/coverage_live_test.exs
    - test/threadline/operator_surface/presentation_test.exs
    - examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts
key-decisions:
  - "A failed read is unavailable, and a failed refresh with same-schema last-good data is stale; neither is confirmed-empty."
  - "The operator topbar reflects the same selected-schema read outcome as the coverage page."
  - "Unsafe identifiers retain exact display values and use host-owned manual migration guidance instead of a generated command."
patterns-established:
  - "Preserve selected schema context during loading, read failure, and retry."
  - "Keep host authorization and validation authoritative; render safe error copy without raw exceptions."
requirements-completed: [UIO-02]
coverage:
  - id: D1
    description: "Operators can distinguish selected-schema coverage gaps, confirmed-empty results, stale last-good rows, and unavailable reads, then reach safe host-migration guidance."
    requirement: UIO-02
    verification:
      - kind: unit
        ref: "mix test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/coverage/on_mount_test.exs (81 tests)"
        status: pass
      - kind: automated_ui
        ref: "Playwright operator-coverage-readiness.spec.ts, desktop-chromium and mobile-chromium (14 tests)"
        status: pass
    human_judgment: false
duration: 25min
completed: 2026-10-10
status: complete
---

# Phase 241 Plan 01: Selected-Schema Coverage and Remediation Summary

**Selected-schema coverage now separates confirmed-empty results from unavailable reads and stale last-good data, and gives operators safe host-migration guidance.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-10-10T16:51:21Z
- **Completed:** 2026-10-10T17:16:44Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Coverage remediation names the selected schema and table. Generator-safe identifiers produce a schema-qualified command; unsafe identifiers retain their exact names and receive the manual host-migration path.
- Initial and changed-schema read errors render an unavailable state with selected-schema context and retry. A same-schema refresh error retains last-good rows and their observation time while marking them stale.
- The topbar coverage signal follows the selected-schema read result, preventing a failed read from appearing as healthy or confirmed-empty.
- Mounted desktop and mobile browser coverage exercises the selected-schema path from an uncovered table to host-migration guidance.

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer: inspect one selected schema and reach its safe migration handoff** - `a325b8fa` (test), `d2b6c479` (feat)
2. **Task 2: Separate failed coverage reads from empty and stale last-known results** - `f03354d8` (fix)

The final metadata commit is separate; its hash is reported by the executor after creation.

## Files Created/Modified

- `lib/threadline/operator_surface/presentation.ex` - schema-qualified command generation and manual fallback.
- `lib/threadline/operator_surface/live/coverage_live.ex` - selected-schema outcomes, stale/unavailable states, and retry rendering.
- `lib/threadline/operator_surface/coverage/on_mount.ex` - polling and topbar outcome consistent with the selected schema.
- `lib/threadline/operator_surface/components/surface_header.ex` - safe labels for unavailable and failed-refresh outcomes.
- `test/threadline/operator_surface/live/coverage_live_test.exs` - failure, empty, stale, schema-change, retry, and row-state coverage.
- `test/threadline/operator_surface/presentation_test.exs` - safe command and manual fallback cases.
- `examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts` - mounted remediation journey.

## Decisions Made

- Confirmed-empty requires a successful selected-schema read. A failed first read remains unavailable, and a failed refresh with same-schema last-good data remains stale.
- Topbar and page verdicts use the same selected-schema read outcome.
- Generated shell guidance requires both schema and table names to pass the existing conservative safety check; other names use the manual path.

## Deviations from Plan

### Verification invocation adjustment

The canonical `mix verify.example_browser` wrapper was not invoked because it runs dependency/package installation steps, which this plan's threat model explicitly excludes. The mounted Playwright journey was run directly against the example built from this executor worktree, using cached dependencies and browser tooling; no packages were installed. A temporary symlink to the cached Playwright installation was removed after the run.

**Total deviations:** 1 verification invocation adjustment; no implementation scope changes.
**Impact on plan:** The required mounted desktop/mobile journey ran successfully without package installation.

## Verification

- Focused ExUnit command, using the cached dependency/build paths and test partition:
  `MIX_DEPS_PATH=<cached-deps> MIX_BUILD_PATH=<phase-worktree-build> MIX_TEST_PARTITION=operator_241_01 mix test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/coverage/on_mount_test.exs` — **81 tests, 0 failures**.
- `MIX_DEPS_PATH=<cached-deps> MIX_BUILD_PATH=<phase-worktree-build> mix verify.format` — **passed**.
- Mounted browser command from `examples/threadline_phoenix`:
  `E2E_BASE_URL=http://127.0.0.1:4002 ./node_modules/.bin/playwright test --config=playwright.config.ts --project=desktop-chromium --project=mobile-chromium tests/operator-coverage-readiness.spec.ts` — **14 passed**.
- `mix ci.all` is phase-wave verification and remains scheduled after all Phase 241 Wave 1 plans complete.
- No dependencies were installed. The mounted browser run used the implementation and example source from this worktree.

## Issues Encountered

- The first sandboxed Chromium launch was blocked by a macOS Mach-port permission; the authorized retry passed all 14 browser tests.
- A temporary nested example `_build` directory from an incorrect build-path invocation was inspected and removed; no generated build directory or module symlink remains in the worktree.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 241-01 is complete and committed. The selected-schema coverage and safe remediation path are ready for the remaining Phase 241 operational-evidence plans. Phase-wide CI remains to be run after the Wave 1 plans complete.

---
*Phase: 241-operational-evidence-and-policy-inspection*
*Completed: 2026-10-10*

## Self-Check: PASSED

- Summary file exists at the expected plan path.
- Task commits `a325b8fa`, `d2b6c479`, and `f03354d8` are ancestors of the execution HEAD.
- Coverage metadata validates and classifies D1 as automatically covered by passing tests.
