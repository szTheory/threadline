---
phase: 97-mix-task-and-machine-readable-proof
plan: 02
subsystem: api
tags: [evidence, proof, mix-task, json, docs]
requires:
  - phase: 97-mix-task-and-machine-readable-proof
    provides: viewer task and wrapped proof document baseline from plan 01
provides:
  - explicit proof verdict semantics for direct facts, posture, and unsupported claims
  - viewer/docs parity for unsupported evidence proof results
  - public contract documentation for `claim_assessment` and proof wrapper keys
affects: [phase-98, evidence-viewers, procurement-proof]
tech-stack:
  added: []
  patterns: [explicit claim assessment verdicts, viewer-not-gate proof contract]
key-files:
  created:
    - .planning/phases/97-mix-task-and-machine-readable-proof/97-02-SUMMARY.md
  modified:
    - lib/threadline/evidence/proof.ex
    - lib/mix/tasks/threadline.evidence.show.ex
    - test/threadline/evidence/proof_test.exs
    - test/mix/tasks/threadline.evidence_show_test.exs
    - guides/domain-reference.md
key-decisions:
  - "Classified `redaction_policy`, `retention_policy`, and `support_scope_posture` as `inferred_posture` by default while keeping direct evidence subjects in `proven`."
  - "Allowed evidence-row `detail.claim_assessment` to carry explicit unsupported reasons without turning viewer output into runtime failure."
  - "Documented `mix threadline.evidence.show` as a viewer-only task and reserved failing policy checks for a future gate task."
patterns-established:
  - "Proof verdicts come from serializer-owned semantics, not raw `summary_status` folding."
  - "Unsupported claims stay decodable and human-readable across every viewer surface."
requirements-completed: [PROOF-03]
duration: 5 min
completed: 2026-05-26
---

# Phase 97 Plan 02: Mix Task And Machine Readable Proof Summary

**Explicit evidence-proof verdicts for direct facts, inferred posture, and unsupported claims, with viewer/docs parity around the wrapped proof contract**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-26T04:46:00Z
- **Completed:** 2026-05-26T04:51:20Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Locked `claim_assessment` semantics in `Threadline.Evidence.Proof` so successful payloads now distinguish `proven`, `inferred_posture`, and `unsupported`.
- Added executable coverage for explicit unsupported payloads, posture snapshots, and directly supported negative facts that still count as `proven`.
- Published the viewer-only proof contract in the Mix task docs and `guides/domain-reference.md`, including the wrapped JSON keys and verdict vocabulary.

## Task Commits

Each task was committed atomically:

1. **Task 1: Encode the layered verdict model directly into proof projection and tests**
   - `8d95f8e` (test) — failing proof verdict tests
   - `e38e164` (feat) — proof verdict classifier implementation
2. **Task 2: Keep CLI and contract docs aligned with unsupported-claim behavior**
   - `664d8d6` (test) — unsupported viewer contract tests
   - `a7aa073` (docs) — viewer/docs contract alignment

## Files Created/Modified
- `lib/threadline/evidence/proof.ex` - classifies direct-fact, posture, and unsupported proof verdicts and keeps error outcomes separate.
- `test/threadline/evidence/proof_test.exs` - locks exact verdict strings, explicit unsupported reasons, and proven negative-fact behavior.
- `lib/mix/tasks/threadline.evidence.show.ex` - documents the viewer-only boundary and the future gate-task split.
- `test/mix/tasks/threadline.evidence_show_test.exs` - proves unsupported JSON stays decodable and human output remains a successful viewer run.
- `guides/domain-reference.md` - documents the wrapped proof keys plus `claim_assessment` contract and verdict vocabulary.
- `.planning/phases/97-mix-task-and-machine-readable-proof/97-02-SUMMARY.md` - execution summary for this plan.

## Decisions Made

- Kept semantic proof classification inside `Threadline.Evidence.Proof` so the CLI and future mounted parity surfaces consume one verdict model.
- Treated explicit `detail.claim_assessment` payloads as the authoritative path for unsupported reasons while defaulting subject families to either direct-fact or posture semantics.
- Preserved the product boundary by documenting `threadline.evidence.show` as a viewer and leaving any future failing policy gate to a separate task.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The plan’s `read_first` reference to `test/threadline.export_test.exs` did not exist at that exact path; implementation used the in-repo export task tests at `test/mix/tasks/threadline/export_test.exs` as the adjacent viewer-contract precedent instead.
- `mix verify.test` still fails on the pre-existing unrelated `test/threadline/ci_topology_contract_test.exs` assertion against `mix.exs`. The owned proof files for Plan 97-02 passed their targeted verification and were left scoped.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The proof serializer, CLI viewer, and public docs now agree on the same honest verdict vocabulary, so mounted parity work in Phase 98 can reuse the shipped `claim_assessment` contract directly. The only remaining verification blocker observed in this run is the known unrelated topology alias failure outside this plan’s ownership.

## Self-Check: PASSED

- Verified `.planning/phases/97-mix-task-and-machine-readable-proof/97-02-SUMMARY.md` exists.
- Verified commits `8d95f8e`, `e38e164`, `664d8d6`, and `a7aa073` exist in git history.
