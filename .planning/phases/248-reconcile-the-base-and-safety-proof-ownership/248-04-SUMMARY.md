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
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-CLIPBOARD-PROOF.md
  modified:
    - .github/workflows/flake-detection.yml
    - test/threadline/browser_journey_evidence_contract_test.exs
    - test/threadline/code_walkthrough_doc_contract_test.exs
    - guides/code-walkthrough.md
    - lib/threadline/operator_surface/router.ex
    - release-please-config.json
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-CANDIDATE-BASELINE.md
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-VALIDATION.md
    - examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts
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

## Current reconciliation — 2026-11-11

Plan 248-04 remains halted. The user's one additional full-repeat grant is consumed: six clean runs followed by a formatter timeout in iteration 7, classifier `flaky`. The formatter test now removes repeated owner-file enumeration, retaining all assertions and execution settings; independent review found no source defects.

The isolated PostgreSQL15 canonical alias exited0 on source `ab65c014`, with root/example/type checks passing and browser417 first-attempt passes,one retry-passed clipboard case and56 configured skips. That browser run remains non-clean. Current test-only clipboard readiness source `ac260b47` passed six first-attempt target invocations and the complete affected file (52 combined instances:41passed,11 configured skips), all with retries disabled; discovery passed9/0 and the inventory validator passed15 checks. Independent source reviews are [248-FORMATTER-REVIEW.md](248-FORMATTER-REVIEW.md) and [248-CLIPBOARD-REVIEW.md](248-CLIPBOARD-REVIEW.md). These scoped results do not claim a fresh full canonical run or pre-connect clipboard behavior.

The task-owned PostgreSQL15 instance is stopped after verification and zero remaining clients; its private data is retained for a possible authorized continuation. The shared service and other projects were untouched. No passing nine-run receipt exists. A NEW explicit one-invocation grant is required before another unchanged nine-run, scale 5, 55-minute repeat with 60-second termination grace. No automatic retry, phase advance, worktree removal, issue closure, hosted dispatch, push, version change or publication is authorized. Local PostgreSQL15 component coverage does not establish the full min/current/latest CI matrix or REL-01.

Historical source-specific records below remain evidence; this section supersedes their old present-tense dispatch/readiness statements. See [248-POSTFIX-READINESS.md](248-POSTFIX-READINESS.md).

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

## Corrective follow-up — 2026-11-11

The single explicitly approved renewed repeat is now terminal and failed: source `8311dc64ac4b7f0b686e27de41839899803139c7`, seed `500886`, suite exit 2, capture exit 0, 2,611 seconds, classifier `flaky` after six clean runs and an iteration-7 formatter timeout. Its portable receipt is [248-RENEWED-REPEAT-RECEIPT.json](248-RENEWED-REPEAT-RECEIPT.json); the active no-further-full-repeat stop remains in force.

The failure stack entered recursive wildcard expansion from `ownership_errors/2`. The test now computes each ordered owner file set once per invocation and reuses those sets for all paths. This preserves fresh sets for the modified overlap/uncovered owners and retains duplicate owner records, all representative paths and negative-control assertions, the synthetic overlap glob, async setting, timeout, tags and suite coverage. Static traversal counts across the existing calls fell from 70 owner-set builds / 168 input wildcard expansions to 15 / 36. This identifies repeated work but does not claim it alone explains the timeout or infer a machine-load cause. Details and attribution limits are in [248-FORMATTER-FIX.md](248-FORMATTER-FIX.md).

The permitted seed-500886 standalone baseline passed (1 test, 0 failures; 0.8s ExUnit, 2s wall). The same focused file passed after the fix (1 test, 0 failures; 0.2s ExUnit, 1s wall), and `mix verify.format` exited 0 in 3s. The code-only commit is `2b00c6bea83e42fe8843b2b8d7767f7ffbe13df4`; it changes only `test/threadline/formatter_topology_contract_test.exs`.

The one canonical `mix ci.all` on that commit exited 1 after 438s. Credo, dependency audit, hygiene, xref, and the root suite passed; the root suite reported 3,400 tests, 0 failures, 3 excluded. `verify.example` then failed to establish its test database because PostgreSQL returned `too_many_connections`. The remaining Dialyzer and browser stages were not reached. A read-only snapshot taken after exit showed 100 configured connections, 30 idle sessions across other databases, and five sessions without a database; this does not prove the count or client owners at failure time. No process/client cleanup was performed. The candidate baseline validator passed all 15 checks. All four lockfile hashes remain unchanged and package version remains `1.1.0`.

**Status remains halted/incomplete.** ADM-04 is incomplete because the renewed repeat failed and no passing nine-run receipt exists. The canonical command also did not complete. No full-repeat retry, additional canonical run, acceptance waiver, phase advance, or worktree removal is authorized. The next decision belongs to the orchestrator/maintainer: whether to authorize a separate canonical run after verified task-local PostgreSQL headroom is available, while preserving the no-repeat stop.

## Corrective clipboard-proof follow-up — 2026-11-11

The later isolated `mix ci.all` on source `ab65c0147ad7bf58e7d3b2394c55514868c2bec5` exited 0 in 1,427 seconds using task-owned PostgreSQL 15.17. It passed the root suite (3,400 tests, 0 failures), example suite (132 tests, 0 failures), Dialyzer (0 errors), and live slice (17 tests, 0 failures). Its browser summary was **417 first-attempt passes, one retry-passed desktop clipboard flake, and 56 configured skips**. The original canonical source remains a flaky browser result, not a clean 418-pass proof. Its exact first-attempt error context, canonical log, and receipt were preserved privately with hashes before later Playwright runs. Trace and screenshots were disabled, so the cause of the lost focus is not proven.

The single test-file change waits for `[data-phx-main]` to have `phx-connected` after navigation in the clipboard-failure case. The six bounded target invocations passed (three desktop and three mobile, `--retries=0`, `--repeat-each=3`). One run of the full affected spec passed 41 tests with 11 configured skips total across both projects (`--retries=0`). The focused discovery contract passed 9 tests, and the inventory validator passed all 15 checks. The source test hash during these runs was `ac640f7ba157c04976cfa917805e50bc5cd1a4c6843b51065ea749af69e9b5a7`; it was committed unchanged as `ac260b47cc642d0a62cdca30e07ea6bfc863e1db`. The code commit changes only `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts`; no product/browser fallback code, asset, journey inventory, lockfile, or global retry setting changed.

This proof is scoped to the connected LiveView state and does not claim behavior for pre-connect copy attempts or identify the original focus-loss cause. No fresh canonical run or full repeat was run after the edit. The nine-run acceptance remains failed and unauthorized for another attempt. Plan 248-04 remains halted; ADM-04 remains incomplete. The task-owned PostgreSQL instance is still running for the parent to stop; the shared database service was left unchanged. Full source bindings and log/context hashes are in [248-CLIPBOARD-PROOF.md](248-CLIPBOARD-PROOF.md).


## Pre-approval automatic-review snapshot (historical)

The author-return halt and failed original repeat remain historical evidence. The orchestrator proposed one bounded local revalidation after prepared canonical exit0 and independent review. Automatic approval review rejected the launch because the existing no-further-repeat stop requires trusted explicit user approval; an assistant-only authorization was insufficient. No new repeat started. ADM04 remains incomplete and the actual worktree stays retained until this concrete approval decision and any subsequently authorized proof are reconciled. No indirect retry is permitted.
