# Phase 175: Navigation, app shell & runtime theme picker - Context

**Gathered:** 2026-06-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Bring the `/audit` operator-surface app shell and navigation (topbar, shell-nav, breadcrumbs, page titles, section tabs, toolbar, back/cancel, mobile nav, pagination, active state) to one consistent, on-brand, unmistakable-wayfinding structure in dark/light/system, and ship the in-product dark/light/system theme picker (NAV-03 / THEME-TOGGLE-01).

**Critical reframe from discussion:** much of this phase is *fix-to-spec*, not greenfield. The theme picker, the keyset pagination engine, and the nav active-state already exist — but the picker and nav toggle violate the zero-JS/CSP-proof invariants, the pager has no accessible UI, and the page-header/breadcrumb story is fragmented. A cross-cutting **CSP-hardening thread** (remove all inline `onclick`/`onchange` handlers) runs through the whole phase.

**In scope:** shell/nav structure + active state; the theme-picker control fix + ban lift; an accessible pagination UI over the existing keyset engine; native-`<details>` mobile nav + sticky/scroll hardening; removal of the three inline event-handler CSP liabilities.

**Out of scope (not this phase):** data-display/table/timeline rendering polish (Phase 176), microcopy/IA sweep (Phase 177), the keyset query engine itself (already built — read-only verify), the theme backend mechanism (shipped in Phase 172), any public/host-facing component API (v1.31 freeze).

</domain>

<decisions>
## Implementation Decisions

