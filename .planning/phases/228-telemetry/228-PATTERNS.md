# Phase 228: Telemetry - Pattern Map

**Mapped:** 2026-10-01
**Files analyzed:** 14 (4 lib files extended, 3 lib emitter call sites, 1 lib event-stripping site x4 callers, 2 new test files, 2 existing test files extended, 1 new guide, 2 config/index files)
**Analogs found:** 14 / 14 (every file to touch already exists in the codebase; this phase extends existing files rather than creating net-new architectural shapes, except the two new test files which have strong existing analogs)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/threadline/telemetry.ex` (extend: export + retention helpers, strip 3 identity fields) | utility (telemetry registry/emitter) | event-driven | itself (`transaction_committed/2`, `emit_health_checked_error/1`) — self-extension | exact |
| `lib/threadline/export.ex` (`to_csv_iodata/2`, `to_json_document/2`) | service (CRUD read + transform) | request-response + event-driven (add emit) | same file's existing `try`-less body; sibling pattern: `orchestrator.ex`'s `try/rescue` + `mark_failed` | role-match |
| `lib/threadline/export/orchestrator.ex` (`run_job/3`, `handle_transaction_result/4`, `persist_export/7`) | service (job orchestration) | event-driven (Oban/Task job) | itself — already has the `try/rescue` + multi-branch-failure shape D-04..D-07 extend | exact |
| `lib/threadline/operator_surface/controllers/export_controller.ex` (`send_chunked_stream/4`) | controller (Phoenix chunked response) | streaming | same file's eager-download clauses (`send_resp` branches above it, lines ~200-226) | role-match |
| `lib/threadline/retention.ex` (`purge/1`, `run_with_tracking/7`, `purge_loop/7`) | service (batch job) | batch + event-driven (span) | `export/orchestrator.ex`'s job-tracking pattern (`RetentionRun`/`ExportJob` both insert-then-update a run record) | role-match |
| `lib/threadline/operator_surface/auth.ex` (`emit_telemetry/3`, `emit_actor_mismatch/2`) | middleware (LiveView on_mount auth) | event-driven | sibling emitters in `theme_auth_plug.ex` / `export_auth_plug.ex` | exact |
| `lib/threadline/operator_surface/theme_auth_plug.ex` | middleware (Plug) | event-driven | `export_auth_plug.ex` (same shape, different plug) | exact |
| `lib/threadline/operator_surface/export_auth_plug.ex` | middleware (Plug) | event-driven | `theme_auth_plug.ex` | exact |
| `lib/threadline/operator_surface/coverage/on_mount.ex` (`assign_initial_coverage/1`, `refresh_coverage/1`) | hook (LiveView on_mount) | event-driven | `lib/threadline/operator_surface/live/coverage_live.ex` (`fetch_coverage_for_schema/2`, same rescue+emit shape) | exact |
| `lib/threadline/operator_surface/live/coverage_live.ex` (`fetch_coverage_for_schema/2`) | component (LiveView) | event-driven | `on_mount.ex` (identical rescue+emit idiom) | exact |
| `test/threadline/telemetry_registry_contract_test.exs` (new) | test (contract) | request-response | `test/threadline/health_findings_doc_contract_test.exs` (doc-parity precedent) + `test/threadline/guide_graph_contract_test.exs` (markdown-table-parsing precedent) + `test/support/telemetry_helpers.ex` (`attach_telemetry!/1`) | role-match |
| `test/threadline/telemetry_raising_handler_test.exs` (new) | test (contract) | event-driven | `test/support/telemetry_helpers.ex` (`attach_telemetry!/1`) + the `:telemetry.list_handlers/1` detach semantics | role-match |
| `test/threadline/capture/redaction_leak_property_test.exs` (extend `setup` + per-iteration surfaces) | test (property) | event-driven + batch | itself — `LeakOracle` already reserves `telemetry:<event>` surface names (D-10 in its own moduledoc) | exact |
| `guides/telemetry.md` (new) | config/doc | request-response (docs) | `guides/operator-surface.md` (telemetry-event prose at lines 185, 486) + `guides/production-checklist.md` (alerting prose) | role-match |
| `mix.exs` (`docs` `extras`/`groups_for_extras`), `test/threadline/guide_graph_contract_test.exs` (`@lanes`, guide count) | config | request-response | existing `extras` list entries (e.g. `guides/audit-indexing.md`) added the same way | exact |

## Pattern Assignments

### `lib/threadline/telemetry.ex` (utility, event-driven) — add export + retention helpers, strip identity fields

**Analog:** itself, `transaction_committed/2` and `emit_health_checked_error/1` (lines 56-99, read this session)

**Core execute-only helper pattern** (`lib/threadline/telemetry.ex:56-64`):
```elixir
def transaction_committed(_transaction, opts \\ []) do
  table_count = Keyword.get(opts, :table_count, 0)
  :telemetry.execute([:threadline, :transaction, :committed], %{table_count: table_count}, %{})
