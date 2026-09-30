---
phase: 218-ci-economy-remove-waste
plan: 03
subsystem: ci
status: complete
tags: [ci, dialyzer, github-actions, contract-tests, econ-05]
requires: ["218-02"]
provides:
  - "bin/verify-dialyzer-slice completed_run/1 (fails closed: exactly one dialyxir completion marker, no `:dialyzer.run error:` line)"
  - "mix verify.dialyzer_slice alias (preferred env :test) + ci.all entry `cmd env MIX_ENV=test mix verify.dialyzer_slice`"
  - "verify-dialyzer job: postgres:16 service + `Live Dialyzer slice proof (fails closed)` step, timeout 12"
  - "test_helper :default_test_excludes app-env key (one binding shared with ExUnit.configure)"
affects: ["218-04", "218-08"]
tech-stack:
  added: []
  patterns:
    - "positive completion marker as proof an --ignore-exit-status analyzer actually ran"
    - "app-env copy of the default exclude list, immune to Mix CLI filter re-configuration"
    - "narrow, self-tested dedup exemption for a single-file --only leaf over a default-excluded tag"
key-files:
  created: []
  modified:
    - bin/verify-dialyzer-slice
    - test/threadline/dialyzer_slice_contract_test.exs
    - test/test_helper.exs
    - test/threadline/zero_skips_contract_test.exs
    - .github/workflows/ci.yml
    - mix.exs
    - CONTRIBUTING.md
    - test/threadline/ci_topology_contract_test.exs
    - test/threadline/ci_all_dedup_contract_test.exs
decisions:
  - "Verifier requires exactly one completion marker (`done (passed successfully)` or `done (warnings were emitted)`, ANSI stripped); any `:dialyzer.run error:` line wins over a marker"
  - "Negative proof is built from raw output copied verbatim from dialyxir 1.4.8 dialyzer.ex:68/120/122 inside tmp_dir; no live missing-PLT dialyxir run (no PLT-path override short of moving the maintainer's PLT)"
  - "verify-dialyzer timeout re-derived as ceil((252 + 80) * 2 / 60) = 12: test-env compile 47 s and container init 23 s from run 36258719902 `Run test suite (current)`, live test ~10 s (estimate)"
  - "Topology-test live-slice tuples moved into a live_slice_checks/3 helper to keep dialyzer_topology_errors/3 under credo's complexity cap"
metrics:
  duration: "~10 min wall (594 s), including one 199 s full-suite run"
  completed: 2026-09-27
actuals:
  tokens: 9700
  tasks: 2
  commits: 2
plan_head_before: 34aaedb5d5e25aa4af5e5cf4a74add272da96e5d
plan_head_after: 15d7f521f02e52e98c2677e47c763ad15b9c2bb6
---

# Phase 218 Plan 03: Live Dialyzer slice, fail-closed, in verify-dialyzer only Summary

`bin/verify-dialyzer-slice` now fails with `Dialyzer did not complete` when the raw output lacks exactly one dialyxir completion marker or carries a `:dialyzer.run error:` line. Before this, `--ignore-exit-status` masked a missing PLT as "0 live warnings". The `:live_dialyzer` test is excluded from default `mix test` and runs only through `mix verify.dialyzer_slice`: in the `verify-dialyzer` job (postgres:16 service, `MIX_ENV: test`, after the PLT restore/build/save and analysis) and in `ci.all` right after `verify.dialyzer`.

## What was built

- **`bin/verify-dialyzer-slice`**
  - New `completed_run/1` step in the `main/1` with-chain, between `raw_output/1` and `parse_raw_output/1`. It applies to live and `--raw-output` input alike.
  - `@dialyzer_command` / `@dialyzer_args` are byte-identical (acceptance diff check passed).
- **`test/threadline/dialyzer_slice_contract_test.exs`**
  - 7 new `@tag :tmp_dir` rows via a `run_raw/3` helper that writes the raw output exactly as given:
    - red: missing-PLT error, empty output, error plus marker, error plus stray warn lines, two markers;
    - green: an ANSI-wrapped passed marker, and the warnings-emitted marker.
  - `run_fixture/3` appends `done (passed successfully)` by default (`completion_marker: false` opts out), so the existing synthetic positives stay green (RESEARCH P9).
