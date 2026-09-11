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

## 199-05: Pre-existing pair-label token wiring TODO

- **Status:** open
- **Discovered during:** Plan 199-05 pre-summary stub scan
- **Evidence:** `examples/threadline_phoenix/e2e/critic/label.ts:708` assigns `pair_with_token: null` with a TODO to wire pair tokens when pair mode is implemented; blame traces it to commit `a248073a9`, before this plan.
- **Scope:** Plan 199-05 owns filesystem authority and atomic writes, not golden-oracle pair-mode behavior.
- **Disposition:** Deferred to a future critic-labeling behavior plan; it does not block DECOUPLE-01 or the adapter-backed reader/writer goal.

## 199-05: Roadmap SDK legacy-layout fallback

- **Status:** resolved
- **Discovered during:** Plan 199-05 sequential state synchronization
- **Evidence:** `roadmap.update-plan-progress 199` returned `missing_phase_details` even though the Phase 199 checklist and progress row exist.
- **Scope:** Planning-state handler compatibility only; production implementation is unaffected.
- **Disposition:** Reconciled the single Plan 199-05 checklist row and Phase 199 progress count from the nine summary-backed plans; all unfinished rows remain unchecked.

## 199-11: Pre-existing locked dependency advisories

- **Status:** open
- **Discovered during:** Plan 199-11 committed-checkout dependency verification
- **Evidence:** `mix deps.get --check-locked` completed successfully but reported current security advisories for locked versions of `decimal`, `hackney`, `phoenix`, `phoenix_live_view`, `plug`, and `postgrex`.
- **Scope:** Plan 199-11 proves committed checkout cleanliness and does not own dependency selection or lockfile changes; neither `mix.exs` nor `mix.lock` changed.
- **Disposition:** Defer remediation to a dependency-security upgrade plan that can assess compatibility and update the lockfile with focused regression coverage.

## 199-16: Pre-existing full-suite Dialyzer contract drift

- **Status:** open
- **Discovered during:** Plan 199-16 overall verification
- **Evidence:** `mix test` ran 1,519 tests and reported two failures: `Threadline.PlanningDependencyContractTest` rejects the existing planning-history read in `test/threadline/dialyzer_ignore_contract_test.exs`, and `Threadline.DialyzerIgnoreContractTest` still caps warning origins at 14 while the sealed analysis contains 22.
- **Scope:** Plan 199-16 owns only the five query/storage warning origins and their source-backed fixture; neither failing contract test is an authorized Plan 199-16 file.
- **Disposition:** Deferred to the plan that owns the repository-wide Dialyzer contract migration. All Plan 199-16 focused suites and the exact 10-warning source verifier pass.
