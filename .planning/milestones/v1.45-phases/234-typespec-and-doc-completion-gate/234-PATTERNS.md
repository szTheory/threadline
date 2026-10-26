# Phase 234: Typespec and Doc Completion Gate - Pattern Map

**Mapped:** 2026-10-04
**Files analyzed:** 18 (6 new, 12 modified)
**Analogs found:** 18 / 18

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `test/threadline/doc_spec_coverage_contract_test.exs` (NEW, 234-01) | test (static-analysis contract) | batch (compiled-module introspection) | `test/threadline/source_size_contract_test.exs` | exact (pure-checker + exact-pin ratchet + mutation control + vacuity-guard shape) |
| `test/threadline/doc_rubric_contract_test.exs` or sibling describe block (NEW/EXTENDED, 234-01) | test (static-analysis contract) | batch | `test/threadline/public_surface_contract_test.exs` (hidden-module/pin register) + `facade_naming_contract_test.exs` (`Code.fetch_docs` walking) | role-match |
| `234-SPEC-RUBRIC.md` (NEW, 234-01) | config/doc (committed rubric, not code) | — | none in-repo (first of its kind); use `<specifics>` templates in CONTEXT.md verbatim | no analog |
| `test/threadline/facade_naming_contract_test.exs` (EXTENDED, 234-01/234-02) | test | batch | itself (existing file, already `async: true`) | exact |
| `test/threadline/dialyzer_ignore_contract_test.exs` (EXTENDED, 234-06) | test | batch | itself | exact |
| `test/threadline/source_size_contract_test.exs` (EXTENDED, 234-02) | test | batch | itself | exact |
| `test/partition_weights.txt` (EXTENDED, 234-01) | config | — | itself (existing format) | exact |
| `lib/threadline.ex` (MODIFIED, 234-02) | facade/controller-equivalent (public API surface) | request-response (delegates to Query/Investigation) | itself (existing facade functions) | exact |
| `lib/threadline/query/transaction_lookup.ex` (MODIFIED, 234-02, WR-01) | service (hidden query helper) | CRUD (read) | itself | exact |
| `lib/threadline/investigation.ex` (MODIFIED, 234-02 D-16/D-18) | service (hidden query helper) | CRUD (read) | itself + `transaction_lookup.ex` | exact |
| `lib/threadline/operator_surface/live/actor_live.ex` (MODIFIED, 234-02 D-17) | component (LiveView) | event-driven | itself (call-site edit only) | exact |
| `lib/threadline/operator_surface/controllers/export_controller.ex` (MODIFIED, 234-02 D-17) | controller (Phoenix) | streaming (chunked export) | itself (call-site edit only) | exact |
| `lib/threadline/evidence.ex`, `evidence/proof.ex`, `evidence/subject.ex` (MODIFIED, 234-03) | service | CRUD | `lib/threadline.ex` doc/spec style + `investigation.ex` option-validation style | role-match |
| `lib/threadline/storage_schema.ex`, `continuity.ex`, `job.ex`, `telemetry.ex`, `health.ex` + submodules, `export.ex` + `export_queue/task_adapter.ex`, `retention.ex` + `retention/policy.ex`, `storage.ex`, `change_diff.ex`, `operator_surface/auth.ex`, `operator_surface/router.ex` (MODIFIED, 234-04) | service/middleware/config mix | CRUD / request-response | `transaction_lookup.ex` (option allowlist + `@doc false`/`@spec` pattern), `lib/threadline.ex` (doc rubric) | role-match |
| `lib/threadline/capture/audit_change.ex`, `audit_transaction.ex`, `semantics/audit_action.ex`, `semantics/audit_context.ex`, `semantics/actor_ref.ex`, `page.ex`, `not_found_error.ex`, `investigation/{linked_change,linked_transaction,incident_bundle,incident_change}.ex`, `health/finding.ex` (MODIFIED, 234-05) | model (Ecto schema / struct) | CRUD | `semantics/actor_ref.ex` sketch in CONTEXT `<specifics>`, existing schema files themselves | role-match |
| `mix.exs` (`dialyzer:` flags, `{:ex_doc, ...}` version, `docs()`) (MODIFIED, 234-01/234-02/234-06) | config | — | itself | exact |
| `.dialyzer_ignore.exs` (untouched, asserted `[]`) | config | — | itself | exact |
| `CHANGELOG.md` (MODIFIED, every plan per D-08/D-15/D-49) | doc | — | existing `Unreleased` section conventions (see 232/233 entries) | exact |

