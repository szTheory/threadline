---
phase: 250-brand-foundation-and-first-whole-investigation
plan: "01"
subsystem: ui
tags: [phoenix-liveview, playwright, e2e, investigation, baseline]

requires: []
provides:
  - "Live-row-bound, byte-verified legacy before candidate for Acme 4521"
  - "Startup-source freshness and strict-after receipt guards for paired investigation evidence"
affects: [250-02, operator-ui, e2e-evidence]

actuals:
  tokens: null
  tasks: 2
  commits: 5
  plan_head_before: 81fd490359cd0d68a558675678339df6cbc57b7c
  plan_head_after: 5d1b25cc8f7f1bbd3c96b2bd790ae4b578ef648a

tech-stack:
  added: []
  patterns:
    - "Pair evidence binds actual live rows, history fingerprint, runtime source bytes, route screenshots, and file custody."
    - "Before-only legacy paths are labeled separately from strict after acceptance."

key-files:
  created:
    - examples/threadline_phoenix/e2e/support/operator-investigation-pair.ts
    - examples/threadline_phoenix/e2e/support/operator-investigation-pair.test.ts
    - .planning/phases/250-brand-foundation-and-first-whole-investigation/250-BASELINE-RECEIPT.md
  modified:
    - examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts
    - examples/threadline_phoenix/e2e/support/operator-investigation-pair.ts
    - examples/threadline_phoenix/e2e/support/operator-investigation-pair.test.ts
    - .planning/phases/250-brand-foundation-and-first-whole-investigation/250-BASELINE-RECEIPT.md

key-decisions:
  - "Keep the original canonical pointer and bytes untouched; store the corrected evidence as a separate, noncanonical before candidate."
  - "Match the app's launch-time runtime-source inventory to current serving and test runtime bytes; do not require HEAD equality."
  - "Only a strict transaction-history copy and UI-link return can satisfy the after proof."

requirements: ["ADM-14", "ADM-16", "ADM-17"]
requirements-completed: ["ADM-14", "ADM-16", "ADM-17"]

coverage:
  - id: D1
    description: "A corrected before-only candidate captures the real Acme 4521 routes and selected Timeline-origin copy path."
    verification:
      - kind: e2e
        ref: "operator-earned-flows.spec.ts#Acme 4521 whole investigation; browser-invocations/whole-investigation-candidate-5d1b25cc-r1.json"
        status: pass
      - kind: integration
        ref: "operator-investigation-pair.ts candidate-check review-correction-5d1b25cc-r1; 26 capture files verified"
        status: pass
    human_judgment: true
    rationale: "Parent intake is still pending and the candidate proves only the legacy before route, not the strict after contract."
  - id: D2
    description: "Candidate, live-row, source-freshness, and nested evidence-byte guards reject malformed or mismatched receipts."
    verification:
      - kind: unit
        ref: "operator-investigation-pair.test.ts (15 passed, 0 failed)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Existing CI identity and route-evidence checks continue to pass."
    verification:
      - kind: unit
        ref: "operator-ci-evidence.test.ts + operator-route-evidence.test.ts (32 passed in the initial Plan01 run)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The retained app startup snapshot matches current serving and test runtime source maps while selected rows and history remain unchanged."
    verification:
      - kind: integration
        ref: "parent environment_ready 66d20381; candidate-check against live materialization and source inventory"
        status: pass
    human_judgment: true
    rationale: "The parent owns the app lifecycle, candidate selection, and final acceptance; this worker can verify integrity but cannot record parent acceptance."

duration: null
completed: 2026-11-12
status: complete
---

# Phase 250 Plan 01: Brand Foundation and First Whole Investigation Summary

**Acme 4521 legacy before candidate with live-row, history, startup-source, and evidence-byte guards**

## Performance

- **Duration:** Not measured in this worktree; parent reconciles elapsed time from process receipts.
- **Completed:** 2026-11-12
- **Tasks:** 2 plan tasks complete; review-correction continuation completed.
- **Files modified:** 5 tracked files in this continuation and close-out.

## Accomplishments

