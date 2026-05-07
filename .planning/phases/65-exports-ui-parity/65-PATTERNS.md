# Phase 65: Exports UI Parity - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 11 (5 NEW, 5 EDIT, 1 ADDITIVE-LIB-EDIT)
**Analogs found:** 11 / 11 (every new file has at least a role-match analog already in the codebase)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/threadline/operator_surface/controllers/export_controller.ex` (NEW) | Phoenix.Controller (csv/2, json/2, ndjson/2) | request-response + chunked streaming | `lib/mix/tasks/threadline.export.ex:73-110` (flag→opt mapping + format dispatch) + `lib/threadline/operator_surface/auth.ex` (file-scope gating shape, telemetry idiom) | role-NEW (no existing Phoenix.Controller); flow-match against Mix-task `to_csv_iodata`/`to_json_document` dispatch. Diverges: HTTP transport (send_resp / send_chunked) instead of `File.write!`; threshold dispatch is new. |
| `lib/threadline/operator_surface/export_auth_plug.ex` (NEW) | Plug @behaviour | request-response + side-effects (telemetry + halt) | `lib/threadline/operator_surface/auth.ex:1-64` (LV-side authorize contract — granted/denied/error telemetry, scope assign, halt strategy) + `lib/threadline/plug.ex:68-96` (Conn-shaped `@behaviour Plug` shape with `init/1`/`call/2`) | exact role-match for the dual-callback Conn-shaped pattern; LV `Auth.on_mount/4` is the semantic twin. Diverges: operates on `%Plug.Conn{}` not `%Phoenix.LiveView.Socket{}`; halts with `send_resp(403)` instead of `redirect(to: "/")`. |
| `lib/threadline/operator_surface/exports/filename.ex` (NEW) | Pure helper module (no IO, no Phoenix dep) | transform | None in `lib/threadline/operator_surface/`; closest stdlib-only sibling is `lib/threadline/semantics/actor_ref.ex` (pure constructor with `@spec`, fixed enum, `@moduledoc`) | role-NEW (first non-Phoenix-gated module under `operator_surface/`); copy `actor_ref.ex`'s docstring + `@spec` + guard shape. |
| `test/threadline/operator_surface/controllers/export_controller_test.exs` (NEW) | Phoenix.ConnTest integration test (nested Endpoint) | request-response + DB-side-effect (seed) | `test/threadline/operator_surface/live/timeline_live_test.exs:1-124` (nested Layouts + Router + Endpoint + setup_all shape) + `test/mix/tasks/threadline/export_test.exs:1-41` (lib seeding via Repo.insert! + DataCase cleanup pattern) | exact harness shape match — adopt `TimelineLiveTest.Endpoint` skeleton verbatim, swap `Phoenix.LiveViewTest` for `Phoenix.ConnTest`. |
| `test/threadline/operator_surface/exports_doc_contract_test.exs` (NEW) | Doc-contract test (read source, assert literals) | file-I/O | `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs:1-153` (regex-over-source, ARIA + filter-key parity + file-scope gate + native-widget assertions) + `test/threadline/operator_surface_doc_contract_test.exs:1-31` (older minimal `String.contains?` shape) | exact role-match — Phase 64's BROWSE-04 doc-contract IS the template; rename + replace assertion bodies. |
| `test/threadline/operator_surface/exports_mix_parity_test.exs` (NEW) | Byte-equality parity test (Mix task vs controller) | request-response + Mix-task-execution + file-I/O | `test/mix/tasks/threadline/export_test.exs:1-41` (Mix.Task invocation + capture_io + DataCase) + the new `export_controller_test.exs` (controller invocation half) | role-NEW (no existing parity test); compose the two halves: Mix-task half from `export_test.exs`, controller half from new `export_controller_test.exs`. |
| `test/threadline/operator_surface/export_auth_plug_test.exs` (NEW, recommended supplementary — surfaced in RESEARCH §"Recommended Project Structure") | Plug unit test | request-response + telemetry-assertion | `test/threadline/operator_surface/auth_test.exs:1-80` (telemetry-handler-attach setup, mock_socket helper, `:granted`/`:denied`/`:error` cases) + `test/threadline/plug_test.exs:1-100` (Plug-side `Plug.Test.conn(:get, "/")` + `call/2` shape) | exact role-match — fuse the LV `auth_test.exs` telemetry shape with `plug_test.exs`'s Conn-construction shape. |
| `lib/threadline/operator_surface/router.ex` (EDIT) | Plug+LV router macro | n/a (compile-time) | itself, lines 38-48 (`live_session :threadline` block + macro hygiene) | exact (sibling `scope unquote(path) <> "/exports"` block adjacent to existing `live_session` block; reuse `Code.ensure_loaded?` guard idiom, this time gating on `Phoenix.Controller` inside the `quote`) |
| `lib/threadline/operator_surface/live/timeline_live.ex` (EDIT) | LiveView render + handle_params | request-response + parallel-task | itself, render block lines 165-242 + `handle_params/3` lines 57-126 | exact (append three `<.link href download>` to existing `.button-cluster`; insert count status line + two-band banner above existing `<section class="timeline-rows">`; replace single `Query.timeline_page/2` call at line 112 with `Task.async`+`Task.await` pair) |
| `lib/threadline/operator_surface/style.ex` (EDIT) | CSS module (HEEx `<style>` block) | static render | itself, lines 162-176 (`.button-cluster` + `.button-cluster button` rules), lines 184-195 (`.filter-error` + `.filter-hint` informational variants) | exact (extend the existing `~H` block with `.export-cluster`, `.match-count-status`, `.truncation-banner.informational`, `.truncation-banner.warning` — reuse existing CSS variables `--tl-spacing-*`, `--tl-color-*`, `--tl-font-*`) |
| `test/threadline/operator_surface/live/timeline_live_test.exs` (EDIT) | LV integration test extension | request-response | itself, Cases 1-9 (mount + filter parity + URL round-trip + viewport-bottom assertions) | exact (add Cases for: three download anchor hrefs at expected paths; match-count status line text; two-band truncation banner rendering at counts 5_001 and 10_001) |
| `lib/threadline/export.ex` (EDIT — additive `:cap` opt on `count_matching/2`) | Library API extension | CRUD + DB-aggregate | itself, `count_matching/2` at lines 151-172 (existing `:correlation_id`-aware select branch) | exact (additive `Keyword.get(opts, :cap)`; if integer, wrap in `from(sub in subquery(... |> limit(^cap)), select: count())` per RESEARCH §P-8 SQL pattern) |

## Pattern Assignments

### `lib/threadline/operator_surface/controllers/export_controller.ex` (NEW, controller, request-response + chunked streaming)

**Primary analog:** `lib/mix/tasks/threadline.export.ex` (lines 73-110) — same flag→opt mapping the controller mirrors at the URL level.
**Supporting analog:** `lib/threadline/operator_surface/auth.ex:1-3, 63-64` — file-scope `Code.ensure_loaded?` wrapper shape.
**Supporting analog:** RESEARCH §P-4 (canonical controller shape) — full controller skeleton.

#### File-scope gating (D-21, mandatory)

Lift the wrapper shape from `auth.ex:1, 63-64` verbatim, but gate on `Phoenix.Controller` (NOT `Phoenix.LiveView`):

```elixir
# Source: lib/threadline/operator_surface/auth.ex:1-3, 63-64 (existing wrapper template)
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Auth do
    # …
  end
end
```

> **Adapt to:** `if Code.ensure_loaded?(Phoenix.Controller) do … end`. The doc-contract test at `exports_doc_contract_test.exs` MUST pin this exact first line via `assert String.starts_with?(src, "if Code.ensure_loaded?(Phoenix.Controller) do")` (RESEARCH §P-9, line 838-840). `mix verify.compile_no_optional` regresses if the gate is missing.

#### Format dispatch table (lift from Mix task)

The Mix task's `case format do "csv" -> Export.to_csv_iodata(...); "json" -> Export.to_json_document(...) end` (`threadline.export.ex:99-102`) is the EXACT shape the controller's three actions must mirror — same call site, same opts derivation:

```elixir
# Source: lib/mix/tasks/threadline.export.ex:73-102 (flag→opt mapping the controller mirrors)
format = String.downcase(format)

unless format in ["csv", "json"] do
  Mix.raise("threadline.export: --format must be csv or json, got: #{inspect(format)}")
end

max_rows_kw = if(n = opts[:max_rows], do: [max_rows: n], else: [])

json_format_kw =
  case opts[:json_format] do
    nil -> []
    "wrapped" -> [json_format: :wrapped]
    "ndjson" -> [json_format: :ndjson]
    other -> Mix.raise("threadline.export: unknown --json-format #{inspect(other)}")
  end

{:ok, %{count: count}} = Export.count_matching(filters, [])
banner(repo, count)

{:ok, %{data: data}} =
  case format do
    "csv" -> Export.to_csv_iodata(filters, max_rows_kw)
    "json" -> Export.to_json_document(filters, max_rows_kw ++ json_format_kw)
  end
```

> **What to copy literally:** the `Export.to_csv_iodata(filters, max_rows_kw)` and `Export.to_json_document(filters, max_rows_kw ++ json_format_kw)` call shapes — the parity test at `exports_mix_parity_test.exs` proves byte-equality precisely because both surfaces hit the same `Threadline.Export.{to_csv_iodata, to_json_document}/2` API with the same opts.

> **What MUST diverge:** the controller has THREE actions (`csv/2`, `json/2`, `ndjson/2`) instead of one `--format` flag (D-22 — the UI's analog of a flag is a separate visible affordance, not a hidden URL param). Map URL extension to opts: `.csv → []`, `.json → [json_format: :wrapped]`, `.ndjson → [json_format: :ndjson]`. RESEARCH §P-4 lines 462-464 has the canonical three-action shape.

> **What MUST diverge:** the controller dispatches between `to_csv_iodata` (≤5k count) and `send_chunked + stream_changes` (>5k count); Mix task always writes a single iodata blob via `File.write!/2`. The threshold compare is the controller's responsibility (D-24).

#### Chunked stream + `Plug.Conn.chunk/2` reduce_while pattern (Pitfall 1 + RESEARCH §P-4)

No existing analog in the project — adopt the RESEARCH §P-4 canonical pattern verbatim. The shape is load-bearing because `Plug.Conn.chunk/2` returns `{:ok, conn} | {:error, term()}` (NOT `:ok`); `Enum.into/2` and `Enum.reduce/3` silently swallow `{:error, :closed}` and continue writing to a closed socket.

```elixir
# Source: RESEARCH §P-4 lines 504-519 (canonical chunked-stream pattern)
defp send_chunked_stream(conn, filters, format) do
  conn = send_chunked(conn, 200)

  filters
  |> Export.stream_changes(page_size: 1_000)
  |> Stream.take(@max_rows)                         # ◄── Pitfall 4: stream_changes does NOT enforce :max_rows
  |> rows_to_chunks(format)
  |> Stream.chunk_every(500)
  |> Enum.reduce_while(conn, fn chunk, conn ->
    case Plug.Conn.chunk(conn, chunk) do
      {:ok, conn}        -> {:cont, conn}
      {:error, :closed}  -> {:halt, conn}
      {:error, _other}   -> {:halt, conn}
    end
  end)
