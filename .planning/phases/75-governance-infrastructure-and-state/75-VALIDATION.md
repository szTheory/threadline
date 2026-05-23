---
phase: 75
slug: governance-infrastructure-and-state
status: passed
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-23
updated: 2026-05-23T13:39:11Z
---

# Phase 75 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.
> Phase 75 is validated on the repaired final tree. The primary risk is artifact drift: old prose claiming a smaller behaviour surface or the wrong local export directory even though the shipped tree now proves more precise contracts.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Planning-artifact checks, targeted ExUnit contract tests for built-in adapters, and code-surface grep verification |
| **Config file** | `lib/mix/tasks/threadline.install.ex`; `lib/threadline/governance/migration.ex`; `lib/threadline/governance/export_job.ex`; `lib/threadline/governance/retention_run.ex`; `lib/threadline/governance/saved_view.ex`; `lib/threadline/storage.ex`; `lib/threadline/export_queue.ex`; `lib/threadline/storage/local.ex` |
| **Quick run command** | `mix test test/threadline/export_queue/task_adapter_test.exs test/threadline/storage/local_test.exs --max-failures 1` |
| **Full suite command** | `mix ci.all` |
| **Compile-no-optional gate** | `mix verify.compile_no_optional` |
| **Estimated runtime — quick** | ~10-20 seconds on a warm cache |
| **Estimated runtime — full** | ~90-180 seconds on a warm cache |

---

## Sampling Rate

- Run the governance grep proof before accepting the repaired evidence.
- Run the targeted built-in adapter suite after writing the repaired verification artifact.
- Reuse `mix verify.compile_no_optional` and `mix ci.all` later from the milestone-closeout phase instead of duplicating full-suite claims here.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 75-01-01 | 01 | 1 | INFRA-01 | T-80-01 | `mix threadline.install` and `Threadline.Governance.Migration` prove the governance schema install path on the repaired final tree. | artifact + code-surface | `rg -n 'threadline_governance_schema|threadline_export_jobs|threadline_retention_runs|threadline_saved_views' lib/mix/tasks/threadline.install.ex lib/threadline/governance/migration.ex lib/threadline/governance/export_job.ex lib/threadline/governance/retention_run.ex lib/threadline/governance/saved_view.ex` | ✅ | ✅ green |
| 75-01-02 | 01 | 1 | INFRA-02 | T-80-01 | `Threadline.Storage` and `Threadline.ExportQueue` expose the shipped behaviour contracts, including `path/1`, `download_url/2`, and `enqueue/1`, while `Threadline.Storage.Local` uses `priv/threadline_exports`. | artifact + targeted unit | `rg -n '@callback init|@callback put|@callback get|@callback path|@callback download_url|@callback delete|@callback enqueue|threadline_exports' lib/threadline/storage.ex lib/threadline/export_queue.ex lib/threadline/storage/local.ex .planning/phases/75-governance-infrastructure-and-state/75-VERIFICATION.md .planning/phases/75-governance-infrastructure-and-state/75-VALIDATION.md && mix test test/threadline/export_queue/task_adapter_test.exs test/threadline/storage/local_test.exs --max-failures 1` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `.planning/phases/75-governance-infrastructure-and-state/75-01-PLAN.md`
- [x] `.planning/phases/75-governance-infrastructure-and-state/75-VERIFICATION.md`
- [x] `.planning/phases/75-governance-infrastructure-and-state/75-VALIDATION.md`

Wave 0 is complete. Phase 75 now has explicit current-tree evidence for its governance schemas and behaviour contracts.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Human review that the repaired artifact does not reuse stale `priv/exports` or pre-Phase-79 behaviour wording | INFRA-02 | The strongest failure mode here is language drift rather than broken code | Read `75-VERIFICATION.md` and confirm it names `priv/threadline_exports`, `path/1`, and `download_url/2` exactly as the shipped tree does. |

---

## Validation Sign-Off

- [x] Phase 75 has explicit automated coverage for both repaired requirement surfaces.
- [x] The repaired evidence is tied to current-tree grep proof and targeted adapter tests.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** finalized on 2026-05-23 after the repaired final tree proved the governance install path, schema modules, and behaviour/default surfaces for INFRA-01 and INFRA-02.
