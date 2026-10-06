---
phase: 234-typespec-and-doc-completion-gate
plan: 20
subsystem: docs
tags: [elixir, typespecs, ex_doc, playwright, ci]
requires:
  - phase: 234-15
    provides: Evidence reconciliation and SPEC-02 closeout contract
provides:
  - Corrected record_action/2 and context_opts/2 public documentation with executable behavior checks
  - Generic AuditTransaction action field type with an executable capture-boundary assertion
  - Fresh independent D-46 PASS bound to current review input
affects: [phase-234-verification, phase-235-stability-guide]
actuals:
  tokens: 7836
  tasks: 3
  commits: 6
  plan_head_before: 051f95de9d731575b0523bed8a7946d9d2be4181
  plan_head_after: 2814e3429d34a6ab7154f41cca2aa60430e8c978
tech-stack:
  added: []
  patterns:
    - Public documentation claims are paired with executable runtime and compiled-doc assertions.
    - Capture-to-semantics type separation is pinned through compiled-type and source-AST checks.
key-files:
  created: []
  modified:
    - lib/threadline.ex
    - lib/threadline/job.ex
    - lib/threadline/capture/audit_transaction.ex
    - test/threadline/semantics/audit_action_test.exs
    - test/threadline/job_test.exs
    - test/threadline/capture_semantics_boundary_test.exs
    - .planning/phases/234-typespec-and-doc-completion-gate/234-REVIEW-INPUT.md
    - .planning/phases/234-typespec-and-doc-completion-gate/234-D46-REVIEW.md
    - .planning/phases/234-typespec-and-doc-completion-gate/deferred-items.md
    - .planning/REQUIREMENTS.md
key-decisions:
  - "Marked SPEC-02 Complete only after the fresh D-46 PASS, focused tests, strict Dialyzer, warning-free docs build, canonical mix ci.all, and report-integrity gate all passed."
  - "Plan 21 repaired the mobile browser obstruction without changing Plan 20's reviewed input; the D-46 hash remains unchanged."
  - "Preserved D-55's >=82 visible-entry floor and D-07's eight exact hidden pins."
patterns-established: []
requirements-completed: [SPEC-02]
coverage:
  - id: D1
    description: The public action example and job helper documentation match executable behavior.
    requirement: SPEC-02
    verification:
      - kind: unit
        ref: "mix test test/threadline/semantics/audit_action_test.exs test/threadline/job_test.exs test/threadline/doc_rubric_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: AuditTransaction exposes a generic action type and the capture source boundary is executable.
    requirement: SPEC-02
    verification:
      - kind: unit
        ref: "mix test test/threadline/capture_semantics_boundary_test.exs test/threadline/doc_spec_coverage_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: Current-source D-46 review, static/documentation gates, and canonical CI all pass; Plan 21 repaired the mobile browser obstruction.
    requirement: SPEC-02
    verification:
      - kind: other
        ref: "234-D46-REVIEW.md: PASS, input SHA-256 e341c89282ceca06f738754985c2aaff4af24e2c9b2ed7efb792a8dc70fd6cb8; report integrity passed"
        status: pass
      - kind: integration
        ref: "mix verify.dialyzer; MIX_ENV=dev mix docs --warnings-as-errors"
        status: pass
      - kind: e2e
        ref: "mix ci.all after Plan 21 repair on 2026-10-06: 3,010 root tests and 130 example tests passed; Dialyzer 0 errors; browser 318 passed/26 skipped"
        status: pass
    human_judgment: false
duration: 49min (first-to-last scoped commit; executor start was not separately recorded)
completed: 2026-10-06
status: complete
---

# Phase 234 Plan 20 Summary

**Public documentation and capture-type corrections are committed with a fresh D-46 PASS, and the required canonical CI gate now passes after Plan 21 repaired the mobile motion browser obstruction.**

## Performance

- **Duration:** 49 minutes for Plan 20's scoped implementation and review work; Plan 21 later supplied the required canonical CI pass.
- **Started:** 2026-10-06T13:16:38-04:00 (first scoped task commit)
- **Completed:** 2026-10-06; canonical CI passed after Plan 21's mobile repair.
- **Tasks:** 3/3 completed. Task 3's remaining canonical CI gate passed after Plan 21 repaired the mobile test.
- **Files modified:** 10

## Accomplishments

- Updated the `record_action/2` example to construct a validated `ActorRef`, and made `Job.context_opts/2` documentation match its pass-through behavior. Focused tests cover the runtime paths and compiled docs.
- Changed `AuditTransaction.t.action` to `struct() | nil` and added compiled-type and source-AST assertions protecting the capture/semantics boundary.
- Regenerated D-46 evidence and received a fresh independent PASS bound to input SHA-256 `e341c89282ceca06f738754985c2aaff4af24e2c9b2ed7efb792a8dc70fd6cb8`. The focused tests, strict Dialyzer, warning-free docs build, and review-integrity check passed.
- Preserved the D-55 floor of at least 82 visible entries and all eight exact D-07 hidden pins.

## Task Commits

1. **Task 1: Prove the documented job-to-action path with a validated actor** — `f8631499` (test), `9a13e97a` (docs and behavior assertions), `d4636e15` (facade source-size pin correction).
2. **Task 2: Reinstate and pin the capture-to-semantics typespec boundary** — `5f14d7da` (test), `01698e43` (typespec).
3. **Task 3: Re-review the corrected public surface and close SPEC-02 from current evidence** — `2814e342` records the fresh independent review; its final canonical CI gate passed after Plan 21's repair.

## Files Created/Modified

- `lib/threadline.ex`, `lib/threadline/job.ex` — corrected public examples and option behavior docs.
- `lib/threadline/capture/audit_transaction.ex` — generic hydrated action field type.
- `test/threadline/semantics/audit_action_test.exs`, `test/threadline/job_test.exs`, `test/threadline/capture_semantics_boundary_test.exs` — executable behavior and type-boundary contracts.
- `234-REVIEW-INPUT.md`, `234-D46-REVIEW.md`, `deferred-items.md`, `REQUIREMENTS.md` — current review evidence, completed CI closeout, and SPEC-02 status.

## Decisions Made

- Marked both SPEC-02 markers Complete only after all Plan 20 gates passed, including Plan 21's canonical CI rerun and the unchanged D-46 input hash.
- Reused Plan 21's focused mobile and canonical CI evidence to finish Plan 20's previously halted Task 3 without repeating committed source, tests, docs, or independent review.

## Issues Encountered

- The first `mix ci.all` stopped in `verify.example_browser`: 313 passed, 26 skipped, 4 flaky, and 1 failed. The Pixel 5 reduced-motion scenario timed out clicking “Show Drawer” at `operator-motion.spec.ts:323` because overlays obscured the control.
- Plan 21 dismissed the toast, waited for the modal to hide, and retained a normal drawer click. Its focused mobile run passed 7/7, and the subsequent canonical CI passed with 318 browser tests and 26 skips.
- Plan 21's canonical gate initially exposed two machine-specific GSD paths in its plan document. Those references were normalized to the repository's `<home>` convention before the successful full rerun.

## User Setup Required

None.

## Next Phase Readiness

Plan 20 is complete and SPEC-02 is Complete under its evidence-gated contract. Phase 234 is ready for its phase verifier; the phase remains In Progress until that verifier passes.

---
*Phase: 234-typespec-and-doc-completion-gate*
*Completed: 2026-10-06*
