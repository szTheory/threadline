---
phase: 247-ci-critical-path-and-suite-lanes
reviewed: 2026-10-27T00:02:50Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - .github/workflows/ci.yml
  - bin/browser-full-projects
  - bin/ci-test-partitions
  - bin/measure-main-ci
  - examples/threadline_phoenix/e2e/support/operator-ci-evidence.ts
  - examples/threadline_phoenix/e2e/support/operator-ci-evidence.test.ts
  - examples/threadline_phoenix/e2e/support/slow-specs.ts
  - examples/threadline_phoenix/e2e/support/slow-specs.test.ts
  - examples/threadline_phoenix/e2e/playwright.config.ts
  - test/support/partition_monitor.ex
  - test/test_helper.exs
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 247: Code Review Report

**Reviewed:** 2026-10-27T00:02:50Z  
**Depth:** standard  
**Files Reviewed:** 11  
**Status:** issues_found

## Summary

Reviewed the CI partition runner and project resolver, main CI measurement reader, ExUnit partition monitor, browser timing and receipt tooling, their Node contract tests, test setup, Playwright config, and CI workflow. The phase-summary scope also includes many pre-existing Elixir contract tests whose phase changes only add the `:repo_contract` classification tag; those tag-only edits do not change test behavior. CI-03's recorded numeric miss is an acceptance gap, not a code defect, and is excluded from findings.

## Warnings

### WR-01: Playwright list parsing is ambiguous when a title contains the separator (pre-existing)

**File:** `examples/threadline_phoenix/e2e/support/operator-ci-evidence.ts:51-54`
**Issue:** `parseDiscovered` splits a `playwright test --list` line on ` › ` and `parseExecuted` treats the corresponding JSON title as one title-path element. Playwright titles are arbitrary strings and may themselves contain ` › `. For example, a test declared with title `opens A › B` is emitted with that text in the final title segment; this parser splits it into `opens A` and `B`, so its discovered identity does not match the executed/inventory identity and the receipt job fails. Deterministic reproduction from the repository root (no browser required): `node --experimental-strip-types --input-type=module -e 'import {parseDiscovered, identityKey} from "./examples/threadline_phoenix/e2e/support/operator-ci-evidence.ts"; const got=parseDiscovered("[desktop-chromium] › tests/example.spec.ts:4:1 › opens A › B")[0]; console.log(got.titlePath, identityKey(got) === identityKey({project:"desktop-chromium",file:"tests/example.spec.ts",titlePath:["opens A › B"]}));'` prints `[ 'opens A', 'B' ] false`. Git blame attributes the ambiguous regex and split at lines 51-54 to `81c920e4` (2026-10-23), before phase 247. Phase 247 commit `3e832c12` adds multi-file fan-in but leaves this parser unchanged, so this is an inherited defect carried into the new required receipt fan-in rather than a newly introduced parser change.
**Fix:** Avoid parsing the display-oriented `--list` output for machine identities. Generate the discovered identity list from a structured Playwright reporter/API, or use an unambiguous encoding for each title-path component and decode it before `identityKey` comparison.

---

_Reviewed: 2026-10-27T00:02:50Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
