---
phase: 52
slug: docs-and-contract-alignment
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-05
---

# Phase 52 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix |
| **Config file** | `test/test_helper.exs` |
| **Docs command** | `mix test test/threadline/integrations/sigra_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/exploration_routing_doc_contract_test.exs test/threadline/incident_playbook_doc_contract_test.exs test/threadline/stg_doc_contract_test.exs` |
| **Full suite command** | `mix verify.test` |
| **Estimated runtime** | ~30 seconds for focused doc-contract checks, longer for full suite |

---

## Sampling Rate

- **After every task commit:** Run the focused doc-contract command for the affected surfaces.
- **After Plan 52-01 completes:** Run the grep-based literal checks captured in `52-01-SUMMARY.md`.
- **After Plan 52-02 completes:** Run the full focused doc-contract bundle covering quickstart, Sigra, README, domain reference, playbook, and adoption backlog.
- **Before `$gsd-verify-work`:** Run `mix verify.test`.
- **Max feedback latency:** 30 seconds for focused checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 52-01-01 | 01 | 1 | ADOPT-03 | T-52-01 / T-52-02 | The quickstart, Sigra guide, README, and incident-facing docs all describe the same direct callback contract and authenticated baseline. | doc lint | `rg -n "Threadline\\.Integrations\\.Sigra\\.actor_ref_from_conn/1|Threadline\\.Integrations\\.Sigra\\.audit_context_overrides_from_conn/1|authenticated actor|tenancy|authorization" guides/getting-started-saas.md guides/integrations/sigra.md guides/domain-reference.md guides/incident-playbook.md guides/adoption-pilot-backlog.md examples/threadline_phoenix/README.md` | ✅ | ⬜ pending |
| 52-01-02 | 01 | 1 | ADOPT-03 | T-52-03 / T-52-04 | Incident docs keep tenancy and richer authorization host-owned rather than implying Threadline ships a full policy layer. | doc lint | `rg -n "COMP-EXAMPLE-INCIDENT-JSON|authenticated actor|tenancy|authorization|Host teams still own tenancy and richer authorization review" guides/domain-reference.md guides/incident-playbook.md guides/adoption-pilot-backlog.md` | ✅ | ⬜ pending |
| 52-02-01 | 02 | 2 | ADOPT-03 | T-52-05 / T-52-06 | Focused contract tests fail if direct callback names or additive-only semantics drift on any adopter-facing surface. | doc-contract | `mix test test/threadline/integrations/sigra_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs` | ✅ | ⬜ pending |
| 52-02-02 | 02 | 2 | ADOPT-03 | T-52-05 / T-52-06 / T-52-07 | Cross-doc contract tests fail if the authenticated incident boundary or host-owned authorization wording drifts. | doc-contract | `mix test test/threadline/exploration_routing_doc_contract_test.exs test/threadline/incident_playbook_doc_contract_test.exs test/threadline/stg_doc_contract_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

- Read the final public-doc wording once after the automated checks pass so the shared host-wiring story remains concise and consistent for fresh adopters.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s for focused checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-05
