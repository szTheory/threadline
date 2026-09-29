---
phase: 219-deps-only-build-cache
plan: 02
subsystem: ci
tags: [ci, github-actions, actions-cache, build-cache, contract-test, contributing]
status: complete

requires:
  - phase: 219-01
    provides: "build_cache_errors/2, the <interfaces> step names and ids, the fixture shape and 65 mutation controls"
provides:
  - "exact-keyed deps-only root and example _build caches in verify-test (both lanes), verify-example-browser, verify-capture; restore-only root cache in verify-pgbouncer-topology"
  - "cache-free verify-compile-no-optional (its deps cache step deleted, D-13)"
  - "THREADLINE_BUILD_CACHE / THREADLINE_EXAMPLE_BUILD_CACHE hit|miss key=<primary key> log fields"
  - "present-tense ci.yml CACHE KEY CONTRACT comment and CONTRIBUTING `### Dependency build cache` with runbook"
  - "live contract: build_cache_errors(all_workflows(), CONTRIBUTING) == [], every control run on the live tree, YamlElixir step-count anti-drift"
affects: [219-03]

actuals:
  tokens: 6073
  tasks: 4
  commits: 1
plan_head_before: 3ab2aebf516875f60b322a0a7dbfcdc42a5e8f7d
plan_head_after: cfa615a9d92483bdca5d2d29b6cecd077b8a007e

tech-stack:
  added: []
  patterns:
    - "Split actions/cache/restore@v5 + save@v5 with exact keys and no restore-keys for _build"
    - "Unconditional first-party rm between deps.compile and save/compile"
    - "Lane-silent example log line via a step-env key and a shell non-empty guard"

key-files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - CONTRIBUTING.md
    - test/threadline/ci_workflow_parity_contract_test.exs

key-decisions:
  - "The root restore sits above verify-test's existing D-19 comment so that comment stays attached to `Cache deps`"
  - "The pgbouncer bootstrap now runs a single-line `run: mix run priv/ci/topology_bootstrap.exs`; install, deps compile, rm and compile are separate steps, and the wait step moved after the compile"
  - "The verify-capture row control is scoped to the `### Dependency build cache` section, because live CONTRIBUTING has an earlier CI table with the same row prefix"
  - "The old `dependency cache contract` describe keeps its name; its test is renamed `ci.yml caches deps and the e2e npm lockfile` and the stale _build refute is deleted"

requirements-completed: []

coverage:
  - id: D1
    description: "Whole CACHE-01 contract holds on the live workflows and live CONTRIBUTING"
    requirement: "CACHE-01"
    verification:
      - kind: unit
        ref: "test/threadline/ci_workflow_parity_contract_test.exs#every live workflow and CONTRIBUTING satisfy the whole build cache contract"
        status: pass
  - id: D2
    description: "Every mutation control changes the live input and is red with its own rule= fragment"
    requirement: "CACHE-01"
    verification:
      - kind: unit
        ref: "test/threadline/ci_workflow_parity_contract_test.exs#control: every build cache fault is red on the live tree, each with its own rule"
        status: pass
  - id: D3
    description: "YamlElixir step count equals job_steps/1 count for each allowlisted job"
    requirement: "CACHE-01"
    verification:
      - kind: unit
        ref: "test/threadline/ci_workflow_parity_contract_test.exs#anti-drift: the text step splitter sees every parsed step of each cached job"
        status: pass

duration: 17min
completed: 2026-09-28
---

# Phase 219 Plan 02: Deps-Only Build Cache in CI Summary

**ci.yml now has exact-keyed, deps-only `_build` caches in four test jobs (five job-lanes). Every one removes the first-party apps before it saves or compiles. The plan 01 contract, all 65 controls and a YamlElixir step-count check now run against the real workflows and CONTRIBUTING. Everything landed in one commit.**

## Performance

- **Duration:** about 17 min
- **Completed:** 2026-09-28T14:56Z
- **Tasks:** 4 of 4 (Tasks 1-3 uncommitted by design, Task 4 is the single commit)
- **Files modified:** 3 (+323 / -25)

## Accomplishments

- **Task 1 (tracer), verify-test.**
  - Added the root block: `Restore deps-only build cache` with the `${{ matrix.runner }}` lead, then `Compile dependencies on build cache miss`, `Remove own build (never cached, never reused)` and `Save deps-only build cache`, all around the existing `Cache deps` / `Install dependencies` / `Compile (warnings as errors)`.
  - Added the five example steps before `Verify Threadline Phoenix example`, with the `matrix.lane == 'current'` guards. The example rm step has no guard.
  - The tracer gate re-ran the live per-job assert and passed before expanding.
