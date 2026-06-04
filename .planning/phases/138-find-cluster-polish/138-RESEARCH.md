# Phase 138: find-cluster-polish - Research

**Researched:** 2026-06-04
**Domain:** Phoenix LiveView operator-surface UI polish
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

## Implementation Decisions

### 1. Find cluster model
- **D-01:** Treat Phase 138 as the Find investigation path, not five unrelated pages. Timeline owns the filtered result set and active investigation context; Transaction explains what changed together; Row-history explains point-in-time record state; Actor explains touched-record blast radius; Coverage explains whether Timeline answers are complete enough to trust.
- **D-02:** Keep the operator's next pivot visible and conventional: `Open transaction`, `Open row history`, `Open in timeline`, `Queue export`, `View activity`, or `Add capture` guidance. Do not invent new flow labels that imply Phase 140 capabilities.
- **D-03:** The Find cluster serves P1/P2 incident and support lookup jobs first, while Coverage serves P4 operational confidence. Product language should reinforce Threadline's brand promise: make system history followable under pressure.

### 2. Timeline journey and dense-first treatment
- **D-04:** Use the hybrid recommendation from advisor research: demote the `FIND / EXPLAIN / PACKAGE` journey strip by default unless a label can link to a real existing destination. It must not look like clickable stat cards when it is inert.
- **D-05:** Do not make `PACKAGE` imply the Phase 140 closed export loop. In Phase 138, packaging remains the existing Timeline export affordance or existing Exports surface only.
- **D-06:** Make dense and mobile Timeline states show the active filter summary and rows sooner. Orientation chrome can remain, but it must not become the first-scan handle or push useful results far below the fold.
- **D-07:** Empty Timeline copy uses the locked recovery nudge: widen the time range, clear the table filter, or explain future-window emptiness when matching data exists outside the selected window. Scoped views must keep the authorized-record caveat.
- **D-08:** Disabled anonymous actor-id input gets an inline `n/a for anonymous` hint. Long correlation IDs and table names use middle truncation, full `title`, and copy affordance where interactive.

### 3. Diff and value primitive convergence
- **D-09:** Add shared pure value-formatting helpers in `Threadline.OperatorSurface.Presentation` for UI value semantics, while keeping Transaction and Row-history markup local. This is value convergence, not a new component framework.
- **D-10:** The value helper must distinguish absent, present `nil`, omitted/prior-state, redacted strings, timestamps, booleans/numbers, maps/lists, and ordinary strings. Do not collapse these into `inspect/1` output.
- **D-11:** Transaction INSERT rows render inserted column values when `field_changes` has `after` values. If no fields exist, render diagnostic empty copy tied to capture/coverage, not a blank diff area.
- **D-12:** Transaction before/after rows use an explicit `before -> after` treatment. Row-history snapshots use the same value tokens but remain stable sorted key/value rows, not transaction-style diffs.
- **D-13:** Row-history snapshot values render muted `null` for nil and formatted timestamps instead of raw `nil` or quoted ISO strings. String values remain HTML-escaped and deterministic.

### 4. Coverage remediation model
- **D-14:** Move repeated consequence copy such as `Timeline may be incomplete` out of each row action cell and into a section-level callout. Action cells contain actions or compact remediation only.
- **D-15:** Uncovered Coverage rows get a compact real remediation affordance: prefer `Add capture` guidance with a copyable or revealable CLI command/hint. `View activity` may stay secondary when it is useful, but it is not a substitute for remediation.
- **D-16:** The browser must not pretend it can mutate host code. `Add capture` is guidance, not an in-browser fix. Copy should point to the Mix-task/migration path and verify-coverage follow-up.
- **D-17:** Expected gaps get deliberate muted/warning treatment, not neutral bare text. They do not get the same urgent fix action as uncovered rows; they can expose source/reason and `View activity` when appropriate.
- **D-18:** Fix Coverage grammar and count ownership: `1 expected gap`, `2 expected gaps`, and avoid echoing the same readiness count across multiple equally strong UI elements.

### 5. Actor blast-radius rows
- **D-19:** Use transaction-led Actor rows with compact inline blast-radius metadata. Example shape: `UPDATE tickets - 3 changes - Transaction <id>`. For mixed transactions: `UPDATE tickets + 2 tables - 7 changes`.
- **D-20:** Keep detailed field proof behind `Open transaction`; Actor rows are summaries, not mini transaction reports.
- **D-21:** Avoid N+1 queries and public API churn. If row summaries require visible-page preloads or a focused presenter/helper, keep that local to the operator surface unless planning proves a reusable query boundary is necessary.
- **D-22:** If summary data is unavailable, render an honest fallback such as `Changes unavailable` plus `Open transaction`; do not show only the first table/op without a `+ N tables` indicator.
- **D-23:** Actor time-window segmented controls must expose selected state with `[aria-pressed="true"]` Thread Blue active styling already established by Phase 136/138 UI contracts.