end
```

> **What to copy literally:**
> - `Stream.take(@max_rows)` BEFORE `Stream.chunk_every(500)` — without it, multi-million-row tables stream past the 10k truncation contract (Pitfall 4, RESEARCH §"Anti-Patterns" line 1139). Doc-contract test should grep `Stream.take(10_000)` literal in source.
> - `Enum.reduce_while/3` with explicit `{:cont, conn}` / `{:halt, conn}` — never `Enum.reduce/3` (RESEARCH §"Anti-Patterns" line 1137).
> - All `put_resp_header/3` calls MUST come BEFORE `send_chunked/2` (Pitfall 2, RESEARCH §P-4 line 570).

#### RFC 5987 `Content-Disposition` header (D-25, P-5)

```elixir
# Source: RESEARCH §P-5 lines 580-585 (no Phoenix helper exists for dynamic-iodata downloads)
filename = Filename.for("csv", DateTime.utc_now())
disposition = ~s|attachment; filename="#{filename}"; filename*=UTF-8''#{filename}|

put_resp_header(conn, "content-disposition", disposition)
```

> **What to copy literally:** the `~s|attachment; filename="..."; filename*=UTF-8''...|` interpolation. Both `filename=` (legacy ASCII) and `filename*=UTF-8''` (RFC 5987 modern form) MUST be emitted (RFC 6266 §4.3 belt+braces). For Threadline's ASCII-only filenames they're identical strings; emit both anyway for future-proofing.

> **Doc-contract test pins** the three content-type literals verbatim:
> - `"text/csv; charset=utf-8"`
> - `"application/json; charset=utf-8"`
> - `"application/x-ndjson; charset=utf-8"`
> (RESEARCH §P-9 lines 791-793). Use `put_resp_content_type(conn, "text/csv; charset=utf-8")` so the literal appears in source.

#### `count_matching` returns `{:ok, %{count: N}}` — destructure (Pitfall 5)

```elixir
# Source: lib/mix/tasks/threadline.export.ex:67 (Mix task already destructures correctly)
{:ok, %{count: count}} = Export.count_matching(filters, [])
```

> **DO NOT write** `count = Export.count_matching(filters, [])` — `count` becomes `{:ok, %{count: N}}` and `if count > 5_000` compares a tuple to an integer (always falsy or truthy depending on Erlang term order). The Mix task at line 67 already destructures correctly; mirror exactly.

#### Filter-validation rescue (lift from TimelineLive)

```elixir
# Source: lib/threadline/operator_surface/live/timeline_live.ex:366-373 (single source of truth for filter validation)
defp safe_validate(filters) do
  try do
    Threadline.Query.validate_timeline_filters!(filters)
    :ok
  rescue
    e in ArgumentError -> {:error, e.message}
  end
end
```

> **Lift verbatim** to the controller. Map `{:error, message}` to `send_resp(conn, 422, "invalid filter: #{message}")` with `Content-Type: text/plain; charset=utf-8`. Critical: NEVER invent a parallel UI-only filter dialect (RESEARCH §"Anti-Patterns" + Phase 64 PATTERNS Footgun F-2 echo).

#### Filter-param parsing (RESEARCH Pitfall 3 — extract shared helper)

The TimelineLive functions `filters_raw_from_params/1` (timeline_live.ex:264-280), `normalize_params/1` (timeline_live.ex:282-290), `parse_datetimes/1` (timeline_live.ex:292-315), `parse_datetime_local/1` (timeline_live.ex:375-385), `collapse_actor_ref/1` (timeline_live.ex:317-356), `safe_actor_kind/1` (timeline_live.ex:387-393), and `build_filters/1` (timeline_live.ex:358-364) collectively encode the canonical URL-params → filters keyword pipeline.

> **What to do:** Extract these to `Threadline.OperatorSurface.Exports.FilterParams` (per RESEARCH §"Recommended Project Structure" line 264). BOTH TimelineLive (modify to delegate) AND ExportController (new — call) consume the shared module. Without this extraction, the parity test at `exports_mix_parity_test.exs` becomes a hand-copy guard rather than a structural guarantee. **Do not copy-paste the parser into the controller.**

> **Datetime-local pad rule (load-bearing, lifted from `timeline_live.ex:378-385`):**
> ```elixir
> defp parse_datetime_local(str) when is_binary(str) do
>   padded = if String.length(str) == 16, do: str <> ":00Z", else: str <> "Z"
>   case DateTime.from_iso8601(padded) do
>     {:ok, dt, _offset} -> {:ok, dt}
>     _ -> {:error, :invalid_datetime}
>   end
> end
> ```

#### Repo + scope resolution (mirror TimelineLive shape)

```elixir
# Source: lib/threadline/operator_surface/live/timeline_live.ex:18-23 (mount-time resolution)
repo =
  socket.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()

scope = socket.assigns[:threadline_scope]
```

> **Adapt to:** `conn.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()`. Bracket form (`[:threadline_scope]`) MUST be used — Phase 64 PATTERNS F-9: `:threadline_scope` may be absent when `:authorize_fn` returns `:ok`/`true`. The auth plug assigns `:threadline_repo` from `opts` (mirroring `auth.ex:11, 16`).

---

### `lib/threadline/operator_surface/export_auth_plug.ex` (NEW, Plug, request-response + telemetry)

**Primary analog:** `lib/threadline/operator_surface/auth.ex:1-64` — the LV-side `on_mount/4` is the semantic twin. Same telemetry events, same scope-assign shape, same try/rescue catch-all.
**Supporting analog:** `lib/threadline/plug.ex:68-96` — the `@behaviour Plug` shape (`init/1` + `call/2`) and `import Plug.Conn, only: [...]` idiom.

#### File-scope gating (D-21, mandatory)

Same shape as `auth.ex:1, 63-64`, gating on `Phoenix.Controller`:

```elixir
# Source: RESEARCH §P-3 lines 357-435 (full canonical plug)
if Code.ensure_loaded?(Phoenix.Controller) do
  defmodule Threadline.OperatorSurface.ExportAuthPlug do
    @behaviour Plug
    import Plug.Conn
    # …
  end
end
```

> Doc-contract test (RESEARCH §P-9 lines 842-845) pins the first line via `assert String.starts_with?(src, "if Code.ensure_loaded?(Phoenix.Controller) do")`.

#### Auth try/rescue + telemetry (lift from `auth.ex:19-43` verbatim shape)

The LV `Auth.on_mount/4` is the structural template. The plug operates on `%Plug.Conn{}` instead of `%Phoenix.LiveView.Socket{}`, but the case-tree on `authorize_fn.()` return values is IDENTICAL.

```elixir
# Source: lib/threadline/operator_surface/auth.ex:19-44 (LV-side try/case-tree — copy structurally)
try do
  case authorize_fn.(socket) do
    :ok ->
      emit_telemetry(:granted, socket, nil)
      {:cont, socket}

    true ->
      emit_telemetry(:granted, socket, nil)
      {:cont, socket}

    {:ok, scope} when is_map(scope) ->
      emit_telemetry(:granted, socket, scope)
      {:cont, Phoenix.Component.assign(socket, :threadline_scope, scope)}

    {:ok, scope} ->
      emit_telemetry(:granted, socket, nil)
      {:cont, Phoenix.Component.assign(socket, :threadline_scope, scope)}

    _ ->
      halt_unauthorized(socket, :denied)
  end
rescue
  _ ->
    halt_unauthorized(socket, :error)
end
```

> **What to copy literally:**
> - The five-arm case tree: `:ok | true | {:ok, scope} when is_map(scope) | {:ok, scope} | _`. Both `:ok` and `true` are accepted as "authorized, no scope" (Auth Cases 1 + 3 in `auth_test.exs:37-73`).
> - Telemetry event name `[:threadline, :operator_surface, :authorize]` (auth.ex:58) — adopters watching this event get one stream of auth decisions across both surfaces (RESEARCH §P-3 line 438). DO NOT introduce a new event name.
> - Measurements `%{result: result}` and metadata `%{path: "", actor_ref: ..., scope_keys: ...}` (auth.ex:59-61) — preserve verbatim for parity.
> - The `rescue _` catch-all → `:error` telemetry shape (auth.ex:40-43) — without it, host `authorize_fn`s that raise leak the exception through to Plug's default 500 handler instead of producing a clean 403.

> **What MUST diverge:**
> - **Halt response:** `auth.ex:48` halts with `{:halt, redirect(socket, to: "/")}` — appropriate for an interactive page navigation. The plug halts with `send_resp(conn, 403, "forbidden")` + `halt()` because there's no redirect target that makes sense for a download anchor (RESEARCH §P-3 line 440). Use `Content-Type: text/plain; charset=utf-8` for parity with the controller's 422 path.
> - **Scope assign:** the LV uses `Phoenix.Component.assign(socket, :threadline_scope, scope)` (auth.ex:31, 35); the plug uses `Plug.Conn.assign(conn, :threadline_scope, scope)`. Both end up readable as `assigns[:threadline_scope]`.
> - **Authorizer dispatch (D-20 — the new bit):** the plug accepts BOTH `:export_authorize_fn` (Conn-shaped, called with `conn` directly) AND `:authorize_fn` (LV-shaped, wrapped in a synthetic `%{assigns: conn.assigns}` mirror). The LV `Auth.on_mount/4` only knows about `:authorize_fn`. Code shape (RESEARCH §P-3 lines 374-387):
>
>   ```elixir
>   authorizer =
>     case export_authorize_fn do
>       fun when is_function(fun, 1) ->
>         fn -> fun.(conn) end
>       nil ->
>         fn ->
>           mirror = %{assigns: conn.assigns}
>           authorize_fn.(mirror)
>         end
>     end
>   ```
>
>   The synthetic mirror is the entire D-20 contract — most adopter `:authorize_fn`s only access `assigns.current_user` or similar, so the mirror suffices. v1.17 `:authorize_fn.(socket)` contract stays frozen.

#### Plug behaviour shape (lift from `plug.ex:68-96`)

```elixir
# Source: lib/threadline/plug.ex:68-83 (existing @behaviour Plug pattern)
@behaviour Plug

