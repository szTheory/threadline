---
phase: 248-reconcile-the-base-and-safety-proof-ownership
plan: "04"
subsystem: ci, testing
tags: [github-actions, playwright, exunit, flake-detection]
requires:
  - phase: "248-02"
    provides: Explicit operator mount authorization policy and route behavior used by final integration checks
  - phase: "248-03"
    provides: Reconciled lockfiles and all-lock advisory evidence
provides:
  - Pinned Node and locked E2E setup before the existing verify-flake repeat
  - A scoped regression and source-bound local setup, repeat, canonical, and review evidence
affects: [ADM-01, ADM-02, ADM-03, ADM-04, phase-249]
actuals:
  tokens: 15440.5
  tasks: 3
  commits: 4
  plan_head_before: 0b36bfc0baff94e27dc0a4f40ca189c982901409
  plan_head_after: 2495891863f5a0fbaab8800a787d668daeb67625
tech-stack:
  added: []
  patterns:
    - Reuse the pinned setup-node action and npm ci under the existing workflow gate
key-files:
  created:
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-SUITE-PROOF.md
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-WORKFLOW-REVIEW.md
  modified:
    - .github/workflows/flake-detection.yml
    - test/threadline/browser_journey_evidence_contract_test.exs
    - test/threadline/code_walkthrough_doc_contract_test.exs
    - guides/code-walkthrough.md
    - lib/threadline/operator_surface/router.ex
    - release-please-config.json
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-CANDIDATE-BASELINE.md
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-VALIDATION.md
key-decisions:
  - "Keep the failed one-iteration repeat receipt and active no-retry stop; do not infer nine-run acceptance."
  - "Use task-local npm/browser caches and the authorized Git metadata context for local verification."
  - "Keep hosted CI, issue closure, scheduled dependency-health evidence, and REL-01 separate from local results."
requirements-completed: [ADM-01, ADM-02, ADM-03]
coverage:
  - id: D1
    description: "The existing verify-flake job installs its pinned Node runtime and locked E2E packages before repeats, guarded by the existing run decision."
    requirement: ADM-04
    verification:
      - kind: integration
        ref: "mix test test/threadline/browser_journey_evidence_contract_test.exs --seed 876664"
        status: pass
    human_judgment: false
  - id: D2
    description: "The attributed missing-CLI failure and one corrected bounded repeat are recorded with real exit, elapsed, log, and classifier evidence."
    requirement: ADM-04
    verification:
      - kind: other
        ref: ".planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-SUITE-PROOF.md#bounded-corrected-repeat"
        status: fail
    human_judgment: false
  - id: D3
    description: "The assembled candidate passes canonical local integration and preserved-inventory validation, with an independent review report attached."
    verification:
      - kind: integration
        ref: "mix ci.all"
        status: pass
      - kind: other
        ref: "python3 .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/verify-candidate-baseline.py --check-inventory --self-test"
        status: pass
      - kind: other
        ref: ".planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-WORKFLOW-REVIEW.md"
        status: pass
    human_judgment: false
duration: "1h 44m"
completed: 2026-11-10
status: halted
---

# Phase 248 Plan 04: Flake Setup Repair and Bounded Evidence Summary

**Pinned E2E setup now precedes the unchanged flake gate, with a seeded missing-CLI repair trace and a blocked one-iteration repeat receipt.**

## Performance

- **Duration:** 1h 44m
- **Started:** 2026-11-11T03:01:37Z
- **Completed:** 2026-11-11T04:46:14Z
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments

- Confirmed the actual executor worktree matched the launch pin before editing. With the Playwright CLI absent, the one pre-setup seeded test run produced the two expected real-discovery failures. The scoped setup regression failed on the original workflow and passed after repair.
- Added only the existing pinned `actions/setup-node` action and `npm ci` step, under the existing run gate and before the unchanged repeat. The same seeded real-discovery test passed after setup; the four existing workflow contracts passed.
- Resolved the accepted walkthrough, strict-Credo, and release-exclusion findings with focused checks. No lockfile, job ID, trigger, tag, repeat count, property scale, timeout, classifier, or real discovery assertion changed.
- Ran the final prepared `mix ci.all` on the assembled source with exit 0. The root suite passed 3,400 tests, the example suite passed 132 tests, Dialyzer and its live slice passed, and the desktop/mobile browser gate passed 418 tests with 56 skips. The candidate inventory validator passed all 15 checks.

## Task Commits

1. **Task 248-04-01 RED:** `6a0f9ce3` — `test(248-04): guard flake job E2E setup`
2. **Task 248-04-01 GREEN:** `450320d7` — `fix(248-04): install E2E dependencies before flake repeats`
3. **Task 248-04-03:** `cb1f5fa0` — `fix(248-04): align walkthrough contract with current policy`
4. **Task 248-04-03:** `24958918` — `fix(248-04): clear router and release gates`

The plan evidence and this summary are committed together after self-check; the commit is recorded in the completion handoff.

## Files Created/Modified

