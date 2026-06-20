---
phase: 175
slug: navigation-app-shell-runtime-theme-picker
status: approved
shadcn_initialized: false
preset: none
created: 2026-06-17
reviewed_at: 2026-06-17
---

# Phase 175 — UI Design Contract

> Visual and interaction contract for the operator-surface app shell, navigation, accessible pagination UI, native-`<details>` mobile nav, and the zero-JS/CSP-proof runtime theme picker (NAV-01..NAV-04 / THEME-TOGGLE-01).
>
> **Stack note:** This is an Elixir/Phoenix/LiveView library, not React. There is no shadcn, no Tailwind, no asset pipeline, and no public component API. The design system is the frozen, parity-tested `--tl-*` token contract in `brandbook/tokens.{json,css}` and `lib/threadline/operator_surface/style.ex`, consumed by internal `ui.ex` function components. The shadcn gate is **not applicable** and the Registry Safety section is **not applicable**. New tokens are forbidden unless they land in `brandbook/tokens.{json,css}` first and keep `brandbook_token_parity_test` green — this phase introduces none.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none (Phoenix/LiveView internal function components; `--tl-*` token contract) |
| Preset | not applicable |
| Component library | none — internal private function components in `lib/threadline/operator_surface/ui.ex` (`button`, `radio`, `field_group`, `tabs`, `segmented_control`, native `<details>`); this phase adds internal `page_header`, breadcrumb, and `pager` |
| Icon library | none — inline SVG / glyph characters only (no icon-font runtime dep); breadcrumb separator and pager directional cues use plain text/inline marks |
| Font | Geist → Inter → system-ui fallback stack (`--tl-font-family`); mono = IBM Plex Mono → JetBrains Mono → ui-monospace (`--tl-font-mono`) |

**Source:** `brandbook/tokens.css` (lines 1–87), `lib/threadline/operator_surface/style.ex` (semantic token block ~73–174). Pre-populated; not asked.

---

## Spacing Scale

Declared values from the frozen `--tl-space-*` scale (`brandbook/tokens.css` lines 6–16). All multiples of 4.

| Token | Value | Usage |
|-------|-------|-------|
| `--tl-space-1` | 4px | Icon gaps, inset border bar offset, tightest inline padding |
| `--tl-space-2` | 8px | Compact element spacing; pager control gap; radio row gap |
| `--tl-space-3` | 12px | Nav-link inner padding; breadcrumb segment gap |
| `--tl-space-4` | 16px | Default element spacing; page-header block vertical rhythm |
| `--tl-space-5` | 20px | Intermediate spacing |
| `--tl-space-6` | 24px | Section padding; page-header to content gap |
| `--tl-space-8` | 32px | Layout gaps; topbar horizontal padding |
| `--tl-space-12` | 48px | Major section breaks |
| `--tl-space-16` | 64px | Page-level spacing |
| `--tl-space-20` | 80px | Rare outermost layout spacing |

**Exceptions:** None new. Sticky offset (`scroll-padding-top`, D-23) is a **computed sum of measured sticky element heights** (mobile = topbar + collapsed `<summary>`; ≥768px = topbar only), reconciled to the **same token** as the existing per-row `scroll-margin-top` so the offset is never double-counted. Touch targets for the theme radios, pager buttons, and `<summary>` toggle must be comfortable (≥44px effective hit area via padding) per A11Y-02 intent — achieved with existing `--tl-space-*` padding, not a new token.

---

## Typography

