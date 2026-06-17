---
phase: 175-navigation-app-shell-runtime-theme-picker
verified: 2026-06-17T19:32:50Z
status: human_needed
score: 16/16 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Run the Playwright browser harness: mix ci.all (includes verify.example_browser + verify.example_browser_light)."
    expected: "Operator shell renders on-brand in both dark and light; theme picker switches dark/light/system with no FOUC and persists across reload; mobile nav opens/closes via native <details> with no nested-scroll trap; sticky topbar never covers anchored content; pager controls Older/Newer behave (disable at boundary, hide at zero). All browser specs green."
    why_human: "Playwright is a separate browser harness that cannot be executed in this verification environment. Visual on-brand consistency, real FOUC behavior on reload, real overscroll/sticky-cover behavior, and dark/light rendering are visual/runtime properties grep and ExUnit cannot confirm."
---

# Phase 175: Navigation, App Shell & Runtime Theme Picker Verification Report

**Phase Goal:** Bring the app shell and navigation to a consistent on-brand structure and ship the in-product dark/light/system theme picker (THEME-TOGGLE-01).
**Verified:** 2026-06-17T19:32:50Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #   | Truth (merged ROADMAP SC + PLAN must_haves) | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Operator shell carries ZERO inline `on*=` handlers (CSP headline) | ✓ VERIFIED | `surface_header.ex`: no onclick/onchange/etc. The only `on…=` substring match is `aria-cONtrols=` (false positive; not preceded by whitespace, so the CSP guard regex `\son[a-z]+=` excludes it). CSP guard test passes. |
| 2 | Theme picker = native `<form>` POST `/theme` + `_csrf_token`, visible radios, "Apply theme" button | ✓ VERIFIED | `surface_header.ex:88-105` — `<form action={…/theme} method="post">`, hidden `_csrf_token` (L89), `<fieldset>`+`<legend>Theme</legend>`, 3 visible `<input type="radio" name="theme">` (system/light/dark, L93/97/101), `<button type="submit">Apply theme</button>` (L105). No `tl-sr-only`, no dead `tl-segmented__item--active`. |
| 3 | Selected radio shows non-color active cue via `:has(:checked)` | ✓ VERIFIED | `style.ex:612` `.tl-theme-picker__option:has(:checked)` — `box-shadow: inset 2px 0 0` (border bar) + `font-weight: var(--tl-weight-medium)` (weight) as the non-color signals, plus accent-soft background. Uses existing tokens only. |
| 4 | Theme resolved server-side (cookie+plug), zero JS, no FOUC | ✓ VERIFIED | `data-tl-theme={@threadline_theme}` applied server-side on each LiveView root (`timeline_live:324`, etc.); CSS `.threadline-ui[data-tl-theme="…"]` selectors in style.ex. Router doc (L55-56): "adds no JavaScript and no local storage." No JS. (Real no-FOUC confirmation deferred to browser harness.) |
| 5 | `theme-toggle` ban lifted + positive CSP guard test present | ✓ VERIFIED | `style_contract_test.exs` has NO `theme-toggle` reference; positive asserts for `:has(:checked)`, `.tl-shell-nav[open]`, `scroll-padding-top`, `overscroll-behavior: contain`, `100svh`; refutes for old `.tl-shell-nav__control:checked`/`tl-shell-nav--open`. Dedicated `surface_header_csp_test.exs` enforces the inline-handler ban. |
| 6 | Choice persists per operator | ✓ VERIFIED | Cookie+plug backend (D-09, untouched); `@threadline_theme` reflected server-side. Persistence-across-reload routed to browser harness. |
| 7 | `page_header/1` exists in ui.ex; exactly one `<h1>` per rendered page | ✓ VERIFIED | `ui.ex:202 def page_header` (`@doc false`), single `<h1>` (`tl-page__title` heading / `tl-home__headline` display, variant L184). Adopted via `<UI.page_header>` on 9 LiveViews. Timeline command toolbar + Coverage command-center state keep a bespoke single `<h1>` (documented deviation, summary item 47); each rendered state still emits exactly one `<h1>` (coverage branches L112/132/153 are mutually exclusive if/else). |
| 8 | Breadcrumbs only on the 3 drill-down pages; `<nav aria-label="Breadcrumb">`, root "Timeline", single `aria-current` on nav link only | ✓ VERIFIED | `ui.ex:225` `<nav aria-label="Breadcrumb">`, final segment plain `<span>` (no aria-current). Threaded into transaction/actor/row_history (`breadcrumbs={[…]}`). `aria-label="Investigation path"` fully removed from live/. Drill-down pages set `current={nil}` → only the breadcrumb contributes wayfinding; breadcrumb_test asserts aria_current_count == 1. |
| 9 | `pager/1` exists; reuses next/prev events; hide-at-zero; disable-not-hide; `role="status"` caption; capped "10,000+" | ✓ VERIFIED | `ui.ex:270 def pager`. `<nav :if={@match_count > 0}>` (hide-at-zero); Newer/Older `<button phx-click=… disabled={!@has_…}>` (disable-not-hide); `:if={@newer_event}` omits Newer on next-only timeline; caption `<span role="status" aria-live="polite">` "Showing N of … matching changes"; `pager_total/1` returns "10,000+" at ≥10_001. Adopted on timeline_live:421 (next-only) and actor_live:185 (bidirectional). |
| 10 | Exports + Retention show honest cap caption; Coverage + Redaction show no pager | ✓ VERIFIED | `export_status_live:262` "Showing latest 100 export jobs"; `retention_history_live:165` "Showing latest 40 retention runs". No `<UI.pager` on coverage/redaction. |
| 11 | Mobile nav = native `<details>` keyed on `[open]`; no nested-scroll trap; sticky never covers content | ✓ VERIFIED | `surface_header.ex:57-58` `<details class="tl-shell-nav">` + `<summary class="tl-shell-nav__toggle">`, no `aria-expanded` on summary, no `tl-shell-nav__control`. `style.ex` re-points all selectors to `.tl-shell-nav[open]` (L552/564/3628); `scroll-padding-top` (L432/3605), `overscroll-behavior: contain` (L434/3027), `min-height: 100svh` (L429). |
| 12 | Skip link is scriptless native fragment nav | ✓ VERIFIED | `surface_header.ex:31` `<a class="tl-skip-link" href="#tl-main">` — onclick removed; all `<main id="tl-main">` retain `tabindex="-1"` (skip_link_test green regression lock). |
| 13 | Router macro doc updated (no longer claims "no runtime theme toggle") | ✓ VERIFIED | `router.ex:55-56`: runtime theme picker (cookie+plug, server-side); no JS, no local storage. |
| 14 | Capture layer UNTOUCHED; D-15 deferred as perf debt with only a doc note | ✓ VERIFIED | `git diff --quiet 5e40723 HEAD -- lib/threadline/capture/` → clean. `migration.ex:57` single-col `(captured_at)` index unchanged; no composite. `query.ex:350-357` documents deferred `(captured_at, id)` composite-index perf debt; query.ex diff = +12 lines (doc only), no migration added. |
| 15 | Five Wave-0 NAV test files exist, compile, and gate the implementation | ✓ VERIFIED | `surface_header_csp_test.exs`, `page_header_test.exs`, `breadcrumb_test.exs`, `pager_test.exs`, `skip_link_test.exs` all present; 20 tests green. |
| 16 | Full operator-surface suite green; compile clean | ✓ VERIFIED | `mix test test/threadline/operator_surface/` → 497 tests, 0 failures. `mix compile --warnings-as-errors` clean. `mix format --check-formatted` clean. |

