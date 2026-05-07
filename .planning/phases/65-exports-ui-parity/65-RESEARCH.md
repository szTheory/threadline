# Phase 65: Exports UI Parity - Research

**Researched:** 2026-05-06
**Domain:** Phoenix controller + `Plug.Conn.send_chunked/2` mounted inside an existing LV-emitting macro, fed by `Threadline.Export.{to_csv_iodata, to_json_document, count_matching, stream_changes}/2`, with parity to `mix threadline.export`
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-15 — Plain `<.link href={…}>` anchor** for each download button. Browser handles GET; `Content-Disposition: attachment` keeps operator on the LV. Phoenix LiveView PR #2611 fixed `wantsNewTab()` so anchors with `download=` / `Content-Disposition: attachment` no longer tear down the LV socket.
- **D-22 — Three affordances total**: `[Download CSV]`, `[Download JSON]` (wrapped, default), `[Download NDJSON]`. Cluster grows from `[Clear all] [Apply]` (Phase 64) → `[Clear all] [Apply] [Download CSV] [Download JSON] [Download NDJSON]`. Filename extensions: `.csv`, `.json`, `.ndjson`.
- **D-16 — Always-on, computed concurrently with `timeline_page` on every Apply.** In `handle_params`, run `count_matching/2` and `timeline_page/2` in parallel so total latency is `max(count, page)`, not `sum`. Cache count in socket assigns.
- **D-17 — Count appears above the timeline as a status line** — *"Showing 50 of 3,142 matches in this window."*
- **D-18 — Two-band truncation banner.** Count > 5,000 → informational *"Large export — will stream in chunks."* Count > 10,000 → warning amber *"Truncated to first 10,000 rows. Use `mix threadline.export --max-rows N` for the full window."*
- **D-23 — Degraded-count fallback** for huge unfiltered windows: `EXISTS`-with-`LIMIT 10001` capped pattern; degrade to `"10,000+ matches"` rather than erroring the LV. Planner picks exact mechanism.
- **D-19 — Same `threadline_operator_surface` macro emits both LV routes and a controller scope.** Sibling `scope "/exports"` block inside the existing `path` block. Add `:exports` boolean opt (default `true`).
- **D-20 — New `:export_authorize_fn` opt; default = thin Conn-shaped adapter wrapping the existing `:authorize_fn`.** **Preserve the v1.17 `:authorize_fn.(socket)` contract verbatim.** Generated plug `Threadline.OperatorSurface.ExportAuthPlug` calls export-specific opt or falls back to a synthetic `%{assigns: conn.assigns}` mirror around `:authorize_fn`. Maps `false`/`{:error, _}`/`:error` → 403; `:ok`/`{:ok, scope}` → assign `:threadline_scope`.
- **D-21 — File-scope gating: `Code.ensure_loaded?(Phoenix.Controller)`** on the new controller file (`lib/threadline/operator_surface/controllers/export_controller.ex`) and on the new auth plug file (`lib/threadline/operator_surface/export_auth_plug.ex`). NOT gated on LiveView. `mix verify.compile_no_optional` stays trivially green.
- **D-24 — Threshold compare lives in the controller action**, not in `Threadline.Export`. Sequence: validate filters (raise→422) → count_matching/2 → if ≤5k full iodata via send_resp; if >5k send_chunked + stream_changes |> Stream.chunk_every(500) |> Enum.reduce_while/3 calling chunk(conn, iodata). Truncation at 10k via `Stream.take(10_000)` for parity with iodata path.
- **D-25 — Filename helper is a new module**, not inlined. `Threadline.OperatorSurface.Exports.Filename.for(format, datetime)` returning `"threadline-changes-2026-05-06T12-00Z.csv"`. Datetime granularity is **minute**.
- **D-26 — Doc-contract test asserts the locked literals as pure source-reading**, mirroring the BROWSE-04 doc-contract test pattern from Phase 64.
- **D-27 — Focused integration test for the chunked-stream path** — seed >5,000 rows, hit `GET /audit/exports/changes.csv?from=…&to=…` via `Phoenix.ConnTest`, assert response is 200 with `Content-Type: text/csv; charset=utf-8` and `transfer-encoding: chunked`.
- **D-28 — Parity test (Mix task vs controller produce identical bytes for identical filters).** Run both paths in same test for all three formats; `assert File.read!(tmp_path) == response_body`.
- **D-29 — `mix verify.compile_no_optional` stays green.** Capture-only adopter compiles cleanly. LV-only adopter gets the controller for free.

### Claude's Discretion

- Exact CSS class names + visual styling for count status line, truncation banners, and download cluster — extend `.threadline-ui` namespace + CSS-variable convention from `Threadline.OperatorSurface.Style`. No Tailwind, no JS framework.
- Exact button labels — must match doc-contract test literals (planner picks the literals, test pins them). Recommended: `"Download CSV"`, `"Download JSON"`, `"Download NDJSON"`.
- Exact wording of the chunked + truncation banners (terse, neutral tone, parity with existing TransactionLive empty-state copy).
- Exact location of the filename helper (`Threadline.OperatorSurface.Exports.Filename` is recommended, planner may rename if namespace conflicts).
- Pre-flight match-count integration test seeding strategy (must seed >5k rows for chunked-path assertion).
- Exact strategy for the degraded-count fallback (D-23) — `EXISTS LIMIT 10001` cap, separate library helper, or `Repo`-level timeout retry.
- Whether `include_action_metadata` / `max_rows` / CSV column-toggle UIs are exposed as URL knobs — recommendation: NO at this phase.
- Phoenix-LiveView version constraint check — D-15 relies on PR #2611. **CONFIRMED: PR #2611 merged 2023-05-12, included in LiveView v0.19+ and definitely in v1.0; mix.exs declares `phoenix_live_view ~> 1.0` so the lib is well above the fix line. No version bump required.**

### Deferred Ideas (OUT OF SCOPE)

