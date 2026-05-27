---
phase: 110-triage-narrow-fixes
plan: 02
subsystem: testing
tags: [walkthrough, findings, doc-contract, demo-seed]

requires:
  - phase: 110-triage-narrow-fixes
    plan: 01
    provides: finding 0001 fixed; ci green baseline
provides:
  - Findings 0002 (WR-002 CLI) and 0003 (WR-001 agent2 window) filed and closed
  - WALK-03-02 window aligned to demo_last_tuesday through demo_epoch
  - WALK-03-03 optional CLI uses --subject and --subject-ref-json
  - demo_contract_test SEED-03 leaving agent window describe
  - walkthrough_doc_contract_test locks WR-002 CLI literals
  - IN-001 §0 maintainer-voice cleanup (no Plan 05 / Task 2 labels)
affects: [110-03, validation-re-walk]

tech-stack:
  added: []
  patterns:
    - "Doc-only WR fixes — anchors.ex unchanged; contract tests lock window fiction"

key-files:
  created:
    - .planning/v1.23/findings/0002-wr-002-cli-syntax.md
    - .planning/v1.23/findings/0003-wr-001-agent2-window.md
  modified:
    - examples/threadline_phoenix/WALKTHROUGH.md
    - examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs
    - examples/threadline_phoenix/test/threadline_phoenix/walkthrough_doc_contract_test.exs

key-decisions:
  - "0002/0003 fixes are doc + contract-test only — seed timestamps unchanged per D-110-05a"

patterns-established:
  - "Pre-registered 108-REVIEW findings promoted with classification note before doc fix"

requirements-completed: [FIX-01, FIX-02, FIX-03]

duration: 20min
completed: 2026-05-27
---

# Phase 110 Plan 02: Wave 2 — WR-001/WR-002 Doc Fixes Summary

**Findings 0002 and 0003 filed from 108-REVIEW, WALK-03-02/03 prose aligned with seed fiction, contract tests extended, IN-001 §0 voice cleaned**

## Performance

- **Duration:** 20 min
- **Started:** 2026-05-27T20:00:00Z
- **Completed:** 2026-05-27T20:20:00Z
- **Tasks:** 3 completed
- **Files modified:** 5

## Accomplishments

- Promoted WR-002 → finding 0002 and WR-001 → finding 0003 with 108-REVIEW evidence and pre-registration classification notes
- Replaced WALK-03-02 24h-only window with `demo_last_tuesday` through `demo_epoch`; fixed WALK-03-03 optional CLI to flag style
- Added `SEED-03 leaving agent window` contract test and extended walkthrough doc contract literals
- IN-001 §0: removed `Plan 05` and `Task 2` internal labels; closed findings with `fixed_in: 8dfcb87`
- L0 CLI spot-check and L1 `mix ci.all` passed

## Task Commits

Each task was committed atomically:

1. **Task 1: File findings 0002 and 0003** - `a5fc7e2` (docs)
2. **Task 2: Fix WALK-03-02 window and WALK-03-03 CLI + contract tests** - `8dfcb87` (fix)
3. **Task 3: IN-001 §0 maintainer voice + close findings 0002/0003** - `58d10d7` (docs)

**Plan metadata:** `7ff605a` (docs: complete plan)

## Files Created/Modified

- `.planning/v1.23/findings/0002-wr-002-cli-syntax.md` — WR-002 (c) finding, closed
- `.planning/v1.23/findings/0003-wr-001-agent2-window.md` — WR-001 (c) finding, closed
- `examples/threadline_phoenix/WALKTHROUGH.md` — WALK-03-02 window, WALK-03-03 CLI, IN-001 §0 voice
- `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` — agent2 window contract
- `examples/threadline_phoenix/test/threadline_phoenix/walkthrough_doc_contract_test.exs` — CLI literal locks

## Decisions Made

- Doc-only fixes per scope guard — `anchors.ex` unchanged; window fix is prose alignment only

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Wave 2 complete; ready for plan 110-03 (validation re-walk)
- WALK-03-02 and WALK-03-03 no longer produce false `(a)` findings on re-walk

## Self-Check: PASSED

- [x] Findings 0002/0003 exist with `Pre-registered 108-REVIEW`
- [x] WALKTHROUGH no longer uses `2026-05-26T12:00:00Z` as WALK-03-02 `from`
- [x] WALK-03-03 has `--subject retention_run` and `--subject-ref-json`
- [x] `demo_contract_test.exs` has `leaving agent window` describe
- [x] Example contract tests: 9 tests, 0 failures
- [x] L0 CLI exit 0
- [x] Findings 0002/0003 `status: fixed` with `fixed_in` SHA
- [x] `mix ci.all` exit 0 (677 + 51 tests)

---
*Phase: 110-triage-narrow-fixes*
*Completed: 2026-05-27*
