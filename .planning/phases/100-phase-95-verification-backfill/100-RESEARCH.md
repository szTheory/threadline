# Phase 100: Phase 95 Verification Backfill - Research

**Researched:** 2026-05-26
**Domain:** Current-tree proof, verification backfill, and requirement-closure evidence for the Phase 95 evidence-model boundary
**Confidence:** HIGH for the Phase 95 runtime/doc surfaces and missing-artifact gap; MEDIUM for milestone authority follow-through because `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` were intentionally deferred to Phase 103

## Summary

Phase 100 is a verification-backfill phase, not a new evidence feature phase.
The current tree already contains the implementation Phase 95 was supposed to
close:

- a dedicated append-only `threadline_evidence_records` governance table,
- a stable `Threadline.Governance.EvidenceRecord` schema and changeset,
- a closed `Threadline.Evidence.Subject` registry with explicit unsupported
  subject errors,
- public docs and doc-contract tests that repeat the same non-goal boundary.

What is missing is the closure chain. The v1.22 milestone audit says Phase 95
has no `95-VERIFICATION.md`, so `EVID-01`, `EVID-02`, and `EVID-03` are still
claimed only by summaries and draft validation instead of an explicit
current-tree verification artifact.

**Primary recommendation:** keep Phase 100 narrow. Re-verify the current tree as
it exists today, make only literal truth repairs if a mismatch is found, write
`95-VERIFICATION.md`, finalize `95-VALIDATION.md` around the actual rerun
bundle, and defer milestone authority-surface reconciliation to Phase 103.

## Audit-Driven Gap Definition

The milestone audit localizes the problem precisely:

- `EVID-01` is unclosed because the append-only evidence primitive has code and
  tests, but no phase verification artifact.
- `EVID-02` is unclosed because the record-field contract exists in code/tests,
  but there is no authoritative current-tree proof tying the migration, schema,
  and append-only behavior together.
- `EVID-03` is unclosed because the subject boundary and doc boundary were
  implemented in Phase 95 but never phase-verified.

This means Phase 100 should not redesign evidence storage or subject policy. It
should convert existing truth into auditable evidence.

## Current-Tree Findings

### Verified implementation truth

- `lib/threadline/governance/migration.ex` and
  `priv/repo/migrations/20260525210000_threadline_evidence_records.exs` already
  define the dedicated evidence table.
- `lib/threadline/governance/evidence_record.ex` already expresses the stable
  record contract with required fields and no mutable `updated_at` semantics.
- `test/threadline/governance/evidence_record_test.exs` already proves valid
  insert shape, missing-required-field rejection, and repeated insert
  acceptance for the same logical subject.
- `lib/threadline/evidence/subject.ex` and
  `test/threadline/evidence/subject_test.exs` already enforce a closed
  supported-subject inventory and explicit unsupported examples.
- `guides/how-threadline-works.md` and `guides/integration-contracts.md` plus
  their paired doc-contract tests already repeat the same evidence-plane
  non-goal boundary.

### Verified artifact gap

- `.planning/phases/95-evidence-model-lock-and-scope-guard/95-VERIFICATION.md`
  does not exist.
- `.planning/phases/95-evidence-model-lock-and-scope-guard/95-VALIDATION.md`
  exists only as a draft strategy with `nyquist_compliant: false`.
- The active milestone authority files intentionally still leave `EVID-01`,
  `EVID-02`, and `EVID-03` pending because the backfill chain was split across
  Phases 100-103.

## Verified Risks

### Risk 1: Restating intent instead of verifying the current tree

Phase 95 summaries describe what shipped, but Phase 100 must prove what is on
disk now. If `95-VERIFICATION.md` copies summary prose without re-running the
actual contract suite, it recreates the same audit gap.

### Risk 2: Smuggling Phase 103 authority work into Phase 100

Phase 100 should close the Phase 95 evidence chain, not reconcile every active
planning surface. Requirement/status remapping belongs to Phase 103.

