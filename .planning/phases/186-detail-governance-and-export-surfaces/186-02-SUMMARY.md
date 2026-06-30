---
phase: 186-detail-governance-and-export-surfaces
plan: 02
subsystem: operator-surface-governance
tags: [phoenix-liveview, evidence, redaction, feature-gates, governance-ui]
requires:
  - phase: 185-coverage-and-audit-readiness
    provides: focused workflow verdict pattern for governance pages
provides:
  - Evidence page focused workflow summary with valid gated export handoff
  - Redaction page configured-vs-deployed posture summary with contextual feature-gated actions
affects: [operator-surface, evidence, redaction, exports, policy]
tech-stack:
  added: []
  patterns:
    - Private LiveView summary helpers for focused governance surfaces
    - Feature-gated contextual links rendered only when destination surfaces are enabled
key-files:
  created:
    - .planning/phases/186-detail-governance-and-export-surfaces/186-02-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/live/evidence_live.ex
    - lib/threadline/operator_surface/live/policy_redaction_live.ex
    - test/threadline/operator_surface/live/evidence_live_test.exs
    - test/threadline/operator_surface/live/policy_redaction_live_test.exs
    - test/threadline/operator_surface/policy_show_doc_contract_test.exs
key-decisions:
  - "Evidence back-to-latest navigation is history-mode only; subject-filter latest mode stays focused on the filtered proof list."
  - "Redaction all-clear copy is pinned as a source contract to avoid coupling LiveView tests to unrelated deployed trigger rows in the shared test database."
patterns-established:
  - "Governance summary helpers replace repeated trust rails and metric grids with one focused page-level decision unit."
  - "Contextual Coverage/Evidence/Export links are omitted unless their destination feature is enabled and the context is valid."
requirements-completed: [GOV-01, GOV-03]
duration: 12 min
completed: 2026-06-30
status: complete
---

# Phase 186 Plan 02: Evidence and Redaction Focused Workflow Controls Summary

Focused Evidence and Redaction governance summaries with gated export handoff and no runtime redaction destructive controls.

## Performance

| Metric | Value |
|--------|-------|
| Started | 2026-06-30T11:24:11Z |
| Completed | 2026-06-30T11:36:14Z |
| Duration | 12 min |
| Tasks completed | 2/2 |
| Status | complete |

## Accomplishments

- Replaced the Evidence trust rail/nav cluster with a single `Evidence workflow summary` helper while preserving subject grouping, proof-history navigation, and valid export handoff parameters.
- Updated Evidence empty-state copy to the Phase 186 focused-governance sentence and added negative coverage for invalid or disabled export handoffs.
- Replaced the Redaction trust rail and metric grid with one `Redaction policy posture` helper that summarizes configured rules, deployed triggers, drift, and unresolved follow-up.
- Preserved the deferred runtime-redaction boundary: Redaction remains read-only and does not expose destructive test-run, preview, apply, or redact controls.
- Gated Redaction contextual Coverage/Evidence links by their feature flags so disabled destination surfaces are omitted instead of linking to unavailable workflows.
- Added contract tests for Evidence, Redaction, and policy-show documentation behavior across the focused governance surfaces.

## Task Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | d3e8336a | Added failing Evidence workflow-summary, empty-copy, and export-handoff assertions. |
| 1 | 39229dcc | Implemented focused Evidence workflow summary and gated export handoff behavior. |
| 2 | 47bb45cd | Added failing Redaction posture, feature-gated action, and no-destructive-control assertions. |
| 2 | cf097ff7 | Implemented focused Redaction policy posture and feature-gated contextual actions. |
| 2 | 8c20b314 | Aligned focused-workflow assertions with history-mode navigation and stable all-clear copy contracts. |

## Files Modified

