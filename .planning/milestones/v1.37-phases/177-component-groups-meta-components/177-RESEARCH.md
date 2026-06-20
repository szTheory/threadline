# Phase 177: Component groups / meta-components - Research

**Researched:** 2026-06-18
**Domain:** Phoenix LiveView function-component composition; internal `--tl-*` token design system; CSP-clean motion + connection-lifecycle CSS
**Confidence:** HIGH (codebase verified line-by-line; LiveView connection classes verified against v1.1.0 source; JS transition API verified against official docs)

## Summary

This is a **compose-and-audit** phase, not greenfield. Every constituent primitive already exists in `lib/threadline/operator_surface/ui.ex` (verified: `page_header` L210, `pager` L291, `stat_tile` L350, `kv` L409, `data_table` L446, the full state family `empty_state`/`error_state`/`loading_state`/`stale_banner`/`data_state` L489–655, `modal` L676, `drawer` L746, `toast` L814, `tabs` L927, `dropdown` L899, `segmented_control` L945, `accordion` L962). The phase ships five new internal function components (`stack/1`, `cluster/1`, `data_panel/1`, `toolbar/1`, `detail_header/1`), wires a breadcrumbs surface on `page_header/1`, encodes cross-child state coordination, defines group motion via `Phoenix.LiveView.JS`, builds the reconnect/offline group from LiveView's connection CSS hooks, and maps all 12 GROUP-01 configurations onto stress stories.

Three findings materially change the plan versus the assumptions baked into CONTEXT/UI-SPEC and MUST be surfaced to the planner before any task is written:

1. **`page_header/1` already has a `breadcrumbs` API — but it's an `attr(:breadcrumbs, :list)` (L189), NOT the `:breadcrumbs` *slot* D-04 calls for.** A private `breadcrumb_trail/1` (L232) already renders it, reusing the `tl-transaction__breadcrumbs` CSS (style.ex L2313). D-04/D-14 must reconcile: keep the working list-attr, OR convert to a slot. Converting to a slot is a breaking change to the attr already shipped; the list-attr is arguably the better fit (breadcrumbs are data, not markup). [VERIFIED: codebase]
2. **LiveView's connection classes attach to the LiveView ROOT element, not `<body>`.** The UI-SPEC and CONTEXT D-08 repeatedly say "body classes (`.phx-loading`/`.phx-disconnected`/…)". This is wrong on two counts: (a) the classes go on the LiveView container element (`this.el`), and (b) `.phx-disconnected` no longer exists in LiveView 1.x — it was replaced by `.phx-loading`. The actual class set is `phx-connected`, `phx-loading`, `phx-error`, `phx-client-error`, `phx-server-error`. [VERIFIED: phoenix_live_view v1.1.0 source]
3. **The overlay primitives (`modal`/`drawer`/`toast`) reference JS-transition utility classes that DO NOT EXIST in `style.ex`.** `show_modal`/`hide_modal`/`show_drawer`/`hide_drawer` (ui.ex L709–843) use `tl-fade-in`, `tl-rise-in`, `opacity-0`, `opacity-100`, `translate-y-4`, `translate-y-0`, `translate-x-full`, `translate-x-0`, plus `tl-modal-container`/`tl-drawer-container`/`tl-toast` shells — none are defined in `style.ex` (verified by grep; only `@keyframes tl-rise-in`/`tl-fade-in` exist, which are for CSS `animation:` mount reveals, not JS `transition:` tuples). The group-motion work (D-10.1) is therefore partly **completing unfinished overlay CSS**, not just polishing it. [VERIFIED: codebase]

**Primary recommendation:** Build `stack`/`cluster` first (pure layout, zero coordination), then `data_panel` (the highest-value extraction and the locus of state-alignment bugs), then `toolbar`/`detail_header`, then the offline group (keyed off the LiveView root, not body), then complete the overlay JS-transition CSS + define the missing utility classes, then map the stress stories. Reconcile the breadcrumbs attr-vs-slot question and the body-vs-root class question explicitly at plan time — both are locked-decision conflicts with reality.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Vertical/horizontal spacing rhythm (`stack`/`cluster`) | Frontend (HEEx function component) | CSS (`style.ex`) | Pure presentational layout; no server state |
| Data-region state coordination (`data_panel`) | Frontend (component shell) | Server (typed reason flows in via author branching, D-06d) | The shell coordinates; the server still owns *which* state via its typed reason |
| Toolbar disabled-coordination | Frontend (CSS state + `disabled` attr) | Server (loading/error assigns) | Disabled state derived from the data region's state assign |
| Detail-header layout | Frontend | — | Pure composition of `kv` + actions |
| Breadcrumb trail | Frontend | — | Location data passed as a list |
| Reconnect/offline banner + action-disable | Browser (LiveView client CSS classes) | CSS (`style.ex`) | **Zero server involvement** — rides the client's own `phx-*` lifecycle classes on the LiveView root |
| Overlay enter/exit motion | Browser (`Phoenix.LiveView.JS` transitions) | CSS utility classes | CSP-clean client transitions; no server round-trip |
| Stress-story audit surface | Frontend (`stress_live.ex`) + ledger JSON | — | Pure verification scaffold |

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GROUP-01 | The 12 recurring configurations audited as units with intentional spacing/hierarchy | `stack`/`cluster` + semantic gap tokens own the rhythm; `data_panel`/`toolbar`/`detail_header` lock the high-recurrence assemblies; all 12 mapped to stress stories (Verification Surface §). Spacing mechanics + existing `--tl-space-*`/`--tl-gap-*` documented below. |
| GROUP-02 | Each group holds together narrow↔wide, states aligned across children, motion clarifies transitions | State Coordination Contract (data_panel owns focus-move, scoped-by-state-kind sibling behavior); Motion Contract (overlay/state-swap/stale/tab via `Phoenix.LiveView.JS`, GPU-only, reduced-motion blanket inherited); Responsive Reflow § (reuse `data-label`/`::before`, `cluster` wrap) verified at 320/375/768/1024/1440. |

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01 — Hybrid, primitives-first.** Tiny set of layout/spacing primitives that pages compose explicitly; extract a named meta-component ONLY for assemblies that recur verbatim with real coordination logic. Everything else audited in-place as inline composition.

**D-02 — Layout primitives: `UI.stack/1` (vertical rhythm) + `UI.cluster/1` (horizontal grouping with wrap).** Both `@doc false`, strict `attr`/`slot`, `--tl-*`-driven, zero public API. Map to `--tl-space-*` scale; a small set of *semantic* gap tokens (stack/inline/section, D-09) sits on top.