- Preserved the original canonical before pointer and its bytes, and added a distinct corrected before candidate without automatic promotion.
- Captured transaction detail, the earlier ticket state, Timeline-origin reply history, and restored Timeline in dark/light, with shell/header, content, observation, and System-preference evidence.
- Bound the candidate's selected action, transaction, changes, reply, ticket, actor, exact timestamps, materialization, and linked history fingerprint to the live read-only query result.
- Added nested evidence-path, regular-file, byte-digest, changed-file, missing-file, and symlink-escape checks with clean controls.
- Bound app source freshness to the parent-recorded startup inventory and added the UI, logo, presentation, data/display, row-history, SVG, and font inputs.
- Required the after half to use transaction-origin reply history, keyboard-copy the exact reply ID there, and return through UI links. The strict after proof remains future work.
- Updated the [portable before receipt](./250-BASELINE-RECEIPT.md) to distinguish candidate integrity from parent acceptance.

## Verification

| Check | Result |
|---|---|
| Corrected selected Acme 4521 candidate | Pass: one desktop Chromium case, retry 0, skipped 0; candidate labeled legacy-before, Timeline copy, browser-back. |
| Candidate integrity | Pass: candidate half digest, live selected materialization/history, startup source maps, and all 26 referenced evidence files validated; output explicitly says parentAcceptance=false. |
| Pair/support negative controls | Pass: 15 tests, 0 failures, 0 skips. Covers live-field mutations with refreshed candidate digest, missing/changed/nested symlink evidence, source-map drift, and skipped browser results. |
| Existing CI and route-evidence tests | Pass: 32 tests from the initial Plan01 run; those files were not changed by this correction continuation. |
| Post-failure materialization check | Pass: live selected rows and history still matched the prepared snapshot; no reset, migration, or seed rerun. |
| Playwright test discovery | Pass: 18 tests listed; no browser launched by this check. |
| Formatting / diff check | Pass: git diff --check. |

The first correction browser attempt was blocked before test execution because the sandbox denied Chromium's macOS process bootstrap. The next attempt reached the test and found the screenshot theme controls had altered the journey page's Back history. Both reports, traces, and the partial candidate are preserved. Capture checkpoints were moved to a temporary page in the same authenticated context; the next first-attempt run passed with retries disabled.

## Task Commits

1. **Task 1: Capture the Acme 4521 before journey** — 99c0e51d
2. **Task 2: Add pair and browser-result guards** — a9ab0cb3
3. **Review correction: Bind candidate to live rows, source startup, and evidence bytes** — 66d20381
4. **Review correction: Keep screenshot capture out of journey history** — 5d1b25cc

The earlier close-out commit 3d8442e1 is superseded by this corrected receipt and summary. Plan metadata for this close-out is committed separately.

## Files Created/Modified

- examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts — before/after navigation modes; corrected legacy path and strict after flow.
- examples/threadline_phoenix/e2e/support/operator-investigation-pair.ts — source inventory, launch freshness, live row/history binding, candidate receipt and nested evidence validation.
- examples/threadline_phoenix/e2e/support/operator-investigation-pair.test.ts — meaningful clean and negative controls for candidate fields, file bytes/paths, source drift, and after-mode enforcement.
- .planning/phases/250-brand-foundation-and-first-whole-investigation/250-BASELINE-RECEIPT.md — candidate proof, artifact/source digests, and limits.

## Decisions Made

- Keep evidence for the historical legacy before route separate from canonical acceptance; the candidate is not parent-approved.
- Compare the full actual runtime-source byte map captured at app startup, not just current disk trees or commit IDs.
- Do not treat a passing screenshot, source hash, or before-only candidate as the final after proof.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Aligned the original journey assertions to current LiveView markup and route behavior**
- **Found during:** Task 1
- **Issue:** Initial selectors assumed different transaction labels, timestamp markup, history structure, and a one-step Back path.
- **Fix:** Asserted rendered operation/diff text, exact history routes, and bounded traversal to the original filtered Timeline.
- **Files modified:** examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts
- **Verification:** Initial selected flow and tracer feedback passed; the corrected candidate is verified separately below.
- **Commit:** 99c0e51d

**2. [Rule 3 - Blocking] Matched listener checks to the retained app's actual process identity**
- **Found during:** Task 1
- **Issue:** macOS lsof returned descriptor records and the app cwd was the nested Phoenix example directory.
- **Fix:** Checked the listener process record, exact nested cwd, retained checkout, and distinct test process.
- **Files modified:** examples/threadline_phoenix/e2e/support/operator-investigation-pair.ts
- **Verification:** Initial parent-owned listener checks passed; later candidate-check repeated the source/identity boundary.
- **Commit:** 99c0e51d

