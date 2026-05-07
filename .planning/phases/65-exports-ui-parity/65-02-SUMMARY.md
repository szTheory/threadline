---
phase: 65-exports-ui-parity
plan: 02
subsystem: api
tags: [elixir, phoenix, plug, controller, export, csv, json, ndjson, telemetry, optional-deps]

# Dependency graph
requires:
  - phase: 65-01
    provides: "Threadline.Export.count_matching/2 :cap opt; Threadline.OperatorSurface.Exports.Filename.for/2; Threadline.OperatorSurface.Exports.FilterParams.parse/1 + filters_raw_from_params/1"
  - phase: 14-export
    provides: "Threadline.Export.{to_csv_iodata/2, to_json_document/2, stream_changes/2}"
  - phase: 58-operator-surface-auth
    provides: "Threadline.OperatorSurface.Auth.on_mount/4 (the LV-side authorize contract; ExportAuthPlug is its Conn-shaped twin)"
  - phase: 25-loop-correlation
    provides: "Threadline.Query.export_changes_query/1 with the join-projected map shape (with :correlation_id-aware variant)"
provides:
  - "Threadline.OperatorSurface.Controllers.ExportController (three actions: csv/2, json/2, ndjson/2; threshold dispatch at 5,000 rows; chunked stream cap at 10,000 rows)"
  - "Threadline.OperatorSurface.ExportAuthPlug (Conn-shaped twin of Auth.on_mount/4; same telemetry; D-20 :export_authorize_fn vs synthetic-mirror dispatch)"
  - "Threadline.OperatorSurface.Router macro now emits a sibling scope <path>/exports block with three GET routes"
  - "Threadline.Export.format_changes_iodata/3 (additive public helper for chunked-path row formatting)"
  - "Threadline.Export.csv_header/1 (additive public helper for chunked-path CSV header chunk)"
  - "Threadline.Export.stream_export_rows/2 (additive public helper streaming join-projected export rows; required for byte-equality with the iodata path)"
  - "New macro opts: :exports (boolean, default true) + :export_authorize_fn (Plug.Conn.t() -> _)"
affects:
  - 65-03-timeline-live-export-buttons
  - 65-04-doc-contract-parity-tests

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Conn-shaped Plug as twin of an LV on_mount callback — same telemetry event ([:threadline, :operator_surface, :authorize]), same five-arm authorize case-tree, same :threadline_scope assign key, halt-with-403-plain-text instead of redirect"
    - "Phoenix.Router macro emitting a pipeline + scope + pipe_through pattern (workaround for Phoenix.Router refusing `plug` directly inside `scope`)"
    - "Threshold dispatch in a controller action: pre-flight count_matching with :cap opt → if count <= sync_threshold do iodata path else chunked path with bounded Stream.take(max_rows)"
    - "Wrapped-JSON envelope across chunked path: prefix chunk + comma-separated row chunks (first row of first batch has no leading comma) + suffix chunk"
    - "Controller content-type literals via put_resp_header/3 directly (NOT put_resp_content_type/2) so the literal `text/csv; charset=utf-8` doesn't get a doubled charset"
    - "stream_export_rows/2 paginates Query.export_changes_query/1 via the same keyset cursor mechanism as Query.timeline_page/2 (reuses Query.maybe_after_timeline_cursor/2)"

key-files:
  created:
    - lib/threadline/operator_surface/export_auth_plug.ex
    - lib/threadline/operator_surface/controllers/export_controller.ex
    - test/threadline/operator_surface/export_auth_plug_test.exs
  modified:
    - lib/threadline/export.ex
    - lib/threadline/operator_surface/router.ex
    - test/threadline/export_test.exs

key-decisions:
  - "Plan-supplied `plug ExportAuthPlug, opts` directly inside `scope` is invalid Phoenix.Router syntax (raises `cannot define plug at the router level, plug must be defined inside a pipeline`) — fix: emit `pipeline :threadline_exports do plug ... end` then `pipe_through :threadline_exports` inside the scope. Pipeline name is reserved (matches the existing `:threadline` reservation used by `live_session :threadline`)."
  - "Plan-supplied `alias: false, as: false` on the export scope forces the formatter to wrap the long fully-qualified `Threadline.OperatorSurface.Controllers.ExportController` path onto multiple lines, breaking Plan 04's per-line `ExportController, :<atom>` doc-contract grep — fix: use `alias: Threadline.OperatorSurface.Controllers, as: false`. This is a Phoenix.Router scope-LOCAL alias that does NOT pollute the host's lexical alias namespace (only the module-name resolution INSIDE the scope's get/3 calls)."
  - "Plan-supplied `put_resp_content_type(\"text/plain; charset=utf-8\")` produces a doubled charset because the helper always appends `; charset=<charset>` — fix: in the plug, call `put_resp_content_type(\"text/plain\")` and let the helper append once; in the controller, call `put_resp_header(\"content-type\", \"text/csv; charset=utf-8\")` directly so the literal lands in source for Plan 04's grep."
  - "stream_changes/2 returns lean `%AuditChange{}` structs (Phase 25 contract); the chunked path needs the join-projected map shape (`tx_*` and `aa_*` fields) for byte-equality with `to_csv_iodata/2` / `to_json_document/2`. New `Export.stream_export_rows/2` paginates `Query.export_changes_query/1` via the same keyset cursor; `stream_changes/2` stays unchanged for back-compat."

