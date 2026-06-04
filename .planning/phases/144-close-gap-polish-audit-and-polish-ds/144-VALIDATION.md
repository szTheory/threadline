---
phase: 144
slug: close-gap-polish-audit-and-polish-ds
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-04
---

# Phase 144 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Playwright + GSD milestone audit |
| **Config file** | `mix.exs`; `examples/threadline_phoenix/e2e/playwright.config.ts`; `.planning/config.json` |
| **Quick run command** | `DB_PORT=5433 mix test test/threadline/operator_surface/style_contract_test.exs` |
| **Full suite command** | `DB_PORT=5433 mix verify.example_browser && gsd-sdk query milestone.audit v1.31` |
| **Estimated runtime** | ~180-360 seconds, depending on example browser startup |

---

## Sampling Rate

- **After every task commit:** Run `DB_PORT=5433 mix test test/threadline/operator_surface/style_contract_test.exs` when source/design-system files changed; otherwise run the relevant docs/metadata check listed in the task.
- **After every plan wave:** Run `DB_PORT=5433 mix verify.example_browser` and the milestone audit rerun if ROADMAP/REQUIREMENTS/audit closure changed.
- **Before `$gsd-verify-work`:** Full suite must be green and milestone audit must no longer report `POLISH-AUDIT` or `POLISH-DS` as blockers.
- **Max feedback latency:** 360 seconds for full validation; under 60 seconds for source-contract-only task checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 144-01-01 | 01 | 1 | POLISH-AUDIT | — | No fabricated Phase 134 history; closure is explicit errata/provenance. | artifact | `test -f .planning/phases/144-close-gap-polish-audit-and-polish-ds/144-AUDIT-ERRATA.md && find .planning/milestones/v1.31-screenshots/baseline -maxdepth 1 -name '*.png' | wc -l && find .planning/milestones/v1.31-screenshots/final -maxdepth 1 -name '*.png' | wc -l` | W0 | pending |
| 144-02-01 | 02 | 1 | POLISH-DS | — | Design-system freeze uses source contracts and no new build/theme dependency. | unit/source | `DB_PORT=5433 mix test test/threadline/operator_surface/style_contract_test.exs` | W0 | pending |
| 144-02-02 | 02 | 1 | POLISH-DS | — | Catalog exists and documents canonical/deprecated/consolidated primitives and token freeze. | artifact | `test -f .planning/milestones/v1.31-DESIGN-SYSTEM.md && rg \"canonical|deprecated|consolidated|token freeze|--tl-|\\.tl-\" .planning/milestones/v1.31-DESIGN-SYSTEM.md` | W0 | pending |
| 144-03-01 | 03 | 1 | POLISH-AUDIT, POLISH-DS | — | Milestone traceability closes both blockers without widening scope. | integration | `DB_PORT=5433 mix verify.example_browser && gsd-sdk query milestone.audit v1.31` | W0 | pending |

*Status: pending · green · red · flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:

- `test/threadline/operator_surface/style_contract_test.exs`
- `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts`
- `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts`
- `.planning/milestones/v1.31-screenshots/baseline/`
- `.planning/milestones/v1.31-screenshots/final/`
- `gsd-sdk query milestone.audit v1.31`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Design-system catalog judgment | POLISH-DS | Automated grep can prove anchors exist, but not whether usage guidance is coherent and future-maintainer friendly. | Review `v1.31-DESIGN-SYSTEM.md` for canonical/deprecated/consolidated class catalog, usage rules, anti-patterns, accessibility rules, and token freeze statement. |
| Errata wording honesty | POLISH-AUDIT | Automated checks cannot fully judge provenance language. | Review `144-AUDIT-ERRATA.md` and final verification for explicit "verified during Phase 144" wording and absence of fabricated Phase 134 execution claims. |

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 360s for full validation
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-04