## Pattern Assignments

### `test/threadline/doc_spec_coverage_contract_test.exs` (test, batch/static-analysis)

**Analog:** `test/threadline/source_size_contract_test.exs` (exact-pin ratchet pattern) + `public_surface_contract_test.exs` (hidden-register pattern) + the `Code.fetch_docs`/`Code.Typespec` facts verified in RESEARCH.md.

**Exact-pin ratchet shape to copy** (`source_size_contract_test.exs:51-73,391-421,460-497`):
```elixir
@file_exceptions %{
  "lib/threadline/operator_surface/stress_fixtures.ex" =>
    {980, "declarative fixture data tables; excluded from the Hex package (mix.exs exclude_patterns)"}
}

describe "exceptions at rest" do
  test "exactly one named exception remains: ..." do
    assert Map.keys(@file_exceptions) == [...],
           "... a new exception needs a named reason in review, not a quiet pin"
  end
end

defp validate_files(files, exceptions) do
  demand_non_empty!(files, @file_glob)
  validate_reasons!(exceptions)
  measured = Map.new(files, fn {path, source} -> {path, line_count(source)} end)
  measured
  |> compare_exact(exceptions, @file_limit, fn path, value -> "..." end)
  |> report!("file length")
catch
  {:contract_error, message} -> {:error, message}
end

# Measured values must equal their pins exactly. Keys over the limit need a pin;
# a pin whose key is missing, back under the limit, or measured differently fails.
defp compare_exact(measured, exceptions, limit, missing_message) do
  unpinned = for {key, value} <- Enum.sort(measured), value > limit,
                 not Map.has_key?(exceptions, key), do: missing_message.(key, value)
  pinned = exceptions |> Enum.sort()
    |> Enum.map(fn {key, {pin, _reason}} -> pin_problem(key, pin, Map.get(measured, key), limit) end)
    |> Enum.reject(&is_nil/1)
  unpinned ++ pinned
end
```
Copy this `demand!/fail!/throw({:contract_error, ...})` control-flow idiom verbatim — it is the project's standard "pure validator returns `:ok` or raises inside, caught at the boundary into `{:error, message}`" pattern, reused by every contract test in `test/threadline/`.

**Vacuity guard pattern** (`source_size_contract_test.exs:515-521`):
```elixir
defp demand_non_empty!(files, glob) do
  demand!(files != [], "the scanned file set is empty. A broken #{glob} glob would let this " <>
    "contract pass vacuously, which is worse than having no gate at all.")
end
```
Map directly onto D-11's vacuity sentinels (≥50 modules, ≥90 entries, `{Threadline, :timeline, 2}` present).

**Hidden-pin register pattern to copy** (`public_surface_contract_test.exs:6-21`):
```elixir
@hidden_modules [
  Threadline.CriticTrust.Measure,
  ...
  Threadline.Query,
  Threadline.Investigation
]
# D-17/D-18: internal builders hidden from ExDoc but still callable.
@hidden_functions [
  {Threadline.Query, :export_changes_query, 1},
  {Threadline.Query, :export_changes_query, 2}
]
```
Use this exact `@hidden_functions` list-of-tuples shape for D-06's `%{{M, f, a} => "reason"}` pin (a map keyed the same way, with a reason string value instead of just existing).

**`Code.fetch_docs`/`Code.Typespec` facts to build the live wrapper from** (verified in RESEARCH.md, confirmed against real compiled app):
```elixir
{:docs_v1, _anno, _lang, _format, moduledoc, _module_meta, entries} = Code.fetch_docs(Threadline)
# entries :: [{{kind, name, arity}, _anno, _signature, doc, metadata}]
# doc :: :none | :hidden | %{"en" => "markdown"}

{:ok, specs} = Code.Typespec.fetch_specs(SomeModule)
spec_key = if kind == :macro, do: {:"MACRO-#{name}", arity + 1}, else: {name, arity}
has_spec? = Enum.any?(specs, fn {k, _} -> k == spec_key end)
```

**Mutation-control fixture (D-10) — read from the binary, never via module name:**
```elixir
mod_name = :"ScratchCS#{System.unique_integer([:positive])}"
[{mod, bin}] = Code.compile_string(src)
Code.fetch_docs(mod)          # => {:error, :module_not_found} — do NOT use this path for the fixture
:beam_lib.chunks(bin, [~c"Docs"])
Code.Typespec.fetch_specs(bin)
```

