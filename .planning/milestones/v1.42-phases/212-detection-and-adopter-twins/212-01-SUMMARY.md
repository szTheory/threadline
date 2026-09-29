---
phase: 212-detection-and-adopter-twins
plan: 01
subsystem: database
tags: [postgres, ecto, triggers, telemetry, health-checks]

requires:
  - phase: 210-pk-agnostic-capture
    provides: Naming prefixes (trigger_name/1, function_name/1), TriggerSQL DO-block trigger installation
  - phase: 211-read-side-agreement
    provides: composite-id read-side conventions used by the twins (not consumed directly by this plan)
provides:
  - "Threadline.Health.Finding public struct (code, severity, schema, table, message, details)"
  - "Threadline.Health.trigger_findings/1 public API"
  - ":capture_trigger_disabled and :duplicate_capture_trigger finding codes"
  - "Threadline.Telemetry.emit_findings_checked/2 ([:threadline, :health, :findings_checked])"
  - "trigger_coverage/1 excludes disabled/replica-only triggers (D-05), CHANGELOG Breaking changes entry"
  - "zero-grant NOLOGIN role proof for trigger_findings/1 (PgBouncer/non-owner safety half)"
affects: [212-02, 212-03, 212-04, 213-upgrade-guide]

actuals:
  tokens: 8925
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Catalog-only health checks: pg_trigger/pg_class/pg_namespace/pg_proc reads only, no SET/DDL/advisory locks, safe for a zero-grant role under PgBouncer transaction pooling"
    - "D-03-style identification union: a trigger is Threadline's own if its name matches the Naming prefix OR its function is/matches the Naming function prefix"

key-files:
  created:
    - lib/threadline/health/finding.ex
    - lib/threadline/health/trigger_catalog.ex
    - lib/threadline/health/trigger_findings.ex
    - test/threadline/health/trigger_findings_test.exs
    - test/threadline/health/trigger_findings_non_owner_test.exs
  modified:
    - lib/threadline/health.ex
    - lib/threadline/telemetry.ex
    - mix.exs
    - test/threadline/health_test.exs
    - CHANGELOG.md

key-decisions:
  - "trigger_coverage/1's WHERE clause gained only `tgenabled NOT IN ('D', 'R')`; its name-prefix identification is unchanged, keeping the D-05 change minimal and reviewable"
  - "duplicate_capture_trigger groups by {schema, table}, never the bare table name, so same-named tables in different schemas are never merged"
  - "Naming.trigger_name/1 raising for an unvalidatable identifier falls back to treating every trigger in the group as extra rather than crashing the whole check (no real identifier triggered this path, so it is undemonstrated by a test — noted here per the plan's own allowance)"

requirements-completed: [HLTH-05]

coverage:
  - id: D1
    description: "Threadline.Health.Finding struct with enforced code/severity/schema/table/message/details keys, grouped under mix.exs Data Types"
    requirement: HLTH-05
    verification:
      - kind: unit
        ref: "test/threadline/health/trigger_findings_test.exs#Finding struct @enforce_keys raises on a missing key"
        status: pass
      - kind: unit
        ref: "test/threadline/public_surface_contract_test.exs#every visible compiled module belongs to exactly one of six groups"
        status: pass
    human_judgment: false
  - id: D2
    description: ":capture_trigger_disabled reported for disabled ('D') and replica-only ('R') triggers, with negative controls for re-enabled/ENABLE ALWAYS"
    requirement: HLTH-05
    verification:
      - kind: unit
        ref: "test/threadline/health/trigger_findings_test.exs#capture_trigger_disabled — disabled ('D')"
        status: pass
      - kind: unit
        ref: "test/threadline/health/trigger_findings_test.exs#capture_trigger_disabled — replica-only ('R')"
        status: pass
    human_judgment: false
  - id: D3
    description: ":duplicate_capture_trigger reported via the D-03 identification union (name prefix or function), unrelated triggers excluded, same-named tables across schemas kept separate"
    requirement: HLTH-05
    verification:
      - kind: unit
        ref: "test/threadline/health/trigger_findings_test.exs#duplicate_capture_trigger"
        status: pass
      - kind: unit
        ref: "test/threadline/health/trigger_findings_test.exs#schema adjacency, filtering and empty edge"
        status: pass
    human_judgment: false
  - id: D4
    description: "trigger_coverage/1 no longer counts disabled/replica-only triggers as covered; CHANGELOG documents the breaking change"
    requirement: HLTH-05
    verification:
      - kind: unit
        ref: "test/threadline/health_test.exs#trigger_coverage/1 - disabled and replica-only triggers"
        status: pass
      - kind: unit
        ref: "test/threadline/changelog_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D5
    description: "Zero-grant NOLOGIN role reads identical findings to the owner under SET LOCAL ROLE inside a transaction, with no leftover role"
    requirement: HLTH-05
    verification:
      - kind: unit
        ref: "test/threadline/health/trigger_findings_non_owner_test.exs#a zero-grant NOLOGIN role reads the same findings as the owner"
        status: pass
    human_judgment: false