**3. [Rule 1 - Bug] Matched support fixtures to installed Playwright JSON and filesystem behavior**
- **Found during:** Task 2
- **Issue:** Fixtures assumed unavailable report fields and compared a symlink spelling with the canonical checkout path.
- **Fix:** Matched installed report parsing and resolved checkout identities; added stale listener and removed-checkout controls.
- **Files modified:** examples/threadline_phoenix/e2e/support/operator-investigation-pair.ts, examples/threadline_phoenix/e2e/support/operator-investigation-pair.test.ts
- **Verification:** Initial support suite passed; expanded suite now passes 15/15.
- **Commit:** a9ab0cb3

**4. [Rule 2 - Missing critical] Made candidate acceptance depend on current selected rows, history, startup source, and real evidence bytes**
- **Found during:** Independent intake correction
- **Issue:** The first receipt guard did not bind every candidate field to the live rows, could not validate nested evidence bytes, and compared current source trees without the app's launch-time snapshot.
- **Fix:** Added those checks, a distinct candidate selector, source inventory inputs, and missing/changed/symlink plus field-mutation controls.
- **Files modified:** examples/threadline_phoenix/e2e/support/operator-investigation-pair.ts, examples/threadline_phoenix/e2e/support/operator-investigation-pair.test.ts, examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts
- **Verification:** 15 pure tests passed; candidate-check matched current live rows/history, source maps, and 26 evidence files.
- **Commit:** 66d20381

**5. [Rule 1 - Test harness] Prevented evidence theme controls from changing the legacy browser Back path**
- **Found during:** Corrected candidate browser run
- **Issue:** Applying dark/light preferences on the journey page added history entries, so the bounded Back path stayed on the transaction route.
- **Fix:** Captured each checkpoint in a temporary page sharing the authenticated browser context and installed clipboard doubles at context scope.
- **Files modified:** examples/threadline_phoenix/e2e/support/operator-investigation-pair.ts, examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts
- **Verification:** The corrected selected candidate passed once with retries disabled.
- **Commit:** 5d1b25cc

**Total deviations:** 5 auto-fixed (3 Rule 1, 1 Rule 2, 1 Rule 3). **Impact:** corrections remained within Plan01's test/evidence boundary; no production rendering code, database records, public API, or dependencies changed.

## Issues Encountered

- One sandboxed Playwright attempt stopped at Chromium startup with macOS bootstrap permission denied before the test body ran.
- The first escalated browser execution exposed evidence-capture interference with the legacy Back history. Its partial captures were preserved; the fix isolated screenshot pages and the next candidate passed.
- A helper-output wrapper call had a tool-call JavaScript syntax error and did not launch a command; the corrected candidate-check invocation passed.
- No authentication gate, package install, database reset/reseed, migration, or app lifecycle action occurred.

## User Setup Required

None.

## Known Stubs

None.

## Threat Flags

None. All changes remain in the existing test/evidence boundary; no new runtime endpoint, auth path, schema, or rendered product behavior was added.

## Self-Check: PASSED

- Source, test, receipt, and candidate files exist; all five plan-scope commits resolve on this branch.
- The selected report is one passed case with retry 0; candidate-check passed with parentAcceptance=false.
- The live materialization and three-change history fingerprints match the recorded receipt.
- The canonical pointer and referenced half digests match the preserved original values; the candidate remains separate.
- `git diff --check` passes, and neither tracked document contains a machine-local path.

## Next Phase Readiness

Plan01 tasks and correction work are complete. The corrected candidate is ready for parent independent intake, but accepted-before count remains zero until the parent selects it and commits a matching result. Do not proceed to Plan02 or rely on this candidate for after proof before that acceptance. The strict transaction-history copy and UI-link return proof remains unimplemented in this plan.

---
Phase: 250-brand-foundation-and-first-whole-investigation
Completed: 2026-11-12


## Final milestone traceability writeback

This plan's declared requirement contributions are now reflected in `requirements-completed`, following the independently passed phase goal and final34-requirement integration check/current candidate CI. Earlier empty completion fields were local contribution bookkeeping, not a new missing implementation. Historical results remain preserved; the bounded successor-impact verification owns current fingerprint freshness.
