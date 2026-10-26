---
phase: "245"
slug: "supply-chain"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-25"
---

# Phase 245 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17.3, OTP 27); `test_helper.exs` needs Postgres |
| **Config file** | `test/test_helper.exs`; partition inventory `test/partition_weights.txt` |
| **Quick run command** | `mix test test/threadline/<file>_test.exs` (ephemeral postgres:16) |
| **Full suite command** | `CI=true mix ci.all` on an ephemeral postgres:16, plus `bin/verify-repo-hygiene` and `mix verify.credo` |
| **Estimated runtime** | ~30 seconds per quick run; full gate several minutes |

---

## Sampling Rate

- **After every task commit:** run the touched test files (quick run command)
- **After every plan wave:** `mix test` (full default suite) on an ephemeral postgres:16
- **Before `/gsd-verify-work`:** `CI=true mix ci.all`, `bin/verify-repo-hygiene`, `mix verify.credo` all green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

Seeded from `245-RESEARCH.md` § Validation Architecture; task IDs are filled once plans exist.

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| SUP-01 | dependabot.yml shape + 4 mutation controls | unit contract | `mix test test/threadline/dependabot_config_contract_test.exs` | ❌ W0 | ⬜ pending |
| SUP-01 | doc sentence replaced; `refute dependabot.yml` inverted | doc contract | `mix test test/threadline/deps_health_doc_contract_test.exs` | ✅ edit | ⬜ pending |
| SUP-02 | PIN-* / NODE-* rules, each with mutation control incl. tag-only `actions/checkout@v5` | unit contract | `mix test test/threadline/ci_action_pin_contract_test.exs` | ❌ W0 | ⬜ pending |
| SUP-02 | runtime allowlist keyed `{action, major}` | unit contract | `mix test test/threadline/ci_action_runtime_contract_test.exs` | ✅ edit | ⬜ pending |
| SUP-02 | existing workflow contracts green after pinning | unit contracts | `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/browser_journey_evidence_contract_test.exs test/threadline/flake_classifier_contract_test.exs test/threadline/browser_full_projects_contract_test.exs` | ✅ edit | ⬜ pending |
| SUP-02 | `bin/verify-action-pins` via fake `GH_BIN` | unit (script) | `mix test test/threadline/verify_action_pins_test.exs` | ❌ W0 | ⬜ pending |
| SUP-03 | D-23 cases 1–12 via fake `MIX_BIN` + live closure contract | unit (script) | `mix test test/threadline/deps_audit_gate_test.exs` | ✅ extend | ⬜ pending |
| SUP-03 | real-Hex downgrade (e) and red (a) proofs | network CI step | `bin/verify-deps-audit --self-test` | ✅ extend | ⬜ pending |
| SUP-03 | job keeps no `issues: write` | unit contract | `mix test test/threadline/ci_token_permissions_contract_test.exs test/threadline/deps_audit_contract_test.exs` | ✅ | ⬜ pending |
| SUP-04 | class arms, precedence, `hex.outdated` never invoked, workflow shape | unit (script) | `mix test test/threadline/deps_health_report_test.exs test/threadline/deps_health_doc_contract_test.exs` | ✅ rewrite | ⬜ pending |
| SUP-04 | upsert retitles only when title differs | unit (script) | `mix test test/threadline/ci_issue_upsert_contract_test.exs` | ✅ extend | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline/dependabot_config_contract_test.exs` — SUP-01 (register in `test/partition_weights.txt`)
- [ ] `test/threadline/ci_action_pin_contract_test.exs` — SUP-02 (register)
- [ ] `test/threadline/verify_action_pins_test.exs` — D-14 (register if new)
- [ ] SARIF + `deps.tree` fixtures for the fake `MIX_BIN`
- [ ] `ci_issue_upsert_contract_test.exs` fake-gh `issue edit` arm

---

## Manual-Only Verifications

None in phase verification. Post-landing observations are deferred-to-landing (D-31), not manual UAT:

| Behavior | Requirement | Why deferred | Read-only check |
|----------|-------------|--------------|-----------------|
| GitHub accepted dependabot.yml | SUP-01 | only observable after merge to main | `gh run list --repo szTheory/threadline --event dynamic --limit 5` |
| #61 retitles and self-closes | SUP-04 | needs a scheduled/push run on main | `gh issue view 61 --json state,title` |
| `sha_pinning_required=true` | SUP-02 | maintainer setting after pins land (D-15) | `gh api repos/szTheory/threadline/actions/permissions --jq .sha_pinning_required` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