**Weight-line pattern to append** (`test/partition_weights.txt:1-9`, sorted-by-path, `<ms> <path>` lines):
```
30 test/threadline/doc_spec_coverage_contract_test.exs
```

---

### `234-SPEC-RUBRIC.md` (doc, committed before any spec/doc write)

**No code analog.** Transcribe D-25 (R1-R5), D-36 (full/floor templates), D-37 (`## Options`/`## Filters` bullet form), D-45 (D-1..D-12, S-1..S-5, M-1..M-3 checklist) verbatim from `234-CONTEXT.md`'s `<decisions>` and `<specifics>` sections — those are the source of truth, already written in final form by the maintainer-accepted research. Do not paraphrase; copy the bullet text.

---

### `test/threadline/facade_naming_contract_test.exs` (test, batch) — new `describe` block for D-33 groups

**Analog:** itself, existing `Code.fetch_docs`-walking style (lines 1-93, already `async: true`).

**Pattern to extend (metadata walk + exact pin):**
```elixir
defp metadata_for(docs, name, arity) do
  Enum.find_value(docs, fn
    {{:function, ^name, ^arity}, _anno, _sig, _doc, metadata} -> metadata
    _ -> nil
  end)
end
```
Add a `describe "facade groups" do` block using this same `Code.fetch_docs(Threadline)` destructure, pinning `{name, arity} => group` for D-33(b), asserting `@moduledoc groups` titles equal the D-30 allowlist in order for D-33(c), and reusing the file's own `paired_names/1`-style pure-helper-plus-fixture-test idiom (lines 23-25, "non-vacuous over a fixture") for D-33(e)'s `ungrouped/2` mutation control.

**`since`/`deprecated` metadata assertion to mirror** (lines 27-55) — same shape, different metadata key (`:group` instead of `:since`/`:deprecated`):
```elixir
for {name, arity} <- [...] do
  metadata = metadata_for(docs, name, arity)
  assert metadata[:since] == "1.0.0", "expected ... got #{inspect(metadata)}"
end
```

---

### `lib/threadline.ex` (facade, request-response) — doc/spec rewrites, types, groups

**Analog:** itself. Current exemplars to follow and extend:

**Existing `## Required options`/`## Optional options` doc shape** (`lib/threadline.ex:44-70`, `record_action/2` — D-37 says this exact split migrates to the new `## Options` form with inline Required/Defaults markers):
```elixir
@doc """
Records a semantic audit action.

## Required options

- `:actor` or `:actor_ref` — `%ActorRef{}` identifying who performed the action
- `:repo` — the `Ecto.Repo` module to use for insertion

## Optional options

- `:status` — `:ok` or `:error` (default: `:ok`)
```

**Existing `@doc since:`/`@deprecated` pairing to copy for new facade entries** (`lib/threadline.ex:271-275,321-325,352-356`):
```elixir
@doc """
...
"""
@doc since: "1.0.0"
@spec row_history(module(), term(), keyword()) :: ...
def row_history(schema_module, id, opts \\ []) when is_list(opts), do: ...
```

**Multi-arity `@spec` stacking for default-argument functions** (`lib/threadline.ex:302-308`):
```elixir
@spec row_history_page(module(), term()) :: Threadline.Page.t(LinkedChange.t())
@spec row_history_page(module(), term(), keyword()) :: Threadline.Page.t(LinkedChange.t())
@spec row_history_page(module(), term(), keyword(), keyword()) :: Threadline.Page.t(LinkedChange.t())
def row_history_page(schema_module, id, filters \\ [], opts \\ []), do: ...
```
D-04 requires a spec only at the max (docs-entry) arity — use this existing stacked-arity style as the shape, but per D-04 the gate only checks the max.

**Moduledoc `## Jobs` replacement target** (`lib/threadline.ex:1-32` is the exact text D-32 replaces — "Reading audit data" bullet list becomes a short `## Jobs` section, one bullet per D-30 group, while preserving the escape-hatch paragraph naming `Threadline.Query.timeline_query/1` verbatim, since `public_surface_contract_test.exs:24-27` pins that exact string as `@escape_hatch_reference`).

**Group mechanism to add** (Ecto precedent, `deps/ecto/lib/ecto/repo.ex:223`, confirmed present):
```elixir
@moduledoc groups: [
  %{title: "Capture & Transactions", description: "..."},
  %{title: "Querying & Timelines", description: "..."},
  %{title: "Actions & Context", description: "..."},
  %{title: "Operations", description: "..."}
]
```
and per function: `@doc group: "Capture & Transactions"` (merges with existing `@doc since:`).

