---
phase: 198-green-bringup
plan: 25
subsystem: testing
tags: [elixir, phoenix, liveview, ecto, demo-seed, ci, example-app, operator-surface]

# Dependency graph
requires:
  - phase: 198-green-bringup
    provides: "198-23's retention_tail.ex cutoff fix and the reusable six-step fix protocol; 198-24's assertion-hardening pattern"
provides:
  - "Root-cause fix for the last local mix verify.example failure: a production-code label divergence between Presentation.export_action_label/2 (spec-correct) and export_status_live.ex's own duplicate private function (drifted, wrong)"
  - "Two hardened evidence-plane assertions (WALK-04-01 wrong-route + vacuous refute; WALK-04-03 assertion matching static CSS instead of data)"
  - "Directly-evidenced ExUnit.TimeoutError diagnosis via live pg_stat_activity capture: an orphaned idle-in-transaction Postgres session blocking a deterministic-UUID upsert"
  - "mix verify.example measured at 109 tests, 0 failures on two consecutive runs — local readiness signal only, per D-01"
affects: [198-26, 198-27, 198-28, 198-29]

# Actuals (#2632)
actuals:
  tokens: 6900
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Diagnosis-authorizes-scope: when a demo-seed test's failure cause lives in production library code, the fix lands there (per plan text's 'wherever it genuinely lives'), not in the seed/test files alone — same authorized-by-diagnosis pattern 198-23 established for retention_tail.ex"
    - "Vacuous-pass detection via static-content grep: before trusting an assertion, grep the page's own <style> block and unconditional markup for the asserted substring — CSS class names and other static text can make a substring assertion pass regardless of seeded data"
    - "Live pg_stat_activity capture during a targeted timeout reproduction, instead of speculative cause attribution, to get a directly-evidenced diagnosis rather than an inferred one"

key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/live/export_status_live.ex
    - test/threadline/operator_surface/live/export_status_live_test.exs
    - test/threadline/operator_surface/copy_contract_test.exs
    - examples/threadline_phoenix/test/support/walkthrough_case.ex
    - examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_evidence_test.exs
    - .planning/audits/198-round4-demo-seed.md

key-decisions:
  - "The 'Export expired' failure's real cause was a production-code bug (two divergent copy-label functions for the same state), not a seed or test-assertion defect — fixed in lib/threadline/operator_surface/live/export_status_live.ex, outside this plan's pre-declared files_modified, authorized by the plan's own 'wherever it genuinely lives' instruction and 198-23's precedent."
  - "Three sibling assertions in the ROOT library's own test suite (export_status_live_test.exs x3, copy_contract_test.exs x1) had been written against the drifted, incorrect 'Expired' string and were updated to the spec-correct 'Export expired' — not weakened, made stricter and consistent with the already-existing, already-tested Presentation.export_action_label/2 and the 137-series UI-SPEC."
  - "WALK-04-01's empty-timeline check was pointed at the wrong route (/audit, which redirects to Home, not Timeline) and contained a refute against a string ('View Incident') that appears nowhere in the entire codebase — routed to /audit/timeline and replaced with a positive assertion against the real empty-state title."
  - "WALK-04-03's coverage assertion matched the page's own static CSS class names (tl-table__row--covered/--uncovered are emitted unconditionally), not seeded data — replaced with the two actual data-driven chip labels, confirmed absent from the stylesheet."
  - "The ExUnit.TimeoutError's cause class (lock/deadlock against the seeded transaction) was confirmed by directly polling pg_stat_activity during a targeted reproduction, catching a genuine transactionid wait against an orphaned idle-in-transaction session, rather than inferred from the stacktrace alone."
  - "Added a session-level Postgres advisory lock around walkthrough_case.ex's seed_demo_fiction!/0 as in-scope defensive hardening (same pattern already used in lib/threadline/retention/pruner.ex), while stating honestly that it does not close the full external-session-hygiene class, which is out of this plan's scope."

patterns-established:
  - "Pattern: grep a LiveView's own inline <style> block for an assertion's target substring before trusting it as a data-driven signal — static CSS class names are a common source of vacuous-pass HTML substring assertions."
  - "Pattern: when a demo-seed test's failure diagnosis points at production library code rather than the seed/test layer, follow the diagnosis there and document the scope expansion as a deviation, rather than declaring the failure permanently out of scope."

requirements-completed: []  # GREEN-04 remains Pending per D-01 -- this plan is a local readiness signal only; plan 198-29's measured CI run is authoritative.

