---
phase: "247"
slug: "ci-critical-path-and-suite-lanes"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-26"
---

# Phase 247 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `247-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17.3 local; CI matrix 1.15.8 / 1.17.3 / 1.20.4); `node:test` via tsx for TS; bash `bin/ci-test-partitions --self-test` harness |
| **Config file** | `test/test_helper.exs` (pointer comment only); `examples/threadline_phoenix/e2e/package.json` `test:unit` |
| **Quick run command** | `DB_PORT=<ephemeral> mix test test/threadline/ci_topology_contract_test.exs test/threadline/ci_workflow_parity_contract_test.exs test/threadline/browser_journey_evidence_contract_test.exs test/threadline/browser_full_projects_contract_test.exs test/threadline/ci_coverage_doc_contract_test.exs test/threadline/ci_action_pin_contract_test.exs test/threadline/ci_action_runtime_contract_test.exs test/threadline/repo_contract_scope_contract_test.exs` + `bin/ci-test-partitions --self-test` + touched tsx unit tests |
| **Full suite command** | `mix verify.test` on an ephemeral `postgres:16` container (never the shared PG14 on 5432); phase gate `mix ci.all` (CI=true) |
| **Estimated runtime** | quick ~60 s; full ~6 min |

---

## Sampling Rate

- **After every task commit:** quick run command
- **After every plan wave:** `mix verify.test` on ephemeral PG16 + `mix verify.credo` + `mix format --check-formatted`
- **Before `/gsd-verify-work`:** `mix ci.all` green, then the live main-run measurements below
- **Max feedback latency:** 120 seconds (local); live CI measurements are batch evidence, not per-task feedback

---

## Per-Task Verification Map

Filled by the planner/executor per task; requirement-level map:

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| CI-01 | slow-specs ranking, cap 20, retry sum, skip exclusion, malformed → warning exit 0 | unit | `cd examples/threadline_phoenix/e2e && ./node_modules/.bin/tsx --test support/slow-specs.test.ts` | ❌ W0 | ⬜ pending |
| CI-01 | timings step in every leg, `always()`, guard, step summary, `browser-timings-…` artifact; `test:unit` wires both TS tests | contract | `mix test test/threadline/browser_journey_evidence_contract_test.exs` | ✅ extend | ⬜ pending |
| CI-02 | matrix == inventory `votingProjects`; check names; retired name; needs exemption; job ids; time-to-red | contract | `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs` | ✅ extend | ⬜ pending |
| CI-02 | `bin/browser-full-projects` resolves `${{ matrix.project }}`, fails closed | contract + mutation | `mix test test/threadline/browser_full_projects_contract_test.exs test/threadline/ci_coverage_doc_contract_test.exs` | ✅ extend | ⬜ pending |
| CI-02 | receipt merges N files; missing leg → not executed; duplicates rejected | unit | `./node_modules/.bin/tsx --test support/operator-ci-evidence.test.ts` | ✅ extend | ⬜ pending |
| CI-02 | download-artifact SHA pin + node24 | contract | `mix test test/threadline/ci_action_pin_contract_test.exs test/threadline/ci_action_runtime_contract_test.exs` | ✅ | ⬜ pending |
| CI-02 | measurement script (attempt-1 wall, median) | contract (fake gh) | measurement-script contract test | ❌ W0 | ⬜ pending |
| CI-03 | scope=toolchain filtering, exactly-once, summary count, `--ingest-weights` | self-test | `bin/ci-test-partitions --self-test` | ✅ extend | ⬜ pending |
| CI-03 | D-09 no-dodging + no-silent-unclassified; env var min/latest only; CONTRIBUTING sentence | contract | `mix test test/threadline/repo_contract_scope_contract_test.exs` | ❌ W0 | ⬜ pending |
| CI-03 | default excludes unchanged | contract | `mix test test/threadline/zero_skips_contract_test.exs` | ✅ | ⬜ pending |
| CI-04 | hang / hang_ignore_term killed within budget, 124, no leftover process | self-test | `bin/ci-test-partitions --self-test` (bash 3.2 and 5) | ✅ extend | ⬜ pending |
| CI-04 | monitor names `file:line` + stack for test-body and `setup_all` hangs | integration | `mix test test/threadline/partition_monitor_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `examples/threadline_phoenix/e2e/support/slow-specs.test.ts` + `test:unit` wiring (also for `operator-ci-evidence.test.ts`)
- [ ] `test/threadline/repo_contract_scope_contract_test.exs`
- [ ] `test/threadline/partition_monitor_test.exs` (runtime-built sandbox fixtures, never committed `*_test.exs` fixtures)
- [ ] measurement script + fake-`gh` contract test
- [ ] fake-mix support for `--formatter X` pairs and `hang` / `hang_ignore_term` behaviors

---

## Live-CI Verifications (automated reads, maintainer-granted writes)

| Behavior | Requirement | Why live | Instructions |
|----------|-------------|----------|--------------|
| ≥20 slowest specs in summary/artifact on main | CI-01 | needs a real main run | read job summary / `gh run download` the `browser-timings-*` artifact |
| median ci.yml wall ≤ 9 min over 5 attempt-1 main runs | CI-02 | measurement on main | measurement script over the 5 runs at/after the split head |
| partition max/min ≤ 1.15 over 3 runs per lane | CI-03 | measurement on main | parse the script's report table from 3 consecutive runs |
| monitor works on Elixir 1.15.8 / OTP 26 | CI-04 | min lane only in CI | any PR run of the min lane with the formatter attached |
| PR #89 shape reproduced red, module named, ≪ 20 min | CI-04 | synthetic live run | throwaway-branch PR with `Process.sleep(:infinity)` in a `setup_all` (push = maintainer grant) |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
