---
phase: 91
slug: phase-86-verification-backfill
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-25
---

# Phase 91 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.
> Phase 91 is a verification-backfill slice. The main risks are claiming
> support-scoped row-history / as-of closure without the full three-layer proof
> bar, updating public truth surfaces before the mounted `/audit` route is
> proven, and marking `SCOPE-01` / `SCOPE-02` complete without matching
> authority-surface evidence.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix LiveViewTest + doc-contract tests |
| **Config file** | `mix.exs`, `config/test.exs`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md` |
| **Quick run command** | `MIX_ENV=test mix test test/threadline/query_test.exs test/threadline/investigation_test.exs test/threadline/operator_surface/transaction_live_test.exs --max-failures 1` |
| **Full suite command** | `mix verify.test` for full root tests; `mix verify.example` only if Phase 91 truth promotion touches example-host proof |
| **Estimated runtime** | ~20-60 seconds warm, depending on root suite breadth and whether example-host verification is needed |

---

## Sampling Rate

- After any query/helper proof change in `91-01`: run the quick scoped-proof slice.
- After any mounted `/audit` history proof change in `91-01`: run the same quick slice again before moving to artifact or doc work.
- After any guide/example wording change in `91-02`: rerun the doc-contract subset that locks the affected truth surface.
- Before finalizing `86-VERIFICATION.md` and `86-VALIDATION.md`: require the targeted proof slice green; run `mix verify.example` only if the phase promotes the example-host claim.
- Max feedback latency: under 60 seconds for targeted proof commands in this phase.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 91-01-01 | 01 | 1 | SCOPE-01, SCOPE-02 | T-91-01 / T-91-02 | `Threadline.history/3`, `Threadline.as_of/4`, `Threadline.row_history/4`, and `Threadline.row_history_page/4` apply host-owned scope narrowing and block cross-scope historical reads. | unit + integration | `MIX_ENV=test mix test test/threadline/query_test.exs test/threadline/investigation_test.exs --max-failures 1` | ✅ | ⬜ pending |
| 91-01-02 | 01 | 1 | SCOPE-01, SCOPE-02 | T-91-02 | The mounted `/audit` transaction-history path threads `scope` and `scope_query_fn` into row-history queries and proves support-visible behavior honestly on the current tree. | mounted integration | `MIX_ENV=test mix test test/threadline/operator_surface/transaction_live_test.exs --max-failures 1` | ✅ | ⬜ pending |
| 91-02-01 | 02 | 2 | SCOPE-01, SCOPE-02 | T-91-03 | `86-VERIFICATION.md` and `86-VALIDATION.md` record only the proof the current tree actually earned, distinguishing proven behavior from any still-`unclaimed` support path. | artifact review | `rg -n 'SCOPE-01|SCOPE-02|history/3|as_of/4|row_history/4|row_history_page/4|unclaimed|Commands Actually Used|nyquist_compliant: true' .planning/phases/86-scoped-read-path-closure/86-VERIFICATION.md .planning/phases/86-scoped-read-path-closure/86-VALIDATION.md` | ❌ W0 | ⬜ pending |
| 91-02-02 | 02 | 2 | SCOPE-01, SCOPE-02 | T-91-03 | If Phase 91 promotes the support-lane claim, authority and public truth surfaces move in lockstep; if not, they continue to mark row-history / as-of as `unclaimed` for support sessions. | doc-contract + planning artifact | `MIX_ENV=test mix test test/threadline/operator_surface_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1 && rg -n 'SCOPE-01|SCOPE-02|Phase 91|Complete|unclaimed' .planning/REQUIREMENTS.md .planning/ROADMAP.md .planning/STATE.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [ ] Add explicit scoped assertions to `test/threadline/query_test.exs` for `Threadline.history/3` and `Threadline.as_of/4`.
- [ ] Add explicit scoped assertions to `test/threadline/investigation_test.exs` for `Threadline.row_history/4` and `Threadline.row_history_page/4`.
- [ ] Strengthen `test/threadline/operator_surface/transaction_live_test.exs` to prove the mounted row-history route through the scoped `/audit` tree.
- [ ] Create `.planning/phases/86-scoped-read-path-closure/86-VERIFICATION.md` after the proof verdict is known.
- [ ] Create `.planning/phases/86-scoped-read-path-closure/86-VALIDATION.md` after execution evidence is recorded.
- [ ] If proof promotes the current public claim, update the matching guide/example wording and paired doc-contract assertions in the same pass.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Judge whether the row-history / as-of support-lane claim can be promoted or must remain `unclaimed` | SCOPE-02 | This is a truth-boundary decision that depends on proof strength across queries, mounted LiveView flow, and authority surfaces, not just a single grep or passing test. | After targeted proof is green, compare the new evidence with the current public claim bar. Promote the claim only if query-level, helper-level, and mounted `/audit` proof all exist and match the shipped user-facing story. |

---

## Validation Sign-Off

- [x] All planned tasks have explicit automated verification coverage.
- [x] Sampling continuity stays below the three-task Nyquist gap.
- [x] No watch-mode or non-deterministic verification commands are required.
- [ ] `nyquist_compliant: true` will be set after execution evidence is recorded.

**Approval:** pending
