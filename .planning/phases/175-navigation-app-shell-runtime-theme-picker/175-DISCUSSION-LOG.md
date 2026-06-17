# Phase 175: Navigation, app shell & runtime theme picker - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-17
**Phase:** 175-Navigation, app shell & runtime theme picker
**Areas discussed:** Theme picker UI, Active-location signaling, Pagination pattern, Mobile nav mechanism
**Mode:** advisor (minimal_decisive); two research passes — a first decisive sweep, then a deeper multi-lens sweep (SWE/Elixir-Phoenix idiom, ecosystem lessons, UI/UX/creative direction, user psychology/JTBD, accessibility) reading `prompts/`, `brandbook/`, and the live codebase.

---

## Theme picker UI

| Option | Description | Selected |
|--------|-------------|----------|
| fieldset+legend + 3 visible native radios + explicit submit button, nav drawer | Canonical AA grouping; all 3 lanes visible; native radio dot = non-color current cue; zero-JS form POST | ✓ |
| Segmented control = 3 submit buttons | Compact, on-brand, no JS; but needs hand-authored group label + aria-current + non-color cue | |
| Native `<select>` + submit | Most compact; but hides options until opened, weaker discoverability | |
| Single cycle button | Smallest; but hides choice set + "system", hostile to SR | |
| Persistent topbar / dedicated settings page placement | Always-visible vs zero-clutter; rejected — topbar too dense at 320px, settings page over-engineered for one toggle | |

**User's choice:** Decisive recommendation accepted (research-then-recommend, minimal_decisive).
**Notes:** Deep research found the picker ALREADY EXISTS in `surface_header.ex` but is broken — every radio uses `onchange="this.form.submit()"` (inline JS, CSP-violating, silently dead under strict CSP) and radios are visually hidden with color-only active state (WCAG 1.4.1 risk). Decision became *fix the existing control*: remove `onchange`, expose radios, add explicit "Apply theme" submit, add non-color `:has(:checked)` cue, keep existing CSRF token, lift the `theme-toggle` ban and replace with a positive CSP guard, update the router macro doc.

## Active-location signaling

| Option | Description | Selected |
|--------|-------------|----------|
| Nav active-highlight + H1 only (no breadcrumbs) | Simplest; but loses the drill-down depth signal | |
| Nav + H1 everywhere + breadcrumbs only on the drill-down chain (Pattern B) | GOV.UK/NN/g/Polaris rule; breadcrumb earns its place only where real hierarchy exists | ✓ |
| Breadcrumbs on every page | Uniform; but fabricates hierarchy on flat sibling pages, duplicates nav, adds noise | |

**User's choice:** Pattern B accepted.
**Notes:** Nav active-state already solid (4 non-color signals + aria-current) — keep it. Gaps found: H1 treatment fragmented across 3+ conventions → collapse into one `page_header` component (single H1/page); breadcrumbs exist only on transaction+actor, row-history missing → extend to the 4 drill-down pages with domain-mapped trails; rename `aria-label="Investigation path"` → `"Breadcrumb"`; root link = Timeline not Home; final segment plain text; avoid double `aria-current`. Add a single-H1 / breadcrumb-presence regression test (sibling to the phase-174 formless-page guard).

## Pagination pattern

| Option | Description | Selected |
|--------|-------------|----------|
| Keyset "Older/Newer" Prev-Next pager + range caption | O(1) at depth, stable boundaries on append-heavy log, mobile-efficient, no COUNT(*); engine already built | ✓ |
| Offset numbered pages (1 2 3 … 47) | Familiar, jump-to-page; but O(n) deep scans, COUNT(*) cost, boundaries reshuffle on live data, crowds 320px | |
| Load-more / infinite scroll only (current) | Lowest UI cost; but a11y debt — no controls, no "end" signal for keyboard/SR | |

**User's choice:** Keyset pager + keep infinite scroll (hybrid) accepted.
**Notes:** Deep research found the data layer is ALREADY correct keyset (`Query.timeline_page/2`, `(captured_at, id)` tiebreaker, capped count, Actor already bidirectional). So the gray area is the accessible UI, not the engine. Decision: keep infinite scroll, ADD a de-emphasized reusable "Newer/range-caption/Older" `ui.ex` pager (fixes the infinite-scroll a11y gap); hide pager only at zero results, disable (not hide) at boundaries; filters in URL, cursor in assigns; Exports/Retention get honest cap captions, Coverage/Redaction nothing; verify the `(captured_at DESC, id DESC)` index.

## Mobile nav mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Native `<details>`/`<summary>` disclosure | True zero-JS, CSP-proof, native button role + keyboard + open state; minor AT state-announcement weakness (most benign failure) | ✓ |
| Pure-CSS checkbox `:checked`/`:has()` drawer | Zero-JS; but checkbox-as-disclosure is an ARIA anti-pattern, invalid aria-expanded, no programmatic state | |
| Keep JS `<button onclick>` (current) | Correct aria-expanded when JS runs; but inline onclick violates CSP + not zero-JS | |

**User's choice:** Native `<details>`/`<summary>` accepted.
**Notes:** Resolves aria-expanded-vs-CSP explicitly in favor of CSP/zero-JS (the only correct-aria-expanded option violates two hard invariants). Plus the scroll/sticky technique set (`scroll-padding-top`, `overscroll-behavior: contain`, `svh`/`dvh`, reduced-motion already covered) and the skip-link `onclick` fix via `tabindex="-1"` on `<main>`. Surfaced a cross-cutting CSP-hardening thread (theme-picker onchange + nav-toggle onclick + skip-link onclick → zero inline handlers after 175).

## Claude's Discretion

- Exact token names / `page_header` slot API / breadcrumb separator glyph — match existing `ui.ex`/`style.ex` idioms.
- Whether the pager lives as `ui.ex pager/1` or colocated.

## Deferred Ideas

- Data-display/table/timeline polish → Phase 176.
- Microcopy & IA sweep → Phase 177.
- Per-page & flow stress matrix → Phase 178.
- Accessibility verification & adversarial closeout → Phase 180.
- Transaction-page desktop left-push layout bug → reviewed, belongs in 176/178 per-page work, not folded.
