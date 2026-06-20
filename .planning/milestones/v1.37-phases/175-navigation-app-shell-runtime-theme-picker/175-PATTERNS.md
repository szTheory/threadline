# Phase 175: Navigation, app shell & runtime theme picker - Pattern Map

**Mapped:** 2026-06-17
**Files analyzed:** 18 (new + modified)
**Analogs found:** 15 / 18 (3 are pure edits to their own current state — the analog *is* the file)

> Fix-to-spec phase. Most production files already exist; this map gives the planner the
> *closest existing analog* + concrete excerpts for each NEW internal component and NEW test,
> plus the *before-state* excerpts for each in-place fix. All `lib/` line numbers are from the
> reads done this session (cite verbatim in plans). Read-only: nothing here was modified.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/threadline/operator_surface/ui.ex` → **new `pager/1`** | component (function) | request-response (emits existing `phx-click` events) | `field_group/1`, `radio/1`, `segmented_control/1` in same file | exact (same module, same `attr`/`slot` idiom) |
| `lib/threadline/operator_surface/ui.ex` or `surface_header.ex` → **new `page_header/1`** | component (function) | transform (renders title/lede/breadcrumb slots) | `card/1` (slots: title/meta/actions), `empty_state/1` in `ui.ex` | exact (slot-bearing function component) |
| `lib/threadline/operator_surface/ui.ex` or `surface_header.ex` → **new breadcrumb** | component (function) | transform | `surface_header.ex` `nav_link/1` (private slot component); current `tl-transaction__breadcrumbs` markup | role-match |
| `lib/threadline/operator_surface/components/surface_header.ex` (theme picker fix) | component | request-response (form POST) | itself (lines 104–126 before-state) + `radio/1` + `field_group/1` in `ui.ex` | exact |
| `lib/threadline/operator_surface/components/surface_header.ex` (nav `<details>` + skip-link fix) | component | event-driven (native disclosure) | `timeline_live.ex:546` `<details>` precedent | role-match |
| `lib/threadline/operator_surface/style.ex` (nav `[open]` re-point) | config (inline CSS) | n/a | itself, lines 505–586 (before-state) | exact |
| `lib/threadline/operator_surface/style.ex` (picker `:has(:checked)`, pager, scroll/svh) | config (inline CSS) | n/a | nav active block 640–647; segmented 983–1021; scroll-margin 2452; `100dvh` 2974 | exact |
| `lib/threadline/operator_surface/router.ex` (macro doc edit, D-08) | route | n/a | itself (~52–55) | exact |
| `lib/threadline/operator_surface/live/{11 pages}.ex` (thread `breadcrumbs` + `page_header`) | provider (LiveView) | request-response (`handle_params`) | `transaction_live.ex:35–81` handle_params + 99–138 markup | exact |
| `test/threadline/operator_surface/surface_header_csp_test.exs` **(new)** | test (contract) | n/a | `style_contract_test.exs:1–30` (`File.read!` + `String.contains?`); `surface_header_test.exs` for render | exact |
| `test/threadline/operator_surface/page_header_test.exs` **(new)** | test (render) | n/a | `ui_test.exs:1–55` (`rendered_to_string`); `surface_header_test.exs` | exact |
| `test/threadline/operator_surface/breadcrumb_test.exs` **(new)** | test (render) | n/a | `surface_header_test.exs:43–66` (`aria-current` count idiom) | exact |
| `test/threadline/operator_surface/pager_test.exs` **(new)** | test (render) | n/a | `ui_test.exs` (`rendered_to_string`) + `timeline_live_test.exs:1–134` (full LV harness) | exact |
| `test/threadline/operator_surface/skip_link_test.exs` **(new)** | test (render, all 11 pages) | n/a | `timeline_live_test.exs:1–134` (Layouts+Router+Endpoint LV harness) | exact |
| `test/threadline/operator_surface/style_contract_test.exs` (lift 3 bans + add asserts) | test (contract) | n/a | itself (lines 8–30, 991–1010, 1111–1119) | exact |

---

## Pattern Assignments

### NEW `pager/1` in `ui.ex` (component, request-response)

**Analog:** `field_group/1` / `radio/1` / `segmented_control/1` — `lib/threadline/operator_surface/ui.ex`

**`attr`/`slot` signature idiom to copy** (radio, `ui.ex:734–759`):
```elixir
@doc false
# Native radio group: every option shares @name; the option whose value equals
# @value is checked; each input has a distinct id and an associated <label>.
attr :name, :string, required: true
attr :value, :any, default: nil
attr :options, :list, default: []
attr :class, :any, default: nil
attr :rest, :global

