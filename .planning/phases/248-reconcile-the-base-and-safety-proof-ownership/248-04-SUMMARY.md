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
  tokens: 47899.0
  tasks: 3
  commits: 17
  plan_head_before: 0b36bfc0baff94e27dc0a4f40ca189c982901409
  plan_head_after: ce0c2e30d0b7401b3b35df21dcd986ad9ed8cafb
tech-stack:
  added: []
  patterns:
    - Reuse the pinned setup-node action and npm ci under the existing workflow gate
key-files:
  created:
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-SUITE-PROOF.md
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-WORKFLOW-REVIEW.md
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-CLIPBOARD-PROOF.md
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-PUBLIC-SURFACE-FIX.md
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-POSTFIX-REPEAT-RECEIPT.json
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-FILE-PRESSURE-PROOF.md
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-INVENTORY-REPEAT-RECEIPT.json
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
    - test/threadline/public_surface_contract_test.exs
    - test/threadline/repo_contract_scope_contract_test.exs
    - test/threadline/storage_schema_call_site_contract_test.exs
    - test/threadline/formatter_topology_contract_test.exs
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-04-PLAN.md
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-SUITE-PROOF.md
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-CANDIDATE-BASELINE.md
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-VALIDATION.md
key-decisions:
  - "Keep all failed full-repeat receipts as failures; do not infer nine-run acceptance."
  - "Reduce measured repeated file operations locally while preserving each contract's fixtures and checks."
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

## Current diagnostic outcome and narrow correction — 2026-11-11

Plan 248-04 remains halted and ADM-04 incomplete. The approved instrumented nine-run alias failed its first suite on `8bdb4ac0`: 32 properties, 3,400 tests, one formatter timeout, three exclusions; 727.45 seconds wall, suite exit 2 / capture 0 / wrapper 1, classifier `broken`. No later suites ran. The one-invocation grant is consumed. [Exact diagnostic receipt](248-INSTRUMENTED-DIAGNOSTIC-RECEIPT.json).

Current source `ce0c2e30d0b7401b3b35df21dcd986ad9ed8cafb` changes only the synthetic overlap input to the exact existing representative, preserving production formatter configs/globs, all 12 representatives, exact overlap/uncovered assertions, async settings and timeouts. A post-run check showed the old recursive fixture glob returned 107 files, including 97 under dependencies/build output, while the literal returned the one required representative. This is scope evidence, not a latency or exclusive-cause claim. Focused test, format and strict Credo pass; two private control mutants fail as intended; independent 33-file recheck has no active findings (32 exact reads reused, one changed file fully read). [Correction and bounded proof](248-OVERLAP-PROOF.md), [review](248-OVERLAP-REVIEW.md).

No current full-root or plain nine-run pass is claimed. During the timeout, sampled file-server counters kept advancing with changing operations and queued requests; the observer had material variable overhead, so no single continuous stall, sole cause or reliable speedup is established. PostgreSQL is stopped after zero clients; shared services untouched. The next concrete decision is one plain acceptance invocation with the same nine-run / scale 5 / max-cases 36 / 55-minute plus 60-second limits; authorization is false. [Current readiness](248-OVERLAP-READINESS.md). Formal post-gates, acceptance and phases 249–253 remain pending; no external authority inferred.

## Prior source-specific evidence (current status superseded)


## Current correction and proof boundary — 2026-11-11

Plan 248-04 remains halted; ADM-04 and phase acceptance remain incomplete. Current reviewed source is `9b695ca25b41be882902ddfb06716141e5a462db`. The latest plain repeat completed three clean suites, then five file-operation timeouts in iteration 4; its one-invocation user grant is consumed. No further full repeat is authorized.

The intermediate pressure refactor accidentally passed nine benign fixture bodies without the required tagged-source wrapper. Those assertions bypassed the detector. That defect and the earlier clean review are explicitly superseded: current source restores the wrapper and asserts the premise for every fixture. The intentional raw direct controls retain fresh default inventories. Current focused checks, formatting, strict Credo and one ordinary full-root observation pass. A private mutant removing the wrapper fails at the new premise assertion as expected; it is not a current-source failure. The independent 33-file review has no active findings (32 exact-identity reads reused, one changed file fully read). See [current proof](248-FILE-PRESSURE-PROOF.md) and [superseding review](248-NEGATIVE-PREMISE-REVIEW.md).

