---
phase: 217-repo-hygiene
plan: 02
subsystem: testing
tags: [exunit, tmp_dir, bash, mix-alias, temp-leak-guard]

requires:
  - phase: 215-supply-chain-gate
    provides: "bin/verify-deps-audit's bin-script + MIX_BIN seam + aggregated-failure pattern, copied for the leak-check script"
provides:
  - "bin/verify-temp-leaks: private-TMPDIR mix test wrapper that fails on any leftover system-temp entry, with MIX_BIN test seam"
  - "mix verify.temp_leaks: opt-in alias (not in ci.all) wrapping the script, args pass through"
  - "Six of the seven leaking files (RESEARCH's list) migrated to ExUnit @tag/@moduletag :tmp_dir"
  - "A full mix test run (2360 tests) proven to leave zero entries in the system temp dir"
affects: []

actuals:
  tokens: 8709
  tasks: 3
  commits: 3
  plan_head_before: 653ca87b0fbea8c5f0a825d16b6d21fbcdae2c56
  plan_head_after: d633c16ae2390018715249c62b3c8f89845d5f9d

tech-stack:
  added: []
  patterns:
    - "bin/ guard script + MIX_BIN test seam + --self-test-free aggregated behavior matrix, copied from bin/verify-deps-audit"
    - "ExUnit @tag/@moduletag :tmp_dir + fixture-injection instead of hand-rolled System.tmp_dir!(), copied from playwright_fail_fast_contract_test.exs"

key-files:
  created:
    - bin/verify-temp-leaks
    - test/threadline/temp_leak_check_test.exs
  modified:
    - test/threadline/operator_surface/exports_mix_parity_test.exs
    - test/threadline/getting_started_fixtures_test.exs
    - test/threadline/branch_protection_comparison_contract_test.exs
    - test/threadline/ci_attestation_contract_test.exs
    - test/threadline/e2e_preflight_contract_test.exs
    - test/threadline/operator_surface/refute_partition_test.exs
    - mix.exs
    - CONTRIBUTING.md
    - bin/verify-playwright-fail-fast
    - test/threadline/capture/trigger_migrate_time_errors_test.exs
    - test/threadline/capture/trigger_pk_override_test.exs

key-decisions:
  - "bin/verify-temp-leaks strips a trailing slash from TMPDIR before building its mktemp template. macOS sets TMPDIR with a trailing slash by default; the unstripped double slash it would otherwise bake into every private-TMPDIR path broke a real path-equality assertion in gen_triggers_test.exs (Path.join(System.tmp_dir!(), name) preserves an internal double slash from its first argument; Path.wildcard normalizes it away when reading the same file back), so this was a hard requirement discovered during the full-suite proof, not a style choice."
  - "bin/verify-playwright-fail-fast now points NODE_COMPILE_CACHE and PWTEST_CACHE_DIR at its own already-cleaned-up scratch dir. npm's CLI (module.enableCompileCache() with no argument) and Playwright's TS transform cache both default to os.tmpdir() otherwise, and this script's private-TMPDIR leak check proved they do write there on every run."
  - "trigger_migrate_time_errors_test.exs and trigger_pk_override_test.exs were missing the File.rm_rf!(tmp) line that every sibling MigrationHarness-using test file has after Harness.cleanup!/drop_fixtures! in on_exit — MigrationHarness.cleanup! only forgets migration versions and unloads compiled modules; it never removes the scratch directory. Added the missing line to match the sibling convention exactly, rather than inventing a new cleanup shape."

requirements-completed: [HYG-03]

