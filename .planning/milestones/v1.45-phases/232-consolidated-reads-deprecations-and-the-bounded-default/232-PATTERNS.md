# Phase 232: Consolidated Reads, Deprecations and the Bounded Default - Pattern Map

**Mapped:** 2026-10-03
**Files analyzed:** 16 (new + modified)
**Analogs found:** 15 / 16

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/threadline/page.ex` (NEW) | model (struct) | transform | `lib/threadline/query/actor_history_page.ex` (`Threadline.Query.ActorHistoryPage`) | exact (struct-to-replace-struct) |
| `lib/threadline.ex` — new `row_history/3` facade fn | controller (facade) | CRUD (read) | `lib/threadline.ex` `timeline_page/2` (lines 183-194) + `row_history/4` (lines 196-203) | exact |
| `lib/threadline.ex` — deprecated `history/3`, `row_history/4` (old shape), `*_page/2,3,4` delegates | controller (deprecation shim) | request-response (delegate) | `lib/threadline/query/action_hydration.ex` `extract_action_preload/1` + `maybe_warn_deprecated_action_preload/1` (Phase 231 D-10 precedent) | role-match |
| `lib/threadline/investigation.ex` — `row_history/4` gains cursor mode + 200-cap | service | CRUD (read) + event-driven (telemetry) | `lib/threadline/investigation.ex` `row_history_page/4` (lines 41-48) and `actor_window_page/3` (lines 71-80), same file | exact |
| `lib/threadline/investigation.ex` — `actor_window/3`, `correlation_bundle/3` gain cursor mode | service | CRUD (read) | `lib/threadline/investigation.ex` `actor_window_page/3` / `correlation_bundle_page/3` (lines 71-119), same file | exact |
| `lib/threadline/query.ex` — `row_history/4` split: new 200-cap/`:limit`/`:cursor` logic + deprecated raw unbounded clause | service | CRUD (read) | `lib/threadline/query.ex` `history/3` (lines 389-396) + `row_history_page/4` (lines 53-76), same file | exact |
| `lib/threadline/query.ex` — `TimelinePage` deletion, `timeline_page/2`/`actor_history/2` emit `%Threadline.Page{}` | model + service | transform / CRUD | `lib/threadline/query.ex` `timeline_page/2` (lines 287-324) and `actor_history/2` (lines 505-555) | exact |
| `lib/threadline/query/history_limit.ex` extended (or sibling module) for 200-default + `:infinity` | utility (validator) | transform | `lib/threadline/query/history_limit.ex` (whole file, 16 lines — the `validate!`/`apply` pair to extend) | exact |
| `lib/threadline/query/cursors.ex` — generalize limit+1 `has_more` for `timeline_page_next_cursor/2` and new cursor-mode paths | utility | transform | `lib/threadline/query/cursors.ex` `actor_history_trim/3` (lines 74-84) and `actor_history_page/4` (lines 97-107) | exact |
| `lib/threadline/telemetry.ex` — register `[:threadline, :row_history, :truncated]`, add `emit_row_history_truncated/2`, hide 8 `emit_*` with `@doc false` | utility (telemetry) | event-driven | `lib/threadline/telemetry.ex` `emit_health_checked_error/1` (lines 211-217, metadata-shape precedent) + `emit_export_completed/4` (lines 296-306, measurement/duration precedent) | exact |
| `lib/threadline/export.ex` — update `stream_changes/2`/`stream_export_rows/2` to `%Threadline.Page{}` field names | service | streaming | `lib/threadline/export.ex` `stream_changes/2` (lines 321-347) and `split_truncated/2` (lines 407-413, D-14 template) | exact |
| `lib/threadline/operator_surface/live/row_history_component.ex` — `Threadline.history/3` → `Threadline.row_history/3, limit: :infinity` | component (LiveView) | request-response | same file, lines 26-57 (the call site itself, forced edit not a new pattern) | exact (self) |
| `lib/threadline/operator_surface/live/actor_live.ex` — `:after`/`:before` → `:cursor`/`{:before, map}` on the "newer" button | component (LiveView) | request-response | same file, `handle_event("next-page", ...)` (lines 306-346) and `handle_event("prev-page", ...)` (lines 348-388) | exact (self) |
| `test/threadline/row_history_test.exs` (NEW) | test | CRUD / cursor-walk | `test/threadline/query_test.exs` `actor_history/2` page tests (lines 763-785, 1235, 1383) | role-match |
| `test/threadline/page_test.exs` (NEW) | test | transform | `test/threadline/query_test.exs` `ActorHistoryPage`/`TimelinePage` struct-shape assertions | role-match |
| `test/threadline/public_surface_contract_test.exs`, `test/threadline/facade_only_references_contract_test.exs`, `test/threadline/telemetry_registry_contract_test.exs` (extended, not new) | test (contract) | transform | same three files, existing `@hidden_modules`/`@hidden_module_child_structs` (lines 6-37) and regex-offender machinery (lines 1-90) | exact (self) |

## Pattern Assignments

### `lib/threadline/page.ex` (NEW struct)

**Analog:** `lib/threadline/query/actor_history_page.ex` (verbatim, whole file — delete this one and `TimelinePage` once `Page` replaces both)

```elixir
defmodule Threadline.Query.ActorHistoryPage do
  @moduledoc """
  One keyset page from the actor history query layer.
  """

  alias Threadline.Capture.AuditTransaction

  @enforce_keys [:entries]
  defstruct [:entries, :next_cursor, :prev_cursor]

  @type cursor :: %{occurred_at: DateTime.t(), id: String.t()}
  @type t :: %__MODULE__{
          entries: [%AuditTransaction{}],
          next_cursor: cursor() | nil,
          prev_cursor: cursor() | nil
        }
