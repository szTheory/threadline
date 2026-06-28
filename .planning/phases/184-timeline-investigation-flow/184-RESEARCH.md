# Phase 184: Timeline investigation flow - Research

**Researched:** 2026-06-28
**Domain:** Phoenix LiveView operator workflow, responsive audit investigation UI, accessibility, export handoff
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

The following constraints are copied from `.planning/phases/184-timeline-investigation-flow/184-CONTEXT.md` and are planning authority for this phase. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]

### Locked Decisions

## Implementation Decisions

### Investigation Command Shape

- **D-184-01:** Use a row-first Timeline command surface. The first viewport should expose only the investigation starters: `from`, `to`, `table`, and `correlation_id`, plus current result facts, active filter chips, one primary `Apply`, and one explicit reset to the default last-24h window.
- **D-184-02:** Keep schema and actor filters in the existing filter drawer. They are important but secondary; putting every filter inline would push rows down, crowd mobile keyboards, and make the page feel like a filter console instead of an investigation workflow.
- **D-184-03:** Keep batch Apply semantics. Do not introduce per-keystroke `phx-change` filtering for Timeline. The current explicit `phx-submit` model preserves URL/back-button behavior and avoids expensive scan churn while operators compose filters.
- **D-184-04:** Keep Timeline state shareable and recoverable through URL params. Filters that affect investigation results stay in the query string and flow through `handle_params/3` / `push_patch`.
- **D-184-05:** Reject a query-language command bar for Phase 184. It may be useful for future power-user search, but qualifier syntax like `table:` / `actor:` / `correlation:` adds grammar burden under incident pressure and exposes backend concepts too early.
- **D-184-06:** Reject a persistent desktop filter side rail for Phase 184. It competes with the existing shell rail, reduces row width, increases 320px reflow risk, and is not needed to satisfy TIME-01 through TIME-03.
- **D-184-07:** The result facts should be useful but not repetitive: window, matching changes, and audit-readiness posture are enough. Avoid duplicated status lines that repeat the same count/window in multiple places unless tests or assistive-tech proof require a specific live region.

### Row Scan And Pivots

- **D-184-08:** Use a hybrid Timeline row. Each row should stay scan-first while exposing visible pivots: operation, table, exact/human time, actor when known, correlation when present, primary transaction link, and direct row-history link when the row has a safe routeable row identity.
- **D-184-09:** `Open transaction` remains the primary row action because transaction is the canonical DB grouping for one or more changes.
- **D-184-10:** Add or preserve direct row-history access from Timeline only when the route can be built safely from the row data. If the row has composite/unsupported/ambiguous identity, omit the direct row-history action and leave transaction as the safe pivot.
- **D-184-11:** Keep actor and correlation as visible URL-backed pivots. Actor pivots answer "what else did this actor do?", and correlation pivots answer "what else happened in this request/job/integration chain?".
- **D-184-12:** Use copy controls sparingly. Copy affordances should be attached only to values operators plausibly paste into another tool or ticket: correlation id, row/table identity where useful, transaction id where visible, and other full refs. Every copy control needs a specific accessible label and must copy the full value, not the truncated label.
- **D-184-13:** Do not convert Timeline to a dense fixed-column table in Phase 184. It would improve desktop alignment but invites horizontal scroll and raw-ID overload on 320px/375px screens.
- **D-184-14:** Do not hide primary pivots behind overflow menus or expandable rows in Phase 184. Menus add focus/state complexity, hide the actions operators need under pressure, and are harder to keep stable in streamed rows.
- **D-184-15:** Timeline rows remain visually calm and static. Use hover/focus state and status stripes; do not add row entrance animations or decorative motion to high-frequency streams.

### Handoff Utilities

- **D-184-16:** Keep saved views, Coverage/Evidence checks, Queue export, Carry to Exports, and direct CSV/JSON/NDJSON downloads in a drawer or equivalent utility sheet. The main Timeline command area should have at most one low-noise handoff entry.
- **D-184-17:** Saved views stay near filters because they mutate and restore URL filter state. Saved views remain actor-owned; do not expose save/apply/delete affordances when no actor is available.
- **D-184-18:** `Carry to Exports` is the safest primary handoff because it takes the current filter context to the Exports surface where context and status can be reviewed.
- **D-184-19:** `Queue export` remains a faster secondary path for operators who already trust the current filter. It must keep clear feedback and route to export status on success.
- **D-184-20:** Direct CSV/JSON/NDJSON links remain real HTTP download links, but they should be visually secondary and grouped under "Download now" or equivalent. They must not imply LiveView UI checks are authoritative; `ExportAuthPlug`, direct controller auth, and `FilterParams` remain the security and filter-parity boundary.
- **D-184-21:** Coverage and Evidence links are secondary checks, not the main Timeline job. Keep them accessible from the handoff/refinement utility area without turning Timeline into a generic command center.
- **D-184-22:** Do not move Exports page IA or export-status workflow polish into Phase 184. Timeline may carry context into Exports, but Exports surface cleanup belongs to Phase 186 unless a strict Timeline blocker is found.

### Ugly-Data States And Proof Bar

- **D-184-23:** Use a Timeline-critical state lattice, not an exhaustive screenshot matrix. First-class design/proof should cover states that change an operator's investigation decision or can break the workflow.
- **D-184-24:** Timeline-specific states to design and verify: first-run empty, filtered no-data, future-window empty, unknown table, invalid filter, scoped/authorized-record caveat, export hidden/denied/unavailable affordance, background export failure, capped/large result warning, long table/correlation/actor refs, dense pagination, drawer focus/escape/return, mobile keyboard layout, reduced motion, and dark/light/system rendering.
- **D-184-25:** Generic permission/unavailable/redacted/pruned states stay in shared state/stress/detail proof unless Timeline renders them directly. Do not duplicate generic component proof just to inflate Phase 184 coverage.
- **D-184-26:** Empty and error copy must state what happened, why if known, and the next action. Preserve distinct meanings: "no captured changes", "no matches for this filter", "future window", "unknown table", and "scoped view" are not interchangeable.
- **D-184-27:** Loading/reconnecting/stale trust states must not replace last-good data unless there is no safe data to show. If stale data is shown, label it clearly and offer a retry/refresh path.
- **D-184-28:** Verification should be layered: focused LiveView/source tests for URL/filter/query/export branches and copy contracts; narrow Playwright proof for mobile/no-overflow/focus/keyboard/drawer/theme/reduced-motion; existing stress/ledger contracts for shared component states. Do not promote broad new screenshot baselines unless a specific stable cell is worth owning.

