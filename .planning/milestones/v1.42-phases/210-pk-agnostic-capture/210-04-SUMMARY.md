---
phase: 210-pk-agnostic-capture
plan: 04
subsystem: capture
tags: [postgresql, plpgsql, ecto-migration, trigger, primary-key, configuration]

requires:
  - phase: 210-pk-agnostic-capture
    provides: "Plan 03's PrimaryKeySQL.qualifying_index_predicate/0 (shared stand-in-index predicate), the :redacted_columns option on TriggerSQL.create_trigger/3, and the type-allowlist DO-block check this plan's override branch reuses"
provides:
  - "Threadline.Capture.TriggerCaptureConfig: primary_key: [...] normalization (declared order, strings), a table-aware normalize_table_entry/2, strict validate_primary_key!/3 (non-empty list, valid identifiers, no duplicates, no redaction overlap), and near-miss key rejection (pk:, primary_keys:, pkey:, primary:)"
  - "Threadline.StorageSchema role :primary_key_column, used by the override's identifier validation"
  - "Threadline.Capture.PrimaryKeySQL.create_trigger_block/3's override branch: a declared primary_key: skips the pg_index lookup, refuses a table that already has a primary key (naming the discovered columns), refuses a missing or dropped declared column, and otherwise requires a qualifying unique index whose key-column set equals the declared set exactly — with a DETAIL line per considered index naming every disqualifying reason (partial, deferrable, expression, nullable column, invalid, column-set mismatch)"
  - "mix threadline.gen.triggers wires a table's primary_key: entry into TriggerSQL.create_trigger/3 and wraps TriggerCaptureConfig.load/0's ArgumentError into a Mix error prefixed with the config path"
  - "test/threadline/capture/trigger_capture_config_test.exs (pure unit) and test/threadline/capture/trigger_pk_override_test.exs (real PostgreSQL): the override loaded, validated, enforced and captured end to end, including every refusal shape"
affects: [211-read-side-pk-agnostic, 212-health-and-drift]

actuals:
  tokens: 11906
  tasks: 3
  commits: 3
  plan_head_before: 47be55c59340dc7b47509a6b9b3f37df6d0c19e7

tech-stack:
  added: []
  patterns:
    - "The override branch shares its type-allowlist FOREACH loop (key_type_check_sql/1) and its text[] literal builder (text_array_sql/1) with the detected-key branch, so the two code paths cannot silently diverge on either check"
    - "The override's qualifying-index search and its per-index mismatch DETAIL reuse one column-set-equality fragment (override_index_key_set_sql/0), computed once as a private helper rather than duplicated inline"
    - "Config validation runs on the RAW value before normalize_columns/1 (which dedups and drops blanks), so an empty name, a NUL byte, untrimmed whitespace, or a duplicate is never silently absorbed before it can be rejected"
    - "A single private validate_primary_key!/3 dispatches every rejection reason through one case expression (not multiple function clauses), so the function stays a single named definition callers and tests can reference unambiguously"

key-files:
  created:
    - test/threadline/capture/trigger_capture_config_test.exs
    - test/threadline/capture/trigger_pk_override_test.exs
  modified:
    - lib/threadline/capture/trigger_capture_config.ex
    - lib/threadline/capture/primary_key_sql.ex
    - lib/threadline/capture/trigger_sql.ex
    - lib/threadline/storage_schema.ex
    - lib/mix/tasks/threadline.gen.triggers.ex
    - test/mix/tasks/threadline/gen_triggers_test.exs

key-decisions:
  - "validate_primary_key!/3 is one case-expression-dispatched function, not multiple pattern-matched clauses, satisfying the plan's acceptance criterion that grep counts exactly one `defp validate_primary_key!` definition line"
  - "The has-a-primary-key refusal's HINT names the discovered columns (queried from pg_index the same way the detected branch resolves them), not just a generic 'remove primary_key:' message, so an adopter with a stale override sees exactly what Threadline already found"
  - "The qualifying-index search in the override branch also carries the detected branch's NOT NULL check (originally only present in the detected-key branch's search query); this was a gap caught by the nullable-column test during Task 3 and fixed before commit"
  - "The per-index mismatch DETAIL is built once per RAISE, over every unique index on the table (not just the declared columns' overlap), using concat_ws over six independent CASE WHEN reasons so an index can report more than one disqualifier at once"

requirements-completed: [CONF-01, CAP-05]

