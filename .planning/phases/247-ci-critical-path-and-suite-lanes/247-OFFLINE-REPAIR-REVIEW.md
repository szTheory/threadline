---
phase: 247-ci-critical-path-and-suite-lanes
reviewed: 2026-10-27T18:15:45Z
depth: deep
files_reviewed: 3
files_reviewed_list:
  - .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_case.exs
  - .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py
  - .planning/phases/247-ci-critical-path-and-suite-lanes/tools/test_exunit_boundary_probe.py
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# Phase 247: Offline Repair Code Review

**Reviewed:** 2026-10-27T18:15:45Z  
**Depth:** deep  
**Files Reviewed:** 3  
**Status:** clean

## Summary

Reviewed the three uncommitted offline repair files, the previous WR-05/WR-06 and CR-05 findings, and security threat T-247-48. The INVALID preflight verdict and its compile/runtime projections are now derived from raw output, and timing/deadline evidence is present. No derived-field inconsistency was found when the raw timing observations are held fixed.

The changed Elixir argument rename is consistent with the function's current behavior. I did not run Docker, pinned-runtime observations, CI, or a new timing series; those outcomes remain unobserved.

## Timing Evidence Boundary

WR-06's original evidence defect is fixed for new `/2` preflight receipts: they record start, end, elapsed, and limit values; verification checks the arithmetic, cap, child containment, and reservation binding to the preflight start. Historical Plan 25 `/1` evidence remains without these fields and is not retroactively upgraded.

These checks establish internal consistency and a bounded execution path, not authenticated physical elapsed time. A party able to coherently rewrite every raw timestamp can also rewrite the derived elapsed values while retaining the reserved start. That is a provenance limit of local self-reported monotonic observations, not a separate code blocker. Pinned producer output or independent review attestation is needed to strengthen that trust boundary. No additional sidecar or minimum-runtime oracle is recommended.

With the raw timing observations unchanged, changing only the derived `elapsed_ns` fails `timing_errors` as inconsistent; changing only the derived result status/reason fails comparison with `derive_recheck_preflight_result`. No concrete derived-claim counterexample was identified.

The final deadline delta was also reviewed: `run_owned_container` clamps its child deadline to the supplied absolute parent deadline and derives every Docker operation timeout from that clamped deadline; `recheck_preflight` passes its absolute deadline through. The fake-clock regression checks that Docker operations receive no more than remaining time and the child timing ends within the parent deadline. No defect found in this delta. The parent reports 37 pure-mock tests and the offline self-test passing; I did not rerun them.

Coordinator source SHA-256 at final review: `2ec1b603a4566f3e136d5cb7b0b68169036250f276777ee6e647eb758f610ab1`.

## Prior Finding Disposition

- **WR-05 / T-247-48:** The previous fabricated INVALID reason and compile/runtime projection cases are now re-derived and rejected by the updated verifier. The inspected changes address the prior finding.
- **WR-06:** Original missing fields and cap enforcement are implemented for new `/2` receipts; the older Plan 25 `/1` record remains historically unmeasured. Authenticated elapsed-time proof is a provenance limitation, not an additional finding.
- **CR-05:** The `_mode` rename removes the reported unused-variable warning in the source. Pinned runtime semantic readiness remains unobserved; this offline review does not close CR-05.

---

_Reviewed: 2026-10-27T18:15:45Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: deep_