### Product, JTBD, And UX Posture

- **D-184-29:** Optimize Timeline for P1 incident responders and P2 support agents first, with P3 compliance/security reviewers and P4 audit/SRE operators served by accurate filters, export handoff, and trust states. P5 adopter developers benefit from route stability, source contracts, and Phoenix-native implementation.
- **D-184-30:** Apply the who/what/where/when/why lens:
  - Who: incident/support/audit operators using a mounted host-owned admin surface.
  - What: find matching changes, scan the sequence, open a transaction or row history, copy/pivot refs, and export current context.
  - Where: `/audit/timeline`, with handoff to `/audit/transactions/:id`, `/audit/rows/:table/:id`, `/audit/actors/:kind/:id`, and `/audit/exports`.
  - When: incident pressure, customer support triage, readiness/proof review, or handoff to another operator.
  - Why: make system history followable without forcing operators to understand Threadline's backend storage model.
- **D-184-31:** Use canonical domain language: Timeline, Audit Change, Audit Transaction, Actor, Correlation, row history, current view, filter, scan, open, copy, carry, queue export, download, widen, clear, refresh.
- **D-184-32:** Hide backend implementation details unless they explain trust, scope, or performance. It is acceptable to mention capped counts, scoped views, audited tables, and export auth boundaries when they affect what the operator can rely on. Avoid exposing query internals, trigger implementation, or raw storage jargon in primary copy.
- **D-184-33:** Preserve Threadline brand posture: calm under pressure, exact, useful over impressive, dense but scannable, color as signal not decoration, accessible focus/hover/disabled states, no decorative gradients/blobs, and cards only for repeated items or tools.

### Architecture And Implementation Posture

- **D-184-34:** Stay inside the existing private Phoenix LiveView component system. Prefer function components and focused helper extraction over new LiveComponents or public APIs unless a planner proves local state/event ownership needs it.
- **D-184-35:** Keep LiveView as orchestration/presentation. Do not move query authorization, export authorization, or durable semantics into the view. Existing context/controller/filter modules remain the authority for their boundaries.
- **D-184-36:** Preserve existing route paths, `data-testid`s, URL filter keys, feature gates, optional Phoenix/LiveView dependency boundaries, theme contract, and host-owned auth/export auth posture.
- **D-184-37:** Use current assets before inventing new abstractions: `TimelineLive`, `UI.field`, `UI.drawer`, `UI.pager`, `UI.ref`, `UI.empty_state`, `UI.loading_state`, `UI.stale_banner`, `Presentation`, `FilterParams`, existing Playwright suites, `style_contract_test`, and `/audit/__stress`.
- **D-184-38:** Do not introduce a new dependency, Tailwind/shadcn migration, client-side router, localStorage theme behavior, custom date picker, custom select, or visual regression SaaS for this phase.

### the agent's Discretion

The user explicitly asked for all gray areas to be considered with research-backed, cohesive recommendations. Downstream agents may choose exact plan count, task slicing, helper names, CSS selectors, and test organization if they preserve the decisions above and keep Phase 184 scoped to Timeline.

### Deferred Ideas (OUT OF SCOPE)

- Query-language power-user search (`table:`, `actor:`, `correlation:` qualifiers) is deferred. It may belong in a future search/power-user phase if operator demand appears.
- Persistent desktop filter side rail is deferred. It may be revisited if Timeline becomes a desktop analyst workspace rather than the mounted operator reference workflow.
- Dense fixed-column Timeline table is deferred. It may be useful for future sortable/comparable audit data, but it is not the right mobile-first investigation shape for Phase 184.
- Expandable row raw diff previews are deferred. Transaction/detail pages remain the right place for deeper raw change inspection in this milestone.
- Exports page IA and export-status workflow polish remain Phase 186.
- Coverage audit-readiness workflow polish remains Phase 185.
- Transaction, actor, standalone row-history, Evidence, Redaction, Retention, and Exports page polish remains Phase 186.
- Accessibility/motion/docs/adversarial closeout remains Phase 187, though Phase 184 must preserve Timeline accessibility and motion contracts.
- Broad visual-regression matrix or screenshot SaaS remains deferred unless a future milestone explicitly scopes stable cells and owners.
- Public component API, root Tailwind/shadcn migration, root PhoenixStorybook dependency, production Storybook/stress route, and runtime destructive redaction remain out of scope.
- No matching todo artifacts were found for Phase 184.
</user_constraints>

## Summary

Phase 184 should be planned as a bounded workflow refinement inside the existing mounted `/audit/timeline` LiveView, not as a new query surface, router change, component-library migration, or export redesign. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md] The current Timeline spine already includes URL-backed filter params, explicit Apply submit behavior, saved views, export handoff, streamed rows, long-ref rendering, empty variants, capped count copy, keyset pagination, and operator-route pivots. [VERIFIED: codebase grep]

The primary implementation risk is boundary drift: adding convenience in the LiveView can accidentally move filter parsing, export auth, host scoping, route semantics, or copy/truncation into the presentation layer. [VERIFIED: codebase grep] The planner should preserve existing ownership: `FilterParams` owns URL/export filter dialect, `Threadline.Query` owns audit reads, host-owned auth/scope callbacks own access, `ExportController` and `ExportAuthPlug` own direct downloads, `UI` and `Presentation` own private component/presentation primitives, and `TimelineLive` orchestrates rendering and route transitions. [VERIFIED: codebase grep]

External guidance supports the locked direction: LiveView patch navigation is the right primitive for same-LiveView URL state, Phoenix docs prefer function components unless stateful event ownership is needed, WCAG reflow guidance makes 320 CSS px proof mandatory for non-table layouts, APG dialog guidance makes drawer focus/escape/return a real acceptance criterion, and Playwright recommends behavior-first assertions over broad visual snapshot matrices. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html] [CITED: https://www.w3.org/WAI/WCAG21/Understanding/reflow.html] [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/] [CITED: https://playwright.dev/docs/best-practices]

**Primary recommendation:** Plan a small number of vertical Timeline workflow tasks: command hierarchy, row pivots, drawer handoff, state/copy lattice, and focused verification at 320, 375, 768, 1024, and 1440 px using existing LiveView tests plus narrow Playwright additions. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: codebase grep]

