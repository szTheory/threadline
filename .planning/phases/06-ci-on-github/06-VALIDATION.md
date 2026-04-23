---
phase: 06
slug: ci-on-github
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-23
validated: 2026-04-23
---

# Phase 06 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (via `mix test`) |
| **Config file** | `config/test.exs`, `mix.exs` aliases |
| **Quick run command** | `MIX_ENV=test mix test test/threadline/phase06_nyquist_ci_contract_test.exs` |
| **Full suite command** | `MIX_ENV=test mix compile --warnings-as-errors && mix ci.all` (matches CI `verify-test` ordering after any `ci.all` change in 06-01) |
| **Estimated runtime** | ~60–180 seconds |

---

## Sampling Rate

- **After every task commit:** Run `MIX_ENV=test mix ci.all`
- **After every plan wave:** Run full suite command above
- **Before `/gsd-verify-work`:** Full suite must be green locally; **CI-02** additionally requires GitHub evidence per `06-CONTEXT` D-10–D-12
- **Max feedback latency** ~180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 06-01-01 | 01 | 1 | CI-01 | T-06-01-01 / T-06-01-02 | Stable `jobs:` keys and `main` triggers | exunit | `mix test test/threadline/phase06_nyquist_ci_contract_test.exs` | ✅ | ✅ green |
| 06-01-02 | 01 | 1 | CI-02 | T-06-01-03 | `ci.all` mirrors `verify-test` compile ordering | exunit | `mix test test/threadline/phase06_nyquist_ci_contract_test.exs` | ✅ | ✅ green |
| 06-01-03 | 01 | 1 | CI-01 | — | Optional `ci.yml` glue (none required on 06-01) | exunit | Same suite asserts current contract | ✅ | ✅ green |
| 06-02-01 | 02 | 1 | CI-03 | T-06-02-01 | README D-05 adjacency + Actions URL | exunit | `mix test test/threadline/phase06_nyquist_ci_contract_test.exs` | ✅ | ✅ green |
| 06-02-02 | 02 | 1 | CI-03 | — | CONTRIBUTING names jobs + hub URL | exunit | `mix test test/threadline/phase06_nyquist_ci_contract_test.exs` | ✅ | ✅ green |
| 06-02-03 | 02 | 1 | CI-02 | T-06-02-02 | `06-VERIFICATION.md` literals for maintainer audit | exunit | `mix test test/threadline/phase06_nyquist_ci_contract_test.exs` | ✅ | ✅ green |
| 06-02-04 | 02 | 1 | CI-02 | — | Live GitHub run matches `origin/main` | manual | `gh run list --workflow=ci.yml --branch=main --limit=5` | ✅ | ⬜ pending maintainer |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/threadline/phase06_nyquist_ci_contract_test.exs` — encodes CI-01 / CI-02 / CI-03 acceptance from Plans 06-01 and 06-02 (Nyquist audit 2026-04-23).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `origin/main` SHA matches successful Actions `headSha` | CI-02 | GitHub-hosted truth | `git fetch origin main && git rev-parse origin/main`; compare to `gh run view <id> --json headSha,conclusion,url` for workflow `ci.yml`; all three jobs `success`. Record URL in `06-VERIFICATION.md`. |
| README discovery (badge + prose) | CI-03 | Human a11y scan | Open README: confirm CI badge row then contiguous prose linking to Actions hub per `06-CONTEXT` D-05. |

---

## Validation Audit 2026-04-23

| Metric | Count |
|--------|-------|
| Gaps found | 6 |
| Resolved | 6 |
| Escalated | 0 |

**Gaps addressed:** Plan acceptance greps and D-05 / CONTRIBUTING / `06-VERIFICATION.md` literals were shell-only during execution; they are now exercised by `Threadline.Phase06NyquistCIContractTest` on every `mix test`. Live CI-02 (`gh` against GitHub) remains manual per D-10–D-12.

---

## Validation Sign-Off

- [x] All tasks have automated verify or manual table above
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency under target
- [x] `nyquist_compliant: true` set in frontmatter after execution

**Approval:** approved 2026-04-23
