# Deferred Items

## Plan 198-12

- **Status:** acknowledged
- **Acknowledged at:** 2026-08-28 (Plan 198-12 execution)

- `mix ci.all` fails at the `verify.example` step: `examples/threadline_phoenix`'s own
  `ThreadlinePhoenix.DemoContractTest` (`test/threadline_phoenix/demo_contract_test.exs`) has
  5-9 failing tests asserting specific seeded-data shapes (org_memberships actor attribution,
  SEED-03 manifest hero transactions, SEED-05 delete incident) that do not hold against the
  current `mix demo.seed` output. This reproduces standalone (`cd examples/threadline_phoenix
  && MIX_ENV=test mix test test/threadline_phoenix/demo_contract_test.exs`), is unrelated to the
  root-repo `threadline_test` unprefixed-audit-table defect class this plan targets (no
  `Postgrex.Error ERROR 42P01 undefined_table` involved — these are `Ecto.NoResultsError` /
  assertion mismatches against demo-seed content), and matches the recurring "example precommit
  demo-seed/walkthrough failures" pattern already acknowledged & deferred across Phases 177,
  179, 180, and 182 (see `.planning/STATE.md` Deferred Items table). Out of scope for GREEN-04 —
  `files_modified` for 198-12 is limited to the 14 root test files plus `CONTRIBUTING.md`; fixing
  the example app's demo-seed generator/assertions was never part of this plan's target.
  Root `mix test` — the actual GREEN-04 headline — passes at **1397 tests, 0 failures**,
  confirmed on two consecutive runs.
