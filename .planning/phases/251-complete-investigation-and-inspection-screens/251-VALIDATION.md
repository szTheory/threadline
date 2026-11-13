---
phase: "251"
slug: "complete-investigation-and-inspection-screens"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-12"
---

# Phase 251 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + existing Node contracts + Playwright 1.60.0 |
| **Config file** | mix.exs; examples/threadline_phoenix/e2e/playwright.config.ts |
| **Quick run command** | `mix verify.test test/threadline/query/filter_params_test.exs` |
| **Full suite command** | `Selected Phase 251 owners, finalized in plans; whole-root repeat remains stopped` |
| **Estimated runtime** | Unmeasured; record actual scoped runtimes |

---

## Sampling Rate

- **After every task commit:** Run `mix verify.test with the changed owner paths specified in each plan`
- **After every plan wave:** Run `the combined selected Phase 251 regression specified by the plan`
- **Before `$gsd-verify-work`:** All selected checks must be green; no claim of a whole-root run
- **Max feedback latency:** 60 seconds for an update; actual command runtimes recorded

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| Planning pending | 01/02 | 1/2 | ADM-15/18/19/20/21/22 | To be authored in plans | Scoped query, state and privacy boundaries | ExUnit/live/Node/browser | Exact owners/commands to be populated by planner before execution | Existing owners; new cases pending | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. Add meaningful regression cases to existing owners; no framework installation or new runner. Planner must replace the planning row with concrete task commands and threat references before execution.


---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
All phase behaviors have automated verification. Independent agent review covers visual/copy judgment; no maintainer UAT is planned.


---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Actual feedback latency recorded; no unmeasured target pass
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** Pending execution and Nyquist audit