end
```

And the sibling to delete, `lib/threadline/query.ex` lines 17-30:
```elixir
defmodule TimelinePage do
  @moduledoc """
  One keyset page from the timeline query layer.
  """

  @enforce_keys [:entries]
  defstruct [:entries, :next_cursor]

  @type cursor :: %{captured_at: DateTime.t(), id: Ecto.UUID.t()}
  @type t :: %__MODULE__{
          entries: [%AuditChange{}],
          next_cursor: cursor() | nil
        }
end
```

**New shape to build (per D-05/D-06):** `%Threadline.Page{entries, cursor, has_more}` — note the field rename `next_cursor` → `cursor`, and the new boolean `has_more` replacing "cursor present/absent" as the walk-termination signal. This is a visible, documented module (`@doc since: "1.0.0"`), unlike its two predecessors which are hidden inside `@moduledoc false Threadline.Query`.

**Why this analog:** `ActorHistoryPage` is the closer template because it already has two cursor fields and documents them with `@type cursor`; `Page` needs the same `@enforce_keys [:entries]` + typed cursor shape, just collapsed to one `cursor` field plus `has_more`.

---

### `lib/threadline.ex` — new `Threadline.row_history/3`

**Analog:** same file, `timeline_page/2` (facade doc style) and `row_history/4` (existing discoverable-helper delegate), lines 196-209:

```elixir
@doc """
Returns the investigation slice for one schema row.

This is the discoverable row-history helper for operators who want one row's
changes without assembling table and primary-key predicates manually.
"""
def row_history(schema_module, id, filters \\ [], opts \\ []),
  do: Investigation.row_history(schema_module, id, filters, opts)

@doc """
Returns one keyset page of row history for a single schema row.
"""
def row_history_page(schema_module, id, filters \\ [], opts \\ []),
  do: Investigation.row_history_page(schema_module, id, filters, opts)
```

**D-12 arity-collision guard — copy this shape exactly:**
```elixir
# New, non-deprecated — owns /2 and /3, no @deprecated:
def row_history(schema, id, opts \\ []), do: Investigation.row_history(schema, id, opts)

