---
phase: "244"
slug: "release-flow"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-24"
validated: "2026-10-25"
---

# Phase 244 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Seeded from `244-RESEARCH.md` → Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17.3 / OTP 27 per `.tool-versions`) |
| **Config file** | `test/test_helper.exs`; contract tests under `test/threadline/` |
| **Quick run command** | `mix test test/threadline/release_control_plane_contract_test.exs test/threadline/changelog_contract_test.exs test/threadline/version_truth_doc_contract_test.exs` |
| **Full suite command** | `mix verify.test` (phase gate: `mix ci.all`) |
| **Estimated runtime** | ~30 seconds quick; full suite several minutes |

---

## Sampling Rate

- **After every task commit:** quick run command plus the one test file the task touched
- **After every plan wave:** `mix verify.test`, `mix verify.credo`, `mix verify.format`, `bin/verify-repo-hygiene`
- **Before `/gsd-verify-work`:** `mix ci.all` green (after local `mix local.hex 2.6.0 --force`) and the phase PR's CI green
- **Max feedback latency:** 60 seconds for the quick loop

---

## Per-Task Verification Map

| Req | Behavior | Test Type | Automated Command | File Exists | Status |
|-----|----------|-----------|-------------------|-------------|--------|
| REL-01 | Script renames Unreleased, reseeds block, fails on empty prose, idempotent | unit | `mix test test/threadline/date_release_changelog_test.exs` | ✅ | ✅ green |
| REL-01 | Sync job runs script before commit and stages CHANGELOG.md | contract | `mix test test/threadline/release_control_plane_contract_test.exs` | ✅ | ✅ green |
| REL-01 | Renamed CHANGELOG passes shape/version-truth/upgrade contracts | contract | `mix test test/threadline/changelog_contract_test.exs test/threadline/version_truth_doc_contract_test.exs test/threadline/upgrading_to_1_0_doc_contract_test.exs test/threadline/guides/upgrade_path_contract_test.exs` | ✅ | ✅ green |
| REL-01 | Rehearsal uses the real script | integration | `mix verify.bump_rehearsal` | ✅ | ✅ green ¹ |
| REL-02 | `always-update` true; PAT on release-please step; sync gated on `prs_created` | contract | `mix test test/threadline/release_control_plane_contract_test.exs` | ✅ | ✅ green |
| REL-02 | Observed refresh run | evidence | `gh run list --workflow release.yml` / `gh run list --branch release-please--branches--main` | evidence task | ⏳ deferred ² |
| REL-03 | Retry wraps only deps.get/local.hex; no test step retried | contract | `mix test test/threadline/retry_network_contract_test.exs` | ✅ | ✅ green |
| REL-04 | Hex pin uniform across jobs and equals audit floor | contract | `mix test test/threadline/hex_pin_contract_test.exs test/threadline/deps_audit_gate_test.exs` | ✅ | ✅ green |
| All | Workflow parity/topology/token contracts unaffected | contract | `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/ci_action_runtime_contract_test.exs test/threadline/ci_token_permissions_contract_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky · ⏳ deferred to landing*

Audit run 2026-10-25 at HEAD `b3cb7797`: the 14 mapped test files ran as one command, 360 tests, 0 failures. `bin/verify-lock-hygiene` over all 4 tracked locks: 134 `:hex` entries clean, exit 0.

¹ `mix verify.bump_rehearsal`: the real `bin/date-release-changelog` dated `[1.2.0]`; doc-contract gate 287/0, changelog contract 9/0, `verify.release` 45/0, tree identity MATCH. The run still exits 1 at the final absolute `surviving worktree` guard (`bin/verify-bump-rehearsal:589`). That guard counts every linked worktree, and this checkout already had 3 (`quality-baseline` plus two v1.46 worktrees). The guard dates from 23f0505a (0.10.0) and is not a phase 244 change. The CI and plain-clone gate (244-10 `ci.all exit=0`) have no linked worktrees, so it passes there. Environmental, not a coverage gap. Possible follow-up: compare against a baseline count (the tree-identity check already does).

² Evidence that only exists after landing; see Manual-Only.

---

## Wave 0 Requirements

- [x] `test/threadline/date_release_changelog_test.exs` — REL-01 script behaviour
- [x] `test/threadline/retry_network_contract_test.exs` — REL-03 rules + mutation controls
- [x] `test/threadline/hex_pin_contract_test.exs` — REL-04 uniform pin
- [x] Red-first: each contract lands before the workflow/script edit that satisfies it (74d631a5→50d08552, f4072de9→a5dc793b, 6c1e451e red before the pin edit)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Observed stale-release-PR refresh | REL-02 | Needs an open release PR + a later non-releasable merge on GitHub | Agent-collected after landing via the read-only `gh` procedure in `244-REL02-EVIDENCE.md` (Status: pending); no human step. Contract half is automated and green. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-10-25 (gsd-validate-phase audit, State A, 0 gaps)

## Validation Audit 2026-10-25

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
