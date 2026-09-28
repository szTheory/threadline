---
phase: 212-detection-and-adopter-twins
plan: 03
subsystem: database
tags: [postgres, ecto, mix-tasks, health-checks, ci-gate]

requires:
  - phase: 212-detection-and-adopter-twins
    provides: "212-01/212-02: Threadline.Health.trigger_findings/1 returning all five finding codes (Finding struct, TriggerFindings)"
provides:
  - "Threadline.Verify.CoveragePolicy.partition_findings/2 -> %{gated:, not_gated:, warnings:}"
  - "mix threadline.verify_coverage findings gate: fails on a gated :error finding, prints NOT GATED for unlisted-table errors, always prints warnings"
  - "mix threadline.health.coverage FINDINGS text section and additive --json findings key"
  - "malformed :trigger_capture config raises Mix.Error in both tasks before any findings check (D-07)"
affects: [212-04, 213-upgrade-guide]

actuals:
  tokens: 7956
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Positive-list gate extension: CoveragePolicy.partition_findings/2 sits alongside the untouched violations/2 and summary_counts/2, keeping the CI gate's existing intersection semantics unchanged while adding a severity/membership split for findings"
    - "load_capture_config!/0 duplicated per-task (mirroring the existing resolve_repo!/0 duplication pattern from gen.triggers) rather than shared, keeping each Mix task self-contained"

key-files:
  created: []
  modified:
    - lib/threadline/verify/coverage_policy.ex
    - lib/mix/tasks/threadline.verify_coverage.ex
    - lib/mix/tasks/threadline.health.coverage.ex
    - config/test.exs
    - test/threadline/verify_coverage_policy_test.exs
    - test/threadline/verify_coverage_task_test.exs
    - test/threadline/operator_surface/coverage_mix_test.exs
    - test/threadline/operator_surface/coverage_doc_contract_test.exs

key-decisions:
  - "HLTH-06 is intentionally left unchecked in REQUIREMENTS.md: 212-04's own frontmatter lists requirements: [HLTH-01, HLTH-06] and completes HLTH-06's CHANGELOG/guides/doc-contract obligations. This plan delivers the gate and viewer behavior; 212-04 closes the requirement."
  - "print_findings/1 in verify_coverage.ex and the FINDINGS section in health.coverage.ex duplicate similar row-formatting logic rather than sharing a helper module, matching the two tasks' existing independence (each already duplicates resolve_repo!/0, ensure_repo_started!/1, validate_schema!/2)"
  - "The moduledoc's NOT GATED prose was reworded to avoid a second literal match of the heading string, keeping the acceptance-criteria grep (count = 1) meaningful as a check against the actual printed heading rather than the doc mentioning it too"

requirements-completed: []

coverage:
  - id: D1
    description: "CoveragePolicy.partition_findings/2 splits findings into gated/not_gated/warnings by :expected_tables membership and severity, pure, order-preserving, leaving violations/2 and summary_counts/2 untouched"
    requirement: HLTH-06
    verification:
      - kind: unit
        ref: "test/threadline/verify_coverage_policy_test.exs#partition_findings/2"
        status: pass
    human_judgment: false
  - id: D2
    description: "mix threadline.verify_coverage exits {:shutdown, 1} on a gated :error finding, prints NOT GATED for an unlisted-table error without failing, prints warnings without failing, and findings: none when clean — proven both in-process and via an OS-level System.cmd exit status with a clean negative control"
    requirement: HLTH-06
    verification:
      - kind: unit
        ref: "test/threadline/verify_coverage_task_test.exs#findings gate"
        status: pass
      - kind: integration
        ref: "test/threadline/verify_coverage_task_test.exs#findings gate — OS-level exit status (D-17)"
        status: pass
    human_judgment: false
  - id: D3
    description: "mix threadline.health.coverage shows a FINDINGS text section (SEVERITY/CODE/TABLE/MESSAGE) after the existing coverage table and an additive --json findings key (code, severity, schema, table, message, details), always exits 0, and every existing JSON key keeps its shape"
    requirement: HLTH-06
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/coverage_mix_test.exs#health.coverage findings (HLTH-06/D-18)"
        status: pass
      - kind: unit
        ref: "test/threadline/operator_surface/coverage_doc_contract_test.exs#--json emits exactly the locked top-level keys (sorted) plus the additive findings key"
        status: pass
    human_judgment: false
  - id: D4
    description: "A malformed :trigger_capture config stops both mix threadline.verify_coverage and mix threadline.health.coverage with Mix.Error naming the config, never a stack trace or a finding"
    requirement: HLTH-06
    verification:
      - kind: unit
        ref: "test/threadline/verify_coverage_task_test.exs#malformed :trigger_capture config (D-07)"
        status: pass
    human_judgment: false

