---
phase: "218"
slug: "ci-economy-remove-waste"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-27"
---

# Phase 218 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17.3-otp-27) contract tests under `test/threadline/`, plus table-tested `bin/` scripts driven through a fake `gh` |
| **Config file** | `test/test_helper.exs` (exclude list changes in the `:live_dialyzer` plan) |
| **Quick run command** | `mix test <touched contract test files>` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | ~20 seconds quick; full `ci.all` several minutes (Dialyzer + 2-project browser lane) |

---

## Sampling Rate

- **After every task commit:** Run the touched contract test files (quick run command)
- **After every plan wave:** Run `mix test test/threadline/ci_topology_contract_test.exs test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_coverage_doc_contract_test.exs test/threadline/release_control_plane_contract_test.exs test/threadline/flake_classifier_contract_test.exs test/threadline/dialyzer_slice_contract_test.exs test/threadline/zero_skips_contract_test.exs test/threadline/ci_issue_upsert_contract_test.exs`
- **Before `/gsd-verify-work`:** `mix test`, `mix ci.all` and `bin/verify-repo-hygiene` must be green (a Dialyzer red in `ci.all` is a PLT miss first: rebuild with `MIX_ENV=dev mix dialyzer --plt`)
- **Max feedback latency:** 60 seconds for the quick command

---

## Per-Task Verification Map

Seeded from 218-RESEARCH.md § Validation Architecture; the planner binds task IDs.

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| ECON-01 | Classifier rows: `inconclusive`, `broken-upstream`, old rows unchanged | unit (script table) | `mix test test/threadline/flake_classifier_contract_test.exs` | ✅ extend | ⬜ pending |
| ECON-01 | Green-SHA gate decisions (schedule+green skip, dispatch runs, CI red → broken-upstream, gh error → run) | unit (fake gh) | `mix test test/threadline/ci_sha_gate_contract_test.exs` | ❌ W0 | ⬜ pending |
| ECON-01 | Flake workflow shape: weekly cron + dispatch, `timeout` wrapper, step < job timeout, `actions: read` | contract | `mix test test/threadline/flake_classifier_contract_test.exs` | ✅ extend | ⬜ pending |
| ECON-01 | OS-family context absent from every workflow | contract | `mix test test/threadline/ci_workflow_parity_contract_test.exs` | ✅ extend | ⬜ pending |
| ECON-02 | `--close` path: 0 → none, 1 → comment+close, >1 → fail closed | unit (fake gh) | `mix test test/threadline/ci_issue_upsert_contract_test.exs` | ✅ extend | ⬜ pending |
| ECON-02 | #28 and #36 closed with a cited green run | evidence | `gh issue view 28 --json state`; `gh issue view 36 --json state` | n/a | ⬜ pending |
| ECON-03 | PAT-absence guard on bootstrap dispatch; no run queries | contract + mutation | `mix test test/threadline/release_control_plane_contract_test.exs` | ✅ extend | ⬜ pending |
| ECON-04 | CI ∪ Browser-full == config project set; CI ∩ BF == ∅ | contract | `mix test test/threadline/browser_full_projects_contract_test.exs` | ❌ W0 | ⬜ pending |
| ECON-04 | CI Coverage doc rows match the union | doc contract | `mix test test/threadline/ci_coverage_doc_contract_test.exs` | ✅ extend | ⬜ pending |
| ECON-05 | Verifier red on "Could not read PLT" and on missing `done (` marker (runtime-built fixture) | unit | `mix test test/threadline/dialyzer_slice_contract_test.exs` | ✅ extend | ⬜ pending |
| ECON-05 | Live proof with real PLT | integration (tagged) | `MIX_ENV=test mix test test/threadline/dialyzer_slice_contract_test.exs --only live_dialyzer` | ✅ | ⬜ pending |
| ECON-05 | Exclude list == {pgbouncer_topology, live_dialyzer}; verify-dialyzer runs the tagged test | contract | `mix test test/threadline/zero_skips_contract_test.exs test/threadline/ci_topology_contract_test.exs` | ✅ extend | ⬜ pending |
| ECON-06 | Roster parity, setup-beam count, dominance pins | contract | `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs` | ✅ extend | ⬜ pending |
| ECON-07 | Every figure in the re-measure doc cites a run ID or command | doc check | `python3 .planning/phases/218-ci-economy-remove-waste/tools/check-citations.py <doc>` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline/ci_sha_gate_contract_test.exs` — gate decision table with fake `gh` (ECON-01, ECON-04 nightly skip)
- [ ] `test/threadline/browser_full_projects_contract_test.exs` — union/intersection + mutation controls (ECON-04)
- [ ] `.planning/phases/218-ci-economy-remove-waste/tools/` — copies of the 214 `collect-ci-runs.sh`, `summarize-ci.py`, `check-citations.py` with only the self-path retargeted (ECON-07)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Branch reaches the remote so post-landing runs exist | ECON-07 | Push/publish is a maintainer-only action | Maintainer grants the push; the executor then dispatches Flake Detection and Browser-full and collects ≥5 CI runs |

*All other phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
