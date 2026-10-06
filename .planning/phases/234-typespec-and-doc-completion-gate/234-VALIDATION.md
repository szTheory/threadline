---
phase: "234"
slug: "typespec-and-doc-completion-gate"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-04"
validated: "2026-10-05"
---

# Phase 234 — Validation Strategy

> The D-28 spec-contract violation was fixed in Plan 12 and reconfirmed by Plan 15's compiled public-spec probe, strict Dialyzer, focused caller-message test, and independent D-46 PASS. Plan 19's advisory reachability and accountable-ignore gates passed, followed by a fresh full `mix ci.all` pass in Plan 15. Validation gates are green; the normal phase verifier still regenerates `VERIFICATION.md`.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, dialyxir 1.4.8, ExDoc 0.40.1 |
| **Config file** | `test/test_helper.exs`, `mix.exs`, `.dialyzer_ignore.exs` |
| **Quick run command** | `mix test test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs test/threadline/facade_naming_contract_test.exs test/threadline/dialyzer_ignore_contract_test.exs test/threadline/dialyzer_slice_contract_test.exs test/threadline/source_size_contract_test.exs` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | Focused gates ~13 seconds; full suite several minutes; cold Dialyzer PLT rebuild ~9 minutes |

## Sampling Rate

- After each plan task, run its focused ExUnit command from that plan's `<automated>` verify block.
- After each plan, run `mix verify.dialyzer` and `MIX_ENV=dev mix docs --warnings-as-errors` where specified.
- Before phase verification, run `mix ci.all`; Plan 15's fresh post-Plan-19 run passed on 2026-10-06.
- Max feedback latency observed in this audit: ~13 seconds for the focused contract suite.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 234-01-T1 | 01 | 1 | SPEC-01 | T-234-01 | Docs/spec gate detects missing and fabricated coverage | unit | `mix test test/threadline/doc_spec_coverage_contract_test.exs` | ✅ | ✅ green |
| 234-01-T2 | 01 | 1 | SPEC-01, SPEC-02 | T-234-02 | Hidden pin and facade-group pins cannot drift | unit | `mix test test/threadline/doc_spec_coverage_contract_test.exs test/threadline/dialyzer_ignore_contract_test.exs test/threadline/facade_naming_contract_test.exs` | ✅ | ✅ green |
| 234-01-T3 | 01 | 1 | SPEC-01, SPEC-02 | T-234-02 | Rubric, parity, bare-type, and style contracts stay exact | unit | `mix test test/threadline/doc_rubric_contract_test.exs test/threadline/doc_spec_coverage_contract_test.exs test/threadline/facade_naming_contract_test.exs` | ✅ | ✅ green |
| 234-02-T1 | 02 | 2 | SPEC-01, SPEC-02 | T-234-03 | Unknown row-history options are rejected and return shapes stay honest | integration | `mix test test/threadline/option_allowlist_test.exs test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs test/threadline/transaction_lookup_test.exs test/threadline/investigation_test.exs test/threadline/row_history_test.exs` | ✅ | ✅ green |
| 234-02-T2 | 02 | 2 | SPEC-01, SPEC-02 | T-234-05 | Lookup return-shape and option contracts catch drift | integration | `mix test test/threadline/transaction_lookup_test.exs test/threadline/lookup_return_shapes_contract_test.exs test/threadline/option_allowlist_test.exs test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs test/threadline/changelog_contract_test.exs` | ✅ | ✅ green |
| 234-02-T3 | 02 | 2 | SPEC-01, SPEC-02 | T-234-04 | Actor LiveView uses internal query API and docs no longer advise override | integration | `mix test test/threadline/operator_surface/live/actor_live_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/query_test.exs test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs` | ✅ | ✅ green |
| 234-02-T4 | 02 | 2 | SPEC-01, SPEC-02 | T-234-03 | Facade option reads, deprecations, and docs remain aligned | integration | `mix test test/threadline/option_allowlist_test.exs test/threadline/query_test.exs test/threadline/operator_surface/live/actor_live_test.exs test/threadline/actor_reads_doc_contract_test.exs test/threadline/deprecation_parity_test.exs test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs test/threadline/changelog_contract_test.exs test/threadline/source_size_contract_test.exs` | ✅ | ✅ green |
| 234-02-T5 | 02 | 2 | SPEC-01, SPEC-02 | T-234-03 | Investigation and export facade option/results contracts stay aligned | integration | `mix test test/threadline/option_allowlist_test.exs test/threadline/investigation_test.exs test/threadline/export_test.exs test/threadline/deprecation_parity_test.exs test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs test/threadline/changelog_contract_test.exs` | ✅ | ✅ green |
| 234-02-T6 | 02 | 2 | SPEC-01, SPEC-02, SPEC-03 | T-234-02 | Facade grouping, hidden surface, generated docs, and Dialyzer contracts are pinned | unit + docs | `mix test test/threadline/facade_naming_contract_test.exs test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs test/threadline/source_size_contract_test.exs test/threadline/public_surface_contract_test.exs test/threadline/deprecation_parity_test.exs test/threadline/facade_only_references_contract_test.exs test/threadline/operator_surface/row_history_component_test.exs` | ✅ | ✅ green |
| 234-03-T1 | 03 | 3 | SPEC-01, SPEC-02 | — | Evidence write API behavior and specs agree | integration | `mix test test/threadline/evidence_test.exs test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs` | ✅ | ✅ green |
| 234-03-T2 | 03 | 3 | SPEC-01, SPEC-02 | — | Evidence reads/writes and CLI docs remain consistent | integration | `mix test test/threadline/evidence_test.exs test/threadline/evidence test/threadline/evidence_cli_doc_contract_test.exs test/mix/tasks/threadline.evidence_show_test.exs test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs` | ✅ | ✅ green |
| 234-03-T3 | 03 | 3 | SPEC-01, SPEC-02 | T-234-07/T-234-08 | Proof entry points, hidden helpers, and CHANGELOG surface remain pinned | integration | `mix test test/threadline/evidence/proof_test.exs test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs test/threadline/changelog_contract_test.exs test/threadline/public_surface_contract_test.exs` | ✅ | ✅ green |
| 234-04-T1 | 04 | 4 | SPEC-01, SPEC-02 | T-234-09/T-234-11 | Export options are closed and moved operator call sites work | integration | `mix test test/threadline/option_allowlist_test.exs test/threadline/export_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/mix/tasks/threadline/export_test.exs test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs test/threadline/source_size_contract_test.exs` | ✅ | ✅ green |
| 234-04-T2 | 04 | 4 | SPEC-01, SPEC-02 | T-234-09 | Export and ChangeDiff option/result contracts stay closed and typed | integration | `mix test test/threadline/option_allowlist_test.exs test/threadline/export_test.exs test/threadline/change_diff_test.exs test/mix/tasks/threadline/export_test.exs test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs test/threadline/changelog_contract_test.exs test/threadline/source_size_contract_test.exs` | ✅ | ✅ green |
| 234-04-T3 | 04 | 4 | SPEC-01, SPEC-02 | T-234-11 | Export adapters and walkthrough examples remain usable | integration | `mix test test/threadline/export_queue/task_adapter_test.exs test/threadline/code_walkthrough_doc_contract_test.exs test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs` | ✅ | ✅ green |
| 234-04-T4 | 04 | 4 | SPEC-01, SPEC-02 | T-234-10 | Storage identifier exposure and hidden helper call sites remain constrained | unit | `mix test test/threadline/storage_schema_call_site_contract_test.exs test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs test/threadline/public_surface_contract_test.exs test/threadline/changelog_contract_test.exs` | ✅ | ✅ green |
| 234-04-T5 | 04 | 4 | SPEC-01, SPEC-02 | — | Health findings and operator docs/types stay aligned | integration | `mix test test/threadline/health_findings_doc_contract_test.exs test/threadline/production_checklist_doc_contract_test.exs test/threadline/health_test.exs test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs` | ✅ | ✅ green |
| 234-04-T6 | 04 | 4 | SPEC-01, SPEC-02 | — | Telemetry docs and runtime event behavior stay aligned | integration | `mix test test/threadline/telemetry_doc_contract_test.exs test/threadline/telemetry_test.exs test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs` | ✅ | ✅ green |
| 234-04-T7 | 04 | 4 | SPEC-01, SPEC-02 | T-234-09 | Auth, retention, and policy docs/types and example app are verified | integration | `mix test test/threadline/operator_surface_doc_contract_test.exs test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs test/threadline/public_surface_contract_test.exs test/threadline/option_allowlist_test.exs test/threadline/source_size_contract_test.exs` | ✅ | ✅ green |
| 234-05-T1 | 05 | 5 | SPEC-01, SPEC-02 | — | ActorRef serialization and precise facade type contracts hold | unit | `mix test test/threadline/semantics/actor_ref_test.exs test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs` | ✅ | ✅ green |
| 234-05-T2 | 05 | 5 | SPEC-01, SPEC-02 | — | Capture/semantics fields remain correctly typed without layer inversion | integration | `mix test test/threadline/capture_semantics_boundary_test.exs test/threadline/layer_boundary_contract_test.exs test/threadline/semantics/audit_action_test.exs test/threadline/audit_transaction_test.exs test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs` | ✅ | ✅ green |
| 234-05-T3 | 05 | 5 | SPEC-01, SPEC-02 | — | Page, error, findings, and transaction result shapes remain accurate | integration | `mix test test/threadline/page_test.exs test/threadline/not_found_error_test.exs test/threadline/health_findings_doc_contract_test.exs test/threadline/audit_doc_contract_test.exs test/threadline/health_test.exs test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs` | ✅ | ✅ green |
| 234-06-T1 | 06 | 6 | SPEC-01, SPEC-02 | — | Strict Dialyzer findings in facade/query cohort are fixed | static + integration | `MIX_ENV=dev mix dialyzer --no-check --missing_return --underspecs --error_handling`; `mix verify.dialyzer` | ✅ | ✅ green |
| 234-06-T2 | 06 | 6 | SPEC-01, SPEC-02 | — | Lookup/export/proof result specs match behavior under strict flags | static + integration | `MIX_ENV=dev mix dialyzer --no-check --missing_return --underspecs --error_handling`; `mix verify.dialyzer` | ✅ | ✅ green |
| 234-06-T3 | 06 | 6 | SPEC-01, SPEC-02 | — | Raise-only helpers use `no_return()` only when private | static contract | Focused ExUnit probe for exported bang specs; Plan 15 reran compiled probe and exact caller-message test | ✅ | ✅ resolved in Plan 12; reconfirmed in Plan 15 |
| 234-06-T4 | 06 | 6 | SPEC-01, SPEC-02 | T-234-14 | Exact strict flags and zero-ignore policy stay pinned | unit + static | `mix test test/threadline/dialyzer_ignore_contract_test.exs test/threadline/dialyzer_slice_contract_test.exs`; `mix verify.dialyzer`; `mix verify.dialyzer_slice` | ✅ | ✅ green |
| 234-06-T5 | 06 | 6 | SPEC-01, SPEC-02, SPEC-03 | T-234-01/T-234-02 | Zero-gap doc/spec gate, live mutation record, size pin, and handoff notes stay enforced | unit + docs | `mix test test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs test/threadline/facade_naming_contract_test.exs test/threadline/source_size_contract_test.exs test/threadline/changelog_contract_test.exs test/threadline/public_surface_contract_test.exs` | ✅ | ✅ green |
| 234-06-T6 | 06 | 6 | SPEC-01, SPEC-02, SPEC-03 | T-234-15 | Docs build, example, CI aggregate, and D-46 review input are complete | integration | `MIX_ENV=dev mix docs --warnings-as-errors`; `mix verify.example`; `mix ci.all` | ✅ | ✅ green |

