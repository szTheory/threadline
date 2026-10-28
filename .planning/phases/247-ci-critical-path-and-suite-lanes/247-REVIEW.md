---
phase: 247-ci-critical-path-and-suite-lanes
reviewed: 2026-10-27T17:33:15Z
depth: deep
files_reviewed: 3
files_reviewed_list:
  - .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_case.exs
  - .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py
  - .planning/phases/247-ci-critical-path-and-suite-lanes/tools/test_exunit_boundary_probe.py
findings:
  critical: 1
  warning: 2
  info: 0
  total: 3
status: issues_found
---

# Phase 247: Incremental Code Review Report — Plans 23–25

**Reviewed:** 2026-10-27T17:33:15Z
**Depth:** deep
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Reviewed the three scoped local tools against Plans 23–25 and the saved recheck evidence. The new pinned native ARM64 compile smoke exited 0 and emitted `THREADLINE_COMPILE_SMOKE|ok`; its only stderr was an unused-variable warning at runner line 140. The strict any-stderr rule therefore made the preflight `INVALID`, ran zero ExUnit arms, and produced no semantic result. This differs observably from the immutable Plan 22 receipt, which records an OTP compiler exception before a marker. CR-05 remains open as a semantic-readiness blocker, not as a claim that the current compiler still crashes.

Plan 25 records a matching owned container name/CID and successful CID-only cleanup for its sole child. This satisfies current-run ownership evidence but cannot repair Plan 22's historical missing identity. The independent disposition also identifies two verifier/evidence limits confirmed in source: INVALID preflight details are not recomputed, and preflight elapsed time is not recorded. CI-02 remains INCOMPLETE, CI-03 remains MISS at `1.24/1.28/1.27`, and Phase 247 remains 2/4.

## Critical Issues

### CR-05: The pinned runner still has no semantic result (current warning is not the historical compiler crash)

**Severity:** BLOCKER
**File:** `.planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_case.exs:140`
**Issue:** The Plan 22 immutable receipt records an OTP compiler exception before runtime identity or events. The current Plan 25 receipt is materially different: the pinned ARM64 compiler exited 0 and emitted the compile-smoke marker, but the unused `mode` argument emits a warning. The coordinator treats any compile-smoke stderr as `compile_smoke_stderr_present` (`exunit_boundary_probe.py:873-890, 1838-1858`), so the strict preflight is terminal `INVALID` and launches zero semantic arms. The current failure is the warning-gated preflight, not a continuing compiler crash; the underlying semantic-readiness gate remains open.

**Fix:** Remove or use the unused argument, then obtain a separately authorized preflight and semantic run. Preserve both historical receipts and do not reuse the consumed Plan 25 grant.

## Warnings

### WR-01: Playwright list parsing is ambiguous when a title contains the separator (inherited; deferred)

**Severity:** WARNING
**File:** `examples/threadline_phoenix/e2e/support/operator-ci-evidence.ts:51-54`
**Issue:** `parseDiscovered` splits display output on ` › `, which can also occur in a valid test title. Discovered and executed identities can then disagree. This is inherited, outside the Plan 23–25 source scope, and remains deferred.

**Fix:** Build identities from structured Playwright output or encode title-path components unambiguously.

### WR-04: Plan 22 preflight and arm receipts lack historical owned-container identity

**Severity:** WARNING
**File:** `.planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py:911-925`
**Issue:** The Plan 22 receipts do not preserve sufficient owned container identity to independently tie cleanup to a specific container. The current implementation records name, captured CID, inspected name, and cleanup outcome; Plan 25's one child has matching identity and successful CID-only cleanup. That current evidence does not retroactively fill the immutable Plan 22 gap, so the inherited finding remains open only for the historical evidence.

**Fix:** Keep the old finding open as a historical evidence limitation; retain per-child name/CID/inspect/cleanup evidence for any separately authorized future run.

### WR-05: INVALID preflight verification accepts an unsubstantiated reason and compile result — FIXED 8c9f1541

**Severity:** WARNING
**File:** `.planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py:1875-1895`
**Issue:** `check_recheck_preflight` recomputes compile output, runtime, image, and ownership predicates only inside the `status == "VALID"` branch. For an `INVALID` receipt it only checks that the status is one of the allowed values, then verifies source and reservation bindings. A pure-Python probe against the saved receipt returned no errors after changing its result reason to `forged-invalid-reason`; changing `compile_smoke_result` to a fabricated semantic result also returned no errors. Consequently `--verify` can accept a self-consistent report projection whose INVALID cause or compile classification is not supported by the raw child fields.

**Fix:** For INVALID preflights, derive `compile_smoke_result` and the expected reason from the captured exit code, stdout, stderr, runtime, and ownership fields; reject a result whose cause is not reproduced from those fields. Add negative controls for modified reason/status and fabricated compile results.

### WR-06: Recheck preflight receipts cannot establish the elapsed-time cap — FIXED FOR NEW RECEIPTS 8c9f1541

**Severity:** WARNING
**File:** `.planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py:1810-1823, 1829-1837, 1868-1913`
**Issue:** The reservation stores only the preflight start monotonic timestamp. The preflight receipt records no finish timestamp or elapsed duration, and its verifier does not validate the 45-second preflight limit. Although the child and image-inspection helpers have individual timeouts, the raw evidence cannot establish that the overall preflight stayed within its plan cap. The recorded Plan 25 child's cleanup evidence does not supply this missing timing evidence.

**Fix:** Record monotonic preflight start/end and elapsed duration, enforce one deadline across image inspection and the child, and have verification check both the recorded duration and the cap.

## Verification Performed

- Read the Plan 23 review, Plans 23–25, their summaries, the authorization, machine decision, raw preflight, projected report, reservation, and recheck disposition.
- Traced the warning, strict stderr classification, owned-container capture/cleanup, INVALID verification branch, and preflight timing fields in the three scoped tools.
- Pure-Python verifier probe: the saved raw preflight returned no errors; changing its INVALID reason and separately fabricating its `compile_smoke_result` also returned no errors. No test suite was run.
- No Docker, Elixir, Mix, CI, network, install, source edit, or new observation was performed.

## Prior Finding Disposition

`CR-01` through `CR-04`, `WR-02`, `WR-03`, and `IN-01` remain historically fixed as recorded in `247-REVIEW-DISPOSITION.md`. `WR-01` remains deferred. `CR-05` remains open with the current no-semantic-result evidence distinguished from the old compiler-exception receipt. `WR-04` remains open for the Plan 22 historical identity gap; Plan 25's owned CID is verified for its own child. `WR-05` and `WR-06` are fixed in source by offline repair commit `8c9f1541`; the independent repair review is clean. Historical Plan 25 timing is not retroactively supplied. No old receipt or disposition was rewritten.

---

_Reviewed: 2026-10-27T17:33:15Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_

## Offline repair re-review

Commit 8c9f1541 fixes WR-05/T-247-48 and implements WR-06 for new producer-bound `/2` preflights. The independent 247-OFFLINE-REPAIR-REVIEW.md reports zero findings. Fresh checks: 37 Python tests, synthetic round-trip, old receipt/report verification and warning-free host compile-only all pass. The `_mode` edit removes the reported warning; no pinned-runtime/ExUnit arm was run. CR-05 remains an empirical semantic-readiness gap; WR-04 remains historical; WR-01 remains deferred. Current active counts: 1 critical, 2 warnings, 0 info. Timing consistency is verified; authenticated physical elapsed time remains a documented provenance boundary. See 247-OFFLINE-REPAIR.md.
