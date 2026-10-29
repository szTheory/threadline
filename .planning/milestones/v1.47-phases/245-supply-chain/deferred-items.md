# Phase 245 deferred items

Out-of-scope discoveries logged during execution. They are not fixed in this phase.

## Intermittent flake: TriggerRerunPropertyTest (found in 245-05 gate run 1)

- **Test:** `test/threadline/capture/trigger_rerun_property_test.exs:24`, property "a random chain of 1-4 runs rolls back to zero new orphaned capture functions".
- **Failure:** `assert Harness.threadline_triggers("public", table) == []` returned `[{"threadline_audit_trp_405", "O"}]` after 5 successful runs. The generated value was `[:default, :default, :default, :default]`.
- **Context:** first `CI=true mix ci.all` on an ephemeral postgres:16, library suite seed 825295: 3432 tests, 1 failure. Phase 245 does not touch capture or trigger code.
- **Not reproducible:** the same seed (825295) on a fresh postgres:16 gave 0 failures, the file alone passed 5 times out of 5, a full `mix test` passed, and the re-run `ci.all` was green (exit 0).
- **Suggested follow-up:** run `mix verify.flake` against this file, or look at whether a concurrent sync test can leave a `default`-mode trigger behind on a `trp_*` table.
  status: acknowledged