Plan and summary artifacts provide the recorded task-level pass evidence. In this audit, the six central contract suites passed (70 tests, 0 failures, 1 excluded), `mix verify.dialyzer` passed with 0 errors, and `MIX_ENV=dev mix docs --warnings-as-errors` passed. Plan 234-06 records its earlier `mix ci.all` pass (2,986 root tests, 130 example tests, 0 failures; strict Dialyzer 0 errors). Plan 15's fresh post-Plan-19 `mix ci.all` also passed: 3,006 root tests and 130 example tests with 0 failures, strict Dialyzer with 0 errors, live Dialyzer slice 17/0, npm audit with 0 vulnerabilities, and Playwright 318 passed / 26 intentionally skipped across desktop and mobile Chromium.

### Resolved escalated gap

| Task ID | Requirement | Finding | Probe result | Disposition |
|----------|-------------|---------|--------------|-------------|
| 234-06-T3 | SPEC-02 / D-28 | `Threadline.CriticTrust.RepositoryBoundary.task_error!/3` was exported with a `no_return()` spec, contrary to D-28. | The initial focused ExUnit contract probe failed once with `[task_error!: 3]` (1 test, 1 failure), identifying a spec-contract failure rather than a runtime failure. Plan 12 made both task helpers private and preserved all four messages. Plan 15's compiled probe confirmed neither helper is exported and no exported bang spec in either module returns `no_return()`; the focused test passed all four caller-visible error paths (31 tests, 0 failures). Strict Dialyzer passed with zero errors, and the fresh independent D-46 report records a PASS. | RESOLVED in Plan 12; reconfirmed in Plan 15 after fresh D-46 PASS. |