import Plug.Conn, only: [get_req_header: 2, assign: 3]

@impl Plug
def init(opts) do
  %{
    actor_fn: Keyword.get(opts, :actor_fn),
    context_overrides_fn: Keyword.get(opts, :context_overrides_fn)
  }
end

@impl Plug
def call(conn, %{actor_fn: actor_fn, context_overrides_fn: context_overrides_fn}) do
  # …
end
```

> **Adapt:** `init/1` returns the raw opts keyword (RESEARCH §P-3 line 364: `def init(opts), do: opts`) — the plug receives the macro's opts via `unquote(opts)` (router.ex pattern P-2 line 334). `call/2` destructures `:authorize_fn`, `:export_authorize_fn`, `:repo` from opts.

> **Repo passthrough:** the plug should `assign(conn, :threadline_repo, repo)` so the controller can read it via `conn.assigns[:threadline_repo]` (mirroring `auth.ex:16`). The macro passes the same `:repo` opt down (router.ex P-2).

#### Telemetry test setup (mirror `auth_test.exs:15-34`)

```elixir
# Source: test/threadline/operator_surface/auth_test.exs:15-34 (telemetry-handler-attach setup)
setup do
  pid = self()
  handler_id = "auth_test_#{System.unique_integer()}"

  :telemetry.attach(
    handler_id,
    [:threadline, :operator_surface, :authorize],
    fn name, measurements, metadata, _config ->
      send(pid, {:telemetry_event, name, measurements, metadata})
    end,
    nil
  )

  on_exit(fn ->
    :telemetry.detach(handler_id)
  end)

  :ok
end
```

> Lift verbatim into `export_auth_plug_test.exs`. Then assert the same five cases (`:ok`, `true`, `{:ok, map_scope}`, `{:ok, non_map_scope}`, `false` denial, `raise → :error`) using `Plug.Test.conn(:get, "/audit/exports/changes.csv")` instead of `mock_socket()`. Cases 1-7 of `auth_test.exs` are the test-case template.

---

### `lib/threadline/operator_surface/exports/filename.ex` (NEW, pure helper, transform)

**Closest analog:** `lib/threadline/semantics/actor_ref.ex:1-52` — the only other pure-stdlib module under `lib/threadline/` with a `@spec` constructor + fixed string allowlist + no Phoenix/Ecto deps. Its docstring + `@spec` shape is the template.

#### Pure helper file (no `Code.ensure_loaded?` wrapper — D-21 deliberately excludes it)

```elixir
# Source: RESEARCH §P-6 lines 600-624 (canonical helper)
defmodule Threadline.OperatorSurface.Exports.Filename do
  @moduledoc """
  Canonical filename for operator-surface and Mix-task exports.

  Format: `threadline-changes-YYYY-MM-DDTHH-MM-Z.{csv|json|ndjson}` — UTC,
  minute granularity (per EXPO-04 literal example `2026-05-06T12-00Z`).

  Filenames are ASCII by construction; no RFC 5987 percent-encoding required.
  """

  @valid_formats ~w(csv json ndjson)

  @spec for(String.t(), DateTime.t()) :: String.t()
  def for(format, %DateTime{} = dt) when format in @valid_formats do
    stamp = format_stamp(dt)
    "threadline-changes-#{stamp}.#{format}"
  end

  defp format_stamp(%DateTime{} = dt) do
    dt
    |> DateTime.shift_zone!("Etc/UTC")
    |> Calendar.strftime("%Y-%m-%dT%H-%MZ")
  end
end
```

> **What to copy literally:**
> - Format string `"%Y-%m-%dT%H-%MZ"` — produces the exact `2026-05-06T12-00Z` shape from EXPO-04. The hyphen between hours and minutes (NOT colon) is filesystem-friendly (Windows forbids colons).
> - `@valid_formats ~w(csv json ndjson)` — the doc-contract test asserts these three formats and no others (RESEARCH §P-9 lines 798-803).
> - `Calendar.strftime/2` — Elixir stdlib since 1.11; no new dep.
> - `DateTime.shift_zone!/2` to "Etc/UTC" — defends against accidental local-tz inputs (any future caller passing a non-UTC datetime gets normalized).

> **What MUST diverge from `actor_ref.ex`:**
> - No `@types` enum-style atom list — formats are strings (URL-extension parity).
> - No tagged-tuple return — `for/2` returns a bare string. Errors go through guard mismatch (raises `FunctionClauseError`) — invalid format = programmer error, not user-input error.

> **Doc-contract requirement (RESEARCH §P-9 line 850):** test asserts `refute String.contains?(src, "Code.ensure_loaded?")` — the helper is pure stdlib with no optional deps. Don't accidentally add a wrapper.

> **Test shape:** `test/threadline/operator_surface/exports/filename_test.exs` is `use ExUnit.Case, async: true` (no DataCase, no DB). Three trivial assertions:
> ```elixir
> dt = ~U[2026-05-06 12:00:00.000Z]
> assert Filename.for("csv", dt) == "threadline-changes-2026-05-06T12-00Z.csv"
> assert Filename.for("json", dt) == "threadline-changes-2026-05-06T12-00Z.json"
> assert Filename.for("ndjson", dt) == "threadline-changes-2026-05-06T12-00Z.ndjson"
> ```

---

### `test/threadline/operator_surface/controllers/export_controller_test.exs` (NEW, integration test, request-response + DB-side-effect)

**Primary analog:** `test/threadline/operator_surface/live/timeline_live_test.exs:1-124` — the nested `Layouts + Router + Endpoint + setup_all` shape is exactly what the controller test needs; only difference is `Phoenix.LiveViewTest` swaps for `Phoenix.ConnTest`.
**Supporting analog:** `test/mix/tasks/threadline/export_test.exs:1-41` — the `Repo.insert!` + `AuditTransaction.changeset` + `AuditChange.changeset` seeding shape, plus `use Threadline.DataCase` (`async: false`, FK-order `delete_all` cleanup) — but the controller test cannot use DataCase directly (it needs the Endpoint plumbing).

#### Test harness (lift from `timeline_live_test.exs:1-124` verbatim, rename to `ExportControllerTest`)

```elixir
# Source: test/threadline/operator_surface/live/timeline_live_test.exs:1-57 (nested Layouts + Router + Endpoint)
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.TimelineLiveTest.Layouts do
    use Phoenix.Component
    def root(assigns) do
      ~H"""
      <html><head><title>Test</title></head><body><%= @inner_content %></body></html>
      """
    end
    def render("500.html", assigns) do
      ~H"Error 500: <%= inspect(assigns.reason) %>"
    end
  end

  defmodule Threadline.OperatorSurface.TimelineLiveTest.Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)
      plug(:put_root_layout, html: {Threadline.OperatorSurface.TimelineLiveTest.Layouts, :root})
    end

    scope "/" do
      pipe_through(:browser)
      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit")
    end
  end

  defmodule Threadline.OperatorSurface.TimelineLiveTest.Endpoint do
    use Phoenix.Endpoint, otp_app: :threadline
    @session_options [store: :cookie, key: "_threadline_key", signing_salt: "v8q+QWvj"]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.TimelineLiveTest.Router)
  end
```

> **What to copy literally:**
> - The four-module structure: `Layouts`, `Router`, `Endpoint`, then the actual test module.
> - `pipeline :browser` with `:accepts`, `:fetch_session`, `:fetch_live_flash`, `:put_root_layout`.
> - `Endpoint` with `Plug.Session`, `:fetch_session`, `Plug.Parsers`, `Plug.MethodOverride`, `Plug.Head`, then the test Router.
> - `setup_all` (timeline_live_test.exs:111-120) doing `Application.put_env` for `secret_key_base`, `live_view`, `render_errors`, then `start_supervised!(@endpoint)`.
> - Mount call: `Threadline.OperatorSurface.Router.threadline_operator_surface("/audit")` — same `/audit` path so URLs `/audit/exports/changes.csv` resolve.

> **What MUST diverge:**
> - Outer wrapper: `if Code.ensure_loaded?(Phoenix.Controller) do` (NOT `Phoenix.LiveView`) — RESEARCH §P-10 line 867. Both deps are present in dev/test, but the controller-side gate is the load-bearing one.
> - `import Phoenix.ConnTest` (NOT `Phoenix.LiveViewTest`) — controller test uses `build_conn() |> get(path)`.
> - `pipeline :browser` accept list extends to `["html", "csv", "json"]` (RESEARCH §P-10 line 879) — Phoenix needs to recognize the format extensions in URLs.
> - `setup` block does `Repo.delete_all` in FK order (mirroring DataCase shape; cannot `use DataCase` because that conflicts with the Endpoint/setup_all bootstrap).

#### `async: false` is mandatory (RESEARCH §P-10 line 1038, mirroring DataCase.ex:8)

```elixir
# Source: test/support/data_case.ex:6-10
@moduledoc """
Test case for integration tests that require a real PostgreSQL database.
Does NOT use Ecto sandbox — PostgreSQL triggers fire at the DB level, outside
sandbox awareness. Each test cleans audit tables in `setup` (FK order).
**`async: false` by default** so tests in the same module never hit the same DB concurrently.
"""
```

> **What to copy literally:**
> - `use ExUnit.Case, async: false` — Postgres triggers don't respect `Ecto.Adapters.SQL.Sandbox`.
> - FK-order cleanup in `setup`: `delete_all(AuditChange)` → `delete_all(AuditTransaction)` → `delete_all(AuditAction)` (data_case.ex:23-25).
> - Bulk seeding via `Repo.insert_all/3` for the >5k case (RESEARCH §P-10 lines 1004-1033) — much faster than 5,001 individual changesets.

#### Test cases to mirror Phase 64's 11-case shape, scoped to controller assertions

Lift the test-case naming convention from `timeline_live_test.exs:176-345` (Cases 1-11). For controller, RESEARCH §P-10 mandates these cases:

| Case | What it asserts | Source pattern |
|------|----------------|----------------|
| iodata-CSV-happy | `GET /audit/exports/changes.csv` with small window → 200 + `text/csv; charset=utf-8` + RFC 4180 body | RESEARCH §P-10 lines 935-951 |
| iodata-JSON-happy | Same shape, `.json` URL → wrapped JSON body parses as `Jason.decode!` | extension of above |
| iodata-NDJSON-happy | Same shape, `.ndjson` URL → each line `Jason.decode!`s | extension of above |
| chunked-CSV-above-5k (D-27) | Seed 5_001 rows, hit `.csv`, assert `conn.state == :chunked` and `conn.resp_body` parses as CSV with ≥5_001 rows | RESEARCH §P-10 lines 956-973 |
| 422 on bad filter | `GET ?from=not-a-date` → 422 + plain text | RESEARCH §P-10 lines 977-982 |
| empty-window CSV header-only | Filter to no matches → 200 + 1-line CSV (header only) | RESEARCH §P-10 lines 990-1000 |
| 403 on auth denial | Separate Endpoint module mounting macro with `authorize_fn: fn _ -> false end` | RESEARCH §P-10 lines 985-986 (recommend separate test module to keep Endpoint setup clean) |

> **`Plug.Test` chunk accumulation:** when testing chunked responses with `Phoenix.ConnTest`, chunks are stitched into `conn.resp_body` and `conn.state == :chunked`. The test asserts byte-content correctness even though transport-wise it was chunked (RESEARCH §P-10 line 1042).

---

### `test/threadline/operator_surface/exports_doc_contract_test.exs` (NEW, doc-contract test, file-I/O)

**Primary analog:** `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs:1-153` (Phase 64's BROWSE-04 doc-contract). Lift the entire file structure verbatim — it is the project's locked template for source-pinning tests.

#### Test module shape (lift from `timeline_browse_doc_contract_test.exs:1-10`)

```elixir
# Source: test/threadline/operator_surface/timeline_browse_doc_contract_test.exs:1-10
defmodule Threadline.OperatorSurface.TimelineBrowseDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @router_path "lib/threadline/operator_surface/router.ex"
  @lv_path "lib/threadline/operator_surface/live/timeline_live.ex"
  @query_path "lib/threadline/query.ex"
  @transaction_lv_path "lib/threadline/operator_surface/live/transaction_live.ex"
  @actor_lv_path "lib/threadline/operator_surface/live/actor_live.ex"