# Retired old 4-arity shape — a SEPARATE clause, literal arity, no defaults:
@deprecated "Use Threadline.row_history/3 instead."
@doc "..."
def row_history(schema, id, filters, opts) when is_list(filters) and is_list(opts) do
  # merges filters into opts, preserves unbounded via limit: :infinity (D-04)
end
```
This mirrors the one hard constraint D-12 names: `@deprecated` + `\\` defaults on one clause tags every arity those defaults generate, so the new/retired shapes must be two distinct function clauses, not one clause with an extra default arg.

**Cursor-mode dispatch to add (per D-07), illustrative — not yet in the tree:**
```elixir
if Keyword.has_key?(opts, :cursor) do
  cursor = Keyword.fetch!(opts, :cursor)
  if is_nil(cursor) do
    raise ArgumentError, "cursor: nil is invalid — pass cursor: :start to begin a walk"
  end
  # ... Page mode ...
else
  # ... bare-list mode, apply the 200/:limit/:infinity cap ...
end
```
Use `Keyword.has_key?/2`, never `Keyword.get/2` — the latter cannot distinguish "caller omitted `:cursor`" from "caller passed `cursor: nil`," which must raise per D-07.

---

### `lib/threadline.ex` — deprecated delegates (`history/3`, old `row_history/4`, `*_page/2,3,4`)

**Analog:** Phase 231's `preload: :action` deprecation precedent, `lib/threadline/query/action_hydration.ex` lines 162-172 (runtime-warning mechanism for D-09's legacy `actor_history/2` options — `IO.warn` vs `Logger.warning` choice should stay consistent with this):

```elixir
@doc false
def maybe_warn_deprecated_action_preload(false), do: :ok

def maybe_warn_deprecated_action_preload(true) do
  IO.warn(
    "Threadline: preloading :action is deprecated and will be removed no earlier than " <>
      "Threadline 2.0. AuditTransaction no longer declares an :action association. Drop " <>
      ":action from :preload; Threadline.transaction_context/2 and " <>
      "Threadline.incident_bundle/2 return the linked AuditAction."
  )
end
```

**Compile-time `@deprecated` + own `@doc` pattern (D-11) — every retired name needs this, not `@doc false`:**
```elixir
@deprecated "Use Threadline.row_history/3 instead."
@doc """
Deprecated. Use `row_history/3` with `limit: :infinity` for the same
unbounded, plain-`AuditChange` behavior.
"""
def history(schema_module, id, opts), do: Threadline.Query.history(schema_module, id, opts)
```
(current, pre-deprecation version at `lib/threadline.ex` lines 86-124 — keep the `@doc`, add `@deprecated`, keep the implementation delegating to the hidden raw-read path per D-02, not to `row_history/3`'s hydrated result.)

**Note (D-11):** deprecated delegates inside the hidden `Query`/`Investigation` modules (`@moduledoc false`) still need their own `@deprecated` + `@doc` — `@moduledoc false` does not suppress the function-level warning, verified by the researcher. Do not special-case these as already-hidden-therefore-skippable.

---

### `lib/threadline/query.ex` / `lib/threadline/investigation.ex` — row_history 200-cap + cursor mode

**Analog (bare-list unbounded cap, to extend for the 200-default):** `lib/threadline/query.ex` `history/3`, lines 389-396:
```elixir
def history(schema_module, id, opts) do
  repo = Keyword.fetch!(opts, :repo)
  HistoryLimit.validate!(Keyword.get(opts, :limit))

  schema_module
  |> history_query(id, Keyword.put(opts, :repo, repo))
  |> repo.all(storage_opts([], opts))