## Wave 0 Requirements

- [x] `test/threadline/doc_spec_coverage_contract_test.exs` — zero-gap coverage gate, vacuity sentinels, fixture and mutation checks.
- [x] `test/threadline/doc_rubric_contract_test.exs` — parity, doc rubric, bare-type and type-reference checks.
- [x] `234-SPEC-RUBRIC.md` and partition-weight entries exist and are covered by plan checks.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Spec/doc informativeness judgment against the frozen rubric | SPEC-02 / D-46 | Requires independent judgment over the generated review dump. Project policy assigns this to a fresh agent, not a person; the D-46 review remains part of phase verification. | Have the phase verifier compare `234-REVIEW-INPUT.md` against `234-SPEC-RUBRIC.md` and record the result in the phase verification artifact. |

## Validation Sign-Off

- [x] All planned tasks have automated verification or the recorded Wave 0 dependencies.
- [x] Sampling continuity: no three consecutive tasks lack automated verification.
- [x] Wave 0 covers the documented validation dependencies.
- [x] No watch-mode flags.
- [x] Focused feedback latency is under 15 seconds.
- [x] `nyquist_compliant: true` — Plan 15's focused evidence tests, D-28 compiled probe and four-path test, strict Dialyzer, current independent D-46 PASS/integrity check, and fresh post-Plan-19 full `mix ci.all` all pass.

**Approval:** Validation gates passed on 2026-10-06; the normal Phase 234 verifier must still regenerate `VERIFICATION.md`. No human UAT requested.

## Validation Audit 2026-10-05

| Metric | Count |
|--------|-------|
| Tasks audited | 28 |
| Tasks with green recorded automated coverage | 27 |
| Tasks with a confirmed escalated criterion | 1 |
| Confirmed gaps found | 1 |
| Behavioral/runtime gaps | 0 |
| Spec-contract gaps escalated | 1 |
| New permanent tests added | 0 |
