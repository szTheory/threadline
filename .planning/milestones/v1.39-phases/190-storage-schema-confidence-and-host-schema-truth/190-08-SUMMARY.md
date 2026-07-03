---
phase: 190-storage-schema-confidence-and-host-schema-truth
plan: 08
subsystem: policy-redaction
tags: [postgres, host-schema, redaction, liveview, mix-task]

requires:
  - phase: 190-storage-schema-confidence-and-host-schema-truth
    provides: 190-07 support.tickets trigger, coverage, verify, and continuity host-schema proof
provides:
  - selected host-schema redaction CLI via `mix threadline.policy.show --schema=NAME`
  - selected-schema redaction presenter grouping for schema-qualified configured table keys
  - PolicyRedactionLive host-schema selector with non-public Timeline links
affects: [phase-190, SCHEMA-04, redaction, operator-surface, timeline-links]

tech-stack:
  added: []
  patterns:
    - CoverageSchemas validates redaction CLI/UI host-schema input before catalog inspection
    - RedactionPresenter emits public shorthand labels for public rows and schema-qualified labels for non-public rows
    - PolicyRedactionLive reuses the existing tl-schema-picker control pattern from CoverageLive

key-files:
  created:
    - .planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-08-SUMMARY.md
  modified:
    - lib/mix/tasks/threadline.policy.show.ex
    - lib/threadline/policy/redaction_presenter.ex
    - lib/threadline/operator_surface/live/policy_redaction_live.ex
    - test/threadline/policy/redaction_presenter_test.exs
    - test/threadline/operator_surface/policy_show_mix_test.exs
    - test/threadline/operator_surface/policy_show_doc_contract_test.exs
    - test/threadline/operator_surface/live/policy_redaction_live_test.exs

key-decisions:
  - "`--schema` and `?schema=` remain host-schema selectors only; they are never passed to Threadline storage repo opts."
  - "Non-public redaction rows display as `support.tickets` while retaining `table_schema: support` and `table_name: tickets` for Timeline links."
  - "PolicyRedactionLive uses CoverageSchemas validation and the existing schema-picker control family instead of adding a new operator UI pattern."

patterns-established:
  - "Selected host-schema redaction: validate schema, fetch deployed triggers for that host schema, normalize configured keys by host schema, then render selected-schema rows."
  - "Non-public policy row navigation: public rows link with `table=NAME`; non-public rows link with `table_schema=SCHEMA&table=NAME`."

requirements-completed: [SCHEMA-04]

duration: 9 min
completed: 2026-07-01
status: complete
---

# Phase 190 Plan 08: Selected Host-Schema Redaction Summary

**Redaction inspection now supports selected non-public host schemas in the CLI, shared presenter, and operator LiveView without changing Threadline-owned storage schema behavior.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-07-01T22:36:47Z
- **Completed:** 2026-07-01T22:45:39Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added `mix threadline.policy.show --schema=NAME` with CoverageSchemas edge validation and JSON `"schema": "support"` output.
- Updated `RedactionPresenter` to filter configured redaction keys by selected host schema, matching `support.tickets` config against deployed `tickets` rows from the `support` schema.
- Added `PolicyRedactionLive` schema selection, invalid-schema handling, selected host-schema posture copy, and Timeline links that preserve `table_schema=support&table=tickets`.
- Preserved no-sample-values behavior and read-only operator posture.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: selected redaction schema tests** - `5e670fa5` (test)
2. **Task 1 GREEN: selected redaction schema CLI and presenter** - `4d886155` (feat)
3. **Task 2 RED: redaction LiveView selected-schema tests** - `113c2d64` (test)
4. **Task 2 GREEN: redaction LiveView host schema selection** - `4b5d9789` (feat)

## Files Created/Modified

