---
phase: 116-example-first-hour-fixes
plan: 02
subsystem: docs
tags: [phoenix, readme, runbook, doc-contract, mix-tasks]

requires:
  - phase: 116-example-first-hour-fixes
    plan: 01
    provides: Auth curl anchor and session plugs on :api pipeline
provides:
  - Choose your path decision table and shared Base install runbook
  - Track A / Track B forks with neutral vs walkthrough fiction terminology
  - Mix task reference and Mix task ownership appendix tables
  - Extended readme_doc_contract_test locks for EXAMPLE-02/03/04 remainder
affects:
  - Phase 117 (evidence-plane doc authority)

tech-stack:
  added: []
  patterns:
    - "Single Base install + short Track A/B forks (no duplicated install tracks)"
    - "Generator commands live in Regenerating skeleton + ownership table only"

key-files:
  created: []
  modified:
    - examples/threadline_phoenix/README.md
    - test/threadline/readme_doc_contract_test.exs

key-decisions:
  - "Demo walkthrough data heading preserved; body compressed to Track B pointer"
  - "Greenfield generator order in blockquote; committed clone skips generators in Base install callout"

patterns-established:
  - "priv/repo/seeds.exs = neutral; mix demo.seed = walkthrough fiction — never bare seed for demo"
  - "Mix task ownership table is SSOT for ecto.reset vs demo.reset vs generator tasks"

requirements-completed: [EXAMPLE-02, EXAMPLE-03, EXAMPLE-04]

duration: 20min
completed: 2026-05-27
---

# Phase 116 Plan 02: First-Hour Runbook Clarity Summary

**Example README restructured with Choose your path, shared Base install, Track A/B forks, and Mix task ownership tables — doc contracts lock skip-generators and neutral vs walkthrough fiction literals.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-05-27T22:10:00Z
- **Completed:** 2026-05-27T22:30:50Z
- **Tasks:** 5
- **Files modified:** 2

## Accomplishments

- Added **`## Choose your path`** decision table and **`## Base install (all paths)`** with committed-checkout skip-generators callout.
- Split evaluator paths into **Track A** (first audited write, no `demo.seed`) and **Track B** (WALKTHROUGH fiction); compressed **`## Demo walkthrough data`** to a pointer.
- Added **`## Mix task reference`** and **`## Mix task ownership`** appendix; restored generator commands in **Regenerating the skeleton** with `MIX_ENV` note.
- Extended **`readme_doc_contract_test.exs`** with first-hour path and task-ownership literal locks.

## Task Commits

Each task was committed atomically:

1. **Task 1: Choose your path + Base install** - `23b2e38` (docs)
2. **Task 2: Track A/B forks + compress Demo section** - `f05b321` (docs)
3. **Task 3: Mix task reference + ownership appendix** - `2484f50` (docs)
4. **Task 4: Extend root doc-contract tests** - `e68a2c3` (test)
5. **Task 5: Phase closeout verification** - (verify-only; no code commit)

**Plan metadata:** pending (docs commit after STATE/ROADMAP update)

## Files Created/Modified

- `examples/threadline_phoenix/README.md` — EXAMPLE-02/03 runbook restructure (~75 LOC delta)
- `test/threadline/readme_doc_contract_test.exs` — EXAMPLE-04 remainder literal locks

## Decisions Made

- Kept **`## Demo walkthrough data`** heading exact per root doc contract; compressed body only.
- Placed greenfield integrator callout in blockquote under Mix task reference pointing to getting-started-saas.md.
- Left Plan 01 **Authenticate before the audited API call** subsection untouched.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Verification

```bash
mix test test/threadline/readme_doc_contract_test.exs  # 17 tests, 0 failures
mix test test/threadline/example_phoenix_readme_contract_test.exs  # 7 tests, 0 failures
mix verify.doc_contract  # 63 tests, 0 failures
mix verify.example  # 53 tests, 0 failures
```

## Next Phase Readiness

Phase 116 complete (both plans). Ready for **Phase 117** (evidence-plane doc authority + semver prose).

## Self-Check: PASSED

- [x] All 5 tasks executed with individual commits (Task 5 verify-only)
- [x] SUMMARY.md created at `.planning/phases/116-example-first-hour-fixes/116-02-SUMMARY.md`
- [x] Plan verification commands exit 0
- [x] Key artifacts exist on disk

---
*Phase: 116-example-first-hour-fixes*
*Completed: 2026-05-27*
