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
| 230-01-01 | 01 | 1 | SUITE-04 | T-230-02 | whole-file cuts leave weights, references and the 30-file floor consistent | contract (shell gate) | `mix test test/threadline/ci_topology_contract_test.exs …` + `mix verify.bump_rehearsal` + 35-file count | ✅ | ⬜ pending |
| 230-01-02 | 01 | 1 | SUITE-04 | T-230-01 | auth / fail-closed / export-auth sentences stay pinned; KEEP-whole files unchanged | unit | `mix test test/threadline/operator_surface_doc_contract_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs test/threadline/operator_surface/policy_show_doc_contract_test.exs test/threadline/storage_schema_migration_contract_test.exs test/threadline/storage_schema_prefix_contract_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 230-01-03 | 01 | 1 | SUITE-04 | T-230-02, T-230-03 | ci-required roster unchanged; CONTRIBUTING contract tests green | contract | `mix test` over every CONTRIBUTING-reading test + `bin/verify-repo-hygiene` | ✅ | ⬜ pending |
| 230-02-01 | 02 | 2 | SUITE-06 | T-230-04 | gate formula fixed before measurement | cited measurement | `python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py 36730596489 --cache-state` | ✅ | ⬜ pending |
| 230-02-02 | 02 | 2 | SUITE-06 | T-230-04, T-230-05 | every figure cited; local-only phases not back-filled | doc grep gate | D-09 header + rows 224-230 + verdict row grep; `bin/verify-repo-hygiene` | ✅ | ⬜ pending |
| 230-03-01 | 03 | 3 | REL-01 | T-230-08 | dated 0.12.0 entry + 0.11.x → 0.12.x coverage; rehearsal synthesises nothing | contract + rehearsal | `mix test test/threadline/changelog_contract_test.exs test/threadline/version_truth_doc_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs …` + `mix verify.bump_rehearsal` | ✅ | ⬜ pending |
| 230-03-02 | 03 | 3 | REL-01 | T-230-07 | no phase/plan/decision/v1.44 requirement ID in lib/, guides/, 0.12.0 CHANGELOG | grep gate (W0 one-off sweep) | scoped `grep -rnE` sweep over `lib guides` + 0.12.0 block; `mix compile --warnings-as-errors && mix docs` | ✅ (one-off grep) | ⬜ pending |
| 230-03-03 | 03 | 3 | REL-01 | T-230-06 | ci.all, hygiene and privacy grep green pre-landing | full gate | `mix ci.all` + `bin/verify-repo-hygiene --self-test` + tracked-.planning whoami grep | ✅ | ⬜ pending |
| 230-04-01 | 04 | 4 | REL-01 | T-230-12 | squash message validated; latest-lane pins re-checked against builds.hex.pm and Docker Hub | cited check (W0, read-only curl per 220/223 precedent) | merge-base check + squash-message awk/grep + pin re-check evidence grep | ✅ | ⬜ pending |
| 230-04-02 | 04 | 4 | SUITE-06, REL-01 | T-230-09, T-230-10, T-230-11 | land only on D-06 PASS from the PR's own CI run | cited measurement + git | `ci-job-timing.py <pr run> --cache-state`; `git log -1 origin/main` subject + 3 footers | ✅ | ⬜ pending |
| 230-04-03 | 04 | 4 | REL-01 | T-230-09, T-230-13 | 0.12.0 published through production-hex, smoke green, sync merged | live check | `gh release view v0.12.0` + hex.pm API + Release run job conclusions | ✅ | ⬜ pending |

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
| Push / PR / merge / `production-hex` approval / sync-PR open+merge | REL-01 | Maintainer grant required (push/publish is maintainer-owned, D-17) | One grant at 230-04 Task 2 naming exactly the six D-17 actions in the maintainer's own words (no workflow rerun; a cache-miss INVALID goes through D-10 and a granted push) |

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
