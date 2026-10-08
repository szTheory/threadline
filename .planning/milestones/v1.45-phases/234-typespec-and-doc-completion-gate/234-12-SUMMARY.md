---
phase: typespec-and-doc-completion-gate
plan: 12
subsystem: testing
tags: [elixir, mix-task, dialyzer, typespec]
requires: []
provides:
  - "D-28 raise-only task_error!/3 helpers remain private with truthful no_return() specs"
  - "The four critic.measure failure paths retain exact caller-visible messages"
affects: [phase-234-review, phase-234-security]
actuals:
  tokens: 1529
  tasks: 1
  commits: 1
tech-stack:
  added: []
  patterns:
    - "Keep raise-only helpers private and preserve their exact Mix.Error envelope at the task boundary"
key-files:
  created:
    - .planning/phases/234-typespec-and-doc-completion-gate/234-12-SUMMARY.md
  modified:
    - lib/threadline/critic_trust/repository_boundary.ex
    - lib/mix/tasks/critic.measure.ex
    - test/threadline/operator_surface/critic_trust_test.exs
key-decisions:
  - "Keep truthful no_return() specs on private helpers; do not suppress Dialyzer or widen public types"
  - "Preserve D-55's approved 82-entry floor; its message correction is already committed separately"
patterns-established:
  - "A local Mix task helper owns caller-facing error formatting when the hidden repository boundary helper is private"
requirements-completed: [SPEC-02]
coverage:
  - id: D1
    description: "Both raise-only helpers are private, and all four critic.measure failure paths preserve their full error messages."
    requirement: SPEC-02
    verification:
      - kind: integration
        ref: "mix test test/threadline/critic_trust/measure_test.exs test/threadline/operator_surface/critic_trust_test.exs (42 tests)"
        status: pass
      - kind: other
        ref: "mix run -e D-28 compiled helper-privacy and exported-bang-spec probe"
        status: pass
      - kind: other
        ref: "mix verify.dialyzer"
        status: pass
      - kind: other
        ref: "MIX_ENV=dev mix docs --warnings-as-errors"
        status: pass
    human_judgment: false
duration: 11min
completed: 2026-10-05
status: complete
---

# Phase 234 Plan 12 Summary

**D-28 raise-only helpers are private, with all four `critic.measure` failure messages preserved and verified.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-10-05T23:43:34Z
- **Completed:** 2026-10-05T23:54:13Z
- **Tasks:** 1
- **Files modified:** 3

## Accomplishments

- Made `RepositoryBoundary.task_error!/3` private while keeping its truthful `no_return()` spec.
- Added a private `Mix.Tasks.Critic.Measure.task_error!/3` and routed its four local failure paths through it.
- Added an integration test asserting the full error messages for invalid arguments, unknown source, ledger splice failure, and invalid rubric.
- Verified that neither helper is exported and no exported bang spec in either module carries `no_return()`.

## Task Commits

1. **Task 1: Make the raise-only error helpers private** — `daac60bc` (`fix(critic-trust): keep task errors private`)

## Files Created/Modified

- `lib/threadline/critic_trust/repository_boundary.ex` — keeps the raising helper private.
- `lib/mix/tasks/critic.measure.ex` — defines the private task-level helper and routes all four task errors through it.
- `test/threadline/operator_surface/critic_trust_test.exs` — covers the four exact caller-visible messages.

## Decisions Made

- Kept the truthful `no_return()` typespec private rather than suppressing Dialyzer or weakening the type contract.
- Left the D-55 coverage assertion and hidden-helper pins unchanged; the approved floor is 82.

## Deviations from Plan

### Auto-fixed Issues

**1. Verification probe accounted for private specs retained in BEAM metadata**

- **Found during:** Task 1 compiled metadata probe
- **Issue:** `Code.Typespec.fetch_specs/1` includes private helper specs, so scanning every typespec incorrectly classified the private `no_return()` spec as public.
- **Fix:** Updated the Plan 12 and Plan 15 probes to filter on `function_exported?/3` before checking public bang specs.
- **Files modified:** `.planning/phases/234-typespec-and-doc-completion-gate/234-12-PLAN.md`, `.planning/phases/234-typespec-and-doc-completion-gate/234-15-PLAN.md`
- **Verification:** Independent plan check passed; the corrected compiled probe exited successfully.
- **Committed in:** `38065512` (planning correction)

---

**Total deviations:** 1 verification correction
**Impact on plan:** Made the probe measure the intended public API contract; no runtime scope changed.

## Issues Encountered

- An earlier attempt to remove the helper spec was restored after strict Dialyzer reported `no local return`. The private-helper implementation satisfies D-28 and strict Dialyzer without a suppression or public type change.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 12 is complete. Continue sequentially with Phase 234 Plan 14, then Plan 13's independent D-46 review, then Plan 15's security and SPEC-02 reconciliation.
- The independent Plan 13 checker now requires the exact PASS evidence schema and distinct reviewer/executor identifiers.

---
*Phase: typespec-and-doc-completion-gate*
*Completed: 2026-10-05*
