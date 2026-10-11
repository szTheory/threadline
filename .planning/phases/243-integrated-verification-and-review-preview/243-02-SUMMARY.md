---
phase: 243-integrated-verification-and-review-preview
plan: "02"
subsystem: testing
tags: [playwright, evidence, candidate-receipt, postgres, ci]
requires:
  - phase: 243-01
    provides: Named journey matrix and required CI evidence contract
provides:
  - Complete candidate identity for evidence-producing source and verifier inputs
  - Receipt-gated synthetic browser evidence runs
  - Immutable Phase 238 baseline validation and candidate review ledger
affects: [243-03, 243-04, 243-05, 243-06]
actuals:
  tokens: 24167
  tasks: 3
  commits: 8
  plan_head_before: 04db5d65230135f1939e21384bc78ed0ca3f7079
  plan_head_after: 3a704a08a753e2ae674c09b4c724ff39210e94bb
tech-stack:
  added: []
  patterns: [receipt-bound evidence runs, staged/unstaged/untracked verifier-input hashing, immutable baseline byte validation]
key-files:
  created:
    - examples/threadline_phoenix/e2e/support/operator-candidate-receipt.ts
    - examples/threadline_phoenix/e2e/support/operator-candidate-review.ts
    - .planning/phases/243-integrated-verification-and-review-preview/243-CANDIDATE-RECEIPT.json
  modified:
    - examples/threadline_phoenix/e2e/support/operator-evidence-manifest.ts
    - examples/threadline_phoenix/e2e/support/operator-browser-evidence.ts
    - examples/threadline_phoenix/e2e/run-e2e.sh
    - test/partition_weights.txt
decisions:
  - Candidate review verifies candidate assets against current local bytes and records historical generated-asset drift without mutating accepted Phase 238 evidence.
  - The generated candidate receipt remains a local machine artifact because it is bound to the pre-summary candidate HEAD.
requirements-completed: []
coverage:
  - id: D1
    description: Candidate receipts bind the exact candidate, accepted baseline, fixture and evidence-producing bytes before setup.
    requirement: UIV-02
    verification:
      - kind: unit
        ref: examples/threadline_phoenix/e2e/support/operator-candidate-receipt.test.ts
        status: pass
      - kind: integration
        ref: examples/threadline_phoenix/e2e/support/operator-evidence-manifest.test.ts
        status: pass
    human_judgment: false
  - id: D2
    description: A fresh route bundle is validated against the immutable Phase 238 baseline with explicit render and asset differences.
    requirement: UIV-02
    verification:
      - kind: automated_ui
        ref: examples/threadline_phoenix/e2e/artifacts/operator-evidence/operator_243_routes_1791689404/candidate-review.json
        status: pass
      - kind: integration
        ref: mix verify.example_browser --project=route-capture operator-page-capture.spec.ts
        status: pass
    human_judgment: false
duration: 30min
completed: 2026-10-11
status: complete
commits: 8
plan_head_before: 04db5d65230135f1939e21384bc78ed0ca3f7079
plan_head_after: 3a704a08a753e2ae674c09b4c724ff39210e94bb
---

# Phase 243 Plan 02: Candidate-bound evidence and immutable capture Summary

**Receipt-bound operator evidence now hashes verifier inputs, validates fresh full-shell captures, and preserves the accepted Phase 238 baseline.**

## Performance

- **Duration:** 30 minutes
- **Started:** 2026-10-11T03:04:50Z
- **Completed:** 2026-10-11T03:34:00Z
- **Tasks:** 3
- **Files modified:** 10, including the generated local candidate receipt

## Accomplishments

- Expanded candidate identity to include CI workflow/helpers, material project and example inputs, relevant contracts, route inventory, and the test partition-weight inventory. The digest detects committed, staged, unstaged, and untracked bytes while excluding generated output.
- Added strict Phase 243 candidate receipt validation before database setup or browser launch; carried receipt custody into browser manifests and retained the existing ordinary and earlier-phase flows.
- Validated a fresh receipt-bound route bundle against Phase 238 manifest/output hashes. The final run at `operator_243_routes_1791689404` produced 34 valid full-shell PNGs across 12 route IDs; review comparison is explicitly `limited` because of recorded historical asset, fixture, OS, and condition differences. No accepted snapshot or baseline bytes changed; baseline digest remained `c744df9cd8e999109be2ac0956028288b4f4b1eb734354d8d22d0bcf3332f4aa` before and after the named checks.
- Added the missing measured CI partition weight (`800 ms`) for the Phase 243-01 browser journey contract and bound the partition file into the candidate digest.

## Task Commits

1. **Task 1: Include all evidence-producing bytes in the candidate identity** — `d52a51a0` (test), `61a56379` (feat)
2. **Task 2: Guard Phase 243 evidence runs with a refreshed candidate receipt** — `c4cdba23` (test), `29169bac` (feat)
3. **Task 3: Validate fresh full-shell images against the immutable reference** — `0ad5e97b` (test), `037563c5` (feat)

**Plan fixes:** `4903c542` (historical generated-asset provenance) and `3a704a08` (partition-weight repair and candidate-identity coverage).

## Files Created/Modified

