---
phase: 238-current-main-preview-and-acceptance-baseline
reviewed: 2026-10-09T04:54:13Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - examples/threadline_phoenix/e2e/playwright.config.ts
  - examples/threadline_phoenix/e2e/run-e2e.sh
  - examples/threadline_phoenix/e2e/support/operator-browser-evidence.ts
  - examples/threadline_phoenix/e2e/support/operator-evidence-manifest.test.ts
  - examples/threadline_phoenix/e2e/support/operator-evidence-manifest.ts
  - examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts
  - examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts
  - test/fixtures/operator_surface/README.md
  - test/fixtures/operator_surface/route-inventory.json
  - test/fixtures/operator_surface/source-surface-checklist.json
  - test/partition_weights.txt
  - test/threadline/operator_surface/operator_evidence_contract_test.exs
  - test/threadline/operator_surface/operator_surface_fixture_contract_test.exs
  - test/threadline/operator_surface/rendered_output_contract_test.exs
findings:
  critical: 2
  warning: 2
  info: 0
  total: 4
status: issues_found
---

# Phase 238: Code Review Report

**Reviewed:** 2026-10-09T04:54:13Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

Reviewed the exact task-commit source scope supplied in `/tmp/threadline-238-review-scope.json`, including the initial implementation and `2a1887e9`, in the retained isolated worktree. Inspected complete implementations and their path, configuration, alias, source-inventory and evidence-validation dependencies; used immutable base `9eefb75c` for regression context. No structural pre-pass or external reviewer lane was supplied.

Two blockers remain: a caller-selected evidence manifest can bypass custody validation, and the new argument arrays break ordinary runner invocation on macOS system Bash. Two warnings concern focused capture execution and a machine-specific test executable. Existing product UI findings, actual browser zoom and clipboard-denial limitations are outside these implementation findings.

Verification during review: the 20 Node contracts passed with Homebrew Bash first on PATH; the same contracts under the default macOS PATH executed 20 tests with 14 passes and six failures, including the new empty-array failures. The standalone committed-fixture ExUnit contract executed 10 tests with zero failures. In-memory mutation probes executed the actual embedded custody validator and actual capture teardown body and reproduced the two gaps described below. Source files, running previews and retained evidence were not modified; no commit was made.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Caller-selected manifest can bypass source, asset and output validation

**Classification:** BLOCKER

**File:** `test/threadline/operator_surface/operator_evidence_contract_test.exs:200` (also lines 228–233)

**Issue:** `live_catalog!/3` validates only directory entries named `manifest.json` or ending in `-manifest.json`. The independently supplied `THREADLINE_OPERATOR_EVIDENCE_MANIFEST` may name any existing file inside that accepted bundle. It is then parsed separately as `main`, where only expected capture IDs and the total count are checked. A copy named `selected-evidence.json` therefore bypasses serialization, source identity, ancestry, fixture, served/local asset and actual output-byte checks. Valid neighboring manifests provide the findings catalog, so they do not make the selected manifest trustworthy. Explicit live mode can succeed with the selected manifest pointing to absent output and forged hashes/source metadata, contradicting its fail-closed custody contract.

**Evidence:** Executed the exact embedded Node validator against the real accepted bundles, intercepting only the read of an in-memory `selected-evidence.json` sibling. Changed its `baseSha` to `forged` and its first capture's `outputPath` to `missing-output.png` and `outputSha256` to `forged`. Validation returned successfully while all actual neighboring manifests still underwent their normal checks. This probe changed no on-disk evidence.

**Fix:** Resolve and contain the supplied main path, then pass it through the same manifest-validation routine as every enumerated manifest, independently of its basename. Reuse the resulting verified object for route completeness and preview comparison. Add a live negative control with a nonmatching filename and corrupt source/output metadata, plus a positive control for a valid renamed manifest.

### CR-02: New empty-array expansions abort the runner on macOS system Bash

**Classification:** BLOCKER

**File:** `examples/threadline_phoenix/e2e/run-e2e.sh:32` (also lines 420 and 504)

**Issue:** With `set -u`, macOS `/bin/bash` 3.2 treats the expansion of an empty array as an unbound variable. The newly added `set -- "${FORWARDED_ARGS[@]}"` runs unconditionally. A no-argument ordinary invocation, `--preview` alone, or the environment-based stop invocation all abort at line 32 before reaching their intended behavior. With forwarded arguments present, the newly added empty `PROJECT_ARGS` expansion breaks the default dark argument path at line 420 or final browser launch at line 504. The public Mix aliases select `bash` from PATH, and this worktree's default resolves to `/bin/bash`; the successful Homebrew-Bash runs conceal this compatibility regression. The existing origin parser's Bash-4 syntax is separate: the new failure is unconditional and occurs before that parser or any database setup.

**Evidence:** `THREADLINE_E2E_ARGUMENTS_ONLY=1 /bin/bash examples/threadline_phoenix/e2e/run-e2e.sh` exits 1 with `line 32: FORWARDED_ARGS[@]: unbound variable`. The default-PATH Node run reproduces six failures, while prepending the installed Bash 5 yields 20/20 passing contracts.

**Fix:** Use nounset-safe array forwarding at every new expansion, preserving zero arguments without adding an empty string, for example `set -- ${FORWARDED_ARGS[@]+"${FORWARDED_ARGS[@]}"}` and the equivalent guarded `PROJECT_ARGS` expansion. Add explicit system-Bash regression coverage for no arguments, both preview-stop entrypoints, and the dark lane with arguments. If the project instead adopts a newer minimum Bash, resolve and enforce that executable in the public Mix aliases with an actionable diagnostic before claiming ordinary compatibility.

## Warnings

### WR-01: Route aggregation makes individually selected captures fail teardown

**Classification:** WARNING

**File:** `examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts:422`

**Issue:** The evidence-mode `afterAll` always reads all eleven route manifests plus the degraded Timeline manifest, regardless of the selected tests. A valid fresh `--grep home`, single-route invocation or `--last-failed` rerun produces only the selected artifacts, then fails with ENOENT for another route. The route tests are individually named and the phase's initial home tracer explicitly uses `--grep home`; aggregation has made that supported focused workflow unusable. A failure/retry can also report missing unrelated manifests alongside the original failure.

**Evidence:** Executed the exact teardown body with the files a successful fresh home-only selection supplies. It immediately failed reading `route.timeline-manifest.json`. No browser, process or on-disk capture was altered.

**Fix:** Publish valid partial manifests for the tests actually selected/executed, with completeness asserted only by the explicit full eleven-route acceptance gate. Preserve a failure for genuinely missing selected captures; do not silently label a subset complete. Add a focused-selection teardown contract and retain the existing complete-run route check.

### WR-02: New runner contract depends on an Apple Silicon Homebrew installation

**Classification:** WARNING

**File:** `examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts:23`

**Issue:** The System/project-forwarding contract hardcodes `/opt/homebrew/bin/bash`. Running this new test on the repository's Ubuntu CI platform, Intel macOS with a different Homebrew prefix, or a clean environment without that installation fails with ENOENT before testing argument forwarding. Its neighboring runner tests and the public Mix aliases resolve `bash` from PATH. This makes the focused contract suite depend on the implementation machine and prevents it from serving as a portable regression check.

**Evidence:** The exact executable is visible in the new test; supported workflows use `ubuntu-24.04`, and `verify_example_browser/1` and `verify_example_browser_light/1` call `System.cmd("bash", ...)`.

**Fix:** Resolve `bash` through PATH, following the public runner contract, or share a documented portable executable resolver if a minimum Bash version is adopted. Verify the focused Node suite on Linux and the supported macOS path rather than embedding a developer-specific installation prefix.

---

_Reviewed: 2026-10-09T04:54:13Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