## Project Constraints (from CLAUDE.md)

- Keep Threadline's three layers separate: Capture owns persisted row mutation capture, Semantics owns action/actor/correlation meaning, and Exploration/operations owns Timeline, filters, exports, health, retention, redaction, coverage, and telemetry. [VERIFIED: CLAUDE.md]
- Use canonical domain language: `AuditTransaction`, `AuditChange`, `AuditAction`, `AuditContext`, `ActorRef`, and `Correlation`. [VERIFIED: CLAUDE.md]
- Prefer named verification entrypoints over ad hoc commands: `mix verify.format`, `mix verify.credo`, `mix verify.test`, and `mix ci.all`. [VERIFIED: CLAUDE.md]
- Keep default tests honest; do not silently exclude heavy suites from `mix test` without updating `test/test_helper.exs` and docs together. [VERIFIED: CLAUDE.md]
- Preserve stable CI job IDs, keep expensive path-filtered jobs running on `main`, and keep documentation contract tests aligned with docs. [VERIFIED: CLAUDE.md]
- Preserve key design constraints: correct by default, SQL-native, composable Plug/Phoenix/Ecto/Oban/LiveView integration, capture mechanism still TBD, and Threadline is not a SIEM, event-sourcing system, pgAudit replacement, or data warehouse. [VERIFIED: CLAUDE.md]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TIME-01 | Timeline presents one clear investigation workflow: filter, scan, open transaction or row history, and export the current view. [VERIFIED: .planning/REQUIREMENTS.md] | Plan around URL-backed filter command, scan-first row pivots, safe row-history links, and drawer/export handoff. [VERIFIED: codebase grep] |
| TIME-02 | Timeline controls, pager, saved-view affordances, empty/loading/error/stale states, long values, and mobile layouts remain readable and keyboard-operable under ugly real data. [VERIFIED: .planning/REQUIREMENTS.md] | Reuse `UI.drawer`, `UI.pager`, `UI.ref`, state primitives, `Presentation`, `/audit/__stress`, and responsive CSS contracts; add narrow browser proof at required widths. [VERIFIED: codebase grep] |
| TIME-03 | Timeline copy and micro-interactions are concise, on-brand, and useful under incident pressure without creating decorative motion or layout jumps. [VERIFIED: .planning/REQUIREMENTS.md] | Keep copy state-specific, use full-value copy controls only for useful refs, preserve reduced-motion/no-row-animation contracts, and test copy vocabulary/source contracts. [VERIFIED: codebase grep] |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| URL-backed filter state and route transitions | Frontend Server (Phoenix LiveView) | Browser / Client | LiveView `push_patch` and `handle_params/3` update current LiveView params without remounting and keep shareable state in the URL. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] |
| Filter parsing and export filter parity | API / Backend | Frontend Server (Phoenix LiveView) | `FilterParams` is the canonical Timeline/export filter dialect and prevents duplicate parsing in the LiveView. [VERIFIED: codebase grep] |
| Audit reads, count caps, and scoping | API / Backend | Database / Storage | `Threadline.Query` and scope callbacks own audited reads and host scoping; the LiveView should not bypass them. [VERIFIED: codebase grep] |
| Timeline row hierarchy and pivots | Frontend Server (Phoenix LiveView) | Browser / Client | Timeline owns presentation and route links while transaction, actor, correlation, and row-history destinations own deeper views. [VERIFIED: codebase grep] |
| Drawer utilities, saved views, and export handoff | Frontend Server (Phoenix LiveView) | API / Backend | The drawer presents utilities; saved views are actor-owned LiveView state, while export auth and direct downloads remain backend/controller boundaries. [VERIFIED: codebase grep] |
| Direct CSV/JSON/NDJSON downloads | API / Backend | Frontend Server (Phoenix LiveView) | Real HTTP download links route through the export controller and auth plug; the LiveView only renders affordances. [VERIFIED: codebase grep] |
| Copy controls and truncation | Frontend Server (Phoenix LiveView private components) | Browser / Client | `UI.ref` and `Presentation` render truncated labels while copy metadata preserves full values for client-side copy behavior. [VERIFIED: codebase grep] |
| Responsive layout, theme, motion, focus styling | Browser / Client | Frontend Server (Phoenix LiveView) | `style.ex` emits the operator CSS contract; LiveView supplies stable markup, labels, and state classes. [VERIFIED: codebase grep] |

## Standard Stack

### Core