**Named option/filter types** (sketches already written in CONTEXT.md `<specifics>` — copy verbatim and refine keys against the real allowlists in `transaction_lookup.ex:15` and `investigation.ex:18-21`):
```elixir
@typedoc "An `Ecto.Repo` module."
@type repo_opt :: {:repo, module()}
@typedoc "Tenant scoping. `:scope` is opaque to Threadline (R1); it is handed to `:scope_query_fn`."
@type scope_opt :: {:scope, term()} | {:scope_query_fn, scope_query_fn()}
```

---

### `lib/threadline/query/transaction_lookup.ex` (hidden service, CRUD) — WR-01 fix + allowlist model

**Analog:** itself.

**Current allowlist-closing pattern to replicate elsewhere (D-15/D-18)** (`transaction_lookup.ex:15-43`):
```elixir
@lookup_opt_keys [:repo, :storage_schema, :scope, :scope_query_fn]

@spec validate_opts!(keyword(), String.t()) :: :ok
def validate_opts!(opts, function_name) when is_list(opts) and is_binary(function_name) do
  Enum.each(opts, fn
    {key, _value} ->
      if key not in @lookup_opt_keys do
        allowed = Enum.map_join(@lookup_opt_keys, ", ", &inspect/1)
        raise ArgumentError, "unknown #{function_name} option key #{inspect(key)}. Allowed: #{allowed}"
      end
    other ->
      raise ArgumentError, "#{function_name} options must be a keyword list, got entry: #{inspect(other)}"
  end)
  :ok
end
```
This is the canonical per-function allowlist shape (232 D-03 pattern) every closed allowlist in 234-02/234-04 must match — no NimbleOptions.

**WR-01 bug site (`fetch_row/2`, `fetch/2`, lines 97-150):** today `resolve_id/1` is checked before `Keyword.fetch!(opts, :repo)` (line 104/130 comes after the `case resolve_id(id)` branch), so a malformed id with a missing `:repo` returns `:not_found` instead of raising. Fix: hoist `Keyword.fetch!(opts, :repo)` above the `resolve_id/1` call in both functions, matching the well-formed path's raise behavior. Add a mutation control (a test asserting a malformed id + missing `:repo` raises `KeyError`/`ArgumentError`, not `:not_found`).

---

### `lib/threadline/investigation.ex` (hidden service, CRUD) — D-16, drop `:surface` from public allowlist

**Analog:** itself + `transaction_lookup.ex`.

**Current allowlist containing the internal-only key to close** (`investigation.ex:18-21`):
```elixir
@allowed_row_history_filter_keys ~w(from to repo)a
@allowed_actor_window_filter_keys ~w(table from to correlation_id repo)a
@allowed_correlation_bundle_filter_keys ~w(table actor_ref from to repo)a
@row_history_opt_keys ~w(repo from to limit cursor page_size scope scope_query_fn surface storage_schema)a
```
D-16/D-17: once call sites are moved (see below), drop `surface` from `@row_history_opt_keys` (and any sibling `*_opt_keys` lists gaining the same key) so no public allowlist contains an internal-only key.

**Existing deprecated-delegate doc/spec pairing to copy for 234-03/234-04/234-05 narrowing work** (`investigation.ex:46-55`):
```elixir
@deprecated "Use Threadline.row_history/3 instead."
@doc """
Returns row history for one schema row using the retired `(filters, opts)` shape, with 0.12's unbounded default.
"""
@spec row_history(module(), term(), keyword(), keyword()) :: [LinkedChange.t()]
def row_history(schema_module, id, filters, opts) when is_list(filters) and is_list(opts) do
  row_history(schema_module, id, LegacyOpts.row_history(filters, opts))
end
```

---

### `lib/threadline/operator_surface/live/actor_live.ex` + `controllers/export_controller.ex` (D-17 call-site moves)

**Analog:** themselves — only the call target changes, not the surrounding LiveView/controller shape.

