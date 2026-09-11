---
phase: 199
slug: decouple
status: planned
wave_0_complete: true
nyquist_compliant: true
created: 2026-09-10
updated: 2026-09-10
---

# Phase 199 — Validation Strategy

Every implementation task has an automated command. `wave_0_complete: true` means all required contract scaffolds are explicitly assigned to early tasks (199-01, 199-04, 199-07, 199-09, 199-10, 199-11, 199-12, 199-13); it does not claim implementation has run. `nyquist_compliant: true` describes plan coverage only.

## Validation Architecture

| Layer | Purpose | Primary command |
|---|---|---|
| Fast contract | Fixture ownership and tracked-only digest | `mix test test/threadline/operator_surface/operator_surface_fixture_contract_test.exs -x` |
| Edge adapters | Elixir and TypeScript explicit-input paths | Focused ExUnit suites and `npm --prefix examples/threadline_phoenix/e2e run test:paths` |
| Repository hygiene | Exact deletion, ignore, formatter, and planning scans | Focused contract suites plus `mix format --check-formatted` |
| Static analysis | Full-app warnings and strict ignore ratchet | `mix dialyzer`; `mix dialyzer --no-check --list-unused-filters` |
| Integration | Clean committed clone and planning-absent aggregate | `bin/verify-clean-checkout`; `bin/verify-planning-independent` |

## Task-to-Command Matrix

| Plan.Task | Wave | Automated command | Frequency |
|---|---:|---|---|
| 199-01.1 | 1 | `mix test test/threadline/operator_surface/mechanical_checker_test.exs -x` | each commit |
| 199-01.2 | 1 | `mix test test/threadline/operator_surface/mechanical_checker_test.exs -x && mix verify.format` | plan exit |
| 199-02.1 | 2 | `mix test test/threadline/operator_surface/stress_router_test.exs examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs -x` | each commit |
| 199-02.2 | 2 | `mix test test/threadline/operator_surface/mechanical_checker_test.exs test/threadline/operator_surface/refute_partition_test.exs test/threadline/operator_surface/stress_ledger_test.exs test/threadline/operator_surface/stress_router_test.exs -x` | plan exit |
| 199-03.1 | 1 | `mix test test/threadline/operator_surface/critic_trust_test.exs -x` | each commit |
| 199-03.2 | 1 | `mix test test/threadline/operator_surface/critic_trust_test.exs -x && mix verify.format` | plan exit |
| 199-04.1 | 1 | `npm --prefix examples/threadline_phoenix/e2e run test:paths` | each commit |
| 199-04.2 | 1 | `npm --prefix examples/threadline_phoenix/e2e run test:paths` | plan exit |
| 199-05.1 | 2 | `npm --prefix examples/threadline_phoenix/e2e run test:paths && npm --prefix examples/threadline_phoenix/e2e run critic:check` | each commit |
| 199-05.2 | 2 | `npm --prefix examples/threadline_phoenix/e2e run test:paths && npm --prefix examples/threadline_phoenix/e2e run critic:check` | plan exit |
| 199-06.1 | 2 | `npm --prefix examples/threadline_phoenix/e2e run test:paths && npm --prefix examples/threadline_phoenix/e2e run typecheck` | each commit |
| 199-06.2 | 2 | `npm --prefix examples/threadline_phoenix/e2e run typecheck && npm --prefix examples/threadline_phoenix/e2e run test:paths` | plan exit |
| 199-07.1 | 1 | `mix test test/threadline/operator_surface/operator_surface_fixture_contract_test.exs -x` | each commit |
| 199-07.2 | 1 | `mix test test/threadline/operator_surface/operator_surface_fixture_contract_test.exs -x` | plan exit |
| 199-08.1 | 3 | `mix test test/threadline/operator_surface/operator_surface_fixture_contract_test.exs test/threadline/operator_surface/mechanical_checker_test.exs test/threadline/operator_surface/critic_trust_test.exs test/threadline/operator_surface/refute_partition_test.exs test/threadline/operator_surface/stress_ledger_test.exs test/threadline/operator_surface/stress_router_test.exs -x && npm --prefix examples/threadline_phoenix/e2e run test:paths` | each commit |
| 199-08.2 | 3 | `mix test test/threadline/operator_surface/operator_surface_fixture_contract_test.exs test/threadline/release_artifact_contract_test.exs -x && mix hex.build` | plan exit |
| 199-09.1 | 1 | `mix test test/threadline/removed_artifact_contract_test.exs test/threadline/readme_doc_contract_test.exs -x` | each commit |
| 199-09.2 | 1 | `mix test test/threadline/removed_artifact_contract_test.exs test/threadline/readme_doc_contract_test.exs -x && mix verify.format` | plan exit, including explicit double-run status/diff snapshot assertion |
| 199-10.1 | 1 | `mix test test/threadline/clean_checkout_contract_test.exs -x` | each commit |
| 199-10.2 | 1 | `mix test test/threadline/formatter_topology_contract_test.exs -x && mix format --check-formatted` | plan exit |
| 199-11.1 | 2 | `mix test test/threadline/clean_checkout_contract_test.exs -x` | each commit |
| 199-11.2 | 2 | `mix test test/threadline/clean_checkout_contract_test.exs -x && bin/verify-clean-checkout` | plan exit |
| 199-12.1 | 1 | `mix test test/threadline/row_history_focus_evidence_contract_test.exs test/threadline/operator_surface/style_contract_test.exs test/threadline/planning_dependency_contract_test.exs -x` | each commit |
| 199-12.2 | 1 | `mix test test/threadline/planning_dependency_contract_test.exs test/threadline/zero_skips_contract_test.exs -x && mix verify.test` | plan exit |
| 199-13.1 | 4 | `mix dialyzer` | after triage/fix iteration and plan exit |
| 199-13.2 | 4 | `mix test test/threadline/dialyzer_ignore_contract_test.exs -x && mix dialyzer --no-check --list-unused-filters` | each ratchet change |
| 199-14.1 | 5 | `mix test test/threadline/ci_topology_contract_test.exs test/threadline/ci_coverage_doc_contract_test.exs test/threadline/dialyzer_ignore_contract_test.exs -x && mix dialyzer --no-check` (also proves cold-build/analysis GNU-time marker topology) | each commit |
| 199-14.2 | 5 | Human checkpoint: push prepared commit/branch and supply/record cold + identical-commit hit CI run URLs/IDs | once, after Task 1 commit |
| 199-14.3 | 5 | `mix test test/threadline/ci_topology_contract_test.exs test/threadline/ci_coverage_doc_contract_test.exs -x` | once, after authenticated read-only miss/hit retrieval |
| 199-14.4 | 5 | `mix test test/threadline/planning_independence_contract_test.exs test/threadline/planning_dependency_contract_test.exs -x && bin/verify-planning-independent` | phase exit |

