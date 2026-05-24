---
phase: 84
slug: export-delivery-and-scale-adapter-integration-repair
status: passed
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-24
updated: 2026-05-24T11:08:09Z
---

# Phase 84 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.
> Phase 84 is the final export-runtime closure phase for v1.20. The repaired final-tree risk is overstating closure unless delivery behavior, startup validation, docs, and evidence all prove the same actor-owned contract.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Targeted ExUnit controller, LiveView, startup-validation, adapter, doc-contract, and planning-artifact verification |
| **Config file** | `config/config.exs`; `config/test.exs`; `lib/threadline/application.ex`; `lib/threadline/operator_surface/controllers/export_controller.ex`; `lib/threadline/operator_surface/live/export_status_live.ex`; `lib/threadline/storage/local.ex`; `lib/threadline/storage/s3.ex`; `lib/threadline/export_queue/oban.ex`; `.planning/phases/79-scale-adapters/79-VERIFICATION.md`; `.planning/phases/79-scale-adapters/79-VALIDATION.md`; `.planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-VERIFICATION.md` |
| **Quick run command** | `mix test test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/application_test.exs test/threadline/export_queue/oban_test.exs test/threadline/storage/s3_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs --max-failures 1` |
| **Full suite command** | `mix ci.all` |
| **Compile-no-optional gate** | `mix verify.compile_no_optional` |
| **Estimated runtime — quick** | ~20-45 seconds on a warm cache |
| **Estimated runtime — full** | ~90-180 seconds on a warm cache |

---

## Sampling Rate

- Re-run the controller and Export Status suites after any change to delivery resolution, expiry handling, or operator-surface copy.
- Re-run the application, Oban, and S3 suites after any change to adapter init/config behavior or host-owned runtime targeting.
- Re-run doc-contract tests whenever the example or guides change so the public contract stays aligned with the repaired runtime.
- Re-run the evidence grep gates whenever Phase 79 or Phase 84 closeout artifacts are rewritten.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 84-01-01 | 01 | 1 | EXP-03 | T-84-01 / T-84-02 | `ExportController.download/2` authorizes first, then resolves local `send_file` or adapter-backed redirect without leaking backend-native URLs into LiveView markup. | controller + code-surface | `mix test test/threadline/operator_surface/controllers/export_controller_test.exs --max-failures 1` | ✅ | ✅ green |
| 84-01-02 | 01 | 1 | EXP-03 | T-84-02 / T-84-03 | The Export Status page renders `Download Export`, `Preparing download`, `Expires At`, actor-scoped rows, and truthful failed-state messaging with no dead completed-state links. | liveview | `mix test test/threadline/operator_surface/live/export_status_live_test.exs --max-failures 1` | ✅ | ✅ green |
| 84-02-01 | 02 | 2 | ADAPT-01, ADAPT-02 | T-84-04 / T-84-05 | `Threadline.Application` validates configured adapters at startup for static truth only, while Oban and S3 expose stable human-readable error messages and explicit targeting/config behavior. | application + targeted unit | `mix test test/threadline/application_test.exs test/threadline/export_queue/oban_test.exs test/threadline/storage/s3_test.exs --max-failures 1` | ✅ | ✅ green |
| 84-02-02 | 02 | 2 | ADAPT-01 | T-84-05 / T-84-06 | The example app and guides teach the repaired host-owned Oban and actor-owned export delivery contract without implying Threadline starts optional infrastructure. | docs + contract | `mix test test/threadline/example_phoenix_readme_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs --max-failures 1` | ✅ | ✅ green |
| 84-03-01 | 03 | 3 | ADAPT-01, ADAPT-02 | T-84-06 / T-84-07 | `79-VERIFICATION.md` and `79-VALIDATION.md` now reflect satisfied final-tree closure backed by executable startup, adapter, controller, and doc proof. | evidence grep | `rg -n 'ADAPT-01|ADAPT-02|satisfied|download_url|Oban|host-owned|startup validation' .planning/phases/79-scale-adapters/79-VERIFICATION.md .planning/phases/79-scale-adapters/79-VALIDATION.md` | ✅ | ✅ green |
| 84-03-02 | 03 | 3 | EXP-03, ADAPT-01, ADAPT-02 | T-84-06 / T-84-07 | `84-VERIFICATION.md` and `84-VALIDATION.md` record current-tree proof for actor-owned delivery, startup validation, docs, and repaired evidence closure without milestone wording drift. | evidence grep | `rg -n 'EXP-03|ADAPT-01|ADAPT-02|Observable Truths|Download Export|download_url|Oban|S3|actor-owned' .planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-VERIFICATION.md .planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-VALIDATION.md` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `.planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-CONTEXT.md`
- [x] `.planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-RESEARCH.md`
- [x] `.planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-01-PLAN.md`
- [x] `.planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-02-PLAN.md`
- [x] `.planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-03-PLAN.md`
- [x] `.planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-01-SUMMARY.md`
- [x] `.planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-02-SUMMARY.md`
- [x] `test/threadline/application_test.exs`
- [x] `.planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-VERIFICATION.md`

Wave 0 is complete. Execution has now produced the missing startup-validation proof and first-class Phase 84 verification artifact.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Human review that the repaired export lane still presents one storage-agnostic operator action while hiding backend-specific delivery details behind the controller | EXP-03 | The failure mode is UX or architecture drift rather than missing targeted tests | Read `84-VERIFICATION.md` and confirm local and remote delivery diverge only after actor authorization inside the controller. |
| Human review that startup validation remains limited to static truth and does not claim host ownership of Oban/S3 runtime liveness | ADAPT-01, ADAPT-02 | The boundary is architectural and not fully machine-checkable | Review `lib/threadline/application.ex`, `lib/threadline/export_queue/oban.ex`, and the updated guides, then confirm Oban supervision and external-service runtime remain host-owned. |

---

## Validation Sign-Off

- [x] Every planned runtime and evidence behavior has targeted automated proof on the repaired tree.
- [x] The missing startup-validation test surface and Phase 84 verification artifact now exist.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** finalized on 2026-05-24 after current-tree proof covered delivery resolution, startup validation, public contract alignment, and repaired evidence closure.
