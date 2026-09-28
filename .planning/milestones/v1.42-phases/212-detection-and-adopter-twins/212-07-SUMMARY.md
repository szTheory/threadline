---
phase: 212-detection-and-adopter-twins
plan: 07
subsystem: verification
tags: [phase-gate, ci, pgbouncer, hex-evaluator, browser-lane, docs]

requires:
  - phase: 212-detection-and-adopter-twins
    provides: "212-01..06: findings API, all five codes, Mix task gate and viewer, PgBouncer proof, both adopter twins"
provides:
  - "Phase 212 gate evidence: ci.all, PgBouncer topology lane, hex evaluator, unscoped browser lane, docs build, vocabulary scan"
affects: [212-verification]

commits: 3
plan_head_before: e7882dbc

key-files:
  created: []
  modified:
    - test/threadline/operator_surface/coverage_doc_contract_test.exs
    - lib/mix/tasks/threadline.health.coverage.ex
    - lib/mix/tasks/threadline.verify_coverage.ex
    - lib/threadline/health.ex
    - lib/threadline/health/finding.ex
    - lib/threadline/query.ex

key-decisions:
  - "Gate fixes were committed as separate fix(212-07) commits, and every gate was re-run on the fixed tree."
  - "The gate executor subagent stalled after committing the three fixes (stream watchdog, 600s without progress) and before re-running ci.all. The orchestrator ran the full gate sequence itself on the fixed tree (acf5ca19) and wrote this summary."

duration: ~90min (ci.all 68 min under heavy shared-machine load; browser lane 19.5 min)
completed: 2026-09-26
---

# Phase 212 Plan 07: Phase Gate Summary

**Every phase 212 gate is green on `acf5ca19`, including the three lanes `ci.all` does not cover. The unscoped browser lane shows exactly the 8 known screenshot failures and no ninth.**

## Gate Fixes (committed before the final gate run)

| Commit | Gate that caught it | Fix |
|--------|---------------------|-----|
| `cd281ea8` | `mix credo --strict` (inside ci.all) | readability: use a sigil in `coverage_doc_contract_test.exs` (a test touched by 212-03) |
| `a96baaab` | Dialyzer `unmatched_returns` (inside ci.all) | `_ =` on the discarded `load_capture_config!/0` result and the NOT GATED `if` in both coverage Mix tasks |
| `acf5ca19` | `mix docs --warnings-as-errors` | public moduledocs in `health.ex`, `health/finding.ex` and `query.ex` stopped autolinking `@moduledoc false` modules (`TriggerCaptureConfig`, `TriggerFindings`, `RowKey`). The `query.ex` reference dates from phase 211, so the CI docs job would have failed on 211 as well. |

## Final Gate Run (tree `acf5ca19`, script `gate212.sh`, 2026-09-26 06:21–07:49)

| Gate | Command | Result |
|------|---------|--------|
| ci.all | `mix ci.all` | **exit 0**. Tests: `9 properties, 2190 tests, 0 failures, 2 excluded`. Dialyzer: `Total errors: 0, Skipped: 0, Unnecessary Skips: 0`. Browser: `316 passed, 2 flaky, 26 skipped, 0 failed` (see Flakes). |
| PgBouncer up | `docker compose --profile pgbouncer up -d`; `pg_isready` on 5433 and 6432 | exit 0 |
| Topology bootstrap | `MIX_ENV=test DB_HOST=localhost DB_PORT=5433 THREADLINE_TOPOLOGY_BOOTSTRAP=1 mix run priv/ci/topology_bootstrap.exs` | exit 0 |
| Topology tests | `MIX_ENV=test DB_HOST=localhost DB_PORT=6432 THREADLINE_PGBOUNCER_TOPOLOGY=1 mix verify.topology` | **exit 0**. The 2 `:pgbouncer_topology` tests ran and passed (`..`, 0 failures); every other tag was excluded. |
| Coverage gate via pooler | `... DB_PORT=6432 THREADLINE_PGBOUNCER_TOPOLOGY=1 mix verify.threadline` | **exit 0**. `findings: 0 gated error(s), 1 not-gated error(s), 1 warning(s)`. The bootstrap's disabled-trigger fixture printed under NOT GATED with its exact `ALTER TABLE ... ENABLE TRIGGER` fix. |
| PgBouncer down | `docker compose --profile pgbouncer stop pgbouncer` | exit 0 (only the pgbouncer container stopped) |
| Hex evaluator | `mix verify.hex_evaluator` (rehearsal mode) | **exit 0**, `19 tests, 0 failures` |
| Docs | `MIX_ENV=dev mix docs --warnings-as-errors` | **exit 0** |
| Vocabulary scan | `grep -rnE '\b(D-[0-9]{2,}\|HLTH-0[0-9]\|TWIN-0[0-9]\|WR-[0-9]{2,})\b' lib/` and `grep -rnE '\bPhase [0-9]{3}\b' lib/` | no matches |
| Browser, unscoped | `mix verify.example_browser` | **exactly the 8 known failures**: `operator-screenshot-regression.spec.ts` :108, :115, :136, :145 × desktop-chromium and mobile-chromium. `326 passed, 8 failed, 16 skipped`. No ninth failure, and none of the eight now passes. Matches the recorded baseline. |
| Scorecards | `git checkout -- test/fixtures/operator_surface/scorecards/` after each browser run | restored; `git status` clean apart from `.planning/config.json` and `.tool-versions`, both pre-existing and never staged |

## Flakes

In `ci.all`'s CI-scoped browser lane, two mobile tests failed their first attempt and passed on retry. Playwright reports them as flaky, not failed, and `ci.all` exited 0:
- `operator-motion.spec.ts:323` (mobile): already documented as the stress-toast lost-click flake class.
- `operator-component-contracts.spec.ts:161` (mobile, horizontal-scroll check across group stories): not previously recorded. It passed on retry, with no code change, during a run slowed to 68 minutes by other projects' concurrent test load.

The browser line therefore reads 316 passed + 2 flaky = 318 non-skipped passing, 26 skipped, 0 failed, against the 318 / 26 / 0 baseline. The unscoped local lane, a separate full run, passed both of these tests.

## Must-Haves

- ci.all exits 0 with 0 browser failures. 318 passed, with 2 of them passing only on retry.
- The PgBouncer topology lane really ran through the pooler: 2 tagged tests, not a skipped or zero-test run.
- verify.hex_evaluator exit 0.
- Unscoped browser: exactly the 8 known failures, no ninth.
- docs --warnings-as-errors exit 0.
- Scorecards restored after every run and never staged; no baseline changes.
- No planning vocabulary in packaged `lib/`.

## Self-Check: PASSED
