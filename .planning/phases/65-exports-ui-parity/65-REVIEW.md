---
phase: 65-exports-ui-parity
reviewed: 2026-05-07T00:00:00Z
depth: standard
files_reviewed: 16
files_reviewed_list:
  - lib/threadline/export.ex
  - lib/threadline/operator_surface/controllers/export_controller.ex
  - lib/threadline/operator_surface/export_auth_plug.ex
  - lib/threadline/operator_surface/exports/filename.ex
  - lib/threadline/operator_surface/exports/filter_params.ex
  - lib/threadline/operator_surface/live/timeline_live.ex
  - lib/threadline/operator_surface/router.ex
  - lib/threadline/operator_surface/style.ex
  - test/threadline/export_test.exs
  - test/threadline/operator_surface/controllers/export_controller_test.exs
  - test/threadline/operator_surface/export_auth_plug_test.exs
  - test/threadline/operator_surface/exports/filename_test.exs
  - test/threadline/operator_surface/exports/filter_params_test.exs
  - test/threadline/operator_surface/exports_doc_contract_test.exs
  - test/threadline/operator_surface/exports_mix_parity_test.exs
  - test/threadline/operator_surface/live/timeline_live_test.exs
findings:
  critical: 0
  warning: 7
  info: 6
  total: 13
status: issues_found
---

# Phase 65: Code Review Report

**Reviewed:** 2026-05-07T00:00:00Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

Reviewed the Phase 65 "exports UI parity" implementation: export library
(`Threadline.Export`), HTTP controller (`ExportController`), Conn-shaped auth
plug (`ExportAuthPlug`), shared filter parser (`FilterParams`), filename
helper, LV timeline, router macro, and CSS module — plus their corresponding
tests.

The implementation is generally well-structured: the FilterParams module
unifies LV + HTTP filter parsing (Pitfall 3 closed), the auth plug emits the
same telemetry event as `Auth.on_mount`, the chunked-stream path correctly
handles client disconnects via `Enum.reduce_while`, atom-leak vectors are
closed via `String.to_existing_atom`, and parity tests pin Mix-task-vs-controller
byte equality.

That said, the review found:

- **Two correctness/usability defects in datetime parsing** that reject
  valid ISO-8601 inputs the docs imply are accepted (WARNING).
- **One client/server validation mismatch** for `correlation_id`
  (`maxlength="256"` chars vs server "256 UTF-8 bytes") (WARNING).
- **Defense-in-depth header gap** (`X-Content-Type-Options: nosniff`) for
  audit-data downloads that may contain attacker-controlled JSONB payloads
  (WARNING).
- **Empty `path` field in plug telemetry metadata** that defeats per-route
  observability across the three export endpoints (WARNING).
- **Test isolation defect** in `timeline_live_test.exs` (async: true with no
  per-test DB cleanup, shared "posts" table name) (WARNING).
- **Several quality/maintainability defects**: dead defensive code paths,
  inconsistent constants, JSON `data_after` type drift vs CSV.

No security blockers (the SQL/atom/path-traversal vectors I checked are all
closed); no data-loss or correctness blockers in the export pipeline itself.

## Warnings

### WR-01: `parse_datetime_local/1` rejects pre-formatted ISO-8601-Z input

**File:** `lib/threadline/operator_surface/exports/filter_params.ex:116-123`
**Issue:**
```elixir
defp parse_datetime_local(str) when is_binary(str) do
  padded = if String.length(str) == 16, do: str <> ":00Z", else: str <> "Z"
  ...
end
```
The padding rule is "if 16 chars, append `:00Z`; otherwise append `Z`". A
user who pastes a fully-formed ISO-8601 timestamp into the URL (e.g.,
`?from=2026-05-06T12:00:00Z`, 20 chars) gets the `Z` re-appended, producing
`2026-05-06T12:00:00ZZ`, which `DateTime.from_iso8601/1` rejects. The
controller then returns 422 "invalid datetime: 2026-05-06T12:00:00Z".

This contradicts the parity-test's documented contract that the Mix task
accepts "full ISO-Z" form (`--from "2020-01-01T00:00:00Z"`); the test
side-steps the bug by `String.slice(0..15)`-ing the input before submitting
to the controller, but a real user pasting from logs/curl/copy-paste hits
the bug.

The same break applies to inputs with timezone offsets
(`2026-05-06T12:00:00-05:00` becomes `...-05:00Z`).

