---
phase: 56
slug: docs-contracts-and-arc-alignment
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-05
---

# Phase 56 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/threadline/readme_doc_contract_test.exs test/threadline/exploration_routing_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/incident_playbook_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/investigation_test.exs --max-failures 1` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | ~60 seconds |

## Sampling Rate

- **After every task commit:** Run `mix test test/threadline/readme_doc_contract_test.exs test/threadline/exploration_routing_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/incident_playbook_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/investigation_test.exs --max-failures 1`
- **After every plan wave:** Run `mix verify.test`
- **Before `$gsd-verify-work`:** `mix ci.all` must be green
- **Max feedback latency:** 60 seconds

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 56-01-01 | 01 | 1 | ADOPT-04 | T-56-04 | README and public guides teach one canonical routing hierarchy with `Threadline.incident_bundle/2` as the default transaction drill-down story. | doc contract | `mix test test/threadline/readme_doc_contract_test.exs test/threadline/exploration_routing_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/incident_playbook_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1` | ✅ | ✅ green |
| 56-01-02 | 01 | 1 | ADOPT-04 | T-56-05 | Docs only promote shipped investigation behavior and preserve the host-owned auth/policy boundary. | behavior regression | `mix test test/threadline/investigation_test.exs --max-failures 1` | ✅ | ✅ green |
| 56-02-01 | 02 | 2 | ADOPT-04 | T-56-04 / T-56-05 | Focused doc-contract suites fail if the final literals or cross-doc boundary wording drift. | doc contract | `mix verify.test` | ✅ | ✅ green |
| 56-02-02 | 02 | 2 | ADOPT-04 | T-56-06 | Planning summaries point to `.planning/MILESTONE-ARC.md` and do not duplicate ranked future-arc tables. | grep/manual | `rg -n "MILESTONE-ARC|next candidate|Operator-surface foundation|Adoption and policy hardening|Integration Breadth|Scale and Governance Depth" .planning/PROJECT.md .planning/STATE.md .planning/MILESTONE-ARC.md` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Planning-doc pointer discipline remains narrow and non-duplicative. | ADOPT-04 | Internal planning prose should stay low-noise; a one-off grep review is sufficient unless repeated drift appears. | Run `rg -n "MILESTONE-ARC|next candidate|Operator-surface foundation|Adoption and policy hardening|Integration Breadth|Scale and Governance Depth" .planning/PROJECT.md .planning/STATE.md .planning/MILESTONE-ARC.md` and confirm `.planning/MILESTONE-ARC.md` is the only ranked future-arc owner. |

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved
