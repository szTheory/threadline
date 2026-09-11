# Phase 199 Deferred Items

## 199-01: Pre-existing repository-wide formatter drift

- **Status:** open
- **Discovered during:** Plan 199-01 Task 2 verification
- **Evidence:** `mix verify.format` reports formatting drift in `test/threadline/e2e_preflight_contract_test.exs`, `test/threadline/phase198_automation_policy_test.exs`, `test/threadline/phase198_nyquist_contract_test.exs`, and `test/threadline/main_ci_observer_contract_test.exs`.
- **Scope:** None of the four files was modified by Plan 199-01. The plan-owned checker and test files pass `mix format --check-formatted` directly.
- **Disposition:** Deferred to the owner of the Phase 198 contract-test formatting drift; Plan 199-01 does not rewrite unrelated files.

## 199-12: Pre-existing Plan-199-01/02 mechanical checker handoff gap

- **Status:** open
- **Discovered during:** Plan 199-12 Task 2 full-suite verification
- **Evidence:** `mix verify.test` ran 1,498 tests and reported one failure in `Threadline.OperatorSurface.RefutePartitionTest`: the test still calls `MechanicalChecker.run(scorecard_dir: tmp_dir)` after Plan 199-01 made `:mechanical_floors` a required explicit input.
- **Scope:** Plan 199-12 does not own `test/threadline/operator_surface/refute_partition_test.exs`; Plan 199-02 explicitly lists that file and depends on 199-01.
- **Disposition:** Deferred to Plan 199-02, which owns migration of operator-surface tests to the explicit fixture/floor boundary. The Plan 199-12 focused scanner, zero-skip, and migrated live-contract tests pass independently.