**Confirmed literal internal-key call sites to move off the public facade** (`actor_live.ex:32-39,309-318,351-360,394-402,431-439`):
```elixir
Threadline.actor_history(
  actor_ref,
  [
    repo: repo,
    from: from_time,
    scope: socket.assigns[:threadline_scope],
    scope_query_fn: socket.assigns[:threadline_scope_query_fn],
    surface: :actor_history,
    params: %{actor_ref: actor_ref, from: from_time}
  ] ++ storage_schema_opts(socket)
)
```
and (`export_controller.ex:178-179`):
```elixir
scope_opts = [
  scope: conn.assigns[:threadline_scope],
  scope_query_fn: conn.assigns[:threadline_scope_query_fn],
  surface: :export,
  params: %{filters: filters}
]
```
**Fix pattern:** replace these `Threadline.actor_history(...)`/`Export.*(...)` calls with the equivalent hidden `Threadline.Query`/`Threadline.Investigation` function that legitimately accepts `:surface`/`:params` (per D-17). Keep every other option identical; only the module/function name and the now-internal-only keys move. There are 5 call sites in `actor_live.ex` and 1 in `export_controller.ex` — re-grep exact line numbers at execution time since CONTEXT flags D-A2/line drift risk.

---

## Shared Patterns

### Hand-rolled option allowlist (no NimbleOptions)
**Source:** `lib/threadline/query/transaction_lookup.ex:15-43`, `lib/threadline/investigation.ex:18-21`
**Apply to:** every function closed under D-15 (`timeline/2`, `timeline_page/2`, `actor_window/3`, `correlation_bundle/3`, `actor_history/2`, all `Export.*` functions) and every option type narrowed under D-18/D-22.
```elixir
if key not in @allowed_keys do
  allowed = Enum.map_join(@allowed_keys, ", ", &inspect/1)
  raise ArgumentError, "unknown #{function_name} option key #{inspect(key)}. Allowed: #{allowed}"
end
```

### Pure-checker-behind-a-thin-wrapper, exact-pin ratchet, caught via `throw({:contract_error, ...})`
**Source:** `test/threadline/source_size_contract_test.exs` (full file is the canonical model)
**Apply to:** `doc_spec_coverage_contract_test.exs`, any sibling `doc_rubric_contract_test.exs`, the D-33 facade-group test, the D-27 dialyzer-ignore-flags assertion update.
```elixir
defp validate_X(data, exceptions) do
  demand_non_empty!(data, @glob)
  ...
  measured |> compare_exact(exceptions, @limit, &message_fn/2) |> report!("rule name")
catch
  {:contract_error, message} -> {:error, message}
end
```

### `@doc since: "1.0.0"` + `@deprecated` metadata pairing
**Source:** `lib/threadline.ex:271-275,321-325,352-356`; asserted by `test/threadline/facade_naming_contract_test.exs:27-55`
**Apply to:** every newly-documented facade function (D-40: `since` only on names new in 1.0) and every deprecated delegate narrowed in 234-02..234-05.

### `Code.fetch_docs/1` destructure + metadata filter idiom
**Source:** `test/threadline/facade_naming_contract_test.exs:28,57-73`
**Apply to:** `doc_spec_coverage_contract_test.exs`'s live wrapper, the D-33 group test, the D-44 mechanized doc checks (M2-M9).
```elixir
{:docs_v1, _, _, _, _, _, docs} = Code.fetch_docs(module)
docs
|> Enum.filter(fn {{:function, _n, _a}, _anno, _sig, doc, metadata} -> doc != :hidden and ... end)
```

### Partition-weight registration
**Source:** `test/partition_weights.txt:1-9` (header comment + `<ms> <path>` sorted lines), regenerated by `bin/ci-test-partitions --write-weights`
**Apply to:** every new test file in 234-01 (`doc_spec_coverage_contract_test.exs` and, if split out, `doc_rubric_contract_test.exs`).

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `234-SPEC-RUBRIC.md` | doc (rubric, not code) | — | First committed written-rubric file in this codebase; use CONTEXT.md D-25/D-36/D-37/D-45 text verbatim as source of truth rather than an existing analog |
| Named `row_id()`, `json_map`, `export_result()` types (D-19, D-25 R3, D-24) | type definition | — | No existing named type of this shape in the codebase today; CONTEXT `<specifics>` sketches are the only source — copy those sketches, not a codebase analog |

## Metadata

**Analog search scope:** `test/threadline/*.ex`, `lib/threadline.ex`, `lib/threadline/query/`, `lib/threadline/investigation.ex`, `lib/threadline/operator_surface/`, `test/partition_weights.txt`, `deps/ecto/lib/ecto/repo.ex`, `deps/ex_doc/lib/ex_doc/{config,retriever,utils}.ex`
**Files scanned:** 10 read in full/targeted sections, plus 2 CONTEXT/RESEARCH documents
**Pattern extraction date:** 2026-10-04