| Library / Module | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| Phoenix | 1.8.7 locked in `mix.lock`; released 2026-05-06. [VERIFIED: mix.lock + Hex registry] | Host-mounted web/router/controller foundation for the operator surface. [VERIFIED: codebase grep] | Already used by the example app and operator router; do not upgrade or replace in Phase 184. [VERIFIED: codebase grep] |
| Phoenix LiveView | 1.1.30 locked in `mix.lock`; released 2026-05-05. [VERIFIED: mix.lock + Hex registry] | Server-rendered interactive Timeline, patch navigation, form submit, streamed rows, and LiveView tests. [VERIFIED: codebase grep] | Existing operator UI is LiveView-gated and private; docs support patch navigation for same-LiveView URL state. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] |
| Phoenix.Component function components | From Phoenix LiveView 1.1.30 lock; current docs checked against 1.2.3. [VERIFIED: mix.lock + Hex registry] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html] | Private UI primitives: `UI.field`, `UI.drawer`, `UI.pager`, `UI.ref`, `UI.empty_state`, `UI.loading_state`, `UI.stale_banner`. [VERIFIED: codebase grep] | Phoenix docs provide attrs/slots/global-attr contracts, and LiveComponent docs recommend function components when extra state/event ownership is not needed. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html] |
| Ecto SQL | 3.13.5 locked in `mix.lock`; released 2026-03-03. [VERIFIED: mix.lock + Hex registry] | Query layer and database access underneath Timeline reads, counts, and exports. [VERIFIED: codebase grep] | Threadline's audit data is SQL-native and queryable through existing contexts; Timeline should not hand-roll query semantics. [VERIFIED: CLAUDE.md] |
| Plug | 1.19.1 locked in `mix.lock`; released 2025-12-09. [VERIFIED: mix.lock + Hex registry] | Request/response and export-controller boundary for downloads and auth plugs. [VERIFIED: codebase grep] | Plug docs define connection/request-response primitives; existing export controller/auth plug own HTTP downloads. [CITED: https://plug.hexdocs.pm/Plug.Conn.html] |

### Supporting

| Library / Asset | Version | Purpose | When to Use |
|-----------------|---------|---------|-------------|
| `@playwright/test` | 1.60.0 installed in example `package-lock.json`; published 2026-05-11; latest checked 1.61.1 on 2026-06-28. [VERIFIED: npm registry + package-lock.json] | Browser proof for responsive layout, keyboard/focus, route transitions, no overflow, and copy controls. [VERIFIED: codebase grep] | Use existing E2E package; do not upgrade for this phase. [VERIFIED: package-lock.json] |
| `lazy_html` | 0.1.11 locked in root `mix.lock`. [VERIFIED: mix.lock] | HTML/source contract assertions in tests. [VERIFIED: codebase grep] | Use for source/HTML contract tests where LiveViewTest alone is less direct. [VERIFIED: codebase grep] |
| `/audit/__stress` and `StressFixtures` | Existing project assets, not external packages. [VERIFIED: codebase grep] | Shared ugly-data proof for generic component states. [VERIFIED: codebase grep] | Use only when Timeline renders a state directly or when a new Timeline stress cell is justified. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing LiveView URL patching | Client-side router or localStorage filter state | Rejected because Phase 184 requires shareable/recoverable URL state and existing routes; LiveView patch semantics already fit same-LiveView filter changes. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] |
| Private function components | New LiveComponents or public component API | Rejected unless stateful event ownership is proven; Phoenix docs say use LiveComponents when encapsulated state/event handling is needed, not for generic markup organization. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html] |
| Native date/select/form controls | Custom date picker, custom select, query-language command bar | Rejected by phase decisions and existing doc contracts; native controls reduce keyboard and mobile risk. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md] [VERIFIED: codebase grep] |
| Scan-first hybrid rows | Dense fixed-column table | Rejected for 320/375 px reflow risk and primary-pivot visibility. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md] [CITED: https://www.w3.org/WAI/WCAG21/Understanding/reflow.html] |
| Focused browser proof | Broad screenshot regression matrix | Rejected because Playwright guidance favors user-visible behavior assertions and context decisions defer broad screenshot matrices. [CITED: https://playwright.dev/docs/best-practices] [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md] |

**Installation:**

```bash
# No external package install for Phase 184.
# Use existing dependencies locked in mix.lock and examples/threadline_phoenix/e2e/package-lock.json.
```

**Version verification evidence:** Versions above were checked with `mix hex.info phoenix 1.8.7`, `mix hex.info phoenix_live_view 1.1.30`, `mix hex.info ecto_sql 3.13.5`, `mix hex.info plug 1.19.1`, and `npm view @playwright/test@1.60.0`. [VERIFIED: Hex registry] [VERIFIED: npm registry]

## Package Legitimacy Audit

Phase 184 should not install external packages; the Standard Stack is already present in `mix.lock` and `package-lock.json`. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md] [VERIFIED: mix.lock] [VERIFIED: package-lock.json]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| None planned | - | - | - | - | Not applicable | No install |

**Packages removed due to [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none.

*If a later plan proposes a new dependency, rerun the package-legitimacy gate before planning any install. [VERIFIED: gsd package legitimacy protocol]*

## Architecture Patterns

### System Architecture Diagram

```text
Operator enters /audit/timeline
        |
        v
TimelineLive mount
  - repo/scope/actor/theme/export assigns
  - covered table metadata
        |
        v
URL params? -- no --> push_patch default last-24h window
        | yes
        v
FilterParams.parse + safe validation
        |
        +--> invalid filter / unknown table / future window state
        |
        v
Threadline.Query timeline/count using scope-aware opts
        |
        v
Stream scan-first Audit Change rows
        |
        +--> visible actor/correlation URL pivots
        +--> primary transaction route
        +--> direct row-history route only when row identity is safe
        |
        v
Drawer utilities
  - advanced filters and saved views
  - Coverage/Evidence checks
  - Carry to Exports
  - Queue export
  - direct CSV/JSON/NDJSON links
        |
        +--> ExportController / ExportAuthPlug for direct downloads
        +--> ExportStatusLive for queued status
```

This diagram reflects the existing route/filter/query/export boundaries and the Phase 184 locked workflow. [VERIFIED: codebase grep] [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]

### Recommended Project Structure

```text
lib/threadline/operator_surface/
├── live/timeline_live.ex          # Orchestration, row hierarchy, drawer/handoff presentation
├── live/transaction_live.ex       # Primary transaction pivot destination
├── live/row_history_live.ex       # Direct row-history destination when safe
├── exports/filter_params.ex       # Canonical Timeline/export URL filter dialect
├── controllers/export_controller.ex # Direct HTTP download boundary
├── ui.ex                          # Private function components
├── presentation.ex                # Ref/truncation/copy label formatting helpers
└── style.ex                       # Operator CSS, responsive, focus, theme, motion contract

test/threadline/operator_surface/
├── live/timeline_live_test.exs
├── timeline_browse_doc_contract_test.exs
├── pager_test.exs
├── presentation_test.exs
├── copy_contract_test.exs
└── style_contract_test.exs

examples/threadline_phoenix/e2e/tests/
├── operator-responsive-mobile-first.spec.ts
├── operator-accessibility.spec.ts
├── operator-earned-flows.spec.ts
└── operator-find-mobile.spec.ts
```

This structure is existing and should be extended in place rather than replaced. [VERIFIED: codebase grep]

### Pattern 1: URL-As-State With Batch Apply

**What:** Keep filters in URL params, parse them in `handle_params/3`, and update them with form submit plus `push_patch`. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html]

**When to use:** Any filter that changes Timeline results or export handoff context. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]

**Example:**

```elixir
# Source: lib/threadline/operator_surface/live/timeline_live.ex [VERIFIED: codebase grep]
def handle_event("apply", %{"filter" => raw}, socket) do
  query =
    raw
    |> FilterParams.canonical_query_from_raw(socket.assigns.default_from, socket.assigns.default_to)

  {:noreply, push_patch(socket, to: ~p"/audit/timeline?#{query}")}
end
```