- **Task 2, the remaining jobs.**
  - Deleted `Cache deps` from `verify-compile-no-optional`.
  - `verify-example-browser` and `verify-capture` gained job-level `MIX_ENV: test` and the five example steps, placed right before their consumers. The Playwright comment block stays attached to its step.
  - `verify-pgbouncer-topology` gained the restore-only root block (literal `ubuntu-24.04` lead). Its combined bootstrap was split into install, deps compile, rm and compile steps, and `Wait for Postgres and PgBouncer` now runs after the compile.
- **Task 3, docs.**
  - The ci.yml `CACHE KEY CONTRACT` comment is now in the present tense. It names `build-v1`, the rm literal and the CONTRIBUTING pointer, and the stale sentence is gone.
  - CONTRIBUTING gained `### Dependency build cache`, placed after the PLT section. It covers what is cached, the cached-job table, the key segments and exclusions, why there are no restore-keys (CargoSense/setup-elixir-project#13), both rm literals, the 13-row not-cached table, the log fields, the benign save race, the 7-day and 10 GB budget, and the poisoned-cache runbook (`gh cache list`, `gh cache delete` with `actions: write`, a `build-v1` bump).
- **Task 4, the live flip.**
  - The old describe keeps the three still-true asserts. The stale `_build` refute is deleted.
  - Three new live tests: the whole contract on the live tree, every control on the live tree, and the YamlElixir anti-drift check.

## Task Commits

1. **Tasks 1-4 (one atomic commit, per the plan):** `cfa615a9` (ci)

TDD evidence: each task's live assert went in with its workflow edit and was run green before moving on. In Task 4, the live control run went red on one control first, and that failure led to deviation 1.

## Verification

- Quick contract suite (parity, topology, action runtime, browser-full): 103 tests, 0 failures. The coverage-doc contract was also green in Tasks 2-3.
- `mix verify.test`: 2502 tests and 9 properties, 0 failures, 3 excluded (the standing tags).
- `mix format --check-formatted`, `mix verify.credo` (no issues), `actionlint -shellcheck= .github/workflows/ci.yml` (clean) and `bin/verify-repo-hygiene` (4037 files clean, 0 inert) all pass.
- The milestone invariants hold:
  - 11 setup-beam steps before and after;
  - no job header added, removed or renamed in the diff;
  - no added `continue-on-error`, `always()` or `restore-keys`;
  - `CI required` count unchanged;
  - `mix.exs`, release.yml, flake-detection.yml and browser-full.yml untouched.
- Acceptance greps: `id: build-restore` 2, `id: example-build-restore` 3, `Save deps-only build cache` 1, `Save example deps and deps-only build cache` 3, `EXAMPLE_BUILD_KEY` guard 3, `^      # CACHE KEY CONTRACT` 1, `^### Dependency build cache$` 1.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The verify-capture row control mutated the wrong table on live text**
- **Found during:** Task 4, running the controls on the live tree
- **Issue:** The control removed the first line in the whole file that starts with ``| `verify-capture` |``. In live CONTRIBUTING, that line is the existing CI table row at line 645 (the `mix verify.capture` description), not the build cache table row. On live text the control therefore changed an unrelated table and could not produce `rule=doc-contributing`. Plan 01 had proven this control only on the fixture CONTRIBUTING, which has a single such row.
- **Fix:** Added `remove_build_cache_section_row/2`. It applies the same first-match row regex, but only after the `### Dependency build cache` heading. If the section is missing, it returns the text unchanged, which the control runner then reports as "did not change its input".
  - The fragment, the label and the rule under test are unchanged. On the fixture the control removes the same row as before.
  - This makes the control more precise, not weaker. The unrelated CI table was not edited.
- **Files modified:** `test/threadline/ci_workflow_parity_contract_test.exs`
- **Commit:** `cfa615a9`

### Minor choices

- The `dependency cache contract` describe keeps its name; only the test is renamed.
- The anti-drift test reads ci.yml through `Path.join(@repo_root, ...)` rather than a bare relative path, so it does not depend on the working directory.

## Known Stubs

None.

## Threat Flags

None. No new permissions, triggers or endpoints. The only new trust-boundary surface is the cache service, which is covered by T-219-06 to T-219-11.

## Next Phase Readiness

The static half of CACHE-01 is enforced on the real tree. Plan 03 owns the runtime half:
- two 64-hex segments after `-full-` in the rendered key (RESEARCH A1);
- the rendering of the hit/miss idiom (A2/A3);
- whether root `config/test.exs` loads cleanly under the new job-level `MIX_ENV: test` in `Run example Playwright suite` (Pitfall 7).

Plan 03 needs a maintainer grant to push and dispatch.

## Self-Check: PASSED

- All three modified files exist, and commit `cfa615a9` is in `git log`. `git rev-list --count 3ab2aebf..HEAD` = 1.
