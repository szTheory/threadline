---
phase: 50
slug: direct-sigra-host-wiring
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-05
---

# Phase 50 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix |
| **Config file** | `test/test_helper.exs` and `examples/threadline_phoenix/test/test_helper.exs` |
| **Quick run command** | `mix test test/threadline/integrations/sigra_test.exs` |
| **Example app command** | `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/posts_audit_path_test.exs test/threadline_phoenix_web/posts_correlation_path_test.exs` |
| **Docs command** | `mix test test/threadline/integrations/sigra_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs` |
| **Full suite command** | `mix verify.test` plus the example app test run above |
| **Estimated runtime** | ~30 seconds for focused checks, longer for full suite |

---

## Sampling Rate

- **After every task commit:** Run the focused command for that task’s surface.
- **After Plan 50-01 completes:** Run library Sigra tests and the targeted example app request-path tests.
- **After Plan 50-02 completes:** Run the Sigra guide doc-contract test and the example README drift test.
- **Before `$gsd-verify-work`:** Run `mix verify.test` and re-run the targeted example app request-path tests.
- **Max feedback latency:** 30 seconds for focused checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 50-01-01 | 01 | 1 | SIGRA-04, SIGRA-05 | T-50-01 / T-50-02 | The shipped adapter is the only canonical direct wiring name and the example app does not preserve a dead Sigra delegate seam. | integration | `mix test test/threadline/integrations/sigra_test.exs` | ✅ | ⬜ pending |
| 50-01-02 | 01 | 1 | SIGRA-04, SIGRA-05 | T-50-02 / T-50-03 / T-50-04 | The real router path proves the direct callback golden path, including no-header correlation fallback, without absorbing Phase 51 auth scope. | integration | `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/posts_audit_path_test.exs test/threadline_phoenix_web/posts_correlation_path_test.exs` | ✅ | ⬜ pending |
| 50-02-01 | 02 | 2 | SIGRA-04, SIGRA-05 | T-50-05 / T-50-06 | The Sigra guide and example README teach one canonical direct callback story. | doc-contract | `mix test test/threadline/integrations/sigra_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs` | ✅ | ⬜ pending |
| 50-02-02 | 02 | 2 | SIGRA-04, SIGRA-05 | T-50-05 / T-50-06 / T-50-07 | Drift tests lock the direct callback names and responsibility split in the authoritative Sigra guide and the example README. | doc-contract | `mix test test/threadline/integrations/sigra_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

- Inspect the final example README wording for readability after the automated literal checks pass.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s for focused checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-05
