---
phase: 186-detail-governance-and-export-surfaces
plan: 04
subsystem: operator-surface
tags:
  - exports
  - liveview
  - download-authorization
  - feature-gates
  - gov-01
  - gov-02
dependency_graph:
  requires:
    - Phase 186 UI-SPEC export affordance contract
    - Phase 186 validation lane for exports
    - Existing ExportController and ExportAuthPlug enforcement
  provides:
    - Focused Exports workflow summary
    - Real completed-export HTTP download links
    - Status-only affordances for non-ready export jobs
    - Targeted controller/auth/gating proof for direct downloads
  affects:
    - lib/threadline/operator_surface/live/export_status_live.ex
    - test/threadline/operator_surface/live/export_status_live_test.exs
    - test/threadline/operator_surface/controllers/export_controller_test.exs
    - test/threadline/operator_surface/export_auth_plug_test.exs
    - test/threadline/operator_surface/gating_test.exs
    - test/threadline/operator_surface/exports_doc_contract_test.exs
tech_stack:
  added: []
  patterns:
    - Phoenix LiveView links for completed downloads
    - Controller-enforced export download authorization
    - Router-route inspection for feature-gated exports
key_files:
  created:
    - .planning/phases/186-detail-governance-and-export-surfaces/186-04-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/live/export_status_live.ex
    - test/threadline/operator_surface/live/export_status_live_test.exs
    - test/threadline/operator_surface/controllers/export_controller_test.exs
    - test/threadline/operator_surface/export_auth_plug_test.exs
    - test/threadline/operator_surface/gating_test.exs
    - test/threadline/operator_surface/exports_doc_contract_test.exs
decisions:
  - Completed exports use real HTTP links while direct download authorization remains in ExportController and ExportAuthPlug.
  - Disabled Exports route proof inspects router output directly instead of depending on endpoint error rendering.
requirements-completed:
  - GOV-01
  - GOV-02
metrics:
  started: 2026-06-30T11:24:44Z
  completed: 2026-06-30T11:36:25Z
  duration: 11m41s
  tasks: 2
  files_changed: 7
status: complete
---

# Phase 186 Plan 04: Exports Workflow and Download Controls Summary

Phase 186 GOV-01 and GOV-02 export surfaces now present one focused workflow summary, render completed export downloads as real HTTP links, show honest status text for unavailable jobs, and keep direct download enforcement in the controller/auth layer.

## Task Results

| Task | Name | Commit | Result |
| ---- | ---- | ------ | ------ |
| 1 | Correct Exports workflow focus and job affordances | e51e0a8c, cc6ec295 | Added RED coverage, then implemented focused workflow copy, real completed-download links, and status-only non-ready jobs. |
| 2 | Preserve download authorization and feature-gate enforcement | a5429111 | Added targeted controller, auth-plug, and feature-gate tests proving the UI is not the enforcement boundary. |

## What Changed

- `ExportStatusLive` now renders a single workflow summary below the Exports page header.
- Completed export jobs render `Download export` as a real Phoenix link to `/audit/exports/download/:job_id` without disabled-looking attributes.
- Queued, processing, expired, failed, and unavailable jobs render status text rather than inactive links.
- Timeline queue controls remain valid-context-only, with existing server-side validation preserved for forged events.
- Direct HTTP export downloads are covered for missing actor assignment, actor ownership, readiness/status, expiry, storage availability, and auth-plug denial telemetry.
- Exports-disabled routing now has proof that export controls are omitted and direct HTTP export routes are not mounted.

## Verification

Commands run:

```bash
mix test test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/exports_doc_contract_test.exs
mix test test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/gating_test.exs
mix test test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/gating_test.exs test/threadline/operator_surface/exports_doc_contract_test.exs
mix compile --warnings-as-errors
```

Results:

- Task 1 RED run failed as expected on the new download-affordance assertions before implementation.
- Task 1 verification passed in a clean temporary worktree: 50 tests, 0 failures.
- Task 2 verification passed in a clean temporary worktree: 34 tests, 0 failures.
- Full Phase 186 exports lane passed at HEAD `5f0bb335`: 84 tests, 0 failures.
- `mix compile --warnings-as-errors` passed at HEAD `5f0bb335`.

The direct main checkout had unrelated dirty Phase 186 files from parallel executors, so automated verification was run in `/tmp/threadline-186-04-verify` with the repository `deps` and `_build` linked in.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Repaired stale export doc-contract regex**

- **Found during:** Task 1 verification
- **Issue:** `exports_doc_contract_test.exs` no longer matched the current multi-line `<.link>` form where the `download` attribute appears before `class`.
- **Fix:** Updated the contract regex to match the existing LiveView link shape without changing routes, controller actions, or public component APIs.
- **Files modified:** `test/threadline/operator_surface/exports_doc_contract_test.exs`
- **Commit:** cc6ec295

## Auth Gates

None.

## Known Stubs

None. The stub scan found only expected test assertions and existing filter helper empty-value handling; no placeholder UI or unwired data source was introduced.

## Threat Flags

None. This plan changed an existing LiveView and tests only; it did not add network endpoints, auth paths, file access patterns, schema changes, dependencies, or route churn.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/186-detail-governance-and-export-surfaces/186-04-SUMMARY.md`.
- Task commits exist: `e51e0a8c`, `cc6ec295`, `a5429111`.
- Owned files only were changed for plan code/tests; shared `.planning/STATE.md` and `.planning/ROADMAP.md` were not updated.
