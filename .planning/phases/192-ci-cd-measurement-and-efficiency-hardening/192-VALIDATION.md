---
phase: 192
slug: ci-cd-measurement-and-efficiency-hardening
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| 192-XX-XX | XX | X | CI-XX | — | {planner fills} | static-parse | `mix test test/threadline/phase06_nyquist_ci_contract_test.exs` | ✅ | ⬜ pending |

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

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s (contract test)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
