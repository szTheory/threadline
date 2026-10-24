---
phase: 229-adopter-api-and-health-additions
plan: 03
subsystem: cli
tags: [mix-task, health, trigger-coverage, ci-gate, postgres]

# Dependency graph
requires:
  - phase: 229-02
    provides: "Threadline.Health.legacy_key_findings/1 public function"
provides:
  - "mix threadline.health.coverage --strict (HLTH-01)"
  - "Threadline.Health.legacy_key_findings/1 wired into the task's findings list"
  - "@doc false Mix.Tasks.Threadline.Health.Coverage.legacy_findings_or_hint/2"
  - "unknown/invalid switch Mix.raise before the repo starts (D-16)"
affects: [229-04, 230-rebalance-net-suite-check-and-0-12-0]

# Actuals (#2632)
actuals:
  tokens: 8257
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Error-fails, warning-never-fails gate split (mirrors verify_coverage's exit({:shutdown, 1}) precedent)"
    - "Compile-time generated ExUnit tests via `for {a, b, c} <- @matrix do test ... end` for an exit/output matrix, instead of hand-copied test bodies"
    - "try/catch helper (run_catching_exit/1) to normalize a function's own :ok return and a caught exit/1 reason into one value, since ExUnit.Assertions.catch_exit/1 raises when no exit occurs"

key-files:
  created: []
  modified:
    - lib/mix/tasks/threadline.health.coverage.ex
    - lib/threadline/health.ex
    - test/threadline/operator_surface/coverage_mix_test.exs
    - test/threadline/operator_surface/coverage_doc_contract_test.exs
    - guides/domain-reference.md
    - guides/operator-surface.md
    - guides/configuration-and-commands.md
    - guides/production-checklist.md
    - CHANGELOG.md

key-decisions:
  - "legacy_findings_or_hint/2 rescues only %Postgrex.Error{postgres: %{code: :query_canceled}} (D-20 discretion already made in 229-02); any other exception reraises unchanged via reraise/2 with the original stacktrace"
  - "The 12-cell matrix is generated at compile time from a module-attribute list (@matrix) rather than 12 hand-copied test bodies, per the plan's own instruction"
  - "Exit/ok normalization via a local run_catching_exit/1 helper, since ExUnit.Assertions.catch_exit/1 raises 'Expected to catch exit, got nothing' on the non-strict and uncovered-only cells that return :ok"

requirements-completed: [HLTH-01, HLTH-03]

coverage:
  - id: D1
    description: "--strict exits via exit({:shutdown, 1}) only when an in-scope :error finding is present, and returns :ok otherwise (never on uncovered tables or warnings); prints the stderr status line via Mix.shell().error/1; never uses System.halt"
    requirement: "HLTH-01"
    verification:
      - kind: integration
        ref: "test/threadline/operator_surface/coverage_mix_test.exs#--strict (HLTH-01 tracer) a disabled trigger fails --strict end-to-end with exit 1 and the stderr status line"
        status: pass
      - kind: integration
        ref: "test/threadline/operator_surface/coverage_mix_test.exs#severity x strict x format matrix (D-09) schema=* strict=* json=* outcome=* (12 generated cells)"
        status: pass
      - kind: integration
        ref: "test/threadline/operator_surface/coverage_mix_test.exs#severity x strict x format matrix (D-09) uncovered-only schema with --strict returns :ok"
        status: pass
      - kind: integration
        ref: "test/threadline/operator_surface/coverage_mix_test.exs#severity x strict x format matrix (D-09) an :error finding in another schema does not fail --strict --schema=<clean schema>"
        status: pass
    human_judgment: false
  - id: D2
    description: "legacy_key_findings/1 is concatenated into the task's findings (trigger_findings ++ legacy_findings_or_hint), sorted by {schema, table, code, message}; a cancelled probe prints the Step 4 hint to stderr, continues with [], and never fails --strict; unknown/invalid switches raise Mix.raise naming the switch before the repo starts"
    requirement: "HLTH-03"
    verification:
      - kind: integration
        ref: "test/threadline/operator_surface/coverage_mix_test.exs#severity x strict x format matrix (D-09) the warning schema's findings include unresolved_legacy_keys and --strict passes"
        status: pass
      - kind: integration
        ref: "test/threadline/operator_surface/coverage_mix_test.exs#legacy probe timeout hint (D-20) a cancelled probe prints the row-history-index hint and continues with []"
        status: pass
      - kind: integration
        ref: "test/threadline/operator_surface/coverage_mix_test.exs#unknown switches (D-16) unknown or invalid switches raise Mix.Error naming the switch, before any DB access"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every doc (task moduledoc, Health moduledoc, domain-reference.md, operator-surface.md, configuration-and-commands.md, production-checklist.md) states the task is a viewer by default and that --strict never fails on uncovered tables; production-checklist.md carries the --strict CI snippet; CHANGELOG documents --strict and the unknown-switch fix"
    requirement: "HLTH-01"
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/coverage_doc_contract_test.exs#--strict doc rewording (229-03 D-10) S1 appears in the task moduledoc source, domain-reference.md, operator-surface.md and configuration-and-commands.md"
        status: pass
      - kind: unit
        ref: "test/threadline/operator_surface/coverage_doc_contract_test.exs#--strict doc rewording (229-03 D-10) S2 appears in the task moduledoc source, domain-reference.md, operator-surface.md and production-checklist.md"
        status: pass
      - kind: unit
        ref: "test/threadline/operator_surface/coverage_doc_contract_test.exs#--strict doc rewording (229-03 D-10) production-checklist.md carries the --strict CI snippet line"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-10-02
status: complete
---

# Phase 229 Plan 03: `mix threadline.health.coverage --strict` Summary

**`--strict` turns `:error`-severity findings into `exit({:shutdown, 1})` on `mix threadline.health.coverage` without ever gating on uncovered tables or warnings, wires `Threadline.Health.legacy_key_findings/1` into the task's findings list with a timeout-safe stderr hint, makes unknown/misspelled switches raise instead of silently passing CI, and rewords every doc to say so.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-10-02T17:09:00Z
- **Completed:** 2026-10-02T17:34:00Z
- **Tasks:** 3 completed
- **Files modified:** 9

## Accomplishments
- `--strict` on `mix threadline.health.coverage`: exits 1 via `exit({:shutdown, 1})` when any `:error`-severity finding is present in the checked schema, printing one stderr status line through `Mix.shell().error/1` (`strict: FAILED — N error finding(s) ...` or `strict: passed (W warning(s) not gated)`); never uses `System.halt`; `--json` stdout stays exactly one pure JSON document with its existing key set unchanged
- Unknown or invalid switches (`--stict`, `--jsn`, `--schema` with no value) now raise `Mix.raise` naming the offending switch, before the repo starts — closing a silent-typo gap left by `OptionParser`'s discarded invalid-switch tuple
- `Threadline.Health.legacy_key_findings/1` is concatenated into the task's findings (`trigger_findings ++ legacy_findings_or_hint`, sorted by `{schema, table, code, message}`); a cancelled probe (typically a missing row-history index) prints a one-line stderr hint pointing at the upgrade guide's Step 4 and continues with `[]` — a timeout never fails `--strict`
- The `{clean, warning-only, error} x {non-strict, --strict} x {table, --json}` 12-cell exit/output matrix is the new baseline (no prior test pinned per-severity exit codes), generated at compile time from a module-attribute list rather than 12 hand-copied tests, plus cross-schema isolation, uncovered-only-never-gated, and the legacy-warning wiring
- Every doc (task moduledoc, `Threadline.Health`'s Mix-task parity paragraph, `domain-reference.md`, `operator-surface.md`, `configuration-and-commands.md`, `production-checklist.md`) states the task is a viewer by default and that `--strict` never fails on uncovered tables, pointing to `mix threadline.verify_coverage` for the positive-list gate; `production-checklist.md` gains a `- run: mix threadline.health.coverage --strict` CI snippet next to `verify_coverage`; doc-contract tests pin both canonical sentences across all five files
- CHANGELOG Unreleased gains an `### Added` bullet for `--strict` and a `### Fixed` bullet for the unknown/misspelled-switch raise; no Breaking changes bullet (D-27)

## Task Commits

1. **Task 1: Tracer — `--strict` exits 1 on a disabled capture trigger, with the stderr status line and the updated pinned spec** - `654b0f3b` (feat)
2. **Task 2: The 12-cell matrix, cross-schema and uncovered cases, legacy-key wiring, timeout hint, unknown switches** - `58c92673` (test)
3. **Task 3: Reword the docs (viewer by default; `--strict` gates errors), CI snippet, doc contracts, CHANGELOG** - `4a6142a0` (docs)

_No TDD tasks in this plan; each task is a single atomic commit._

## Files Created/Modified
- `lib/mix/tasks/threadline.health.coverage.ex` — `--strict` gate (`apply_strict_gate/1`), invalid-switch `Mix.raise`, `@doc false legacy_findings_or_hint/2`, reworded moduledoc (S1/S2, usage lines, timeout-hint and unknown-switch prose)
- `lib/threadline/health.ex` — Mix-task parity paragraph updated with `--strict` and S1
- `test/threadline/operator_surface/coverage_mix_test.exs` — tracer test, the 12-cell generated matrix, cross-schema/uncovered-only/legacy-warning tests, unknown-switch tests, timeout-hint test, `run_catching_exit/1` helper
- `test/threadline/operator_surface/coverage_doc_contract_test.exs` — updated pinned `OptionParser` spec literal, new S1/S2/CI-snippet doc-contract assertions
- `guides/domain-reference.md`, `guides/operator-surface.md`, `guides/configuration-and-commands.md` — S1 (viewer-by-default / `--strict` exit-1)
- `guides/production-checklist.md` — S2 (uncovered tables never fail `--strict`) plus the CI snippet
- `CHANGELOG.md` — `### Added` bullet for `--strict`, `### Fixed` bullet for the unknown-switch raise

## Decisions Made
- `legacy_findings_or_hint/2` rescues only `%Postgrex.Error{postgres: %{code: :query_canceled}}` and reraises anything else unchanged (`reraise e, __STACKTRACE__`), per the D-20 discretion plan 02 already exercised (a raise, not a sentinel, out of `legacy_key_findings/1` itself).
- The matrix is generated at compile time from `@matrix for ... do: {schema_key, strict, json} end` plus a `for {...} <- @matrix do test ... end` loop, per the plan's explicit instruction to avoid 12 hand-copied test bodies.
- Added a local `run_catching_exit/1` test helper (`fun.() catch :exit, reason -> reason end`) because `ExUnit.Assertions.catch_exit/1` raises `"Expected to catch exit, got nothing"` on any cell that returns `:ok` without exiting — the matrix needed both outcomes handled uniformly.

## Deviations from Plan

None — plan executed exactly as written. The only discoveries were test-authoring mechanics (the `catch_exit/1` limitation above and an implicit-try Credo finding on the new helper, fixed before commit), not corrections to the implementation or acceptance criteria.

## Issues Encountered
- `ExUnit.Assertions.catch_exit/1` only works when the wrapped code is guaranteed to exit; several matrix cells return `:ok` normally. Fixed by writing `run_catching_exit/1` as a plain try/catch (Credo flagged the first version for using an explicit `try` where an implicit one suffices; switched to the bodyless `catch` form).
- None beyond that; `mix verify.credo`, `mix format --check-formatted`, and `mix docs` are clean, and the full targeted suite (`test/threadline/operator_surface/ test/threadline/verify_coverage_task_test.exs test/threadline/health/ test/threadline/health_findings_doc_contract_test.exs`) is 939 tests / 0 failures.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Plan 04 (`--all-schemas`, HLTH-02, plus the after-half of `evidence/SC5-wallclock.md` per D-28) can proceed: it widens the same `OptionParser` spec and raise message this plan established (`--schema`/`--strict` stay as declared; plan 04 adds `--all-schemas` and the mutual-exclusion raise per D-15). `lib/mix/tasks/threadline.verify_coverage.ex` and `test/threadline/pgbouncer_topology_test.exs` are confirmed untouched (`git diff --quiet HEAD` exits 0), preserving the catalog-only CI-gate invariant (D-18).

---
*Phase: 229-adopter-api-and-health-additions*
*Completed: 2026-10-02*

## Self-Check: PASSED

- `lib/mix/tasks/threadline.health.coverage.ex` exists
- `lib/threadline/health.ex` exists
- `test/threadline/operator_surface/coverage_mix_test.exs` exists
- `test/threadline/operator_surface/coverage_doc_contract_test.exs` exists
- `guides/domain-reference.md`, `guides/operator-surface.md`, `guides/configuration-and-commands.md`, `guides/production-checklist.md` exist
- `CHANGELOG.md` exists
- Commits `654b0f3b`, `58c92673`, `4a6142a0` all found in `git log --oneline --all`