## External Checkpoint Topology

| Plan.Task | Type | Ordering | Required evidence | Failing direction |
|---|---|---|---|---|
| Human handoff | `checkpoint:human-action` | After committed CI wiring; before evidence retrieval | Maintainer pushes the prepared branch/commit, dispatches the identical commit once, and supplies or records both CI run URLs/IDs | Halt if remote SHA differs, either ID is absent, either run targets another commit, or any secret is requested |
| Agent retrieval | `auto` | Resumes only after the human handoff | Authenticated read-only inspection proves cold miss then exact-key hit and records provenance/cost | Fail on unauthenticated/unlinked evidence, mismatched SHA/key predicate, placeholder/estimate, or timeout-formula drift |

## Wave Gates

| After wave | Required evidence |
|---:|---|
| 1 | Synthetic fixture/deletion/planning scanners have teeth; Mix/ESM edges, ignore policy, formatter topology, and live-source preservation pass. |
| 2 | Elixir stress/test adapters, all TS consumers, and committed-HEAD clean-clone proof pass without same-wave file overlap. |
| 3 | The 427-entry move is recognized as byte-identical renames; ignored scores do not alter the manifest; actual Hex artifact excludes repository evidence. |
| 4 | Full Dialyzer and strict ignore/unused-filter contracts pass with execution-derived triage and ceiling. |
| 5 | The maintainer checkpoint publishes/dispatches the prepared commit; authenticated read-only miss/hit evidence is then recorded, and the complete committed aggregate passes with planning physically absent. |

## Final Sign-off

- [ ] All eight DECOUPLE requirements have a passing automated proof.
- [ ] Every required dataset/test runs non-vacuously and every safety contract retains a positive control.
- [ ] `mix verify.format`, `mix verify.test`, `mix dialyzer --no-check --list-unused-filters`, `bin/verify-clean-checkout`, and `bin/verify-planning-independent` pass.
- [ ] Authenticated cold/hit measurements and execution-derived timeout are present in `CONTRIBUTING.md`.
- [ ] No skipped/tagged/broad-allowlisted test or planning-backed runtime path exists.
