---
phase: 224-capture-and-bench-fixes
plan: 03
subsystem: ci
tags: [mix, bench, ci, contract-test]

requires: []
provides:
  - "bench/mix.exs compiles with a bare `mix compile` via `def cli, do: [preferred_envs: [compile: :test, run: :test]]`"
  - "`mix verify.bench_compile` alias, wired into `ci.all` and the existing `verify-compile-no-optional` CI job"
  - "`bench_compile_errors/3` contract classifier with 6 mutation controls pinning the wiring"
affects: [225-suite-baseline]

actuals:
  tokens: 2955
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Mix `def cli` preferred_envs idiom applied to a sub-project (bench/) whose path dependency is forced into :test"
    - "bench_compile_errors/3 pure classifier pinning alias wiring, ci.all ordering, and CI step placement with mutation controls (same idiom as dialyzer_topology_errors/3 and removed_proof_errors/3 in the same file)"

key-files:
  created: []
  modified:
    - bench/mix.exs
    - mix.exs
    - .github/workflows/ci.yml
    - CONTRIBUTING.md
    - test/threadline/ci_topology_contract_test.exs
    - .planning/phases/224-capture-and-bench-fixes/224-EVIDENCE.md

key-decisions:
  - "Bundled the bench/mix.exs, mix.exs, ci.yml, CONTRIBUTING.md and contract-test changes into a single fix(bench) commit, per the plan's explicit Task 2 acceptance criteria, rather than the generic per-task commit default"
  - "verify_bench_compile/1 runs `unset MIX_ENV` so the bare-compile proof cannot be made non-bare by a parent `MIX_ENV=test mix ci.all` invocation"
  - "Evidence (224-EVIDENCE.md) committed separately from the code fix, staged by exact path"

patterns-established:
  - "bench_compile_errors/3 follows this file's established {ok?, message} tuple + Enum.reject/Enum.map pattern for contract classifiers"

requirements-completed: [SUITE-05]

coverage:
  - id: D1
    description: "bench compiles bare from a wiped bench/_build and bench/deps via preferred_envs, no MIX_ENV needed"
    requirement: SUITE-05
    verification:
      - kind: other
        ref: "bash -c 'rm -rf bench/_build bench/deps && env -u MIX_ENV mix verify.bench_compile' (exit 0)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The bare compile is proven in the existing per-PR verify-compile-no-optional CI job (no new job, no cache step, no roster change) and pinned by a text contract with 6 mutation controls"
    requirement: SUITE-05
    verification:
      - kind: unit
        ref: "test/threadline/ci_topology_contract_test.exs#bench compiles bare via preferred_envs and is proven in the no-optional CI job (SUITE-05)"
        status: pass
      - kind: integration
        ref: "mix test test/threadline/ci_topology_contract_test.exs test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_all_dedup_contract_test.exs (94 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Local mutation control recorded: removing def cli from bench/mix.exs makes a wiped-state verify.bench_compile fail with 'module ExUnitProperties is not loaded'; restoring makes it pass again"
    requirement: SUITE-05
    verification:
      - kind: manual_procedural
        ref: ".planning/phases/224-capture-and-bench-fixes/224-EVIDENCE.md#SUITE-05 mutation control"
        status: pass
    human_judgment: false

duration: ~35min
completed: 2026-09-30
status: complete
---

# Phase 224 Plan 03: Bench Compile Fix Summary

**`bench/mix.exs` now compiles with a bare `mix compile` via `def cli, do: [preferred_envs: [compile: :test, run: :test]]`, proven by a new `verify.bench_compile` step in the existing `verify-compile-no-optional` CI job and pinned by a `bench_compile_errors/3` text contract with 6 mutation controls.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-09-30T17:32:37Z (STATE.md last_updated)
- **Completed:** 2026-09-30
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- `bench/mix.exs` gains `def cli, do: [preferred_envs: [compile: :test, run: :test]]` — a contributor typing `mix compile` in `bench/` now resolves `:test` (matching the forced `{:threadline, path: "..", env: :test}` path dep) instead of the previous `:dev`/`:test` mismatch that failed with `module ExUnitProperties is not loaded`.
- `mix.exs` gains the `"verify.bench_compile": &verify_bench_compile/1` alias and a private `verify_bench_compile/1` that runs `unset MIX_ENV && cd bench && mix deps.get && mix compile --warnings-as-errors`, wired into `ci.all` directly after `"verify.compile_no_optional"`. `verify_bench/1`'s own `MIX_ENV=test` prefixes are untouched (5 occurrences, unchanged).
- `.github/workflows/ci.yml`'s `verify-compile-no-optional` job gains one new step, `Compile bench project (bare mix compile)` running `mix verify.bench_compile` — no cache step, no job rename, no `ci-required` `needs:` change. `git diff dd780e68 -- .github/workflows/ci.yml` shows exactly the two added step lines plus a blank separator.
- `CONTRIBUTING.md`'s `verify-compile-no-optional` row now names `mix verify.bench_compile` alongside the existing purpose text.
- `test/threadline/ci_topology_contract_test.exs` gains `bench_compile_errors/3`, a pure classifier asserting (1) `bench/mix.exs` carries `def cli` + the exact `preferred_envs` text, (2) `"verify.bench_compile"` appears exactly once in `ci.all` and directly follows `"verify.compile_no_optional"`, (3) the CI step exists in `verify-compile-no-optional` after the no-optional step and nowhere else, and (4) `verify_bench_compile/1`'s command contains `unset MIX_ENV` and no `MIX_ENV=`. One test proves the live tree is clean (`== []`) and exercises 6 named mutation controls, each proven non-vacuous.
- Local mutation control recorded in `224-EVIDENCE.md`: removing `def cli` from `bench/mix.exs`, wiping `bench/_build`/`bench/deps`, and running `env -u MIX_ENV mix verify.bench_compile` fails with `module ExUnitProperties is not loaded`; restoring and wiping again makes it pass.

