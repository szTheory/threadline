---
phase: 250-brand-foundation-and-first-whole-investigation
plan: "01"
subsystem: ui
tags: [phoenix-liveview, playwright, e2e, investigation, baseline]

requires: []
provides:
  - "Passing Acme 4521 investigation flow and canonical before capture"
  - "Same-materialization receipt validation and bounded browser-result gates"
affects: [250-02, operator-ui, e2e-evidence]

actuals:
  tokens: null
  tasks: 2
  commits: 2
  plan_head_before: 81fd490359cd0d68a558675678339df6cbc57b7c
  plan_head_after: a9ab0cb3af15eb694c1016c764b7fe6be505ba41

tech-stack:
  added: []
  patterns:
    - "Paired UI proof binds stable database rows and execution identities while recording each half's actual source and assets."
    - "Focused browser evidence gates validate exact Playwright result receipts without launching a runner or altering historical gates."

key-files:
  created:
    - examples/threadline_phoenix/e2e/support/operator-investigation-pair.ts
    - examples/threadline_phoenix/e2e/support/operator-investigation-pair.test.ts
    - .planning/phases/250-brand-foundation-and-first-whole-investigation/250-BASELINE-RECEIPT.md
  modified:
    - examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts

key-decisions:
  - "Keep the selected pair on one materialized database, partition, listener, IDs, event time, and subject-row fingerprints; source and asset digests are recorded per half and may change."
  - "Verify the serving process identity separately from the test checkout; source HEAD equality is not a valid runtime identity check."
  - "Keep phase-250 pair receipts and browser gates separate from the historical evidence mode and runner."

requirements: [ADM-14, ADM-16, ADM-17]
requirements-completed: []

coverage:
  - id: D1
    description: "The ordinary Acme 4521 investigation passes and has a canonical before half with actual row identities, browser conditions, and shell/content evidence."
    verification:
      - kind: e2e
        ref: "examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts#Acme 4521 whole investigation"
        status: pass
    human_judgment: false
  - id: D2
    description: "Pair receipt and selected Playwright result guards accept clean evidence and reject malformed or mismatched cases."
    verification:
      - kind: unit
        ref: "THREADLINE_E2E_EVIDENCE=0 MIX_TEST_PARTITION=p250tests tsx --test support/operator-investigation-pair.test.ts (12 passed)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Existing CI identity, route inventory, semantic-source ownership, and runner argument gates remain passing."
    verification:
      - kind: unit
        ref: "THREADLINE_E2E_EVIDENCE=0 MIX_TEST_PARTITION=p250tests tsx --test support/operator-ci-evidence.test.ts support/operator-route-evidence.test.ts (32 passed)"
        status: pass
    human_judgment: false
  - id: D4
    description: "A portable baseline receipt and read-only check-before result support parent custody of the before capsule."
    verification:
      - kind: integration
        ref: "THREADLINE_PHASE250_PAIR_ROOT=<private-pair-root> MIX_TEST_PARTITION=p250pair tsx support/operator-investigation-pair.ts check-before"
        status: pass
    human_judgment: true
    rationale: "Only the parent can confirm preservation of the live service and private capsule through worktree cleanup and the parent-owned app restart."

duration: null
completed: 2026-11-12
status: complete
---

# Phase 250 Plan 01: Brand Foundation and First Whole Investigation Summary

**Acme 4521 investigation baseline with same-data identity, keyboard-copy proof, and strict paired-receipt gates**

## Performance

- **Duration:** Not measured in this worktree; the parent reconciles executor runtime from the process receipt.
- **Completed:** 2026-11-12
- **Tasks:** 2
- **Plan files created or modified:** 4

## Accomplishments

- Added the named ordinary Timeline → transaction → ticket/reply history → keyboard-copy → restored-filter journey, using the existing production routes and controlled deferred clipboard write double.
- Captured and validated the canonical before half against one action, one transaction, two changes, and SHA-256 fingerprints of the selected ticket and reply rows.
- Added false-pair rejection controls, read-only before verification, and narrow exact-result browser evidence gates for the selected theme/font observations.
- Recorded the current source, served CSS/SVG/font digests, dark/light shell and content captures, system observations, and limits in the portable [baseline receipt](./250-BASELINE-RECEIPT.md).
- Kept the existing CI and route evidence gates passing. No production-rendered source, dependency, lockfile, public API, or shared planning artifact changed.

## Verification

| Check | Result |
|---|---|
| Selected Acme 4521 whole investigation browser case | Pass: one executed case, retries 0, skips 0. The canonical before capture is from attempt 14; tracer feedback independently passed in attempt 15 and wrote a noncanonical capture. |
| Pair and browser-result support tests | Pass: 12 tests, 0 failures, 0 skips in the final run. Includes one-skipped-of-five, zero/skip-only, stale, extra, duplicate, wrong-project, retried, and malformed report rejection. |
| Existing CI and route evidence tests | Pass: 32 tests, 0 failures, 0 skips. |
| Read-only check-before | Pass twice; final run returned verifiedBefore=true and the canonical materialization digest. |
| Stub scan and git diff check | Pass; no stub markers or uncommitted task files remained. |