end
```

**Analog (keyset page construction, to extend with limit+1/has_more per D-08):** `lib/threadline/query.ex` `row_history_page/4`, lines 50-76:
```elixir
@spec row_history_page(module(), term(), keyword(), keyword()) :: TimelinePage.t()
def row_history_page(schema_module, id, filters \\ [], opts \\ [])
    when is_list(filters) and is_list(opts) do
  validate_row_history_filters!(filters)
  repo = timeline_repo!(filters, opts)

  page_size =
    Cursors.timeline_page_size!(Keyword.get(opts, :page_size, @default_timeline_page_size))

  cursor = Cursors.validate_timeline_cursor!(Keyword.get(opts, :cursor))

  entries =
    schema_module
    |> row_history_query(id, Keyword.put(filters, :repo, repo))
    |> maybe_apply_scope(row_history_scope_opts(schema_module, id, opts))
    |> maybe_after_timeline_cursor(cursor)
    |> limit(^page_size)
    |> repo.all(storage_opts(filters, opts))

  %TimelinePage{
    entries: entries,
    next_cursor: Cursors.timeline_page_next_cursor(entries, page_size)
  }
end
```
This `limit(^page_size)` fetch must become `limit(^(page_size + 1))` with the extra row dropped — see the `has_more` pattern below.

**Investigation-layer hydration wrapper to extend:** `lib/threadline/investigation.ex` `row_history/4` and `row_history_page/4`, lines 28-48:
```elixir
def row_history(schema_module, id, filters \\ [], opts \\ []) do
  filters = validate_helper_filters!(filters, @allowed_row_history_filter_keys, :row_history)

  schema_module
  |> Query.row_history(id, filters, opts)
  |> linked_changes(opts)
end

def row_history_page(schema_module, id, filters \\ [], opts \\ []) do
  filters =
    validate_helper_filters!(filters, @allowed_row_history_filter_keys, :row_history_page)

  schema_module
  |> Query.row_history_page(id, filters, opts)
  |> linked_page(opts)
end
```
and the hydration helpers used by both, lines 200-222:
```elixir
defp linked_page(%TimelinePage{} = page, opts) do
  %TimelinePage{page | entries: linked_changes(page.entries, opts)}
end

defp linked_changes(changes, opts) when is_list(changes) do
  repo = Query.timeline_repo!([], opts)

  changes
  |> Query.preload_investigation_context(repo, opts)
  |> to_linked_changes()
end

defp to_linked_changes(changes) do
  Enum.map(changes, fn audit_change ->
    transaction = audit_change.transaction

    %LinkedChange{
      audit_change: audit_change,
      transaction: transaction,
      action: linked_action(transaction)
    }
  end)
end
```
`linked_page/2` is the exact spot that needs its struct-match updated from `%TimelinePage{}` to `%Threadline.Page{}` once that rename lands (D-05/D-01).

---

### `has_more` exact-boundary fix (D-08) — apply everywhere a page is produced

**Template to copy (already correct), `lib/threadline/query/cursors.ex` lines 74-107:**
```elixir
# The query fetched `limit + 1` rows; the extra row only signals that more
# records exist. Returns the page in descending order and that signal.
def actor_history_trim(entries, limit, reverse?) do
  has_more? = length(entries) > limit
  {trim_actor_history(entries, limit, has_more?, reverse?), has_more?}
end

defp trim_actor_history(entries, _limit, true, true),
  do: entries |> Enum.reverse() |> Enum.drop(1)

defp trim_actor_history(entries, limit, true, false), do: Enum.take(entries, limit)
defp trim_actor_history(entries, _limit, false, true), do: Enum.reverse(entries)
defp trim_actor_history(entries, _limit, false, false), do: entries
```
and the fetch site that feeds it, `lib/threadline/query.ex` lines 542-545:
```elixir
entries_raw =
  query
  |> limit(^(limit + 1))
  |> repo.all(storage_opts([], opts))
```

**Bug this fix replaces, `lib/threadline/query/cursors.ex` lines 173-178 (`timeline_page_next_cursor/2`):**
```elixir
def timeline_page_next_cursor(entries, page_size) when length(entries) < page_size, do: nil