**D-03 — Named meta-components to extract:**
- `UI.data_panel/1` — `data_table` + empty/loading/error/stale/no-data/permission/unavailable state family + `pager`, with cross-child state-coordination (D-06) baked in. Highest-value extraction. Recurs on coverage, retention, timeline.
- `UI.toolbar/1` — search + filters + sort as a `cluster` with consistent wrap/spacing and disabled-coordination. Recurs on timeline / any filtered list.
- `UI.detail_header/1` — title + metadata `kv` + actions for transaction / actor / row-history (recurs 3×).

**D-04 — Do NOT make a new group for page-header+actions+breadcrumbs.** Add a `:breadcrumbs` slot (alongside existing `:actions`) to the existing `UI.page_header/1`. One canonical header.

**D-05 — Everything else stays inline composition** over `stack`/`cluster` (stat-cards+chart+table, modal+destructive, drawer+form, toast+state-update, tabs+subviews, empty+CTA, permission-denied, reconnect/offline). Audited as units on the stress route, not extracted.

**D-06 — Scoped-by-state-class coordination** — siblings react by state *kind*:
- Content-replacing (empty/no-data/error/loading): swap ONLY the data region; `page_header`(+breadcrumbs) and `toolbar` stay; toolbar filter/sort controls go **disabled** while loading and on hard error.
- Resource-level permission/unavailable: collapse the whole **panel body** to one message; `page_header` stays.
- Stale: a `role="status"` banner **above still-rendered data** — never replaces it (D-176-14).

**D-06b — Audit all 12 configurations as group stress stories.** Map the 6 existing reserved baselines onto the 12 and add the missing ones. Build from real-page markup where it exists; where a config isn't on a live page, the stress story IS the canonical reference assembly.

**D-06c — The `data_panel` owns the focus-move on state transition**, per the per-state focus rules locked in D-176-15 (error focuses `tabindex=-1` heading; permission/unavailable focus a rescue element; loading/empty are `role=status`).

**D-06d — Branching stays the page author's job** (D-176-17): ok-empty → `empty` vs `no_data`; `:failed` reason → `permission`/`unavailable`/generic `error`. The group provides the coordinated shell; the typed server reason flows through.

**D-07 — Tag each group story `live` vs `reference-only` in the ledger** so Phase 178 knows which groups are shipped vs reference-only. Reference-only groups still get audited.

**D-08 — Reconnect/offline-banner + disabled-actions group rides LiveView's built-in connection CSS hooks.** Use framework body classes (`.phx-loading`, `.phx-disconnected`, `.phx-error`/`.phx-client-error`/`.phx-server-error`) to drive a reconnect banner (`role="status"`) and disable mutating actions via pure CSS. Zero new JS/deps, CSP-clean. Catches a dropped socket mid-session (unlike mount-time `connected?/1`). *(See Pitfall 1 — these classes attach to the LiveView root, not `body`, and `.phx-disconnected` is `.phx-loading` in LiveView 1.x.)*

**D-08b — Chart piece stays hand-rolled inline** (D-176-22): inline SVG / CSS bar, no chart library; encode meaning with label + shape/pattern (no color alone). Not a new named component.

**D-10 — What earns motion:** (1) Overlay enter/exit (modal fade+scale, drawer slide, toast fade-up, dropdown fade+offset) via `Phoenix.LiveView.JS`; (2) Data-region state swap — short cross-fade (`--tl-motion-fast`) on the *region container*, opacity-only; (3) Stale banner appear — fade/slide in above live data; (4) Tab/segmented switch — active indicator + subview crossfade. Everything else instant.

**D-11 — Motion constraints:** GPU-only (transform/opacity), reuse `--tl-motion-fast`/`--tl-motion-base`/`--tl-ease-standard`, fire on mount. **Never animate high-frequency actions** — timeline stream per-row inserts stay un-animated. Data-region swap animates the **container on a state change**, NOT individual streamed rows.

**D-12 — Reduced-motion is settled system-wide** — `@media (prefers-reduced-motion: reduce)` blanket at `style.ex:3868` collapses transitions/animations to ~1ms. New group motion inherits it; no per-component handling needed.

### Claude's Discretion

**D-09 — Spacing/hierarchy rhythm** — likely a small set of *semantic* gap tokens (stack/inline/section) over `--tl-space-*`, consumed by `stack`/`cluster`. Exact token names + numeric mappings: discretion, matching the `--tl-*` BEM idiom.

**D-13 — Per-group responsive reflow** — toolbar wrap order, action-bar→kebab collapse, stat-cards grid→stack, breadcrumb truncation/overflow. Reuse existing responsive mechanisms (`data-label`/`::before`, `cluster` wrap); no ARIA table roles (D-176-09). Verify at 320/375/768/1024/1440.

**D-14 — Exact names/slot APIs** for `stack`/`cluster`/`data_panel`/`toolbar`/`detail_header`, the `:breadcrumbs` slot shape, ledger tag field name, new `--tl-*` token names, file location — match existing `ui.ex` `attr`/`slot` + `--tl-*` idioms and 173–176 conventions.

### Deferred Ideas (OUT OF SCOPE)

- Fully building configs with no live page (drawer+form, tabs+subviews as shipped surfaces) — reference-only this phase; promote on real demand.
- A named `UI.chart` component — chart stays hand-rolled inline; extract only if a second charted surface appears.
- Group-level bulk actions / multi-select — rejected in D-176-19; not revisited.
- Per-group copy/microcopy sweep — systematic pass is Phase 179.
</user_constraints>

---

## Standard Stack

No new libraries. The entire phase composes existing internal modules. Zero new runtime deps is a v1.37 invariant.

| Module / API | Where | Purpose | Why Standard |
|--------------|-------|---------|--------------|
| `Phoenix.Component` (`attr`/`slot`/`~H`) | `ui.ex` | Function-component definition | The 173–176 convention; already `use`d at ui.ex L3 |
| `Phoenix.LiveView.JS` | aliased at ui.ex L5 | CSP-clean show/hide transitions, class/attribute toggles | Already used by modal/drawer/toast/dropdown; DOM-patch-aware [CITED: phoenix-live-view.hexdocs.pm/js-interop.html] |
| `--tl-*` token system | `brandbook/tokens.css` + `style.ex` | All spacing/color/motion | parity-tested by `brandbook_token_parity_test` |
| `Threadline.OperatorSurface.Presentation` | `presentation.ex` | `human_time/2`, `exact_time/1`, `ref/2` for detail_header/data_panel cells | Already the data-display helper layer (D-176) |

**Verified versions:** `phoenix_live_view` **1.1.30** (mix.lock), declared `~> 1.0` (mix.exs L61), `phoenix ~> 1.7`, `phoenix_html ~> 4.0` — all optional deps. [VERIFIED: mix.lock]

**Installation:** none — `mix deps.get` already satisfied.

## Package Legitimacy Audit