### Theme picker (NAV-03 / THEME-TOGGLE-01)
- **D-01:** The picker ALREADY EXISTS in `surface_header.ex` (~lines 104–126) as a segmented radio group in the nav drawer. This phase **fixes** it; it does not build it from scratch.
- **D-02:** Form factor = `<form method="post" action={base_path<>"/theme"}>` → `<fieldset>` + legend "Theme" + three **native, visible** `<input type="radio">` (order: **System, Light, Dark** — System is the default) + an **explicit submit `<button>` "Apply theme"**. Native HTML controls, full-page reload on submit (on-ethos; operators aren't mid-investigation when changing theme).
- **D-03:** **Remove every `onchange="this.form.submit()"`** — inline JS is banned and CSP-violating (a strict adopter `script-src` blocks it, silently disabling the control). This is the headline correctness fix, not a nicety.
- **D-04:** Keep the existing hidden `<input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()}>`. A LiveView-rendered `<form>` posting to a *controller* route does NOT get Phoenix's automatic CSRF injection, so the explicit token is required and correct.
- **D-05:** Do **not** visually hide the radios while signaling active state by background color only (WCAG 1.4.1 fail). Active state = native radio `checked` (announced "selected") **plus a non-color cue** — an inset border bar (`box-shadow: inset 2px 0 0 …`) + `font-weight` bump, driven by pure-CSS `:has(:checked)` so it can't drift from the markup `--active` class.
- **D-06:** Placement stays in the nav-drawer "settings tail" (after Find/Verify/Prove), NOT the dense incident-critical topbar. Set-once, low-frequency control.
- **D-07:** Lift the `theme-toggle` ban in `style_contract_test.exs` (delete the three `refute String.contains?(src, "theme-toggle")` assertions + the comment block) and **replace it with a positive CSP guard**: the picker form posts to `/theme`, carries a CSRF token, and contains no `onclick=`/`onchange=` substring.
- **D-08:** Update the `router.ex` `threadline_operator_surface/2` macro doc that still says "Threadline does not add JavaScript … or a runtime theme toggle" — that posture is now superseded by the cookie+plug picker.
- **D-09:** Backend is untouched: `ThemeController.update/2` (session + `tl_theme` cookie + redirect-to-referer) and `Auth.on_mount` → `@threadline_theme` → `data-tl-theme` are correct as shipped. No FOUC because resolution is server-side from the cookie/session; never move to localStorage.

### Active-location signaling / wayfinding (NAV-01)
- **D-10:** Adopt **Pattern B**: nav active-highlight (keep existing `aria-current="page"` + 4-signal non-color treatment) + a consistent per-page H1/page-header block + breadcrumbs ONLY on genuine drill-down pages. No breadcrumbs on flat ops pages (GOV.UK/NN/g/Polaris rule — they'd duplicate the nav and fabricate hierarchy).
- **D-11:** Introduce ONE internal `page_header` function component (semantic `<header class="tl-page__header">`, single `<h1 class="tl-page__title">`, optional lede + actions slot, optional breadcrumb), collapsing the 3+ current title conventions (`tl-page__title`, `tl-transaction__title`, `tl-timeline-command__title`/`tl-home__headline`). Exactly one `<h1>` per page.
- **D-12:** Breadcrumb trails (location-based, NOT history-based), mapped to the audit domain model:
  - Transaction detail → `Timeline` → **Transaction {short-id}**
  - Transaction-scoped row history → `Timeline` → `Transaction {short-id}` → **Row history · {table}**
  - Standalone Row history (`/rows/...`) → `Timeline` → **Row history · {table}** (2-segment; do not fabricate a transaction parent it doesn't have)
  - Actor detail → `Timeline` → **Actor · {type}/{id}**
  - Home, Timeline, Coverage, Evidence, Exports, Redaction, Retention → **no breadcrumb**
- **D-13:** Root link is `Timeline` (the real drill-down entry point), not `Home` (a task launcher, not an ancestor). Final segment is plain text, not a link. Wrap in `<nav aria-label="Breadcrumb">` (rename the current bespoke `aria-label="Investigation path"`). Keep `aria-current="page"` on the nav link only — do NOT also put it on the breadcrumb's plain-text current segment (avoid two competing "page" currents in the a11y tree).
- **D-14:** Keep the nav `current` atom as the nav-branch indicator (`:timeline`, `:coverage`, …); add a separate optional `breadcrumbs` assign (ordered `{label, href|nil}` list) threaded into `page_header` in each LiveView's `handle_params`. Explicit-assign (not route-inferred) so a new route can't silently produce a wrong trail.

### Pagination (NAV-02)
- **D-15:** Data layer is DONE — `Threadline.Query.timeline_page/2` is correct keyset with the `(captured_at, id)` tiebreaker, `desc` order, row-values seek predicate; Actor history is already bidirectional; count is capped (`10_001` → "10,000+"), no `COUNT(*)`. **Do not re-litigate or change the engine.** Read-only verify the composite index `audit_changes (captured_at DESC, id DESC)` exists (highest-leverage perf item).
- **D-16:** Keep infinite scroll (`phx-viewport-bottom`) as the primary interaction; **add one reusable, de-emphasized `ui.ex` pager** ("Newer / range-caption / Older") as the accessible / no-JS / end-of-stream companion — this *fixes* the infinite-scroll a11y gap (keyboard/SR users get explicit controls + an "end" signal).
- **D-17:** Microcopy framing = **"Older" / "Newer"** (time-axis), not "Next/Previous" and not page numbers. Range caption is honest and relative ("Showing N of 10,000+ matching changes") — never a fabricated "Page 3 of 200" total. Caption uses `role="status" aria-live="polite"`.
- **D-18:** Hide/de-emphasize rule: **hide the entire pager only at zero results** (empty state owns the screen); when shown, **disable (not hide)** the unavailable directional control at a boundary to avoid layout shift; keep the range caption even on a single full page (audit-trust signal that nothing is missing).
- **D-19:** State split: filters stay in the URL (`handle_params`, shareable/deep-linkable — real auditor handoff need); the append cursor stays in assign/`phx-click` state, NOT the URL (a serialized moving cursor points at a stale mid-scroll position — misleading in an audit context). Use Phoenix streams for the list (memory-bounded).
- **D-20:** Non-Timeline pages: Exports (`limit 100`) and Retention (`limit 40`) get an **honest cap caption** ("Showing latest 40 …"), not full keyset paging (low-volume, recent-only); reuse the pager component later only if volume demands. Coverage (snapshot) and Policy/Redaction (single view) get **no pager**.

### Mobile navigation + sticky/scroll (NAV-04)
- **D-21:** Replace the checkbox + `<button onclick=…>` hybrid drawer with a **native `<details>`/`<summary>`** disclosure. Resolves the aria-expanded-vs-CSP tradeoff in favor of CSP/zero-JS: `<summary>` gives native button role + keyboard + a real `open` state in the a11y tree; a disclosure does not need `aria-expanded`. The CSS-checkbox alternative is rejected (checkbox-as-disclosure is an ARIA anti-pattern; `aria-expanded` on a checkbox is invalid and unsyncable without JS).
- **D-22:** Do NOT add `aria-expanded` to `<summary>` (redundant/double-announce). Do NOT set a shared `name=` on the nav `<details>` (that's accordion grouping). Preserve the `@media (min-width:768px)` desktop override forcing the panel visible + `summary { display:none }` regardless of `[open]` — re-point selectors from `:checked`/`.--open` to `[open]`.
- **D-23:** Sticky-never-covers-content: `scroll-padding-top` on the scroll container = combined sticky height (mobile = topbar + collapsed nav summary; ≥768px = topbar only); reconcile with the existing per-row `scroll-margin-top` to the same token so it isn't double-counted.
- **D-24:** No nested-scroll trap: `overscroll-behavior: contain` on the scrollable panel (and the desktop `overflow:auto` rail). No body-scroll-lock / focus-trap needed — `<details>` is in-flow, not a modal overlay.
- **D-25:** Viewport units: `min-height: 100svh` for the shell (first paint fits the small viewport, no initial scrollbar under the iOS address bar); `100dvh` for scrollable rails that should track the live viewport (keep a `vh` fallback line first). Reduced-motion is already handled by the blanket `prefers-reduced-motion` block — a `display`-toggle disclosure is reduced-motion-safe by construction.
- **D-26:** Fix the skip-link inline `onclick` (`surface_header.ex` ~line 34) the zero-JS way: add `tabindex="-1"` to `<main id="tl-main">` so native fragment navigation moves focus there; the `<a href="#tl-main">` then needs no script.

### CSP-hardening thread (cross-cutting)
- **D-27:** This phase eliminates ALL inline event handlers on the operator surface: theme-picker `onchange` (D-03), nav-toggle `onclick` (D-21), skip-link `onclick` (D-26). Net result: the shell is fully CSP-proof with zero inline handlers — a real correctness win for adopters running strict `script-src`. Consider a contract test asserting no `on*=` inline-handler substrings in the shell source.

### Claude's Discretion
- Exact token names for the new active-state / pager / page-header styles, the precise `page_header` slot API, and the breadcrumb separator glyph — match existing `ui.ex` / `style.ex` BEM + `--tl-*` idioms.
- Whether the pager component is `ui.ex` `pager/1` vs colocated — pick the least-surprise location matching `tabs`/`segmented_control`/`field_group`.

### Folded Todos
- **THEME-TOGGLE-01 (dark/light/system theme picker, idiomatic UI controls)** — folded from the operator-surface backlog. Realized as D-01..D-09 (fix the existing picker to be zero-JS, CSP-proof, AA, with a non-color active cue).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` — NAV-01..NAV-04 (and the THEME-TOGGLE-01 alias on NAV-03); v1.37 invariants (no public API, zero new runtime deps, inline CSS, CSP-proof, WCAG 2.2 AA, mobile-first 320–1440, brand-token parity).
- `.planning/ROADMAP.md` §"Phase 175" — goal + 4 success criteria.

### Domain & OSS DNA
- `prompts/audit-lib-domain-model-reference.md` — the audit domain hierarchy (AuditTransaction → AuditChange; Actor/Correlation as cross-cutting indices) that the breadcrumb trails (D-12) must mirror.
- `prompts/threadline-elixir-oss-dna.md` — engineering/quality bar (contracts, deterministic tests, explicit composition, no-public-API discipline).

### Brand (NEWER than `prompts/Threadline Brand Book.txt` — prefer these)
- `brandbook/brand-book.md` — voice/microcopy (plainspoken, sentence case, no "!"), color, focus/hover states, non-color-state rule, motion guidance.
- `brandbook/tokens.json`, `brandbook/tokens.css` — the `--tl-*` token contract (dark + light/system lanes) the new shell/pager/active-state styles must use.

### Ecosystem best-practice research
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md` — `handle_params`/URL state, streams, `phx-viewport-*` infinite scroll idioms.
- `prompts/prior-art/oss-deep-research/ecto-best-practices-deep-research.md` — keyset/cursor query idioms (verification context for D-15).

### Code (existing implementations this phase fixes/extends)
- `lib/threadline/operator_surface/components/surface_header.ex` — topbar, shell-nav, existing theme picker (~104–126, the `onchange` to remove), nav toggle (~61–75), skip-link (~34); home of the new `page_header`/breadcrumb component.
- `lib/threadline/operator_surface/controllers/theme_controller.ex` — theme POST handler (no change needed).
- `lib/threadline/operator_surface/auth.ex` — `@threadline_theme` resolution (~14–22, 179–181).
- `lib/threadline/operator_surface/router.ex` — `threadline_operator_surface/2` macro + `/theme` route; macro doc to update (D-08).
- `lib/threadline/operator_surface/ui.ex` — internal component idioms (`button`, `radio`, `field_group`, `tabs`, `segmented_control`); home of the new `pager` and possibly `page_header`.
- `lib/threadline/operator_surface/style.ex` — nav active state (~620–660), page-header (~905–930), `tl-transaction__breadcrumbs` (~2261), topbar/shell-nav sticky (~429–586), anchor `scroll-margin` (~2453), `dvh` precedent (~2974), media queries (~3546–3619), reduced-motion (~3849).
- `lib/threadline/query.ex` — `timeline_page/2` keyset engine + `actor_history_page` bidirectional reference (read-only verify; D-15).
- `lib/threadline/operator_surface/live/{timeline,transaction,row_history,actor,coverage,evidence,export_status,retention_history,policy_redaction,start}_live.ex` — the 11 pages consuming `page_header`/breadcrumbs/pager.
- `test/threadline/operator_surface/style_contract_test.exs` — the `theme-toggle` ban to lift + replace with a CSP guard (~29, 996–1009, 1113).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`surface_header.ex`** — already renders the shell (topbar + drawer + nav_link active state + a (broken) theme picker + a (CSP-violating) mobile toggle). This phase fixes/extends it rather than rebuilding.
- **`Threadline.Query.timeline_page/2`** — production-correct keyset pagination; `actor_history_page` proves the bidirectional (flip-order-then-reverse-in-Elixir) pattern to reuse for "Newer".
- **`ui.ex` idioms** — `attr`/`slot` function components, `tl-*` BEM classes, `tl-button` variants (`secondary`/`ghost`/`compact`), `tl-status` (`role="status" aria-live="polite"`), native `<details>` already used elsewhere (e.g. policy rows) — the new pager, page_header, and `<details>` nav all follow these.
- **Theme backend (Phase 172)** — `ThemeController` + cookie/session + `Auth.on_mount` + `data-tl-theme` is complete and correct; no FOUC, server-side resolution.

### Established Patterns
- **Zero new runtime deps / inline CSS / no JS lib / CSP-proof** — the dominant constraint; it is *why* the existing `onchange`/`onclick` handlers are defects, not stylistic choices.
- **No public component API (v1.31 freeze)** — every new component (`pager`, `page_header`, breadcrumb) is an internal function component.
- **4-signal non-color active state** — nav already pairs accent-soft fill + accent border + inset ring + `font-weight` + `aria-current`; reuse this as the standard for the picker and breadcrumbs (WCAG 1.4.1).
- **Capped count, never `COUNT(*)`** — the `10_001` cap → "10,000+" pattern; do not let an exact deep total sneak back in.

### Integration Points
- New `page_header`/breadcrumb assign threaded through each LiveView `handle_params`.
- New `pager` consumes the existing `next-page`/`prev-page` events + cursor assigns on Timeline (and Actor); range caption reuses `shown_count`/`match_count`.
- CSP-hardening touches `surface_header.ex` (3 handlers) + the layout `<main>` (tabindex).

</code_context>

<specifics>
## Specific Ideas

- All four decisions form ONE coherent native-HTML, zero-JS, CSP-proof design language: a theme `<form>`, location-based breadcrumbs, plain `<button phx-click>`/link pager, and a native `<details>` drawer — no JS widgets, no public API, dual non-color indicators throughout, looks correct in dark/light/system with no hover/focus weirdness.
- Brand voice for all new microcopy: plainspoken, sentence case, active voice, no exclamation marks; distinguish *audit history* from *db activity*; breadcrumb/landmark labels use conventional words ("Breadcrumb", "Older"/"Newer") not cute ones ("Investigation path").
- The phase's quiet headline is **CSP hardening**: after 175 the operator shell has zero inline event handlers and the runtime theme picker actually works under a strict adopter CSP.

</specifics>

<deferred>
## Deferred Ideas

- **Data-display / table / timeline / KV rendering polish** → Phase 176 (DATA-01..05).
- **Microcopy & IA sweep (full brand-voice pass, banned vocabulary, GOV.UK IA)** → Phase 177.
- **Per-page & flow stress (happy/empty/loading/error/permission-denied × dark/light/system × 320–1440 × keyboard × reduced-motion × LiveView reconnect)** → Phase 178.
- **Accessibility verification & adversarial closeout (axe + manual SR/keyboard, expanded Playwright/screenshot guards)** → Phase 180.

### Reviewed Todos (not folded)
- **Transaction-page content left-pushed at desktop widths (theme-independent layout bug)** — reviewed; it's a data/page-layout bug better addressed in Phase 176/178's per-page work, not the shell/nav scope here. Noted, not folded.

</deferred>

---

*Phase: 175-Navigation, app shell & runtime theme picker*
*Context gathered: 2026-06-17*
