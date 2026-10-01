---
phase: 224-capture-and-bench-fixes
reviewed: 2026-09-30T00:00:00Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - .github/workflows/ci.yml
  - CHANGELOG.md
  - CONTRIBUTING.md
  - bench/mix.exs
  - examples/threadline_phoenix/priv/shape_fixtures/migrations/20260930173006_threadline_triggers_shape_code_keyed_shape_composi_f2f800f9eb80.exs
  - guides/upgrading-to-0.11.md
  - lib/mix/tasks/threadline.gen.triggers.ex
  - mix.exs
  - test/mix/tasks/threadline/gen_triggers_test.exs
  - test/support/migration_harness.ex
  - test/support/trigger_run_generators.ex
  - test/threadline/capture/trigger_rerun_property_test.exs
  - test/threadline/capture/trigger_rerun_test.exs
  - test/threadline/ci_topology_contract_test.exs
findings:
  critical: 0
  warning: 1
  info: 1
  total: 2
status: issues_found
---

# Phase 224: Code Review Report

**Reviewed:** 2026-09-30
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

This phase does two things: (1) fixes `mix threadline.gen.triggers` so that
rolling back a whole default-then-rerun trigger-migration chain drops the
per-table capture function a rerun installed, instead of orphaning it, and
(2) makes `bench/` compile with a bare `mix compile` by forcing its
`compile`/`run` tasks into `:test` via `def cli/0`, proven by a new
`verify.bench_compile` CI step.

I traced the core fix (`down_body/2` in
`lib/mix/tasks/threadline.gen.triggers.ex`) against its own moduledoc, the
generated migration fixture, the unit test suite
(`test/mix/tasks/threadline/gen_triggers_test.exs`), the DB-integration suite
(`test/threadline/capture/trigger_rerun_test.exs`), and the new DB-backed
property test (`trigger_rerun_property_test.exs`, 1-4 run chains, both
default and all three per-table variants). The logic is sound: every
first-run migration's `down` now unconditionally calls the existing
usage-checked `TriggerSQL.drop_function_if_unused/2` for the table's
deterministic per-table function name, which is a safe no-op when no such
function exists and keeps (with a `WARNING`, never `CASCADE`) any function a
live trigger still uses. Rerun migrations' `down` bodies are untouched (still
empty for rerun tables), preserving the documented "rolling back a rerun
keeps capture on" behavior. The generated example-app migration fixture
matches: every first-run table (`shape_join` included, which never leaves
default mode) gets the defensive drop, confirming the "whether or not this
migration itself created one" design intent stated in the moduledoc and
commit message.

The `bench/mix.exs` / `verify.bench_compile` change is narrow and covered by
an extensive `test/threadline/ci_topology_contract_test.exs` mutation-control
suite that pins ordering (`verify.compile_no_optional` →
`verify.bench_compile` in `ci.all` and in the CI job), the absence of
`MIX_ENV=` in the alias command, and that no other job runs the step.

I found no correctness or security defects. Two lower-severity items below
are worth a look.

## Warnings

### WR-01: `verify-compile-no-optional` CI job timeout not re-validated after adding a dependency-fetching step

**File:** `.github/workflows/ci.yml:188-207`
**Issue:** The new `Compile bench project (bare mix compile)` step runs
`cd bench && mix deps.get && mix compile --warnings-as-errors`, which fetches
and compiles `benchee`, `benchee_html`, `benchee_markdown`, `ecto_sql`,
`postgrex`, and the `threadline` path dependency itself (in `:test`, so with
`stream_data`/`ExUnitProperties` on the compile path) — a nontrivial amount
of extra network and compile work. The job's `timeout-minutes: 10` was left
unchanged (224-03-PLAN.md explicitly scoped the change to exclude any
`timeout-minutes` edit), and neither `224-03-SUMMARY.md` nor
`224-EVIDENCE.md` records a measured wall-clock margin against the existing
budget — only that the command exits 0 locally. A slow Hex mirror or cold
dependency cache on a shared runner could push this job over 10 minutes,
turning a correctness fix into an intermittent CI red that has nothing to do
with the change being tested.
**Fix:** Either bump `timeout-minutes` on `verify-compile-no-optional` with
margin, or capture and document an actual CI wall-clock measurement (the way
other phase-224/218 gates document `THREADLINE_*_WALL_SECONDS` evidence) to
confirm the existing budget comfortably covers the new step.

## Info

### IN-01: `CONTRIBUTING.md`'s "no `MIX_ENV`" phrasing is a little imprecise

**File:** `CONTRIBUTING.md:646`
**Issue:** The table entry reads "`mix verify.bench_compile` (the bench
project compiles with a bare `mix compile`, no `MIX_ENV`)". In practice the
compile still runs under `MIX_ENV=test` — `bench/mix.exs`'s
`def cli, do: [preferred_envs: [compile: :test, run: :test]]` forces it there
internally, and `verify_bench_compile/1` in `mix.exs` only guarantees the
*caller's shell* has no `MIX_ENV` exported before invoking `mix compile`. A
reader could take "no `MIX_ENV`" to mean the compile runs in `:dev`, which is
exactly the failure mode this fix proves against.
**Fix:** Reword to something like "…(the bench project compiles with a bare
`mix compile`, `MIX_ENV` unset by the caller; `bench/mix.exs`'s own
`preferred_envs` resolves it to `:test`)".

---

_Reviewed: 2026-09-30_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
