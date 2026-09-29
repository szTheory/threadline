---
phase: 211-read-side-agreement
reviewed: 2026-09-25T00:00:00Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - lib/mix/tasks/threadline.gen.row_history_index.ex
  - lib/threadline.ex
  - lib/threadline/capture/migration.ex
  - lib/threadline/capture/row_history_index_sql.ex
  - lib/threadline/operator_surface/live/row_history_component.ex
  - lib/threadline/operator_surface/live/transaction_live.ex
  - lib/threadline/query.ex
  - lib/threadline/query/row_key.ex
  - mix.exs
  - priv/repo/migrations/20260925000000_threadline_row_history_index.exs
  - test/mix/tasks/threadline/gen_row_history_index_test.exs
  - test/threadline/audit_indexing_doc_contract_test.exs
  - test/threadline/operator_surface/transaction_live_test.exs
  - test/threadline/public_surface_contract_test.exs
  - test/threadline/query/row_history_index_explain_test.exs
  - test/threadline/query/row_key_composite_test.exs
  - test/threadline/query/row_key_legacy_test.exs
  - test/threadline/query/row_key_override_test.exs
  - test/threadline/query/row_key_read_test.exs
  - test/threadline/query/row_key_types_test.exs
  - test/threadline/query/row_key_validation_test.exs
  - test/threadline/query_test.exs
  - test/threadline/storage_schema_migration_contract_test.exs
findings:
  critical: 1
  warning: 2
  info: 1
  total: 4
status: issues_found
---

# Phase 211: Code Review Report

**Reviewed:** 2026-09-25
**Depth:** standard
**Files Reviewed:** 15 source files (+ 8 test files read for corroboration)
**Status:** issues_found

## Summary

The read-side agreement work (`Threadline.Query.RowKey`, the `history/3` /
`row_history_query/3` / `as_of/4` rewrite, the row-history index, and the
composite-key operator-surface guard) is thorough and well-tested against
D-01 through D-13. `String.to_atom/1` is never called on caller input
(confirmed by both code inspection and `row_key_validation_test.exs`'s
explicit `String.to_existing_atom` regression check). The whole-map `=`
match against `table_pk`, the `format_type`-driven catalog cast, and the
dropped/renamed-table fallback all behave as the locked decisions require,
and are exercised by real-Postgres tests (`row_key_read_test.exs`,
`row_key_composite_test.exs`, `row_key_types_test.exs`,
`row_history_index_explain_test.exs`). The composite-row-link guard
(`Helpers.routeable_row_ref/1`, reused by `transaction_live.ex`) correctly
excludes composite, `{}`, and `{"id": null}` rows from a row-history link.

One real correctness gap was found in `RowKey.normalize!/2`'s eager
validation: a caller-supplied map/keyword id that contains the *same*
logical key field once as an atom and once as its string form, with two
different values, passes `validate_key_set!/3` (which normalizes both to
strings before comparing as `MapSet`s, silently collapsing the duplicate)
and then silently uses the atom-keyed value while discarding the
string-keyed one — with no error. This directly contradicts D-03's
"A missing, extra or misnamed key ... raises `ArgumentError`" guarantee: a
map with 3 raw keys for a 2-field composite key is an extra key by any
reasonable reading of that contract, yet it is accepted and one of the two
conflicting values is dropped without any signal to the caller. In an audit
product, a query silently resolving to the wrong key value in an ambiguous
input is exactly the class of bug that matters.

Two lower-severity issues were also found: the `column_types!`/`render!`
identifier-safety comment overstates what `validate_type_text!/1` actually
does (a small denylist, not true identifier quoting/escaping), and the
`RowKey.normalize!/2` catch-all struct clause silently treats an
unexpected struct as a scalar for single-column tables instead of
rejecting it explicitly.

## Critical Issues

### CR-01: Ambiguous atom/string duplicate key silently passes D-03 validation and drops a value

**File:** `lib/threadline/query/row_key.ex:168-177` (`validate_key_set!/3`), interacting with `lib/threadline/query/row_key.ex:183-194` (`fetch_field!/3`)

