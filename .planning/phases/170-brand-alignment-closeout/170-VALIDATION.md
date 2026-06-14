---
phase: 170
slug: brand-alignment-closeout
status: planned
nyquist_compliant: true
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
| 170-01 T1: reconcile tokens.json/css to style.ex | 170-01 | 1 | BRAND-01 | T-170-01 | N/A | unit | `mix test test/threadline/brandbook_token_parity_test.exs` | ❌ W0 (test authored in T3) | ⬜ pending |
| 170-01 T2: posture note + pressure-test addendum | 170-01 | 1 | BRAND-01, BRAND-02 | — | N/A | unit (doc-contract) | `mix test test/threadline/brandbook_token_parity_test.exs` | ❌ W0 (test authored in T3) | ⬜ pending |
| 170-01 T3: keystone parity test (dark/light intersection, exclusion drift, posture + pressure-test locks) | 170-01 | 1 | BRAND-01, BRAND-02 | — | N/A | unit | `mix test test/threadline/brandbook_token_parity_test.exs` | ✅ created by this task | ⬜ pending |
| 170-02 T1: author v1.36-MILESTONE-AUDIT.md | 170-02 | 1 | (success criterion 4) | T-170-03 | N/A | grep/doc-contract | `grep -q "closeout_readiness: pending-uat" .planning/milestones/v1.36-MILESTONE-AUDIT.md` | ✅ created by this task | ⬜ pending |
| 170-02 T2: REQUIREMENTS.md traceability | 170-02 | 1 | BRAND-01, BRAND-02 | — | N/A | grep | `grep -E "BRAND-01 \| Phase 170 \| Complete" .planning/REQUIREMENTS.md` | ✅ existing file | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**Note on Wave 0:** The keystone test file `test/threadline/brandbook_token_parity_test.exs` is the only MISSING test reference. It is authored within Plan 170-01 Task 3 (the plan's last task), against the corrections made in Tasks 1–2 of the same plan, so it goes green within the plan rather than needing a separate Wave-0 plan. The audit/traceability assertions (Plan 170-02) are grep-based doc-contract checks against files the plan itself authors/edits.

---

## Wave 0 Requirements

- [ ] `test/threadline/brandbook_token_parity_test.exs` — keystone test covering all BRAND-01 token-parity assertions (dark + light intersection value-equality, brand-exclusive absent, runtime-only exclusion list, tokens.css consistency), the posture-note doc-contract literal lock (D-06), and the BRAND-02 pressure-test addendum literal locks. **Authored in Plan 170-01 Task 3.**
- [ ] Framework install: none needed — ExUnit is built-in; Jason is an existing dependency for `tokens.json` decode.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Milestone audit doc reads as accurate (verdict, requirement table, COMP-01/02 status, risks accepted) | success criterion 4 | Audit narrative judgment; not literal-lockable beyond doc-contract structure | Reviewer reads `.planning/milestones/v1.36-MILESTONE-AUDIT.md`; confirms closeout readiness is `pending-uat`, the requirement→phase table matches REQUIREMENTS.md traceability, and COMP-01/02 are reported as built-verified-source-uncommitted (not rubber-stamped) |
| End-of-milestone UAT (dark/light/system walkthrough) | milestone gate | Human gate runs *after* this phase per ROADMAP Human Gates | User walks operator surface in all three modes; confirms brand posture + docs match shipped behavior |

---

## Validation Sign-Off

- [x] All BRAND-01 / BRAND-02 tasks have automated verify via the parity test or a grep doc-contract check
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers the keystone test file (authored in Plan 170-01 Task 3)
- [x] No watch-mode flags
- [x] Feedback latency < 5s for the keystone test
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** planner-approved 2026-06-14
