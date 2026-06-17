---
status: gaps_found
phase: 174-form-components
plan_count: 4
score: 1/3
human_needed: false
---

# Phase 174 Verification Report

## Goal
Adopt unified WAI-ARIA form primitives across the operator surface

## Must-Haves
- ❌ Internal form components exist... — Several specified components are missing (field group, error summary, combobox).
- ❌ The 11 operator-surface LiveView pages consume the components... — Usage of the new components across the 11 pages seems incomplete based on grep counts (only found in start_live, timeline_live, row_history_component, stress_live, surface_header).
- ✅ Key Link: LiveView templates to UI components — Connected via UI.field

## Gaps
1. **Internal form components exist...** — Several specified components are missing (field group, error summary, combobox).
   - Missing: Implement missing form components in `lib/threadline/operator_surface/ui.ex` according to COMP-04.
2. **The 11 operator-surface LiveView pages consume the components...** — Usage of the new components across the 11 pages is incomplete.
   - Missing: Ensure all forms in all remaining LiveViews (actor_live, transaction_live, export_status_live, etc.) use the new `<UI.field>` and `<UI.input>` components if any exist, or verify they truly don't have forms.

## Human Verification Required
None.