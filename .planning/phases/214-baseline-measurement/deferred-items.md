# Phase 214 deferred items

Out-of-scope discoveries logged by plan executors. Not fixed in Phase 214 (measurement only).

## From 214-02

- **`:live_dialyzer` passes vacuously without a PLT.** `test/threadline/dialyzer_slice_contract_test.exs`
  shells out (through `bin/verify-dialyzer-slice`) to
  `MIX_ENV=dev mix dialyzer --no-check --format raw --ignore-exit-status`. `--no-check` skips the PLT
  check/build step, so with no `.dialyzer` PLT Dialyzer fails with
  `Could not read PLT file ...: no_such_file`. `--ignore-exit-status` turns that into exit 0 with no
  `{:warn_` lines, and the verifier reports "0 live warnings". Locally the test passed in 1.21 s with the
  PLT moved aside (`raw/local/live-dialyzer.json`, `raw/local/live-dialyzer-cold-raw-dialyzer.txt`).
  Plan 03 or Phase 218 should check whether the CI test lanes (which do not restore `.dialyzer`) hit the
  same vacuous path, and the verifier should fail closed on a Dialyzer run error. Owner: CI economy phase
  (live-Dialyzer test disposition).
- **Runner cache path counted by the local-path regex.** The home-relative regex in
  `tools/measure-base02.sh` matches the Playwright cache `path:` in `.github/workflows/ci.yml` (2 hits) and
  `.github/workflows/browser-full.yml` (1 hit). These are runner paths, not maintainer paths. The Phase 217
  local-path guard needs an allowlist decision for them.

## From 214-03

- **CI test lanes most likely take the vacuous `:live_dialyzer` path too.** `verify-test` (min and current)
  caches only `deps` (ci.yml `Cache deps` step in that job) and restores no `.dialyzer`, and the green push
  run 36258719902 prints no Dialyzer output from either test job. A passing test does not print the
  verifier's output, so this stays an inference until the CI-economy phase captures the test's own output
  (for example with `--trace` on that one file) or makes the verifier fail closed on a Dialyzer run error.
  Recorded in 214-BASELINE.md section 8.