Planning rule: preserve batch submit and do not add `phx-change` to Timeline filters. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]

### Pattern 2: Row-First Scan Surface With Visible Pivots

**What:** Rows should lead with operation/table/time and keep transaction, actor, correlation, and safe row-history pivots visible without overflow menus. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]

**When to use:** Any change to Timeline row hierarchy, copy controls, or action placement. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```elixir
# Source: lib/threadline/operator_surface/live/timeline_live.ex [VERIFIED: codebase grep]
<.link navigate={~p"/audit/transactions/#{entry.audit_transaction_id}"}>
  Open transaction
</.link>

<%= if entry.correlation_id do %>
  <UI.ref value={entry.correlation_id} copy_label="Copy correlation id" />
  <.link navigate={correlation_path(entry.correlation_id)}>Filter by correlation</.link>
<% end %>
```

Planning rule: add direct row-history only when the row has a safe routeable identity; otherwise leave transaction as the safe pivot. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]

### Pattern 3: Drawer as Utility Sheet, Not Primary Workflow

**What:** Keep secondary filters, saved views, Coverage/Evidence checks, export carry/queue/download affordances in `UI.drawer`. [VERIFIED: codebase grep] [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]

**When to use:** Any utility that helps refine, save, or hand off the current view but is not needed for the first scan. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]

**Example:**

```elixir
# Source: lib/threadline/operator_surface/live/timeline_live.ex [VERIFIED: codebase grep]
<UI.drawer id="timeline-filters-drawer" title="Refine timeline">
  <.form id="timeline-filters" phx-submit="apply">
    <UI.field field={@filter_form[:actor_kind]} label="Actor kind" />
    <UI.field field={@filter_form[:actor_id]} label="Actor id" />
  </.form>
  <.link navigate={~p"/audit/exports?#{@canonical_query}"}>Carry to Exports</.link>
</UI.drawer>
```

Planning rule: drawer keyboard behavior is not decorative; APG dialog guidance requires focus moves inside, Escape closes, Tab stays contained while open, and focus returns to the invoker. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/]

### Pattern 4: State Lattice Copy, Not Generic Error Text

**What:** Timeline must distinguish first-run empty, filtered no-data, future-window, unknown table, invalid filter, scoped caveat, export unavailable/denied, background export failure, large/capped results, stale data, and long values. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]

**When to use:** Any empty/error/loading/stale/export state rendered on Timeline. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```elixir
# Source: lib/threadline/operator_surface/ui.ex [VERIFIED: codebase grep]
<UI.empty_state
  title="No changes match these filters"
  description="Widen the time window or clear a filter to keep investigating."
/>
```

Planning rule: stale trust states must label last-good data instead of replacing it when safe last-good data exists. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]

### Anti-Patterns to Avoid

- **Per-keystroke Timeline filtering:** `phx-change` would violate the locked batch-Apply workflow and can create expensive scan churn. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix_live_view/form-bindings.html]
- **LiveView-owned security:** Hiding buttons in the LiveView is not export auth; direct downloads must remain protected by controller/auth boundaries. [VERIFIED: codebase grep]
- **Second filter dialect:** Duplicating filter parsing in Timeline risks diverging from export parity. [VERIFIED: codebase grep]
- **Dense table at narrow widths:** A fixed-column audit table invites two-dimensional scrolling and raw-ID overload on 320/375 px. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md] [CITED: https://www.w3.org/WAI/WCAG21/Understanding/reflow.html]
- **Truncated copy values:** Visible truncated refs are acceptable; copied values must be full exact refs. [VERIFIED: codebase grep]
- **Decorative row motion:** High-frequency streamed Timeline rows must remain static and reduced-motion safe. [VERIFIED: codebase grep] [CITED: https://www.w3.org/WAI/WCAG21/Understanding/animation-from-interactions.html]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Timeline/export filter parsing | Ad hoc params parsing in `TimelineLive` | `Threadline.OperatorSurface.Exports.FilterParams` | Keeps URL and export filter parity in one allowlisted dialect. [VERIFIED: codebase grep] |
| Query authorization/scoping | Direct repo queries in LiveView | `Threadline.Query` plus `scope_aware_opts/1` and host scope callbacks | Preserves host-owned scoping and audited read semantics. [VERIFIED: codebase grep] |
| Direct downloads | LiveView-generated file responses | `ExportController` plus `ExportAuthPlug` | HTTP downloads, auth, and filter parity belong at the controller/backend boundary. [VERIFIED: codebase grep] |
| Drawer/focus behavior | Custom client widget | `UI.drawer` plus existing browser focus tests | APG dialog guidance requires specific focus, Escape, labelling, and return behavior. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/] |
| Ref truncation/copy | Inline string slicing/copy attributes | `Presentation.ref` and `UI.ref` | Existing helpers preserve readable labels and full exact copy values. [VERIFIED: codebase grep] |
| Pagination controls | New pager markup | `UI.pager` | Existing pager hides at zero, exposes disabled states, count copy, and role/status semantics. [VERIFIED: codebase grep] |
| Browser proof | Screenshot matrix or pixel tests for every state | Existing Playwright suites with focused additions | Playwright docs recommend user-visible behavior and reliable locators over broad implementation checks. [CITED: https://playwright.dev/docs/best-practices] [CITED: https://playwright.dev/docs/locators] |

**Key insight:** Phase 184 succeeds by composing existing private operator primitives around a clearer Timeline workflow; custom widgets or new dependencies add risk without addressing TIME-01 through TIME-03. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md] [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Turning Timeline Into a Filter Console

**What goes wrong:** Too many inline filters push rows below the first viewport and make incident scanning slower. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]

**Why it happens:** Implementers try to expose every backend filter equally instead of preserving the selected starter set. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]

**How to avoid:** Keep `from`, `to`, `table`, and `correlation_id` inline; keep schema/actor/saved views/handoff in the drawer. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]

**Warning signs:** Rows are not visible early at 320/375/768 px, filter grid needs horizontal scroll, or the drawer duplicates primary Apply/reset controls. [VERIFIED: .planning/REQUIREMENTS.md]

### Pitfall 2: Breaking URL/Back-Button Semantics

**What goes wrong:** Filters become local form state, browser back no longer restores investigations, or exports receive stale context. [VERIFIED: codebase grep]

**Why it happens:** Adding `phx-change`, client storage, or local-only assigns bypasses canonical URL params. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]

