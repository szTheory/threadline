---
phase: 66
plan: 02
subsystem: operator-surface-mix-parity
tags:
  - elixir
  - threadline
  - mix-task
  - coverage
  - cli
  - capture-only-adopter
requires:
  - "Threadline.Health.trigger_coverage/1 :schema opt + three-bucket return shape (Plan 66-01)"
provides:
  - "mix threadline.health.coverage viewer with --json and --schema=NAME flags (D-34)"
  - "mix threadline.verify_coverage --schema=NAME additive flag (D-33a)"
  - "Mix-task integration test locking the table format, --json schema, and validation contract"
affects:
  - "66-03 (coverage dashboard LV) — parity between LV and Mix surface is now structural"
  - "66-05 doc-contract test (pins Mix-task literals + --json schema + atom-safety refute)"
tech-stack:
  added: []
  patterns:
    - "OptionParser strict: [json: :boolean, schema: :string] (Mix flag plumbing)"
    - "Two-layer schema validation — regex (~r/\\A[a-z_][a-z0-9_]{0,62}\\z/) THEN parameterized pg_namespace lookup (D-33a)"
    - "Mix.raise/1 on bad schema input — exits 1 with clear message"
    - "Pure stdlib + Ecto + Jason; no Phoenix gating (D-36) — works for capture-only adopters"
    - "Mix.Task.reenable/1 in test setup so each case can re-invoke (Pitfall 8 carry-forward)"
key-files:
  created:
    - "lib/mix/tasks/threadline.health.coverage.ex"
    - "test/threadline/operator_surface/coverage_mix_test.exs"
  modified:
    - "lib/mix/tasks/threadline.verify_coverage.ex"
decisions:
  - "Task 1's TDD RED commit (test/threadline/operator_surface/coverage_mix_test.exs) authored the full 12-case integration test the plan specifies as Task 3's deliverable; Task 3 verified its acceptance criteria against the already-committed file rather than re-authoring it"
metrics:
  duration: ~6 min
  completed: 2026-05-07T00:00:00Z
  tasks: 3
  files: 3
  tests_added: 12
  full_suite: "445 tests / 0 failures (1 excluded — pgbouncer_topology)"
---

# Phase 66 Plan 02: Coverage Dashboard Mix-Task Parity Summary

The Mix-task companion for Phase 66's three-bucket coverage data ships clean: a brand-new `mix threadline.health.coverage` viewer task with locked table-format default, `--json` flag emitting a sorted-keys JSON object whose `expected_uncovered` entries carry per-table `source` provenance (`baseline` vs `config`), and an edge-validated `--schema=NAME` flag (regex `~r/\A[a-z_][a-z0-9_]{0,62}\z/` + parameterized `pg_namespace` lookup, both fail via `Mix.raise/1`); the existing `mix threadline.verify_coverage` CI gate gains the same additive `--schema=NAME` flag with default `"public"` (default behavior byte-equivalent to pre-Phase-66 — existing `verify_coverage_task_test.exs` continues to pass unchanged); a 12-case integration test pins all the locked literals (TABLE/STATUS/SOURCE columns; `covered`/`uncovered`/`expected` status values; `baseline`/`config` source values; `Coverage: N covered, M uncovered, K expected uncovered` footer; sorted JSON top-level keys; `expected_uncovered` entry shape; `--schema=Public` regex rejection; `--schema=nonexistent` `pg_namespace` rejection; `--schema=public;DROP` SQL-injection probe rejection; verify_coverage default-flag unchanged + `--schema=public` byte-equivalence + `--schema=Public` regex rejection); both Mix task source files are clean of `String.to_atom\b` (Pitfall 3 / T-66-08) and clean of interpolated `nspname = '#` (T-66-07).

## What Shipped

### (a) `mix threadline.health.coverage` ships with all locked literals

`lib/mix/tasks/threadline.health.coverage.ex` — new pure-stdlib + Ecto + Jason Mix task. NO file-scope `Code.ensure_loaded?(Phoenix.LiveView)` gate (D-36 — capture-only adopters need this). Module shape mirrors `verify_coverage` boot sequence verbatim (`app.config` + `:ssl`/`:postgrex`/`:ecto_sql` ensure-started + `resolve_repo!/0` + `ensure_repo_started!/1`).