def timeline_page_next_cursor(entries, _page_size) do
  last = List.last(entries)
  %{captured_at: last.captured_at, id: last.id}
end
```
This returns a non-nil cursor whenever `length(entries) == page_size`, even with no further rows — the exact-multiple-of-page_size bug D-08/SC1 names. Every paged read (`timeline_page/2`, `row_history/3` cursor mode, `actor_window/3`/`correlation_bundle/3` cursor mode) must go through the limit+1-and-drop shape instead.

---

### Truncation telemetry (D-14/D-15)

**Detection-probe analog (same limit+1 shape, applied to truncation detection not cursors), `lib/threadline/export.ex` lines 407-413:**
```elixir
defp split_truncated(rows, max_rows) do
  if length(rows) > max_rows do
    {true, Enum.take(rows, max_rows)}
  else
    {false, rows}
  end
end
```
Apply the same shape to `row_history/3`'s bare-list default path: fetch `limit: 201` internally, `{truncated?, entries} = split_truncated(rows, 200)`, emit `[:threadline, :row_history, :truncated]` only when `truncated?`. Do NOT use `length(entries) == limit` (that false-positives when a row has exactly 200 real changes — D-14 explicitly overrides this weaker rule).

**Event-registration analog, `lib/threadline/telemetry.ex` lines 57-152 (`@events` list) — add one entry shaped like this:**
```elixir
%{
  name: [:threadline, :health, :checked, :error],
  measurements: [],
  metadata: [:exception],
  when: "a polled coverage check raises"
},
```
New entry per D-15:
```elixir
%{
  name: [:threadline, :row_history, :truncated],
  measurements: [:limit],
  metadata: [:schema],
  when: "row_history/3's implicit 200-row default cap actually truncated results"
}
```

**Emit-function analog (module-atom-only metadata, mirrors the no-row-data rule), `lib/threadline/telemetry.ex` lines 211-217 (`emit_health_checked_error/1`):**
```elixir
def emit_health_checked_error(exception) when is_exception(exception) do
  :telemetry.execute(
    [:threadline, :health, :checked, :error],
    %{},
    %{exception: exception.__struct__}
  )
end
```
New function per D-15 (metadata `%{schema: schema_module}`, a bare module atom, never a string table name):
```elixir
@doc false
def emit_row_history_truncated(limit, schema_module) when is_atom(schema_module) do
  :telemetry.execute(
    [:threadline, :row_history, :truncated],
    %{limit: limit},
    %{schema: schema_module}
  )
end
```

**Registry-contract test to extend:** add a `drive_row_history_truncated!/0` call to `drive_all!/0` in `test/threadline/telemetry_registry_contract_test.exs`, following whatever sibling `drive_*!/0` function already exists for `emit_health_checked_error/1` there (grep that file for `drive_health_checked_error` as the exact sibling to copy).

---

### Internal callers forced to opt out of the cap (D-16)

**`lib/threadline/operator_surface/live/row_history_component.ex` lines 26-41 (current, to edit):**
```elixir
if schema_module do
  opts = [
    repo: assigns.repo,
    scope: assigns[:scope],
    scope_query_fn: assigns[:scope_query_fn]
  ]

  try do
    history = Threadline.history(schema_module, assigns.record_id, opts)
    ...
```
Change to `Threadline.row_history(schema_module, assigns.record_id, opts ++ [limit: :infinity])` (or add `limit: :infinity` to the `opts` list directly) — a bare rename would silently cap the drawer at 200 rows, which is the exact regression Pitfall 3 names.

**`lib/threadline/operator_surface/live/actor_live.ex` — the forced `:cursor`/`{:before, map}` edit (D-09), current `next-page`/`prev-page` handlers, lines 306-388:**
```elixir
def handle_event("next-page", _, socket) do
  if socket.assigns.next_cursor do
    page =
      Threadline.actor_history(
        socket.assigns.actor_ref,
        [
          repo: socket.assigns.repo,
          from: socket.assigns.from_time,
          after: socket.assigns.next_cursor,
          ...
        ] ++ storage_schema_opts(socket)
      )
    ...
