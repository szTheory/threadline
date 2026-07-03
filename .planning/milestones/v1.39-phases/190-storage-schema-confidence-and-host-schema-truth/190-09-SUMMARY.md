---
phase: 190-storage-schema-confidence-and-host-schema-truth
plan: 09
plan_name: Host Schema Through Timeline, Export, Row History, and Docs
status: complete
subsystem: operator-surface
tags:
  - storage-schema
  - host-schema
  - timeline
  - coverage
  - row-history
requirements:
  - SCHEMA-04
dependency_graph:
  requires:
    - 190-06
    - 190-08
  provides:
    - SCHEMA-04
  affects:
    - lib/threadline/operator_surface/live/timeline_live.ex
    - guides/operator-surface.md
    - guides/domain-reference.md
tech_stack:
  added: []
  patterns:
    - Phoenix LiveView
    - ExUnit LiveView tests
    - doc-contract tests
    - TDD red/green commits
key_files:
  created:
    - .planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-09-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/live/timeline_live.ex
    - guides/operator-surface.md
    - guides/domain-reference.md
    - test/threadline/operator_surface/live/timeline_live_test.exs
    - test/threadline/operator_surface/coverage_doc_contract_test.exs
    - test/threadline/operator_surface/policy_show_doc_contract_test.exs
decisions:
  - Timeline renders `table_schema` as "host schema" so operators do not confuse audited host schemas with Threadline's storage schema.
  - Non-public row-history links require exact schema-qualified `schemas:` keys such as `support.tickets`; public rows keep the existing bare-table shorthand.
metrics:
  duration: 9m 17s
  completed_at: 2026-07-01T23:00:15Z
  tasks_completed: 2
  files_modified: 6
---

# Phase 190 Plan 09: Host Schema Through Timeline, Export, Row History, and Docs Summary

Timeline, export, row-history, and docs now keep host-table schema identity separate from Threadline storage schema.

## Completed Tasks

| Task | Description | Commit |
| ---- | ----------- | ------ |
| 1 | Preserved non-public host schema through Timeline filters/export links and clarified active-filter copy. | 05b015da, ff54af7d |
| 2 | Added schema-qualified row-history routing plus docs/doc-contracts for `support.tickets` workflows. | 55592e19, b65bd65e |

## Implementation Notes

- Added Timeline tests proving `table_schema=support&table=tickets` filters out public rows, keeps export links canonical, and queues export jobs with the host schema preserved.
- Updated Timeline active-filter and validation wording from "schema" to "host schema".
- Added row-history test coverage for a non-public duplicate table using `schemas: %{"support.tickets" => MyApp.Support.Ticket}`.
- Updated row-history link generation so public rows keep `/rows/tickets/:id`, while non-public rows route through `/rows/support.tickets/:id` only when the schema-qualified mapping exists.
- Documented the storage schema versus host schema happy path: `storage_schema: "audit"`, `mix threadline.install`, `mix threadline.gen.triggers --tables support.tickets`, coverage verification, policy drift inspection, and Timeline filtering.

## Verification

| Command | Result |
| ------- | ------ |
| `mix compile --warnings-as-errors` | Passed |
| `mix test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/live/timeline_live_test.exs` | Passed: 66 tests, 0 failures |
| `mix test test/threadline/operator_surface/coverage_doc_contract_test.exs test/threadline/operator_surface/policy_show_doc_contract_test.exs` | Passed: 46 tests, 0 failures |
| `mix format --check-formatted` | Passed |

## Deviations from Plan

None - plan executed against current HEAD. `FilterParams` and background export already preserved `table_schema`; task 1 locked that behavior with tests and only needed host-schema copy in `TimelineLive`.

## Auth Gates

None.

## Known Stubs

None. Stub scan found only existing placeholder wording in redaction documentation/tests and UI placeholder attributes; no new functional stubs were introduced.

## Threat Flags

None. No new endpoints, auth paths, file access patterns, trust-boundary schema changes, or network surfaces were introduced.

## Self-Check: PASSED

- Found modified source/docs/tests listed in `key_files`.
- Found task commits: `05b015da`, `ff54af7d`, `55592e19`, `b65bd65e`.
- Confirmed no accidental tracked file deletions in task commits.
- Confirmed working tree was clean before summary creation.
