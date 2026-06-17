# Phase 175: Navigation, app shell & runtime theme picker - Research

**Researched:** 2026-06-17
**Domain:** Phoenix LiveView operator-surface app shell — CSP-hardening, accessible pagination UI, native `<details>` mobile nav, runtime theme picker (Elixir/Phoenix/Ecto/PostgreSQL)
**Confidence:** HIGH (codebase-verified; this is a fix-to-spec phase grounded entirely in current source)

## Summary

Phase 175 is **fix-to-spec**, not greenfield. Every fact in the CONTEXT.md/UI-SPEC.md was checked against the current source. The theme picker, keyset pagination engine, nav active-state, breadcrumb markup, and native-`<details>` precedent **all already exist** in the repo. This phase fixes three CSP-violating inline handlers, adds an accessible pager UI over the existing keyset engine, introduces one `page_header`/breadcrumb component, converts the mobile nav to native `<details>`, and lifts the `theme-toggle` style-contract ban.

The 27 locked decisions are sound and accurately describe the code — with **one material correction**: D-15 instructs a "read-only verify" that the composite index `audit_changes (captured_at DESC, id DESC)` exists. It **does not exist**. The capture-layer migration (`lib/threadline/capture/migration.ex:57`) creates only a single-column `audit_changes_captured_at_idx ON audit_changes (captured_at)`. Because `id` is a random UUID PK (not sequential), the keyset tiebreaker `ORDER BY captured_at DESC, id DESC` is not fully index-backed. This is the highest-leverage open question for the planner (see Open Questions Q1) — and it touches the capture layer, which the milestone invariants say is "untouched."

**Primary recommendation:** Treat all 27 decisions as locked and accurate. Plan the three CSP fixes in `surface_header.ex` (lines 34, 74, 110/114/118) plus the `<main>` `tabindex` (already present on some pages, missing on others). Add one `ui.ex` `pager/1` consuming the **already-existing** `next-page`/`prev-page` events and `@cursor`/`shown_count`/`match_count` assigns. Add one `page_header/1` + breadcrumb collapsing the three current title conventions. Re-point the mobile-nav CSS from `:checked`/`.tl-shell-nav--open` to `[open]`. Lift the three `theme-toggle` bans and add a positive CSP guard test that reads `surface_header.ex` as a string. **Escalate the missing composite index to the user before planning D-15 as "read-only."**

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Theme picker (NAV-03 / THEME-TOGGLE-01)**
- **D-01:** Picker ALREADY EXISTS in `surface_header.ex` (~104–126) as a segmented radio group in the nav drawer. This phase fixes it; does not build from scratch.
- **D-02:** Form factor = `<form method="post" action={base_path<>"/theme"}>` → `<fieldset>` + legend "Theme" + three native, visible `<input type="radio">` (order: System, Light, Dark — System is default) + explicit submit `<button>` "Apply theme". Native HTML controls, full-page reload on submit.
- **D-03:** Remove every `onchange="this.form.submit()"` — inline JS is banned/CSP-violating. Headline correctness fix.
- **D-04:** Keep the existing hidden `<input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()}>`. A LiveView-rendered form posting to a controller route gets no auto-CSRF injection — the explicit token is required.
- **D-05:** Do NOT visually hide the radios while signaling active state by background color only (WCAG 1.4.1 fail). Active state = native radio `checked` + non-color cue (inset border bar via `box-shadow: inset 2px 0 0 …` + `font-weight` bump), driven by pure-CSS `:has(:checked)`.
- **D-06:** Placement stays in nav-drawer "settings tail" (after Find/Verify/Prove), NOT the topbar.
- **D-07:** Lift the `theme-toggle` ban in `style_contract_test.exs` (delete the three `refute String.contains?(src, "theme-toggle")` assertions + comment block) and replace with a positive CSP guard: picker form posts to `/theme`, carries CSRF token, contains no `onclick=`/`onchange=`.
- **D-08:** Update the `router.ex` `threadline_operator_surface/2` macro doc that still says "Threadline does not add JavaScript … or a runtime theme toggle".
- **D-09:** Backend untouched: `ThemeController.update/2` (session + `tl_theme` cookie + redirect-to-referer) and `Auth.on_mount` → `@threadline_theme` → `data-tl-theme` are correct. No FOUC (server-side resolution); never move to localStorage.

**Active-location signaling / wayfinding (NAV-01)**
- **D-10:** Adopt Pattern B: nav active-highlight (keep `aria-current="page"` + 4-signal non-color treatment) + a consistent per-page H1/page-header block + breadcrumbs ONLY on genuine drill-down pages.
- **D-11:** Introduce ONE internal `page_header` function component (semantic `<header class="tl-page__header">`, single `<h1 class="tl-page__title">`, optional lede + actions slot, optional breadcrumb), collapsing the 3+ current title conventions. Exactly one `<h1>` per page.
- **D-12:** Breadcrumb trails (location-based, NOT history-based): Transaction detail → `Timeline` → **Transaction {short-id}**; Transaction-scoped row history → `Timeline` → `Transaction {short-id}` → **Row history · {table}**; Standalone Row history → `Timeline` → **Row history · {table}** (2-segment); Actor detail → `Timeline` → **Actor · {type}/{id}**; Home/Timeline/Coverage/Evidence/Exports/Redaction/Retention → **no breadcrumb**.
- **D-13:** Root link is `Timeline`, not `Home`. Final segment is plain text, not a link. Wrap in `<nav aria-label="Breadcrumb">` (rename the bespoke `aria-label="Investigation path"`). Keep `aria-current="page"` on the nav link only — NOT also on the breadcrumb current segment.
- **D-14:** Keep the nav `current` atom; add a separate optional `breadcrumbs` assign (ordered `{label, href|nil}` list) threaded into `page_header` in each LiveView's `handle_params`. Explicit-assign, not route-inferred.

