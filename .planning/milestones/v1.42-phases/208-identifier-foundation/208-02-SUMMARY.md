---
phase: 208-identifier-foundation
plan: 02
subsystem: capture
status: complete
tags: [identifiers, errors, storage-schema, NAME-01]
requires: ["208-01"]
provides:
  - "Threadline.StorageSchema.validate_identifier!/2,3 (@doc false) with :storage_schema | :host_schema | :host_table | :derived roles"
  - "role-aware parse_table_identifier/1 errors (host table / host schema, value, byte count, original input)"
affects: ["208-05 (Mix task wraps the new message and uses :derived)"]
tech-stack:
  added: []
  patterns: ["role label map + single raise template; storage schema role keeps legacy text via its own clause"]
key-files:
  created: []
  modified:
    - lib/threadline/storage_schema.ex
    - lib/threadline/continuity.ex
    - lib/threadline/policy/redaction_presenter.ex
    - test/threadline/storage_schema_test.exs
decisions:
  - "validate!/1 is a one-line delegate to validate_identifier!(value, :storage_schema); the :storage_schema clause of invalid_identifier!/3 holds the legacy text byte-for-byte"
  - "Non-binary invalid values (nil, booleans, other terms) get the role prefix without an 'is N bytes;' clause"
  - "The (from ...) echo uses the trimmed original input and is dropped when it equals the offending segment"
metrics:
  duration: "~5 min"
  completed: 2026-09-25
actuals:
  tokens: 2400
  tasks: 2
  commits: 3
plan_head_before: d0ed667205811e00d715360be945d91917b26f24
---

# Phase 208 Plan 02: Role-accurate identifier errors Summary

`StorageSchema.validate_identifier!/2,3` now names the role, the value and its byte count. A 70-byte host table raises `Threadline host table "aaa…" (from "public.aaa…") is 70 bytes; it must be a PostgreSQL identifier matching ^[A-Za-z_][A-Za-z0-9_]*$ and at most 63 bytes`, not an error that blames the storage schema. `validate!/1` keeps its existing text exactly.

## Tasks

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 (RED) | Failing role-accurate error tests | 7499d9db | test/threadline/storage_schema_test.exs |
| 1 (GREEN) | validate_identifier!/2,3 wired through parse_table_identifier/1 | 31dfcc2c | lib/threadline/storage_schema.ex |
| 2 | Continuity and RedactionPresenter use the :host_schema role | 07c8c677 | lib/threadline/continuity.ex, lib/threadline/policy/redaction_presenter.ex, test/threadline/storage_schema_test.exs |

## Verification

- RED: 8 of the 9 new tests failed before the implementation. The validate!/1 byte-identity test passed from the start, as intended, because it pins the existing text.
- `mix test test/threadline/storage_schema_test.exs test/threadline/capture/trigger_rerun_test.exs`: 29 tests, 0 failures. The existing `~r/at most 63 bytes/` assertion still passes.
- Targeted Task 2 command: 42 tests, 0 failures.
- Full `mix test`: 1854 tests, 0 failures, 1 excluded.
- `mix compile --warnings-as-errors --force` is clean. `mix credo --strict` on storage_schema.ex found no issues. `mix format --check-formatted` is clean.
- Tracer gate: the automated `<verify>` passed end to end, so the plan continued to Task 2.

## Deviations from Plan

**1. Acceptance grep count is 3, not 2.** `grep -cE "validate_identifier!\((table|schema), :host_(table|schema), value\)"` prints 3 because `:host_table` appears in two branches, the bare `NAME` branch and the `SCHEMA.NAME` branch, and `:host_schema` in one. The plan's intent was that both roles receive the original input, and they do. Nothing was changed to make the count match.

Task 2, step 3: no existing test in continuity_brownfield_test.exs or redaction_presenter_test.exs asserted the old "storage schema" wording, so no tests were changed.

**2. NAME-01 left Pending in REQUIREMENTS.md.** `requirements.mark-complete NAME-01` ticked it, but this plan delivers only the library half of the error message. Plans 04 (naming) and 05 (Mix task) are still needed, so I reverted the tick.

Otherwise the plan was executed as written.

## Known Stubs

None.

## Self-Check: PASSED

- lib/threadline/storage_schema.ex, lib/threadline/continuity.ex, lib/threadline/policy/redaction_presenter.ex and test/threadline/storage_schema_test.exs all exist.
- Commits 7499d9db, 31dfcc2c and 07c8c677 are present in `git log`.
