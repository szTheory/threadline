---
phase: 175
slug: navigation-app-shell-runtime-theme-picker
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-17
---

# Phase 175 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `175-RESEARCH.md` § Validation Architecture (codebase-grounded, HIGH confidence).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir stdlib) + `Phoenix.LiveViewTest` |
| **Config file** | `test/test_helper.exs`; aliases in `mix.exs` (`verify.test`, `ci.all`) |
| **Quick run command** | `mix test test/threadline/operator_surface/style_contract_test.exs` |
| **Full suite command** | `mix verify.test` (== `mix test`); full gate `mix ci.all` |
| **Estimated runtime** | ~25–60 seconds (full ExUnit); `ci.all` longer (adds Playwright `verify.example_browser`) |

---

## Sampling Rate

- **After every task commit:** Run the relevant contract/LiveView test file + `mix verify.format`
- **After every plan wave:** Run `mix verify.test` (full ExUnit) + `mix verify.credo`
- **Before `/gsd:verify-work`:** `mix ci.all` green (includes Playwright `verify.example_browser`)
- **Max feedback latency:** ~60 seconds (single contract file is ~2s)

---

## Per-Task Verification Map

| Req ID | Behavior | Test Type | Automated Command | File Exists |
|--------|----------|-----------|-------------------|-------------|
| NAV-03 | Shell source has no `onclick=`/`onchange=`/`on*=` inline handlers | contract (source string) | `mix test test/threadline/operator_surface/surface_header_csp_test.exs` | ❌ W0 |
| NAV-03 | Theme form posts to `/theme` and carries `_csrf_token` | contract (source string) | surface_header_csp_test | ❌ W0 |
| NAV-03 | `theme-toggle` ban removed (3 sites) + style contract still green | contract | `mix test test/threadline/operator_surface/style_contract_test.exs` | ✅ edit |
| NAV-03 | Picker active state visible & non-color (`:has(:checked)` rule present in `style.ex`) | contract (source string) | style_contract_test | ✅ add assertion |
| NAV-01 | Exactly one `<h1>` per LiveView page | LiveView render | `mix test test/threadline/operator_surface/page_header_test.exs` | ❌ W0 |
| NAV-01 | Breadcrumb landmark is `<nav aria-label="Breadcrumb">` on drill-down pages; absent on flat pages | LiveView render | `mix test test/threadline/operator_surface/breadcrumb_test.exs` | ❌ W0 |
| NAV-01 | `aria-current="page"` on nav link only, never on breadcrumb current segment | LiveView render | breadcrumb_test | ❌ W0 |
| NAV-02 | Pager hides at zero results; disabled (not absent) boundary control on a single full page; range caption present | LiveView render | `mix test test/threadline/operator_surface/pager_test.exs` | ❌ W0 |
| NAV-02 | Range caption container has `role="status" aria-live="polite"`; copy = "Showing N of 10,000+ matching changes" when capped | LiveView render | pager_test | ❌ W0 |
| NAV-02 | `match_count >= 10_001` renders "10,000+" (no exact deep total) | LiveView render | pager_test (reuse `format_count` path) | ✅ extend |
| NAV-04 | Mobile nav uses native `<details>`; CSS keys on `[open]` not `:checked`/`.--open` | contract (source string) | style_contract_test | ✅ add assertion |
| NAV-04 | Every page's `<main id="tl-main">` has `tabindex="-1"` (skip-link target) | LiveView render | `mix test test/threadline/operator_surface/skip_link_test.exs` | ❌ W0 |
| NAV-04 | `scroll-padding-top` + `overscroll-behavior: contain` + `100svh` present in `style.ex` | contract (source string) | style_contract_test | ✅ add assertions |
| D-08 | Router macro doc no longer claims "no runtime theme toggle" | contract (source string) | router/doc-contract test | verify existing |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline/operator_surface/surface_header_csp_test.exs` — NAV-03 (no inline handlers; form posts `/theme` + CSRF) and NAV-04 (no `onclick` on nav/skip)
- [ ] `test/threadline/operator_surface/page_header_test.exs` — NAV-01 (one `<h1>` per page)
- [ ] `test/threadline/operator_surface/breadcrumb_test.exs` — NAV-01 (D-12/D-13 trails, landmark label, single `aria-current`)
- [ ] `test/threadline/operator_surface/pager_test.exs` — NAV-02 (hide-at-zero, disable-not-hide, range caption, `role=status`, "10,000+")
- [ ] `test/threadline/operator_surface/skip_link_test.exs` — NAV-04 (all 11 `<main>` have `tabindex="-1"`)
- [ ] Edits to existing `style_contract_test.exs`: remove 3 `theme-toggle` bans (lines ~29, ~1009, anti-pattern list-item ~1113); add `[open]`, `:has(:checked)`, `scroll-padding-top`, `overscroll-behavior`, `100svh` assertions

*Note: the conditional composite-index DB test is NOT required — Q1 resolved to defer the index as capture-layer perf debt (capture layer stays untouched in 175).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Theme picker renders correctly and persists choice across full-page reload in dark/light/system | NAV-03 | Visual + cookie round-trip across themes; automated render covers markup but not the perceptual "unmistakable in all 3 modes" bar | Load `/audit`, open nav drawer, pick each of System/Light/Dark, click "Apply theme", confirm reload reflects choice and persists on next navigation |
| Active/current nav + selected radio are unmistakable in dark AND light (non-color cues visible) | NAV-01 | WCAG 1.4.1 perceptual judgment across themes | Eyeball nav current item + checked radio in all 3 themes; confirm border/ring/weight cues, not color alone |
| Mobile nav `<details>` has no nested-scroll trap; sticky never covers content (320–1440) | NAV-04 | Touch/scroll behavior across viewport widths | Resize to 320/768/1440; toggle nav, scroll, confirm no scroll trap and anchored content not covered by sticky topbar |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