**Score:** 16/16 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/threadline/operator_surface/components/surface_header.ex` | Zero-handler shell, native form picker + Apply button, `<details>` nav, scriptless skip link | ✓ VERIFIED | All present; CSP guard green |
| `lib/threadline/operator_surface/style.ex` | `:has(:checked)`, `[open]` re-point, scroll-padding-top, overscroll contain, 100svh | ✓ VERIFIED | All present; old `:checked`/`--open` selectors absent |
| `lib/threadline/operator_surface/router.ex` | Updated macro doc | ✓ VERIFIED | L55-56 corrected |
| `lib/threadline/operator_surface/ui.ex` | `page_header/1` + `breadcrumb_trail/1` + `pager/1` | ✓ VERIFIED | All `@doc false`, substantive, wired |
| `lib/threadline/query.ex` | D-15 perf-debt doc note, no migration | ✓ VERIFIED | +12 lines doc only |
| 5 NAV test files | RED→GREEN scaffolds | ✓ VERIFIED | Exist, 20 tests green |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| surface_header theme form | `/theme` (ThemeController) | native POST + `_csrf_token` | ✓ WIRED | L88-89 |
| `.tl-shell-nav[open]` (style) | `<details class="tl-shell-nav">` (header) | `[open]` attr selector | ✓ WIRED | style L552/564 ↔ header L57 |
| skip link `#tl-main` | `<main id=tl-main tabindex=-1>` | native fragment nav | ✓ WIRED | header L31 + all pages tabindex=-1 |
| page_header breadcrumbs | `<nav aria-label="Breadcrumb">` | breadcrumbs assign | ✓ WIRED | ui.ex L225, threaded in 3 pages |
| pager Older/Newer | timeline/actor next-page/prev-page | `phx-click` | ✓ WIRED | timeline:421, actor:185 reuse existing events |
| pager caption | format_count/match_count | role=status live region | ✓ WIRED | ui.ex L287-288, capped path |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| NAV-01 | 175-01, 175-03 | Consistent on-brand shell/nav; unmistakable active/current | ✓ SATISFIED | page_header, breadcrumb, single aria-current (truths 7-8, 11-13) |
| NAV-02 | 175-01, 175-04 | Pagination clear; de-emphasize/hide at one page/zero | ✓ SATISFIED | pager hide-at-zero/disable-not-hide/cap caption (truths 9-10) |
| NAV-03 (THEME-TOGGLE-01) | 175-01, 175-02 | In-product dark/light/system picker, cookie+plug, zero JS, no FOUC, ban lifted, persists | ✓ SATISFIED | truths 2-6, 13; FOUC/persistence runtime → human verify |
| NAV-04 | 175-01, 175-02 | Mobile nav no nested-scroll trap; sticky never covers content | ✓ SATISFIED | truths 11-12; runtime overscroll/sticky → human verify |