```

> **Adapt:** rename module to `Threadline.OperatorSurface.ExportsDocContractTest`. Module attributes:
> ```elixir
> @router_path     "lib/threadline/operator_surface/router.ex"
> @lv_path         "lib/threadline/operator_surface/live/timeline_live.ex"
> @controller_path "lib/threadline/operator_surface/controllers/export_controller.ex"
> @plug_path       "lib/threadline/operator_surface/export_auth_plug.ex"
> @filename_path   "lib/threadline/operator_surface/exports/filename.ex"
> @query_path      "lib/threadline/query.ex"
> ```

#### Filter-key parity test (LOAD-BEARING — Phase 64 PATTERNS calls this "the load-bearing one")

```elixir
# Source: test/threadline/operator_surface/timeline_browse_doc_contract_test.exs:47-90 (filter-key parity)
test "filter form key list matches Threadline.Query allowlist exactly (BROWSE-04 parity guarantee)" do
  live_src = File.read!(@lv_path)
  query_src = File.read!(@query_path)

  [_, allowlist_block] =
    Regex.run(~r/@allowed_timeline_filter_keys\s+~w\(([^)]+)\)a/, query_src) ||
      flunk("could not find @allowed_timeline_filter_keys in #{@query_path}")

  lib_keys =
    allowlist_block
    |> String.split()
    |> MapSet.new()
    |> MapSet.delete("repo")    # :repo is socket-injected, not URL-supplied

  form_keys =
    Regex.scan(~r/name="filter\[(\w+)\]"/, live_src)
    |> Enum.map(fn [_, k] -> k end)
    |> MapSet.new()

  form_keys_collapsed =
    form_keys
    |> MapSet.delete("actor_kind")
    |> MapSet.delete("actor_id")
    |> MapSet.put("actor_ref")

  assert form_keys_collapsed == lib_keys, "..."
end
```

> **What to copy literally:**
> - The `Regex.run(~r/@allowed_timeline_filter_keys\s+~w\(([^)]+)\)a/, query_src)` extractor — single source of truth for the lib's filter allowlist.
> - The `MapSet.delete("repo")` (socket-injected, not URL-supplied).
> - The `actor_kind` + `actor_id` → `actor_ref` collapse.

> **What MUST diverge for Phase 65:**
> - Read `@controller_path` (not just `@lv_path`) — the controller's filter parsing must reference the same keys. RESEARCH §P-9 lines 808-833 has the canonical controller-side parity assertion.
> - Optional but recommended: assert that BOTH `lib/threadline/operator_surface/live/timeline_live.ex` AND `lib/threadline/operator_surface/controllers/export_controller.ex` reference the shared `Threadline.OperatorSurface.Exports.FilterParams` module (per Pitfall 3 — the extracted helper is the structural guarantee against parser drift).

#### File-scope gate assertions

```elixir
# Source: test/threadline/operator_surface/timeline_browse_doc_contract_test.exs:94-100 (LV gate)
test "timeline live module is wrapped in file-scope Code.ensure_loaded? gate" do
  live_src = File.read!(@lv_path)
  first_line = live_src |> String.split("\n") |> hd()

  assert first_line == "if Code.ensure_loaded?(Phoenix.LiveView) do",
         "expected line 1 of #{@lv_path} to be the Sentry-idiom file-scope gate, got: #{inspect(first_line)}"
end
```

> **Adapt for Phase 65:** add THREE assertions per RESEARCH §P-9 lines 837-852:
> - Controller: `assert String.starts_with?(File.read!(@controller_path), "if Code.ensure_loaded?(Phoenix.Controller) do")`
> - Auth plug: `assert String.starts_with?(File.read!(@plug_path), "if Code.ensure_loaded?(Phoenix.Controller) do")`
> - Filename helper: `refute String.contains?(File.read!(@filename_path), "Code.ensure_loaded?")` — pure stdlib, no gate.

#### Pinned literals (D-26)

Per CONTEXT D-26 + RESEARCH §P-9, pin these literals:

| Literal | File | Source |
|---------|------|--------|
| `"Download CSV"`, `"Download JSON"`, `"Download NDJSON"` | `@lv_path` | RESEARCH §P-9 lines 768-773 |
| `"/changes.csv"`, `"/changes.json"`, `"/changes.ndjson"` | `@router_path` | RESEARCH §P-9 lines 778-781 |
| `"ExportController, :csv"`, `"ExportController, :json"`, `"ExportController, :ndjson"` | `@router_path` | RESEARCH §P-9 lines 782-784 |
| `"text/csv; charset=utf-8"`, `"application/json; charset=utf-8"`, `"application/x-ndjson; charset=utf-8"` | `@controller_path` | RESEARCH §P-9 lines 791-793 |
| `Filename.for("csv", dt) == "threadline-changes-2026-05-06T12-00Z.csv"` (and json, ndjson) | live execution | RESEARCH §P-9 lines 798-803 |

#### `phx-change` prohibition (carry forward Phase 64 D-04 / F-6 — RESEARCH §"Anti-Patterns" line 1145)

The Phase 64 doc-contract `refute String.contains?(live_src, "phx-change=")` (timeline_browse_doc_contract_test.exs:117-127) MUST stay green even after Phase 65's edits to TimelineLive. Recommend re-asserting this in `exports_doc_contract_test.exs` to make Phase 65's commitment explicit.

---

### `test/threadline/operator_surface/exports_mix_parity_test.exs` (NEW, byte-equality test, request-response + Mix-task-execution)

**Primary analog:** `test/mix/tasks/threadline/export_test.exs:1-41` — Mix-task invocation half (`capture_io` + `Mix.Tasks.Threadline.Export.run([...])`).
**Secondary analog:** the new `export_controller_test.exs` — controller invocation half (`build_conn() |> get("/audit/exports/changes.csv?...")` + `response/2`).

#### Mix-task invocation (lift from `export_test.exs:32-36`)

```elixir
# Source: test/mix/tasks/threadline/export_test.exs:32-40
out =
  capture_io(fn ->
    Mix.Tasks.Threadline.Export.run(["--dry-run", "--table", tname])
  end)

assert out =~ "matching_rows=1"
```

> **What to copy literally:** `capture_io` wrapper around `Mix.Tasks.Threadline.Export.run/1` (suppresses banner chatter — see `threadline.export.ex:113-115`). Required because the Mix task always prints `matching_rows=#{count}` to `Mix.shell().info/1`.

> **What MUST diverge:**
> - Use `Mix.Task.rerun("threadline.export", argv)` OR call `Mix.Task.reenable("threadline.export")` in `setup` before the next test case (RESEARCH §"Critical detail #8" line 74; RESEARCH §P-11 line 1128). Plain `Mix.Task.run/2` no-ops on second call within the same OS process.
> - Pass `--output PATH` instead of `--dry-run` so the Mix task writes a file the test can read.

#### Controller invocation (lift from `export_controller_test.exs` setup)

Reuse the `Endpoint` module from `Threadline.OperatorSurface.ExportControllerTest.Endpoint` (RESEARCH §P-11 line 1064 — `@endpoint Threadline.OperatorSurface.ExportControllerTest.Endpoint`). The two test files share the Endpoint via `start_supervised(@endpoint)` (idempotent — `setup_all` returns `{:error, {:already_started, _}}` quietly).

```elixir
# Source: RESEARCH §P-11 lines 1067-1071
setup_all do
  _ = start_supervised(@endpoint)
  :ok
end
```

#### Time-format gotcha (Mix uses ISO-Z; controller uses datetime-local)

```elixir
# Source: RESEARCH §P-11 lines 1103-1106
from = "2020-01-01T00:00:00Z"
to   = "2099-01-01T00:00:00Z"

# Convert Mix's ISO-Z to controller's datetime-local format (drop seconds + Z)
from_local = String.slice(from, 0..15)  # "2020-01-01T00:00"
to_local   = String.slice(to,   0..15)
```

> **What to copy literally:** the `String.slice(0..15)` translation. TimelineLive does the SAME slice at lines 67-69 of `timeline_live.ex`. Without this, the two paths see different `DateTime` values and parity fails.

#### Byte-equality assertion shape