- `@shortdoc "Show trigger coverage for audited tables"`
- `@moduledoc` `## Usage` lists three literal invocations (`mix threadline.health.coverage`, `mix threadline.health.coverage --json`, `mix threadline.health.coverage --schema=NAME`) — Plan 05 doc-contract test will pin these.
- `OptionParser.parse(argv, strict: [json: :boolean, schema: :string])` — schema is `:string`, never `:atom` (Pitfall 3).
- `validate_schema!/2`: regex `~r/\A[a-z_][a-z0-9_]{0,62}\z/` first, then parameterized `SELECT 1 FROM pg_namespace WHERE nspname = $1 LIMIT 1` (T-66-07 mitigation: never interpolated; the `$1` bind list is `[schema]`).
- Default table renderer: `TABLE` (24-col min) / `STATUS` (12-col) / `SOURCE` (remainder) header, separator rule, alphabetically sorted rows, blank line, summary footer literal `Coverage: N covered, M uncovered, K expected uncovered`.
- JSON renderer: `%{"schema" => schema, "covered" => sorted_list, "uncovered" => sorted_list, "expected_uncovered" => [%{"table" => t, "source" => "baseline"|"config"}, ...]}`. The `expected_uncovered` list is a list of objects, not strings, so `jq '.expected_uncovered[] | select(.source == "config")'` works.
- Always exits `:ok` after rendering — viewer, not CI gate (D-34). The CI gate remains `mix threadline.verify_coverage`.
- `@baseline ~w(schema_migrations)` — module attr, deliberately duplicated from `lib/threadline/health.ex`'s `@expected_uncovered_baseline` because module attributes are compile-time only and not exposed across modules. Plan 05's doc-contract test will pin both lists to the same value so they cannot drift.

### (b) `mix threadline.verify_coverage --schema=NAME` is live, default unchanged

`lib/mix/tasks/threadline.verify_coverage.ex` — three additive edits:

1. `def run(_args)` → `def run(argv)`; `OptionParser.parse(argv, strict: [schema: :string])` at the top of `run/1`; `schema = Keyword.get(opts, :schema, "public")`.
2. New `defp validate_schema!(repo, schema)` next to `ensure_repo_started!/1` — verbatim shape from Task 1's helper (D-33a "two-layer belt-and-suspenders"). Called AFTER `ensure_repo_started!(repo)` so the repo is connectable when we hit `pg_namespace`.
3. `Threadline.Health.trigger_coverage(repo: repo)` → `Threadline.Health.trigger_coverage(repo: repo, schema: schema)`.
4. `@moduledoc` gains a `## Schema scope (Phase 66)` paragraph documenting the new flag.

The existing report-rendering path, `expected_tables` resolution, and exit-1-on-violation behavior are untouched. Plan 01's additive `:expected_uncovered` clause in `Verify.CoveragePolicy.violations/2` already keeps the existing CI gate semantics correct for the new bucket.

**Default-flag invariance proven**: `test/threadline/verify_coverage_task_test.exs` (3 tests, exists pre-Phase-66) continues to pass without modification — the additive flag does not alter the no-flag code path. The new integration test also asserts `out_no_flag == out_with_flag` for `--schema=public`, structurally proving byte-equivalence.

### (c) Integration test covers all locked literals + validation paths

`test/threadline/operator_surface/coverage_mix_test.exs` — 12 cases, `use ExUnit.Case, async: false` (single-OS-process Mix gotcha — Pitfall 8), `Mix.Task.reenable/1` for both tasks in `setup` so each case can re-invoke.

| Describe block | Cases | What's locked |
| -------------- | ----- | ------------- |
| default table format | 2 | TABLE/STATUS/SOURCE header, schema_migrations row + "expected"/"baseline" status/source, footer literal `Coverage: N covered, M uncovered, K expected uncovered`, exit-0 (viewer not gate) |
| --json output | 3 | sorted top-level keys `["covered", "expected_uncovered", "schema", "uncovered"]`, entry keys `["source", "table"]` with `source ∈ ["baseline", "config"]`, schema_migrations entry with `source: "baseline"` |
| --schema=NAME validation | 4 | `--schema=public` passes; `--schema=Public` raises `Mix.Error` matching `not a valid PostgreSQL identifier`; `--schema=nonexistent_schema_xyz_definitely_not_present` raises `Mix.Error` matching `not found`; `--schema=public;DROP` SQL-injection probe raises `Mix.Error` matching `not a valid PostgreSQL identifier` |
| mix threadline.verify_coverage --schema=NAME (additive flag) | 3 | default-flag unchanged (try/catch `:exit, {:shutdown, _}`); `--schema=public` byte-equivalent to no-flag; `--schema=Public` raises `Mix.Error` |

`Threadline.Test.Repo` is started by `test/test_helper.exs` (line 35), so the Mix tasks inside the test process can call `repo.start_link()` and get back `{:error, {:already_started, _}}` — the existing `ensure_repo_started!/1` handles this branch, no test-isolation hack needed.

### (d) Atom-safety + SQL-injection refutes both clean

```bash
$ grep -E "String\.to_atom\b" lib/mix/tasks/threadline.health.coverage.ex lib/mix/tasks/threadline.verify_coverage.ex
(empty)

$ grep -E "nspname = '#" lib/mix/tasks/threadline.health.coverage.ex lib/mix/tasks/threadline.verify_coverage.ex
(empty)
```

