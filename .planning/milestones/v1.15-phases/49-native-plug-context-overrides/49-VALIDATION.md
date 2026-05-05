---
phase: 49
slug: native-plug-context-overrides
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-05
---

# Phase 49 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/threadline/plug_test.exs test/threadline/integrations/sigra_test.exs` |
| **Full suite command** | `mix verify.test` |
| **Estimated runtime** | ~20 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/threadline/plug_test.exs test/threadline/integrations/sigra_test.exs`
- **After every plan wave:** Run `mix verify.test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 49-01-01 | 01 | 1 | PLUG-01, PLUG-02 | T-49-01 / T-49-02 / T-49-03 / T-49-04 | `Threadline.Plug` accepts additive-only `request_id` and `correlation_id` overrides, preserves actor and transport authority, and rejects invalid callback shapes loudly. | unit | `mix test test/threadline/plug_test.exs` | ✅ | ⬜ pending |
| 49-01-02 | 01 | 1 | PLUG-01 | T-49-02 / T-49-03 | Sigra composition only fills missing metadata and explicit inbound correlation headers still win. | integration | `mix test test/threadline/plug_test.exs test/threadline/integrations/sigra_test.exs` | ✅ | ⬜ pending |
| 49-02-01 | 02 | 2 | PLUG-01, PLUG-02 | T-49-05 / T-49-06 | Guides describe additive-only metadata, precedence, failure behavior, and host-owned IP normalization correctly. | doc-contract | `mix test test/threadline/integrations/sigra_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs` | ✅ | ⬜ pending |
| 49-02-02 | 02 | 2 | PLUG-01, PLUG-02 | T-49-05 / T-49-06 / T-49-07 / T-49-08 | Drift tests lock the direct callback example and the narrowed public contract. | doc-contract | `mix test test/threadline/integrations/sigra_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 20s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-05
