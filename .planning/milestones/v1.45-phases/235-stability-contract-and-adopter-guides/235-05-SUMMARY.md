---
phase: 235-stability-contract-and-adopter-guides
plan: 05
subsystem: database
tags: [elixir, ecto, schema-contract, moduledoc]

requires:
  - phase: 234-typespec-and-doc-completion-gate
    provides: Precisely typed persisted schemas with additive 1.x field evolution.
  - phase: 235-01
    provides: Stability-contract decisions and phase contract-test conventions.
provides:
  - Stable 1.x field subsets documented for AuditChange, AuditTransaction, and AuditAction.
  - A focused schema and moduledoc contract that catches field removal while allowing additive schema fields.
affects: [236-support-floor-and-partition-weights]

actuals:
  tokens: 2086
  tasks: 2
  commits: 2
commits: 2
plan_head_before: 357f8cfdc46bed309123e81a7feb988ce3b65040
plan_head_after: 6f42507ca0a32fc1fd167ce97ecac5bb9f2f9054

tech-stack:
  added: []
  patterns:
    - Pin only the selected stable struct fields against Ecto schema metadata, leaving additive fields available.
    - Scope field documentation assertions to an explicit stable-field moduledoc section and exercise removal mutations.

key-files:
  created:
    - test/threadline/schema_fields_contract_test.exs
  modified:
    - lib/threadline/capture/audit_change.ex
    - lib/threadline/capture/audit_transaction.ex
    - lib/threadline/semantics/audit_action.ex

key-decisions:
  - "Applied D-02's selected 1.x schema subsets; current unlisted fields and virtual relationships are not frozen."
  - "Captured JSONB promises cover additive keys and shapes, not serialization bytes or key ordering."

patterns-established:
  - "Schema-field contract errors name the schema and exact missing field."

requirements-completed: [CONTRACT-05]
coverage:
  - id: D1
    description: "All three schemas document only their selected stable 1.x field subsets, with removal controls and additive schema fields permitted."
    requirement: CONTRACT-05
    verification:
      - kind: unit
        ref: "mix verify.test test/threadline/schema_fields_contract_test.exs test/threadline/doc_spec_coverage_contract_test.exs"
        status: pass
      - kind: unit
        ref: "mix verify.format"
        status: pass
    human_judgment: false
  - id: D2
    description: "AuditChange documents additive JSONB map keys and shapes and an additive text-name list without serialization or key-order guarantees."
    requirement: CONTRACT-05
    verification:
      - kind: unit
        ref: "test/threadline/schema_fields_contract_test.exs#AuditChange stable snapshot documentation limits the JSON and list promises"
        status: pass
      - kind: other
        ref: "MIX_ENV=dev mix docs --warnings-as-errors"
        status: pass
    human_judgment: false

duration: 4 min
completed: 2026-10-07
status: complete
---

# Phase 235 Plan 05: Stable Schema Fields Summary

**AuditChange, AuditTransaction, and AuditAction now publish deliberate stable 1.x field subsets guarded by an additive schema and documentation contract.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-10-07T00:59:49Z
- **Completed:** 2026-10-07T01:03:39Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Documented the selected stable fields for both capture schemas without freezing additional or virtual fields.
- Documented AuditChange's additive JSONB keys/shapes and changed-fields list, including the absence of byte-serialization and key-order guarantees.
- Documented AuditAction's stable fields while preserving its semantic-event distinction from AuditTransaction's database grouping.
- Added literal schema-field and moduledoc checks, plus per-schema removal mutation controls and an explicit additive-field control.

## Task Commits

1. **Task 1: Commit the capture-side stable fields and additive snapshot promise** - `fcdd2cd2` (feat)
2. **Task 2: Commit semantic AuditAction fields under the same schema gate** - `6f42507c` (feat)

## Files Created/Modified

