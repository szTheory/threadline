---
phase: 227-db-backed-property-tests
plan: 04
subsystem: testing
tags: [streamdata, ex_unit_properties, postgres, retention]

requires:
  - phase: 227-db-backed-property-tests
    provides: "Threadline.Test.DbProperty (227-01): iteration_key/0, with_iteration/2, delete_transactions!/1, assert_audit_tables_empty!/0, the D-06 scale-contract rule, and the hardened mutation-control.sh"
provides:
  - "Threadline.Test.RetentionCutoffGenerators: fixture_gen/0"
  - "cutoff_property_test.exs — PROP-07 property, DB-backed, generated-fact oracle over a real dry run + real Retention.purge/1"
  - "Threadline.Retention dry-run transaction under-count fix (D-20), CHANGELOG Fixed entry, three retention_test.exs examples (D-22)"
  - "property_generator_coverage_test.exs: RetentionCutoffGenerators D-26 floors (exact-cutoff row, mixed-survivor transaction, empty transaction, every batch_size)"
  - "five PROP-07 mutation controls (dry-run/delete <= one-site each, orphan-guard drop, post-delete survivor tamper, dry-run-transaction-fix revert), all killed 5/5"
affects: [228]

actuals:
  tokens: 10385
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "retention fixture built entirely by insert_all against explicit, deterministic uuids derived from the iteration key (no host table/trigger — unlike PROP-04/PROP-06, retention's fixture rows are the audit tables themselves)"
    - "whole-row ::text snapshot before and after a real purge, compared only for ids the generated facts say must survive — covers any column added later without the test needing to know its name"
    - "a DB generator's general mixed-bias branch reaching an edge case only by chance is itself a defect in the generator, not just a weak mutation control — fixed by adding a dedicated biased branch, not by loosening the kill-rate bar"

key-files:
  created:
    - test/support/retention_cutoff_generators.ex
    - test/threadline/retention/cutoff_property_test.exs
    - .planning/phases/227-db-backed-property-tests/tools/mutations/retention_dry_run_lte.patch
    - .planning/phases/227-db-backed-property-tests/tools/mutations/retention_delete_lte.patch
    - .planning/phases/227-db-backed-property-tests/tools/mutations/retention_orphan_guard.patch
    - .planning/phases/227-db-backed-property-tests/tools/mutations/retention_survivor_update.patch
    - .planning/phases/227-db-backed-property-tests/tools/mutations/retention_dry_run_txn.patch
    - .planning/phases/227-db-backed-property-tests/evidence/PROP-07-mutation-dry-run-lte.md
    - .planning/phases/227-db-backed-property-tests/evidence/PROP-07-mutation-delete-lte.md
    - .planning/phases/227-db-backed-property-tests/evidence/PROP-07-mutation-orphan-guard.md
    - .planning/phases/227-db-backed-property-tests/evidence/PROP-07-mutation-survivor-update.md
    - .planning/phases/227-db-backed-property-tests/evidence/PROP-07-mutation-dry-run-txn.md
  modified:
    - lib/threadline/retention.ex
    - CHANGELOG.md
    - test/threadline/retention_test.exs
    - test/threadline/property_generator_coverage_test.exs