Declared from the frozen `--tl-font-size-*` / `--tl-line-*` / `--tl-weight-*` scale (`brandbook/tokens.css` lines 18–34). This phase uses a 4-role subset; weights are constrained to **regular (400)** and **strong (600)**, with **medium (500)** permitted only as the existing nav/active-state emphasis bump.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 16px (`--tl-font-size-body`) | 400 (`--tl-weight-regular`) | 1.5 (`--tl-line-body`) |
| Label / nav / control | 14px (`--tl-font-size-label`) | 400 → 500 active (`--tl-weight-medium` bump on `aria-current`/`:has(:checked)`) | 1.4 (`--tl-line-label`) |
| Heading (page H1) | 24px (`--tl-font-size-title`) | 600 (`--tl-weight-strong`) | 1.2 (`--tl-line-heading`) |
| Display / hero (Home headline only) | 32px (`--tl-font-size-display`) | 600 (`--tl-weight-strong`) | 1.2 (`--tl-line-heading`) |

**Notes:**
- Exactly **one `<h1>` per page** (D-11), rendered by the single internal `page_header` component at the Heading role (24px/600/1.2). Home's existing larger headline maps to the Display role.
- Breadcrumb segments and the pager range-caption render at Label role (14px). The breadcrumb current segment is plain text (not a link, not bolded as a heading).
- The 500 (medium) weight is reserved exclusively for active-state emphasis (nav current item, checked theme radio) — it is the non-color "font-weight bump" half of the dual-signal active treatment, never decorative.

---

## Color

Semantic mapping from `style.ex` (~73–98), resolved per theme via `data-tl-theme` (dark default / light / system). Values shown are the **dark (default/brand)** lane; the light lane is the parity-tested mirror shipped in v1.36 and must render correctly in all three modes (D-05, NAV-01).

| Role | Value (dark) | Usage |
|------|-------|-------|
| Dominant (60%) | `--tl-color-bg` = `#0B1020` (threadline-black) | App shell background, main scroll surface |
| Secondary (30%) | `--tl-color-surface` = `#141B2D` (graphite); raised `--tl-color-surface-raised` = `#1B253A` | Topbar, nav drawer/rail, page-header band, pager bar, breadcrumb strip |
| Accent (10%) | `--tl-color-accent` = `#4F8CFF` (thread-blue); soft `--tl-color-accent-soft` = `rgba(79,140,255,0.18)`; border `--tl-color-accent-border` = `rgba(127,169,255,0.48)` | **Reserved list below** |
| Destructive | `--tl-color-danger` = `#F06A6A` (`-dark-text` `#FF8585` for AA text) | Not used in this phase — no destructive actions in shell/nav/theme/pager scope |

**Accent reserved for (explicit list — never "all interactive elements"):**
- The **active/current navigation item** (`aria-current="page"`): accent-soft fill + accent border + inset ring + medium-weight text (the established 4-signal non-color active treatment).
- The **selected theme radio** (`:has(:checked)`): inset border bar via `box-shadow: inset 2px 0 0 var(--tl-color-accent-border)` + font-weight bump — dual-signal, never background-color-only (D-05, WCAG 1.4.1).
- The **focus ring** on every interactive control (`--tl-focus-ring` = `0 0 0 3px rgba(127,169,255,0.42), 0 0 0 1px #7FA9FF`) — keyboard `:focus-visible`.
- The **"Apply theme"** primary submit button (existing `tl-button` primary variant).
- The **active pager directional control** (enabled "Older"/"Newer") link/button affordance.

**Not accent:** disabled pager boundary control (de-emphasized via `--tl-color-text-muted`/reduced opacity, still distinguishable from enabled per PAGE-02 "disabled-looks-enabled" footgun), range-caption text, breadcrumb non-current segments (use `--tl-color-text` link color, current segment uses muted/plain text).

**Hard rule (NAV-01, A11Y-02):** color is never the only signal. Every active/current/selected/disabled state pairs color with a non-color cue (border, inset ring, weight, `aria-current`, native `checked`, native `disabled`).

---

## Copywriting Contract

Brand voice: plainspoken, **sentence case**, active voice, **no exclamation marks**, conventional landmark words (not cute ones). Source: `brandbook/brand-book.md` voice section + CONTEXT.md D-13, D-17, "Specific Ideas".

