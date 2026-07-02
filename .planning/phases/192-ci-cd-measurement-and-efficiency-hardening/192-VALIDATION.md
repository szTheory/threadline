---
phase: 192
slug: ci-cd-measurement-and-efficiency-hardening
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-02
---

# Phase 192 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/threadline/phase06_nyquist_ci_contract_test.exs` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | ~contract test <5s; `mix ci.all` several minutes |

---

## Sampling Rate

- **After every task commit:** Run the contract test (`mix test test/threadline/phase06_nyquist_ci_contract_test.exs`)
- **After every plan wave:** Run `mix verify.test` (and `mix ci.all` before phase close)
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~5 seconds for the static-parse contract test

---

## Per-Task Verification Map

> Planner fills this from RESEARCH.md `## Validation Architecture`. Split auto-verifiable
> (phase06 contract-test extensions per D-26; dep-floor guard per D-16) from human-gated
> (branch-protection reconfig D-19; throwaway matrix resolution run D-17; run-history
> aggregation D-02) and honest-unavailable boundaries (billed minutes, cache-hit rate D-04).

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 192-01-01 | 01 | 1 | CI-01 | T-192-B01/B02 | Read-only run-history aggregation; no workflow perturbed | shell (gh/jq) | `bash .planning/phases/192-ci-cd-measurement-and-efficiency-hardening/scripts/aggregate-ci-baseline.sh \| grep -Eiq 'verify-test\|Run test suite'` | ⬜ (created by task) | ⬜ pending |
| 192-01-02 | 01 | 1 | CI-01 | T-192-B02 | Honest-unavailable rows carry reopen triggers | grep artifact | `grep -q 'requirements: \[CI-01\]' .../192-BASELINE.md && grep -Eiq 'reopen trigger' .../192-BASELINE.md` | ⬜ (created by task) | ⬜ pending |
| 192-02-01 | 02 | 2 | CI-02 | T-192-01/05 | deps/ source-only cache, no _build; nested keys e2e-scoped | grep YAML | `grep -c 'uses: actions/cache@v4' .github/workflows/ci.yml \| grep -qx 9` | ✅ ci.yml | ⬜ pending |
| 192-02-02 | 02 | 2 | CI-04/CI-03 | T-192-01/02/03/04 | Min lane keeps gates; pin removes :latest; PR concurrency | grep YAML | `grep -q 'lane: \[min, current\]' .github/workflows/ci.yml && grep -q 'edoburu/pgbouncer:v1.25.2-p0' .github/workflows/ci.yml` | ✅ ci.yml | ⬜ pending |
| 192-03-01 | 03 | 2 | CI-03 | T-192-06 | Publish-only concurrency; bookkeeping independent | grep YAML | `grep -q 'group: release-publish-${{ github.ref }}' .github/workflows/release.yml` | ✅ release.yml | ⬜ pending |
| 192-03-02 | 03 | 2 | CI-03 | T-192-07 | List 1 8→10; List 2 rename, stays subset | grep doc | `grep -q '\`verify-hex-evaluator\`' CONTRIBUTING.md && grep -q 'Run test suite (min)' CONTRIBUTING.md` | ✅ CONTRIBUTING.md | ⬜ pending |
| 192-03-03 | 03 | 2 | CI-04 | T-192-08 | Explicit contract; floor NOT raised | grep doc | `grep -Eiq '1\.15.*floor\|Supported versions' README.md && grep -q 'elixir: "~> 1.15"' mix.exs` | ✅ README/mix.exs | ⬜ pending |
| 192-04-01 | 04 | 3 | CI-02/03/04 | T-192-09 | Durable alignment lock (no :latest, PR/publish concurrency, matrix names, no _build cache) | static-parse ExUnit | `mix test test/threadline/phase06_nyquist_ci_contract_test.exs` | ✅ (extended) | ⬜ pending |
| 192-04-02 | 04 | 3 | CI-04 | T-192-10 | Dep floor >1.15 fails loudly at the lock | ExUnit (reads deps/) | `mix deps.get && mix test test/threadline/dep_floor_guard_test.exs` | ⬜ (created by task) | ⬜ pending |
| 192-04-03 | 04 | 3 | CI-03/04 | T-192-04 | Branch-protection reconfig + min-lane resolution | human-gated | manual — maintainer checklist (D-17 throwaway run + D-19 required-checks reconfig) | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing infrastructure covers phase requirements: `phase06_nyquist_ci_contract_test.exs` is the
  established static-parse contract test (extended per D-26); no new framework install required.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Baseline run-history aggregation (p50/p95, flaky/rerun) | CI-01 | External `gh api` evidence, not repo-testable | Run throwaway aggregation script over last ~15 green `ci.yml`/`push` runs; record in `192-BASELINE.md` |
| min-lane runtime resolution (elixir 1.15 / otp 26 on ubuntu-22.04) | CI-04 | Inherently a live CI run | Throwaway matrix run confirms resolution before committing the contract (D-17) |
| Branch-protection required-checks reconfig | CI-03/CI-04 | GitHub repo settings, not in-repo | Reconfigure required checks to `Run test suite (min)` / `Run test suite (current)`; maintainer checklist item (D-19) |
| Billed-minute cost; cache-hit rate | CI-01 | Public-repo billing API returns empty; no `actions/cache` today | Record as honest "unavailable" rows with owner/date/reopen-trigger (D-04) |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (only 192-04-03 is the sanctioned human-gated checkpoint: D-17 throwaway run + D-19 branch-protection reconfig)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (phase06 contract test pre-exists; extended in Plan 04)
- [x] No watch-mode flags
- [x] Feedback latency < 5s (static-parse contract test)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved (planner) — one intentional human-gated task (192-04-03) per D-17/D-19; all other tasks carry automated verify.
