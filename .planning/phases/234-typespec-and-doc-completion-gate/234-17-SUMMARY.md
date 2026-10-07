---
phase: 234-typespec-and-doc-completion-gate
plan: 17
subsystem: api
tags: [elixir, typespecs, ex_doc, evidence, retention]
requires:
  - phase: 234-typespec-and-doc-completion-gate
    provides: D-56 compatibility contracts and existing Subject/Retention runtime behavior
provides:
  - Recursive Subject descriptor types that match normalize/1
  - Retention atom-key window types that match nil/false string-key fallback
affects: [SPEC-02, phase-234-api-docs]
actuals:
  tokens: 1006
  tasks: 2
  commits: 2
plan_head_before: fb14614d6b11f588d1540f20caa6afc5e68c8807
plan_head_after: d5fda8696afb796c2afcc3325eabd4ab79564211
tech-stack:
  added: []
  patterns:
    - Recursive public descriptor aliases model nested values accepted by existing normalization.
    - Atom-key option aliases include fallback sentinel values accepted by runtime resolution.
key-files:
  created:
    - .planning/phases/234-typespec-and-doc-completion-gate/234-17-SUMMARY.md
  modified:
    - lib/threadline/evidence/subject.ex
    - lib/threadline/retention/policy.ex
key-decisions:
  - "Kept runtime behavior and existing compatibility assertions unchanged while correcting the public types."
  - "Left SPEC-02 pending until Plan 13's fresh D-46 review and Plan 15's reconciliation pass."
requirements-completed: []
coverage:
  - id: D1
    description: Subject descriptor types include recursively recognized nested descriptors.
    requirement: SPEC-02
    verification:
      - kind: unit
        ref: mix test test/threadline/evidence/subject_test.exs
        status: pass
      - kind: other
        ref: mix compile --warnings-as-errors
        status: pass
    human_judgment: false
  - id: D2
    description: Retention atom-key window types include nil/false values that fall back to matching string keys.
    requirement: SPEC-02
    verification:
      - kind: unit
        ref: mix test test/threadline/retention/policy_test.exs
        status: pass
      - kind: other
        ref: mix compile --warnings-as-errors
        status: pass
    human_judgment: false
  - id: D3
    description: Strict API documentation and type gates pass while D-55's visible-entry floor and D-07 hidden pin remain intact.
    verification:
      - kind: unit
        ref: mix test test/threadline/doc_spec_coverage_contract_test.exs test/threadline/public_surface_contract_test.exs
        status: pass
      - kind: other
        ref: mix verify.dialyzer
        status: pass
      - kind: other
        ref: MIX_ENV=dev mix docs --warnings-as-errors
        status: pass
    human_judgment: false
duration: 37min
completed: 2026-10-06
status: complete
---

# Phase 234 Plan 17: Subject and Retention Type Alignment Summary

**Subject and Retention public types now describe their existing recursive normalization and nil/false fallback behavior.**

## Performance

- **Duration:** 37 min
- **Started:** 2026-10-06T08:51:12Z
- **Completed:** 2026-10-06T09:27:57Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added recursive descriptor values to the recognized atom-key and string-key Subject map arms; typedoc now explains nested normalization and key precedence.
- Added `nil | false` to Retention's atom-key `keep_days` and `max_age_seconds` types; typedoc states matching string-key fallback and existing truthy invalid-value errors.
- Left runtime normalization/resolution clauses and compatibility tests unchanged. D-55's >=82 visible-entry floor and D-07 hidden-function pin remain intact.

## Task Commits

1. **Task 1: Type the nested Subject descriptors already accepted by normalize/1** — `a7743b17` (fix)
2. **Task 2: Type Retention nil/false window fallbacks already accepted by resolve!/1** — `d5fda869` (fix)

## Files Created/Modified

- `lib/threadline/evidence/subject.ex` — recursive descriptor type and matching typedoc.
- `lib/threadline/retention/policy.ex` — atom-key fallback value types and matching typedoc.

## Decisions Made

- Preserved runtime behavior and the current focused compatibility assertions; this plan changes only type declarations and typedocs.
- SPEC-02 remains pending for Plan 13's fresh independent D-46 review and Plan 15's reconciliation gate.

## Deviations from Plan

None — plan executed as written.

## Issues Encountered

The roadmap progress command could not parse the repository's bespoke Phase 234 section. The Plan 17 checkbox and execution note were updated directly, and the next-plan cursor was hand-checked as Plan 13.

## Verification

- `mix test test/threadline/evidence/subject_test.exs` — 8 tests, 0 failures.
- `mix test test/threadline/retention/policy_test.exs` — 11 tests, 0 failures.
- `mix compile --warnings-as-errors` — passed after each task.
- `mix test test/threadline/doc_spec_coverage_contract_test.exs test/threadline/public_surface_contract_test.exs` — 52 tests, 0 failures; the D-55 >=82 floor and unchanged D-07 hidden pin pass.
- `mix verify.dialyzer` — passed, 0 errors.
- `MIX_ENV=dev mix docs --warnings-as-errors` — passed.
- No stubs or new security-relevant surfaces were introduced.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Plan 17 is complete. Plan 13 can regenerate its review input and obtain a fresh independent D-46 verdict; Plan 15 remains gated on a validated PASS. SPEC-02 and security sign-off remain pending.

---
*Phase: 234-typespec-and-doc-completion-gate*
*Completed: 2026-10-06*

## Self-Check: PASSED

- Summary file and both task commits exist.
- The two implementation files are committed.
- Focused tests, strict compile, D-55/D-07 contract tests, Dialyzer, and strict docs generation passed.