- NDJSON-only progressive download (no count pre-flight) — out of v1.18 scope.
- CSV column toggles / `include_action_metadata` UI checkbox — Mix task doesn't expose it.
- `?max_rows=N` URL knob with sanity ceiling — out of Phase 65 scope.
- Saved exports / "schedule this export to email" — deferred to v1.20+; Oban dep barrier.
- Resume / partial-download recovery — out of scope; chunked stream is one-shot.
- Per-row "export this row" affordance — out of scope; Phase 65 is window-shaped.
- Async download with status page — out of scope; Oban dep barrier.
- Email-when-ready / signed-link-expiry exports — deferred indefinitely.
- Auto-name "save as" for Mix task sharing `Threadline.OperatorSurface.Exports.Filename` — possible but out of Phase 65 scope.
- Phase 66 forward-compat for surface-header count — Phase 66's coverage badge is independent of Phase 65's above-timeline count.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| **EXPO-03** | Download CSV/JSON affordances on TimelineLive; LV redirects (HTTP 303) to a Phoenix controller endpoint under operator surface that re-validates via `validate_timeline_filters!/1` and authorizes via the same `:authorize_fn` contract. | §"Implementation Approach" + §"Idiomatic Patterns" P-1 (anchor), P-2 (controller mount), P-3 (auth plug Conn-shaped adapter). The HTTP "redirect" framing in EXPO-03 is satisfied by a plain `<.link href>` GET to the controller — no `phx-click` + `redirect/2` is needed (D-15 supersedes the literal "303 redirect" wording from REQUIREMENTS.md; CONTEXT.md is the controlling artifact). |
| **EXPO-04** | Controller streams large windows via `Plug.Conn.send_chunked/2` + `Threadline.Export.stream_changes/2`; sends iodata synchronously below 5k rows; pre-flight `count_matching/2`; UTC-ISO filenames + RFC 5987 `Content-Disposition`; RFC 4180 CSV `text/csv; charset=utf-8` no BOM; JSON wrapped + NDJSON variants matching Mix-task flags. | §"Idiomatic Patterns" P-4 (chunked dispatch), P-5 (RFC 5987 header), P-6 (filename helper), P-7 (count pre-flight in parallel with timeline_page), P-8 (degraded count). §"API Reference Confirmations" confirms `to_csv_iodata/2` returns `{:ok, %{data: iodata, ...}}`, `count_matching/2` returns `{:ok, %{count: N}}`, `stream_changes/2` does NOT enforce `max_rows`. |
| **EXPO-05** | Doc-contract test pins button labels + filename format + content-type literals + Mix-task flag parity; focused integration test asserts chunked-stream completes for >5k row window; parity assertion proves Mix task and controller produce byte-identical files for identical filters. | §"Idiomatic Patterns" P-9 (regex-over-source doc-contract pattern, mirrors BROWSE-04), P-10 (LV+chunked integration test infrastructure — reuses Phase 64's nested test-Endpoint shape), P-11 (parity test using `Mix.Task.rerun/2`). §"Validation Architecture" maps every observable behavior to its test layer. |
</phase_requirements>

## Summary

Phase 65 ships three new files (one Plug, one Phoenix.Controller, one pure filename helper) and one new test file pattern (chunked-integration + Mix-parity). The macro at `lib/threadline/operator_surface/router.ex` grows a sibling `scope "/exports"` block that emits three `get/3` routes with `plug Threadline.OperatorSurface.ExportAuthPlug` (no separate `pipeline` indirection — the host router can't easily define a Threadline-internal pipeline, so the plug goes inline inside the scope; this is the LiveDashboard idiom). `Threadline.OperatorSurface.Live.TimelineLive` grows three `<.link href>` anchors in `.button-cluster`, a status-line above the timeline rows, and a parallel `Task.async/await`-style call in `handle_params/3` so `count_matching/2` runs concurrently with `timeline_page/2`. Eight load-bearing details deserve explicit naming in the plan because none of them are obvious from CONTEXT.md alone:

1. **`Plug.Conn.chunk/2` returns `{:ok, conn} | {:error, term()}` (NOT `:ok`).** The canonical streaming pattern is `Enum.reduce_while/3` with `{:cont, conn}` / `{:halt, conn}` — using `Enum.into/2` or `Enum.reduce/3` silently swallows client-disconnect errors and continues to attempt writes on a closed socket. Plans MUST encode the `reduce_while` shape exactly.
2. **`count_matching/2` returns `{:ok, %{count: N}}`, NOT a bare integer.** The Mix task already destructures (`{:ok, %{count: count}}`); the controller MUST do the same. (`lib/threadline/export.ex:151`, `lib/mix/tasks/threadline.export.ex:67`.)
3. **`stream_changes/2` does NOT enforce `:max_rows`.** Module doc: *"`stream_changes/2` … does **not** apply `max_rows` — cap with `Stream.take/2`."* Controller MUST wrap in `Stream.take(10_000)` for symmetry with the iodata path's default `:max_rows` of 10_000. Without this wrap, a chunked CSV could deliver millions of rows past the 10k truncation contract.
4. **PR #2611 specifically respects the HTML `download` attribute on anchor tags**, not (strictly) `Content-Disposition: attachment` alone. The safest pattern is `<.link href={…} download>Download CSV</.link>` — the `download` attribute makes wantsNewTab() return true at the JS layer, while `Content-Disposition: attachment` is the server-side enforcement. Both belt + braces. CONTEXT.md D-15 mentions `download=` / `Content-Disposition: attachment`; plans should include both.
5. **The "EXISTS LIMIT 10001" pattern from CONTEXT.md D-23 needs a SQL correction.** A bare `EXISTS (... LIMIT 10001)` returns a boolean, not a count. The correct pattern is `SELECT count(*) FROM (SELECT 1 FROM ... LIMIT 10001) limited` — a windowed count that returns the actual count when below the cap and the cap value when at it. Recommend exposing as `Threadline.Export.count_matching/2` accepting a new `:cap` option (default unbounded for current callers — including the Mix task — so behavior is unchanged for capture-only adopters), with the controller passing `cap: 10_001` and the LV checking `count >= 10_001` to render the "10,000+" approximation.
6. **Threadline tests do NOT use `Ecto.Adapters.SQL.Sandbox`.** `test/support/data_case.ex` documents the reason: PostgreSQL triggers fire at the DB level, outside sandbox awareness. Tests use `async: false` and explicit `Repo.delete_all` cleanup in `setup`. Plans for the >5k chunked-integration test MUST follow this convention — bulk insert via `Repo.insert_all/3` in the test's `setup` block, NOT in a sandbox transaction. The test must be `async: false`.
7. **Phase 64's TimelineLive test already builds a nested Endpoint + Router for `Phoenix.LiveViewTest`** (`test/threadline/operator_surface/live/timeline_live_test.exs:1-60`). The Phase 65 controller integration test should follow the same shape — define a nested `…ExportControllerTest.Endpoint`, mount the macro inside it, and use `Phoenix.ConnTest.build_conn/0 |> get("/audit/exports/changes.csv?…")`. NO `use ConnCase` exists in this codebase; do not invent one.
8. **`Mix.Task.run/2` runs each task only ONCE per OS process.** The parity test calls `Mix.Tasks.Threadline.Export.run/1` from inside an ExUnit test; on the second test case in the same module, it would silently no-op. Use `Mix.Task.rerun/2` (or call `Mix.Task.reenable("threadline.export")` before each `run/1`) to make the parity test deterministic across multiple test cases.

**Primary recommendation:** Implement the controller as a near-clone of the Mix task's flag-to-opt mapping (`lib/mix/tasks/threadline.export.ex:73-93`) — three actions, identical opts derived from identical filters, identical `Threadline.Export.{to_csv_iodata, to_json_document}/2` calls. Implement the auth plug as a thin Conn-shaped wrapper that mirrors `Threadline.OperatorSurface.Auth.on_mount/4`'s telemetry events, scope-assign, and halt strategy verbatim. Implement the LV count pre-flight via `Task.async/await` (NOT `Task.async_stream` — only two parallel calls, no enumerable to map over). Implement the chunked stream via `Stream.take(10_000) |> Stream.chunk_every(500) |> Enum.reduce_while(conn, fn chunk, conn -> case Plug.Conn.chunk(conn, chunk) do … end end)`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Three download anchors render (HEEx) | **Frontend Server (LiveView render)** | — | `<.link href>` is server-rendered; href computed from current filter assigns. |
| LiveView count pre-flight + parallel `timeline_page` | **Frontend Server (LiveView server)** | Capture/Semantics layer (consumes) | Two `Task.async` over `Threadline.Export.count_matching/2` and `Threadline.Query.timeline_page/2`; await with timeout. Both calls run in the LV process (not a GenServer); no supervision tree change required. |
| Status-line + truncation banner render | **Frontend Server (LiveView render)** | — | Reads the cached count assign; no IO. |
| Filter validation re-run on controller request | **Capture/Semantics layer (lib)** | API/Backend (calls it) | `Threadline.Query.validate_timeline_filters!/1` is the single literal; controller calls it verbatim. |
| Filter param parsing (URL → keyword) | **API/Backend (controller)** | — | Same `actor_kind`+`actor_id` collapse + datetime-local pad as TimelineLive — extract to a shared helper module per "Pitfalls" §3 below. |
| Auth (HTTP-side) | **API/Backend (Plug)** | Operator surface | New `Threadline.OperatorSurface.ExportAuthPlug` — Conn-shaped twin of `Threadline.OperatorSurface.Auth.on_mount/4`. |
| Iodata ≤5k dispatch | **API/Backend (controller)** | Capture/Semantics layer (lib provides iodata) | `Threadline.Export.to_csv_iodata/2` returns iodata; controller wraps with `Plug.Conn.send_resp/3` + headers. |
| Chunked >5k dispatch | **API/Backend (controller)** | Capture/Semantics layer (lib provides Enumerable) | `Plug.Conn.send_chunked/2` + `Stream.take(10_000) |> Stream.chunk_every(500) |> Enum.reduce_while/3`; lib stream is the data source, controller is the transport. |
| Filename formatting (UTC-ISO, minute granularity) | **Operator surface (pure helper)** | — | New `Threadline.OperatorSurface.Exports.Filename.for/2`; no Phoenix deps, easy to doc-contract test. |
| RFC 5987 `Content-Disposition` header | **API/Backend (controller)** | — | Hand-crafted in the controller (`put_resp_header/3`); no Phoenix helper exists. |
| Capped "EXISTS LIMIT 10001" count | **Capture/Semantics layer (lib)** | Operator surface (calls with `:cap` opt) | New optional `:cap` keyword on `Threadline.Export.count_matching/2`; SQL is a `from(sub in subquery(... |> limit(^cap)), select: count())`. Pure lib concern; LV/controller just read the count. |
| Mix-task / controller byte-equality | **Test infrastructure** | Capture/Semantics layer (the shared call site) | Both surfaces ultimately call `Threadline.Export.{to_csv_iodata, to_json_document}/2` with identical opts; the parity test asserts no per-surface divergence. |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Plug` | `~> 1.15` (project mix.exs:55) | `Plug.Conn.send_resp/3`, `send_chunked/2`, `chunk/2`, `put_resp_header/3` | Already a HARD dep (NOT optional); the controller's transport primitives. [VERIFIED: lib/mix.exs:55] |
| `Phoenix` | `~> 1.7` optional (mix.exs:57) | `Phoenix.Controller` macros (`use Phoenix.Controller`, `action_fallback`); `Phoenix.Router.get/3` | Optional dep; controller file is wrapped in `Code.ensure_loaded?(Phoenix.Controller)` per D-21. [VERIFIED: lib/mix.exs:57] |
| `Phoenix.LiveView` | `~> 1.0` optional (mix.exs:58) | `<.link href>` anchor in TimelineLive HEEx; PR #2611 merged 2023-05-12, shipped in v0.19+ and definitely v1.0. | Already declared. mix.exs `~> 1.0` is well above the PR #2611 fix line. **No version bump required.** [VERIFIED: lib/mix.exs:58; CITED: github.com/phoenixframework/phoenix_live_view/pull/2611] |
| `Threadline.Export` | n/a | `to_csv_iodata/2`, `to_json_document/2`, `count_matching/2`, `stream_changes/2` | All four are existing public API; controller is a thin wrapper. [VERIFIED: lib/threadline/export.ex:71, 108, 151, 184] |
| `Threadline.Query` | n/a | `validate_timeline_filters!/1`, `timeline_page/2` | Single source of truth for filter validation; LV calls in parallel with count. [VERIFIED: lib/threadline/query.ex:138, 290] |
| `Threadline.Semantics.ActorRef` | n/a | `new/2` for actor_kind+actor_id collapse | Already used by TimelineLive's `collapse_actor_ref/1` (lib/threadline/operator_surface/live/timeline_live.ex:317-356). Controller reuses the same shape. [VERIFIED: lib/threadline/semantics/actor_ref.ex:35-52] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `NimbleCSV.RFC4180` | `~> 1.2` (mix.exs:54) | Already used inside `Threadline.Export.to_csv_iodata/2` | Don't call directly — `to_csv_iodata/2` wraps it. [VERIFIED: lib/threadline/export.ex:50, 89] |
| `Jason` | `~> 1.4` (mix.exs:53) | Already used inside `Threadline.Export.to_json_document/2` | Don't call directly. [VERIFIED: lib/threadline/export.ex:124, 134] |
| `Task` (stdlib) | n/a | `Task.async/1` + `Task.await/2` for parallel `count_matching` + `timeline_page` in `handle_params/3` | Two parallel calls only — `Task.async_stream/3` is overkill (it's for enumerable mapping with bounded concurrency). The LV process supervises the tasks naturally; no supervision-tree change. [CITED: hexdocs.pm/elixir/Task.html] |
| `Ecto.Query` (stdlib for Threadline) | `~> 3.10` (mix.exs:51) | New `count_matching/2` `:cap` option uses `from(sub in subquery(... |> limit(^cap)))` shape | Already an idiom — `Threadline.Query` already uses `subquery/1`-shaped patterns. [CITED: hexdocs.pm/ecto/aggregates-and-subqueries.html] |
| `Phoenix.ConnTest` (test only) | bundled with Phoenix | `build_conn/0`, `get/2`, `response/2`, `response_content_type/2` | Reuse Phase 64's nested-Endpoint pattern in `test/threadline/operator_surface/live/timeline_live_test.exs:1-60`. [VERIFIED: test/threadline/operator_surface/live/actor_live_test.exs:1-80] |
| `Mix.Task.rerun/2` | bundled | Re-runs a Mix task in-process (re-enables + runs) | The parity test calls the Mix task in each test case; `Mix.Task.run/2` no-ops on second call. [CITED: hexdocs.pm/mix/Mix.Task.html] |
| `ExUnit.CaptureIO.capture_io/1` | bundled | Suppresses `Mix.shell().info/1` chatter from the Mix task | Already used in `test/mix/tasks/threadline/export_test.exs:3, 32`. [VERIFIED] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Task.async/await` for two parallel queries | `Task.async_stream/3` | `async_stream` is for enumerable mapping with bounded concurrency; with exactly 2 queries the boilerplate is heavier and there's no concurrency cap to enforce. **Use `Task.async/await`.** |
| `Task.async/await` for two parallel queries | `assign_async/3` (LV 1.0 helper) | `assign_async` shows a loading state then re-renders — but D-16 wants the count visible on the same render as the timeline rows (one debounced Apply = one network round-trip = one full render). `assign_async` would render the timeline first then "snap in" the count, breaking D-17's status-line shape. **Stick with `Task.async/await`** — both results land before the first render. |
| New `count_matching_capped/3` helper | `:cap` option on existing `count_matching/2` | A new helper duplicates the validation + repo-resolution boilerplate. A new keyword option is additive (default = unbounded = current behavior, so the Mix task is unaffected). **Use the `:cap` option.** |
| `:cap` option on `count_matching/2` | `Repo`-level `try`/`rescue` for `Postgrex.Error` (statement timeout) | Catching `Postgrex.Error` is fragile — the message format isn't a stable API, and it only fires after `statement_timeout` actually elapses (multi-second wait). The `:cap` option short-circuits at the SQL planner level (PostgreSQL stops the index scan after N rows); typical query time goes from 100s of ms to < 5ms regardless of total row count. **Use the `:cap` option.** |
| Separate `pipeline :threadline_export_auth` defined inside the macro | `plug Threadline.OperatorSurface.ExportAuthPlug` directly inside `scope "/exports"` block | Phoenix.Router pipelines are typically defined at host level. Defining a pipeline from inside a third-party macro pollutes the host's pipeline namespace and risks naming collisions. LiveDashboard's `live_dashboard/2` macro does NOT define internal pipelines — it relies on the host's `pipe_through` and emits routes inside a `scope path, alias: false, as: false do … end`. **Use a bare `plug` inside the scope.** Phoenix.Router supports `plug …` inside `scope do … end`. [CITED: github.com/phoenixframework/phoenix_live_dashboard/blob/v0.8.4/lib/phoenix/live_dashboard/router.ex] |
| Phoenix-helper `send_download/3` | Hand-crafted `put_resp_header/3` + `send_resp/3` | `Phoenix.Controller.send_download/3` exists for static files (it sets `Content-Disposition: attachment; filename=...` from disk). For dynamic iodata or chunked streams, neither use case fits cleanly. The chunked path needs `send_chunked/2` (not `send_resp/3`), and `send_download/3` doesn't help with the iodata path either since you need to specify Content-Type explicitly. **Hand-craft the headers.** |
| AST-walk via `Code.string_to_quoted/1` | Regex over file source for doc-contract tests | The existing project pattern (BROWSE-04, all `*_doc_contract_test.exs` files) is `String.contains?` and `Regex.scan` over `File.read!/1` results. AST walking is heavier and brittle to formatting changes. **Use regex.** [VERIFIED: test/threadline/operator_surface/timeline_browse_doc_contract_test.exs] |

**Installation:** No new deps. Phase 65 lands inside the existing `phoenix ~> 1.7` + `phoenix_live_view ~> 1.0` optional-dep envelope. `mix verify.compile_no_optional` MUST stay green.

**Version verification:**
- Phoenix LiveView PR #2611 merged 2023-05-12 — `phoenix_live_view ~> 1.0` (released 2024-12-03) is well above the fix line. **VERIFIED via PR page on github.com.** [CITED: github.com/phoenixframework/phoenix_live_view/pull/2611]
- `Plug` `~> 1.15` covers `send_chunked/2` (introduced in `Plug v0.7`, stable since `Plug v1.0`). **VERIFIED via Plug.Conn hexdoc.** [CITED: hexdocs.pm/plug/Plug.Conn.html#send_chunked/2]

## Architecture Patterns

### System Architecture Diagram

```
   Operator browser ──► (a) GET /audit?…filters…                                   (LiveView mount + render)
                        (b) Click <.link href="/audit/exports/changes.csv?…filters…" download>
                            ──► (separate HTTP GET, LV socket NOT torn down — PR #2611)
                                                        │
                                                        ▼
                                       ┌────────────────────────────────────────┐
                                       │ Phoenix Router                         │
                                       │  scope unquote(path) do                │
                                       │   live_session :threadline ... do      │
                                       │     live "/", TimelineLive, :index     │
                                       │     ...                                │
                                       │   end                                  │
                                       │   scope "/exports" do          ◄──NEW │
                                       │     plug Threadline.OperatorSurface.   │
                                       │          ExportAuthPlug                │
                                       │     get "/changes.csv",  EC, :csv     │
                                       │     get "/changes.json", EC, :json    │
                                       │     get "/changes.ndjson", EC, :ndjson│
                                       │   end                                  │
                                       │  end                                   │
                                       └────────────────┬───────────────────────┘
                                                        ▼
                                       ┌────────────────────────────────────────┐
                                       │ Threadline.OperatorSurface.            │
                                       │   ExportAuthPlug.call(conn, opts)      │ ◄── Conn-shaped twin of Auth.on_mount/4
                                       │  • call :export_authorize_fn  OR       │
                                       │    fallback Conn-shaped adapter that   │
                                       │    builds %{assigns: conn.assigns}     │
                                       │    and calls :authorize_fn.(mirror)    │
                                       │  • emit telemetry granted/denied/error │
                                       │  • assign(:threadline_scope, scope)    │
                                       │  • on denial: send_resp(403) |> halt  │
                                       └────────────────┬───────────────────────┘
                                                        ▼
                                       ┌────────────────────────────────────────┐
                                       │ Threadline.OperatorSurface.            │
                                       │   Controllers.ExportController         │
                                       │                                        │
                                       │  csv/2  → opts = []                    │
                                       │  json/2 → opts = [json_format: :wrapped│
                                       │  ndjson/2→opts = [json_format: :ndjson│
                                       │                                        │
                                       │  1. parse params (same shape as        │
                                       │     TimelineLive — extract shared      │
                                       │     helper module)                     │
                                       │  2. validate_timeline_filters!  →      │
                                       │     rescue ArgumentError → 422 text/   │
                                       │  3. count_matching/2 with cap: 10_001  │
                                       │  4. dispatch:                          │
                                       │     count <= 5_000 ──► to_csv_iodata/  │
                                       │                       send_resp(200,…)│
                                       │     count >  5_000 ──► send_chunked +  │
                                       │                       stream_changes  │
                                       │                       |> Stream.take( │
                                       │                          10_000)      │
                                       │                       |> Stream.chunk_│
                                       │                          every(500)   │
                                       │                       |> reduce_while │
                                       └────────────────┬───────────────────────┘
                                                        ▼
                                       ┌────────────────────────────────────────┐
                                       │ Threadline.Export.{                    │
                                       │   to_csv_iodata/2,                     │
                                       │   to_json_document/2,                  │
                                       │   count_matching/2,                    │
                                       │   stream_changes/2}                    │
                                       │ — same calls Mix task makes —          │
                                       └────────────────┬───────────────────────┘
                                                        ▼
                                       PostgreSQL (audit_changes ⋈ audit_transactions ⋈ audit_actions?)


LIVEVIEW SIDE (separate socket connection, persists across download click):

   TimelineLive.handle_params/3 ──► spawn 2 tasks in parallel:
                                       Task.async(fn -> Export.count_matching(filters, cap: 10_001) end)
                                       Task.async(fn -> Query.timeline_page(filters, page_size: 50) end)
                                    ──► Task.await both with timeout: 8_000

                                    ──► assign(:match_count, count)
                                    ──► assign(:cursor, page.next_cursor)
                                    ──► stream(:changes, page.entries, reset: true)

   render/1 ──► <header class="timeline-toolbar">
                  <form id="timeline-filters">…</form>
                  <div class="button-cluster">
                    <.link patch={@base_path} class="clear-link">Clear all</.link>
                    <button type="submit">Apply</button>
                    <.link href={"#{@base_path}/exports/changes.csv?#{@filter_query}"}    download>Download CSV</.link>
                    <.link href={"#{@base_path}/exports/changes.json?#{@filter_query}"}   download>Download JSON</.link>
                    <.link href={"#{@base_path}/exports/changes.ndjson?#{@filter_query}"} download>Download NDJSON</.link>
                  </div>
                </header>
                <div class="match-count-status" role="status">  ◄── D-17 status line
                  Showing <%= length(visible) %> of <%= format_count(@match_count) %> matches in this window.
                </div>
                <%= if @match_count > 5_000 do %>
                  <div class="truncation-banner informational" role="status">  ◄── D-18 band 1
                    Large export — will stream in chunks.
                  </div>
                <% end %>
                <%= if @match_count >= 10_001 do %>
                  <div class="truncation-banner warning" role="alert">          ◄── D-18 band 2
                    Truncated to first 10,000 rows. Use `mix threadline.export --max-rows N` for the full window.
                  </div>
                <% end %>
                <section class="timeline-rows" …>…</section>
```

### Recommended Project Structure

```
lib/threadline/operator_surface/
├── router.ex                                      # MODIFY: grow macro to emit `scope "/exports" do plug … get … end` + :export_authorize_fn opt validation + :exports boolean opt
├── auth.ex                                        # NO CHANGE
├── export_auth_plug.ex                            # NEW: Code.ensure_loaded?(Phoenix.Controller) gated; @behaviour Plug; mirrors auth.ex telemetry/scope/halt
├── style.ex                                       # MODIFY: add .export-cluster, .match-count-status, .truncation-banner.informational, .truncation-banner.warning rules
├── controllers/
│   └── export_controller.ex                       # NEW: gated; csv/2, json/2, ndjson/2 actions
├── exports/
│   ├── filename.ex                                # NEW: pure helper, no Phoenix deps; for(format, datetime)
│   └── filter_params.ex                           # NEW (recommended): shared filter-param-parse helper extracted from TimelineLive — used by both TimelineLive and ExportController so the actor_kind+actor_id collapse + datetime-local pad lives in ONE place
└── live/
    └── timeline_live.ex                           # MODIFY: render — add three download <.link href download>; add count status line + two-band banner; handle_params/3 — Task.async parallel count_matching + timeline_page; assign :match_count and :filter_query

lib/threadline/
└── export.ex                                      # MODIFY: add :cap option to count_matching/2; default unbounded (Mix task unaffected)

test/threadline/operator_surface/
├── controllers/
│   └── export_controller_test.exs                 # NEW: nested test-Endpoint shape (mirrors timeline_live_test.exs:1-60); cases: csv-iodata-happy, json-iodata-happy, ndjson-iodata-happy, chunked-CSV-above-5k (D-27), 422-on-bad-filter, 403-on-auth-denial, empty-window-CSV-header-only
├── export_auth_plug_test.exs                      # NEW: unit tests — explicit :export_authorize_fn called, fallback adapter wraps :authorize_fn, telemetry events emitted (granted/denied/error), 403 halt strategy
├── exports/
│   └── filename_test.exs                          # NEW: pure-function unit tests for Filename.for/2
├── exports_doc_contract_test.exs                  # NEW: regex-over-source pinning button labels, filename pattern, content-type literals, route literals, filter-key parity
├── exports_mix_parity_test.exs                    # NEW: byte-equality across all three formats; uses Mix.Task.rerun/2
└── live/
    └── timeline_live_test.exs                     # EXTEND: add cases for three download anchor hrefs, match-count-status text, two-band truncation banner rendering at counts 5_001 and 10_001
```

### Pattern P-1: Plain anchor for download (D-15)

**What:** Use `<.link href={…} download>` — NOT `phx-click` + `redirect/2`.
**When to use:** Each of the three download buttons in the toolbar.
**Example:**
```heex
<!-- Source: D-15 + PR #2611 (anchors with `download` attr no longer tear down LV socket) -->
<.link href={"#{@base_path}/exports/changes.csv?#{@filter_query}"} download class="download-button">
  Download CSV
</.link>
<.link href={"#{@base_path}/exports/changes.json?#{@filter_query}"} download class="download-button">
  Download JSON
</.link>
<.link href={"#{@base_path}/exports/changes.ndjson?#{@filter_query}"} download class="download-button">
  Download NDJSON
</.link>
```

> **Both `download` attribute AND `Content-Disposition: attachment` are needed.** PR #2611 specifically checks the HTML `download` attribute on anchor elements at the JS layer — without it, the LV socket can still tear down. The server-side `Content-Disposition: attachment` header is what triggers the actual file download in the browser. Belt + braces. [CITED: github.com/phoenixframework/phoenix_live_view/pull/2611 — "modified `wantsNewTab()` in `dom.js` to recognize download links"]

> `@filter_query` is computed in `handle_params/3` from the validated filters — same shape as the canonical query already built in `build_canonical_query/1` (timeline_live.ex:395-406). Reuse this function; do not re-derive.

### Pattern P-2: Macro grows a sibling controller scope (D-19)

**What:** `threadline_operator_surface/2` macro emits both the existing `live_session` block AND a new `scope "/exports"` block, all inside the existing `path` scope. The `scope "/exports"` uses an inline `plug` (NOT a host-defined pipeline).
**When to use:** Edit `lib/threadline/operator_surface/router.ex`.
**Example:**
```elixir
# Source: lib/threadline/operator_surface/router.ex (current shape) + LiveDashboard pattern
defmacro threadline_operator_surface(path, opts \\ []) do
  has_auth_fn? = Keyword.has_key?(opts, :authorize_fn)
  has_ack? = Keyword.get(opts, :adopter_acknowledges_unauthenticated, false)
  exports_enabled? = Keyword.get(opts, :exports, true)
  caller_file = __CALLER__.file
  caller_line = __CALLER__.line

  quote do
    # ... existing fail-closed compile-time check unchanged ...

    import Phoenix.LiveView.Router, only: [live_session: 3, live: 3]
    import Phoenix.Router, only: [scope: 2, scope: 3, scope: 4, get: 3, get: 4]

    live_session :threadline, on_mount: [{Threadline.OperatorSurface.Auth, unquote(opts)}] do
      scope unquote(path), alias: Threadline.OperatorSurface.Live do
        live("/", TimelineLive, :index)
        # ... other live routes unchanged ...
      end
    end

    if unquote(exports_enabled?) and Code.ensure_loaded?(Phoenix.Controller) do
      scope unquote(path) <> "/exports", alias: false, as: false do
        plug(Threadline.OperatorSurface.ExportAuthPlug, unquote(opts))
        get("/changes.csv",    Threadline.OperatorSurface.Controllers.ExportController, :csv)
        get("/changes.json",   Threadline.OperatorSurface.Controllers.ExportController, :json)
        get("/changes.ndjson", Threadline.OperatorSurface.Controllers.ExportController, :ndjson)
      end
    end
  end
end
```

> **Macro hygiene notes:**
> - `alias: false, as: false` — don't pollute host's alias namespace (LiveDashboard idiom).
> - Use full module path `Threadline.OperatorSurface.Controllers.ExportController` — no `alias:` shortcut to avoid ambiguity with the host's `alias` directives.
> - `Code.ensure_loaded?(Phoenix.Controller)` guard inside the `quote` is OK because it runs at the host's compile time — by then optional deps are or aren't loaded. The router macro file itself stays gated on `Phoenix.LiveView` at file scope (existing).
> - The `:exports` opt defaults to `true`; rare LV-only adopters can pass `exports: false`. [CITED: github.com/phoenixframework/phoenix_live_dashboard/blob/v0.8.4/lib/phoenix/live_dashboard/router.ex — `scope path, alias: false, as: false do`]

### Pattern P-3: Conn-shaped auth plug wrapping `:authorize_fn` (D-20)

**What:** A new `Threadline.OperatorSurface.ExportAuthPlug` mirrors `Threadline.OperatorSurface.Auth.on_mount/4`'s telemetry events, scope-assign, and halt strategy, but operates on `%Plug.Conn{}` instead of `%Phoenix.LiveView.Socket{}`.
**When to use:** Inside the new `scope "/exports"` block in router.ex; the macro passes the same `opts` keyword down so both `:authorize_fn` (LV) and `:export_authorize_fn` (Conn) are visible.
**Example:**
```elixir
# Source: NEW lib/threadline/operator_surface/export_auth_plug.ex
if Code.ensure_loaded?(Phoenix.Controller) do
  defmodule Threadline.OperatorSurface.ExportAuthPlug do
    @behaviour Plug

    import Plug.Conn

    @impl Plug
    def init(opts), do: opts

    @impl Plug
    def call(conn, opts) do
      authorize_fn = Keyword.get(opts, :authorize_fn, fn _ -> true end)
      export_authorize_fn = Keyword.get(opts, :export_authorize_fn)
      repo = Keyword.get(opts, :repo)

      conn = assign(conn, :threadline_repo, repo)

      authorizer =
        case export_authorize_fn do
          fun when is_function(fun, 1) ->
            fn -> fun.(conn) end

          nil ->
            # Fallback: build a synthetic socket-shaped mirror so the existing
            # `:authorize_fn.(socket)` contract works for HTTP requests too.
            # Most adopter functions only access `assigns.current_user` or similar.
            fn ->
              mirror = %{assigns: conn.assigns}
              authorize_fn.(mirror)
            end
        end

      try do
        case authorizer.() do
          :ok ->
            emit_telemetry(:granted, conn, nil)
            conn

          true ->
            emit_telemetry(:granted, conn, nil)
            conn

          {:ok, scope} when is_map(scope) ->
            emit_telemetry(:granted, conn, scope)
            assign(conn, :threadline_scope, scope)

          {:ok, scope} ->
            emit_telemetry(:granted, conn, nil)
            assign(conn, :threadline_scope, scope)

          _ ->
            halt_unauthorized(conn, :denied)
        end
      rescue
        _ -> halt_unauthorized(conn, :error)
      end
    end

    defp halt_unauthorized(conn, result) do
      emit_telemetry(result, conn, nil)

      conn
      |> put_resp_content_type("text/plain; charset=utf-8")
      |> send_resp(403, "forbidden")
      |> halt()
    end

    defp emit_telemetry(result, _conn, scope) do
      scope_keys = if is_map(scope), do: Map.keys(scope) |> Enum.sort(), else: []
      actor_ref = if is_map(scope), do: Map.get(scope, :actor_ref) || Map.get(scope, :user_id), else: nil

      :telemetry.execute(
        [:threadline, :operator_surface, :authorize],
        %{result: result},
        %{path: "", actor_ref: actor_ref, scope_keys: scope_keys}
      )
    end
  end
end
```

> **Telemetry event reuse:** The plug emits the **same** `[:threadline, :operator_surface, :authorize]` event as the LV `on_mount`. Adopters watching this event get one stream of auth decisions across both surfaces; no new event name is needed. The metadata `path: ""` matches `auth.ex:60` for parity. [VERIFIED: lib/threadline/operator_surface/auth.ex:51-62]

> **Halt response format:** The LV `on_mount` halts with `redirect(socket, to: "/")` — a redirect makes sense for an interactive page navigation, but for a download HTTP request, a plain `403 forbidden` text response is the right shape (no JSON adopter contract to match; no redirect target makes sense for a download anchor). [VERIFIED via auth.ex:48 vs HTTP semantics]

### Pattern P-4: Controller threshold dispatch (D-24)

**What:** Per-action sequence of validate → count → branch on threshold → dispatch. Iodata path is one `send_resp/3`; chunked path is `send_chunked/2` + `Stream.take(10_000) |> Stream.chunk_every(500) |> Enum.reduce_while/3`.
**When to use:** Inside each of `csv/2`, `json/2`, `ndjson/2` (factor the shared logic into a private `dispatch_export/3`).
**Example:**
```elixir
# Source: NEW lib/threadline/operator_surface/controllers/export_controller.ex
if Code.ensure_loaded?(Phoenix.Controller) do
  defmodule Threadline.OperatorSurface.Controllers.ExportController do
    use Phoenix.Controller, formats: [:html]

    import Plug.Conn

    alias Threadline.Export
    alias Threadline.OperatorSurface.Exports.Filename
    alias Threadline.OperatorSurface.Exports.FilterParams

    @sync_threshold 5_000
    @max_rows 10_000

    def csv(conn, params),    do: dispatch(conn, params, :csv)
    def json(conn, params),   do: dispatch(conn, params, :json)
    def ndjson(conn, params), do: dispatch(conn, params, :ndjson)

    defp dispatch(conn, params, format) do
      with {:ok, filters} <- FilterParams.parse(params),
           :ok <- safe_validate(filters) do
        repo = conn.assigns[:threadline_repo] || default_repo()
        filters = Keyword.put(filters, :repo, repo)

        {:ok, %{count: count}} = Export.count_matching(filters, cap: @max_rows + 1)

        conn = put_export_headers(conn, format)

        if count <= @sync_threshold do
          send_iodata(conn, filters, format)
        else
          send_chunked_stream(conn, filters, format)
        end
      else
        {:error, message} ->
          conn
          |> put_resp_content_type("text/plain; charset=utf-8")
          |> send_resp(422, "invalid filter: #{message}")
      end
    end

    defp send_iodata(conn, filters, :csv) do
      {:ok, %{data: iodata}} = Export.to_csv_iodata(filters, max_rows: @max_rows)
      send_resp(conn, 200, iodata)
    end

    defp send_iodata(conn, filters, :json) do
      {:ok, %{data: iodata}} = Export.to_json_document(filters, max_rows: @max_rows, json_format: :wrapped)
      send_resp(conn, 200, iodata)
    end

    defp send_iodata(conn, filters, :ndjson) do
      {:ok, %{data: iodata}} = Export.to_json_document(filters, max_rows: @max_rows, json_format: :ndjson)
      send_resp(conn, 200, iodata)
    end

    defp send_chunked_stream(conn, filters, format) do
      conn = send_chunked(conn, 200)

      filters
      |> Export.stream_changes(page_size: 1_000)
      |> Stream.take(@max_rows)
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

    # rows_to_chunks/2: format-specific row-to-iodata projection. CSV uses
    # NimbleCSV.RFC4180.dump_to_iodata/1 per-batch; JSON/NDJSON use Jason.
    # **Open Question O-1**: chunked-path byte-parity with iodata path requires
    # exact row-to-iodata function reuse. Recommended: extract a small public
    # helper from Threadline.Export (e.g. csv_row/2, change_map/1) — currently
    # private at lib/threadline/export.ex:220-284.

    defp put_export_headers(conn, :csv) do
      put_export_headers(conn, "text/csv; charset=utf-8", "csv")
    end

    defp put_export_headers(conn, :json) do
      put_export_headers(conn, "application/json; charset=utf-8", "json")
    end

    defp put_export_headers(conn, :ndjson) do
      put_export_headers(conn, "application/x-ndjson; charset=utf-8", "ndjson")
    end

    defp put_export_headers(conn, content_type, ext) do
      filename = Filename.for(ext, DateTime.utc_now())
      disposition = ~s|attachment; filename="#{filename}"; filename*=UTF-8''#{filename}|

      conn
      |> put_resp_content_type(content_type)
      |> put_resp_header("content-disposition", disposition)
      |> put_resp_header("cache-control", "no-store")
    end

    defp safe_validate(filters) do
      try do
        Threadline.Query.validate_timeline_filters!(filters)
        :ok
      rescue
        e in ArgumentError -> {:error, e.message}
      end
    end

    defp default_repo do
      Application.get_env(:threadline, :ecto_repos) |> hd()
    end
  end
end
```

> **Why `@sync_threshold = 5_000` and `@max_rows = 10_000`:** EXPO-04 fixes 5,000 as the iodata threshold; `Threadline.Export`'s `@default_max_rows` is 10,000 (lib/threadline/export.ex:2) — the controller forwards explicitly for symmetry between iodata and chunked paths. Both threshold and max_rows are module attributes here, NOT URL knobs (per Claude's Discretion in CONTEXT.md).

> **Why `:cap` is `@max_rows + 1` (10_001):** This lets the LV distinguish "10,000 exact matches" from "10,000+ matches" by checking `count >= 10_001` (the cap). The Mix task and capture-only adopters never see this cap because they don't pass `:cap`.

> **Headers MUST be set BEFORE `send_chunked/2`:** Plug requires response headers to be in place before transitioning to the chunked-response state. Setting `put_resp_header/3` after `send_chunked/2` is a hard error. [CITED: hexdocs.pm/plug/Plug.Conn.html#send_chunked/2]

> **`Cache-Control: no-store`:** Filtered audit data may include sensitive identifiers; downloaded files must not be cached by intermediate proxies or browsers' history stores. (REQUIREMENTS.md doesn't mandate this, but it's the audit-data hygiene default.) Document in plan as a discretionary choice.

### Pattern P-5: RFC 5987 `Content-Disposition` filename* header

**What:** Hand-craft the `Content-Disposition` header with both `filename=` (ASCII fallback) and `filename*=UTF-8''…` (RFC 5987 modern form). For ASCII-safe filenames like `threadline-changes-2026-05-06T12-00Z.csv`, both values are identical strings; the percent-encoding rules apply only to non-ASCII bytes.
**When to use:** Inside `put_export_headers/3` in the controller.
**Example:**
```elixir
# Filename is ASCII-safe by construction (D-25 minute granularity, ASCII format).
filename = "threadline-changes-2026-05-06T12-00Z.csv"
disposition = ~s|attachment; filename="#{filename}"; filename*=UTF-8''#{filename}|
# → attachment; filename="threadline-changes-2026-05-06T12-00Z.csv"; filename*=UTF-8''threadline-changes-2026-05-06T12-00Z.csv

put_resp_header(conn, "content-disposition", disposition)
```

> **No Phoenix helper exists.** `Phoenix.Controller.send_download/3` builds a header but only for static-file delivery; for dynamic iodata/chunked, hand-craft. [VERIFIED via Plug.Conn + Phoenix.Controller hexdocs]

> **Browser support:** RFC 6266 (which references RFC 5987) recommends emitting BOTH `filename=` and `filename*=` because some old user agents only understand the legacy form. For Threadline's ASCII-safe filenames they're identical strings, but the dual-emit pattern is harmless and future-proofs against any future filename change. [CITED: rfc-editor.org/rfc/rfc6266 §4.3; developer.mozilla.org Content-Disposition]

> **`filename*=` percent-encoding:** Each non-ASCII byte becomes `%XX` (hex). For Threadline's filenames (ASCII letters, digits, hyphens, periods only), no characters need encoding. If the filename ever includes non-ASCII (it shouldn't), use `URI.encode_www_form/1` is WRONG (that's for query strings — replaces space with `+`); the correct function is `URI.encode/2` with the RFC 5987 `pchar` set, or hand-roll: `:binary.bin_to_list(filename) |> Enum.map_join(fn b -> "%" <> Integer.to_string(b, 16) end)`. **For Phase 65 the filenames are ASCII-only by construction; document the encoding rule in the helper module's `@moduledoc` for future-proofing.** [CITED: rfc-editor.org/rfc/rfc5987 §3.2.1]

### Pattern P-6: Filename helper (D-25)

**What:** A pure function `Threadline.OperatorSurface.Exports.Filename.for(format, datetime)` returning the canonical filename string with minute granularity.
**When to use:** Both controller actions call this; doc-contract test asserts the output literal.
**Example:**
```elixir
# Source: NEW lib/threadline/operator_surface/exports/filename.ex
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

> **Date format note:** EXPO-04's literal example is `threadline-changes-2026-05-06T12-00Z.csv` — the colon between hours and minutes is a HYPHEN (`12-00`), not a colon (`12:00`). Filesystem-friendly (Windows forbids colons in filenames). The `Calendar.strftime/2` format string `"%Y-%m-%dT%H-%MZ"` produces this exact shape. [VERIFIED: REQUIREMENTS.md EXPO-04 + CONTEXT.md D-25]

> **`Calendar.strftime/2` ships in Elixir stdlib (since 1.11)** — no new dep. [CITED: hexdocs.pm/elixir/Calendar.html#strftime/2]

### Pattern P-7: Parallel `count_matching` + `timeline_page` in `handle_params/3` (D-16)

**What:** Two `Task.async/1` calls awaited together so total latency is `max(count, page)`, not `sum`.
**When to use:** TimelineLive `handle_params/3` after filter validation succeeds.
**Example:**
```elixir
# Replaces the single Query.timeline_page call at lib/threadline/operator_surface/live/timeline_live.ex:112
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

  # Two parallel queries; await with a generous timeout for the worst case.
  # Default Task.await timeout is 5_000ms; bump to 8_000 to leave headroom for
  # slow capped-count queries on large tables.
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

> **Why `Task.async` over `Task.async_stream` or `assign_async`:**
> - `Task.async_stream/3` is for enumerable mapping with bounded concurrency — overkill for two fixed calls.
> - `assign_async/3` (LV 1.0) renders a loading state then re-renders when the async resolves — but D-17 wants the count visible on the SAME render as the timeline rows. `assign_async` would render the timeline first then "snap in" the count, breaking the status-line shape.
> - Plain `Task.async/await` is the idiomatic Elixir pattern for two parallel calls awaited together; the LV process supervises both tasks naturally (linked); on either task crash the LV process crashes, which the LV supervision tree handles via socket re-mount. [CITED: hexdocs.pm/elixir/Task.html#async/1]

> **Connection-pool sizing:** This adds 1 extra concurrent query per LV mount + per Apply submit. For a 10-pool default Ecto repo, this means up to 5 simultaneous LV operators can hit the timeline before pool saturation. **Document in plan; not a Phase 65 blocker.** Phase 68 (lifecycle ergonomics) could surface a "consider sizing your pool for N timeline operators" hint in operator-surface.md.

> **Crash semantics:** If `count_matching` raises (DB connection refused, statement timeout NOT covered by `:cap`, etc.), the `Task.await` re-raises in the LV process. Result: LV crash → socket reconnect → mount re-runs → user sees the empty toolbar momentarily then the form re-fills from URL. Acceptable for an interactive operator surface. **Do not wrap in try/rescue** — silent failures are worse than a brief LV reconnect.

### Pattern P-8: Capped count via `:cap` opt on `count_matching/2` (D-23)

**What:** New `:cap` option on `Threadline.Export.count_matching/2`. Default is unbounded (Mix-task-callers and capture-only adopters get current behavior unchanged). The LV passes `cap: 10_001` so any window with >10,000 rows returns 10_001 immediately, allowing the LV to render "10,000+ matches" without waiting for a true count.
**When to use:** Add to `lib/threadline/export.ex`; LV passes `cap: 10_001`; controller passes `cap: 10_001` (so the controller's threshold check at >5_000 is reliable even for huge windows).
**SQL pattern:**
```sql
-- WRONG (returns boolean, not count):
SELECT EXISTS (SELECT 1 FROM audit_changes ... LIMIT 10001);

-- CORRECT (windowed count — returns true count when below cap, returns cap when at it):
SELECT count(*) FROM (
  SELECT 1 FROM audit_changes
  INNER JOIN audit_transactions ON ...
  WHERE ...
  LIMIT 10001
) limited;
```
**Example Elixir:**
```elixir
# In lib/threadline/export.ex, additive change to count_matching/2:
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

> **Why this option goes on `Threadline.Export.count_matching/2`, NOT on a new helper:** A new helper duplicates the `validate_timeline_filters!` + `timeline_repo!` boilerplate. A keyword option is purely additive (default `nil` = current unbounded behavior); the Mix task and any existing capture-only adopter are unaffected. [VERIFIED: lib/threadline/export.ex:151-172]

> **Performance impact at the cap:** PostgreSQL stops the index scan at `LIMIT 10001` rows — typical query time becomes < 5ms regardless of total table size. Without the cap, multi-million-row tables can take 100s of ms or hit `statement_timeout`. [CITED: pganalyze.com/blog/5mins-postgres-limited-count]

> **LV decision logic:**
> ```elixir
> banner_message =
>   cond do
>     match_count >= 10_001 -> :truncation_warning  # "10,000+ matches" + "Truncated to first 10,000"
>     match_count > 5_000   -> :chunked_informational
>     true                   -> nil
>   end
>
> count_text =
>   cond do
>     match_count >= 10_001 -> "10,000+"
>     true                   -> Integer.to_string(match_count) |> add_thousands_sep()
>   end
> ```

### Pattern P-9: Doc-contract test (regex over source)

**What:** Pure `ExUnit.Case, async: true` test that reads source files and asserts string presence/regex match — same shape as `OperatorSurfaceDocContractTest` and Phase 64's `TimelineBrowseDocContractTest`.
**When to use:** New file `test/threadline/operator_surface/exports_doc_contract_test.exs`. Locks button labels, filename helper output, content-type literals, route literals, filter-key parity.
**Example:**
```elixir
# Source: NEW test/threadline/operator_surface/exports_doc_contract_test.exs
# Pattern source: test/threadline/operator_surface/timeline_browse_doc_contract_test.exs
defmodule Threadline.OperatorSurface.ExportsDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @router_path     "lib/threadline/operator_surface/router.ex"
  @lv_path         "lib/threadline/operator_surface/live/timeline_live.ex"
  @controller_path "lib/threadline/operator_surface/controllers/export_controller.ex"
  @plug_path       "lib/threadline/operator_surface/export_auth_plug.ex"
  @filename_path   "lib/threadline/operator_surface/exports/filename.ex"
  @query_path      "lib/threadline/query.ex"

  # --- EXPO-05: button label literals ---

  test "TimelineLive renders the three download button labels verbatim" do
    src = File.read!(@lv_path)
    assert String.contains?(src, "Download CSV")
    assert String.contains?(src, "Download JSON")
    assert String.contains?(src, "Download NDJSON")
  end

  # --- EXPO-05: route literals (parity test target) ---

  test "router macro emits /exports/changes.{csv,json,ndjson} GET routes" do
    src = File.read!(@router_path)
    assert String.contains?(src, ~s|"/changes.csv"|)
    assert String.contains?(src, ~s|"/changes.json"|)
    assert String.contains?(src, ~s|"/changes.ndjson"|)
    assert String.contains?(src, "ExportController, :csv")
    assert String.contains?(src, "ExportController, :json")
    assert String.contains?(src, "ExportController, :ndjson")
  end

  # --- EXPO-05: content-type literals ---

  test "controller emits exact content-type literals" do
    src = File.read!(@controller_path)
    assert String.contains?(src, ~s|"text/csv; charset=utf-8"|)
    assert String.contains?(src, ~s|"application/json; charset=utf-8"|)
    assert String.contains?(src, ~s|"application/x-ndjson; charset=utf-8"|)
  end

  # --- EXPO-05: filename helper canonical pattern ---

  test "Filename.for/2 produces the canonical UTC-minute pattern for each format" do
    dt = ~U[2026-05-06 12:00:00.000Z]

    assert Threadline.OperatorSurface.Exports.Filename.for("csv",    dt) == "threadline-changes-2026-05-06T12-00Z.csv"
    assert Threadline.OperatorSurface.Exports.Filename.for("json",   dt) == "threadline-changes-2026-05-06T12-00Z.json"
    assert Threadline.OperatorSurface.Exports.Filename.for("ndjson", dt) == "threadline-changes-2026-05-06T12-00Z.ndjson"
  end

  # --- EXPO-05: filter-key parity (load-bearing) ---

  test "controller filter-param parsing covers the same allowlist as Threadline.Query (parity guarantee)" do
    controller_src = File.read!(@controller_path)
    query_src = File.read!(@query_path)

    [_, allowlist_block] =
      Regex.run(~r/@allowed_timeline_filter_keys\s+~w\(([^)]+)\)a/, query_src) ||
        flunk("could not find @allowed_timeline_filter_keys in #{@query_path}")

    lib_keys =
      allowlist_block
      |> String.split()
      |> MapSet.new()
      |> MapSet.delete("repo")

    # The shared FilterParams module enumerates these keys; assert every lib key
    # is referenced by name (controller never invents a parallel allowlist).
    for key <- MapSet.to_list(lib_keys) -- ["actor_ref"] do
      # actor_ref collapses from actor_kind + actor_id; assert both raw URL keys
      # are referenced where the lib key is "actor_ref".
      assert String.contains?(controller_src, key) or
               (key == "actor_ref" and
                  String.contains?(controller_src, "actor_kind") and
                  String.contains?(controller_src, "actor_id")),
             "controller does not reference filter key #{inspect(key)}"
    end
  end

  # --- EXPO-05: file-scope Code.ensure_loaded? gates ---

  test "controller is wrapped in file-scope Code.ensure_loaded?(Phoenix.Controller) gate" do
    src = File.read!(@controller_path)
    assert String.starts_with?(src, "if Code.ensure_loaded?(Phoenix.Controller) do")
  end

  test "auth plug is wrapped in file-scope Code.ensure_loaded?(Phoenix.Controller) gate" do
    src = File.read!(@plug_path)
    assert String.starts_with?(src, "if Code.ensure_loaded?(Phoenix.Controller) do")
  end

  # --- EXPO-05: filename helper has NO Phoenix dep gate (per D-21 — pure helper) ---

  test "Filename helper file is NOT gated on optional deps (pure stdlib)" do
    src = File.read!(@filename_path)
    refute String.contains?(src, "Code.ensure_loaded?")
  end
end
```

> **Why regex over AST:** Existing project pattern (BROWSE-04 + every other `*_doc_contract_test.exs`) uses `String.contains?` and `Regex.scan`. AST walking via `Code.string_to_quoted/1` is heavier, brittle to formatting changes (e.g. `live("/", ...)` vs `live "/", ...`), and inconsistent with project convention. **Use regex.** [VERIFIED: test/threadline/operator_surface/timeline_browse_doc_contract_test.exs:47-90 + test/threadline/operator_surface_doc_contract_test.exs]

### Pattern P-10: Chunked-stream integration test infrastructure

**What:** Nested test-Endpoint that mounts the macro at `/audit`, then `Phoenix.ConnTest.build_conn() |> get("/audit/exports/changes.csv?…")` and assert response shape.
**When to use:** New file `test/threadline/operator_surface/controllers/export_controller_test.exs`. Test cases per format, plus EXPO-05 chunked-path assertion.
**Example:**
```elixir
# Source: NEW test/threadline/operator_surface/controllers/export_controller_test.exs
# Pattern source: test/threadline/operator_surface/live/timeline_live_test.exs:1-60 (nested Endpoint shape)

if Code.ensure_loaded?(Phoenix.Controller) do
  defmodule Threadline.OperatorSurface.ExportControllerTest.Layouts do
    use Phoenix.Component
    def root(assigns), do: ~H"<html><body><%= @inner_content %></body></html>"
    def render("500.html", assigns), do: ~H"Error 500: <%= inspect(assigns.reason) %>"
  end

  defmodule Threadline.OperatorSurface.ExportControllerTest.Router do
    use Phoenix.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html", "csv", "json"])
      plug(:fetch_session)
    end

    scope "/" do
      pipe_through(:browser)
      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit")
    end
  end

  defmodule Threadline.OperatorSurface.ExportControllerTest.Endpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [store: :cookie, key: "_threadline_export_key", signing_salt: "x" |> String.duplicate(8)]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:urlencoded, :json], pass: ["*/*"], json_decoder: Jason)
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.ExportControllerTest.Router)
  end

  defmodule Threadline.OperatorSurface.ExportControllerTest do
    # async: false — Threadline does NOT use SQL Sandbox; tests share a real DB
    # and clean up between cases. See test/support/data_case.ex.
    use ExUnit.Case, async: false

    import Phoenix.ConnTest

    alias Threadline.Capture.{AuditChange, AuditTransaction}

    @endpoint Threadline.OperatorSurface.ExportControllerTest.Endpoint
    @repo Threadline.Test.Repo

    setup_all do
      Application.put_env(:threadline, @endpoint,
        secret_key_base: "x" |> String.duplicate(64),
        live_view: [signing_salt: "x" |> String.duplicate(8)],
        render_errors: [view: Threadline.OperatorSurface.ExportControllerTest.Layouts]
      )

      start_supervised!(@endpoint)
      :ok
    end

    setup do
      # Honest cleanup — same as DataCase, FK order
      @repo.delete_all(AuditChange)
      @repo.delete_all(AuditTransaction)
      @repo.delete_all(Threadline.Semantics.AuditAction)
      {:ok, conn: build_conn()}
    end

    # --- iodata path (count <= 5_000) ---

    test "GET /audit/exports/changes.csv with small window returns 200 + RFC 4180 CSV", %{conn: conn} do
      seed_changes!(10, table: "posts")

      from = "2020-01-01T00:00"
      to   = "2099-01-01T00:00"

      conn = get(conn, "/audit/exports/changes.csv?from=#{from}&to=#{to}&table=posts")

      assert conn.status == 200
      assert response_content_type(conn, :csv) =~ "text/csv"
      assert get_resp_header(conn, "content-disposition") |> List.first() =~ ~r/attachment; filename="threadline-changes-/
      body = response(conn, 200)
      # RFC 4180: header row + 10 data rows + trailing newline behavior matches NimbleCSV.RFC4180.dump_to_iodata
      lines = String.split(body, "\r\n", trim: true)
      assert length(lines) == 11  # 1 header + 10 data
      assert hd(lines) == "id,transaction_id,table_schema,table_name,op,captured_at,table_pk,data_after,changed_fields,changed_from,transaction_json"
    end

    # --- chunked path (D-27, EXPO-05 — load-bearing) ---

    @tag :slow
    test "GET /audit/exports/changes.csv with >5,000 rows returns 200 + chunked transfer", %{conn: conn} do
      # D-27 mandates >5,000 rows seeded for chunked-path coverage
      seed_changes!(5_001, table: "posts")

      from = "2020-01-01T00:00"
      to   = "2099-01-01T00:00"

      conn = get(conn, "/audit/exports/changes.csv?from=#{from}&to=#{to}&table=posts")

      assert conn.status == 200
      assert response_content_type(conn, :csv) =~ "text/csv"
      # Plug.Test stitches chunks into a single binary response; transport behavior
      # is verified by send_chunked/2 being on the call path (asserted via state).
      assert conn.state == :chunked
      body = conn.resp_body  # Plug.Test accumulates chunks here
      lines = String.split(body, "\r\n", trim: true)
      assert length(lines) >= 5_001  # 1 header + 5,000+ data rows
    end

    # --- 422 on filter validation failure ---

    test "GET with invalid filter key returns 422 plain text", %{conn: conn} do
      conn = get(conn, "/audit/exports/changes.csv?from=not-a-date")
      assert conn.status == 422
      assert response_content_type(conn, :text) =~ "text/plain"
      assert response(conn, 422) =~ "invalid"
    end

    # --- 403 on auth denial — requires endpoint reconfigured with denying authorize_fn ---
    # Recommend: separate test module with its own Endpoint that mounts the macro
    # with `authorize_fn: fn _ -> false end`. Keeps this test file's setup_all simple.

    # --- empty window — header-only CSV (RFC 4180 valid) ---

    test "GET with no matching rows returns 200 + header-only CSV", %{conn: conn} do
      from = "2020-01-01T00:00"
      to   = "2020-01-02T00:00"

      conn = get(conn, "/audit/exports/changes.csv?from=#{from}&to=#{to}&table=does_not_exist")

      assert conn.status == 200
      body = response(conn, 200)
      lines = String.split(body, "\r\n", trim: true)
      assert length(lines) == 1  # header only
    end

    # --- Helpers ---

    defp seed_changes!(n, opts) when n > 0 do
      table = Keyword.fetch!(opts, :table)

      # Bulk insert via insert_all for the >5k case — much faster than 5,001 individual changesets.
      txn =
        @repo.insert!(
          AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: DateTime.utc_now()
          })
        )

      now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

      changes =
        for i <- 1..n do
          %{
            id: Ecto.UUID.generate(),
            transaction_id: txn.id,
            table_schema: "public",
            table_name: table,
            table_pk: %{"id" => "#{i}"},
            op: "insert",
            data_after: %{"i" => i},
            captured_at: now
          }
        end

      @repo.insert_all(AuditChange, changes)
    end
  end