**Fix:**
```elixir
defp parse_datetime_local(str) when is_binary(str) do
  # Accept already-formatted ISO-8601 strings; pad only datetime-local forms.
  padded =
    cond do
      String.length(str) == 16 -> str <> ":00Z"
      String.length(str) == 19 -> str <> "Z"
      true -> str
    end

  case DateTime.from_iso8601(padded) do
    {:ok, dt, _offset} -> {:ok, dt}
    _ -> {:error, :invalid_datetime}
  end
end
```

### WR-02: `correlation_id` `maxlength="256"` is chars, but server validates 256 UTF-8 bytes

**File:** `lib/threadline/operator_surface/live/timeline_live.ex:227-232`
**Issue:**
```html
<input type="text" name="filter[correlation_id]" id="filter-correlation-id"
       ...
       maxlength="256" phx-debounce="300" />
<small>request_id, job_id, or integration token. Up to 256 chars.</small>
```
HTML `maxlength` counts UTF-16 code units (effectively chars in the BMP);
`Threadline.Query` validates 256 *UTF-8 bytes after trimming*
(`lib/threadline/query.ex:194`). A user can type 256 multi-byte characters
(say, Japanese — 3 bytes/char in UTF-8) for ~768 bytes, pass `maxlength`,
and hit a 422 server-side. The `<small>` copy says "256 chars" reinforcing
the wrong contract.

**Fix:**
- Drop `maxlength` (let server be the source of truth) **or** change the
  copy + label to "Up to 256 ASCII chars / shorter for non-ASCII"; OR
- Add a JS-level UTF-8 byte counter — but that's heavier than worth.
  Cleanest is to drop `maxlength` and rely on the form-error rendering
  the server's "256 UTF-8 bytes" message.

```html
<input type="text" name="filter[correlation_id]" id="filter-correlation-id"
       aria-label="correlation id"
       value={@filters_raw["correlation_id"] || ""}
       phx-debounce="300" />
<small>request_id, job_id, or integration token. Up to 256 UTF-8 bytes.</small>
```

### WR-03: Missing `X-Content-Type-Options: nosniff` on export downloads

**File:** `lib/threadline/operator_surface/controllers/export_controller.ex:214-222`
**Issue:** Audit-data exports embed user-controlled JSONB payloads
(`data_after`, `changed_from`, `table_pk`) inside CSV cells and JSON values.
A motivated adversary who can write to an audited table can craft a
`data_after` payload that some browser MIME-sniffer interprets as HTML/JS
(historically a real attack on CSV/JSON downloads). The controller sets
`Cache-Control: no-store` but does not set `X-Content-Type-Options: nosniff`.

The downloads use `Content-Disposition: attachment`, which prevents
inline-rendering in modern browsers — that's the primary mitigation — but
defense-in-depth is cheap and the lib is positioned as "audit platform"
with an attacker-controlled-payload threat model.

**Fix:**
```elixir
defp put_export_headers(conn, content_type, ext) do
  filename = Filename.for(ext, DateTime.utc_now())
  disposition = ~s|attachment; filename="#{filename}"; filename*=UTF-8''#{filename}|

  conn
  |> put_resp_header("content-type", content_type)
  |> put_resp_header("content-disposition", disposition)
  |> put_resp_header("cache-control", "no-store")
  |> put_resp_header("x-content-type-options", "nosniff")
end
```

### WR-04: `ExportAuthPlug` telemetry emits empty `path: ""` — defeats per-route auth observability

**File:** `lib/threadline/operator_surface/export_auth_plug.ex:90-101`
**Issue:**
```elixir
defp emit_telemetry(result, _conn, scope) do
  ...
  :telemetry.execute(
    [:threadline, :operator_surface, :authorize],
    %{result: result},
    %{path: "", actor_ref: actor_ref, scope_keys: scope_keys}
  )
end
```
The `_conn` parameter is captured but unused; `path: ""` is hardcoded. The
`@moduledoc` claims "adopters watching the auth telemetry stream get one
feed of decisions across both the LV and HTTP surfaces" — but with `path`
hardcoded, an adopter cannot tell whether a denial fired on
`/exports/changes.csv` vs `/exports/changes.json` vs `/exports/changes.ndjson`.

**Fix:**
```elixir
defp emit_telemetry(result, conn, scope) do
  scope_keys = if is_map(scope), do: Map.keys(scope) |> Enum.sort(), else: []

  actor_ref =
    if is_map(scope), do: Map.get(scope, :actor_ref) || Map.get(scope, :user_id), else: nil

  :telemetry.execute(
    [:threadline, :operator_surface, :authorize],
    %{result: result},
    %{path: conn.request_path, actor_ref: actor_ref, scope_keys: scope_keys}
  )
end
```

### WR-05: `timeline_live_test.exs` is `async: true` with no DB cleanup — shared "posts" table races between tests

