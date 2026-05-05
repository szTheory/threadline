---
phase: 51
slug: authenticated-incident-drill-down
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-05
---

# Phase 51 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix |
| **Config file** | `test/test_helper.exs` and `examples/threadline_phoenix/test/test_helper.exs` |
| **Quick run command** | `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/posts_incident_json_path_test.exs` |
| **Example app command** | `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/posts_incident_json_path_test.exs test/threadline_phoenix_web/posts_audit_path_test.exs test/threadline_phoenix_web/posts_correlation_path_test.exs` |
| **Docs command** | `mix test test/threadline/example_phoenix_readme_contract_test.exs test/threadline/exploration_routing_doc_contract_test.exs test/threadline/incident_playbook_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/stg_doc_contract_test.exs` |
| **Full suite command** | `mix verify.test` plus the example app test run above |
| **Estimated runtime** | ~35 seconds for focused checks, longer for full suite |

---

## Sampling Rate

- **After every task commit:** Run the focused command for that task's surface.
- **After Plan 51-01 completes:** Run the targeted example app incident-path tests.
- **After Plan 51-02 completes:** Run the incident-facing doc-contract suite covering README, domain reference, playbook, quickstart, and adoption backlog.
- **Before `$gsd-verify-work`:** Run `mix verify.test` and re-run the targeted example app incident-path tests.
- **Max feedback latency:** 35 seconds for focused checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 51-01-01 | 01 | 1 | INCIDENT-03 | T-51-01 / T-51-02 / T-51-04 | The controller keeps the auth gate endpoint-local, keys it off `audit_context.actor_ref`, preserves `401` for anonymous requests and `400` for malformed ids, and does not add `403` / `404` policy branches. | integration | `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/posts_incident_json_path_test.exs` | ✅ | ⬜ pending |
| 51-01-02 | 01 | 1 | INCIDENT-03 | T-51-01 / T-51-02 / T-51-03 | The real router path proves authenticated success, exact anonymous rejection, and authenticated malformed-id handling without bypassing the Sigra-backed request flow. | integration | `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/posts_incident_json_path_test.exs test/threadline_phoenix_web/posts_audit_path_test.exs test/threadline_phoenix_web/posts_correlation_path_test.exs` | ✅ | ⬜ pending |
| 51-02-01 | 02 | 2 | INCIDENT-04 | T-51-05 / T-51-07 / T-51-08 | Incident-facing docs consistently describe the shipped authenticated baseline while keeping tenancy and richer authorization host-owned. | doc-contract | `mix test test/threadline/example_phoenix_readme_contract_test.exs test/threadline/exploration_routing_doc_contract_test.exs test/threadline/incident_playbook_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/stg_doc_contract_test.exs` | ✅ | ⬜ pending |
| 51-02-02 | 02 | 2 | INCIDENT-04 | T-51-05 / T-51-06 / T-51-07 / T-51-08 | Existing doc-contract tests lock the incident-auth boundary on the README, domain reference, playbook, quickstart, and adoption backlog without widening into Phase 52. | doc-contract | `mix test test/threadline/example_phoenix_readme_contract_test.exs test/threadline/exploration_routing_doc_contract_test.exs test/threadline/incident_playbook_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/stg_doc_contract_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

- Inspect the final incident-facing wording for clarity so the shipped authenticated baseline does not read like full production authorization guidance.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 35s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-05
