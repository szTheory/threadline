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


- **Existing motion-fixture keyboard focus race exposed during the B3 measurement window (2026-10-27).** Main attempt-1 run 40435657557 at 89add23e failed mobile job 121963594493 in `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts:275`: toast stayed visible after focusing Close and pressing Enter immediately after Confirm stress modal. The same delayed modal focus restoration pattern was proved and synchronized in the separate accessibility evidence test (source b35750bd). Motion spec is byte-identical to B2 29abf565 and was outside the B3 source delta. Keep this failed attempt explicitly excluded from the five-successful-run wall median, as D-08 prescribes; do not rerun its attempt/job or hide it. Preserve the fixed source during this measurement window. Follow-up: apply the same modal-hidden and opener-focused state waits before toast keyboard dismissal in the motion fixture, verify both projects without retries and through a green quality PR. This is test synchronization, not a relaxed assertion or a numeric gate exception. The CI-03 ratio miss remains independently open. Resolved on new source by 832bfe5e (Plan 247-17): both modal-hidden and exact opener-focused waits now precede the subsequent toast path. Focused desktop/mobile passed 2/2 and the complete motion spec passed 24/24 (12 per project), all with retries disabled; independent review found no findings. See `247-17-SUMMARY.md`. Historical run 40435657557 remains failed and excluded; no retry or retroactive reclassification.