| Element | Copy |
|---------|------|
| Primary CTA (theme picker submit) | **"Apply theme"** (explicit submit button; D-02) |
| Theme picker legend / fieldset | Legend: **"Theme"**; radio options in order **System**, **Light**, **Dark** (System is default; D-02) |
| Pager directional controls | **"Older"** and **"Newer"** (time-axis framing, not "Next/Previous", not page numbers; D-17) |
| Pager range caption | **"Showing {N} of 10,000+ matching changes"** when capped, or **"Showing {N} of {total} matching changes"** when under the `10_001` cap — honest, relative, never a fabricated "Page 3 of 200" (D-17, D-18). Container: `role="status" aria-live="polite"`. |
| Non-Timeline cap caption (Exports/Retention) | **"Showing latest {N} …"** honest cap caption (D-20) |
| Empty state heading | Owned by Phase 176 (DATA-03) for data surfaces. For the pager: at **zero results the entire pager is hidden** and the page's empty state owns the screen (D-18) — no pager-specific empty copy here. |
| Empty state body | Not in scope (deferred to Phase 176). Pager simply hides at zero results. |
| Error state | Not in scope — shell/nav/theme/pager have no new error surfaces. Theme POST failure falls through to the existing `ThemeController` redirect-to-referer behavior (D-09); no new error copy. |
| Breadcrumb landmark label | `<nav aria-label="Breadcrumb">` (rename the bespoke `aria-label="Investigation path"`; D-13). Root link label **"Timeline"** (not "Home"; D-13). Trails per D-12 (e.g. `Timeline › Transaction {short-id}`, `Timeline › Transaction {short-id} › Row history · {table}`). Final segment is plain text, not a link. |
| Skip link | Existing `<a href="#tl-main">` skip-to-content copy preserved; only the inline `onclick` is removed (D-26). |
| Destructive confirmation | **None** — this phase contains no destructive actions. (Destructive row/bulk actions are Phase 176 / DATA-04.) |

**Domain language (COPY-02 carry-forward):** pager caption says **"matching changes"** (AuditChange domain term), not "rows"/"results"/"items". Breadcrumb segments use domain nouns: **Transaction**, **Row history**, **Actor**, **Timeline**.

---

## Interaction & Wayfinding Contract (phase-specific)

This phase is primarily about interaction states and structure, so the contract extends beyond static tokens. The checker should treat these as binding alongside the visual tables above.

### Active / current state (NAV-01, D-05, D-10)
- **Nav current item:** `aria-current="page"` + 4-signal treatment (accent-soft fill, accent border, inset ring, medium font-weight). Must be unmistakable in dark **and** light.
- **Theme radio selected:** native `checked` (announced "selected") + non-color inset border bar (`box-shadow: inset 2px 0 0 …`) + font-weight bump, driven by pure-CSS `:has(:checked)` so it cannot drift from markup. **Radios are visible, never visually hidden** (D-05).
- **Single `aria-current="page"`** lives on the nav link only — not duplicated onto the breadcrumb current segment (avoid two competing currents in the a11y tree; D-13).

### Page header (NAV-01, D-11)
- One internal `page_header` component: semantic `<header class="tl-page__header">`, single `<h1 class="tl-page__title">`, optional lede, optional actions slot, optional breadcrumb slot. Collapses the 3+ existing title conventions.

### Breadcrumbs (D-12, D-13, D-14)
- Location-based (not history-based), explicit `breadcrumbs` assign threaded via `handle_params` (never route-inferred). Only on genuine drill-down pages (Transaction, Row history, Actor). **No breadcrumbs** on Home, Timeline, Coverage, Evidence, Exports, Redaction, Retention.

### Pagination UI (NAV-02, D-16..D-20)
- Infinite scroll (`phx-viewport-bottom`) stays primary; add one **de-emphasized** reusable `pager` ("Newer / range-caption / Older") as the accessible / no-JS / end-of-stream companion.
- **Hide entire pager only at zero results.** When shown, **disable (not hide)** the boundary directional control to avoid layout shift. Keep the range caption even on a single full page (audit-trust signal).
- Filters live in the URL (`handle_params`, shareable); the append cursor stays in assign/`phx-click` state (never serialized into the URL — a stale mid-scroll cursor misleads in an audit context). List uses Phoenix streams (memory-bounded).