coverage:
  - id: D1
    description: "bin/verify-temp-leaks runs mix test with a private per-run TMPDIR and fails, naming each leftover, when anything remains after the run"
    requirement: "HYG-03"
    verification:
      - kind: unit
        ref: "test/threadline/temp_leak_check_test.exs (6 tests: leak, no-leak, exit-status passthrough with/without a leak, arg passthrough, private-dir cleanup)"
        status: pass
      - kind: integration
        ref: "bin/verify-temp-leaks (full default mix test, no args) — 2360 tests, 0 failures, 0 leaks"
        status: pass
    human_judgment: false
  - id: D2
    description: "exports_mix_parity_test.exs (Task 1 tracer) and five more named files migrated from bare System.tmp_dir!() to ExUnit @tag/@moduletag :tmp_dir; planning_independence_contract_test.exs deliberately kept on System.tmp_dir!() (out-of-repo clone)"
    requirement: "HYG-03"
    verification:
      - kind: unit
        ref: "bin/verify-temp-leaks against each of the 6 migrated files plus planning_independence_contract_test.exs — 43 tests, 0 failures, 0 leaks"
        status: pass
    human_judgment: false
  - id: D3
    description: "mix verify.temp_leaks alias (opt-in, not in ci.all) and a CONTRIBUTING.md rule-of-thumb bullet"
    requirement: "HYG-03"
    verification:
      - kind: unit
        ref: "grep -c '\"verify.temp_leaks\"' mix.exs == 1; ci.all block contains 0 occurrences; grep -c 'verify.temp_leaks' CONTRIBUTING.md >= 1"
        status: pass
    human_judgment: false

duration: ~70min
completed: 2026-09-27
status: complete
---

# Phase 217 Plan 2: Temp-Dir Leak Check and ExUnit tmp_dir Migration Summary

**A private-TMPDIR `bin/verify-temp-leaks` wrapper (behavior-tested, opt-in `mix verify.temp_leaks` alias) proves a full 2360-test `mix test` run leaves nothing in the real system temp dir, after migrating six leaking test files to ExUnit `@tag :tmp_dir` and fixing two unrelated scratch-dir leaks the full-suite proof surfaced.**

## Performance

- **Duration:** ~70 min
- **Tasks:** 3
- **Files:** 2 created, 11 modified

## Accomplishments

- `bin/verify-temp-leaks`: a bash script that runs `mix test` (or any subset of its arguments) with `TMPDIR` pointed at a fresh `mktemp -d` private directory, then fails with a `LEAK <name>` line per leftover if anything remains — even if the tests themselves passed. `MIX_BIN` test seam mirrors `bin/verify-deps-audit`.
- `exports_mix_parity_test.exs` (Task 1, tracer): before the edit, the leak check printed `LEAK parity-csv-*.csv`, `LEAK parity-json-*.json`, and `LEAK parity-ndjson-*.ndjson` on every run (its `setup` handed back a bare `System.tmp_dir!()` with no cleanup at all). Migrated to `@moduletag :tmp_dir`; the check now reports `0 entries left`.
- Five more files migrated to `@tag`/`@moduletag :tmp_dir`, with their now-redundant inline `File.rm_rf!`/`File.rm` calls removed: `getting_started_fixtures_test.exs`, `branch_protection_comparison_contract_test.exs`, `ci_attestation_contract_test.exs`, `e2e_preflight_contract_test.exs`, `operator_surface/refute_partition_test.exs`.
- `planning_independence_contract_test.exs` deliberately kept on `System.tmp_dir!()` per the plan's out-of-repo clause: its verifier clones outside the checkout via `TMPDIR`, and its `try ... after` cleanup already runs on a raised assertion.
- `test/threadline/operator_surface/critic_trust_test.exs`'s deferred scratch-dir-reuse item (STATE.md, carried from the v1.41 archive) is confirmed already fixed by commit `23f0505a` (pid + nanosecond + counter naming, `on_exit` cleanup, `async: false`) — no code change made here.
- `test/threadline/temp_leak_check_test.exs`: a 6-test offline behavior matrix for `bin/verify-temp-leaks`, driven through a fake `mix` via `MIX_BIN`, covering leak/no-leak, exit-status passthrough with and without a leak, argument passthrough, and private-directory cleanup after every case.
- `mix verify.temp_leaks`: opt-in alias (same rationale as `verify.flake` — it re-runs the whole suite, so it stays out of `ci.all`), CLI args pass through to `mix test`.
- `CONTRIBUTING.md`: one rule-of-thumb bullet under "Deterministic tests (no flakes)" naming `@tag :tmp_dir` as the default, `System.tmp_dir!()` + `on_exit` as the out-of-repo exception, and `mix verify.temp_leaks` as the proof.
- Full-suite proof: `bin/verify-temp-leaks` with no arguments (the whole default `mix test`) is **2360 tests, 0 failures, 0 leaks**, after two additional fixes the proof itself surfaced (see Deviations).

