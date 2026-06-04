# Phase 140: Earned New Flows - Research

**Researched:** 2026-06-04
**Domain:** Phoenix LiveView operator surface route/query/export flow wiring
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Ship only the four roadmap-listed flows. Do not add a general search builder, advanced query DSL, bulk export workflow, or new proof surfaces.
- **D-02:** Keep Home as the entry point for record-first lookup and correlation paste because Phase 139 made it the operator orientation hub. Add actual controls only where they map directly to Phase 140 flows.
- **D-03:** Keep the record-first path cordoned and plain-language. It should ask for a mapped schema/table and record id, then navigate to the existing row-history experience or a dedicated route; it should not expose raw Timeline filter construction.
- **D-04:** Treat correlation paste/deep-link as a Timeline-context shortcut. Use existing `correlation_id` filtering semantics where possible, with validation and error copy for empty/invalid input.
- **D-05:** Treat the closed export loop as context carry-forward, not a new export builder. From filtered Timeline/Evidence, carry allowed filters into the existing Exports surface and make the pre-populated context obvious.
- **D-06:** Treat first-class row-history as a discoverability route for an existing capability. Reuse existing row-history components/query constraints and preserve scope authorization.
- **D-07:** Every flow must trace to a named persona/JTBD and a decision/earned-flow record from the locked IA. If a behavior cannot be tied to that map, defer it.
- **D-08:** Preserve Phase 139 nav/Home IA, scope chip, coverage badge, feature flags, and mobile viewport fixes. Do not regress the Home/nav baseline while adding controls.
- **D-09:** Use existing `Threadline.OperatorSurface` primitives, `.tl-*` styles, `FilterParams`, `Threadline.Query`, export/auth/scoping seams, and example-app E2E patterns before adding abstractions.
- **D-10:** Keep validation tight: each flow needs focused ExUnit coverage and at least one browser UAT path when the behavior crosses Home/Timeline/Evidence/Exports.

### the agent's Discretion

No explicit separate discretion section exists in `140-CONTEXT.md`. Planning discretion is limited to implementation shape inside the locked decisions above. [VERIFIED: codebase grep]

### Deferred Ideas (OUT OF SCOPE)

- Motion and animation refinements.
- Full mobile-first table/filter/drawer redesign.
- Screenshot-diff infrastructure.
- Bulk export lifecycle redesign.
- Advanced saved search/query builder.
- Any new persona flow not named in Phase 140's roadmap goal.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| POLISH-FLOWS | A support operator can look up one record's history from Home without building filters; a reviewer can carry a filtered Timeline/Evidence view into a pre-populated export; an incident responder can paste/deep-link a `correlation_id` from Home; row history is reachable as a first-class entry; each new flow traces to a persona JTBD and decision record. | Use Home `StartLive`, `FilterParams`, Timeline export/correlation semantics, `RowHistoryComponent`, router mount macro, export status/controller auth seams, and example Playwright fixtures documented below. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: codebase grep] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

No `AGENTS.md` exists in `/Users/jon/projects/threadline`, so no additional project-agent directives were found. [VERIFIED: codebase grep]

## Summary

Phase 140 should be implemented as route/query wiring and small, persona-scoped controls over existing LiveView capabilities, not as new backend query machinery. The current code already has strict Timeline `correlation_id` parsing/validation, canonical query encoding, scope-aware Timeline/export query options, actor-owned export job status, and a reusable row-history component. [VERIFIED: `lib/threadline/operator_surface/exports/filter_params.ex`; VERIFIED: `lib/threadline/operator_surface/live/timeline_live.ex`; VERIFIED: `lib/threadline/operator_surface/live/export_status_live.ex`; VERIFIED: `lib/threadline/operator_surface/live/row_history_component.ex`]

The highest-leverage first slice is a first-class row-history route because it unlocks both "record-first lookup from Home" and "row history as its own entry point." The route should reuse `RowHistoryComponent` and `Threadline.history/3` / `Threadline.as_of/4` through the existing `:schemas`, `repo`, `scope`, and `scope_query_fn` assigns. The component path in `140-CONTEXT.md` is stale; the actual file is `lib/threadline/operator_surface/live/row_history_component.ex`. [VERIFIED: `lib/threadline/operator_surface/live/row_history_component.ex:8`; VERIFIED: `lib/threadline/operator_surface/router.ex:99`]