Not applicable. This phase installs **zero external packages** (v1.37 invariant: zero new runtime dependencies, inline assets only). The legitimacy gate is vacuously satisfied. No `npm`/`pip`/`cargo` install occurs; all components are internal `OperatorSurface.UI` function components written in Elixir/HEEx.

## Architecture Patterns

### System Architecture Diagram

```
                          ┌─────────────────────────────────────────────┐
  Server LiveView         │  page author branches typed reason (D-06d)   │
  (coverage/retention/    │  ok-empty → empty | no_data                  │
   timeline/transaction…) │  :failed  → permission | unavailable | error │
                          └───────────────────┬─────────────────────────┘
                                              │ assigns: rows | reason | as_of | loading?
                                              ▼
        ┌──────────────────── page-level <stack> (vertical rhythm, --tl-gap-section) ──────────────────┐
        │                                                                                              │
        │   ┌─ page_header (single <h1>) ──────────────────────────────────────────────────────────┐  │
        │   │  breadcrumb trail (list)   ·   title/lede/meta   ·   :actions  (primary CTA = accent)  │  │
        │   └──────────────────────────────────────────────────────────────────────────────────────┘  │
        │                                                                                              │
        │   ┌─ toolbar  (<cluster>, --tl-gap-inline, wraps at narrow) ────────────────────────────────┐ │
        │   │  search  ·  filters  ·  sort     ── DISABLED while data region = loading | hard error ──│ │
        │   └──────────────────────────────────────────────────────────────────────────────────────┘  │
        │                                                                                              │
        │   ┌─ data_panel (owns focus-move on transition, D-06c) ─────────────────────────────────────┐ │
        │   │  stale_banner (role=status) ── ABOVE data, never replaces (D-176-14)                     │ │
        │   │  ┌─ DATA REGION (cross-fades on state swap, opacity-only, --tl-motion-fast) ───────────┐ │ │
        │   │  │  happy: data_table          loading: loading_state (role=status, aria-busy)         │ │ │
        │   │  │  empty/no_data: empty_state error: error_state (focus tabindex=-1 heading)          │ │ │
        │   │  │  permission/unavailable: COLLAPSE panel body → one message (lock | cloud_off shape) │ │ │
        │   │  └────────────────────────────────────────────────────────────────────────────────────┘ │ │
        │   │  pager (de-emphasized, hide-at-zero / disable-not-hide, D-175-04)                        │ │
        │   └──────────────────────────────────────────────────────────────────────────────────────┘  │
        └──────────────────────────────────────────────────────────────────────────────────────────────┘

  Overlay layer (Phoenix.LiveView.JS transitions — CSP-clean, GPU-only):
     modal (fade+scale) · drawer (slide-from-edge) · toast (fade-up) · dropdown (fade+offset)

  Connection layer (CLIENT-applied classes on the LiveView ROOT element — NOT body):
     .phx-loading / .phx-error / .phx-client-error / .phx-server-error
        → reconnect banner (role=status) + descendant pointer-events/opacity/aria-disabled on mutating controls
```

### Recommended Component Locations

```
lib/threadline/operator_surface/
├── ui.ex            # ADD: stack/1, cluster/1, data_panel/1, toolbar/1, detail_header/1
│                    #      RECONCILE: page_header/1 breadcrumbs (attr already present L189)
├── style.ex         # ADD: .tl-stack, .tl-cluster, .tl-data-panel, .tl-toolbar, .tl-detail-header,
│                    #      .phx-* connection rules (keyed off LiveView ROOT), overlay JS-transition
│                    #      utility classes (currently MISSING), data-region cross-fade
├── stress_fixtures.ex  # REMAP @group_stories (6→12), add live/reference tag field
└── live/stress_live.ex # render group stories across viewports
brandbook/tokens.{css,json}  # ADD --tl-gap-* semantic tokens (parity-tested)
```

### Pattern 1: Layout primitive (`stack`/`cluster`) — flex + `gap`

`stack` and `cluster` are thin flex wrappers whose only job is to own the gap. Match the existing `attr`/`slot` idiom (e.g. `card/1` ui.ex L155–182). Cleanest mechanism is flexbox `gap` (no margin-collapse, no last-child resets).

```elixir
# Source: pattern derived from existing UI.card/1 (ui.ex L155) + tokens
@doc false
attr(:gap, :string, default: "stack", values: ~w(stack section inline tight))
attr(:class, :any, default: nil)
attr(:rest, :global)
slot(:inner_block, required: true)

def stack(assigns) do
  ~H"""
  <div class={["tl-stack", "tl-stack--#{@gap}", @class]} {@rest}>
    <%= render_slot(@inner_block) %>
  </div>
  """
end
```

```css
/* style.ex — flex column, gap-driven; NO raw child margins (GROUP-01 spacing rule) */
.tl-stack { display: flex; flex-direction: column; }
.tl-stack--stack   { gap: var(--tl-gap-stack); }    /* 16px */
.tl-stack--section { gap: var(--tl-gap-section); }   /* 32px */

.tl-cluster { display: flex; flex-wrap: wrap; align-items: center; gap: var(--tl-gap-inline); } /* 8px */
.tl-cluster--start { justify-content: flex-start; }
.tl-cluster--between { justify-content: space-between; }
```

**Confirmation against 173–176:** every existing component uses the `["tl-x", @variant && "tl-x--#{@variant}", @class]` class-list idiom (see `button/1` L27, `badge/1` L100, `stat_tile/1` L352) and a trailing `attr(:rest, :global)` + `slot(:inner_block)`. `stack`/`cluster` must follow it exactly. [VERIFIED: codebase]

### Pattern 2: Semantic gap tokens (D-09)

**The `--tl-gap-*` aliases ALREADY EXIST in `style.ex` (L175–176) but NOT in `tokens.css`.** This is a parity gap the planner must close:

```css
/* style.ex L175-176 — already present: */
--tl-gap-inline: var(--tl-space-2);   /* 8px */
--tl-gap-stack:  var(--tl-space-4);   /* 16px */
/* MISSING everywhere: --tl-gap-section (UI-SPEC proposes --tl-space-8 / 32px) */
```

Recommended mapping (matches UI-SPEC §"Semantic gap tokens"):

| Token | Maps to | Meaning | Status |
|-------|---------|---------|--------|
| `--tl-gap-inline` | `--tl-space-2` (8px) | Horizontal gap in a `cluster` | EXISTS in style.ex; **must add to tokens.css** |
| `--tl-gap-stack` | `--tl-space-4` (16px) | Vertical rhythm in a `stack` | EXISTS in style.ex; **must add to tokens.css** |
| `--tl-gap-section` | `--tl-space-8` (32px) | Section break between page-stack sections | **NEW — add to tokens.css + style.ex** |

