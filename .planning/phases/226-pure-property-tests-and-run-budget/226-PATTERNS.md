# Phase 226: Pure Property Tests and Run Budget - Pattern Map

**Mapped:** 2026-10-01
**Files analyzed:** 14 new, 7 modified
**Analogs found:** 14 / 14 (all have at least a role-match; several exact)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `test/support/property_runs.ex` | utility (test support, env config) | transform | `test/test_helper.exs` (fail-fast env tripwire style) | role-match |
| `test/support/cursor_generators.ex` | test fixture/generator | transform | `test/support/naming_generators.ex` | exact |
| `test/support/change_fact_generators.ex` | test fixture/generator | transform | `test/support/trigger_run_generators.ex` + `test/support/naming_generators.ex` | exact |
| `test/support/redaction_policy_generators.ex` | test fixture/generator | transform | `test/support/naming_generators.ex` | exact |
| `test/support/export_hostile_value_generators.ex` | test fixture/generator | transform | `test/support/naming_generators.ex` | exact |
| `test/support/strict_rfc4180.ex` | utility (independent decoder) | transform | none (new category); nearest shape is any hand-written parser — none exists | no analog |
| `test/threadline/query/cursors_property_test.exs` (PROP-01) | test (property) | CRUD (in-memory model of keyset paging) | `test/threadline/capture/naming_property_test.exs` | exact |
| `test/threadline/change_diff_property_test.exs` (PROP-02) | test (property) | transform | `test/threadline/capture/naming_property_test.exs` | exact |
| `test/threadline/capture/redaction_policy_property_test.exs` (PROP-03) | test (property) | transform/validation | `test/threadline/capture/naming_property_test.exs` | exact |
| `test/threadline/export_property_test.exs` (PROP-05) | test (property) | transform (round-trip encode/decode) | `test/threadline/capture/naming_property_test.exs` | exact |
| `test/threadline/property_scale_contract_test.exs` (PROP-08) | test (contract) | config/YAML parsing | `test/threadline/flake_classifier_contract_test.exs` Test 6 + `test/threadline/ci_topology_contract_test.exs` | exact |
| `test/threadline/property_generator_coverage_test.exs` | test (coverage/sampling) | transform | none exact; nearest is the generator modules themselves (no prior "coverage floor" test exists) | no analog |
| `lib/threadline/query/cursors.ex` (D-01 refactor: new `actor_history_page/4`-style fn) | service/library (pure) | CRUD (list slicing) | itself — existing functions in the same file (`actor_history_trim/3`, `actor_history_cursor/2`) | exact (extend in place) |
| `lib/threadline/export.ex` (D-17 fix: `\r`-quoting) | service/library (pure) | transform (encode) | `dump_csv_to_iodata/1` / `csv_row/2` in the same file | exact (extend in place) |
| `lib/threadline/capture/redaction_policy.ex` (D-18 fix) | service/library (pure, validation) | request-response (validate/raise) | `validate!/1` / `validate_placeholder!/1` / `normalize_columns/1` in the same file | exact (extend in place) |
| `test/threadline/query_test.exs` (D-05 new DB example test) | test (integration, DB) | CRUD | existing `describe "actor_history/2 — QUERY-02"` (~L469) and `describe "timeline_page/2"` (~L756) tests in the same file | exact |
| `test/threadline/mix/trigger_migration_property_test.exs` (D-10 migrate to `PropertyRuns.pure(200)`) | test (property, modify) | transform | itself | exact |
| `test/threadline/capture/trigger_rerun_property_test.exs` (D-10 migrate to `PropertyRuns.db(20)`) | test (property, modify) | event-driven/DB | itself | exact |
| `test/test_helper.exs` (D-08 fail-fast scale check) | config (test bootstrap) | event-driven (startup) | itself — the existing `client_min_messages` / stale-DB tripwire blocks | exact |
| `.github/workflows/flake-detection.yml` (D-09 env on `repeat` step) | config (CI workflow) | event-driven (CI step) | itself — the existing `repeat` step's `env:` block | exact |
| `test/partition_weights.txt` / `bin/ci-test-partitions` (D-24, only if a new file's solo cost > 2s) | config (measured weights) | batch | itself | exact |
| `CONTRIBUTING.md` "Deterministic tests" (D-13) | docs | n/a | itself — existing `mix verify.flake` bullet list | exact |

## Pattern Assignments

### `test/threadline/query/cursors_property_test.exs` (PROP-01) and the other three `*_property_test.exs` files

**Analog:** `test/threadline/capture/naming_property_test.exs` (full file read)

**Header/imports pattern** (lines 1-8):
```elixir
defmodule Threadline.Capture.NamingPropertyTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Threadline.Test.NamingGenerators

  alias Threadline.Capture.Naming
```
Apply verbatim shape to all four new property files, swapping the generator import and the aliased module under test, e.g.:
```elixir
defmodule Threadline.Query.CursorsPropertyTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Threadline.Test.CursorGenerators

  alias Threadline.Query.Cursors
```

**Core property shape** (lines 17-28, 55-63):
```elixir
property "every derived name is a valid identifier of at most 63 bytes" do
  check all(pair <- pair_gen()) do
    for name <- [...] do
      assert byte_size(name) <= 63
      assert name =~ @identifier
    end
  end
end
```
and a comparison-of-two-inputs property:
```elixir
property "distinct tables with distinct hash12 get distinct function names" do
  check all(
          {p1, p2} <- pair_of_pairs_gen(),
          p1 != p2,
          Naming.hash12(Naming.qualified(p1)) != Naming.hash12(Naming.qualified(p2))
        ) do
    refute Naming.function_name(p1) == Naming.function_name(p2)
  end
end
```
This is the `check all(gen, filter_clauses...)` idiom — filter clauses after the generator bind, not a separate `when`.

**`max_runs` call site (now via `PropertyRuns`)** — see `test/threadline/mix/trigger_migration_property_test.exs:23`:
```elixir
check all(pair <- pair_gen(), max_runs: 300) do
```
D-10/D-07 change this literal to `max_runs: PropertyRuns.pure(200)` (import/alias `Threadline.Test.PropertyRuns` at the top of every new/modified property file).

**Named failure messages** — none of the existing property files use a message string on `assert`/`refute` (they rely on ExUnit's default diff). D-04 requires named failure messages for PROP-01's six assertions; use the standard `assert expr, "message"` / `refute expr, "message"` form already used in contract tests, e.g. `ci_topology_contract_test.exs:183`:
```elixir
refute dialyzer_topology_errors(mix_exs, mutated_yaml, contributing) == [],
       "#{control} mutation must make the Dialyzer topology contract fail"
```

**No DB access, no `Threadline.DataCase`** — confirmed convention: every pure property file in the repo is `use ExUnit.Case, async: true` plus `use ExUnitProperties`, never `use Threadline.DataCase`.

---

### `test/support/cursor_generators.ex`, `change_fact_generators.ex`, `redaction_policy_generators.ex`, `export_hostile_value_generators.ex`

**Analog:** `test/support/naming_generators.ex` (full file) and `test/support/trigger_run_generators.ex` (full file)

**Moduledoc-states-the-bias pattern** (`naming_generators.ex:1-6`):
```elixir
defmodule Threadline.Test.NamingGenerators do
  @moduledoc """
  StreamData generators for host table pairs, biased toward the pairs that
  break naive naming: `_`-joined suffixes (public.a_b vs a.b), tables that
  differ only in case, and long tables sharing a 36-byte prefix.
  """

  use ExUnitProperties
```
Every new generator module's moduledoc must name its specific bias the same way (per CONTEXT.md D-02/D-14/D-15/D-16's bias lists), not just describe the type.

**`frequency/2` weighted generator composition** (`naming_generators.ex:34-44`):
```elixir
def pair_gen do
  frequency([
    {4, map(ident(63), &public/1)},
    {3, gen(all(schema <- ident(30), table <- ident(40), do: %{schema: schema, table: table}))},
    {2, gen(all(prefix <- prefix36(), tail <- tail_gen(), do: public(prefix <> tail)))},
    {1,
     gen all(stem <- ident(30), hex <- string(@hex, length: 12)) do
       public(stem <> "_" <> hex)
     end}
  ])
end
```
This is the exact pattern for D-02's `frequency([{5, constant(1)}, {3, integer(2..4)}, {2, integer(5..12)}])` tie-group-size generator and D-15's defect-tag weighting.

**Size-independent, fixed-length composition** (`trigger_run_generators.ex:49-70` — directly cited by CONTEXT.md's "size-independent" requirement for D-14):
```elixir
defp fixed_length_list(_gen, 0), do: constant([])

defp fixed_length_list(gen, n) when n > 0 do
  gen all(head <- gen, tail <- fixed_length_list(gen, n - 1)) do
    [head | tail]
  end
end

def run_sequence do
  gen all(
        length <- length_gen(),
        first <- first_run_gen(),
        rest <- fixed_length_list(later_run_gen(), length - 1)
      ) do
    [first | rest]
  end
end
```
Use this shape for CursorGenerators' tie-group list assembly (D-02) so every group size/count combination is reachable at low StreamData "size", not just at large sizes — directly addresses D-14's "size-independent (`member_of`/`frequency`), so every matrix cell appears within 150 runs" requirement.

**Public helper + private detail split** (`naming_generators.ex:32, 15-25`):
```elixir
def public(table), do: %{schema: "public", table: table}

def ident(max) do
  gen all(head <- member_of(@first), tail <- string(@rest, max_length: max - 1)) do
    <<head>> <> tail
  end
end
```
Mirror for e.g. `ChangeFactGenerators.fact_gen/0` (public, used by the property) plus small private helpers for `op_gen`, `prior_gen`, etc.

**Pair/tuple generators for "two related but distinct inputs"** (`naming_generators.ex:46-76`, `pair_of_pairs_gen/0`) — model for D-14's mixed-key-map generator and D-06's "flip tie-break" scenarios where two correlated values are needed in one `check all`.

---

### `test/support/property_runs.ex` (D-07/D-08)

**Analog pattern — fail-fast, named-variable env tripwire:** `test/test_helper.exs:56-69` (client_min_messages check) and `:83-120` (stale-DB tripwire). Both raise with a message naming the exact variable/condition and the fix:
```elixir
if client_min_messages != "notice" do
  raise """
  Threadline tests: client_min_messages is #{inspect(client_min_messages)}, expected "notice".
  ...
  """
end
```
`PropertyRuns.parse_scale/1` should raise `ArgumentError` with the same "name the variable + the fix/range" convention: `"THREADLINE_PROPERTY_SCALE must be an integer 1..10, got: ..."`.

**Runtime-not-compile-time env read** — there is no existing module-attribute-vs-runtime-read example to copy directly (this is a new pattern for `test/support`), but the surrounding convention (`test_helper.exs` calls `System.get_env` directly inside a running script, never caches at compile time) supports D-07's requirement that `scale/0` read `System.get_env/1` inside the function body on every call.

**Existing anticipatory doc** confirming the exact shape expected — `test/threadline/capture/trigger_rerun_property_test.exs:1-24` moduledoc:
```elixir
@moduledoc """
DB-backed property proving that any chain of 1-4 real
`mix threadline.gen.triggers` runs ... `@max_runs` is a named attribute so a later phase's
environment-driven scale knob can swap it in one line.
"""
...
@max_runs 20

property "a random chain of 1-4 runs rolls back to zero new orphaned capture functions" do
  check all(runs <- run_sequence(), max_runs: @max_runs) do
```
D-10 changes `@max_runs 20` to `@max_runs PropertyRuns.db(20)`.

---

### `test/threadline/property_scale_contract_test.exs` (PROP-08)

**Analog:** `test/threadline/flake_classifier_contract_test.exs` Test 6 (lines 749-846) and `test/threadline/ci_topology_contract_test.exs` (lines 1-60, 120-199)

**Regex-extract-a-committed-constant-from-source pattern** (`flake_classifier_contract_test.exs:763-773`):
```elixir
defp flake_repeats(mix_exs) do
  [_, n] = Regex.run(~r/"verify\.flake":\s*\["test --repeat-until-failure (\d+)"\]/, mix_exs)
  String.to_integer(n)
end

defp budget_seconds(yaml) do
  [_, minutes] =
    Regex.run(~r/timeout --signal=TERM --kill-after=60s (\d+)m mix verify\.flake/, yaml)

  String.to_integer(minutes) * 60
end
```
Use this shape to extract the committed `max_runs` base literals from each `*_property_test.exs` source for D-11(c)'s "every `check all(` uses `PropertyRuns.pure(`/`.db(`" scan.

**Violations-list + reject-passing pattern** (`flake_classifier_contract_test.exs:776-789`):
```elixir
defp sizing_violations(repeats, cold_s, repeat_s, budget_s) do
  needed = cold_s + repeats * repeat_s
  usable = div(budget_s * (100 - @headroom_percent), 100)

  [
    {repeats >= 1 and repeats <= 15, "repeats (#{repeats}) must stay within D-02's bound of 15"},
    {needed <= usable, "..."}
  ]
  |> Enum.reject(&elem(&1, 0))
  |> Enum.map(&elem(&1, 1))
end
```
Mirror this exact `{bool, message} |> Enum.reject |> Enum.map` idiom for `property_scale_violations/...` checking (a) the workflow YAML's `repeat` step has `THREADLINE_PROPERTY_SCALE: "5"`, (b) no `ci.yml` job/step sets it, (c) every `check all(` source match uses `pure(`/`.db(`, (d) CONTRIBUTING.md names the variable.

**Mutation-control test pattern (same-input-really-differs assertion)** (`flake_classifier_contract_test.exs:813-845`, and `ci_topology_contract_test.exs:130-185`):
```elixir
reverted =
  String.replace(
    mix_exs,
    "test --repeat-until-failure #{committed}",
    "test --repeat-until-failure 15"
  )

if committed != 15, do: refute(reverted == mix_exs, "control did not change the input")

assert Enum.any?(sizing_violations(flake_repeats(reverted), ...), &(&1 =~ "over"))
```
and the list-of-named-mutations idiom:
```elixir
mutation_controls = [
  {"PLT timing command", String.replace(yaml, "...", "...")},
  ...
]

for {control, mutated_yaml} <- mutation_controls do
  refute dialyzer_topology_errors(mix_exs, mutated_yaml, contributing) == [],
         "#{control} mutation must make the Dialyzer topology contract fail"
end
```
Use this exact `mutation_controls = [{"label", mutated_string}, ...] |> for {control, mutated} <- ..., refute ...` shape for D-11's five mutation controls (misspelled key, moved to compile step, set to `"1"`, deleted, fixture with hard-coded `max_runs: 300`).

**YAML read helper** (`ci_topology_contract_test.exs:5, 15-17`):
```elixir
@repo_root File.cwd!()

defp read_rel!(segments) when is_list(segments) do
  @repo_root |> Path.join(Path.join(segments)) |> File.read!()
end
```
Reuse for reading `.github/workflows/flake-detection.yml`, `ci.yml`, `CONTRIBUTING.md`, and the property test source files for the D-11(c) source scan. Note CONTEXT.md D-11(b) requires the workflow be *parsed* (step-by-`run:`-content), not matched by a bare top-level string search — `ci_topology_contract_test.exs`'s `workflow_job/2` / `workflow_step/2` helpers (referenced at lines 126-127) are the pattern to extend for "find the step whose `run:` contains `mix verify.flake`".

---

### D-01 refactor target: `lib/threadline/query/cursors.ex` (new `actor_history_page/4`)

**Analog:** the module's own existing functions, `lib/threadline/query/cursors.ex` (full file, 163 lines)

The functions to compose into one new entry point are already individually pure and already follow this file's established style — small top-level `def`s, `@moduledoc false`, no DB access:
```elixir
# lib/threadline/query/cursors.ex:74-91 [exact code to be wrapped/composed]
def actor_history_trim(entries, limit, reverse?) do
  has_more? = length(entries) > limit
  {trim_actor_history(entries, limit, has_more?, reverse?), has_more?}
end
...
def actor_history_cursor(true, %{occurred_at: occurred_at, id: id}),
  do: %{occurred_at: occurred_at, id: id}

def actor_history_cursor(_more?, _entry), do: nil
```
**Call site to replace** — `lib/threadline/query.ex:545-564` (exact text, the glue D-01 says to move):
```elixir
{query, reverse?} = Cursors.actor_history_window(base_query, before_cursor, after_cursor)

entries_raw =
  query
  |> limit(^(limit + 1))
  |> repo.all(storage_opts([], opts))

{entries, has_more?} = Cursors.actor_history_trim(entries_raw, limit, reverse?)

has_next? = if reverse?, do: true, else: has_more?
has_prev? = if reverse?, do: has_more?, else: after_cursor != nil

next_cursor = Cursors.actor_history_cursor(has_next?, List.last(entries))
prev_cursor = Cursors.actor_history_cursor(has_prev?, List.first(entries))

%Threadline.Query.ActorHistoryPage{
  entries: entries,
  next_cursor: next_cursor,
  prev_cursor: prev_cursor
}
```
D-01's new function takes `raw, limit, reverse?, after_cursor` (everything after the DB fetch) and returns `{entries, next_cursor, prev_cursor}`; `query.ex` keeps only the DB call and the final struct build. D-06.1's mutation control (break the reverse trim, "keep the wrong end") targets `trim_actor_history/4` clauses (`cursors.ex:79-84`); D-06.2's mutation control (flip id tiebreak to `asc`) targets `query.ex:357-361`'s `timeline_order/1`:
```elixir
# lib/threadline/query.ex:357-361 — exact mutation target for D-06.2
defp timeline_order(query) do
  query
  |> order_by([ac], desc: ac.captured_at)
  |> order_by([ac], desc: ac.id)
end
```
and the equivalent `order_by([at], desc: at.occurred_at, desc: at.id)` lines in `actor_history_window/3` (`cursors.ex:57, 63`).

---

### D-05: new DB example test in `test/threadline/query_test.exs`

**Analog:** the existing sibling tests in the same `describe` blocks (not independently re-read line-by-line this session beyond the citations already verified in RESEARCH.md): `describe "actor_history/2 — QUERY-02"` opens at line 469; the tie test "advances safely across captured_at ties without duplicates or skips" is at line 819; its sibling "concatenated pages match eager timeline order exactly" sits around line 795 and builds `eager_ids` via `Threadline.timeline(filters)`.

**Pitfall confirmed by research (do not copy this part):** both existing tests build their expected order via `Threadline.timeline(filters)` — the implementation's own unpaged path, not an independent sort. D-05's new test and the new model-agreement assertion on the existing tie test must compare against the *pure model* (same one PROP-01's property uses), not `eager_ids`, or the DB test becomes tautological (PITFALLS.md Pitfall 3).

---

### D-14: `lib/threadline/change_diff.ex` mutation target

**Analog:** the module's own `build_update_field/4`, `map_has_field?/2`, `map_get/2` (lines 179-224, read in full):
```elixir
defp build_update_field(name, da, cf, before_values) do
  base = %{"name" => name, "after" => map_get(da, name)}

  cond do
    before_values == "none" -> base
    is_map(cf) ->
      if map_has_field?(cf, name) do
        Map.put(base, "before", map_get(cf, name))
      else
        Map.put(base, "prior_state", "omitted")
      end
    true -> base
  end
end

defp map_has_field?(m, name) when is_binary(name) and is_map(m) do
  Map.has_key?(m, name) or atom_key_has?(m, name)
end
```
D-14's mutation control is `map_has_field?(cf, name)` → `map_get(cf, name) != nil` inside `build_update_field/4`'s `cond` — this is the exact one-line patch target for `tools/mutations/change_diff.patch`.

**`before_values_signal/1` note for the oracle (D-14's "none"/"sparse" structural property):**
```elixir
defp before_values_signal(nil), do: "none"
defp before_values_signal(%{}), do: "sparse"
```
CONFIRMED (research-flagged): the second clause matches *any* map including non-empty ones — `"sparse"` is not specific to an empty map. The generator's oracle must replicate this exact matching behavior, not assume `%{}` means literally empty.

---

### D-15: `lib/threadline/capture/redaction_policy.ex` fix + mutation targets

**Analog:** the module itself (full file, 73 lines, read above) — this is simultaneously the property's target and the D-18 fix site.

**D-15 mutation control 1** (remove `String.trim/1`), exact target (`redaction_policy.ex:64-69`):
```elixir
defp normalize_columns(list) when is_list(list) do
  list
  |> Enum.map(&to_string/1)
  |> Enum.map(&String.trim/1)
  |> Enum.reject(&(&1 == ""))
end
```

**D-15 mutation control 2** (`>` → `>=` on length check), exact target (`redaction_policy.ex:51-54`):
```elixir
if String.length(placeholder) > @max_placeholder_length do
  raise ArgumentError, "placeholder exceeds max length (#{@max_placeholder_length})"
end
```

**D-18 fix site 1** — the silent-`[]` catch-all to replace with a raise (`redaction_policy.ex:71`):
```elixir
defp normalize_columns(_), do: []
```
Must become an `ArgumentError`-raising clause for non-list input (the "exclude/mask must be a list" message D-18 specifies). Note the overlap-message style to match for consistency (`redaction_policy.ex:26-28`):
```elixir
raise ArgumentError,
      "exclude and mask overlap on columns: #{cols}. " <>
        "Column #{inspect(sample)} cannot be both excluded and masked."
```

**D-18 fix site 2** — `validate_placeholder!/1` has only one clause guarding `is_binary/1` (`redaction_policy.ex:46`), so any non-binary falls through to `FunctionClauseError`; add a catch-all clause here that raises `ArgumentError` instead, following the existing message style at lines 48, 52-53, 58.

---

### D-16: `lib/threadline/export.ex` — D-17 fix seam and mutation targets

**Analog:** the module's own `dump_csv_to_iodata/1`, `csv_row/2`, `change_map/1`, `datetime_iso/1` (read in full above, lines 215-460).

**D-17 fix seam** — confirmed no pre-quoting step exists anywhere upstream (`export.ex:277-281`):
```elixir
defp dump_csv_to_iodata(rows) do
  rows
  |> RFC4180.dump_to_iodata()
  |> Enum.map(&IO.iodata_to_binary/1)
end
```
`csv_row/2` builds plain strings with no transformation (`export.ex:387-417`, e.g. `Jason.encode!(row.data_after || %{})` at line 404) and passes them straight to `dump_csv_to_iodata/1`. Per RESEARCH.md's Open Question 2, the lower-risk mechanism is a new private field-level pre-quote function inserted between `csv_row/2`'s list construction and `dump_csv_to_iodata/1`'s call — wrap any field containing `\r` in `"..."` with internal `"` doubled, matching RFC 4180's own quoting convention NimbleCSV already uses for comma/quote/`\n`.

**D-16/D-23 mutation-control target** (`datetime_iso/1`, duplicated in both `export.ex:456-457` and `change_diff.ex:108-109`):
```elixir
defp datetime_iso(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
defp datetime_iso(nil), do: nil
```
Mutation control: truncate to `:second` (e.g. `DateTime.to_iso8601(DateTime.truncate(dt, :second))`).

**D-19 nil-default asymmetry to pin (not change)** — confirmed exact and verbatim:
```elixir
# change_map/1 (JSON), export.ex:419-430 — keeps nil for data_after
"table_pk" => row.table_pk || %{},
"data_after" => row.data_after,              # no || %{} fallback: JSON keeps null
"changed_fields" => row.changed_fields || [],
"changed_from" => row.changed_from || %{},
```
```elixir
# csv_row/2, export.ex:404 — turns nil data_after into "{}"
Jason.encode!(row.data_after || %{})
```

**JSON decoder convention for the independent test-side decoder:** `Jason.decode!/1` is already the only decoder used anywhere in the test suite for JSON — no project-specific JSON-decoding wrapper exists; use it directly per D-16.

---

## Shared Patterns

### Env-driven scale, read at runtime, never a module attribute (D-07)
**Source:** no direct precedent in `test/support` (this is new), but the surrounding convention is `test/test_helper.exs`'s runtime `System.get_env`-based tripwires (lines 1-121, read in full).
**Apply to:** `property_runs.ex` and every `*_property_test.exs`/`property_scale_contract_test.exs` file that calls `PropertyRuns.scale/0`, `.pure/1`, or `.db/1`.

### Fail-fast with a named variable and valid range in the raise message
**Source:** `test/test_helper.exs:34-41, 59-68, 108-120` (three existing tripwires, same shape: raise a multi-line string naming the exact cause and the fix).
**Apply to:** `PropertyRuns.parse_scale/1`'s `ArgumentError` messages (D-07) and `test_helper.exs`'s own new scale-check addition (D-08).

### Contract test: regex/YAML-extract-then-assert-no-violations, plus named mutation controls that assert the mutated input really differs
**Source:** `test/threadline/flake_classifier_contract_test.exs` Test 6 (lines 749-846) and `test/threadline/ci_topology_contract_test.exs` (lines 1-199).
**Apply to:** `test/threadline/property_scale_contract_test.exs` (PROP-08) in full — this is the single most load-bearing shared pattern for the D-11 test.

### Pure `async: true` property file: `use ExUnit.Case, async: true` + `use ExUnitProperties`, generator imported from `test/support`, never `Threadline.DataCase`
**Source:** `test/threadline/capture/naming_property_test.exs` (full file), `test/threadline/mix/trigger_migration_property_test.exs` (full file).
**Apply to:** all four PROP-01/02/03/05 property files plus `property_scale_contract_test.exs`/`property_generator_coverage_test.exs`.

### Generator module: moduledoc names the specific bias; `frequency/2` for weighted cases; size-independent fixed-length composition for variable-length structures
**Source:** `test/support/naming_generators.ex` (full file), `test/support/trigger_run_generators.ex` (full file).
**Apply to:** all four new `test/support/*_generators.ex` files.

### Mutation-control runner script producing re-runnable, markdown-evidence-emitting proof (D-20)
**Source:** D-20/D-21's own exact spec in CONTEXT.md (no closer prior-phase script exists in-repo to copy; `tools/mutation-control.sh` is new per Claude's Discretion note, but the refuse/apply-with-check/trap-revert/require-green-after shape matches the git-hygiene discipline already used by `bin/ci-test-partitions`'s own fail-closed, nothing-left-behind design, lines 1-60 read above).
**Apply to:** every mutation-control patch under `.planning/phases/226-.../tools/mutations/`.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `test/support/strict_rfc4180.ex` | utility (independent CSV decoder) | transform | No hand-written parser exists anywhere in the repo's test or lib code; this is deliberately new (D-16: "decoding with the encoder's own library hides its quirks"). RFC 4180 itself is the spec to follow, not a codebase analog. |
| `test/threadline/property_generator_coverage_test.exs` | test (sampling/coverage floors) | transform | No prior test samples a generator with `StreamData.seeded/2` and asserts rate floors; this is a new test shape in the repo (D-22). The nearest conceptual precedent is the generator modules' own moduledoc bias statements — the coverage test mechanically verifies those claims. |

## Metadata

**Analog search scope:** `test/support/`, `test/threadline/` (capture, mix, query, root), `lib/threadline/` (query, query/cursors.ex, change_diff.ex, capture/redaction_policy.ex, export.ex), `.github/workflows/`, `bin/`, `CONTRIBUTING.md`
**Files scanned:** 16 read in full or targeted-range this session (naming_property_test.exs, naming_generators.ex, trigger_migration_property_test.exs, trigger_run_generators.ex, flake_classifier_contract_test.exs ×2 ranges, flake-detection.yml, test_helper.exs, cursors.ex, query.ex ×2 ranges, redaction_policy.ex, change_diff.ex, export.ex ×2 ranges, ci_topology_contract_test.exs ×2 ranges, partition_weights.txt head, bin/ci-test-partitions head, CONTRIBUTING.md Deterministic-tests section) plus 226-CONTEXT.md and 226-RESEARCH.md (both already contain re-verified line citations into every target `lib/` file for this phase).
**Pattern extraction date:** 2026-10-01

---

*Phase: 226-pure-property-tests-and-run-budget*
