---
phase: 170
slug: brand-alignment-closeout
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-14
---

# Phase 170 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in Elixir) |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `mix test test/threadline/brandbook_token_parity_test.exs` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | ~3 seconds (single test file); ~full suite for `mix ci.all` |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/threadline/brandbook_token_parity_test.exs`
- **After every plan wave:** Run `mix ci.all`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~3 seconds (keystone parity test)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| parity: dark intersection | TBD | 1 | BRAND-01 | — | N/A | unit | `mix test test/threadline/brandbook_token_parity_test.exs` | ❌ W0 | ⬜ pending |
| parity: light intersection | TBD | 1 | BRAND-01 | — | N/A | unit | `mix test test/threadline/brandbook_token_parity_test.exs` | ❌ W0 | ⬜ pending |
| parity: brand-exclusive tokens absent from style.ex | TBD | 1 | BRAND-01 | — | N/A | unit | `mix test test/threadline/brandbook_token_parity_test.exs` | ❌ W0 | ⬜ pending |
| parity: runtime-only tokens absent from brandbook semantics | TBD | 1 | BRAND-01 | — | N/A | unit | `mix test test/threadline/brandbook_token_parity_test.exs` | ❌ W0 | ⬜ pending |
| posture-note keystone sentence literal lock | TBD | 1 | BRAND-01 | — | N/A | unit (doc-contract) | `mix test test/threadline/brandbook_token_parity_test.exs` | ❌ W0 | ⬜ pending |
| pressure-test dim #11 dual-mode pass condition | TBD | 1 | BRAND-02 | — | N/A | unit (doc-contract) | `mix test test/threadline/brandbook_token_parity_test.exs` | ❌ W0 | ⬜ pending |
| pressure-test mechanical parity gate line present | TBD | 1 | BRAND-02 | — | N/A | unit (doc-contract) | `mix test test/threadline/brandbook_token_parity_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline/brandbook_token_parity_test.exs` — keystone test covering all BRAND-01 token-parity assertions (dark + light intersection value-equality, brand-exclusive absent, runtime-only exclusion list), the posture-note doc-contract literal lock, and the BRAND-02 pressure-test addendum literal locks.
- [ ] Framework install: none needed — ExUnit is built-in; Jason is an existing dependency for `tokens.json` decode.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Milestone audit doc reads as accurate (verdict, requirement table, COMP-01/02 status, risks accepted) | success criterion 4 | Audit narrative judgment; not literal-lockable beyond doc-contract structure | Reviewer reads `.planning/milestones/v1.36-MILESTONE-AUDIT.md`; confirms closeout readiness is marked `pending-uat` and the requirement→phase table matches REQUIREMENTS.md traceability |
| End-of-milestone UAT (dark/light/system walkthrough) | milestone gate | Human gate runs *after* this phase per ROADMAP Human Gates | User walks operator surface in all three modes; confirms brand posture + docs match shipped behavior |

---

## Validation Sign-Off

- [ ] All BRAND-01 / BRAND-02 tasks have automated verify via the parity test or Wave 0 dependency
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers the keystone test file (the only MISSING reference)
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s for the keystone test
- [ ] `nyquist_compliant: true` set in frontmatter after planner completes

**Approval:** pending
