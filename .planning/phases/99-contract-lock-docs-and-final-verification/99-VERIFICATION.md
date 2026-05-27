---
phase: 99-contract-lock-docs-and-final-verification
verified: 2026-05-26T14:12:32Z
status: verified_with_followup
score: 4/4 rerun bands reviewed
authoritative_surface_drift: detected
---

# Phase 99: Contract Lock, Docs, And Final Verification - Verification Report

**Phase Goal:** Lock the public evidence-plane claim on the current tree through aligned docs, named doc-contract coverage, targeted behavioral proof, and one explicit rerun bundle that stays separate from broader repo-health failures.

**Verified:** 2026-05-26T14:12:32Z  
**Status:** verified with follow-up  
**Re-verification:** No

---

## Current-tree preflight

**Result:** PASS with noted state drift

- Dirty-tree snapshot captured before verification: the working tree already contained Phase 98/99 evidence changes plus unrelated formatting drift and documentation edits outside the Phase 99 target list.
- On-disk Phase 98 authority artifacts are present: `98-01-SUMMARY.md`, `98-02-SUMMARY.md`, and `test/threadline/operator_surface/live/evidence_live_test.exs`.
- `STATE.md` is not fully authoritative for the current tree: `Current Focus`, `Milestone Readiness`, `Last Action`, and `Next Step` still talk about verifying Phase 96 even though Phase 99 execution is in progress on disk.

This phase therefore treats the working tree plus the on-disk Phase 98/99 artifacts as ground truth, and records the rerun bundle below as the authority for `DOC-03`.

---

## 1. Public doc-contract lock

**Result:** PASS

The public docs now agree on the same bounded evidence-plane story:

- `README.md` stays a front door, adds one compact evidence-plane claim strip, and links outward to the canonical guides instead of becoming a shadow spec.
- `guides/how-threadline-works.md` owns the canonical non-goals list, including legal hold, immutable-storage guarantees beyond the host contract, generic compliance packs, vendor-specific reporting suites, and Threadline-owned RBAC / tenancy DSL claims.
- `guides/upgrade-path.md`, `guides/integration-contracts.md`, and `guides/operator-surface.md` now describe `/audit/evidence` as separately authorized and host-owned rather than automatically inherited from any mounted `/audit` path.
- `guides/domain-reference.md` remains the owner of `claim_assessment`, `proven`, `inferred_posture`, and `unsupported`.

### Evidence

```bash
mix verify.doc_contract
```

Result: PASS

---

## 2. Current-tree behavioral proof

**Result:** PASS

The current tree proves the same bounded story in behavior:

- `Threadline.Evidence` and `Threadline.Evidence.Proof` keep the exact verdict vocabulary.
- `mix threadline.evidence.show` remains a viewer, including valid unsupported output.
- Mounted `/audit/evidence` renders overview/history on the allowed path and an explicit `Unsupported View` plus CLI fallback when denied.
- `evidence_authorize_fn` stays fail-closed and host-owned.

### Evidence

```bash
MIX_ENV=test mix test test/threadline/evidence_test.exs test/threadline/evidence/proof_test.exs test/mix/tasks/threadline.evidence_show_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/auth_test.exs --max-failures 1
```

Result: PASS

---

## 3. Example-host proof

**Result:** PASS

The example app still proves the narrower `sigra-reference` lane while keeping evidence access subordinate to the root library's broader `phoenix-surface` contract.

### Evidence

```bash
mix verify.example
```

Result: PASS

---

## 4. Repo-health / named full-suite proof

**Result:** FAIL, but scoped separately from the claim proof

`mix ci.all` is useful repo-health evidence, but it is not the authority for the evidence-plane claim. On this tree it fails immediately in `mix verify.format` before the broader compile/test chain runs.

### Evidence

```bash
mix ci.all
```

Result: FAIL

Failure surface recorded from the run:

- `lib/mix/tasks/threadline.evidence.show.ex`
- `lib/threadline/evidence.ex`
- `test/threadline/evidence/proof_test.exs`
- `test/threadline/evidence_test.exs`
- multiple unrelated operator-surface and retention files already dirty in the tree

This is broader repo-health drift, not a contradiction of the Phase 99 claim bundle above. The claim-shaped reruns passed; the full-suite gate is red because the working tree is not format-clean.

---

## Known unrelated failures

- `mix ci.all` fails on `mix verify.format` against a dirty working tree.
- The failure is not evidence-plane contract drift; it is repo-health drift spanning both Phase 99-adjacent files and unrelated files already modified before this closeout.

---

## Authority statement

The authoritative Phase 99 rerun bundle is:

1. `mix verify.doc_contract`
2. `MIX_ENV=test mix test test/threadline/evidence_test.exs test/threadline/evidence/proof_test.exs test/mix/tasks/threadline.evidence_show_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/auth_test.exs --max-failures 1`
3. `mix verify.example`

Those three commands are the authority for `DOC-03` on the current tree. `mix ci.all` remains recorded as repo-health evidence and is intentionally not collapsed into the claim verdict.