- `lib/threadline/capture/audit_change.ex` - Selected stable fields and qualified additive snapshot promises.
- `lib/threadline/capture/audit_transaction.ex` - Selected stable fields, excluding unpromised schema and virtual fields.
- `lib/threadline/semantics/audit_action.ex` - Stable semantic action fields and layer distinction.
- `test/threadline/schema_fields_contract_test.exs` - Literal three-schema field gate, documented-section assertions, JSON-shape assertions, and mutation controls.

## Decisions Made

- Kept the public 1.x promise limited to D-02's explicit subsets; the full `t()` types may gain fields.
- Kept JSONB guarantees additive and shape-based, without byte-stable serialization or ordering promises.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

- The first focused test run exposed a line-wrap-sensitive phrase assertion in the new test. The assertion now normalizes whitespace; the focused suite passes.
- The initial phase-level gate found machine-local `.codex/gsd-core` paths in all five plan files. Phase closeout changed them to portable `$HOME`-relative paths, and `mix verify.repo_hygiene` passed.
- The first complete `mix ci.all` run was sandbox-limited: it denied Hex/npm/Playwright cache and temporary Git worktree writes. The canonical gate was rerun with those permissions and passed; one desktop browser test was flaky on its first attempt and passed on retry.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The Phase 235 implementation plans are complete. Focused contracts, formatting, warning-free documentation, and the final `mix ci.all` gate pass. The regenerated goal report passes all five must-haves and retains the five judgment-tier prohibition groups as unverified.

---
*Phase: 235-stability-contract-and-adopter-guides*
*Completed: 2026-10-07*

## Self-Check: PASSED

- Summary and schema contract test exist.
- Task commits `fcdd2cd2` and `6f42507c` are ancestors of HEAD and the plan evaluation scope resolves both commits.
- Coverage classification passed for both deliverables; focused tests, formatting, and warning-free docs build passed.
- Stub scan found no placeholder patterns in the plan's changed files.
- The repository-hygiene finding was resolved and the final canonical `mix ci.all` passed.

## Post-verification gap closure

- The goal verifier found two assertion gaps: stability coverage did not pin all additive database object kinds and the exact `0.12.x` backport window; redaction coverage did not reject unscoped `all`/`prevents` language or bind each guarantee to evidence in the same row.
- The stability contract now pins tables, columns, indexes, and the six-month interval after `0.12.0`. The redaction contract now rejects those absolute terms and checks each guarantee against its own named test or policy command.
- Credo prompted the SQL contract's nested `TriggerSQL` reference to move to the module alias list.
- The final gate exposed a flaky docs fixture: `Code.compiler_options/1` affects the whole VM, but two contract modules temporarily changed it while running asynchronously. Both modules now run synchronously; their focused suite passed (17 tests, 0 failures).
- Final `mix ci.all`: root 3,047 tests, 0 failures, 3 excluded; example 130 tests, 0 failures; Dialyzer passed; Dialyzer slice 17 tests, 0 failures, 16 excluded; browser lane 318 passed, 26 skipped. Repository hygiene reported 4,651 tracked text files clean, with 8 allowlist entries used and 0 inert.
- A read-only, non-authoritative review found no current violation among the five grouped judgment topics. These judgment-tier prohibitions remain explicitly flagged as unverified in the regenerated goal report; the review is not treated as an automated guarantee.

## Final review and verification gate

- The redaction contract now evaluates complete sentences against exact bounded claims, validates each evidence link against the repository identity and local file, and rejects the absolute-language, destination, negation, compound, and numeric guarantee forms found during adversarial review. The exact bounded guide sentences are explicitly allowlisted; the final independent code review found 0 open findings.
- Final `mix ci.all` after these changes passed: repository hygiene found 4,651 tracked text files clean (8 allowlist entries used, 0 inert); root suite 3,047 tests, 0 failures, 3 excluded; example suite 130 tests, 0 failures; Dialyzer passed; Dialyzer slice 17 tests, 0 failures, 16 excluded; browser lane 318 passed, 26 skipped.
- Final `mix verify.format`, `mix verify.credo`, and the focused redaction/stability contract suite passed. No UI implementation changed; UI review is not applicable.
