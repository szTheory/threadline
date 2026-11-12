---
phase: 249-map-jobs-scenarios-and-the-brand-contract
reviewed: 2026-11-12T05:45:56Z
depth: standard
files_reviewed: 18
files_reviewed_list:
  - examples/threadline_phoenix/DEMO-MANIFEST.md
  - examples/threadline_phoenix/WALKTHROUGH.md
  - examples/threadline_phoenix/e2e/run-e2e.sh
  - examples/threadline_phoenix/e2e/support/operator-ci-evidence.test.ts
  - examples/threadline_phoenix/e2e/support/operator-journey-inventory.json
  - examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/manifest.ex
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed.ex
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/exports.ex
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/filler.ex
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/personas.ex
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/support.ex
  - examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_contract_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix/walkthrough_doc_contract_test.exs
findings:
  critical: 0
  warning: 3
  info: 0
  total: 3
  necessity: 0
status: issues_found
---

# Phase 249: Code Review Report

**Reviewed:** 2026-11-12T05:45:56Z  
**Depth:** standard  
**Files Reviewed:** 18  
**Status:** issues_found

## Summary

Reviewed the full resolved 18-file phase scope, including the seed call paths, their database contracts, and the semantic inventory validators. The seed timestamp and actor assertions align with the changed writes. Three warning-level gaps remain in the inventory validation and its focused test harness; no blocker-level runtime defect was established.

## Narrative Findings (AI reviewer)

### WR-01: Scenario class changes bypass class-specific validation

**Classification:** WARNING  
**File:** `examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts:596-685`  
**Issue:** The required scenario IDs are checked, but their expected `class` values are not. The checks at lines 661-686 only apply the comparison-baseline rule when `candidate.class` is exactly `stress`, and the ordinary-data rule when it is exactly `ordinary`. Changing `scenario.state-empty` to `boundary` and removing its `ordinaryBaseline` therefore bypasses both checks while its ID still satisfies the required list. This lets the contract accept a misclassified named stress scenario.  
**Fix:** Pin the expected class for each required scenario ID before applying class-specific rules, and add a negative control that changes a stress scenario to `boundary` while removing its baseline.

### WR-02: Reference identity checks miss blank and duplicate brand-role IDs

**Classification:** WARNING  
**File:** `examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts:551-556,614-625,718-757`  
**Issue:** The Acme scenario check collects `fixtureIds`, but only compares set size to list length; a single fixture reference with no `id` becomes `{ "" }` and passes. The generic scenario loop at lines 614-625 does not check fixture IDs at all, so missing or duplicate IDs there also pass. Brand-role source and proof IDs are collected at lines 720-721 and used by U3 criteria, but are never checked for blanks or duplicates. As a result, incomplete or ambiguous reference identities can pass the semantic inventory contract.  
**Fix:** Apply one helper to every identity-bearing reference list, requiring each ID to be non-empty and the set size to equal the list length. Add mutation controls for a missing Acme fixture ID, missing/duplicate named-scenario fixture IDs, and duplicate/blank brand-role source and proof IDs.

### WR-03: Focused contract test reads planning files that normal cleanup moves

**Classification:** WARNING  
**File:** `examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts:71-81`  
**Issue:** Module initialization reads six files beneath `.planning/phases/249-map-jobs-scenarios-and-the-brand-contract/` with `readFileSync`. The repository cleanup workflow moves completed phase directories from `.planning/phases/` to `.planning/milestones/v{X.Y}-phases/` by default. After that routine archive, rerunning this focused contract test fails during module loading with `ENOENT`, before any assertions run.  
**Fix:** Keep the contract test's source map limited to durable source paths, or resolve archived planning evidence through a maintained archive-aware path instead of hard-coding the live phase directory.

---

_Reviewed: 2026-11-12T05:45:56Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
