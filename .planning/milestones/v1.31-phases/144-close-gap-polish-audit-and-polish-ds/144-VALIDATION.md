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
| 144-01-01 | 01 | 1 | POLISH-AUDIT | T-144-01-01 / T-144-01-02 | No fabricated Phase 134 history; closure is explicit errata/provenance. | artifact | `test -f .planning/phases/144-close-gap-polish-audit-and-polish-ds/144-AUDIT-ERRATA.md && rg -n "This is not an original Phase 134 execution record|verified during Phase 144|POLISH-AUDIT" .planning/phases/144-close-gap-polish-audit-and-polish-ds/144-AUDIT-ERRATA.md` | creates `144-AUDIT-ERRATA.md` | pending |
| 144-02-01 | 02 | 1 | POLISH-DS | T-144-02-01 / T-144-02-02 | Operation helper handles unknown input safely and never creates atoms. | unit/source | `DB_PORT=5433 mix test test/threadline/operator_surface/presentation_test.exs` | existing test/source files | pending |
| 144-02-02 | 02 | 1 | POLISH-DS | T-144-02-03 | Timeline and Transaction consume shared operation presentation helpers with no schema drift. | unit/source | `DB_PORT=5433 mix test test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/live/timeline_live_test.exs && gsd-sdk query verify.schema-drift 144 --raw` | existing source files | pending |
| 144-03-01 | 03 | 2 | POLISH-DS | T-144-03-01 | Final token/class freeze is enforced by source-contract tests and anti-pattern grep. | unit/source | `DB_PORT=5433 mix test test/threadline/operator_surface/style_contract_test.exs && ! rg -n "@tailwind|prefers-color-scheme|color-scheme: light|theme-toggle|shadcn|daisyui" lib/threadline/operator_surface/style.ex` | existing test/source files | pending |
| 144-03-02 | 03 | 2 | POLISH-DS | T-144-03-02 / T-144-03-03 | Design-system catalog exists and reflects source truth; it is not an aspirational component API. | artifact | `test -f .planning/milestones/v1.31-DESIGN-SYSTEM.md && rg -n "artifact: design-system-catalog|status: source-contract|requirements: \\[POLISH-DS\\]|## Token Freeze|## Canonical Class Catalog|## Deprecated And Consolidated Classes|## Focus And Accessibility|## Anti-Patterns" .planning/milestones/v1.31-DESIGN-SYSTEM.md` | creates `v1.31-DESIGN-SYSTEM.md` | pending |
| 144-04-01 | 04 | 3 | POLISH-AUDIT, POLISH-DS | T-144-04-02 | Final verification records focused automated evidence and artifact checks. | integration | `DB_PORT=5433 mix test test/threadline/operator_surface/style_contract_test.exs && gsd-sdk query verify.schema-drift 144 --raw && test "$(find .planning/milestones/v1.31-screenshots/baseline -maxdepth 1 -type f -name '*.png' | wc -l | tr -d ' ')" = "24" && test "$(find .planning/milestones/v1.31-screenshots/final -maxdepth 1 -type f -name '*.png' | wc -l | tr -d ' ')" = "24"` | creates `144-VERIFICATION.md` | pending |
| 144-04-02 | 04 | 3 | POLISH-AUDIT, POLISH-DS | T-144-04-01 | Requirements, roadmap, and state traceability close both blockers truthfully. | artifact | `rg -n "\\[x\\] \\*\\*POLISH-AUDIT\\*\\*|\\[x\\] \\*\\*POLISH-DS\\*\\*|Phase 144" .planning/REQUIREMENTS.md && rg -n "144-01-PLAN\\.md|144-02-PLAN\\.md|144-03-PLAN\\.md|144-04-PLAN\\.md" .planning/ROADMAP.md` | existing planning files | pending |
| 144-04-03 | 04 | 3 | POLISH-AUDIT, POLISH-DS | T-144-04-01 / T-144-04-02 | Milestone audit no longer blocks on `POLISH-AUDIT` or `POLISH-DS`. | integration | `gsd-sdk query milestone.audit v1.31 && rg -n "milestone\\.audit v1\\.31|POLISH-AUDIT|POLISH-DS" .planning/phases/144-close-gap-polish-audit-and-polish-ds/144-VERIFICATION.md` | updates milestone audit if generated | pending |

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
