---
phase: 103
slug: authority-surface-reconciliation-and-milestone-re-audit
status: finalized
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
updated: 2026-05-27T10:27:00Z
---

# Phase 103 — Validation Strategy

> Finalized validation artifact for the v1.22 closeout rerun recorded in
> Phase 103-02.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Mix alias verification + planning artifact review |
| **Config file** | `mix.exs`, `.planning/v1.22-MILESTONE-AUDIT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/PROJECT.md` |
| **Quick run command** | `mix verify.doc_contract` |
| **Named proof commands** | `mix verify.doc_contract` and `mix verify.example` |
| **Full closeout bundle** | `mix verify.doc_contract` then `MIX_ENV=test mix test test/threadline/evidence_test.exs test/threadline/evidence/proof_test.exs test/mix/tasks/threadline.evidence_show_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/auth_test.exs --max-failures 1` then `mix verify.example` |
| **Artifact checks** | `rg` for `SURF-01`/`SURF-02`/`SURF-03`, named proof commands, `/gsd-complete-milestone v1.22`, and closeout_readiness wording in the final Phase 103 artifacts |
| **Estimated runtime** | ~20-30 seconds warm for the full rerun bundle |

## Sampling Rate

- After any guide or example contract edit affecting the evidence-plane
  claim: run `mix verify.doc_contract`.
- After any example-host wiring change affecting the canonical
  `/audit/evidence` lane: run `mix verify.example`.
- After any evidence-plane runtime or seam change: rerun the 5-file middle
  bundle (`evidence_test.exs`, `proof_test.exs`,
  `threadline.evidence_show_test.exs`, `evidence_live_test.exs`,
  `auth_test.exs`).
- Before closing v1.22: require all three proof bands green on the same
  tree, then refresh the milestone audit from that evidence.

## Per-Task Verification Map

| Task ID | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Status |
|---------|-------------|------------|-----------------|-----------|-------------------|--------|
| 103-V-01 | `SURF-01`, `SURF-02`, `SURF-03` (closure via REQUIREMENTS.md row flips) | `T-103-01` | Authority surfaces close SURF traceability only when Phase 102 VERIFICATION PASS is durable on the current tree. | artifact review | `rg -c '^\| SURF-0[123] \| Phase 102 \| Complete \|$' .planning/REQUIREMENTS.md` | ✅ green |
| 103-V-02 | `DOC-01`, `DOC-02`, `DOC-03` | `T-103-04` | Public contract surfaces still describe the exact proven evidence plane and host-owned seams. | doc-contract | `mix verify.doc_contract` | ✅ green |
| 103-V-03 | evidence-plane seam (EVID, PROOF, SURF) | `T-103-04` | The 5-file evidence-plane bundle proves library API + Mix-task + mounted view + auth gate parity on the current tree. | focused integration | `MIX_ENV=test mix test test/threadline/evidence_test.exs test/threadline/evidence/proof_test.exs test/mix/tasks/threadline.evidence_show_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/auth_test.exs --max-failures 1` | ✅ green |
| 103-V-04 | example-host parity (`SURF-01`, `SURF-02`, `DOC-01`, `DOC-02`) | `T-103-04` | `mix verify.example` proves canonical `/audit/evidence` on the runnable example host. | nested integration | `mix verify.example` | ✅ green |
| 103-V-05 | audit rewrite | `T-103-05` | `v1.22-MILESTONE-AUDIT.md` `status` flips to `passed` only after the rerun bundle proves green. | artifact review | `rg -q '^status: passed$' .planning/v1.22-MILESTONE-AUDIT.md` | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

## Requirement-to-Command Map

| Requirement | Evidence Band | Command | Why This Command Counts |
|-------------|---------------|---------|-------------------------|
| `EVID-01`, `EVID-02`, `EVID-03` | Evidence-plane seam bundle | 5-file middle bundle (`evidence_test.exs` first) | Re-proves the append-only evidence contract and subject inventory on the current tree (Phase 100 backfill closure). |
| `PROOF-01` | Evidence-plane seam bundle | 5-file middle bundle | Re-proves the public evidence write/read API and Phoenix-optional usage (Phase 101 backfill closure). |
| `PROOF-02`, `PROOF-03` | Evidence-plane seam bundle | 5-file middle bundle (`proof_test.exs` and `threadline.evidence_show_test.exs`) | Re-proves verdict vocabulary and Mix-task parity at the original Phase 97 verifier. |
| `SURF-01`, `SURF-02` | Evidence-plane seam bundle + Example-host proof | `evidence_live_test.exs` + `mix verify.example` | Re-proves mounted `/audit/evidence` parity and example-host wiring (Phase 102 backfill closure). |
| `SURF-03` | Evidence-plane seam bundle | `auth_test.exs` | Re-proves the host-owned `evidence_authorize_fn` fail-closed gate. |
| `DOC-01`, `DOC-02`, `DOC-03` | Public contract + example-host proof | `mix verify.doc_contract` and `mix verify.example` | Locks the public docs, example README, and support-matrix wording to the exact current evidence-plane claim and explicit negative claims. |

## Commands Actually Used

1. `mix verify.doc_contract`  
   Result: PASS (`46 tests, 0 failures`), exit 0
2. `MIX_ENV=test mix test test/threadline/evidence_test.exs test/threadline/evidence/proof_test.exs test/mix/tasks/threadline.evidence_show_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/auth_test.exs --max-failures 1`  
   Result: PASS (`55 tests, 0 failures`), exit 0
3. `mix verify.example`  
   Result: PASS (`21 tests, 0 failures`), exit 0

## Nyquist Notes

- The rerun remains compliant only if the audit and requirement closure are
  refreshed from the same proof bundle recorded here.
- `SURF-01`, `SURF-02`, and `SURF-03` closure must remain open if any one
  of the three proof bands turns red on a later tree.
- `103-01-SUMMARY.md` and `103-02-SUMMARY.md` frontmatter are NOT
  authoritative for requirement closure; only this rerun-backed artifact
  pair plus the refreshed milestone audit can close the final v1.22
  requirements.

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. The three D-10
commands (`mix verify.doc_contract`, the 5-file `mix test` bundle, and
`mix verify.example`) and the planning artifacts under `.planning/` are
all already present on the current tree; no Wave 0 install is required.

## Manual-Only Verifications

All phase behaviors have automated verification. The D-10 closeout bundle
+ artifact greps cover every closeout-bearing requirement on the
reconciled tree; no manual-only step gates Phase 103 closure.

## Validation Sign-Off

- [x] All closeout-bearing tasks map to named rerun surfaces or explicit
      artifact checks.
- [x] Commands actually used are recorded exactly.
- [x] The rerun bundle stayed green on the reconciled tree.
- [x] `SURF-01`, `SURF-02`, and `SURF-03` are defined as evidence-gated,
      not prose-gated.
- [x] `nyquist_compliant: true` is set only after the full rerun bundle
      passed.

**Approval:** finalized on 2026-05-27 after `mix verify.doc_contract`, the
5-file evidence-plane bundle (`test/threadline/evidence_test.exs`,
`test/threadline/evidence/proof_test.exs`,
`test/mix/tasks/threadline.evidence_show_test.exs`,
`test/threadline/operator_surface/live/evidence_live_test.exs`,
`test/threadline/operator_surface/auth_test.exs`), and `mix verify.example`
all passed on the reconciled current tree.