## Task Commits

1. **Task 1: Tracer — leak check proves exports_mix_parity leaks, migrate it, check goes green** - `cfb3da1a` (test)
2. **Task 2: Migrate the remaining five leaking files; keep the out-of-repo test and record why** - `28ea6358` (test)
3. **Task 3: Leak-check behavior test, verify.temp_leaks alias, CONTRIBUTING line, full-suite proof** - `d633c16a` (test)

_All three tasks were `type="tracer"`/`type="auto"` with no checkpoints; no separate plan-metadata commit beyond this SUMMARY commit._

## Files Created/Modified

- `bin/verify-temp-leaks` - the leak-check script: private TMPDIR, `LEAK <name>` output, `MIX_BIN` seam, trailing-slash-safe TMPDIR handling
- `test/threadline/temp_leak_check_test.exs` - 6-test offline behavior matrix for the script
- `test/threadline/operator_surface/exports_mix_parity_test.exs` - `@moduletag :tmp_dir`, dropped bare `System.tmp_dir!()`
- `test/threadline/getting_started_fixtures_test.exs` - `@moduletag :tmp_dir`, `write_fixture!/2` threads `tmp_dir`
- `test/threadline/branch_protection_comparison_contract_test.exs` - `@moduletag :tmp_dir`, `compare/2` threads `tmp_dir`, plus a shell-quoting fix (see Deviations)
- `test/threadline/ci_attestation_contract_test.exs` - `@tag :tmp_dir` on the one test that needed it
- `test/threadline/e2e_preflight_contract_test.exs` - `@moduletag :tmp_dir`, `run_preflight/5` threads `tmp_dir`
- `test/threadline/operator_surface/refute_partition_test.exs` - `@tag :tmp_dir`, removed the `try ... after` wrapper
- `mix.exs` - `verify.temp_leaks` alias + `defp verify_temp_leaks/1`
- `CONTRIBUTING.md` - one bullet under "Deterministic tests (no flakes)"
- `bin/verify-playwright-fail-fast` - redirects `NODE_COMPILE_CACHE`/`PWTEST_CACHE_DIR` into its own scratch dir (extra fix, see Deviations)
- `test/threadline/capture/trigger_migrate_time_errors_test.exs`, `test/threadline/capture/trigger_pk_override_test.exs` - added the missing `File.rm_rf!(tmp)` in `on_exit` (extra fix, see Deviations)

## Decisions Made

See `key-decisions` in the frontmatter — all three are documented there with full rationale (the TMPDIR trailing-slash strip, the Node/Playwright cache redirection, and matching the sibling `File.rm_rf!(tmp)` convention).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Unquoted shell path broke on a describe/test-name apostrophe**
- **Found during:** Task 2 (migrating `branch_protection_comparison_contract_test.exs`)
- **Issue:** `compare/2` built a raw `bash -c "... < #{path}"` string. Before migration, `path` was always a flat `System.tmp_dir!()`-based name with no special characters. After migration, `path` is built from the injected `tmp_dir`, which embeds the sanitized describe/test name — e.g. `.../test-the-comparison's-four-edges-edge-1.../rules_1.json`. The apostrophe in "comparison's" broke the unquoted shell redirect (`bash: unexpected EOF while looking for matching \`''`), failing 4 of the file's tests.
- **Fix:** Added a `shell_quote/1` helper (single-quote wrap with embedded-quote escaping) and applied it to both the args and the file path.
- **Files modified:** test/threadline/branch_protection_comparison_contract_test.exs
- **Verification:** All 43 tests across the five Task-2 files pass; `mix verify.format`/`verify.credo` clean.
- **Committed in:** 28ea6358 (Task 2 commit)