**Critical:** `brandbook_token_parity_test` asserts tokens.css ↔ tokens.json ↔ style.ex consistency. Any `--tl-gap-*` must land in `tokens.{css,json}` first, then style.ex, in the same change, or the test goes red. [VERIFIED: codebase — DS-05 rule in UI-SPEC]

### Pattern 3: `data_panel/1` — state-coordinating shell

`data_panel` is a render-prop-ish shell: it takes the resolved state + the data slot and decides which region to show, owning the focus-move (D-06c). It does NOT branch the typed reason — that's the page author (D-06d). It composes the EXISTING state family (`loading_state` L551, `error_state` L526, `stale_banner` L570, `data_state` L590, `empty_state` L489).

```elixir
# Source: composes existing UI state family (ui.ex L489-655) + pager (L291)
@doc false
attr(:state, :atom, default: :ok,
  doc: "ok | loading | empty | no_data | error | permission | unavailable")
attr(:reason, :atom, default: nil, doc: "typed reason passed straight to data_state/1")
attr(:as_of, :string, default: nil, doc: "stale timestamp; presence renders stale_banner ABOVE data")
attr(:class, :any, default: nil)
attr(:rest, :global)
slot(:data, required: true, doc: "the data_table (only rendered in :ok)")
slot(:pager)

def data_panel(assigns) do
  ~H"""
  <section class={["tl-data-panel", @class]} {@rest}>
    <.stale_banner :if={@as_of} as_of={@as_of} />
    <div class="tl-data-panel__region" data-state={@state}>
      <%= cond do %>
        <% @state == :ok -> %><%= render_slot(@data) %>
        <% @state in [:permission, :unavailable] -> %>
          <.data_state reason={@reason} />          <%!-- collapses body, focuses rescue --%>
        <% true -> %>
          <.data_state reason={@reason || @state} as_of={@as_of} />
      <% end %>
    </div>
    <div :if={@pager != [] and @state == :ok} class="tl-data-panel__pager"><%= render_slot(@pager) %></div>
  </section>
  """
end
```

Key coordination rules the planner must encode:
- **Focus-move is already implemented inside the state family** — `error_state` (L526) sets `focus_heading` → `data_state(:error)`; `data_state(:unauthorized)` (L605) sets `focus_heading`; `loading_state`/`no_data` are `role=status`. `data_panel` just delegates; it does NOT reinvent the focus logic. [VERIFIED: codebase]
- **Pager hidden when not `:ok`** — and `pager/1` independently enforces hide-at-zero (L294 `:if={is_nil(@match_count) or @match_count > 0}`). [VERIFIED: codebase]
- **Stale banner sits ABOVE the region regardless of region state** (D-176-14), and stale is NOT a clause in the cond (it can coexist with `:ok` data).
- **Toolbar disabled-coordination is a SIBLING concern, not data_panel's** — the page passes the same `state` to both `toolbar` and `data_panel`; toolbar derives `disabled={state in [:loading, :error]}`.

### Pattern 4: `toolbar/1` — cluster with disabled-coordination

```elixir
# Source: cluster pattern + existing disabled CSS (style.ex L1431-1454)
@doc false
attr(:disabled, :boolean, default: false, doc: "true while data region loading or hard error (D-06)")
attr(:class, :any, default: nil)
attr(:rest, :global)
slot(:inner_block, required: true)

def toolbar(assigns) do
  ~H"""
  <div class={["tl-toolbar", @disabled && "is-disabled", @class]} role="search" aria-disabled={@disabled} {@rest}>
    <%= render_slot(@inner_block) %>
  </div>
  """
end
```

```css
/* style.ex — descendant disable, mirrors the offline pattern */
.tl-toolbar.is-disabled { pointer-events: none; opacity: 0.55; }
/* belt-and-braces: still set disabled on the controls server-side so they're truly inert + SR-announced */
```
**Note:** `pointer-events:none` is a *visual/affordance* disable; for true a11y/security the controls must also carry the HTML `disabled` attribute (set from the same `state` assign). `pointer-events:none` alone does not prevent keyboard focus/activation. [VERIFIED: codebase — `.tl-button[disabled]` styles exist L1431]

### Pattern 5: `detail_header/1` — title + kv metadata + actions

```elixir
# Source: composes UI.kv/1 (L409) + cluster for actions
@doc false
attr(:title, :string, required: true)
attr(:class, :any, default: nil)
attr(:rest, :global)
slot(:metadata, doc: "kv rows: <:item key=...>")
slot(:actions)

def detail_header(assigns) do
  ~H"""
  <header class={["tl-detail-header", @class]} {@rest}>
    <div class="tl-detail-header__top">
      <h2 class="tl-detail-header__title"><%= @title %></h2>
      <div :if={@actions != []} class="tl-cluster"><%= render_slot(@actions) %></div>
    </div>
    <.kv :if={@metadata != []} class="tl-detail-header__meta">
      <:item :for={m <- @metadata} key={m.key}><%= render_slot(m) %></:item>
    </.kv>
  </header>
  """
end
```
Spacing per UI-SPEC: title (24px `--tl-font-size-title`) → metadata `--tl-space-6` (24px) below → actions cluster. `<h2>` not `<h1>` (page_header owns the single `<h1>`, D-175-03). [CITED: 177-UI-SPEC.md §Typography]

### Anti-Patterns to Avoid
- **Re-implementing the state taxonomy inside `data_panel`.** The named family (D-176-13) is the source of truth; the group delegates. Building a `variant=` mega-switch reverses D-176-13.
- **Putting connection CSS on `<body>`.** The classes are on the LiveView root (Pitfall 1). A `body.phx-loading` selector will never match.
- **Animating streamed rows in the data-region cross-fade.** D-11: the *container* cross-fades on a state change; `phx-update="stream"` per-row inserts stay instant.
- **A second header component for breadcrumbs.** D-04: one canonical `page_header`.
- **`pointer-events:none` as the only disable.** Add the HTML `disabled` attr too (Pattern 4 note).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Disconnect detection | A server `connected?/1` heartbeat assign | LiveView's `.phx-loading`/`.phx-error` root classes (D-08) | `connected?/1` is mount-time only; it misses a *dropped* socket mid-session. The client classes catch it for free. [VERIFIED: v1.1.0 source — `onError`→`displayError`→`showLoader` re-applies `phx-loading` on disconnect] |
| Overlay enter/exit animation | Custom JS / inline `on*=` handlers | `Phoenix.LiveView.JS.show/hide` with `transition:` tuples (already in `show_modal` L709) | CSP-clean, DOM-patch-aware, survives server patches [CITED: js-interop.html] |
| Focus management on state transition | New focus logic in `data_panel` | The `focus_heading` + `phx-mounted={JS.focus(...)}` already in `empty_state`/`error_state`/`data_state` | Already implemented and tested in D-176 [VERIFIED: ui.ex L505, L519-540, L605] |
| Spacing rhythm | Per-call-site margin classes | `stack`/`cluster` + `--tl-gap-*` flex gap | Margin-collapse + last-child resets are the class-soup D-02 kills |
| Responsive table stacking | New ARIA grid roles | The existing `data-label`/`::before` mechanism (style.ex L3471-3498) | D-176-09 / D-13: re-asserting `role=table` over a stacked card makes AT announce "table, row, cell" — a regression |
| Reduced-motion handling | Per-component media queries | The system-wide blanket at style.ex:3868 | D-12: it already collapses all transitions/animations to ~1ms |

