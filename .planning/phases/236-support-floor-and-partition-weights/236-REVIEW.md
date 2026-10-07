---
phase: 236-support-floor-and-partition-weights
reviewed: 2026-10-07T18:04:15Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - .github/workflows/ci.yml
  - CHANGELOG.md
  - README.md
  - guides/upgrade-path.md
  - mix.exs
  - test/threadline/ci_topology_contract_test.exs
  - test/threadline/ci_workflow_parity_contract_test.exs
  - test/threadline/guides/upgrade_path_contract_test.exs
  - test/partition_weights.txt
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 236: Code Review Report

**Reviewed:** 2026-10-07T18:04:15Z  
**Depth:** standard  
**Files Reviewed:** 9  
**Status:** issues_found

## Summary

The PostgreSQL floor change and its source-derived contracts are consistent across CI, Mix, the guide, README, and changelog. The partition inventory contract checks path coverage, duplicates, malformed rows, and ordering. One comment in the weights file now describes only the runner's fallback behavior and conflicts with the new CI contract, which rejects missing or stale rows.

## Warnings

### WR-01: Weight-file comment understates the effect of stale or missing rows

**File:** `test/partition_weights.txt:5-6`  
**Issue:** The comment says a stale or missing entry “only makes the partitions less even,” but the new inventory contract in `test/threadline/ci_topology_contract_test.exs` fails when either occurs. The runner still assigns every discovered test exactly once, but CI will fail the contract, so the comment gives maintainers an incomplete description of the consequences.  
**Fix:** Clarify the distinction: the runner tolerates stale or missing weights for assignment, while the committed-inventory contract rejects them in CI.

---

_Reviewed: 2026-10-07T18:04:15Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
