---
phase: "221"
slug: "ci-names-and-order"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-29"
---

# Phase 221 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Source: 221-RESEARCH.md § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17.3), yaml_elixir 2.11.0 (test-only) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/release_control_plane_contract_test.exs` |
| **ci.yml-reader sweep** | the quick files plus `browser_full_projects_contract_test.exs ci_sha_gate_contract_test.exs deps_audit_contract_test.exs deps_health_doc_contract_test.exs main_ci_observer_contract_test.exs planning_dependency_contract_test.exs repo_hygiene_contract_test.exs upgrade_path_doc_contract_test.exs branch_protection_comparison_contract_test.exs optional_deps_contract_test.exs` |
| **Full suite command** | `mix verify.test`, then `bin/verify-repo-hygiene`, `mix verify.format` and `mix verify.credo`; run `mix ci.all` before landing |
| **Tool check** | `python3 .planning/phases/221-ci-names-and-order/tools/time-to-red.py check`. It runs offline, against the committed raw JSON. |
| **Estimated runtime** | quick ~4 s, sweep ~14 s, full ~200 s |

---

## Sampling Rate

- **After every task commit:** the quick command. Add `bin/verify-repo-hygiene` if the commit touches `.planning`.
- **After every plan wave:** the ci.yml-reader sweep, then `mix verify.format` and `mix verify.credo`.
- **Before `/gsd-verify-work`:** `mix verify.test` is fully green and `mix ci.all` is green. If `mix ci.all` goes red at Dialyzer from a PLT cache miss, rebuild with `mix dialyzer --plt`.
- **Max feedback latency:** 15 s for the quick and sweep commands.

---

## Per-Task Verification Map

| SC | Behavior | Test Type | Automated Command | File Exists | Status |
|----|----------|-----------|-------------------|-------------|--------|
| SC-1 | Every name states what it proves. The evaluator name is truthful. The CONTRIBUTING quotes change in the same commit. | contract + doc-contract | the quick command (name rules), plus `git show --stat <rename sha>` listing ci.yml and CONTRIBUTING.md | ❌ W0 | ⬜ pending |
| SC-1 | ci.yml never sets `THREADLINE_HEX_EVALUATOR_MODE`, so the rehearsal default applies | contract (existing) | `mix test test/threadline/ci_topology_contract_test.exs` | ✅ | ⬜ pending |
| SC-2 | YAML order equals `@time_to_red_order ++ ["ci-required"]`, and no job other than ci-required has `needs` | contract | the quick command (`ci_order_errors/1` + controls + the a,b,c fixture) | ❌ W0 | ⬜ pending |
| SC-2 | The move changes order only: the parsed maps are equal, the line multiset differs only in header line 2, and the chunk multiset is equal | mechanical | the three proof commands in RESEARCH § Order-Only Move | n/a | ⬜ pending |
| SC-2 | The order literal matches the tool's output | tool | `time-to-red.py check` | ❌ W0 | ⬜ pending |
| SC-3 | The ids are the frozen `@ci_job_ids` literal. `CI required` is byte-exact against the ruleset. | contract | the quick command | partial | ⬜ pending |
| SC-4 | gate-if, gate-step, gate-inputs, gate-jobs-input and gate-name each have a mutation control, and a comment positive control exists | contract | the quick command (`required_gate_errors/1`) | ❌ W0 | ⬜ pending |
| Landing | The PR run posts the expected check names | CI observation | `gh api repos/szTheory/threadline/actions/runs/<id>/jobs --jq '[.jobs[].name]\|sort'` compared with the expected list | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

Mutation controls:
- Each control must turn its rule red.
- Each control's mutation must actually change the input, and must not produce `rule=yaml-parse`.
- The full list is in RESEARCH § Validation Architecture, grouped as order, gate, positive and names.

---

## Wave 0 Requirements

- [ ] `parsed_job_order/1`, `ci_order_errors/1`, `@time_to_red_order` with its provenance comment, and the a,b,c ordering fixture (parity test)
- [ ] `required_gate_errors/1`, the `@ci_job_ids` literal, and the gate controls (parity test)
- [ ] name rules, `@ci_check_names` and `@retired_check_names` (parity test), landed in the rename commit
- [ ] `.planning/phases/221-ci-names-and-order/tools/time-to-red.py` plus `raw/ci/runs/*.json`: 10 cited runs; 5 are missing from 219's raw directory

---

## Manual-Only Verifications

All phase behaviors have automated verification. This follows the zero-human-verification rule in PROJECT.md Constraints.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
