---
phase: 219-deps-only-build-cache
fixed_at: 2026-09-28T18:19:21Z
review_path: .planning/phases/219-deps-only-build-cache/219-REVIEW.md
iteration: 1
findings_in_scope: 7
fixed: 7
skipped: 0
status: all_fixed
---

# Phase 219: Code Review Fix Report

**Fixed at:** 2026-09-28T18:19:21Z
**Source review:** .planning/phases/219-deps-only-build-cache/219-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 7 (fix scope `all`: WR-01..03, IN-01..04)
- Fixed: 7
- Skipped: 0

**Where verification ran:** every gate ran in the main checkout on branch `milestone/v1.43`. No worktree was used, as the orchestrator directed. The numbers can be reproduced from this tree.

## Fixed Issues

### WR-01: The contract validates only the first `_build` restore and first save window

**Files modified:** `test/threadline/ci_workflow_parity_contract_test.exs`
**Commit:** de860adc
**Applied fix:** This fix used TDD.

- **RED:** five new mutation controls, each fragment naming the inserted step:
  - a second root save after `Compile (warnings as errors)` must yield `"Save deps-only build cache again" rule=cache-count`;
  - a second example save after `Regenerate Tier A capture` in `verify-capture` must yield `"Save example build cache again" rule=cache-count`;
  - a second root restore (`restore-keys:`, key `ubuntu-24.04-otp-x`) after the compile must yield `rule=restore-keys`, `rule=key-segment` and `rule=cache-count` on `"Restore stale build cache"`. These are three separate controls.

  A scratch run proved all five red on the live tree, the fixture and the hybrid map before the fix, and no other control changed.
- **GREEN:**
  - `project_cache_errors/2` now runs `restore_errors/3` over every restore of the project.
  - A new `cache_count_errors/2` (`rule=cache-count`) allows one restore per project and exactly one save in a `:save` job. A restore-only job's saves are still reported by `rule=restore-only`.
  - Each extra step is named in its error.

### WR-02: A step-level `MIX_ENV` override inside a cached block passes the contract

**Files modified:** `test/threadline/ci_workflow_parity_contract_test.exs`
**Commit:** f49ac4c2
**Applied fix:** This fix used TDD.

- **RED:** two controls add `env: MIX_ENV: dev` at step level, one to `Compile dependencies on build cache miss` and one to `Compile (warnings as errors)`. Each must yield `"<step>" rule=job-mix-env`. Both were proven red on all three inputs.
- **GREEN:** `job_env_errors/2` now scans every step of a cached job for an uncommented `MIX_ENV:` line and reports it as `rule=job-mix-env`. The job-level check is unchanged. The live `ci.yml` has no step-level `MIX_ENV:` in a cached job, so the live contract stays clean with no YAML change.

### WR-03: The poisoned-cache runbook's durable fix turns the contract red

**Files modified:** `test/threadline/ci_workflow_parity_contract_test.exs`, `CONTRIBUTING.md`
**Commit:** c4d966a0
**Applied fix:**
- A single `@build_key_version "build-v1"` attribute now drives:
  - both `@build_key_segments` entries;
  - the `@build_cache_doc_needles` entry;
  - the `ci_cache_comment_errors/1` check;
  - the literal-save-key control;
  - the fixtures, through a `__BUILD_KEY_VERSION__` placeholder and `with_key_version/1`.
- CONTRIBUTING runbook step 3 now names:
  - the CACHE KEY CONTRACT comment;
  - `@build_key_version` in `test/threadline/ci_workflow_parity_contract_test.exs`;
  - the fact that a partial bump fails `Run test suite`.
- A new control bumps the live `ci.yml` and CONTRIBUTING to `build-v2` without touching the attribute. It asserts that `rule=key-segment`, `rule=doc-ci-comment` and `rule=doc-contributing` all fire.
- The doc rules in `build_cache_errors/2` still pass live.

### IN-01: The CHANGELOG Unreleased entry contradicts itself about the scope of the security fix

**Files modified:** `CHANGELOG.md`
**Commit:** f54a5570
**Applied fix:**
- The two `mint` bullets are now one: "`mint` bumped to 1.11.0 (with `hpax` 1.1.0), fixing four advisories". It names EEF-CVE-2026-82672, -91043 (high), -92103 and -94194 with their GHSA ids.
- The `req` -> `finch` -> `mint` reachability note and the `mix deps.update mint` advice are kept. The advice now notes that it also moves `hpax` to 1.1.0.
- The intro says the release clears "four published security advisories in `mint`".
- The `## Unreleased — highlights` heading is unchanged.
- The CHANGELOG and release contract tests pass.

### IN-02: `remeasure-219.py critical-path` crashes on a run with no successful voting job

**Files modified:** `.planning/phases/219-deps-only-build-cache/tools/remeasure-219.py`
**Commit:** 344678b6
**Applied fix:**
- A new `critical_path_end()` returns `None` when no job ran or no voting job succeeded.
- `sub_critical_path` counts these runs in a separate "not measured" row instead of raising `ValueError`.
- Self-test case (i) covers the all-failed run, the empty run and a normal run.
- The `critical-path` output for the sets `all219`, `warm`, `cold`, `post218` and `base` is byte-identical before and after the fix.

### IN-03: The `verify-test` save and compile guards accept a form with no lane guard

**Files modified:** `test/threadline/ci_workflow_parity_contract_test.exs`
**Commit:** 58d78d3b
**Applied fix:**
- `cache_miss_guards/3` now takes the project. `{verify-test, :example}` accepts only `matrix.lane == 'current' && steps.<id>.outputs.cache-hit != 'true'`. The root block keeps both forms.
- Two new controls strip the lane prefix from the example deps compile and from the example save. They must yield `rule=compile-guard` and `rule=save-guard` respectively. Both were proven red before the change.

### IN-04: The root removal step interpolates `${{ }}` directly into `run:`

**Files modified:** `.github/workflows/ci.yml`, `test/threadline/ci_workflow_parity_contract_test.exs`
**Commit:** fbd5a461
**Applied fix:**
- Both root `Remove own build (never cached, never reused)` steps (`verify-test` and `verify-pgbouncer-topology`) now pass `BUILD_KEY` and `BUILD_HIT` through `env:`. They echo `THREADLINE_BUILD_CACHE=${state} key=${BUILD_KEY}`, which is the same log line as before.
- These are unchanged:
  - every step name and `id:`: the diff of all `- name:` / `id:` lines is empty;
  - the 11 `uses: erlef/setup-beam` steps;
  - the `rm -rf` line.
- The contract fixture's root block mirrors the new shape.
- `actionlint` is clean.

## Verification

All gates ran in the main checkout after the last fix:

| Gate | Result |
|---|---|
| `mix test` on the four contract files (parity, topology, action runtime, browser-full projects) | 104 tests, 0 failures |
| `mix verify.test` | 2503 tests: 1 failure on the first run, then 0 failures on two consecutive re-runs (see note) |
| `mix format --check-formatted` | clean |
| `mix verify.credo` | no issues |
| `bin/verify-repo-hygiene` | clean (4064 files) |
| `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py --self-test` | ok |

**Note on `mix verify.test`:** the first full run reported 1 failure out of 2503 tests. That run's output was not captured, so the failing test is unknown. The next two full runs were green, with 0 failures each.

The finding fixes change only deterministic text-based contract tests, the CHANGELOG, a planning tool and one `ci.yml` step body, and every contract file passed in every run. So this looks like an intermittent failure outside these changes, but it was not proven. If it recurs, run `mix verify.flake`.

---

_Fixed: 2026-09-28T18:19:21Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