## Task Commits

1. **Task 1: Tracer — bare bench compile through the new alias, ci.all and the CI step** + **Task 2: Text contract with in-test mutations, plus the recorded local mutation control** — bundled per Task 2's acceptance criteria into a single code commit - `4ca8f8db` (fix)
2. **Evidence record** - `8c7af4ed` (docs)

_The plan's Task 2 acceptance criteria explicitly required bundling ci.yml, mix.exs, bench/mix.exs, CONTRIBUTING.md, and the contract test into one `fix(bench)` commit with evidence staged separately by exact path; followed literally rather than the generic per-task commit default._

## Files Created/Modified
- `bench/mix.exs` - `def cli` with `preferred_envs: [compile: :test, run: :test]`
- `mix.exs` - `"verify.bench_compile"` alias + `verify_bench_compile/1`, inserted into `ci.all` after `"verify.compile_no_optional"`
- `.github/workflows/ci.yml` - new step in `verify-compile-no-optional`: `Compile bench project (bare mix compile)`
- `CONTRIBUTING.md` - `verify-compile-no-optional` row names the bench proof
- `test/threadline/ci_topology_contract_test.exs` - `bench_compile_errors/3` + one live test with 6 mutation controls
- `.planning/phases/224-capture-and-bench-fixes/224-EVIDENCE.md` - new `## SUITE-05 mutation control` section (red + green excerpts)

## Decisions Made
- Bundled all production-code changes (Task 1 + Task 2) into a single `fix(bench)` commit exactly as the plan's Task 2 acceptance criteria specified, rather than committing Task 1 (tracer) separately per the generic executor protocol; evidence committed separately, staged by exact path.
- Scoped the `verify_bench_compile/1` text extraction in the contract test to the function body only (stopping at the enclosing `end`, with comment lines stripped) after an initial false-positive: the function's own explanatory comment (`... MIX_ENV=test mix ci.all ...`) otherwise tripped the "no MIX_ENV=" rule, and an unscoped split also picked up an unrelated `MIX_ENV=dev mix docs` alias later in the file.

## Deviations from Plan

None - plan executed exactly as written. (The single-commit bundling above is not a deviation — it is what the plan's own Task 2 acceptance criteria specify.)

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- SUITE-05 complete. `bench/` now compiles bare in the same per-PR CI job that already ran the no-optional-deps proof, with a text contract and a recorded local mutation control.
- `mix test test/threadline/ci_topology_contract_test.exs test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_all_dedup_contract_test.exs` (94 tests, 0 failures), `mix verify.credo` and `mix format --check-formatted` all green.
- `bin/verify-repo-hygiene` clean (4263 tracked files, 0 inert).
- Ready for `224-02` (wave 2, DB-backed property test) and `224-04` (wave 3, docs + SUITE-06 measurement).

## Self-Check: PASSED

- `[ -f bench/mix.exs ]` FOUND
- `[ -f mix.exs ]` FOUND
- `[ -f .github/workflows/ci.yml ]` FOUND
- `[ -f CONTRIBUTING.md ]` FOUND
- `[ -f test/threadline/ci_topology_contract_test.exs ]` FOUND
- `[ -f .planning/phases/224-capture-and-bench-fixes/224-EVIDENCE.md ]` FOUND
- `git log --oneline -5` shows `8c7af4ed` and `4ca8f8db` present in history
- Re-ran all task `<verify>` commands: clean-state `env -u MIX_ENV mix verify.bench_compile` (exit 0), `mix test test/threadline/ci_topology_contract_test.exs test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_all_dedup_contract_test.exs` (94/0), `bin/verify-repo-hygiene` (clean), `mix verify.credo` (clean), `mix format --check-formatted` (clean) — all pass
- `plan_head_before: cfe1ce59`, `plan_head_after: 8c7af4ed`, commits measured via `git rev-list --count cfe1ce59..HEAD` = 2

---
*Phase: 224-capture-and-bench-fixes*
*Completed: 2026-09-30*
