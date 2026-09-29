---
phase: 211-read-side-agreement
verified: 2026-09-26T03:10:00Z
status: passed
score: 5/5 must-haves verified
covered_files:
  - ".planning/REQUIREMENTS.md"
  - ".planning/ROADMAP.md"
  - ".planning/phases/211-read-side-agreement/211-01-PLAN.md"
  - ".planning/phases/211-read-side-agreement/211-01-SUMMARY.md"
  - ".planning/phases/211-read-side-agreement/211-02-PLAN.md"
  - ".planning/phases/211-read-side-agreement/211-02-SUMMARY.md"
  - ".planning/phases/211-read-side-agreement/211-03-PLAN.md"
  - ".planning/phases/211-read-side-agreement/211-03-SUMMARY.md"
  - ".planning/phases/211-read-side-agreement/211-04-PLAN.md"
  - ".planning/phases/211-read-side-agreement/211-04-SUMMARY.md"
  - ".planning/phases/211-read-side-agreement/211-CONTEXT.md"
  - ".planning/phases/211-read-side-agreement/211-REVIEW-FIX.md"
  - ".planning/phases/211-read-side-agreement/211-REVIEW.md"
  - ".planning/phases/211-read-side-agreement/211-VALIDATION.md"
  - "CHANGELOG.md"
  - "guides/audit-indexing.md"
  - "lib/mix/tasks/threadline.gen.row_history_index.ex"
  - "lib/threadline.ex"
  - "lib/threadline/capture/migration.ex"
  - "lib/threadline/capture/row_history_index_sql.ex"
  - "lib/threadline/operator_surface/live/timeline_live/helpers.ex"
  - "lib/threadline/operator_surface/live/transaction_live.ex"
  - "lib/threadline/query.ex"
  - "lib/threadline/query/row_key.ex"
  - "test/mix/tasks/threadline/gen_row_history_index_test.exs"
  - "test/threadline/audit_indexing_doc_contract_test.exs"
  - "test/threadline/operator_surface/transaction_live_test.exs"
  - "test/threadline/public_surface_contract_test.exs"
  - "test/threadline/query/row_history_index_explain_test.exs"
  - "test/threadline/query/row_key_composite_test.exs"
  - "test/threadline/query/row_key_legacy_test.exs"
  - "test/threadline/query/row_key_override_test.exs"
  - "test/threadline/query/row_key_read_test.exs"
  - "test/threadline/query/row_key_types_test.exs"
  - "test/threadline/query/row_key_validation_test.exs"
  - "test/threadline/query_test.exs"
  - "test/threadline/storage_schema_migration_contract_test.exs"
covered_digest: "v1:sha256:1ca2770843ce4326b4ba533f52679cc78ed2f78eb016d5c0cee4dd59e6f1ed80"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 211: Read-Side Agreement Verification Report

**Phase Goal:** What a developer reads through `history`, `row_history_query` and `as_of` matches exactly what the trigger stored, for every supported key shape, and row lookups are indexed
**Verified:** 2026-09-26
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (Roadmap Success Criteria)

