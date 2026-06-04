---
phase: 139-orientation-hub-home-nav
plan: "02"
subsystem: ui
tags: [phoenix-liveview, operator-surface, home, gds, saved-views, health]

requires:
  - phase: 139-orientation-hub-home-nav
    plan: "01"
    provides: "Surface header IA foundation and topbar coverage ownership"
provides:
  - "Home orientation hub with Find, Verify, and Prove next-action cards"
  - "Severity-aware Home health row for coverage, export, and retention signals"
  - "Actor-owned saved-view resume links and honest empty resume state"
  - "Scoped token-backed Home CSS contracts"
affects: [operator-surface-home, phase-139, phase-140-boundary]

tech-stack:
  added: []
  patterns:
    - "LiveView Home health items carry severity and render via health_chip_class/1"
    - "StartLive resume links continue using FilterParams.canonical_query/1"
    - "Home CSS remains scoped under .tl-home__* and token-backed by --tl-* variables"

key-files:
  created:
    - test/threadline/operator_surface/live/start_live_test.exs
    - .planning/phases/139-orientation-hub-home-nav/139-02-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/live/start_live.ex
    - lib/threadline/operator_surface/style.ex
    - test/threadline/operator_surface/style_contract_test.exs

key-decisions:
  - "Home coverage health uses recovery/action copy while the topbar retains numeric coverage ownership."
  - "Saved-view tests stay inside FilterParams.canonical_query/1's existing allowlist; no op query behavior was added."
  - "Exports are visually separated as a Prove handoff/deliverable link, not a closed export workflow."

patterns-established:
  - "Home health maps include :severity and are rendered through health_chip_class/1."
  - "Home resume renders both actor-owned saved-view links and a no-saved-views empty state."
  - "Phase 140 non-leakage is guarded with a static StartLive source contract."

requirements-completed: [POLISH-HOME]

duration: 5min
completed: 2026-06-04
---

# Phase 139 Plan 02: Orientation Hub Home Polish Summary

**GDS-style Home orientation hub with severity-aware health, actor-owned Timeline resume links, and a separated Prove exports handoff**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-04T14:43:29Z
- **Completed:** 2026-06-04T14:48:27Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Removed the redundant `Threadline` hero eyebrow while preserving the Home headline and lede.
- Preserved Find, Verify, and Prove cards with links only to existing destinations.
- Added severity-aware Home health: coverage gaps warning, failed exports danger, failed retention danger, all-clear success.
- Changed Home coverage health to action/recovery copy instead of duplicating the topbar numeric count.
- Added actor-owned saved-view resume links and a truthful empty resume state.
- Added style contracts for scoped, token-backed Home primitives including `.tl-home__resume` and `.tl-home__prove-handoff`.
- Added source-level tests preventing Phase 140 form, record lookup, correlation input, or `push_patch` behavior from leaking into Home.

## Task Commits

1. **Task 1: Add StartLive Home orientation contracts** - `0b52d95` (test)
2. **Task 2: Add Home style contracts** - `9bbd84e` (test)
3. **Task 2: Implement Home orientation, health severity, and resume styling** - `1ce7184` (feat)

## Files Created/Modified

- `test/threadline/operator_surface/live/start_live_test.exs` - StartLive LiveView contracts for orientation, health severity, saved-view ownership, empty resume state, and Phase 140 non-leakage.
- `lib/threadline/operator_surface/live/start_live.ex` - Home render changes, severity-aware health item maps, Prove handoff grouping, resume section, and `health_chip_class/1`.
- `lib/threadline/operator_surface/style.ex` - Scoped Home CSS for Prove handoff and resume empty states.
- `test/threadline/operator_surface/style_contract_test.exs` - CSS contract for Phase 139 Home primitives.

## Decisions Made

- Home coverage health intentionally says `Close coverage gaps before trusting Timeline answers` instead of repeating the numeric topbar badge role.
- Saved-view resume links continue to use `FilterParams.canonical_query/1`; tests use only keys currently allowed by that function.
- The Prove card separates `Exports` visually under a `Handoff` label without adding export creation, closed-loop export workflow, or new routes.

## Deviations from Plan

None - plan executed within scope. The saved-view test fixture was kept inside the existing canonical filter allowlist to avoid adding new query behavior.

## Issues Encountered

- The initial saved-view test expected an `op` query key, but `FilterParams.canonical_query/1` does not preserve `op`. The fixture was corrected to assert canonical links using existing keys only.
- The all-clear health test needed coverage disabled through the test auth seam because the repo coverage fixture legitimately reports gaps.

## Verification Evidence

- `mix test test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/style_contract_test.exs` - 15 tests, 0 failures.
- `rg -n "phx-submit|phx-change|record_lookup|name=\"correlation_id\"|push_patch" lib/threadline/operator_surface/live/start_live.ex` - no output.
- `git diff --name-only -- lib/threadline/operator_surface/router.ex priv/repo/migrations lib/threadline/query.ex lib/threadline/governance` - no output.

## Known Stubs

None. Stub scan only found intentional empty-list render conditions for Home health and saved-view empty state.

## Threat Flags

None. No new network endpoints, routes, schema changes, file access patterns, or trust-boundary expansions were introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 139 Home polish is ready for downstream Phase 139 plans and preserves the Phase 140 boundary: no record-first lookup, correlation paste/deep-link, row-history route, form behavior, or closed export loop was introduced.

## Self-Check: PASSED

- Summary file created at `.planning/phases/139-orientation-hub-home-nav/139-02-SUMMARY.md`.
- Task commits found: `0b52d95`, `9bbd84e`, `1ce7184`.
- Required verification passed after the last code change.

---
*Phase: 139-orientation-hub-home-nav*
*Completed: 2026-06-04*