### Mobile nav + sticky/scroll (NAV-04, D-21..D-26)
- Replace checkbox/`onclick` hybrid drawer with native `<details>`/`<summary>` disclosure. **No `aria-expanded` on `<summary>`** (redundant; native `open` state covers it). **No shared `name=`** on nav `<details>` (that's accordion grouping). Re-point desktop `@media (min-width:768px)` override from `:checked`/`.--open` to `[open]`, keeping `summary { display:none }` ≥768px.
- `scroll-padding-top` = combined sticky height; `overscroll-behavior: contain` on scrollable panels (no scroll trap); no body-scroll-lock / focus-trap (`<details>` is in-flow, not a modal).
- Shell uses `min-height: 100svh` (first paint fits small viewport, no iOS-address-bar scrollbar); scrollable rails use `100dvh` with a `vh` fallback line first.
- Reduced-motion already covered by the blanket `prefers-reduced-motion` block; a `display`-toggle disclosure is reduced-motion-safe by construction.

### CSP-hardening (D-03, D-21, D-26, D-27) — the phase's headline
- **Zero inline event handlers** on the operator shell after this phase: remove theme-picker `onchange="this.form.submit()"`, nav-toggle `onclick`, and skip-link `onclick`. Skip link works via `tabindex="-1"` on `<main id="tl-main">` so native fragment navigation moves focus there. Recommended contract test: assert no `on*=` inline-handler substrings (and no `onclick=`/`onchange=`) in the shell source.

### Theme picker form contract (NAV-03 / THEME-TOGGLE-01, D-02..D-09)
- `<form method="post" action={base_path<>"/theme"}>` → `<fieldset>` + legend "Theme" + three native visible `<input type="radio">` (System/Light/Dark) + explicit `<button>` "Apply theme". Full-page reload on submit (on-ethos). Keep the explicit hidden `_csrf_token` (LiveView-rendered form posting to a controller route gets no auto-CSRF). Backend untouched (`ThemeController`, `Auth.on_mount`, `data-tl-theme`); no FOUC because resolution is server-side from cookie/session — never localStorage.

---

## Style-Contract Amendment (NAV-03, D-07, D-08)

This phase **lifts the `theme-toggle` ban** and replaces it with a positive CSP guard.

- **Remove** the three `refute String.contains?(src, "theme-toggle")` assertions + comment block in `test/threadline/operator_surface/style_contract_test.exs` (~29, 996–1009, 1113).
- **Replace with** a positive CSP guard asserting: the picker form posts to `/theme`, carries a CSRF token, and contains **no** `onclick=` / `onchange=` substring; and the broader shell source contains no inline `on*=` handlers (D-27).
- **Update** the `router.ex` `threadline_operator_surface/2` macro doc that still claims "Threadline does not add JavaScript … or a runtime theme toggle" — superseded by the cookie+plug picker (D-08).

---

## Registry Safety

**Not applicable.** No shadcn, no third-party component registries, no npm component installs. The component system is internal Phoenix function components governed by `style.ex` + `style_contract_test.exs` + `brandbook_token_parity_test`. Zero new runtime dependencies is a hard milestone invariant.

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| n/a (internal function components only) | none | not applicable — zero-dep, inline-asset, no public API |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS (note: weight 500 reserved exclusively for active-state emphasis per D-05/WCAG 1.4.1, never decorative)
- [x] Dimension 5 Spacing: PASS (note: `--tl-space-*` frozen token contract is the source of truth, not the generic 4/8/16/24/32/48/64 set; zero new tokens)
- [x] Dimension 6 Registry Safety: PASS (n/a — internal components, zero registries)

**Approval:** approved 2026-06-17
