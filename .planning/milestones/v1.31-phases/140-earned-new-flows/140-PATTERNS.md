# Phase 140: earned-new-flows - Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 12 target surfaces/tests
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/threadline/operator_surface/live/start_live.ex` | LiveView | request-response, navigation | `lib/threadline/operator_surface/live/start_live.ex` | exact |
| `test/threadline/operator_surface/live/start_live_test.exs` | test | request-response, navigation | `test/threadline/operator_surface/live/start_live_test.exs` | exact |
| `lib/threadline/operator_surface/live/timeline_live.ex` | LiveView | request-response, CRUD-ish filters | `lib/threadline/operator_surface/live/timeline_live.ex` | exact |
| `test/threadline/operator_surface/live/timeline_live_test.exs` | test | request-response, filters, scoping | `test/threadline/operator_surface/live/timeline_live_test.exs` | exact |
| `lib/threadline/operator_surface/live/row_history_live.ex` or route action in `transaction_live.ex` | LiveView | request-response, row lookup | `lib/threadline/operator_surface/live/transaction_live.ex` + `row_history_component.ex` | role-match |
| `test/threadline/operator_surface/live/row_history_live_test.exs` or `transaction_live_test.exs` additions | test | request-response, row lookup, scoping | `test/threadline/operator_surface/transaction_live_test.exs` | role-match |
| `lib/threadline/operator_surface/live/row_history_component.ex` | component | request-response, query/snapshot | `lib/threadline/operator_surface/live/row_history_component.ex` | exact |
| `test/threadline/operator_surface/row_history_component_test.exs` | test | request-response, scoped query | `test/threadline/operator_surface/row_history_component_test.exs` | exact |
| `lib/threadline/operator_surface/live/export_status_live.ex` | LiveView | request-response, status list | `lib/threadline/operator_surface/live/export_status_live.ex` | exact |
| `lib/threadline/operator_surface/controllers/export_controller.ex` | controller | request-response, file I/O/streaming | `lib/threadline/operator_surface/controllers/export_controller.ex` | exact |
| `lib/threadline/operator_surface/router.ex` | router macro | request-response route mounting | `lib/threadline/operator_surface/router.ex` | exact |
| `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` | browser E2E | request-response, seeded navigation | `operator-home-nav-mobile.spec.ts`, `operator-find-mobile.spec.ts`, `operator-prove-mobile.spec.ts` | role-match |

## Pattern Assignments

### `lib/threadline/operator_surface/live/start_live.ex` (Home controls/forms/navigation)

**Analog:** `lib/threadline/operator_surface/live/start_live.ex`

**Imports/base assigns pattern** (lines 5-12, 30-48):
```elixir
use Phoenix.LiveView
import Ecto.Query

alias Threadline.Governance.ExportJob
alias Threadline.Governance.RetentionRun
alias Threadline.Governance.SavedView
alias Threadline.OperatorSurface.Exports.FilterParams
```

Keep Home's base path model: `handle_params/3` treats the request path as the mount root and assigns `:base_path` (lines 39-48). New forms should navigate or patch relative to `@base_path`, not hard-code `/audit`.

**Header/navigation pattern** (lines 61-75, 98-140):
```elixir
<Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
  coverage={@threadline_coverage}
  base_path={@base_path}
  exports_enabled={@threadline_exports_enabled}
  current={:start}
  scoped={not is_nil(assigns[:threadline_scope])}
/>
```

Home cards use plain anchors for existing routes (`href={"#{@base_path}/timeline"}`, `href={"#{@base_path}/exports"}`), not route helpers. Add Phase 140 controls inside `tl-home` with `.tl-*` classes and preserve the topbar/scope/health layout.

**Saved/canonical link pattern** (lines 263-289):
```elixir
defp saved_view_path(base_path, view) do
  case FilterParams.canonical_query(view.filters || %{}) do
    "" -> "#{base_path}/timeline"
    query -> "#{base_path}/timeline?#{query}"
  end
