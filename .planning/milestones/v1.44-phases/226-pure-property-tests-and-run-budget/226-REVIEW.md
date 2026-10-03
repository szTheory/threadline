---
phase: 226-pure-property-tests-and-run-budget
reviewed: 2026-10-01T17:15:39Z
depth: standard
files_reviewed: 28
files_reviewed_list:
  - .github/workflows/flake-detection.yml
  - CHANGELOG.md
  - CONTRIBUTING.md
  - bin/classify-flake-run
  - lib/threadline/capture/redaction_policy.ex
  - lib/threadline/capture/trigger_capture_config.ex
  - lib/threadline/export.ex
  - lib/threadline/export/csv.ex
  - lib/threadline/query.ex
  - lib/threadline/query/cursors.ex
  - mix.exs
  - test/support/change_fact_generators.ex
  - test/support/cursor_generators.ex
  - test/support/export_hostile_value_generators.ex
  - test/support/keyset_model.ex
  - test/support/property_runs.ex
  - test/support/redaction_policy_generators.ex
  - test/support/strict_rfc4180.ex
  - test/test_helper.exs
  - test/threadline/capture/naming_property_test.exs
  - test/threadline/capture/redaction_policy_property_test.exs
  - test/threadline/capture/trigger_capture_config_test.exs
  - test/threadline/capture/trigger_rerun_property_test.exs
  - test/threadline/change_diff_property_test.exs
  - test/threadline/export_property_test.exs
  - test/threadline/export_test.exs
  - test/threadline/flake_classifier_contract_test.exs
  - test/threadline/mix/trigger_migration_property_test.exs
  - test/threadline/property_generator_coverage_test.exs
  - test/threadline/property_scale_contract_test.exs
  - test/threadline/query/cursors_property_test.exs
  - test/threadline/query_test.exs
  - test/threadline/strict_rfc4180_test.exs
findings:
  critical: 1
  warning: 2
  info: 2
  total: 5
status: resolved
---

# Phase 226: Code Review Report

**Reviewed:** 2026-10-01T17:15:39Z
**Depth:** standard
**Files Reviewed:** 28 (files in the `files` config list that could not be located under the repo — e.g. a `test/threadline/query/cursors_property_test.exs` duplicate reference — were read once)
**Status:** issues_found

## Summary

