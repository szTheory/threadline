---
phase: 235-stability-contract-and-adopter-guides
plan: 01
subsystem: database
tags: [postgresql, redaction, migration, exdoc, contract-tests]
requires:
  - phase: 234-typespec-and-doc-completion-gate
    provides: Current public-contract and documentation baselines
provides:
  - Generated migration-time validation for configured mask and exclude columns
  - PostgreSQL rollback and valid-redaction coverage for detected and override keys
  - Evidence-linked redaction guide with rollout timing and residual plaintext surfaces
affects: [phase-235-adopter-guides, phase-236-partition-weights]
tech-stack:
  added: []
  patterns: [Catalog-backed configured-column checks in generated host migrations, Evidence-linked and scope-qualified guide contracts]
key-files:
  created:
    - guides/redaction.md
    - test/threadline/guides/redaction_contract_test.exs
  modified:
    - lib/threadline/capture/primary_key_sql.ex
    - lib/mix/tasks/threadline.gen.triggers.ex
    - test/threadline/capture/trigger_migrate_time_errors_test.exs
    - test/threadline/guide_graph_contract_test.exs
    - mix.exs
    - guides/getting-started-saas.md
decisions:
  - Keep mask and exclude catalog checks separate so migration errors identify the exact option.
  - Scope redaction guarantees to generated per-table capture and document global/direct-trigger gaps separately.
metrics:
  duration: 13m
  completed: 2026-10-06
status: complete
actuals:
  tokens: 5122
  tasks: 2
  commits: 3
plan_head_before: 383edb75354b72850301624d57a44424df7657f5
plan_head_after: 7638817a658183272a28787734a30e4be71b2e9d
coverage:
  - id: D1
    description: Generated trigger migrations reject absent mask/exclude columns with rollback and preserve valid redaction behavior.
    requirement: DOCS-02
    verification:
      - kind: integration
        ref: test/threadline/capture/trigger_migrate_time_errors_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Redaction guide ties claims to tests, names rollout timing and residual plaintext locations, and rejects unscoped absolute claims.
    requirement: DOCS-02
    verification:
      - kind: unit
        ref: test/threadline/guides/redaction_contract_test.exs
        status: pass
      - kind: unit
        ref: test/threadline/guide_graph_contract_test.exs
        status: pass
      - kind: other
        ref: MIX_ENV=dev mix docs --warnings-as-errors
        status: pass
    human_judgment: false
requirements-completed: [DOCS-02]
---

# Phase 235 Plan 01: Generated Redaction Guard and Threat Guide Summary

**Generated host migrations now reject absent redaction columns before trigger installation, with PostgreSQL rollback proof and an evidence-linked redaction threat guide.**

## Performance

- **Duration:** 13m
- **Started:** 2026-10-07T00:25:41Z (plan execution state timestamp)
- **Completed:** 2026-10-07T00:38:52Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added catalog-backed validation for each configured `mask:` and `exclude:` column in both generated migration branches. Error text identifies the option, column, and qualified table; failed migrations roll back the trigger, per-table function, and schema migration row.
- Proved invalid mask and exclude settings on detected primary keys and `primary_key:` overrides, and proved valid mask/exclude controls still install and redact captured rows.
- Published `guides/redaction.md` with test-linked claims, the host migration rollout boundary, the `changed_fields` side channel, residual plaintext locations, and explicit global/direct-trigger proof gaps.
- Added a qualifier-aware absolute-claim contract with a document-claim mutation control and registered the guide in ExDoc and the Adopt guide graph.

## Verification

- `mix verify.test test/threadline/capture/trigger_migrate_time_errors_test.exs test/threadline/guides/redaction_contract_test.exs test/threadline/guide_graph_contract_test.exs` — passed, 41 tests / 0 failures.
- `mix verify.format` — passed.
- `MIX_ENV=dev mix docs --warnings-as-errors` — passed.

## TDD Cycle

- RED: the new PostgreSQL regression failed because the generated migration accepted `mask: ["missing_name"]`; commit `57dc67f2` records the failing test.
- GREEN: the catalog guard and initial guide slice passed the focused migration and guide-graph checks; commit `5cb3b592` records the tracer slice.
- Expansion: option-specific refusal, valid controls, and guide claim contracts passed in commit `7638817a`.

