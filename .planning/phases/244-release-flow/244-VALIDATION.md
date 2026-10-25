---
phase: "244"
slug: "release-flow"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-24"
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
| REL-01 | Script renames Unreleased, reseeds block, fails on empty prose, idempotent | unit | `mix test test/threadline/date_release_changelog_test.exs` | ❌ W0 | ⬜ pending |
| REL-01 | Sync job runs script before commit and stages CHANGELOG.md | contract | `mix test test/threadline/release_control_plane_contract_test.exs` | ✅ extend | ⬜ pending |
| REL-01 | Renamed CHANGELOG passes shape/version-truth/upgrade contracts | contract | `mix test test/threadline/changelog_contract_test.exs test/threadline/version_truth_doc_contract_test.exs test/threadline/upgrading_to_1_0_doc_contract_test.exs test/threadline/guides/upgrade_path_contract_test.exs` | ✅ | ⬜ pending |
| REL-01 | Rehearsal uses the real script | integration | `mix verify.bump_rehearsal` | ✅ modify | ⬜ pending |
| REL-02 | `always-update` true; PAT on release-please step; sync gated on `prs_created` | contract | `mix test test/threadline/release_control_plane_contract_test.exs` | ✅ extend | ⬜ pending |
| REL-02 | Observed refresh run | evidence | `gh run list --workflow release.yml` / `gh run list --branch release-please--branches--main` | evidence task | ⬜ pending |
| REL-03 | Retry wraps only deps.get/local.hex; no test step retried | contract | `mix test test/threadline/retry_network_contract_test.exs` | ❌ W0 | ⬜ pending |
| REL-04 | Hex pin uniform across jobs and equals audit floor | contract | `mix test test/threadline/hex_pin_contract_test.exs test/threadline/deps_audit_gate_test.exs` | ❌ W0 / ✅ | ⬜ pending |
| All | Workflow parity/topology/token contracts unaffected | contract | `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/ci_action_runtime_contract_test.exs test/threadline/ci_token_permissions_contract_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline/date_release_changelog_test.exs` — REL-01 script behaviour
- [ ] `test/threadline/retry_network_contract_test.exs` — REL-03 rules + mutation controls
- [ ] `test/threadline/hex_pin_contract_test.exs` — REL-04 uniform pin
- [ ] Red-first: each contract lands before the workflow/script edit that satisfies it

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Observed stale-release-PR refresh | REL-02 | Needs an open release PR + a later non-releasable merge on GitHub | Agent-collected evidence (run IDs) recorded in VERIFICATION; no human step |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