```elixir
# Source: RESEARCH §P-11 lines 1101-1110
mix_bytes = File.read!(tmp_path)
controller_conn = get(conn, "/audit/exports/changes.csv?from=#{from_local}&to=#{to_local}")
controller_bytes = response(controller_conn, 200)

assert mix_bytes == controller_bytes,
       "Mix task and controller produced different bytes for the same filters."
```

> **Run this for all three formats** (csv, json wrapped, ndjson) — RESEARCH §P-11 lines 1113-1119 sketches the second + third tests. Each test is `async: false` (mirroring DataCase + `Mix.Task.reenable` requirement).

---

### `lib/threadline/operator_surface/router.ex` (EDIT, macro extension)

**Analog:** itself (lines 38-48) — the existing `live_session :threadline` block. Phase 65 grows a SIBLING `scope unquote(path) <> "/exports"` block adjacent to it (NOT inside the `live_session` — `live_session`'s `on_mount` does NOT apply to `get/3` routes).

#### Existing macro shape (lift macro hygiene as-is)

```elixir
# Source: lib/threadline/operator_surface/router.ex:13-50 (current shape)
defmacro threadline_operator_surface(path, opts \\ []) do
  has_auth_fn? = Keyword.has_key?(opts, :authorize_fn)
  has_ack? = Keyword.get(opts, :adopter_acknowledges_unauthenticated, false)
  caller_file = __CALLER__.file
  caller_line = __CALLER__.line

  quote do
    _scopes = @phoenix_top_scopes || %{pipes: []}
    _has_pipe? = ...
    if not (_has_pipe? or unquote(has_auth_fn?) or unquote(has_ack?)) do
      raise CompileError, ...
    end

    import Phoenix.LiveView.Router, only: [live_session: 3, live: 3]

    live_session :threadline, on_mount: [{Threadline.OperatorSurface.Auth, unquote(opts)}] do
      scope unquote(path), alias: Threadline.OperatorSurface.Live do
        live("/", TimelineLive, :index)
        live("/transactions/:id", TransactionLive, :show)
        live("/transactions/:id/history/:table/:record_id", TransactionLive, :history)
        live("/actors/:kind/:id", ActorLive, :show)
      end
    end
  end
end
```

#### Edit: append sibling controller scope (D-19, RESEARCH §P-2 lines 332-339)

Add INSIDE the same `quote do … end` block, AFTER the existing `live_session :threadline` call:

```elixir
# Source: RESEARCH §P-2 lines 332-339 (canonical sibling scope pattern)
exports_enabled? = Keyword.get(opts, :exports, true)
# ... at top of macro alongside other Keyword.get calls ...

# inside `quote do`, after the live_session block:
import Phoenix.Router, only: [scope: 2, scope: 3, scope: 4, get: 3, get: 4]

if unquote(exports_enabled?) and Code.ensure_loaded?(Phoenix.Controller) do
  scope unquote(path) <> "/exports", alias: false, as: false do
    plug(Threadline.OperatorSurface.ExportAuthPlug, unquote(opts))
    get("/changes.csv",    Threadline.OperatorSurface.Controllers.ExportController, :csv)
    get("/changes.json",   Threadline.OperatorSurface.Controllers.ExportController, :json)
    get("/changes.ndjson", Threadline.OperatorSurface.Controllers.ExportController, :ndjson)
  end
end
```

> **What to copy literally:**
> - `alias: false, as: false` — the LiveDashboard idiom (RESEARCH §"Alternatives Considered" line 128 — `phoenix_live_dashboard` v0.8.4 router). Don't pollute host's alias namespace.
> - Full module path `Threadline.OperatorSurface.Controllers.ExportController` (no alias shortcut) — avoids ambiguity with host's alias directives.
> - `plug(Threadline.OperatorSurface.ExportAuthPlug, unquote(opts))` INSIDE the scope (NOT a separately-named pipeline — pipelines defined from a third-party macro pollute the host's pipeline namespace). Phoenix.Router supports bare `plug …` inside `scope do … end`.

> **What MUST diverge from existing macro:**
> - The new `scope` is OUTSIDE `live_session :threadline` (because `on_mount` doesn't run for `get/3` routes — D-19).
> - Add `:exports` boolean opt with default `true`; `Keyword.get(opts, :exports, true)` at the top of the macro alongside `has_auth_fn?` / `has_ack?` (D-19 — rare LV-only adopter can opt out).
> - Extract `:export_authorize_fn` for opt-validation (D-20) — mirrors how `:authorize_fn` is checked at lines 14-15. If both `:authorize_fn` and `:export_authorize_fn` are absent AND no `pipe_through`, the existing CompileError fires (the secure-by-default guarantee already covers the new case because `:export_authorize_fn` is opt-in narrowing of `:authorize_fn`, not a separate auth surface).

> **Doc-contract test assertions** (`exports_doc_contract_test.exs`):
> - `assert String.contains?(router_src, ~s|"/changes.csv"|)` (and json, ndjson) — RESEARCH §P-9 lines 779-781.
> - `assert String.contains?(router_src, "ExportController, :csv")` (and :json, :ndjson) — RESEARCH §P-9 lines 782-784.
> - Optional: `assert String.contains?(router_src, "alias: false, as: false")` to pin the LiveDashboard hygiene idiom.

---

### `lib/threadline/operator_surface/live/timeline_live.ex` (EDIT, render + handle_params)

**Analog:** itself — the existing render block at lines 165-242 (button cluster at lines 208-211; section at lines 225-235) and `handle_params/3` at lines 57-126.

#### Edit 1: append three download anchors to existing `.button-cluster` (D-22)

```heex
<!-- Source: lib/threadline/operator_surface/live/timeline_live.ex:208-211 (existing two-link cluster) -->
<div class="button-cluster">
  <.link patch={@base_path} class="clear-link">Clear all</.link>
  <button type="submit">Apply</button>
</div>
```

Append three sibling `<.link href download>` elements per RESEARCH §P-1 lines 290-298:

```heex
<div class="button-cluster">
  <.link patch={@base_path} class="clear-link">Clear all</.link>
  <button type="submit">Apply</button>
  <.link href={"#{@base_path}/exports/changes.csv?#{@filter_query}"}    download class="download-button">Download CSV</.link>
  <.link href={"#{@base_path}/exports/changes.json?#{@filter_query}"}   download class="download-button">Download JSON</.link>
  <.link href={"#{@base_path}/exports/changes.ndjson?#{@filter_query}"} download class="download-button">Download NDJSON</.link>
</div>
```

> **What to copy literally:**
> - The `<.link …>` HEEx component is already imported (`<.link patch={@base_path}>` at line 209) — no new imports.
> - `@base_path` is already computed in `handle_params/3` at line 60 (`base_path = uri_parsed.path`) — reuse, don't re-derive.
> - Button labels `"Download CSV"`, `"Download JSON"`, `"Download NDJSON"` are doc-contract pinned (D-26, RESEARCH §P-9 lines 768-773).

> **What MUST diverge:**
> - The existing two cluster items use `<.link patch>` (LV navigation, no full reload) and `<button type="submit">` (form submit). The three new items use `<.link href>` (full HTTP GET, no LV navigation) PLUS the `download` HTML attribute. Both `download` AND server-side `Content-Disposition: attachment` are needed (RESEARCH §P-1 line 301): `download` makes `wantsNewTab()` return true at the JS layer (PR #2611); `Content-Disposition: attachment` triggers the browser file-download dialog.
> - **Compute `@filter_query` in `handle_params/3`** by calling the existing private `build_canonical_query/1` (timeline_live.ex:395-401) — it already produces the canonical sorted+filtered+URI-encoded query string. Add `assign(socket, :filter_query, build_canonical_query(socket.assigns.filters_raw))` in the success branch. **Do not re-derive** the canonical-query logic.

#### Edit 2: count status line + two-band truncation banner (D-17, D-18)

Insert between the existing `<header class="timeline-toolbar">` (lines 170-213) and `<section class="timeline-rows">` (lines 225-235):

```heex
<!-- Source: RESEARCH §"System Architecture Diagram" lines 236-248 (canonical placement) -->
<div class="match-count-status" role="status">
  Showing <%= length_visible(@streams.changes.inserts) %> of <%= format_count(@match_count) %> matches in this window.
</div>

<%= if @match_count > 5_000 do %>
  <div class="truncation-banner informational" role="status">
    Large export — will stream in chunks.
  </div>
<% end %>

<%= if @match_count >= 10_001 do %>
  <div class="truncation-banner warning" role="alert">
    Truncated to first 10,000 rows. Use `mix threadline.export --max-rows N` for the full window.
  </div>
<% end %>
```

> **What to copy literally:**
> - `role="status"` for the count line and informational banner; `role="alert"` for the warning banner — same shape as Phase 64's `<div class="filter-error" role="alert">` at timeline_live.ex:216 and `<div class="filter-hint">` at lines 220-222 (no role on filter-hint — it's a passive hint).
> - The thresholds: `> 5_000` (informational) and `>= 10_001` (warning). The `>= 10_001` threshold matches the `:cap` value the LV passes (`cap: 10_001` per RESEARCH §P-7 line 643) — when the cap is hit, the count is exactly 10_001, signaling "10,000+".
> - Format the count with thousands separator (e.g., `"3,142"`, `"10,000+"`) — implement `format_count/1` private helper. RESEARCH §P-8 lines 740-744 has the canonical shape:
>   ```elixir
>   count_text =
>     cond do
>       match_count >= 10_001 -> "10,000+"
>       true                   -> Integer.to_string(match_count) |> add_thousands_sep()
>     end
>   ```

> **What MUST diverge from existing empty-state shape:**
> - Phase 64's empty-state at lines 236-239 is conditional on `@cursor == nil and Enum.empty?(@streams.changes.inserts)` — keep it; it complements the count line (count line shows "0 matches" while empty-state hints what to do next).

#### Edit 3: `handle_params/3` — parallel `count_matching` + `timeline_page` (D-16, RESEARCH §P-7)

The current single call at line 112 (`page = Query.timeline_page(filters, scope_aware_opts(socket))`) becomes two parallel `Task.async/await` calls:

```elixir
# Source: RESEARCH §P-7 lines 638-669 (canonical parallel-task pattern)
:ok ->
  socket = assign(socket, :cursor, nil)

  count_task =
    Task.async(fn ->
      Threadline.Export.count_matching(filters, cap: 10_001, repo: socket.assigns.repo)
    end)

  page_task =
    Task.async(fn ->
      Threadline.Query.timeline_page(filters, scope_aware_opts(socket))
    end)

  {:ok, %{count: count}} = Task.await(count_task, 8_000)
  page = Task.await(page_task, 8_000)

  filter_query = build_canonical_query(socket.assigns.filters_raw)

  socket =
    socket
    |> assign(:filters, filters)
    |> assign(:form_error, nil)
    |> assign(:unknown_table_attempted, unknown_table_attempted)
    |> assign(:match_count, count)
    |> assign(:filter_query, filter_query)
    |> stream(:changes, page.entries, reset: true)
    |> assign(:cursor, page.next_cursor)

  {:noreply, socket}
```

> **What to copy literally:**
> - `Task.async/1` + `Task.await/2` (NOT `Task.async_stream/3` — overkill for two fixed calls; NOT `assign_async/3` — would render timeline first then "snap in" the count, breaking D-17's status-line-on-same-render contract; RESEARCH §P-7 lines 672-675).
> - Timeout `8_000` ms (vs default 5_000) — leaves headroom for slow capped-count queries (RESEARCH §P-7 lines 651-653).
> - Pass `cap: 10_001` to `count_matching` — enables the "10,000+ matches" approximation (RESEARCH §P-8 lines 568, line 731).
> - DO NOT wrap in `try/rescue` — silent failures are worse than a brief LV reconnect (RESEARCH §P-7 line 679).

> **What MUST diverge from existing line 112:**
> - Replace the single `page =` assignment with the two-task pattern.
> - Add `assign(:match_count, count)` and `assign(:filter_query, filter_query)` (both new).
> - Initial `mount/3` must seed `:match_count` to `0` and `:filter_query` to `""` so the first render before `handle_params/3` doesn't crash on `nil` (mirror the existing `assign(:cursor, nil)` at line 43).

#### Edit 4: also update `next-page` handler to thread `:cap` (consistency)

Current `handle_event("next-page", ...)` at lines 141-159 doesn't compute count (only pages). No edit needed UNLESS the count badge should refresh on infinite-scroll — recommend NO refresh (count is a property of the filter window, not the visible-rows window; D-17 already locks "Showing N of M matches in this window").

---

### `lib/threadline/operator_surface/style.ex` (EDIT, CSS extension)

**Analog:** itself — existing `.button-cluster` rule at lines 162-176 + existing `.filter-hint` / `.filter-error` rules at lines 184-195.

#### Existing `.button-cluster` rule (extend, don't replace)

```elixir
# Source: lib/threadline/operator_surface/style.ex:162-176 (existing cluster)
.threadline-ui .button-cluster {
  margin-left: auto;
  display: flex;
  gap: var(--tl-spacing-sm);
  align-items: center;
}

.threadline-ui .button-cluster button {
  padding: var(--tl-spacing-xs) var(--tl-spacing-md);
  background: var(--tl-color-accent);
  color: var(--tl-color-main);
  border: 0;
  border-radius: 4px;
  cursor: pointer;
}
```

> **Add `.download-button` rule** alongside `.button-cluster button` — same padding/border-radius for visual cluster cohesion, but a different background to distinguish "download" from "submit Apply":

```css
.threadline-ui .button-cluster .download-button {
  padding: var(--tl-spacing-xs) var(--tl-spacing-md);
  background: var(--tl-color-secondary);
  color: var(--tl-color-text);
  border: 1px solid var(--tl-color-secondary);
  border-radius: 4px;
  text-decoration: none;
  cursor: pointer;
}
```

> Use existing CSS variables (`--tl-spacing-*`, `--tl-color-*`, lines 13-26) — DO NOT introduce new variables unless absolutely necessary. Phase 64 PATTERNS Footgun F-8: no Tailwind, no utility classes, no top-level selectors outside `.threadline-ui …`.

#### Add `.match-count-status` rule (D-17)

```elixir
# Pattern source: existing .filter-hint at lines 192-195 (lightweight informational rule)
.threadline-ui .filter-hint {
  font-size: var(--tl-font-label);
  color: var(--tl-color-text-muted);
}
```

> **Add:**
> ```css
> .threadline-ui .match-count-status {
>   padding: var(--tl-spacing-sm) var(--tl-spacing-md);
>   font-size: var(--tl-font-label);
>   color: var(--tl-color-text-muted);
>   border-bottom: 1px solid var(--tl-color-secondary);
> }
> ```

#### Add `.truncation-banner` rules — two visual weights (D-18)

```elixir
# Pattern source: existing .filter-error at lines 184-190 (alert-color rule for warning band)
.threadline-ui .filter-error {
  padding: var(--tl-spacing-md);
  margin: var(--tl-spacing-md);
  background: var(--tl-color-secondary);
  color: var(--tl-color-destructive);
  border-radius: 4px;
}
```

> **Add two rules** with deliberately distinct visual weight (D-18 — "collapsing them deprives the operator of the one piece of information that changes their next action"):
> ```css
> .threadline-ui .truncation-banner {
>   padding: var(--tl-spacing-sm) var(--tl-spacing-md);
>   margin: var(--tl-spacing-sm) var(--tl-spacing-md);
>   border-radius: 4px;
>   font-size: var(--tl-font-label);
> }
>
> .threadline-ui .truncation-banner.informational {
>   background: var(--tl-color-secondary);
>   color: var(--tl-color-text-muted);
> }
>
> .threadline-ui .truncation-banner.warning {
>   /* Amber — distinct from .filter-error's destructive red.
>      Phase 65 may need to add --tl-color-warning if no amber variable exists. */
>   background: #FEF3C7;          /* amber-50 */
>   color: #92400E;               /* amber-800 */
>   border-left: 3px solid #F59E0B; /* amber-500 */
> }
> ```

> **What MUST diverge:** Phase 65 introduces amber as a new color. Either (a) hard-code the three hex values in the `.warning` rule (acceptable — discretionary per Claude's Discretion in CONTEXT.md), or (b) add `--tl-color-warning`, `--tl-color-warning-bg`, `--tl-color-warning-fg` variables to the `.threadline-ui` `:root`-equivalent at lines 12-26. Recommend (b) for variable-naming consistency, but either is acceptable.

---

### `test/threadline/operator_surface/live/timeline_live_test.exs` (EDIT, integration test extension)

**Analog:** itself — Cases 1-11 at lines 176-345 are the test-case template. Phase 65 appends new Cases.

#### New Case: three download anchor hrefs render with current filter state

```elixir
# Pattern source: existing Case 2 at lines 195-219 (form submit + assert_patch + URL assertion)
test "Case 12: Three download anchors render with canonical hrefs reflecting current filter state",
     %{conn: conn} do
  {:ok, _lv, html} = live(conn, "/audit?from=2026-05-01T00:00&to=2026-05-06T23:59&table=posts")

  # All three labels present
  assert html =~ "Download CSV"
  assert html =~ "Download JSON"
  assert html =~ "Download NDJSON"

  # All three hrefs include the canonical filter querystring
  assert html =~ ~s|href="/audit/exports/changes.csv?from=2026-05-01T00%3A00&amp;to=2026-05-06T23%3A59&amp;table=posts"|
  assert html =~ ~s|href="/audit/exports/changes.json?from=|
  assert html =~ ~s|href="/audit/exports/changes.ndjson?from=|

  # Download attribute present (PR #2611 — keeps LV socket alive on click)
  assert html =~ ~r|<a [^>]*download[^>]*>Download CSV</a>|
end
```

> **What to copy literally:**
> - The `live(conn, "/audit?from=…&to=…&table=…")` paste-URL pattern from existing Case 3 (lines 225-245).
> - HEEx-rendered URL escaping: `&` becomes `&amp;` in the HTML output. The existing Case 2 (line 215-216) uses `~r{...}` regex to match against the patched URL; the assertions above use literal HEEx-escaped strings.

#### New Case: count status line renders with formatted count

```elixir
test "Case 13: Match-count status line renders with formatted count", %{conn: conn} do
  seed_changes!(7, table: "posts")

  {:ok, _lv, html} = live(conn, "/audit?from=2020-01-01T00:00&to=2099-01-01T00:00&table=posts")

  assert html =~ ~r/Showing \d+ of 7 matches in this window/
end
```

#### New Case: chunked-informational banner at >5_000 (D-18 band 1)

```elixir
@tag :slow
test "Case 14: Banner renders informational variant when count > 5,000 and < 10,001", %{conn: conn} do
  seed_changes!(5_001, table: "posts")
  {:ok, _lv, html} = live(conn, "/audit?from=2020-01-01T00:00&to=2099-01-01T00:00&table=posts")

  assert html =~ "Large export — will stream in chunks."
  refute html =~ "Truncated to first 10,000 rows"
end
```

#### New Case: truncation-warning banner at >= 10_001 (D-18 band 2)

```elixir
@tag :slow
test "Case 15: Banner renders warning variant when count is capped at 10,001+", %{conn: conn} do
  seed_changes!(10_001, table: "posts")
  {:ok, _lv, html} = live(conn, "/audit?from=2020-01-01T00:00&to=2099-01-01T00:00&table=posts")

  assert html =~ "Truncated to first 10,000 rows"
  assert html =~ "10,000+"   # count line shows the cap-approximation literal
end
```

> **What to copy literally:**
> - `seed_changes!/2` helper from existing line 168-170 — already iterates `seed_change!/1` for bulk seeding.
> - `@tag :slow` for cases that seed >5_000 rows (RESEARCH §P-10 line 1040 — but test runs in default `mix test`; tag is for future opt-in CI splitting only, NEVER added to `mix test`'s exclude list per OSS DNA "honest default tests").

> **What MUST diverge:**
> - For the 10_001 case, the existing `seed_change!/1` at lines 139-164 inserts ONE row per call. 10_001 calls = ~3 sec test. RESEARCH §P-10 lines 1004-1033 has the bulk `Repo.insert_all/3` shape that's much faster — recommend extracting `bulk_seed_changes!/2` into the test module for both this Case and the chunked path test.

---

### `lib/threadline/export.ex` (EDIT — additive `:cap` opt on `count_matching/2`, RESEARCH §P-8)

**Analog:** itself — existing `count_matching/2` at lines 151-172. The `:correlation_id`-aware select branch is preserved.

#### Existing function (additive change only)

```elixir
# Source: lib/threadline/export.ex:151-172 (current count_matching/2)
@spec count_matching(keyword(), keyword()) :: {:ok, %{count: non_neg_integer()}}
def count_matching(filters, opts \\ []) when is_list(filters) and is_list(opts) do
  Query.validate_timeline_filters!(filters)
  repo = Query.timeline_repo!(filters, opts)

  count =
    case Keyword.get(filters, :correlation_id) do
      nil ->
        filters
        |> Query.timeline_query()
        |> select([ac, at], ac.id)
        |> repo.aggregate(:count, :id)

      _ ->
        filters
        |> Query.timeline_query()
        |> select([ac, at, _aa], ac.id)
        |> repo.aggregate(:count, :id)
    end

  {:ok, %{count: count}}
end
```

#### Additive `:cap` opt (RESEARCH §P-8 lines 700-724)

```elixir
@spec count_matching(keyword(), keyword()) :: {:ok, %{count: non_neg_integer()}}
def count_matching(filters, opts \\ []) when is_list(filters) and is_list(opts) do
  Query.validate_timeline_filters!(filters)
  repo = Query.timeline_repo!(filters, opts)
  cap = Keyword.get(opts, :cap)

  base_query =
    case Keyword.get(filters, :correlation_id) do
      nil -> filters |> Query.timeline_query() |> select([ac, _at], ac.id)
      _   -> filters |> Query.timeline_query() |> select([ac, _at, _aa], ac.id)
    end

  count =
    if is_integer(cap) and cap > 0 do
      capped = base_query |> limit(^cap)
      from(sub in subquery(capped), select: count())
      |> repo.one()
    else
      repo.aggregate(base_query, :count, :id)
    end

  {:ok, %{count: count}}
end
```

> **What to copy literally:**
> - Existing `Query.validate_timeline_filters!/1` and `Query.timeline_repo!/2` calls (lines 153-154) — preserve.
> - Existing `case Keyword.get(filters, :correlation_id)` two-arm split — preserve. The `_aa` is the `audit_actions` join only present when `:correlation_id` is set.
> - Existing `{:ok, %{count: count}}` return shape — preserve. **DO NOT** change to bare integer (Pitfall 5 — Mix task and any other caller would break).

> **What's additive (new):**
> - `cap = Keyword.get(opts, :cap)` — defaults to `nil` (unbounded = current behavior).
> - When `cap` is a positive integer: wrap `base_query |> limit(^cap)` in a `subquery` and `count()` over the subquery (the SQL pattern `SELECT count(*) FROM (SELECT 1 FROM ... LIMIT N) limited`). RESEARCH §P-8 lines 686-696 has the SQL.
> - The `from(sub in subquery(capped), select: count())` shape requires `Ecto.Query.from/2` — already imported at `export.ex:48` (`import Ecto.Query`).

> **Test strategy:** Add a unit test in `test/threadline/export_test.exs` that asserts the cap clamps correctly:
> ```elixir
> # Seed 100 rows; cap at 50; assert count == 50, not 100.
> test "count_matching/2 with :cap clamps at the cap value" do
>   # ... insert 100 changes via existing helpers ...
>   assert {:ok, %{count: 50}} = Export.count_matching([repo: @repo, table: tname], cap: 50)
> end
>
> # Without :cap, count is the true count (Mix-task contract preserved).
> test "count_matching/2 without :cap returns the true count (default behavior unchanged)" do
>   assert {:ok, %{count: 100}} = Export.count_matching([repo: @repo, table: tname])
> end
> ```

> **Why on `Threadline.Export.count_matching/2` (not a new helper):** A new helper duplicates the `validate_timeline_filters!` + `timeline_repo!` boilerplate. A keyword option is purely additive (default `nil` = current unbounded behavior); the Mix task and any existing capture-only adopter are unaffected (RESEARCH §P-8 lines 727).

---

## Shared Patterns

### File-scope `Code.ensure_loaded?` gating (D-21)
**Source:** every existing module under `lib/threadline/operator_surface/` (router.ex:1, auth.ex:1, style.ex:1, live/*.ex:1).
**Apply to:** `lib/threadline/operator_surface/controllers/export_controller.ex` (gate `Phoenix.Controller`), `lib/threadline/operator_surface/export_auth_plug.ex` (gate `Phoenix.Controller`).
**DO NOT apply to:** `lib/threadline/operator_surface/exports/filename.ex` — it's pure stdlib (D-21 + RESEARCH §P-9 line 850).

```elixir
if Code.ensure_loaded?(Phoenix.Controller) do
  defmodule Threadline.OperatorSurface.Controllers.ExportController do
    use Phoenix.Controller, formats: [:html]
    # …
  end
end
```

> Doc-contract test pins each gate's first line literal (RESEARCH §P-9 lines 837-852). `mix verify.compile_no_optional` enforces in CI.

### Telemetry event reuse — `[:threadline, :operator_surface, :authorize]`
**Source:** `lib/threadline/operator_surface/auth.ex:51-62` (LV-side `emit_telemetry/3`).
**Apply to:** `lib/threadline/operator_surface/export_auth_plug.ex` — emit the SAME event with the SAME measurements + metadata shape.

```elixir
:telemetry.execute(
  [:threadline, :operator_surface, :authorize],
  %{result: result},
  %{path: "", actor_ref: actor_ref, scope_keys: scope_keys}
)
```

> Adopters watching this event get one stream of auth decisions across both surfaces (RESEARCH §P-3 line 438). DO NOT introduce a new event name.

### Repo + scope resolution
**Source:** `lib/threadline/operator_surface/live/timeline_live.ex:18-23` (mount-time pattern, identical to actor_live.ex / transaction_live.ex).
**Apply to:** `ExportController.dispatch/3` (read from `conn.assigns[:threadline_repo]` — the auth plug populated it from `opts`).

```elixir
repo = conn.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()
scope = conn.assigns[:threadline_scope]   # bracket form — may be absent
```

> **Bracket form mandatory** (Phase 64 PATTERNS F-9): `:threadline_scope` may be absent when `:authorize_fn` returns `:ok`/`true` (auth.ex:21-27 do not assign it). `conn.assigns.threadline_scope` (dot form) raises `KeyError` on the absent case.

### Filter validation — `Threadline.Query.validate_timeline_filters!/1` as single source of truth
**Source:** `lib/threadline/operator_surface/live/timeline_live.ex:366-373` (`safe_validate/1` `try/rescue` wrapper).
**Apply to:** `ExportController.dispatch/3` — same `try/rescue ArgumentError` shape, map error to 422.

```elixir
defp safe_validate(filters) do
  try do
    Threadline.Query.validate_timeline_filters!(filters)
    :ok
  rescue
    e in ArgumentError -> {:error, e.message}
  end
end
```

> Phase 64 PATTERNS Shared Pattern: never invent a parallel UI-only filter dialect. The controller's filter parsing must produce a keyword list that `validate_timeline_filters!/1` accepts — Pitfall 3 (extract shared `FilterParams` module) is the structural guarantee.

### CSS isolation — `.threadline-ui` namespace + CSS variables
**Source:** `lib/threadline/operator_surface/style.ex:12-26` (`:root`-equivalent variables) + lines 33-212 (every rule prefixed `.threadline-ui …`).
**Apply to:** every new rule added in Phase 65 (`.export-cluster`, `.match-count-status`, `.truncation-banner.informational`, `.truncation-banner.warning`, `.download-button`).

> Phase 64 PATTERNS Footgun F-8: NO Tailwind, NO utility classes, NO new top-level selectors outside `.threadline-ui …`.

### `Threadline.OperatorSurface.Style.css` opening tag in render blocks
**Source:** `lib/threadline/operator_surface/live/timeline_live.ex:166-168` (existing render opening).
**Apply to:** TimelineLive render block edits MUST keep this opening intact.

```heex
~H"""
<div class="threadline-ui">
  <Threadline.OperatorSurface.Style.css />
  …
"""
```

> Already present at line 167-168; the Phase 65 edits insert inside this `<div>`.

---

## Footguns (anti-patterns Phase 65 must NOT introduce)

### F-1 (Phase 65 new): `Enum.into/2` or `Enum.reduce/3` over `Plug.Conn.chunk/2`
**Source:** Not observed (no chunked-stream code exists yet). Flag preemptively.
> `Plug.Conn.chunk/2` returns `{:ok, conn} | {:error, term()}` — silently swallowed by `Enum.into/2`. Always use `Enum.reduce_while/3` with explicit `{:cont, conn}` / `{:halt, conn}`. RESEARCH §"Anti-Patterns" line 1137; Pitfall 1.

### F-2 (Phase 65 new): `put_resp_header/3` AFTER `send_chunked/2`
**Source:** Not observed. Flag preemptively.
> Plug requires headers in place BEFORE the chunked-state transition. Setting `put_resp_header/3` after `send_chunked/2` raises `Plug.Conn.AlreadySentError`. RESEARCH Pitfall 2; §P-4 line 570.

### F-3 (Phase 65 new): Forgetting `Stream.take(10_000)` on chunked path
**Source:** Not observed. Flag preemptively.
> `Threadline.Export.stream_changes/2` is unbounded by design (module doc line 41-43: "does not apply max_rows"). Without the `Stream.take(10_000)` wrap, the chunked path streams every row past the 10k truncation contract — operator gets a 500MB CSV instead of the 10k-row truncated one. RESEARCH Pitfall 4.

### F-4 (Phase 65 new): `Mix.Task.run/2` (not `rerun/2`) in multi-test parity test
**Source:** `test/mix/tasks/threadline/export_test.exs:35` uses `run/1` — but that file has only ONE test case so no second-call no-op problem. The new parity test has THREE test cases.
> A Mix task runs at most ONCE per OS process by default. Use `Mix.Task.rerun/2` OR `Mix.Task.reenable("threadline.export")` in `setup`. RESEARCH §"Critical detail #8" + §P-11 line 1128.

### F-5 (Phase 65 new): `count_matching/2` return-shape misuse
**Source:** Not observed (Mix task at `threadline.export.ex:67` correctly destructures). Flag preemptively for the new controller.
> `count_matching/2` returns `{:ok, %{count: N}}`, NOT a bare integer. `count = Export.count_matching(filters, [])` then `if count > 5_000` compares a tuple to an integer (always falsy or truthy). Mirror the Mix task: `{:ok, %{count: count}} = ...`. Pitfall 5.

### F-6 (Phase 65 new): Duplicate filter-param parsing between LV and controller
**Source:** TimelineLive (lib/threadline/operator_surface/live/timeline_live.ex:264-393) has 130 lines of parser logic that the controller needs IDENTICALLY for parity test to pass.
> Extract to `Threadline.OperatorSurface.Exports.FilterParams`. Both surfaces call it. Hand-copying invites silent divergence — parity test would pass for ASCII filters but fail for edge cases. RESEARCH Pitfall 3.

### F-7 (Phase 65 new): Defining `pipeline :threadline_export_auth` from inside macro
**Source:** Not observed. Flag preemptively because `pipe_through :threadline_export_auth` reads naturally and a contributor might write it.
> Phoenix.Router pipelines defined from a third-party macro pollute the host's pipeline namespace and risk naming collisions. Use bare `plug Threadline.OperatorSurface.ExportAuthPlug, opts` INSIDE the `scope` block (LiveDashboard idiom). RESEARCH §"Alternatives Considered" line 128.

### F-8 (Phase 65 new): `phx-click` + `redirect(socket, external: …)` for download
**Source:** Not observed. Flag preemptively because it's the documented LV "footgun" pattern.
> Tears down LV socket mid-export; loses scroll/cursor/filter state. CONTEXT D-15 + Phoenix LiveView PR #2611 lock the `<.link href download>` pattern explicitly. RESEARCH §"Anti-Patterns" line 1136.

### F-9 (Phase 65 new): `Ecto.Adapters.SQL.Sandbox` in chunked-stream integration test
**Source:** Not observed (project consistently uses `DataCase` with `async: false` + explicit cleanup). Flag preemptively.
> Postgres triggers fire OUTSIDE sandbox awareness — sandbox would mask trigger-row creation. Use `async: false` + FK-order `Repo.delete_all` in setup, mirroring `Threadline.DataCase`. RESEARCH §P-10 line 1038; data_case.ex:6-10.

### F-10 (Phase 65 new): Tagging the >5k seed test as `:slow` AND adding `:slow` to `mix test` exclude list
**Source:** Not observed. Flag preemptively because the test takes ~100ms-3s and a contributor might "speed up" CI by hiding it.
> Per OSS DNA "honest default tests" (CLAUDE.md "CI & Verification Conventions"): `@tag :slow` is fine for future opt-in CI splitting, but it MUST run in default `mix test`. NEVER add `:slow` to `mix test`'s exclude list without updating `test/test_helper.exs` AND docs together. RESEARCH §P-10 line 1040.

### F-11 (Phase 65 new): AST-walk via `Code.string_to_quoted/1` for doc-contract tests
**Source:** Not observed (every existing `*_doc_contract_test.exs` uses regex). Flag preemptively because a contributor unfamiliar with the project might reach for AST.
> Inconsistent with project convention (BROWSE-04 + every other doc-contract test uses `String.contains?` and `Regex.scan` over `File.read!/1`). AST is heavier and brittle to formatting changes (`live("/", …)` vs `live "/", …`). RESEARCH §"Alternatives Considered" line 130.

### F-12 (Phase 65 carry-forward from Phase 64): `phx-change=` re-introduction during edits to TimelineLive
**Source:** Phase 64 doc-contract test refute at `timeline_browse_doc_contract_test.exs:117-127`.
> Phase 65 edits TimelineLive's render block — easy to accidentally add `phx-change="…"` to one of the form inputs while extending it. Per CONTEXT D-04 + Phase 64 D-04 + RESEARCH §"Anti-Patterns" line 1145: form is `phx-submit` only. Recommend re-asserting the refute in `exports_doc_contract_test.exs` to make Phase 65's commitment explicit.

### F-13 (Phase 65 new): `socket.assigns.threadline_scope` (dot form) when scope may be absent
**Source:** Phase 64 PATTERNS F-9 already names this for LV. Same Footgun in plug context: `conn.assigns.threadline_scope` (dot form) raises if scope absent.
> Use `conn.assigns[:threadline_scope]` (bracket form) — returns `nil` when `:authorize_fn` returns `:ok`/`true` (auth.ex:21-27 do not assign scope). Same shape as TimelineLive at `timeline_live.ex:23`.

---

## Differences from analogs (planner must call out in plan tasks)

| Aspect | Phase 64 analog (TimelineLive / LV-side) | Phase 65 (controller / HTTP-side) — DIFFERENCE |
|--------|-----------------------------------------|------------------------------------------------|
| File-scope gate | `Code.ensure_loaded?(Phoenix.LiveView)` | **`Code.ensure_loaded?(Phoenix.Controller)`** for controller + plug; **NO gate** for filename helper. |
| Auth contract | `:authorize_fn.(socket)` invoked from `Auth.on_mount/4` | **TWO callbacks accepted:** `:export_authorize_fn.(conn)` (preferred) OR `:authorize_fn.(%{assigns: conn.assigns})` (synthetic mirror). v1.17 contract preserved verbatim. |
| Auth halt | `redirect(socket, to: "/")` (interactive page redirect) | **`send_resp(conn, 403, "forbidden") |> halt()`** (no redirect target makes sense for a download anchor). |
| Repo resolution | `socket.assigns[:threadline_repo] |> Application.get_env(...) |> hd()` (bracket form) | Same shape: `conn.assigns[:threadline_repo] |> Application.get_env(...) |> hd()`. |
| Scope assign | `Phoenix.Component.assign(socket, :threadline_scope, scope)` | `Plug.Conn.assign(conn, :threadline_scope, scope)`. Same key. |
| Filter validation | `safe_validate/1` `try/rescue ArgumentError` (timeline_live.ex:366-373) | **Lift verbatim** to controller; map `{:error, msg}` to `send_resp(conn, 422, "invalid filter: #{msg}")` plain text. |
| Filter param parsing | `filters_raw_from_params/1` + `normalize_params/1` + `parse_datetimes/1` + `parse_datetime_local/1` + `collapse_actor_ref/1` + `safe_actor_kind/1` + `build_filters/1` (130 LOC inline in TimelineLive) | **Extract** to `Threadline.OperatorSurface.Exports.FilterParams` shared module. BOTH surfaces delegate. (Pitfall 3.) |
| Pagination | `Threadline.Query.timeline_page/2` with `cursor:` opt | **Streaming** `Threadline.Export.stream_changes/2` (chunked path) OR `to_csv_iodata/2` / `to_json_document/2` (iodata path). Different lib API entry points. |
| Anchor for navigation | `<.link patch={…}>` (LV-internal navigation, no full reload) | **`<.link href={…} download>`** (full HTTP GET, browser handles file download). Both `download` HTML attr AND `Content-Disposition: attachment` server header REQUIRED (PR #2611 + browser behavior). |
| Pre-flight count | NONE in Phase 64 (just `timeline_page/2`) | **Two parallel `Task.async`** — `count_matching/2` AND `timeline_page/2` — awaited together so total latency is `max(count, page)`. Pass `cap: 10_001` for "10,000+" approximation. |
| Tests | `Phoenix.LiveViewTest` — `live(conn, path)`, `render_submit`, `assert_patch` | **`Phoenix.ConnTest`** — `build_conn() |> get(path)`, `response(conn, 200)`, `response_content_type(conn, :csv)`. Same nested Endpoint shell. |
| Test cleanup | `seed_change!/1` per row (timeline_live_test.exs:139-164) | **`Repo.insert_all/3`** for >5k seeding (RESEARCH §P-10 lines 1004-1033). 100x faster on the chunked-path test. |
| Lib-side change | None | **Additive `:cap` opt** on `Threadline.Export.count_matching/2`. Default `nil` = current unbounded behavior. Mix task + capture-only adopters unaffected. |

---

## No Analog Found

No file in scope is "no analog" — every NEW file has at least a role-match precedent in the codebase, and every EDIT extends an existing template. The closest-to-orphan patterns are:

1. **`Phoenix.Controller` use** — there is no existing controller in `lib/`. The Mix task at `lib/mix/tasks/threadline.export.ex` provides the closest "thin wrapper around `Threadline.Export`" shape (the controller's three actions mirror the Mix task's `--format` switch). Use RESEARCH §P-4 (lines 449-563) as the canonical controller template.

2. **`Plug.Conn.send_chunked/2` + `Enum.reduce_while/3` chunked stream** — no existing chunked-response code in the project. RESEARCH §P-4 lines 504-519 provides the canonical pattern; Pitfall 1 + §"Anti-Patterns" line 1137 lock the `Enum.reduce_while/3` shape against drift.

3. **Mix-task / controller byte-equality parity test** — no existing parity test. Compose: Mix-task half from `test/mix/tasks/threadline/export_test.exs:32-40` (`capture_io` + `Mix.Task.run`, swap `run` for `rerun`); controller half from new `export_controller_test.exs` (`build_conn() |> get(...) |> response(200)`).

The planner should treat (1) and (2) as "canonical RESEARCH-pattern reuse" rather than "no analog" — the patterns exist as fully-worked code in RESEARCH.md, just not as already-shipped Threadline code. Pattern (3) is a true new test type, but the two halves it composes are both present in the codebase.

---

## Metadata

**Analog search scope:**
- `/Users/jon/projects/threadline/lib/threadline/operator_surface/` (entire subtree — auth.ex, router.ex, style.ex, live/{actor_live,transaction_live,timeline_live,row_history_component}.ex)
- `/Users/jon/projects/threadline/lib/threadline/` (export.ex, plug.ex, query.ex, health.ex, semantics/actor_ref.ex)
- `/Users/jon/projects/threadline/lib/mix/tasks/threadline.export.ex` (parity target)
- `/Users/jon/projects/threadline/test/threadline/operator_surface/` (live/{actor,timeline}_live_test.exs, auth_test.exs, router_test.exs, timeline_browse_doc_contract_test.exs, transaction_live_test.exs)
- `/Users/jon/projects/threadline/test/threadline/operator_surface_doc_contract_test.exs` (root-level doc-contract analog)
- `/Users/jon/projects/threadline/test/threadline/{export,plug}_test.exs`
- `/Users/jon/projects/threadline/test/mix/tasks/threadline/export_test.exs` (parity-test source)
- `/Users/jon/projects/threadline/test/support/data_case.ex` (test cleanup convention)
- `/Users/jon/projects/threadline/.planning/phases/64-raw-timeline-browse-and-filter-form/64-PATTERNS.md` (template)
- `/Users/jon/projects/threadline/.planning/phases/65-exports-ui-parity/65-{CONTEXT,RESEARCH}.md`

**Files scanned:** ~17 source/test files; full RESEARCH §P-1..P-11.
**Pattern extraction date:** 2026-05-06
**Phoenix LiveView version assumed:** `~> 1.0` (per `mix.exs:54`, RESEARCH §"Standard Stack" line 103). PR #2611 fix is well below the version envelope; no bump needed.

## PATTERN MAPPING COMPLETE
