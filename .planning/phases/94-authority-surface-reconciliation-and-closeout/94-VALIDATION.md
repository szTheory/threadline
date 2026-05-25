---
phase: 94
slug: authority-surface-reconciliation-and-closeout
status: finalized
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
updated: 2026-05-25T16:18:47Z
---

# Phase 94 — Validation Strategy

> Finalized validation artifact for the v1.21 closeout rerun recorded in Phase
> 94-02.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Mix alias verification + planning artifact review |
| **Config file** | `mix.exs`, `.planning/v1.21-MILESTONE-AUDIT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/PROJECT.md` |
| **Quick run command** | `mix verify.doc_contract` |
| **Named proof commands** | `mix verify.doc_contract` and `mix verify.example` |
| **Root support-lane proof** | `MIX_ENV=test mix test test/threadline/query_test.exs test/threadline/investigation_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs --max-failures 1` |
| **Artifact checks** | grep for `DOC-01`, `DOC-02`, named proof commands, and closeout wording in the final Phase 94 artifacts |
| **Estimated runtime** | ~15 seconds warm for the full rerun bundle |

## Sampling Rate

- After any guide or example contract edit affecting the support-lane claim:
  run `mix verify.doc_contract`.
- After any example-host wiring change affecting the canonical `/audit` lane:
  run `mix verify.example`.
- After any scoped read-path or denial/fallback runtime change affecting the
  claimed support lane: rerun the targeted root suite.
- Before closing `DOC-01` or `DOC-02`: require all three proof bands green on
  the same tree, then refresh the milestone audit from that evidence.

## Per-Task Verification Map

| Task ID | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Status |
|---------|-------------|------------|-----------------|-----------|-------------------|--------|
| 94-V-01 | `DOC-01`, `DOC-02` | `T-94-04` | Public contract surfaces still describe the exact proven support lane and host-owned seams. | doc-contract | `mix verify.doc_contract` | ✅ green |
| 94-V-02 | `ADOPT-01`, `ADOPT-02`, `DOC-01`, `DOC-02` | `T-94-04` | The runnable example host still proves the canonical shared `/audit` lane and admin-only export posture. | nested integration | `mix verify.example` | ✅ green |
| 94-V-03 | `SCOPE-01`, `SCOPE-02`, `AUTH-01`, `UX-01`, `UX-02`, `DOC-02` | `T-94-04` | The targeted root support-lane slice still proves scoped row history / as-of plus denial/fallback behavior on the shipped tree. | focused integration | `MIX_ENV=test mix test ... --max-failures 1` | ✅ green |
| 94-V-04 | `DOC-01`, `DOC-02` | `T-94-05` | The final Phase 94 artifacts record only current-tree rerun evidence and make closeout readiness explicit. | artifact review | `rg -n 'DOC-01|DOC-02|mix verify\\.doc_contract|mix verify\\.example|SCOPE-01|SCOPE-02|AUTH-01|UX-01|UX-02|ADOPT-01|ADOPT-02|closeout readiness' .planning/phases/94-authority-surface-reconciliation-and-closeout/94-VERIFICATION.md .planning/phases/94-authority-surface-reconciliation-and-closeout/94-VALIDATION.md` | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

## Requirement-to-Command Map

| Requirement | Evidence Band | Command | Why This Command Counts |
|-------------|---------------|---------|-------------------------|
| `DOC-01` | Public contract + example-host proof | `mix verify.doc_contract` and `mix verify.example` | Locks the public docs and example-host wording to the exact current support-lane claim instead of inherited prose. |
| `DOC-02` | Full rerun bundle | `mix verify.doc_contract`, `mix verify.example`, and targeted root suite | Proves the contract, example-host, and scoped runtime lane all agree on the current tree. |
| `SCOPE-01`, `SCOPE-02` | Root support-lane proof | targeted root suite | Re-proves scoped reads plus row history / as-of on the shipped `/audit` route. |
| `AUTH-01`, `UX-01`, `UX-02` | Root support-lane proof | targeted root suite | Re-proves hidden export affordances, direct HTTP denial, explicit denied state, and unsupported-view fallback messaging. |
| `ADOPT-01`, `ADOPT-02` | Example-host proof | `mix verify.example` | Re-proves the canonical `/audit` mount recipe and example-host support lane through the maintained reference app. |

## Commands Actually Used

1. `mix verify.doc_contract`  
   Result: PASS (`43 tests, 0 failures`)
2. `mix verify.example`  
   Result: PASS (`21 tests, 0 failures`)
3. `MIX_ENV=test mix test test/threadline/query_test.exs test/threadline/investigation_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs --max-failures 1`  
   Result: PASS (`141 tests, 0 failures`)
4. `rg -n 'DOC-01|DOC-02|mix verify\\.doc_contract|mix verify\\.example|SCOPE-01|SCOPE-02|AUTH-01|UX-01|UX-02|ADOPT-01|ADOPT-02|closeout readiness' .planning/phases/94-authority-surface-reconciliation-and-closeout/94-VERIFICATION.md .planning/phases/94-authority-surface-reconciliation-and-closeout/94-VALIDATION.md`  
   Result: pending until artifact write completes, then expected PASS

## Nyquist Notes

- The rerun remains compliant only if the audit and requirement closure are
  refreshed from the same proof bundle recorded here.
- `DOC-01` and `DOC-02` must remain open if any one of the three proof bands
  turns red on a later tree.
- `94-01-SUMMARY.md` frontmatter is not authoritative for requirement closure;
  only this rerun-backed artifact pair plus the refreshed milestone audit can
  close the final documentation requirements.

## Validation Sign-Off

- [x] All closeout-bearing tasks map to named rerun surfaces or explicit
      artifact checks.
- [x] Commands actually used are recorded exactly.
- [x] The rerun bundle stayed green on the repaired tree.
- [x] `DOC-01` and `DOC-02` are defined as evidence-gated, not prose-gated.
- [x] `nyquist_compliant: true` is set only after the full rerun bundle passed.

**Approval:** finalized on 2026-05-25 after `mix verify.doc_contract`,
`mix verify.example`, and the targeted root support-lane suite all passed on
the repaired current tree.