**Key insight:** Nearly every "hard" part of this phase is already solved by an existing primitive or by the framework. The phase's real work is *assembly rules + completing the unfinished overlay CSS + correcting the offline-class assumption* — not new mechanisms.

## Runtime State Inventory

This phase is component composition + CSS, not a rename/migration. No stored data, live service config, OS-registered state, secrets, or build artifacts carry phase-specific strings. The one stateful artifact is the **stress-story registry**, which has two coordinated stores that must stay in sync (ledger↔fixtures↔projection parity is enforced by tests):

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `.planning/design-system-ledger.json` — 6 `group.*.reserved` entries (L303+), `owner_phase: 177`, `current_score: 35`, `target_score: 90`, `status: "reserved"` | Remap/expand to 12 group stories; add a `live`/`reference-only` tag field (D-07); keep ledger↔`stress_fixtures.ex`↔`DESIGN-SYSTEM.md` parity |
| Stored data | `stress_fixtures.ex` `@group_stories` (L65-78) — same 6 baselines; consumed by `reserved_story_maps(@group_stories, "group", 177)` (L243) | Expand to 12; add tag field to `story/1` map (L435) and `reserved_story/5` (L416) |
| Live service config | None — `/audit/__stress` is route-gated, no external service holds phase state | None |
| OS-registered state | None | None — verified by grep (no scheduler/systemd/pm2 references) |
| Secrets/env vars | None | None — pure presentational phase |
| Build artifacts | None (Elixir compiles in-place; no egg-info/dist) | None |

**Parity caution:** `stress_live.ex` only renders stories that appear in BOTH the ledger (`load_ledger_entries` L434) AND `StressFixtures.by_id` (L463-468). A new story added to fixtures but not the ledger will silently not render. Both must be updated together.

## Common Pitfalls

### Pitfall 1: Connection classes are on the LiveView root, not `<body>`, and `.phx-disconnected` no longer exists
**What goes wrong:** CONTEXT D-08 and the UI-SPEC §"Reconnect/Offline Group Contract" both say "LiveView body classes (`.phx-loading`, `.phx-disconnected`, `.phx-error`, …)". A `body.phx-disconnected` selector matches nothing in LiveView 1.x.
**Why it happens:** Pre-1.0 LiveView docs used `.phx-disconnected`; it was renamed to `.phx-loading`. And the classes attach to the LiveView container element (`this.el`), not the document body.
**The verified truth (LiveView 1.1.0 source):** [VERIFIED: phoenix_live_view v1.1.0 constants.js + view.js]
- Classes: `phx-connected`, `phx-loading`, `phx-error`, `phx-client-error`, `phx-server-error`. (No `phx-disconnected`.)
- Applied to: the **LiveView root element** via `setContainerClasses()`.
- Initial load: `phx-loading` until join completes, then `phx-connected`.
- **Mid-session socket drop:** `onError()` → `displayError([phx-loading, phx-error, phx-client-error])` — `phx-loading` is re-applied. This is exactly the dropped-socket case D-08 wants.
- **Server crash (socket up, view dead):** `displayError([phx-loading, phx-error, phx-server-error])`.
**How to avoid:** Key the reconnect-banner + action-disable CSS off the LiveView root, e.g. `.threadline-ui.phx-loading .tl-reconnect-banner` / `.threadline-ui.phx-error [data-tl-mutating]`. The operator shell wrapper (`.threadline-ui`, seen in stress_live L73) is the natural anchor. **Confirm which element carries the class in THIS app** — if the audit pages mount the LiveView on `.threadline-ui` or a parent, the selector must match that element. (Stress route uses `data-tl-theme` on `.threadline-ui` L73.)
**Warning signs:** banner never appears on disconnect; `body.phx-*` selectors in style.ex.

### Pitfall 2: The overlay JS-transition utility classes are not defined
**What goes wrong:** `modal`/`drawer`/`toast` motion appears broken or instant because `show_modal`/`hide_modal` (ui.ex L709-736) reference `tl-fade-in`, `tl-rise-in`, `tl-rise-out`, `tl-fade-out`, `opacity-0`, `opacity-100`, `translate-y-4`, `translate-y-0` and `show_drawer` references `tl-slide-in-right`/`tl-slide-out-right`/`translate-x-full`/`translate-x-0` — **none of which exist in `style.ex`** (verified by grep; only `@keyframes tl-fade-in`/`tl-rise-in` exist, used by CSS `animation:` mount reveals, NOT by JS `transition:` tuples). The shells `tl-modal-container`/`tl-modal`/`tl-drawer-container`/`tl-toast` are also undefined.
**Why it happens:** D-176 extracted the overlay *components* but the JS-transition CSS was deferred to the group-motion phase (here).
**How to avoid:** D-10.1 work must DEFINE these utility classes. A JS `transition:` tuple is `{transition_classes, from_classes, to_classes}` — the from/to classes need real CSS:
```css
/* style.ex — overlay JS-transition utilities (currently MISSING) */
.tl-fade-in  { transition: opacity var(--tl-motion-base) var(--tl-ease-standard); }
.tl-fade-out { transition: opacity var(--tl-motion-base) var(--tl-ease-standard); }
.opacity-0 { opacity: 0; } .opacity-100 { opacity: 1; }
.translate-y-4 { transform: translateY(var(--tl-motion-distance-md)); }
.translate-y-0 { transform: translateY(0); }
.translate-x-full { transform: translateX(100%); }
.translate-x-0 { transform: translateX(0); }
.tl-rise-in, .tl-rise-out { transition: opacity var(--tl-motion-base) var(--tl-ease-standard), transform var(--tl-motion-base) var(--tl-ease-standard); }
.tl-slide-in-right, .tl-slide-out-right { transition: transform var(--tl-motion-base) var(--tl-ease-standard); }
.hidden { display: none; }
```
**Warning signs:** overlays snap with no animation; grep for `tl-modal-container` in style.ex returns nothing (it does today).

