---
phase: 89-contract-lock-final-verification
verified: 2026-05-25T07:45:00Z
status: verified_with_followup
score: 4/4 evidence bands reviewed
authoritative_surface_drift: detected
---

# Phase 89: Contract Lock & Final Verification — Verification Report

**Phase Goal:** Prove on the current tree that Threadline’s public docs, root behavior, example-host proof, and named verification surfaces all describe the same support lane truthfully, with support-scoped row history / as-of narrowed out of the claimed lane until explicit scoped proof exists.

**Verified:** 2026-05-25T07:45:00Z  
**Status:** verified with follow-up  
**Re-verification:** No

---

## 1. Public Contract Text

**Result:** PASS

The public contract surfaces now agree on the same layered story:

- `guides/upgrade-path.md` remains the lane-taxonomy authority and now says the v1.21 mounted proof covers timeline, actor, transaction, and export-auth seams while support-scoped row history / as-of remains `unclaimed`.
- `guides/operator-surface.md` keeps the row-history route documented as a product surface but explicitly narrows the support-lane claim for that path.
- `guides/getting-started-saas.md` keeps the shared `/audit` recipe truthful by saying `scope_query_fn` narrows timeline, actor, and transaction, while row history / as-of stays a direct API tool unless separately proven.
- `guides/integration-contracts.md` now names `scope_query_fn` beside `authorize_fn` and `export_authorize_fn` as the host-owned seam contract.
- `examples/threadline_phoenix/README.md` stays a `sigra-reference` proof artifact and no longer implies that the example proves support-scoped row history / as-of.

### Evidence

```bash
mix verify.doc_contract
```

Result: PASS

---

## 2. Root Behavioral Proof

**Result:** PASS

The root app still proves the support-lane surfaces that remain claimed:

- timeline scoping
- actor scoping
- transaction scoping
- export denial and unsupported/fallback posture for coverage, policy, and retention

No new row-history support test was added in this phase because the public claim was narrowed instead of widened. That is intentional and matches the verified docs.

### Evidence

```bash
MIX_ENV=test mix test \
  test/threadline/operator_surface/transaction_live_test.exs \
  test/threadline/operator_surface/live/timeline_live_test.exs \
  test/threadline/operator_surface/live/actor_live_test.exs \
  test/threadline/operator_surface/controllers/export_controller_test.exs \
  test/threadline/operator_surface/live/export_status_live_test.exs \
  test/threadline/operator_surface/live/coverage_live_test.exs \
  test/threadline/operator_surface/live/policy_redaction_live_test.exs \
  test/threadline/operator_surface/live/retention_history_live_test.exs \
  --max-failures 1
```

Result: PASS

---

## 3. Example-Host Proof

**Result:** PASS

The example app still proves the narrower `sigra-reference` lane in its own app context:

- authenticated operator boundary on `/audit`
- scoped support access for the still-claimed read surfaces
- admin-only export capability
- aligned README and router-backed proof

The root app cannot compile `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs` directly because that file depends on the example app’s `ConnCase`. The honest current-tree proof path is therefore `mix verify.example`, which compiles and runs the example app inside its own project context.

### Evidence

```bash
mix verify.example
```

Result: PASS

---

## 4. Named Verification/CI Proof

**Result:** MIXED, but honest

What passed:

- `mix verify.doc_contract` now runs in `MIX_ENV=test` directly and covers the full support-lane contract suite.
- `mix verify.example` remains the named example-proof entrypoint.
- `mix.exs` and `.github/workflows/ci.yml` still expose the stable alias and job names that the docs point to.

What failed:

- `mix ci.all` currently fails on `mix verify.format` because the working tree already contains unrelated unformatted local edits outside Phase 89 ownership.

This means the named proof surface is wired correctly, but the local dirty tree is not full-suite clean at the moment. That failure is real and is recorded here instead of being hidden.

### Evidence

```bash
rg -n 'verify\.doc_contract|verify\.example|verify\.test|ci\.all' mix.exs && \
rg -n 'verify-test|verify-docs|verify-compile-no-optional' .github/workflows/ci.yml
```

Result: PASS

```bash
mix ci.all
```

Result: FAIL on formatting checks in pre-existing local edits outside the Phase 89 execution slice.

---

## 5. Authoritative-Surface Drift

**Verdict:** detected

The public contract and proof surfaces are now honest, but milestone authority files still contradict that verified truth:

- `.planning/ROADMAP.md` still says row history / as-of “will be safely scoped via scope_query_fn, not disabled.”
- `.planning/STATE.md` still reports “Execute Phase 85” / “Start Phase 85” and milestone metrics from before the v1.21 execution run.

Those files are authoritative milestone surfaces, so Phase 89 must not silently patch them inside this verification plan. Per the phase boundary, that contradiction requires a separate `89-03` reconciliation plan.

### Required Follow-up

- Open or execute `89-03` specifically to reconcile `ROADMAP.md` and `STATE.md` with the now-verified narrowed support-lane claim.
- Do not claim Phase 89 fully closed until that authority-layer drift is resolved.

---

## Gaps Summary

- **No gap** remains in the public contract lock for the currently claimed support-lane surfaces.
- **No gap** remains in the named alias or CI discoverability contract.
- **A remaining gap** exists in milestone authority surfaces (`ROADMAP.md`, `STATE.md`), so final phase closeout still depends on `89-03`.

Phase 89 is therefore **verified on the current tree with a required follow-up**, not fully closed.