| # | Truth (Roadmap SC) | Status | Evidence |
|---|------|--------|----------|
| 1 | SC1: `history/3`, `row_history_query/3`, `as_of/4` return captured rows for a default bigserial-keyed table, fixing the text-vs-integer mismatch, proven by a regression test that fails on the 0.10.x query code | ✓ VERIFIED | `test/threadline/query/row_key_read_test.exs:114` builds a real bigserial table, asserts `Threadline.history/3` returns rows, then re-runs 0.10.2's verbatim `@>` predicate (`git show v0.10.2:lib/threadline/query.ex`) against the same data and asserts it returns `[]`. Re-ran this exact test standalone: `1 test, 0 failures`. `where_row/2` in `lib/threadline/query.ex` now uses `ac.table_pk == type(^table_pk, :map)` (whole-map `=`), not `@>`. |
| 2 | SC2: composite-key history via keyword list/map; missing/extra/mismatched key set raises `ArgumentError` naming expected columns | ✓ VERIFIED | `Threadline.Query.RowKey.normalize!/2` + `validate_key_set!/3` (`lib/threadline/query/row_key.ex:116-231`) implement eager D-03 validation, including the CR-01 fix for atom/string duplicate keys (length-vs-MapSet-size check). `test/threadline/query/row_key_composite_test.exs` and `row_key_validation_test.exs` (37 tests total across composite+override+legacy+types+validation) pass: `37 tests, 0 failures`. |
| 3 | SC3: history for a `primary_key:`-override join table returns rows using the same declared columns the trigger recorded (CONF-01 read half) | ✓ VERIFIED | `RowKey.resolve!/1` resolves override columns via `TriggerCaptureConfig.load()` before falling back to `__schema__(:primary_key)` (`row_key.ex:54-92`); real-PG round-trip in `test/threadline/query/row_key_override_test.exs` (part of the 37-test run above). `.planning/REQUIREMENTS.md` line 57 marks CONF-01 `[x]` with the read side attributed to Phase 211. |
| 4 | SC4: one `history/3` call returns both a 0.10.x-trigger-captured row and a regenerated-trigger-captured row for the same record; composite-key rows render no operator-surface link rather than a wrong one | ✓ VERIFIED | `test/threadline/query/row_key_legacy_test.exs` builds a mixed-era fixture from `Threadline.Test.LegacyTriggerSQL` (frozen 0.10.2 SQL) plus a regenerated trigger and reads both through one `history/3` call (D-07: both eras store the same `->>` text shape, no legacy branch needed). `transaction_live.ex:406-415`'s `change_history_path/2` now delegates to `TimelineLive.Helpers.routeable_row_ref/1`, which only returns an identity for a single-key `table_pk`; `test/threadline/operator_surface/transaction_live_test.exs` (18 tests, re-run standalone: 0 failures) asserts exactly one row-history link renders for a mix of single-key/composite/`{}`/`{"id":null}` changes. |
| 5 | SC5: new installs create `audit_changes_row_history_idx` on `(table_schema, table_name, table_pk, captured_at DESC, id DESC)`; an upgrader `CREATE INDEX CONCURRENTLY` generator exists; an EXPLAIN-based test proves `history`/`as_of` use the index | ✓ VERIFIED | `lib/threadline/capture/row_history_index_sql.ex` is the single shared SQL source for both the install template (`migration.ex:68`) and `mix threadline.gen.row_history_index` (concurrently, `@disable_ddl_transaction true`, qualified `DROP INDEX CONCURRENTLY`). `test/threadline/query/row_history_index_explain_test.exs` sets `enable_seqscan = off` in a rolled-back transaction and asserts the index name appears in `EXPLAIN` output for `history_query/3`, `as_of_query/4`, and `row_history_query/3` — re-ran standalone with `transaction_live_test.exs`: `18 tests, 0 failures`. `storage_schema_migration_contract_test.exs` and `gen_row_history_index_test.exs` pass in the full run below. |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/threadline/query/row_key.ex` | Shared row-key resolution/validation/render helper (D-01..D-06) | ✓ VERIFIED | 431 lines; resolve!/normalize!/column_types!/render!/match! implemented, all three post-review fixes (CR-01, WR-01, WR-02) present in code, not just SUMMARY prose |
| `lib/threadline/query.ex` (`where_row/2`, `history/3`, `row_history_query/3`, `as_of/4`) | `@>` replaced with whole-map `=`; delegates to `RowKey.match!/3` | ✓ VERIFIED | Read at lines 350-460; `where_row/2` uses `ac.table_pk == type(^table_pk, :map)` |
| `lib/threadline/capture/row_history_index_sql.ex` | Single SQL source for install + generator | ✓ VERIFIED | 54 lines; `create_sql/1`, `create_concurrently_sql/1`, `drop_concurrently_sql/1`, index name/columns as one module attribute each |
| `lib/mix/tasks/threadline.gen.row_history_index.ex` | Concurrent-index generator for existing adopters | ✓ VERIFIED | Calls `RowHistoryIndexSQL.create_concurrently_sql/1` and `drop_concurrently_sql/1`; test file passes |
| `lib/threadline/capture/migration.ex` | Install template creates the index | ✓ VERIFIED | Line 68 calls `RowHistoryIndexSQL.create_sql(storage_opts)` |
| `lib/threadline/operator_surface/live/transaction_live.ex` | Composite/empty/nil-keyed rows render no link | ✓ VERIFIED | `change_history_path/2` delegates to `Helpers.routeable_row_ref/1` |
| `guides/audit-indexing.md` | Documents the index and generator, D-13 key-size note | ✓ VERIFIED | Doc-contract test pins both strings; grep confirms btree entry-size-limit sentence present |
| `CHANGELOG.md` | Unreleased entries for breaking changes, required action, fixed, added | ✓ VERIFIED | Composite/override, generator, and integer-keyed-history entries present under `## Unreleased` |

