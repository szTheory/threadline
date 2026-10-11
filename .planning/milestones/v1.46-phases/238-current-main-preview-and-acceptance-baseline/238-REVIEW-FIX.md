---
phase: 238-current-main-preview-and-acceptance-baseline
reviewed: 2026-10-09T05:01:10Z
depth: standard
scope: four-original-findings-only
repair_commit: a2b4f350d2f150ffadd4b8fa4b7f10e2ae20523d
original_review: 238-REVIEW.md
files_reviewed: 6
files_reviewed_list:
  - examples/threadline_phoenix/e2e/run-e2e.sh
  - examples/threadline_phoenix/e2e/support/operator-evidence-manifest.test.ts
  - examples/threadline_phoenix/e2e/support/operator-evidence-manifest.ts
  - examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts
  - examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts
  - test/threadline/operator_surface/operator_evidence_contract_test.exs
fixed: 4
skipped: 0
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# Phase 238: Code Review Fix Report

Rechecked only the four findings from `238-REVIEW.md` against repair commit `a2b4f350d2f150ffadd4b8fa4b7f10e2ae20523d`. All four are fixed. The original review remains unchanged; this report does not claim a second review of the full phase or fresh browser acceptance.

## Fixed Issues

### CR-01: Caller-selected manifest can bypass source, asset and output validation

**Original classification:** BLOCKER. **Outcome:** Fixed.

`operator_evidence_contract_test.exs:196–206` resolves the selected path, inserts its exact basename into the accepted bundle's validation set, and checks each resolved manifest remains directly inside that bundle. The selected object must pass the same canonical serialization, source identity, fixture, asset and output checks as neighboring manifests. The final route/count checks use that verified object and fail if none was validated.

**Evidence:** Executed the exact embedded live validator with a virtual `selected-evidence.json` sibling. A valid renamed manifest passed; independently altered base SHA, output SHA and missing output path each failed. Existing capture and asset bytes were read from the retained bundle. To isolate selection validation from previously captured source identity, candidate metadata was refreshed only in memory and the candidate-identity function was held to that identity; no source or evidence files were changed. The new live contract also copies a bundle and exercises the renamed-path positive case and all three negatives when live mode is requested. The independent static evidence contract run passed 10/10 tests.

### CR-02: New empty-array expansions abort the runner on macOS system Bash

**Original classification:** BLOCKER. **Outcome:** Fixed.

`run-e2e.sh:32,420,504` now uses nounset-safe array forwarding for both argument arrays, preserving zero arguments and each supplied argument. Host normalization uses portable `tr` rather than Bash 4 lowercase expansion. The diagnostic prints no phantom empty argument for an empty invocation.

**Evidence:** Independently executed both Node contract files under the default macOS PATH: 23/23 passed. The contracts include explicit `/bin/bash` and PATH `bash` zero-argument and spaced-argument probes, the ordinary mocked lifecycle, and System/light argument forwarding. This reproduces the environment in which the original review failed and verifies the actual launch forwarding as well as its diagnostic.

### WR-01: Route aggregation makes individually selected captures fail teardown

**Original classification:** WARNING. **Outcome:** Fixed.

`operator-page-capture.spec.ts` records route tests that start after evidence/project skip checks and passes that selection to `writeRouteBundle` in teardown. `operator-evidence-manifest.ts:208–217` aggregates only selected route manifests, explicitly marks a subset as `partial-direct-route-selection`, returns without writing for an empty selection, and still throws when a selected manifest is absent. Full-baseline acceptance retains its independent eleven-route/135-output requirements.

**Evidence:** The independently executed aggregation contract passed: a home-only selection writes one partial capture, a missing selected timeline manifest fails, and an empty selection leaves the previous manifest untouched. Inspected the production selection and teardown wiring; it no longer reads every inventory route for a focused run.

### WR-02: New runner contract depends on an Apple Silicon Homebrew installation

**Original classification:** WARNING. **Outcome:** Fixed.

`operator-route-evidence.test.ts:23` invokes PATH `bash`; no Homebrew executable path remains in this test. Additional shell probes cover PATH `bash` and `/bin/bash` when present.

**Evidence:** The independent default-PATH Node run passed 23/23 without prepending Homebrew. Both explicit system-shell and PATH-shell probes passed. The parent-provided Bash 5 run log also records 23/23 passing; this corroborates portability without serving as a new browser acceptance claim.

## Skipped Issues

None. No original finding remains unresolved within this targeted recheck.

---

_Reviewer: gsd-code-reviewer. No implementation edits or commit were made._