coverage:
  - id: D1
    description: "A posts_tags-shaped PK-less join table with a declared primary_key: override captures its declared columns end to end (config load, DO-block literal, migrate-time enforcement, trigger arguments, table_pk), under both the bare and schema-qualified config key (CONF-01 capture half)"
    requirement: "CONF-01"
    verification:
      - kind: integration
        ref: "test/threadline/capture/trigger_pk_override_test.exs#a posts_tags join table with a declared override"
        status: pass
    human_judgment: false
  - id: D2
    description: "TriggerCaptureConfig.load/1 exposes the override as a string list in declared order for the read side, including when declared with atoms"
    requirement: "CONF-01"
    verification:
      - kind: unit
        ref: "test/threadline/capture/trigger_pk_override_test.exs#TriggerCaptureConfig.load/1"
      - kind: unit
        ref: "test/threadline/capture/trigger_capture_config_test.exs#primary_key: accepted values"
        status: pass
    human_judgment: false
  - id: D3
    description: "Declared order becomes trigger-argument order, independent of the matched index's own column order (set equality, not order equality)"
    requirement: "CONF-01"
    verification:
      - kind: integration
        ref: "test/threadline/capture/trigger_pk_override_test.exs#declared order becomes trigger-argument order"
        status: pass
    human_judgment: false
  - id: D4
    description: "Every malformed primary_key: value (bare string/atom, non-list, empty list, blank/NUL/whitespace/oversized/malformed name, duplicate, non-string element, mask/exclude overlap) raises ArgumentError naming the table and the offending value at config load, before any migration is generated"
    requirement: "CONF-01"
    verification:
      - kind: unit
        ref: "test/threadline/capture/trigger_capture_config_test.exs#primary_key: rejected values"
        status: pass
    human_judgment: false
  - id: D5
    description: "Near-miss keys (pk:, primary_keys:, pkey:, primary:) raise, suggesting primary_key:; entries without primary_key keep loading exactly as before; mix threadline.gen.triggers wraps the config loader's ArgumentError into a Mix error prefixed with the config path, and has no --primary-key CLI flag"
    requirement: "CONF-01"
    verification:
      - kind: unit
        ref: "test/threadline/capture/trigger_capture_config_test.exs#near-miss keys"
      - kind: integration
        ref: "test/mix/tasks/threadline/gen_triggers_test.exs#table spelling (a malformed primary_key:, there is no --primary-key CLI flag)"
        status: pass
    human_judgment: false
  - id: D6
    description: "The migration refuses, before any host write, when the table already has a primary key (naming the discovered columns), when a declared column does not exist or was dropped, or when no unique index qualifies; a partial, deferrable, expression, nullable-column, invalid or column-set-mismatched index each names its own reason in DETAIL; a qualifying index with an INCLUDE column is accepted; a declared timestamptz column is refused the same way a detected one is"
    requirement: "CONF-01"
    verification:
      - kind: integration
        ref: "test/threadline/capture/trigger_pk_override_test.exs (an override on a table that already has a primary key, a declared column that does not exist, no unique index at all, subset/superset, partial/deferrable/expression/nullable-column, INCLUDE column, timestamptz type)"
        status: pass
    human_judgment: false
  - id: D7
    description: "Every pre-existing capture/mix/gen.triggers/policy/source-size suite plus the full mix verify.test stays green after the override branch lands"
    verification:
      - kind: integration
        ref: "mix verify.test"
        status: pass
    human_judgment: false

duration: 21min
completed: 2026-09-25
status: complete
---

# Phase 210 Plan 04: PK-Agnostic Capture — Configured Primary-Key Override Summary

**A `primary_key: [...]` override for a table with no primary key is now validated strictly at config load (empty lists, malformed names, duplicates, redaction overlap, near-miss keys all rejected with table-and-value-naming messages), enforced at migrate time against a qualifying unique index with a per-index disqualification reason in `DETAIL`, and captured with the declared columns as trigger arguments — closing the `posts_tags` copy-paste fix Plan 03's HINT already prints.**

## Performance

- **Duration:** ~21 min
- **Started:** 2026-09-25T17:09:00Z
- **Completed:** 2026-09-25T17:30:01Z
- **Tasks:** 3
- **Files modified:** 8 (2 created, 6 modified)

## Accomplishments

