---
phase: 06
slug: ci-on-github
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-23
---

# Phase 06 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (via `mix test`) |
| **Config file** | `config/test.exs`, `mix.exs` aliases |
| **Quick run command** | `MIX_ENV=test mix ci.all` |
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
| 06-01-01 | 01 | 1 | CI-01 | T-06-01-01 / — | N/A (contract check) | grep | `grep -E '^  verify-(format|credo|test):' .github/workflows/ci.yml` | ✅ | ⬜ pending |
| 06-01-02 | 01 | 1 | CI-02 | T-06-01-02 / — | N/A | mix | `MIX_ENV=test mix compile --warnings-as-errors` | ✅ | ⬜ pending |
| 06-01-03 | 01 | 1 | CI-02 | — | N/A | mix | `MIX_ENV=test mix ci.all` | ✅ | ⬜ pending |
| 06-02-01 | 02 | 1 | CI-03 | T-06-02-01 / — | No secrets in README | grep | `grep -F 'github.com/szTheory/threadline/actions' README.md` | ✅ | ⬜ pending |
| 06-02-02 | 02 | 1 | CI-02 | — | N/A | manual | `gh run list --workflow=ci.yml --branch=main --limit=5` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing ExUnit + Credo + formatter infrastructure covers CI behavior; no new test stubs required for Wave 0.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `origin/main` SHA matches successful Actions `headSha` | CI-02 | GitHub-hosted truth | `git fetch origin main && git rev-parse origin/main`; compare to `gh run view <id> --json headSha,conclusion,url` for workflow `ci.yml`; all three jobs `success`. Record URL in `06-VERIFICATION.md`. |
| README discovery (badge + prose) | CI-03 | Human a11y scan | Open README: confirm CI badge row then contiguous prose linking to Actions hub per `06-CONTEXT` D-05. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or manual table above
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency under target
- [ ] `nyquist_compliant: true` set in frontmatter after execution

**Approval:** pending
