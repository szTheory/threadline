---
phase: 196
slug: forward-only-net-positive-gate-first-proven-iteration
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-28
---

# Phase 196 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> **Core rule:** every gate must be **deterministically verifiable in CI without the LLM.**
> The LLM critic (`verify.ui_critique`, `npm run critic:*`, `npm run capture:*`) is maintainer-local
> and excluded from `ci.all`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) + Playwright (e2e, local-only) |
| **Config file** | `mix.exs` aliases (`verify.*`, `ci.all`); `examples/threadline_phoenix/e2e/playwright.config.ts` |
| **Quick run command** | `mix verify.critic_trust` (pure Elixir — no browser, no network, no LLM) |
| **Full suite command** | `mix ci.all` (order: … → `verify.critic_trust` → `verify.mechanical` → `verify.example_browser`) |
| **Estimated runtime** | `verify.critic_trust` ~2s · `verify.mechanical` ~3s · `ci.all` full ~several min (browser lane) |

---

## Sampling Rate

- **After every task commit:** Run `mix verify.critic_trust` (fast, deterministic).
- **After every plan wave:** Run `mix verify.critic_trust && mix verify.mechanical`.
- **Before `/gsd-verify-work`:** `mix ci.all` must be green.
- **Max feedback latency:** ~5 seconds (deterministic guards); browser lane on wave merges.

---

## Per-Task Verification Map

> Seed rows from the research Requirements→Test map. The planner expands these to real
> `{N}-PP-TT` task IDs as PLAN.md files are written. Every gate resolves to a deterministic
> ExUnit assertion; the LLM-dependent loop steps are local-only integration checks.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 196-01-xx | 01 | 1 | GATE-04 | — | Silent target-drop / fixture-removal / panel-change FAILS the guard | unit | `mix verify.critic_trust` | ❌ W0 | ⬜ pending |
| 196-01-xx | 01 | 1 | GATE-02 | — | Structural whitelist empty unless signed off in ledger | unit | `mix verify.critic_trust` | ❌ W0 | ⬜ pending |
| 196-01-xx | 01 | 1 | GATE-05 | — | Baseline refresh requires a fresh clean semantic-guard stamp | unit | `mix verify.critic_trust` | ❌ W0 | ⬜ pending |
| 196-0x-xx | 0x | 2 | GATE-01 | — | Accept only on target-up + no blocking-lens regress + floor pass | integration (local LLM) + unit floor | `npm run critic -- gate …` (local); `mix verify.mechanical` (CI floor via `page.*` twin) | ❌ W0 | ⬜ pending |
| 196-0x-xx | 0x | 2 | GATE-03 | — | Held-out ρ ≥ recorded floor; training-vs-held-out divergence halts | unit floor + local recompute | `mix verify.critic_trust`; `mix critic.measure --source synthetic` (local) | ⚠️ recompute exists; halt ❌ W0 | ⬜ pending |
| 196-0x-xx | 0x | 3 | PROOF-01 | — | Loop runs end-to-end; one improvement lands; runbook pinned | integration (local) + doc-contract | full loop (local) + `mix verify.doc_contract` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `examples/threadline_phoenix/e2e/critic/gate.ts` (+ `run.ts` `case "gate"`) — the propose→re-eval→guard orchestrator (GATE-01), built over the existing `scoreCellLens` two-blind-score + noise-floor-margin primitive.
- [ ] `test/threadline/operator_surface/critic_trust_test.exs` — 3 GATE-04 clauses + GATE-02 whitelist clause + GATE-05 semantic-stamp clause (all **vacuous-safe** until baseline data lands, so they never falsely red before Wave-1 data exists).
- [ ] Ledger additive blocks in `.planning/design-system-ledger.json`: `critic_panel` (baseline of the 4-lens blocking membership), `mechanical_auto_apply.structural_whitelist: []`, `semantic_guard_stamp` per allowlisted baseline entry, `ratchet.signoffs` append-only entries.
- [ ] Divergence-halt compare in `gate.ts` reading `mix critic.measure --source synthetic` output (GATE-03).
- [ ] Expanded `ROUTES` in `examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts` for the weakest-page candidates (PROOF-01 pick).
- [ ] `CONTRIBUTING.md` runbook subsection + `verify.doc_contract` pin (and fix the stale "α ≥ 0.67" line at ~`CONTRIBUTING.md:132`, superseded by the ρ-ranking pivot).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| One real, human-ratified UI improvement on the weakest `/audit` page (target lens advanced, zero regressions) | PROOF-01 (First Proven Iteration) | The gate proposes/measures deterministically, but a human must ratify that the landed change is a genuine improvement (guards against Goodharting the metric) | Run the loop on the weakest page; maintainer reviews the before/after render + score delta; record ratification (ledger `ratchet.signoffs` entry + commit evidence trail) |

*The mechanical half of this proof IS automated:* the improved page's `page.*` Tier-A twin must pass `mix verify.mechanical`, and the score-delta is recomputed by the loop.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s (deterministic guards)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