**Primary recommendation:** Add a first-class `/rows/:table/:record_id` LiveView route, then wire Home record/correlation forms and Timeline/Evidence-to-Exports context links around existing `FilterParams` and export authorization seams. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Home record-first lookup | Frontend Server (LiveView) | API / Backend query layer | Home owns the form and navigation; row-history query execution remains in `Threadline.history/3` and `Threadline.as_of/4`. [VERIFIED: `start_live.ex:75`; VERIFIED: `query.ex:364`] |
| Correlation paste/deep-link | Frontend Server (LiveView) | API / Backend query layer | Home should canonicalize/push navigation to Timeline; Timeline already parses, validates, and runs strict correlation filtering. [VERIFIED: `timeline_live.ex:102`; VERIFIED: `query.ex:153`] |
| Closed Timeline export loop | Frontend Server (LiveView) | API / Backend export layer | Timeline has current filters and export actions; export controller uses the same parser and scope options. [VERIFIED: `timeline_live.ex:411`; VERIFIED: `export_controller.ex:170`] |
| Closed Evidence export loop | Frontend Server (LiveView) | Evidence context | Evidence owns proof filters and can carry a constrained proof context to Exports, but current export files are Timeline-change exports only. [VERIFIED: `evidence_live.ex:172`; VERIFIED: `export_status_live.ex:72`] |
| First-class row history | Frontend Server (LiveView) | API / Backend query layer | Router adds discoverable route; existing component/query layer owns schema lookup, scope, history, and snapshot rendering. [VERIFIED: `router.ex:99`; VERIFIED: `row_history_component.ex:8`] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 | Runtime and test runner. | Existing project runtime. [VERIFIED: local `elixir --version`; VERIFIED: local `mix --version`] |
| Phoenix | 1.8.7 | Router/controller/LiveView host framework. | Existing operator surface mount and example app framework. [VERIFIED: `mix.lock`] |
| Phoenix LiveView | 1.1.30 | Operator screens, forms, patch/navigation, components. | All target flows are LiveView screens today. [VERIFIED: `mix.lock`; VERIFIED: `router.ex:89`] |
| Ecto / Ecto SQL | 3.13.5 | Query layer and repository access. | Timeline, row history, exports, and example scoping are Ecto queries. [VERIFIED: `mix.lock`; VERIFIED: `query.ex:230`] |
| PostgreSQL / Postgrex | PostgreSQL server 14.17; Postgrex 0.22.0 | Audit storage and local validation DB. | `pg_isready` reports local server accepting connections; Threadline audit tables use PostgreSQL JSONB predicates. [VERIFIED: local `pg_isready`; VERIFIED: `mix.lock`; VERIFIED: `query.ex:372`] |
| Playwright | 1.60.0 installed lock; package spec `^1.52.0` | Browser UAT for example app flows. | Existing Phase 139/Find/Prove browser suites use Playwright. [VERIFIED: `examples/threadline_phoenix/e2e/package-lock.json`; VERIFIED: `operator-find-mobile.spec.ts`] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Jason | 1.4.4 | Evidence `subject_ref_json` and session actor serialization. | Needed when carrying Evidence subject context into Exports or tests. [VERIFIED: `mix.lock`; VERIFIED: `evidence_live.ex:197`] |
| Threadline `FilterParams` | local module | Canonical Timeline URL parsing/encoding. | Use for Home correlation navigation and export context query strings. [VERIFIED: `filter_params.ex:62`; VERIFIED: `filter_params.ex:105`] |
| Threadline `RowHistoryComponent` | local module | Row-history drawer rendering, snapshot, scoping. | Reuse for first-class row-history route and record-first lookup target. [VERIFIED: `row_history_component.ex:8`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `/rows/:table/:record_id` route | `/transactions/:id/history/:table/:record_id` only | Existing route requires a transaction id and does not satisfy first-class row-history. [VERIFIED: `router.ex:106`] |
| `FilterParams` | New Home-only query parser | A new parser would duplicate validation/order semantics and risks Timeline/export drift. [VERIFIED: `filter_params.ex:6`] |
| Existing export status page | New export builder | Out of scope: D-05 says carry context into existing Exports, not build a new export builder. [VERIFIED: `140-CONTEXT.md:27`] |

**Installation:** No new external packages are recommended. [VERIFIED: codebase grep]

## Package Legitimacy Audit

No external packages should be added for Phase 140, so the package legitimacy gate is not applicable. Existing dependencies are already present in `mix.lock` and `examples/threadline_phoenix/e2e/package-lock.json`. [VERIFIED: codebase grep]

## Current Capability Inventory

### Home

- `StartLive` is the `/audit` Home entry point and already receives coverage, policy, evidence, export, scope, actor, and repo assigns through the operator surface hooks. [VERIFIED: `start_live.ex:63`; VERIFIED: `router.ex:89`]
- Home currently has no forms or Phase 140 controls; tests explicitly refute `<form>`, `phx-submit`, `name="correlation_id"`, `record_lookup`, and `push_patch` in `StartLive`. [VERIFIED: `test/threadline/operator_surface/live/start_live_test.exs:317`]
- Home saved-view links already use `FilterParams.canonical_query/1`, which proves Home can safely generate canonical Timeline URLs. [VERIFIED: `start_live.ex:151`; VERIFIED: `filter_params.ex:105`]

### Timeline / Correlation

- Timeline accepts URL params `from`, `to`, `table`, `actor_kind`, `actor_id`, and `correlation_id`. [VERIFIED: `filter_params.ex:11`]
- Timeline uses `FilterParams.filters_raw_from_params/1`, `FilterParams.parse/1`, `Threadline.Query.validate_timeline_filters!/1`, and scope-aware `Query.timeline_page/2` / `Export.count_matching/2`. [VERIFIED: `timeline_live.ex:102`; VERIFIED: `timeline_live.ex:146`; VERIFIED: `timeline_live.ex:151`; VERIFIED: `timeline_live.ex:727`]
- `correlation_id` is a strict inner-join filter against linked `audit_actions.correlation_id`, must be a nonblank binary, and is capped at 256 UTF-8 bytes after trimming. [VERIFIED: `query.ex:153`; VERIFIED: `query.ex:181`; VERIFIED: `query.ex:840`]
- Timeline already renders row-level correlation deep links and copy buttons. [VERIFIED: `timeline_live.ex:500`]

### Row History

- The router only exposes transaction-scoped row history today: `/transactions/:id/history/:table/:record_id`. [VERIFIED: `router.ex:106`]
- `TransactionLive` embeds `RowHistoryComponent` for `live_action == :history`, passing `threadline_schemas`, `repo`, `scope`, and `scope_query_fn`. [VERIFIED: `transaction_live.ex:32`; VERIFIED: `transaction_live.ex:202`]
- `RowHistoryComponent` maps `table` to a schema via `threadline_schemas`, calls `Threadline.history/3` and `Threadline.as_of/4`, and renders a mapped-schema error if absent. [VERIFIED: `row_history_component.ex:8`; VERIFIED: `row_history_component.ex:23`; VERIFIED: `row_history_component.ex:28`; VERIFIED: `row_history_component.ex:38`]
- Current component URL generation assumes `base_path/history/...`, which works under a transaction route but must be abstracted or given a row-history-specific base/close path for `/rows/...`. [VERIFIED: `row_history_component.ex:57`; VERIFIED: `row_history_component.ex:82`; VERIFIED: `row_history_component.ex:99`]

### Exports

- Timeline has direct file download links for CSV/JSON/NDJSON using the current canonical filter query, plus `request_background_export` that inserts an `ExportJob` with current filters and navigates to `/exports`. [VERIFIED: `timeline_live.ex:411`; VERIFIED: `timeline_live.ex:235`]
- `ExportStatusLive` lists actor-owned jobs only, shows query params, and provides "Reopen source search" links from persisted `job.query_params`. [VERIFIED: `export_status_live.ex:198`; VERIFIED: `export_status_live.ex:155`; VERIFIED: `export_status_live.ex:168`]
- The HTTP export controller parses params through `FilterParams`, applies export authorization scope as `surface: :export`, and returns `422` for invalid filter input. [VERIFIED: `export_controller.ex:170`; VERIFIED: `export_controller.ex:176`; VERIFIED: `export_controller.ex:195`]
- Example app support users may reach `/audit`, but exports are admin-only through `my_export_authorize_fn/1`. [VERIFIED: `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:44`; VERIFIED: `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:85`]

### Evidence

- Evidence has proof-specific URL params: `subject`, `subject_ref_json`, and `mode`. [VERIFIED: `evidence_live.ex:172`]
- Evidence proof context is not part of the Timeline/export filter vocabulary, so a closed Evidence-to-Exports loop needs a small, explicit adapter/notice rather than passing proof params into `ExportController`. [VERIFIED: `filter_params.ex:11`; VERIFIED: `evidence_live.ex:172`; VERIFIED: `export_controller.ex:170`]

## Open Questions Resolved

| Question | Resolution | Confidence |
|----------|------------|------------|
| Which route shape best supports first-class row-history without duplicating `TransactionLive`? | Add a dedicated LiveView route such as `/rows/:table/:record_id`, backed by a tiny `RowHistoryLive` wrapper that reuses `RowHistoryComponent`. Do not route through a fake transaction id. [VERIFIED: `router.ex:106`; VERIFIED: `row_history_component.ex:8`] | HIGH |
| Does Exports accept enough query context to pre-populate filtered exports? | Timeline context yes: allowed filters already match `FilterParams`. Evidence context no: it needs an adapter because Evidence params are proof params, not Timeline export params. [VERIFIED: `filter_params.ex:11`; VERIFIED: `evidence_live.ex:172`] | HIGH |
| Which seeded records/correlation ids are stable for browser UAT? | Use `walk-acme-4521-close`, `tickets`, `ticket_replies`, and the existing #4521 close path because current Playwright specs already use them for correlation, transaction, and row-history redaction checks. [VERIFIED: `manifest.ex:145`; VERIFIED: `operator.spec.ts:22`; VERIFIED: `operator-find-mobile.spec.ts:65`] | HIGH |
| How should feature flags gate Home controls? | Gate export carry-forward controls on `@threadline_exports_enabled`; gate Evidence export handoff on both Evidence and Exports enabled; record/correlation Home controls can live in Find and should remain available when Timeline is mounted, but must preserve scope chip/header and not expose Prove links when disabled. [VERIFIED: `start_live.ex:63`; VERIFIED: `start_live.ex:123`; VERIFIED: `timeline_live.ex:411`] | HIGH |
| What scope contexts preserve scoped behavior? | Use existing `surface: :row_history` for first-class row history and `surface: :export` for exports; Timeline stays `surface: :timeline`. Example scoping handles all three with organization predicates. [VERIFIED: `query.ex:726`; VERIFIED: `export_controller.ex:176`; VERIFIED: `timeline_live.ex:537`; VERIFIED: `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:123`] | HIGH |

## Architecture Patterns

### System Architecture Diagram

```text
Home (/audit)
  | record lookup: table + record_id
  v
RowHistoryLive (/audit/rows/:table/:record_id)
  -> RowHistoryComponent
  -> schema map (:schemas)
  -> Threadline.history/as_of
  -> scope_query_fn surface=:row_history

Home (/audit)
  | correlation_id paste/deep-link
  v
TimelineLive (/audit/timeline?correlation_id=...)
  -> FilterParams.parse
  -> Query.validate_timeline_filters!
  -> Query.timeline_page / Export.count_matching
  -> scope_query_fn surface=:timeline

TimelineLive filtered context
  | allowed FilterParams query
  v
ExportStatusLive (/audit/exports?...context...)
  -> current context banner / queue action
  -> ExportJob query_params
  -> ExportController downloads
  -> scope_query_fn surface=:export

EvidenceLive proof context
  | subject / subject_ref_json adapter
  v
ExportStatusLive context banner
  -> no raw proof params passed to file export endpoints unless explicitly mapped
```

### Recommended Project Structure

```text
lib/threadline/operator_surface/live/
├── start_live.ex             # Add Home record/correlation controls.
├── timeline_live.ex          # Add filtered-context handoff link into Exports.
├── evidence_live.ex          # Add proof-context handoff link into Exports.
├── export_status_live.ex     # Render carried context and optional queue action.
├── row_history_live.ex       # New wrapper LiveView for first-class row history.
└── row_history_component.ex  # Reuse, but make paths configurable.

test/threadline/operator_surface/live/
├── start_live_test.exs
├── row_history_live_test.exs
├── timeline_live_test.exs
├── evidence_live_test.exs
└── export_status_live_test.exs
```

### Pattern 1: Canonical Context Carry-Forward

**What:** Convert raw form/current params to canonical allowed query keys via `FilterParams.canonical_query/1`. [VERIFIED: `filter_params.ex:105`]

**When to use:** Home correlation deep-link, Timeline-to-Exports link, and any source-search reopening. [VERIFIED: `timeline_live.ex:736`; VERIFIED: `export_status_live.ex:168`]

**Example:**

```elixir
# Source: lib/threadline/operator_surface/exports/filter_params.ex
query = Threadline.OperatorSurface.Exports.FilterParams.canonical_query(%{
  "correlation_id" => correlation_id
})

push_navigate(socket, to: "#{base_path}/timeline?#{query}")
```

### Pattern 2: Thin First-Class LiveView Around Existing Component

**What:** A new `RowHistoryLive` should do base-path extraction, parse `as_of`, and render `RowHistoryComponent`. [VERIFIED: `transaction_live.ex:32`; VERIFIED: `row_history_component.ex:8`]

**When to use:** First-class row-history entry and record-first lookup target. [VERIFIED: `140-CONTEXT.md:28`]

**Example:**

```elixir
# Source pattern: lib/threadline/operator_surface/live/transaction_live.ex
<.live_component
  module={Threadline.OperatorSurface.Live.RowHistoryComponent}
  id="row-history"
  table={@table}
  record_id={@record_id}
  as_of={@as_of}
  base_path={@row_history_path}
  threadline_schemas={@threadline_schemas}
  repo={@threadline_repo}
  scope={@threadline_scope}
  scope_query_fn={@threadline_scope_query_fn}
/>
```

### Pattern 3: Scope Context Is Part Of The Contract

**What:** Pass `surface` and `params` to `scope_query_fn` for every queryable flow. [VERIFIED: `scope.ex:9`]

**When to use:** Row history and export carry-forward. [VERIFIED: `query.ex:726`; VERIFIED: `export_controller.ex:176`]

**Example:**

```elixir
# Source: lib/threadline/query.ex
[
  scope: socket.assigns[:threadline_scope],
  scope_query_fn: socket.assigns[:threadline_scope_query_fn],
  surface: :row_history,
  params: %{schema_module: schema_module, id: record_id}
]
```

### Anti-Patterns to Avoid

- **Fake transaction route for row history:** Do not synthesize or require a transaction id for first-class row history; it fails the "not only from inside a transaction" requirement. [VERIFIED: `140-CONTEXT.md:15`]
- **Passing Evidence params into export downloads:** `subject_ref_json` is not an allowed export filter and would be silently ignored by `FilterParams.normalize_params/1`; use an explicit adapter/banner. [VERIFIED: `filter_params.ex:121`]
- **Raw table injection:** Record-first lookup must choose from mapped `:schemas` or covered/audited tables, not arbitrary SQL identifiers. [VERIFIED: `row_history_component.ex:11`; VERIFIED: `timeline_live.ex:31`]
- **Bypassing export auth:** Export context links must hide or degrade when `@threadline_exports_enabled` is false, and HTTP downloads remain under `ExportAuthPlug`. [VERIFIED: `timeline_live.ex:411`; VERIFIED: `router.ex:119`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Timeline query parsing | Home-only parser | `FilterParams.parse/1` and `canonical_query/1` | Keeps URL order, actor normalization, datetime parsing, and atom safety consistent. [VERIFIED: `filter_params.ex:25`] |
| Correlation search semantics | New correlation query | `Threadline.Query` `:correlation_id` filter via Timeline | Existing semantics are strict and validated. [VERIFIED: `query.ex:12`] |
| Row reconstruction | Custom snapshot algorithm | `Threadline.history/3` and `Threadline.as_of/4` | Existing functions handle delete/before-horizon and scope. [VERIFIED: `query.ex:364`; VERIFIED: `query.ex:401`] |
| Export files | New export format/controller | `ExportController` / `Threadline.Export` | Existing controller handles validation, count cap, chunking, headers, and scope. [VERIFIED: `export_controller.ex:170`] |
| Authorization model | Threadline-owned RBAC | Existing host `authorize_fn`, `export_authorize_fn`, `scope_query_fn` | Host-owned auth boundary is locked. [VERIFIED: `router.ex:31`; VERIFIED: `router.ex:35`] |

**Key insight:** Phase 140's value is exposing existing capabilities through earned paths; custom query/export/history implementations would increase drift and security risk. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Component Paths Are Transaction-Relative

**What goes wrong:** A first-class `/rows/...` route reuses `RowHistoryComponent`, but "Close" or as-of changes patch to `/rows/.../history/...` by accident. [VERIFIED: `row_history_component.ex:57`]

**How to avoid:** Give the component explicit `close_path` and `history_path` assigns, or wrap path generation in a route-mode helper before adding the new route. [VERIFIED: codebase grep]

### Pitfall 2: Evidence Context Is Not Timeline Context

**What goes wrong:** Evidence `subject` / `subject_ref_json` params are passed into export download URLs, but `FilterParams` only allows Timeline filters. [VERIFIED: `filter_params.ex:11`; VERIFIED: `evidence_live.ex:172`]

**How to avoid:** For Evidence-to-Exports, render carried proof context in Exports and provide an "Open exports" / "Queue proof context" affordance only if a concrete export job context is intentionally created. Do not promise Timeline CSV semantics for proof evidence unless a mapping is defined. [VERIFIED: codebase grep]

### Pitfall 3: Support Scope And Export Auth Diverge

**What goes wrong:** A support-scoped user can see Timeline but cannot use Exports in the example app; a Home/Timeline export CTA could imply access that export auth denies. [VERIFIED: `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:72`; VERIFIED: `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:85`]

**How to avoid:** Gate export carry-forward controls on `@threadline_exports_enabled` and test denied fallback. [VERIFIED: `export_status_live.ex:187`; VERIFIED: `test/threadline/operator_surface/live/export_status_live_test.exs:109`]

### Pitfall 4: Correlation Blank/Long Input

**What goes wrong:** Home accepts blank or overlong correlation ids and navigates to a confusing empty Timeline or invalid route. [VERIFIED: `query.ex:181`; VERIFIED: `query.ex:191`]

**How to avoid:** Trim on Home, show plain error for blank, and reuse the 256-byte cap before navigation. [VERIFIED: `timeline_live.ex:399`; VERIFIED: `test/threadline/operator_surface/live/timeline_live_test.exs:486`]

### Pitfall 5: Schema Map Atom Conversion

**What goes wrong:** `String.to_atom(assigns.table)` in `RowHistoryComponent` can create atoms from untrusted route input. [VERIFIED: `row_history_component.ex:12`]

**How to avoid:** Prefer string-key lookup for new route inputs; if keeping atom fallback, change to existing atom or remove the fallback for external route params. [VERIFIED: codebase grep]

## Recommended Plan Slicing / Waves

### Wave 0 - Contracts And Shared Seams

1. Add/adjust route tests for `/audit/rows/:table/:record_id` and source contract tests for no advanced search/export builder. [VERIFIED: `router.ex:99`]
2. Refactor `RowHistoryComponent` path generation into explicit path assigns, preserving transaction route behavior. [VERIFIED: `row_history_component.ex:57`]
3. Add `RowHistoryLive` using existing component and scope assigns. [VERIFIED: `transaction_live.ex:202`]

### Wave 1 - Home Find Controls

1. Add Home record-first form with mapped table selector and record id field. [VERIFIED: `start_live.ex:98`; VERIFIED: `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:172`]
2. Add Home correlation paste form/deep-link behavior to navigate to canonical `/timeline?correlation_id=...`. [VERIFIED: `filter_params.ex:105`; VERIFIED: `timeline_live.ex:399`]
3. Update StartLive tests to replace Phase 139 non-leakage guard with scoped positive/negative guards. [VERIFIED: `test/threadline/operator_surface/live/start_live_test.exs:317`]

### Wave 2 - Export Carry-Forward

1. Add Timeline "Carry to Exports" link using current `@filter_query`, distinct from direct CSV/JSON/NDJSON downloads. [VERIFIED: `timeline_live.ex:411`]
2. Add Exports context banner for allowed Timeline filters from query params and optional queue action that creates an `ExportJob` with actor/scoping. [VERIFIED: `export_status_live.ex:28`; VERIFIED: `timeline_live.ex:235`]
3. Add Evidence "Carry proof context to Exports" banner/link with explicit proof context display, not file-export params passthrough. [VERIFIED: `evidence_live.ex:82`; VERIFIED: `filter_params.ex:11`]

### Wave 3 - Example UAT And Guardrails

1. Add browser UAT covering Home record lookup to `/audit/rows/ticket_replies/:id`, Home correlation paste to Timeline, Timeline filtered context to Exports, and Evidence context to Exports. [VERIFIED: `operator-find-mobile.spec.ts:65`; VERIFIED: `operator-prove-mobile.spec.ts:38`]
2. Add example integration test for first-class row route with support scope. [VERIFIED: `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:123`; VERIFIED: `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs:93`]
3. Run focused ExUnit plus Playwright against demo seed. [VERIFIED: `examples/threadline_phoenix/e2e/package.json`]

## Code Examples

### Home Correlation Navigation

```elixir
# Source: lib/threadline/operator_surface/exports/filter_params.ex
def handle_event("open-correlation", %{"correlation" => %{"correlation_id" => raw}}, socket) do
  correlation_id = String.trim(raw || "")

  query =
    Threadline.OperatorSurface.Exports.FilterParams.canonical_query(%{
      "correlation_id" => correlation_id
    })

  {:noreply, push_navigate(socket, to: "#{socket.assigns.base_path}/timeline?#{query}")}
end
```

### First-Class Row Route

```elixir
# Source pattern: lib/threadline/operator_surface/router.ex
live("/rows/:table/:record_id", RowHistoryLive, :show)
```

### Export Context Link From Timeline

```elixir
# Source pattern: lib/threadline/operator_surface/live/timeline_live.ex
<.link navigate={"#{@base_path}/exports?#{@filter_query}"} class="tl-button tl-button--secondary">
  Carry to exports
</.link>
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Row history only from transaction drill-down | Add first-class `/rows/:table/:record_id` wrapper over same component/query | Phase 140 planned | Satisfies first-class entry without duplicating query logic. [VERIFIED: `router.ex:106`] |
| Export loop starts in Timeline direct downloads/background queue | Add context carry-forward into Exports status/handoff | Phase 140 planned | Makes Exports the handoff destination without redesign. [VERIFIED: `timeline_live.ex:411`; VERIFIED: `export_status_live.ex:72`] |
| Correlation visible only in Timeline/Transaction rows | Add Home paste/deep-link shortcut to existing Timeline filter | Phase 140 planned | Exposes existing strict semantics. [VERIFIED: `timeline_live.ex:500`; VERIFIED: `query.ex:12`] |

**Deprecated/outdated:**
- `140-CONTEXT.md` references `lib/threadline/operator_surface/components/row_history_component.ex`, but the actual current file is `lib/threadline/operator_surface/live/row_history_component.ex`. [VERIFIED: codebase grep]
- Existing walkthrough doc-contracts refute bare `/audit/rows/...` URLs before Phase 140; planner must update those contracts if Phase 140 intentionally ships `/rows`. [VERIFIED: `examples/threadline_phoenix/test/threadline_phoenix/walkthrough_doc_contract_test.exs:53`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The preferred first-class route literal should be `/rows/:table/:record_id`, not `/row-history/:table/:record_id`. | Summary / Open Questions | Existing docs or user preference may require a different route literal; implementation still uses same component. |
| A2 | Evidence-to-Exports should display proof context rather than generate Timeline export files from proof params. | Open Questions / Pitfalls | If stakeholders expect evidence record export files, this would need a separate export format and is broader than current Phase 140 scope. |

## Open Questions

1. **Should the route literal be `/rows/:table/:record_id` or `/row-history/:table/:record_id`?**
   - What we know: `/transactions/:id/history/:table/:record_id` exists today, and older docs explicitly avoided bare `/audit/rows/...` before Phase 140. [VERIFIED: `router.ex:106`; VERIFIED: `examples/threadline_phoenix/test/threadline_phoenix/walkthrough_doc_contract_test.exs:53`]
   - What's unclear: Final product naming preference for the public route.
   - Recommendation: Use `/rows/:table/:record_id` because it matches existing row-history language and is short for Home navigation. [ASSUMED]

2. **Should Evidence context create a persisted ExportJob?**
   - What we know: ExportJob currently stores Timeline-like `query_params`; Evidence has proof-specific params. [VERIFIED: `export_status_live.ex:155`; VERIFIED: `evidence_live.ex:172`]
   - What's unclear: Whether "closed export loop" for Evidence means proof context handoff only or a downloadable proof package.
   - Recommendation: Ship context handoff/banner only in Phase 140 unless the planner can map it to existing Timeline export filters without fiction. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | ExUnit / app compile | yes | 1.19.5 | none |
| Mix | ExUnit / aliases | yes | 1.19.5 | none |
| Node.js | Playwright E2E | yes | v22.14.0 | none |
| npm | Playwright E2E | yes | 11.1.0 | none |
| PostgreSQL | DB-backed tests/example app | yes | server accepting connections on `/tmp:5432`; psql 14.17 | none |
| Playwright deps | Browser UAT | yes | 1.60.0 in lockfile | Existing ExUnit only if browser unavailable, but Phase 140 needs at least one browser UAT by D-10. |

**Missing dependencies with no fallback:** None found. [VERIFIED: local commands]

**Missing dependencies with fallback:** None found. [VERIFIED: local commands]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix 1.19.5; Playwright 1.60.0 for browser UAT. [VERIFIED: local commands; VERIFIED: package lock] |
| Config file | `mix.exs`, `examples/threadline_phoenix/e2e/playwright.config.ts`. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/row_history_component_test.exs` |
| Full suite command | `mix test` plus `cd examples/threadline_phoenix/e2e && E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-earned-flows.spec.ts` after example app reset/seed/server. |

### Phase Requirements To Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| POLISH-FLOWS | Home record-first lookup navigates to first-class row history without Timeline filters. | LiveView + Playwright | `mix test test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/live/row_history_live_test.exs` | RowHistoryLive test does not exist - Wave 0 |
| POLISH-FLOWS | Home correlation paste/deep-link navigates to Timeline and reuses validation. | LiveView + Playwright | `mix test test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/live/timeline_live_test.exs` | StartLive positive tests need Wave 1 |
| POLISH-FLOWS | Timeline/Evidence context carries into Exports. | LiveView + Playwright | `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs` | Partial existing; Wave 2 additions needed |
| POLISH-FLOWS | First-class row history preserves schema-map errors and scope. | LiveView + integration | `mix test test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/row_history_component_test.exs examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs` | RowHistoryLive test does not exist - Wave 0 |

### Sampling Rate

- **Per task commit:** focused file-level `mix test` command for touched LiveViews/components.
- **Per wave merge:** `mix test test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/row_history_component_test.exs`.
- **Phase gate:** full focused ExUnit plus example Playwright earned-flow spec after `mix demo.reset && mix demo.seed` and local server startup.

### Wave 0 Gaps

- [ ] `test/threadline/operator_surface/live/row_history_live_test.exs` - first-class route, missing schema, as-of patch path, close path, scope.
- [ ] `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` - four earned browser paths.
- [ ] StartLive tests must replace the Phase 139 "no Phase 140 controls" source assertion with positive controls plus no advanced builder assertions.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Host-owned `authorize_fn` / example `operator_auth` pipeline. [VERIFIED: `router.ex:89`; VERIFIED: `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:29`] |
| V3 Session Management | yes | Existing Phoenix session actor handoff via `SessionPlug` / example operator session. [VERIFIED: `router.ex:83`; VERIFIED: `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:44`] |
| V4 Access Control | yes | `scope_query_fn`, `export_authorize_fn`, feature-enabled assigns. [VERIFIED: `router.ex:31`; VERIFIED: `export_auth_plug.ex:39`] |
| V5 Input Validation | yes | `FilterParams`, `Query.validate_timeline_filters!`, schema map lookup, `Jason.decode` for Evidence refs. [VERIFIED: `filter_params.ex:62`; VERIFIED: `query.ex:145`; VERIFIED: `evidence_live.ex:197`] |
| V6 Cryptography | no new cryptography | Do not add crypto. [VERIFIED: phase scope] |

### Known Threat Patterns for Phoenix LiveView Operator Flow

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthorized row-history access via first-class route | Elevation of privilege | Pass `scope` and `scope_query_fn` to row-history queries with `surface: :row_history`. [VERIFIED: `query.ex:726`] |
| Export access bypass via carried context | Elevation of privilege | Keep HTTP downloads under `ExportAuthPlug`; hide/degrade LiveView actions when exports disabled. [VERIFIED: `router.ex:119`; VERIFIED: `export_status_live.ex:187`] |
| Atom exhaustion from route table input | Denial of service | Avoid `String.to_atom/1` for external route input; prefer string schema map keys. [VERIFIED: `row_history_component.ex:12`; VERIFIED: `filter_params.ex:25`] |
| Query parameter injection / unsupported filters | Tampering | Use `FilterParams` allowlist and `Query.validate_timeline_filters!`. [VERIFIED: `filter_params.ex:45`; VERIFIED: `query.ex:145`] |
| Cross-actor export job leakage | Information disclosure | `ExportStatusLive` filters jobs by `actor_ref`. [VERIFIED: `export_status_live.ex:198`] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/140-earned-new-flows/140-CONTEXT.md` - locked decisions, personas, non-goals.
- `.planning/phases/140-earned-new-flows/140-DISCUSSION-LOG.md` - open questions and selected gray areas.
- `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md` - phase goal and requirement.
- `.planning/phases/139-orientation-hub-home-nav/139-VERIFICATION.md` - Home/nav baseline and validation precedent.
- `lib/threadline/operator_surface/live/start_live.ex` - Home baseline.
- `lib/threadline/operator_surface/live/timeline_live.ex` - Timeline filters, correlation, export actions.
- `lib/threadline/operator_surface/live/row_history_component.ex` - reusable row-history component.
- `lib/threadline/operator_surface/live/export_status_live.ex` - exports status and source-search reopening.
- `lib/threadline/operator_surface/live/evidence_live.ex` - Evidence proof context params.
- `lib/threadline/operator_surface/controllers/export_controller.ex` - export parser/auth/scope behavior.
- `lib/threadline/operator_surface/router.ex` - mounted routes and auth hooks.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` - example auth/scoping/schema map.
- Existing ExUnit and Playwright specs named in Validation Architecture.

### Secondary (MEDIUM confidence)

- None. No web research was needed because the task is current-code implementation research. [VERIFIED: codebase grep]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions verified from local lockfiles and local commands.
- Architecture: HIGH - based on current code route/query/export seams.
- Pitfalls: HIGH - each pitfall is tied to concrete current source behavior.

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 for codebase-local findings, or until the operator surface routes/query modules change.
