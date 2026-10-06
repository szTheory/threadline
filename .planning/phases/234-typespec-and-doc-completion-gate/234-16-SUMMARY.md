---
phase: 234-typespec-and-doc-completion-gate
plan: 16
subsystem: api
tags: [elixir, typespecs, ex_doc, actor-ref, evidence, retention]
requires:
  - phase: 234-typespec-and-doc-completion-gate
    provides: D-56 approval, the frozen spec/doc rubric, and existing compatibility behavior
provides:
  - Accurate ActorRef, Subject, and retention map contracts with compatibility tests
  - Audit.transaction/3 opening return envelope and conditional audit ID documentation
affects: [SPEC-02, phase-234-api-docs]
actuals:
  tokens: 3346
  tasks: 3
  commits: 3
plan_head_before: f6944d4987d58e8c3ea165c9609821701cc6f8f3
plan_head_after: 13a9b8155dff36b8232b12884d53be693b9275fd
tech-stack:
  added: []
  patterns:
    - Compatibility tests preserve mixed atom/string key behavior and each API's precedence rules.
key-files:
  created:
    - .planning/phases/234-typespec-and-doc-completion-gate/234-16-SUMMARY.md
  modified:
    - lib/threadline/semantics/actor_ref.ex
    - test/threadline/semantics/actor_ref_test.exs
    - lib/threadline/evidence/subject.ex
    - test/threadline/evidence/subject_test.exs
    - lib/threadline/retention/policy.ex
    - test/threadline/retention/policy_test.exs
    - lib/threadline/audit.ex
key-decisions:
  - "Kept runtime acceptance unchanged and limited D-56 to the three approved string-key map arms."
  - "Documented the distinct ActorRef, Subject, boolean-option, and retention-window precedence rules."
  - "Left SPEC-02 pending until Plan 13's fresh review passes and Plan 15 closes its gate."
patterns-established:
  - "Public map typedocs name recognized keys, ignored extras, value domains, and mixed-key precedence."
requirements-completed: []
coverage:
  - id: D1
    description: ActorRef map output and decoding contracts match existing behavior for extras and mixed keys.
    requirement: SPEC-02
    verification:
      - kind: unit
        ref: mix test test/threadline/semantics/actor_ref_test.exs test/threadline/doc_spec_coverage_contract_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Subject descriptors pin recognized-key order, recursive normalization, ignored extras, and unknown-only errors.
    requirement: SPEC-02
    verification:
      - kind: unit
        ref: mix test test/threadline/evidence/subject_test.exs test/threadline/doc_spec_coverage_contract_test.exs
        status: pass
    human_judgment: false
  - id: D3
    description: Retention key precedence and Audit.transaction/3 return documentation match the current implementation.
    requirement: SPEC-02
    verification:
      - kind: unit
        ref: mix test test/threadline/retention/policy_test.exs test/threadline/audit_doc_contract_test.exs test/threadline/doc_spec_coverage_contract_test.exs
        status: pass
      - kind: other
        ref: MIX_ENV=dev mix docs --warnings-as-errors
        status: pass
      - kind: other
        ref: mix verify.dialyzer
        status: pass
    human_judgment: false
duration: 10min
completed: 2026-10-06
status: complete
---

# Phase 234 Plan 16: Public Map and Transaction Return Contracts Summary

**ActorRef, Subject, and retention map docs now match their existing mixed-key behavior, and `Audit.transaction/3` states its actual tuple envelope.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-10-06T01:02:11Z
- **Completed:** 2026-10-06T01:12:24Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Documented ActorRef's exact emitted string-key set, its direct-struct nil ID case, and decoder handling of extra and atom keys; added executable compatibility tests.
- Documented Subject's recognized keys, value domains, recursive normalization, unknown-key behavior, and clause precedence; tests cover mixed descriptors and unchanged unknown-only errors.
- Documented retention key domains, boolean atom-key precedence, window fallback rules, and preserved errors; corrected the transaction opening to state its tuple envelope and possible merged or wrapped audit transaction ID.
- Preserved the public API, runtime behavior, D-55 visible coverage floor, hidden-function pin, and strict Dialyzer configuration.

## Task Commits

Each task was committed atomically:

1. **Task 1: Pin the ActorRef string-map contract from encoding through decoding** — `35aa62e4` (fix)
2. **Task 2: Pin Subject descriptor key precedence and ignored extras** — `c0aa5968` (fix)
3. **Task 3: Pin retention map precedence and correct transaction return summary** — `13a9b815` (fix)

## Files Created/Modified

- `lib/threadline/semantics/actor_ref.ex` and `test/threadline/semantics/actor_ref_test.exs` — ActorRef map types, docs, and compatibility coverage.
- `lib/threadline/evidence/subject.ex` and `test/threadline/evidence/subject_test.exs` — Subject descriptor contract and precedence coverage.
- `lib/threadline/retention/policy.ex` and `test/threadline/retention/policy_test.exs` — retention config contract and fallback coverage.
- `lib/threadline/audit.ex` — `Audit.transaction/3` opening return summary.

## Decisions Made

- Preserved existing runtime acceptance, including extra keys and supported mixed atom/string maps; D-56 remains limited to the three approved string-key arms.
- Kept SPEC-02 pending. Plan 13 still needs a fresh independent PASS, and Plan 15 still needs to close its gate.

## Deviations from Plan

None — plan scope and runtime behavior were preserved.

## Verification

- Task 1 focused suite: 26 tests, 0 failures.
- Task 2 focused suite: 13 tests, 0 failures.
- Task 3 focused suite: 18 tests, 0 failures.
- Plan-level focused contract suite: 57 tests, 0 failures.
- `MIX_ENV=dev mix docs --warnings-as-errors`: passed.
- `mix verify.dialyzer`: passed, 0 errors.
- Stub scan found no placeholder implementation patterns in the seven changed source and test files.
- Threat surface scan found no new network, auth, file-access, or schema boundary.

## Issues Encountered

- The sandbox initially denied writes to Git metadata. After confirming the repository root and branch, the authorized normal commits completed with hooks enabled; no `--no-verify` option was used.

## User Setup Required

None — no external service configuration required.

## Next Plan Readiness

- Plan 234-16 is complete. Plan 13 can generate fresh review input from these corrected contracts; SPEC-02 remains pending until the independent review and Plan 15 gate pass.

---
*Phase: 234-typespec-and-doc-completion-gate*
*Completed: 2026-10-06*

## Self-Check: PASSED

- Summary file exists at the requested phase path.
- Task commits `35aa62e4`, `c0aa5968`, and `13a9b815` exist in Git history.
- All seven implementation files are committed.
- Stub and threat-surface scans found no entries to track.
