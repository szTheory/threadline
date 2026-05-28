---
phase: 124
slug: adopter-doc-finish
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-28
---

# Phase 124 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.14+) |
| **Config file** | `mix.exs` aliases `verify.doc_contract`, `verify.test` |
| **Quick run command** | Per-plan targeted `mix test test/threadline/*_doc_contract_test.exs` |
| **Full suite command** | `mix verify.doc_contract` then `mix ci.all` |
| **Estimated runtime** | ~15–45 seconds (doc contracts only) |

---

## Sampling Rate

- **After every task commit:** Run the plan's targeted test file(s)
- **After every plan wave:** Run `mix verify.doc_contract`
- **Before `/gsd-verify-work`:** `mix ci.all` must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 124-01-01 | 01 | 1 | DOC-01 | — | IEx §6 + collapsed HTTP; no open cookie prose | doc contract | `mix test test/threadline/getting_started_saas_doc_contract_test.exs` | ✅ | ⬜ pending |
| 124-01-02 | 01 | 1 | DOC-02 | — | ADOPT-AUTH dedicated test + ordering | doc contract | same | ✅ | ⬜ pending |
| 124-02-01 | 02 | 1 | DOC-03 | — | `:schemas` mount + reification subsection | doc contract | `mix test test/threadline/operator_surface_doc_contract_test.exs` | ✅ | ⬜ pending |
| 124-03-01 | 03 | 2 | DOC-04 | — | Evidence host-write boundary + mental model fix | doc contract | `mix test test/threadline/how_threadline_works_doc_contract_test.exs` | ✅ | ⬜ pending |
| 124-03-02 | 03 | 2 | DOC-05 | — | Four-lane vocabulary + upgrade-path link | doc contract | `mix test test/threadline/integration_contracts_doc_contract_test.exs` | ✅ | ⬜ pending |
| 124-03-03 | 03 | 2 | DOC-01–05 | — | Full doc contract band green | integration | `mix verify.doc_contract` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new framework install.

- [x] ExUnit doc-contract pattern in four target test files
- [x] `mix verify.doc_contract` alias includes all contract files
- [x] No new test files required (extend existing per CONTEXT D-06/D-14/D-19/D-22)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| §6 IEx prose readability | DOC-01 | Narrative flow not machine-checked | Spot-read §6 — phx adopters see no cookie names in open prose |
| Evidence boundary compliance tone | DOC-04 | v1.22 non-goals — no over-promise | Read domain-reference boundary section for SOC2/compliance tone |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
