---
phase: "213"
slug: "upgrade-guide-and-0-11-0-release"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: true) (#2117)
status: draft
nyquist_compliant: true
wave_0_complete: false
created: "2026-09-26"
---

# Phase 213 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, real PostgreSQL (`Threadline.Test.MigrationHarness`, `Threadline.Test.LegacyTriggerSQL`); `async: false` for DDL-touching modules |
| **Config file** | `config/test.exs`, `test/test_helper.exs` |
| **Quick run command** | `mix test` on the new upgrade/backfill/rollback/doc-contract files plus the touched contract tests |
| **Full suite command** | `mix verify.test` (phase gate: the full local pre-land list — `mix ci.all`, `mix verify.release`, `mix verify.bump_rehearsal`, `mix release.pins --check`, `MIX_ENV=dev mix docs --warnings-as-errors`, `mix hex.build`, `mix verify.topology`, `mix verify.hex_evaluator`, and the unscoped `mix verify.example_browser` with exactly the 8 known failures) |
| **Estimated runtime** | ~60 seconds scoped; full suite about 2 minutes; `ci.all` 30–70 minutes depending on machine load |

---

## Sampling Rate

- **After every task commit:** Run the targeted `mix test` for the files the task touches.
- **After every plan wave:** Run `mix verify.test`.
- **Before `/gsd-verify-work`:** The full local pre-land list must be green on the milestone branch, and `mix ci.all` must be green on the locally built landing branch.
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

Filled by the planner from plans 213-01..03 (sequential waves 1 → 2 → 3 on one checkout).

| Task | Plan | Wave | Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|------|------|------|-------------|----------|-----------|-------------------|-------------|--------|
| 213-01-T1 (tracer) | 01 | 1 | REL-02 | New guide registered in mix.exs extras + Adopt group, guide graph (19), Adopt landing; six-step order and commands pinned | doc contract + docs build | `mix test test/threadline/upgrading_to_0_11_doc_contract_test.exs test/threadline/guide_graph_contract_test.exs test/threadline/release_artifact_contract_test.exs test/threadline/persona_routing_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs`; `MIX_ENV=dev mix docs --warnings-as-errors` | ❌ W0 (created in task) | ⬜ pending |
| 213-01-T2 | 01 | 1 | REL-02 | Backfill + composite + rollback-cleanup markers, D-04 facts, unrecoverable rows; 0.10.x → 0.11.x upgrade-path entry; README link | doc contract | `mix test test/threadline/upgrading_to_0_11_doc_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs test/threadline/version_truth_doc_contract_test.exs test/threadline/guide_graph_contract_test.exs test/threadline/persona_routing_doc_contract_test.exs` | ✅ (extended) | ⬜ pending |
| 213-01-T3 | 01 | 1 | REL-02 | CHANGELOG `### Security` note (detection, fix, rows already captured), pinned to the 0.11.0/Unreleased block; no banned vocabulary | contract | `mix test test/threadline/changelog_contract_test.exs test/threadline/release_artifact_contract_test.exs test/threadline/upgrading_to_0_11_doc_contract_test.exs` | ✅ (new assertions) | ⬜ pending |
| 213-02-T1 (tracer) | 02 | 2 | REL-02 | Guide-extracted backfill resolves a non-id table's legacy INSERT/UPDATE rows, DELETE untouched, idempotent, history/3 finds rows | real-PG | `mix test test/threadline/upgrade_backfill_test.exs` | ❌ W0 (created in task) | ⬜ pending |
| 213-02-T2 | 02 | 2 | REL-02 | id / composite / shared pair / timestamptz / index / health / interruption edge | real-PG | `mix test test/threadline/upgrade_backfill_test.exs test/threadline/upgrading_to_0_11_doc_contract_test.exs` | ✅ (extended) | ⬜ pending |
| 213-02-T3 | 02 | 2 | REL-03 (local) | Rollback-all: no orphan capture function, foreign triggers survive; suite stays green | real-PG catalog + full suite | `mix test test/threadline/upgrade_rollback_test.exs test/threadline/upgrade_backfill_test.exs test/threadline/query/row_history_index_explain_test.exs`; `mix verify.test` | ❌ W0 (created in task) | ⬜ pending |
| 213-03-T1 (tracer) | 03 | 3 | REL-03 (local) | Dated `## [0.11.0]` entry; contracts green; pins clean; bump rehearsal passes with no stand-in | release shape | `mix test test/threadline/changelog_contract_test.exs test/threadline/version_truth_doc_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs test/threadline/upgrading_to_0_11_doc_contract_test.exs test/threadline/release_artifact_contract_test.exs`; `mix release.pins --check`; `mix verify.bump_rehearsal` (no "synthesising") | ✅ | ⬜ pending |
| 213-03-T2 | 03 | 3 | REL-03 (local) | Full D-11 pre-land list on the final milestone tree, exit codes recorded; browser = exactly 8 known failures | release lane | `mix ci.all`, `mix verify.release`, `mix verify.bump_rehearsal`, `mix release.pins --check`, `MIX_ENV=dev mix docs --warnings-as-errors`, `mix hex.build`, contracts, PgBouncer `mix verify.topology` + `mix verify.threadline`, `mix verify.hex_evaluator`, unscoped `mix verify.example_browser` | ✅ | ⬜ pending |
| 213-03-T3 | 03 | 3 | REL-03 (local) | Local land/v1.42: one ID-free `feat!:` commit on origin/main, tree == milestone outside `.planning/`, zero `.planning/` paths, `mix ci.all` green on it; checkout restored; hand-off recorded; nothing pushed | release lane | `mix ci.all` on land/v1.42 + git tree/diff/log checks in the task's verify block | ✅ | ⬜ pending |
| maintainer | — | — | REL-03 (post-merge) | Push, PR, squash merge, release-please proposes exactly 0.11.0, publish, main green on released SHA, stray branches deleted | maintainer action | recorded hand-off in 213-03-SUMMARY.md, pending | — | ⬜ maintainer |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline/upgrading_to_0_11_doc_contract_test.exs` — D-06
- [ ] `test/threadline/upgrade_backfill_test.exs` — D-08
- [ ] `test/threadline/upgrade_rollback_test.exs` — D-09
- [ ] Literal updates to `guide_graph_contract_test.exs` (adopt lane list, count 18 → 19) and new security-note assertions in `changelog_contract_test.exs`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Push, PR, merge, `production-hex` approval, hex publish, remote branch deletion | REL-03 | Maintainer-only by project rule (push, publish and outward-facing deletions need the maintainer's explicit go; `gh pr merge` is blocked for agents) | The exact ordered command list recorded in the phase SUMMARY and VERIFICATION (D-15) |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
