---
phase: 97-mix-task-and-machine-readable-proof
plan: 01
subsystem: api
tags: [mix-task, evidence, json, proof, cli]
requires:
  - phase: 96-evidence-persistence-and-public-api
    provides: public append-only evidence read/write helpers
provides:
  - canonical `mix threadline.evidence.show` viewer task
  - wrapped machine-readable evidence proof contract
  - overview helper covering the full six-subject evidence inventory
affects: [phase-98, evidence-viewers, procurement-proof]
tech-stack:
  added: []
  patterns: [thin mix task over reusable proof serializer, wrapped additive json contract]
key-files:
  created:
    - lib/mix/tasks/threadline.evidence.show.ex
    - lib/threadline/evidence/proof.ex
    - test/mix/tasks/threadline.evidence_show_test.exs
    - test/threadline/evidence/proof_test.exs
  modified:
    - lib/threadline/evidence.ex
    - test/threadline/evidence_test.exs
key-decisions:
  - "Kept `threadline.evidence.show` as a viewer-only task that always exits 0 for successful reads, including unsupported proof states."
  - "Moved proof shaping into `Threadline.Evidence.Proof` and kept the task as argv/bootstrap/render glue only."
  - "Added `Threadline.Evidence.list_overview/2` so overview mode stays inside the existing public evidence boundary."
patterns-established:
  - "Evidence viewer surfaces should delegate proof shaping to `Threadline.Evidence.Proof`."
  - "Machine-readable proof output uses one wrapped snake_case JSON envelope with stable top-level keys."
requirements-completed: [PROOF-02]
duration: 3 min
completed: 2026-05-26
---

# Phase 97 Plan 01: Mix Task And Machine Readable Proof Summary

**Canonical no-Phoenix evidence viewer with a wrapped proof JSON contract and overview coverage for all six supported evidence subjects**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-26T04:42:50Z
- **Completed:** 2026-05-26T04:45:44Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Added `mix threadline.evidence.show` with bounded flags for overview, latest, history, date bounds, limit, and explicit `--json`.
- Introduced `Threadline.Evidence.Proof` for wrapped proof documents and moved proof shaping out of the Mix task.
- Added overview coverage through `Threadline.Evidence.list_overview/2` and contract tests for the six-subject inventory.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the canonical `threadline.evidence.show` viewer task with bounded overview/history flags** - `7275ed3` (feat)
2. **Task 2: Build the wrapped proof projection and JSON contract on top of `Threadline.Evidence`** - `adaafad` (feat)

## Files Created/Modified
- `lib/mix/tasks/threadline.evidence.show.ex` - canonical evidence viewer task with bounded argv parsing and repo bootstrap.
- `lib/threadline/evidence/proof.ex` - reusable wrapped proof projection, human renderer, and JSON encoder.
- `lib/threadline/evidence.ex` - additive `list_overview/2` helper over the existing evidence API.
- `test/mix/tasks/threadline.evidence_show_test.exs` - CLI coverage for default output, JSON mode, filter parsing, and unsupported proof states.
- `test/threadline/evidence/proof_test.exs` - wrapped JSON contract and six-subject overview assertions.
- `test/threadline/evidence_test.exs` - evidence API coverage for overview reads across the full supported inventory.

## Decisions Made

- Kept overview as the default subject label (`"overview"`) and latest as the default mode so operators can answer “what can Threadline prove now?” without picking a subject first.
- Preserved the existing evidence boundary by deriving overview from `list_latest_subject_refs/3` via `list_overview/2` instead of adding task-local reducers or direct SQL.
- Treated empty proof reads as valid wrapped output with explicit `claim_assessment` semantics instead of turning them into viewer failures.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

`mix verify.test` reported one unrelated pre-existing failure in `test/threadline/ci_topology_contract_test.exs` against `mix.exs` alias text. The owned files for Plan 97-01 are green; that failure was left untouched per scope constraints.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The proof serializer and Mix task are ready for mounted parity reuse in the next evidence surface phase. The only known repo-level verification blocker is the unrelated `mix verify.test` failure outside this plan’s ownership.

## Self-Check: PASSED

- Verified `.planning/phases/97-mix-task-and-machine-readable-proof/97-01-SUMMARY.md` exists.
- Verified commits `7275ed3` and `adaafad` exist in git history.
