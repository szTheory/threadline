---
phase: 200-public-surface
plan: 03
subsystem: api
tags: [storage, export-queue, behaviours, optional-callbacks, phoenix]
requires:
  - phase: 200-public-surface
    provides: source-derived public inventories and the no-path storage adapter RED regression
provides:
  - compatibility-grade storage and export-queue extension documentation
  - capability-aware export delivery for storage adapters without optional path/1
affects: [200-04, 200-07, 200-08, 200-09, 200-10, 200-14]
actuals:
  tokens: 4613
  tasks: 3
  commits: 2
plan_head_before: a57b26e63acc81033bda34b2af21544fa0044d86
tech-stack:
  added: []
  patterns: [consumer-first behaviour contracts, optional callback capability checks, shared remote-delivery fallback]
key-files:
  created: []
  modified:
    - lib/threadline/storage.ex
    - lib/threadline/storage/local.ex
    - lib/threadline/storage/s3.ex
    - lib/threadline/export_queue.ex
    - lib/threadline/export_queue/task_adapter.ex
    - lib/threadline/export_queue/oban.ex
    - lib/threadline/operator_surface/controllers/export_controller.ex
    - test/threadline/operator_surface/controllers/export_controller_test.exs
key-decisions:
  - "Confirmed locked D-02 in auto-mode: :storage_adapter is a supported extension point whose portable put/2 input is binary content; Local file-path detection remains adapter-specific."
  - "Optional path/1 dispatch uses a capability check and the existing download_url/2 path, preserving adapter-module options, export expiry, and all established delivery outcomes."
patterns-established:
  - "Public behaviour docs lead with host configuration, callback outcomes, startup failure semantics, and optional-dependency boundaries."
  - "Optional adapter capabilities are tested before invocation and converge on the same existing fallback used by explicit :not_local results."
requirements-completed: [SURFACE-07]
coverage:
  - id: D1
    description: "Storage and export-queue behaviours now document supported callbacks, built-ins, configuration, startup failures, optional dependencies, and custom-adapter responsibilities."
    requirement: SURFACE-07
    verification:
      - kind: integration
        ref: "mix test test/threadline/public_surface_contract_test.exs --only public_inventory"
        status: pass
      - kind: integration
        ref: "mix test test/threadline/public_surface_contract_test.exs --only public_doc_refs_extensions"
        status: pass
      - kind: other
        ref: "mix compile --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "A conforming storage adapter without optional path/1 now redirects through download_url/2 with module-keyed options and remaining expiry intact."
    requirement: SURFACE-07
    verification:
      - kind: integration
        ref: "test/threadline/operator_surface/controllers/export_controller_test.exs#delivers remotely when a conforming storage adapter omits optional path/1"
        status: pass
      - kind: integration
        ref: "mix test test/threadline/operator_surface/controllers/export_controller_test.exs"
        status: pass
    human_judgment: false
duration: 4min
completed: 2026-09-12
status: complete
---

# Phase 200 Plan 03: Storage and Queue Extension Contract Summary

**Public storage and export-queue behaviours now explain the complete adopter contract, while capability-aware delivery supports adapters that omit optional `path/1`.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-09-12T07:46:24Z
- **Completed:** 2026-09-12T07:51:22Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Confirmed the already-locked D-02 compatibility commitment through auto-mode's workflow-valid first option without reopening storage architecture.
- Reframed storage and queue documentation around consumer configuration, portable callback semantics, built-in adapters, early startup failures, and optional dependencies.
- Made optional `path/1` genuinely optional during export delivery and proved that both adapter-module options and the job's remaining expiry reach `download_url/2`.

## Task Commits

1. **Task 1: Confirm execution of the locked storage compatibility commitment** — auto-selected `confirm D-02`; no file commit required.
2. **Task 2: Publish the confirmed storage and queue extension contract** — `9c19543e` (docs)
3. **Task 3: Honor the optional storage path callback during export delivery** — `8577c6f9` (feat)

## Files Created/Modified

- `lib/threadline/storage.ex` — portable binary-content behaviour, host configuration, startup validation, and optional `path/1` contract.
- `lib/threadline/storage/local.ex` — single-node suitability, filesystem outcomes, and Local-only regular-file-path convenience.
- `lib/threadline/storage/s3.ex` — optional dependency boundary, module-keyed options, presigned delivery, and remote failure semantics.
- `lib/threadline/export_queue.ex` — supported queue seam and custom-worker responsibility for the orchestrator lifecycle.
- `lib/threadline/export_queue/task_adapter.ex` — in-process durability tradeoff, supervision requirements, and option propagation.
- `lib/threadline/export_queue/oban.ex` — durable queue configuration, validation, and worker delegation contract.
- `lib/threadline/operator_surface/controllers/export_controller.ex` — capability-aware local-or-remote delivery resolution.
- `test/threadline/operator_surface/controllers/export_controller_test.exs` — green no-path regression with adapter-option and expiry proof.

## Decisions Made

- Auto-mode selected the checkpoint's first documented option, `confirm D-02`, because both `_auto_chain_active` and `auto_advance` were enabled and the gate was `blocking`, not `blocking-human`.
- Kept the repair at the existing adapter boundary: no callback, arity, alias, configuration namespace, authorization rule, status code, or cache policy changed.

## TDD Evidence

- **RED:** The regression committed by Plan 200-01 (`98758884`) was rerun before implementation. The named test failed at its behavioral assertion after capturing `UndefinedFunctionError` for `NoPathStorageStub.path/1`; 1 target failed and 23 unrelated tests were excluded.
- **GREEN:** After the capability check and red-tag removal, the complete controller suite passed with 24 tests and 0 failures.
- **REFACTOR:** The `:not_local` and callback-absent branches share one private `resolve_download_url/3` path; no separate refactor commit was necessary.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The plan's trailing `-x` is not supported by the pinned Mix 1.17.3 task runner, as already established in Plans 200-01 and 200-02. Each specified test selection was run with the same path and tag after removing only that unsupported flag; shell fail-fast behavior and all intended coverage were preserved.

## Known Stubs

None.

## Threat Flags

None. The change adds no endpoint, authorization path, schema, external file-access primitive, or new trust boundary; it applies the planned capability check at the existing adapter boundary.

## User Setup Required

None.

## Next Phase Readiness

- Plan 200-04 can classify and group the now explicit extension modules without inventing a new public API.
- Later operator and guide plans can reference the confirmed storage/queue semantics and the canonical configuration guide.
- No blocker remains for this plan.

## Self-Check: PASSED

- All eight modified files exist and contain the committed changes.
- Both plan commits exist after the persisted `plan_head_before` ledger base; the measured count is 2.
- Public inventory, extension references, compile warnings, formatting, and the complete 24-test controller suite pass on the committed tree.
- Coverage metadata validates with two fully automated deliverables and no schema errors.

---
*Phase: 200-public-surface*
*Completed: 2026-09-12*
