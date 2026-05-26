---
phase: 95
slug: evidence-model-lock-and-scope-guard
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-25
---

# Phase 95 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.
> Phase 95 is a contract-first phase: the main risk is false confidence from
> prose-only boundary claims or a mutable record shape that later phases cannot
> trust.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Targeted ExUnit schema, validator, migration-install, and doc-contract tests |
| **Config file** | `lib/threadline/governance/migration.ex`; `lib/mix/tasks/threadline.install.ex`; `guides/how-threadline-works.md`; `guides/integration-contracts.md` |
| **Quick run command** | `mix test test/threadline/governance/evidence_record_test.exs test/threadline/evidence/subject_test.exs --max-failures 1` |
| **Full suite command** | `mix test test/threadline/governance/evidence_record_test.exs test/threadline/evidence/subject_test.exs test/threadline/how_threadline_works_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs --max-failures 1` |
| **Estimated runtime — quick** | ~10-20 seconds on a warm cache |
| **Estimated runtime — full** | ~15-30 seconds on a warm cache |

---

## Sampling Rate

- Re-run the schema + subject tests after every task that changes evidence
  fields, subject vocabulary, or append-only enforcement.
- Re-run the full suite after every plan because boundary wording and code
  validators must stay aligned.
- Before `$gsd-verify-work`, the full suite must be green and evidence-contract
  grep checks must pass.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 95-01-01 | 01 | 1 | EVID-01, EVID-02 | T-95-01 / T-95-02 | Evidence rows persist in a dedicated append-only governance table with explicit contract fields. | schema + migration | `mix test test/threadline/governance/evidence_record_test.exs --max-failures 1` | ❌ W0 | ⬜ pending |
| 95-01-02 | 01 | 1 | EVID-01, EVID-02 | T-95-02 | `mix threadline.install` still emits the governance migration path that now includes evidence records. | install-path | `mix test test/threadline/governance/evidence_record_test.exs --max-failures 1` | ❌ W0 | ⬜ pending |
| 95-02-01 | 02 | 2 | EVID-03 | T-95-03 / T-95-04 | Unsupported host-owned and compliance-platform subjects are rejected with stable validator errors. | unit | `mix test test/threadline/evidence/subject_test.exs --max-failures 1` | ❌ W0 | ⬜ pending |
| 95-02-02 | 02 | 2 | EVID-03 | T-95-04 | Public boundary docs still say Threadline does not own RBAC, tenancy DSL, legal hold, or generic compliance workflows. | doc-contract | `mix test test/threadline/how_threadline_works_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs --max-failures 1` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline/governance/evidence_record_test.exs` — evidence schema and append-only contract proof
- [ ] `test/threadline/evidence/subject_test.exs` — supported-subject and unsupported-subject boundary proof

Existing infrastructure covers doc-contract verification once the new
assertions are added.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Human review that the chosen evidence subjects are truly Threadline-owned and do not smuggle host business-policy semantics into the contract | EVID-03 | "Owned fact" vs "host meaning" remains partly architectural judgment | Read `95-CONTEXT.md`, `95-RESEARCH.md`, the final `Threadline.Evidence.Subject` module, and confirm every allowed subject maps to an existing Threadline-owned governance/posture surface. |
| Human review that append-only semantics are expressed in both schema wording and execution flow, not only in a doc comment | EVID-01 | Tests can prove insert shape, but they do not fully capture semantic misuse by later code | Review `Threadline.Governance.EvidenceRecord`, migration fields, and plan acceptance criteria; confirm new posture is represented by new inserts rather than updates. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or explicit Wave 0 dependencies
- [ ] Code and doc boundary surfaces use the same unsupported-subject story
- [ ] No plan relies on watch-mode or manual-only verification as the main gate
- [ ] `nyquist_compliant: true` set in frontmatter before phase closeout

**Approval:** pending
