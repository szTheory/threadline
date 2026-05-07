# Phase 65: Exports UI Parity - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Append `[Download CSV] [Download JSON] [Download NDJSON]` affordances to the existing Phase 64 `TimelineLive` toolbar. Each affordance is a plain anchor (`<.link href={…}>`) whose href is computed at render time from the LiveView's current filter assigns, pointing at a Phoenix controller endpoint mounted under the same `threadline_operator_surface` macro. The controller re-validates filter params via `Threadline.Query.validate_timeline_filters!/1`, re-authorizes via the `:export_authorize_fn` opt (defaults to a thin Conn-shaped adapter wrapping the existing `:authorize_fn`), and serves sync iodata below 5,000 rows or `Plug.Conn.send_chunked/2` + `Threadline.Export.stream_changes/2` above. A pre-flight match count (always-on, computed concurrently with `timeline_page` on every Apply) renders above the timeline with a two-band truncation banner. Filenames use UTC-ISO format with RFC 5987 `Content-Disposition`. Files produced for identical filters are byte-identical to `mix threadline.export` output. Read-only. No new auth, no Oban, no scheduled exports.

</domain>

<decisions>
## Implementation Decisions

### Click Mechanism

- **D-15: Plain `<.link href={…}>` anchor — NOT a `phx-click` event handler.** Each download button is `<.link href={"#{@base_path}/exports/changes.csv?#{@filter_query}"}>Download CSV</.link>`. Browser handles the GET; `Content-Disposition: attachment` keeps the operator on the LV. Phoenix LiveView PR #2611 fixed `wantsNewTab()` so anchors with `download=`/`Content-Disposition: attachment` no longer tear down the LV socket. `phx-click` → `redirect(socket, external: …)` is the documented footgun: the LV process tears down, scroll/cursor/filter state is lost mid-export. Datadog Audit Trail, Sentry Discover Export, and GitHub Audit Log all serve "Download CSV" via plain GET.
- **D-22: Three affordances total** — `[Download CSV]`, `[Download JSON]` (wrapped, default), `[Download NDJSON]`. EXPO-04 explicitly requires NDJSON parity with the Mix task; the Mix task exposes the choice via a `--json-format` flag, and the UI's analog of a flag is a separate visible affordance, not a hidden URL param or a checkbox. Cluster grows from `[Clear all] [Apply]` (Phase 64) → `[Clear all] [Apply] [Download CSV] [Download JSON] [Download NDJSON]`. Filename extensions: `.csv`, `.json`, `.ndjson`.

### Match-Count Pre-flight (EXPO-04)

- **D-16: Always-on, computed concurrently with `timeline_page` on every Apply.** In `handle_params`, run `Threadline.Export.count_matching/2` and `Threadline.Query.timeline_page/2` **in parallel** (`Task.async_stream/3` or two parallel `Repo` calls) so total latency is `max(count, page)`, not `sum`. Cache the count in socket assigns. Apply is already a deliberate, debounced action; one extra round-trip on the same join/index path is negligible. GitHub Audit Log, Datadog Logs Explorer, BigQuery preflight, and Oban Web all surface match counts always, on every filter change.
- **D-17: Count appears above the timeline as a status line** — *"Showing 50 of 3,142 matches in this window."* Not in the toolbar (crowds the action cluster), not in the surface header (detaches from the timeline it describes). The count is a property of the result set, not of the export action — operators get a filter-correctness signal during browsing, and the truncation banner has a stable visual home.
- **D-18: Two-band truncation banner.**
  - Count > 5,000 (informational, neutral color): *"Large export — will stream in chunks."*
  - Count > 10,000 (warning, amber): *"Truncated to first 10,000 rows. Use `mix threadline.export --max-rows N` for the full window."*
  - Distinct visual weight per band — chunked is transport, truncation is data-loss-adjacent. The two thresholds have *different remedies* (wait longer vs switch to Mix task); collapsing them deprives the operator of the one piece of information that changes their next action.
- **D-23: Degraded-count fallback for huge unfiltered windows.** If `count_matching/2` would exceed `statement_timeout` on a multi-million-row table, degrade to `"10,000+ matches"` via an `EXISTS`-with-`LIMIT 10001` capped pattern rather than erroring the LV. Implementation detail: planner picks the exact mechanism (a separate library API or a Repo-level cap inside the count helper) — but the operator-visible behavior is "always-on, never errors, may show approximation".

### Controller Routing + Auth

- **D-19: Same `threadline_operator_surface` macro emits both LV routes and a controller scope.** The macro grows a sibling scope inside the same `path` block:
  ```elixir
  scope unquote(path), alias: ... do
    live_session :threadline, on_mount: [...] do
      live "/", TimelineLive, :index
      ...
    end

    scope "/exports" do
      pipe_through :threadline_export_auth   # generated plug
      get "/changes.csv", ExportController, :csv
      get "/changes.json", ExportController, :json
      get "/changes.ndjson", ExportController, :ndjson
    end
  end
  ```
  Adopters keep the v1.17 one-line mount contract intact — exports just appear under the same path. Add `:exports` boolean opt (default `true`) so the rare LV-only adopter can disable. Note: `live_session`-level `on_mount` does NOT apply to `get/3` routes — the controller scope needs its own auth pipeline (D-20).
- **D-20: New `:export_authorize_fn` opt; default = thin Conn-shaped adapter wrapping the existing `:authorize_fn`.** **Preserve the v1.17 `:authorize_fn.(socket)` contract verbatim — DO NOT widen it to `(socket | conn)`.** The macro generates a plug `Threadline.OperatorSurface.ExportAuthPlug` that:
  1. If `:export_authorize_fn` is provided, calls it with `conn` directly.
  2. Otherwise, builds a synthetic `%{assigns: conn.assigns}` map mirror and calls the existing `:authorize_fn`. Document this contract: most adopter functions only access `assigns.current_user` or similar, so the mirror is sufficient.
  3. Maps `false` / `{:error, _}` / `:error` returns to a 403 (or whatever the existing v1.17 `Threadline.OperatorSurface.Auth` halt strategy uses for parity); `:ok` and `{:ok, scope}` returns assign the scope onto `conn.assigns[:threadline_scope]` (parity with the LV `on_mount`).
  Mirrors the in-house precedent at `lib/threadline/plug.ex` (`:actor_fn`, `:context_overrides_fn`) — Threadline already ships separate Conn-shaped callbacks for HTTP-side integration.
- **D-21: File-scope gating — `Code.ensure_loaded?(Phoenix.Controller)`** on the new controller file (`lib/threadline/operator_surface/controllers/export_controller.ex`) and on the new auth plug file (`lib/threadline/operator_surface/export_auth_plug.ex`). NOT gated on LiveView — the controller depends only on `Phoenix.Controller`/`Plug`. The macro file (`router.ex`) stays gated on LiveView since it emits `live/3` calls. `mix verify.compile_no_optional` stays trivially green: each file matches the actual dep used in that file.

### Stream-vs-iodata Dispatch

- **D-24: Threshold compare lives in the controller action, not in `Threadline.Export`.** Sequence per request:
  1. `Threadline.Query.validate_timeline_filters!/1` (raises → render 422 with the message).
  2. `Threadline.Export.count_matching/2` (defends `send_chunked` from opening before the count is known).
  3. If `count <= 5_000`: build full iodata via `Threadline.Export.to_csv_iodata/2` or `to_json_document/2`, call `send_resp(conn, 200, iodata)` with the right headers.
  4. If `count > 5_000`: `send_chunked(conn, 200)` with headers, then `Threadline.Export.stream_changes/2` |> `Stream.chunk_every(500)` |> `Enum.reduce_while/3` calling `chunk(conn, iodata)`. Halt on error.
  5. Truncation at 10,000 is the lib's existing `:max_rows` default — controller forwards `max_rows: 10_000` explicitly to `stream_changes` via `Stream.take/2` for symmetry with the iodata path.