end
```

Reuse `FilterParams.canonical_query/1` for correlation Home deep links and for allowed export carry-forward params. Do not build ad hoc query strings.

**Tests to extend:** `test/threadline/operator_surface/live/start_live_test.exs`

Useful existing assertions:
- Orientation links and anti-routes: lines 179-204.
- Actor-owned saved view canonical URLs: lines 264-299.
- Phase 139 currently refutes Phase 140 forms/source strings: lines 309-323. Phase 140 must replace/update this boundary test with positive tests for only the earned controls.
- Scoped Home affordance: lines 384-390.

### `lib/threadline/operator_surface/live/timeline_live.ex` (filters and correlation_id)

**Analog:** `lib/threadline/operator_surface/live/timeline_live.ex`

**Filter parse/validation/query pattern** (lines 77-180):
```elixir
socket = assign(socket, :filters_raw, FilterParams.filters_raw_from_params(params))

case FilterParams.parse(params) do
  {:error, message} -> assign(socket, :form_error, message)
  {:ok, filters} ->
    case safe_validate(filters) do
      :ok ->
        Query.timeline_page(filters, scope_aware_opts(socket))
    end
end
```

Use this same chain for Home correlation paste: raw params -> `FilterParams` allowlist/canonicalization -> `Threadline.Query.validate_timeline_filters!/1` through `safe_validate/1` semantics -> navigation to Timeline.

**Correlation input/selectors** (lines 399-405, 500-505, 592-599):
```elixir
<input type="text" name="filter[correlation_id]" id="filter-correlation-id"
       aria-label="correlation id"
       value={@filters_raw["correlation_id"] || ""}
       maxlength="256" phx-debounce="300" class="tl-toolbar__control" />
```

Rows expose correlation links via `correlation_path(@timeline_path, correlation_id)` and copy controls with `data-tl-copy`. Home correlation controls should preserve the 256-byte validation behavior and land on `/timeline?correlation_id=...`.

**Export carry-forward pattern** (lines 411-417, 245-271):
```elixir
<.link href={"#{@base_path}/exports/changes.csv?#{@filter_query}"} download>CSV</.link>
<button phx-click="request_background_export" type="button">Queue export</button>
```

`request_background_export` persists `ExportJob.query_params` from current filters and redirects to `#{base_path}/exports` (lines 245-271). Phase 140's closed loop should carry context into Export Status without redesigning export creation.

**Tests to extend:** `test/threadline/operator_surface/live/timeline_live_test.exs`

Useful existing cases:
- Default route canonicalizes bare `/audit/timeline`: lines 380-392.
- Submit builds canonical URL with `correlation_id`: lines 398-420.
- Pasted URL hydrates fields: lines 564-580.
- Unknown params dropped: lines 586-610.
- Correlation too long errors: lines 489-494.
- Download anchors include canonical filter state: lines 695-720.
- Scoped mount only shows allowed rows: lines 1030-1043.
- Queue export persists filter params and redirects: lines 1084-1125.
- Export controls hidden when export auth denies: lines 1182-1195.

### `lib/threadline/operator_surface/exports/filter_params.ex` (shared allowlist/canonical query)

**Analog:** `lib/threadline/operator_surface/exports/filter_params.ex`

**Allowed keys and atom safety** (lines 45-52, 96-112):
```elixir
@filter_key_atoms %{
  "from" => :from,
  "to" => :to,
  "table" => :table,
  "actor_kind" => :actor_kind,
  "actor_id" => :actor_id,
  "correlation_id" => :correlation_id
}

@canonical_key_order ~w(from to table actor_kind actor_id correlation_id)
```

All Phase 140 carry-forward contexts should be limited to these keys unless a new parser is deliberately added with tests. Existing tests assert `String.to_existing_atom` is used and `String.to_atom` is not.

**Tests to extend:** `test/threadline/operator_surface/exports/filter_params_test.exs`

Existing coverage:
- Correlation pass-through: lines 73-75.
- Table pass-through with validation elsewhere: lines 78-80.
- Allowlist and blank dropping: lines 13-21.
- Atom safety source contract: lines 108-112.