end

@doc false
def emit_action_recorded(status) do
  :telemetry.execute([:threadline, :action, :recorded], %{status: status}, %{})
end
```
New `emit_export_completed/2`, `emit_export_failed/2` follow this exact `@doc false` + `:telemetry.execute/3` shape (D-02).

**Span pattern — none exists yet to copy from in this file.** Use the vendored `:telemetry.span/3` contract directly (verified `deps/telemetry/src/telemetry.erl:349-369`): the span function must return `{result, extra_measurements_map, stop_metadata_map}` (3-tuple), since `:telemetry` does NOT merge start metadata into stop:
```erlang
% Source: deps/telemetry/src/telemetry.erl:349-369 (read this session)
execute(EventPrefix ++ [start], ..., merge_ctx(StartMetadata, DefaultCtx)),
try SpanFunction() of
  {Result, ExtraMeasurements, StopMetadata} ->
    execute(EventPrefix ++ [stop], Measurements, merge_ctx(StopMetadata, DefaultCtx)), Result
catch
  Class:Reason:Stacktrace ->
    execute(EventPrefix ++ [exception], ..., merge_ctx(StartMetadata#{kind=>Class, reason=>Reason, stacktrace=>Stacktrace}, DefaultCtx)),
    erlang:raise(Class, Reason, Stacktrace)
end.
```
So `Threadline.Telemetry.purge_span/2` (name at planner's discretion) wraps `:telemetry.span([:threadline, :retention, :purge], %{dry_run: dry_run?}, fn -> ... end)` where the inner fn returns `{result, Map.take(result, [:deleted_changes, :deleted_transactions, :batches_run]), %{dry_run: dry_run?}}` (D-09, verbatim).

**Breaking signature change** — `emit_health_checked_error/1` (lines 93-99):
```elixir
# Current (to be replaced per D-17 + D-03):
def emit_health_checked_error(error_message) when is_binary(error_message) do
  :telemetry.execute([:threadline, :health, :checked, :error], %{}, %{error: error_message})
end
```
New shape takes an exception struct, not a binary (D-03: "Helpers accept only integers, booleans, atoms and exception structs"):
```elixir
def emit_health_checked_error(exception) when is_exception(exception) do
  :telemetry.execute(
    [:threadline, :health, :checked, :error],
    %{},
    %{exception: exception.__struct__}
  )
end
```

**Moduledoc table** — replace the "five events" prose list (lines 5-29) with a single markdown table per D-15, every event name + measurement keys + metadata keys + "when emitted" sentence, feeding the D-12.3 doc-parity test. Keep the existing `## Usage` `:telemetry.attach/4` example (lines 31-40) as the template for the new guide's per-family examples.

---

### `lib/threadline/export.ex` (service, request-response) — wrap eager functions in try/rescue + emit

**Analog:** `lib/threadline/export/orchestrator.ex:60-74`'s `try/rescue` + `mark_failed` shape (closest existing analog for "wrap a fallible unit of work and emit on both branches" in this codebase, since `export.ex` itself currently has no try/rescue at all)

**Current shape with no telemetry** (`lib/threadline/export.ex:71-103`, `:114-154`):
```elixir
def to_csv_iodata(filters, opts \\ []) when is_list(filters) and is_list(opts) do
  Query.validate_timeline_filters!(filters)          # can raise — BEFORE any clock starts today
  repo = Query.timeline_repo!(filters, opts)
  ...
  rows = repo.all(Query.export_changes_query(filters, opts) |> limit(^limit), Query.storage_opts(filters, opts))
  {truncated, rows} = split_truncated(rows, max_rows)
  ...
  {:ok, %{data: iodata, truncated: truncated, returned_count: length(rows), max_rows: max_rows}}
end
```
Per D-04/D-07: start the clock at function entry (before `validate_timeline_filters!/1`, so a bad-filter raise is still a `:failed` event), wrap the body in `try/rescue`, emit `:completed` with `row_count: length(rows)` (the already-computed `returned_count`, `lib/threadline/export.ex:100`/`:151`) and `truncated` just before the `{:ok, ...}` return, and in the `rescue` clause emit `:failed` with `row_count: 0, error_kind: :exception, exception: e.__struct__` then `reraise e, __STACKTRACE__` (D-07).

**Analog for the try/rescue + reraise idiom** (`lib/threadline/export/orchestrator.ex:60-73`):
```elixir
try do
  transaction_result = ctx.transaction_fn.(fn -> write_temp_csv(temp_path, job, ctx) end, timeout: :infinity)
  handle_transaction_result(transaction_result, job, temp_path, ctx)
rescue
  e ->
    remove_temp_file(temp_path)
    mark_failed(ctx.repo, job, Exception.message(e), ctx.storage_opts)
    {:error, e}
end
```
Note: this analog does NOT reraise (Orchestrator's contract is `{:error, _}`, not exception-propagating) — export.ex's new `rescue` clause must `reraise`, per D-07, unlike this analog.

---

### `lib/threadline/export/orchestrator.ex` (service, event-driven) — emit on every `mark_failed` branch + on true success

**Analog:** itself — already has the exact branch structure D-04/D-06/D-07 require

**Every `mark_failed` call site that needs a sibling `emit_export_failed` call** (verified this session):
```elixir
# lib/threadline/export/orchestrator.ex:68-73 (outer rescue)
rescue
  e ->
    remove_temp_file(temp_path)
    mark_failed(ctx.repo, job, Exception.message(e), ctx.storage_opts)
    {:error, e}

# lib/threadline/export/orchestrator.ex:114-118 (temp file read error)
{:error, reason} ->
  remove_temp_file(temp_path)
  mark_failed(ctx.repo, job, inspect({:temp_file_read_error, reason}), ctx.storage_opts)
  {:error, {:temp_file_read_error, reason}}

# lib/threadline/export/orchestrator.ex:121-125 (transaction_fn returned :error)
defp handle_transaction_result({:error, reason}, job, temp_path, ctx) do
  remove_temp_file(temp_path)
  mark_failed(ctx.repo, job, inspect(reason), ctx.storage_opts)
  {:error, reason}
end

# lib/threadline/export/orchestrator.ex:162-166 (storage write failed)
{:error, reason} ->
  remove_temp_file(temp_path)
  mark_failed(repo, job, inspect({:storage_error, reason}), storage_opts)
  {:error, {:storage_error, reason}}
```
Map each to an `error_kind` per D-06's closed set: outer rescue → `:exception`; temp-file-read-error and the `{:error, reason}` transaction branch → `:transaction_failed`; storage-write failure → `:storage_error`. `row_count` on failure is "rows written before the failure" — per Open Question 3 in RESEARCH.md, this needs an accumulator threaded through `write_temp_csv/3`'s `Enum.each` (switch to `Enum.reduce(0, fn chunk, acc -> ...; acc + length(chunk) end)`), since today nothing counts rows written.

Emit `:completed` only on the true success path — inside `handle_transaction_result({:ok, :written}, ...)`, after `finalize_stored_export/6` returns success (not merely after the DB transaction commits).

---

### `lib/threadline/operator_surface/controllers/export_controller.ex` (controller, streaming) — thread an outcome through `reduce_while`

**Analog:** the same file's eager `send_resp` branches above `send_chunked_stream/4` already have the`{:ok, %{data: iodata}} = Export.to_csv_iodata(...)` shape to mirror once `export.ex` emits.

**Current gap** (`lib/threadline/operator_surface/controllers/export_controller.ex:239-252`):
```elixir
{conn, _} =
  filters
  |> Export.stream_export_rows(Keyword.merge([page_size: @stream_page_size], scope_opts))
  |> Stream.take(@max_rows)
  |> Stream.chunk_every(@chunk_batch_size)
  |> Enum.reduce_while({conn, _first_batch? = true}, fn rows, {conn, first_batch?} ->
    batch_iodata = Encoding.format_batch(rows, format, first_batch?)
    case Plug.Conn.chunk(conn, batch_iodata) do
      {:ok, conn} -> {:cont, {conn, false}}
      {:error, :closed} -> {:halt, {conn, false}}
      {:error, _other} -> {:halt, {conn, false}}
    end
  end)
```
This collapses all three outcomes to the same accumulator shape — **a code change, not just an emit call** (D-04 RESEARCH flags this explicitly). The accumulator must track `{conn, first_batch?, row_count, outcome}` where `outcome` is `:ok | :client_closed | {:error, reason}`, so the function can emit `:completed` (clean finish) or `:failed` with `error_kind: :client_closed` (the `{:error, :closed}` branch specifically, distinct from any other `{:error, _other}`).

---

### `lib/threadline/retention.ex` (service, batch + event-driven) — span wraps only the branch past input checks

**Analog:** itself, `purge/1` (lines 53-84) and `purge_loop/7` (lines 173-215)

**Span-opens-late boundary** (`lib/threadline/retention.ex:53-84`):
```elixir
def purge(opts) when is_list(opts) do
  repo = Keyword.fetch!(opts, :repo)              # raises before any span
  ...
  policy = Policy.resolve!(retention_kw)           # raises before any span
  if policy.enabled != true do
    {:error, :disabled}                            # returns before any span — emits NOTHING
  else
    ...
    if dry_run? do
      dry_run_result(repo, cutoff, policy, storage_opts)   # ← span wraps THIS call
    else
      run_with_tracking(...)                               # ← span wraps THIS call
    end
  end
end
```
Wrap only the `dry_run_result(...)`/`run_with_tracking(...)` call expressions in `Threadline.Telemetry`'s new span helper (D-08) — not the whole `purge/1` body.

**Per-batch emission point** (`lib/threadline/retention.ex:173-207`, inside `purge_loop/7`'s `Enum.reduce_while`):
```elixir
Enum.reduce_while(1..max_batches, {0, 0, 0}, fn idx, {tc, tt, _} ->
  n1 = delete_change_batch(repo, cutoff, batch_size, storage_opts)
  n2 = if delete_empty?, do: drain_orphan_batches(repo, batch_size, storage_opts), else: 0
  tc = tc + n1
  tt = tt + n2
  Logger.info("threadline retention purge batch", deleted_changes: n1, deleted_transactions: n2, batch: idx, ...)
  cond do
    n1 == 0 and n2 == 0 -> {:halt, {tc, tt, idx}}
    sleep_ms > 0 -> Process.sleep(sleep_ms); {:cont, {tc, tt, idx}}
    true -> {:cont, {tc, tt, idx}}
  end
end)
```
Emit `Threadline.Telemetry.emit_batch_purged(n1, n2, duration)` right after `n1`/`n2` are computed (after that step's `delete_all` + full orphan drain have returned — statements have already autocommitted, no wrapping transaction exists at any level in this file). Fires for every iteration including the final empty one, matching the existing `Logger.info` call's placement — use it as the emission anchor point. A dry run never reaches `purge_loop/7` (it returns from `dry_run_result/4` instead), so zero batch events fire for dry runs automatically, with no extra guard needed.

---

### `lib/threadline/operator_surface/auth.ex` / `theme_auth_plug.ex` / `export_auth_plug.ex` (middleware, event-driven) — strip identity fields

**Analog:** the three files mirror each other; `theme_auth_plug.ex` is the cleanest of the three (its `path` is populated, not hardcoded).

**Current shape, `lib/threadline/operator_surface/auth.ex:92-102`:**
```elixir
defp emit_telemetry(result, socket, scope) do
  scope_keys = if is_map(scope), do: Map.keys(scope) |> Enum.sort(), else: []
  actor_ref = Map.get(socket.assigns, :threadline_actor_ref)
  :telemetry.execute(
    [:threadline, :operator_surface, :authorize],
    %{result: result},
    %{path: "", actor_ref: actor_ref, scope_keys: scope_keys}
  )
end
```
Required change (D-17): drop `actor_ref:` from the metadata map entirely — keep `result` (measurement), `path` and `scope_keys` (metadata). Move the `:telemetry.execute/3` call itself behind a new `Threadline.Telemetry.emit_operator_authorize/3`-style helper per D-02 (the three operator-surface emitters "move behind helpers"); this file, `theme_auth_plug.ex`, and `export_auth_plug.ex` should call that one shared helper rather than each calling `:telemetry.execute/3` directly as they do today.

**`emit_actor_mismatch/2`, `lib/threadline/operator_surface/auth.ex:160-169`:**
```elixir
defp emit_actor_mismatch(session_actor_ref, scope_actor_ref) do
  :telemetry.execute(
    [:threadline, :operator_surface, :actor_ref_mismatch],
    %{count: 1},
    %{session_actor_ref: ActorRef.to_map(session_actor_ref), scope_actor_ref: ActorRef.to_map(scope_actor_ref)}
  )
end
```
D-17 strips both metadata keys entirely, leaving `%{count: 1}` measurements and `%{}` metadata — the event becomes a pure incidence counter (RESEARCH Open Question 1; this is the locked decision, implement as specified).

---

### `lib/threadline/operator_surface/coverage/on_mount.ex` / `live/coverage_live.ex` (hook/component, event-driven) — change the call argument, not just the helper

**Analog:** the two `rescue` clauses in `on_mount.ex` mirror each other and `coverage_live.ex`'s `fetch_coverage_for_schema/2`.

**Current shape, `lib/threadline/operator_surface/coverage/on_mount.ex:80-88` (and again at `:102-109`):**
```elixir
rescue
  e ->
    message = Exception.message(e)
    Threadline.Telemetry.emit_health_checked_error(message)
    socket
    |> Phoenix.Component.assign(:threadline_coverage, Snapshot.empty(now))
    |> Phoenix.Component.assign(:threadline_coverage_error, message)
end
```
Required change: keep computing `message = Exception.message(e)` for the `:threadline_coverage_error` assign (unchanged UI behavior), but change only the telemetry call's argument to the exception struct itself: `Threadline.Telemetry.emit_health_checked_error(e)`. Apply identically to the second `rescue` clause in this file and to `coverage_live.ex:394-397`'s matching clause.

---

### `test/threadline/telemetry_registry_contract_test.exs` (new) — allowlist + static-scan + doc-parity

**Analog 1 — doc-parity precedent**, `test/threadline/health_findings_doc_contract_test.exs:1-60`:
```elixir
use ExUnit.Case, async: true
...
@findings_checked_event "[:threadline, :health, :findings_checked]"
defp read_rel!(path), do: File.read!(Path.join(File.cwd!(), path))
defp moduledoc!(module) do
  case Code.fetch_docs(module) do
    {:docs_v1, _, _, _, %{"en" => moduledoc}, _, _} -> moduledoc
    other -> flunk(...)
  end
end
test "[:threadline, :health, :findings_checked] appears in domain-reference.md and the Telemetry moduledoc" do
  domain_reference = read_rel!(@domain_reference_path)
  telemetry_moduledoc = moduledoc!(Threadline.Telemetry)
  assert String.contains?(domain_reference, "findings_checked"), "..."
  assert String.contains?(telemetry_moduledoc, @findings_checked_event), "..."
end
```
This `Code.fetch_docs/1` + `String.contains?/2` idiom is the direct precedent for D-12.3's "parse the moduledoc table and `guides/telemetry.md`'s table, compare both to `__events__/0`" — extend it to iterate every `Threadline.Telemetry.__events__/0` entry rather than one hand-picked event string, so the check derives from the registry instead of a hand-typed literal (D-15's explicit requirement).

**Analog 2 — allowlist/runtime shape**, `test/support/telemetry_helpers.ex:47-66` (`attach_telemetry!/1`):
```elixir
def attach_telemetry!(events) when is_list(events) do
  test_pid = self()
  ref = make_ref()
  :telemetry.attach_many(ref, events, &__MODULE__.handle_event/4, %{test_pid: test_pid, ref: ref})
  ExUnit.Callbacks.on_exit(fn -> :telemetry.detach(ref) end)
  ref
end
```
Use this directly: `ref = Threadline.TelemetryHelpers.attach_telemetry!(Threadline.Telemetry.__events__() |> Enum.map(& &1.name))`, drive one real operation per event family, then `for %{name: name, measurements: m, metadata: md} <- Threadline.Telemetry.__events__(), do: assert_receive {^name, ^ref, measurements, metadata}; assert MapSet.new(Map.keys(measurements)) == MapSet.new(m); ...`.

**Static scan (D-12.2)** — no direct existing analog; a straightforward `File.ls!/1` + `Grep`-equivalent `Regex.scan/2` over `lib/**/*.ex` asserting `:telemetry.execute(` / `:telemetry.span(` occur only in `lib/threadline/telemetry.ex`. Follow the `test/threadline/guide_graph_contract_test.exs` convention of reading committed source files directly with `File.read!/1` rather than shelling out to `grep`.

---

### `test/threadline/telemetry_raising_handler_test.exs` (new) — handler-detach assertion

**Analog:** `test/support/telemetry_helpers.ex`'s `attach_telemetry!/1` for the non-raising side; for the raising handler itself, attach ad hoc (not via the helper, since the helper's `handle_event/4` never raises) with `:telemetry.attach_many/4` directly, then assert via `:telemetry.list_handlers(event)` (per D-13) that the handler id is absent post-failure, using `ExUnit.CaptureLog.capture_log/1` to suppress/assert the logged crash. Verified detach-all semantics: `deps/telemetry/src/telemetry.erl:110-111` (doc comment) — "failure of the handler on any of these invocations will detach it from all the events in EventNames."

---

### `test/threadline/capture/redaction_leak_property_test.exs` (extend) — telemetry observer in `setup`

**Analog:** itself — the file's moduledoc (lines 1-40, read this session) already documents that `LeakOracle`'s `surfaces` shape is "deliberately open-ended... phase 228 appends `telemetry:<event>` surfaces to the same list; this module attaches no telemetry handler," i.e. the extension point is pre-reserved and the observer attaches directly in the test, not in `LeakOracle` itself.

**`LeakOracle`'s surfaces contract** (`test/support/leak_oracle.ex:1-24, 73-77`):
```elixir
def stored_surfaces(table_name, id) do
  ...
  [
    {"stored:audit_changes", Enum.join(change_jsons, "\n")},
    {"stored:audit_transactions", Enum.join(txn_jsons, "\n")}
  ]
end
```
The `{name, bytes}` 2-tuple list shape is exactly what D-14's `{"telemetry:" <> Enum.join(event, "."), inspect(meas) <> inspect(meta)}` must produce per event received. In `setup`, mirror `attach_telemetry!/1`'s pattern but use `attach_many` with a uniquely-id'd ref and a non-raising handler forwarding `{event, measurements, metadata}` to the test pid (D-14), draining the mailbox before and after `build_surfaces` each iteration.

---

### `guides/telemetry.md` (new) — doc structure precedent

**Analog:** `guides/operator-surface.md:185,486` (existing telemetry-event prose to migrate/link) and `guides/production-checklist.md:30` (alerting-on-events prose style).

Current prose to replace/link from (`guides/operator-surface.md:185`):
```
Telemetry event `[:threadline, :operator_surface, :authorize]` is emitted with the outcome (`:granted`, `:denied`, or `:error`).
```
and (`guides/operator-surface.md:486`):
```
`[:threadline, :health, :checked, :error]` fires on poll failure with metadata `%{error: message}`; alert on this for sustained drift.
```
Both lines move to the new guide and the second must change to `%{exception: module}` to match D-17.

---

### `mix.exs` / `test/threadline/guide_graph_contract_test.exs` — guide registration

**Analog:** the existing `extras` list entry pattern, e.g. `"guides/audit-indexing.md"` (`mix.exs:595`), and its `groups_for_extras` "Operate" lane regex (`mix.exs:618-619`):
```elixir
Operate:
  ~r{^guides/(operator-surface|incident-playbook|performance|audit-indexing|adoption-evidence-playbook)\.md$},
```
Add `"guides/telemetry.md"` to `extras` (any position; ExDoc sorts by group) and add `telemetry` to this regex's alternation. Then update `test/threadline/guide_graph_contract_test.exs`'s `@lanes` operate list and guide-count assertion (19 → 20), and add an inbound edge from a non-README guide (e.g. `guides/operator-surface.md`) per D-16's registration bullet.

---

## Shared Patterns

### `@doc false` helper + single-module `:telemetry.execute`/`:telemetry.span` boundary
**Source:** `lib/threadline/telemetry.ex` (whole file)
**Apply to:** every new emission call site (`export.ex`, `orchestrator.ex`, `export_controller.ex`, `retention.ex`) and every stripped call site (`auth.ex`, `theme_auth_plug.ex`, `export_auth_plug.ex`, `on_mount.ex`, `coverage_live.ex`) — all must call a `Threadline.Telemetry` helper, never `:telemetry.execute`/`:telemetry.span` directly (D-02, enforced by the new static-scan contract test).

### `try/rescue` + `reraise`, emit-on-both-branches
**Source:** `lib/threadline/export/orchestrator.ex:60-73` (rescue pattern, note: this analog does NOT reraise — export.ex's eager functions must add `reraise e, __STACKTRACE__` which this analog lacks, per D-07)
**Apply to:** `export.ex`'s `to_csv_iodata/2`, `to_json_document/2`.

### Test process isolation for async telemetry assertions
**Source:** `test/support/telemetry_helpers.ex` (`attach_telemetry!/1`, `handle_event/4`)
**Apply to:** `telemetry_registry_contract_test.exs`, any extended test in `export_test.exs`/`retention_test.exs` asserting on the new events, and `redaction_leak_property_test.exs`'s new observer (though D-14 attaches its own handler rather than reusing this helper verbatim, since it needs to append to `LeakOracle` surfaces rather than `assert_receive`).

### Doc-parity via `Code.fetch_docs/1` + `String.contains?/2`
**Source:** `test/threadline/health_findings_doc_contract_test.exs:21-26, 51-59`
**Apply to:** `telemetry_registry_contract_test.exs`'s D-12.3 doc-parity assertions (moduledoc table vs. `guides/telemetry.md` table vs. `__events__/0`).

## No Analog Found

None — every file in this phase's scope either already exists (extend-in-place) or has a close structural sibling already in the codebase (new test files follow `*_contract_test.exs`/`*_doc_contract_test.exs` family conventions; the new guide follows the existing `guides/*.md` + `mix.exs` extras + `guide_graph_contract_test.exs` registration triad).

## Metadata

**Analog search scope:** `lib/threadline/telemetry.ex`, `lib/threadline/export.ex`, `lib/threadline/export/orchestrator.ex`, `lib/threadline/operator_surface/controllers/export_controller.ex`, `lib/threadline/retention.ex`, `lib/threadline/operator_surface/{auth,theme_auth_plug,export_auth_plug}.ex`, `lib/threadline/operator_surface/coverage/on_mount.ex`, `lib/threadline/operator_surface/live/coverage_live.ex`, `test/support/{telemetry_helpers,leak_oracle}.ex`, `test/threadline/capture/redaction_leak_property_test.exs`, `test/threadline/health_findings_doc_contract_test.exs`, `test/threadline/guide_graph_contract_test.exs`, `guides/operator-surface.md`, `mix.exs`
**Files scanned:** 16 read directly this session (line-anchored); all call sites cross-checked against 228-RESEARCH.md's own verified line numbers, no discrepancies found
**Pattern extraction date:** 2026-10-01