end
```

> **`async: false` is mandatory:** Threadline tests share a real PostgreSQL database (Postgres triggers don't respect `Ecto.Adapters.SQL.Sandbox`). `setup` cleans `audit_changes`, `audit_transactions`, `audit_actions` in FK order. **Do not invent a sandboxed setup.** [VERIFIED: test/support/data_case.ex:6-10]

> **`@tag :slow` for the >5k seed test:** Per the OSS DNA "honest default tests" principle, do NOT add `:slow` to `mix test`'s exclude list. The 5_001-row insert via `insert_all` runs in ~100ms on a local PG; tagging is for opt-in CI splitting later, not for hiding it. **The test runs in default `mix test` always.** Document this in the plan. [VERIFIED: prompts/threadline-elixir-oss-dna.md "honest default tests" — referenced in CLAUDE.md]

> **`Plug.Test` accumulates chunks into `conn.resp_body`:** When testing a chunked response with `Phoenix.ConnTest`, the chunks are stitched together; `conn.state` becomes `:chunked` and `conn.resp_body` contains the full assembled body. This means the test can assert byte-content correctness even though transport-wise it was chunked. [CITED: hexdocs.pm/plug/Plug.Test.html]

### Pattern P-11: Mix-task / controller byte-equality parity test (D-28)

**What:** Run both code paths in the same test, assert `assert File.read!(tmp_path) == response_body` for all three formats. Use `Mix.Task.rerun/2` so the Mix task can be invoked across multiple test cases.
**When to use:** New file `test/threadline/operator_surface/exports_mix_parity_test.exs`.
**Example:**
```elixir
# Source: NEW test/threadline/operator_surface/exports_mix_parity_test.exs
if Code.ensure_loaded?(Phoenix.Controller) do
  # Reuse Endpoint + Router from ExportControllerTest, OR define minimal locals.
  # Recommended: alias the test Endpoint module via a shared fixtures file under
  # test/support/, kept minimal so async semantics stay clear.

  defmodule Threadline.OperatorSurface.ExportsMixParityTest do
    use ExUnit.Case, async: false

    import Phoenix.ConnTest
    import ExUnit.CaptureIO

    alias Threadline.Capture.{AuditChange, AuditTransaction}

    @endpoint Threadline.OperatorSurface.ExportControllerTest.Endpoint
    @repo     Threadline.Test.Repo

    setup_all do
      # Endpoint may already be started by ExportControllerTest's setup_all in the same suite
      _ = start_supervised(@endpoint)
      :ok
    end

    setup do
      @repo.delete_all(AuditChange)
      @repo.delete_all(AuditTransaction)
      @repo.delete_all(Threadline.Semantics.AuditAction)

      # Re-enable the Mix task so it can be invoked again in the next test case.
      Mix.Task.reenable("threadline.export")

      {:ok, conn: build_conn(), tmp_dir: System.tmp_dir!()}
    end

    test "CSV: Mix task and controller produce byte-identical output", %{conn: conn, tmp_dir: tmp_dir} do
      seed_changes!(50)

      from = "2020-01-01T00:00:00Z"
      to   = "2099-01-01T00:00:00Z"
      tmp_path = Path.join(tmp_dir, "parity-#{:rand.uniform(1_000_000)}.csv")

      # 1. Mix task (capture stdout to suppress banner chatter)
      capture_io(fn ->
        Mix.Task.rerun("threadline.export", [
          "--format", "csv",
          "--output", tmp_path,
          "--from", from,
          "--to", to
        ])
      end)

      mix_bytes = File.read!(tmp_path)

      # 2. Controller — convert ISO-Z to datetime-local format the LV+controller use
      from_local = String.slice(from, 0..15)  # "2020-01-01T00:00"
      to_local   = String.slice(to,   0..15)
      controller_conn = get(conn, "/audit/exports/changes.csv?from=#{from_local}&to=#{to_local}")
      controller_bytes = response(controller_conn, 200)

      assert mix_bytes == controller_bytes,
             "Mix task and controller produced different bytes for the same filters."
    end

    test "JSON wrapped: byte-identical", %{conn: conn, tmp_dir: tmp_dir} do
      # ... mirror of CSV test, using --format json (no --json-format = wrapped default)
    end

    test "NDJSON: byte-identical", %{conn: conn, tmp_dir: tmp_dir} do
      # ... mirror of CSV test, using --format json --json-format ndjson
    end

    defp seed_changes!(n) do
      # Same shape as ExportControllerTest helper
    end
  end
