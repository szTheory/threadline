# Phase 177 — Deferred / Out-of-Scope Items

## Pre-existing example-app demo-seed timeout (discovered during 177-05)

- **Status:** acknowledged
- **Acknowledged at:** v1.40 milestone close, 2026-08-27

- **File:** `examples/threadline_phoenix/test/mix/tasks/threadline_evidence_show_example_test.exs:20`
- **Symptom:** `mix verify.example` (and `mix ci.all`) reports 1 failure: the test setup
  (`ThreadlinePhoenix.Demo.Seed.run/0` → `Demo.Seed.Exports.run/1` `insert_all`) exceeds the
  default 60s ExUnit setup timeout on the local dual-Postgres dev environment.
- **Proof it is pre-existing:** the same test fails identically with ALL plan-05 changes stashed
  (verified via `git stash` + run on clean baseline). It references no plan-05 artifact
  (stress fixtures / design-system-ledger / DESIGN-SYSTEM.md / group stories).
- **Scope:** out of scope for Phase 177 (presentational stress scaffold). Belongs to the
  example sub-project's demo-seed performance, not the design system.
- **Suggested owner:** a future example-app/perf phase — either speed up `Demo.Seed` under
  trigger-backed inserts or add `@tag timeout:` to the heavy demo-seed setup tests.
