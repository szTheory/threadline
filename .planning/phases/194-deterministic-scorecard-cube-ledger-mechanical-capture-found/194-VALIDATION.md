---
phase: 194
slug: deterministic-scorecard-cube-ledger-mechanical-capture-found
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-03
---

# Phase 194 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir, `async: true`) + `@playwright/test` 1.61.1 (Node) |
| **Config file** | `test/test_helper.exs` (Elixir) + `examples/threadline_phoenix/e2e/playwright.config.ts` |
| **Quick run command** | `mix test test/threadline/operator_surface/stress_ledger_test.exs` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | ~30–60s quick (guard test); several min for full `ci.all` (browser e2e last) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/threadline/operator_surface/stress_ledger_test.exs` (guard) and, once the checker exists, `mix verify.mechanical`
- **After every plan wave:** Run `mix ci.all` (includes `verify.mechanical` after the checker wave lands)
- **Before `/gsd-verify-work`:** Full `mix ci.all` must be green
- **Max feedback latency:** ~60s for the guard/checker unit loop

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| _(planner fills per task)_ | — | — | LEDGER-01..05 / MECH-01..05 | — | dev/test-only, `/audit/__stress` raises in `:prod` | unit / e2e | `mix test …` / `mix verify.mechanical` / `mix verify.capture` | ✅ extend / ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Requirement → command map (from RESEARCH §Validation Architecture):*
- LEDGER-01..05 → `mix test test/threadline/operator_surface/stress_ledger_test.exs` (extend existing guard) + `mix ci.all` (LEDGER-05 determinism)
- MECH-01/02/03 → `mix verify.mechanical` (new `mechanical_checker_test.exs`, Wave 0)
- MECH-04 → `mix verify.capture` (new `operator-tier-a-capture.spec.ts`, Wave 0)
- MECH-05 → guard test asserts Tier A matrix documented + Tier C allowlist bounded at 3

---

## Wave 0 Requirements

- [ ] `test/threadline/operator_surface/mechanical_checker_test.exs` — covers MECH-01, MECH-02, MECH-03
- [ ] `examples/threadline_phoenix/e2e/tests/operator-tier-a-capture.spec.ts` — covers MECH-04
- [ ] `lib/threadline/operator_surface/mechanical_checker.ex` — the checker module itself
- [ ] `.planning/scorecards/` directory (first committed JSON artifacts from capture)
- [ ] `examples/threadline_phoenix/e2e/artifacts/tier-a/` added to `.gitignore`

*Guard/projection/freshness work extends the existing `stress_ledger_test.exs` — no new framework install.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Byte-stable regeneration across machines | MECH-04 | Cross-machine DPR determinism can't be asserted in a single CI run | Run `mix verify.capture` locally and on CI; `git diff` on committed scorecard JSON must be empty |

*All other phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