- `TriggerCaptureConfig.normalize_table_entry/2` (now table-aware) normalizes `primary_key:` to a string list in declared order (atoms and strings both accepted) and exposes it through `load/0`/`load/1`, matching under both a bare and a schema-qualified config key
- A private `validate_primary_key!/3` — one `case`-dispatched function definition — rejects, on the raw value before `normalize_columns/1` can hide anything: a bare string/atom (suggesting a list), any other non-list, an empty list, a blank/NUL-containing/untrimmed/over-63-byte/malformed identifier, a duplicate after `to_string`, a non-string/atom element, and overlap with the table's own `mask` or `exclude` — every message begins `tables "<table>": primary_key ...` and names the offending value
- Near-miss keys `primary_keys:`, `pk:`, `pkey:` and `primary:` raise, suggesting `primary_key:`, without breaking any entry that never sets it; `mix threadline.gen.triggers` wraps the config loader's `ArgumentError` into a `Mix.raise` prefixed `config :threadline, :trigger_capture`, and there is still no `--primary-key` CLI flag
- `PrimaryKeySQL.create_trigger_block/3`'s override branch (dispatched off a new `:primary_key` option) skips the `pg_index` primary-key lookup entirely: refuses a table that already has a primary key (naming the discovered columns in `HINT`), refuses a declared column missing or dropped after table creation (matched by `attname`, never `attnum`), and otherwise requires a qualifying unique index — reusing Plan 03's `qualifying_index_predicate/0` plus a NOT NULL check — whose first-`indnkeyatts` key-column set equals the declared set exactly; when none qualifies, `DETAIL` names every unique index on the table with every disqualifying reason it has (partial, deferrable, expression, nullable column, invalid, column-set mismatch), or says no unique index exists
- The type-allowlist check and the redaction (`mask`/`exclude`) check are shared verbatim between the detected-key and override branches (`key_type_check_sql/1`, `redaction_check_sql/2`), so a declared `timestamptz` column refuses the same way a detected one does, and a declared column also listed in `mask`/`exclude` refuses the same way
- `test/threadline/capture/trigger_capture_config_test.exs` (19 pure-unit tests) and `test/threadline/capture/trigger_pk_override_test.exs` (15 real-PostgreSQL tests) prove every accepted shape, every rejected config value, and every migrate-time refusal, including the INCLUDE-column and declared-order-vs-index-order edges

## Task Commits

Each task was committed atomically:

1. **Task 1: A posts_tags override captured end to end** — `41e9b2b8` (feat)
2. **Task 2: Strict primary_key: validation, near-miss keys, Mix error wrapping** — `358b38cc` (feat)
3. **Task 3: Migrate-time override refusals with per-index reasons; suite green** — `87e37c2b` (feat)

**Plan metadata:** (this commit)

## Files Created/Modified

- `lib/threadline/capture/trigger_capture_config.ex` — `primary_key:` normalization, table-aware `normalize_table_entry/2`, `validate_primary_key!/3`, near-miss key rejection
- `lib/threadline/capture/primary_key_sql.ex` — `create_trigger_block/3` dispatches to `detected_trigger_block/3` or the new `override_trigger_block/4`; shared `key_type_check_sql/1` and `text_array_sql/1` helpers; `override_index_key_set_sql/0` and `override_index_mismatch_detail_sql/0` build the per-index DETAIL
- `lib/threadline/capture/trigger_sql.ex` — `create_trigger/3` `@doc` now describes `:primary_key` alongside `:redacted_columns`
- `lib/threadline/storage_schema.ex` — new `:primary_key_column` role (label + type union) for the override's identifier validation
- `lib/mix/tasks/threadline.gen.triggers.ex` — `build_table_capture_spec/4` carries `primary_key:` from the table's config entry into the trigger opts; `load_capture_tables!/0` wraps `TriggerCaptureConfig.load/0`'s `ArgumentError` into a `Mix.raise`
- `test/threadline/capture/trigger_capture_config_test.exs` — new, pure-unit validation and loader-shape tests
- `test/threadline/capture/trigger_pk_override_test.exs` — new, real-PG end-to-end capture and refusal tests
- `test/mix/tasks/threadline/gen_triggers_test.exs` — two new cases: a malformed `primary_key:` surfaces as a config-prefixed `Mix.Error`; there is no `--primary-key` CLI flag

## Decisions Made

