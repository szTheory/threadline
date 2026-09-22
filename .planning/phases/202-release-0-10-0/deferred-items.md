# Deferred items — Phase 202

## Intermittent: `Threadline.OperatorSurface.CriticTrustTest`

- **Test:** `critic.measure rejects bidirectional canonical overlap without prefix confusion`
- **Observed during:** Plan 202-01 execution, 2026-09-22
- **Frequency:** 2 failures in 6 consecutive `mix test test/threadline/` runs; passes at `--seed 0`.
- **Why deferred:** Out of scope for 202-01. This plan touches
  `lib/threadline/storage_schema.ex`, `lib/mix/tasks/threadline.install.ex`,
  `guides/getting-started-saas.md`, `mix.exs`'s `verify_hex_evaluator/1`,
  `.gitignore`, `bin/with-rehearsal-registry`, the hex evaluator fixture, and two
  doc contract tests. None of them reach critic trust.
- **Suspected mechanism (unverified):** the test builds scratch trees under
  `_build/critic-trust-path-tests/<label>-<random>/`; a collision or cleanup race
  across concurrent runs is the obvious candidate. Not investigated.
- **Next step:** reproduce under `mix verify.flake` and record the failing seed
  before attempting a fix.
