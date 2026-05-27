---
phase: 117
slug: evidence-plane-doc-authority
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-27
---

# Phase 117 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix |
| **Config file** | `mix.exs` aliases `verify.doc_contract` |
| **Quick run command** | `mix test <touched_doc_contract_test.exs>` |
| **Full suite command** | `mix verify.doc_contract` |
| **Estimated runtime** | ~15–30 seconds |

---

## Sampling Rate

- **After every task commit:** Run the doc-contract file(s) touched by that task
- **After plan 117-02:** Run `mix verify.doc_contract`
- **Before `/gsd-verify-work`:** `mix verify.doc_contract` must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 117-01-01 | 01 | 1 | DOC-01 | T-117-01 | Maintainer refs point at real guides | grep | `rg 'guides/evidence-plane.md' .planning/PROJECT.md` → no match | ✅ | ⬜ pending |
| 117-01-02 | 01 | 1 | DOC-02 | T-117-02 | Adopter guides use semver not v1.2x | grep | `rg 'v1\.2[0-9]' guides/getting-started-saas.md guides/upgrade-path.md` → no match | ✅ | ⬜ pending |
| 117-01-03 | 01 | 1 | DOC-03 | T-117-03 | Incident step names blessed path | grep | `rg 'Audit.transaction/3' guides/domain-reference.md` near incident anchor | ✅ | ⬜ pending |
| 117-02-01 | 02 | 2 | DOC-03 | T-117-03 | Evolution + upgrade contracts | unit | `mix test test/threadline/how_threadline_works_doc_contract_test.exs` | ✅ | ⬜ pending |
| 117-02-02 | 02 | 2 | DOC-03 | T-117-03 | Semver refute + hub refute | unit | `mix test test/threadline/semver_adopter_doc_contract_test.exs` (or equivalent) | ❌ W0 | ⬜ pending |
| 117-02-03 | 02 | 2 | DOC-03 | T-117-03 | exploration_routing wired | alias | `mix verify.doc_contract` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing ExUnit doc-contract infrastructure covers all phase requirements. Wave 0 = add new test module in plan 117-02 if `semver_adopter_doc_contract_test.exs` is chosen.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `.planning/milestones/` batch hub ref cleanup | DOC-01 | Not in verify.doc_contract scope | Spot-check touched milestone files list real guide paths |

---

## Validation Sign-Off

- [ ] All tasks have automated verify
- [ ] `mix verify.doc_contract` green after 117-02
- [ ] `nyquist_compliant: true` set in frontmatter after green gate

**Approval:** pending