duration: ~1h
completed: 2026-09-26
status: complete
---

# Phase 212 Plan 3: Findings Wired into verify_coverage and health.coverage Summary

**`mix threadline.verify_coverage` now fails CI on any error finding for a listed table (while only printing warnings and unlisted-table errors), and `mix threadline.health.coverage` shows the same findings in a new text section and an additive `--json` key, with malformed `:trigger_capture` config now raising `Mix.Error` in both tasks instead of a stack trace.**

## Performance

- **Duration:** ~1h
- **Tasks:** 3
- **Files modified:** 8
- **Commits:** 4 (3 task commits + 1 same-day doc-contract fix)

## Accomplishments
- `Threadline.Verify.CoveragePolicy.partition_findings/2`: a pure, order-preserving split of `Threadline.Health.trigger_findings/1` output into `gated` (errors on expected tables), `not_gated` (errors on unlisted tables) and `warnings`, added alongside the untouched `violations/2` and `summary_counts/2`
- `mix threadline.verify_coverage` calls `trigger_findings/1` after its existing coverage check, prints a `FINDINGS` section, fails with `exit({:shutdown, 1})` on any gated error (in addition to the existing missing/uncovered violations), prints unlisted-table errors under a not-gated heading without failing, and prints warnings without failing — proven both in-process (`ExUnit.CaptureIO` + `catch_exit`) and at the OS level via a dedicated `THREADLINE_VERIFY_COVERAGE_FINDINGS_TEST` `config/test.exs` switch driving a real `System.cmd("mix", ...)` subprocess, with a clean negative control (trigger re-enabled → exit 0)
- `mix threadline.health.coverage` gains a `FINDINGS` text section (`SEVERITY`/`CODE`/`TABLE`/`MESSAGE`) after its existing coverage table, and `--json` gains an additive `findings` key whose entries expose `code`, `severity`, `schema`, `table`, `message`, `details` — every existing JSON key and its shape is unchanged, and the task still always exits 0
- Both tasks now call a `load_capture_config!/0` wrapper that surfaces a malformed `config :threadline, :trigger_capture` as `Mix.raise("config :threadline, :trigger_capture " <> Exception.message(e))`, the same pattern `mix threadline.gen.triggers` already uses, before any findings check runs
- Updated `test/threadline/operator_surface/coverage_doc_contract_test.exs`'s locked top-level JSON key assertion (caught by the plan's own full `mix test` run, not any task's scoped `<verify>`) to include the additive `findings` key

## Task Commits

1. **Task 1: Tracer — partition_findings/2 and the verify_coverage findings gate, proven on a disabled trigger in an expected table** - `65b22c1e` (feat)
2. **Task 2: Expand — health.coverage FINDINGS text section and additive JSON findings key** - `02694ff5` (feat)
3. **Task 3: Expand — OS-level exit status for a findings failure and config-error surfacing in both tasks** - `a1be4bf3` (test)

Post-task fix (caught by the plan's own full `mix test` run, not any task's scoped `<verify>`): `9b7f47a2` (fix) — a doc-contract test outside this plan's `files_modified` pinned `mix threadline.health.coverage --json`'s exact top-level key list; updated to expect the additive `findings` key, same failure class as 212-01/212-02's own deviations (a repo-wide contract test tripped by a change outside the touching task's own scoped verify).

**Plan metadata:** committed alongside this SUMMARY (STATE.md/ROADMAP.md/REQUIREMENTS.md updates; no separate `.planning/` commit per `commit_docs` config).

_Note: Task 2 and Task 3 were TDD tasks; each task's own commit includes its tests._