coverage:
  - id: D1
    description: "Fresh two-run re-inventory of both target files after 198-23/198-24's seed changes landed, before any 198-25 edit"
    verification:
      - kind: other
        ref: ".planning/audits/198-round4-demo-seed.md#re-inventory-after-198-23-198-24-198-25"
        status: pass
    human_judgment: false
  - id: D2
    description: "Root-cause fix for 'admin export status shows seeded job states' (assert html =~ Export expired): a production-code label divergence, not a seed defect"
    verification:
      - kind: integration
        ref: "examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_happy_path_test.exs (12 tests, 0 failures, two consecutive runs)"
        status: pass
      - kind: unit
        ref: "test/threadline/operator_surface/live/export_status_live_test.exs + copy_contract_test.exs + presentation_test.exs (68 tests, 0 failures) and root mix test (1422 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "WALK-04-01 and WALK-04-03 vacuous-pass assertions hardened (wrong route + string never rendered anywhere; assertion matching static CSS instead of data)"
    verification:
      - kind: integration
        ref: "examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_evidence_test.exs (3 tests, 0 failures, two consecutive runs)"
        status: pass
    human_judgment: false
  - id: D4
    description: "ExUnit.TimeoutError diagnosed via direct pg_stat_activity capture: an orphaned idle-in-transaction session blocking a deterministic-UUID upsert (lock/deadlock cause class), with an in-scope defensive advisory-lock hardening applied"
    verification:
      - kind: integration
        ref: "test/threadline/idle_transaction_reaper_contract_test.exs + config/test.exs"
        status: pass
      - kind: other
        ref: ".planning/audits/198-round4-demo-seed.md#exuniontimeouterror-diagnosis-198-25 (live pg_stat_activity transcript)"
        status: pass
    human_judgment: false
    rationale: "The advisory lock closes contention between this plan's own two test files; it does not and cannot close the full class of an externally-orphaned session from an unrelated process, which is a connection-hygiene concern outside this plan's declared scope. A human/maintainer should judge whether that residual risk warrants a follow-up phase. Discharged by phase-199: the residual class this entry flagged - an externally-orphaned session no application lock can reach - is now reaped by Postgres itself via idle_in_transaction_session_timeout on the repo's connection parameters. Asserted live (SHOW returns 1min) rather than merely present in config. Only 'idle in transaction' is reaped, so slow-but-active work is untouched."
  - id: D5
    description: "mix verify.example measured at 109 tests, 0 failures on two consecutive runs — the target state named by this plan's must-haves"
    verification:
      - kind: other
        ref: ".planning/audits/198-round4-demo-seed.md#measured-after-count-198-25-closing"
        status: pass
    human_judgment: false
  - id: D6
    description: "GREEN-04 not marked Complete -- only the measured CI run in plan 198-29 (D-01) is admissible evidence"
    verification:
      - kind: integration
        ref: "test/threadline/ci_attestation_contract_test.exs + .planning/audits/ci-attestation-33344382035.json"
        status: pass
    human_judgment: false
    rationale: "Per D-01, no local evidence can satisfy this -- it requires deferring to plan 198-29's CI run, which this SUMMARY does not attempt to substitute for. Discharged by measured CI run 33344382035 per D-01: GREEN-04 is Complete on that run's own job conclusion, not on local evidence."
# Metrics
duration: 95min
completed: 2026-08-28
status: complete
---

# Phase 198 Plan 25: Gap-closure round-4 finale — export-label production bug fix + evidence-plane hardening + live timeout diagnosis Summary

**Fixed the last local `mix verify.example` failure by tracing it to a production-code label divergence in the operator surface (not the demo seed), hardened two vacuous-pass evidence-plane assertions, and diagnosed the recurring `ExUnit.TimeoutError` with a live `pg_stat_activity` capture of an orphaned lock-holding session — closing the round at 109 tests, 0 failures.**

## Performance

- **Duration:** 95 min
- **Started:** 2026-08-28
- **Completed:** 2026-08-28
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Re-inventoried both target files fresh after 198-23/198-24's seed fixes: `walkthrough_evidence_test.exs`'s three tests already passed (predicted side effect, same pattern 198-24 found); the one real target was `walkthrough_happy_path_test.exs`'s `admin export status shows seeded job states` (`assert html =~ "Export expired"`).
- Diagnosed the "Export expired" failure to its true cause: `Threadline.OperatorSurface.Presentation.export_action_label/2` already computes the spec-correct `"Export expired"` label (and is already asserted by `presentation_test.exs` and documented in the Phase 137 UI-SPEC/CONTEXT), but it is **never called from any template** — the actual rendered page uses a separate, private, duplicate function in `export_status_live.ex` that had drifted to return `"Expired"` instead. Fixed the one-line divergence and updated the three sibling root-library assertions that had been written against the drifted string.
- Hardened two genuine vacuous-pass weaknesses in `walkthrough_evidence_test.exs`, both found and grep-proven before editing: `WALK-04-01`'s empty-timeline check navigated to the wrong route (landing on the generic operator Home page, not Timeline) and refuted a string (`"View Incident"`) that is never rendered anywhere in the codebase; `WALK-04-03`'s coverage assertion matched the page's own unconditionally-emitted static CSS class names, not seeded data.
- Diagnosed the recurring `ExUnit.TimeoutError` (observed across 198-23, 198-24, and this round) with direct evidence rather than inference: polling `pg_stat_activity` during a targeted reproduction caught the seed's `insert_all` genuinely blocked on a `transactionid` wait against an orphaned `idle in transaction` Postgres session left by an earlier abnormally-terminated connection. Added a session-level Postgres advisory lock (same pattern as `lib/threadline/retention/pruner.ex`) as in-scope defensive hardening, documented honestly as a partial mitigation.
- Closed the local measurement: `mix verify.example` at **109 tests, 0 failures** on two consecutive runs — the exact target state named by this plan's must-haves. Root library `mix test`: 1422 tests, 0 failures (no regression from the four sibling-test updates).

