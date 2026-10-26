# Deferred Items — Phase 226

Out-of-scope discoveries found during execution, not fixed (per the executor's
scope boundary: only auto-fix issues directly caused by the current task's
changes).

## 226-02

- `test/support/redaction_policy_generators.ex` fails `mix format
  --check-formatted` (two spots: the `defect_tags/0` list, and the `too_long_gen/0`
  `gen all(...)` clause). Pre-existing from 226-01 — confirmed by checking
  `mix format --check-formatted` against the 226-01 commit before any 226-02
  change touched this file. Not touched by 226-02; left unfixed here.
  **RESOLVED** in commit `b24ee66a` (226-01 follow-up `mix format` pass) — `mix
  format --check-formatted` is clean across the whole repo as of 226-03.
