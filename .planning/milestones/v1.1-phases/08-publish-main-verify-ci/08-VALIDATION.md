---
phase: 08
slug: publish-main-verify-ci
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-23
---

# Phase 8 — Validation Strategy

> Per-phase validation contract for gap closure (git remote + GitHub Actions + checklist alignment).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (via Mix) |
| **Config file** | `mix.exs`, `config/test.exs` |
| **Quick run command** | `MIX_ENV=test mix ci.all` |
| **Full suite command** | `MIX_ENV=test mix ci.all` |
| **Estimated runtime** | ~2–5 minutes (depends on Postgres) |

---

## Sampling Rate

- **After code-affecting tasks (if any):** `MIX_ENV=test mix ci.all`
- **After documentation-only tasks:** Greps + optional `mix ci.all` if workflow or `mix.exs` touched
- **Before marking CI-02 satisfied:** Maintainer must record green GitHub run for `origin/main` HEAD (not local alone)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 08-01-01 | 01 | 1 | REPO-03 | T-08-01-01 / — | No secrets in git output | shell | `git rev-parse` parity | ✅ | ⬜ pending |
| 08-01-02 | 01 | 1 | REPO-03 | T-08-01-02 | Push uses SSH/HTTPS already configured | manual | `git push` | ✅ | ⬜ pending |
| 08-02-01 | 02 | 2 | CI-02 | T-08-02-01 | Run URL is GitHub-owned domain | manual | `gh run view` | ✅ | ⬜ pending |
| 08-02-02 | 02 | 2 | CI-01 | T-08-02-02 | Contract unchanged | grep | `grep verify-format` | ✅ | ⬜ pending |
| 08-02-03 | 02 | 2 | CI-03 | — | Links stay canonical | grep | README / CONTRIBUTING greps | ✅ | ⬜ pending |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — **no new test stubs**.

- [x] `mix ci.all` alias present for local parity checks

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| Green Actions on pushed SHA | CI-02 | GitHub is external | Push `main`, wait for `ci.yml`, confirm three jobs; record in `06-VERIFICATION.md` |
| `origin/main` equals local `main` | REPO-03 | Needs network | `git fetch origin main` then compare `git rev-parse main` vs `origin/main` |

---

## Validation Sign-Off

- [ ] All tasks have automated verify **or** explicit manual gate documented
- [ ] Sampling continuity acceptable for ops-only phase
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set after execution sign-off

**Approval:** pending