- `validate_primary_key!/3` is implemented as one function with an internal `case`, not multiple pattern-matched clauses, so the plan's acceptance grep (`defp validate_primary_key!` matching exactly one line) holds while every rejection path still lives in one place
- The has-a-primary-key refusal's `HINT` names the columns Threadline actually discovered (queried the same way the detected branch resolves `pg_index`), not a generic message, so an adopter can see immediately that the override is redundant with what Threadline already finds
- Found during Task 3's nullable-column test: the override branch's qualifying-index search was missing the NOT NULL check the detected branch already had (the `qualifying_index_predicate/0` shared predicate only covers index-level flags, not column nullability). Added the same `NOT EXISTS (... NOT a.attnotnull)` clause to the override branch's index search, matching the detected branch exactly — Rule 1 (bug), fixed before commit, covered by the new test
- The per-index mismatch `DETAIL` is computed with one `concat_ws` over six independent `CASE WHEN` reasons per index, so an index disqualified for more than one reason (for example expression *and* column-set mismatch) reports all of them rather than only the first matched

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Packaged planning vocabulary leaked into a `lib/` doc comment**
- **Found during:** Task 3, running the wider suite (`test/threadline/release_artifact_contract_test.exs`)
- **Issue:** `validate_primary_key!/3`'s doc comment (written during Task 2) referenced `D-15/D-12`, which the packaged-source contract test flags as planning vocabulary that must not ship in `lib/`.
- **Fix:** Rewrote the comment as durable domain rationale (what the function validates and why the raw value is checked before normalization), with no decision-ID cross-reference.
- **Files modified:** `lib/threadline/capture/trigger_capture_config.ex`
- **Verification:** `mix test test/threadline/release_artifact_contract_test.exs` — 19 tests, 0 failures; full `mix verify.test` re-run afterward — 2062 tests, 0 failures, 1 excluded
- **Committed in:** `87e37c2b` (Task 3 commit)

**2. [Rule 1 - Bug] The override branch's qualifying-index search was missing the NOT NULL column check**
- **Found during:** Task 3, writing the nullable-indexed-column refusal test
- **Issue:** The override branch's index search (added in Task 1) reused `qualifying_index_predicate/0` and the column-set-equality check, but never carried over the detected branch's separate `NOT EXISTS (... NOT a.attnotnull)` clause — so a unique index over a nullable column would have incorrectly qualified as a stand-in.
- **Fix:** Added the identical NOT NULL `NOT EXISTS` clause to the override branch's index search query, matching the detected branch.
- **Files modified:** `lib/threadline/capture/primary_key_sql.ex`
- **Verification:** `test/threadline/capture/trigger_pk_override_test.exs#"a nullable indexed column refuses, DETAIL says nullable column"` — passes; full suite re-run green
- **Committed in:** `87e37c2b` (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (1 packaged-vocabulary violation, 1 missing NOT NULL guard caught by its own test before ship)
**Impact on plan:** Both fixes were necessary for correctness and for the plan's own verification commands to pass. No scope creep.

## TDD Gate Compliance

This plan's tasks carry `tdd="true"`, but `workflow.tdd_mode` is not enabled in `.planning/config.json` for this repository (same as Plans 01–03), so the formal RED/GREEN/REFACTOR commit-gate sequence was not enforced. Each task was committed as a single commit containing both its tests and implementation. Test-first discipline was followed in practice: Task 1's `posts_tags` override tests were run against the unmodified branch first (confirmed red — the pre-Task-1 code refused with Plan 03's no-primary-key error), then the override branch was implemented and the same tests turned green; Task 3's nullable-column test caught the missing NOT NULL guard (see Deviations) before any commit, which is exactly the regression-proof a formal RED step would have provided.

## Issues Encountered

None beyond the two deviations above, both caught and resolved within the same task's own verification pass, before commit.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- CONF-01's capture and validation half is closed: a declared `primary_key:` override is validated at config load, enforced at migrate time against a qualifying unique index, and captured with the declared columns. The read-side half (D-18: override first, then `__schema__(:primary_key)` mapped through `field_source`, else raise) is Phase 211's scope — `TriggerCaptureConfig.load/0` already exposes `primary_key:` in the shape Phase 211 needs to consume it.
- CAP-05 was already fully complete after Plan 03 (detected-key mask/exclude refusal); this plan additionally applies the identical redaction check to override columns, so the config-declared half stays consistent with the detected half — no separate requirement-tracking change needed.
- Full suite (`mix verify.test` / `mix test`): 2062 tests, 0 failures, 1 excluded. `mix compile --warnings-as-errors` clean. `mix format --check-formatted` clean on all files this plan touched.
- No blockers. Phase 210 has one plan remaining (210-05).

---
*Phase: 210-pk-agnostic-capture*
*Completed: 2026-09-25*

## Self-Check: PASSED

- FOUND: lib/threadline/capture/trigger_capture_config.ex
- FOUND: lib/threadline/capture/primary_key_sql.ex
- FOUND: lib/threadline/capture/trigger_sql.ex
- FOUND: lib/threadline/storage_schema.ex
- FOUND: lib/mix/tasks/threadline.gen.triggers.ex
- FOUND: test/threadline/capture/trigger_capture_config_test.exs
- FOUND: test/threadline/capture/trigger_pk_override_test.exs
- FOUND: test/mix/tasks/threadline/gen_triggers_test.exs
- FOUND commit: 41e9b2b8 (Task 1)
- FOUND commit: 358b38cc (Task 2)
- FOUND commit: 87e37c2b (Task 3)
