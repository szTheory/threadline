---
phase: 30
slug: retention-at-scale-discovery
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-24
---

# Phase 30 — Validation Strategy

> Per-phase validation contract for documentation changes (SCALE-01, SCALE-02).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix format && mix compile --warnings-as-errors` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | project default (~minutes on full suite) |

---

## Sampling Rate

- **After every task commit:** `mix format`, `mix compile --warnings-as-errors`
- **After every plan wave:** `mix test`
- **Before `/gsd-verify-work`:** `mix ci.all` or at minimum `mix test`

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 30-01-01 | 01 | 1 | SCALE-01 | T-30-01 / T-30-02 | Accurate purge gates in docs | manual+grep | `grep` headings in `guides/production-checklist.md` | ✅ | ⬜ pending |
| 30-01-02 | 01 | 1 | SCALE-01 | T-30-03 | No false SQL/API claims | grep | `grep -E 'Threadline\.(Retention|Query|Export)' guides/production-checklist.md` | ✅ | ⬜ pending |
| 30-02-01 | 02 | 1 | SCALE-02 | T-30-04 | Discovery links only | grep | `grep` hub H2 in `guides/domain-reference.md` | ✅ | ⬜ pending |
| 30-02-02 | 02 | 1 | SCALE-02 | T-30-04 | README handoff | grep | `grep` hub + `domain-reference.md` in `README.md` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

- **Existing infrastructure covers all phase requirements** — no new Wave-0 install; reuse `mix test` / `mix verify.*` from repo.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| ExDoc render of new headings | SCALE-02 | Optional local `mix docs` not in CI | Run `mix docs`, open `doc/index.html`, confirm hub H2 renders and links work. |

---

## Validation Sign-Off

- [ ] All tasks have grep- or `mix test`-backed verify
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter when execution completes

**Approval:** pending
