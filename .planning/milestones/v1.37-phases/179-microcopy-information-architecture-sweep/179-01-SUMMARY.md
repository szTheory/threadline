---
phase: 179-microcopy-information-architecture-sweep
plan: 01
subsystem: ui
tags: [microcopy, information-architecture, phoenix-liveview, operator-surface, copy-contract]

requires:
  - phase: 178-per-page-flow-stress-pass-all-11-pages
    provides: Shared shell, Home stress coverage, and route-stability proof for operator pages
provides:
  - Guard-first rendered/scoped copy-contract tests for shell and Home IA
  - Route-stable shell group relabeling to Investigate, Audit readiness, and Evidence & exports
  - Task-led Home job labels and direct validation messages for row-history/correlation shortcuts
affects: [operator-surface, phase-179, copy, ia, verification]

tech-stack:
  added: []
  patterns:
    - Rendered/scoped copy-contract tests instead of broad repository negative scans
    - Visible-label-only IA changes preserving routes, atoms, ids, and data-testids

key-files:
  created:
    - test/threadline/operator_surface/copy_contract_test.exs
    - .planning/phases/179-microcopy-information-architecture-sweep/deferred-items.md
  modified:
    - lib/threadline/operator_surface/components/surface_header.ex
    - lib/threadline/operator_surface/live/start_live.ex
    - test/threadline/operator_surface/surface_header_test.exs
    - test/threadline/operator_surface/live/start_live_test.exs
    - examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts
    - .planning/phases/179-microcopy-information-architecture-sweep/179-VALIDATION.md

key-decisions:
  - "Shell IA relabeling changed only visible group labels; legacy nav ids, route hrefs, current atoms, data-testids, and destination order remain stable."
  - "Home uses task-led job titles while keeping the existing Timeline, Coverage, Evidence, Redaction, Retention, Exports, row-history, and correlation workflows."

patterns-established:
  - "Copy contracts render the actual shell/Home surfaces and keep negative assertions scoped to primary UI output."
  - "Full-value forensic copy remains protected through data-tl-copy assertions on UI.ref/1."

requirements-completed: [COPY-01, COPY-02, COPY-03]

duration: 11m 53s
completed: 2026-06-19
status: complete
---

# Phase 179 Plan 01: Guard-First Shell/Home IA Summary

**Guard-first shell and Home copy contracts with route-stable IA relabeling for the operator surface**

## Performance

- **Duration:** 11m 53s
- **Started:** 2026-06-19T15:39:18Z
- **Completed:** 2026-06-19T15:51:11Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Added `Threadline.OperatorSurface.CopyContractTest`, covering shell group labels, Home job titles, primary UI copy safety, and full-value `data-tl-copy` affordances.
- Renamed shell navigation groups to `Investigate`, `Audit readiness`, and `Evidence & exports` without changing routes, atoms, nav ids, data-testids, or destination order.
- Renamed Home job cards to `Find what changed`, `Check audit readiness`, and `Use evidence and exports`; validation messages now name the object and next action.
- Updated ExUnit and mobile Playwright assertions to preserve existing links/forms across the IA relabeling.

## Task Commits

Each task was committed atomically. TDD tasks produced RED then GREEN commits where implementation followed the guard commit.

1. **Task 1: Add guard-first rendered copy-contract tests** - `9ac8a92` (test, RED)
2. **Task 2: Relabel shell navigation without route or atom churn** - `55cd24b` (test, RED)
3. **Task 2: Relabel shell navigation without route or atom churn** - `38a7b36` (feat, GREEN)
4. **Task 3: Rename Home jobs and validation microcopy** - `49108cb` (test, RED)
5. **Task 3: Rename Home jobs and validation microcopy** - `88ece8f` (feat, GREEN)

## Files Created/Modified

- `test/threadline/operator_surface/copy_contract_test.exs` - New rendered/scoped copy contract for shell/Home IA, primary copy safety, and full-value copy targets.
- `lib/threadline/operator_surface/components/surface_header.ex` - Visible shell group labels only.
- `lib/threadline/operator_surface/live/start_live.ex` - Home task titles, card copy, health warning, and validation messages.
- `test/threadline/operator_surface/surface_header_test.exs` - Shell label expectations plus href/current/data-testid stability assertions.
- `test/threadline/operator_surface/live/start_live_test.exs` - Home IA and validation expectations.
- `examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts` - Mobile shell/Home IA assertions.
- `.planning/phases/179-microcopy-information-architecture-sweep/179-VALIDATION.md` - Wave 0 marked complete after the red-first copy contract was created and observed.
- `.planning/phases/179-microcopy-information-architecture-sweep/deferred-items.md` - Out-of-scope `mix ci.all` failures recorded for later follow-up.

## Decisions Made

- Shell group ids such as `tl-shell-nav-find` remain unchanged even though their visible labels changed; route and test contracts are more important than renaming internal ids for copy symmetry.
- Home card kickers use destination nouns (`Timeline`, `Coverage`, `Evidence & exports`) while the card titles carry the task-led language.

## Verification

- `mix test test/threadline/operator_surface/copy_contract_test.exs --max-failures 6` - RED as intended before source edits: 4 tests, 3 expected failures.
- `mix test test/threadline/operator_surface/surface_header_test.exs` - RED as intended before shell edit: 5 tests, 2 expected failures.
- `mix test test/threadline/operator_surface/live/start_live_test.exs --max-failures 6` - RED as intended before Home edit: 16 tests, 4 expected failures.
- `mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/live/start_live_test.exs` - PASS, 25 tests.
- `mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/ui_test.exs` - PASS, 68 tests.
- `mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/live` - PASS, 133 tests.
- `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-home-nav-mobile.spec.ts` - PASS, 9 tests across chromium, desktop-chromium, and mobile-chromium.

## Deviations from Plan

None - plan implementation followed the planned shell/Home scope. Out-of-scope full-suite failures were logged separately rather than fixed in this copy slice.

## Issues Encountered

- `mix ci.all` did not pass due failures outside 179-01-owned files:
  - `test/threadline/v1_23_charter_doc_contract_test.exs:15` expects older `PROJECT.md` milestone wording.
  - `verify.example` reported five example demo seed/audit-row failures in walkthrough/demo contract tests.
- These failures are recorded in `deferred-items.md`; the targeted Phase 179 ExUnit and Playwright gates passed.

## Known Stubs

None. Stub scan only found intentional blank-input validation branches, empty-list render conditions, and non-empty copy-target assertions.

## Authentication Gates

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for 179-02. The copy-contract guard now protects shell/Home IA while later plans broaden state, terminology, Timeline, and governance copy.

## Self-Check: PASSED

- Verified summary, created/modified files, validation tracking, and deferred-items artifact exist on disk.
- Verified task commits exist in git history: `9ac8a92`, `55cd24b`, `38a7b36`, `49108cb`, `88ece8f`.

---
*Phase: 179-microcopy-information-architecture-sweep*
*Completed: 2026-06-19*