**Issue:** `validate_key_set!/3` compares the *set of distinct field names* the
caller supplied (after string-normalizing every given key) against the set
of expected field names. It never checks that the caller supplied exactly
one key per expected field. Consequently, a map (or keyword list, since
`Keyword.keys/1` can also carry a field under both spellings when built
programmatically) that supplies the same logical field twice — once as an
atom key and once as its string form, with two different values — passes
validation, because `MapSet.new/2` collapses `:tenant_id` and `"tenant_id"`
to the same string and the resulting set still matches expected 1:1.

`fetch_field!/3` then always prefers the atom-keyed value
(`Map.fetch(map, field)` before falling back to
`Map.fetch(map, Atom.to_string(field))`), so the string-keyed value is
discarded with no error, warning, or indication to the caller that their
input was ambiguous.

This directly contradicts the locked D-03 decision:
> "A missing, extra or misnamed key ... raises `ArgumentError`."

A map with 3 distinct raw keys for a 2-field composite key (`%{tenant_id: 1,
"tenant_id" => 99, id: 5}`) has an extra key under any reasonable reading —
yet `Threadline.history/3` runs the query using `tenant_id: 1`, silently
ignoring `"tenant_id" => 99`, instead of raising. This is a real, testable
gap in the eager-validation guarantee this phase's tests otherwise cover
thoroughly (`row_key_validation_test.exs` never exercises the
atom-vs-string-duplicate case).

**Reproduction (traced, not yet in the test suite):**
```elixir
resolved = Threadline.Query.RowKey.resolve!(RkLineItem) # fields: [tenant_id, id]

# 3 raw keys for a 2-field schema; the string-keyed tenant_id (99) is silently dropped.
Threadline.Query.RowKey.normalize!(resolved, %{tenant_id: 1, "tenant_id" => 99, id: 5})
# => [{:tenant_id, "tenant_id", 1}, {:id, "id", 5}]   -- no ArgumentError raised
```

**Fix:** Validate against the raw `given_keys` list length/uniqueness
directly, not just the string-normalized set — e.g. detect when two given
keys normalize to the same field before deduplicating, and raise the
existing "expected keys ... got ..." error naming the duplicate:

```elixir
defp validate_key_set!(fields, schema, given_keys) do
  expected = MapSet.new(fields, fn {field, _column} -> Atom.to_string(field) end)
  normalized_given = Enum.map(given_keys, &key_to_string/1)
  given = MapSet.new(normalized_given)

  duplicated? = length(normalized_given) != MapSet.size(given)

  unless MapSet.equal?(expected, given) and not duplicated? do
    raise ArgumentError,
          "expected keys #{inspect(field_names(fields))} for #{inspect(schema)}, " <>
            "got #{inspect(given_keys)}"
  end
end
```

## Warnings

### WR-01: `validate_type_text!/1` is a substring denylist, not the "identifier-safe handling" its caller documents

**File:** `lib/threadline/query/row_key.ex:296-302` (`validate_type_text!/1`), referenced from D-05 in `211-CONTEXT.md`: "The type string is interpolated only after identifier-safe handling"

**Issue:** `column_types!/3` reads `format_type(atttypid, atttypmod)` from
the catalog and `render!/3` splices that value, unquoted, directly into
literal SQL text (`CAST($n AS #{cast_type})`). The only guard is
`validate_type_text!/1`, which rejects `;`, a null byte, `--`, and `/*` —
a denylist of a handful of substrings, not actual identifier quoting or an
allowlist of the finite `format_type` output grammar (bare keywords,
`schema.name`, `name(typmod)`, double-quoted identifiers). In practice this
is not exploitable today: `SQL.query!/3` runs over the extended query
protocol (one statement per call, so `;`-based statement injection is moot
regardless of the denylist), and `format_type` itself double-quotes and
escapes any type/domain name that is not a bare unquoted identifier, which
is what actually prevents a maliciously-named type (e.g. a domain named via
`CREATE DOMAIN "int)) OR 1=1 --" AS integer`) from breaking out of the
`CAST(... AS <type>)` position. But the code's own comment ("identifier-safe
handling") claims a guarantee the denylist does not itself provide — the
real safety net is an implicit assumption about `format_type`'s quoting
behavior, undocumented and unenforced in this module. A future PostgreSQL
edge case (custom extension types, unusual array/range type formatting) or
an unrelated refactor of `render!/3` that changes how `cast_type` is used
could silently reintroduce a real injection path with no test to catch it.

