---
phase: 243-integrated-verification-and-review-preview
plan: "01"
subsystem: testing
tags: [playwright, ci, operator-journeys, evidence]

requires:
  - phase: 242-export-and-retention-operations
    provides: Export, retention, accessibility, responsive, and disconnect/reconnect journeys for the required CI matrix
provides:
  - Exact named Playwright journey inventory across required desktop and mobile Chromium projects
  - Fail-closed reconciliation of native discovery and executed JSON reports into an allowlisted CI receipt
  - Required-CI contracts that preserve stable job IDs and non-success aggregate blocking
affects: [Phase 243 final evidence index, required browser CI, operator journey coverage]

actuals:
  tokens: 10255
  tasks: 2
  commits: 5
commits: 5
plan_head_before: 6585dad974419c753557b45b96d393fddbcaf9e1
plan_head_after: e580e9075697486a41fcbe327562fb77ea3da0c4

tech-stack:
  added: []
  patterns:
    - Native Playwright list and JSON reporter identity reconciliation
    - Small allowlisted CI receipt generated only after exact pass-without-retry validation

key-files:
  created:
    - examples/threadline_phoenix/e2e/support/operator-journey-inventory.json
    - examples/threadline_phoenix/e2e/support/operator-ci-evidence.ts
    - examples/threadline_phoenix/e2e/support/operator-ci-evidence.test.ts
    - test/threadline/browser_journey_evidence_contract_test.exs
  modified:
    - .github/workflows/ci.yml
    - examples/threadline_phoenix/e2e/playwright.config.ts

key-decisions:
  - "Use exact project, file, and full title-path identities; counts and durations do not establish coverage."
  - "Enable the native JSON reporter when PLAYWRIGHT_JSON_OUTPUT_FILE is set, preserving the stable Mix command and GitHub annotations."
  - "Keep light/System, browser-full capture projects, and unsupported mobile zoom explicitly nonvoting with reasons."

patterns-established:
  - "Receipt fields are constructed from an allowlist after expected, discovered, and executed identities reconcile."
  - "A required journey passes only when its single Playwright result passes on its required project without retry."

requirements-completed: [UIV-01]
coverage:
  - id: D1
    description: "Required CI proves named operator journeys and material failure cases were discovered and passed without retry in both voting Chromium projects."
    requirement: UIV-01
    verification:
      - kind: unit
        ref: "examples/threadline_phoenix/e2e/support/operator-ci-evidence.test.ts — 10 adversarial contracts"
        status: pass
      - kind: integration
        ref: "mix test test/threadline/browser_journey_evidence_contract_test.exs test/threadline/browser_full_projects_contract_test.exs"
        status: pass
      - kind: e2e
        ref: "mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-timeline-investigation-flow.spec.ts --grep 'starts at Home, applies a Timeline query, and opens its transaction'"
        status: pass
    human_judgment: false

duration: 32min
completed: 2026-10-11
status: complete
---

# Phase 243 Plan 01: Required Operator Journey Evidence Summary

**Required browser CI now reconciles exact named operator journeys with native Playwright discovery and execution results, rejecting missing, filtered, skipped, failed, duplicate, or retry-only coverage.**

## Performance

- **Duration:** 32 minutes
- **Started:** 2026-10-11T02:22:52Z
- **Completed:** 2026-10-11T02:54:30Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added a bounded UIV-01 journey matrix for investigation, actor/correlation, saved searches, evidence, coverage and redaction, export/download/return, retention, disconnect/reconnect, accessibility, responsive behavior, reduced motion, and actual desktop zoom. Light/System, browser-full capture, and unsupported mobile zoom have explicit nonvoting reasons.
- Added a strict reconciler for Playwright list output and native JSON reports. It checks exact project/file/title-path identities, rejects zero or malformed reports and duplicate identities, and requires exactly one pass with no retry for every required row.
- Wired `verify-example-browser` to retain native JSON only in runner temp storage and upload a small allowlisted receipt after successful reconciliation. The `verify-example-browser` and `ci-required` job IDs, required dependency list, and always-run result inspection remain intact.
- Verified the reconciler against a real two-project Playwright JSON run. It emitted a receipt with two expected, discovered, executed, and passed identities and no reporter attachments or other raw data.

## Task Commits