The corrected ordinary root run passed 32 properties / 3,400 tests / 0 failures / 3 exclusions in 332.17 seconds; its benign fixture loop took 34.60 seconds. The earlier 234.24-second intermediate run had vacuous negative controls and is invalid as complete coverage. The corrected observation does not establish a reliable speedup, an exclusive timeout cause or a passing nine-run gate. Assertions, fixture bodies, exclusions, scale, concurrency and timeouts are preserved.

Task-owned PostgreSQL 15.17 is stopped after zero remaining clients; shared services were untouched. A checked private observer and one bounded diagnostic proposal are prepared, with authorization false. An instrumented pass would be diagnostic only; the required plain repeat remains outstanding. [Current readiness and next decision](248-PRESSURE-READINESS.md) supersedes older readiness snapshots. Formal post-gates and phases 249–253 remain pending. No push, merge, publication or package-version authority is inferred.

## Earlier source-specific record (superseded as current status)


## Current file-pressure follow-up — 2026-11-11

Plan 248-04 remains halted and ADM-04 remains incomplete. The latest user-approved full nine-run invocation is terminal and failed at the pre-fix source `10442d31a8c7df50111effe1614c99bf5e7e87ee`: three clean runs, then five 60-second file-server timeouts in iteration 4 at seed `579775`; suite exit 2, wrapper exit 1, capture exit 0, 1,582.26 seconds, classifier `flaky`. The portable record is [248-INVENTORY-REPEAT-RECEIPT.json](248-INVENTORY-REPEAT-RECEIPT.json). No further full repeat is authorized.

The bounded source deviation is committed as `eaedaf5e1a92c9fd797f37fefaffad14b5376e8e`. The final focused run passed 38/0 at seed `579775`, scale 5 and max-cases 36 on working-tree content later committed unchanged; `mix verify.format` and strict Credo passed. An earlier focused run was also 38/0 but exposed an unused-default warning, and the first format check found formatting differences; both were corrected before the final checks. One ordinary root run on the clean commit passed 3,400 tests / 0 failures / 3 exclusions in 234.24 seconds. Its observer recorded 928 samples, a peak file-server queue of 37 and maximum sampling cost of 3 ms. The paired test timings and static before/after traversal counts are in [248-FILE-PRESSURE-PROOF.md](248-FILE-PRESSURE-PROOF.md). This single root result is not nine-run acceptance and does not prove an exclusive failure cause.

The retained canonical alias remains source-bound history with one retry-passed browser case; the scoped clipboard proof remains separate. No fresh canonical/browser run was made here. Protected runtime, router, script, lock and browser-inventory identities stayed unchanged. Independent review and PostgreSQL lifecycle remain parent-owned. No state/roadmap/requirements update, phase advance, worktree removal or external action was performed.

## Prior reconciliation before file-pressure follow-up — 2026-11-11

Plan 248-04 remains halted. The latest user-approved full repeat is terminal: source `baa3a27d56bf6047d791f709aa78d1692d8294c9`, wrapper exit 1, suite exit 2, capture exit 0, 1,932 seconds, five clean runs then the public-surface subject-ownership timeout in iteration 6 at seed `587264`, classifier `flaky`. Its portable receipt is [248-POSTFIX-REPEAT-RECEIPT.json](248-POSTFIX-REPEAT-RECEIPT.json). The earlier formatter timeout at iteration 7 remains historical evidence and is superseded as the latest failure.

The isolated PostgreSQL 15 canonical alias on `ab65c014` remains source-bound history: its browser result was 417 first-attempt passes, one retry-passed clipboard case and 56 configured skips, not a clean browser run. The clipboard readiness fix at `ac260b47` retains its bounded proof. The latest public-surface and heading 15 follow-up is separately recorded in [248-PUBLIC-SURFACE-FIX.md](248-PUBLIC-SURFACE-FIX.md): current affected contracts, formatting, inventory validation and the compiled route probe pass, but the single root-suite invocation has one shared-Git-metadata permission failure. The same failing test passed in a narrow diagnostic with that metadata permission; the root result remains failed.