end
```

> **`Mix.Task.rerun/2` (NOT `run/2`):** A Mix task runs at most ONCE per OS process by default. Within an ExUnit suite running multiple parity tests, the second `Mix.Task.run("threadline.export", …)` call returns `:noop` and your seeded data is never read. `Mix.Task.rerun/2` re-enables and runs in one call. Alternative: `Mix.Task.reenable("threadline.export")` in `setup` (shown above) + plain `run/2` in the test. **Either works; `reenable` in setup keeps the test body clean.** [CITED: hexdocs.pm/mix/Mix.Task.html — "By default, tasks will only run _once_, even when called repeatedly"]

> **Time format gotcha — `from_local = String.slice(from, 0..15)`:** The Mix task accepts ISO-8601 with `Z` suffix (`2020-01-01T00:00:00Z`); the controller (mirroring TimelineLive) accepts the datetime-local format without suffix (`2020-01-01T00:00`). Both ultimately produce the same `DateTime` after parsing. **The parity test must convert between the two formats** so both paths see identical filter `DateTime` values. (TimelineLive does the same `String.slice(0..15)` at line 68-69.) [VERIFIED: lib/threadline/operator_surface/live/timeline_live.ex:68-69]

> **Both paths produce iodata via the SAME `Threadline.Export.{to_csv_iodata, to_json_document}/2` calls** with identical opts derived from identical filters. The byte-equality assertion is essentially a guard against future divergence (e.g., a controller hand-rolling its own row format).

### Anti-Patterns to Avoid

- **`phx-click` + `redirect(socket, external: …)` for download:** documented LV footgun (PR #2611 cite). Tears down LV socket mid-export; loses scroll/cursor/filter state. CONTEXT.md D-15 locks the `<.link href download>` pattern explicitly.
- **`Enum.into/2` or `Enum.reduce/3` over `Plug.Conn.chunk/2`:** silently swallows `{:error, :closed}` and continues writing to a closed socket. **Always use `Enum.reduce_while/3`** with explicit `{:cont, conn}` / `{:halt, conn}`.
- **`put_resp_header/3` AFTER `send_chunked/2`:** Plug requires headers in place before the chunked-state transition. Reorder so all headers are set first.
- **Forgetting `Stream.take(10_000)` on the chunked path:** without it, an unfiltered window streams every row in `audit_changes` (potentially millions) past the 10k truncation contract. The iodata path enforces this implicitly via `Threadline.Export`'s `@default_max_rows = 10_000`; the chunked path must enforce it explicitly.
- **Defining a `pipeline :threadline_export_auth` from inside the macro:** pollutes host's pipeline namespace, risks naming collisions. Use bare `plug` inside the scope (LiveDashboard idiom).
- **Adding `:slow` to `mix test`'s exclude list to "speed up" CI:** violates OSS DNA "honest default tests" principle. The 5_001-row seed test must run in default `mix test`.
- **Using `Ecto.Adapters.SQL.Sandbox` in the chunked-stream integration test:** Postgres triggers fire outside sandbox awareness. Use `async: false` + explicit `Repo.delete_all` in setup, mirroring `Threadline.DataCase`.
- **Calling `Mix.Task.run/2` (not `rerun/2`) in multi-test parity test:** task no-ops on second call; second test sees stale Mix-task output. Use `Mix.Task.rerun/2` or `Mix.Task.reenable/1` in setup.
- **AST-walk via `Code.string_to_quoted/1` for doc-contract tests:** inconsistent with project convention (regex over file source). Brittle to formatting changes.
- **Per-keystroke `phx-change` on the form:** would cause per-keystroke rebuild of `@filter_query` (used in download hrefs) and per-keystroke parallel `count_matching` calls. Phase 64's D-04 already locked explicit Apply-only — Phase 65 inherits this constraint.

## API Reference Confirmations

| API | Source | Arity | Returns | Critical Notes |
|-----|--------|-------|---------|----------------|
| `Threadline.Export.to_csv_iodata/2` | `lib/threadline/export.ex:71` | `(filters, opts)` | `{:ok, %{data: iodata, truncated: bool, returned_count: int, max_rows: int}}` | Opts: `:repo`, `:max_rows` (default 10_000), `:include_action_metadata`. Calls `validate_timeline_filters!/1` internally. |
| `Threadline.Export.to_json_document/2` | `lib/threadline/export.ex:108` | `(filters, opts)` | `{:ok, %{data: data, truncated, returned_count, max_rows}}` | Opts: `:repo`, `:max_rows`, `:json_format` (`:wrapped` default or `:ndjson`). For `:ndjson` the `data` is `binary` (already concatenated); for `:wrapped` it's iodata. **Both shapes work with `send_resp(conn, 200, data)`.** |
| `Threadline.Export.count_matching/2` | `lib/threadline/export.ex:151` | `(filters, opts)` | **`{:ok, %{count: non_neg_integer()}}`** | NOT a bare integer. Must destructure with `{:ok, %{count: count}}` (see Mix task line 67). Phase 65 adds `:cap` opt (additive). |
| `Threadline.Export.stream_changes/2` | `lib/threadline/export.ex:184` | `(filters, opts)` | `Enumerable.t()` (`AuditChange` structs) | **Does NOT enforce `:max_rows`.** Controller MUST wrap in `Stream.take(10_000)`. Opts: `:repo`, `:page_size` (default 1000). |
| `Threadline.Query.validate_timeline_filters!/1` | `lib/threadline/query.ex:138` | `(filters)` | `:ok` or raises `ArgumentError` | Allowlist: `:repo, :table, :actor_ref, :from, :to, :correlation_id`. Controller wraps in `try/rescue` → 422. |
| `Threadline.Query.timeline_page/2` | `lib/threadline/query.ex:290` | `(filters, opts)` | `%TimelinePage{entries, next_cursor}` | Opts: `:repo`, `:page_size` (default 1000), `:cursor`. Calls `validate_timeline_filters!/1` and `timeline_repo!/2` internally. |
| `Threadline.Query.@allowed_timeline_filter_keys` | `lib/threadline/query.ex:36` | (module attribute) | `~w(repo table actor_ref from to correlation_id)a` | EXPO-05 doc-contract test asserts parity. |
| `Threadline.Semantics.ActorRef.new/2` | `lib/threadline/semantics/actor_ref.ex:35` | `(type, id \\ nil)` | `{:ok, %ActorRef{}}` or `{:error, :unknown_actor_type \| :missing_actor_id}` | `:anonymous` is the only kind that accepts `nil` id. Fixed enum: `user, admin, service_account, job, system, anonymous`. |
| `Plug.Conn.send_chunked/2` | hexdocs.pm/plug | `(conn, status)` | `Plug.Conn.t()` | All `put_resp_header/3` calls MUST come BEFORE this. |
| `Plug.Conn.chunk/2` | hexdocs.pm/plug | `(conn, body)` | `{:ok, conn} \| {:error, term()}` | Pair with `Enum.reduce_while/3`. `{:error, :closed}` is the common client-disconnect case. |
| `Plug.Conn.put_resp_header/3` | hexdocs.pm/plug | `(conn, header, value)` | `Plug.Conn.t()` | Header names lowercased. Use `"content-disposition"`, `"cache-control"`, etc. |
| `Plug.Conn.put_resp_content_type/3` | hexdocs.pm/plug | `(conn, content_type, charset \\ "utf-8")` | `Plug.Conn.t()` | Convenience for `Content-Type`. Pass full string `"text/csv; charset=utf-8"` and skip the charset arg, OR pass `"text/csv"` and let it append `; charset=utf-8`. **Be explicit about the format you write so doc-contract test can assert it.** |
| `Mix.Task.rerun/2` | hexdocs.pm/mix | `(task_name, args \\ [])` | task return value | Re-enables + runs. Equivalent to `reenable(name) ; run(name, args)`. |
| `Phoenix.LiveView.<.link>` | hexdocs.pm/phoenix_live_view | (HEEx component) | rendered `<a>` | `href={…}` for full-page navigation; add `download` attribute (HTML attr, no value needed) so PR #2611 keeps LV socket alive. [VERIFIED: github.com/phoenixframework/phoenix_live_view/pull/2611] |

## Pitfalls

### Pitfall 1: `Plug.Conn.chunk/2` return-shape misuse

**What goes wrong:** Using `Enum.into/2` or `Enum.reduce/3` instead of `Enum.reduce_while/3`. On client disconnect, `chunk/2` returns `{:error, :closed}` but the reducer keeps trying to write, accumulating errors and (worst case) blocking on a stuck socket.
**Why it happens:** `chunk/2` looks like a fire-and-forget side-effect; developers reach for the simpler `Enum` shape.
**How to avoid:** Hard-code the `Enum.reduce_while/3` + `case` pattern in the controller. Doc-contract test pins `Enum.reduce_while` literal in source.
**Warning signs:** Test cases for client-disconnect mid-stream are flaky or pass spuriously.

### Pitfall 2: Headers set after `send_chunked/2`

**What goes wrong:** `put_resp_header/3` after `send_chunked/2` raises `Plug.Conn.AlreadySentError` because the response state has transitioned out of the unsent-headers phase.
**Why it happens:** Refactoring; reordering helpers; trying to set a header inside the chunk reducer.
**How to avoid:** Single `put_export_headers/2` helper called BEFORE `send_chunked/2`. Doc-contract test could assert ordering by literal grep.
**Warning signs:** Runtime errors on the chunked path that don't reproduce on the iodata path.

### Pitfall 3: Filter param parsing duplicated between LV and controller

**What goes wrong:** TimelineLive (lib/threadline/operator_surface/live/timeline_live.ex:264-356) has 90 lines of filter-param normalization (`filters_raw_from_params/1`, `normalize_params/1`, `parse_datetimes/1`, `parse_datetime_local/1`, `collapse_actor_ref/1`, `safe_actor_kind/1`, `build_filters/1`). The controller needs IDENTICAL parsing — the parity test depends on bit-identical behavior. Hand-copying invites silent divergence.
**Why it happens:** Phase 64 wrote everything inline in TimelineLive; Phase 65 needs the same logic in a Phoenix.Controller, but copy-paste is the path of least resistance.
**How to avoid:** Extract the parser to `Threadline.OperatorSurface.Exports.FilterParams` (or `Threadline.OperatorSurface.FilterParams` if cross-surface) as part of Phase 65 plan. **Both** TimelineLive (modify) and ExportController (new) call it. The doc-contract test asserts both surfaces import the same module.
**Warning signs:** Parity test passes for ASCII filters but fails for edge cases (empty actor_id with kind=user; correlation_id whitespace; datetime second-precision).

### Pitfall 4: `stream_changes` not capped at 10k on chunked path

**What goes wrong:** `Threadline.Export.stream_changes/2` is unbounded by design (module doc: *"does not apply max_rows"*). On a multi-million-row table with broad filters, the chunked path streams every row past the 10,000 contract — operator gets a 500MB CSV instead of the 10k-row truncated one the iodata path produces, breaking parity with `mix threadline.export --max-rows 10_000`.
**Why it happens:** The iodata path's `to_csv_iodata/2` enforces `:max_rows` internally; the chunked path looks "automatic" because the lib does the keyset paging. The 10k cap must be applied at the consumer.
**How to avoid:** `stream_changes(filters, page_size: 1_000) |> Stream.take(10_000) |> ...` — the `Stream.take/2` MUST be inside the controller pipeline. Doc-contract test grep's `Stream.take(10_000)` literal in `export_controller.ex` source.
**Warning signs:** A multi-GB CSV downloaded for a "no filters" window. Parity test fails for windows with > 10k rows.

### Pitfall 5: `count_matching` returns `{:ok, %{count: …}}`, not bare integer

**What goes wrong:** Controller writes `count = Export.count_matching(filters, [])` and gets `{:ok, %{count: N}}` back; downstream `if count > 5_000` is comparing a tuple to an integer (always falsy or always truthy depending on Erlang term order). Compiler doesn't catch this; tests pass on small-window paths because both branches accidentally write iodata.
**Why it happens:** `count_matching` is named like an integer-returning helper; the wrap in `{:ok, %{count: …}}` is for forward-compat with future metadata.
**How to avoid:** Always destructure: `{:ok, %{count: count}} = Export.count_matching(filters, opts)`. Mix task already does this (lib/mix/tasks/threadline.export.ex:67). Plans MUST encode the destructure.
**Warning signs:** Threshold-dispatch always picks one branch regardless of seeded row count.

### Pitfall 6: SQL Sandbox attempted (will silently break)

**What goes wrong:** Plan adds `Ecto.Adapters.SQL.Sandbox.checkout(@repo)` to chunked-integration test setup. PG triggers don't see the sandbox — captured changes go to the real DB; cleanup leaves residual rows; subsequent tests see ghost data; flake.
**Why it happens:** SQL Sandbox is the standard Phoenix project pattern. New contributor copies a Phoenix tutorial setup.
**How to avoid:** **Plans must reference `test/support/data_case.ex` and explicitly state `async: false` + `Repo.delete_all` in setup.** Doc-contract test could grep for `Ecto.Adapters.SQL.Sandbox` and `async: true` in the new test files and refute their presence.
**Warning signs:** Test failures only on second test in module; fail in CI but pass locally.

### Pitfall 7: `Mix.Task.run` no-ops on second call

**What goes wrong:** Parity test runs three test cases (CSV, JSON, NDJSON), each calling `Mix.Task.run("threadline.export", …)`. After the first invocation, Mix marks the task as run; subsequent calls return `:noop` without executing. The `tmp_path` file from the second test contains the FIRST test's output (or doesn't exist), and the byte-equality assertion compares unrelated content.
**Why it happens:** Standard Mix semantics — designed for one-shot CLI execution.
**How to avoid:** Use `Mix.Task.rerun/2` OR call `Mix.Task.reenable("threadline.export")` in `setup`. Plans pin which.
**Warning signs:** First parity test passes; subsequent tests fail with weird content mismatch or `File.read!/1` enoent.

### Pitfall 8: `:cap` SQL pattern uses `EXISTS` (returns boolean, not count)

**What goes wrong:** Plan reads CONTEXT.md D-23 literal "`EXISTS LIMIT 10001`" and translates to `SELECT EXISTS(SELECT 1 FROM ... LIMIT 10001)`, which returns a boolean. LV gets `true`/`false` instead of a count; the threshold dispatch and the "10,000+" approximation both break.
**Why it happens:** D-23 used "EXISTS" as a colloquial shorthand for "stop after N rows", not the SQL keyword.
**How to avoid:** **Use the windowed-count subquery shape** — `SELECT count(*) FROM (... LIMIT N) sub`. This returns the actual count when below `N` and `N` when at the cap. Document the SQL in the lib helper's `@doc` so future readers don't regress to `EXISTS`.
**Warning signs:** "10,000+" banner shows up for windows with 5 rows; truncation banner never shows for huge windows.

### Pitfall 9: PR #2611 needs the `download` attribute, not just `Content-Disposition`

**What goes wrong:** Plan writes `<.link href={…}>Download CSV</.link>` (no `download` attribute) and trusts `Content-Disposition: attachment` to keep the LV socket alive. PR #2611 specifically checks the HTML `download` attribute at the JS layer; without it, `wantsNewTab()` may return false, the LV socket tears down, and the operator loses scroll/filter state mid-download (the exact problem D-15 was designed to avoid).
**Why it happens:** CONTEXT.md D-15 mentions both; plan author picks one.
**How to avoid:** **Always use `<.link href={…} download>` (both server-side header AND client-side attribute).** Doc-contract test asserts `download>` literal in TimelineLive source.
**Warning signs:** LV reconnects observed in browser dev tools after every download click.

### Pitfall 10: Optional-deps gating drift between files

**What goes wrong:** Author wraps `export_controller.ex` in `if Code.ensure_loaded?(Phoenix.Controller) do … end` correctly, but accidentally also wraps `exports/filename.ex` (no Phoenix dep needed) — making it conditionally compile. A capture-only adopter never gets the helper; a future Mix-task adopter that imports it (per the Deferred Idea about Mix-task auto-name parity) gets a `Code.ensure_loaded?` failure.
**Why it happens:** Cargo-cult application of the file-scope gate everywhere under `operator_surface/`.
**How to avoid:** **Plans must specify per-file gating intent.** `export_controller.ex` and `export_auth_plug.ex` gate on `Phoenix.Controller`; `exports/filename.ex` does NOT gate (pure stdlib); router.ex stays gated on `Phoenix.LiveView` (existing — emits `live/3`). Doc-contract test asserts each file's first line matches the right gate (or absence thereof).
**Warning signs:** `mix verify.compile_no_optional` passes but `mix compile` fails for a Mix-task-only adopter.

### Pitfall 11: `actor_kind` URL param uses `String.to_atom` (atom-table leak)

**What goes wrong:** Controller's filter parser does `String.to_atom(actor_kind)` instead of `String.to_existing_atom/1`. An adversary-reachable controller (export endpoint is HTTP-side, more exposed than the LV) can craft `?actor_kind=arbitrary_xyz_atom_1234567890` URLs, leaking atoms from the BEAM atom table (16 MiB default limit).
**Why it happens:** Convenience; the LV's existing `safe_actor_kind/1` (timeline_live.ex:387-393) already uses `to_existing_atom`, but the controller is a new file and may regress.
**How to avoid:** Shared `FilterParams` module (Pitfall 3) inherits the LV's `safe_actor_kind` shape. Doc-contract test greps `String.to_atom` in controller/plug/filter-params source and `flunk`s if found.
**Warning signs:** Burp/security scanner flags atom-leak vector.

## Validation Architecture

> Required for Nyquist Dimension 8 (`workflow.nyquist_validation` is enabled by default).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.15+ stdlib) |
| Config file | `test/test_helper.exs` (existing) |
| Quick run command | `mix test test/threadline/operator_surface/exports_doc_contract_test.exs --max-failures 1` |
| Full suite command | `mix ci.all` (runs `verify.format`, `verify.credo`, `compile --warnings-as-errors`, `verify.compile_no_optional`, `verify.test`, `verify.threadline`, `verify.example`, `verify.doc_contract`) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EXPO-03 | Three download anchors render in TimelineLive `.button-cluster` with correct hrefs | doc-contract + LV unit | `mix test test/threadline/operator_surface/exports_doc_contract_test.exs` + `mix test test/threadline/operator_surface/live/timeline_live_test.exs` | ❌ Wave 0 (new) + EXTEND |
| EXPO-03 | `<.link>` includes `download` attribute (PR #2611 contract) | doc-contract | `mix test test/threadline/operator_surface/exports_doc_contract_test.exs` | ❌ Wave 0 |
| EXPO-03 | Controller endpoint returns 200 for valid filter params | controller integration | `mix test test/threadline/operator_surface/controllers/export_controller_test.exs` | ❌ Wave 0 |
| EXPO-03 | Controller re-validates via `validate_timeline_filters!/1` (returns 422 on bad input) | controller integration | `mix test test/threadline/operator_surface/controllers/export_controller_test.exs` (the "GET with invalid filter key" case) | ❌ Wave 0 |
| EXPO-03 | Controller authorizes via `:export_authorize_fn` opt (default = adapter wrapping `:authorize_fn`) | plug unit + controller integration | `mix test test/threadline/operator_surface/export_auth_plug_test.exs` + a denying-auth Endpoint variant in controller test | ❌ Wave 0 |
| EXPO-03 | Auth denial returns 403 with `:denied` telemetry event | plug unit | `mix test test/threadline/operator_surface/export_auth_plug_test.exs` | ❌ Wave 0 |
| EXPO-04 | Pre-flight `count_matching/2` runs in parallel with `timeline_page/2` | LV unit | `mix test test/threadline/operator_surface/live/timeline_live_test.exs` (new case asserting `:match_count` assign) | ❌ EXTEND |
| EXPO-04 | Status line renders "Showing N of M matches in this window" with formatted count | LV unit | `mix test test/threadline/operator_surface/live/timeline_live_test.exs` (new case) | ❌ EXTEND |
| EXPO-04 | Truncation banner band 1 (informational) renders at count > 5_000 | LV unit | `mix test test/threadline/operator_surface/live/timeline_live_test.exs` (new case, seed 5_001 rows) | ❌ EXTEND |
| EXPO-04 | Truncation banner band 2 (warning) renders at count >= 10_001 | LV unit | `mix test test/threadline/operator_surface/live/timeline_live_test.exs` (new case, seed 10_001 rows) | ❌ EXTEND (overlaps slow seeding) |
| EXPO-04 | Iodata path: count <= 5_000 → `send_resp(200, iodata)` | controller integration | `mix test test/threadline/operator_surface/controllers/export_controller_test.exs` | ❌ Wave 0 |
| EXPO-04 | Chunked path: count > 5_000 → `send_chunked(200)` + `chunk/2` per batch | controller integration (D-27) | `mix test test/threadline/operator_surface/controllers/export_controller_test.exs` (the >5k case, seeds 5_001 rows) | ❌ Wave 0 |
| EXPO-04 | Chunked path is capped at 10_000 rows (parity with iodata `:max_rows`) | controller integration | `mix test test/threadline/operator_surface/controllers/export_controller_test.exs` (seed 10_500 rows, assert response has 10_000 + header) | ❌ Wave 0 |
| EXPO-04 | Filenames are UTC-ISO minute granularity per format | doc-contract + filename unit | `mix test test/threadline/operator_surface/exports/filename_test.exs` + `mix test test/threadline/operator_surface/exports_doc_contract_test.exs` | ❌ Wave 0 |
| EXPO-04 | `Content-Disposition` header has `attachment; filename="…"; filename*=UTF-8''…` shape (RFC 5987) | controller integration | `mix test test/threadline/operator_surface/controllers/export_controller_test.exs` | ❌ Wave 0 |
| EXPO-04 | `Content-Type` literals are `text/csv; charset=utf-8`, `application/json; charset=utf-8`, `application/x-ndjson; charset=utf-8` | doc-contract + controller integration | both | ❌ Wave 0 |
| EXPO-04 | RFC 4180 CSV (no BOM, `\r\n` separators) | controller integration | `mix test test/threadline/operator_surface/controllers/export_controller_test.exs` (assert no `\xEF\xBB\xBF` prefix; lines split on `\r\n`) | ❌ Wave 0 |
| EXPO-04 | JSON wrapped + NDJSON variants match Mix-task `--json-format` flag values | parity | `mix test test/threadline/operator_surface/exports_mix_parity_test.exs` (3 cases) | ❌ Wave 0 |
| EXPO-04 | Degraded count: window with > 10_000 rows returns count = 10_001 (cap), LV renders "10,000+" | controller integration + LV unit | both | ❌ Wave 0 + EXTEND |
| EXPO-04 | Empty window returns 200 with header-only CSV (RFC 4180 valid) | controller integration | `mix test test/threadline/operator_surface/controllers/export_controller_test.exs` | ❌ Wave 0 |
| EXPO-05 | Doc-contract test pins button labels: `"Download CSV"`, `"Download JSON"`, `"Download NDJSON"` | doc-contract | `mix test test/threadline/operator_surface/exports_doc_contract_test.exs` | ❌ Wave 0 |
| EXPO-05 | Doc-contract test pins filename pattern via `Filename.for/2` outputs | doc-contract | same | ❌ Wave 0 |
| EXPO-05 | Doc-contract test pins content-type literals | doc-contract | same | ❌ Wave 0 |
| EXPO-05 | Doc-contract test pins route literals (`/changes.csv` etc.) | doc-contract | same | ❌ Wave 0 |
| EXPO-05 | Doc-contract test pins filter-key parity with `Threadline.Query.@allowed_timeline_filter_keys` | doc-contract | same (regex over `query.ex` source — same shape as BROWSE-04) | ❌ Wave 0 |
| EXPO-05 | Focused chunked-stream integration test (D-27) | controller integration | `mix test test/threadline/operator_surface/controllers/export_controller_test.exs` (the >5k case) | ❌ Wave 0 |
| EXPO-05 | Mix task vs controller byte-equality across all three formats | parity | `mix test test/threadline/operator_surface/exports_mix_parity_test.exs` | ❌ Wave 0 |
| EXPO-05 | `mix verify.compile_no_optional` stays green | CI invariant | `mix verify.compile_no_optional` | ✅ existing alias |
| EXPO-05 | `:authorize_fn` LV contract is FROZEN (signature unchanged) | doc-contract | the existing `auth.ex` doc-contract test (if present) + a new assertion that `:authorize_fn` opt arity stays 1 in `router.ex` | ✅ partial |

### Sampling Rate

- **Per task commit:** `mix test --max-failures 1 path/to/specific_test.exs` (subset for the file the task touches)
- **Per wave merge:** `mix test test/threadline/operator_surface/` (full operator-surface subtree)
- **Phase gate:** `mix ci.all` green before `/gsd-verify-work` (note: pre-existing repo-wide `mix verify.format` drift in untouched files outside Phase 65 scope is a known blocker scheduled for Phase 68; do NOT format unrelated files in this phase)

### Wave 0 Gaps

- [ ] `lib/threadline/operator_surface/controllers/export_controller.ex` — NEW file, gated on `Phoenix.Controller`
- [ ] `lib/threadline/operator_surface/export_auth_plug.ex` — NEW file, gated on `Phoenix.Controller`
- [ ] `lib/threadline/operator_surface/exports/filename.ex` — NEW file, NOT gated (pure stdlib)
- [ ] `lib/threadline/operator_surface/exports/filter_params.ex` — NEW file (recommended), shared parser extracted from TimelineLive
- [ ] `test/threadline/operator_surface/controllers/export_controller_test.exs` — NEW; nested test-Endpoint shape (mirror timeline_live_test.exs:1-60)
- [ ] `test/threadline/operator_surface/export_auth_plug_test.exs` — NEW; unit tests for the plug
- [ ] `test/threadline/operator_surface/exports/filename_test.exs` — NEW; pure-function unit tests
- [ ] `test/threadline/operator_surface/exports_doc_contract_test.exs` — NEW; regex over source, mirrors BROWSE-04
- [ ] `test/threadline/operator_surface/exports_mix_parity_test.exs` — NEW; uses `Mix.Task.rerun/2` + `Phoenix.ConnTest`
- [ ] Modify `lib/threadline/export.ex` — add `:cap` opt to `count_matching/2` (windowed-count subquery)
- [ ] Modify `lib/threadline/operator_surface/router.ex` — grow macro to emit sibling `scope "/exports"` with inline `plug` + new opts
- [ ] Modify `lib/threadline/operator_surface/live/timeline_live.ex` — append three download anchors, add status line + truncation banner, `Task.async` parallel count + page in `handle_params/3`, assign `:match_count` and `:filter_query`
- [ ] Modify `lib/threadline/operator_surface/style.ex` — add `.export-cluster`, `.match-count-status`, `.truncation-banner.informational`, `.truncation-banner.warning` rules
- [ ] Extend `test/threadline/operator_surface/live/timeline_live_test.exs` — new cases for download hrefs, count status line, truncation bands

## Project Constraints (from CLAUDE.md)

- **Three-layer model**: Phase 65 is exploration/operations layer (LV render + HTTP controller). Capture and semantics layers are untouched. The new `:cap` opt on `count_matching/2` lives in `Threadline.Export` (operations-layer surface) and reads through `Threadline.Query.timeline_query/1` (semantics layer) — does not modify capture or semantics.
- **Domain language**: AuditChange is the row type the export streams; AuditTransaction is joined for `tx_occurred_at`/`tx_actor_ref`/`tx_source` columns; AuditAction is left-joined when `:correlation_id` is absent for action metadata. Phase 65 does not introduce any new domain entity.
- **Build & dev commands**: Use `mix verify.format`, `mix verify.credo`, `mix verify.test`, `mix verify.compile_no_optional`, `mix ci.all`. Cite these verbatim in plan-checker outputs.
- **OSS DNA**: Named entrypoints (`mix verify.*` / `mix ci.*`); honest default tests (do NOT add `:slow` to default exclude list); stable CI job IDs (no Phase 65 CI changes expected); doc-contract tests align README/guides/example-app.
- **GSD positional args** for `gsd-sdk query state.begin-phase` — flag-style invocations corrupt STATE.md.
- **Capture mechanism TBD**: Phase 65 does not touch capture; no Carbonite-vs-alternative concern here.
- **Read-only ceiling**: Phase 65 has zero writes to `audit_changes` / `audit_transactions` / `audit_actions`. Plans must not introduce a "save export" / "log this export was downloaded" feature without a separate phase.
- **No SIEM, no event sourcing**: No new dependencies; no Oban; no pgaudit replacement.
- **Optional-Phoenix-deps invariant**: `mix verify.compile_no_optional` MUST stay green. New controller + plug files gate on `Phoenix.Controller`; new filename helper does NOT gate (pure stdlib).

## Open Questions

### O-1: Chunked-path row-formatting helper extraction

**What:** The chunked path (`send_chunked` + `chunk/2` per batch) needs to project each `AuditChange` struct into the same iodata shape that `to_csv_iodata/2` and `to_json_document/2` produce per-row. Today, those projections live in PRIVATE helpers `csv_row/2` (lib/threadline/export.ex:220-250) and `change_map/1` (lib/threadline/export.ex:252-284) inside `Threadline.Export`.

**Two options for the planner:**

| Option | Description | Tradeoff |
|--------|-------------|----------|
| O-1a | Extract `csv_row/2` and `change_map/1` to public API (e.g. `Threadline.Export.csv_row/2`, `Threadline.Export.change_map/1`) and have the chunked path reuse them per batch. | Adds public surface — future format changes become breaking. Cleanest separation. |
| O-1b | Keep helpers private; chunked-path implementation calls `Threadline.Export.to_csv_iodata/2` per batch (with `repo: nil` and a custom row-list)... | Requires `to_csv_iodata/2` to optionally accept pre-fetched rows (new opt), fragile. |
| O-1c | Add a new `Threadline.Export.stream_csv_chunks/2` that returns `Enumerable.t()` of CSV iodata chunks (header + N data chunks); chunked path consumes via `Stream.into/2` → `chunk/2`. Mirror for `stream_json_chunks/2` (NDJSON only — wrapped JSON has a single `[…]` envelope that doesn't chunk cleanly). | Cleanest API surface (lib owns both end-to-end CSV/NDJSON shapes); but more lib changes. |

**Recommendation:** Defer to planning. O-1a is the smallest-blast-radius change for Phase 65; revisit O-1c if a Phase 66+ requirement surfaces a new chunked-shape consumer. **Document the chosen option in the plan and pin it in the doc-contract test (assert which Threadline.Export functions appear in export_controller.ex source).**

### O-2: Wrapped-JSON chunked-path correctness

**What:** The wrapped JSON shape is one outer object: `{"format_version": 1, "generated_at": "...", "changes": [ … ]}`. Chunking the inner `changes` array is straightforward but the surrounding `{"format_version": 1, …, "changes": [` prefix and `]}` suffix must be sent as fixed first/last chunks. NDJSON chunks naturally (one JSON object per line, no envelope).

**Options:**

| Option | Description |
|--------|-------------|
| O-2a | Wrapped JSON chunked-path emits the prefix as the first `chunk/2` call, then NDJSON-style per-row chunks comma-separated, then the suffix as the last `chunk/2` call. Possible but tedious; comma-handling edge case for the FIRST and LAST element in `changes` array. |
| O-2b | Wrapped JSON above 5k uses an iodata path (just bigger iodata) — only NDJSON and CSV use the chunked path. Sacrifices D-24's clean threshold rule for one format. |
| O-2c | Wrapped JSON above 5k is force-converted to NDJSON in the response (Content-Type stays `application/json` per RFC 8259, but the body is line-delimited). Breaks parity with Mix task; unacceptable. |

**Recommendation:** **O-2a (full chunking with explicit prefix/suffix).** Wrapped JSON is a valid streaming shape if you commit to the prefix/comma/suffix bookkeeping. The doc-contract test cannot easily assert this (byte-level structural correctness over a chunked transport); rely on the parity test (D-28) to prove byte-equality with the Mix-task wrapped-JSON output. **Document chosen option in plan; add a unit test that constructs a 5k+ row wrapped-JSON response and asserts `Jason.decode!(response_body)` succeeds.**

### O-3: The "303 redirect" wording in REQUIREMENTS.md EXPO-03 vs CONTEXT.md D-15 (plain anchor)

**What:** REQUIREMENTS.md EXPO-03 says *"clicking either redirects (HTTP 303) to a Phoenix controller endpoint"*. CONTEXT.md D-15 supersedes this with a plain `<.link href download>` GET — no 303 redirect. The "303" wording was an early-thinking framing where the LV would `phx-click` → `redirect/2` → controller redirect chain.

**Recommendation:** CONTEXT.md is the controlling artifact. The "303" wording in REQUIREMENTS.md is stale; the plain-GET path is functionally equivalent (operator clicks an anchor; browser sends GET; controller responds with the file). Plan should reference D-15 explicitly when this asymmetry is challenged. **Plan-checker should accept the plain-anchor pattern as fulfilling EXPO-03.**

### O-4: Whether `:cap` opt belongs on `Threadline.Export.count_matching/2` or a new `Threadline.Health.match_count_capped/2`

**What:** The capped-count is fundamentally a health/operations concern (it's about NOT bringing down the DB); arguably it belongs in `Threadline.Health`. But the call site is `Threadline.Export.count_matching/2` (used by both Mix task and controller); a new module forces the controller to call two functions instead of one.

**Recommendation:** **Keep `:cap` as an additive opt on `Threadline.Export.count_matching/2`.** The Mix task remains unaffected (default unbounded); the controller and LV pass `cap: 10_001`. A new module is over-engineering for a single SQL flourish. **Document in plan; doc-contract test could assert `count_matching` retains `{:ok, %{count: …}}` shape.**

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Phase 65 build | ✓ | 1.15+ (mix.exs:26) | — |
| Erlang/OTP | Phase 65 runtime | ✓ | bundled | — |
| PostgreSQL | Test DB for chunked-integration test | ✓ (per CLAUDE.md / docker-compose presumed) | 12+ | — |
| `mix` | Verification entrypoints | ✓ | bundled | — |
| `phoenix` (optional dep) | Controller compile | ✓ in dev/test | `~> 1.7` (mix.exs:57) | Capture-only adopters compile cleanly via D-21 file gate |
| `phoenix_live_view` (optional dep) | LV render + PR #2611 fix | ✓ in dev/test | `~> 1.0` (mix.exs:58) — well above PR #2611 fix line | Capture-only adopters compile cleanly |
| `Plug` | `send_chunked/2`, `chunk/2`, `put_resp_header/3` | ✓ | `~> 1.15` (mix.exs:55) — HARD dep | — |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None.

## Sources

### Primary (HIGH confidence)

- `lib/threadline/export.ex:71, 108, 151, 184` — `to_csv_iodata/2`, `to_json_document/2`, `count_matching/2`, `stream_changes/2` API confirmations.
- `lib/threadline/query.ex:36, 138, 290` — `@allowed_timeline_filter_keys`, `validate_timeline_filters!/1`, `timeline_page/2`.
- `lib/threadline/operator_surface/router.ex:1-50` — `threadline_operator_surface/2` macro current shape.
- `lib/threadline/operator_surface/auth.ex:1-65` — LV-side auth contract that `ExportAuthPlug` mirrors.
- `lib/threadline/operator_surface/live/timeline_live.ex:264-356` — Phase 64's filter-param parser (extract to `FilterParams` per Pitfall 3).
- `lib/threadline/plug.ex:1-155` — Conn-shaped callback precedent (`:actor_fn`, `:context_overrides_fn`).
- `lib/mix/tasks/threadline.export.ex:67, 73-93` — `count_matching` destructure pattern; flag→opt mapping byte-equality target.
- `lib/threadline/semantics/actor_ref.ex:24, 35-52` — fixed enum and `new/2` return shapes.
- `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs` — doc-contract regex pattern (BROWSE-04).
- `test/threadline/operator_surface/live/timeline_live_test.exs:1-80` — nested test-Endpoint pattern for `Phoenix.LiveViewTest` (reuse for `Phoenix.ConnTest`).
- `test/support/data_case.ex` — `async: false` + `Repo.delete_all` cleanup (NOT SQL Sandbox).
- `test/mix/tasks/threadline/export_test.exs:1-40` — Mix-task-in-test idiom with `capture_io/1`.

### Secondary (MEDIUM confidence — Context7-equivalent verification via WebFetch on official docs)

- [hexdocs.pm/plug/Plug.Conn.html#send_chunked/2](https://hexdocs.pm/plug/Plug.Conn.html#send_chunked/2) — `send_chunked/2` + `chunk/2` signatures and canonical `Enum.reduce_while/3` example.
- [hexdocs.pm/mix/Mix.Task.html](https://hexdocs.pm/mix/Mix.Task.html) — `Mix.Task.run/2` vs `rerun/2` vs `reenable/1` semantics.
- [hexdocs.pm/elixir/Task.html](https://hexdocs.pm/elixir/Task.html) — `Task.async/await` for two parallel calls.
- [hexdocs.pm/elixir/Calendar.html#strftime/2](https://hexdocs.pm/elixir/Calendar.html#strftime/2) — UTC strftime for filename helper.
- [hexdocs.pm/ecto/aggregates-and-subqueries.html](https://hexdocs.pm/ecto/aggregates-and-subqueries.html) — `from(sub in subquery(...))` shape for capped count.
- [github.com/phoenixframework/phoenix_live_view/pull/2611](https://github.com/phoenixframework/phoenix_live_view/pull/2611) — wantsNewTab() fix; merged 2023-05-12; respects HTML `download` attribute.
- [github.com/phoenixframework/phoenix_live_dashboard/blob/v0.8.4/lib/phoenix/live_dashboard/router.ex](https://github.com/phoenixframework/phoenix_live_dashboard/blob/v0.8.4/lib/phoenix/live_dashboard/router.ex) — `scope path, alias: false, as: false do …` macro pattern.
- [pganalyze.com/blog/5mins-postgres-limited-count](https://pganalyze.com/blog/5mins-postgres-limited-count) — capped count via `count(*) FROM (... LIMIT N)` subquery (NOT EXISTS LIMIT).
- [rfc-editor.org/rfc/rfc6266](https://www.rfc-editor.org/rfc/rfc6266) §4.3 — Content-Disposition `filename=` + `filename*=` dual-emit pattern.
- [rfc-editor.org/rfc/rfc5987](https://www.rfc-editor.org/rfc/rfc5987) §3.2.1 — `filename*=UTF-8''<percent-encoded>` ABNF.

### Tertiary (LOW confidence — flagged for verification)

- None — all critical claims cross-verified against official docs or in-tree source.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every API confirmed against `lib/` source or hexdocs.
- Architecture (controller + plug + macro composition): HIGH — patterns confirmed against LiveDashboard idiom + Phase 64 carry-forward + Threadline's own `Threadline.Plug` precedent.
- Pitfalls: HIGH — six of eleven pitfalls trace directly to existing source-code patterns (Pitfalls 2/3/5/6/8/10); the rest cross-verified against hexdocs.
- Validation Architecture: HIGH — every cell in the Phase Requirements → Test Map is a concrete `mix test path` with a specific assertion target.
- Open Questions: O-1 and O-2 are genuine planner-discretion items (lib API shape choices); O-3 and O-4 surface controlling-artifact ambiguities the planner needs to flag.

**Research date:** 2026-05-06
**Valid until:** 2026-06-05 (30 days — Phoenix LV 1.0.x and Plug 1.15.x are stable; PR #2611 status will not regress)

## RESEARCH COMPLETE
