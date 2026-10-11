---
phase: 240-connected-investigation-and-recovery
plan: "04"
subsystem: ui
tags: [phoenix-liveview, motion, accessibility, playwright]

# Dependency graph
requires:
  - phase: 240-connected-investigation-and-recovery
    provides: Transaction-origin row history, canonical investigation routes, and browser evidence setup.
provides:
  - Investigation evidence and row-history updates render immediately without entry or stagger motion.
  - Row-history route activation, Escape dismissal, and exact opener-focus return remain reliable across LiveView patches.
  - Reduced-motion and source-inventory contracts cover the row-history flow and evidence changes.
affects: [240-03, operator-ui]

# Actuals
actuals:
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Keep evidence updates and investigation rows still; reserve entrance motion for non-evidence feedback.
    - Use an explicit immediate-motion option for row-history while preserving standard motion for generic drawers.
    - Restore focus by a stable record/timestamp selector after the route patch replaces the original opener.

key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/style/08_overlays_motion.css
    - lib/threadline/operator_surface/style/09_responsive.css
    - lib/threadline/operator_surface/ui/overlay.ex
    - lib/threadline/operator_surface/live/row_history_component.ex
    - lib/threadline/operator_surface/live/transaction_live.ex
    - examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts
    - test/fixtures/operator_surface/route-inventory.json
    - test/fixtures/operator_surface/source-surface-checklist.json

key-decisions:
  - "Row history is immediate for pointer, touch, and keyboard because its route lifecycle has no safe existing input-modality signal."
  - "Keep generic drawers on their existing standard motion path; scope the immediate behavior to row history."
  - "Treat confirmation toasts as separate overlays and dismiss them before testing the next mobile stress control."

patterns-established:
  - "History return focus: preserve a stable record/timestamp-based opener ID through as-of patches and focus the newly rendered opener on route return."
  - "Evidence motion: no entry or stagger animation on changing values, evidence cards, actor investigation rows, or row-history timeline items."

requirements-completed: [UIA-07]
coverage:
  - id: D1
    description: Row-history timeline and investigation evidence stay immediate during initial entry and repeated as-of patches.
    requirement: UIA-07
    verification:
      - kind: e2e
        ref: examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts#row-history evidence stays immediate across as-of LiveView patches
        status: pass
      - kind: e2e
        ref: examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts#evidence cards and actor investigation rows do not animate on entry
        status: pass
    human_judgment: false
  - id: D2
    description: Keyboard entry, Escape dismissal, dialog semantics, and exact opener focus survive route patches with normal and reduced motion.
    requirement: UIA-07
    verification:
      - kind: e2e
        ref: examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts#keeps row-history drawer dialog semantics and visible focus
        status: pass
      - kind: e2e
        ref: examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts#reduced motion preserves keyboard row-history route, dialog, and focus
        status: pass
    human_judgment: false
  - id: D3
    description: Reduced motion removes spatial movement in row history without changing route, dialog, or focus behavior.
    requirement: UIA-07
    verification:
      - kind: e2e
        ref: examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts#row-history drawer and evidence stay immediate with reduced motion
        status: pass
      - kind: integration
        ref: test/threadline/operator_surface/operator_evidence_contract_test.exs#generic inventories close every independently discovered declaration
        status: pass
    human_judgment: false

# Metrics
completed: 2026-10-10
status: complete
---

# Phase 240 Plan 04: Investigation motion and focus Summary

**Row-history and changing investigation evidence now update immediately while keyboard semantics and focus return remain stable across LiveView patches.**

## Accomplishments

- Removed entrance and stagger motion from row-history items, evidence cards, and actor investigation rows. Retention-run feedback and confirmed-copy feedback remain unchanged.
- Added an opt-in immediate drawer motion path and applied it only to row history. Generic drawers retain their existing tokenized transitions.
- Made the row-history opener a native keyboard-accessible link with a stable identity. Repeated as-of patches preserve that identity, and returning from the route focuses the newly rendered opener.
- Added default-motion and reduced-motion browser checks for row history, evidence updates, dialog state, Escape, and focus restoration on desktop and mobile.
- Reconciled the source-surface inventory with newly covered controls and tests and refreshed four stale source anchors.

## Task Commits

1. **Tasks 1–2: Immediate investigation evidence and stable row-history focus** - `31dac585` (`feat`)
2. **Plan summary and closeout** - recorded in the following documentation commit.

## Decisions Made

- No stable existing pointer/touch modality signal exists in the row-history route lifecycle, so row-history opens and closes immediately for all input methods.
- Preserve standard motion for unrelated drawers and overlays.
- Keep focus restoration tied to the same row record and timestamp across patches rather than relying on a stale DOM node.

## Deviations from Plan

### Auto-fixed Issues

**1. Extended the source-surface inventories**
- **Found during:** Focused Elixir contract verification.
- **Issue:** The source scanner found 20 existing or newly added declarations missing from the authored inventory and four stale anchors, causing `independent declaration coverage` and `source anchor` failures.
- **Fix:** Added the declarations and reconciled stale inventory/checklist anchors; the immutable rendered evidence corpus was untouched.
- **Verification:** `operator_evidence_contract_test.exs` passes as part of the 105-test focused set.

**2. Dismissed the confirmation toast after modal confirmation in the mobile stress flow**
- **Found during:** Full desktop/mobile motion and accessibility run.
- **Issue:** Confirming the stress modal could render the persistent toast again, leaving it over the mobile “Show Drawer” control.
- **Fix:** The reduced-motion test dismisses the toast after modal confirmation before continuing.
- **Verification:** The complete browser set passes on desktop and mobile Chromium.

**Total deviations:** 2 auto-fixed.
**Impact on plan:** These changes keep the planned behavior and improve contract and browser-test reliability; no dependency or database changes were introduced.

## Verification

- Focused ExUnit coverage for UI, transaction, fixture-contract, and evidence-contract behavior - 105 tests, 0 failures.
- `mix format --check-formatted` on modified Elixir files - passed.
- `npm run typecheck` in the Phoenix example E2E package - passed.
- `operator-motion.spec.ts` and `operator-accessibility.spec.ts` on desktop and mobile Chromium - 48 passed, 0 failed.
- Scoped `git diff --check` for all Plan 240-04 implementation and plan files - passed.

## Next Plan Readiness

Plan 240-04 is complete. Continue with Plan 240-03 in Wave 3. The full `mix ci.all` phase gate remains required at phase close on PostgreSQL 15 or newer; the current environment uses PostgreSQL 14.17.

---
*Phase: 240-connected-investigation-and-recovery*
*Completed: 2026-10-10*