The task-owned PostgreSQL 15.17 service was used for this continuation and left untouched; the parent owns its status and cleanup. The shared service and other projects were not modified. No passing nine-run receipt exists. The repeat grant is consumed; any later repeat requires a new explicit one-invocation grant and must preserve nine runs, scale 5, a 55-minute cap and 60-second termination grace. No automatic retry, phase advance, worktree removal, issue closure, hosted dispatch, push, version change or publication is authorized. Local PostgreSQL 15 evidence does not establish the full min/current/latest CI matrix or REL-01.

Historical source-specific records below remain evidence; this section supersedes their old present-tense dispatch/readiness statements. See [248-POSTFIX-READINESS.md](248-POSTFIX-READINESS.md).

# Phase 248 Plan 04: Flake Setup Repair and Bounded Evidence Summary

**Pinned E2E setup now precedes the unchanged flake gate, with a seeded missing-CLI repair trace and a blocked one-iteration repeat receipt.**

## Performance

- **Duration:** 1h 44m
- **Started:** 2026-11-11T03:01:37Z
- **Completed:** 2026-11-11T04:46:14Z
- **Tasks:** 3
- **Files modified:** 11 during the original plan execution; subsequent corrective follow-up files are itemized in the current reconciliation and `key-files` list.

## Accomplishments

- Confirmed the actual executor worktree matched the launch pin before editing. With the Playwright CLI absent, the one pre-setup seeded test run produced the two expected real-discovery failures. The scoped setup regression failed on the original workflow and passed after repair.
- Added only the existing pinned `actions/setup-node` action and `npm ci` step, under the existing run gate and before the unchanged repeat. The same seeded real-discovery test passed after setup; the four existing workflow contracts passed.
- Resolved the accepted walkthrough, strict-Credo, and release-exclusion findings with focused checks. No lockfile, job ID, trigger, tag, repeat count, property scale, timeout, classifier, or real discovery assertion changed.
- Ran the final prepared `mix ci.all` on the assembled source with exit 0. The root suite passed 3,400 tests, the example suite passed 132 tests, Dialyzer and its live slice passed, and the browser gate had 417 first-attempt passes, one retry-passed clipboard case and 56 configured skips. The candidate inventory validator passed all 15 checks.

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
- `test/threadline/repo_contract_scope_contract_test.exs`, `test/threadline/storage_schema_call_site_contract_test.exs`, and `test/threadline/formatter_topology_contract_test.exs` — reduced repeated local file work while preserving contract coverage.
- `248-FILE-PRESSURE-PROOF.md` and `248-INVENTORY-REPEAT-RECEIPT.json` — recorded the bounded source follow-up and latest failed repeat.

## Decisions Made

- Full-repeat failures remain failures, with the latest terminal result recorded in the current file-pressure reconciliation. No further whole repeat is authorized.
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

**4. [Rule 3 - Blocking] Reduced repeated per-invocation file work in three contracts**
- **Found during:** Corrective file-pressure follow-up after the latest full-repeat timeout cluster
- **Issue:** The same library inventory and formatter owner sets were rebuilt within aggregate fixture/mutation checks, and the storage sweep called `getcwd` for every result. The timeout stacks support common file-server waits but do not establish that this repeated work was the sole cause.
- **Fix:** Reuse the local inventory and unchanged owner sets within each invocation; recompute only the two formatter owners whose synthetic configs change; capture CWD once for the storage sweep.
- **Files modified:** `test/threadline/repo_contract_scope_contract_test.exs`, `test/threadline/storage_schema_call_site_contract_test.exs`, `test/threadline/formatter_topology_contract_test.exs`
- **Verification:** Focused suite 38/0, `mix verify.format`, `mix verify.credo`, one bounded root run 3,400/0/3, and candidate inventory validation 15/15.
- **Committed in:** `eaedaf5e`

**Total deviations:** 4 auto-fixed (2 Rule 1 bugs, 2 Rule 3 blockers). **Impact:** The accepted local fixes preserve test coverage and do not change runtime behavior, dependencies, CI scope or authorization limits.

## Issues Encountered

- The first repeat invocation used the local dev environment and exited before ExUnit. The single corrected full repeat then ran at the recorded source, exited 2 after one iteration, and was classified `broken`. It reported six failures; source failures were repaired and environmental failures were diagnosed, but the no-retry stop remains active.
- Early `mix ci.all` attempts stopped at formatting and Credo. A sandboxed prepared attempt also exposed the shared Git metadata permission boundary and a missing local Dialyzer PLT. The PLT and private browser cache were prepared, and the reviewed canonical rerun completed all alias stages with exit 0.
- A separate Playwright fail-fast invocation timed out at its existing 60-second test limit after the npm bootstrap succeeded. The same test passed in the final full root suite under task-local npm/browser caches. Its earlier timeout stage is not conclusively known; no assertion or timeout was changed.

