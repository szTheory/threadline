# Phase 176: Data display & operator patterns - Research

**Researched:** 2026-06-17
**Domain:** Phoenix/LiveView operator-surface UI — data-display consolidation, data-state taxonomy, destructive-action safety (fix-and-consolidate of existing internal components)
**Confidence:** HIGH (the phase is grounded in already-read source files; almost every claim is verified against the working tree rather than training data)

## Summary

Phase 176 is a **fix-and-consolidate** phase, not greenfield. The CONTEXT.md (D-01..D-22) and approved UI-SPEC.md already lock essentially every implementation decision; this research verifies those decisions against the actual codebase, confirms the named files/line ranges exist as described, and surfaces the small number of places where the locked plan meets a **gap in the current backend** that the planner must account for. The dominant work is: collapse five drifting "ugly-value" render paths into one `ref/1` component backed by `Presentation.ref/2 → %{visible, title, full}`; extract `UI.kv/1` and `UI.data_table/1`; add the data-state family (`loading_state/1`, `stale_banner/1`, three `empty_state` variants); wire per-row kebab actions with a three-tier destructive-confirmation model with **server-side enforcement**; and flatten the coverage command shell plus a system-wide card-nesting sweep.

Three findings materially shape planning. (1) **`transaction_live.ex:121` and `:145` copy `ref.title`, not the full value** — the exact forensic footgun D-02 names — confirmed verbatim in the source; this is a real (currently latent) bug, not a hypothetical. (2) **There is no `assign_async`/`<.async_result>` anywhere in the operator surface today** — all 11 LiveViews load synchronously in `mount`; D-17's dispatch model is a *new* pattern to introduce, which is more work than "wire into the existing async switch" implies. (3) **The T3 "redact an audit value" and "prune now" actions do not both have runtime backends**: `Pruner.trigger/0` exists (prune now is real), but redaction is currently **codegen-time only** (`capture/redaction_policy.ex` validates trigger options at trigger-generation time — there is no runtime "redact this one stored value" operation). The planner must treat the T3-redact flow as either (a) building a new runtime redaction backend, or (b) scoping redact's UI to whatever runtime operation actually exists, and must not assume the handler is a thin wrapper.

**Primary recommendation:** Treat CONTEXT.md/UI-SPEC.md as the locked spec and plan directly against the verified file/line map below. Sequence the work as: (Wave A) `Presentation` core + `ref/1` consolidation + kill `ref.title` copy + CSS double-truncation removal; (Wave B) `kv/1` + `data_table/1` extraction and the per-surface table verdicts; (Wave C) data-state family + introduce `assign_async` dispatch per page; (Wave D) actions + tiered destructive confirmation with server enforcement; (Wave E) coverage flatten + system-wide nesting sweep + regression test. Gate the T3-redact backend question with a `checkpoint:human-verify` before building it.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Ugly-value truncation (`ref/2`) | API/Backend (Elixir `Presentation`) | — | Server-side middle-truncation is the only truncator (D-03/D-05); CSS only wraps. Deterministic + unit-testable. |
| Copy affordance | Frontend Server (HEEx render) + Browser (delegated JS listener) | — | `data-tl-copy={ref.full}` rendered server-side; `script.ex` delegated listener copies client-side; zero-JS fallback = server renders `ref.full` in `<code>`. |
| `kv/1` / `data_table/1` structure | Frontend Server (HEEx function components) | — | Pure render components; `:col label` feeds both `<th>` and `<td data-label>` server-side. |
| Responsive table→card | Browser (CSS `display:block/grid` + `::before`) | — | Native `<table>` restyled per viewport; **no JS, no ARIA roles** (D-09). |
| Data-state branching | API/Backend (typed `:reason`) + Frontend Server (`async_result` switch) | — | Server must preserve typed reason (`:unauthorized`/`:source_down`/…) to the view; the page author branches ok-empty and `:failed` reasons (D-17). |
| Destructive-action enforcement | **API/Backend (`handle_event`)** | — | `secure_compare` + re-fetch canonical token + re-check authz + audit-the-action all server-side; client signal is untrusted (D-21). This is the load-bearing security tier. |
| Time display | API/Backend (`Presentation.human_time/exact_time`) + Frontend Server (`<time datetime>`) | — | UTC canonical; relative + absolute both server-rendered; no live-ticking (deferred, would need JS). |

## User Constraints (from CONTEXT.md)

> CONTEXT.md exists and is fully locked (D-01..D-22). The planner MUST honor these verbatim. The full decision text is in `.planning/phases/176-data-display-operator-patterns/176-CONTEXT.md` and the visual/interaction contract in `176-UI-SPEC.md` (approved, all 6 dimensions PASS). Key locked decisions condensed:

### Locked Decisions
- **D-01/D-02:** Consolidate `secondary_ref/2` + `value_token/1` + 3 ad-hoc copy wirings into ONE `ref/1` component backed by `Presentation.ref/2 → %{visible, title, full}`. `data-tl-copy` MUST bind `ref.full` — never `.title`, never the bare field.
- **D-03:** Truncation server-side, middle, tail-biased (`:tail_min` ≥ 8 chars tail). Per-type rules (UUID middle ~34, ARN/actor tail-weighted, hash ~24, path keep-filename ~42, email keep-domain, URL keep host+last segment, ISO timestamp never truncate).
- **D-04:** Route KV snapshot values + diff before/after cells through the same truncate+copy path (max ~56). Core DATA-01 gap.
- **D-05:** Remove `text-overflow: ellipsis` from `.tl-secondary-ref`; CSS job is `overflow-wrap: anywhere`.
- **D-06/D-07:** Keep `Script.enabled?()` gating; zero-JS fallback renders `ref.full` in `<code>`. `copy_label` required attr, no default; aria-label carries specificity, visible text "Copy"/"Copied", no exclamation.
- **D-08:** Extract `UI.kv/1` (`<dl>` `:item` slot, required `key`) + `UI.data_table/1` (`:col` slot `label` → both `<th>` and `<td data-label>`; supports `stream`, `row_id`, `row_status`, `:action` slot).
- **D-09:** Responsive = keep `data-label` + `::before` stacking; **add NO ARIA table roles**; no sticky-first-column.
- **D-10:** Per-surface verdicts (table vs diff-table vs `kv` vs cards) — see Per-Surface Verdict table below.
- **D-11/D-12:** "One card boundary per logical unit." Coverage flatten = delete hand-rolled header, use `page_header` in all 3 branches, demote `tl-coverage-command` shell, delete dead CSS, add regression test.
- **D-13/D-14:** Extend named-family convention (NOT a polymorphic `variant=` mega-component). Add `loading_state/1` + `stale_banner/1` as named siblings; extend `empty_state` variant enum with `no_data`/`permission`/`unavailable`. Stale PRECEDES still-rendered data, never replaces it.
- **D-15/D-16:** Per-state role/icon-shape/heading/microcopy spec (see Data-State Taxonomy). Three forensic distinctions (permission/no-data/unavailable) must never collapse.
- **D-17:** Dispatch via `assign_async`/`<.async_result>`; page author branches ok-empty (empty vs no_data) and `:failed` reason (permission/unavailable/error). Preserve typed server reason.
- **D-18/D-19:** Per-row kebab (`dropdown/1`) default; collapse to inline `button/1` only for a lone T1 action; destructive last after `divider/1`. **No bulk multi-select.**
- **D-20/D-21:** Three-tier confirmation (T1 direct / T2 confirm modal / T3 type-to-confirm typing the object's own identifier). T3 server-side enforcement: re-fetch canonical token + `secure_compare`, re-check authz + scope-filter, audit-the-action, fail closed.
- **D-22:** Time as relative + absolute UTC in `<time datetime>`; metrics as `stat_tile`; any chart hand-rolled inline SVG/CSS bar (no chart lib); never color alone.

### Claude's Discretion
Exact component names (`tl_ref` vs `ref` vs `copyable`), precise `kv`/`data_table` slot APIs, new `--tl-*` token names, icon glyph choices (reuse `Icon` registry; add only `eye-off` + `plug`/`cloud-off` if missing), component file location. Match existing `ui.ex` BEM + `--tl-*` idioms and 173/174/175 conventions.

### Deferred Ideas (OUT OF SCOPE)
- Sticky-first-column / horizontal-scroll table fallback (no current table needs it; ≤5 cols).
- Bulk "Export all N matching" (only additive bulk candidate; add explicitly later; never bulk redact/prune).
- Live-ticking relative timestamps (would need JS; server-rendered relative+absolute is sufficient).
- Component groups/meta-components (Phase 177); per-page/flow stress (178); microcopy/IA sweep (179); formal a11y audit (180).

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DATA-01 | Long IDs/paths/atoms/emails/URLs/timestamps middle-truncate with copy + title; important columns never squish; card/list where tables don't fit | `Presentation.truncate_middle/2` (presentation.ex:58) + new `:tail_min`; `ref/2` consolidation of `secondary_ref/2` (L229) + `value_token/1` (L239); `data_table/1` responsive `data-label`. **Verified footgun:** `transaction_live.ex:121,145` copy `.title`. |
| DATA-02 | KV/timeline/detail/status/metrics read clearly, never color alone, time relative+absolute w/ tz | `human_time/2` (L10), `exact_time/1` (L29), `checked_label/1` (L33) all emit UTC; `status_modifier/1` (L70) pairs with `status_label/1` (L90); `stat_tile/1` (ui.ex:341). Color-alone ban: brand-book.md:297,348. |
| DATA-03 | Empty/loading/error/stale distinct + next action; permission ≠ no-data ≠ unavailable | `empty_state/1` (ui.ex:358, has `variant`) + `error_state/1` (L377 thin wrapper) — extend per D-13. Coverage already has `role="status"` strip (coverage_live.ex:126) — stale precedent. **Gap:** no `assign_async` exists yet (see Open Questions). |
| DATA-04 | Row/bulk actions discoverable not accidentally triggerable; destructive separated + confirmed by naming object+consequence | `dropdown/1` (ui.ex:629, `role=menu`/`aria-haspopup`), `modal/1` (L406, `focus_first`/`pop_focus`), `divider/1`, `button/1`. **Verified gap:** prune is client-only `data-confirm` (retention_history_live.ex:115,159); handler (L37) has no `secure_compare`/authz/audit. Redact has **no handler at all**. |
| DATA-05 | Coverage card-in-card flattened; accidental nesting/table-overuse removed system-wide | `tl-coverage-command__*` CSS (style.ex ~3336) + hand-rolled `tl-page__title/__lede/__meta`; `page_header/1` (ui.ex:202) is the replacement. Regression test refutes card-under-card. |

## Standard Stack

This phase adds **zero runtime dependencies** (v1.37 invariant). All work uses libraries already present and verified in `mix.lock`.

### Core (already present — versions verified in working tree)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix_live_view` | 1.1.30 | Function components (`attr`/`slot`), `assign_async`/`<.async_result>`, streams (`phx-update="stream"`), `Phoenix.LiveView.JS` | Already the surface's foundation; `assign_async` (LV 0.20+) and streams are available at 1.1.30. `[CITED: mix.lock]` |
| `phoenix` | ~> 1.7 (optional) | HEEx, `Phoenix.Component` | Existing. `[CITED: mix.exs:60]` |
| `plug` | ~> 1.15 (direct dep) | `Plug.Crypto.secure_compare/2` for T3 constant-time token compare (D-21.1) | Direct dependency — `Plug.Crypto` is available without adding anything. `[VERIFIED: mix.exs:58]` |
| `jason` | (present) | `value_token/1` JSON encoding (already used) | Existing. |

### Supporting (internal modules — extend, do not rebuild)
| Module | Purpose | When to Use |
|--------|---------|-------------|
| `Threadline.OperatorSurface.UI` (ui.ex, 1005 lines) | All function components live here (`@doc false`) | Add `ref/1`, `kv/1`, `data_table/1`, `loading_state/1`, `stale_banner/1`; extend `empty_state/1` |
| `Threadline.OperatorSurface.Presentation` (presentation.ex, 483 lines) | Pure helpers | Add `ref/2`; extend `truncate_middle/2` with `:tail_min`; add truncation to `value_token/1` |
| `Threadline.OperatorSurface.Script` (script.ex, 86 lines) | Delegated copy listener, `enabled?/0` | Reuse as-is; gate copy buttons on `Script.enabled?()` |
| `Threadline.OperatorSurface.Components.Icon` (icon.ex) | Zero-dep icon registry | Reuse `:history`/`:shield`/`:filter_x`/`:archive`/`:trash`/`:refresh`; add `eye-off` + `plug`/`cloud-off` if missing |
| `Threadline.Semantics.AuditAction` (semantics/audit_action.ex) | Records who-did-what (D-21.3 audit-the-destructive-action) | Use to audit redact/prune actions themselves; has `changeset/2` (L57) |
| `Threadline.Retention.Pruner` (retention/pruner.ex) | `trigger/0` (L35) backs "prune now" | The real runtime backend for T3 prune |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hand-rolled inline SVG/CSS bar (D-22) | A chart library (Contex, chartjs) | **Rejected by invariant** — zero new runtime deps. Coverage % bar is simple enough for a CSS `width:%` bar with label+pattern. |
| `assign_async` | Keep synchronous `mount` loads + manual `case` branching | `assign_async` is idiomatic and gives the loading/failed/ok switch D-17 wants, but it is a *new* pattern here (none exists today). For pages that already load synchronously and fast, the planner may keep sync load + explicit state branching and still satisfy D-13..D-16; `assign_async` is the means, the **state taxonomy is the requirement**. Flag as a real choice (Open Question 1). |
| ARIA `role="table"` on the responsive grid | Native `<table>` restyled | **Rejected by D-09** — re-asserting roles makes AT announce "table/row/cell" over a visually-stacked card. Native table + source-ordered label/value is AA-compliant. |

**Installation:** None. Zero new packages. (Package Legitimacy Audit therefore not applicable — see below.)

## Package Legitimacy Audit

**Not applicable.** This phase installs no external packages (v1.37 invariant: zero new runtime dependencies, inline assets only). Every library used (`phoenix_live_view`, `plug`, `jason`) is already in `mix.lock` and verified present in the working tree. No registry lookup, slopcheck, or postinstall audit is required because nothing is being added.

## Architecture Patterns

### System Architecture Diagram

```
                     OPERATOR (browser, 320–1440, dark/light/system, keyboard, reduced-motion)
                              │
              ┌───────────────┼────────────────────────────┐
              │ view request  │ copy click                 │ destructive action (phx-submit / phx-click)
              ▼               ▼                            ▼
   ┌─────────────────┐  ┌──────────────────┐   ┌──────────────────────────────────┐
   │ LiveView mount/ │  │ delegated JS      │   │ handle_event (T1/T2/T3)          │
   │ handle_params   │  │ [data-tl-copy]    │   │  ── SERVER ENFORCEMENT (D-21) ──  │
   │                 │  │ → clipboard.write │   │  1. re-check authz (untrusted id)│
   │ (data load —    │  │ (script.ex)       │   │  2. scope-filter query           │
   │  sync today;    │  └──────────────────┘   │  3. re-fetch canonical token (DB) │
   │  assign_async   │         ▲                │  4. secure_compare(typed, token)  │
   │  per D-17)      │         │                │  5. audit-the-action (AuditAction)│
   └───────┬─────────┘         │ ref.full       │  6. fail closed on any mismatch  │
           │                   │ (NEVER .title)  └────────────────┬─────────────────┘
           ▼                   │                                  ▼
   ┌──────────────────────────────────────────────┐   ┌────────────────────────┐
   │ STATE DISPATCH (page author branches):        │   │ Pruner.trigger/0 (real)│
   │  ok+rows   → data                              │   │ Redact backend = GAP   │
   │  ok+empty  → empty (first-run) | no_data       │   │ (codegen-time only)    │
   │  loading   → loading_state/1                   │   └────────────────────────┘
   │  failed:   → :unauthorized → permission        │
   │             :source_down  → unavailable(down)  │
   │             :redacted     → unavailable(redact)│
   │             :pruned       → unavailable(pruned)│
   │             other         → error_state/1      │
   │  stale     → stale_banner/1 ABOVE live data    │
   └───────────────────────┬──────────────────────┘
                           ▼
   ┌──────────────────────────────────────────────────────────────────┐
   │ RENDER (HEEx function components, ui.ex)                           │
   │  Presentation.ref/2 → %{visible, title, full}                      │
   │   → <code data-tl-copy={full} title={full}>{visible}</code> + Copy │
   │  kv/1 (<dl>)   data_table/1 (<table>, :col label → th + td[label]) │
   │  page_header/1 (coverage)   dropdown/1 kebab (:action)             │
   │  CSS: middle-truncation is ONLY truncator; overflow-wrap:anywhere  │
   └──────────────────────────────────────────────────────────────────┘
           │ every new/extended unit also rendered in isolation on:
           ▼
   ┌──────────────────────────────────────────────┐
   │ /audit/__stress  (prod-gated, DS-01)          │
   │  stress_live.ex + stress_router.ex +          │
   │  stress_fixtures.ex (ugly-data: long_id,      │
   │  permission_denied, stale, non_ascii, …)      │
   │  × 5 viewports × 3 themes × states            │
   └──────────────────────────────────────────────┘
```

### Component Responsibilities (verified file map)

| File | Current responsibility | Phase-176 change |
|------|------------------------|------------------|
| `lib/.../operator_surface/ui.ex` (1005 L) | All function components, `@doc false` | Add `ref/1`, `kv/1`, `data_table/1`, `loading_state/1`, `stale_banner/1`; extend `empty_state/1` variant enum (currently `[nil,"error","never","unsupported"]` at L352) |
| `lib/.../operator_surface/presentation.ex` (483 L) | Pure helpers | `truncate_middle/2` (L58) gains `:tail_min`; `value_token/1` (L239) gains truncation; new `ref/2` returning `%{visible,title,full}` (consolidating `secondary_ref/2` L229) |
| `lib/.../operator_surface/script.ex` (86 L) | Delegated copy listener | No change — reuse `enabled?/0` gate |
| `lib/.../operator_surface/style.ex` (3935 L) | All CSS | Remove `text-overflow:ellipsis` from `.tl-secondary-ref` (~2490); add `overflow-wrap:anywhere`; `.tl-copy` (~3152); `tl-kv` (~3228); responsive collapse (~3488)+desktop restore (~3834); delete `tl-coverage-command__*` (~3336) |
| `lib/.../live/transaction_live.ex` | Transaction detail | **Fix L121/L145** `data-tl-copy={...ref.title}` → `ref.full`; convert `tl-param-list` (L127) metadata → `kv/1`; route diff cells (L197/L201 `change_value_token`) through truncate+copy |
| `lib/.../live/coverage_live.ex` | Coverage | Replace hand-rolled header → `page_header/1` (all 3 branches); demote `tl-coverage-command` shell; copy command already at L234 |
| `lib/.../live/retention_history_live.ex` | Retention runs (streamed) | Delete client-only `data-confirm` (L115/L159); rebuild `prune_now` handler (L37) with full D-21 enforcement; uses `data_table` `stream:` |
| `lib/.../live/policy_redaction_live.ex` | Configured-vs-Deployed diff (read-only today) | Keep as 2-col diff table; fix collapse (`scope="row"`). **T3-redact handler does not exist** — see Open Questions |
| `lib/.../live/row_history_component.ex` | Canonical `tl-kv` `<dl>` (L174) | Source for `kv/1` extraction; `value_token` call at L214 |
| `lib/.../live/{timeline,actor,evidence,export_status}_live.ex` | Consumers of `secondary_ref`/copy/`tl-param-list` | Migrate to `ref/1` + `kv/1`; `actor_live.ex:175` already copies bare `tx.id` (correct); `timeline_live.ex:414` copies bare `correlation_id` (correct) |

### Pattern 1: `Presentation.ref/2` returns three faces; the component binds the right one to the right slot
**What:** A single core helper returns `%{visible, title, full}`. The component renders `visible` as text, `full` in both `title` and `data-tl-copy`, never mixing them.
**When to use:** Every place an ID/ARN/hash/path/email/URL/`type/id` ActorRef is shown.
**Example (illustrative — match existing `ui.ex` idioms):**
```elixir
# Presentation.ref/2 (core, unit-testable) — [ASSUMED] shape per D-01
def ref(value, opts \\ []) do
  full = ref_value(value)                       # exact, complete
  %{full: full, title: full, visible: truncate_for(value, opts)}  # middle-trunc, tail_min>=8
end

# ui.ex ref/1 (call-site API) — copy_label REQUIRED, no default (D-07)
attr :value, :any, required: true
attr :kind, :string, default: nil   # uuid|correlation|arn|actor|hash|path|email|url|timestamp
attr :copy_label, :string, required: true
def ref(assigns) do
  ~H"""
  <span class="tl-ref">
    <code class="tl-secondary-ref" title={@r.full} data-tl-copy={@r.full}><%= @r.visible %></code>
    <button :if={Script.enabled?()} type="button" class="tl-copy"
            data-tl-copy={@r.full} aria-label={@copy_label}>Copy</button>
  </span>
  """
end
```
> Note the `data-tl-copy={@r.full}` appears on **both** the `<code>` and the button (D-02/D-06): the `<code>` is the zero-JS select-all source and a clean future click-the-value hook.

### Pattern 2: `data_table/1` `:col` `label` feeds both `<th>` and `<td data-label>`
**What:** One label attribute structurally guarantees the mobile stacked-card label matches the desktop header (D-08). Source order = label then value, so AT reads correctly with **no ARIA roles** (D-09).
**When to use:** Coverage, Retention history (streamed).
**Example:**
```elixir
slot :col, required: true do
  attr :label, :string, required: true
end
slot :action
# <tbody phx-update={@stream && "stream"}>… <td data-label={col.label}>…
```

### Pattern 3: State dispatch the `AsyncResult` switch cannot make alone (D-17)
**What:** `<.async_result>` gives loading/failed/ok, but the page author must split ok-empty into first-run vs filtered, and split `:failed` reason into permission/unavailable/error. Preserve the typed reason from the data layer.
```elixir
<.async_result :let={rows} assign={@changes}>
  <:loading><UI.loading_state>Loading audit changes…</UI.loading_state></:loading>
  <:failed :let={reason}>
    <%= case reason do %>
      <% :unauthorized -> %><UI.empty_state variant="permission">…</UI.empty_state>
      <% :source_down  -> %><UI.empty_state variant="unavailable">…down…</UI.empty_state>
      <% _ -> %><UI.error_state>Could not load this timeline.</UI.error_state>
    <% end %>
  </:failed>
  <%= if rows == [] do %>
    <%= if @filters_active, do: no_data_state(assigns), else: first_run_state(assigns) %>
  <% else %>… data …<% end %>
</.async_result>
```

### Anti-Patterns to Avoid
- **Copying `ref.title`** (the live bug at `transaction_live.ex:121/145`): `.title` is the full value *today* only by coincidence; bind `ref.full` everywhere.
- **CSS `text-overflow:ellipsis` as a second truncator** (`.tl-secondary-ref` ~2490): re-introduces tail-clipping at 320px. Server middle-truncation is the only truncator; CSS only wraps (`overflow-wrap:anywhere`).
- **A polymorphic `data_state variant=` mega-component** (overturns D-13): extend the named family instead.
- **ARIA table roles on the responsive grid** (D-09): regresses AT announcement over a stacked card.
- **Client-only `data-confirm` for destructive actions** (the prune bug): provides zero server enforcement; an attacker bypasses it trivially.
- **Constant-string confirmation ("type DELETE")**: degenerates into ritual; type the object's *own* identifier (change id / policy name) per D-20.
- **Letting the failure reason collapse to "something went wrong"**: destroys the three forensic distinctions (D-16) that are the entire reason DATA-03 exists.
- **Bulk multi-select over redact/prune** (D-19): worst possible blast radius.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Constant-time token compare for T3 | Custom `==` / `String.equivalent?` | `Plug.Crypto.secure_compare/2` (plug already a dep) | `==` leaks timing; `secure_compare` is the standard fail-closed primitive. |
| Clipboard copy | A LiveView hook / new JS file | Existing `script.ex` delegated listener + `data-tl-copy` | Already CSP-aware, idempotent (`__tlCopyBound`), survives LiveView patches, zero-dep. |
| Modal focus trap / restore | New JS | `modal/1` (`focus_first`/`pop_focus`, ui.ex:406) | Already keyboard/escape/scrim-correct. |
| Kebab menu semantics | New disclosure widget | `dropdown/1` (`role=menu`/`aria-haspopup`, ui.ex:629) | Already APG-aligned + CSP-proof. |
| Async loading/failed/ok branching | Manual flags spread across assigns | `assign_async`/`<.async_result>` | Idiomatic LV 1.1; gives the switch cleanly (but is a new pattern here — see Open Q1). |
| Streamed row updates | Re-assign full list each tick | `phx-update="stream"` (retention already streams runs) | Memory-bounded; `data_table` `stream:` is built for this. |
| Charts | A chart library | Inline SVG / CSS `width:%` bar + label/pattern | Zero-dep invariant; coverage % is trivially a CSS bar. |
| Relative time | A datetime/JS humanizer | `Presentation.human_time/2` + `exact_time/1` (UTC, present) | Already deterministic + tz-explicit; live-ticking is deferred. |

**Key insight:** Almost nothing here is genuinely new infrastructure — the components, the copy mechanism, the modal/menu/stream primitives, and the time helpers all exist and are tested. The phase's value is *convergence + a security fix*, not invention. The only genuinely new backend question is the T3-redact runtime operation (below).

## Runtime State Inventory

> This phase is partly a refactor/consolidation (renaming render paths, deleting CSS). State inventory per category:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — this phase changes *how* values are displayed/copied/confirmed, not what is stored. The capture & semantics layers stay untouched (v1.37 invariant, CLAUDE.md). The one DB *write* introduced is the T3 destructive action itself (prune/redact) and the `AuditAction` recording it — those are new writes, not migrations of existing keys. | Code edit only (no data migration) for display; new writes for destructive actions go through existing `Pruner`/`AuditAction`. |
| Live service config | None — no external service config embeds a renamed string. | None. |
| OS-registered state | None. | None. |
| Secrets/env vars | `operator_surface_embed_scripts` config flag is referenced, not renamed (script.ex:45). No secret/env rename. | None. |
| Build artifacts | Deleting `tl-coverage-command__*` CSS (style.ex ~3336) and `text-overflow:ellipsis` (~2490) — these are source edits, the compiled `style.ex` regenerates on compile. The **`style_contract_test`** and **`brandbook_token_parity_test`** assert against the source string, so any deletion must be paired with a contract-test update. | Code edit + update `style_contract_test.exs` assertions if they reference deleted selectors. |

**Verified:** capture/semantics untouched is an explicit invariant (REQUIREMENTS.md:7,94; CLAUDE.md three-layer rule). This is exploration-layer UI only.

## Common Pitfalls

### Pitfall 1: Assuming the T3-redact handler is a thin wrapper
**What goes wrong:** D-20/D-21 describe "redact an audit value" as a T3 type-to-confirm action with server enforcement, parallel to "prune now." A planner reads this and writes a task "wire `handle_redact` like `handle_prune`."
**Why it happens:** Prune *does* have a runtime backend (`Pruner.trigger/0`). Redaction does **not** — `capture/redaction_policy.ex` validates trigger options at *codegen time* (when generating the SQL trigger), and `trigger_sql.ex` bakes redaction into the capture trigger. There is no "redact this one already-stored audit value at runtime" operation in the tree today.
**How to avoid:** Gate the redact flow with a `checkpoint:human-verify` task: confirm whether (a) a runtime redaction backend is in scope for this phase, or (b) the redact UI should target whatever runtime operation actually exists, or (c) redact is deferred and only prune ships the T3 pattern this phase. Do not plan a `handle_redact` against a non-existent backend.
**Warning signs:** A task that says "mirror the prune handler for redact" with no backend-build subtask.

### Pitfall 2: Breaking the style/parity contract tests on CSS deletion
**What goes wrong:** Removing `text-overflow:ellipsis` or `tl-coverage-command__*` makes `style_contract_test.exs` or `brandbook_token_parity_test.exs` fail (they assert against literal source strings).
**Why it happens:** These tests read `style.ex` as a string and assert presence/absence of selectors and tokens.
**How to avoid:** Every CSS deletion/addition is paired in the same task with the corresponding contract-test assertion update. Run `mix verify.test` (or the targeted file) after each style change. The new card-nesting regression test (D-12) must be added here too.
**Warning signs:** A "delete dead CSS" task with no test-file edit beside it.

### Pitfall 3: `assign_async` failure reasons getting normalized
**What goes wrong:** The data layer raises/returns a generic error and the typed reason (`:unauthorized`/`:source_down`) is lost before the view, collapsing permission/unavailable/error into one state — defeating DATA-03's whole purpose.
**Why it happens:** `assign_async`'s `{:error, reason}` path is easy to populate with `Exception.message/1` or `:error`.
**How to avoid:** The async function must return the *typed atom* reason; the `<:failed>` branch pattern-matches it. Add a unit/integration test asserting each typed reason renders the correct state component + icon shape + heading.
**Warning signs:** A `<:failed :let={reason}>` that renders `error_state` unconditionally.

### Pitfall 4: Copy button binding the field instead of `ref.full` after consolidation
**What goes wrong:** During the `secondary_ref → ref` migration, a call site keeps `data-tl-copy={ref.visible}` or the bare field, silently copying a truncated value.
**Why it happens:** Mechanical find/replace; `.visible` and `.full` differ only when truncation fires (long values — exactly the forensic cases).
**How to avoid:** A contract test asserting that for a value long enough to truncate, the rendered `data-tl-copy` equals the full value and `≠` the visible text. Apply across every consuming LiveView.
**Warning signs:** `data-tl-copy={...visible}` or `data-tl-copy={...title}` anywhere post-migration.

## Code Examples

### Time as relative + absolute, UTC explicit, semantic `<time>` (D-22)
```elixir
# Presentation already emits UTC-explicit strings (presentation.ex:10-31, verified):
#   human_time/2  -> "Today, 3:04 PM UTC"   (relative-ish, tz explicit)
#   exact_time/1  -> "2026-06-17T15:04:00Z" (absolute ISO)
~H"""
<time datetime={Presentation.exact_time(@dt)} title={Presentation.exact_time(@dt)}>
  <%= Presentation.human_time(@dt) %>
</time>
"""
```

### T3 destructive enforcement skeleton (D-21 — server is the only authority)
```elixir
def handle_event("prune_now", %{"policy_name" => typed}, socket) do
  with :ok        <- authorize(socket, :prune),                 # 2. re-check authz (untrusted)
       {:ok, pol} <- fetch_policy_scoped(socket),               # 2. scope-filter; forged id fails
       true       <- Plug.Crypto.secure_compare(typed, pol.name), # 1+4. canonical token compare
       :ok        <- Pruner.trigger(),                           # real backend (pruner.ex:35)
       {:ok, _}   <- audit_action(socket, "retention.pruned", pol) do  # 3. audit-the-action
    {:noreply, put_flash(socket, :info, "Prune started.")}
  else
    _ -> {:noreply, put_flash(socket, :error, "Could not prune.")}  # 6. fail closed
  end
end
```
> Never ship the canonical token to the client to compare client-side (D-21.1). `phx-value-id` is an untrusted claim, not a grant (D-21.2).

## State of the Art

| Old Approach (in tree today) | Current Approach (this phase) | Impact |
|------------------------------|-------------------------------|--------|
| Five divergent ref/copy paths (`secondary_ref`, `value_token`, 3 ad-hoc) | One `ref/1` + `Presentation.ref/2` | Single forensic contract; copy always = full value |
| `data-tl-copy={ref.title}` (transaction_live.ex:121,145) | `data-tl-copy={ref.full}` | Closes the truncated-copy footgun |
| KV/diff values rendered raw, untruncated, no copy | Routed through truncate+gated copy (max ~56) | Closes the core DATA-01 gap |
| Client-only `data-confirm` prune (no server check) | T3 `secure_compare` + authz + audit + fail-closed | Closes the load-bearing security hole |
| Hand-rolled coverage header inside synthetic shell | `page_header/1` in all 3 branches; shell demoted | DATA-05 flatten; one card per logical unit |
| Synchronous `mount` data load, ad-hoc state flags | `assign_async`/`<.async_result>` + named state family | Distinct, explained empty/loading/error/stale/permission/unavailable |

**Deprecated/outdated within this surface:**
- `tl-param-list` / `tl-meta` span-soup → replaced by `kv/1` `<dl>`.
- `tl-table--actionable` class-soup → replaced by `data_table` `:action` slot.
- `tl-coverage-command__*` → deleted after flatten.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Presentation.ref/2` returns exactly `%{visible, title, full}` and the component binds `full` to `data-tl-copy` + `title` | Pattern 1 | Low — directly specified by D-01/D-02; shape is the planner's discretion to finalize. |
| A2 | The T3 "redact an audit value" runtime operation does not exist and may need a new backend | Open Questions / Pitfall 1 | **HIGH** — verified `policy_redaction_live.ex` has no redact `handle_event` and redaction is codegen-time only; but a redact backend could exist under a name not matched by my grep. Must be confirmed before planning the redact handler. |
| A3 | Keeping synchronous `mount` loads (instead of `assign_async`) can still satisfy DATA-03 if state branching is explicit | Standard Stack / Open Q1 | Medium — D-17 names `assign_async` as the dispatch; deviating is a discretion call the planner should make consciously. |
| A4 | `style_contract_test.exs` / `brandbook_token_parity_test.exs` assert against literal `style.ex` source strings, so CSS deletions break them unless updated | Pitfall 2 / Validation | Low — verified by reading `style_contract_test.exs` (reads file, asserts `String.contains?`). |
| A5 | Icons `eye-off`, `plug`/`cloud-off` may be missing from the registry | Standard Stack | Low — D-15/CONTEXT flag "add only if missing"; planner verifies against `icon.ex`. |

## Open Questions (RESOLVED)

1. **`assign_async` adoption vs. synchronous load.**
   - What we know: D-17 specifies `assign_async`/`<.async_result>` dispatch; LV 1.1.30 supports it; **no `assign_async` exists in the surface today** (verified — zero matches). All 11 LiveViews load synchronously in `mount`.
   - What's unclear: whether the phase budget covers converting each consuming page to async, or whether some pages keep sync load + explicit state branching (which still satisfies DATA-03's *taxonomy* requirement).
   - Recommendation: Plan the **state taxonomy components** (`loading_state`/`stale_banner`/variants) as the hard requirement; treat `assign_async` conversion as a per-page choice. Convert pages where data is genuinely slow/fallible (coverage introspection, evidence); keep fast in-DB reads synchronous if budget is tight. Make this an explicit planning decision, not an accident.
   - **RESOLVED:** The DATA-03 state-taxonomy components are the hard requirement (built in Plan 02); `assign_async`/`<.async_result>` conversion is treated as per-page planner discretion in the consumer plans (convert genuinely slow/fallible pages, keep fast in-DB reads synchronous with explicit state branching). The taxonomy — not async conversion — is what every plan must deliver.

2. **T3-redact backend existence (BLOCKING for the redact flow).**
   - What we know: `Pruner.trigger/0` backs "prune now" (real). Redaction is codegen-time (`capture/redaction_policy.ex`, `capture/trigger_sql.ex`); `policy_redaction_live.ex` is a read-only Configured-vs-Deployed diff with **no redact `handle_event`**.
   - What's unclear: whether a runtime "redact an already-captured value" operation is intended to be built this phase, targets an existing operation I didn't locate, or is deferred.
   - Recommendation: Insert a `checkpoint:human-verify` early. If no runtime redaction backend exists and building one is out of scope, ship the **T3 pattern via "prune now" only** this phase and defer redact's destructive flow, OR scope redact to a confirmed runtime operation. Do not plan a redact handler against a non-existent backend.
   - **RESOLVED:** A blocking `checkpoint:human-verify` is planned in Plan 05 Task 1 to confirm whether a runtime redact backend exists; the default disposition is to ship the T3 pattern via "prune now" only this phase and defer redact's destructive flow unless the checkpoint confirms a runtime redaction operation to scope against. No redact handler is planned against a non-existent backend.

3. **Stress-route registration of the new components.**
   - What we know: every new/extended unit must render in isolation on `/audit/__stress` (DS-01) across the matrix; `stress_fixtures.ex` already has `long_id`, `permission_denied`, `stale`, `non_ascii`, etc.; `stress_ledger_test.exs` + `stress_router_test.exs` enforce coverage.
   - What's unclear: exact registration shape for `ref`/`kv`/`data_table`/state components in `stress_live.ex` (the file currently registers stories via `stress_fixtures` `assigns_for/1`).
   - Recommendation: Plan a task to add a story per new component + each data-state (loading/stale/no_data/permission/unavailable/unavailable-down/redacted/pruned), reusing existing ugly-data fixtures; update `stress_ledger_test` expectations.
   - **RESOLVED:** Plan 02 Task 3 registers a `/audit/__stress` story per new component (`ref`/`kv`/`data_table`) and each data-state, reusing existing ugly-data fixtures and updating `stress_ledger_test.exs`/`stress_router_test.exs` expectations in the same task so ledger↔registry parity stays green.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `phoenix_live_view` | All components, `assign_async`, streams | ✓ | 1.1.30 (mix.lock) | — |
| `plug` (`Plug.Crypto`) | T3 `secure_compare` (D-21) | ✓ | ~> 1.15 (direct dep) | — |
| `jason` | `value_token` JSON | ✓ | present | — |
| Node/Playwright (e2e) | `verify.operator_stress` screenshot matrix | ✓ (examples/threadline_phoenix/e2e) | operator-stress.spec.ts present | — |
| Chart library | (none — D-22 forbids) | — (intentional) | — | Inline SVG / CSS bar |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None needed — chart lib intentionally absent by invariant.

## Validation Architecture

> `workflow.nyquist_validation: true` (verified in config.json). Section included.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir) + Playwright (e2e screenshot matrix) |
| Config file | `test/test_helper.exs`; `mix.exs` aliases |
| Quick run command | `mix test test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/presentation_test.exs` |
| Full suite command | `mix verify.test` (and `mix ci.all` for the full gate) |
| Style/parity gates | `mix test test/threadline/operator_surface/style_contract_test.exs test/threadline/brandbook_token_parity_test.exs` |
| Stress/ledger gates | `mix test test/threadline/operator_surface/stress_ledger_test.exs test/threadline/operator_surface/stress_router_test.exs test/threadline/operator_surface/stress_fixtures_test.exs` |
| Visual matrix | `mix verify.operator_stress` (Playwright `operator-stress.spec.ts`, 5 viewports × dark/light/system) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DATA-01 | `truncate_middle` guarantees ≥8-char tail; middle-truncates per type | unit | `mix test test/threadline/operator_surface/presentation_test.exs` | ✅ (extend — `:tail_min` cases) |
| DATA-01 | `ref/1` binds `data-tl-copy={full}`, not `.title`/`.visible`, for a long value | unit/component | `mix test test/threadline/operator_surface/ui_test.exs` | ✅ (add `ref` describe) |
| DATA-01 | Each consuming LiveView copies the full value (no truncated copy) | integration | `mix test test/threadline/operator_surface/transaction_live_test.exs` | ✅ (extend) / ❌ others Wave 0 |
| DATA-01 | `data_table` `:col label` emits both `<th>` and `<td data-label>` | component | `mix test test/threadline/operator_surface/ui_test.exs` | ✅ (add) |
| DATA-02 | Time renders `<time datetime>` UTC relative+absolute | unit/component | `mix test test/threadline/operator_surface/presentation_test.exs` | ✅ (extend) |
| DATA-02 | Status pairs color with label/shape (never color alone) | component | `mix test test/threadline/operator_surface/ui_test.exs` | ✅ |
| DATA-03 | `loading_state`/`stale_banner`/3 variants render correct role/icon/heading | component | `mix test test/threadline/operator_surface/ui_test.exs` | ✅ (add) |
| DATA-03 | Each typed `:failed` reason maps to the correct state (permission≠no_data≠unavailable) | integration | `mix test test/threadline/operator_surface/live/...` | ❌ Wave 0 (per affected page) |
| DATA-04 | Kebab renders destructive item last after divider w/ non-color cue | component | `mix test test/threadline/operator_surface/ui_test.exs` | ✅ |
| DATA-04 | T3 handler fails closed on token mismatch / forged id / missing authz; audits the action | integration | `mix test test/threadline/operator_surface/live/retention_history_live_test.exs` | ❌ Wave 0 (security-critical) |
| DATA-04 | No bulk multi-select present | component/integration | grep-style assertion in page test | ❌ Wave 0 |
| DATA-05 | No card-family class nested under another card-family class per rendered page | regression | new test (D-12) across 11 pages | ❌ Wave 0 |
| DATA-05 | `style.ex` no longer contains `text-overflow:ellipsis` on `.tl-secondary-ref` / `tl-coverage-command__*` | contract | `mix test test/threadline/operator_surface/style_contract_test.exs` | ✅ (update assertions) |
| all | Every new/extended unit registered + rendered on `/audit/__stress` across matrix | visual+ledger | `mix verify.operator_stress` + `stress_ledger_test.exs` | ✅ (extend stories) |

### Sampling Rate
- **Per task commit:** quick run of the touched `*_test.exs` (e.g. `presentation_test`, `ui_test`) + `mix verify.format`.
- **Per wave merge:** `mix verify.test` + `style_contract_test` + `brandbook_token_parity_test` + stress ledger tests.
- **Phase gate:** `mix ci.all` green + `mix verify.operator_stress` (screenshot matrix) before `/gsd:verify-work`.

### Wave 0 Gaps
- [ ] T3 security test for `retention_history_live` — fail-closed on mismatch/forged-id/no-authz + audits action (DATA-04) — **highest priority; security-critical**.
- [ ] Card-nesting regression test across 11 pages (DATA-05, D-12).
- [ ] Per-page typed-reason → state mapping tests (DATA-03) for each converted page.
- [ ] `ref` copy-equals-full contract test reused across every consuming LiveView (DATA-01, Pitfall 4).
- [ ] Stress-story registration + `stress_ledger_test` expectation updates for new components/states.
- [ ] `style_contract_test` assertion updates paired with each CSS deletion (so deletion can't silently regress).

## Security Domain

> `security_enforcement` not set to `false` in config — included. This phase contains a real, currently-open security hole (client-only destructive confirm), so this section is load-bearing, not boilerplate.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V1 Architecture | yes | Three-layer separation held; exploration-layer only; capture/semantics untouched (CLAUDE.md). |
| V2 Authentication | no (existing surface auth unchanged) | Fail-closed surface auth already enforced (auth_test.exs, gating_test.exs). |
| V4 Access Control | **yes** | T3 must re-check authorization in the `handle_event` — `phx-value-id` is an untrusted claim, scope-filter the query so a forged id fails closed (D-21.2). |
| V5 Input Validation | **yes** | Typed-confirmation input compared via constant-time `secure_compare` against the DB canonical token; never trust client-supplied token (D-21.1). |
| V6 Cryptography | **yes** | `Plug.Crypto.secure_compare/2` — never hand-roll `==` for token comparison. |
| V7 Error Handling/Logging | **yes** | Destructive action audited as an `AuditAction` (D-21.3); default path is refusal (fail closed). |
| V14 Config | yes | `operator_surface_embed_scripts` CSP escape hatch preserved; no inline `on*=` handlers (CSP-proof). |

### Known Threat Patterns for Phoenix/LiveView operator surface

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Client-only `data-confirm` bypass (current prune bug) | Tampering / EoP | Move enforcement to `handle_event`; client confirm is UX only, never the gate. |
| Forged `phx-value-id` to prune/redact another scope's data | EoP | Re-check authz + scope-filter query in the event; fail closed on miss. |
| Replaying/forging the typed confirmation token | Spoofing | Re-fetch canonical token from DB at action time; `secure_compare`; never ship token to client. |
| Timing attack on token compare | Information disclosure | `Plug.Crypto.secure_compare/2` (constant-time). |
| Copying a truncated audit value (forensic integrity) | Tampering (evidence) | `data-tl-copy={ref.full}` + zero-JS select-all renders `ref.full`. |
| Unaudited destructive action | Repudiation | Record the destructive action itself as an `AuditAction` (audit the auditor). |
| Inline-script CSP violation | (defense-in-depth) | No inline `on*=`; copy via delegated listener; JS via `Phoenix.LiveView.JS` only. |

## Project Constraints (from CLAUDE.md)

- **Three-layer architecture** — this phase is **exploration/operations layer only**; capture and semantics layers MUST stay untouched (explicit invariant; REQUIREMENTS.md:94).
- **Domain language** — use AuditTransaction / AuditChange / AuditAction / ActorRef / Correlation consistently in any new copy/labels.
- **Named verification entrypoints** — cite `mix verify.format` / `mix verify.credo` / `mix verify.test` / `mix ci.all` (+ `mix verify.operator_stress`) in tasks; do not invent ad-hoc commands.
- **Honest default tests** — do not exclude heavy suites from `mix test` without updating `test_helper.exs` + docs together.
- **Stable CI job IDs** — keep GitHub Actions job `id:` immutable; evolve `name:` freely.
- **GSD state** — when running `gsd-sdk query state.begin-phase`, use **positional** args (`phase`, `slug`, `plan_count`); flag-style invocations corrupt `.planning/STATE.md`.
- **v1.37 invariants** — no public component API; zero new runtime deps; inline assets only (no Tailwind/Alpine/build tooling); CSP-safe (no inline event handlers); brand-token parity green; fail-closed auth; WCAG 2.2 AA build-to.

## Sources

### Primary (HIGH confidence — read directly from working tree)
- `lib/threadline/operator_surface/presentation.ex` — `truncate_middle/2` (L58), `secondary_ref/2` (L229), `value_token/1` (L239), time helpers (L6-45).
- `lib/threadline/operator_surface/ui.ex` — `empty_state/1` (L358), `error_state/1` (L377), `modal/1` (L406), `dropdown/1` (L629), `stat_tile/1` (L341).
- `lib/threadline/operator_surface/script.ex` — delegated copy listener, `enabled?/0`, `operator_surface_embed_scripts` flag.
- `lib/threadline/operator_surface/live/{transaction,retention_history,policy_redaction,coverage,timeline,actor,evidence,export_status,row_history_component}_live.ex` — call-site grep (`secondary_ref`/`value_token`/`data-confirm`/`data-tl-copy`), prune handler (retention L37), absence of redact handler.
- `lib/threadline/capture/redaction_policy.ex`, `trigger_sql.ex` — redaction is codegen-time only.
- `lib/threadline/retention/pruner.ex` — `trigger/0` (L35).
- `lib/threadline/semantics/audit_action.ex` — `changeset/2` (L57).
- `test/threadline/operator_surface/{ui_test,style_contract_test,presentation_test,stress_*}.exs` — test patterns + contract-string assertions.
- `mix.exs` (aliases, deps) + `mix.lock` (phoenix_live_view 1.1.30).
- `.planning/phases/176-data-display-operator-patterns/176-CONTEXT.md` + `176-UI-SPEC.md` (approved) + `.planning/REQUIREMENTS.md`.

### Secondary (MEDIUM)
- `.planning/config.json` (nyquist_validation true), CLAUDE.md, MEMORY.md (project invariants).

### Tertiary (LOW)
- None — this research did not rely on web search; every claim is grounded in the working tree or locked planning docs.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all versions read from mix.lock/mix.exs; zero new deps.
- Architecture: HIGH — file/line map verified against source, not training data.
- Pitfalls: HIGH — the two security/forensic pitfalls are confirmed live bugs (`transaction_live.ex:121` copies `.title`; prune is client-only `data-confirm`).
- T3-redact backend: MEDIUM — verified absent by grep across `policy_redaction_live`, `governance/`, `capture/`, but a backend under an unmatched name cannot be fully excluded → flagged as blocking Open Question 2.

**Research date:** 2026-06-17
**Valid until:** 2026-07-17 (stable — internal codebase, no fast-moving external deps; re-verify only if phases 173-175 components shift before planning).