### First-class row-history route/live view

**Analog:** `lib/threadline/operator_surface/live/transaction_live.ex` + `lib/threadline/operator_surface/live/row_history_component.ex`

**Route-action pattern** (transaction lines 35-80, 202-214):
```elixir
if socket.assigns.live_action == :history do
  table = params["table"]
  record_id = params["record_id"]
  # parse optional as_of
  assign(socket, show_history: true, history_table: table, history_record_id: record_id)
end
```

For a first-class route, reuse the component invocation shape:
```elixir
<.live_component
  module={Threadline.OperatorSurface.Live.RowHistoryComponent}
  id="row-history"
  table={@history_table}
  record_id={@history_record_id}
  threadline_schemas={@threadline_schemas}
  repo={@threadline_repo}
  scope={@threadline_scope}
  scope_query_fn={@threadline_scope_query_fn}
/>
```

**Component query/scoping pattern** (row history component lines 8-36):
```elixir
opts = [
  repo: assigns.repo,
  scope: assigns[:scope],
  scope_query_fn: assigns[:scope_query_fn]
]

history = Threadline.history(schema_module, assigns.record_id, opts)
snapshot_result = Threadline.as_of(schema_module, assigns.record_id, as_of_dt, opts)
```

**Pitfall:** lines 11-12 include `String.to_atom(assigns.table)`. A public Home/row-history route must validate table against known `threadline_schemas` string keys before invoking the component, or change the component to avoid atom creation from user input.

**Selectors/routes to reuse:**
- Existing transaction row-history link selector: `data-testid="row-history-link"` at transaction lines 171-174.
- Drawer selector: `data-testid="row-history-drawer"` at component line 74.
- Existing route: `/audit/transactions/:id/history/:table/:record_id`.
- Recommended new first-class route shape: `/audit/row-history/:table/:record_id` or `/audit/history/:table/:record_id`, mounted by the router macro and still supplied `threadline_schemas`, `scope`, and `scope_query_fn`.

**Tests to extend/add:**
- `test/threadline/operator_surface/transaction_live_test.exs` for existing route regressions. Scoped row-history test lines 501-530 proves `Admin Secret` stays hidden.
- `test/threadline/operator_surface/row_history_component_test.exs` for component-level schema missing and scoped query behavior. Missing schema test lines 35-49; scoped query test lines 98-134; scope query function lines 158-168.
- New first-class route tests should live beside LiveView route tests, preferably `test/threadline/operator_surface/live/row_history_live_test.exs` if a new LiveView is created, otherwise in `transaction_live_test.exs`.

### Exports surface/controller/status and carry-forward

**Analogs:** `lib/threadline/operator_surface/live/export_status_live.ex`, `lib/threadline/operator_surface/controllers/export_controller.ex`

**Export Status page pattern** (status lines 28-37, 68-90, 155-173, 297-306):
```elixir
base_path = (uri_parsed.path || "") |> String.replace_suffix("/exports", "")
assign(socket, :export_denied_descriptor, Unsupported.export_denied_descriptor(params))
```

Status page already accepts query params for denied fallback copy and renders source filters from jobs. `timeline_search_path/2` currently encodes whatever is in `job.query_params`; for Phase 140, prefer `FilterParams.canonical_query/1` if adding pre-populated export-context UI.

**Controller pattern** (controller lines 170-199):
```elixir
with {:ok, filters} <- FilterParams.parse(params),
     :ok <- safe_validate(filters) do
  scope_opts = [
    scope: conn.assigns[:threadline_scope],
    scope_query_fn: conn.assigns[:threadline_scope_query_fn],
    surface: :export,
    params: %{filters: filters}
  ]
end
```

Keep export authorization/scoping on the HTTP side. Direct download URLs must continue through `ExportAuthPlug` and `surface: :export` scope context.

