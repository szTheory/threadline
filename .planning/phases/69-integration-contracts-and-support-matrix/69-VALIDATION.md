---
phase: 69
plan: 03
slug: integration-contracts-and-support-matrix
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-07
completed: 2026-05-07
---

# Phase 69 — Validation

> Validation contract for Phase 69 planning.
> This phase freezes the breadth contract, narrows support claims to the proven lanes, and binds those claims to named repo verification anchors.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit source-reading contract tests, Mix alias verification, example-app verification, and CI topology contract tests |
| **Config file** | `mix.exs`, `.github/workflows/ci.yml`, `test/test_helper.exs` |
| **Quick run command** | `mix test test/threadline/integration_contracts_doc_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs test/threadline/integrations/sigra_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/readme_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/phase06_nyquist_ci_contract_test.exs -x` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | Moderate; dominated by `mix verify.example` inside `mix ci.all` |

## Requirement Mapping

| Requirement | Status | Evidence |
|-------------|--------|----------|
| INTEG-01 | complete | `69-01-SUMMARY.md` and `69-VERIFICATION.md` prove the canonical integration-contract guide, corrected callback shapes, and discovery links landed on the final tree. |
| COMPAT-01 | complete | `69-02-SUMMARY.md` and `69-VERIFICATION.md` prove the support matrix now uses `capture-only`, `phoenix-surface`, and `sigra-reference` across the owned doc surfaces. |
| COMPAT-02 | complete | `69-03-SUMMARY.md` and `69-VERIFICATION.md` prove the breadth docs are locked to focused contract tests, `verify.compile_no_optional`, `verify.example`, and stable CI job IDs. |

## Validation Outcome

- Phase 69 completed with the intended three-slice shape: canonical contract -> support lanes -> proof anchors.
- The executed phase stayed inside the locked constraints: no new adapter abstractions, no new hard dependencies, and no CI-topology redesign.
- Final-tree verification succeeded after formatter cleanup on two Phase 69 doc-contract files, so the proof anchors now reflect the actual release gate rather than only per-plan evidence.

## Per-Plan Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 69-01 | 01 | 1 | INTEG-01 | T-69-01..03 | Canonical guide reflects the actual callback/auth contracts, including 1-arity callable shapes and export fallback semantics. | source + docs build | `rg ... guides/integration-contracts.md` and `mix docs` | ✅ | complete |
| 69-02 | 02 | 2 | COMPAT-01 | T-69-04..06 | Support-lane wording stays narrow and the same slice updates the affected doc-contract tests. | source-reading + focused tests | `mix test ...upgrade_path...sigra...readme...example...` | ✅ | complete |
| 69-03 | 03 | 3 | COMPAT-02 | T-69-07..09 | Proof anchors remain tied to current aliases/jobs without speculative CI redesign. | topology + proof commands | `mix verify.compile_no_optional`, `mix verify.example`, focused contract tests, `mix ci.all` | ✅ | complete |

## Wave 0 Requirements

- [x] `.planning/phases/69-integration-contracts-and-support-matrix/69-RESEARCH.md`
- [x] `.planning/phases/69-integration-contracts-and-support-matrix/69-PATTERNS.md`
- [x] `.planning/phases/69-integration-contracts-and-support-matrix/69-VALIDATION.md`

Wave 0 is complete. The planning artifact set now includes the required validation contract.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Support-lane prose remains honest and not marketing-broadened | COMPAT-01 / COMPAT-02 | Human judgment is needed to spot wording that technically passes literal tests but overstates support. | Review `guides/upgrade-path.md`, `guides/integrations/sigra.md`, and `README.md` after execution and confirm the language still distinguishes `supported`, `reference`, and `unclaimed`. |
| Callback examples match the actual callable contract | INTEG-01 | Source-reading tests can miss nuance in code snippets across docs. | Check all touched callback examples in README and `guides/operator-surface.md` for 1-arity function form and accurate export fallback explanation. |

## Validation Sign-Off

- [x] Nyquist validation artifact exists for Phase 69.
- [x] The plan set covers every mapped requirement.
- [x] Verification steps are assigned to the same slice that changes the relevant contract wording.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** completed on 2026-05-08.
