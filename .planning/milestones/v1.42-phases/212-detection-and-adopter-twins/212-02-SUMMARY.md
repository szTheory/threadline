---
phase: 212-detection-and-adopter-twins
plan: 02
subsystem: database
tags: [postgres, ecto, triggers, health-checks, primary-keys]

requires:
  - phase: 212-detection-and-adopter-twins
    provides: "212-01: Threadline.Health.Finding struct, TriggerCatalog catalog-only reads, TriggerFindings.run/1 skeleton (sort/filter/telemetry), :capture_trigger_disabled, :duplicate_capture_trigger"
  - phase: 210-pk-agnostic-capture
    provides: "PrimaryKeySQL DO-block PK resolution and override qualification SQL that health mirrors"
provides:
  - "TriggerCatalog.primary_keys/1, live_columns/1, qualifying_override_index?/3, shared_functions/1"
  - "PrimaryKeySQL.override_index_key_set_sql/0 promoted to @doc false public (text unchanged)"
  - ":legacy_trigger_no_pk_args finding code (warning)"
  - ":pk_drift finding code (error) with all six reasons: key_mismatch, legacy_trigger_on_non_id_key, no_primary_key, override_without_qualifying_index, override_on_table_with_primary_key, recorded_column_missing"
  - ":shared_capture_function finding code (error)"
affects: [212-03, 212-04, 212-07, 213-upgrade-guide]

actuals:
  tokens: 9772
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Key-check scoping to the canonical trigger per {schema, table}: a duplicate/extra trigger already produces its own :duplicate_capture_trigger finding, so key comparison only runs against the trigger matching Naming.trigger_name/1, avoiding double-reporting (and a spurious legacy-key warning on a no-arg copy trigger that is about to be dropped anyway)"
    - "Case-insensitive existence check used ONLY to pick a pk_drift reason (recorded_column_missing vs key_mismatch), never to decide recorded == expected (that stays byte-exact, set-based)"
    - "Health reuses PrimaryKeySQL.qualifying_index_predicate/0 and the newly-promoted override_index_key_set_sql/0 directly by function call, never by copying their SQL text, so install-time enforcement and health can never diverge"

key-files:
  created:
    - test/threadline/health/trigger_findings_key_test.exs
  modified:
    - lib/threadline/capture/primary_key_sql.ex
    - lib/threadline/health/trigger_catalog.ex
    - lib/threadline/health/trigger_findings.ex
    - test/threadline/health/trigger_findings_test.exs

key-decisions:
  - "A recorded column is 'missing' (renamed/dropped) only when no live column of the table matches it under any case; a column that exists under different casing is a byte-exact :key_mismatch instead. This is the one comparison in the module that folds case, and only to select which of two pk_drift reasons applies — never to decide whether recorded equals expected. Without this distinction, the plan's own two must-have fixtures (a genuinely renamed PK column vs. a trigger recording the wrong case of an existing column) collapse to the same catalog-observable shape and cannot both be satisfied by a single reason-precedence rule."
  - "key_findings groups triggers by {schema, table} and checks only the canonical trigger (by Naming.trigger_name/1); when no trigger in a duplicated group matches the canonical name, the key check is skipped for that table until duplicates are resolved. Discovered because 212-01's own duplicate-trigger fixtures create no-argument copy triggers that would otherwise each earn their own spurious :legacy_trigger_no_pk_args warning, breaking already-passing 212-01 tests."
  - "TriggerCaptureConfig.load/0 is called unwrapped at the top of run/1 (not inside a rescue), so a malformed :trigger_capture config surfaces the identical ArgumentError TriggerCaptureConfig.load/0 itself raises, with no health-specific wrapping (D-07)."

requirements-completed: [HLTH-02, HLTH-03, HLTH-04]

coverage:
  - id: D1
    description: "A 0.10.2 no-argument trigger on an id-keyed table yields exactly one :legacy_trigger_no_pk_args warning naming the fix; regenerating clears it. The same shape on a non-id table yields :pk_drift :legacy_trigger_on_non_id_key instead."
    requirement: HLTH-02
    verification:
      - kind: unit
        ref: "test/threadline/health/trigger_findings_key_test.exs#legacy_trigger_no_pk_args — id table"
        status: pass
      - kind: unit
        ref: "test/threadline/health/trigger_findings_key_test.exs#pk_drift — legacy trigger on a non-id table"
        status: pass
    human_judgment: false
  - id: D2
    description: "A live primary-key change yields :pk_drift :key_mismatch (composite PK, order-insensitive comparison); a quoted mixed-case PK column proves byte-exact comparison in both directions (no case folding)"
    requirement: HLTH-03
    verification:
      - kind: unit
        ref: "test/threadline/health/trigger_findings_key_test.exs#pk_drift — composite key mismatch"
        status: pass
      - kind: unit
        ref: "test/threadline/health/trigger_findings_key_test.exs#pk_drift — order-insensitive comparison"
        status: pass
      - kind: unit
        ref: "test/threadline/health/trigger_findings_key_test.exs#pk_drift — byte-exact encoding, no case folding"
        status: pass
    human_judgment: false
  - id: D3
    description: "Expected-key resolution matches mix threadline.gen.triggers exactly: a real DO-block-accepted primary_key: override with a qualifying index yields nothing; dropping or partial-izing the index yields :override_without_qualifying_index; an override on a table with a real PK yields :override_on_table_with_primary_key; no PK and no override yields :no_primary_key with a config snippet; a renamed recorded column yields :recorded_column_missing; malformed config raises ArgumentError"
    requirement: HLTH-03
    verification:
      - kind: unit
        ref: "test/threadline/health/trigger_findings_key_test.exs#pk_drift — configured primary_key: overrides (D-10)"
        status: pass
    human_judgment: false
  - id: D4
    description: "A per-table function shared by two tables' triggers yields one :shared_capture_function error per table, each naming both tables and the single regenerate-all command; clears once the trigger is regenerated. Two tables on the global default function are never flagged. The check scans the whole catalog even when :schema narrows the return. A partitioned table's own per-table function is never reported as shared with its partitions."
    requirement: HLTH-04
    verification:
      - kind: unit
        ref: "test/threadline/health/trigger_findings_test.exs#shared_capture_function"
        status: pass
    human_judgment: false