```
and:
```elixir
def handle_event("prev-page", _, socket) do
  if socket.assigns.prev_cursor do
    page =
      Threadline.actor_history(
        socket.assigns.actor_ref,
        [
          repo: socket.assigns.repo,
          from: socket.assigns.from_time,
          before: socket.assigns.prev_cursor,
          ...
        ] ++ storage_schema_opts(socket)
      )
    ...
```
Per D-09, the "newer" button (today's `prev-page`/`:before` path) is the forced call-site edit: build `{:before, %{occurred_at, id}}` from the first entry and pass it as `cursor:` instead of the legacy `:before` key. Legacy `:after`/`:before`/`:limit` keep working (with a runtime deprecation warning per D-09, following the `IO.warn` precedent above) — this call site is a required, not merely cosmetic, edit because it is in-tree code and D-13 bans in-tree calls to deprecated names/options once a canonical replacement exists.

---

### `lib/threadline/export.ex` — `%Threadline.Page{}` field-name update

**Analog, `lib/threadline/export.ex` `stream_changes/2`, lines 321-347 (the walk loop named in D-08's re-verify instruction):**
```elixir
@spec stream_changes(keyword(), keyword()) :: Enumerable.t()
def stream_changes(filters, opts \\ []) when is_list(filters) and is_list(opts) do
  Query.validate_timeline_filters!(filters)

  Stream.resource(
    fn -> :start end,
    fn
      :done ->
        {:halt, :done}

      state ->
        cursor = if state == :start, do: nil, else: state

        case Query.timeline_page(filters, Keyword.put(opts, :cursor, cursor)) do
          %Query.TimelinePage{entries: []} ->
            {:halt, :done}

          %Query.TimelinePage{entries: rows, next_cursor: nil} ->
            {rows, :done}

          %Query.TimelinePage{entries: rows, next_cursor: next_cursor} ->
            {rows, next_cursor}
        end
    end,
    fn _ -> :ok end
  )
