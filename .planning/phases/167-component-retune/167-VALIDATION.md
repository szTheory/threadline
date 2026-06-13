---
phase: 167
slug: component-retune
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-13
---

# Phase 167 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (bundled with Elixir), `async: true` |
| **Config file** | `test/test_helper.exs` (project standard) |
| **Quick run command** | `mix test test/threadline/operator_surface/style_contract_test.exs` |
| **Full suite command** | `mix verify.test` (alias → `mix test`) |
| **Estimated runtime** | ~5 seconds (contract test); full suite per project norm |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/threadline/operator_surface/style_contract_test.exs`
- **After every plan wave:** Run `mix verify.test` + `mix verify.format`
- **Before `/gsd:verify-work`:** `mix ci.all` green AND `LIGHT-REVIEW.md` committed with all 9 family dispositions + all 3 data-viz surfaces recorded
- **Max feedback latency:** ~5 seconds (contract test); full suite at wave boundaries

---

## Per-Task Verification Map

> Task IDs are assigned by the planner. This map binds each phase requirement to its
> validation mechanism; the planner expands rows per emitted task.

| Requirement | Behavior | Test Type | Automated Command / Artifact | File Exists | Status |
|-------------|----------|-----------|------------------------------|-------------|--------|
| COMP-01 (override authored) | Each authored light override present in BOTH branches (`[data-tl-theme="light"]` + mirrored `@media (prefers-color-scheme: light) [data-tl-theme="system"]`) | source-contract (unit) | `mix test …/style_contract_test.exs` — D-07(a) presence assertions (new) | ❌ W0 extend | ⬜ pending |
| COMP-01 (confirm-only families) | Family renders correctly on white via the 166 45-token lane — no override needed | committed review checklist | `LIGHT-REVIEW.md` per-family disposition (D-08) | ❌ W0 create | ⬜ pending |
| COMP-01 / TOKEN-02 (tint-riders) | No per-component `[data-tl-theme="light"]` selector qualified by a rider class for the ~20 riders (they ride the shared status-tint system) | source-contract (unit) | `mix test …/style_contract_test.exs` — D-07(b) absence assertion (new) | ❌ W0 extend | ⬜ pending |
| COMP-02 (data-viz) | Coverage / timeline / diff pass named light-mode design-review criteria on white (the Grafana lesson) | committed review checklist (human judgment) | `LIGHT-REVIEW.md` per-surface, per-criterion outcome (D-08) | ❌ W0 create | ⬜ pending |
| Dark byte-stability | No dark token value or base `.tl-*` rule changed | existing source-contract | frozen-hex assertions in `style_contract_test.exs` | ✅ exists | ⬜ pending |
| Theme-toggle ban | No runtime theme-toggle UI introduced | existing source-contract | `refute` assertions in `style_contract_test.exs` | ✅ exists | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `LIGHT-REVIEW.md` (phase dir) — records the per-family disposition for the ~9 dark-effect families (`pass | override-needed`) and the named-criteria outcome for each of the 3 data-viz surfaces (coverage / timeline / diff). This artifact IS the proven fail-list that drives which override tasks exist (D-01/D-02 review-first gate, D-08 proof). Must exist before override-authoring tasks.
- [ ] `test/threadline/operator_surface/style_contract_test.exs` extension — D-07(a) authored-override presence (dual-branch) + D-07(b) tint-rider absence (attribute qualified by rider class, NOT bare absence — bare `data-tl-theme="light"` already occurs once as the lane root). Moves in the same wave as any override (166 D-05 source-first amendment).
- Framework install: none — ExUnit + `mix` already present.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Live render review across `:dark` / `:light` / `:system` | COMP-01, COMP-02 | The confirm-strict disposition (which families pass vs. fail on white) and the data-viz Grafana-lesson judgment are inherently visual — no automated pixel/contrast check in this phase (those defer to 169/168). | Render the operator surface live; toggle `:dark` / `:light`, then `:system` via DevTools `prefers-color-scheme: light` emulation (avoid disturbing the uncommitted nav-overhaul lane). Eyeball the 9 families + 3 data-viz surfaces against UI-SPEC named criteria; record each disposition in `LIGHT-REVIEW.md`. Give explicit attention to the flagged trio: #5 drawer scrim, #1 glass topbar, #8 home-card signal-line. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (`LIGHT-REVIEW.md` + contract-test extension)
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