**Tests to extend:**
- `test/threadline/operator_surface/live/export_status_live_test.exs`: actor-owned jobs only lines 156-193; source search/action/failure lines 266-289; readiness/query param display lines 292-354.
- `test/threadline/operator_surface/controllers/export_controller_test.exs`: scoped export only returns allowed rows around lines 622-632; denied direct export around lines 685-689; invalid filter 422 around lines 301-302.

### Evidence filters/context

**Analog:** `lib/threadline/operator_surface/live/evidence_live.ex`

Evidence uses its own parser, not `FilterParams`. Carry-forward from Evidence should be explicit and narrow.

**Evidence request parse/navigation pattern** (lines 22-48, 172-230, 321-330):
```elixir
with {:ok, subject} <- parse_subject(Map.get(params, "subject")),
     {:ok, subject_ref} <- parse_subject_ref(Map.get(params, "subject_ref_json")),
     {:ok, mode} <- parse_mode(Map.get(params, "mode", "latest")) do
  {:ok, %{subject: subject, subject_ref: subject_ref, mode: mode}}
end
```

Existing support actions link to Exports without context (lines 313-317). If Phase 140 carries Evidence context into Exports, add focused parser/allowlist tests; do not mix evidence `subject_ref_json` into Timeline `FilterParams`.

**Tests to extend:** `test/threadline/operator_surface/live/evidence_live_test.exs` for Evidence-specific query shape; browser analog in `operator-prove-mobile.spec.ts` lines 107-124.

### Router macro and example `:schemas` mount map

**Analog:** `lib/threadline/operator_surface/router.ex`

**Live routes pattern** (lines 89-109):
```elixir
live_session :threadline,
  on_mount: [
    {Threadline.OperatorSurface.Auth, opts},
    {Threadline.OperatorSurface.Coverage.OnMount, opts}
  ] do
  scope path, alias: Threadline.OperatorSurface.Live do
    live("/", StartLive, :index)
    live("/timeline", TimelineLive, :index)
    live("/exports", ExportStatusLive, :index)
    live("/transactions/:id", TransactionLive, :show)
    live("/transactions/:id/history/:table/:record_id", TransactionLive, :history)
  end
end
```

Add first-class row history inside this LiveView scope so it inherits auth, coverage assigns, actor, scope, repo, and schemas.

**Export controller routes pattern** (lines 112-145): keep HTTP exports in sibling `scope path <> "/exports"` with `pipe_through(:threadline_exports)`.

**Example app mount map:** `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`

Use existing operator surface mount options:
- Auth/scoping pipelines lines 160-178.
- `schemas` map lines 172-175: `"tickets"` and `"ticket_replies"`.
- `scope_operator_query/3` supports `:row_history` in lines 123-127.
- Support users receive `{:ok, %{access: :support_read_only, organization_id: org_id}}` lines 72-83.

### Browser E2E setup and seeded data

**Analogs:** `examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts`, `operator-find-mobile.spec.ts`, `operator-prove-mobile.spec.ts`

**Setup pattern:**
- Login helper uses `admin@example.com` and `DEMO_SEED_PASSWORD || "password123456"` (`operator-home-nav-mobile.spec.ts` lines 3-34).
- Mobile UAT uses `test.use({ viewport: { width: 375, height: 812 }, isMobile: true })` (`operator-home-nav-mobile.spec.ts` line 6).
- No-horizontal-overflow helper lines 36-43.
- Playwright config uses `E2E_BASE_URL || http://127.0.0.1:4002`, one worker, reduced motion (`playwright.config.ts` lines 3-20).
- `run-e2e.sh` migrates, runs `mix demo.seed`, starts the Phoenix server, then `npm test` (lines 91-145).

**Stable seeded data:**
- Correlation literal `walk-acme-4521-close` is exposed by `Manifest.correlation_id(:acme_4521_close)` (`manifest.ex` lines 73, 145) and used in `operator-find-mobile.spec.ts` line 5.
- Anchor seed creates the close story with that correlation (`seed/anchors.ex` lines 66-78).
- Export seed creates jobs with `correlation_id`, `ticket_replies`, `tickets`, and admin actor (`seed/exports.ex` lines 21-70).
- Saved views are seeded for Home resume (`seed/exports.ex` lines 95-120), but existing filters include non-FilterParams keys (`op`, `status`); Phase 140 tests should assert canonical dropping if relying on them.

