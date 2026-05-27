---
phase: 115-narrative-doc-sync
plan: 01
subsystem: testing
tags: [docs, audit-transaction, doc-contract, narrative, elixir]

# Dependency graph
requires:
  - phase: 113-audited-write-path
    provides: Threadline.Audit.transaction/3 helper and getting-started §6 canonical snippet
provides:
  - how-threadline-works.md centered on Audit.transaction/3 as recommended audited write path
  - NARR-03 doc-contract test with blessed-path literals and write-side ordering lock
affects: [115-02, README cross-links, narrative discovery contract]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Doc-contract :binary.match scope for subsection ordering assertions"

key-files:
  created: []
  modified:
    - guides/how-threadline-works.md
    - test/threadline/how_threadline_works_doc_contract_test.exs

key-decisions:
  - "Surgical retarget of formula, flow, example, Job 2, write-side, and discovery order — Architecture/JTBD Jobs 1/3/4 unchanged"
  - "Capture-only note (Omit :action / capture_only: true) added in flow section to satisfy D-115-02d acceptance"

patterns-established:
  - "Mental model guide teaches Audit.transaction/3 before record_action/2 on write-side"

requirements-completed: [NARR-01, NARR-03]

# Metrics
duration: 8min
completed: 2026-05-27
---

# Phase 115 Plan 01: Narrative Doc Sync (how-threadline-works) Summary

**Retargeted `guides/how-threadline-works.md` to center `Threadline.Audit.transaction/3` as the recommended audited write path and locked blessed-path literals plus write-side ordering in doc-contract tests.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-27T22:04:00Z
- **Completed:** 2026-05-27T22:12:18Z
- **Tasks:** 4 completed
- **Files modified:** 2

## Accomplishments

- Formula, flow steps, code example, JTBD Job 2, Public API write-side, Evolution, and Where to go next now teach `Audit.transaction/3` first
- Standalone `record_action/2`-first patterns removed from flow and Job 2 prose
- Second doc-contract test locks `recommended audited write path`, write-side ordering, and getting-started §6 cross-link (NARR-03)

## Task Commits

Each task was committed atomically:

1. **Task 1: Retarget formula and short-version bullets** - `a4d1373` (docs)
2. **Task 2: Reorder flow, replace code sample, fix JTBD Job 2** - `e73f2e1` (docs)
3. **Task 3: Public API write-side, Evolution bullet, Where to go next** - `6746d30` (docs)
4. **Task 4: Extend how-threadline-works doc-contract test (NARR-03)** - `6c533c6` (test)

## Files Created/Modified

- `guides/how-threadline-works.md` — Mental model guide retargeted to blessed write path
- `test/threadline/how_threadline_works_doc_contract_test.exs` — Added NARR-03 blessed-path contract test

## Decisions Made

- Added capture-only guidance (`Omit :action` / `capture_only: true`) in flow section per D-115-02d even though not explicit in task 2 action text (required by acceptance criteria)
- Used `:binary.match(..., scope: {idx_write, write_len})` instead of plan's raw offset third arg — OTP 27 rejects integer offset

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] binary.match offset syntax**
- **Found during:** Task 4 (Extend doc-contract test)
- **Issue:** Plan specified `:binary.match(doc, needle, idx_write)` but OTP 27 `:binary.match/3` requires options keyword list, not integer offset
- **Fix:** Scoped search with `scope: {idx_write, byte_size(doc) - idx_write}`
- **Files modified:** `test/threadline/how_threadline_works_doc_contract_test.exs`
- **Verification:** `mix test test/threadline/how_threadline_works_doc_contract_test.exs` exits 0
- **Committed in:** `6c533c6`

**2. [Rule 2 - Missing Critical] Capture-only note in flow**
- **Found during:** Task 2 (acceptance criteria gate)
- **Issue:** Task 2 acceptance required `capture_only` or `Omit :action` literal but plan action text omitted it
- **Fix:** Appended capture-only sentence after correlation note in flow section
- **Files modified:** `guides/how-threadline-works.md`
- **Verification:** `grep -F 'capture_only' guides/how-threadline-works.md` matches
- **Committed in:** `e73f2e1`

---

**Total deviations:** 2 auto-fixed (1 bug, 1 missing critical)
**Impact on plan:** Both fixes required for acceptance criteria and test correctness. No scope creep.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Verification Results

```bash
mix test test/threadline/how_threadline_works_doc_contract_test.exs
# 2 tests, 0 failures

mix verify.doc_contract
# 59 tests, 0 failures
```

## Next Phase Readiness

- Ready for 115-02 (README/getting-started cross-link sync and remaining NARR-02/NARR-03 locks)
- NARR-01 and NARR-03 satisfied for how-threadline-works scope

## Self-Check: PASSED

---
*Phase: 115-narrative-doc-sync*
*Completed: 2026-05-27*