## Task Commits

1. **Task 1 RED:** `57dc67f2` — `test(235-01): add failing redaction column regression`
2. **Task 1 tracer implementation:** `5cb3b592` — `feat(235-01): reject absent redaction columns in generated migrations`
3. **Task 2:** `7638817a` — `feat(235-01): complete redaction path proof and guide boundaries`

## Files Created/Modified

- `lib/threadline/capture/primary_key_sql.ex` — migration-time catalog validation for configured redaction columns.
- `lib/mix/tasks/threadline.gen.triggers.ex` — passes `mask` and `exclude` separately to migration SQL for actionable errors.
- `test/threadline/capture/trigger_migrate_time_errors_test.exs` — refusal, rollback, valid-control, and redaction assertions against PostgreSQL.
- `guides/redaction.md` — proof scope, rollout timing, residual plaintext locations, and bypass gaps.
- `test/threadline/guides/redaction_contract_test.exs` — evidence, boundary, residual-location, mutation, and qualifier-aware claim checks.
- `mix.exs` and `test/threadline/guide_graph_contract_test.exs` — ExDoc Adopt lane and graph registration.
- `guides/getting-started-saas.md` — Adopt landing route to the new guide.

## Decisions Made

- Keep configured `mask:` and `exclude:` names as SQL values and validate them independently against `pg_attribute`; do not interpolate them as identifiers.
- Keep the guarantee scoped to generated per-table migrations. The global redacted installer and direct `create_trigger/3` path remain separate gaps.
- State that generated migrations do not rewrite installed triggers or repair audit rows captured before rollout.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Preserve the configured option name through trigger generation**
- **Found during:** Task 1
- **Issue:** The generator passed only merged redacted column names, so `PrimaryKeySQL` could not name whether an absent column came from `mask:` or `exclude:`.
- **Fix:** Pass the two configured lists separately alongside the existing combined primary-key redaction list.
- **Files modified:** `lib/mix/tasks/threadline.gen.triggers.ex`, `lib/threadline/capture/primary_key_sql.ex`
- **Verification:** PostgreSQL tests assert `mask:` and `exclude:` errors separately on both migration branches.
- **Committed in:** `7638817a`

**2. [Rule 2 - Missing graph edge] Route the guide from the Adopt landing**
- **Found during:** Task 1
- **Issue:** The guide graph requires every non-landing Adopt guide to be linked from its lane landing.
- **Fix:** Add the redaction guide to the Getting Started next-steps list.
- **Files modified:** `guides/getting-started-saas.md`
- **Verification:** `Threadline.GuideGraphContractTest` passes with the new guide in the Adopt lane.
- **Committed in:** `7638817a`

**3. [Rule 1 - Incorrect test expectation] Reject case-mismatched configured names**
- **Found during:** Task 1
- **Issue:** An existing test expected `mask: ["Code"]` to be silently ignored for a `code` column, which conflicts with the new exact catalog membership check.
- **Fix:** Update the regression to require migration refusal and identify the configured spelling and table.
- **Files modified:** `test/threadline/capture/trigger_migrate_time_errors_test.exs`
- **Verification:** Focused PostgreSQL suite passes.
- **Committed in:** `5cb3b592`

**Total deviations:** 3 auto-fixed (2 Rule 2, 1 Rule 1)
**Impact on plan:** These additions make option errors actionable, keep the new guide reachable, and align the old case-mismatch expectation with the approved fail-fast contract.

## Issues Encountered

- The first rollback assertion reused a fixture function name left by another test. A dedicated table/function fixture and explicit cleanup made the rollback proof isolated and repeatable.
- The sandbox blocked Git metadata writes on the initial commit attempt; the authorized commits succeeded with normal hooks after escalation. No pre-existing changes were staged.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 235-01 is complete. The redaction guide and its claims are available for the remaining Phase 235 contract and adopter-guide work.

---
*Phase: 235-stability-contract-and-adopter-guides*
*Completed: 2026-10-06*

## Self-Check: PASSED

- Summary file exists at the required phase path.
- Task commits `57dc67f2`, `5cb3b592`, and `7638817a` are ancestors of HEAD.
