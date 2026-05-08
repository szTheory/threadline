---
phase: 69
plan: "69-01"
subsystem: docs
tags:
  - integration-contracts
  - operator-surface
  - exdoc
key_files:
  created:
    - guides/integration-contracts.md
  modified:
    - README.md
    - guides/operator-surface.md
    - mix.exs
    - test/threadline/readme_doc_contract_test.exs
    - test/threadline/operator_surface_doc_contract_test.exs
decisions:
  - "Publish one canonical integration-contract guide instead of introducing a new adapter abstraction."
  - "Treat operator-surface LiveView auth and HTTP export auth as one documented contract with host-owned auth semantics."
  - "Correct public callback examples to the actual 1-arity callable shapes the code invokes."
---

# Phase 69 Plan 69-01 Summary

Published the canonical breadth-contract guide for Threadline's existing
integration seams and wired narrow discovery pointers from the README,
operator-surface guide, and ExDoc.

## Completed Tasks

| Task | Outcome | Commit |
| --- | --- | --- |
| 1 | Added `guides/integration-contracts.md` covering `Threadline.Plug`, `Threadline.Job`, `Threadline.Integrations.*`, and operator-surface auth/export composition. | `fd7c4ec` |
| 2 | Linked the new guide from README, operator-surface docs, and ExDoc extras; corrected stale tuple-style callback examples and matching doc-contract assertions. | `488c683` |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Updated stale doc-contract fixtures**
- **Found during:** Task 2
- **Issue:** Existing doc-contract tests still encoded tuple-style callback examples that the plan explicitly required replacing with the real 1-arity callable shapes.
- **Fix:** Updated the focused README and operator-surface doc-contract assertions to match the corrected public examples.
- **Files modified:** `test/threadline/readme_doc_contract_test.exs`, `test/threadline/operator_surface_doc_contract_test.exs`
- **Commit:** `488c683`

## Verification

- `rg -n "Threadline\\.Plug|Threadline\\.Job|Threadline\\.Integrations|authorize_fn|export_authorize_fn|capture-only|host-owned" guides/integration-contracts.md`
  Result: matched all required contract surfaces and wording anchors in `guides/integration-contracts.md`.
- `rg -n "integration-contracts\\.md" README.md guides/operator-surface.md mix.exs`
  Result: matched README pointers, operator-surface pointer, and ExDoc extras wiring.
- `mix test test/threadline/readme_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs`
  Result: `18 tests, 0 failures`.
- `mix docs`
  Result: succeeded and generated docs. Existing ExDoc warnings remain in out-of-scope files and modules, including `guides/adoption-pilot-backlog.md`, `guides/audit-indexing.md`, and several long-standing type/reference warnings in existing library docs.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check

PASSED
