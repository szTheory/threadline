# Phase 247 — Regression Gate

Prior-phase test references were extracted from the verification reports for phases 244–246. All 19 existing ExUnit test files ran against an isolated PostgreSQL 16 container on loopback port 61528, under the 600-second workflow timeout.

Result: **554 tests, 0 failures**, exit 0, seed 162809. Container stopped after the run.

Command: `DB_HOST=127.0.0.1 DB_PORT=<ephemeral> mix test` followed by the file list below, wrapped with `gsd-tools.cjs run-with-timeout 600`.

Log: `/tmp/threadline-247-regression.log`; SHA-256 `2c55e7711cd8c3d3a899bfd324509a399c95eafab77ac1ea4df18018e2ead253`.

## Test Files

- `test/threadline/browser_journey_evidence_contract_test.exs`
- `test/threadline/ci_action_pin_contract_test.exs`
- `test/threadline/ci_action_runtime_contract_test.exs`
- `test/threadline/ci_coverage_doc_contract_test.exs`
- `test/threadline/ci_issue_upsert_contract_test.exs`
- `test/threadline/ci_topology_contract_test.exs`
- `test/threadline/ci_workflow_parity_contract_test.exs`
- `test/threadline/date_release_changelog_test.exs`
- `test/threadline/dependabot_config_contract_test.exs`
- `test/threadline/deps_audit_gate_test.exs`
- `test/threadline/deps_health_doc_contract_test.exs`
- `test/threadline/deps_health_report_test.exs`
- `test/threadline/flake_classifier_contract_test.exs`
- `test/threadline/hex_pin_contract_test.exs`
- `test/threadline/operator_surface/stress_ledger_test.exs`
- `test/threadline/release_control_plane_contract_test.exs`
- `test/threadline/retry_network_contract_test.exs`
- `test/threadline/ui_critic_retirement_doc_contract_test.exs`
- `test/threadline/verify_action_pins_test.exs`

This regression result does not satisfy the separate CI-03 numeric acceptance gate.


## Gap execution regression gate (2026-10-27)

Fresh discovery from phases 244–246 VERIFICATION and SUMMARY test references found 33 surviving test files (the earlier 19-file gate above remains historical evidence). Ran all 33 with the actual Elixir entrypoint `mix test <files...>` under the GSD `run-with-timeout 600` wrapper, using an ephemeral PostgreSQL 16 container labelled `dev.threadline.plan=247-verify` and its discovered loopback port. Result: **1 property, 785 tests, 0 failures, 1 configured exclusion; exit 0**, 83.2 seconds. No watch process or timeout. The generic language sniff has no Elixir arm, so the real mix.exs project command was supplied explicitly instead of its fallback no-op.

The fresh list is persisted in the GSD regression-files handoff and was built from actual existing paths; the scoped run includes capture, public surface, fixture, packaging and CI-contract checks. The five files implementing lane weights and the browser synchronization change are additionally covered by Plan 14 and the exact-head Plan 15 full CI gate.