**How to avoid:** Keep form submit -> canonical query -> `push_patch` -> `handle_params/3` as the path for result-changing filters. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html]

**Warning signs:** Tests need to read hidden assigns instead of URLs, unknown params persist, or exports no longer match Timeline filters. [VERIFIED: codebase grep]

### Pitfall 3: Unsafe Direct Row-History Links

**What goes wrong:** Timeline links to row history for composite, missing, unsupported, or ambiguous row identity. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]

**Why it happens:** Row-history convenience is added without checking available identity fields and route encoding rules. [VERIFIED: codebase grep]

**How to avoid:** Gate direct row-history links behind a single safe routeable identity; otherwise show only the transaction pivot. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]

**Warning signs:** Link construction happens with nil ids, composite ids are string-concatenated, or row-history route tests only cover happy-path UUID rows. [VERIFIED: codebase grep]

### Pitfall 4: Copying the Label Instead of the Value

**What goes wrong:** Operators copy truncated refs or ambiguous labels into tickets. [VERIFIED: codebase grep]

**Why it happens:** Copy code is attached to visible text instead of the full-value helper. [VERIFIED: codebase grep]

**How to avoid:** Use `UI.ref` or equivalent full-value `data-tl-copy` contract with specific accessible labels. [VERIFIED: codebase grep]

**Warning signs:** Tests assert only visible text, long refs lose tails, or copy buttons share generic "Copy" labels. [VERIFIED: codebase grep]

### Pitfall 5: Treating Stale, Empty, Error, and Scoped States as Interchangeable

**What goes wrong:** Operators cannot tell whether there are no audit records, no matches, a future time window, an invalid table, or a scoped result set. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]

**Why it happens:** Generic empty/error copy is reused across different trust states. [CITED: https://carbondesignsystem.com/patterns/empty-states-pattern/]

**How to avoid:** Implement the Timeline state lattice and give each state what happened, why if known, and a next action. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md] [CITED: https://carbondesignsystem.com/patterns/empty-states-pattern/]

**Warning signs:** Same title appears for filtered no-data and first-run no-data, or stale reconnect copy replaces last-good rows. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]

## Code Examples

Verified patterns from project sources and official docs:

### LiveView Patch Navigation

```elixir
# Source: lib/threadline/operator_surface/live/timeline_live.ex [VERIFIED: codebase grep]
{:noreply, push_patch(socket, to: ~p"/audit/timeline?#{query}", replace: true)}
```

LiveView docs describe patch navigation as same-LiveView navigation that updates URL/params and invokes `handle_params/3` without remounting the LiveView. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html]

### Function Component Reuse

```elixir
# Source: lib/threadline/operator_surface/live/timeline_live.ex [VERIFIED: codebase grep]
<UI.field field={@filter_form[:correlation_id]} label="Correlation id" />
<UI.pager id="timeline-pager" cursor={@cursor} total_count={@matching_count} />
<UI.ref value={entry.correlation_id} copy_label="Copy correlation id" />
```

Phoenix.Component docs define function components, attributes, slots, and global attrs; LiveComponent docs recommend LiveComponents only when state/event encapsulation is needed. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html]

### LiveViewTest Element-Scoped Interaction

```elixir
# Source pattern: test/threadline/operator_surface/live/timeline_live_test.exs [VERIFIED: codebase grep]
view
|> element("form#timeline-filters")
|> render_submit(%{"filter" => %{"table" => "accounts"}})
```

LiveViewTest docs support `element/3` plus `render_submit/2`, `render_click/2`, and related helpers for asserting user-visible LiveView events. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]

### Playwright Behavior Proof

```typescript
// Source pattern: examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts [VERIFIED: codebase grep]
await page.getByRole('button', { name: /filters/i }).click();
await expect(page.getByRole('dialog', { name: /refine timeline/i })).toBeVisible();
await page.keyboard.press('Escape');
await expect(page.getByRole('dialog', { name: /refine timeline/i })).toBeHidden();
```

Playwright docs recommend locators that reflect user-visible roles/text and web-first assertions that wait for expected UI state. [CITED: https://playwright.dev/docs/best-practices] [CITED: https://playwright.dev/docs/locators]

## State of the Art

| Old Approach | Current Approach | When Changed / Verified | Impact |
|--------------|------------------|--------------------------|--------|
| Local/client-only filter state | URL-backed LiveView patch state | Verified against Phoenix LiveView docs on 2026-06-28. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] | Enables shareable investigations, back-button recovery, and export parity. [VERIFIED: codebase grep] |
| Stateful components for markup organization | Function components unless local state/event ownership is required | Verified against Phoenix LiveComponent docs on 2026-06-28. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html] | Keeps private UI simple and avoids unnecessary component state. [VERIFIED: codebase grep] |
| Broad screenshot baselines | Behavior-first Playwright proof plus source contracts | Verified against Playwright docs on 2026-06-28. [CITED: https://playwright.dev/docs/best-practices] | Reduces brittle visual maintenance while still proving workflow, keyboard, overflow, and route behavior. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md] |
| Generic empty/error messages | Specific state lattice with next action | Verified against Carbon empty-state guidance on 2026-06-28. [CITED: https://carbondesignsystem.com/patterns/empty-states-pattern/] | Operators can distinguish no data, no matches, future windows, invalid filters, scoped results, and stale trust states. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md] |
| Decorative streamed-row motion | Static high-frequency rows plus focus/hover/status affordances | Verified against project CSS contracts and WCAG animation guidance. [VERIFIED: codebase grep] [CITED: https://www.w3.org/WAI/WCAG21/Understanding/animation-from-interactions.html] | Prevents layout jumps and supports reduced-motion users. [VERIFIED: .planning/REQUIREMENTS.md] |

**Deprecated/outdated:**

- Query-language command bar for this phase: deferred by user decision because qualifier grammar is too much under incident pressure. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]
- Dense fixed-column Timeline table for this phase: deferred by user decision because mobile reflow and raw-ID overload are higher risk than desktop alignment benefit. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]
- Broad screenshot matrix for this phase: deferred by user decision and contradicted by Playwright behavior-first guidance. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md] [CITED: https://playwright.dev/docs/best-practices]

## Assumptions Log

All claims in this research were verified from project files, registry commands, or cited official documentation during this session. [VERIFIED: codebase grep] [VERIFIED: Hex registry] [VERIFIED: npm registry] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html]

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| - | None | - | - |