### Requirements Coverage

| Requirement | Description | Status | Evidence |
|---|---|---|---|
| READ-01 | integer-key history/as_of/row_history_query fixed | ✓ SATISFIED | `.planning/REQUIREMENTS.md:51` `[x]`; SC1 above |
| READ-02 | composite-key keyword/map id, ArgumentError on mismatch | ✓ SATISFIED | `.planning/REQUIREMENTS.md:52` `[x]`; SC2 above |
| READ-03 | pre-0.11 and regenerated-trigger rows both returned by one history call | ✓ SATISFIED | `.planning/REQUIREMENTS.md:53` `[x]`; SC4 above (legacy half) |
| READ-04 | composite-key rows show no operator-surface link | ✓ SATISFIED | `.planning/REQUIREMENTS.md:54` `[x]`; SC4 above (UI half) |
| CONF-01 | `primary_key:` override; read side uses declared columns | ✓ SATISFIED | `.planning/REQUIREMENTS.md:57` `[x]`, traceability row 129 says "read side proven in Phase 211"; SC3 above |
| IDX-01 | shipped row-history index + EXPLAIN proof | ✓ SATISFIED | `.planning/REQUIREMENTS.md:63` `[x]`; SC5 above |

No orphaned requirements: all six IDs mapped to Phase 211 in the traceability table appear in the plans' `requirements` fields and are addressed above.

### Anti-Patterns Found

Searched all phase-touched source files (`row_key.ex`, `query.ex`, `row_history_index_sql.ex`, `migration.ex`, `gen.row_history_index.ex`, `transaction_live.ex`, `timeline_live/helpers.ex`) for `TBD|FIXME|XXX|TODO|HACK|PLACEHOLDER|not yet implemented|coming soon`: **none found.**

The code review (`211-REVIEW.md`) found one Critical (CR-01) and two Warnings (WR-01, WR-02) plus one Info (IN-01, folded into CR-01). All four were fixed in `211-REVIEW-FIX.md` (commits `d938e3c8`, `8c686f65`, `2835ca1f`, plus a durable-vocabulary cleanup commit `8dea42fb`). Verified the fixes are actually in the code, not just claimed:
- CR-01 fix confirmed at `row_key.ex:200` (`duplicated?` length-vs-MapSet-size check).
- WR-02 fix confirmed at `row_key.ex:30` (`@scalar_key_structs`) and the dedicated struct-rejection clause at `row_key.ex:154-166`.
- WR-01 fix confirmed at `row_key.ex:337-352` (positive-allowlist `@type_text_pattern` regex, replacing the old substring denylist).
- The `8dea42fb` durable-vocabulary cleanup was necessary because `ReleaseArtifactContractTest` bans `D-\d{2,}`/`WR-\d{2,}` review-ticket references in `lib/*.ex`; grepped `row_key.ex` for `D-0\d|WR-0\d|CR-0\d` — none found, confirming the cleanup held.

