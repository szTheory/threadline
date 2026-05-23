---
phase: 79
slug: scale-adapters
status: passed
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-23
updated: 2026-05-23T13:39:11Z
---

# Phase 79 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.
> Phase 79 is a scale-adapter implementation phase. The repaired final-tree risk is overclaiming end-to-end closure when the current host/runtime path only proves the optional adapter modules and their isolated tests.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Planning-artifact checks, focused ExUnit adapter tests, and code-surface grep verification |
| **Config file** | `mix.exs`; `lib/threadline/export_queue.ex`; `lib/threadline/storage.ex`; `lib/threadline/export_queue/oban.ex`; `lib/threadline/storage/s3.ex`; `lib/threadline/operator_surface/controllers/export_controller.ex`; `.planning/v1.20-MILESTONE-AUDIT.md` |
| **Quick run command** | `mix test test/threadline/export_queue/oban_test.exs test/threadline/storage/s3_test.exs --max-failures 1` |
| **Full suite command** | `mix ci.all` |
| **Compile-no-optional gate** | `mix verify.compile_no_optional` |
| **Estimated runtime — quick** | ~10-25 seconds on a warm cache |
| **Estimated runtime — full** | ~90-180 seconds on a warm cache |

---

## Sampling Rate

- Run the focused Oban and S3 adapter tests after implementation changes.
- Re-run artifact/status checks whenever milestone truth is repaired so the active evidence surface does not silently drift back to `satisfied`.
- Defer full-suite proof to the later milestone reconciliation phase rather than claiming end-to-end closure here.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 79-01-01 | 01 | 1 | ADAPT-01, ADAPT-02 | T-80-02 | Behaviour contracts expose `init/1` safeguards without breaking the built-in adapters. | code-surface + targeted unit | `rg -n '@callback init|optional: true' mix.exs lib/threadline/export_queue.ex lib/threadline/storage.ex && mix test test/threadline/export_queue/task_adapter_test.exs test/threadline/storage/local_test.exs --max-failures 1` | ✅ | ✅ green |
| 79-02-01 | 02 | 2 | ADAPT-01 | T-80-02 | The Oban adapter is implemented and guarded, but startup/runtime closure is not overstated beyond the current tree. | artifact + targeted unit | `test -f .planning/phases/79-scale-adapters/79-02-SUMMARY.md && rg -n 'Oban|ADAPT-01|implemented|integrated|satisfied|startup|runtime proof' .planning/phases/79-scale-adapters/79-02-SUMMARY.md .planning/phases/79-scale-adapters/79-VERIFICATION.md .planning/phases/79-scale-adapters/79-VALIDATION.md && mix test test/threadline/export_queue/oban_test.exs --max-failures 1` | ✅ | ✅ green |
| 79-03-01 | 03 | 3 | ADAPT-02 | T-80-03 | The S3 adapter is implemented and tested, while the active evidence explicitly preserves the `path/1` versus `download_url/2` operator-flow gap. | artifact + targeted unit | `rg -n 'S3|ADAPT-02|implemented|integrated|satisfied|path/1|download_url/2|not_local' .planning/phases/79-scale-adapters/79-VERIFICATION.md .planning/phases/79-scale-adapters/79-VALIDATION.md lib/threadline/storage/s3.ex lib/threadline/operator_surface/controllers/export_controller.ex && mix test test/threadline/storage/s3_test.exs --max-failures 1` | ✅ | ✅ green |

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

Wave 0 is complete. The full evidence chain exists, and the active truth surface now distinguishes module implementation from adopter-facing runtime closure.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Human review that the active verification surface does not describe ADAPT-01 or ADAPT-02 as fully satisfied | ADAPT-01, ADAPT-02 | The failure mode is wording drift across artifacts rather than broken unit logic | Read `79-VERIFICATION.md` and confirm that Oban and S3 are described as implemented adapter surfaces with open runtime/download integration owned by later phases. |

---

## Validation Sign-Off

- [x] All three Phase 79 plans have explicit automated verification coverage.
- [x] The missing `79-02-SUMMARY.md` evidence trail has been restored.
- [x] The active verification surface distinguishes implemented adapter modules from unsatisfied adopter-facing runtime flows.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** finalized on 2026-05-23 after restoring the missing summary trail and reclassifying adapter closure claims to match the repaired final tree.
