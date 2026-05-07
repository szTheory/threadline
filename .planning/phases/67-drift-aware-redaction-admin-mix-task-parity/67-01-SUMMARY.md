---
phase: 67
plan: 01
subsystem: redaction-drift-reconciliation
tags:
  - elixir
  - threadline
  - policy
  - redaction
  - pg-proc
  - drift
requires: []
provides:
  - "Threadline.Capture.TriggerCaptureConfig shared validated trigger-capture loader"
  - "Threadline.Policy.RedactionPresenter shared fail-closed reconciliation over configured policy and deployed trigger SQL"
  - "Focused parser/reconciliation tests plus repo-backed pg_proc introspection coverage"
affects:
  - "mix threadline.gen.triggers now reuses the shared trigger-capture config loader"
  - "Phase 67 LiveView and Mix-task surfaces can consume one canonical grouped redaction report"
tech-stack:
  added: []
  patterns:
    - "Application.get_env(:threadline, :trigger_capture) normalized once in a pure-stdlib capture module"
    - "pg_trigger -> pg_proc -> pg_language catalog query through Ecto.Adapters.SQL"
    - "fail-closed parsing limited to known TriggerSQL fragments"
    - "canonical grouped ordering: drift_detected / could_not_introspect / config_matches_deployed"
key-files:
  created:
    - "lib/threadline/capture/trigger_capture_config.ex"
    - "lib/threadline/policy/redaction_presenter.ex"
    - "test/threadline/policy/redaction_presenter_test.exs"
    - "test/threadline/policy/redaction_presenter_catalog_test.exs"
  modified:
    - "lib/mix/tasks/threadline.gen.triggers.ex"
decisions:
  - "Kept the shared reconciliation layer Phoenix-free so Mix and LiveView can consume the same facts without optional-dep gates"
  - "Parsed only Threadline-owned redaction fragments from TriggerSQL and treated any unsupported catalog shape as could_not_introspect"
  - "Used one minimal adjacent edit in mix threadline.gen.triggers to switch trigger generation onto the shared loader"
metrics:
  duration: ~22 min
  completed: 2026-05-07T21:53:00Z
  tasks: 2
  files: 5
  tests_added: 13
---

# Phase 67 Plan 01: Shared Redaction Reconciliation Core Summary

Phase 67's shared redaction fact layer now exists in two pure Elixir modules. `Threadline.Capture.TriggerCaptureConfig` is the single loader for `config :threadline, :trigger_capture`; it normalizes table entries and re-validates every configured table through `Threadline.Capture.RedactionPolicy.validate!/1`. `Mix.Tasks.Threadline.Gen.Triggers` now consumes that shared loader instead of maintaining its own config parsing path. `Threadline.Policy.RedactionPresenter` builds the canonical report for downstream Mix and LiveView surfaces: summary counts, per-table rows, and grouped output ordered as `:drift_detected`, `:could_not_introspect`, then `:config_matches_deployed`, with alphabetical ordering inside each section.

The deployed-policy parser is intentionally narrow and fail-closed. It reads PostgreSQL trigger metadata via `pg_trigger`, `pg_class`, `pg_namespace`, `pg_proc`, and `pg_language`, trusts only `plpgsql` functions named like `threadline_capture_changes*`, and recognizes only the Threadline-generated fragments for excluded columns, masked columns, and changed-from masking. Missing configured-table triggers report `:drift_detected`; malformed, unsupported, or ambiguous SQL reports `:could_not_introspect` with the rerun hint from the phase context. The report never carries sample values, only column names and placeholder metadata.

## Deviations from Plan

None - plan executed exactly as written.

## Tasks -> Commits

| Task | Description | Commit(s) |
| ---- | ----------- | --------- |
| 1 (RED) | Failing config-loader, parser, diff, ordering, and catalog tests | `0939554` |
| 1-2 (GREEN) | Shared loader, shared presenter, and trigger-generation reuse | `be1dc72` |

## Plan-Level Verification Results

| Check | Status |
| ----- | ------ |
| `mix test test/threadline/policy/redaction_presenter_test.exs test/threadline/policy/redaction_presenter_catalog_test.exs` | 13 tests / 0 failures |
| `mix test test/threadline/capture/trigger_redaction_test.exs` | 3 tests / 0 failures |
| `mix verify.compile_no_optional` | clean |

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: `lib/threadline/capture/trigger_capture_config.ex`
- FOUND: `lib/threadline/policy/redaction_presenter.ex`
- FOUND: `test/threadline/policy/redaction_presenter_test.exs`
- FOUND: `test/threadline/policy/redaction_presenter_catalog_test.exs`
- FOUND commit: `0939554`
- FOUND commit: `be1dc72`
