---
phase: 126
slug: nyquist-validation-signoff-122-124
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-28
---

# Phase 126 — Validation Strategy

> Meta-phase validation: each plan finalizes a target phase's Nyquist artifact (122, 123, 124).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix aliases |
| **Config file** | `mix.exs` (`verify.doc_contract`, `ci.all`) |
| **Quick run command** | Per-plan targeted `mix test` bundle (see 126-CONTEXT.md D-14–D-16) |
| **Full suite command** | `mix ci.all` (126-03 session close only) |
| **Estimated runtime** | ~30–90s per targeted bundle; ~minutes for `ci.all` |

---

## Sampling Rate

- **After 126-01 / 126-02 task commits:** Run that plan's targeted bundle + `mix verify.doc_contract`
- **After 126-03:** Run 124 bundle + `mix verify.doc_contract` + `mix ci.all`
- **Before phase complete:** All three target `*-VALIDATION.md` show `nyquist_compliant: true`

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 126-01-01 | 01 | 1 | ROADMAP SC #1 (122) | artifact | Gap audit 122-VALIDATION ↔ 122-VERIFICATION | ✅ | ⬜ pending |
| 126-01-02 | 01 | 1 | ROADMAP SC #1 (122) | integration | 122 sign-off bundle (D-14) + `mix verify.doc_contract` | ✅ | ⬜ pending |
| 126-01-03 | 01 | 1 | ROADMAP SC #1 (122) | artifact | Finalize `122-VALIDATION.md` | ✅ | ⬜ pending |
| 126-02-01 | 02 | 2 | ROADMAP SC #2 (123) | artifact | Gap audit 123-VALIDATION ↔ 123-VERIFICATION | ✅ | ⬜ pending |
| 126-02-02 | 02 | 2 | ROADMAP SC #2 (123) | integration | 123 sign-off bundle (D-15) + `mix verify.doc_contract` | ✅ | ⬜ pending |
| 126-02-03 | 02 | 2 | ROADMAP SC #2 (123) | artifact | Finalize `123-VALIDATION.md` | ✅ | ⬜ pending |
| 126-03-01 | 03 | 3 | ROADMAP SC #3 (124) | artifact | Gap audit 124-VALIDATION ↔ 124-VERIFICATION | ✅ | ⬜ pending |
| 126-03-02 | 03 | 3 | ROADMAP SC #3 (124) | integration | 124 sign-off bundle (D-16) + `mix verify.doc_contract` | ✅ | ⬜ pending |
| 126-03-03 | 03 | 3 | ROADMAP SC #3 (124) | artifact | Finalize `124-VALIDATION.md` | ✅ | ⬜ pending |
| 126-03-04 | 03 | 3 | Phase 126 close | integration | `mix ci.all` (D-17, once) | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing doc-contract infrastructure covers all target-phase requirements. No new test files expected.

---

## Manual-Only Verifications

| Behavior | Plan | Why Manual | Test Instructions |
|----------|------|------------|-------------------|
| 122 hex publish attestation | 126-01 | Registry fact; `inferred_posture` per D-10 | Cite `122-VERIFICATION.md` tag + workflow URL; optional `mix hex.info` corroboration |
| 124 prose spot-reads | 126-03 | Narrative tone per D-12 | Mark `✅ attested` via `124-VERIFICATION.md` traceability |

---

## Validation Sign-Off

- [ ] `122-VALIDATION.md` has `nyquist_compliant: true`
- [ ] `123-VALIDATION.md` has `nyquist_compliant: true`
- [ ] `124-VALIDATION.md` has `nyquist_compliant: true`
- [ ] `mix ci.all` green once after 126-03
- [ ] `nyquist_compliant: true` on this artifact after all three targets signed

**Approval:** pending
