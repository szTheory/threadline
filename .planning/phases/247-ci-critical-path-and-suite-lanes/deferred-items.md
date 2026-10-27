# Phase 247 deferred items

## From 247-08 (Task 3)

- **`bin/measure-main-ci --ratios` exits 1 on gh 2.101.** Its `job-log` read
  (`gh api repos/{owner}/{repo}/actions/jobs/<id>/logs`) now fails with "the response contains
  terminal escape sequences; pass --allow-escape-sequences to output it anyway". CI job logs
  always contain ANSI. 247-08 worked around it, without changing code, with a read-only
  `GH_BIN` shim that adds the flag to `gh api` calls. Fix the script before 247-12 / 247-13 run it
  for D-08 / D-12. Older gh versions reject the flag, so either feature-detect it (for example
  `gh api --help | grep -q allow-escape-sequences`) or pin a minimum gh, and add a self-test
  case. The plan text's `gh api …/logs` reads need the same flag. Out of 247-08's scope: its
  files are planning-only.

  **Resolved in 247-13** (`d1261dfd`): the script feature-detects the flag from
  `gh api --help`, and the fake-gh contract covers both gh generations.

## From 247-13 (Task 1)

- **Time-sensitive `as_of` pair flaked once in local `CI=true mix ci.all`.**
  `test/threadline/query/row_key_read_test.exs:204` (`as_of` at `DateTime.utc_now()` right
  after a write returned `:before_audit_horizon`) and
  `test/threadline/query/as_of_property_test.exs:94` (`captured_at did not strictly
  increase`) failed together in run 1 (seed 414420). Both passed in isolation with that seed
  and with 4 more seeds, and the full gate re-run on the unchanged tree was green. Neither
  file is in the B2 diff. Both compare database `captured_at` with BEAM wall-clock time, so
  load or clock-correction sensitivity is the likely cause. Candidate for `mix verify.flake`.
  Out of 247-13's scope.