### Pitfall 3: `JS.show/hide` `:time` defaults to 200ms — out of sync with the 180ms/120ms tokens
**What goes wrong:** `show_modal`/`show_drawer` (ui.ex L709, L777) call `JS.show(transition: {...})` WITHOUT a `:time` option. `:time` defaults to **200ms** [CITED: js-interop.html / JS.show docs], but the CSS `transition-duration` above is `--tl-motion-base` (180ms). LiveView removes the from/to classes after `:time` ms; if `:time` (200) > CSS duration (180) it's harmless, but if a token is *longer* than 200 the transition is cut off. More importantly, D-11 says "reuse the motion tokens" — the 200ms default silently violates that.
**How to avoid:** Pass `time: 180` (matching `--tl-motion-base`) to every overlay `JS.show/hide`, OR set the CSS transition-duration to 200ms to match the default. Recommend passing explicit `time:` so the token stays the single source of truth. The data-region cross-fade (D-10.2) uses `--tl-motion-fast` (120ms) so its JS transition needs `time: 120`.
**Warning signs:** transitions feel clipped or laggy; mismatch between `:time` and `transition-duration`.

### Pitfall 4: Adding a `:breadcrumbs` slot breaks the existing `:breadcrumbs` attr
**What goes wrong:** `page_header/1` already declares `attr(:breadcrumbs, :list, default: [])` (ui.ex L189) rendered by `breadcrumb_trail/1` (L232). Phoenix does not allow an `attr` and a `slot` with the same name. Adding `slot(:breadcrumbs)` per a literal reading of D-04 will fail to compile.
**Why it happens:** D-04 was written assuming breadcrumbs didn't exist yet; they were added earlier (likely D-175 era).
**How to avoid:** Reconcile at plan time. Two options:
1. **Keep the list attr (recommended).** Breadcrumbs are location *data* (`%{label, href}`), not arbitrary markup — a list attr is the cleaner contract and it already works. Just audit/extend `breadcrumb_trail/1` for truncation (Pitfall 5). D-14 explicitly grants "exact slot API … match existing idioms" discretion, which covers keeping the attr.
2. If a slot is truly required, rename the attr (breaking change to current call sites) — higher cost, no clear benefit.
**Warning signs:** compile error "attribute :breadcrumbs already defined".

### Pitfall 5: Breadcrumb overflow at 320px
**What goes wrong:** Long table/correlation names in a breadcrumb trail overflow the 320px viewport. The existing `tl-transaction__breadcrumbs` CSS (style.ex L2313) has no documented truncation.
**How to avoid (D-13):** truncate the *current/last* crumb with `text-overflow: ellipsis` + `max-width`, keep ancestors as links; or collapse middle crumbs to `…`. Reuse the `cluster` wrap mechanism if crumbs should wrap rather than truncate. Verify at 320/375.
**Warning signs:** horizontal scroll on the header at 320px.

### Pitfall 6: Toolbar `pointer-events:none` lets keyboard users still tab into disabled controls
**What goes wrong:** disabling the toolbar visually with `pointer-events:none` + `opacity` (D-08 pattern) does NOT remove the controls from the tab order or prevent activation via keyboard/SR.
**How to avoid:** also set the HTML `disabled` attribute on the actual controls (derived from the same `state` assign), and `aria-disabled` on the container. `pointer-events:none` is the affordance; `disabled` is the enforcement. (For the offline group's mutating *links*, which can't be `disabled`, use `pointer-events:none` + `tabindex="-1"` + `aria-disabled="true"`.)
**Warning signs:** tabbing reaches a greyed-out control; pressing Enter still fires a filter while the table is broken.

## Code Examples

### Reconnect/offline group (D-08) — keyed off the LiveView root
```css
/* style.ex — connection-lifecycle group. Anchor is the LiveView container
   (.threadline-ui in this app). NOT body. NOT .phx-disconnected. */
.tl-reconnect-banner { display: none; }

.threadline-ui.phx-loading .tl-reconnect-banner,
.threadline-ui.phx-error   .tl-reconnect-banner {
  display: flex;           /* role="status" strip, warning-tinted, icon + text */
  gap: var(--tl-gap-inline);
}

/* disable mutating actions while disconnected/erroring */
.threadline-ui.phx-loading [data-tl-mutating],
.threadline-ui.phx-error   [data-tl-mutating] {
  pointer-events: none;
  opacity: 0.55;
}
```
```heex
<%!-- reconnect banner: zero JS, pure CSS visibility. role=status (calm, transient). --%>
<div class="tl-reconnect-banner" role="status">
  <Icon.icon name={:refresh} /> Reconnecting…
</div>
<%!-- mark mutating controls so the CSS above can disable them --%>
<.button data-tl-mutating>Prune now</.button>
```
*(Banner copy "Reconnecting…" per UI-SPEC Copywriting Contract — status, not error.)*

### Data-region cross-fade on state swap (D-10.2)
```css
/* style.ex — container-level opacity cross-fade; opacity-only so it degrades cleanly.
   Reduced-motion blanket at L3868 collapses this to ~1ms automatically (D-12). */
.tl-data-panel__region {
  transition: opacity var(--tl-motion-fast) var(--tl-ease-standard);
}
/* Optional: drive via a phx-mounted JS.transition on the region when [data-state] changes,
   time: 120 to match --tl-motion-fast (Pitfall 3). NEVER on streamed <tr> children (D-11). */
```

### Stress-story map with live/reference tag (D-07)
```elixir
# stress_fixtures.ex — add a `surface` (or `realization`) tag to the story map.
# Existing reserved_story/5 (L416) hardcodes status:"reserved"; group stories become
# status:"current" with a new tag distinguishing shipped vs reference-only.
defp group_story(id, fixture_key, scenario, surface) when surface in [:live, :reference] do
  story(%{
    id: id, kind: "group", category: "group",
    scenario: scenario, fixture_key: fixture_key,
    cases: ["one"], status: "current", owner_phase: 177,
    data: %{surface: surface, summary: "Phase 177 #{scenario} audited as a unit."},
    metadata: %{owner_phase: 177, surface: surface}   # tag flows to ledger projection
  })
end
```
Then a matching ledger row per story (ledger↔fixtures parity, Pitfall in Runtime State Inventory). Suggested 12-config → story-id mapping:

| GROUP-01 config | Story id (remap/new) | Surface | Source |
|-----------------|----------------------|---------|--------|
| page-header+actions+breadcrumbs | `group.page-header.current` | live | page_header on every page |
| toolbar+search+filters+sort | `group.filter-bar.*` → `group.toolbar.current` | live | timeline |
| table+empty+loading+pagination | `group.data-panel.current` | live | coverage/retention/timeline |
| stat-cards+chart+table | `group.status-strip.*` → `group.stats-chart-table.current` | live | coverage |
| detail-header+metadata+actions | `group.kv-list.*` → `group.detail-header.current` | live | transaction/actor/row-history |
| modal-confirm+destructive | `group.modal-destructive.current` | live | retention prune |
| drawer+form | `group.drawer-form.reference` | reference-only | (no live page — D-07/deferred) |
| toast+state-update | `group.toast-update.current` | live | export/prune toasts |
| tabs+subviews | `group.tabs-subviews.reference` | reference-only | (no live page) |
| empty+CTA | `group.empty-cta.current` | live | timeline empty |
| permission-denied | `group.permission-denied.current` | live | scoped pages |
| reconnect/offline-banner+disabled-actions | `group.offline.current` | live | shell-level |
*(6 existing reserved baselines: `action-bar`, `filter-bar`, `kv-list`, `pagination`, `status-strip`, `timeline-list` get remapped/absorbed; ~6 new ids added. Exact id naming is D-14 discretion — match the dotted-hyphen idiom seen at fixtures L66-78.)*

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `.phx-disconnected` class | `.phx-loading` class | LiveView 1.0 | D-08's named class doesn't exist; use `phx-loading` [VERIFIED: v1.1.0 source] |
| `connected?/1` heartbeat for offline UI | client connection classes on root el | — | catches mid-session drops; zero server code (D-08) |
| ARIA `role=table/row/cell` for responsive tables | native `<table>` + `data-label`/`::before` | D-176-09 | re-asserting roles regresses AT; reuse existing mechanism (D-13) |
| Polymorphic `data_state variant=` | named state family + coordinating shell | D-176-13 | `data_panel` delegates, never reinvents |

**Deprecated/outdated:**
- `.phx-disconnected` — replaced by `.phx-loading` (any new CSS must use the current name).
- Animating `scale(0)` overlays (MOTION-01) — use opacity + small translate; existing `tl-rise-in` keyframe starts from `translateY(8px)` not `scale(0)`. [VERIFIED: style.ex L3084-3093]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `--tl-gap-section` should map to `--tl-space-8` (32px) | Pattern 2 | Low — D-09 is discretion; wrong value is a one-line token edit |
| A2 | The audit LiveViews mount on/under `.threadline-ui`, so connection classes land on an element a `.threadline-ui.phx-loading` selector can match | Pitfall 1, Code Examples | **Medium — must verify the actual LiveView root element/wrapper in the 11 audit pages.** If the LiveView root is an inner element, the selector anchor changes. Stress route shows `.threadline-ui` as the theme wrapper (L73) but that may not be the LiveView container element. |
| A3 | Keeping the `breadcrumbs` list attr (not converting to a slot) satisfies D-04 | Pitfall 4 | Low — D-14 grants slot-API discretion; but a planner taking D-04 literally may force a breaking slot conversion |
| A4 | The 12-config → story-id mapping table | Code Examples | Low — exact ids are D-14 discretion; mapping is a suggestion |
| A5 | `data_panel` cond/slot shape (state attr + data slot + pager slot) | Pattern 3 | Low — API is D-14 discretion; the coordination *rules* it encodes are locked (D-06/D-06c) |

## Open Questions

1. **Which DOM element do the audit LiveViews use as their root (for the `.phx-*` connection classes)?**
   - What we know: classes attach to the LiveView container element (`this.el`); stress route wraps content in `.threadline-ui` (L73).
   - What's unclear: whether `.threadline-ui` IS the LiveView root or a child of it, across the 11 audit pages.
   - Recommendation: a Wave-0 task should `grep` the live views / layout for the LiveView container and confirm the selector anchor before writing offline CSS. (A2.)

2. **Attr vs slot for breadcrumbs (D-04 literal reading vs the shipped attr).**
   - What we know: a working list attr + `breadcrumb_trail/1` already exist.
   - What's unclear: whether the planner/checker will insist on a `:breadcrumbs` slot per D-04's wording.
   - Recommendation: keep the attr; document the reconciliation in the plan so the checker doesn't flag it.

3. **Should `toast` get a fade-up *exit* in addition to the existing `hide_toast` fade-out, and an auto-dismiss?**
   - What we know: `toast/1` (L814) has `hide_toast` (fade-out) but D-10 says "toast fade-up" (entrance). No entrance transition is wired on mount.
   - Recommendation: add a `phx-mounted` fade-up using the same JS-transition utilities; auto-dismiss is out of scope (would need JS timer) — leave manual/`phx-click` dismiss.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Mix | compile + test | ✓ (project) | — | — |
| `phoenix_live_view` | `Phoenix.LiveView.JS`, connection classes | ✓ | 1.1.30 | — |
| `/audit/__stress` route | group story audit | ✓ | — (route-gated dev surface) | — |
| `.planning/design-system-ledger.json` | stress_live story rendering | ✓ | 66 entries, 6 group rows | — |

No missing dependencies. No external tools, services, or runtimes beyond the project's own stack.

## Validation Architecture

> `workflow.nyquist_validation` is enabled (no explicit `false` in config). This section defines how each group's spacing/hierarchy/state/motion is verifiable.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit + `Phoenix.LiveViewTest` (render_component / live) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/<file>_test.exs` (single file) |
| Full suite command | `mix ci.all` (format + credo + test, per CLAUDE.md) |
| Component render assert | `Phoenix.LiveViewTest.render_component/2` for `stack`/`cluster`/`data_panel`/`toolbar`/`detail_header` |

### Phase Requirements → Test Map
| Req | Behavior | Test Type | Automated Command | File Exists? |
|-----|----------|-----------|-------------------|--------------|
| GROUP-01 | `stack`/`cluster` emit correct gap classes + no raw child margins | unit (render_component) | `mix test test/.../ui_test.exs` | ❌ Wave 0 (extend existing ui test) |
| GROUP-01 | `data_panel` renders the right region per `state` (ok/loading/empty/no_data/error/permission/unavailable) | unit | `mix test test/.../ui_test.exs` | ❌ Wave 0 |
| GROUP-01 | `page_header` breadcrumbs render trail + truncate current crumb | unit | same | ⚠️ extend (attr exists) |
| GROUP-01 | all 12 group stories present in fixtures AND ledger (parity) | unit | `mix test test/.../stress_fixtures_test.exs` + ledger parity test | ⚠️ extend existing parity test |
| GROUP-02 | `data_panel` moves focus on error/permission transition (focus_heading) | unit (assert `tabindex=-1` + `phx-mounted` JS.focus present) | `mix test test/.../ui_test.exs` | ❌ Wave 0 |
| GROUP-02 | toolbar disabled when `state in [:loading,:error]` (HTML `disabled` + `aria-disabled`) | unit | same | ❌ Wave 0 |
| GROUP-02 | stale_banner renders ABOVE data, never replaces (already D-176 tested) | unit | existing | ✅ (D-176) |
| GROUP-02 | offline CSS keyed off `.phx-loading`/`.phx-error` (NOT body, NOT `.phx-disconnected`) | source assertion (refute `body.phx-`/`phx-disconnected`; assert `phx-loading`) | `mix test test/.../style_test.exs` | ❌ Wave 0 |
| GROUP-02 | overlay JS-transition utility classes DEFINED in style.ex | source assertion (assert `.tl-fade-in`, `.translate-x-full`, etc. present) | `mix test test/.../style_test.exs` | ❌ Wave 0 |
| GROUP-02 | new motion uses transform/opacity only + motion tokens (GPU-only) | source assertion / credo-style check | `mix test test/.../style_test.exs` | ⚠️ extend |
| GROUP-02 | token parity: `--tl-gap-*` in tokens.css ↔ tokens.json ↔ style.ex | unit | `mix test test/.../brandbook_token_parity_test.exs` | ✅ exists (will go red until tokens added) |
| GROUP-01/02 | each of the 12 stories renders without error across viewport/theme matrix | integration (live) | `mix test test/.../stress_live_test.exs` | ⚠️ extend |

### Sampling Rate
- **Per task commit:** `mix test test/<touched>_test.exs` + `mix format --check-formatted`
- **Per wave merge:** `mix verify.test` (full suite)
- **Phase gate:** `mix ci.all` green before `/gsd-verify-work`; visual audit of all 12 stories on `/audit/__stress` at 320/375/768/1024/1440 × dark/light/system.

### Wave 0 Gaps
- [ ] `test/.../style_test.exs` — source assertions: connection classes use `phx-loading`/`phx-error` not `body`/`phx-disconnected`; overlay JS-transition utility classes defined; new motion is transform/opacity-only.
- [ ] Extend `ui_test.exs` — `stack`/`cluster`/`data_panel`/`toolbar`/`detail_header` render + coordination (focus-move, toolbar-disable, region-per-state).
- [ ] Extend `brandbook_token_parity_test` — `--tl-gap-inline`/`--tl-gap-stack`/`--tl-gap-section` in all three sources.
- [ ] Extend stress-fixtures + ledger parity test — 12 group stories, `surface` tag (live/reference).
- [ ] Wave-0 investigation task — confirm the LiveView root element for the connection-class selector (Open Question 1 / A2).

*(Manual-only: the actual *visual* "holds together at every viewport" judgment is a `/gsd-verify-work` human pass on the stress route — automated tests assert structure/classes/focus/parity, not pixels.)*

## Security Domain

> `security_enforcement` is enabled (absent = enabled). This phase is presentational; the load-bearing security work (T3 type-to-confirm, server-side `secure_compare`, fail-closed authz) was done in D-176-21 and is NOT re-opened here. The group layer must not *weaken* it.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V1 Architecture | yes | No public/host-facing component API (v1.31 freeze); all components `@doc false` internal |
| V3 Session Management | no | Untouched |
| V4 Access Control | indirectly | Permission/unavailable state coordination must preserve the D-176-16 forensic distinction; the *grant* decision stays server-side (D-06d). The group never converts a permission denial into a generic empty. |
| V5 Input Validation | no (presentational) | The destructive-confirm group still routes through the server-enforced D-176-21 path; the group is just the shell |
| V7 Errors & Logging | yes | Error/unavailable states must not leak internals; copy is plainspoken + cause-named (UI-SPEC Copywriting) |
| V14 Configuration (CSP) | **yes** | **No inline `on*=` handlers; all interactivity via `Phoenix.LiveView.JS`; offline group is pure CSS (zero JS).** This is the central security constraint of the phase. |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Inline `on*=` event handler reintroduced via a new component | Tampering (CSP bypass) | All handlers via `Phoenix.LiveView.JS`; source test refuting inline `on*=` (carried from D-175 CSP posture) |
| Disabled mutating control still keyboard-activatable (offline/loading) | Elevation / Tampering | HTML `disabled` + `aria-disabled` + `tabindex=-1`, not `pointer-events:none` alone (Pitfall 6) |
| Permission denial collapsing to generic "no data" (operator misreads access vs absence) | Information disclosure / trust failure | Preserve distinct icon shape + heading even when panel body collapses (D-06, D-176-16) |
| New JS dependency smuggled in for motion | — (supply chain) | Zero-new-dep invariant; motion is `Phoenix.LiveView.JS` + CSS only |

## Sources

### Primary (HIGH confidence)
- `lib/threadline/operator_surface/ui.ex` (read in full) — all existing primitives, the `breadcrumbs` attr (L189), overlay JS-transition calls (L709-843), state family (L489-655)
- `lib/threadline/operator_surface/style.ex` (targeted reads + grep) — `--tl-gap-*` already at L175-176, reduced-motion blanket L3868, responsive table L3471-3498, disabled CSS L1431-1454, motion block L3107, MISSING overlay/connection CSS (grep-verified absent)
- `lib/threadline/operator_surface/stress_fixtures.ex` (read in full) — `@group_stories` L65, `reserved_story/5` L416, `story/1` L435
- `lib/threadline/operator_surface/live/stress_live.ex` (read in full) — ledger↔fixtures rendering, `.threadline-ui` wrapper L73
- `brandbook/tokens.css` (read in full) — `--tl-space-*` L6-16, motion tokens L76-78, NO `--tl-gap-*`
- `.planning/design-system-ledger.json` — group story schema L303-319
- phoenix_live_view **v1.1.0** `constants.js` + `view.js` (GitHub raw) — exact connection class names + which element + when applied [VERIFIED]
- CONTEXT.md, UI-SPEC.md, DISCUSSION-LOG.md, REQUIREMENTS.md, ROADMAP.md (Phase 177) — locked decisions

### Secondary (MEDIUM confidence)
- phoenix-live-view.hexdocs.pm/js-interop.html — `Phoenix.LiveView.JS` purpose, DOM-patch awareness
- `Phoenix.LiveView.JS.show` transition tuple `{transition, from, to}` + `:time` default 200ms (web search of official docs)
- GitHub issue #1009 / #2211 — historical `.phx-disconnected` → `.phx-loading` rename confirmation
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md` — JS transitions, connection lifecycle framing

### Tertiary (LOW confidence)
- None — all load-bearing claims verified against source or codebase.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — zero new deps; everything verified in mix.lock + ui.ex
- Architecture / API sketches: HIGH for *rules* (locked decisions), MEDIUM for *exact signatures* (D-14 discretion)
- Pitfalls: HIGH — all three major pitfalls verified against source (connection classes, missing overlay CSS, JS.show :time)
- Connection-class behavior: HIGH — verified against phoenix_live_view v1.1.0 source, not just docs

**Research date:** 2026-06-18
**Valid until:** 2026-07-18 (stable internal codebase; LiveView 1.1.x connection-class behavior is stable). Re-verify the LiveView root-element anchor (A2/Open Q1) before writing offline CSS.