## Task Commits

1. **Task 1: Fix the "Export expired" production-code label divergence** - `e6f3cd5d` (fix)
2. **Task 2: Harden evidence-plane vacuous-pass assertions, diagnose the timeout, close the measurement** - `c43bb578` (docs — includes the seed-support advisory-lock hardening and audit doc)

## Files Created/Modified

- `lib/threadline/operator_surface/live/export_status_live.ex` - fixed `export_job_status_label/1`'s completed+expired branch to return `"Export expired"` (was `"Expired"`), matching the already-correct `Presentation.export_action_label/2`
- `test/threadline/operator_surface/live/export_status_live_test.exs` - 3 assertions updated from the drifted `"Expired"` to the spec-correct `"Export expired"`
- `test/threadline/operator_surface/copy_contract_test.exs` - 1 literal updated from `"Expired"` to `"Export expired"`
- `examples/threadline_phoenix/test/support/walkthrough_case.ex` - `seed_demo_fiction!/0` now wraps `Reset.run()`/`Seed.run()` in a session-level Postgres advisory lock
- `examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_evidence_test.exs` - `WALK-04-01` routed to `/audit/timeline` with a positive empty-state assertion; `WALK-04-03` asserts the two actual data-driven coverage chip labels instead of a CSS-matching substring
- `.planning/audits/198-round4-demo-seed.md` - extended with `## Plan 198-25`'s re-inventory, root-cause diagnosis, two red-then-green/structural teeth proofs, the live `pg_stat_activity` timeout diagnosis, a local multi-worktree DB isolation discovery note, and the closing measured count

## Decisions Made

See `key-decisions` in frontmatter above — summarized: fixed the real cause wherever it lived (production LiveView code, not the seed), updated sibling assertions that had drifted from the correct spec rather than leaving them silently inconsistent, replaced two vacuous-pass assertions with genuinely data-driven ones (grep-proven non-vacuous), and diagnosed the timeout with live database evidence rather than speculation, applying an honest, scope-appropriate partial mitigation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] "Export expired" fix landed in production library code, not the seed or test files the plan pre-declared**
- **Found during:** Task 1 (diagnosis)
- **Issue:** The plan's `files_modified` and this plan's own dispatch context expected the cause to be in the demo-seed layer or the test assertion itself. Root-cause tracing showed the actual defect was a divergence between two label-computing functions in `lib/threadline/operator_surface/live/export_status_live.ex` and `lib/threadline/operator_surface/presentation.ex` — production library code, never named in this plan's declared scope.
- **Fix:** Fixed `export_status_live.ex`'s drifted private function to match the already-correct, already-tested `Presentation.export_action_label/2`, per the plan's own "wherever it genuinely lives" dispatch instruction and 198-23's identical precedent (fixing `retention_tail.ex`, also outside its pre-declared file list).
- **Files modified:** `lib/threadline/operator_surface/live/export_status_live.ex`, `test/threadline/operator_surface/live/export_status_live_test.exs`, `test/threadline/operator_surface/copy_contract_test.exs`
- **Verification:** Root library full suite (1422 tests, 0 failures); example app `walkthrough_happy_path_test.exs` (12 tests, 0 failures, two consecutive runs).
- **Committed in:** `e6f3cd5d`