### 6. Primitive strictness and implementation shape
- **D-24:** Prefer pure `Presentation` helpers for derived labels, secondary refs, value tokens, coverage remediation labels, actor transaction summaries, count grammar, and truncation metadata.
- **D-25:** Prefer small Phoenix function components only when repeated markup appears in 2+ Find surfaces. Do not introduce LiveComponents for static organization or a broad component system.
- **D-26:** CSS stays scoped in `Threadline.OperatorSurface.Style` with `.threadline-ui` / `.tl-*`. New classes must be token-backed, dark-first, accessible on hover/focus, and consistent with the brand book's composed, precise, non-flashy direction.
- **D-27:** Keep LiveViews thin. LiveViews orchestrate assigns, streams, URL state, and events; presentation helpers/components own display decisions; query/domain changes remain out of scope unless required to close a locked finding without N+1 behavior.

### the agent's Discretion

- Exact helper names and module grouping are left to planning. Bias toward `Presentation` helper functions first; extract function components only after repeated markup is obvious.
- Exact Timeline layout order can be finalized with screenshots, provided rows appear sooner and the journey strip no longer reads as inert clickable cards.
- Exact Coverage command copy can be finalized during planning after verifying the existing generator/task syntax. The UI must avoid commands that interpolate `schema.table` incorrectly.
- Exact Actor summary computation can be finalized during planning, provided summaries do not cause N+1 queries, public API churn, or misleading first-table-only labels.

### Deferred Ideas (OUT OF SCOPE)

- Home record-first lookup, Home correlation paste/deep-link, first-class row-history entry from Home, and closed Timeline/Evidence to Exports loop remain Phase 140 earned flows.
- Broad mobile nav architecture and full responsive sweep remain Phase 142, except local Phase 138 fixes needed to make Timeline dense/mobile states scannable.
- Full accessibility sweep remains Phase 143, though Phase 138 must preserve labels, focus rings, non-color-only status meaning, and hit targets.

### Reviewed Todos (not folded)
- `Capture direct demo and UI polish` — matched Phase 138 only by the generic keyword `polish` with score 0.2. Reviewed but not folded; it is milestone background already represented by Phase 134 audit, Phase 135 seed/IA lock, Phase 136 design-system hardening, and the Phase 138 UI-SPEC.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| POLISH-FIND | Timeline, Transaction, Row-history, and Actor reach the consistent baseline; Timeline dense/error/mobile states are correct; filter/diff/correlation interactions are consistent. | The current code audit identifies the exact files, primitive gaps, helper insertion points, and focused LiveView/Playwright tests needed to close F-201(render), F-401 through F-405, F-501/F-502/F-504/F-505, and F-701 through F-706. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 138 should be planned as a Find-cluster convergence pass over existing Phoenix LiveView surfaces, not as feature expansion. The reliable path is: add shared pure presentation helpers first, then apply them to Transaction/Row-history value rendering, Timeline dense/error/mobile and truncation states, Actor blast-radius rows, and Coverage remediation copy. This matches the locked context and avoids new backend behavior, routes, schemas, Tailwind, shadcn, icon dependencies, and Phase 140 earned flows. [VERIFIED: `.planning/phases/138-find-cluster-polish/138-CONTEXT.md`; `.planning/phases/138-find-cluster-polish/138-UI-SPEC.md`; `.planning/REQUIREMENTS.md`]

The highest-risk planning area is Actor row summaries. `Threadline.actor_history/2` returns `AuditTransaction` structs, while detailed row changes live behind transaction/bundle queries; the plan must either preload summaries for only the visible page or render an honest `Changes unavailable` fallback without creating N+1 queries or public API churn. [VERIFIED: `lib/threadline/query.ex`; `lib/threadline/operator_surface/live/actor_live.ex`; `.planning/phases/138-find-cluster-polish/138-CONTEXT.md`]

**Primary recommendation:** Use four slices: shared helper/style foundations, Transaction + Row-history value convergence, Timeline dense/error/mobile/truncation, then Actor + Coverage remediation with Playwright Find mobile UAT. [VERIFIED: codebase grep]

## Project Constraints (from AGENTS.md)

No `./AGENTS.md` exists in the repository root, so there are no additional AGENTS.md directives to apply. [VERIFIED: shell check]

