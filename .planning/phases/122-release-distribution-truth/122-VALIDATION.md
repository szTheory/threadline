---
phase: 122
slug: release-distribution-truth
status: finalized
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-28
updated: 2026-05-28T18:55:10Z
---

# Phase 122 — Validation Strategy

> Finalized Nyquist validation for release distribution truth (Phase 126-01).
> Superseding closure authority: `122-VERIFICATION.md`.

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
| 122-01-01 | 01 | 1 | DIST-03 | — | N/A | doc-contract | `mix test test/threadline/release_distribution_doc_contract_test.exs` | ✅ | ✅ green |
| 122-01-02 | 01 | 1 | DIST-03 | — | N/A | doc-contract | `grep phx-gen-auth-reference CHANGELOG.md` | ✅ | ✅ green |
| 122-01-03 | 01 | 1 | DIST-02 | — | N/A | doc-contract | `mix test test/threadline/adoption_pilot_doc_contract_test.exs` | ✅ | ✅ green |
| 122-02-01 | 02 | 2 | DIST-01 | — | N/A | manual | `mix hex.info threadline` | — | ✅ attested |
| 122-03-01 | 03 | 3 | DIST-01 | — | N/A | manual | `122-VERIFICATION.md` exists with tag + workflow URL | ✅ | ✅ attested |
| 122-03-02 | 03 | 3 | DIST-02 | — | N/A | doc-contract | `mix test test/threadline/evaluating_threadline_doc_contract_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ✅ attested · ❌ red · ⚠️ flaky*

*Manual attestation tier (`122-02-01`, `122-03-01`): `inferred_posture` — maintainer-attested registry fact corroborated by `122-VERIFICATION.md` (tag `v0.6.0`, workflow `26583473336`).*

---

## Wave 0 Requirements

- [x] Existing doc-contract infrastructure covers phase requirements
- [x] `test/threadline/release_distribution_doc_contract_test.exs` — DIST-03 CHANGELOG four-lane lock (exists on current tree)

*Wave 0 complete; release distribution doc contract file present.*

---

## Commands Actually Used

Phase 126-01 rerun bundle (2026-05-28T18:55:10Z):

1. `mix test test/threadline/release_distribution_doc_contract_test.exs`  
   Result: PASS (1 test, 0 failures), exit 0
2. `grep -q phx-gen-auth-reference CHANGELOG.md`  
   Result: PASS, exit 0
3. `mix test test/threadline/adoption_pilot_doc_contract_test.exs`  
   Result: PASS (5 tests, 0 failures), exit 0
4. `mix test test/threadline/evaluating_threadline_doc_contract_test.exs`  
   Result: PASS (7 tests, 0 failures), exit 0
5. `mix verify.doc_contract`  
   Result: PASS (97 tests, 0 failures), exit 0

*Optional corroboration (not a CI gate):* `mix hex.info threadline` — recent releases include **0.6.0** (2026-05-28).

---

## Nyquist Notes

**Retroactive backfill:** Phase 126-01 finalized this artifact on the current tree. `122-VERIFICATION.md` remains the **superseding authority** for DIST-01/02/03 closure (tag `v0.6.0`, workflow `26583473336`, adoption-pilot and CHANGELOG evidence). This VALIDATION file records the Nyquist rerun bundle and honest per-task map; it does not replace VERIFICATION attestation for manual registry facts.

- `nyquist_compliant: true` applies only with the named commands above green on the same tree.
- Manual-only hex publish rows stay manual — not relabeled as per-PR automated CI (D-10).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| hex.pm publish | DIST-01 | Registry event; no CI hex.pm polling per D-04 | Tag `v0.6.0`, watch `hex-publish.yml`, run `mix hex.info threadline` |
| 122-VERIFICATION.md content | DIST-01 | Maintainer attestation; network/registry proof | Record tag, GH Actions URL, redacted hex.info excerpt |
| adoption-pilot OK row | DIST-02 | Human confirms registry before flip | Only after hex.pm shows 0.6.0; date-stamp + workflow URL |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 300s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** finalized on 2026-05-28 after Phase 126-01 rerun bundle.