No orphaned requirements: REQUIREMENTS.md maps NAV-01..04 to Phase 175 and all four appear in plan `requirements` frontmatter.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Operator-surface suite green | `mix test test/threadline/operator_surface/` | 497 tests, 0 failures | ✓ PASS |
| 5 NAV test files green | `mix test …5 NAV files` | 20 tests, 0 failures | ✓ PASS |
| Compile clean | `mix compile --warnings-as-errors` | clean | ✓ PASS |
| Format clean | `mix format --check-formatted` | clean | ✓ PASS |
| Capture layer untouched | `git diff --quiet 5e40723 HEAD -- lib/threadline/capture/` | clean (exit 0) | ✓ PASS |
| Browser/visual + FOUC + sticky + overscroll | `mix ci.all` (Playwright `verify.example_browser`) | not runnable here | ? SKIP → human |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| (none) | — | No TBD/FIXME/XXX in any phase-modified lib file | — | — |

### Human Verification Required

#### 1. Playwright browser harness (visual + runtime behavior)

**Test:** `mix ci.all` (runs `verify.example_browser` + `verify.example_browser_light`).
**Expected:** Shell on-brand in dark AND light; theme picker switches dark/light/system with no FOUC and persists across full-page reload; mobile nav opens/closes via native `<details>` with no nested-scroll trap; sticky topbar never covers anchored content; pager Older/Newer disable at boundaries and hide at zero.
**Why human:** Playwright is a separate browser harness not runnable in this verification environment. Visual on-brand consistency, real FOUC on reload, real overscroll/sticky-cover behavior, and dark/light rendering are visual/runtime properties that grep and ExUnit cannot confirm.

### Gaps Summary

No code-level gaps. All 16 must-haves are verified in the codebase: the CSP headline (zero inline handlers) holds, the theme picker is a native zero-JS form with a `:has(:checked)` non-color cue and ban lifted, page_header/breadcrumb/pager components exist and are wired, mobile nav is native `<details>` keyed on `[open]` with hardened sticky/scroll, the capture layer is byte-clean with D-15 documented as deferred perf debt, and the full operator-surface suite (497 tests) is green.

One documented deviation (175-03 SUMMARY item 47): the Timeline command toolbar and Coverage command-center state retain a bespoke single `<h1>` rather than routing through `page_header`, because they are specialized command structures pinned by `timeline_live_test`. The NAV-01 success-criterion intent ("exactly one `<h1>` per page") is preserved — each rendered state emits exactly one `<h1>`. This is acceptable and does not reduce scope.

Status is `human_needed` solely because the Playwright browser harness (visual, FOUC, sticky/overscroll runtime behavior) cannot be executed in this environment, per the phase verification guidance to list it as a manual item rather than fail the phase.

---

_Verified: 2026-06-17T19:32:50Z_
_Verifier: Claude (gsd-verifier)_
