---
phase: 238-current-main-preview-and-acceptance-baseline
plan: "01"
subsystem: testing
tags: [playwright, operator-ui, evidence, provenance, postgres]
requires: []
provides:
  - "Guarded evidence-mode runner and source-bound home capture implementation; browser acceptance remains blocked."
affects: [phase-238-preview, operator-browser-evidence]
actuals:
  tokens: 6444
  tasks: 0
  commits: 1
plan_head_before: 9eefb75c2a45cdc93c6b3d3cac8e7850bc61d7d2
plan_head_after: 19d6a45e7001ccd79eb7c9750a222d52e57dc094
tech-stack:
  added: []
  patterns: [isolated database preflight, source and served-asset manifest, contained per-run capture output]
key-files:
  created:
    - examples/threadline_phoenix/e2e/support/operator-evidence-manifest.ts
  modified:
    - examples/threadline_phoenix/e2e/run-e2e.sh
    - examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts
key-decisions:
  - "Keep evidence mode opt-in and preserve existing default browser entrypoints."
  - "Use writable temporary caches for Hex, npm, and Playwright in evidence mode."
  - "Halt before Task 2 because the named browser acceptance gate could not launch Chromium under the current process permissions."
requirements-completed: [UIB-01]
coverage:
  - id: D1
    description: "Guarded evidence runner and authenticated home capture path were implemented, but no capture bundle was produced."
    requirement: UIB-01
    verification:
      - kind: integration
        ref: "THREADLINE_E2E_EVIDENCE=1 MIX_TEST_PARTITION=operator_baseline_<unique> mix verify.example_browser --project=route-capture operator-page-capture.spec.ts --grep home"
        status: fail
    human_judgment: true
    rationale: "Chromium exited before test execution because macOS denied Mach port registration (bootstrap_check_in permission denied, SIGTRAP); no screenshot or manifest exists."
duration: 15 min
completed: 2026-10-09
status: halted
---

# Phase 238 Plan 01: Current-main preview and acceptance baseline Summary

**Evidence-mode database guards and a source-bound authenticated home capture path are committed; the required browser run halted before Chromium could start.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-10-09T00:54:00Z (approximate; executor start was not recorded)
- **Completed:** 2026-10-09T01:09:04Z
- **Tasks:** 0/2 completed; Task 1 implementation committed, acceptance gate failed
- **Files modified:** 3

## Accomplishments

- Added an opt-in evidence runner that requires a fresh partition, derives the test database from `config/test.exs`, rejects non-loopback or existing database targets and unsafe overrides, and uses writable temporary caches.
- Added a separately selectable authenticated `/audit` full-shell and content capture path with candidate, fixture, browser, served stylesheet/script, and output identity validation.
- Preserved the Playwright launch failure report and trace under `examples/threadline_phoenix/e2e/test-results/`.

## Task Commits

1. **Task 1 implementation (acceptance incomplete):** `19d6a45e` — `feat(238-01): add guarded operator evidence capture`

**Plan metadata:** not committed yet.

## Files Created/Modified

- `examples/threadline_phoenix/e2e/support/operator-evidence-manifest.ts` — candidate, fixture, asset, and output identity validation.
- `examples/threadline_phoenix/e2e/run-e2e.sh` — evidence-mode target guards, temporary caches, and guarded preview lifecycle.
- `examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts` — authenticated home shell and content capture.

## Decisions Made

- Kept evidence mode opt-in so existing named browser checks retain their default runner path.
- Used per-run writable Hex/npm caches and a writable Playwright cache after the default Hex cache failed with `:eaccess`.
- Stopped before Task 2 because the Task 1 acceptance gate requires a real browser capture.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Redirect dependency caches to writable temporary directories**
- **Found during:** Task 1 browser setup
- **Issue:** Hex could not persist its registry under the default user cache (`:eaccess`); the default browser cache also did not complete setup in this environment.
- **Fix:** Evidence mode now uses writable temporary Hex and npm caches and a writable Playwright browser cache.
- **Files modified:** `examples/threadline_phoenix/e2e/run-e2e.sh`
- **Verification:** Locked example dependencies compiled, the synthetic partition was seeded, npm installed 19 locked packages with 0 reported vulnerabilities, and Chromium downloaded to the temporary cache.
- **Committed in:** `19d6a45e`

**Total deviations:** 1 auto-fixed (1 blocking environment issue). **Impact:** Cache setup progressed without sudo or hook bypass; browser execution remained blocked by process permissions.

## Issues Encountered

- The named browser command’s Node preflight executed 21 tests. The final run passed all 21, then Playwright attempted the named home test and Chromium failed to launch with `bootstrap_check_in org.chromium.Chromium.MachPortRendezvousServer: Permission denied (1100)` and `SIGTRAP`.
- No browser test body ran. No home screenshot, source/asset manifest, or valid capture bundle was produced. The retained Playwright trace records the launch failure only.
- Task 2 and its focused negative controls were not started because Task 1’s required acceptance gate did not clear.
- `git diff --check` and `bash -n examples/threadline_phoenix/e2e/run-e2e.sh` passed before the Task 1 implementation commit.

## User Setup Required

None. The blocker is the current execution environment’s Chromium process permission.

## Next Phase Readiness

**Halted.** Retry this plan in an environment where Playwright Chromium can start. Require the named home test to execute and pass, inspect a real screenshot and manifest, then continue to Task 2’s focused mutation-controlled negative tests. Do not treat the retained launch trace as capture evidence.

---
*Phase: 238-current-main-preview-and-acceptance-baseline*
*Completed: 2026-10-09 (halted)*

## Self-Check: FAILED

- Task 1 acceptance failed before Chromium test execution; no evidence capture or manifest exists.
- Task 2 remains unexecuted.
- The partial implementation commit `19d6a45e` exists on this worktree branch.