No `.codex/skills/` or `.agents/skills/` project skill directory exists, so there are no project-local skill rules to load. [VERIFIED: shell check]

## Graph Context

No `.planning/graphs/graph.json` exists, so graph context was unavailable and semantic relationships were derived from planning artifacts plus code inspection. [VERIFIED: shell check]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Timeline filtering, URL state, dense/error/mobile rendering | Frontend Server (Phoenix LiveView) | Database / Storage | `TimelineLive` parses URL params, owns form state, streams row entries, and delegates query execution to `Threadline.Query`/`Threadline.Export`; Phase 138 should alter display/copy/layout only. [VERIFIED: `timeline_live.ex`] |
| Transaction diff rendering | Frontend Server (Phoenix LiveView) | API / Backend | `TransactionLive` receives `incident_bundle/2` output and renders `change_diff["field_changes"]`; value formatting belongs in `Presentation`, not the query layer. [VERIFIED: `transaction_live.ex`; `investigation.ex`] |
| Row-history snapshot rendering | Frontend Server (LiveComponent) | API / Backend | `RowHistoryComponent` calls `Threadline.history/3` and `Threadline.as_of/4`, then renders a local KV snapshot; Phase 138 should format values, not change history semantics. [VERIFIED: `row_history_component.ex`] |
| Actor blast-radius summaries | Frontend Server (Phoenix LiveView) | Database / Storage | `ActorLive` streams actor transactions from `Threadline.actor_history/2`; any per-row summary must stay bounded to visible entries or be presented as unavailable. [VERIFIED: `actor_live.ex`; `query.ex`] |
| Coverage remediation treatment | Frontend Server (Phoenix LiveView) | Database / Storage | `CoverageLive` consumes `Threadline.Health.trigger_coverage/1` snapshots; Phase 138 changes row/callout/action copy and styling, not coverage detection. [VERIFIED: `coverage_live.ex`; `health.coverage.ex`] |
| Copy affordances | Browser / Client | Frontend Server | `Threadline.OperatorSurface.Script` binds dependency-free copy behavior to `[data-tl-copy]`; LiveViews render the attributes and CSS. [VERIFIED: `script.ex`; `style.ex`] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 | Runtime and build/test task runner | Current local runtime used by the repo and test aliases. [VERIFIED: shell `mix --version`] |
| Erlang/OTP | 28 | BEAM runtime | Current local runtime used by Elixir. [VERIFIED: shell `mix --version`] |
| Phoenix | 1.8.7, published 2026-05-06 | Router/endpoint and LiveView host framework | Existing optional dependency and example app dependency; no framework switch is in scope. [VERIFIED: Hex API; `mix.lock`; `mix.exs`] |
| Phoenix LiveView | 1.1.30 locked locally; docs opened at 1.1.31 | Server-rendered UI, streams, `handle_params`, `push_patch`, LiveComponents | Existing operator surface uses LiveView modules, streams, and HEEx templates; official docs describe LiveViews as stateful server processes that render diffs and document `stream/3` and `handle_params/3`. [VERIFIED: Hex API; `mix.lock`; CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html] |
| Ecto SQL | 3.13.5, published 2026-03-03 | Repo/query integration for tests and coverage/schema checks | Existing query layer and Coverage schema validation use Ecto SQL/Postgrex. [VERIFIED: Hex API; `mix.lock`; `coverage_live.ex`] |
| Jason | 1.4.4, published 2024-07-26 | JSON encoding for refs and diff structures | `Presentation.secondary_ref/2` encodes map refs with Jason and ChangeDiff tests assert JSON-friendly maps. [VERIFIED: Hex API; `mix.lock`; `presentation.ex`; `change_diff_test.exs`] |

### Supporting
| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| Phoenix.LiveViewTest / ExUnit | local dependency | LiveView behavioral assertions | Add focused tests per surface and helper-level `Presentation` tests before implementation. [VERIFIED: test files] |
| Playwright via `mix verify.example_browser` | repo script | Browser/mobile UAT and screenshots | Add a Find-cluster mobile spec modeled after `operator-prove-mobile.spec.ts`. [VERIFIED: `mix.exs`; `examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts`] |
| PostgreSQL | 14.17 local client, server accepting on `/tmp:5432` | Test database and coverage schema lookup | Required for LiveView tests and example browser verification. [VERIFIED: shell `psql --version`; `pg_isready`] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Local `Presentation` helpers | New component library or Tailwind/shadcn | Forbidden by phase context and requirements; would add scope and dependency churn. [VERIFIED: CONTEXT.md; REQUIREMENTS.md] |
| Function components for repeated static markup | LiveComponents | Official docs say LiveComponents are for state/markup/event compartmentalization and advise preferring function components unless event handling/state is needed; the phase context also forbids LiveComponents for static organization. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html; VERIFIED: CONTEXT.md] |
| Visible-page summary preload for Actor | Public `Threadline.actor_history_with_changes/2` API | Public API churn is out of scope; use local presenter/preload only if needed and bounded. [VERIFIED: CONTEXT.md; `actor_live.ex`] |