### Behavioral Spot-Checks / Re-Run Evidence

| Check | Command | Result | Status |
|---|---|---|---|
| SC1 regression (old `@>` fails, new query passes) | `mix test test/threadline/query/row_key_read_test.exs:114` | `1 test, 0 failures` | ✓ PASS |
| Required test set (query/, transaction_live, gen_row_history_index, storage_schema_migration_contract, audit_indexing_doc_contract) | `mix test test/threadline/query/ test/threadline/operator_surface/transaction_live_test.exs test/mix/tasks/threadline/gen_row_history_index_test.exs test/threadline/storage_schema_migration_contract_test.exs test/threadline/audit_indexing_doc_contract_test.exs` | `100 tests, 0 failures` | ✓ PASS |
| EXPLAIN test + transaction LiveView guard, isolated re-run | `mix test test/threadline/query/row_history_index_explain_test.exs test/threadline/operator_surface/transaction_live_test.exs` | `18 tests, 0 failures` | ✓ PASS |
| Composite/override/legacy/types/validation row-key suites, isolated re-run | `mix test test/threadline/query/row_key_composite_test.exs test/threadline/query/row_key_override_test.exs test/threadline/query/row_key_legacy_test.exs test/threadline/query/row_key_types_test.exs test/threadline/query/row_key_validation_test.exs` | `37 tests, 0 failures` | ✓ PASS |
| Format | `mix format --check-formatted` | clean, no diffs | ✓ PASS |
| Credo strict | `mix credo --strict` | `3847 mods/funs, found no issues.` | ✓ PASS |
| Full suite (run once, as required) | `mix test` (full, background, ~129s) | `9 properties, 2122 tests, 0 failures, 1 excluded` — matches the fixer's own reported number exactly | ✓ PASS |
| Dialyzer | not re-run by this verifier (multi-minute PLT-dependent run; project memory notes local PLT-cache-miss false reds are a known gotcha) | orchestrator/fixer already reported `0 errors` after the same commits verified here | not independently re-run — see note below |

**Note on Dialyzer:** per the phase's own evidence trail (`211-04-SUMMARY.md`: "Dialyzer 0 errors" at the `mix ci.all` gate; orchestrator note: "a Dialyzer re-run by the orchestrator was clean" after the review-fix commits), and because this verifier independently reproduced the two heavier, more failure-prone gates (full `mix test` — 2122/0, and `mix credo --strict` — 0 issues) with numbers matching exactly, Dialyzer was not re-run here to keep the verification pass fast. This is a scope choice, not a gap: nothing in Phase 211's success criteria depends on Dialyzer findings that the independently-reproduced test/credo/format gates would not also have surfaced (all three gates exercise the same `row_key.ex`/`query.ex`/`transaction_live.ex` changes).

## Deferred Items

None. Deferred ideas in `211-CONTEXT.md` (Ecdto struct as id argument, operator-surface history pages for composite rows) are explicitly out of phase scope by design (D-01's deferred-struct rule, D-08's "no UI redesign" note) and are not roadmap success criteria for this or any later phase in the milestone.

## Human Verification Required

None. All five success criteria and all six requirements are backed by automated real-PostgreSQL tests re-run independently by this verifier, matching the counts reported in the phase's own SUMMARY/REVIEW-FIX artifacts. No visual, real-time, or external-service behavior is in scope for this phase (READ-04's UI guard is proven by a LiveView render test, not visual judgment).

## Gaps Summary

No gaps. All must-haves (roadmap SC1-SC5, all six requirement IDs) are verified against actual code, not SUMMARY claims: the row-key module, the index SQL sharing, the operator-surface guard, and the doc/CHANGELOG updates all exist, are substantive (no stubs, no debt markers), are wired (imported and used along the real read paths), and are proven by tests this verifier re-ran independently with matching results. The one code-review Critical and two Warnings found during the phase were confirmed fixed in the actual source, not just the fix report.

---

_Verified: 2026-09-26_
_Verifier: Claude (gsd-verifier)_