**Fix:** Either (a) document explicitly that `validate_type_text!/1` is a
last-resort belt-and-suspenders check and that the real safety property
relies on `format_type`'s own identifier quoting, and add a regression test
asserting a type name requiring quoting (e.g. a domain named with a space
or a SQL keyword) round-trips correctly through `render!/3`; or (b) replace
the denylist with a positive allowlist regex matching the known
`format_type` output shapes (e.g. `^[A-Za-z_][A-Za-z0-9_ ]*(\(\d+(,\d+)?\))?(\[\])?$`
plus a separate branch for double-quoted identifiers), so an unexpected
catalog value fails closed instead of only failing on four specific
substrings.

### WR-02: `RowKey.normalize!/2`'s struct catch-all silently coerces an unrelated struct into a scalar id

**File:** `lib/threadline/query/row_key.ex:122-156`

**Issue:** The struct-rejection clause only matches `is_struct(id, schema)`
(a loaded struct of the *same* schema, per D-01's deferred-struct rule).
Any other struct (e.g. a caller accidentally passing a `%Date{}`,
`%MyApp.SomeOtherSchema{}`, or a typo'd struct) falls through every
subsequent clause — it is not a struct-of-schema, `is_map(id) and not
is_struct(id)` is false (it *is* a struct), `is_list(id)` is false — and
lands on the final single-column clauses, which treat it as an opaque
scalar value for a single-key table. For a composite table it correctly
falls into the "expected keys ... got a single value" branch. For a
single-column table, though, the struct is passed straight to
`dump_value!/4` → `Ecto.Type.cast/2`, which will usually (but not
guaranteed, depending on the Ecto type) fail loudly — but the error the
caller sees is a generic "cannot cast" message rather than the clearer,
purpose-built "struct is not accepted as a row key" message the code
already has for the matching-schema case. This is a minor
message-quality/robustness gap rather than a functional bug (bad structs
are still eventually rejected for every case that matters), but it means
the explicit, well-documented struct-rejection behavior only reliably fires
for the one struct type the tests exercise (`RkLineItemV`/matching-schema
structs).

**Fix:** Broaden the struct guard to `is_struct(id)` (not just
`is_struct(id, schema)`) so any struct gets the clearer, purpose-built
rejection message naming the expected fields, e.g.:

```elixir
def normalize!(%{fields: fields, schema: schema}, id) when is_struct(id) do
  raise ArgumentError,
        "a struct is not accepted as a row key; pass a map or keyword list " <>
          "with #{inspect(field_names(fields))}"
end
```
(placed before the `is_map(id) and not is_struct(id)` clause, as it already is positionally).

## Info

### IN-01: Duplicate keyword-list entries silently take the last value with no diagnostic

**File:** `lib/threadline/query/row_key.ex:133-141, 160-166`

**Issue:** A caller-supplied keyword list with the same atom key repeated
twice with different values (e.g. `[tenant_id: 1, tenant_id: 2, id: 5]`)
passes `Keyword.keyword?/1`, is converted with `Map.new/1` (which keeps the
last occurrence), and `Keyword.keys/1` still reports both occurrences —
but since both normalize to the same string, `validate_key_set!/3` sees no
extra key and the "last value wins" `Map.new/1` semantics silently decide
the outcome. This is the same root cause as CR-01 (validation counts
distinct normalized field names, not raw entries) but for a same-type
duplicate rather than an atom/string spelling duplicate, and is
lower-severity because "last value wins" is standard, unsurprising
`Keyword` semantics that most Elixir developers already expect from a
keyword list — unlike the cross-representation case in CR-01, which is
much more likely to happen by accident (e.g. merging atom-keyed defaults
with string-keyed request params) and much less likely to be anticipated
by the caller.

**Fix:** If CR-01's fix (checking `length(normalized_given) !=
MapSet.size(given)`) is applied, this case is automatically caught by the
same code path and can be left as one consolidated fix.

---

_Reviewed: 2026-09-25_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
