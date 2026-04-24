---
phase: 21
slug: host-staging-pooler-parity
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-23
---

# Phase 21 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.15+) |
| **Config file** | `config/test.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/threadline/ci_topology_contract_test.exs test/threadline/readme_doc_contract_test.exs` |
| **Full suite command** | `MIX_ENV=test mix ci.all` |
| **Estimated runtime** | Quick slice ~5–15s; full `ci.all` per machine/DB |

---

## Sampling Rate

- **After every task commit:** Run quick slice command above
- **After every plan wave:** Run `MIX_ENV=test mix ci.all`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** Bounded by local `ci.all` runtime

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 21-01-01 | 01 | 1 | STG-01 | T-21-01-01 / — | Docs do not encourage pasting live secrets | integration | `mix test test/threadline/ci_topology_contract_test.exs` | ✅ | ⬜ pending |
| 21-01-02 | 01 | 1 | STG-03 | — | N/A | integration | `mix test test/threadline/ci_topology_contract_test.exs` | ✅ | ⬜ pending |
| 21-02-01 | 02 | 2 | STG-02 | T-21-02-01 / — | CONTRIBUTING describes fork+PR provenance | integration | `mix test test/threadline/readme_doc_contract_test.exs` (if README touched) + manual grep per plan | ✅ | ⬜ pending |
| 21-02-02 | 02 | 2 | STG-03 | — | Cross-links resolve | integration | `mix test test/threadline/readme_doc_contract_test.exs` + `mix ci.all` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

- **Existing infrastructure covers all phase requirements.** No new test framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Integrator STG evidence quality | STG-02 | Maintainer cannot run host staging | Review PR: confirm OK/Issue/N/A + pointer present; no raw secrets in `main` |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or documented manual row
- [ ] Sampling continuity: no three consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter after execution

**Approval:** pending