## User Setup Required

None — no external service configuration is required.

## Next Phase Readiness

Plan 248-04 is **halted**, not complete: the latest user-approved full repeat ended after three clean runs and five timeouts in iteration 4, so the required nine-run proof is missing and the grant is consumed. ADM-04 must remain incomplete. A future repeat requires a new explicit user grant and must preserve the approved scale, nine-run count, 55-minute limit and 60-second grace. Do not start Phase 249, push, dispatch hosted CI, update issues, merge, publish or change versions.

## Self-Check: PASSED

- The corrective source commit `eaedaf5e` is on this branch; the follow-up plan, proof and receipt files are present.
- The candidate inventory validator passed all 15 checks. The historical full `mix ci.all` result remains separately source-bound; this follow-up did not run a fresh canonical alias.
- The latest repeat's three clean runs, five timeouts, true suite exit 2, elapsed time and `flaky` classification are preserved. This self-check verifies the evidence record; nine-run acceptance remains unsatisfied and the summary status is `halted`.

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

## Corrective public-surface follow-up — 2026-11-11

The latest one-invocation user grant was consumed by the terminal repeat on source `baa3a27d56bf6047d791f709aa78d1692d8294c9`: wrapper 1, suite 2, capture 0, 1,932 seconds; five clean runs then a 60-second public-surface reference timeout in iteration 6 at seed `587264`, classifier `flaky`. It is preserved in [248-POSTFIX-REPEAT-RECEIPT.json](248-POSTFIX-REPEAT-RECEIPT.json); earlier formatter/clipboard receipts remain history. No new full repeat or canonical run was performed.

The public surface contract now builds one reference inventory for the aggregate subject set and reuses a single discovered Mix task list within each helper invocation. The source-derived traversal is 80 subjects over 134 source files: AST parse passes go from 241 to 3, or 32,294 source parses to 402. The selected seed test passed before and after (15.3s then 0.6s ExUnit in these individual runs); the affected file passed 47/0. The doc contracts passed 14/0, the compiled route probe verified all 16 routes inherit both host pipelines and the ignored-option control fails, formatting passed, and the inventory validator passed 15 checks. Changes are isolated in source commits `6843856f` and `2c6c6152`; details and hashes are in [248-PUBLIC-SURFACE-FIX.md](248-PUBLIC-SURFACE-FIX.md).

The one bounded root invocation exited 2 after 421 seconds with 3,400 tests, 1 failure and 3 existing exclusions. The failure was `CleanCheckoutContractTest` denied permission to create a temporary worktree under shared Git metadata. Its exact test passed in a narrow diagnostic with scoped metadata access (9 tests, 0 failures, 8 excluded); the root run remains failed. No second root run followed.

Plan 248-04 remains **halted**, and ADM-04 remains incomplete because there is no passing nine-run receipt. The consumed repeat grant does not renew. The latest worktree source reviews are pending. The task-owned PostgreSQL service was left untouched for the parent to manage; no shared database, state, roadmap, requirements, phase boundary or external system was changed.


## Source-review reconciliation before file-pressure follow-up

The public-reference optimization and heading 15 guide correction have independent review with no remaining source findings. See [248-PUBLIC-SURFACE-REVIEW.md](248-PUBLIC-SURFACE-REVIEW.md). The actual-snippet extraction compiler check passes for the corrected scope and rejects the old form. The full-repeat failure, ordinary root sandbox failure and separately passing permission-scoped fixture remain distinct; Plan 04 is halted and ADM-04 incomplete until required current-source nine-run proof exists.

## Current source-review reconciliation

Independent review of the file-pressure source commit `eaedaf5e` is pending with the parent. The ordinary root result and paired timing limits are in [248-FILE-PRESSURE-PROOF.md](248-FILE-PRESSURE-PROOF.md). The latest nine-run receipt remains failed; Plan 248-04 is halted and ADM-04 incomplete until a passing nine-run proof exists.
