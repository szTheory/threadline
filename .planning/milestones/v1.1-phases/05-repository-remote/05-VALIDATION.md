---
phase: 05
slug: repository-remote
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-22
---

# Phase 05 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Mix aliases (`verify.format`, `verify.credo`, `verify.test`) |
| **Config file** | `mix.exs` aliases, `.formatter.exs` |
| **Quick run command** | `mix verify.format` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | ~60–120 seconds (depends on Postgres test setup) |

---

## Sampling Rate

- **After every task commit:** Run `mix verify.format` if `mix.exs` or workflow YAML changed; otherwise document-only tasks may skip.
- **After every plan wave:** Run `mix ci.all` before closing the phase.
- **Before `/gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 180 seconds (allow cold test DB)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | REPO-01 | T-05-01-01 / — | N/A (read-only git) | manual | `git remote -v` | ✅ | ⬜ pending |
| 05-01-02 | 01 | 1 | REPO-02 | T-05-01-02 / — | URLs point to canonical host, not typosquat | grep | `rg @source_url mix.exs` | ✅ | ⬜ pending |
| 05-01-03 | 01 | 1 | REPO-03 | T-05-01-03 / — | CI triggers on integration branch only | grep | `rg "branches: \\[main\\]" .github/workflows/ci.yml` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

Existing Elixir/Mix test infrastructure covers code quality; **no new Wave 0 test files** required for Phase 5 (repository metadata is external/git-state).

- [x] Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `origin` URL and tracking branch | REPO-01, REPO-03 | Depends on local git clone and remote | Run `git remote -v` and `git branch -vv`; confirm `main` tracks `origin/main` |
| GitHub metadata | REPO-01 (social proof) | Needs `gh` + network | Run `gh repo view szTheory/threadline --json url,description,homepageUrl` |

---

## Validation Sign-Off

- [ ] All tasks have verify steps or manual table above
- [ ] Sampling continuity: REPO checks are manual CLI — documented per task
- [ ] Wave 0 covers all MISSING references — N/A (none missing)
- [ ] No watch-mode flags in commands
- [ ] Feedback latency < 180s for `mix ci.all`
- [ ] `nyquist_compliant: true` set in frontmatter when phase completes

**Approval:** pending
