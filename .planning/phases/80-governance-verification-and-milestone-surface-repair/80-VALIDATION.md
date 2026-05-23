---
phase: 80
slug: governance-verification-and-milestone-surface-repair
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-23
---

# Phase 80 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.
> Phase 80 is a current-tree truth-repair slice. The main risk is artifact theater: creating or updating milestone evidence without proving the underlying INFRA requirements or preserving the audit boundary for Phases 81-84.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Planning-artifact checks, targeted ExUnit verification for storage/export queue surfaces, and Mix alias verification |
| **Config file** | `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`; `.planning/STATE.md`; `.planning/PROJECT.md`; `.planning/v1.20-MILESTONE-AUDIT.md`; `mix.exs` |
| **Quick run command** | `mix test test/threadline/export_queue/task_adapter_test.exs test/threadline/export_queue/oban_test.exs test/threadline/storage/local_test.exs test/threadline/storage/s3_test.exs --max-failures 1` |
| **Full suite command** | `mix ci.all` |
| **Compile-no-optional gate** | `mix verify.compile_no_optional` |
| **Estimated runtime — quick** | ~15-30 seconds on a warm cache |
| **Estimated runtime — full** | ~90-180 seconds on a warm cache |

---

## Sampling Rate

- **After the Phase 75 evidence-repair plan:** run the quick suite plus artifact greps for the new `75-VERIFICATION.md` and `75-VALIDATION.md`.
- **After the Phase 79 evidence/bookkeeping repair plan:** run the quick suite plus artifact greps for `79-02-SUMMARY.md`, `79-VALIDATION.md`, and any repaired Phase 79 status language.
- **After milestone-surface reconciliation / before final verification:** run `mix verify.compile_no_optional` and `mix ci.all`.
- **Max feedback latency:** 30 seconds for the quick suite, 180 seconds for the full gate.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 80-01-01 | 01 | 1 | INFRA-01, INFRA-02 | T-80-01 | Phase 75 evidence is rewritten from current-tree proof instead of stale summaries, and it states the shipped governance schema/install/storage/export-queue reality. | artifact + targeted unit | `rg -n 'threadline_export_jobs|threadline_retention_runs|threadline_saved_views|threadline_exports|@callback enqueue|@callback download_url' .planning/phases/75-governance-infrastructure-and-state/75-VERIFICATION.md .planning/phases/75-governance-infrastructure-and-state/75-VALIDATION.md lib/mix/tasks/threadline.install.ex lib/threadline/governance/migration.ex lib/threadline/storage.ex lib/threadline/storage/local.ex lib/threadline/export_queue.ex && mix test test/threadline/export_queue/task_adapter_test.exs test/threadline/export_queue/oban_test.exs test/threadline/storage/local_test.exs test/threadline/storage/s3_test.exs --max-failures 1` | ❌ W0 | ⬜ pending |
| 80-02-01 | 02 | 2 | INFRA-02 | T-80-02 | Phase 79 evidence distinguishes adapter-module implementation from unsatisfied end-to-end runtime flows and restores the missing summary/validation bookkeeping trail. | artifact + targeted unit | `test -f .planning/phases/79-scale-adapters/79-02-SUMMARY.md && rg -n '^phase: 79|^status:|ADAPT-01|ADAPT-02|implemented|integrated|satisfied' .planning/phases/79-scale-adapters/79-02-SUMMARY.md .planning/phases/79-scale-adapters/79-VALIDATION.md .planning/phases/79-scale-adapters/79-VERIFICATION.md && mix test test/threadline/export_queue/task_adapter_test.exs test/threadline/export_queue/oban_test.exs test/threadline/storage/s3_test.exs --max-failures 1` | ❌ W0 | ⬜ pending |
| 80-03-01 | 03 | 3 | INFRA-01, INFRA-02 | T-80-03 | `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, `PROJECT.md`, and `v1.20-MILESTONE-AUDIT.md` all describe the same repaired milestone truth and leave runtime closure with Phases 81-84. | planning artifact + full gate | `rg -n 'Phase 80|INFRA-01\\s+\\| Phase 80 \\| (Pending|Complete)|milestone: v1.20|status: in_progress|Phase 81|Phase 82|Phase 83|Phase 84' .planning/ROADMAP.md .planning/REQUIREMENTS.md .planning/STATE.md .planning/PROJECT.md .planning/v1.20-MILESTONE-AUDIT.md && mix verify.compile_no_optional && mix ci.all` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `.planning/phases/75-governance-infrastructure-and-state/75-VERIFICATION.md` — missing today; must be created from current-tree proof.
- [ ] `.planning/phases/75-governance-infrastructure-and-state/75-VALIDATION.md` — missing today; must be created in Nyquist shape.
- [ ] `.planning/phases/79-scale-adapters/79-02-SUMMARY.md` — missing today; must be restored without overstating requirement closure.
- [ ] `.planning/phases/79-scale-adapters/79-VALIDATION.md` — must be normalized to the newer Nyquist frontmatter and verification-map shape if Phase 80 keeps it as an active truth surface.
- [ ] `.planning/phases/80-governance-verification-and-milestone-surface-repair/80-VALIDATION.md` — created for this phase; update status and per-task rows during execution.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Human review that Phase 80 does not smuggle runtime fixes from Phases 81-84 into an evidence-only slice | INFRA-01, INFRA-02 | The boundary is architectural and status-oriented, not fully machine-checkable | Read the final Phase 80 summaries/verification and confirm retention supervision, session handoff, export runtime, cleanup, and S3-download delivery remain explicitly owned by Phases 81-84. |
| Human review that `PROJECT.md` is narrative-only and no longer contradicts the authoritative milestone files | INFRA-01, INFRA-02 | Narrative drift is easier to catch with a final prose review | Compare the `PROJECT.md` current milestone/current state sections against `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, and the final v1.20 audit after the authoritative files are reconciled. |

---

## Validation Sign-Off

- [x] All planned execution slices have explicit automated verification coverage.
- [x] Artifact repair is tied to current-tree proof commands, not summary-only restatement.
- [x] Final reconciliation is tied to `mix verify.compile_no_optional` and `mix ci.all`.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** planning baseline created on 2026-05-23; update to `status: passed` and mark task rows green only after execution evidence is recorded.
