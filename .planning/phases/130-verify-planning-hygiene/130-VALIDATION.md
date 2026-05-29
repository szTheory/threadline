---
phase: 130
slug: verify-planning-hygiene
status: finalized
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-28
---

# Phase 130 — Validation Strategy

> Meta verification-backfill: Nyquist 125 finalize + SUMMARY convention hygiene on current tree.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix aliases |
| **Config file** | `mix.exs` (`verify.doc_contract`, `ci.all`) |
| **Quick run command (Tier 1 / 125)** | `mix test test/threadline/v1_23_charter_doc_contract_test.exs` |
| **Mid run command (Tier 1 / 125)** | `mix verify.doc_contract` |
| **Full suite command (Tier 2 / session close)** | `mix ci.all` (Plan 02 only — once) |
| **Estimated runtime** | ~30s Tier 1; ~minutes Tier 2 |

---

## Sampling Rate

- **After Plan 01 charter test task:** Run Tier 1 quick command
- **After Plan 01 finalize task:** Run full Tier 1 bundle; confirm `125-VALIDATION.md` frontmatter
- **After Plan 02 backfill tasks:** Run `rg` acceptance greps on GAP IDs and convention doc
- **Before phase complete:** Single `mix ci.all` recorded in `130-VERIFICATION.md`

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 130-01-01 | 01 | 1 | NYQ-01 | T-130-01 | 125 archive files present under milestones path | grep | `test -f .planning/milestones/v1.27-phases/125-authority-surface-reconciliation/125-VALIDATION.md` | ✅ | ⬜ pending |
| 130-01-02 | 01 | 1 | NYQ-01 | T-130-02 | Charter test locks v1.29 active milestone | unit | `mix test test/threadline/v1_23_charter_doc_contract_test.exs` | ✅ | ⬜ pending |
| 130-01-03 | 01 | 1 | NYQ-01 | T-130-03 | Tier 1 bundle green on current tree | integration | `mix verify.doc_contract` | ✅ | ⬜ pending |
| 130-01-04 | 01 | 1 | NYQ-01 | T-130-04 | 125-VALIDATION finalized; NYQ-01 path updated | grep | `rg 'nyquist_compliant: true' .planning/milestones/v1.27-phases/125-authority-surface-reconciliation/125-VALIDATION.md` | ✅ | ⬜ pending |
| 130-02-01 | 02 | 2 | PLAN-01 | — | Convention SSOT documents GAP namespace | grep | `rg 'GAP-\\{phase\\}-\\{nn\\}' .planning/conventions/summary-frontmatter.md` | ❌ W0 | ⬜ pending |
| 130-02-02 | 02 | 2 | PLAN-01 | — | 125–127 SUMMARYs have gap-closure + GAP IDs | grep | plan rg bundle | ❌ W0 | ⬜ pending |
| 130-02-03 | 02 | 2 | NYQ-01, PLAN-01 | — | Session-close ci.all green | integration | `mix ci.all` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. Convention doc and archive dirs are created during execution — no new ExUnit files beyond charter assertion updates.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Tier 1 bundle recorded in archived `125-VALIDATION.md` Commands Actually Used
- [ ] Tier 2 `mix ci.all` recorded in `130-VERIFICATION.md`
- [ ] `nyquist_compliant: true` on 125-VALIDATION only after Tier 1 green
- [x] `nyquist_compliant: true` set in this file after phase complete

**Approval:** Phase 130 session-close `mix ci.all` green (130-VERIFICATION.md)