**Pagination (NAV-02)**
- **D-15:** Data layer is DONE — `Threadline.Query.timeline_page/2` is correct keyset; Actor history is bidirectional; count is capped (`10_001` → "10,000+"), no `COUNT(*)`. Do NOT change the engine. Read-only verify the composite index `audit_changes (captured_at DESC, id DESC)` exists. **[RESEARCH CORRECTION — see Open Questions Q1: this index does NOT exist.]**
- **D-16:** Keep infinite scroll (`phx-viewport-bottom`) primary; add one reusable, de-emphasized `ui.ex` pager ("Newer / range-caption / Older") as the accessible / no-JS / end-of-stream companion.
- **D-17:** Microcopy = "Older" / "Newer" (time-axis), not "Next/Previous", not page numbers. Range caption honest/relative ("Showing N of 10,000+ matching changes"). Caption uses `role="status" aria-live="polite"`.
- **D-18:** Hide entire pager only at zero results; when shown, disable (not hide) the unavailable directional control at a boundary; keep the range caption even on a single full page.
- **D-19:** Filters stay in the URL (`handle_params`); the append cursor stays in assign/`phx-click` state, NOT the URL. Use Phoenix streams for the list.
- **D-20:** Non-Timeline pages: Exports (`limit 100`) and Retention (`limit 40`) get an honest cap caption ("Showing latest 40 …"), not full keyset paging. Coverage (snapshot) and Policy/Redaction (single view) get no pager.

**Mobile navigation + sticky/scroll (NAV-04)**
- **D-21:** Replace checkbox + `<button onclick=…>` hybrid drawer with native `<details>`/`<summary>` disclosure. CSS-checkbox alternative rejected.
- **D-22:** Do NOT add `aria-expanded` to `<summary>`. Do NOT set a shared `name=` on the nav `<details>`. Preserve the `@media (min-width:768px)` desktop override forcing panel visible + `summary { display:none }`; re-point selectors from `:checked`/`.--open` to `[open]`.
- **D-23:** `scroll-padding-top` on the scroll container = combined sticky height (mobile = topbar + collapsed nav summary; ≥768px = topbar only); reconcile with existing per-row `scroll-margin-top` to the same token.
- **D-24:** `overscroll-behavior: contain` on the scrollable panel (and desktop `overflow:auto` rail). No body-scroll-lock / focus-trap.
- **D-25:** `min-height: 100svh` for the shell; `100dvh` for scrollable rails (keep a `vh` fallback line first). Reduced-motion already handled by the blanket `prefers-reduced-motion` block.
- **D-26:** Fix the skip-link inline `onclick` (`surface_header.ex` ~34) by adding `tabindex="-1"` to `<main id="tl-main">` so native fragment navigation moves focus there; the `<a href="#tl-main">` then needs no script.

**CSP-hardening thread (cross-cutting)**
- **D-27:** Eliminate ALL inline event handlers on the operator surface: theme-picker `onchange` (D-03), nav-toggle `onclick` (D-21), skip-link `onclick` (D-26). Net: shell fully CSP-proof. Consider a contract test asserting no `on*=` substrings in the shell source.

### Claude's Discretion
- Exact token names for the new active-state / pager / page-header styles, the precise `page_header` slot API, and the breadcrumb separator glyph — match existing `ui.ex` / `style.ex` BEM + `--tl-*` idioms.
- Whether the pager component is `ui.ex` `pager/1` vs colocated — pick the least-surprise location matching `tabs`/`segmented_control`/`field_group`.

### Deferred Ideas (OUT OF SCOPE)
- Data-display / table / timeline / KV rendering polish → Phase 176 (DATA-01..05).
- Microcopy & IA sweep → Phase 177.
- Per-page & flow stress → Phase 178.
- Accessibility verification & adversarial closeout → Phase 180.
- Transaction-page left-push desktop layout bug → reviewed, NOT folded (Phase 176/178/PAGE-03).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| NAV-01 | App shell + nav present consistent on-brand structure; active/current state unmistakable in dark and light | Nav 4-signal active CSS verified at `style.ex:640–647` (accent-soft bg + accent-border + inset ring + strong weight + `aria-current="page"` selector). `page_header`/breadcrumb work collapses 3 title conventions (`tl-page__title`, `tl-transaction__title`, `tl-timeline-command__title`/`tl-home__headline`) — all located. |
| NAV-02 | Pagination clear when present; de-emphasizes/hides at one page or zero results | Existing keyset engine `Threadline.Query.timeline_page/2` + `actor_history/2` verified. LiveView events `next-page`/`prev-page` and assigns `@cursor`/`shown_count`/`match_count` confirmed in `timeline_live.ex` + `actor_live.ex`. New `ui.ex` pager consumes these; no engine change. |
| NAV-03 (THEME-TOGGLE-01) | In-product dark/light/system picker, cookie + plug, zero JS, no FOUC; lift `theme-toggle` ban; persists per operator | Backend (`ThemeController`, `Auth.on_mount`, `data-tl-theme`) confirmed correct (D-09). Picker markup + 3 `onchange` handlers + visually-hidden `tl-sr-only` radios located. 3 `theme-toggle` ban sites located (`style_contract_test.exs:29, 1009, 1113`). |
| NAV-04 | Mobile nav without scroll traps; sticky never covers content | Native `<details>` precedent confirmed (3 existing uses). Mobile-nav CSS uses `:checked`/`.tl-shell-nav--open` (`style.ex:554, 558, 570, 574`) — to re-point to `[open]`. `100dvh` precedent at `style.ex:2974`. Skip-link `onclick` at `surface_header.ex:34`, nav-toggle `onclick` at `:74`. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Theme persistence (cookie/session) | API/Backend (`ThemeController` + `Auth.on_mount` plug) | — | Server-side resolution → no FOUC, CSP-proof. Already shipped (D-09). |
| Theme picker rendering | Frontend Server (LiveView render in `surface_header.ex`) | Browser (native form POST) | Server renders native `<form>`/radios; browser does native submit + full-page reload. No client JS. |
| Active-state / breadcrumb styling | Frontend Server (`style.ex` inline CSS) + Browser (CSS `:has`, `[aria-current]`, `[open]`) | — | Pure CSS, no JS. `:has(:checked)` is pure-CSS active state (D-05). |
| Pagination data (keyset) | API/Backend (`Threadline.Query`) | Database (composite index) | Engine done (D-15); index is the DB-tier perf concern — see Q1. |
| Pagination UI / cursor state | Frontend Server (LiveView assigns + `phx-click`/`phx-viewport-bottom`) | — | Cursor in socket assign, NOT URL (D-19). Streams for memory bound. |
| Filter state | Frontend Server (`handle_params`, URL) | — | URL-serialized for shareability (D-19). |
| Mobile nav disclosure | Browser (native `<details>` `open` state) + Frontend Server (CSS) | — | Native disclosure, zero JS (D-21). |