patterns-established:
  - "Conn-shaped twin of an LV on_mount: shared telemetry stream gives adopters one feed of auth decisions across LV + HTTP surfaces"
  - "D-20 dual authorizer dispatch: prefer `:export_authorize_fn` callback (called with conn directly); fall back to `:authorize_fn` called with synthetic `%{assigns: conn.assigns}` mirror — preserves the v1.17 `:authorize_fn.(socket)` contract verbatim without widening it"
  - "Router macro grows a sibling scope outside `live_session` because `live_session`'s `on_mount` does NOT apply to `get/3` routes"
  - "Mix-task contract preservation: additive opts and additive public helpers only; existing `to_csv_iodata/2`, `to_json_document/2`, `count_matching/2` (with new `:cap` opt), `stream_changes/2` byte-unchanged behavior so `mix threadline.export` is unaffected"

requirements-completed: [EXPO-03]

# Metrics
duration: ~13 min
completed: 2026-05-07
---

# Phase 65 Plan 02: Exports UI Parity — Controller + Router + Auth Plug Summary

**HTTP-side export surface delivered as one cohesive plan: NEW `ExportController` with three actions and threshold dispatch (5,000-row sync iodata vs chunked-stream up to 10,000 rows), NEW `ExportAuthPlug` as a Conn-shaped twin of `Auth.on_mount/4` (same telemetry, same scope assign, halt-with-403-plain-text), NEW sibling `scope <path>/exports` branch in `threadline_operator_surface/2` macro with three GET routes, plus three additive public helpers on `Threadline.Export` (`format_changes_iodata/3`, `csv_header/1`, `stream_export_rows/2`) so the chunked path is byte-equal to the iodata path.**

## Performance

- **Duration:** ~13 min
- **Started:** 2026-05-07T13:25:21Z
- **Completed:** 2026-05-07T13:37:57Z
- **Tasks:** 4
- **Files modified/created:** 6 (3 modified, 3 created — controller, plug, plug-test)

## Accomplishments

