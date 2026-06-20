---
phase: 171-audit-baseline-stress-lab-harness-idempotency-ledger
plan: 02
subsystem: testing
tags: [elixir, exunit, json, design-system, ratchet-ledger]
requires:
  - phase: 171-audit-baseline-stress-lab-harness-idempotency-ledger
    provides: DS-04 stress fixture registry from Plan 171-01
provides:
  - canonical JSON design-system audit ledger
  - deterministic DESIGN-SYSTEM.md projection
  - ExUnit ratchet, freshness, allowlist, and fixture round-trip contracts
affects: [171-03-stress-route, 171-04-browser-harness, 172-foundations, 173-primitives]
tech-stack:
  added: []
  patterns:
    - JSON ledger as machine-readable source of truth
    - markdown projection freshness checked from ledger rows
    - fixture-backed ledger IDs locked by ExUnit
key-files:
  created:
    - .planning/design-system-ledger.json
    - DESIGN-SYSTEM.md
    - test/threadline/operator_surface/stress_ledger_test.exs
  modified: []
key-decisions:
  - "Every StressFixtures story is represented as a ledger entry with matching story_id, fixture_key, and ledger ID."
  - "Reserved future-owned inventory entries are explicit rows with reserved_for_phase metadata and ratchet scores."
  - "DESIGN-SYSTEM.md remains a deterministic human projection, not the canonical source."
patterns-established:
  - "Ledger rows use `current_score`, `target_score`, and `ratchet_score`; decreases require ratchet.resets plus reset_rationale."
  - "Screenshot allowlist entries are ledger-owned and name story_id, theme, viewport, and baseline_ref."
requirements-completed: [DS-02, DS-03, DS-04]
duration: 8min
completed: 2026-06-14
---

# Phase 171 Plan 02: Ledger and Projection Summary

**Fixture-backed JSON audit ledger with ratchet rules, deterministic design-system projection, and ExUnit freshness contracts**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-14T21:45:00Z
- **Completed:** 2026-06-14T21:53:18Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `test/threadline/operator_surface/stress_ledger_test.exs` with schema, sorted-entry, ratchet, locked-ID, fixture round-trip, screenshot allowlist, projection freshness, and forbidden-copy checks.
- Created `.planning/design-system-ledger.json` with all Plan 171-01 stress stories, reserved future cases, current/target/ratchet scores, locked IDs, minimum scores, and screenshot allowlist metadata.
- Created `DESIGN-SYSTEM.md` as a deterministic projection of the ledger across foundations, primitives, form controls, groups, pages, known footguns, and future reserved cases.

## Task Commits

1. **Task 1: Write ledger schema and projection contract tests** - `fcaa87b` (`test`)
2. **Task 2: Create canonical JSON ledger and DESIGN-SYSTEM projection** - `224e4d3` (`feat`)

## Files Created/Modified

- `.planning/design-system-ledger.json` - Canonical machine-readable ledger with ratchet metadata and fixture-backed inventory entries.
- `DESIGN-SYSTEM.md` - Human-readable inventory projection from the ledger.
- `test/threadline/operator_surface/stress_ledger_test.exs` - ExUnit contract for ledger schema, ratchet semantics, fixture coverage, allowlist shape, and markdown freshness.

## Decisions Made

- Used `StressFixtures.all/0` as the complete entry seed so downstream stress route work can round-trip ledger rows back to fixture stories.
- Kept `DESIGN-SYSTEM.md` timestamp-free and table-based so freshness checks can assert deterministic row presence.
- Locked every current ledger ID in `ratchet.locked_ids` and mirrored the starting score into `ratchet.minimum_scores`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

Intentional reserved rows remain for planned inventory not implemented in Phase 171: form controls, groups, page fixtures, primitive placeholders, and folded future-owned cases. Each row is fixture-backed, has `status: "reserved"`, includes `reserved_for_phase`, and is required by the plan.

## Threat Flags

None. The trust boundaries introduced here match the plan threat model: JSON ledger to tests, JSON ledger to markdown projection, and fixture registry to ledger.

## Verification

- `mix test test/threadline/operator_surface/stress_ledger_test.exs` - 10 tests, 0 failures
- `mix test test/threadline/operator_surface/stress_fixtures_test.exs test/threadline/operator_surface/stress_ledger_test.exs` - 19 tests, 0 failures
- `node -e "JSON.parse(require('fs').readFileSync('.planning/design-system-ledger.json','utf8')); console.log('ledger json ok')"` - `ledger json ok`
- `rg -n 'PhoenixStorybook|Tailwind|Chromatic|Percy|Applitools|immutable ledger' .planning/design-system-ledger.json DESIGN-SYSTEM.md` - no matches

## Self-Check: PASSED

- Found `.planning/design-system-ledger.json`
- Found `DESIGN-SYSTEM.md`
- Found `test/threadline/operator_surface/stress_ledger_test.exs`
- Found task commit `fcaa87b`
- Found task commit `224e4d3`

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 171-03 can build `/audit/__stress` against stable ledger rows and fixture story IDs. Plan 171-04 can consume the screenshot allowlist without inventing a second source of truth.

---
*Phase: 171-audit-baseline-stress-lab-harness-idempotency-ledger*
*Completed: 2026-06-14*