## Files Created/Modified
- `lib/threadline/verify/coverage_policy.ex` - `partition_findings/2`, moduledoc findings section
- `lib/mix/tasks/threadline.verify_coverage.ex` - findings gate wiring, `print_findings/1`/`print_finding_rows/1`, `load_capture_config!/0`
- `lib/mix/tasks/threadline.health.coverage.ex` - `render_table/3`/`render_json/3` gain a `findings` parameter, `finding_json/1`, `load_capture_config!/0`
- `config/test.exs` - `THREADLINE_VERIFY_COVERAGE_FINDINGS_TEST` switch (single-branch `if`/`else` promoted to a `cond`)
- `test/threadline/verify_coverage_policy_test.exs` - `partition_findings/2` pure-policy cases
- `test/threadline/verify_coverage_task_test.exs` - "findings gate" describe (in-process), "findings gate — OS-level exit status" describe (System.cmd), "malformed :trigger_capture config" describe
- `test/threadline/operator_surface/coverage_mix_test.exs` - "health.coverage findings" describe, updated locked-keys test
- `test/threadline/operator_surface/coverage_doc_contract_test.exs` - updated locked top-level JSON key assertion

## Decisions Made
- HLTH-06 is left unchecked in REQUIREMENTS.md (see key-decisions) because 212-04 also lists it in `requirements:` and closes its CHANGELOG/guides/doc-contract obligations; this plan proves the gate and viewer behavior only.
- Findings row-formatting is duplicated between the two Mix tasks rather than factored into a shared helper, consistent with their existing independence (each already duplicates `resolve_repo!/0`, `ensure_repo_started!/1`, `validate_schema!/2`).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated a doc-contract test outside this plan's `files_modified` pinning the exact top-level JSON key list**
- **Found during:** the plan's own top-level `mix test` run, after all three tasks — same failure class as 212-01's and 212-02's own deviations (a task's own scoped `<verify>` only ran the files it had just touched; a repo-wide doc-contract test elsewhere pinned the old key list)
- **Issue:** `test/threadline/operator_surface/coverage_doc_contract_test.exs` asserted `mix threadline.health.coverage --json`'s top-level keys were exactly `["covered", "expected_uncovered", "schema", "uncovered"]`, which the additive `findings` key correctly breaks
- **Fix:** updated the assertion and test name to expect `["covered", "expected_uncovered", "findings", "schema", "uncovered"]`
- **Files modified:** `test/threadline/operator_surface/coverage_doc_contract_test.exs`
- **Verification:** `mix test test/threadline/operator_surface/coverage_doc_contract_test.exs` and the full `mix test` re-run (2184 tests, 0 failures)
- **Committed in:** `9b7f47a2`

---

**Total deviations:** 1 auto-fixed (1 bug — a doc-contract test outside the plan's own file list, same class as 212-01/212-02)
**Impact on plan:** No scope creep; caught by the plan's own required top-level verification before handoff.

## Issues Encountered
- The `NOT GATED (table not in :expected_tables)` acceptance-criteria grep (expected count 1) initially matched twice, once in the printed heading and once in the moduledoc's prose describing it. Reworded the moduledoc prose to avoid the second literal match without losing the documentation.
- The initial "findings gate" test fixture pre-created a legacy no-arg trigger on `legacy_t` in `setup`, which produced a spurious `legacy_trigger_no_pk_args` warning in every test in that describe block (including the "no findings" test), because `trigger_findings/1` returns findings for every Threadline trigger in the filtered schema regardless of `:expected_tables`. Fixed by moving the legacy trigger's creation into only the test that exercises it.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `mix threadline.verify_coverage` and `mix threadline.health.coverage` both fully consume `Threadline.Health.trigger_findings/1`'s five finding codes; the gate and viewer contracts from ROADMAP SC3 are proven.
- 212-04 (PgBouncer topology lane for findings, CHANGELOG Added, guides, doc contract) can build directly on this plan's stable task output; it owns closing HLTH-06 in REQUIREMENTS.md.
- No blockers for Wave 4.

---
*Phase: 212-detection-and-adopter-twins*
*Completed: 2026-09-26*

## Self-Check: PASSED

All modified files found on disk; all four commits (`65b22c1e`, `02694ff5`, `a1be4bf3`, `9b7f47a2`) found in `git log --oneline --all`.
</content>