end
```
Update every `%Query.TimelinePage{...}` pattern match to `%Threadline.Page{...}`, and `next_cursor` → `cursor`; additionally the `has_more`-boolean replaces "cursor is nil" as the authoritative "stop walking" signal once D-08 lands (today's code conflates "no `next_cursor`" with "no more rows," which is exactly the bug D-08 fixes — this call site needs the same re-verification, per the RESEARCH.md's explicit note to re-check `lib/threadline/export.ex` around this line range).

---

## Shared Patterns

### Deprecation-delegate shape (D-11)
**Source:** `lib/threadline/query/action_hydration.ex` lines 162-172 (`maybe_warn_deprecated_action_preload/1`) and `lib/threadline.ex` lines 196-233 (the one-line facade-delegate style already used for every `Investigation` function).
**Apply to:** every retired name in the D-11 table (`history/3`, old `row_history/4`, `row_history_page/*`, `actor_window_page/*`, `correlation_bundle_page/*`, and their `Query`/`Investigation` equivalents).
```elixir
@deprecated "Use Threadline.<fun>/<arity> instead."
@doc """
Deprecated. <one line pointing at the replacement + the behavior difference>.
"""
def <retired_name>(...), do: <one-line delegate preserving the old return shape/default>
```

### Arity-collision avoidance (D-12)
**Source:** D-12's "hard constraint, verified experimentally" — no existing in-tree example because this is a new rule for this phase, but the shape is: the new function uses `\\` defaults and owns only the arities its defaults generate; any retired arity is a **separate clause with no defaults**.
**Apply to:** `row_history/2,3` (new, no `@deprecated`) vs. `row_history/4` (old shape, separate clause, `@deprecated`). Add a compile-warning-capture test or similar proving `/2,3` do NOT warn (D-12's explicit ask).

### Exact `has_more` via limit+1 (D-08)
**Source:** `lib/threadline/query/cursors.ex` lines 74-107 (`actor_history_trim/3`, `actor_history_page/4`) + the fetch site at lines 542-545 in `lib/threadline/query.ex`.
**Apply to:** `timeline_page/2`, `row_history/3` cursor mode, `actor_window/3`/`correlation_bundle/3` cursor mode — i.e. every paged read this phase touches.

### Hand-rolled `ArgumentError` validation, no NimbleOptions
**Source:** `lib/threadline/query/cursors.ex` lines 109-171 (`validate_actor_history_cursor!/1`, `validate_timeline_cursor!/1`) and `lib/threadline/query/history_limit.ex` (whole file).
**Apply to:** the new `:cursor`/`:limit` mutual-exclusion check on `row_history/3`, and the `cursor: nil` → raise check (D-07).
```elixir
def validate_timeline_cursor!(nil), do: nil

def validate_timeline_cursor!(%{captured_at: %DateTime{} = captured_at, id: id})
    when is_binary(id) do
  case Ecto.UUID.cast(id) do
    {:ok, canonical} -> %{captured_at: captured_at, id: canonical}
    :error -> raise ArgumentError, ":cursor.id must be a UUID binary, got: #{inspect(id)}"
  end
end
```

### Telemetry: module-atom-only metadata, no row/table-string leakage
**Source:** `lib/threadline/telemetry.ex` lines 211-217 (`emit_health_checked_error/1`, metadata is `%{exception: exception.__struct__}` — a module atom, never the exception message) and lines 296-306 (`emit_export_completed/4`, measurements carry only counts/durations/booleans).
**Apply to:** the new `[:threadline, :row_history, :truncated]` event — metadata `%{schema: schema_module}` (atom), measurements `%{limit: 200}` (integer).

### Contract-test extension machinery (D-18)
**Source:** `test/threadline/public_surface_contract_test.exs` lines 1-70 (`@hidden_modules`, `@hidden_module_child_structs` lists) and `test/threadline/facade_only_references_contract_test.exs` lines 1-90 (`@backtick_regex`/`@call_regex`/`@bare_alias_regex` offender-scanning machinery).
**Apply to:** add `Threadline.Telemetry.emit_*` function-level hiding pins, `Threadline.Query.export_changes_query/1,2`, and the deleted `TimelinePage`/`ActorHistoryPage` names to both files' patterns, each with a non-vacuous fixture self-test (per D-18's explicit requirement — do not add a pattern without a test proving it actually catches something).

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `test/threadline/row_history_test.exs` cursor-walk-to-exact-page-boundary case (SC1) | test (property/integration) | cursor-walk | No existing test exercises "total row count is an exact multiple of page_size" — this is a new scenario this phase introduces precisely because today's code has the bug. Base the test structure on `test/threadline/query_test.exs`'s `actor_history/2` page tests (lines 763-785) but there is no pre-existing exact-boundary case to copy verbatim. |

## Metadata

**Analog search scope:** `lib/threadline.ex`, `lib/threadline/query.ex`, `lib/threadline/investigation.ex`, `lib/threadline/query/cursors.ex`, `lib/threadline/query/history_limit.ex`, `lib/threadline/query/action_hydration.ex`, `lib/threadline/telemetry.ex`, `lib/threadline/export.ex`, `lib/threadline/operator_surface/live/{row_history_component,actor_live}.ex`, `test/threadline/{public_surface_contract,facade_only_references_contract,telemetry_registry_contract,query}_test.exs`
**Files scanned:** 16 read in full or targeted sections this session (all git-tracked; verified via `git ls-files`)
**Pattern extraction date:** 2026-10-03

---
*Phase: 232-consolidated-reads-deprecations-and-the-bounded-default*