**Selectors/routes to reuse:**
- Home: `/audit`, `#tl-main`, nav test IDs `operator-nav-timeline`, `operator-nav-exports`.
- Timeline: `/audit/timeline?correlation_id=${encodeURIComponent(closeCorrelation)}`, `data-testid="operator-timeline"`, `data-testid="timeline-row"`, `data-testid="transaction-link"`.
- Row history: `data-testid="transaction-change-row"` filtered by `ticket_replies`, then `data-testid="row-history-link"`, then `data-testid="row-history-drawer"`.
- Exports: `/audit/exports`, `data-testid="export-jobs"`, `data-testid="export-readiness-group"`, link text `Reopen source search`.

Recommended new E2E file: `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts`.

## Shared Patterns

### Auth And Scoping

**Source:** `lib/threadline/operator_surface/router.ex` lines 89-109 and example router lines 72-83, 123-127, 160-178.

Apply to all new LiveViews/routes by mounting under `threadline_operator_surface/2`. Pass `scope: @threadline_scope`, `scope_query_fn: @threadline_scope_query_fn`, and `surface: :row_history | :timeline | :export` to query APIs. Add scoped tests that seed visible and hidden rows and assert hidden text is absent.

### Query Param Canonicalization

**Source:** `FilterParams.canonical_query/1` lines 93-112.

Apply to Home correlation links, Timeline carry-forward, saved views, export context links, and “reopen source” links where params match Timeline filter keys.

### Error Handling

**Source:** Timeline filter errors lines 104-116 and 658-660; Evidence errors lines 38-44 and 100-101; Export controller invalid params lines 194-199.

Use visible `tl-alert tl-alert--error` for LiveView form errors and `422 text/plain` for direct export controller invalid filters.

### UI Style

**Source:** StartLive and Timeline use `Threadline.OperatorSurface.Style.css`, `tl-page`, `tl-home`, `tl-toolbar`, `tl-button`, `tl-alert`, `tl-empty`, `tl-chip`.

Do not introduce broad CSS redesign. Phase 140 controls should be compact, token-backed, and preserve Phase 139 mobile nav/no-overflow contracts.

## Pitfalls

| Pitfall | Source | Recommendation |
|---|---|---|
| Unsafe atom creation from route table | `row_history_component.ex` lines 11-12 | Validate table against `threadline_schemas` string keys before component call, or refactor to avoid `String.to_atom/1`. |
| Query param drift | `timeline_live.ex` lines 736-737; `filter_params.ex` lines 93-112 | Use `FilterParams.canonical_query/1`; do not hand-roll query order. |
| Export auth is separate from LiveView auth | `router.ex` lines 112-145 | Direct downloads/export endpoints must remain behind `ExportAuthPlug`. |
| Scope bypass risk | example router lines 123-127 | Ensure row-history and export contexts pass correct `surface` atom to `scope_query_fn`. |
| Phase 139 boundary tests currently refute new Home controls | `start_live_test.exs` lines 309-323 | Update these tests intentionally when adding earned controls; keep refutes for non-roadmap routes/workflows. |
| Seeded saved views include non-FilterParams keys | `seed/exports.ex` lines 95-120 | For Phase 140 UAT, prefer explicit query URLs or add seed data with allowed keys. |

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| None | - | - | Existing Home, Timeline, row-history, export, router, and E2E patterns cover all Phase 140 flows. |

## Metadata

**Analog search scope:** `lib/threadline/operator_surface`, `test/threadline/operator_surface`, `examples/threadline_phoenix/lib`, `examples/threadline_phoenix/e2e`, demo seed files.
**Files scanned:** 40+ via `rg`, 18 read with line-numbered targeted slices.
**Pattern extraction date:** 2026-06-04