- **D-25: Filename helper is a new module, not inlined.** Add `Threadline.OperatorSurface.Exports.Filename` exposing `for(format, datetime)` returning `"threadline-changes-2026-05-06T12-00Z.csv"`. Pure function, easy to doc-contract test, and the Mix task could adopt it later for parity (currently it lets the user pass `--output PATH` so it doesn't format filenames itself; if/when the Mix task gains an "auto-name" mode, both surfaces share the helper). Datetime granularity is **minute** (not second) — matches EXPO-04's literal example `2026-05-06T12-00Z`.

### Doc-Contract Test (EXPO-05)

- **D-26: Doc-contract test asserts the locked literals as pure source-reading**, mirroring the BROWSE-04 doc-contract test pattern from Phase 64:
  - LiveView render output contains the exact button label literals (`"Download CSV"`, `"Download JSON"`, `"Download NDJSON"`).
  - Controller action constants for `Content-Type` literals (`"text/csv; charset=utf-8"`, `"application/json; charset=utf-8"`, `"application/x-ndjson; charset=utf-8"`).
  - Filename helper produces the canonical pattern (`"threadline-changes-YYYY-MM-DDTHH-MM-Z.{csv|json|ndjson}"`).
  - Router macro emits the `get "/exports/changes.{csv,json,ndjson}"` literals (parsed via `Code.string_to_quoted/1` + tree-walk, parity with BROWSE-04's literal pinning).
  - Mix-task / controller filter-key parity: the controller's filter-allowlist read via `Threadline.Query` is the same `@allowed_timeline_filter_keys` literal at `lib/threadline/query.ex:36`.
- **D-27: Focused integration test for the chunked-stream path** — seed >5,000 rows in a test fixture, hit `GET /audit/exports/changes.csv?from=…&to=…` via `Phoenix.ConnTest`, assert response is 200 with `Content-Type: text/csv; charset=utf-8` and `transfer-encoding: chunked` (or equivalent), assert the body parses as RFC 4180 CSV with header + N data rows. The exact seeding strategy is Claude's discretion (likely `ExUnit.Case` setup that inserts via Ecto in a transaction the test then truncates).
- **D-28: Parity test (Mix task vs controller produce identical bytes for identical filters).** Run both paths in the same test:
  1. `Mix.Tasks.Threadline.Export.run(["--format", "csv", "--output", tmp_path, "--from", iso_str, "--to", iso_str_2])`.
  2. `conn |> get("/audit/exports/changes.csv?from=...&to=...") |> response(200)`.
  3. `assert File.read!(tmp_path) == response_body`.
  Run for all three formats. Both surfaces ultimately call `Threadline.Export.{to_csv_iodata, to_json_document}/2` — this test proves the controller is a thin Plug wrapper, not a divergent reimplementation.

### Optional-Phoenix-deps Posture

- **D-29: `mix verify.compile_no_optional` stays green.** Capture-only adopter (no `:phoenix`, no `:phoenix_live_view`) compiles cleanly. LV-only adopter (`:phoenix_live_view` present, `:phoenix` present transitively) gets the controller for free. Hypothetical "Phoenix.Controller present, Phoenix.LiveView absent" adopter (rare but legal — Plug-only Phoenix host) gets the export endpoints without the LV — this is a side benefit of D-21, not a guaranteed adoption path.

### Claude's Discretion

- Exact CSS class names and visual styling for the count status line, truncation banners, and download cluster — extend `.threadline-ui` namespace + CSS-variable convention from `Threadline.OperatorSurface.Style`. No Tailwind, no JS framework.
- Exact button labels — must match doc-contract test literals (planner picks the literals, test pins them). Recommended: `"Download CSV"`, `"Download JSON"`, `"Download NDJSON"`.
- Exact wording of the chunked + truncation banners (terse, neutral tone, parity with existing TransactionLive empty-state copy).
- Exact location of the filename helper (`Threadline.OperatorSurface.Exports.Filename` is the recommended path, but Claude may rename if the namespace conflicts with a future home for shared export helpers).
- Pre-flight match-count integration test seeding strategy (must seed >5k rows for the chunked-path assertion).
- Exact strategy for the degraded-count fallback (D-23) — `EXISTS LIMIT 10001` cap, separate library helper, or `Repo`-level timeout retry — planner picks whichever is cleanest.
- Whether `include_action_metadata`, `max_rows`, or `csv` column-toggle UIs are exposed as URL knobs — recommend **NO** at this phase. Mix task itself doesn't surface `include_action_metadata`; `--max-rows` could be a `?max_rows=` knob with a sanity ceiling, but defer unless real adopters report pain. The doc-contract parity test catches drift if the Mix task ever exposes these flags.
- Phoenix-LiveView version constraint check — D-15 relies on PR #2611 (LiveView ≥ 1.0). The lib's existing optional-deps version range probably already covers this; confirm during research.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 65 contract + milestone scope

- `.planning/ROADMAP.md` §"Phase 65: Exports UI Parity" — phase goal, 4 success criteria, sequencing rationale (Phase 65 must come immediately after Phase 64; both halves of the filter contract must be on the same literal).
- `.planning/REQUIREMENTS.md` §"EXPO-03..05" — verbatim requirements:
  - EXPO-03 — Download buttons, 303 redirect to controller, re-validate via `validate_timeline_filters!/1`, re-authorize via `:authorize_fn` parity.
  - EXPO-04 — Pre-flight `count_matching/2`, chunked >5k, iodata <5k, UTC-ISO filenames, RFC 5987 `Content-Disposition`, RFC 4180 CSV with `text/csv; charset=utf-8` no BOM, JSON wrapped + NDJSON variants matching `mix threadline.export` flags.
  - EXPO-05 — Doc-contract test pins button labels + filename format + content-type literals; focused integration test for chunked path; parity assertion (Mix task and controller produce identical files for identical filters).
- `.planning/REQUIREMENTS.md` §"Out of Scope (explicit exclusions for v1.18)" — read-only ceiling, no Oban exports, no email-when-ready, no scheduled exports.
- `.planning/PROJECT.md` §"Current Milestone: v1.18" — strategic framing.
- `.planning/STATE.md` §"Accumulated Context" — v1.18 scoping rationale, optional-Phoenix-deps invariant.

### Phase 64 carry-forward (URL contract + toolbar shape are LOCKED)

- `.planning/phases/64-raw-timeline-browse-and-filter-form/64-CONTEXT.md` — full Phase 64 context.
- `64-CONTEXT.md` §"Canonical URL Contract" — locked verbatim:
  ```
  GET /audit/exports/changes.csv?from=…&to=…&table=…&actor_kind=…&actor_id=…&correlation_id=…
  ```
  Same allowlist as `validate_timeline_filters!/1`. `actor_kind` + `actor_id` collapse to a single `:actor_ref` keyword before validation. Empty params omitted. `actor_kind=anonymous` strips id.
- `64-CONTEXT.md` D-03 — toolbar action cluster. Phase 65 appends three download affordances to the right of `[Apply]`.
- `64-CONTEXT.md` D-10 — validation reuses `Threadline.Query.validate_timeline_filters!/1` verbatim; UI errors caught from `try/rescue ArgumentError` wrapper.
- `.planning/phases/64-raw-timeline-browse-and-filter-form/64-VERIFICATION.md` — confirms BROWSE-01..04 shipped; the LV foundation Phase 65 builds on is verified.

### Library APIs the controller must call (and not duplicate)

- `lib/threadline/export.ex:71` — `Threadline.Export.to_csv_iodata/2`. Sync iodata path for count ≤ 5k. Returns `{:ok, %{data: iodata, truncated, returned_count, max_rows}}`.
- `lib/threadline/export.ex:108` — `Threadline.Export.to_json_document/2`. Same shape; takes `:json_format` (`:wrapped` | `:ndjson`).
- `lib/threadline/export.ex:151` — `Threadline.Export.count_matching/2`. Single `aggregate(:count, :id)` over the timeline join. Pre-flight + chunked-path dispatch input.
- `lib/threadline/export.ex:184` — `Threadline.Export.stream_changes/2`. Lazy keyset-paged Enumerable; chunked path consumes via `Stream.chunk_every` + `Plug.Conn.chunk/2`. Does NOT enforce `max_rows` — controller wraps in `Stream.take(10_000)` for parity with iodata path.
- `lib/threadline/query.ex:36` — `@allowed_timeline_filter_keys` literal. EXPO-05 doc-contract test asserts parity against this and against the controller's filter list.
- `lib/threadline/query.ex:130-155` — `Threadline.Query.validate_timeline_filters!/1`. Controller MUST call this verbatim — no UI-only filter dialect.
- `lib/threadline/semantics/actor_ref.ex` — `Threadline.Semantics.ActorRef.new/2` and the fixed kind enum. Controller collapses `actor_kind` + `actor_id` query params to `:actor_ref` keyword exactly the way Phase 64's `TimelineLive.collapse_actor_ref/1` does.

### Mix task parity (EXPO-05 byte-equality target)

- `lib/mix/tasks/threadline.export.ex:1-174` — `Mix.Tasks.Threadline.Export`. The byte-equality target. Both Mix task and controller end up calling `Threadline.Export.{to_csv_iodata, to_json_document}/2` with identical opts derived from identical filters. Note: Mix task does NOT format filenames (takes `--output PATH`); controller-side filename helper is new.
- `lib/mix/tasks/threadline.export.ex:73-93` — flag → opt mapping (`--format`, `--json-format`, `--max-rows`). The controller's three endpoints map 1:1: `.csv` → `to_csv_iodata`, `.json` → `to_json_document(format: :wrapped)`, `.ndjson` → `to_json_document(format: :ndjson)`.

### v1.17 surface artifacts the new controller must integrate with

- `lib/threadline/operator_surface/router.ex:1-50` — `threadline_operator_surface` mount macro. Phase 65 grows a sibling controller scope inside the existing macro (D-19). Note the existing `:authorize_fn` / `:adopter_acknowledges_unauthenticated` validation logic — `:export_authorize_fn` follows the same opt-validation shape.
- `lib/threadline/operator_surface/auth.ex:1-65` — `Threadline.OperatorSurface.Auth.on_mount/4`. The LV-side auth contract. Phase 65's new `Threadline.OperatorSurface.ExportAuthPlug` mirrors this for HTTP requests: same `:granted` / `:denied` / `:error` telemetry events, same scope assign, same halt strategy.
- `lib/threadline/operator_surface/live/timeline_live.ex:165-242` — Phase 64 render block. Phase 65 edits this file to:
  1. Append the three download anchors to the `<div class="button-cluster">` block.
  2. Render the count status line + truncation banner above the timeline rows section.
  3. Run `count_matching/2` concurrently with `timeline_page/2` in `handle_params/3`.
- `lib/threadline/operator_surface/style.ex` — `.threadline-ui` CSS namespace + CSS-variable convention. Extend with `.export-cluster`, `.match-count-status`, `.truncation-banner` (informational + warning variants).
- `lib/threadline/plug.ex` — existing `Threadline.Plug` with `:actor_fn` / `:context_overrides_fn` Conn-shaped callbacks. Architectural precedent for `:export_authorize_fn` (separate Conn-shaped callback, distinct from LV-side `:authorize_fn`).

### Verification + CI invariants

- `mix verify.compile_no_optional` (Phase 57 alias) — must stay green. Both new files (`export_controller.ex`, `export_auth_plug.ex`) wrap in `if Code.ensure_loaded?(Phoenix.Controller) do … end` at file scope.
- EXPO-05 doc-contract test — to be added in this phase. Asserts: button label literals, filename helper output, content-type literals, route literals, filter-key parity.
- EXPO-05 chunked-stream integration test — seed >5k rows, hit `/audit/exports/changes.csv` via `Phoenix.ConnTest`, assert chunked-transfer body parses as RFC 4180.
- EXPO-05 parity test — Mix task output vs controller response body byte-equality across all three formats.

### Idiomatic peer projects (consult during planning if patterns are unclear)

- **Phoenix LiveView PR #2611** — `wantsNewTab()` fix for anchors with `download=` / `Content-Disposition: attachment`. Confirms D-15 is the post-fix idiom.
- **Phoenix LiveDashboard** (`phoenix_live_dashboard`) — `live_dashboard/2` macro emits LV routes only; `:on_mount` callback for auth. Threadline goes further by adding controller routes (deliberate — chunked CSV over an LV channel is a known anti-pattern).
- **phx.gen.auth's `UserAuth` module** — generates BOTH `fetch_current_user/2` (Plug) AND `on_mount/4` callbacks, sharing private helpers. The "extract auth kernel" pattern is idiomatic for apps; Threadline applies a thinner version (separate callback opts, not a shared module the host re-uses).
- **GitHub Audit Log** (`/settings/security-log`) — count appears as a status line above the result table on every filter change; export button is separate. Direct D-17 analog.
- **Datadog Audit Trail / Sentry Discover Export** — both serve "Download CSV" via plain GET to a controller endpoint with current filter state in the querystring. Direct D-15 analog.
- **Datadog Logs Explorer** — always-on event count with "10,000+ events" cap (approximation) when the true count is expensive. Validates D-23 degraded-count fallback.
- **BigQuery preflight** — pre-flight "this query will process X bytes" inline next to the action. Cost/scope previews must precede the click; validates D-16.
- **Oban Web** — "matching jobs" count rendered in toolbar/header on every filter Apply, no hover indirection. Closest Elixir-ecosystem precedent.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Threadline.Export.{to_csv_iodata,to_json_document,count_matching,stream_changes}/2` — full export library. Phase 65 controller is a thin Plug wrapper; lib does the heavy lifting.
- `Threadline.Query.validate_timeline_filters!/1` — single-source filter validation. Controller calls verbatim; no parallel UI dialect.
- `Threadline.Query.@allowed_timeline_filter_keys` — `lib/threadline/query.ex:36`. EXPO-05 doc-contract asserts parity.
- `Threadline.Semantics.ActorRef.new/2` — `actor_kind` + `actor_id` query params → `%ActorRef{}`. Controller reuses Phase 64's collapse logic shape.
- `Threadline.OperatorSurface.Auth` — LV-side auth contract; Phase 65's `ExportAuthPlug` mirrors its semantics (granted/denied/error telemetry, scope assign, halt strategy).
- `Threadline.OperatorSurface.Style.css/1` — CSS-variable themed `.threadline-ui` namespace. Extend with export-cluster + status-line + banner styles.
- `Threadline.Plug` — `:actor_fn` / `:context_overrides_fn` Conn-shaped callbacks. Architectural precedent for `:export_authorize_fn`.
- `Phoenix.Controller`, `Plug.Conn.send_chunked/2`, `Plug.Conn.chunk/2` — standard Phoenix HTTP primitives. No new deps.
- `<.link href={…}>` — already imported in `TimelineLive` for `[Clear all]`. Reuse for download affordances.
- `Mix.Tasks.Threadline.Export` — byte-equality target for EXPO-05 parity test. Same `Threadline.Export.*` calls, same opts.

### Established Patterns

- **File-scope optional-deps gating**: every operator-surface module starts with `if Code.ensure_loaded?(<dep>) do defmodule … end end`. New files: controller + auth plug both gate on `Phoenix.Controller`. `mix verify.compile_no_optional` enforces in CI.
- **CSS isolation**: every render block opens with `<div class="threadline-ui"><Threadline.OperatorSurface.Style.css /> …`. No layout component, no Tailwind utilities. Phase 65 extends the `.button-cluster` rule and adds `.match-count-status` + `.truncation-banner` rules.
- **Repo resolution**: `socket.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()` — same shape used throughout. Controller resolves identically (via `conn.assigns[:threadline_repo]` or app env).
- **Auth scope threading**: `:authorize_fn`-returned scope set on assigns by the on_mount / plug; investigation queries receive it through helper layer. New `ExportAuthPlug` follows same pattern.
- **Empty-state markup**: `<div class="empty-state"><p>…</p></div>` — terse copy, neutral tone. Phase 65 truncation banner uses parallel structure with role="status" (informational) or role="alert" (warning).
- **Doc-contract test posture**: pure source-reading tests (no LV bootup needed for literal pinning). BROWSE-04 in Phase 64 is the template for EXPO-05.

### Integration Points

- **Edit**: `lib/threadline/operator_surface/router.ex` — grow the macro to emit a sibling controller `scope` block + `:export_authorize_fn` opt-validation.
- **New file**: `lib/threadline/operator_surface/controllers/export_controller.ex` (`Phoenix.Controller`-gated). Three actions: `csv/2`, `json/2`, `ndjson/2`.
- **New file**: `lib/threadline/operator_surface/export_auth_plug.ex` (`Phoenix.Controller`-gated). Plug that calls `:export_authorize_fn` (or its default Conn-shaped adapter wrapping `:authorize_fn`).
- **New file**: `lib/threadline/operator_surface/exports/filename.ex` (no Phoenix deps; pure functions). `for(format, datetime)` helper.
- **Edit**: `lib/threadline/operator_surface/live/timeline_live.ex` — append three download anchors to `.button-cluster`; render count status line + two-band truncation banner above timeline rows section; run `count_matching` concurrently with `timeline_page` in `handle_params/3`.
- **Edit**: `lib/threadline/operator_surface/style.ex` — add `.export-cluster`, `.match-count-status`, `.truncation-banner.informational`, `.truncation-banner.warning` rules.
- **New file**: `test/threadline/operator_surface/controllers/export_controller_test.exs` — happy-path tests per format, chunked-stream integration test (>5k rows seeded), filter validation 422 response, auth denial 403 response.
- **New file**: `test/threadline/operator_surface/exports_doc_contract_test.exs` — pure source-reading test pinning button labels, filename helper output, content-type literals, route literals, filter-key parity.
- **New file**: `test/threadline/operator_surface/exports_mix_parity_test.exs` — byte-equality across all three formats (Mix task vs controller).
- **Edit**: `test/threadline/operator_surface/live/timeline_live_test.exs` — extend with assertions for the three new anchor hrefs at expected paths and for the count status line + truncation banner rendering.

</code_context>

<specifics>
## Specific Ideas

- **Idiomatic anchor (D-15)**: Phoenix LiveView PR #2611 + GitHub Audit Log + Datadog Audit Trail. The plain anchor IS the idiom post-fix; the controller is a thin Plug wrapper.
- **Status-line count (D-17)**: GitHub Audit Log "Showing 1-50 of 3,142 events" pattern. Threadline's variant keys off `@filters_raw` window context: *"Showing 50 of 3,142 matches in this window."*
- **Two-band truncation banner (D-18)**: Sentry events export precedent — chunked transport notice (informational) and truncation notice (warning) are surfaced separately.
- **Three buttons (D-22)**: Mix task = three callable shapes; UI = three visible affordances. Cluster: `[Clear all] [Apply] [Download CSV] [Download JSON] [Download NDJSON]`.
- **Auth dual-callback (D-20)**: matches Threadline's existing `Threadline.Plug` precedent (`:actor_fn` is Conn-shaped, separate from any LV equivalent). v1.17 contract stays frozen; one new opt is additive, not breaking.
- **Filename literal**: `threadline-changes-2026-05-06T12-00Z.{csv|json|ndjson}` — minute granularity per EXPO-04's literal example.
- **Banner colors**: chunked = neutral gray (informational), truncation = amber (warning, data-loss-adjacent). Distinct visual weight is mandatory; collapsing them deprives the operator of the info that changes their next action.

</specifics>

<deferred>
## Deferred Ideas

- **NDJSON-only progressive download** (start streaming immediately on click, no count pre-flight) — out of v1.18 scope. Phase 65 is parity with the Mix task, not a new export modality.
- **CSV column toggles / `include_action_metadata` UI checkbox** — Mix task itself doesn't expose `include_action_metadata` flag, so UI parity = no UI control. Revisit when a real adopter requests it; doc-contract parity test catches drift if the Mix task ever exposes it.
- **`?max_rows=N` URL knob with sanity ceiling** — out of Phase 65 scope; lib's 10k default + truncation banner is sufficient. Revisit if real adopters hit "I need exactly 7,500 rows" pain.
- **Saved exports / "schedule this export to email"** — already deferred to v1.20+ per REQUIREMENTS.md "Future Requirements" — Oban as a hard dep walks back the v1.17 optional-deps win.
- **Resume / partial-download recovery** — out of scope; chunked stream is one-shot.
- **Per-row "export this row" affordance** — out of scope; Phase 65 is window-shaped.
- **Async download with status page / "preparing your export, refresh in 30s"** — out of scope; Oban dep barrier.
- **Email-when-ready / signed-link-expiry exports** — already deferred indefinitely per REQUIREMENTS.md.
- **Auto-name "save as" for the Mix task to share `Threadline.OperatorSurface.Exports.Filename`** — possible but out of Phase 65 scope; the Mix task currently takes `--output PATH`. If the Mix task ever gains an auto-name mode, both surfaces share the helper for free.
- **Phase 66 forward-compat for the count surface header** — Phase 66's "uncovered count surfaced in the surface header" is its own surface; Phase 65's count belongs above the timeline, not in the header. Independent decisions.

### Reviewed Todos (not folded)

None — no `.planning/todos/` matches surfaced for Phase 65.

</deferred>

---

*Phase: 65-exports-ui-parity*
*Context gathered: 2026-05-06*
