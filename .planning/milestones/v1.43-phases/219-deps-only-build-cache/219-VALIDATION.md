---
phase: "219"
slug: "deps-only-build-cache"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-28"
---

# Phase 219 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Source: `219-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17.3) text/regex contracts + YamlElixir 2.11.0 anti-drift; Python stdlib tools for measurement |
| **Config file** | `test/test_helper.exs` (default excludes `pgbouncer_topology`, `live_dialyzer`) |
| **Quick run command** | `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/ci_action_runtime_contract_test.exs test/threadline/browser_full_projects_contract_test.exs` |
| **Full suite command** | `mix verify.test` + `mix verify.format` + `mix verify.credo` + `bin/verify-repo-hygiene`; `mix ci.all` at phase close |
| **Estimated runtime** | ~20 seconds quick; full suite several minutes |

---

## Sampling Rate

- **After every task commit:** Run the quick run command plus `mix format --check-formatted`.
- **After every plan wave:** Run `mix verify.test`, `mix verify.credo`, `bin/verify-repo-hygiene`.
- **Before `/gsd-verify-work`:**
  - `mix ci.all` must be green locally.
  - On the pushed branch, all ci.yml jobs must be green, with at least 1 cold and 1 warm run cited.
- **Max feedback latency:** 30 seconds (quick run).

---

## Per-Task Verification Map

| Req / Decision | Behavior | Test Type | Automated Command | File Exists | Status |
|----------------|----------|-----------|-------------------|-------------|--------|
| CACHE-01 SC1 / D-01, D-02, D-05 | Every `_build` restore key carries all `@build_key_segments`; `no-optional` forbidden | contract + mutation | `mix test test/threadline/ci_workflow_parity_contract_test.exs` | ❌ W0 (Plan 01) | ⬜ pending |
| SC1 / D-14, D-15 | Split restore/save only, with no `restore-keys`. Save key = matching restore's `cache-primary-key`; exact guard; no `always()`; paths equal | contract + mutation | same | ❌ W0 | ⬜ pending |
| SC2 / D-07, D-08 | Unconditional rm with `${MIX_ENV:?}`; contiguous order; example rm names both apps | contract + mutation | same | ❌ W0 | ⬜ pending |
| D-09 | Literal job-level `MIX_ENV`; env-scoped path | contract + mutation | same | ❌ W0 | ⬜ pending |
| SC3 / D-13 | verify-compile-no-optional has zero cache steps | contract + mutation | same | ❌ W0 | ⬜ pending |
| SC3 / D-17 | release.yml cache-free; no cache in `pull_request_target`/`workflow_run`/`issue_comment` workflows; compiler-env denylist | contract + mutation | same | ❌ W0 | ⬜ pending |
| D-20 / D-21 | Fail-closed allowlist; only `cache: npm`; anti-drift step count; positive comment control | contract + mutation | same | ❌ W0 | ⬜ pending |
| D-19 | ci.yml comment and CONTRIBUTING section aligned (doc contract) | doc contract + mutation | same | ❌ (Plan 02) | ⬜ pending |
| Regression | Existing parity/topology/runtime/browser-full contracts stay green | contract | quick run command | ✅ | ⬜ pending |
| SC4 / D-23..D-26 | Before/after with run IDs; citation checker passes | tool | `python3 .planning/phases/219-deps-only-build-cache/tools/check-citations.py .planning/phases/219-deps-only-build-cache/219-REMEASURE.md` | ❌ W0 (Plan 03) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `build_cache_errors/2` and its synthetic-fixture mutation tests in `test/threadline/ci_workflow_parity_contract_test.exs` (Plan 01).
- [ ] `.planning/phases/219-deps-only-build-cache/tools/`, containing:
  - copies of the 218 tools, with the citation exemption widened to 219;
  - a new `remeasure-219.py` (Plan 03).

No framework install is needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| A warm run restores the cache: no `==> <dep>` lines, threadline recompiled, `THREADLINE_BUILD_CACHE=hit` | CACHE-01 SC1 (runtime half) | Needs the GitHub cache service, so it can only be observed on a pushed branch. This is automated evidence capture once pushed, not human judgment | `gh run view --job <id> --log` grep, recorded in 219-REMEASURE §correctness. The push/dispatch grant comes from the maintainer (D-25) |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
