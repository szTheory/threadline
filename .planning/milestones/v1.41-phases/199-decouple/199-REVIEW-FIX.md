---
phase: 199-decouple
fixed_at: 2026-09-11T23:46:08Z
review_path: .planning/phases/199-decouple/199-REVIEW.md
iteration: 3
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 199: Code Review Fix Report

**Fixed at:** 2026-09-11T23:46:08Z
**Source review:** `.planning/phases/199-decouple/199-REVIEW.md`
**Iteration:** 3

**Summary:**

- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### CR-01: Route variants are omitted from the gate blast radius

**Status:** fixed: requires human verification
**Files modified:** `examples/threadline_phoenix/e2e/support/operator-surface-paths.ts`, `examples/threadline_phoenix/e2e/support/operator-surface-paths.test.ts`, `examples/threadline_phoenix/e2e/critic/run.ts`, `examples/threadline_phoenix/e2e/critic/gate.ts`
**Commit:** `d1d90c2c`
**Test-only follow-up:** `74419486`
**Applied fix:** Added one shared route-page matcher that includes the exact ledger ID and dot-qualified variants while excluding similarly prefixed siblings. Both pre-edit score scope and gate blast-radius discovery now use that matcher.
**Test evidence:** The end-to-end route contract creates `route.timeline__dark-1280`, `route.timeline.degraded__dark-1280`, and the negative control `route.timelineish__dark-1280`. Dry-run score reports exactly 2 cells; gate reports 2 scanned cells, includes exact and degraded IDs, and excludes the prefix sibling. The follow-up commit corrected only the test's expected lexical enumeration order after the first main-checkout run exposed that assertion typo.

### CR-02: Capture failure does not force the gate to VOID

**Status:** fixed: requires human verification
**Files modified:** `examples/threadline_phoenix/e2e/critic/gate.ts`, `examples/threadline_phoenix/e2e/support/operator-surface-paths.test.ts`
**Commit:** `a807b2b1`
**Applied fix:** Added explicit `captureStatus` and `void` state to blast-radius results. A failed live `capture:pages` now prints a final `VOID`, exits nonzero immediately after step 1, and never evaluates stale evidence through the mechanical floor, paid ranking, divergence, advisory, or fix stages.
**Test evidence:** The regression supplies pre-existing route evidence plus a fake failing `npm`, removes the API key, and records subprocess calls. It proves a nonzero `VOID`, absence of steps 2–4, and an invocation log containing only `npm run capture:pages`; the fake `mix` command is never reached.

## Verification

Verification in the isolated review-fix worktree:

- Critic-trust and clean-checkout integration: 38 tests, 0 failures.
- Critic CLI and path-contract bundles parsed successfully with external packages excluded; the worktree intentionally had no `node_modules`.
- Immutable 427-entry fixture manifest remained unchanged.
- Formatting and `git diff --check`: passed.

Verification in the main checkout after transactional fast-forward:

- `npm run typecheck`: passed under strict TypeScript settings.
- `npm run test:paths`: 14 tests, 0 failures, including both new gate end-to-end regressions.
- The route dry-run exercised exact/variant discovery, prefix-sibling exclusion, explicit empty-scope rejection, and generated-vs-oracle isolation.
- `mix verify.format`, immutable-manifest diff check, and `git diff --check`: passed.
- Recovery sentinels were cleared and both isolated review-fix worktrees/temp branches were removed.

## Skipped Issues

None.

---

_Fixed: 2026-09-11T23:46:08Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 3_