**File:** `test/threadline/operator_surface/live/timeline_live_test.exs:104-124`
**Issue:**
```elixir
defmodule Threadline.OperatorSurface.Live.TimelineLiveTest do
  use ExUnit.Case, async: true
  ...

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
```
There is **no per-test DB cleanup** — `Threadline.DataCase` is not used
and `Repo.delete_all` is not called. The sibling `ExportControllerTest`
explicitly cleans up because Threadline does not use the SQL Sandbox
(`test/support/data_case.ex`). With `async: true`, multiple tests in this
file run concurrently *and* against the shared real DB.

Cases that seed into the literal `"posts"` table can interfere with each
other:
- Case 3 (`seed_change!(table: "posts", ...)`)
- Case 9 (`seed_changes!(51, table: "posts")`)
- Case 13 (no seed but filters on `table=posts`)
- Cases 12 and 14 also reference `table=posts`

Other "test 16/17/18" cases use unique-suffix tables (good practice), but
the legacy cases do not. Result: flaky tests when the suite runs under load.

**Fix:**
- Either flip to `async: false` and add `Repo.delete_all` in `setup` (mirror
  `ExportControllerTest`), or
- Renumber every shared-table seed to use a unique table per test
  (`"posts_#{System.unique_integer([:positive])}"`).

The latter is cheaper and keeps the test file fast:
```elixir
setup do
  table = "posts_#{System.unique_integer([:positive])}"
  {:ok, conn: Phoenix.ConnTest.build_conn(), table: table}
end
```
Then change every `table: "posts"` to `table: table` and every URL builder
to interpolate `table`.

### WR-06: `next-page` handler hardcodes `page_size: 50` instead of using `@page_size`

**File:** `lib/threadline/operator_surface/live/timeline_live.ex:166-184`
**Issue:**
```elixir
def handle_event("next-page", _, socket) do
  if socket.assigns.cursor do
    page =
      Query.timeline_page(
        socket.assigns.filters,
        repo: scope_aware_opts(socket)[:repo] || default_repo(),
        scope: socket.assigns[:threadline_scope],
        page_size: 50,                                      # <-- magic number
        ...
      )
```
A `@page_size 50` module attribute already exists (line 10) and is used by
`scope_aware_opts/1`. Hardcoding `50` here will silently drift if anyone
changes `@page_size`. Same maintainability defect calls out from any code
review of "two source-of-truth-for-the-same-constant" patterns.

**Fix:**
```elixir
page_size: @page_size,
```

### WR-07: JSON `data_after` is non-defensive (`row.data_after` vs CSV's `row.data_after || %{}`)

**File:** `lib/threadline/export.ex:393-411`
**Issue:**
```elixir
defp change_map(row) do
  base = %{
    ...
    "table_pk" => row.table_pk || %{},
    "data_after" => row.data_after,                # <-- no `|| %{}` fallback
    "changed_fields" => row.changed_fields || [],
    "changed_from" => row.changed_from || %{},
    ...
  }
```
Compare to `csv_row/2` (line 378): `Jason.encode!(row.data_after || %{})`.
The JSON path emits literal `null` for nullable `data_after` (e.g., DELETE
ops where `data_after` is intentionally null), while the CSV path emits
`{}`. This is a documented type drift between the two surfaces — adopters
parsing both formats need to handle two different "null" representations.