1. **Task 1: Prove Home to Timeline through expected, discovered, and executed evidence** — `6d18b8aa` (RED test), `e5269a02` (implementation)
2. **Task 2: Expand the journey matrix and attack the CI contract** — `f2db6346` (matrix RED), `afdb5089` (native JSON shape RED), `e580e907` (implementation and contracts)

## Files Created/Modified

- `examples/threadline_phoenix/e2e/support/operator-journey-inventory.json` — exact voting identities and explicit nonvoting limitations.
- `examples/threadline_phoenix/e2e/support/operator-ci-evidence.ts` — discovery/execution reconciliation and safe receipt generation.
- `examples/threadline_phoenix/e2e/support/operator-ci-evidence.test.ts` — positive and adversarial parser/receipt controls.
- `test/threadline/browser_journey_evidence_contract_test.exs` — live inventory discovery and CI topology contract.
- `.github/workflows/ci.yml` — required job runs reconciliation and uploads only the validated receipt.
- `examples/threadline_phoenix/e2e/playwright.config.ts` — selects GitHub annotations plus native JSON reporting when the receipt output path is configured.

## TDD Gate Compliance

- Task 1 RED `6d18b8aa` failed on the intended exact-identity assertion; `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK`. GREEN `e5269a02` passed the focused Node tests.
- Task 2 RED `f2db6346` demonstrated the missing journey categories; `RED_EVIDENCE_OK`. The native reporter fixture exposed a second identity mismatch in RED `afdb5089`; `RED_EVIDENCE_OK`. The final implementation commit `e580e907` passes all ten Node contracts.

## Decisions Made

- Identity is the exact project, relative test file, and complete title path. Playwright line numbers and run duration are intentionally excluded.
- The receipt is built from validated synthetic status fields only; raw report attachments, cookies, storage state, and environment maps are not copied.
- Reporter selection is controlled by `PLAYWRIGHT_JSON_OUTPUT_FILE`, retaining the existing Mix command that other CI partition contracts inspect.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Normalize native JSON file-suite titles out of the test title path**
- **Found during:** Task 2 (native reporter identity regression)
- **Issue:** Playwright JSON includes the spec filename as a suite title, while native list output treats it as the file identity. Direct comparison therefore rejected a real passing test.
- **Fix:** Ignore the file-suite title while retaining describe and test titles in the exact identity.
- **Files modified:** `examples/threadline_phoenix/e2e/support/operator-ci-evidence.ts`, `examples/threadline_phoenix/e2e/support/operator-ci-evidence.test.ts`
- **Verification:** The native JSON fixture and real two-project reporter output reconcile successfully.
- **Committed in:** `e580e907`

**2. [Rule 1 - Bug] Preserve the existing browser-full project-discovery contract**
- **Found during:** Task 2 (ExUnit contract run)
- **Issue:** Adding a CLI reporter flag changed the stable Mix command text that the browser-full partition mutation test uses as an input anchor.
- **Fix:** Select GitHub annotations plus JSON reporting from Playwright config only when `PLAYWRIGHT_JSON_OUTPUT_FILE` is configured; the Mix command and project flags stay unchanged.
- **Files modified:** `.github/workflows/ci.yml`, `examples/threadline_phoenix/e2e/playwright.config.ts`, `test/threadline/browser_journey_evidence_contract_test.exs`
- **Verification:** Both the journey workflow contract and browser-full project partition contract pass.
- **Committed in:** `e580e907`

**Total deviations:** 2 auto-fixed (Rule 1: 2)
**Impact on plan:** Both changes were needed to validate actual Playwright report identities and preserve existing CI discovery coverage.

## Issues Encountered

- The local home directory’s Hex cache was read-only (`:eaccess`). The browser harness passed after setting `HEX_HOME` to the permitted temp directory; no dependency or lockfile changes were made.
- The first RED run used Node’s default reporter, which the classifier correctly rejected as unsupported. Rerunning with the native TAP reporter produced `RED_EVIDENCE_OK`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

UIV-01 has an executable named-journey CI contract and a safe receipt for the later Phase 243 evidence index. Plan 02 can extend candidate identity to cover the workflow, helper, inventory, and contracts.

## Self-Check: PASSED

- Summary file created at the required phase path.
- All five measured task commits are ancestors of the plan head.
- The receipt helper, inventory, Playwright config, workflow contract, and journey ExUnit contract exist.

---
*Phase: 243-integrated-verification-and-review-preview*
*Completed: 2026-10-11*