**2. [Rule 1 - Bug] `bin/verify-temp-leaks` baked a double slash into every private-TMPDIR path**
- **Found during:** Task 3 (full-suite proof)
- **Issue:** macOS sets `TMPDIR` with a trailing slash (`/var/folders/.../T/`). The script concatenated `"${TMPDIR:-/tmp}/threadline-temp-leak-check.XXXXXX"` without stripping it, so the private directory's own path carried a double slash. `mktemp` and any directory-listing code (`Path.wildcard`, `File.ls!`) normalize that away on read, but `gen_triggers_test.exs` builds a path via `Path.join(System.tmp_dir!(), name)` — which only normalizes at the join boundary, not inside its first argument — and compares it by exact string equality (a pinned `^legacy` match) against a value read back through `Path.wildcard`. The two strings differed by one slash for the same file, so the full-suite run genuinely failed `Mix.Tasks.Threadline.GenTriggersTest`'s "rerun detection" test — three times, with a shifting set of collateral failures each run, which is exactly what an ordering-independent but state-dependent string mismatch looks like across ExUnit's randomized `async: true` scheduling.
- **Fix:** Strip the trailing slash from the TMPDIR base before building the `mktemp` template.
- **Files modified:** bin/verify-temp-leaks
- **Verification:** Isolated re-run of the three previously-failing files (`trigger_migration_test.exs`, `gen_triggers_test.exs`, `source_family_test.exs`) under the leak check: 86 tests, 0 failures. Full-suite re-run: 2360 tests, 0 failures, 0 leaks.
- **Committed in:** d633c16a (Task 3 commit)

**3. [Rule 1 - Bug] `mix.exs`'s `verify_temp_leaks/1` used a bare relative path `System.cmd` could not resolve**
- **Found during:** Task 3 (wiring the alias)
- **Issue:** `System.cmd("bin/verify-temp-leaks", args, ...)` raised `:enoent` — a command string containing `/` is looked up relative to Erlang's own resolution, which did not find it from Mix's invocation context.
- **Fix:** Resolve the script with `Path.expand("bin/verify-temp-leaks")` first, matching the existing `verify_example_browser/1` pattern in the same file.
- **Files modified:** mix.exs
- **Verification:** `mix verify.temp_leaks test/threadline/operator_surface/exports_mix_parity_test.exs` runs and reports `0 entries left`.
- **Committed in:** d633c16a (Task 3 commit)

**4. [Rule 1 - Bug] Two third-party tools (npm, Playwright) write into the real system temp dir by default**
- **Found during:** Task 3 (full-suite proof)
- **Issue:** `bin/verify-playwright-fail-fast` (exercised by `playwright_fail_fast_contract_test.exs`, one of the 40 `System.tmp_dir`-using files but NOT one of the seven leaking ones) invokes `npm exec` and the resolved `playwright` binary. npm's own CLI (`lib/cli.js`) calls `module.enableCompileCache()` with no directory argument, which defaults to `<tmpdir>/node-compile-cache`; Playwright's TS transform cache (`playwright-core/lib/transform/esmLoader.js`) defaults to `<tmpdir>/playwright-transform-cache-<euid>` unless `PWTEST_CACHE_DIR` is set. Both landed directly in the shared system temp root on every run — proven by an isolated single-file re-run before any fix (`LEAK node-compile-cache`, `LEAK playwright-transform-cache-501`), confirming the source was third-party tooling, not this repo's test code.
- **Fix:** This script already creates and cleans up its own scratch directory (`$TMP`, removed via an `EXIT` trap). Exported `NODE_COMPILE_CACHE="$TMP/node-compile-cache"` and `PWTEST_CACHE_DIR="$TMP/playwright-transform-cache"` at the top of the script, redirecting both caches into that already-managed, already-cleaned-up location — a supported environment-variable seam on our own script's child-process invocations, not a change to npm/Node/Playwright source and not an allowlist exclusion in the guard itself.
- **Files modified:** bin/verify-playwright-fail-fast
- **Verification:** Isolated re-run of `playwright_fail_fast_contract_test.exs` under the leak check: 1 test, 0 failures, 0 leaks.
- **Committed in:** d633c16a (Task 3 commit)