def radio(assigns) do
  ~H"""
  <div class={["tl-radio-group", @class]} role="group" {@rest}>
    ...
  </div>
  """
end
```

**De-emphasized button + disabled-not-hidden idiom — copy from `button/1` (`ui.ex:7–30`):**
```elixir
attr :variant, :string, default: "secondary", values: ~w(primary secondary quiet-primary danger ghost icon)
attr :rest, :global, include: ~w(disabled form name value phx-disable-with)   # ← `disabled` already in the global include
...
<button type={@type} class={["tl-button", @variant != "secondary" && "tl-button--#{@variant}", ...]} {@rest}>
```
Pager directional controls are `<button>` (or `.link`) emitting the EXISTING events; "Older" = `phx-click="next-page"`, "Newer" = `phx-click="prev-page"` (verified `timeline_live.ex:382` / `actor_live.ex:161–162`). Disable (not hide) at boundary via the `disabled` global attr — never conditionally drop the element (D-18, avoids layout shift).

**Range-caption container — copy the live-region idiom verbatim (`timeline_live.ex:601`):**
```elixir
<div class="tl-status tl-timeline-command__status" role="status" aria-live="polite">
  <strong><%= @shown_count %> shown</strong>
  <span><%= format_count(@match_count) %> matching changes</span>
  ...
</div>
```
Reuse `format_count/1` (the `10_001` → "10,000+" cap path; `timeline_live.ex:603`). Caption copy per UI-SPEC: `"Showing {N} of 10,000+ matching changes"` / `"Showing {N} of {total} matching changes"`. Domain noun is **"matching changes"** not "rows"/"results".

**Recommended location:** `ui.ex` `pager/1` (Claude's Discretion D / least-surprise — matches `tabs`/`segmented_control`/`field_group` colocation).

---

### NEW `page_header/1` (component, transform)

**Analog:** `card/1` — `lib/threadline/operator_surface/ui.ex:143–165` (the canonical multi-slot pattern).

**Slot signature idiom to copy (`card/1`, `ui.ex:143–165`):**
```elixir
attr :class, :any, default: nil
attr :rest, :global
slot :title
slot :meta
slot :actions
slot :inner_block, required: true

def card(assigns) do
  ~H"""
  <div class={["tl-card", ...]} {@rest}>
    <div :if={@title != [] || @meta != []} class="tl-card__header">
      <h3 :if={@title != []} class="tl-card__title"><%= render_slot(@title) %></h3>
      ...
    </div>
    ...
    <div :if={@actions != []} class="tl-card__actions"><%= render_slot(@actions) %></div>
  </div>
  """
end
```

**Target markup it must collapse — current `tl-page__header` (verified `transaction_live.ex:117–128`, `coverage_live.ex:111–113`):**
```elixir
<header class="tl-page__header">    # coverage_live.ex:111 already uses semantic <header>
  <h1 class="tl-page__title">Coverage — schema: <%= @schema_param %></h1>
</header>
```
`page_header/1` renders `<header class="tl-page__header">` (CSS already exists, `style.ex:905`), a single `<h1 class="tl-page__title">` (CSS `style.ex:914`), optional `lede` (`tl-page__lede`, `style.ex:922`), optional `actions` slot, optional `breadcrumbs`. **Exactly one `<h1>` per page** (D-11). Collapses the three current conventions: `tl-page__title` (majority), `tl-transaction__title` (`transaction_live.ex:120`, `actor_live.ex:123`), `tl-timeline-command__title` (`timeline_live.ex:456`) / `tl-home__headline` (`start_live.ex:135`, Display role).

---

### NEW breadcrumb (component, transform)

**Analog:** current bespoke markup `transaction_live.ex:113–116` (the before-state to replace) + `nav_link/1` private-component idiom `surface_header.ex:132–149`.

**Before-state to replace (`transaction_live.ex:113–116`):**
```elixir
<nav class="tl-transaction__breadcrumbs" aria-label="Investigation path">
  <a href={"#{surface_root(@base_path)}/timeline"} class="tl-link tl-link--back">← Timeline</a>
  <span>Transaction</span>