- `.planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-08-SUMMARY.md` - Plan completion summary.
- `lib/mix/tasks/threadline.policy.show.ex` - Adds `--schema=NAME`, host-schema validation, selected-schema human copy, and selected-schema JSON output.
- `lib/threadline/policy/redaction_presenter.ex` - Normalizes configured/deployed redaction rows by selected host schema and exposes row schema/table identity for callers.
- `lib/threadline/operator_surface/live/policy_redaction_live.ex` - Adds schema picker, invalid schema state, selected host-schema report loading, and non-public Timeline links.
- `test/threadline/policy/redaction_presenter_test.exs` - Locks schema-qualified configured key matching and public shorthand behavior.
- `test/threadline/operator_surface/policy_show_mix_test.exs` - Locks CLI `--schema=support`, invalid schema validation, storage-schema separation, and JSON contract.
- `test/threadline/operator_surface/policy_show_doc_contract_test.exs` - Locks `--schema` usage/help contract.
- `test/threadline/operator_surface/live/policy_redaction_live_test.exs` - Locks LiveView selected schema, schema picker, invalid schema state, Timeline links, and prefix-aware test cleanup.

## Decisions Made

- Followed the Phase 190 host/storage separation: selected host schema controls catalog inspection only; storage schema remains governed by Threadline configuration and repo opts.
- Reused `CoverageSchemas` rather than creating a separate policy-redaction schema validator.
- Kept the stable JSON row shape unchanged while adding row schema/table metadata for internal presenter consumers.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Repaired PolicyRedactionLive test fixture cleanup after owned-prefix removal**
- **Found during:** Task 2 RED run
- **Issue:** Existing `policy_redaction_live_test.exs` setup deleted Threadline-owned schemas without `StorageSchema.repo_opts/1`, which failed after earlier Phase 190 commits removed fixed owned `@schema_prefix` values.
- **Fix:** Updated the touched LiveView test setup to call `Repo.delete_all/2` with `StorageSchema.repo_opts()`.
- **Files modified:** `test/threadline/operator_surface/live/policy_redaction_live_test.exs`
- **Verification:** `mix test test/threadline/operator_surface/live/policy_redaction_live_test.exs`
- **Committed in:** `113c2d64`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The fix was required for the Task 2 RED/GREEN loop to exercise the planned LiveView behavior. It did not change production behavior or expand scope.

## Issues Encountered

None remaining.

## Known Stubs

None - stub scan found only intentional redaction placeholders and locked `not available` / `not used` UI labels.

## Threat Flags

None - new CLI/UI schema input and Timeline link surfaces were already in the plan threat model and were mitigated with CoverageSchemas validation plus selected-schema URL preservation.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix compile --warnings-as-errors` - PASSED
- `mix test test/threadline/policy/redaction_presenter_test.exs test/threadline/policy/redaction_presenter_catalog_test.exs test/threadline/operator_surface/policy_show_mix_test.exs test/threadline/operator_surface/policy_show_doc_contract_test.exs` - PASSED (31 tests, 0 failures)
- `mix test test/threadline/operator_surface/live/policy_redaction_live_test.exs` - PASSED (9 tests, 0 failures)
- `mix format --check-formatted` - PASSED

## TDD Gate Compliance

- Task 1 RED failed on missing `build_report/3`, public-only `policy.show`, missing `--schema` docs, and missing schema validation; GREEN passed after presenter and CLI support were added.
- Task 2 RED failed on missing PolicyRedactionLive schema picker, invalid-schema state, and support-schema Timeline links; GREEN passed after selected-schema LiveView loading and links were implemented.

## Next Phase Readiness

Plan 190-08 completes selected host-schema redaction inspection. Plan 190-09 can build on the same `table_schema` / `table_name` presenter shape and selected-host-schema link contract for Timeline, filters, row history, and docs.

## Self-Check: PASSED

- Found key files: `lib/mix/tasks/threadline.policy.show.ex`, `lib/threadline/policy/redaction_presenter.ex`, `lib/threadline/operator_surface/live/policy_redaction_live.ex`, `test/threadline/policy/redaction_presenter_test.exs`, `test/threadline/operator_surface/policy_show_mix_test.exs`, `test/threadline/operator_surface/policy_show_doc_contract_test.exs`, `test/threadline/operator_surface/live/policy_redaction_live_test.exs`
- Found task commits: `5e670fa5`, `4d886155`, `113c2d64`, `4b5d9789`
- Final production/test worktree was clean before summary creation.

---
*Phase: 190-storage-schema-confidence-and-host-schema-truth*
*Completed: 2026-07-01*
