---
phase: 234-typespec-and-doc-completion-gate
plan: 02
subsystem: api
tags: [elixir, typespecs, ex_doc, dialyzer, phoenix]
requires:
  - phase: 233
    provides: settled transaction lookup signatures and return shapes
  - phase: 234
    provides: exact docs/spec ratchets and frozen review rubric from plan 01
provides:
  - Facade option, filter, and row identifier types with matching read allowlists
  - Typed and documented facade reads, including deprecated call shapes
  - Four ordered ExDoc job groups and facade page navigation by job
  - WR-01 repository lookup ordering fix with mutation evidence
affects: [234-03, 234-04, 234-05, 234-06, 235]
actuals:
  tokens: 28600
  tasks: 6
  commits: 7
tech-stack:
  added: []
  patterns:
    - Hidden OptionKeys module owns facade read allowlists and preserves validator messages
    - Named public keyword unions are checked against option/filter docs and runtime keys
key-files:
  created:
    - lib/threadline/query/option_keys.ex
    - test/threadline/option_allowlist_test.exs
  modified:
    - lib/threadline.ex
    - lib/threadline/query/transaction_lookup.ex
    - lib/threadline/query.ex
    - lib/threadline/investigation.ex
    - lib/threadline/operator_surface/live/actor_live.ex
    - lib/threadline/operator_surface/live/row_history_component.ex
    - lib/threadline/semantics/audit_action.ex
    - mix.exs
    - CHANGELOG.md
    - guides/integration-contracts.md
    - test/threadline/doc_spec_coverage_contract_test.exs
    - test/threadline/doc_rubric_contract_test.exs
    - test/threadline/facade_naming_contract_test.exs
    - test/threadline/source_size_contract_test.exs
    - test/threadline/transaction_lookup_test.exs
    - test/partition_weights.txt
key-decisions:
  - "Keep all adopter-facing named types on Threadline; OptionKeys remains hidden in Threadline.Query."
  - "Use the legacy page function names' actual old argument shapes in their specs while keeping them in their replacement groups."
  - "Pull AuditAction.t() forward from plan 05 because the correctly typed record_action/2 return depends on it and Dialyzer rejects an unknown type."
requirements-completed: [SPEC-01, SPEC-02, SPEC-03]
coverage:
  - id: FACADE-OPTIONS
    description: "Facade option/filter types, docs, and runtime allowlists stay in parity."
    requirement: SPEC-02
    verification:
      - kind: unit
        ref: "mix test test/threadline/option_allowlist_test.exs test/threadline/doc_rubric_contract_test.exs"
        status: pass
    human_judgment: false
  - id: LOOKUP-ORDER
    description: "A missing repository raises before a malformed transaction id is resolved."
    requirement: SPEC-02
    verification:
      - kind: unit
        ref: test/threadline/transaction_lookup_test.exs
        status: pass
    human_judgment: false
  - id: FACADE-GROUPS
    description: "The rendered facade docs expose all four groups in their specified order."
    requirement: SPEC-03
    verification:
      - kind: unit
        ref: test/threadline/facade_naming_contract_test.exs
        status: pass
      - kind: other
        ref: "MIX_ENV=dev mix docs --warnings-as-errors and generated Threadline.html anchors"
        status: pass
    human_judgment: false
  - id: DIALYZER-CONTRACT
    description: "The facade option contracts reject mistyped literal options and strict Dialyzer remains clean."
    requirement: SPEC-02
    verification:
      - kind: other
        ref: "temporary limitt: 3 facade call produced a contract warning; after removal, mix verify.dialyzer reported Total errors: 0"
        status: pass
    human_judgment: false
duration: 1h 16m
completed: 2026-10-04
status: complete
---

# Phase 234 Plan 02: Facade Types and Job Groups

**The public facade now has named read contracts, matching key allowlists, and an ExDoc page organized around the jobs adopters need to do.**

## Performance

- **Duration:** 1h 16m
- **Started:** 2026-10-04T19:29:30Z
- **Completed:** 2026-10-04T20:45:26Z
- **Tasks:** 6
- **Files modified:** 18

## Accomplishments

- Added facade option, filter, row ID, JSON, and legacy-shape types; closed public read allowlists now match their types and documentation.
- Moved actor LiveView callers off the facade, fixed lookup repository validation order, and recorded the lookup mutation control.
- Added four ordered facade groups with a `## Jobs` index, rewrote the remaining facade docs, updated the ExDoc requirement, and pinned the exact facade size at 1,336 lines.
- Confirmed the temporary `limitt: 3` literal call broke Dialyzer's facade contract, then removed it and returned Dialyzer to zero errors.

## Task Commits

1. **Task 1: Row history types and allowlist** — `bb383648`
2. **Task 2: Lookup family and WR-01** — `5c1de774` (test-first fix), `b669892c` (lookup types/docs)
3. **Task 3: Move actor LiveView callers** — `5e1a6710`
4. **Task 4: Timeline reads** — `1ab338e8`
5. **Task 5: Investigation and export reads** — `fc72f6b5`
6. **Task 6: Remaining facade contracts and groups** — `32d9b5e1`

**Plan metadata:** recorded with the following state/roadmap update commit.

## Verification

- Focused facade, docs, deprecation, and operator checks: 144 tests, 0 failures.
- `MIX_ENV=dev mix docs --warnings-as-errors`: passed.
- Generated anchors appear in order: `capture-transactions`, `querying-timelines`, `actions-context`, `operations`.
- `mix verify.format`, `mix verify.credo`, and `mix verify.dialyzer`: passed; Dialyzer reported 0 errors.
- `mix.lock` unchanged.

## Deviations from Plan

### Auto-fixed Issues

**1. Pulled the planned `AuditAction.t()` schema type forward from plan 05.**
- **Found during:** Task 6 Dialyzer verification.
- **Issue:** The correctly narrowed `record_action/2` return spec referenced a type that plan 05 had not created yet; Dialyzer also exposed the caller's supported `:storage_schema` option as missing from the named option type.
- **Fix:** Added the complete `AuditAction.t()` field type now and included `:storage_schema` in `record_action_opt`.
- **Files modified:** `lib/threadline/semantics/audit_action.ex`, `lib/threadline.ex`.
- **Verification:** Doc/spec ratchets pass and `mix verify.dialyzer` reports 0 errors.
- **Committed in:** `32d9b5e1`.

**Total deviations:** 1 auto-fixed dependency-order adjustment.
**Impact on plan:** Plan 05 can reuse the already-defined `AuditAction.t()` instead of introducing it again.

## Issues Encountered

- The first source-size check correctly failed after the remaining docs grew the facade. The pin was updated to the measured 1,336 lines and the full focused gate passed.
- The first Dialyzer run found the missing planned `AuditAction.t()` plus two caller warnings; adding the real schema type and completing the accepted option union restored a clean run.

## User Setup Required

None.

## Next Plan Readiness

Ready for `234-03-PLAN.md`; it can consume the facade's `repo_opt`, `json_map`, and `AuditAction.t()` types.

---
*Phase: 234-typespec-and-doc-completion-gate*
*Completed: 2026-10-04*