</nav>
```
(Identical bespoke trail at `actor_live.ex:117`.) **Fix per D-13:** rename landmark to `aria-label="Breadcrumb"`; root link label `"Timeline"`; final segment is plain text (current code already uses `<span>` for the leaf — keep that, but do NOT add `aria-current="page"` to it). Trails are the explicit `breadcrumbs` assign (`{label, href|nil}` list), NOT route-inferred (D-14).

**Separator idiom already in CSS (`style.ex:2274–2278`) — reuse the `::before` glyph, don't invent markup separators:**
```css
.tl-transaction__breadcrumbs span::before {
  content: "/";
  margin-right: var(--tl-space-2);
  color: var(--tl-color-border-strong);
}
```

---

### `surface_header.ex` theme-picker fix (component, request-response form POST)

**Analog:** itself (before-state below) + `radio/1` (`ui.ex:734–759`) + `field_group/1` (`ui.ex:719–732`).

**Before-state to fix — the broken picker (`surface_header.ex:104–126`):**
```elixir
<section class="tl-shell-nav__group tl-theme-picker" aria-labelledby="tl-shell-nav-theme">
  <h2 id="tl-shell-nav-theme" class="tl-shell-nav__label">Theme</h2>
  <form action={"#{@base_path}/theme"} method="post" class="tl-theme-picker__form">
    <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />   # ← KEEP (D-04)
    <div class="tl-segmented">
      <label class={["tl-segmented__item", @theme == "system" && "tl-segmented__item--active"]}>   # ← --active is a DEAD class (no CSS rule)
        <Threadline.OperatorSurface.UI.input type="radio" id="theme-system" name="theme" value="system"
          class="tl-sr-only" checked={@theme == "system"} onchange="this.form.submit()" />   # ← REMOVE tl-sr-only + onchange (D-03/D-05)
        System
      </label>
      <label ...>Light</label>   # value="light"
      <label ...>Dark</label>    # value="dark"
    </div>
    <noscript>
      <button type="submit" class="tl-button tl-button--compact tl-button--secondary">Save</button>   # ← promote out of <noscript>, copy = "Apply theme" (D-02)
    </noscript>
  </form>
</section>
```

**Fix shape (D-02/D-03/D-05):** `<fieldset>` + `<legend>Theme</legend>` + three **visible** native radios (order **System, Light, Dark**) + an explicit `<button type="submit">Apply theme</button>` (no `<noscript>`). Remove every `class="tl-sr-only"` and `onchange="this.form.submit()"`. Delete the dead `tl-segmented__item--active` markup class — active state comes from pure-CSS `:has(:checked)` (see style.ex assignment). Keep the `_csrf_token` hidden input (line 107) exactly.

**`<fieldset>`/`<legend>` idiom to copy — `field_group/1` (`ui.ex:719–732`):**
```elixir
<fieldset class={["tl-filter-group", @class]} {@rest}>
  <legend class="tl-filter-group__legend"><%= @legend %></legend>
  <%= render_slot(@inner_block) %>
</fieldset>
```

---

### `surface_header.ex` nav `<details>` + skip-link fix (component, event-driven / native)

**Analog:** native `<details>` precedent — `timeline_live.ex:546` (cited in RESEARCH Pattern 1):
```elixir
<details class="tl-filter-disclosure" open={@advanced_filters_active?}>
  <summary class="tl-filter-disclosure__summary">…</summary>
  …
</details>
```

**Before-state to remove — hidden checkbox + inline-JS toggle (`surface_header.ex:61–75`):**
```elixir
<input id="tl-shell-nav-toggle" class="tl-shell-nav__control" type="checkbox" tabindex="-1" aria-hidden="true" />
<nav class="tl-shell-nav" ...>
  <button type="button" class="tl-shell-nav__toggle" aria-controls="tl-shell-nav-panel" aria-expanded="false"
    onclick="var nav=this.closest('.tl-shell-nav'); ... nav.classList.toggle('tl-shell-nav--open', open); ...">Menu</button>
```
**Fix (D-21/D-22):** replace the `<input type=checkbox>` + `<nav>`+`<button onclick>` with `<details class="tl-shell-nav"><summary class="tl-shell-nav__toggle">Menu</summary>…panel…</details>`. NO `aria-expanded` on `<summary>` (D-22). NO shared `name=`. Remove the whole `tl-shell-nav__control` input.

**Before-state to remove — skip-link inline JS (`surface_header.ex:31–35`):**
```elixir
<a class="tl-skip-link" href="#tl-main"
   onclick="var target=document.getElementById('tl-main'); if (target) target.focus();">Skip to main content</a>