## Standard Stack

This phase introduces **zero new dependencies** (hard milestone invariant). The "stack" is the existing repo's idioms.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix.LiveView | (repo's pinned dep) | Function components, `handle_params`, streams, `phx-viewport-*`, `phx-click` | Already the entire operator-surface runtime; no alternative permitted. |
| Phoenix.Component | (with LiveView) | `attr`/`slot` internal components (`button`, `radio`, `segmented_control`, `tabs`, `field_group`) | All `ui.ex` components use this. New `pager`/`page_header` follow suit. |
| Plug.CSRFProtection | (Plug dep) | `get_csrf_token/0` for the theme form's hidden `_csrf_token` | Already used at `surface_header.ex:107`. Required because a LV-rendered form posting to a controller route gets no auto-CSRF (D-04). |
| Ecto / Postgrex | (repo's deps) | Keyset pagination queries in `Threadline.Query` | Engine done; read-only this phase except the index question (Q1). |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ExUnit | (Elixir stdlib) | Contract tests (`File.read!` + `String.contains?` source assertions); LiveView tests (`Phoenix.LiveViewTest`) | New CSP guard test + pager/breadcrumb/h1 assertions. |
| Native HTML (`<details>`/`<summary>`, `<form>`, `<input type=radio>`, `:has()`, `[open]`) | browser-native | Zero-JS disclosure, theme form, pure-CSS active state | The whole phase. No JS widget libraries. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Native `<details>` mobile nav | CSS-checkbox-as-disclosure (current) | REJECTED by D-21: checkbox-as-disclosure is an ARIA anti-pattern; `aria-expanded` on a checkbox is invalid and unsyncable without JS. |
| Cookie+plug theme | localStorage + `<head>` script | REJECTED (REQUIREMENTS "Out of Scope" + D-09): FOUC on dead render, dies under CSP. |
| `:has(:checked)` pure-CSS active | markup `--active` class | D-05 mandates `:has(:checked)` so active state can't drift from markup. (Current `tl-segmented__item--active` markup class has NO matching CSS rule — see Pitfall 2.) |

**Installation:** None. `mix deps.get` unchanged. Zero new runtime deps is a hard invariant.

**Version verification:** N/A — no packages added. The only registry-touching change considered (a Postgres index) is SQL in an existing migration module, not a dependency.

## Package Legitimacy Audit

**Not applicable.** This phase installs zero external packages (hard milestone invariant: "zero new runtime dependencies", REQUIREMENTS.md line 7 + UI-SPEC Registry Safety). No npm, Hex, or PyPI installs. slopcheck/registry verification is moot.

## Architecture Patterns

### System Architecture Diagram

```
                          ┌─────────────────────────────────────────────┐
  Operator browser        │         Phoenix LiveView (server)            │
  ───────────────         │                                              │
                          │  Auth.on_mount (plug)                        │
  GET /audit/timeline ───►│   session[:tl_theme] / cookie ──► @theme ────┼──► data-tl-theme attr
                          │                                              │     (style.ex CSS resolves lane)
  scroll to bottom ──────►│  phx-viewport-bottom="next-page"             │
                          │   handle_event("next-page") ─► Query.timeline_page/2 (keyset)
                          │     ──► stream(:changes, entries, at: -1)     │
                          │     ──► assign(:cursor, next_cursor)          │
                          │     ──► assign(:shown_count/:match_count)     │
  click "Older" ─────────►│  phx-click="next-page" (SAME handler) ───────┘
  click "Newer" ─────────►│  phx-click="prev-page" (actor only today)
                          │
  POST /audit/theme ─────►│  ThemeController.update (controller, NOT LV)
   (native form submit)   │   put_session + put_resp_cookie + redirect(referer)
                          │   ──► full-page reload ──► new @theme everywhere
                          │
  <details open> toggle ─►│  (browser-native; CSS [open] reveals panel; NO server round-trip)
  <a href="#tl-main"> ───►│  (browser-native fragment nav; focuses <main tabindex="-1">; NO script)
```

Data flow trace (primary use case — operator paginates the timeline): request enters via `handle_params` (filters from URL) → `Query.timeline_page/2` runs keyset query → entries pushed to stream + `next_cursor`/counts assigned → operator scrolls (or clicks "Older") → `next-page` event → next keyset page appended → range caption (`role=status`) announces new `shown_count`.

### Component Responsibilities

| File | Responsibility | Change in 175 |
|------|----------------|---------------|
| `components/surface_header.ex` | Topbar, shell-nav, theme picker, mobile toggle, skip-link, `nav_link` | Fix 3 inline handlers; rebuild picker (visible radios + submit button); convert toggle to `<details>`; **new home of `page_header`/breadcrumb** (or `ui.ex`). |
| `ui.ex` | Internal function components | **Add `pager/1`** (and possibly `page_header/1`). |
| `style.ex` | All inline CSS | Add picker `:has(:checked)` active rule; re-point mobile-nav `:checked`/`.--open` → `[open]`; add pager styles; `scroll-padding-top`; `overscroll-behavior`; `100svh`. |
| `query.ex` | Keyset engine | **Read-only** (D-15) — except Q1 index decision. |
| `live/*_live.ex` (11 pages) | Page content, `handle_params`, events | Thread `breadcrumbs` assign; adopt `page_header`; mount `pager`. |
| `router.ex` | Mount macro + `/theme` route | Update macro doc (D-08). Route unchanged. |
| `controllers/theme_controller.ex` | Theme POST | **No change** (D-09). |
| `test/.../style_contract_test.exs` | Source-string contract | Remove 3 `theme-toggle` bans; add CSP guard. |

### Recommended Project Structure
No new directories. New components land in existing files:
```
lib/threadline/operator_surface/
├── ui.ex                       # + pager/1 (and maybe page_header/1) — matches tabs/segmented_control/field_group
├── components/surface_header.ex# fixed picker, <details> nav, fixed skip-link; maybe page_header/breadcrumb here
├── style.ex                    # + picker :has(:checked), [open] re-point, pager, scroll-padding, overscroll, svh
└── live/{11 pages}.ex          # thread breadcrumbs assign + page_header + pager
```

### Pattern 1: Native `<details>` disclosure (zero-JS, already in repo)
**What:** Use `<details>`/`<summary>` for the mobile nav drawer; CSS reveals the panel on `[open]`.
**When to use:** Any disclosure that today uses a checkbox or `onclick`.
**Example:**
```elixir
# Source: lib/threadline/operator_surface/live/timeline_live.ex:546 (EXISTING precedent)
<details class="tl-filter-disclosure" open={@advanced_filters_active?}>
  <summary class="tl-filter-disclosure__summary">…</summary>
  …
</details>
# CSS: lib/threadline/operator_surface/style.ex:1293
# .tl-filter-disclosure[open] > .tl-filter-disclosure__summary::before { … }
```
For the nav: re-point `style.ex:554/558/570/574` from `.tl-shell-nav__control:checked + …` and `.tl-shell-nav.tl-shell-nav--open …` to `.tl-shell-nav[open] …`, and keep the `@media (min-width:768px)` rule forcing the panel visible + `summary { display:none }` (re-pointed to `[open]`-agnostic selectors). [CITED: lib/threadline/operator_surface/style.ex:505–583]

### Pattern 2: Theme form posting to a controller route (CSRF-explicit)
**What:** LiveView-rendered `<form method="post">` to the `/theme` controller route needs an explicit CSRF token.
**Example:**
```elixir
# Source: lib/threadline/operator_surface/components/surface_header.ex:106–107 (EXISTING)
<form action={"#{@base_path}/theme"} method="post" class="tl-theme-picker__form">
  <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
  …
</form>
```
Fix (D-02/D-03/D-05): remove `class="tl-sr-only"` and `onchange="this.form.submit()"` from each radio; make radios visible; add explicit `<button type="submit">Apply theme</button>`; drive active state with `:has(:checked)` CSS.

### Pattern 3: Pager over the existing keyset events
**What:** A de-emphasized `ui.ex` pager that emits the SAME `next-page`/`prev-page` events infinite-scroll already uses.
**Example (real assign/event names — verified):**
```elixir
# Timeline: phx-viewport-bottom={@cursor && "next-page"} already at timeline_live.ex:382
# handle_event("next-page", _, socket) at timeline_live.ex:297 → stream(:changes, …, at: -1), assign(:cursor, next_cursor)
# Actor: phx-viewport-bottom="next-page" / phx-viewport-top="prev-page" at actor_live.ex:161-162
#   handle_event("next-page")/"prev-page" at actor_live.ex:222/255
# Counts: shown_count={length(@streams.changes.inserts)}, match_count={@match_count}  (timeline_live.ex:344-345)
<.pager
  newer_event="prev-page"  newer_enabled={…}
  older_event="next-page"  older_enabled={@cursor != nil}
  shown={@shown_count} total={@match_count} capped={@match_count >= 10_001}
/>
```
Range caption container: `role="status" aria-live="polite"` (reuse the `.tl-status` pattern already at `timeline_live.ex:601`).

### Pattern 4: `page_header` collapsing three title conventions
**Current conventions (verified):**
- `tl-page__title` — coverage, evidence, exports, retention, redaction, stress (the majority)
- `tl-transaction__title` — transaction_live (120), actor_live (123)
- `tl-timeline-command__title` (456) — timeline; `tl-home__headline` (start_live 135) — home (Display role)

`page_header/1` renders `<header class="tl-page__header">` (class already exists, e.g. transaction_live:117) with one `<h1 class="tl-page__title">`, optional `lede` (`tl-page__lede` already used at transaction_live), optional `actions` slot, optional `breadcrumbs`.

### Anti-Patterns to Avoid
- **Markup-driven active class with no CSS / drift risk:** the current `tl-segmented__item--active` markup class (surface_header.ex:109/113/117) has **no matching CSS rule** (`style.ex` only defines `.tl-segmented__item[aria-pressed="true"]`). Replace with pure-CSS `:has(:checked)` per D-05 — never a hand-set `--active` class.
- **Serializing the scroll cursor into the URL:** D-19 — a stale mid-scroll cursor misleads in an audit context. Cursor stays in assign.
- **`aria-expanded` on `<summary>`:** D-22 — redundant double-announce; native `open` state covers it.
- **`COUNT(*)` for an exact total:** the `10_001` cap → "10,000+" pattern is load-bearing (timeline_live.ex:369/375). Never let an exact deep total back in.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Mobile nav open/close | A JS toggle / checkbox hybrid (the current code) | Native `<details>`/`<summary>` | Native button role, keyboard, focus, and `open` a11y state for free; CSP-proof; precedent exists in repo. |
| Skip-link focus move | Inline `onclick` focusing `#tl-main` | `tabindex="-1"` on `<main>` + native fragment nav | Browser moves focus natively; D-26. |
| Theme submit on change | `onchange="this.form.submit()"` | Explicit `<button>Apply theme</button>` + full-page reload | Inline JS is CSP-blocked; explicit submit is on-ethos and works everywhere. |
| Active-state styling sync | A markup `--active` class set in Elixir | Pure-CSS `:has(:checked)` / `[aria-current="page"]` selectors | Can't drift from markup; no JS; D-05. |
| Keyset pagination engine | Re-implementing cursor logic | `Threadline.Query.timeline_page/2` + `actor_history/2` | Production-correct, capped, tiebreaker-safe. D-15: do not touch. |
| Bidirectional ("Newer") paging | New query code | `actor_history/2`'s flip-order-then-reverse-in-Elixir pattern (query.ex:482–537) | Already proves the bidirectional pattern. |

**Key insight:** Every "fix" in this phase is a *removal* of hand-rolled JS in favor of a native HTML/CSS capability the platform already provides — and the keyset engine is already built. The phase's value is subtractive (CSP liabilities removed) plus one accessible UI veneer over existing server events.

## Runtime State Inventory

> Rename/refactor concerns. This is primarily a UI-fix phase, but it touches a persisted theme cookie/session and a DB index, so the inventory matters.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | **Theme preference:** `tl_theme` in both **session** (`put_session(:tl_theme, …)`) and a **cookie** (`put_resp_cookie("tl_theme", …, path: "/")`, no `max_age` → session cookie). Read at `auth.ex:14` (`session["tl_theme"] \|\| session[:tl_theme]`). Values: `"light"`/`"dark"`/`"system"`. | **No migration** — the picker UI fix does not change stored values or keys. Backend untouched (D-09). Note: cookie has no `max_age`, so "persists per operator" (NAV-03) holds only for the session lifetime unless a `max_age` is added — flag if true persistence is intended (out of D-09 scope; do not change without escalation). |
| Live service config | None. No external service stores this string. | None — verified: only `ThemeController` + `Auth` touch `tl_theme`. |
| OS-registered state | None. | None — UI-only phase. |
| Secrets/env vars | None. The `_csrf_token` is request-scoped (`Plug.CSRFProtection.get_csrf_token/0`), not a stored secret. | None. |
| Build artifacts / installed packages | None. No package rename; zero deps added/removed. | None. |
| **Database schema (index)** | `audit_changes_captured_at_idx ON audit_changes (captured_at)` — **single-column**, at `lib/threadline/capture/migration.ex:57`. The composite `(captured_at, id)` index D-15 assumes does **not** exist. | **DECISION NEEDED (Q1).** If a composite index is added, it is a **capture-layer migration change** (data migration / new `CREATE INDEX`), not a code edit, and brushes the "capture layer untouched" invariant. Adding an index is safe/online-able (`CREATE INDEX CONCURRENTLY`) but must be a deliberate, escalated decision — not a silent D-15 "read-only verify". |

**Canonical question answer:** After all repo files are updated, the only runtime state with the relevant string is the `tl_theme` session/cookie (unchanged by this phase) and the DB index situation (Q1). Nothing else is cached, stored, or registered.

## Common Pitfalls

### Pitfall 1: Treating the composite index as already-existing (D-15)
**What goes wrong:** Planner writes a "read-only verify the index exists" task; reviewer finds only `audit_changes (captured_at)`; the keyset tiebreaker `ORDER BY captured_at DESC, id DESC` falls back to a sort on random-UUID `id` for ties. On a deep timeline this is a latent perf cliff exactly where pagination matters most.
**Why it happens:** D-15's wording assumes prior work created the composite index. The migration shows it did not.
**How to avoid:** Escalate Q1 first. Either (a) add `CREATE INDEX CONCURRENTLY IF NOT EXISTS audit_changes_captured_at_id_idx ON audit_changes (captured_at DESC, id DESC)` to the capture migration (deliberate capture-layer change), or (b) explicitly accept the single-column index and document that `id` ties are rare (UUID collisions on identical `captured_at` are uncommon). Do NOT plan D-15 as zero-work.
**Warning signs:** A task that says only "verify index exists" with no `CREATE INDEX` fallback.

### Pitfall 2: The theme-picker active state has no CSS today
**What goes wrong:** The current markup sets `tl-segmented__item--active`, but `style.ex` has no `.tl-segmented__item--active` rule — only `.tl-segmented__item[aria-pressed="true"]`. Native radios don't set `aria-pressed`. So the "active" theme is currently signaled **only** by the visually-hidden checked radio (a screen-reader-only signal) — a real WCAG 1.4.1 / visible-state gap, which is precisely why D-05 mandates `:has(:checked)` + visible radios.
**How to avoid:** Implement D-05's `:has(:checked)` rule on the new visible radio group; delete the dead `--active` markup class.
**Warning signs:** Keeping `tl-sr-only` on the radios, or relying on `--active`/`aria-pressed`.

### Pitfall 3: The `theme-toggle` bans live in style.ex tests, but the CSP risk lives in surface_header.ex
**What goes wrong:** The three `refute "theme-toggle"` assertions all read `@style_path` (`style.ex`). Removing them does nothing to guard the *actual* CSP liability (inline handlers in `surface_header.ex`). A naive "lift the ban" leaves no positive guard.
**How to avoid:** Add a NEW contract test that `File.read!`s `lib/threadline/operator_surface/components/surface_header.ex` and asserts: no `onclick=`, no `onchange=`, no `on` + event-name substrings; AND asserts the picker form contains `action=` ending `/theme` and `_csrf_token`. Follow the existing `File.read! + String.contains?` idiom (style_contract_test.exs:9). Remember D-07 also keeps the OTHER anti-patterns in the `style.ex:1111` list (`@tailwind`, `shadcn`, `daisyui`, `heroicons`) — remove ONLY `"theme-toggle"` from that list.
**Warning signs:** Deleting the whole anti-pattern loop, or testing the wrong source file.

### Pitfall 4: `<main tabindex="-1">` is inconsistent across pages
**What goes wrong:** D-26 relies on `<main id="tl-main" tabindex="-1">`. It IS present on timeline_live (340) and row_history_live (50), but each of the 11 pages renders its own `<main>` — some may lack `tabindex="-1"`. If any page misses it, the skip-link silently fails to move focus on that page.
**How to avoid:** Audit all 11 `<main id="tl-main">` for `tabindex="-1"`; add where missing. A contract/LiveView test asserting every page's `<main>` has `tabindex="-1"` locks it.
**Warning signs:** Skip-link works on Timeline but not on Coverage/Evidence/etc.

### Pitfall 5: `scroll-padding-top` double-counting with per-row `scroll-margin-top` (D-23)
**What goes wrong:** Adding `scroll-padding-top` on the container while per-row anchors already set `scroll-margin-top` (style.ex ~2453) can double the offset, pushing anchored rows too far down.
**How to avoid:** Reconcile both to the **same token** (D-23). Mobile offset = topbar + collapsed `<summary>` height; ≥768px = topbar only.
**Warning signs:** Anchored rows land with a large gap above them.

## Code Examples

### Reading a source file in a contract test (the established idiom)
```elixir
# Source: test/threadline/operator_surface/style_contract_test.exs:5,9
@style_path "lib/threadline/operator_surface/style.ex"
src = File.read!(@style_path)
refute String.contains?(src, "theme-toggle")   # ← the 3 to remove (lines 29, 1009; and item in list at 1113)
```

### New positive CSP guard (recommended shape)
```elixir
@header_path "lib/threadline/operator_surface/components/surface_header.ex"
test "operator shell carries zero inline event handlers (CSP-proof)" do
  src = File.read!(@header_path)
  refute String.contains?(src, "onclick=")
  refute String.contains?(src, "onchange=")
  # picker posts to /theme with CSRF, no inline JS
  assert String.contains?(src, "/theme")
  assert String.contains?(src, "_csrf_token")
end
```

### Composite index (if Q1 resolves to "add it")
```elixir
# Source pattern: lib/threadline/capture/migration.ex:57 (existing single-col index)
execute "CREATE INDEX IF NOT EXISTS audit_changes_captured_at_id_idx " <>
        "ON #{storage_schema}.audit_changes (captured_at DESC, id DESC)"
# Online variant for adopters with existing data: CREATE INDEX CONCURRENTLY (outside a txn migration).
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Inline `onchange`/`onclick` handlers for theme/nav/skip | Native `<form>` submit, native `<details>`, native fragment-nav + `tabindex="-1"` | This phase (175) | Shell becomes CSP-proof; controls work under strict `script-src`. |
| Checkbox-as-disclosure (`#tl-shell-nav-toggle` + JS class toggle) | Native `<details>`/`<summary>` `[open]` | This phase (175) | Correct ARIA disclosure semantics; no invalid `aria-expanded`-on-checkbox. |
| Visually-hidden radios (`tl-sr-only`) + dead `--active` class | Visible radios + `:has(:checked)` dual-signal active state | This phase (175) | Fixes WCAG 1.4.1; visible, non-color-only selected state. |
| `theme-toggle` banned in style contract | Ban lifted + positive CSP guard on `surface_header.ex` | This phase (175) | Picker is now sanctioned; CSP liability is what's guarded instead. |

**Deprecated/outdated:**
- The `router.ex` macro doc claim "Threadline does not add JavaScript, local storage, or a runtime theme toggle" (lines 53–55) — superseded by the cookie+plug picker (D-08). (The claim is still half-true: no JS, no localStorage; but a runtime theme *picker* now exists.)
- `#tl-shell-nav-toggle` hidden checkbox input (surface_header.ex:61–67) — removed when converting to `<details>`.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Adding a composite `(captured_at, id)` index improves keyset tiebreaker performance materially | Pitfall 1 / Q1 | LOW — standard keyset-index practice; but the *decision to touch the capture-layer migration* is what needs user sign-off, not the perf claim. |
| A2 | All 11 pages render their own `<main id="tl-main">` (not a shared layout) | Pitfall 4 | MEDIUM — if there's a shared layout, the `tabindex` audit is one fix not eleven. Verified `<main>` in timeline/row_history individually; full enumeration deferred to planner per-page. |
| A3 | The `tl_theme` cookie being a session cookie (no `max_age`) is intentional | Runtime State Inventory | LOW — D-09 says backend is correct as-is; flagged only because NAV-03 says "persists per operator". Not changing it without escalation. |

**Note:** All other claims in this research are `[VERIFIED: codebase]` via direct file reads cited inline. No external/registry assumptions were made (zero-dep phase).

## Open Questions (RESOLVED)

1. **The composite index `audit_changes (captured_at DESC, id DESC)` does not exist (D-15).** — **RESOLVED 2026-06-17: defer as capture-layer perf debt.**
   - What we know: Only `audit_changes_captured_at_idx ON audit_changes (captured_at)` exists (`lib/threadline/capture/migration.ex:57`). `id` is a random-UUID PK, so the keyset tiebreaker is not index-backed.
   - **Resolution (user):** Keep the capture layer untouched in Phase 175. Do NOT add a migration/index and do NOT plan an index-existence test. Document the unbacked `(captured_at, id)` tiebreaker (ties on `captured_at` are rare given timestamp + random UUID) in `query.ex` and file the composite index as deferred capture-layer perf debt. D-15 is reframed from "read-only verify it exists" to this documentation note.

2. **Does any page lack `<main tabindex="-1">`? (D-26)** — **RESOLVED: all 11 pages already carry it.**
   - What we know: present on timeline_live (340) and row_history_live (50); plan-time grounding confirmed all 11 `<main id="tl-main">` already have `tabindex="-1"`.
   - **Resolution:** The skip-link fix is purely the inline `onclick` removal; `skip_link_test.exs` is a GREEN regression lock asserting every page's `<main id="tl-main">` has `tabindex="-1"`.

3. **Should the `tl_theme` cookie gain a `max_age` for true per-operator persistence?** — **RESOLVED: out of scope (D-09).**
   - What we know: It's currently a session cookie (no `max_age`); D-09 says the backend is correct.
   - **Resolution:** Out of scope per D-09 (backend untouched); flagged only. Not changed in Phase 175.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Mix | All work | ✓ (repo builds) | repo-pinned | — |
| PostgreSQL | Index decision (Q1), test DB | ✓ (existing tests run) | — | — |
| Node + Playwright | `mix verify.example_browser` (browser e2e in `ci.all`) | (assumed present per `ci.all`) | — | Browser tests are the slowest gate; unit/contract tests cover most NAV signals without them. |

No new external tools required. This is code/CSS/test work plus one possible SQL index.

## Validation Architecture

> nyquist_validation enabled (no `workflow.nyquist_validation: false` found). Section included.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir stdlib) + `Phoenix.LiveViewTest` |
| Config file | `test/test_helper.exs`; aliases in `mix.exs` (`verify.test`, `ci.all`) |
| Quick run command | `mix test test/threadline/operator_surface/style_contract_test.exs` |
| Full suite command | `mix verify.test` (== `mix test`); full gate `mix ci.all` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| NAV-03 | Shell source has no `onclick=`/`onchange=`/`on*=` inline handlers | contract (source string) | `mix test test/threadline/operator_surface/surface_header_csp_test.exs` | ❌ Wave 0 (new file) |
| NAV-03 | Theme form posts to `/theme` and carries `_csrf_token` | contract (source string) | same file as above | ❌ Wave 0 |
| NAV-03 | `theme-toggle` ban removed from style contract (3 sites) + style test still green | contract | `mix test test/threadline/operator_surface/style_contract_test.exs` | ✅ (edit existing) |
| NAV-03 | Picker active state visible & non-color (`:has(:checked)` rule present in `style.ex`) | contract (source string) | `mix test test/threadline/operator_surface/style_contract_test.exs` | ✅ (add assertion) |
| NAV-01 | Exactly one `<h1>` per LiveView page | LiveView render | `mix test test/threadline/operator_surface/page_header_test.exs` | ❌ Wave 0 |
| NAV-01 | Breadcrumb landmark is `<nav aria-label="Breadcrumb">` (not "Investigation path") on drill-down pages; absent on flat pages | LiveView render | `mix test test/threadline/operator_surface/breadcrumb_test.exs` | ❌ Wave 0 |
| NAV-01 | `aria-current="page"` on nav link only, never on breadcrumb current segment | LiveView render | breadcrumb_test | ❌ Wave 0 |
| NAV-02 | Pager hides at zero results; renders with disabled (not absent) boundary control on a single full page; range caption present | LiveView render | `mix test test/threadline/operator_surface/pager_test.exs` | ❌ Wave 0 |
| NAV-02 | Range caption container has `role="status" aria-live="polite"`; copy = "Showing N of 10,000+ matching changes" when capped | LiveView render | pager_test | ❌ Wave 0 |
| NAV-02 | `match_count >= 10_001` renders "10,000+" (no exact deep total) | LiveView render | pager_test (reuse existing `format_count` path) | ✅ (extend timeline test) |
| NAV-04 | Mobile nav uses native `<details>`; CSS keys on `[open]` not `:checked`/`.--open` | contract (source string) | `mix test test/threadline/operator_surface/style_contract_test.exs` | ✅ (add assertion) |
| NAV-04 | Every page's `<main id="tl-main">` has `tabindex="-1"` (skip-link target) | LiveView render | `mix test test/threadline/operator_surface/skip_link_test.exs` | ❌ Wave 0 |
| NAV-04 | `scroll-padding-top` + `overscroll-behavior: contain` + `100svh` present in `style.ex` | contract (source string) | `mix test test/threadline/operator_surface/style_contract_test.exs` | ✅ (add assertions) |
| D-08 | Router macro doc no longer claims "no runtime theme toggle" | contract (source string) | `mix test test/threadline/operator_surface/router_test.exs` or doc-contract | ❌/✅ (verify existing) |
| D-15 / Q1 | Composite index exists (IF Q1 resolves to "add") | migration/DB | `mix test` querying `pg_indexes` for `audit_changes` | ❌ Wave 0 (only if Q1 = add) |

