---
phase: 79
slug: scale-adapters
status: passed
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-23
updated: 2026-05-24T11:08:09Z
---

# Phase 79 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.
> Phase 79 is now validated against the repaired final tree rather than the earlier adapter-module-only posture. The main risk is regressing back to wording or runtime drift that breaks configured-path Oban/S3 truth.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Targeted ExUnit startup, adapter, controller, LiveView, and doc-contract verification |
| **Config file** | `config/config.exs`; `config/test.exs`; `lib/threadline/application.ex`; `lib/threadline/export_queue/oban.ex`; `lib/threadline/storage/s3.ex`; `lib/threadline/operator_surface/controllers/export_controller.ex`; `lib/threadline/operator_surface/live/export_status_live.ex` |
| **Quick run command** | `mix test test/threadline/application_test.exs test/threadline/export_queue/oban_test.exs test/threadline/storage/s3_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/live/export_status_live_test.exs --max-failures 1` |
| **Full suite command** | `mix ci.all` |
| **Compile-no-optional gate** | `mix verify.compile_no_optional` |
| **Estimated runtime — quick** | ~15-35 seconds on a warm cache |
| **Estimated runtime — full** | ~90-180 seconds on a warm cache |

---

## Sampling Rate

- Re-run the application and Oban tests after any change to adapter config keys, startup validation, or Oban targeting/error normalization.
- Re-run the S3, controller, and Export Status tests after any delivery-path or operator-surface change touching remote download behavior.
- Re-run the doc-contract tests whenever the example or guides change so the public host-owned contract does not drift away from the repaired runtime.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 79-01-01 | 01 | 1 | ADAPT-01, ADAPT-02 | T-80-02 | Behaviour contracts and optional-dependency posture remain intact while the default adapters stay compile-clean without optional deps. | contract + compile | `rg -n '@callback init|optional: true' mix.exs lib/threadline/export_queue.ex lib/threadline/storage.ex && mix verify.compile_no_optional` | ✅ | ✅ green |
| 79-02-01 | 02 | 2 | ADAPT-01 | T-84-04 / T-84-05 | Configured Oban integration is validated at startup, targets a configured Oban instance/queue, and emits stable enqueue failures without taking over host supervision. | startup + targeted unit | `mix test test/threadline/application_test.exs test/threadline/export_queue/oban_test.exs --max-failures 1` | ✅ | ✅ green |
| 79-03-01 | 03 | 3 | ADAPT-02 | T-84-02 / T-84-05 | S3-backed delivery now flows through the actor-owned controller path via `download_url/2`, and the status UI only renders a truthful download action. | targeted unit + liveview | `mix test test/threadline/storage/s3_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/live/export_status_live_test.exs --max-failures 1` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `.planning/phases/79-scale-adapters/79-01-PLAN.md`
- [x] `.planning/phases/79-scale-adapters/79-02-PLAN.md`
- [x] `.planning/phases/79-scale-adapters/79-03-PLAN.md`
- [x] `.planning/phases/79-scale-adapters/79-01-SUMMARY.md`
- [x] `.planning/phases/79-scale-adapters/79-02-SUMMARY.md`
- [x] `.planning/phases/79-scale-adapters/79-03-SUMMARY.md`
- [x] `.planning/phases/79-scale-adapters/79-VERIFICATION.md`
- [x] `.planning/phases/79-scale-adapters/79-VALIDATION.md`

Wave 0 is complete. The active evidence chain now reflects repaired final-tree closure instead of preserving the earlier downgraded wording.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Human review that the repaired docs still preserve host ownership of Oban supervision while describing startup validation truthfully | ADAPT-01 | The failure mode is architecture drift in prose rather than broken unit logic | Read `examples/threadline_phoenix/README.md` and confirm it describes Threadline startup validation without implying Threadline supervises Oban. |
| Human review that the operator surface still exposes one storage-agnostic `Download Export` action instead of backend-specific UI branches | ADAPT-02 | The failure mode is UX drift rather than missing controller logic | Read `guides/operator-surface.md` and `84-VERIFICATION.md`, then confirm the backend split happens only after controller authorization. |

---

## Validation Sign-Off

- [x] All three Phase 79 plans now have final-tree automated verification coverage.
- [x] The active evidence surface has been upgraded from implemented-only wording to satisfied configured-path closure.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** finalized on 2026-05-24 after Phase 84 closed the remaining startup-validation and actor-owned delivery gaps.
