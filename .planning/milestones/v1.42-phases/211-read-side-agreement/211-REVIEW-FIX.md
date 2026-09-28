---
phase: 211-read-side-agreement
fixed_at: 2026-09-26T02:35:00Z
review_path: .planning/phases/211-read-side-agreement/211-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 211: Code Review Fix Report

**Fixed at:** 2026-09-26
**Source review:** .planning/phases/211-read-side-agreement/211-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 3 (CR-01, WR-01, WR-02; IN-01 folded into CR-01 per orchestrator instruction, since it shares CR-01's root cause and fix)
- Fixed: 3
- Skipped: 0

## Fixed Issues

### CR-01: Ambiguous atom/string duplicate key silently passes D-03 validation and drops a value (folds in IN-01)

**Files modified:** `lib/threadline/query/row_key.ex`, `test/threadline/query/row_key_validation_test.exs`
**Commit:** `d938e3c8`
**Applied fix:** `validate_key_set!/3` now also compares `length(normalized_given)` against `MapSet.size(given)` before accepting a caller-supplied key set. A raw key list where two distinct entries (e.g. `:tenant_id` and `"tenant_id"`, or a repeated keyword-list key like `tenant_id: 1, tenant_id: 2`) normalize to the same field name now raises the existing "expected keys ... got ..." `ArgumentError` naming every raw key given, instead of silently collapsing to one field and discarding a value. This single code path fixes both the atom/string spelling case (CR-01) and the same-type duplicate-keyword case (IN-01), matching the review's own suggested consolidation.

Added two regression tests to `row_key_validation_test.exs`:
- "the same field given as both an atom and its string form raises (CR-01)"
- "a duplicated keyword-list key raises instead of last-value-wins (IN-01)"

### WR-02: `RowKey.normalize!/2`'s struct catch-all silently coerces an unrelated struct into a scalar id

**Files modified:** `lib/threadline/query/row_key.ex`, `test/threadline/query/row_key_validation_test.exs`
**Commit:** `8c686f65`
**Applied fix:** Added a module attribute `@scalar_key_structs [Date, NaiveDateTime, DateTime, Time, Decimal]` naming the legitimate scalar-value struct types a single-column table may still accept as a bare id (the ones 211-02 fixed to keep working and that `row_key_types_test.exs` already round-trips through Postgres). Added a new `normalize!/2` clause for single-column tables, placed before the existing scalar fallthrough clause, that matches any struct whose module is *not* in that allowlist and raises the purpose-built "a struct is not accepted as a row key" `ArgumentError` naming the expected fields — rather than letting the struct fall through to `dump_value!/4` and fail later with a generic "cannot cast" message. Deliberately scoped to single-column tables only, since the review confirmed composite tables already reject any non-map/keyword scalar (including structs) correctly via the existing "expected keys ... got a single value" branch.

Added two regression tests to `row_key_validation_test.exs`:
- "legitimate scalar-value structs are still accepted as a bare id" (Date, NaiveDateTime, DateTime, Time, Decimal)
- "an unrelated struct raises the purpose-built message, not a generic cast failure"

### WR-01: `validate_type_text!/1` is a substring denylist, not the "identifier-safe handling" its caller documents

**Files modified:** `lib/threadline/query/row_key.ex`, `test/threadline/query/row_key_types_test.exs`
**Commit:** `2835ca1f`
**Applied fix:** Chose option (b) from the review's fix suggestion. Replaced the four-substring denylist (`;`, null byte, `--`, `/*`) with a positive-allowlist regex (`@type_text_pattern`) matching `format_type/2`'s finite output grammar: a bare, possibly multi-word identifier (e.g. `"timestamp without time zone"`) or a double-quoted identifier (internal `"` doubled per PostgreSQL quoting rules), optionally schema-qualified, optionally followed by a typmod (`(digits[,digits])`) and/or one or more `[]` array markers. An unexpected catalog value now fails closed instead of only failing on four specific substrings.

Verified against the existing type matrix (bigint, uuid, text, date, timestamp, char(n), enum, domain — all still pass in `row_key_types_test.exs`), and added a new DB-backed regression test creating an enum type whose name requires double-quoting (`"rk t weird status"`, chosen for containing a space) to prove a quoted identifier round-trips through `Threadline.history/3` under the new allowlist.

### Follow-up: durable-vocabulary cleanup (same scope, not a separate review finding)

**Files modified:** `lib/threadline/query/row_key.ex`
**Commit:** `8dea42fb`
**Applied fix:** The full `mix test` run surfaced two `Threadline.ReleaseArtifactContractTest` failures: the CR-01/WR-01/WR-02/D-03/IN-01 review-ticket markers left in the CR-01, WR-01, and WR-02 commits' explanatory comments tripped the packaged-source durable-vocabulary gate (`D-\d{2,}` and `WR-\d{2,}` are banned shapes in `lib/*.ex`). Rewrote those three comments to state the same rationale in plain domain language with no phase-review ticket references, keeping every other line unchanged. Re-ran the full suite afterward to confirm the fix (see Verification below).

## Skipped Issues

None — all in-scope findings (and their fold-in) were fixed.

## Verification

Ran in the main checkout at `/Users/<user>/projects/threadline` (branch `milestone/v1.42`) — the orchestrator's supplied root-pin script (`pin.sh`) requires the cwd's git toplevel to match the pinned project root exactly, which an isolated `git worktree` would not satisfy, so per the orchestrator's explicit working-directory instruction this fix work ran directly in the main checkout rather than in a separate worktree. Numbers below are reproducible from this same checkout/branch.

- `mix compile --warnings-as-errors`: clean, no warnings.
- `mix format --check-formatted`: clean, no diffs.
- `mix credo --strict`: `3847 mods/funs, found no issues.`
- `mix test` (full suite, after all four commits above): `9 properties, 2122 tests, 0 failures, 1 excluded` (the 1 excluded is the pre-existing `pgbouncer_topology: true` tag exclusion, unrelated to this fix).

No background test run was left running; the `mix test` background job was waited on to completion before this report was written.

---

_Fixed: 2026-09-26_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