- **`test/test_helper.exs`**: one `exclude` binding, `[live_dialyzer: true]` or `[pgbouncer_topology: true, live_dialyzer: true]`, passed to `ExUnit.configure/1` and stored with `Application.put_env(:threadline, :default_test_excludes, exclude)`.
- **`zero_skips_contract_test.exs`**: pins both ExUnit's exclude list and the app-env key to exactly the two sanctioned gates, each with its reason. A third tag is still forbidden.
- **`mix.exs`**:
  - alias `verify.dialyzer_slice`, with `preferred_envs` `:test`;
  - `ci.all` entry `cmd env MIX_ENV=test mix verify.dialyzer_slice` immediately after the dev `verify.dialyzer` entry.
- **`.github/workflows/ci.yml` `verify-dialyzer`**:
  - `DB_HOST`/`DB_PORT` env;
  - a `postgres:16` service copied verbatim from `verify-mechanical`;
  - the new step after `Analyze and measure with Dialyzer`;
  - `timeout-minutes: 12`, with the formula and source run in the comment.
- **`ci_topology_contract_test.exs`**:
  - order position for the live step;
  - `live_slice_checks/3`: the step exists with `MIX_ENV: test`, the postgres:16 service is present, no other job runs the slice or tag, test_helper has the exclusion, and `ci.all` runs the slice once after the dev dialyzer;
  - new timeout and formula pins;
  - mutation controls: step deleted, step moved before the analysis, alias added to verify-test, ci.all entry dropped.
- **`ci_all_dedup_contract_test.exs`**:
  - `validate_single_test_step/2` and `default_excluded_tags/0`, which reads `Application.fetch_env!(:threadline, :default_test_excludes)`;
  - `excluded_tag_names/1` handles tuple and atom entries and raises on anything else;
  - `disjoint_tagged_leaf?/2` recognizes the exempt single-file `--only` leaf.
  - Test count went from 14 to 24 (10 new self-test rows): accept; reject with an empty excluded list; reject `--only other_tag`; reject `--include`; reject a leaf with no `--only`; reject a second `--only`; reject two paths; accept `TAG:value`; a mixed-shape normalization row; an unknown shape raises.
- **`CONTRIBUTING.md`**:
  - the local command list gains `mix verify.dialyzer` and `mix verify.dialyzer_slice`;
  - new text documents the two default-excluded gates with their reasons;
  - the `verify-dialyzer` table row names the live step;
  - the Dialyzer contract section explains the fail-closed rule and notes that removing the test from `verify-test (min)` drops no real coverage (it passed vacuously there, with no PLT);
  - the timeout paragraph carries the new formula and links run 36258719902.

## dialyxir source citations (negative-proof shapes)

From `deps/dialyxir/lib/dialyxir/dialyzer.ex`, dialyxir 1.4.8:
- line 68: `{:error, ":dialyzer.run error: " <> Chars.to_string(msg)}` (the error prefix)
- line 120: `color("done (passed successfully)", :green)`
- line 122: `color("done (warnings were emitted)", :yellow)`

A local raw run confirms the live output ends with `done (passed successfully)`.

## TDD evidence

**RED** (Task 1 negative rows run against the unchanged verifier, which exited 0 for every one of them):

```
  1) test two completion markers fail closed
  2) test a Dialyzer run error with no completion marker fails closed
  3) test empty raw output fails closed
  4) test an error line wins over a completion marker
  5) test an error line alongside stray warn lines fails closed
17 tests, 5 failures
```

Each failure had the same shape: `right: {"verified slice critic-tooling: 3/40 sealed warnings; 3 authorized origins; 0 live warnings\n", 0}`. This is the vacuous pass the plan targets.

**GREEN** (after `completed_run/1`): `17 tests, 0 failures`.