**2. [Rule 2 - Missing Critical] Two vacuous-pass assertions in `walkthrough_evidence_test.exs` hardened before they could mask a real regression**
- **Found during:** Task 2 (reading the file against this plan's own must-haves)
- **Issue:** `WALK-04-01` navigated to the wrong route and refuted a string that is never rendered anywhere; `WALK-04-03` matched the page's own static CSS instead of seeded data. Neither was currently failing, but both matched the exact vacuous-pass rot class GREEN-04's must-haves name.
- **Fix:** Routed `WALK-04-01` to `/audit/timeline` with a positive empty-state assertion; replaced `WALK-04-03`'s CSS-matching substring with the two actual data-driven chip labels.
- **Files modified:** `examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_evidence_test.exs`
- **Verification:** `mix test test/threadline_phoenix_web/walkthrough_evidence_test.exs` (3 tests, 0 failures, two consecutive runs); grep-confirmed both new assertion targets are absent from the static stylesheet.
- **Committed in:** `c43bb578`

**3. [Rule 3 - Blocking] Local worktree's Postgres role lacked the `threadline` schema on its search_path**
- **Found during:** Task 1 (initial verification attempt after the fix)
- **Issue:** `mix test` failed with `Postgrex.Error 42P01 undefined_table` for `audit_transactions` — the tables live in the `threadline` schema, which was not on the connecting role's default search_path on this specific local database. `.github/workflows/ci.yml` already applies this exact `ALTER DATABASE` in CI; this worktree's freshly-created local database simply hadn't had it applied yet.
- **Fix:** Applied the identical `ALTER DATABASE threadline_phoenix_test SET search_path TO "$user", public, threadline;` CI already runs, locally.
- **Files modified:** none (database-level, not code)
- **Verification:** `mix test`/`mix verify.example` ran cleanly afterward.
- **Committed in:** N/A (environment setup only, no trackable file change)

**4. [Rule 3 - Blocking] Concurrent sibling-worktree access to the shared local test database produced transient, unrelated errors during diagnosis**
- **Found during:** Task 1/2 verification attempts
- **Issue:** Running against the repository's default shared `threadline_phoenix_test` database intermittently produced unrelated transient errors (`undefined_table`, `Ecto.StaleEntryError`, a missing chip-text assertion) consistent with this plan's sibling worktree (198-27) running its own test/seed activity against the identically-named shared database concurrently.
- **Fix:** Used `MIX_TEST_PARTITION=_198_25` to create and verify against an isolated local database for this plan's own verification runs. No code changed for this — documented as an environment-only discovery in the audit file, not attributable to product or seed code.
- **Files modified:** none (local environment only)
- **Verification:** All flakiness cleared once isolated; the closing `mix verify.example` measurement was re-run against the shared database (matching CI's actual environment) once confirmed clean, and still passed 109/0 twice.
- **Committed in:** N/A (environment setup only)

---

**Total deviations:** 4 (2 Rule 1/2 — code fixes authorized by the diagnosis exceeding pre-declared scope; 2 Rule 3 — local environment blockers, no code change).
**Impact on plan:** No scope creep beyond what the plan's own dispatch context explicitly authorized ("diagnose the real cause ... wherever it genuinely lives"). All fixes stayed within the operator-surface/demo-seed/test layers; nothing touched `ci.yml`, `mix.exs`, or `playwright.config.ts` (confirmed empty diff). No dependency added or upgraded.

## Issues Encountered

- The `ExUnit.TimeoutError`'s full root-cause class (an externally-orphaned Postgres session that can outlive its owning process and block a future demo-seed run) is only partially addressed by this plan's advisory-lock hardening — the complete fix (e.g. a Postgres-side `idle_in_transaction_session_timeout` reaper) applies pool-wide, is riskier, and is out of this plan's declared scope. Documented honestly in the audit file as `D4`'s `human_judgment: true` coverage entry rather than claimed as fully closed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `mix verify.example` measured at 109 tests, 0 failures on two consecutive runs — the phase's local readiness target reached.
- Per D-01, GREEN-04 remains **Pending** — this plan is a local readiness signal only; the verdict belongs exclusively to plan 198-29's measured CI run.
- Plans 198-26/27/28 can proceed independently; this plan touched only the operator-surface LiveView/Presentation label, two sibling root-library test files, `walkthrough_case.ex`, `walkthrough_evidence_test.exs`, and the shared audit file — no Playwright/e2e files touched, consistent with the parallel-execution boundary with plan 198-27.
- No new `deferred-items.md` entry was needed — no residual failure remains; the one partial mitigation (D4's advisory-lock scope limit) is documented in the audit file and this SUMMARY's coverage block for a future maintainer's judgment, not left silent.

## Self-Check: PASSED

- All 6 key files confirmed present on disk (`ls -la`).
- All 3 commits (`e6f3cd5d`, `c43bb578`, `b1652ade`) confirmed in `git log --oneline`.
- `mix verify.example`: 109 tests, 0 failures, two consecutive runs (post-commit re-verification).
- Root library `mix test`: 1422 tests, 0 failures.
- `git diff -- .github/workflows/ci.yml mix.exs playwright.config.ts`: empty.

---
*Phase: 198-green-bringup*
*Completed: 2026-08-28*