```
**Fix (D-26):** delete the `onclick`; rely on `<main id="tl-main" tabindex="-1">` (already present on all pages read — `transaction_live.ex:99`, `timeline_live.ex:340`, `coverage_live.ex:108`, `actor_live.ex:103`, `start_live.ex:133`, `row_history_live.ex:47`; audit the remaining pages — RESEARCH Q2).

---

### `style.ex` CSS edits (config, inline CSS)

**Edit 1 — re-point mobile-nav selectors `:checked`/`.--open` → `[open]` (D-22).** Before-state (`style.ex:554–576`):
```css
.tl-shell-nav__control:checked + .tl-shell-nav .tl-shell-nav__toggle::after { transform: rotate(225deg); }
.tl-shell-nav.tl-shell-nav--open .tl-shell-nav__toggle::after { transform: rotate(225deg); }
.tl-shell-nav__panel { display: none; ... }
.tl-shell-nav__control:checked + .tl-shell-nav .tl-shell-nav__panel { display: grid; }
.tl-shell-nav.tl-shell-nav--open .tl-shell-nav__panel { display: grid; }
.tl-shell-nav__control:focus-visible + .tl-shell-nav .tl-shell-nav__toggle { outline: ...; }
```
Re-point all four `:checked +`/`.--open` selectors to `.tl-shell-nav[open] …`; the `<summary>` (`.tl-shell-nav__toggle`) already has `::-webkit-details-marker { display:none }` (line 540) and a `:focus-visible` rule (line 583) ready for the native disclosure. Keep the `@media (min-width:768px)` desktop override (forces panel visible + `summary { display:none }`).

**Edit 2 — picker active state via `:has(:checked)` (D-05).** Copy the 4-signal active block from the nav (`style.ex:640–647`):
```css
.threadline-ui .tl-shell-nav__item--active,
.threadline-ui .tl-shell-nav__item[aria-current="page"] {
  background: var(--tl-color-accent-soft);
  border-color: var(--tl-color-accent-border);
  box-shadow: inset 0 0 0 1px var(--tl-color-accent-inset);
  color: var(--tl-color-accent-strong);
  font-weight: var(--tl-weight-strong);
}
```
The segmented block (`style.ex:983–1021`) is **missing a `--active`/`:checked` rule** — it only has `.tl-segmented__item[aria-pressed="true"]` (line 1017), which native radios never set (RESEARCH Pitfall 2). Add a new `label:has(:checked)` rule using `box-shadow: inset 2px 0 0 var(--tl-color-accent-border)` + a `font-weight` bump (the non-color dual-signal per UI-SPEC Color §).

**Edit 3 — scroll-padding / overscroll / svh.** Reconcile to the SAME token the per-row anchor uses (`style.ex:2452–2453`):
```css
.tl-target-row {
  scroll-margin-top: calc(var(--tl-header-height-mobile) + var(--tl-space-4));
}
```
`100dvh` precedent to mirror for rails (`style.ex:2974`): `min-height: 100dvh;` (keep a `vh` fallback line first per D-25; shell uses `100svh`). Add `overscroll-behavior: contain` on the scrollable panel/rail (D-24).

---

### LiveView `handle_params` threading (provider, request-response) — 11 pages

**Analog:** `transaction_live.ex:35–81` (the richest existing `handle_params`).

**`handle_params` idiom to thread the `breadcrumbs` assign into (`transaction_live.ex:35–44, 65–80`):**
```elixir
def handle_params(params, uri, socket) do
  uri_parsed = URI.parse(uri)
  base_path = ...
  socket = assign(socket, :base_path, base_path)
  ...
  {:noreply,
   assign(socket,
     show_history: true,
     history_table: table,
     ...
   )}            # ← add `breadcrumbs: [{"Timeline", timeline_path}, {"Transaction #{short_id}", nil}]` per D-12