| File | Purpose |
|------|---------|
| `lib/threadline/operator_surface/live/evidence_live.ex` | Focused Evidence summary helper, exact empty-state copy, and preserved gated export handoff. |
| `lib/threadline/operator_surface/live/policy_redaction_live.ex` | Focused Redaction posture helper, feature-gated contextual actions, and removal of redundant trust rail/metric grid UI. |
| `test/threadline/operator_surface/live/evidence_live_test.exs` | Evidence focused-governance, empty-state, and export-handoff coverage. |
| `test/threadline/operator_surface/live/policy_redaction_live_test.exs` | Redaction posture, contextual action gating, and runtime-boundary coverage. |
| `test/threadline/operator_surface/policy_show_doc_contract_test.exs` | Policy-show documentation contract coverage for safe redaction placeholder language. |

## Decisions Made

- Evidence back-to-latest navigation remains history-mode only. Subject-filter latest mode stays focused on the filtered proof list instead of rendering a stale reset affordance.
- Redaction all-clear copy is pinned as a source contract, not as a shared-database LiveView state assertion, because unrelated deployed trigger rows can exist during concurrent test execution.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test Bug] Narrowed Evidence trust-rail absence assertion**

- **Found during:** Task 1 verification
- **Issue:** The negative assertion matched `tl-trust-rail` anywhere in the rendered HTML, which also caught inline style text rather than actual rendered trust-rail markup.
- **Fix:** Narrowed the assertion to rendered `class="tl-trust-rail"` markup so the test validates the removed UI surface without coupling to static CSS text.
- **Files modified:** `test/threadline/operator_surface/live/evidence_live_test.exs`
- **Commit:** 39229dcc

**2. [Rule 1 - Test Bug] Corrected stale focused-workflow expectations**

- **Found during:** Final plan verification
- **Issue:** One Evidence assertion expected history-mode back-to-latest navigation while testing subject-filter latest mode, and one Redaction all-clear LiveView assertion depended on shared test database trigger state.
- **Fix:** Kept back-to-latest coverage in history mode and moved exact all-clear copy coverage to a source contract assertion.
- **Files modified:** `test/threadline/operator_surface/live/evidence_live_test.exs`, `test/threadline/operator_surface/live/policy_redaction_live_test.exs`
- **Commit:** 8c20b314

## Auth Gates

None.

## Known Stubs

None. The safe redaction phrases `not available`, `not used`, and `mask placeholder` are intentional policy-documentation language covered by contract tests.

## Issues Encountered

- Concurrent phase executors temporarily left unrelated files uncompilable during narrow verification. The plan did not modify those files, and final verification passed after those concurrent commits landed.
- A detached temporary verification worktree hit build-cache/dependency artifact issues, so the authoritative verification was run in the main checkout after only the orchestrator-owned `.planning/STATE.md` remained dirty.

## Verification

| Command | Result |
|---------|--------|
| `mix test test/threadline/operator_surface/live/evidence_live_test.exs` | Baseline passed before RED: 10 tests, 0 failures. |
| `mix test test/threadline/operator_surface/live/evidence_live_test.exs` | RED failed as expected after Task 1 test commit. |
| `mix test test/threadline/operator_surface/live/policy_redaction_live_test.exs test/threadline/operator_surface/policy_show_doc_contract_test.exs` | RED failed as expected after Task 2 test commit. |
| `mix test test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs test/threadline/operator_surface/policy_show_doc_contract_test.exs` | Passed: 28 tests, 0 failures. |
| `mix compile --warnings-as-errors` | Passed. |

## Self-Check: PASSED

- Summary file exists: `.planning/phases/186-detail-governance-and-export-surfaces/186-02-SUMMARY.md`
- Required task commits exist: `d3e8336a`, `39229dcc`, `47bb45cd`, `cf097ff7`, `8c20b314`
- Final verification passed for the owned Evidence, Redaction, and policy-show contract tests.
- No `.planning/STATE.md` or `.planning/ROADMAP.md` updates were made by this plan executor.