duration: ~1h
completed: 2026-09-26
status: complete
---

# Phase 212 Plan 1: Findings API, Disabled/Duplicate Detection, Coverage Exclusion Summary

**Catalog-only `Threadline.Health.trigger_findings/1` reporting `:capture_trigger_disabled` and `:duplicate_capture_trigger` with exact SQL fixes, `trigger_coverage/1` no longer crediting disabled/replica-only triggers, and a zero-grant-role proof that the check is PgBouncer/non-owner safe.**

## Performance

- **Duration:** ~1h
- **Tasks:** 3
- **Files modified:** 10 (5 created, 5 modified)
- **Commits:** 4 (3 task commits + 1 same-day vocabulary fix)

## Accomplishments
- `Threadline.Health.Finding` public struct (`@enforce_keys` on all six fields), documented per code, grouped under mix.exs "Data Types"
- `Threadline.Health.TriggerCatalog`: one parameterized, catalog-only `pg_trigger`/`pg_class`/`pg_namespace`/`pg_proc` read; `decode_tgargs/1` splits `tgargs` bytea on NUL; LIKE prefixes pinned by test to `Naming`'s prefixes
- `Threadline.Health.TriggerFindings.run/1`: schema normalization (string/list/omitted/raise), storage-schema exclusion, sort by `{schema, table, code, message}`, telemetry emission
- `:capture_trigger_disabled` (D/R states) and `:duplicate_capture_trigger` (name-or-function identification union) finding codes, each with an exact PostgreSQL fix in its message
- `Threadline.Health.trigger_findings/1` public entry and `Threadline.Telemetry.emit_findings_checked/2` (`[:threadline, :health, :findings_checked]`)
- `trigger_coverage/1`'s covered-table query excludes `tgenabled IN ('D', 'R')`; CHANGELOG Breaking changes + Required action document the semantics change
- First `CREATE ROLE` test in the repo: a zero-grant NOLOGIN role under `SET LOCAL ROLE` inside a transaction gets the same findings list as the owner; role and scratch schema are gone afterward

## Task Commits

1. **Task 1: Tracer — Finding struct, catalog read, :capture_trigger_disabled, public entry and telemetry** - `b6f7eee7` (feat)
2. **Task 2: Expand — :duplicate_capture_trigger, D-03 identification union, schema filtering, ordering** - `b223c00f` (feat)
3. **Task 3: Expand — D-05 coverage filter with CHANGELOG breaking entry, zero-grant role proof** - `f4800891` (feat)

