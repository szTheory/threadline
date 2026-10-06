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
  tasks: 2
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
key-decisions:
  - "Kept SPEC-02 Pending because the required canonical mix ci.all gate did not pass."
  - "Recorded the unrelated mobile browser obstruction as a designed halt; Plan 21 owns its repair."
  - "Preserved D-55's >=82 visible-entry floor and D-07's eight exact hidden pins."
patterns-established: []
requirements-completed: []
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
    description: Current-source D-46 review and static/documentation gates pass, but the canonical CI closeout is blocked by the mobile browser test.
    requirement: SPEC-02
    verification:
      - kind: other
        ref: "234-D46-REVIEW.md: PASS, input SHA-256 e341c89282ceca06f738754985c2aaff4af24e2c9b2ed7efb792a8dc70fd6cb8; report integrity passed"
        status: pass
      - kind: integration
        ref: "mix verify.dialyzer; MIX_ENV=dev mix docs --warnings-as-errors"
        status: pass
      - kind: e2e
        ref: "mix ci.all on 2026-10-06: verify.example_browser reported 313 passed, 26 skipped, 4 flaky, 1 failed at operator-motion.spec.ts:323"
        status: fail
    human_judgment: false
duration: 49min (first-to-last scoped commit; executor start was not separately recorded)
completed: 2026-10-06
status: halted
---

# Phase 234 Plan 20 Summary

**Public documentation and capture-type corrections are committed with a fresh D-46 PASS; canonical CI stopped at the pre-existing mobile motion browser obstruction.**

## Performance

- **Duration:** 49 minutes from the first scoped task commit to the final evidence commit; executor start was not separately recorded.
- **Started:** 2026-10-06T13:16:38-04:00 (first scoped task commit)
- **Halted:** 2026-10-06; last Plan 20 evidence commit at 2026-10-06T14:05:29-04:00
- **Tasks:** 2/3 completed. Task 3 completed its D-46 review and other gates, but not the required full CI gate.
- **Files modified:** 9

## Accomplishments

- Updated the `record_action/2` example to construct a validated `ActorRef`, and made `Job.context_opts/2` documentation match its pass-through behavior. Focused tests cover the runtime paths and compiled docs.
- Changed `AuditTransaction.t.action` to `struct() | nil` and added compiled-type and source-AST assertions protecting the capture/semantics boundary.
- Regenerated D-46 evidence and received a fresh independent PASS bound to input SHA-256 `e341c89282ceca06f738754985c2aaff4af24e2c9b2ed7efb792a8dc70fd6cb8`. The focused tests, strict Dialyzer, warning-free docs build, and review-integrity check passed.
- Preserved the D-55 floor of at least 82 visible entries and all eight exact D-07 hidden pins.

## Task Commits

1. **Task 1: Prove the documented job-to-action path with a validated actor** — `f8631499` (test), `9a13e97a` (docs and behavior assertions), `d4636e15` (facade source-size pin correction).
2. **Task 2: Reinstate and pin the capture-to-semantics typespec boundary** — `5f14d7da` (test), `01698e43` (typespec).
3. **Task 3: Re-review the corrected public surface and close SPEC-02 from current evidence** — `2814e342` records the fresh review and blocked closeout evidence. The task remains incomplete because `mix ci.all` failed.

## Files Created/Modified

- `lib/threadline.ex`, `lib/threadline/job.ex` — corrected public examples and option behavior docs.
- `lib/threadline/capture/audit_transaction.ex` — generic hydrated action field type.
- `test/threadline/semantics/audit_action_test.exs`, `test/threadline/job_test.exs`, `test/threadline/capture_semantics_boundary_test.exs` — executable behavior and type-boundary contracts.
- `234-REVIEW-INPUT.md`, `234-D46-REVIEW.md`, `deferred-items.md` — current review evidence and the CI residual.

## Decisions Made

- Kept both SPEC-02 markers Pending. The independent review does not override Plan 20's explicit full-gate requirement.
- Closed this partial execution as `halted` so the standard safe-resume gate will not repeat the already committed tasks. Plan 21 owns the remaining mobile browser obstruction; after its focused test and canonical CI pass, Plan 20 must be re-summarized as complete before phase verification.

## Issues Encountered

- `mix ci.all` exited nonzero only in `verify.example_browser`: 313 passed, 26 skipped, 4 flaky, and 1 failed. The Pixel 5 reduced-motion scenario timed out clicking “Show Drawer” at `operator-motion.spec.ts:323`.
- Retained Playwright logs show the modal intercepted the first two click probes, then the persistent `#stress-toast` intercepted approximately 228/229 retries. The retry screenshot shows the toast covering the button. The same viewport-sensitive failure is documented in earlier phases; Plan 20 does not change the browser fixture.
- Plan 21 will dismiss the toast, wait for the modal to hide, use a normal click, rerun the focused mobile scenario, and rerun `mix ci.all`.

## User Setup Required

None.

## Next Phase Readiness

Phase 234 is not ready to verify yet. Plan 21 can now run without repeating Plan 20's committed tasks. After its canonical CI gate passes, re-summarize Plan 20 as complete while keeping SPEC-02 Pending until the phase verifier passes.

---
*Phase: 234-typespec-and-doc-completion-gate*
*Completed: 2026-10-06 (halted)*