- `examples/threadline_phoenix/e2e/support/operator-evidence-manifest.ts` and `.test.ts` — deterministic hashing for all relevant candidate evidence inputs, including partition assignment.
- `examples/threadline_phoenix/e2e/support/operator-candidate-receipt.ts` and `.test.ts` — strict candidate receipt creation and validation.
- `examples/threadline_phoenix/e2e/support/operator-browser-evidence.ts` and `examples/threadline_phoenix/e2e/run-e2e.sh` — receipt custody through the browser run, with pre-setup validation.
- `examples/threadline_phoenix/e2e/support/operator-candidate-review.ts` and `.test.ts` — immutable baseline/output checks, current candidate asset checks, and recorded comparison limits.
- `test/partition_weights.txt` — measured weight for `test/threadline/browser_journey_evidence_contract_test.exs`.
- `.planning/phases/243-integrated-verification-and-review-preview/243-CANDIDATE-RECEIPT.json` — generated local receipt for candidate HEAD `3a704a08a753e2ae674c09b4c724ff39210e94bb`, SHA-256 `5e08528dae6716ea6fc9b7c44b20b2a92f48dbdd6164a3248d1638f271748760`.

## Decisions Made

- Accepted Phase 238 manifests and image outputs remain the historical authority. Their recorded served/local hash pair is checked as captured; changed ignored/generated local assets are disclosed as drift rather than used to rewrite the baseline.
- Candidate served assets continue to be checked against current local bytes. A candidate mismatch still fails closed.
- The candidate receipt is generated locally for the exact source HEAD and is not committed as a durable fixture.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Disclosed regenerated historical assets while retaining strict candidate checks**
- **Found during:** Task 3
- **Issue:** Phase 238's immutable manifests recorded correct served/local hashes, but ignored generated dependency and stylesheet files in the retained baseline worktree had since been rebuilt, causing historical source rehashing to reject valid accepted evidence.
- **Fix:** Kept manifest/output byte verification and captured served/local equality for Phase 238; checked current local assets strictly for the candidate; recorded exact historical generated-asset and candidate/baseline differences in the review ledger.
- **Files modified:** `examples/threadline_phoenix/e2e/support/operator-candidate-review.ts`, `examples/threadline_phoenix/e2e/support/operator-candidate-review.test.ts`
- **Verification:** Candidate review passed and classified the comparison as limited; negative controls still reject candidate asset mismatches.
- **Commit:** `4903c542`

**2. [Rule 2 - Missing CI inventory input] Added the partition-weight inventory to candidate identity**
- **Found during:** Overall verification
- **Issue:** `mix ci.all` found that the new browser journey contract lacked a required sorted partition-weight row, while the candidate digest omitted `test/partition_weights.txt`.
- **Fix:** Measured the contract at 800 ms, added its sorted weight, and extended the digest mutation matrix to cover the inventory in staged, unstaged, and untracked states.
- **Files modified:** `test/partition_weights.txt`, `examples/threadline_phoenix/e2e/support/operator-evidence-manifest.ts`, `examples/threadline_phoenix/e2e/support/operator-evidence-manifest.test.ts`
- **Verification:** The browser journey and topology contract tests passed (29 tests total); manifest tests passed (27/27).
- **Commit:** `3a704a08`

**Total deviations:** 2 auto-fixed. Both close evidence-integrity gaps found while validating this plan.

## Verification and Issues Encountered

- Focused evidence-manifest tests: **27/27 passed**.
- Focused candidate-receipt and review tests: **7/7 passed**; receipt adversarial and Phase 238 anchor tests passed.
- Browser journey plus topology contracts after the weight repair: **29/29 passed**.
- Final fresh named route capture: **12 passed, 1 expected skip** (the legacy reference-capture test is skipped in read-only evidence mode). Browser launch required an elevated local command because the sandbox denied Chromium's macOS MachPort rendezvous; the first sandboxed run and its logs were preserved.
- Candidate review: passed, 34 valid shell PNGs, comparison `limited`, with 647 explicit differences. The primary recorded differences are historical generated asset drift (accepted served/local JS `7f97fe…` and stylesheet `b5053f…` versus current candidate JS `880c3d…` and stylesheet `cf8ec7…`), fixture identity, OS, route/state inventory, and missing structured conditions in old manifests.
- `tsc --noEmit`, `bash -n run-e2e.sh`, and owned-file `git diff --check` passed.
- `mix ci.all` was run and did not pass. Its root suite reported **32 properties, 3,128 tests, 4 failures, 3 excluded**: the missing partition weight (fixed afterward), a sandbox denial creating shared `.git/worktrees/registered-worktree`, a clean-checkout verifier timeout during temp clone/dependency resolution, and npm `EPERM` under `/Users/jon/.npm/_cacache`. Later phases passed **132 example tests**, **17 live-Dialyzer tests (16 excluded)**, and Dialyzer with **0 errors**; the browser alias then failed when Hex could not persist `/Users/jon/.hex/cache.ets` (`:eaccess`) after an expired-auth warning. These environment failures remain for the phase orchestrator's clean-cache validation; the full suite was not rerun.
- No unrelated process was signaled and no evidence database or failed-run artifacts were deleted. Three unique task-owned synthetic databases and all route-run artifacts remain preserved. Port 4002 had no listener after capture.

## Next Phase Readiness

The final receipt-bound capture and immutable review ledger are ready for the remaining Phase 243 review, preview, and final-candidate plans. Phase-level requirements UIV-02 and UIV-03 remain pending until their later visual-review and guarded-preview work completes.

## Self-Check: PASSED

The summary file and final evidence run exist; all eight plan commits are ancestors of the recorded candidate HEAD. The final candidate receipt SHA and baseline digest match the verified artifacts.

---
*Phase: 243-integrated-verification-and-review-preview*
*Completed: 2026-10-11*
