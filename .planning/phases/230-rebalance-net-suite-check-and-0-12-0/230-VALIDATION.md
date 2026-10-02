---
phase: "230"
slug: "rebalance-net-suite-check-and-0-12-0"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-02"
---

# Phase 230 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17.3 local / 1.20.4 latest-lane) |
| **Config file** | `test/test_helper.exs`, `config/test.exs` |
| **Quick run command** | `mix test test/threadline/ci_topology_contract_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs test/threadline/operator_surface/policy_show_doc_contract_test.exs test/threadline/storage_schema_migration_contract_test.exs test/threadline/storage_schema_prefix_contract_test.exs` |
| **Full suite command** | `mix test` (local) / `mix ci.all` (full gate) |
| **Estimated runtime** | ~140 seconds (`mix test` local median 137.0s baseline) |

---

## Sampling Rate

- **After every task commit:** Run targeted `mix test` on touched files (quick run command above)
- **After every plan wave:** Run `mix ci.all`
- **Before `/gsd-verify-work`:** `mix ci.all` + `bin/verify-repo-hygiene` green, plus one fresh CI run on the final pre-landing tree
- **Max feedback latency:** ~140 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 230-01-xx | 01 | 1 | SUITE-04 | — | N/A | unit | `mix test test/threadline/operator_surface/coverage_doc_contract_test.exs test/threadline/operator_surface/policy_show_doc_contract_test.exs` | ✅ | ⬜ pending |
| 230-01-xx | 01 | 1 | SUITE-04 | — | N/A | contract | `mix test test/threadline/ci_topology_contract_test.exs` | ✅ | ⬜ pending |
| 230-01-xx | 01 | 1 | SUITE-04 | — | N/A | contract (shell gate) | `bin/verify-bump-rehearsal` | ✅ | ⬜ pending |
| 230-02-xx | 02 | 2 | SUITE-06 | — | N/A | cited measurement | `python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py <run_id> --cache-state` | ✅ | ⬜ pending |
| 230-03-xx | 03 | 3 | REL-01 | — | N/A | contract | `mix test test/threadline/changelog_contract_test.exs test/threadline/release_artifact_contract_test.exs` | ✅ | ⬜ pending |
| 230-03-xx | 03 | 3 | REL-01 | — | N/A | grep gate | scoped phase/plan-ID sweep over `lib/`, `guides/`, 0.12.0 CHANGELOG block | ❌ W0 (one-off grep) | ⬜ pending |
| 230-04-xx | 04 | 4 | REL-01 | — | N/A | cited check | read-only registry check of `latest`-lane pins (builds.hex.pm, Docker Hub) | ❌ W0 (manual per 220/223 precedent) | ⬜ pending |

*Task IDs finalized by the planner. Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Scoped phase/plan-ID grep sweep (SC5) — `release_artifact_contract_test.exs` `@banned_shapes` does not cover v1.44 prefixes
- [ ] `latest`-lane pin re-check — no script exists; cited read-only check per 220/223 precedent

*No test-framework install gap — ExUnit and all cited tools already exist.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Push / PR / merge / `production-hex` approval | REL-01 | Maintainer grant required (push/publish is maintainer-owned) | Grant naming branch, push, PR, merge, `production-hex` approval |

*All other behaviors are verified by automated commands or agent-run, cited checks.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 140s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