**Installation:**

No new packages should be installed for this phase. [VERIFIED: CONTEXT.md; UI-SPEC.md]

**Version verification:** `mix deps` and Hex package API verified `phoenix_live_view 1.1.30`, `phoenix 1.8.7`, `ecto_sql 3.13.5`, and `jason 1.4.4`. [VERIFIED: shell; Hex API]

## Package Legitimacy Audit

No external packages are recommended or installed in this phase, so the Package Legitimacy Gate is not triggered. [VERIFIED: CONTEXT.md; UI-SPEC.md]

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| none | — | — | — | — | not run | No install planned |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
Operator request /audit/*
  -> Phoenix Router threadline_operator_surface/2
  -> Surface on_mount assigns auth/scope/coverage/config
  -> LiveView handle_params / mount
       -> query/domain functions for existing data only
       -> Presentation helpers for labels, refs, value tokens, summaries
       -> HEEx using .threadline-ui / .tl-* primitives
       -> optional browser copy helper via [data-tl-copy]
  -> LiveView tests + Playwright Find mobile UAT verify behavior and layout pressure
```

This flow is existing architecture; Phase 138 should add presentation derivation and markup/CSS only where required to close locked findings. [VERIFIED: codebase grep]

### Recommended Project Structure

```text
lib/threadline/operator_surface/
├── presentation.ex                  # pure labels, refs, value tokens, actor summaries, count grammar
├── style.ex                         # scoped token-backed .tl-* CSS primitives
├── script.ex                        # existing copy affordance; no new JS dependency
└── live/
    ├── timeline_live.ex             # filter state, dense/error/mobile, refs/copy
    ├── transaction_live.ex          # transaction diff/value rendering
    ├── row_history_component.ex     # snapshot KV value rendering
    ├── actor_live.ex                # actor window and bounded row summaries
    └── coverage_live.ex             # coverage remediation/copy/status

test/threadline/operator_surface/
├── presentation_test.exs            # helper semantics
├── style_contract_test.exs          # token/class contract
├── transaction_live_test.exs
├── row_history_component_test.exs
└── live/{timeline,actor,coverage}_live_test.exs

examples/threadline_phoenix/e2e/tests/
└── operator-find-mobile.spec.ts     # new Phase 138 mobile/dense UAT
```

### Pattern 1: Presentation Helpers Before Markup

**What:** Add pure helpers for value tokens, secondary refs, count grammar, actor summaries, and remediation labels before touching LiveView templates. [VERIFIED: `presentation.ex`; Phase 137 summaries]

**When to use:** Any derived display logic reused across Transaction/Row-history/Actor/Coverage or complex enough to unit test directly. [VERIFIED: CONTEXT.md]

**Example:**

```elixir
# Source: existing Phase 137 helper pattern in lib/threadline/operator_surface/presentation.ex
def secondary_ref(value, max_length \\ 34) do
  full = secondary_ref_value(value)

  %{
    visible: truncate_middle(full, max_length),
    title: full
  }
end
```

### Pattern 2: Keep URL State in LiveView `handle_params/3`

**What:** Timeline and Transaction history routes already use `handle_params/3` for URL-derived state; continue this for local display changes. [VERIFIED: `timeline_live.ex`; `transaction_live.ex`]

**Why:** LiveView docs state `handle_params/3` runs after mount and on live patch navigation, matching the existing shareable filter/history pattern. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html]

### Pattern 3: Function Components Only for Repeated Static Markup

**What:** Use small function components only if repeated markup appears in two or more Find surfaces. [VERIFIED: CONTEXT.md]

**Why:** Phoenix docs describe function components as stateless pure functions, and LiveComponent docs advise avoiding LiveComponents merely for organization. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html; https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html]

### Anti-Patterns to Avoid

- **Raw `inspect/1` for UI values:** It collapses nil/null/omitted/timestamp/string semantics and directly violates D-10/F-706. [VERIFIED: `transaction_live.ex`; `row_history_component.ex`; UI-SPEC.md]
- **Hard prefix truncation for UUIDs/refs:** `Presentation.short_id/2` drops the middle/end and cannot verify identity; use `secondary_ref/2` or `truncate_middle/2` with full `title` and copy affordance. [VERIFIED: `presentation.ex`; F-701]
- **Per-row Coverage consequence copy:** `Timeline may be incomplete` belongs at section/callout level, not repeated in every action cell. [VERIFIED: `coverage_live.ex`; F-502]
- **N+1 Actor row summaries:** `actor_history/2` streams transactions; do not query each transaction independently during render. [VERIFIED: `actor_live.ex`; `query.ex`; CONTEXT.md]
- **New product routes/flows:** Record-first lookup, closed export loop, and first-class row-history entry from Home are Phase 140, not Phase 138. [VERIFIED: CONTEXT.md; ROADMAP.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Middle truncation and full ref metadata | New truncation helpers per LiveView | `Presentation.secondary_ref/2` and `Presentation.truncate_middle/2` | Existing tested helpers preserve full `title` and consistent visible refs. [VERIFIED: `presentation.ex`; `presentation_test.exs`] |
| Copy-to-clipboard behavior | New JS hooks or dependency | Existing `[data-tl-copy]` and `.tl-copy` | Existing script is dependency-free, idempotent, and CSP-disable-aware. [VERIFIED: `script.ex`; `style.ex`] |
| Diff/value semantics | Inline `inspect/1` in templates | New pure `Presentation` value-token helpers | Needed to distinguish absent, `nil`, omitted, redacted, timestamps, primitives, maps/lists, and strings. [VERIFIED: CONTEXT.md; UI-SPEC.md] |
| Coverage remediation commands | Browser-side mutation or fake fix | Existing Mix task guidance: `mix threadline.gen.triggers --tables ...`, then verify coverage | Generator docs define trigger migration usage; browser cannot mutate host code. [VERIFIED: `threadline.gen.triggers.ex`; CONTEXT.md] |
| Actor blast-radius summaries | New public query API by default | Bounded visible-page preload or local presenter fallback | Public API churn and N+1 behavior are out of scope. [VERIFIED: CONTEXT.md; `actor_live.ex`] |

**Key insight:** This phase is about making existing investigation data legible under pressure; custom frameworks, new flows, and backend expansion would dilute the locked audit-finding closure work. [VERIFIED: CONTEXT.md; UI-SPEC.md]

## Common Pitfalls

### Pitfall 1: Planning Actor Summary as a Public API Change

**What goes wrong:** The plan adds a broad `actor_history_with_changes` API to solve a row-label problem. [ASSUMED]
**Why it happens:** `ActorLive` currently only streams transaction rows, while the desired label needs op/table/change counts. [VERIFIED: `actor_live.ex`; `query.ex`]
**How to avoid:** Prefer a local visible-page preload/presenter or an honest unavailable fallback; include an explicit N+1 guard. [VERIFIED: CONTEXT.md]
**Warning signs:** A plan modifies `lib/threadline.ex`, `Threadline.Query.actor_history/2`, or public docs without proving it is required. [VERIFIED: codebase grep]

### Pitfall 2: Treating INSERT Empty Diffs as Missing Data Only

**What goes wrong:** Transaction INSERT rows still render blank if `field_changes` is empty. [VERIFIED: `transaction_live.ex`; F-201]
**Why it happens:** `ChangeDiff` defaults INSERT `field_changes` to `[]`, but supports `expand_insert_fields: true` to derive sorted set rows from `data_after`. [VERIFIED: `change_diff.ex`; `change_diff_test.exs`]
**How to avoid:** During planning, decide whether `incident_bundle/2` should request `expand_insert_fields` for presentation or TransactionLive should derive inserted value rows locally from `data_after`; keep this presentation-only. [VERIFIED: `change_diff.ex`; CONTEXT.md]
**Warning signs:** Blank `.tl-change__fields` after an INSERT row or tests that only assert `INSERT` and table name. [VERIFIED: `transaction_live_test.exs`]

### Pitfall 3: CSS Drift Through One-Off Classes

**What goes wrong:** New `.tl-*` classes use non-token colors/spacing or create another local primitive. [VERIFIED: style contract pattern]
**Why it happens:** The target screens have bespoke gaps, but Phase 136 froze dark-first/token-first direction. [VERIFIED: `136-CONTEXT.md`; `style.ex`]
**How to avoid:** Add only narrow token-backed CSS and update `style_contract_test.exs` for any reusable primitive. [VERIFIED: `style_contract_test.exs`]
**Warning signs:** Raw hex colors outside token definitions, new typography sizes, or new one-off class families. [VERIFIED: UI-SPEC.md]

### Pitfall 4: Mobile UAT Stops at Screenshots

**What goes wrong:** Screenshot inventory updates but no automated assertions prevent dense/mobile regressions. [VERIFIED: Phase 137 verification]
**Why it happens:** Timeline mobile pressure is visual and source-order based, so unit tests alone miss it. [VERIFIED: UI-SPEC.md]
**How to avoid:** Add `operator-find-mobile.spec.ts` with 375px checks for Timeline rows-before-orientation pressure, Transaction constrained content, Row-history drawer values, Actor summaries, and Coverage remediation. [VERIFIED: `operator-prove-mobile.spec.ts`; `mix verify.example_browser`]
**Warning signs:** Phase plans only mention LiveView tests and never mention Playwright. [VERIFIED: Phase 137 verification]

## Code Examples

### Value Token Helper Shape

```elixir
# Source: planner pattern derived from CONTEXT.md D-09..D-13 and existing Presentation helper style.
# Implement exact names during planning.
def value_token(%{"prior_state" => "omitted"}), do: %{text: "(omitted)", modifier: "tl-value--omitted"}
def value_token(nil), do: %{text: "null", modifier: "tl-value--null"}
def value_token(%DateTime{} = dt), do: %{text: human_time(dt), title: exact_time(dt), modifier: "tl-value--time"}
```

Use HEEx interpolation so strings remain HTML-escaped; do not return raw HTML from value helpers unless the helper returns safe component assigns and the markup stays in HEEx. [VERIFIED: Phoenix HEEx usage in LiveViews]

### Copy Affordance Pattern

```elixir
# Source: existing transaction/timeline copy affordance pattern.
<button
  :if={Threadline.OperatorSurface.Script.enabled?()}
  type="button"
  class="tl-copy"
  data-tl-copy={full_value}
  aria-label="Copy correlation id"
>
  Copy
</button>
```

### Actor Summary Planning Pattern

```elixir
# Source: CONTEXT.md D-19..D-22; exact implementation should stay local/bounded.
%{
  visible: "UPDATE tickets + 2 tables - 7 changes",
  op: "UPDATE",
  modifier: "tl-change__op--update",
  transaction_ref: Presentation.secondary_ref(tx.id, 28)
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Per-screen ad hoc refs | Shared `Presentation.secondary_ref/2` and `.tl-secondary-ref` | Phase 137 | Phase 138 should reuse middle truncation/full title/copy affordance for correlation, transaction, actor, record, and table refs. [VERIFIED: 137-VERIFICATION.md; `presentation.ex`] |
| Static Prove mobile screenshots only | Automated `operator-prove-mobile.spec.ts` in `mix verify.example_browser` | Phase 137 | Phase 138 should add an equivalent Find mobile UAT lane. [VERIFIED: 137-VERIFICATION.md; `operator-prove-mobile.spec.ts`] |
| Neutral expected-gap Coverage treatment | Deliberate muted/warning semantic treatment | Locked for Phase 138 | Coverage expected gaps must not remain bare neutral text. [VERIFIED: UI-SPEC.md; `coverage_live.ex`] |
| Raw diff/snapshot values | Semantic value tokens | Locked for Phase 138 | Transaction and Row-history need a shared value vocabulary while preserving diff-vs-snapshot distinction. [VERIFIED: CONTEXT.md; UI-SPEC.md] |

**Deprecated/outdated:**
- `Presentation.short_id/2` for UUID-like visible identity in Transaction/Actor is outdated for Phase 138 because F-701 requires middle truncation plus full title/copy. [VERIFIED: F-701; `presentation.ex`]
- Raw `inspect/1` in Transaction/Row-history UI is outdated for Phase 138 because D-10/F-706 require semantic value formatting. [VERIFIED: `transaction_live.ex`; `row_history_component.ex`; UI-SPEC.md]

## Recommended Plan Slicing

| Slice | Scope | Primary Files | Verification |
|-------|-------|---------------|--------------|
| 138-01 Shared Find presentation primitives | Value tokens, count grammar, coverage labels, secondary-ref wrappers, style primitives | `presentation.ex`, `style.ex`, `presentation_test.exs`, `style_contract_test.exs` | `mix test test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/style_contract_test.exs` [VERIFIED: codebase] |
| 138-02 Transaction + Row-history diff/value convergence | INSERT values, before/after arrow, null/timestamp/redacted/omitted rendering, constrained short content | `transaction_live.ex`, `row_history_component.ex`, related tests | Focused transaction + row-history tests [VERIFIED: codebase] |
| 138-03 Timeline dense/error/mobile and refs | Row-first dense layout, empty/future/error copy, journey demotion, anonymous hint, long table/correlation truncation/copy | `timeline_live.ex`, `timeline_live_test.exs`, new Playwright spec | Timeline LiveView tests plus mobile UAT [VERIFIED: codebase] |
| 138-04 Actor + Coverage closure | Actor blast-radius summaries, selected segmented state test, Coverage remediation/callout/expected-gap/count grammar | `actor_live.ex`, `coverage_live.ex`, related tests | Actor/Coverage focused tests plus mobile UAT [VERIFIED: codebase] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Actor row summaries can be implemented with a local visible-page preload or presenter without public API churn. | Common Pitfalls / Recommended Plan Slicing | If existing data access cannot do this without N+1 queries, the plan must use `Changes unavailable` fallback or add a tightly scoped query change after explicit review. |

## Open Questions

1. **Where should INSERT field expansion happen?**
   - What we know: `ChangeDiff.from_audit_change/2` supports `expand_insert_fields: true`, while `incident_bundle/2` currently calls `Threadline.change_diff(linked_change.audit_change)` without options. [VERIFIED: `change_diff.ex`; `investigation.ex`]
   - What's unclear: Whether the team prefers changing incident-bundle presentation output or deriving inserted value rows inside TransactionLive.
   - Recommendation: Keep it presentation-only and test F-201 first; planner should choose the smallest change that does not alter public semantics. [VERIFIED: CONTEXT.md]

2. **How much Actor summary data is available without extra queries?**
   - What we know: `actor_history/2` returns `AuditTransaction` structs and ActorLive does not preload changes. [VERIFIED: `query.ex`; `actor_live.ex`]
   - What's unclear: Whether visible-page transaction IDs can be batch-loaded with change counts cheaply inside ActorLive.
   - Recommendation: Plan a proof task with an explicit N+1 check; use the locked fallback if summary data is unavailable. [VERIFIED: CONTEXT.md]

3. **Exact Coverage command copy**
   - What we know: `mix threadline.gen.triggers --tables users` and `mix threadline.gen.triggers --tables users,posts,comments` are documented task forms. [VERIFIED: `threadline.gen.triggers.ex`]
   - What's unclear: Whether UI should show a literal single-table command, a schema-qualified hint, or a revealable snippet.
   - Recommendation: Prefer `mix threadline.gen.triggers --tables <table>` for unqualified table names and avoid interpolating `schema.table` incorrectly. [VERIFIED: CONTEXT.md; `threadline.gen.triggers.ex`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix | Unit and LiveView tests | ✓ | Mix 1.19.5 / Elixir 1.19.5 | none |
| Erlang/OTP | Runtime | ✓ | OTP 28 | none |
| PostgreSQL server | Repo-backed tests, Coverage schema lookup | ✓ | accepting on `/tmp:5432`; client 14.17 | none |
| Node.js | Playwright/browser UAT | ✓ | v22.14.0 | none |
| npm | Playwright/browser UAT dependencies | ✓ | 11.1.0 | none |
| Docker | Optional local services | ✓ | 29.5.2 | local Postgres is already available |

**Missing dependencies with no fallback:** none verified. [VERIFIED: shell]

**Missing dependencies with fallback:** none verified. [VERIFIED: shell]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit + Phoenix.LiveViewTest; Playwright through example app E2E. [VERIFIED: test files; `mix.exs`] |
| Config file | `mix.exs`; Playwright config under `examples/threadline_phoenix/e2e`. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/row_history_component_test.exs test/threadline/operator_surface/live/actor_live_test.exs test/threadline/operator_surface/live/coverage_live_test.exs` |
| Full suite command | `mix ci.all` |
| Browser UAT command | `mix verify.example_browser` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| POLISH-FIND | Shared Find primitives/token contract | unit/contract | `mix test test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/style_contract_test.exs` | ✅ |
| POLISH-FIND | Timeline empty/future/error/dense/mobile/truncation/copy/anonymous hint | LiveView + Playwright | `mix test test/threadline/operator_surface/live/timeline_live_test.exs` and `mix verify.example_browser` | LiveView ✅ / Find mobile spec ❌ Wave 0 |
| POLISH-FIND | Transaction diff/INSERT/short content/copy/truncation | LiveView | `mix test test/threadline/operator_surface/transaction_live_test.exs` | ✅ |
| POLISH-FIND | Row-history null/timestamp/snapshot values | component | `mix test test/threadline/operator_surface/row_history_component_test.exs` | ✅ but sparse |
| POLISH-FIND | Actor blast-radius summaries and selected segmented state | LiveView + Playwright | `mix test test/threadline/operator_surface/live/actor_live_test.exs` and `mix verify.example_browser` | LiveView ✅ / Find mobile spec ❌ Wave 0 |
| POLISH-FIND | Coverage remediation/expected-gap/count grammar | LiveView | `mix test test/threadline/operator_surface/live/coverage_live_test.exs` | ✅ |

### Sampling Rate

- **Per task commit:** Focused files named in the slice.
- **Per wave merge:** Focused Find suite plus `mix verify.example_browser` after Playwright spec lands.
- **Phase gate:** `mix ci.all` or explicit waiver if browser verification is unavailable.

### Wave 0 Gaps

- [ ] `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts` — covers Timeline dense/mobile, Transaction constrained content, Row-history values, Actor summaries, Coverage remediation.
- [ ] Additional `presentation_test.exs` cases for value tokens, expected-gap grammar, coverage remediation labels, and actor transaction summaries.
- [ ] Row-history component fixture coverage for actual snapshot values, not only missing schema.

## Security Domain

Security enforcement is enabled by default because `.planning/config.json` does not set `security_enforcement: false`. [VERIFIED: `.planning/config.json`]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Existing operator surface auth/on_mount and scoped router assigns; Phase 138 must not weaken auth gates. [VERIFIED: operator surface tests] |
| V3 Session Management | no direct change | Phoenix session/LiveView setup remains unchanged. [VERIFIED: test routers] |
| V4 Access Control | yes | Preserve `threadline_scope`, `scope_query_fn`, support scoped Timeline/Transaction/Actor/Row-history tests. [VERIFIED: scoped tests] |
| V5 Input Validation | yes | Preserve Timeline `FilterParams` validation, Coverage schema regex + `pg_namespace` parameterized query, and escaped HEEx output. [VERIFIED: `coverage_live.ex`; `timeline_live_test.exs`] |
| V6 Cryptography | no direct change | No cryptographic logic in scope. [VERIFIED: CONTEXT.md] |

### Known Threat Patterns for Phoenix LiveView Operator UI

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Ref/value XSS via row data | Tampering / Information Disclosure | Render values through HEEx text interpolation and return data assigns from helpers, not raw HTML. [VERIFIED: LiveView HEEx usage] |
| Scope bypass through drill-in links | Elevation of Privilege | Preserve `threadline_scope` and `scope_query_fn` options on Timeline, Transaction, Row-history, and Actor queries. [VERIFIED: scoped tests] |
| SQL injection in Coverage schema | Tampering | Existing regex validation plus parameterized `pg_namespace` lookup. [VERIFIED: `coverage_live.ex`; coverage tests] |
| Confusing copy controls that leak full IDs unexpectedly | Information Disclosure | Only render existing copy affordance for values already visible/authorized on the page; keep full values in `title` where required. [VERIFIED: UI-SPEC.md; `script.ex`] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/138-find-cluster-polish/138-CONTEXT.md` — locked decisions, constraints, code context.
- `.planning/phases/138-find-cluster-polish/138-UI-SPEC.md` — visual/copy/primitive/audit closure contract.
- `.planning/milestones/v1.31-UI-AUDIT.md` — F-201, F-401..F-405, F-501/F-502/F-504/F-505, F-701..F-706.
- `.planning/phases/137-prove-cluster-polish/137-VERIFICATION.md` and `137-PATTERNS.md` — prior primitive/test patterns.
- `lib/threadline/operator_surface/{presentation.ex,style.ex,script.ex}` — shared helper, CSS, and copy affordance implementation.
- `lib/threadline/operator_surface/live/{timeline_live.ex,transaction_live.ex,row_history_component.ex,actor_live.ex,coverage_live.ex}` — target implementation surfaces.
- `test/threadline/operator_surface/**` and `examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts` — existing test architecture and Phase 137 UAT model.
- Hex API package metadata for Phoenix, Phoenix LiveView, Ecto SQL, Jason.
- Phoenix LiveView HexDocs: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html, https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html, https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html

### Secondary (MEDIUM confidence)
- None needed; this phase is constrained by local code and official docs.

### Tertiary (LOW confidence)
- None used.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified through `mix.lock`, `mix deps`, Hex API, and current local runtime commands.
- Architecture: HIGH — derived from target LiveViews, query/investigation modules, and existing tests.
- Pitfalls: HIGH for code-backed issues; MEDIUM for Actor summary implementation feasibility because the exact bounded preload approach still needs proof during planning.

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 for codebase-local findings; 2026-06-11 for package/version currency.