### Risk 3: Over-broad rerun bundles

The authoritative proof for Phase 95 is the evidence-model contract bundle:

- `mix test test/threadline/governance/evidence_record_test.exs --max-failures 1`
- `mix test test/threadline/evidence/subject_test.exs --max-failures 1`
- `mix test test/threadline/how_threadline_works_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs --max-failures 1`

Anything broader is useful repo-health context but should not replace the phase
truth bundle.

## Planning Recommendations

### Plan 100-01: Re-verify the current Phase 95 implementation and boundary

Use the current tree as authority. Re-run the evidence-record, subject, and
doc-contract proof paths. If any literal mismatch remains in the named Phase 95
surfaces, make the smallest truthful repair. Then write `95-VERIFICATION.md`
with explicit sections for:

- append-only evidence contract,
- record-field contract and install-path proof,
- supported-subject inventory and explicit non-goal boundary,
- requirement closure for `EVID-01`, `EVID-02`, and `EVID-03`.

### Plan 100-02: Finalize Nyquist closure for Phase 95

Convert `95-VALIDATION.md` from draft strategy to final Nyquist artifact using
the actual commands run in Plan 100-01. Keep the closure narrow:

- finalize `nyquist_compliant: true`,
- record the executed contract bundle,
- synchronize validation truth with `95-VERIFICATION.md`,
- do not update `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, or
  `.planning/STATE.md` in this phase.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit schema tests, subject-boundary tests, doc-contract tests, and planning-artifact grep verification |
| Quick run | `mix test test/threadline/governance/evidence_record_test.exs test/threadline/evidence/subject_test.exs --max-failures 1` |
| Phase gate | `mix test test/threadline/governance/evidence_record_test.exs test/threadline/evidence/subject_test.exs test/threadline/how_threadline_works_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs --max-failures 1` |

### Requirement Map

| Requirement | Truth to prove | Expected evidence |
|-------------|----------------|-------------------|
| EVID-01 | Threadline owns a dedicated append-only evidence primitive instead of mutable operational rows. | `95-VERIFICATION.md`, evidence-record tests, migration/schema reads |
| EVID-02 | The record contract captures stable subject identity, timestamp, provenance/actor metadata, summary status, and machine-readable detail. | `95-VERIFICATION.md`, evidence-record schema/tests |
| EVID-03 | Supported evidence subjects remain Threadline-owned and the public docs repeat the same boundary. | `95-VERIFICATION.md`, subject tests, doc-contract tests |

## Sources

### Primary

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/v1.22-MILESTONE-AUDIT.md`
- `.planning/phases/95-evidence-model-lock-and-scope-guard/95-CONTEXT.md`
- `.planning/phases/95-evidence-model-lock-and-scope-guard/95-RESEARCH.md`
- `.planning/phases/95-evidence-model-lock-and-scope-guard/95-PATTERNS.md`
- `.planning/phases/95-evidence-model-lock-and-scope-guard/95-01-SUMMARY.md`
- `.planning/phases/95-evidence-model-lock-and-scope-guard/95-02-SUMMARY.md`
- `.planning/phases/95-evidence-model-lock-and-scope-guard/95-VALIDATION.md`
- `.planning/phases/99-contract-lock-docs-and-final-verification/99-VERIFICATION.md`
- `lib/threadline/governance/migration.ex`
- `lib/threadline/governance/evidence_record.ex`
- `lib/threadline/evidence/subject.ex`
- `priv/repo/migrations/20260525210000_threadline_evidence_records.exs`
- `guides/how-threadline-works.md`
- `guides/integration-contracts.md`
- `test/threadline/governance/evidence_record_test.exs`
- `test/threadline/evidence/subject_test.exs`
- `test/threadline/how_threadline_works_doc_contract_test.exs`
- `test/threadline/integration_contracts_doc_contract_test.exs`

## RESEARCH COMPLETE
