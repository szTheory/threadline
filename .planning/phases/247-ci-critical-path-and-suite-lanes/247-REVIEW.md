---
phase: 247-ci-critical-path-and-suite-lanes
reviewed: 2026-10-27T01:11:34Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts
  - bin/ci-test-partitions
  - test/partition_weights.txt
  - test/partition_weights_latest.txt
  - test/partition_weights_min.txt
  - test/threadline/ci_topology_contract_test.exs
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 247: Code Review Report

**Reviewed:** 2026-10-27T01:11:34Z
**Depth:** standard
**Files Reviewed:** 6 (incremental Plan 14 and Plan 15 test-fix scope)
**Status:** issues_found

## Summary

Reviewed the CI partition runner and project resolver, main CI measurement reader, ExUnit partition monitor, browser timing and receipt tooling, their Node contract tests, test setup, Playwright config, and CI workflow. The phase-summary scope also includes many pre-existing Elixir contract tests whose phase changes only add the `:repo_contract` classification tag; those tag-only edits do not change test behavior. CI-03's recorded numeric miss is an acceptance gap, not a code defect, and is excluded from findings.

The incremental Plan 14 review covered `bin/ci-test-partitions`, `test/partition_weights.txt`, `test/partition_weights_min.txt`, `test/partition_weights_latest.txt`, and `test/threadline/ci_topology_contract_test.exs`. Strict ingestion constrains explicit destinations to the three committed weight files, validates three distinct complete four-partition runs against the exact lane inventory, rejects malformed, duplicate, missing, wrong-lane, and stale observations, and writes by same-directory replacement. Lane selection rejects unknown values before compilation; exact-once assignment and colocation/watchdog paths remain wired through the existing runner. The five-file delta introduced no new confirmed findings.

The temporary routing-test coverage warning recorded in `247-14-REVIEW.md` was resolved before final review: sentinel weights now differ by lane, the test compares actual assignment TSVs against lane-specific expected assignments, and a mutation that routes latest through current weights must diverge. The report's existing WR-01 and its deferred disposition remain unchanged. Per the 247-14 summary, local full and min/toolchain suites and both Bash self-tests passed; local ratios are not main-run acceptance evidence. CI-03's numeric claim remains pending the required post-landing main runs.

The Plan 14 artifact provenance records three successful attempt-1 main runs at the recorded head, 12 TSVs per lane across three runs, and exact inventories of 206 scoped files for min/latest and 269 full files for current. The committed weight files are path sorted and positive; timing observations of zero milliseconds are valid and their generated medians are floored at 1 ms.

The incremental Plan 15 test-fix review also covered `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts`. After confirming the stress modal, the test now waits for it to become hidden and for the exact “Show Modal” trigger to regain focus before it moves focus to the persistent toast and presses Enter. This pins the expected dialog dismissal/focus-restoration sequence and removes the observed focus race from the test; the change does not alter product code. No new finding was confirmed. The final targeted zero-retry check and full `ci.all` run were in progress at review time and were not run by this reviewer.

## Warnings

### WR-01: Playwright list parsing is ambiguous when a title contains the separator (pre-existing)

**File:** `examples/threadline_phoenix/e2e/support/operator-ci-evidence.ts:51-54`
**Issue:** `parseDiscovered` splits a `playwright test --list` line on ` › ` and `parseExecuted` treats the corresponding JSON title as one title-path element. Playwright titles are arbitrary strings and may themselves contain ` › `. For example, a test declared with title `opens A › B` is emitted with that text in the final title segment; this parser splits it into `opens A` and `B`, so its discovered identity does not match the executed/inventory identity and the receipt job fails. Deterministic reproduction from the repository root (no browser required): `node --experimental-strip-types --input-type=module -e 'import {parseDiscovered, identityKey} from "./examples/threadline_phoenix/e2e/support/operator-ci-evidence.ts"; const got=parseDiscovered("[desktop-chromium] › tests/example.spec.ts:4:1 › opens A › B")[0]; console.log(got.titlePath, identityKey(got) === identityKey({project:"desktop-chromium",file:"tests/example.spec.ts",titlePath:["opens A › B"]}));'` prints `[ 'opens A', 'B' ] false`. Git blame attributes the ambiguous regex and split at lines 51-54 to `81c920e4` (2026-10-23), before phase 247. Phase 247 commit `3e832c12` adds multi-file fan-in but leaves this parser unchanged, so this is an inherited defect carried into the new required receipt fan-in rather than a newly introduced parser change.
**Fix:** Avoid parsing the display-oriented `--list` output for machine identities. Generate the discovered identity list from a structured Playwright reporter/API, or use an unambiguous encoding for each title-path component and decode it before `identityKey` comparison.

---

_Reviewed: 2026-10-27T01:11:34Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
