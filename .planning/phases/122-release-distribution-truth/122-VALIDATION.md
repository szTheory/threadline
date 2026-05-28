---
phase: 122
slug: release-distribution-truth
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-28
---

# Phase 122 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Config file** | `mix.exs` aliases (`verify.doc_contract`, `verify.release`, `ci.all`) |
| **Quick run command** | `mix verify.doc_contract` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | ~60–120 seconds (doc contracts); ~3–5 min (full ci.all) |

---

## Sampling Rate

- **After every task commit:** Run `mix verify.doc_contract` (or targeted test file from task)
- **After every plan wave:** Run `mix ci.all`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 300 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 122-01-01 | 01 | 1 | DIST-03 | — | N/A | doc-contract | `mix test test/threadline/release_distribution_doc_contract_test.exs` | ❌ W0 | ⬜ pending |
| 122-01-02 | 01 | 1 | DIST-03 | — | N/A | doc-contract | `grep phx-gen-auth-reference CHANGELOG.md` | ✅ | ⬜ pending |
| 122-01-03 | 01 | 1 | DIST-02 | — | N/A | doc-contract | `mix test test/threadline/adoption_pilot_doc_contract_test.exs` | ✅ | ⬜ pending |
| 122-02-01 | 02 | 2 | DIST-01 | — | N/A | manual | `mix hex.info threadline` | — | ⬜ pending |
| 122-03-01 | 03 | 3 | DIST-01 | — | N/A | manual | `122-VERIFICATION.md` exists with tag + workflow URL | ❌ W0 | ⬜ pending |
| 122-03-02 | 03 | 3 | DIST-02 | — | N/A | doc-contract | `mix test test/threadline/evaluating_threadline_doc_contract_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing doc-contract infrastructure covers phase requirements
- [ ] `test/threadline/release_distribution_doc_contract_test.exs` — stubs for DIST-03 CHANGELOG four-lane lock (created in Plan 01)

*Existing infrastructure covers most requirements; one new test file expected in Wave 1.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| hex.pm publish | DIST-01 | Registry event; no CI hex.pm polling per D-04 | Tag `v0.6.0`, watch `hex-publish.yml`, run `mix hex.info threadline` |
| 122-VERIFICATION.md content | DIST-01 | Maintainer attestation; network/registry proof | Record tag, GH Actions URL, redacted hex.info excerpt |
| adoption-pilot OK row | DIST-02 | Human confirms registry before flip | Only after hex.pm shows 0.6.0; date-stamp + workflow URL |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 300s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