duration: ~1h30m
completed: 2026-09-26
status: complete
---

# Phase 212 Plan 2: Findings API — Key Drift and Shared Functions Summary

**Extended `Threadline.Health.trigger_findings/1` with `:legacy_trigger_no_pk_args`, `:pk_drift` (all six reasons, override-aware via the same SQL the migration enforces), and `:shared_capture_function`, each with a real-PG fixture and a clean negative control.**

## Performance

- **Duration:** ~1h30m
- **Tasks:** 3
- **Files modified:** 5 (1 created, 4 modified)
- **Commits:** 4 (3 task commits + 1 same-day vocabulary fix)

## Accomplishments
- `Threadline.Health.TriggerCatalog` gains `primary_keys/1` and `live_columns/1` (catalog-only reads restricted to relids carrying a Threadline trigger via one shared identification predicate), `qualifying_override_index?/3` (calls `PrimaryKeySQL`'s own predicate and key-set SQL directly, binding relid/declared as query parameters), and `shared_functions/1` (per-table functions referenced by triggers on more than one table, whole-catalog scan, `tgparentid = 0` excluding partition clones)
- `Threadline.Capture.PrimaryKeySQL.override_index_key_set_sql/0` promoted from `defp` to `@doc false` public, text byte-identical, so health and the migration can never diverge on override qualification
- `:legacy_trigger_no_pk_args` (warning) and `:pk_drift` (error) finding codes: expected-key resolution mirrors `mix threadline.gen.triggers` exactly — a qualifying `primary_key:` override, else the live PK, else none — with a distinct `:pk_drift` reason for every way regeneration would refuse (`:no_primary_key`, `:override_without_qualifying_index`, `:override_on_table_with_primary_key`, `:recorded_column_missing`) plus `:key_mismatch` and `:legacy_trigger_on_non_id_key`
- `:shared_capture_function` (error): one finding per affected table, every message naming every table that shares the function and the single regenerate-all command, never one table at a time
- Key comparison is set-based (MapSet, order-insensitive) and byte-exact (no `String.downcase`/`trim` anywhere in the equality path); the one narrow exception is choosing between `:recorded_column_missing` and `:key_mismatch`, which uses a case-insensitive existence check only to pick the reason, never to decide equality
- Key-checking is scoped to the canonical trigger per `{schema, table}`, so 212-01's duplicate-trigger fixtures (a no-argument copy trigger on an id table) keep producing exactly their original `:duplicate_capture_trigger` finding with no new spurious warning

## Task Commits

1. **Task 1: Tracer — live PK read, recorded-vs-expected comparison, legacy warning and :pk_drift key mismatch on real triggers** - `7814772b` (feat)
2. **Task 2: Expand — override-aware expected key, every :pk_drift reason, D-07 raise, promoted shared SQL** - `6c3b05d8` (feat)
3. **Task 3: Expand — :shared_capture_function over the whole catalog, partition safety** - `6b14b271` (feat)

Post-task fix (caught by the plan's own full `mix test` run, not any task's scoped `<verify>`): `3f793e47` (fix) — planning decision-ID references (`D-NN`, `210 D-NN`) in `lib/` comments tripped the release-artifact-contract test's ban on packaged planning vocabulary; same failure class 212-01 hit. Reworded in plain domain terms.

**Plan metadata:** committed alongside this SUMMARY (STATE.md/ROADMAP.md/REQUIREMENTS.md updates; no separate `.planning/` commit per `commit_docs` config).

_Note: no TDD tasks in this plan; each task's own commit includes its tests._

## Files Created/Modified
- `lib/threadline/capture/primary_key_sql.ex` — `override_index_key_set_sql/0` promoted to `@doc false` public
- `lib/threadline/health/trigger_catalog.ex` — `primary_keys/1`, `live_columns/1`, `qualifying_override_index?/3`, `shared_functions/1`, shared identification predicate refactor
- `lib/threadline/health/trigger_findings.ex` — `key_findings`/`key_finding` (recorded/expected comparison, all pk_drift reasons, legacy warning), `shared_findings` (shared_capture_function), config loaded unwrapped in `run/1`
- `test/threadline/health/trigger_findings_key_test.exs` — real-PG fixtures for every key-set finding and every `:pk_drift` reason, each with a negative control
- `test/threadline/health/trigger_findings_test.exs` — `shared_capture_function` describe block appended (shared function, global-function negative, cross-schema D-02, partition safety)

## Decisions Made
- Key comparison is scoped to the canonical trigger per `{schema, table}` (see key-decisions above) — an intentional deviation from a literal per-trigger read of D-09/D-10, made because checking every trigger in a duplicated group would double-report the same underlying problem and would misclassify a no-argument copy trigger (about to be dropped by the `:duplicate_capture_trigger` fix) as its own legacy-key warning.
- `:recorded_column_missing` vs `:key_mismatch` disambiguation uses a case-insensitive existence check against the table's live columns (see key-decisions above) — the only case-folding in the module, confined to reason selection.
- `PrimaryKeySQL.override_index_key_set_sql/0`'s promotion changed nothing about its SQL text or its two existing call sites in `override_trigger_block/4`; only its visibility and a doc comment changed, verified by an unchanged capture/migration test suite.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed planning decision-ID references from `lib/` comments**
- **Found during:** the plan's own top-level full `mix test` run, after all three tasks — same failure class as 212-01's own deviation (each task's own scoped `<verify>` command only ran the files it had just touched, and the release-artifact-contract test scans the whole packaged tree)
- **Issue:** `lib/threadline/health/trigger_catalog.ex` and `lib/threadline/health/trigger_findings.ex` had several comments citing `D-03`, `D-10`, `D-11`, `D-02`, `D-07`, and `210 D-16`, tripping `Threadline.ReleaseArtifactContractTest`'s ban on packaged planning vocabulary (this repo's own CLAUDE.md-mandated gate)
- **Fix:** reworded every flagged comment in plain domain terms with no decision-ID
- **Files modified:** `lib/threadline/health/trigger_catalog.ex`, `lib/threadline/health/trigger_findings.ex`
- **Verification:** `mix test test/threadline/release_artifact_contract_test.exs` (0 failures) and the full `mix test` re-run (2165 tests, 0 failures)
- **Committed in:** `3f793e47`

---

**Total deviations:** 1 auto-fixed (1 bug — planning vocabulary leak, same class as 212-01)
**Impact on plan:** No scope creep; caught before handoff by the plan's own required top-level verification.

## Issues Encountered

**Genuine tension in the plan's own must-have truths, resolved during execution.** The plan's must-have truths specify two fixtures that are, at the raw catalog-comparison level, structurally identical: a genuinely renamed PK column (`code` renamed to `sku`, trigger still records `code`) must yield `:recorded_column_missing`, while a trigger that always recorded the wrong case of an existing column (`'code'` recorded against a live `"Code"` PK) must yield `:key_mismatch`. Both cases reduce to "the recorded column, compared byte-exactly, does not exist among the table's live columns" — there is no way to distinguish "renamed" from "always wrong" from catalog state alone. Resolved by using a case-insensitive existence check *only* to decide which of the two reasons applies (a column present under a different case is a mismatch, not a disappearance); the actual recorded-vs-expected equality decision that determines whether a finding fires at all stays byte-exact throughout, satisfying 210 D-16's "never case-fold" requirement for that decision while still letting both fixtures reach their specified outcome. Documented above as a key-decision for whoever next touches this reason precedence.

**Interaction with 212-01's duplicate-trigger fixtures.** A first implementation checked every Threadline trigger independently, which caused 212-01's own already-passing duplicate-trigger tests to regress: a no-argument copy trigger created to simulate a stray duplicate would itself earn a `:legacy_trigger_no_pk_args` warning, changing the finding count those tests assert. Resolved by scoping key-checking to the canonical trigger per `{schema, table}` only (see key-decisions above), which is both semantically correct (the extra trigger is getting dropped anyway, per its own `:duplicate_capture_trigger` fix) and non-breaking.

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness
- `Threadline.Health.trigger_findings/1` now reports all five finding codes in the phase's scope (`:capture_trigger_disabled`, `:duplicate_capture_trigger` from 212-01; `:legacy_trigger_no_pk_args`, `:pk_drift`, `:shared_capture_function` from this plan).
- 212-03 (verify_coverage findings gate, health.coverage FINDINGS text/JSON) can build directly on `trigger_findings/1`'s stable output shape.
- HLTH-01 (PgBouncer topology lane) and HLTH-06 (Mix task wiring) remain open for 212-04/212-03 respectively, per the original wave plan.
- No blockers for Wave 3.

---
*Phase: 212-detection-and-adopter-twins*
*Completed: 2026-09-26*

## Self-Check: PASSED

All modified/created files found on disk; all four commits (`7814772b`, `6c3b05d8`, `6b14b271`, `3f793e47`) found in `git log --oneline --all`.
