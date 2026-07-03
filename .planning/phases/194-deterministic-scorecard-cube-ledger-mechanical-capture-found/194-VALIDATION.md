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
| 01-T1 migrate ledger v2 + guard attrs | 194-01 | 1 | LEDGER-01 | T-194-01 | trusted repo artifact | unit | `mix test test/threadline/operator_surface/stress_ledger_test.exs` | ✅ extend | ⬜ pending |
| 01-T2 five cube guard blocks | 194-01 | 1 | LEDGER-01/02/03 | T-194-01/02 | trusted repo artifact | unit | `mix test test/threadline/operator_surface/stress_ledger_test.exs` | ✅ extend | ⬜ pending |
| 01-T3 DESIGN-SYSTEM cube projection | 194-01 | 1 | LEDGER-04/05 | T-194-03 | no LLM/network | unit + integration | `mix test …/stress_ledger_test.exs` + `mix ci.all` | ✅ extend | ⬜ pending |
| 02-T1 viewport/project/gitignore | 194-02 | 2 | MECH-04 | T-194-06 | `/audit/__stress` fail-closed | config | `mix test …/stress_ledger_test.exs` | ❌ W0 | ⬜ pending |
| 02-T2 capture spec + 120 scorecards | 194-02 | 2 | MECH-04 | T-194-04/05 | dev/test-only capture | e2e | `mix verify.capture` | ❌ W0 | ⬜ pending |
| 02-T3 verify.capture + matrix doc | 194-02 | 2 | MECH-05 | — | local-only, not in ci.all | contract | `mix verify.capture` + `mix test …/stress_ledger_test.exs` | ❌ W0 | ⬜ pending |
| 03-T1 MechanicalChecker module | 194-03 | 3 | MECH-01/02 | T-194-09 | pure Elixir, no browser | unit | `mix verify.mechanical` | ❌ W0 | ⬜ pending |
| 03-T2 checker meta-test + unit | 194-03 | 3 | MECH-01/02/03 | T-194-07 | LOCKED-constant pin | unit | `mix verify.mechanical` | ❌ W0 | ⬜ pending |
| 03-T3 ci.all wiring + floor seed | 194-03 | 3 | MECH-03 | T-194-08 | no LLM in gate | integration | `mix ci.all` | ❌ W0 | ⬜ pending |

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