Post-task fix (caught by the full `mix verify.test` run, not a task's own `<verify>` scope): `d79309ed` (fix) — a stray planning decision-ID (`D-03`) in a `lib/` comment tripped the release-artifact-contract test's ban on packaged planning vocabulary; rewritten in plain domain terms.

**Plan metadata:** committed alongside this SUMMARY (STATE.md/ROADMAP.md/REQUIREMENTS.md updates, no separate `.planning/` commit per `commit_docs` config — see Deviations).

_Note: no TDD tasks in this plan; each task's own commit includes its tests._

## Files Created/Modified
- `lib/threadline/health/finding.ex` - `Threadline.Health.Finding` struct, types, per-code moduledoc
- `lib/threadline/health/trigger_catalog.ex` - catalog-only trigger reads, `decode_tgargs/1`, LIKE prefix constants
- `lib/threadline/health/trigger_findings.ex` - `run/1`, `codes/0`, disabled + duplicate builders, sort/filter/telemetry
- `lib/threadline/health.ex` - `trigger_findings/1` public entry, `trigger_coverage/1` D-05 WHERE-clause change and doc update
- `lib/threadline/telemetry.ex` - `emit_findings_checked/2`, moduledoc event list updated to five events
- `mix.exs` - `Threadline.Health.Finding` added to the "Data Types" docs group
- `test/threadline/health/trigger_findings_test.exs` - real-PG fixtures: disabled/replica states, telemetry, decode_tgargs, struct enforcement, duplicate detection, pin test, schema adjacency/filtering/empty, ordering
- `test/threadline/health/trigger_findings_non_owner_test.exs` - zero-grant NOLOGIN role parity proof
- `test/threadline/health_test.exs` - D/R/A/O coverage states describe block
- `CHANGELOG.md` - Breaking changes + Required action entries for the D-05 coverage semantics change

## Decisions Made
- `trigger_coverage/1`'s identification (name-prefix LIKE) was left untouched; only the enabled-state filter was added, per the plan's explicit scope boundary for D-05.
- Duplicate-trigger grouping keys on `{schema, table}` rather than the bare table name, keeping same-named tables in different schemas from ever merging into one finding.
- The `Naming.trigger_name/1`-raises fallback (treat every trigger as extra) is implemented but not exercised by a test, because no real Threadline-derived identifier in the test suite triggers that raise; recorded here as the plan allows.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed a planning decision-ID reference from a `lib/` comment**
- **Found during:** the plan's own top-level `<verification>` command (`mix verify.test`), run after all three tasks — the acceptance-criteria greps in each task's `<verify>` block only scanned for `D-\d{2}` immediately after that task's own edits, and Task 2's duplicate-trigger comment was added after Task 1's grep had already run clean.
- **Issue:** `lib/threadline/health/trigger_findings.ex` had `# duplicate_capture_trigger: ... (D-03 union) on ...`, tripping `Threadline.ReleaseArtifactContractTest`'s ban on packaged planning vocabulary (this repo's own CLAUDE.md-mandated gate, not GSD's).
- **Fix:** reworded the comment in plain domain terms with no decision-ID.
- **Files modified:** `lib/threadline/health/trigger_findings.ex`
- **Verification:** `mix test test/threadline/release_artifact_contract_test.exs` (19 tests, 0 failures) and the full `mix verify.test` re-run (2145 tests, 0 failures)
- **Committed in:** `d79309ed`

---

**Total deviations:** 1 auto-fixed (1 bug — planning vocabulary leak)
**Impact on plan:** No scope creep; caught by the plan's own required verification step before handoff.

## Issues Encountered
- The non-owner test's final `pg_roles` leftover assertion initially ran before its `on_exit` cleanup (ExUnit `on_exit` runs after the test body returns), so the role appeared to still exist at assertion time. Fixed by dropping the schema and role explicitly inside the test body before the final `SELECT`, keeping `on_exit` only as a safety net for early-failure paths.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The catalog module (`Threadline.Health.TriggerCatalog`) and the finding-building/sort/filter/telemetry skeleton in `Threadline.Health.TriggerFindings` are in place for Plan 212-02 to add `:legacy_trigger_no_pk_args`, `:pk_drift`, and `:shared_capture_function` builders on top.
- HLTH-01 (PgBouncer topology lane for `trigger_findings/1`) is intentionally not addressed here; it lands in 212-04 per the ROADMAP wave plan. The non-owner half of PgBouncer/role safety (D-15/D-16) is proven here; the pooler-transport half is not.
- No blockers for Wave 2.

---
*Phase: 212-detection-and-adopter-twins*
*Completed: 2026-09-26*

## Self-Check: PASSED

All created files found on disk; all four task/fix commits (`b6f7eee7`, `b223c00f`, `f4800891`, `d79309ed`) found in `git log --oneline --all`.
