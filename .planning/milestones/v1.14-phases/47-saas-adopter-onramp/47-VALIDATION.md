---
phase: 47
slug: saas-adopter-onramp
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-05
---

# Phase 47 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/stg_doc_contract_test.exs` |
| **Full suite command** | `mix verify.test && mix docs` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/stg_doc_contract_test.exs`
- **After every plan wave:** Run `mix verify.test`
- **Before `$gsd-verify-work`:** `mix verify.test && mix docs` must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 47-01-01 | 01 | 1 | ADOPT-01 | T-47-01 | Marker-backed guide blocks fail loudly on missing, duplicate, or unbalanced anchors. | unit | `mix test test/threadline/getting_started_fixtures_test.exs` | ✅ planned | ⬜ pending |
| 47-01-02 | 01 | 1 | ADOPT-01 | T-47-02 | Example-app marker edits remain minimal and the guide publishes through ExDoc extras. | smoke | `mix docs` | ✅ | ⬜ pending |
| 47-01-03 | 01 | 1 | ADOPT-02 | T-47-03 | Walked STG example uses only fictional placeholders and in-repo evidence pointers. | unit / doc-contract | `mix test test/threadline/stg_doc_contract_test.exs` | ✅ | ⬜ pending |
*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing infrastructure covers all phase requirements once the new fixture unit test and doc-contract test land within Plan 47-01.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| The quickstart reads as a real 30-minute onboarding path for a Phoenix/SaaS adopter. | ADOPT-01 | Editorial flow and cognitive load are not fully machine-checkable. | Read `guides/getting-started-saas.md` top-to-bottom and confirm each step follows naturally from the previous step with no missing prerequisites. |
| The STG walked example is honest, non-promotional, and clearly maintainer-scoped. | ADOPT-02 | Tone and disclaimer clarity need human review. | Read the new `### Example: ExampleCloud walkthrough (maintainer-walked)` section and confirm it distinguishes maintainer CI evidence from host-owned staging evidence. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** ready for execution