If `null` is intentional for DELETE ops (so consumers can distinguish "no
data" from "empty data"), the inconsistency should be the other way: CSV
should emit `null` too. If `{}` is intentional for both, JSON should match.

**Fix (option A — null is meaningful, fix CSV side):**
```elixir
# csv_row/2
Jason.encode!(row.data_after),  # was: row.data_after || %{}
```

**Fix (option B — `{}` is the contract, fix JSON side):**
```elixir
"data_after" => row.data_after || %{},
```
Either way, document the choice in the `@moduledoc`. The current code
silently diverges.

## Info

### IN-01: `_scopes |> List.wrap()` in router macro is dead defensive code

**File:** `lib/threadline/operator_surface/router.ex:49-57`
**Issue:**
```elixir
_scopes = @phoenix_top_scopes || %{pipes: []}

_has_pipe? =
  _scopes
  |> List.wrap()
  |> Enum.any?(fn
    %{pipes: [_ | _]} -> true
    _ -> false
  end)
```
`@phoenix_top_scopes` is normally a list of scope maps (Phoenix.Router
internal), not a single map. The fallback `%{pipes: []}` is then `List.wrap`ed
into `[%{pipes: []}]` — which is correct, but if Phoenix ever changed the
internal type the fallback wouldn't match. Not a current bug; just defensive
code without a documented invariant.

**Fix:** Either document the Phoenix internal contract being relied on or
drop the unused defensive branch. Acceptable as-is.

### IN-02: `next-page` handler `repo: scope_aware_opts(socket)[:repo] || default_repo()` is dead code

**File:** `lib/threadline/operator_surface/live/timeline_live.ex:171`
**Issue:** `scope_aware_opts/1` always sets `:repo` from `socket.assigns.repo`
(which itself defaults from `Application.get_env(...) |> hd()` at mount time).
The `|| default_repo()` fallback in `next-page` can never trigger unless
`socket.assigns.repo` is set to `nil` somewhere — which mount/3 never does.

**Fix:**
```elixir
repo: socket.assigns.repo,
```

### IN-03: `format_count/1` thousands-separator implementation is convoluted

**File:** `lib/threadline/operator_surface/live/timeline_live.ex:311-326`
**Issue:**
```elixir
count
|> Integer.to_string()
|> String.reverse()
|> String.codepoints()
|> Enum.chunk_every(3)
|> Enum.map(&Enum.join/1)
|> Enum.join(",")
|> String.reverse()
```
Functional but hard to read; also incorrect for negative integers (irrelevant
here since count is non-negative). Cldr / `Number.Delimit` are heavier
dependencies than the stdlib justifies, but a simpler regex approach is
clearer:

**Fix:**
```elixir
defp format_count(count) when is_integer(count) and count >= 0 do
  cond do
    count >= 10_001 -> "10,000+"
    true ->
      count
      |> Integer.to_string()
      |> String.reverse()
      |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
      |> String.reverse()
  end
end
```

### IN-04: `Application.get_env(:threadline, :ecto_repos) |> hd()` raises opaque error if no repos configured

**File:** `lib/threadline/operator_surface/live/timeline_live.ex:20`, `:305`
**File:** `lib/threadline/operator_surface/controllers/export_controller.ex:238`
**Issue:** `nil |> hd()` raises `FunctionClauseError`; `[] |> hd()` raises
`ArgumentError`. Either is opaque to an adopter who's misconfigured the host
app.

**Fix:** Raise explicitly with a hint:
```elixir
defp default_repo do
  case Application.get_env(:threadline, :ecto_repos) do
    [repo | _] -> repo
    _ ->
      raise ArgumentError,
            "Threadline operator surface requires a repo. Either configure " <>
              ":ecto_repos for :threadline or pass :repo to the export plug."
  end
end
```

### IN-05: `emit_prefix(conn, :json)` discards `chunk` failure silently

**File:** `lib/threadline/operator_surface/controllers/export_controller.ex:141-152`
**Issue:**
```elixir
defp emit_prefix(conn, :json) do
  ...
  case Plug.Conn.chunk(conn, prefix) do
    {:ok, conn} -> conn
    {:error, _} -> conn
  end
end
```
If the prefix chunk fails (client closed before first byte), the controller
still proceeds into the reduce_while and the suffix emit. The reduce_while
itself handles `:closed` gracefully, so this is a correctness no-op — but it
generates extra DB queries (`stream_export_rows` will issue one keyset page
before the chunk-write fails) for a client that's already gone. Minor.

**Fix:** Halt early on prefix-chunk failure:
```elixir
defp emit_prefix(conn, :json) do
  ...
  case Plug.Conn.chunk(conn, prefix) do
    {:ok, conn} -> {:ok, conn}
    {:error, reason} -> {:error, conn, reason}
  end
end
```
And bail out of `send_chunked_stream` if `emit_prefix` returned `{:error, ...}`.
Optional optimization.

### IN-06: ExportController `default_repo/0` duplicates logic in TimelineLive `default_repo/0` and `auth.ex`

**File:** `lib/threadline/operator_surface/controllers/export_controller.ex:237-239`
**File:** `lib/threadline/operator_surface/live/timeline_live.ex:304-306`
**File:** `lib/threadline/operator_surface/auth.ex` (and `transaction_live.ex`, `actor_live.ex`)
**Issue:** Five `socket.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()`
or equivalent patterns scattered across the operator surface. A single
`Threadline.OperatorSurface.RepoResolver.resolve(socket_or_conn)` helper
would centralize the fallback logic and the IN-04 "opaque crash" fix.

**Fix:** Extract a shared helper:
```elixir
defmodule Threadline.OperatorSurface.RepoResolver do
  def resolve(%{assigns: assigns}) do
    assigns[:threadline_repo] || default!()
  end

  defp default! do
    case Application.get_env(:threadline, :ecto_repos) do
      [repo | _] -> repo
      _ -> raise ArgumentError, "..."
    end
  end
end
```

---

_Reviewed: 2026-05-07T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