This phase is unusually well-executed for a property-testing phase: every oracle
(`KeysetModel`, `ChangeFactGenerators`'s `expected/3`, `StrictRFC4180`,
`ExportHostileValueGenerators`'s hand-built JSON) is genuinely independent of the
code under test — none of them call `Threadline.ChangeDiff`, `Threadline.Export`,
or the CSV-dumping library to produce their expected values, which is exactly what
an oracle needs to avoid a tautological property. Generator bias is backed by a
dedicated coverage-floor test (`property_generator_coverage_test.exs`) rather than
asserted and hoped. The `THREADLINE_PROPERTY_SCALE` run-budget wiring and the
Flake Detection repeat count (8) are both pinned end-to-end by
`property_scale_contract_test.exs` / `flake_classifier_contract_test.exs`, so the
mix.exs/workflow/CONTRIBUTING/bin triad cannot silently drift. The CSV bare-CR fix
is correctly scoped (new `reserved: [",", "\"", "\r", "\n"]` custom NimbleCSV
definition, replacing the stock `NimbleCSV.RFC4180`) and is covered by its own
round-trip property plus a hand-written independent decoder.

One real correctness gap survived, however: the breaking-change validation this
phase added for a non-list `exclude:`/`mask:` on a `:trigger_capture` table entry
(D-18/D-12) was **not** extended to the sibling `:except_columns` key, which has
the identical silent-data-loss failure mode and is documented in the same
moduledoc area. See CR-01.

## Critical Issues

### CR-01: `except_columns:` with a non-list value is silently dropped to `[]`, unlike `exclude:`/`mask:`

**File:** `lib/threadline/capture/trigger_capture_config.ex:64-78`
**Issue:** This phase (commits `24c7af2e`, `00fd767c`, confirmed by the new
`test/threadline/capture/trigger_capture_config_test.exs` "D-18 regression
examples") made a non-list `:exclude` or `:mask` value raise `ArgumentError` via
`check_column_list!/3`, specifically because silently normalizing it to `[]`
means "the column is never redacted and nothing warns the adopter" (see the
comment at lines 94-98). `:except_columns` has the exact same shape and the exact
same consumer-facing risk — it suppresses fields from `changed_fields` /
`changed_from` for compliance/PII reasons (see `trigger_sql.ex:46`) — but it is
normalized directly:
```elixir
|> put_if_present(
  :except_columns,
  normalize_columns(Keyword.get(entry, :except_columns, []))
)
```
with no `check_column_list!(table, :except_columns, ...)` guard before it. Because
`normalize_columns/1`'s catch-all clause is `defp normalize_columns(_), do: []`, a
config such as `tables: %{"users" => [except_columns: :ssn]}` (a very plausible
typo — a single atom instead of `[:ssn]`) loads successfully and silently
captures the `ssn` field in every `changed_fields`/`changed_from` payload instead
of excluding it. This is the identical "harder to miss capture than to enable it"
failure this phase explicitly closed for `exclude`/`mask`, left open for
`except_columns`.
**Fix:**
```elixir
defp normalize_table_entry(table, entry) when is_list(entry) do
  check_near_miss_keys!(table, entry)
  check_column_list!(table, :exclude, Keyword.get(entry, :exclude))
  check_column_list!(table, :mask, Keyword.get(entry, :mask))
  check_column_list!(table, :except_columns, Keyword.get(entry, :except_columns))
  ...
```
Add a `TriggerCaptureConfig` regression test mirroring the existing D-18 ones:
`TriggerCaptureConfig.load(tables: %{"users" => [except_columns: :ssn]})` must
raise `ArgumentError` naming `"users"`, `except_columns`, and `list`.

## Warnings

### WR-01: Two naming/migration properties silently lost a third of their default run budget

**File:** `test/threadline/mix/trigger_migration_property_test.exs:23,29`
**Issue:** Before this phase, `"a table's own generated trigger migration is a
rerun of it"` and `"another table's generated trigger migration is never a
rerun"` ran at `max_runs: 300`. The PROP-08 rollout (commit `a5d4e194`) replaced
both with `PropertyRuns.pure(200)`, which at the default scale (`scale() == 1`,
i.e. every PR run with `THREADLINE_PROPERTY_SCALE` unset) is `200`, a ~33%
reduction in default coverage for these two properties specifically (every other
property touched by this phase was already at or below 200). This is consistent
with the new `property_scale_contract_test.exs` contract (which caps the allowed
literal base at 200), so it's not a contract violation, but it is a quiet
regression in per-PR assurance for the naming/migration-rerun logic that isn't
called out in any commit message, SUMMARY, or CHANGELOG entry.
**Fix:** If 300 runs mattered for this property (e.g. it previously caught a rare
hash-collision edge case), consider whether `PropertyRuns.pure(200)` undershoots
it, or explicitly note in the 226 plan/summary that the ceiling was intentionally
lowered to standardize on the 150-200 band.

### WR-02: `RedactionPolicy.validate!/1`'s overlap-error sample column is non-deterministic across calls

**File:** `lib/threadline/capture/redaction_policy.ex:22-29`
**Issue:** `sample = intersection |> MapSet.to_list() |> List.first()` picks an
arbitrary element of the overlap set when `exclude:` and `mask:` overlap on more
than one column. `MapSet.to_list/1` order is an implementation detail (currently
derived from internal hashing), so which column name appears in the raised
message is unspecified when there are 2+ overlapping columns, even though the
message also lists every overlapping column via `cols` on the line above. This
isn't a logic bug — the property test (`redaction_policy_property_test.exs`) only
exercises a single overlapping column per case, so it can't catch this — but it
means two operators hitting the same multi-column overlap could see different
single-column call-outs in their error message across Elixir/OTP versions or
compiler changes, which is a minor reproducibility smell in an error path meant
to "fail loudly" with a stable, citable message.
**Fix:** Sort before taking the first element for a deterministic message, e.g.
`sample = intersection |> MapSet.to_list() |> Enum.sort() |> List.first()` (or
just reuse `cols`'s already-sorted list: `List.first(String.split(cols, ", "))`).

## Info

### IN-01: `files_reviewed_list` in this report includes two files not read

**File:** (meta — this REVIEW.md)
**Issue:** The task's `<required_reading>`/`files` list named both
`test/threadline/query/cursors_property_test.exs` and implicitly expected the
module files reviewed above; no actual discrepancy was found once resolved — note
retained only because the file list in the config block had a nested indirection
(`test/threadline/query/cursors_property_test.exs` lives under `test/threadline/query/`,
not `test/threadline/`) that is easy to mis-path. No action needed; flagged only
for the record since it cost extra lookup time during review.
**Fix:** N/A — documentation note only.

### IN-02: `check_column_list!/3` duplicated between `RedactionPolicy` (implicit) and `TriggerCaptureConfig` (explicit) with slightly different messages

**File:** `lib/threadline/capture/trigger_capture_config.ex:99-105`, `lib/threadline/capture/redaction_policy.ex:17-19`
**Issue:** `TriggerCaptureConfig.normalize_table_entry/2` now does its own
non-list check (`check_column_list!/3`, raising `"tables <table>: <key> must be a
list of column names, got: ..."`) specifically so the error names the table —
*before* delegating to `RedactionPolicy.validate!/1`, whose own
`normalize_columns/2` would otherwise raise a table-less `"<key> must be a list
of column names, got: ..."`. This means the same invalid input now goes through
two near-identical validation passes with two slightly different messages
depending on the call path (direct `RedactionPolicy.validate!/1` vs. via
`TriggerCaptureConfig.load/1`), which is intentional and tested, but it is a small
duplication that a future redaction-policy key addition (anything besides
`exclude`/`mask`) must remember to mirror in both places — exactly the gap CR-01
identifies for `except_columns`.
**Fix:** No immediate change needed beyond CR-01; worth a comment cross-reference
between the two call sites so a future key addition doesn't repeat the gap.

---

_Reviewed: 2026-10-01T17:15:39Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

## Resolution

| Finding | Disposition | Commit |
|---------|-------------|--------|
| CR-01 | fixed — `except_columns:` gets the same non-list guard as `exclude:`/`mask:` on the config load path; regression test added; CHANGELOG Breaking-changes entry widened. The direct `TriggerSQL` path already raises on a non-list (`Enum.map_join/3` on an atom), so only the config path was silent. | 742c191b |
| WR-01 | accepted — the 200 base cap is the locked run-budget decision (D-07, pinned by `property_scale_contract_test.exs`); the weekly Flake Detection lane runs these properties at scale 5 (1,000 runs), above the old 300. | — |
| WR-02 | fixed — the overlap message's sample column now comes from the sorted list. | bea03cd5 |
| IN-01, IN-02 | noted, no change — informational. | — |

Full suite after fixes: 28 properties, 2650 tests, 0 failures; `mix verify.credo` clean.