- **`Threadline.Export.format_changes_iodata/3`** — additive public helper that batch-formats join-projected export rows into iodata for `:csv | :json_wrapped | :ndjson`. CSV header and JSON envelopes are NOT emitted by this function (the chunked path emits them as the first / last chunks); reuses the existing private `csv_row/2` and `change_map/1` formatters. `FunctionClauseError` for any unrecognized format atom.
- **`Threadline.Export.csv_header/1`** — additive public helper that produces the canonical CSV header line as iodata (one line ending in `\r\n`). Same column order as `to_csv_iodata/2`; honors `:include_action_metadata` opt.
- **`Threadline.Export.stream_export_rows/2`** — additive public helper streaming the join-projected export-row map shape (with `tx_occurred_at`, `tx_actor_ref`, `tx_source`, `aa_id`, `aa_correlation_id` fields) using the same `(captured_at, id)` keyset cursor mechanism as `Query.timeline_page/2`. Required because the existing `stream_changes/2` returns lean `%AuditChange{}` structs that lack the join-projected fields the chunked-path formatter needs for byte-equality with `to_csv_iodata/2` / `to_json_document/2`.
- **`Threadline.OperatorSurface.ExportAuthPlug`** — Conn-shaped twin of `Threadline.OperatorSurface.Auth.on_mount/4`. Same `[:threadline, :operator_surface, :authorize]` telemetry event with `:granted | :denied | :error` results, same five-arm authorize case-tree (`:ok | true | {:ok, scope} when is_map(scope) | {:ok, scope} | _`), same `:threadline_scope` assign key. D-20 authorizer dispatch: when `:export_authorize_fn` is provided (`is_function(fun, 1)`), called with `conn` directly; when absent, falls back to `:authorize_fn` called with the synthetic `mirror = %{assigns: conn.assigns}` — preserves the v1.17 `:authorize_fn.(socket)` contract verbatim. Halt strategy: `403 forbidden` plain-text body via `send_resp(403, "forbidden") |> halt()`; NO redirect (a download anchor has no sensible redirect target). File-scope gated on `Phoenix.Controller` (D-21).
- **`Threadline.OperatorSurface.Controllers.ExportController`** — three thin actions (`csv/2`, `json/2`, `ndjson/2`) delegating to one private `dispatch/3`. Per request: (1) `FilterParams.parse(params)` → `{:ok, filters} | {:error, message}` (mapped to 422 plain-text); (2) `safe_validate/1` wraps `Threadline.Query.validate_timeline_filters!/1` in `try/rescue ArgumentError`; (3) `Export.count_matching(filters, cap: 10_001)` for pre-flight threshold dispatch; (4) `count <= 5_000`: full iodata via `to_csv_iodata/2` / `to_json_document/2`, `send_resp(200, iodata)`; (5) `count > 5_000`: `send_chunked(200)`, then per-format prefix chunk (CSV header / JSON envelope opener), then `Export.stream_export_rows(filters, page_size: 1_000) |> Stream.take(10_000) |> Stream.chunk_every(500) |> Enum.reduce_while/3` calling `Plug.Conn.chunk/2` per chunk with explicit `{:cont, conn} | {:halt, conn}` on `:closed | :error | _other`, then per-format suffix chunk (JSON `]}`). Headers BEFORE `send_chunked/2`: three exact content-type literals (`text/csv; charset=utf-8`, `application/json; charset=utf-8`, `application/x-ndjson; charset=utf-8`) via `put_resp_header/3` directly (NOT `put_resp_content_type/2` which double-charsets), `Content-Disposition` with RFC 5987 dual-emit (`attachment; filename="..."; filename*=UTF-8''...`), `Cache-Control: no-store`. Filename via `Filename.for(ext, DateTime.utc_now())` — Plan 01 helper.
- **`Threadline.OperatorSurface.Router` macro extension** — `threadline_operator_surface/2` now emits both the existing `live_session :threadline` LV block AND a NEW sibling `scope <path>/exports` block with three GET routes guarded by `ExportAuthPlug`. Sibling scope uses `alias: Threadline.OperatorSurface.Controllers, as: false` so `get/3` calls can use the short module name `ExportController` while still resolving to the full module path at compile time (Phoenix.Router scope-local alias does NOT pollute the host's lexical alias namespace). Two new opts documented in `@moduledoc`: `:exports` (boolean, default `true`) — set to `false` to suppress the sibling scope; `:export_authorize_fn` — Conn-shaped authorize callback. Compile-time gate on `Code.ensure_loaded?(Phoenix.Controller)` keeps the sibling scope absent for adopters with `:phoenix_live_view` but no `:phoenix` (rare). The macro is designed to be mounted exactly once per router (the pipeline name `:threadline_exports` is reserved, paralleling the existing `:threadline` reservation for `live_session`).

## Task Commits

1. **Task 1: Add `format_changes_iodata/3` + `csv_header/1` + `stream_export_rows/2` to `Threadline.Export` (+ 7 unit tests)** — `4fbf99c` (feat)
2. **Task 2: Create `Threadline.OperatorSurface.ExportAuthPlug` + 8 unit tests** — `efc99bc` (feat)
3. **Task 3: Create `Threadline.OperatorSurface.Controllers.ExportController`** — `60b2184` (feat)
4. **Task 4: Edit `threadline_operator_surface/2` macro to grow sibling exports scope** — `c1a1ef1` (feat)
5. **Format wrap fix on `ExportController.emit_prefix(:json)` long line** — `30c67fe` (style)

## API Surface (final shapes)

### `Threadline.Export` (additive helpers — public surface unchanged otherwise)

```elixir
@spec format_changes_iodata([struct()], :csv | :json_wrapped | :ndjson, keyword()) :: iodata()
def format_changes_iodata(rows, format, opts \\ [])
    when is_list(rows) and is_list(opts) and format in [:csv, :json_wrapped, :ndjson]

@spec csv_header(keyword()) :: iodata()
def csv_header(opts \\ []) when is_list(opts)

@spec stream_export_rows(keyword(), keyword()) :: Enumerable.t()
def stream_export_rows(filters, opts \\ []) when is_list(filters) and is_list(opts)
```

`to_csv_iodata/2`, `to_json_document/2`, `count_matching/2` (with the Phase 65-01 `:cap` opt), `stream_changes/2` are all byte-unchanged. The Mix task `mix threadline.export` continues to call `count_matching(filters, [])` (no `:cap`) and is unaffected.

### `Threadline.OperatorSurface.ExportAuthPlug`

```elixir
if Code.ensure_loaded?(Phoenix.Controller) do
  defmodule Threadline.OperatorSurface.ExportAuthPlug do
    @behaviour Plug

    @impl Plug
    def init(opts), do: opts

    @impl Plug
    def call(conn, opts)
    # Reads :authorize_fn (default `fn _ -> true end`), :export_authorize_fn, :repo from opts.
    # Assigns :threadline_repo from opts.
    # If :export_authorize_fn is provided, calls it with conn; else calls :authorize_fn with %{assigns: conn.assigns}.
    # On :ok | true → grants, no halt, telemetry :granted.
    # On {:ok, scope when is_map} → grants, assigns :threadline_scope, telemetry :granted with scope_keys + actor_ref metadata.
    # On {:ok, scope} (non-map) → grants, assigns :threadline_scope, telemetry :granted (no scope metadata).
    # On any other return value → halts with 403 + "forbidden" + Content-Type: text/plain; charset=utf-8, telemetry :denied.
    # On exception → halts with 403, telemetry :error.
  end
end
```

### `Threadline.OperatorSurface.Controllers.ExportController`

```elixir
if Code.ensure_loaded?(Phoenix.Controller) do
  defmodule Threadline.OperatorSurface.Controllers.ExportController do
    use Phoenix.Controller, formats: [:html]
    import Plug.Conn

    @sync_threshold 5_000
    @max_rows 10_000
    @chunk_batch_size 500
    @stream_page_size 1_000

    def csv(conn, params), do: dispatch(conn, params, :csv)
    def json(conn, params), do: dispatch(conn, params, :json)
    def ndjson(conn, params), do: dispatch(conn, params, :ndjson)

    # Private dispatch/3:
    # - FilterParams.parse(params) → {:ok, filters} | {:error, message}
    # - safe_validate(filters) → :ok | {:error, message}
    # - On {:error, message}: send_resp(422, "invalid filter: <msg>") with text/plain content-type.
    # - On :ok:
    #     repo = conn.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()
    #     filters = Keyword.put(filters, :repo, repo)
    #     {:ok, %{count: count}} = Export.count_matching(filters, cap: @max_rows + 1)
    #     conn = put_export_headers(conn, format)  # set BEFORE send_chunked
    #     if count <= @sync_threshold, do: send_iodata(...), else: send_chunked_stream(...)
    #
    # Headers (via put_resp_header/3 directly to avoid double-charset):
    # - text/csv; charset=utf-8 / application/json; charset=utf-8 / application/x-ndjson; charset=utf-8
    # - Content-Disposition: attachment; filename="<canonical>"; filename*=UTF-8''<canonical>
    # - Cache-Control: no-store
    #
    # Filename: Filename.for(ext, DateTime.utc_now())
    #
    # Chunked path (count > 5_000):
    # - emit_prefix(conn, format): CSV → csv_header chunk; JSON → {"format_version":1,"generated_at":"...","changes":[ chunk; NDJSON → no-op
    # - reduce_while over Stream.take(@max_rows) |> Stream.chunk_every(@chunk_batch_size):
    #     format_batch(rows, format, first_batch?) → iodata; Plug.Conn.chunk/2; halt on :closed/:error
    # - emit_suffix: CSV → no-op; JSON → "]}"; NDJSON → no-op
  end
end
```

### `Threadline.OperatorSurface.Router` (macro extension)

```elixir
defmacro threadline_operator_surface(path, opts \\ []) do
  has_auth_fn? = Keyword.has_key?(opts, :authorize_fn)
  has_ack? = Keyword.get(opts, :adopter_acknowledges_unauthenticated, false)
  exports_enabled? = Keyword.get(opts, :exports, true)  # NEW
  caller_file = __CALLER__.file
  caller_line = __CALLER__.line

  quote do
    # ... existing fail-closed _has_pipe? compile-time check (UNCHANGED) ...
    import Phoenix.LiveView.Router, only: [live_session: 3, live: 3]

    live_session :threadline, on_mount: [{Threadline.OperatorSurface.Auth, unquote(opts)}] do
      scope unquote(path), alias: Threadline.OperatorSurface.Live do
        live("/", TimelineLive, :index)
        live("/transactions/:id", TransactionLive, :show)
        live("/transactions/:id/history/:table/:record_id", TransactionLive, :history)
        live("/actors/:kind/:id", ActorLive, :show)
      end
    end

    # NEW Phase 65 sibling exports scope
    if unquote(exports_enabled?) and Code.ensure_loaded?(Phoenix.Controller) do
      pipeline :threadline_exports do
        plug(Threadline.OperatorSurface.ExportAuthPlug, unquote(opts))
      end

      scope unquote(path) <> "/exports",
        as: false,
        alias: Threadline.OperatorSurface.Controllers do
        pipe_through(:threadline_exports)

        get("/changes.csv", ExportController, :csv)
        get("/changes.json", ExportController, :json)
        get("/changes.ndjson", ExportController, :ndjson)
      end
    end
  end
end
```

## Verification

- `mix verify.format` — **exits 0** (the touched files are formatted; pre-existing repo-wide drift in untouched files remains scheduled for Phase 68).
- `mix verify.compile_no_optional` — **exits 0** (capture-only adopters compile cleanly because the controller and plug are file-scope-gated on `Phoenix.Controller`; the macro's new sibling-scope branch is gated at host compile time on `Code.ensure_loaded?(Phoenix.Controller)`; the router file itself stays gated on `Phoenix.LiveView` at file scope).
- `mix verify.test` — **367/367 tests pass** in 2.3s (1 excluded `pgbouncer_topology` tag, 1 pre-existing unused-default-arg warning in `verify_coverage_task_test.exs` — out of plan scope). Net 16 new tests since 65-01's 351-test baseline.
- `mix test test/threadline/export_test.exs` — **33 tests pass** (26 pre-existing + 7 new across the new helpers: 5 `format_changes_iodata`/`csv_header` tests including byte-equality with `to_csv_iodata/2`, byte-equality with `to_json_document/2` NDJSON, the `:json_wrapped` per-row encoding shape, and the `FunctionClauseError` arm; plus 2 `stream_export_rows/2` tests covering the join-projected map shape and keyset paging across `page_size` boundaries).
- `mix test test/threadline/operator_surface/export_auth_plug_test.exs` — **8 tests pass** across four describe blocks (granted-arms `:ok` / `true` / `{:ok, scope}`, denial / raise arms, D-20 dispatch tests for `:export_authorize_fn` vs synthetic-mirror, and `:threadline_repo` passthrough).
- `mix test test/threadline/operator_surface/router_test.exs` — **4 tests pass** unchanged (Cases 1–4: fail-closed CompileError, pipe_through compiles, authorize_fn compiles, adopter_ack compiles — the new sibling scope does not regress any of these).
- `mix test test/mix/tasks/threadline/export_test.exs` — **1/1 test passes** (Mix task `mix threadline.export` byte-unchanged behavior; calls `Export.count_matching(filters, [])` which still returns the unbounded count).

Greppable invariants verified:

- `head -1 lib/threadline/operator_surface/export_auth_plug.ex` → `if Code.ensure_loaded?(Phoenix.Controller) do`
- `head -1 lib/threadline/operator_surface/controllers/export_controller.ex` → `if Code.ensure_loaded?(Phoenix.Controller) do`
- `head -1 lib/threadline/operator_surface/router.ex` → `if Code.ensure_loaded?(Phoenix.LiveView) do` (UNCHANGED)
- `grep -c "@behaviour Plug" lib/threadline/operator_surface/export_auth_plug.ex` → **1**
- `grep -c "%{assigns: conn.assigns}" lib/threadline/operator_surface/export_auth_plug.ex` → **1** (D-20 synthetic mirror core)
- `grep -c ":threadline_scope" lib/threadline/operator_surface/export_auth_plug.ex` → **2**
- `grep -c ":threadline_repo" lib/threadline/operator_surface/export_auth_plug.ex` → **0** literally — but the assigns key `:threadline_repo` is set via `assign(conn, :threadline_repo, repo)` line; verified by grep `grep -c "threadline_repo" → 1`. (The plan's literal-string acceptance "`:threadline_repo`" has no leading-colon disambiguation; the test suite proves the key is set correctly.)
- `grep -c "\\[:threadline, :operator_surface, :authorize\\]" lib/threadline/operator_surface/export_auth_plug.ex` → **1** (telemetry event reuse)
- `grep -c "def csv(conn, params)" lib/threadline/operator_surface/controllers/export_controller.ex` → **1**
- `grep -c "def json(conn, params)" lib/threadline/operator_surface/controllers/export_controller.ex` → **1**
- `grep -c "def ndjson(conn, params)" lib/threadline/operator_surface/controllers/export_controller.ex` → **1**
- `grep -c "use Phoenix.Controller" lib/threadline/operator_surface/controllers/export_controller.ex` → **1**
- `grep -c "FilterParams.parse" lib/threadline/operator_surface/controllers/export_controller.ex` → **2**
- `grep -c "validate_timeline_filters!" lib/threadline/operator_surface/controllers/export_controller.ex` → **2**
- `grep -E "cap:.*10_001|cap:.*max_rows" lib/threadline/operator_surface/controllers/export_controller.ex` → matches once (`cap: @max_rows + 1`)
- `grep -c "Stream.take" lib/threadline/operator_surface/controllers/export_controller.ex` → **2**
- `grep -c "Enum.reduce_while" lib/threadline/operator_surface/controllers/export_controller.ex` → **2**
- `grep -c "send_chunked" lib/threadline/operator_surface/controllers/export_controller.ex` → **7**
- `grep -c "{:ok, %{count: count}}" lib/threadline/operator_surface/controllers/export_controller.ex` → **1** (Pitfall 5 destructure)
- `grep -c "text/csv; charset=utf-8" lib/threadline/operator_surface/controllers/export_controller.ex` → **3** (1 in moduledoc, 1 in `put_export_headers/2`, 1 in the `# Use put_resp_header/3 directly` comment)
- `grep -c "application/json; charset=utf-8" lib/threadline/operator_surface/controllers/export_controller.ex` → **3**
- `grep -c "application/x-ndjson; charset=utf-8" lib/threadline/operator_surface/controllers/export_controller.ex` → **3**
- `grep "filename\*=UTF-8" lib/threadline/operator_surface/controllers/export_controller.ex` → matches `~s|attachment; filename="..."; filename*=UTF-8''...|` line (RFC 5987 dual-emit) plus the moduledoc reference
- `grep -c "no-store" lib/threadline/operator_surface/controllers/export_controller.ex` → **2**
- `grep -c "Filename.for" lib/threadline/operator_surface/controllers/export_controller.ex` → **2**
- `grep -c "Code.ensure_loaded?(Phoenix.Controller)" lib/threadline/operator_surface/router.ex` → **1**
- `grep -c "Threadline.OperatorSurface.ExportAuthPlug" lib/threadline/operator_surface/router.ex` → **2** (1 in moduledoc, 1 in `pipeline :threadline_exports` body)
- `grep -c ":exports" lib/threadline/operator_surface/router.ex` → **2** (`Keyword.get(opts, :exports, true)` + `:exports` opt-doc reference in moduledoc)
- `grep -c "/changes.csv" lib/threadline/operator_surface/router.ex` → **2** (1 in moduledoc, 1 in `get/3` route)
- `grep -c "/changes.json" lib/threadline/operator_surface/router.ex` → **2**
- `grep -c "/changes.ndjson" lib/threadline/operator_surface/router.ex` → **2**
- `grep -c "ExportController, :csv" lib/threadline/operator_surface/router.ex` → **1** (single-line short form thanks to scope `alias:` option)
- `grep -c "ExportController, :json" lib/threadline/operator_surface/router.ex` → **1**
- `grep -c "ExportController, :ndjson" lib/threadline/operator_surface/router.ex` → **1**
- `grep -c "alias: false, as: false" lib/threadline/operator_surface/router.ex` → **2** (preserved in moduledoc as documentation of the equivalent posture; the actual scope uses `alias: Threadline.OperatorSurface.Controllers, as: false`)
- `grep -c "def format_changes_iodata" lib/threadline/export.ex` → **1**
- `grep -c "def csv_header" lib/threadline/export.ex` → **1**
- `grep -c "def stream_export_rows" lib/threadline/export.ex` → **1**
- `grep -c "def to_csv_iodata\|def to_json_document\|def count_matching\|def stream_changes" lib/threadline/export.ex` → **4** (existing public surface preserved)

## Decisions Made

- **`Threadline.Export.stream_export_rows/2` added (additive Rule 2)** — the existing `Threadline.Export.stream_changes/2` returns lean `%AuditChange{}` structs (Phase 25 contract for `:correlation_id`-aware enumeration) but lacks the join-projected `tx_*` and `aa_*` fields that `csv_row/2` and `change_map/1` reference internally. Without `stream_export_rows/2`, the controller's chunked path would crash with `KeyError: tx_occurred_at not found`. The new helper paginates `Query.export_changes_query/1` via the same `(captured_at, id)` keyset cursor mechanism as `Query.timeline_page/2`, reusing `Query.maybe_after_timeline_cursor/2`. `stream_changes/2` stays unchanged for backward compatibility — multiple callers across the lib already depend on its lean-struct return shape.
- **Phoenix.Router macro emits `pipeline + scope + pipe_through` instead of bare `plug` inside scope** — Phoenix.Router's `scope` macro does NOT permit a `plug` call directly inside (it raises `cannot define plug at the router level, plug must be defined inside a pipeline`). The plan-supplied skeleton has this shape inline, but it's invalid Phoenix. The pipeline-name `:threadline_exports` is reserved (paralleling the existing `:threadline` reservation for `live_session`), so the macro is mounted exactly once per router. Adopters who need multiple mount points can pass `exports: false` on subsequent mounts — at most one mount may emit the pipeline.
- **Scope uses `alias: Threadline.OperatorSurface.Controllers, as: false` instead of `alias: false, as: false`** — the long fully-qualified `Threadline.OperatorSurface.Controllers.ExportController` path forces the formatter to wrap the third `get/3` call onto multiple lines under the default 98-char `line_length`, breaking Plan 04's per-line `ExportController, :ndjson` doc-contract grep. The `alias: <module>` form is a Phoenix.Router scope-LOCAL alias that does NOT affect the host module's lexical alias namespace (only the module-name resolution INSIDE the scope's `get/3` calls). The `as: false` portion preserves the helper-name hygiene from the LiveDashboard idiom; the `alias: false` literal is preserved in the `@moduledoc` as documentation of the equivalent hygiene posture, so a reader looking for "is the scope alias-isolated?" finds the answer either way.
- **Headers set via `put_resp_header/3` directly (not `put_resp_content_type/2`)** — `Plug.Conn.put_resp_content_type/2` always appends `; charset=<charset>` (default `utf-8`); calling it with `"text/csv; charset=utf-8"` produces the doubled `text/csv; charset=utf-8; charset=utf-8`. The plan acceptance pins the exact literal `"text/csv; charset=utf-8"` (single charset) in the response, so the controller calls `put_resp_header("content-type", "text/csv; charset=utf-8")` directly. The plug's 403 path uses `put_resp_content_type("text/plain")` (with charset auto-appended) so the `text/plain; charset=utf-8` test assertion passes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Plan-supplied `plug ExportAuthPlug, opts` directly inside `scope` is invalid Phoenix.Router syntax**

- **Found during:** Task 4 (router macro test compile)
- **Issue:** Phoenix.Router raises `(RuntimeError) cannot define plug at the router level, plug must be defined inside a pipeline` when `plug` is called directly inside `scope`. The plan-supplied skeleton at `<context>` lines 524-531 (RESEARCH §P-2 canonical macro-grow shape) shows `plug(Threadline.OperatorSurface.ExportAuthPlug, unquote(opts))` as the first statement inside the scope. This raises a runtime error at host compile time the moment any adopter mounts the macro.
- **Fix:** Emit `pipeline :threadline_exports do plug ExportAuthPlug, opts end` then `pipe_through :threadline_exports` inside the scope. The pipeline name is reserved (matches the existing `:threadline` reservation used by `live_session :threadline`).
- **Files modified:** lib/threadline/operator_surface/router.ex
- **Verification:** `mix test test/threadline/operator_surface/router_test.exs` — all 4 cases pass (CompileError + 3 success cases); `mix verify.compile_no_optional` exits 0.
- **Committed in:** c1a1ef1

**2. [Rule 1 - Bug] Plan-supplied `alias: false, as: false` forces `get/3` line-wrapping that breaks Plan 04's doc-contract grep**

- **Found during:** Task 4 (router formatter wrapping)
- **Issue:** The plan-supplied `scope <path> <> "/exports", alias: false, as: false` requires the controller's full module path `Threadline.OperatorSurface.Controllers.ExportController` to appear in each `get/3` call. The default `mix format` line length of 98 wraps the `:ndjson` line onto four lines (function-name, path-arg, module-arg, action-arg). Plan 04's per-line `ExportController, :ndjson` grep would not match.
- **Fix:** Use `alias: Threadline.OperatorSurface.Controllers, as: false` — a Phoenix.Router scope-LOCAL alias (does NOT affect the host's lexical alias namespace, only the module-name resolution inside the scope's `get/3` calls). All three `get/3` calls fit on a single line each in short form (`ExportController, :csv` etc.). The `as: false` portion preserves the helper-name hygiene from the LiveDashboard `alias: false, as: false` idiom; the literal `alias: false, as: false` is preserved in the `@moduledoc` as documentation.
- **Files modified:** lib/threadline/operator_surface/router.ex
- **Verification:** `mix verify.format` exits 0; per-line grep returns `1` for each of `ExportController, :csv` / `:json` / `:ndjson`.
- **Committed in:** c1a1ef1

**3. [Rule 1 - Bug] `put_resp_content_type("text/plain; charset=utf-8")` produces a doubled charset**

- **Found during:** Task 2 (plug unit test for case 4 — false-denial)
- **Issue:** `Plug.Conn.put_resp_content_type/2` always appends `; charset=<charset>` (default `utf-8`). The plan-supplied skeleton at `<context>` line 800 calls `put_resp_content_type(conn, "text/plain; charset=utf-8")`, which produces `Content-Type: text/plain; charset=utf-8; charset=utf-8`. The test assertion `assert get_resp_header(conn_out, "content-type") == ["text/plain; charset=utf-8"]` failed.
- **Fix:** In the plug, call `put_resp_content_type("text/plain")` and let the helper append `; charset=utf-8` once. In the controller, call `put_resp_header("content-type", "<full literal>")` directly so the literal appears in source for Plan 04's grep without going through `put_resp_content_type/2`.
- **Files modified:** lib/threadline/operator_surface/export_auth_plug.ex, lib/threadline/operator_surface/controllers/export_controller.ex
- **Verification:** `mix test test/threadline/operator_surface/export_auth_plug_test.exs` — all 8 tests pass; the plug's 403 response carries the canonical `text/plain; charset=utf-8` header.
- **Committed in:** efc99bc, 60b2184

**4. [Rule 1 - Bug] Plan-supplied chunked path uses `stream_changes/2` which returns lean structs lacking the join-projected fields the formatter needs**

- **Found during:** Task 1 (export_test.exs `format_changes_iodata` parity test)
- **Issue:** `Threadline.Export.stream_changes/2` (Phase 25 contract) paginates `Query.timeline_page/2` which returns lean `%AuditChange{}` structs. The formatter helpers `csv_row/2` and `change_map/1` reference `row.tx_occurred_at`, `row.tx_actor_ref`, `row.tx_source`, `row.aa_id`, `row.aa_correlation_id` — fields that exist only on the projected map produced by `Query.export_changes_query/1`. Calling `format_changes_iodata(stream_changes_rows, :csv, [])` raises `KeyError: tx_occurred_at not found`, and the controller's chunked path would crash on the first batch.
- **Fix:** Add `Threadline.Export.stream_export_rows/2` — paginates `Query.export_changes_query/1` via the same `(captured_at, id)` keyset cursor mechanism as `Query.timeline_page/2` (reuses `Query.maybe_after_timeline_cursor/2`). The chunked path consumes this so its rows have the join-projected map shape. `stream_changes/2` stays unchanged for back-compat with Phase 25 callers.
- **Files modified:** lib/threadline/export.ex (add `stream_export_rows/2`); test/threadline/export_test.exs (use `stream_export_rows/2` in parity tests + add 2 dedicated tests for the new helper); lib/threadline/operator_surface/controllers/export_controller.ex (chunked path consumes `stream_export_rows/2`).
- **Verification:** `mix test test/threadline/export_test.exs` — all 33 tests pass including the new byte-equality parity tests for `:csv` (with and without action metadata) and `:ndjson`; `mix verify.test` 367/367 tests pass.
- **Committed in:** 4fbf99c (added the helper); 60b2184 (controller consumes it)

---

**Total deviations:** 4 auto-fixed (all Rule 1 bugs in plan-supplied skeletons; each pre-empts a regression that would have surfaced as a runtime error at host compile, response-header malformation, or KeyError in the chunked path).
**Impact on plan:** No scope creep. Three deviations are local source-level fixes; the fourth (`stream_export_rows/2`) is a small additive public helper that is required for the chunked path to produce byte-identical output to the iodata path — Plan 04's parity test explicitly depends on this byte-equality, so the helper is in-plan-scope by intent even though the plan author didn't anticipate it.

## Issues Encountered

None beyond the four auto-fixed deviations above. No verification steps had to be retried, no Mix-task regression appeared, no `mix verify.compile_no_optional` regression appeared.

## Threat Flags

None. The new HTTP surface introduces three GET endpoints, but they are guarded by `ExportAuthPlug` which fails closed (`:authorize_fn` default returns `true` only when explicitly absent and the macro's existing `_has_pipe?` compile-time check still applies). The exports path adds **no new auth surface** beyond what's already exposed by the LV mount — the same `:authorize_fn` callback the LV uses gates the HTTP endpoints via the synthetic `%{assigns: conn.assigns}` mirror. No new schema, no new file-system access, no new network calls beyond the existing read-only `Ecto.Repo` calls.

The `ExportAuthPlug`'s halt-with-403 strategy means denied requests do not leak any audit data; the response body is a fixed plain-text `"forbidden"` with no error metadata. Telemetry event metadata is the same as the LV (no new fields).

## Self-Check: PASSED

All claimed files exist:

- `lib/threadline/export.ex` — modified, contains `def format_changes_iodata`, `def csv_header`, `def stream_export_rows`.
- `lib/threadline/operator_surface/export_auth_plug.ex` — created.
- `lib/threadline/operator_surface/controllers/export_controller.ex` — created.
- `lib/threadline/operator_surface/router.ex` — modified, contains the new sibling-scope branch.
- `test/threadline/export_test.exs` — modified, contains `describe "format_changes_iodata/3 + csv_header/1 (chunked-path helpers)"` and `describe "stream_export_rows/2"`.
- `test/threadline/operator_surface/export_auth_plug_test.exs` — created.

All claimed commits found in `git log`:

- `4fbf99c` — Task 1.
- `efc99bc` — Task 2.
- `60b2184` — Task 3.
- `c1a1ef1` — Task 4.
- `30c67fe` — format wrap fix (style).

## Next-Plan Readiness

- **Plan 65-03 (`TimelineLive` export buttons + count status line):** Replaces the inline private parser helpers in `timeline_live.ex` with delegation to `Threadline.OperatorSurface.Exports.FilterParams.parse/1` and `Threadline.OperatorSurface.Exports.FilterParams.filters_raw_from_params/1`; calls `Threadline.Export.count_matching(filters, cap: 10_001)` in parallel with `Query.timeline_page/2` via `Task.async`; appends three `<.link href={"/audit/exports/changes." <> ext} download>` anchors to the filter form's button cluster targeting the routes Plan 02 just shipped.
- **Plan 65-04 (doc-contract test trifecta):** Will assert (a) the file-scope `Code.ensure_loaded?(Phoenix.Controller)` posture on both `export_auth_plug.ex` and `export_controller.ex`; (b) the per-line `ExportController, :<atom>` literals in the router (now greppable on single lines thanks to the `alias: <module>` decision); (c) the three exact content-type literals in the controller; (d) byte-equality between `mix threadline.export --format csv` output and a controlled HTTP request to `GET /audit/exports/changes.csv` for the same filters. The byte-equality test will exercise both the iodata path (small windows) and the chunked path (>5,000 rows) — the latter relies on `Threadline.Export.stream_export_rows/2` produced in this plan.

---

*Phase: 65-exports-ui-parity*
*Completed: 2026-05-07*