### Sampling Rate
- **Per task commit:** `mix test test/threadline/operator_surface/style_contract_test.exs <new test file>` + `mix verify.format`
- **Per wave merge:** `mix verify.test` (full ExUnit) + `mix verify.credo`
- **Phase gate:** `mix ci.all` green (includes `verify.example_browser` Playwright) before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/threadline/operator_surface/surface_header_csp_test.exs` — covers NAV-03 (no inline handlers; form posts /theme + CSRF) and NAV-04 (no `onclick` on nav/skip)
- [ ] `test/threadline/operator_surface/page_header_test.exs` — covers NAV-01 (one `<h1>` per page)
- [ ] `test/threadline/operator_surface/breadcrumb_test.exs` — covers NAV-01 (D-12/D-13 trails, landmark label, single `aria-current`)
- [ ] `test/threadline/operator_surface/pager_test.exs` — covers NAV-02 (hide-at-zero, disable-not-hide, range caption, `role=status`, "10,000+")
- [ ] `test/threadline/operator_surface/skip_link_test.exs` — covers NAV-04 (all 11 `<main>` have `tabindex="-1"`)
- [ ] (Conditional) DB index existence test — only if Q1 resolves to "add the composite index"
- [ ] Edits to existing `style_contract_test.exs`: remove 3 `theme-toggle` bans (lines 29, 1009, list-item at 1113); add `[open]`, `:has(:checked)`, `scroll-padding-top`, `overscroll-behavior`, `100svh` assertions

*No framework install needed — ExUnit + LiveViewTest already in use.*

## Security Domain

> `security_enforcement` not set to false → included.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Auth is upstream (`Auth.on_mount`, fail-closed); unchanged this phase. |
| V3 Session Management | partial | `tl_theme` in session/cookie (low-sensitivity preference, not auth). No change to session handling. |
| V4 Access Control | no | No new routes/authorization; `/theme` route already gated by the mount pipeline. |
| V5 Input Validation | yes | `ThemeController.update/2` already guards `theme in ["light","dark","system"]` with a fall-through clause (theme_controller.ex:4,11) — verified correct. |
| V6 Cryptography | no | No crypto; CSRF token is framework-provided. |
| V14 (Config / CSP) | **yes (headline)** | Removing inline `on*=` handlers makes the shell compatible with a strict `script-src` CSP — the phase's central security win. New contract test guards it. |

### Known Threat Patterns for Phoenix LiveView shell

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Inline event handlers blocked by strict CSP → silently disabled control | Denial of Service (control fails silently) | Remove all `on*=`; native HTML/CSS (D-03/D-21/D-26/D-27); positive CSP contract test. |
| CSRF on theme form (LV-rendered form → controller route, no auto-CSRF) | Tampering | Explicit hidden `_csrf_token` via `Plug.CSRFProtection.get_csrf_token/0` (D-04, already present). |
| Open-redirect via `referer` in `ThemeController` | Tampering/Spoofing | Existing behavior `redirect(to: referer || "/")`. NOTE: `referer` is attacker-influenceable; out of this phase's scope (D-09 backend untouched) but worth flagging to the planner as a possible future hardening (validate same-host referer). Not a 175 task. |

## Sources

### Primary (HIGH confidence — codebase, verified this session)
- `lib/threadline/operator_surface/components/surface_header.ex` — 3 inline handlers (34, 74, 110/114/118); `tl-sr-only` radios; `_csrf_token` (107); hidden checkbox toggle (61–67); `nav_link` active class (142–143)
- `lib/threadline/operator_surface/controllers/theme_controller.ex` — full file; `theme in [...]` guard + referer redirect
- `lib/threadline/operator_surface/auth.ex:9–25` — `@threadline_theme` resolution from session/cookie
- `lib/threadline/operator_surface/router.ex:52–55, 127` — macro doc (D-08) + `/theme` POST route
- `lib/threadline/query.ex:298–335, 448–537, 769–828` — `timeline_page/2` keyset + `actor_history/2` bidirectional + cursor structs
- `lib/threadline/capture/migration.ex:55–57` — **single-column** `captured_at` index (Q1 evidence)
- `lib/threadline/operator_surface/ui.ex` — component inventory (button/link/tabs/segmented_control/input/field_group/radio)
- `lib/threadline/operator_surface/style.ex:378–395 (skip/sr-only), 505–583 (shell-nav toggle/:checked/--open), 615–647 (nav active 4-signal), 983–1021 (segmented; no --active rule), 2974 (100dvh)`
- `lib/threadline/operator_surface/live/timeline_live.ex` — events `next-page` (297), `phx-viewport-bottom` (382), assigns `match_count`/`@cursor`/`shown_count`, `10_001` cap (369/375), `tl-status role=polite` (601), `<main tabindex="-1">` (340)
- `lib/threadline/operator_surface/live/actor_live.ex:161–162, 222, 255` — `prev-page`/`next-page`, `phx-viewport-top/bottom`
- `lib/threadline/operator_surface/live/{transaction,row_history,coverage,evidence,export_status,retention_history,policy_redaction,start}_live.ex` — title conventions + breadcrumb markup (`aria-label="Investigation path"` at transaction:113, actor:117)
- `test/threadline/operator_surface/style_contract_test.exs:5,9,24–30,990–1010,1100–1119` — `@style_path` idiom; 3 `theme-toggle` bans; anti-pattern list
- `mix.exs:75–130` — `verify.*` / `ci.all` aliases
- `.planning/REQUIREMENTS.md`, `.planning/phases/175-.../175-CONTEXT.md`, `.../175-UI-SPEC.md`

### Secondary (MEDIUM)
- None required — phase is fully grounded in repo source.

### Tertiary (LOW)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — zero new deps; all idioms verified in-repo.
- Architecture: HIGH — every component/event/assign name verified by direct read.
- Pitfalls: HIGH — each pitfall is backed by a specific cited line (esp. the missing composite index and the dead `--active` class).

**Research date:** 2026-06-17
**Valid until:** 2026-07-17 (stable; source-grounded). Re-verify Q1 (index) and the per-page `<main>` audit at plan time.
