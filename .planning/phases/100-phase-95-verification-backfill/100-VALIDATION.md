---
phase: 100
slug: phase-95-verification-backfill
status: finalized
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-26
updated: 2026-05-27T10:20:47.000Z
---

# Phase 100 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.
> Phase 100 is a verification-backfill slice. The main risks are proving only
> summary prose instead of the current Phase 95 tree, widening the rerun bundle
> beyond the actual evidence-model contract, and accidentally treating
> milestone-authority reconciliation as Phase 100 scope.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit schema tests, subject-boundary tests, doc-contract tests, and planning-artifact grep verification |
| **Config file** | `mix.exs`, `.planning/phases/95-evidence-model-lock-and-scope-guard/95-VALIDATION.md`, `.planning/phases/95-evidence-model-lock-and-scope-guard/95-VERIFICATION.md` |
| **Quick run command** | `mix test test/threadline/governance/evidence_record_test.exs test/threadline/evidence/subject_test.exs --max-failures 1` |
| **Full suite command** | `mix test test/threadline/governance/evidence_record_test.exs test/threadline/evidence/subject_test.exs test/threadline/how_threadline_works_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs --max-failures 1` |
| **Estimated runtime** | ~15-30 seconds warm |

---

## Sampling Rate

- After any literal truth repair in `100-01`: run the quick suite.
- Before finalizing `95-VERIFICATION.md`: run the full Phase 95 contract suite.
- After writing `95-VALIDATION.md` in `100-02`: grep the artifact for exact
  requirement IDs, commands, and Nyquist markers.
- Do not use `mix ci.all` as the authority for this phase; it is broader
  repo-health evidence and not required to close the Phase 95 verification gap.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 100-01-01 | 01 | 1 | EVID-01, EVID-02 | T-100-01 / T-100-02 | The current tree still uses one dedicated append-only evidence table and one stable schema contract with no mutable row semantics. | schema + migration | `mix test test/threadline/governance/evidence_record_test.exs --max-failures 1` | ✅ | ⬜ pending |
| 100-01-02 | 01 | 1 | EVID-03 | T-100-03 | Supported evidence subjects stay closed and the docs repeat the same non-goal boundary. | subject + doc-contract | `mix test test/threadline/evidence/subject_test.exs test/threadline/how_threadline_works_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs --max-failures 1 && rg -n 'EVID-01|EVID-02|EVID-03|append-only|unsupported_subject|legal hold|vendor-reporting|RBAC|tenancy' .planning/phases/95-evidence-model-lock-and-scope-guard/95-VERIFICATION.md` | ✅ | ⬜ pending |
| 100-02-01 | 02 | 2 | EVID-01, EVID-02, EVID-03 | T-100-04 | `95-VALIDATION.md` records the actual proof bundle and final Nyquist status for the Phase 95 closure chain. | artifact review | `rg -n '^phase: 95|^nyquist_compliant: true|^wave_0_complete: true|EVID-01|EVID-02|EVID-03|## Commands Actually Used|evidence_record_test\\.exs|subject_test\\.exs|how_threadline_works_doc_contract_test\\.exs|integration_contracts_doc_contract_test\\.exs' .planning/phases/95-evidence-model-lock-and-scope-guard/95-VALIDATION.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing ExUnit proof surfaces already exist for the evidence-record
  contract, subject boundary, and public doc boundary.
- [ ] `.planning/phases/95-evidence-model-lock-and-scope-guard/95-VERIFICATION.md`
  — to be created in `100-01`.
- [ ] `.planning/phases/95-evidence-model-lock-and-scope-guard/95-VALIDATION.md`
  — to be finalized in `100-02`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Distinguish Phase 95 closure from milestone-authority closure | EVID-01, EVID-02, EVID-03 | The phase boundary is a planning-truth judgment, not just a test result. | After updating `95-VERIFICATION.md` and `95-VALIDATION.md`, confirm `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` remain unchanged so Phase 103 still owns authority-surface reconciliation. |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [x] All planned tasks have explicit automated verification coverage.
- [x] Sampling continuity stays below the three-task Nyquist gap.
- [x] The authoritative rerun bundle is scoped to the Phase 95 contract only.
- [ ] `nyquist_compliant: true` will be set after execution evidence is recorded.

**Approval:** pending