end
```
Thread a `breadcrumbs` assign (ordered `{label, href|nil}`) into the `assign/2` call for the drill-down pages only (Transaction, Row history, Actor — D-12); flat pages (Home, Timeline, Coverage, Evidence, Exports, Redaction, Retention) get **no** `breadcrumbs` assign. The `page_header` is rendered in each page's `render/1` consuming this assign. The `current` nav atom (`surface_header.ex` `current={@current}`) stays as-is (D-14).

---

## Shared Patterns

### Internal-component `attr`/`slot` convention
**Source:** `lib/threadline/operator_surface/ui.ex` (entire file — `button` 7–30, `card` 143–165, `radio` 734–759, `field_group` 719–732, `segmented_control` 499–514).
**Apply to:** `pager/1`, `page_header/1`, breadcrumb.
- `@doc false` (no public API — v1.31 freeze).
- `attr :class, :any, default: nil` + `attr :rest, :global` last; merge with `class={["tl-base", cond && "tl-base--mod", @class]}`.
- BEM: `tl-block`, `tl-block__element`, `tl-block--modifier`.
- `disabled` / `name` / `value` / `form` ride on `:rest, :global, include: ~w(...)` — never separate attrs.

### Live-region status caption
**Source:** `lib/threadline/operator_surface/live/timeline_live.ex:601`
**Apply to:** pager range caption, any new count/status text.
```elixir
<div class="tl-status ..." role="status" aria-live="polite"> ... <%= format_count(@match_count) %> matching changes ... </div>
```

### Capped-count formatting
**Source:** `format_count/1` used at `timeline_live.ex:603`; `10_001` cap branches at `timeline_live.ex:369/375`.
**Apply to:** pager caption — reuse `format_count/1`; never reintroduce an exact deep total / `COUNT(*)`.

### Contract-test source-string idiom
**Source:** `test/threadline/operator_surface/style_contract_test.exs:5,9`
**Apply to:** new `surface_header_csp_test.exs` + edits to `style_contract_test.exs`.
```elixir
@style_path "lib/threadline/operator_surface/style.ex"
src = File.read!(@style_path)
refute String.contains?(src, "theme-toggle")   # ← the 3 to remove (lines 29, 1009, list-item 1113)
```
New CSP guard reads `@header_path "lib/.../components/surface_header.ex"`, then `refute String.contains?(src, "onclick=")`, `refute "onchange="`, `assert "/theme"`, `assert "_csrf_token"`.

### LiveViewTest render harness (Layouts + Router + Endpoint)
**Source:** `test/threadline/operator_surface/live/timeline_live_test.exs:1–134`
**Apply to:** new `skip_link_test.exs`, `pager_test.exs` (LV-mounted assertions), and any breadcrumb/page-header test that needs a live route.
- Define a `…Test.Layouts` root (lines 2–19), a `…Test.Router` that `require`s `Threadline.OperatorSurface.Router` and calls `threadline_operator_surface("/audit")` (21–40), and an `Endpoint` (~80–98).

### Standalone component render (no live mount)
**Source:** `test/threadline/operator_surface/ui_test.exs:1–55` (`rendered_to_string(~H""" <UI.button>… """)`) and `surface_header_test.exs:43–66` (`render_header/1` helper + `aria_current_count/1`).
**Apply to:** `page_header_test.exs`, `breadcrumb_test.exs`, `pager_test.exs` component-level assertions, and the "single `aria-current`" assertion (copy `aria_current_count(html) == 1` idiom from `surface_header_test.exs:48`).

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `style.ex` `:has(:checked)` picker rule | config (CSS) | n/a | No existing `:has()` active-state rule in the repo; the *visual treatment* analog is the nav 4-signal block (640–647) but the `:has(:checked)` selector mechanism is new this phase (D-05). Planner copies the *property set*, writes the *selector* fresh. |
| `style.ex` `overscroll-behavior: contain` | config (CSS) | n/a | No existing `overscroll-behavior` declaration found; net-new property (D-24). Use the existing scrollable rail block (`.tl-subview`, ~2968) as the host selector. |
| `style.ex` `min-height: 100svh` (shell) | config (CSS) | n/a | Repo has `100dvh` (2974) but no `100svh`; new viewport unit (D-25). Mirror the `dvh` line's structure (keep `vh` fallback first). |

---

## Metadata

**Analog search scope:** `lib/threadline/operator_surface/{ui.ex,components/surface_header.ex,style.ex,live/*_live.ex}`, `test/threadline/operator_surface/{,live/}`.
**Files scanned (read this session):** `ui.ex`, `surface_header.ex`, `style.ex` (6 ranges), `style_contract_test.exs` (3 ranges), `surface_header_test.exs`, `ui_test.exs`, `timeline_live_test.exs` (2 ranges), `transaction_live.ex` (2 ranges), `timeline_live.ex` (2 ranges); plus grep across 6 LiveView pages.
**Pattern extraction date:** 2026-06-17