## Open Questions

1. **What exact row identity should qualify as safe for direct Timeline row-history links?**
   - What we know: User decisions require direct row-history only when the row has a safe routeable row identity. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]
   - What's unclear: The planner must inspect current row entry shape and route builder behavior before deciding whether single-column ids, table schema, or encoded table refs are enough. [VERIFIED: codebase grep]
   - Recommendation: Add a helper and tests that return `nil` for missing/composite/unsupported identities, then render no direct row-history action in that case. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]

2. **Should 320 and 1440 px proof extend the existing responsive matrix or live in a Phase 184-specific spec?**
   - What we know: Existing Playwright responsive coverage includes 375, 768, 1024, and 1280 px, while Phase 184 success criteria require 320, 375, 768, 1024, and 1440 px. [VERIFIED: codebase grep] [VERIFIED: .planning/REQUIREMENTS.md]
   - What's unclear: Extending the shared matrix may increase runtime for unrelated pages. [VERIFIED: codebase grep]
   - Recommendation: Add a narrow Timeline-only test for 320 and 1440 if widening the shared matrix creates too much browser runtime. [CITED: https://playwright.dev/docs/best-practices]

3. **How should stale/last-good Timeline data be triggered in tests?**
   - What we know: `UI.stale_banner` exists, and user decisions require stale data not to replace last-good data unless no safe data exists. [VERIFIED: codebase grep] [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]
   - What's unclear: Timeline may not currently have a dedicated async stale branch beyond shared component primitives. [VERIFIED: codebase grep]
   - Recommendation: If Phase 184 renders stale state directly, test the real branch; otherwise cite shared component/stress proof and avoid fabricating a fake Timeline stale path. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix | LiveView tests and project verification | Yes | Elixir 1.19.5 / Mix 1.19.5. [VERIFIED: command probe] | None needed |
| Erlang / OTP | Elixir runtime | Yes | OTP 28. [VERIFIED: command probe] | None needed |
| PostgreSQL | Example app and browser tests | Yes | `pg_isready` reports localhost `/tmp:5432` accepting connections; `psql` 14.17 installed. [VERIFIED: command probe] | Planner can use existing local service |
| Node.js | Playwright E2E | Yes | v22.14.0. [VERIFIED: command probe] | None needed |
| npm | Playwright package scripts | Yes | 11.1.0. [VERIFIED: command probe] | None needed |
| Playwright CLI | Browser proof | Yes | 1.60.0 in `examples/threadline_phoenix/e2e/node_modules`. [VERIFIED: command probe] | Use `npm install` only if local node_modules is removed |
| Docker | Optional local services | Yes | 29.5.2. [VERIFIED: command probe] | Not required for default plan |
| git | GSD docs commit | Yes | 2.41.0. [VERIFIED: command probe] | None needed |

**Missing dependencies with no fallback:** none found. [VERIFIED: command probe]

**Missing dependencies with fallback:** none found. [VERIFIED: command probe]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit through Mix plus Phoenix.LiveViewTest 1.1.30 lock; Playwright 1.60.0 for browser proof. [VERIFIED: mix.lock] [VERIFIED: package-lock.json] |
| Config file | Root `mix.exs` aliases; `examples/threadline_phoenix/e2e/playwright.config.ts`. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/timeline_browse_doc_contract_test.exs test/threadline/operator_surface/pager_test.exs test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/exports/filter_params_test.exs` [VERIFIED: codebase grep] |
| Full suite command | `mix verify.format && mix verify.credo && mix verify.test && mix verify.example_browser -- operator-responsive-mobile-first.spec.ts operator-accessibility.spec.ts operator-earned-flows.spec.ts operator-find-mobile.spec.ts` [VERIFIED: mix.exs] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| TIME-01 | Filter -> scan -> open transaction/row history -> export current view | LiveView integration + Playwright earned flow | `mix test test/threadline/operator_surface/live/timeline_live_test.exs && mix verify.example_browser -- operator-earned-flows.spec.ts operator-find-mobile.spec.ts` | Yes, with row-history direct-link gap to review. [VERIFIED: codebase grep] |
| TIME-02 | Controls, pager, saved views, empty/loading/error/stale states, long values, mobile, keyboard | LiveView/source contracts + Playwright responsive/a11y | `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/pager_test.exs test/threadline/operator_surface/style_contract_test.exs && mix verify.example_browser -- operator-responsive-mobile-first.spec.ts operator-accessibility.spec.ts` | Yes, with 320/1440 gap. [VERIFIED: codebase grep] |
| TIME-03 | Concise copy, micro-interactions, no decorative motion or layout jumps | Source contract + Playwright motion/responsive checks | `mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/style_contract_test.exs && mix verify.example_browser -- operator-motion.spec.ts operator-responsive-mobile-first.spec.ts` | Yes. [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** Run the quick Mix command above and the narrow browser spec touched by the task. [VERIFIED: CLAUDE.md] [VERIFIED: mix.exs]
- **Per wave merge:** Run the full suite command above. [VERIFIED: mix.exs]
- **Phase gate:** Run `mix ci.all` when browser/runtime cost is acceptable; otherwise run `mix verify.format`, `mix verify.credo`, `mix verify.test`, `mix verify.example_browser`, and document any skipped gate with reason. [VERIFIED: CLAUDE.md] [VERIFIED: mix.exs]

### Wave 0 Gaps

- [ ] `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` or a narrow Timeline spec must cover 320 and 1440 px because existing responsive proof covers 375, 768, 1024, and 1280 px. [VERIFIED: codebase grep] [VERIFIED: .planning/REQUIREMENTS.md]
- [ ] `test/threadline/operator_surface/live/timeline_live_test.exs` needs explicit safe/unsafe row-history direct-link coverage if implementation changes Timeline row actions. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]
- [ ] Browser proof should cover keyboard-only operation for filters, rows, copy controls, pagination, drawer close/return, and route transitions; existing a11y specs cover parts of this but Phase 184 criteria are broader. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: codebase grep]
- [ ] If Timeline renders stale/last-good state directly, add LiveView/source coverage for that real branch; if it does not, rely on shared state primitive/stress proof and do not invent a fake path. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | Yes | Host-owned operator auth/session context remains outside Timeline; Phase 184 must not weaken mount/auth assumptions. [VERIFIED: codebase grep] |
| V3 Session Management | Yes | Phoenix/Plug session and assigns carry actor/theme/scope context; do not add localStorage auth or client-only state. [VERIFIED: codebase grep] |
| V4 Access Control | Yes | Use host scope callbacks for reads and `ExportAuthPlug`/controller auth for direct downloads; LiveView visibility is not a security boundary. [VERIFIED: codebase grep] |
| V5 Input Validation | Yes | Use `FilterParams`, allowlisted URL keys, existing validation, native inputs, and no unsafe atom creation. [VERIFIED: codebase grep] |
| V6 Cryptography | No new cryptography | Do not hand-roll tokens, signing, or encryption in Phase 184; rely on Phoenix/Plug/session/export auth boundaries already present. [VERIFIED: codebase grep] |

### Known Threat Patterns for Phoenix LiveView Timeline

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Scope bypass / IDOR through row or export pivots | Elevation of privilege / Information disclosure | Always use scoped query opts and controller export auth; never trust LiveView button visibility as authorization. [VERIFIED: codebase grep] |
| Filter-param injection or atom exhaustion | Denial of service / Tampering | Keep allowlisted `FilterParams` parsing and avoid `String.to_atom`; existing parser uses safe normalization patterns. [VERIFIED: codebase grep] |
| Export filter mismatch | Information disclosure | Generate direct download and carry URLs from the same canonical query used by Timeline. [VERIFIED: codebase grep] |
| XSS or malformed refs in copy/links | Tampering / Information disclosure | Use HEEx escaping, route helpers, and `UI.ref` full-value copy rather than raw HTML interpolation. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html] [VERIFIED: codebase grep] |
| Trust confusion during stale/reconnect states | Information disclosure / Repudiation | Label last-good data clearly and offer refresh/retry; do not silently replace safe data with stale/untrusted states. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md] |
| Keyboard trap in drawer | Denial of service / Accessibility failure | Follow APG dialog focus trapping, Escape close, and focus return behavior. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/184-timeline-investigation-flow/184-CONTEXT.md` - locked user decisions, discretion, deferred ideas, canonical refs. [VERIFIED: file read]
- `.planning/REQUIREMENTS.md` - TIME-01, TIME-02, TIME-03. [VERIFIED: file read]
- `CLAUDE.md` - project architecture, domain language, verification constraints. [VERIFIED: file read]
- `lib/threadline/operator_surface/live/timeline_live.ex` - Timeline LiveView implementation spine. [VERIFIED: codebase grep]
- `lib/threadline/operator_surface/ui.ex` - private UI components. [VERIFIED: codebase grep]
- `lib/threadline/operator_surface/presentation.ex` - truncation/ref/label helpers. [VERIFIED: codebase grep]
- `lib/threadline/operator_surface/exports/filter_params.ex` - canonical filter dialect. [VERIFIED: codebase grep]
- `lib/threadline/operator_surface/style.ex` - responsive/theme/motion/focus CSS contract. [VERIFIED: codebase grep]
- `test/threadline/operator_surface/live/timeline_live_test.exs` and related operator tests - existing verification surface. [VERIFIED: codebase grep]
- `mix.lock`, `mix hex.info`, `package-lock.json`, and `npm view` - locked and registry-verified versions. [VERIFIED: Hex registry] [VERIFIED: npm registry]

### Secondary (MEDIUM confidence)

- `https://hexdocs.pm/phoenix_live_view/live-navigation.html` - LiveView patch/navigate and URL state semantics. [CITED: official docs]
- `https://hexdocs.pm/phoenix_live_view/form-bindings.html` - `phx-submit` and `phx-change` form behavior. [CITED: official docs]
- `https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html` - function component attrs/slots/global attrs. [CITED: official docs]
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html` - when to use LiveComponents versus function components. [CITED: official docs]
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html` - LiveView test interaction helpers. [CITED: official docs]
- `https://plug.hexdocs.pm/Plug.Conn.html` - Plug request/response and controller boundary primitives. [CITED: official docs]
- `https://www.w3.org/WAI/WCAG21/Understanding/reflow.html` - reflow and narrow-width expectations. [CITED: W3C]
- `https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/` - dialog focus, Escape, and return behavior. [CITED: W3C]
- `https://www.w3.org/WAI/WCAG21/Understanding/focus-visible.html` - visible focus. [CITED: W3C]
- `https://www.w3.org/WAI/WCAG21/Understanding/use-of-color.html` - color not sole signal. [CITED: W3C]
- `https://www.w3.org/WAI/WCAG21/Understanding/animation-from-interactions.html` - reducible interaction motion. [CITED: W3C]
- `https://carbondesignsystem.com/patterns/filtering/` - filtering and batch state clarity. [CITED: official design-system docs]
- `https://carbondesignsystem.com/patterns/empty-states-pattern/` - specific empty-state copy and recovery guidance. [CITED: official design-system docs]
- `https://playwright.dev/docs/best-practices` - behavior-first browser testing guidance. [CITED: official docs]
- `https://playwright.dev/docs/locators` - resilient user-facing locators. [CITED: official docs]

### Tertiary (LOW confidence)

- None. All non-project claims used in recommendations came from official docs or registry/codebase verification during this session. [VERIFIED: research notes]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - existing locked dependencies and registry versions were verified; no new packages are recommended. [VERIFIED: mix.lock] [VERIFIED: Hex registry] [VERIFIED: npm registry]
- Architecture: HIGH - existing source files and user decisions clearly define ownership boundaries. [VERIFIED: codebase grep] [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md]
- Pitfalls: MEDIUM - pitfalls are derived from locked phase decisions, source contracts, and official docs; some row-history safety details require implementation-time inspection. [VERIFIED: .planning/phases/184-timeline-investigation-flow/184-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html]
- Accessibility/browser proof: MEDIUM - official WCAG/APG/Playwright docs were cited, and existing tests were inspected, but exact Phase 184 browser additions remain planning work. [CITED: https://www.w3.org/WAI/WCAG21/Understanding/reflow.html] [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/] [CITED: https://playwright.dev/docs/best-practices]

**Research date:** 2026-06-28
**Valid until:** 2026-07-28 for project structure and locked stack; 2026-07-05 for Playwright/npm latest-version freshness. [VERIFIED: npm registry]
