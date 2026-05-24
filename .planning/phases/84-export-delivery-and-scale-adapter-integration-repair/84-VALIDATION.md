---
phase: 84
slug: export-delivery-and-scale-adapter-integration-repair
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-24
updated: 2026-05-24T00:00:00Z
---

# Phase 84 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.
> Phase 84 is the final export-runtime closure phase for v1.20. The main risk is overstating adapter-backed delivery closure before the actor-owned controller path, startup validation posture, and repaired evidence surfaces all agree on the same final-tree truth.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Targeted ExUnit controller, LiveView, adapter, application-startup, docs, and planning-artifact verification |
| **Config file** | `config/config.exs`; `config/test.exs`; `lib/threadline/application.ex`; `lib/threadline/operator_surface/controllers/export_controller.ex`; `lib/threadline/operator_surface/live/export_status_live.ex`; `lib/threadline/storage.ex`; `lib/threadline/storage/local.ex`; `lib/threadline/storage/s3.ex`; `lib/threadline/export_queue/oban.ex`; `.planning/phases/79-scale-adapters/79-VERIFICATION.md`; `.planning/phases/79-scale-adapters/79-VALIDATION.md` |
| **Quick run command** | `mix test test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/export_queue/oban_test.exs test/threadline/storage/s3_test.exs --max-failures 1` |
| **Full suite command** | `mix ci.all` |
| **Compile-no-optional gate** | `mix verify.compile_no_optional` |
| **Estimated runtime — quick** | ~15-35 seconds on a warm cache |
| **Estimated runtime — full** | ~90-180 seconds on a warm cache |

---

## Sampling Rate

- Re-run the controller and Export Status tests after any change to delivery resolution, actor-owned authorization, or operator-surface copy/layout.
- Re-run the Oban and S3 adapter tests after any change to adapter config keys, `init/1` validation, or delivery/queue integration behavior.
- Re-run startup/configuration tests whenever `Threadline.Application` changes how configured adapters are initialized.
- Re-run the evidence grep gates whenever Phase 79 or Phase 84 verification/validation artifacts are rewritten so the active truth surface cannot drift out of sync with the repaired runtime.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 84-01-01 | 01 | 1 | EXP-03 | T-84-01 / T-84-02 | `ExportController.download/2` authorizes by actor/job first, then resolves either local `send_file` delivery or adapter-backed redirect without leaking backend URLs into the LiveView HTML. | controller + code-surface | `rg -n 'download\\(|send_file|download_url|redirect|threadline_actor_ref|not_local' lib/threadline/operator_surface/controllers/export_controller.ex lib/threadline/storage/local.ex lib/threadline/storage/s3.ex && mix test test/threadline/operator_surface/controllers/export_controller_test.exs --max-failures 1` | ✅ | ⬜ pending |
| 84-01-02 | 01 | 1 | EXP-03 | T-84-02 / T-84-03 | The Export Status page matches the locked UI contract: `Download Export`, `Preparing download`, `Expires At`, actor-scoped rows, and truthful failed-state messaging with no dead links. | liveview | `mix test test/threadline/operator_surface/live/export_status_live_test.exs --max-failures 1` | ✅ | ⬜ pending |
| 84-02-01 | 02 | 2 | ADAPT-01, ADAPT-02 | T-84-04 / T-84-05 | `Threadline.Application` invokes configured adapter `init/1` callbacks for static validation only, while Oban and S3 adapters expose stable, human-readable failure reasons and explicit config targeting. | application + targeted unit | `mix test test/threadline/application_test.exs test/threadline/export_queue/oban_test.exs test/threadline/storage/s3_test.exs --max-failures 1` | ❌ W0 | ⬜ pending |
| 84-02-02 | 02 | 2 | ADAPT-01 | T-84-05 | The example app and public docs teach the host-owned Oban startup/configuration truth and do not imply Threadline auto-starts optional infrastructure. | docs + contract | `mix test test/threadline/example_phoenix_readme_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs --max-failures 1` | ✅ | ⬜ pending |
| 84-03-01 | 03 | 3 | ADAPT-01, ADAPT-02 | T-84-06 | `79-VERIFICATION.md` and `79-VALIDATION.md` are upgraded to final-tree closure language backed by executable proof instead of adapter-module-only claims. | evidence grep | `rg -n 'ADAPT-01|ADAPT-02|satisfied|download_url|Oban|runtime proof|Phase 84' .planning/phases/79-scale-adapters/79-VERIFICATION.md .planning/phases/79-scale-adapters/79-VALIDATION.md` | ✅ | ⬜ pending |
| 84-03-02 | 03 | 3 | EXP-03, ADAPT-01, ADAPT-02 | T-84-06 | `84-VERIFICATION.md` records current-tree proof for local and remote delivery, startup validation, and actor-owned export status/download behavior without introducing new milestone drift. | evidence grep | `rg -n 'EXP-03|ADAPT-01|ADAPT-02|Observable Truths|Download Export|download_url|Oban|S3|actor-owned' .planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-VERIFICATION.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `.planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-CONTEXT.md`
- [x] `.planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-RESEARCH.md`
- [x] `.planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-01-PLAN.md`
- [x] `.planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-02-PLAN.md`
- [x] `.planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-03-PLAN.md`
- [ ] `test/threadline/application_test.exs` — startup validation proof for configured adapters
- [ ] `.planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-VERIFICATION.md`

Wave 0 for planning is complete. Execution remains responsible for adding the missing startup-validation test surface and the final Phase 84 verification artifact.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Human review that Phase 84 keeps one storage-agnostic operator affordance while hiding backend-specific delivery details behind the controller | EXP-03 | The main failure mode is UX or architecture drift rather than missing targeted tests | Read `84-VERIFICATION.md` after execution and confirm the UI still presents one `Download Export` action while local and remote backends diverge only after actor authorization in the controller path. |
| Human review that startup validation preserves host ownership of Oban/S3 runtime concerns | ADAPT-01, ADAPT-02 | The distinction between static validation and runtime liveness is architectural, not fully machine-checkable | Review the final adapter/application changes and confirm `init/1` checks only dependency/config truth, while host-owned supervision/network state remain operation-time concerns. |

---

## Validation Sign-Off

- [x] Every planned runtime or evidence behavior has a targeted automated command or an explicit Wave 0 dependency.
- [x] Sampling continuity is preserved across controller delivery, LiveView status rendering, adapter startup validation, host-doc truth, and evidence-surface repair.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** planning-ready on 2026-05-24; finalize after Phase 84 execution proves delivery resolution, adapter validation, and repaired evidence closure on the current tree.
