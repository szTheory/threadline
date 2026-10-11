---
phase: "243"
slug: "integrated-verification-and-review-preview"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-10"
---

# Phase 243 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, Node's built-in test runner, and Playwright Test 1.60.0 |
| **Config file** | `test/test_helper.exs`; `examples/threadline_phoenix/e2e/playwright.config.ts` |
| **Quick run command** | `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-route-states.spec.ts` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | Approximately 20 minutes for the exact-SHA required CI run (#38158769462); local full-suite timing is environment-dependent. |

---

## Sampling Rate

- **After every task commit:** Run the focused ExUnit or Node contract tests for that task; run the named browser command when journey or capture behavior changes.
- **After every plan wave:** Run `mix ci.all` before relying on cross-layer integration evidence.
- **Before `$gsd-verify-work`:** `mix ci.all` and the exact-candidate required CI browser lane must be green.
- **Max feedback latency:** Keep the focused contract-test loop under 120 seconds where practical; record actual browser/full-suite durations instead of assuming a fixed ceiling.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 243-01/T1 | 01 | 1 | UIV-01 | T-243-01 | Reject missing, skipped, flaky, malformed or project-mismatched journey results. | Node contract + browser | `cd examples/threadline_phoenix/e2e && ./node_modules/.bin/tsx --test support/operator-ci-evidence.test.ts`; `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-timeline-investigation-flow.spec.ts --grep "starts at Home, applies a Timeline query, and opens its transaction"` | Present; exact-SHA browser receipt passed | ✅ covered |
| 243-01/T2 | 01 | 1 | UIV-01 | T-243-01, T-243-03 | Reject renamed/filtered identities or changed required-project/job topology. | Node contract + ExUnit | `cd examples/threadline_phoenix/e2e && ./node_modules/.bin/tsx --test support/operator-ci-evidence.test.ts`; `mix test test/threadline/browser_journey_evidence_contract_test.exs test/threadline/browser_full_projects_contract_test.exs` | Present; exact-SHA browser receipt passed | ✅ covered |
| 243-02/T1 | 02 | 2 | UIV-02, UIV-03 | T-243-04 | Every relevant source/tool/workflow/fixture mutation changes candidate identity; escaped paths are rejected. | Node contract | `cd examples/threadline_phoenix/e2e && ./node_modules/.bin/tsx --test support/operator-evidence-manifest.test.ts` | Present; focused and full suites passed | ✅ covered |
| 243-02/T2 | 02 | 2 | UIV-02, UIV-03 | T-243-05 | Candidate or custody mismatch fails before destructive setup; ordinary mode remains unchanged. | Node contract | `cd examples/threadline_phoenix/e2e && ./node_modules/.bin/tsx --test support/operator-candidate-receipt.test.ts` | Present; focused and full suites passed | ✅ covered |
| 243-02/T3 | 02 | 2 | UIV-02 | T-243-04, T-243-06 | Fresh 11-route full-shell output matches source, fixture and served assets without mutating reference bytes. | Node contract + browser capture | `cd examples/threadline_phoenix/e2e && ./node_modules/.bin/tsx --test support/operator-candidate-review.test.ts`; `THREADLINE_E2E_EVIDENCE=1 THREADLINE_E2E_CANDIDATE_RECEIPT=.planning/phases/243-integrated-verification-and-review-preview/243-CANDIDATE-RECEIPT.json MIX_TEST_PARTITION=operator_243_routes_$(date +%s)_$$ mix verify.example_browser --project=route-capture operator-page-capture.spec.ts` | Present; focused and full suites passed | ✅ covered |
| 243-03/T1 | 03 | 3 | UIV-03 | T-243-07, T-243-09 | Forged candidate, secret, asset or process ownership is rejected before signal/reset. | Node contract + ExUnit | `cd examples/threadline_phoenix/e2e && ./node_modules/.bin/tsx --test support/operator-preview-receipt.test.ts`; `mix test test/threadline/e2e_preflight_contract_test.exs` | Present; focused preflight and full suites passed | ✅ covered |
| 243-03/T2 | 03 | 3 | UIV-03 | T-243-08, T-243-09 | Real host auth protects direct entry; seeded preview reopens with exact shell/assets and fresh isolated DB. | Live preview + ExUnit | `cd examples/threadline_phoenix/e2e && THREADLINE_E2E_LIVE_PREVIEW=1 ./node_modules/.bin/tsx --test support/operator-preview-receipt.test.ts`; `mix test test/threadline/e2e_preflight_contract_test.exs` | Present; live lifecycle passed 5/5; exact-SHA CI passed | ✅ covered |
| 243-04/T1 | 04 | 4 | UIV-02 | T-243-10, T-243-11 | Findings link matched source/output hashes and conditions; raw captures contain only synthetic data. | Agent review + Node contract | `cd examples/threadline_phoenix/e2e && ./node_modules/.bin/tsx --test support/operator-candidate-review.test.ts` | Present; visual ledger and fresh capture validated | ✅ covered |
| 243-04/T2 | 04 | 4 | UIV-02 | T-243-12 | Policy/status copy retains host scope, unavailable-state meaning and refresh behavior. | ExUnit | `mix test test/threadline/operator_surface/live/policy_redaction_live_test.exs` | Present; 14/14 passed and full suite passed | ✅ covered |
| 243-04/T3 | 04 | 4 | UIV-02 | T-243-12 | Evidence footer links keep accessible labels, reachability and scoped meaning. | ExUnit | `mix test test/threadline/operator_surface/live/evidence_live_test.exs` | Present; 14/14 passed and full suite passed | ✅ covered |
| 243-05/T1 | 05 | 5 | UIV-02 | T-243-13, T-243-15 | Corrected candidate is freshly recaptured, findings are confirmed, and baseline/full-suite checks stay green. | Node contract + browser capture + full suite | `cd examples/threadline_phoenix/e2e && ./node_modules/.bin/tsx --test support/operator-candidate-review.test.ts support/operator-candidate-receipt.test.ts`; `THREADLINE_E2E_EVIDENCE=1 THREADLINE_E2E_CANDIDATE_RECEIPT=.planning/phases/243-integrated-verification-and-review-preview/243-CANDIDATE-RECEIPT.json MIX_TEST_PARTITION=operator_243_final_$(date +%s)_$$ mix verify.example_browser --project=route-capture operator-page-capture.spec.ts`; `mix ci.all` | Present; final capture and full suite passed | ✅ covered |
| 243-05/T2 | 05 | 5 | UIV-03 | T-243-14, T-243-15 | Preview stays loopback-only, source/asset/fixture-current, owned, and safely reopenable. | Preview + Node contract + ExUnit | `THREADLINE_E2E_EVIDENCE=1 THREADLINE_E2E_PREVIEW=1 THREADLINE_E2E_CANDIDATE_RECEIPT=.planning/phases/243-integrated-verification-and-review-preview/243-CANDIDATE-RECEIPT.json MIX_TEST_PARTITION=operator_243_preview_$(date +%s)_$$ mix verify.example_browser --preview`; `cd examples/threadline_phoenix/e2e && ./node_modules/.bin/tsx --test support/operator-preview-receipt.test.ts`; `mix test test/threadline/e2e_preflight_contract_test.exs` | Present; exact-SHA browser receipt passed | ✅ covered |
| 243-06/T1 | 06 | 6 | UIV-01, UIV-02, UIV-03 | T-243-16, T-243-17, T-243-18, T-243-19 | Evidence index reconciles exact candidate, CI, captures, findings, limits and baseline state without credentials/raw customer data. | Node contracts | `cd examples/threadline_phoenix/e2e && ./node_modules/.bin/tsx --test support/operator-ci-evidence.test.ts support/operator-candidate-review.test.ts support/operator-preview-receipt.test.ts` | Index and CI receipt present; 22 focused contracts passed | ✅ covered |
| 243-06/T2 | 06 | 6 | UIV-01, UIV-02, UIV-03 | T-243-16, T-243-17, T-243-18, T-243-19 | Push/dispatch is explicitly maintainer-controlled; exact-SHA required CI must pass before release-ready status. | Maintainer authorization gate | Maintainer push completed; run 38158769462 reconciled against the candidate SHA. | Maintainer action completed; run recorded | ✅ covered |
| 243-06/T3 | 06 | 6 | UIV-01, UIV-02, UIV-03 | T-243-16, T-243-17, T-243-18, T-243-19 | Missing/stale/failed/skipped/flaky CI evidence or unresolved high finding prevents release-ready recommendation. | CI receipt contract + exact-SHA required CI | `cd examples/threadline_phoenix/e2e && ./node_modules/.bin/tsx --test support/operator-ci-evidence.test.ts support/operator-candidate-review.test.ts support/operator-preview-receipt.test.ts` | Receipt present; exact-SHA jobs and 31/31 browser identities passed | ✅ covered |

---

## Wave 0 Requirements

- Existing ExUnit, Node, Playwright, Phoenix preview, and isolated PostgreSQL infrastructure covers the phase; no new framework, package, hosted service, or database migration is required.
- Add only contracts for material uncovered failure modes: required tests missing/filtered/skipped; normal verification changing baselines; candidate digest omitting workflow/evidence-tool edits; and forged/stale preview ownership or database identity.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None. Candidate visual judgment is assigned to a bounded agent review with reproducible evidence and explicit finding dispositions. The sole human checkpoint is the maintainer-authorized push/dispatch, not manual verification. | — | — | — |

---

## Validation Sign-Off

- [x] All tasks have automated verification or completed maintainer checkpoint evidence
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references; no validation gaps remain
- [x] No watch-mode flags in the recorded test commands
- [x] Focused checks and exact-SHA CI stayed within the recorded phase run windows
- [x] `nyquist_compliant: true` set in frontmatter after validation

**Approval:** Automated coverage audit complete; exact-SHA CI and required browser receipt passed.

## Validation Audit 2026-10-11

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
