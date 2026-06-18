---
phase: 178
slug: per-page-flow-stress-pass-all-11-pages
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-18
---

# Phase 178 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `178-RESEARCH.md` § Validation Architecture. Two-tier honesty contract:
> **Tier A** (Elixir `render_component`/`rendered_to_string` DOM + CSS-source assertions) proves the **full structural cartesian**; **Tier B** (Playwright real-engine) proves a **representative high-signal sample**. Never pixel-diff (baseline-free, deterministic).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Tier A — library `mix test`) + Playwright (Tier B — `examples/threadline_phoenix/e2e`) |
| **Config file** | `test/test_helper.exs` (ExUnit); `examples/threadline_phoenix/playwright.config.ts` (dark / `desktop-chromium-light` / reduced-motion lanes) |
| **Quick run command** | `mix test test/threadline/operator_surface/` |
| **Full suite command** | `mix ci.all` (incl. `mix verify.test`); Tier B via `mix verify.example_browser` |
| **Estimated runtime** | Tier A ~30–60s; Tier B ~2–4 min |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/threadline/operator_surface/` (relevant contract/ledger/stress files)
- **After every plan wave:** Run `mix verify.test` (+ `mix verify.example_browser` when Tier B specs change)
- **Before `/gsd-verify-work`:** Full `mix ci.all` green + Tier B sample green
- **Max feedback latency:** ~60 seconds (Tier A)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| {populated by planner} | — | — | PAGE-01 | — | per-page path stories render + carry `data-state`, ledger ratchet upward-only | Tier A unit | `mix test test/threadline/operator_surface/stress_ledger_test.exs` | ⬜ W0 | ⬜ pending |
| {populated by planner} | — | — | PAGE-02 | — | 11 footgun detectors fail on today's surface, then green after fix | Tier A + Tier B | `mix test test/threadline/operator_surface/` | ⬜ W0 | ⬜ pending |
| {populated by planner} | — | — | PAGE-03 | — | `.tl-container` (and latent `.tl-home`) carry `justify-self: center`; centered bbox at 1024/1440 | Tier A + Tier B geometry | `mix test test/threadline/operator_surface/style_contract_test.exs` | ⬜ W0 | ⬜ pending |
| {populated by planner} | — | — | SEED-005 | — | real socket-drop shows `.tl-reconnect-banner`; `[data-tl-mutating]` computes `opacity:.55`/`pointer-events:none` | Tier B real-LiveView | `mix verify.example_browser` | ⬜ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Guard-first failing detectors for the 11 footgun classes (Tier A CSS-source/DOM + Tier B geometry/focus) — must fail on today's surface before fix (D-05)
- [ ] Reserved page stories (`page.<x>.reserved`) and `footgun.transaction-page-left-push-desktop` converted to fixture-backed RED targets in the ledger
- [ ] Real socket-drop Tier B spec scaffold (`window.liveSocket.disconnect()` ladder) replacing the 177 inject-probe

*Existing infrastructure (contrast_ratio/2 WCAG engine, z-order guard, Playwright cursor/disabled/Esc/overflow/focus helpers, light/system lane, ledger ratchet) covers the bulk — detectors extend, they do not reinvent.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Sub-pixel optical balance; "focus landed somewhere *sensible*" beyond "inside the overlay" | PAGE-02 | Not mechanically assertable | OPTIONAL, NON-BLOCKING spot-check note only — not a UAT gate (0-human-UAT goal, D-07) |

*Residual manual ≈ zero by design; the 0-human-UAT campaign covers everything else via Tier A + Tier B.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