**Live positive on the real PLT**: `MIX_ENV=test mix test test/threadline/dialyzer_slice_contract_test.exs --only live_dialyzer` gave `17 tests, 0 failures, 16 excluded`; the live test ran in 3537 ms. `bin/verify-dialyzer-slice --fixture test/fixtures/dialyzer/critic-tooling.json` printed `verified slice critic-tooling: 3/40 sealed warnings; 3 authorized origins; 0 live warnings`. The existing local PLT was current, so no rebuild was needed, and `.dialyzer` was never moved.

## Verification run

- `actionlint -shellcheck=`: clean.
- `mix test` on zero_skips, ci_topology, ci_workflow_parity, dialyzer_slice and ci_all_dedup: `85 tests, 0 failures, 1 excluded`.
- `MIX_ENV=test mix verify.dialyzer_slice` and bare `mix verify.dialyzer_slice`: `17 tests, 0 failures, 16 excluded`. The live test ran.
- `mix test test/threadline/dialyzer_slice_contract_test.exs`: `17 tests, 0 failures, 1 excluded`.
- `mix test test/threadline/ci_all_dedup_contract_test.exs --exclude no_such_probe_tag`: `24 tests, 0 failures`.
- `mix test test/threadline/ci_all_dedup_contract_test.exs:30`, with the line resolved by grep: `24 tests, 0 failures, 23 excluded`. The `--trace` output shows the one live dedup test ran and passed. See deviation 2.
- `mix verify.format` and `mix verify.credo`: clean.
- Full default `mix test` after the Task 2 commit: `9 properties, 2404 tests, 0 failures, 3 excluded`.
- `bin/verify-repo-hygiene` after committing: clean.
- Every acceptance grep passed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Credo complexity on `dialyzer_topology_errors/3`**
- **Found during:** Task 2 (`mix verify.credo`)
- **Issue:** Adding the live-slice locals and tuples inline raised cyclomatic complexity to 15 (max 9).
- **Fix:** Moved them into `live_slice_checks/3`, which is appended to the tuple list with `Kernel.++/2`. The checks themselves are unchanged.
- **Files modified:** test/threadline/ci_topology_contract_test.exs
- **Commit:** 15d7f521

**2. [Plan verify pattern] `file:LINE` output shape on Elixir 1.17**
- **Found during:** Task 2 verify row 4
- **Issue:** The plan greps `^1 test, 0 failures`. Mix 1.17 counts the excluded tests, so it prints `24 tests, 0 failures, 23 excluded`.
- **Resolution:** No code change. The intent still holds: exactly one test ran and it passed, with ExUnit's exclude list replaced by `[:test]`, which is the case the app-env key exists for. `--trace` confirms that the only test that ran was `exactly one ci.all step, verify.test, runs test files`.

**3. [Scope] Extra rows beyond the plan's minimum**
- Two extra fail-closed rows in dialyzer_slice (error plus stray warn lines, two markers), and two extra dedup self-tests (`TAG:value` accepted, unknown exclude shape raises). They cover the plan's flagged edge rows and the "anything else should raise" rule.

## Hand-offs

- **CI confirmation** needs a push, which is the maintainer's call. The first `verify-dialyzer` run after landing will be cold, because the PLT cache key hashes `mix.exs` and this plan changed it. That run is the first real measurement of the new 12-minute budget and of the live step on CI (cite it in 218-08).
- No GitHub writes were made; the only `gh` call was the read-only `gh api .../runs/36258719902/jobs`.

## Known Stubs

None.

## Threat Flags

None. The only new surface is a Postgres service container in `verify-dialyzer`, the same as the one in `verify-mechanical`.

## Self-Check: PASSED

- FOUND: bin/verify-dialyzer-slice, test/threadline/dialyzer_slice_contract_test.exs, test/test_helper.exs, test/threadline/zero_skips_contract_test.exs, .github/workflows/ci.yml, mix.exs, CONTRIBUTING.md, test/threadline/ci_topology_contract_test.exs, test/threadline/ci_all_dedup_contract_test.exs
- FOUND: faa5f7e4 (Task 1), 15d7f521 (Task 2)
