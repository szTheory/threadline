---
phase: 168
slug: accessibility-verification
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-13
---

# Phase 168 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`use ExUnit.Case, async: true`) for the contract; Playwright `^1.52.0` for the affordance re-run |
| **Config file** | `test/test_helper.exs` (existing); `examples/threadline_phoenix/e2e/playwright.config.ts` (existing) |
| **Quick run command** | `mix test test/threadline/operator_surface/style_contract_test.exs` |
| **Full suite command** | `mix verify.test` (or `mix ci.all` for format+credo+test) |
| **Estimated runtime** | ~2s contract test; e2e re-run gated behind existing `run-e2e.sh` harness |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/threadline/operator_surface/style_contract_test.exs` + `mix format --check-formatted`
- **After every plan wave:** Run `mix verify.test` (scope-aware of the 3 known nav-lane failures — do not conflate)
- **Before `/gsd:verify-work`:** Full contract test green in BOTH modes, dark phase-143 test + frozen-hex catalog unchanged, e2e affordance re-run green under the light branch
- **Max feedback latency:** ~5 seconds (contract test); e2e ~minutes via existing harness

---

## Per-Task Verification Map

> Plan/wave/task IDs are filled by the planner. This map enumerates the requirement-level proofs every plan must satisfy.

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| A11Y-01 | `color_tokens/1` (or sibling) parses `#RRGGBB` + `rgba(...)` and composites translucent tokens over the per-mode opaque base before luminance math | unit (source) | `mix test test/threadline/operator_surface/style_contract_test.exs` | ✅ extend (`:1058-1062`) | ⬜ pending |
| A11Y-01 | Every text-bearing token ≥ 4.5:1 in `light` + `system`, incl. status text composited over its own tint | unit (source) | same | ✅ extend (mirror of dark `:653`) | ⬜ pending |
| A11Y-02 p1 | Focus 1px `border-focus` edge ≥ 3:1 vs `surface`/`surface-raised`, both modes; translucent halo composited-and-reported (not masking) | unit (source) | same | ✅ extend | ⬜ pending |
| A11Y-02 p1 | `outline:none` blanket forbidden; `:focus-visible` restores `--tl-focus-ring` per mode | unit (source) | same (focus guard `:688`) | ✅ re-confirm per mode | ⬜ pending |
| A11Y-02 p2 | Hover/active/disabled/selected resolve to perceptible delta per mode; coverage-hover polarity holds (`style.ex:299-315`); D-04 `muted-soft` strict 4.5:1 w/ bounded exemption | unit (source) | same | ✅ extend | ⬜ pending |
| A11Y-02 p2 | Affordance set (focus box-shadow≠none, chip border≠0px/none, aria-current, aria-pressed, dialog semantics, no h-overflow) holds under light branch | e2e | `bash examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-accessibility.spec.ts` (light project/branch) | ✅ re-run existing spec | ⬜ pending |
| Guard | Dark byte-stability: phase-143 dark test + frozen-hex catalog pass unchanged | unit (source) | `mix test test/threadline/operator_surface/style_contract_test.exs` | ✅ must stay green | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] **D-01 e2e light-branch activation mechanism** — resolve BEFORE wiring the Playwright re-run. The example operator mount defaults `theme: :dark`, so `colorScheme: "light"` emulation alone renders the dark branch (RESEARCH Pitfall 1 / Open Question 1). This is a prerequisite decision, not a code stub.
- [ ] No new test FILES needed — all source assertions extend `style_contract_test.exs`; the affordance proof re-runs `operator-accessibility.spec.ts`. No `conftest`/fixture equivalent.
- [ ] No framework install — ExUnit + Playwright `^1.52.0` present.

*Net: the only Wave-0 prerequisite is the D-01 mechanism decision; otherwise existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| (none) | — | All phase behaviors have automated source or e2e verification. | — |

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (D-01 mechanism resolved)
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s (contract)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
