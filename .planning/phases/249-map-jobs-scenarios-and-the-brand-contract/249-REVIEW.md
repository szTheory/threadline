---
phase: 249-map-jobs-scenarios-and-the-brand-contract
reviewed: 2026-11-12T06:21:45Z
reviewed_revision: 4f0b523efe0af4a0190d8aac07642ac6d2c90c9d
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
  warning: 1
  info: 0
  total: 1
  necessity: 0
status: issues_found
---

# Phase 249: Code Review Report

**Reviewed:** 2026-11-12T06:21:45Z
**Reviewed revision:** `4f0b523efe0af4a0190d8aac07642ac6d2c90c9d`
**Depth:** standard
**Files Reviewed:** 18
**Status:** issues_found

## Summary

Re-reviewed the exact 18-file scope at the current revision. WR-01 and WR-02 are fixed: expected classes are pinned per scenario ID, and nonblank unique IDs are checked within each reference list without rejecting IDs shared across separate lists. The changed carry mappings to the durable v1.48 research and existing route-test owner match their stated limitations. WR-03 remains open: the replacement source map still depends on the active milestone `REQUIREMENTS.md`, which normal milestone completion archives and removes. The fixer reports 32 focused Node tests passing, including a fixture without `.planning/phases`; that fixture does not cover this active-requirements lifecycle. I did not rerun suites or perform a TypeScript typecheck.

## Narrative Findings (AI reviewer)

### WR-03: Focused contract test reads active requirements that milestone completion removes

**Classification:** WARNING
**File:** `examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts:71-76,991-997`; `examples/threadline_phoenix/e2e/support/operator-journey-inventory.json:2210-2220`
**Issue:** The source map still eagerly reads `.planning/REQUIREMENTS.md`, and the ADM-06 carry source references both its requirement text and the transient `Pending` row. The repository's milestone-completion workflow archives that file as `.planning/milestones/v1.48-REQUIREMENTS.md` and then removes the active `.planning/REQUIREMENTS.md`. After completion, the focused test fails at module load with `ENOENT`; if a later milestone creates a new active requirements file, the old ADM-06 locator is absent and the inventory reference validation fails instead. The private fixture that omits only `.planning/phases` does not exercise either state.
**Fix:** Make this specific v1.48 source lifecycle explicit: use the active requirements source before closeout and the versioned archive after closeout, with a focused fixture for each; keep the ADM-06 reference on stable requirement wording and preserve the unresolved flag and later owners without promoting the contract test into classifier or human-acceptance proof.

---

_Reviewed: 2026-11-12T06:21:45Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
