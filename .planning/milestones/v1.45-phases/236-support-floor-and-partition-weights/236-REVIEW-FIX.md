---
phase: 236-support-floor-and-partition-weights
fixed_at: 2026-10-07T18:08:41Z
review_path: .planning/phases/236-support-floor-and-partition-weights/236-REVIEW.md
iteration: 2
findings_in_scope: 1
fixed: 1
skipped: 0
status: all_fixed
---

# Phase 236: Code Review Fix Report

**Fixed at:** 2026-10-07T18:08:41Z  
**Source review:** `.planning/phases/236-support-floor-and-partition-weights/236-REVIEW.md`  
**Iteration:** 2

**Summary:**
- Findings in scope: 1
- Fixed: 1
- Skipped: 0

## Fixed Issues

### WR-01: Weight regeneration restores the obsolete comment

**Files modified:** `bin/ci-test-partitions`, `test/partition_weights.txt`  
**Commit:** `ce7e2763`  
**Applied fix:** Updated the canonical writer and checked-in header to clarify that the runner tolerates stale or missing weights while assigning every discovered test exactly once, while the committed-inventory CI contract rejects either condition. Added a self-test assertion that checks both emitted comment lines.

## Verification

Ran in the main checkout. Added the self-test assertion first and confirmed `bin/ci-test-partitions --self-test` failed against the old writer output. After updating the writer and checked-in header, `bin/ci-test-partitions --self-test` passed, and `mix test test/threadline/ci_topology_contract_test.exs` passed (25 tests, 0 failures). `bash -n bin/ci-test-partitions` and `git diff --check -- bin/ci-test-partitions test/partition_weights.txt` passed.

---

_Fixed: 2026-10-07T18:08:41Z_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 2_
