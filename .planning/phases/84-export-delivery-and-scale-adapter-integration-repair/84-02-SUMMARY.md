---
phase: 84-export-delivery-and-scale-adapter-integration-repair
plan: 02
subsystem: adapter-integration
tags: [exports, oban, s3, startup-validation, docs]
dependency_graph:
  requires: [phase-84 plan-01 backend-aware delivery]
  provides: [startup adapter validation, configurable oban targeting, stable s3 failure posture, repaired adapter docs]
  affects: [ADAPT-01, ADAPT-02, example-app guidance, integration docs]
tech_stack:
  added: []
  patterns: [startup-static-validation, host-owned-oban-runtime, stable-adapter-errors]
key_files:
  created:
    - test/threadline/application_test.exs
  modified:
    - config/config.exs
    - config/test.exs
    - lib/threadline/application.ex
    - lib/threadline/export_queue/oban.ex
    - lib/threadline/storage/s3.ex
    - examples/threadline_phoenix/README.md
    - guides/operator-surface.md
    - guides/integration-contracts.md
    - test/threadline/export_queue/oban_test.exs
    - test/threadline/storage/s3_test.exs
    - test/threadline/example_phoenix_readme_contract_test.exs
    - test/threadline/integration_contracts_doc_contract_test.exs
    - test/threadline/operator_surface_doc_contract_test.exs
decisions_made:
  - Validate configured storage and queue adapters during `Threadline.Application` startup only for static truths the library can honestly know.
  - Keep Oban host-owned by validating config and targeting a configured instance/queue rather than supervising Oban from the library.
  - Normalize S3 and Oban failures into stable human-readable messages suitable for operator surfaces and support logs.
requirements-completed: [ADAPT-01, ADAPT-02]
metrics:
  duration: inline-execution
  tasks_completed: 3
  tasks_total: 3
---

# Phase 84 Plan 02: Adapter Integration Summary

## Completed Work

1. Added application-level adapter validation so `Threadline.Application` now runs configured storage and queue adapter `init/1` callbacks when a repo exists and surfaces actionable startup errors for static misconfiguration.
2. Upgraded `Threadline.ExportQueue.Oban` and `Threadline.Storage.S3` to support configured-path integration more truthfully: Oban now honors configured targeting and emits stable enqueue errors, while S3 validates bucket config and normalizes presign/storage failures.
3. Aligned defaults and public guidance with the repaired contract by making the default adapters explicit in config and documenting the one actor-owned download action plus host-owned Oban supervision in the example and guides.

## Verification

- `mix test test/threadline/application_test.exs test/threadline/export_queue/oban_test.exs test/threadline/storage/s3_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs --max-failures 1`
- `mix verify.compile_no_optional`

## Deviations From Plan

None in scope. The runtime and doc updates stayed inside startup validation, configured-path adapter truth, and host-owned integration guidance.