The browser failure attempts were used to correct test locators and local process-identity assertions; none changed application state. One C02 invocation's tool output was truncated, so it is recorded as unknown and was not used as proof. A later bounded run passed all 12 cases. The focused theme/font gates themselves were not run in this plan; their receipt validation and capture support are covered by the unit fixtures.

## Task Commits

1. **Task 1: Run the ordinary investigation and capture its before half** — 99c0e51d (feat(250-01))
2. **Task 2: Prove receipt rejection and hand custody to parent** — a9ab0cb3 (feat(250-01))

## Files Created or Modified

- examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts — selected whole-investigation journey and before-half capture.
- examples/threadline_phoenix/e2e/support/operator-investigation-pair.ts — pair, materialization, serving-process, before-custody, and selected browser-result checks.
- examples/threadline_phoenix/e2e/support/operator-investigation-pair.test.ts — clean and mutated pair/report controls.
- .planning/phases/250-brand-foundation-and-first-whole-investigation/250-BASELINE-RECEIPT.md — portable evidence record with relative source names and content digests.

## Decisions Made

- The pair identity is the actual selected database materialization and runtime custody, not equality between the test checkout's HEAD and the serving checkout's HEAD.
- Source and asset bytes are recorded for each half and can differ; the database, partition, listener identity, selected records, event time, and row fingerprints must remain stable.
- Parent owns the running app, database lifecycle, capsule retention, cleanup, and independent review.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Aligned the journey assertions with rendered LiveView markup and navigation behavior**
- **Found during:** Task 1
- **Issue:** Initial assertions assumed different transaction labels, timestamp markup, history drawer structure, and one-step browser-back behavior.
- **Fix:** Used the rendered operation and diff-cell text, exact visible history labels, and bounded history traversal to the original filtered URL.
- **Files modified:** examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts
- **Verification:** Selected browser case and tracer feedback passed; no production defect was identified.
- **Committed in:** 99c0e51d

**2. [Rule 3 - Blocking] Matched listener checks to the retained app's actual process identity**
- **Found during:** Task 1
- **Issue:** macOS lsof returned descriptor records and the app cwd was the nested Phoenix example directory, so earlier local checks rejected the correct parent-owned process.
- **Fix:** Check the listener's process record, exact nested cwd, retained checkout, and a separately running test process.
- **Files modified:** examples/threadline_phoenix/e2e/support/operator-investigation-pair.ts
- **Verification:** Browser capture and final read-only check-before passed against the parent-owned listener.
- **Committed in:** 99c0e51d

**3. [Rule 1 - Bug] Matched support fixtures to the installed Playwright JSON and canonical filesystem behavior**
- **Found during:** Task 2
- **Issue:** One fixture expected unavailable Playwright report fields and another compared a symlink path with the runtime's canonical path.
- **Fix:** Validate the installed report schema and compare resolved checkout paths; expanded the controls to cover stale listener and removed-checkout cases.
- **Files modified:** examples/threadline_phoenix/e2e/support/operator-investigation-pair.ts, examples/threadline_phoenix/e2e/support/operator-investigation-pair.test.ts
- **Verification:** Final support run passed 12/12; check-before passed after the final guard changes.
- **Committed in:** a9ab0cb3

**Total deviations:** 3 auto-fixed (2 Rule 1, 1 Rule 3). **Impact:** corrections were limited to the assigned browser proof and its local evidence guards; no application behavior or scope changed.

## Issues Encountered

- The initial Task 2 receipt commit check found two trailing Markdown spaces. They were removed and the normal commit completed with hooks enabled.
- One C02 attempt's output was unavailable after tool-output truncation; it remains explicitly unknown, and the subsequent complete run is the evidence used.
- No authentication gates, skipped tests, package installs, database mutations, or application restarts occurred.

## User Setup Required

None.

## Known Stubs

None found in the plan's created or modified files.

## Threat Flags

None. Changes are confined to the existing test/evidence boundary and a sanitized planning receipt; no new production endpoint, auth path, database schema, or rendered application surface was added.

## Self-Check: PASSED

- Assigned source, support test, and receipt files exist.
- Task commit hashes are ancestors of the bound worktree HEAD; the measured task commit count is 2.
- C01, C02, C03, and C04 final acceptance evidence is recorded; the private invocation ledger parses as JSONL.
- The summary and receipt contain no machine-local checkout or temporary paths.

## Next Phase Readiness

The before half validates and is ready for Plan 02 to build on the same selected materialization. The after half is not captured yet. Parent custody confirmation, retained-capsule preservation, the parent-owned app restart, and the independent review result are pending; Plan 02 should wait for the parent result matching the final source commit.

---
Phase: 250-brand-foundation-and-first-whole-investigation
Completed: 2026-11-12