Both Mix task source files use the parameterized `[schema]` bind list — never string interpolation. Schema input crosses the trust boundary `argv → OptionParser`, is regex-screened before hitting `Ecto.Adapters.SQL.query!/3`, and is never atomized (Pitfall 3 / T-66-08).

### (e) `mix verify.compile_no_optional` stays green

```bash
$ mix verify.compile_no_optional
Compiling 48 files (.ex)
Generated threadline app
```

Both Mix tasks are pure stdlib + Ecto + Jason; capture-only adopters with no Phoenix deps can use them.

## Deviations from Plan

### Auto-fixed Issues

None — plan executed cleanly with no Rule 1 / 2 / 3 fixes triggered.

### TDD-driven authoring overlap (informational, not a deviation)

Task 1 has `tdd="true"`. The RED phase required a failing test against `Mix.Tasks.Threadline.Health.Coverage.run/1`. The minimal-failing test the executor wrote landed in `test/threadline/operator_surface/coverage_mix_test.exs` — the same file Task 3 specifies as its deliverable. Rather than write a stub test in a throwaway file for RED and then re-author the same content under Task 3, the RED test was authored to the full Task 3 spec (12 cases) up front. After Tasks 1 and 2 GREENed, all 12 cases pass; Task 3's acceptance criteria were verified against the already-committed file (file existence, `async: false`, both `Mix.Task.reenable/1` calls, ≥5 cases, both Mix-task module references, footer literal, sorted-keys assertion, `Mix.Error` count ≥3, `mix verify.format` clean) — ALL PASS.

Net effect: Task 3's deliverable is committed in `b4e4a1f` (Task 1 RED commit) rather than a separate Task 3 commit. The audit trail on the file is `b4e4a1f` for the test file. This is functionally equivalent to a separate Task 3 commit — the file content matches the plan's Task 3 specification verbatim, all acceptance criteria pass, and 12/12 tests pass against the committed Task 1 + Task 2 code.

## Tasks → Commits

| Task | Description | Commit |
| ---- | ----------- | ------ |
| 1 (RED) | Failing integration test for mix threadline.health.coverage parity (full 12-case test file) | `b4e4a1f` |
| 1 (GREEN) | `Mix.Tasks.Threadline.Health.Coverage` module with --json + --schema=NAME | `314d0d5` |
| 2 | Additive `--schema=NAME` flag on `mix threadline.verify_coverage` | `f438d13` |
| 3 | Test file already committed in `b4e4a1f` (RED); Task 3 acceptance criteria verified against existing file | (`b4e4a1f`) |

## Plan-Level Verification Results

| Check | Status |
| ----- | ------ |
| `mix test test/threadline/operator_surface/coverage_mix_test.exs --trace` | 12 tests / 0 failures |
| `mix test test/threadline/verify_coverage_task_test.exs` | 3 tests / 0 failures (existing CI-gate test, unchanged) |
| `mix help threadline.health.coverage` | prints `## Usage` block with three literal invocations |
| `mix verify.compile_no_optional` | clean (both Mix tasks pure stdlib + Ecto + Jason) |
| `mix verify.format` | clean |
| Atom-safety refute (`grep -E "String\.to_atom\b" lib/mix/tasks/threadline.health.coverage.ex lib/mix/tasks/threadline.verify_coverage.ex`) | empty |
| SQL-injection refute (`grep -E "nspname = '#" ...`) | empty |
| Full `mix test` (regression check) | 445 tests / 0 failures (1 excluded — `pgbouncer_topology`) |

## TDD Gate Compliance

Task 1 (`tdd="true"`) observed RED → GREEN order. RED commit `b4e4a1f` (test only) failed with 10 `UndefinedFunctionError` for `Mix.Tasks.Threadline.Health.Coverage.run/1` plus 1 expected-vs-actual error for the not-yet-extended `verify_coverage`; GREEN commit `314d0d5` shipped the new module and brought 9/12 cases green; Task 2 commit `f438d13` shipped the `verify_coverage` flag and brought all 12/12 cases green. Tasks 2 and 3 are not marked `tdd="true"` in the plan; commits follow the standard feat/test conventions.

## Self-Check: PASSED

**Files created:**
- FOUND: lib/mix/tasks/threadline.health.coverage.ex
- FOUND: test/threadline/operator_surface/coverage_mix_test.exs

**Files modified:**
- FOUND modifications in lib/mix/tasks/threadline.verify_coverage.ex (HEAD vs base: `def run(argv)` + OptionParser + `validate_schema!/2` helper + `## Schema scope (Phase 66)` moduledoc section + Health call w/ `:schema`)

**Commits:**
- FOUND: b4e4a1f (test 66-02 RED — Task 1 RED + Task 3 deliverable)
- FOUND: 314d0d5 (feat 66-02 — Task 1 GREEN)
- FOUND: f438d13 (feat 66-02 — Task 2)
