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
