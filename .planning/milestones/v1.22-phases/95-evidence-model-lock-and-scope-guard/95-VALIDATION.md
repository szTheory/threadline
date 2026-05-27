---
phase: 95
slug: evidence-model-lock-and-scope-guard
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
updated: 2026-05-26T14:54:49Z
---

# Phase 95 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.
> Phase 95 is now closed against the current-tree rerun bundle recorded in
> `95-VERIFICATION.md`, not against summary prose alone.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Targeted ExUnit schema, validator, and doc-contract tests |
| **Config file** | `lib/threadline/governance/migration.ex`, `priv/repo/migrations/20260525210000_threadline_evidence_records.exs`, `lib/threadline/governance/evidence_record.ex`, `lib/threadline/evidence/subject.ex`, `guides/how-threadline-works.md`, `guides/integration-contracts.md` |
| **Quick run command** | `mix test test/threadline/governance/evidence_record_test.exs test/threadline/evidence/subject_test.exs --max-failures 1` |
| **Full suite command** | `mix test test/threadline/governance/evidence_record_test.exs test/threadline/evidence/subject_test.exs test/threadline/how_threadline_works_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs --max-failures 1` |
| **Estimated runtime — quick** | ~10-20 seconds on a warm cache |
| **Estimated runtime — full** | ~15-30 seconds on a warm cache |

---

## Sampling Rate

- Re-run the targeted schema contract whenever the evidence row shape changes.
- Re-run the subject validator whenever supported evidence subjects or unsupported categories change.
- Re-run the doc-contract bundle whenever the public evidence-plane boundary language changes.
- Keep milestone authority-surface reconciliation separate; this validation artifact closes Phase 95 only.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 95-01-01 | 01 | 1 | EVID-01, EVID-02 | T-95-01 / T-95-02 | Evidence rows persist in a dedicated append-only governance table with explicit contract fields. | schema + migration | `mix test test/threadline/governance/evidence_record_test.exs --max-failures 1` | ✅ | ✅ green |
| 95-01-02 | 01 | 1 | EVID-01, EVID-02 | T-95-02 | The current-tree contract still proves repeated inserts for one logical subject and preserves the stable field set. | schema + insert proof | `mix test test/threadline/governance/evidence_record_test.exs --max-failures 1` | ✅ | ✅ green |
| 95-02-01 | 02 | 2 | EVID-03 | T-95-03 / T-95-04 | Unsupported host-owned and compliance-platform subjects are rejected with stable validator errors. | unit | `mix test test/threadline/evidence/subject_test.exs --max-failures 1` | ✅ | ✅ green |
| 95-02-02 | 02 | 2 | EVID-03 | T-95-04 | Public boundary docs still say Threadline does not own RBAC, tenancy DSL, approval workflows, legal hold, or vendor-reporting workflows. | doc-contract | `mix test test/threadline/how_threadline_works_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs --max-failures 1` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Commands Actually Used

1. `mix test test/threadline/governance/evidence_record_test.exs --max-failures 1`
   Result: PASS (`3 tests, 0 failures`)
2. `mix test test/threadline/evidence/subject_test.exs --max-failures 1`
   Result: PASS (`3 tests, 0 failures`)
3. `mix test test/threadline/how_threadline_works_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs --max-failures 1`
   Result: PASS (`6 tests, 0 failures`)

---

## Wave 0 Requirements

- [x] `test/threadline/governance/evidence_record_test.exs` proves the dedicated append-only evidence-record contract.
- [x] `test/threadline/evidence/subject_test.exs` proves the closed supported-subject boundary and stable unsupported_subject errors.
- [x] `test/threadline/how_threadline_works_doc_contract_test.exs` and `test/threadline/integration_contracts_doc_contract_test.exs` prove the public non-goal boundary.
- [x] `95-VERIFICATION.md` now exists and records the authoritative current-tree rerun bundle.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Distinguish Phase 95 closure from milestone-authority closure | EVID-01, EVID-02, EVID-03 | The phase boundary is a planning-truth judgment, not just a test result. | Confirm `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` remain unreconciled here and are still reserved for Phase 103 follow-up. |
| Review append-only semantics as an architectural claim | EVID-01 | The targeted test proves insert behavior, but human review still confirms the chosen model is append-only by design. | Read `95-VERIFICATION.md`, `lib/threadline/governance/evidence_record.ex`, and the checked-in migration; confirm new posture is represented by new inserts rather than updates. |

---

## Phase Boundary Guard

- `95-VALIDATION.md` closes `EVID-01`, `EVID-02`, and `EVID-03` only.
- `.planning/REQUIREMENTS.md` was not reconciled here.
- `.planning/ROADMAP.md` was not reconciled here.
- `.planning/STATE.md` was not reconciled here.
- Phase 96, Phase 98, and milestone closeout work remain outside this validation artifact.

---

## Validation Sign-Off

- [x] All executed tasks have explicit automated verification coverage.
- [x] Sampling continuity stayed below the three-task Nyquist gap.
- [x] The validation artifact records the exact rerun bundle used to close `EVID-01`, `EVID-02`, and `EVID-03`.
- [x] `nyquist_compliant: true` set in frontmatter.
- [x] Phase-boundary limits are stated explicitly so this artifact does not overclaim authority-surface reconciliation.

**Approval:** finalized on 2026-05-26 after Phase 100-01 produced `95-VERIFICATION.md` and the current-tree rerun bundle passed.