key-decisions:
  - "Fixture rows are inserted directly via insert_all against AuditTransaction/AuditChange (no host table, no trigger) — retention's oracle acts on the audit tables themselves, so there is nothing else to capture from"
  - "Deterministic ids: Ecto.UUID.load!(<<n::64, t::32, 0xFFFFFFFF::32>>) for a transaction and <<n::64, t::32, c::32>> for its changes (n = the per-iteration key, t = 1-based transaction index, c = 0-based change index), mirroring db_property.ex's ordered_id/2 convention; insert_all dumps the human-readable uuid string through the schema's binary_id type automatically (227-03's established decision), unlike a raw-SQL uuid parameter which needs Ecto.UUID.dump!/1"
  - "Both the dry run and the real purge are driven by the SAME cutoff and EXPECTED sets computed only from DateTime.compare(captured_at, cutoff) == :lt (D-18) — no eligible-rows predicate is shared with lib/, so a one-site <-to-<= mutation on either side alone is still caught by the dry/real agreement assertion, not just by the direct expected-count assertion"
  - "RetentionCutoffGenerators' transaction_offsets_gen gained a dedicated ~30% 'entirely negative offsets' branch after the retention_dry_run_txn mutation control proved unreliable (survived on 2 of 10 seeds) against the original 90%-general/10%-empty mix — the general offset mix only produces a non-empty, fully-purged ('orphaned by the purge') transaction by chance; this is a generator gap, not a control weakness, so the fix raises the generator's bias rather than loosening the kill-rate bar (per the plan's explicit halt-clause instruction)"

patterns-established:
  - "DB-property retention oracle: snapshot id::text,row::text before a real purge, compute expected survivor/purge/orphan sets from generated timestamps alone, run dry_run: true then the real purge of the identical fixture, and assert both agree with each other and with the generated facts"

requirements-completed: [PROP-07]

coverage:
  - id: D1
    description: "PROP-07 property: Retention.purge/1 selects exactly the rows strictly older than the generated cutoff, dry_run: true and the real purge agree on deleted_changes/deleted_transactions, every surviving row (change and transaction) is byte-identical after the purge, and exactly one completed RetentionRun is recorded with the matching deleted_count"
    requirement: "PROP-07"
    verification:
      - kind: unit
        ref: "test/threadline/retention/cutoff_property_test.exs#purge selects exactly the rows strictly older than the cutoff, dry run and real purge agree, and survivors are byte-identical"
        status: pass
    human_judgment: false
  - id: D2
    description: "D-20 fix: Retention.purge/1's dry run now counts the transactions a completed purge itself would empty (previously under-counted, counting only transactions already empty before the run), with a regression test, two D-22 examples (newer-than-policy-cutoff ArgumentError, precision-0 cutoff equality), and a CHANGELOG Fixed entry"
    requirement: "PROP-07"
    verification:
      - kind: unit
        ref: "test/threadline/retention_test.exs#dry run counts the transactions a purge would empty, matching a completed real purge (D-20 regression)"
        status: pass
    human_judgment: false
  - id: D3
    description: "D-26 generator coverage floors: an exact-cutoff row in >=25% of sampled fixtures, a mixed-survivor transaction in >=20%, an empty transaction at least once, and every batch_size in [1, 2, 3, 500] at least once"
    requirement: "PROP-07"
    verification:
      - kind: unit
        ref: "test/threadline/property_generator_coverage_test.exs#RetentionCutoffGenerators.fixture_gen/0 (cutoff-cluster bias)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Five D-21 mutation controls against Threadline.Retention (dry-run cutoff operator, delete cutoff operator, orphan-drain guard, post-delete survivor content tamper, and a revert of the D-20 dry-run-transaction fix), each killed 5/5 with a reproduced shrunk counterexample, lib/ clean after every revert"
    requirement: "PROP-07"
    verification:
      - kind: other
        ref: "bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh --max-runs 20 .planning/phases/227-db-backed-property-tests/tools/mutations/retention_dry_run_txn.patch test/threadline/retention/cutoff_property_test.exs 5"
        status: pass
    human_judgment: false

duration: ~1h45m
completed: 2026-10-01
status: complete
---

# Phase 227 Plan 04: PROP-07 Retention Cutoff Property Summary

**A DB-backed StreamData property proves `Retention.purge/1`'s cutoff is exact and that a dry run matches a completed real purge byte-for-byte — fixing a real dry-run under-count the property's own research probes found, before the agreement assertion was switched on**

## Performance

- **Duration:** ~1h45m
- **Started:** 2026-10-01
- **Completed:** 2026-10-01
- **Tasks:** 3
- **Files modified:** 16 (13 created, 4 modified, plus `.planning/config.json`'s pre-existing intentional orchestrator change left untouched)

## Accomplishments

- `Threadline.Test.RetentionCutoffGenerators` (`test/support/retention_cutoff_generators.ex`): `fixture_gen/0` yields a cutoff clustered on `~U[2001-01-01 00:00:00.000000Z]` (exactly `.000000`, exactly `.999999`, or a random offset up to ~10^12us, always precision 6), 1-4 transactions each carrying per-change microsecond offsets biased around the cutoff, `delete_empty?` 3:1 toward true, and `batch_size` from `[1, 2, 3, 500]`.
- `test/threadline/retention/cutoff_property_test.exs` (new `test/threadline/retention/` directory): each iteration inserts its own transactions/changes directly via `insert_all` (deterministic uuids derived from the iteration key, per db_property.ex's `ordered_id/2` convention), snapshots both storage-qualified tables with a whole-row `::text` cast, runs `Retention.purge(dry_run: true)` then the real `Retention.purge(sleep_ms: 0)` of the identical fixture, and asserts: the dry run's counts, the real purge's counts, dry/real agreement as a whole-map check, every surviving change and transaction is byte-identical to its pre-purge snapshot, no transaction holding a surviving change was deleted, and exactly one completed `RetentionRun` is recorded with the matching `deleted_count`. Expected purge/survivor/orphan sets come only from `DateTime.compare(captured_at, cutoff) == :lt` on the generated facts — no eligible-rows predicate is shared with `lib/` (D-18), so a one-site `<`-to-`<=` mutation on either the dry-run or the real-delete side alone is still caught by the dry/real agreement assertion. Measured ~111ms unscaled (20 runs) and ~265ms at `THREADLINE_PROPERTY_SCALE=5` (60 runs), both well under the `db(20)` budget thresholds.
- Fixed the dry-run transaction under-count the research probes found (D-20): `dry_run_result/4`'s `not exists` subquery now also requires `c.captured_at >= ^cutoff`, so it counts "transactions with no surviving change" — exactly the orphan set a completed purge produces — instead of only transactions already empty before the run. Shipped as `fix(retention): count transactions a purge would empty in dry runs` with a CHANGELOG `### Fixed` entry (no planning vocabulary), an extended `:dry_run` doc caveat ("the preview assumes the run completes"), a pinned regression example reproducing the exact research-probe fixture (`C = 2001-06-01`, dry `{changes: 2, txns: 0}` before the fix, `{changes: 2, txns: 1}` after), and two more D-22 examples (a cutoff newer than the policy cutoff raises `ArgumentError` naming "retention"; a precision-0 cutoff gives the same dry-run result as the equivalent microsecond cutoff). One pre-existing test (`"dry-run counts only the selected storage schema"`) had its `deleted_transactions` expectation corrected from `1` to `2` — it was unknowingly asserting the old buggy under-count; the real purge against the identical fixture already returned `2`.
- `test/threadline/property_generator_coverage_test.exs` gains a `RetentionCutoffGenerators.fixture_gen/0` describe block proving the D-26 floors: an exact-cutoff row reaches >=25% of 1000 sampled fixtures, a mixed-survivor transaction reaches >=20%, an empty transaction and every `batch_size` each appear at least once.
- Five D-21 mutation controls against `lib/threadline/retention.ex`, each killed 5/5 by the property with a reproduced shrunk counterexample, `lib/` clean after every revert: `retention_dry_run_lte.patch` (dry-run cutoff `<`->`<=`), `retention_delete_lte.patch` (real-delete cutoff `<`->`<=`, same one-site-caught-by-agreement property as the dry-run control), `retention_orphan_guard.patch` (drop the `not exists` guard in `drain_orphans/4` — the cascade then deletes transactions that still hold survivors), `retention_survivor_update.patch` (an `update_all` tamper that rewrites surviving rows' `captured_at` right after the delete batch — caught by the byte-identical snapshot), and `retention_dry_run_txn.patch` (revert the D-20 fix — caught by the dry/real agreement assertion). The last control initially survived on 2 of 10 seeds against the original generator (see Deviations); `RetentionCutoffGenerators` was strengthened with a dedicated ~30% "entirely negative offsets" transaction branch so a purge-orphaned, non-empty transaction is reliably present, and all five controls were re-run and re-captured 5/5 against the updated generator.

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer — PROP-07 retention cutoff property** - `503901c0` (feat)
2. **Task 2: D-20 fix + D-22 examples** - `1d09091f` (fix), then `1436eeff` (test, agreement assertions + coverage floors)
3. **Task 3: D-21 mutation controls** - `d2ee967c` (test)

**Plan metadata:** pending (this commit)

## Files Created/Modified

- `test/support/retention_cutoff_generators.ex` - the retention fixture generator (D-04/D-19), later strengthened with the entirely-negative-offsets branch
- `test/threadline/retention/cutoff_property_test.exs` - the PROP-07 property
- `lib/threadline/retention.ex` - the D-20 dry-run transaction count fix
- `CHANGELOG.md` - the D-20 Fixed entry
- `test/threadline/retention_test.exs` - D-20 regression example, two D-22 examples, one corrected pre-existing assertion
- `test/threadline/property_generator_coverage_test.exs` - `RetentionCutoffGenerators` D-26 floors
- `.planning/phases/227-db-backed-property-tests/tools/mutations/retention_dry_run_lte.patch`
- `.planning/phases/227-db-backed-property-tests/tools/mutations/retention_delete_lte.patch`
- `.planning/phases/227-db-backed-property-tests/tools/mutations/retention_orphan_guard.patch`
- `.planning/phases/227-db-backed-property-tests/tools/mutations/retention_survivor_update.patch`
- `.planning/phases/227-db-backed-property-tests/tools/mutations/retention_dry_run_txn.patch`
- `.planning/phases/227-db-backed-property-tests/evidence/PROP-07-mutation-dry-run-lte.md`
- `.planning/phases/227-db-backed-property-tests/evidence/PROP-07-mutation-delete-lte.md`
- `.planning/phases/227-db-backed-property-tests/evidence/PROP-07-mutation-orphan-guard.md`
- `.planning/phases/227-db-backed-property-tests/evidence/PROP-07-mutation-survivor-update.md`
- `.planning/phases/227-db-backed-property-tests/evidence/PROP-07-mutation-dry-run-txn.md`

## Decisions Made

See `key-decisions` in frontmatter. The two load-bearing ones for later plans:

1. Retention's fixture has no host table or trigger — unlike PROP-04/PROP-06, rows are inserted directly into `AuditTransaction`/`AuditChange` via `insert_all`, because retention's oracle acts on the audit tables themselves.
2. A DB generator's general mixed-bias branch reaching an edge case only "by chance" within a low `max_runs` budget is a generator defect, not just a mutation-control weakness — the fix is a dedicated biased branch, never a loosened kill-rate bar (227's standing halt-clause instruction, applied here concretely).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] A pre-existing test asserted the dry run's pre-D-20 buggy under-count**
- **Found during:** Task 2, GREEN verify run
- **Issue:** `test/threadline/retention_test.exs`'s `"dry-run counts only the selected storage schema"` test asserted `result.deleted_transactions == 1` for a fixture containing one transaction with a single change already before the policy cutoff (now correctly counted as an orphan the purge would empty) plus one pre-existing empty transaction — two orphans, not one. The real purge against the identical fixture (a few lines later in the same file) already asserted `2`. The test's `== 1` expectation was only ever correct under the bug this plan fixes.
- **Fix:** Corrected the assertion to `== 2`, matching the real purge's established-correct behavior for the same fixture.
- **Files modified:** test/threadline/retention_test.exs
- **Verification:** `mix test test/threadline/retention_test.exs` 10/10 green
- **Committed in:** `1d09091f` (Task 2 fix commit)

**2. [Rule 1 - Bug] The `retention_dry_run_txn` mutation control survived on 2 of 10 seeds**
- **Found during:** Task 3, first `mutation-control.sh` run
- **Issue:** `RetentionCutoffGenerators`' original transaction generator (90% general mixed offsets, 10% empty) only produces a non-empty, fully-before-cutoff ("purge-orphaned") transaction by chance (roughly `0.3^k` for a `k`-row transaction under the mixed offset bias) — not reliably within `db(20)`'s 20-run budget. The D-20-fix-revert mutant is invisible except on exactly this case, so the control was flaky across seeds (`FATAL: RED_FILE exited 0 on at least one seed` on the first attempt; manual seed sweep confirmed 2 of 10 seeds passed when they should fail).
- **Fix:** Per the plan's explicit halt-clause instruction ("If WEAK or below 5/5, raise the generator's cutoff-cluster bias, never weaken the patch, and re-run"), added a dedicated ~30% "entirely negative offsets" branch to `transaction_offsets_gen/0` so a purge-orphaned transaction is reliably present. Verified across 10 fresh seeds under the mutant: 10/10 failures. Re-ran and re-captured all five mutation controls against the updated generator (all still 5/5, same `transactions: [[0]]` shrunk fixture for the first four, `transactions: [[-1]]` for the fifth).
- **Files modified:** test/support/retention_cutoff_generators.ex
- **Verification:** `mix test test/threadline/retention/cutoff_property_test.exs --repeat-until-failure 20` green; all five `mutation-control.sh` runs 5/5, `lib/` clean after each
- **Committed in:** `d2ee967c` (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 — a stale test expectation and a generator reliability gap surfaced by the property/mutation work itself, not scope creep).
**Impact on plan:** Neither changed the plan's design. The generator strengthening is additive (it does not remove or weaken any existing D-19/D-26 bias) and was verified not to break the already-passing coverage floors or the tracer's own repeated-run green streak.

## Issues Encountered

**`mutation-control.sh`'s seed-1 reproduce check is flaky independent of this plan's work**, consistent with 227-01's documented finding for `ChangeFactGenerators.fact_gen()`: `fixture_gen/0`'s generated value is printed as a map literal (`%{cutoff: ..., transactions: ..., delete_empty?: ..., batch_size: ...}`), and Elixir's map key print order can differ between separate `mix test` OS-process invocations for the identical generated value (BEAM's per-process randomized hash seed). Each of the five mutation-control captures in this plan needed one retry (2 attempts) before the reproduce check passed; `lib/` stayed clean on every attempt, including the failed ones (the runner's trap-based revert worked correctly throughout). This is the same pre-existing characteristic 227-01 flagged as out of scope for the awk-extraction hardening; not re-fixed here.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- PROP-07 is fully proven: the property, its generator (including the strengthened purge-orphan bias), the D-20 fix with its regression and two D-22 examples, its D-26 coverage floors, and all five mutation controls (killed 5/5) are in place and green.
- `Threadline.Retention`'s only behavior change is the dry-run transaction count becoming accurate — the real purge's logic, return shape, and `RetentionRun` recording are unchanged, so 228 (which attaches `:telemetry` handlers to this same purge fixture per 227-CONTEXT D-11) builds on an unchanged `purge/1` contract.
- Full `mix test` is green (2672 tests, 31 properties, 0 failures, 3 excluded) with these changes in place; `mix verify.format` and `mix verify.credo` are clean; `mix compile --warnings-as-errors` is clean.
- No blockers.

---
*Phase: 227-db-backed-property-tests*
*Completed: 2026-10-01*

## Self-Check: PASSED

All created/modified files confirmed on disk; all 4 task commit hashes (`503901c0`, `1d09091f`, `1436eeff`, `d2ee967c`) confirmed in `git log`.