- `.github/workflows/flake-detection.yml` — pinned Node and locked E2E setup before the existing repeat.
- `test/threadline/browser_journey_evidence_contract_test.exs` — job-scoped setup/order regression preserving real discovery.
- `test/threadline/code_walkthrough_doc_contract_test.exs` and `guides/code-walkthrough.md` — aligned the current route-auth anchor and excerpt contract.
- `lib/threadline/operator_surface/router.ex` — extracted the callback normalization branch to satisfy strict Credo without changing behavior.
- `release-please-config.json` — excluded the unshipped `brand/` source tree from release detection.
- `248-CANDIDATE-BASELINE.md`, `248-VALIDATION.md`, and `248-SUITE-PROOF.md` — reconciled task evidence and blockers.
- `248-WORKFLOW-REVIEW.md` — copied independent review report; its SHA-256 matches the orchestrator result.

## Decisions Made

- The repeat's real exit 2 and classifier result `broken` remain the acceptance result. No further whole repeat is authorized.
- The final canonical run uses private temporary npm/browser caches and the approved local Git metadata context. These were task-scoped prerequisites; no global package-manager, Hex, TLS, or shared `node_modules` state was changed.
- Local results do not close issues #61 or #90, create hosted post-fix CI, satisfy the scheduled dependency-health receipt, establish minimum-toolchain execution, or resolve REL-01.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated stale walkthrough contract after the Phase 248-02 route correction**
- **Found during:** Task 248-04-02 repeat diagnostics
- **Issue:** The guide contract still expected a removed router-auth anchor and 14 excerpts although the current route policy and guide had 15.
- **Fix:** Updated the anchor and exact count, retained the bounded excerpt range, and marked the function excerpt's omitted surrounding context.
- **Files modified:** `test/threadline/code_walkthrough_doc_contract_test.exs`, `guides/code-walkthrough.md`
- **Verification:** Focused browser/walkthrough command passed 16 tests; `mix format --check-formatted` passed.
- **Committed in:** `cb1f5fa0`

**2. [Rule 3 - Blocking] Extracted router callback normalization to clear strict Credo**
- **Found during:** Task 248-04-03 integration
- **Issue:** Strict Credo stopped the canonical alias on one excess-nesting finding in `normalize_authorize_fn/2`.
- **Fix:** Extracted the existing placeholder-capture branch into a private helper and placed it after the existing clauses; callback behavior remained unchanged.
- **Files modified:** `lib/threadline/operator_surface/router.ex`
- **Verification:** Focused router/mount/release tests passed; warnings-as-errors compile, strict Credo, and final `mix ci.all` passed.
- **Committed in:** `24958918`

**3. [Rule 1 - Bug] Excluded unshipped brand source from release detection**
- **Found during:** Task 248-04-02 repeat diagnostics
- **Issue:** Release Please treated tracked `brand/` authoring assets as changed package content even though the Hex archive excludes them.
- **Fix:** Added `brand` to the existing package exclusion list; no package inclusion or release action changed.
- **Files modified:** `release-please-config.json`
- **Verification:** Release-artifact contract passed in the focused suite and final `mix ci.all`.
- **Committed in:** `24958918`

**Total deviations:** 3 auto-fixed (2 Rule 1 bugs, 1 Rule 3 blocker). **Impact:** These accepted findings were repaired within the reviewed in-scope paths; no new dependency, workflow job, public API, or risk waiver was introduced.

## Issues Encountered

- The first repeat invocation used the local dev environment and exited before ExUnit. The single corrected full repeat then ran at the recorded source, exited 2 after one iteration, and was classified `broken`. It reported six failures; source failures were repaired and environmental failures were diagnosed, but the no-retry stop remains active.
- Early `mix ci.all` attempts stopped at formatting and Credo. A sandboxed prepared attempt also exposed the shared Git metadata permission boundary and a missing local Dialyzer PLT. The PLT and private browser cache were prepared, and the reviewed canonical rerun completed all alias stages with exit 0.
- A separate Playwright fail-fast invocation timed out at its existing 60-second test limit after the npm bootstrap succeeded. The same test passed in the final full root suite under task-local npm/browser caches. Its earlier timeout stage is not conclusively known; no assertion or timeout was changed.

## User Setup Required

None — no external service configuration is required.

## Next Phase Readiness

Plan 248-04 is **halted**, not complete: the canonical integration and baseline checks pass, but the required corrected repeat did not produce nine clean runs and no retry is authorized. ADM-04 must remain blocked. Do not start Phase 249, push, dispatch hosted CI, update issues, merge, publish, or change versions. A future repeat requires explicit owner authorization and must preserve the approved scale, nine-run count, 55-minute limit, and 60-second grace.

## Self-Check: PASSED

- The four plan source commits resolve on this branch; the new phase summary/evidence files are present and their recorded review hash matches the independent result.
- Final `mix ci.all` exited 0, and the required candidate validator passed all 15 inventory checks.
- The repeat's failed classifier result, one-iteration count, and active no-retry blocker are preserved. This self-check verifies the evidence record; the plan's repeat acceptance remains unsatisfied and the summary status is `halted`.

---
*Phase: 248-reconcile-the-base-and-safety-proof-ownership*
*Completed: 2026-11-10*


## Orchestration continuation and current authority boundary

The author-return halt and failed original repeat remain historical evidence. The orchestrator proposed one bounded local revalidation after prepared canonical exit0 and independent review. Automatic approval review rejected the launch because the existing no-further-repeat stop requires trusted explicit user approval; an assistant-only authorization was insufficient. No new repeat started. ADM04 remains incomplete and the actual worktree stays retained until this concrete approval decision and any subsequently authorized proof are reconciled. No indirect retry is permitted.