**5. [Rule 1 - Bug] Two migration-fixture test files never removed their own scratch directory**
- **Found during:** Task 3 (full-suite proof)
- **Issue:** `trigger_migrate_time_errors_test.exs` and `trigger_pk_override_test.exs` (neither is one of the seven named files) create a `tmp` scratch directory via `System.tmp_dir!()` for `mix threadline.gen.triggers` to write into, then call `Harness.cleanup!(Harness.migration_files(tmp))` in `on_exit`. `MigrationHarness.cleanup!/1` only deletes `schema_migrations` rows and unloads compiled modules — it never removes the directory tree itself. Every one of the twelve other files in this repo that use the same `MigrationHarness` helper ends its `on_exit` with `File.rm_rf!(tmp)` after the same two calls; these two were the only ones missing it, leaking `threadline-migrate-time-errors-*` and `threadline-pk-override-*` directories on every run — confirmed by an isolated single-file re-run before the fix.
- **Fix:** Added the missing `File.rm_rf!(tmp)` line, matching the sibling convention exactly (e.g. `trigger_pk_shapes_test.exs`).
- **Files modified:** test/threadline/capture/trigger_migrate_time_errors_test.exs, test/threadline/capture/trigger_pk_override_test.exs
- **Verification:** Isolated re-run of both files under the leak check: 39 tests, 0 failures, 0 leaks.
- **Committed in:** d633c16a (Task 3 commit)

---

**Total deviations:** 5 auto-fixed (5 bugs, all Rule 1)
**Impact on plan:** All five were required either for the migrated tests to keep passing (deviations 1 and 3) or for the plan's own hard acceptance criterion — a fully clean full-suite `mix verify.temp_leaks` run — to be achievable at all (deviations 2, 4, 5). No scope creep: every fix stayed inside the plan's own "fixed at the source... even when that test is not one of the seven" instruction, and none touched third-party tool source or added a guard exclusion.

## Issues Encountered

None beyond the deviations above. The full-suite proof required four total runs of `bin/verify-temp-leaks` with no arguments (~4.5–9 min each): the first surfaced the leak set and one path-equality failure; a second confirmed the leaks were fixed but the same test family failed again with a *different* member of its describe block (consistent with an env-derived string bug under ExUnit's randomized `async: true` scheduling, not a database ordering flake); isolating the exact double-slash mechanism explained why every affected assertion failed identically; the fourth run, after the trailing-slash fix, was clean: 2360 tests, 0 failures, 0 leaks.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- HYG-03 is closed: `bin/verify-temp-leaks` + `mix verify.temp_leaks` prove a full `mix test` run leaves nothing in the system temp dir; six of the seven named files use `@tag`/`@moduletag :tmp_dir`; the out-of-repo test is documented and untouched; `critic_trust_test.exs`'s deferred item is confirmed already fixed.
- No blockers for the remaining Phase 217 plans (217-03 onward: forward scrub, CI wiring for the repo-hygiene guard, HYG-04 verification).

---
*Phase: 217-repo-hygiene*
*Completed: 2026-09-27*

## Self-Check: PASSED

- `bin/verify-temp-leaks`, `test/threadline/temp_leak_check_test.exs` found on disk.
- Commits `cfb3da1a`, `28ea6358`, `d633c16a` all found in `git log --oneline --all`.
- `mix test test/threadline/temp_leak_check_test.exs` — 6 tests, 0 failures.
- `bin/verify-temp-leaks` (no args, full suite) — 2360 tests, 0 failures, 0 leaks, exit 0.
- `mix verify.format` and `mix verify.credo` — both clean.
- `commits: 3` measured via `git rev-list --count 653ca87b..d633c16a` (matches `actuals.commits`).
