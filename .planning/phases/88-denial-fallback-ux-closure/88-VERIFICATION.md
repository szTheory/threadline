---
phase: 88-denial-fallback-ux-closure
verified: 2026-05-25T15:40:00Z
status: verified
score: 4/4 evidence bands green
authoritative_surface_drift: none
---

# Phase 88: Denial / Fallback UX Closure — Verification Report

**Phase Goal:** Prove on the current tree that the support-lane denial/fallback UX stays truthful across hidden export affordances, direct HTTP export denial, explicit unavailable/denied screens, public docs, the example host, and named rerun entrypoints.

**Verified:** 2026-05-25  
**Status:** verified  
**Re-verification:** Yes

---

## Claim Boundary

Phase 88 closes the denial/fallback UX claim for the shipped shared `/audit`
tree:

- support-scoped sessions remain read-only by default
- export affordances stay hidden when export is unavailable to that session
- direct export requests still fail server-side with plain-text `403 forbidden`
- denied export routes render explicit `Action Denied` fallback guidance instead
  of redirect-only or blank states
- unsupported coverage, policy, and retention surfaces render explicit
  `Unsupported View` messaging with truthful fallback transports
- the operator guide, SaaS quickstart, integration contract guide, and example
  README teach the same host-owned callback seams and fallback posture
- maintainers can rerun the same proof via `mix verify.doc_contract` and
  `mix verify.example`

This verification inherits the Phase 91 scoped-read truth boundary. It closes
the denial/fallback UX and export-denial posture; it does not reopen broader
milestone reconciliation or any future support-lane widening beyond what the
current tree already proves.

---

## 1. Root Behavioral Evidence

**Result:** PASS

The root operator-surface tests still prove the full denial/fallback chain:

- support-scoped timeline sessions hide `Request Background Export` when export
  is unavailable
- direct export requests still return plain-text `403 forbidden`
- denied export routes show explicit `Action Denied` fallback messaging
- unsupported coverage, policy, and retention surfaces show explicit
  `Unsupported View` messaging instead of redirect-only handling

This keeps the proof server-authoritative. Hidden affordances remain convenience
UX only; the direct HTTP boundary still denies access independently.

### Evidence

```bash
mix test \
  test/threadline/operator_surface/live/timeline_live_test.exs \
  test/threadline/operator_surface/controllers/export_controller_test.exs \
  test/threadline/operator_surface/live/export_status_live_test.exs \
  test/threadline/operator_surface/live/coverage_live_test.exs \
  test/threadline/operator_surface/live/policy_redaction_live_test.exs \
  test/threadline/operator_surface/live/retention_history_live_test.exs \
  --max-failures 1
```

Result: PASS

Supporting spot-check:

```bash
rg -n 'Request Background Export|forbidden|Action Denied|Unsupported View' \
  test/threadline/operator_surface/live/timeline_live_test.exs \
  test/threadline/operator_surface/controllers/export_controller_test.exs \
  test/threadline/operator_surface/live/export_status_live_test.exs \
  test/threadline/operator_surface/live/coverage_live_test.exs \
  test/threadline/operator_surface/live/policy_redaction_live_test.exs \
  test/threadline/operator_surface/live/retention_history_live_test.exs
```

Result: PASS

---

## 2. Public Contract Evidence

**Result:** PASS

The public contract surfaces still describe the same denial/fallback posture:

- `guides/operator-surface.md` keeps one shared `/audit` tree and teaches the
  hidden-affordance plus explicit-denial story
- `guides/getting-started-saas.md` keeps the host-owned `authorize_fn`,
  `scope_query_fn`, and `export_authorize_fn` seams together with the exact
  fallback transports
- `guides/integration-contracts.md` keeps auth, scope, and export posture
  host-owned and avoids introducing a Threadline-owned policy or tenancy DSL

The current wording is truthful on the current tree and does not require
additional narrowing for Phase 88 closure.

### Evidence

```bash
mix verify.doc_contract
```

Result: PASS

Supporting spot-check:

```bash
rg -n 'authorize_fn|scope_query_fn|export_authorize_fn|plain-text `403`|Unsupported View|mix threadline.export --dry-run|mix threadline.health.coverage|mix threadline.policy.show' \
  guides/operator-surface.md \
  guides/getting-started-saas.md \
  guides/integration-contracts.md
```

Result: PASS

Negative guard:

```bash
rg -n '/support tree|policy DSL|tenancy DSL' \
  guides/operator-surface.md \
  guides/getting-started-saas.md \
  guides/integration-contracts.md
```

Result: PASS for the intended guardrail. No separate support-tree claim or
Threadline-owned tenancy/policy model is introduced.

---

## 3. Example-Host Evidence

**Result:** PASS

The example Phoenix host still proves the same denial/fallback posture in its
own truthful runtime context:

- one shared `/audit` tree
- host-owned `authorize_fn`
- host-owned `scope_query_fn`
- admin-only export posture via `export_authorize_fn`
- aligned README and router-backed proof

The example app remains intentionally narrow: it proves the shipped Phoenix host
lane, not arbitrary consumer stacks.

### Evidence

```bash
mix verify.example
```

Result: PASS

Supporting spot-check:

```bash
rg -n 'scope "/audit"|authorize_fn|scope_query_fn|export_authorize_fn' \
  examples/threadline_phoenix/README.md \
  examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
```

Result: PASS

---

## 4. Named Rerun Surface Evidence

**Result:** PASS

The proof remains discoverable through the same named rerun surfaces:

- `mix verify.doc_contract`
- `mix verify.example`
- CI-visible verification steps in `.github/workflows/ci.yml`

This preserves a rerunnable contract chain rather than an artifact-only claim.

### Evidence

```bash
rg -n 'verify\.example|verify\.doc_contract|ci\.all' mix.exs
rg -n 'run: mix verify\.example|run: mix verify\.doc_contract|verify-test|verify-docs' .github/workflows/ci.yml
```

Result: PASS

---

## 5. Requirement Verdicts

### AUTH-01

**Verdict:** PASS

Support-scoped operators remain read-only by default for export. The current
tree proves both hidden export affordances and direct HTTP `403 forbidden`
enforcement unless the host explicitly opts into a different export posture
through `export_authorize_fn`.

### UX-01

**Verdict:** PASS

Support-scoped operators get the claimed least-surprise denial/fallback UX:
hidden unavailable export affordances, explicit denied export messaging, and
explicit unsupported-view states for surfaces outside the support lane.

### UX-02

**Verdict:** PASS

The operator guide, SaaS quickstart, integration contracts guide, example
README, and named rerun surfaces stay aligned on fallback transports and on what
to do instead when a support-scoped operator hits an unavailable surface.

---

## 6. Caveats

- This verification uses the current working tree as the source of truth because
  the repo already contained unrelated local edits when Phase 93 execution
  started.
- No Wave 1 source repair was needed, so this backfill records the verified
  current-tree posture rather than introducing new implementation behavior.
- `mix ci.all` was not required for this phase. Phase 93 closes on the targeted
  denial/fallback proof bar, not on unrelated full-suite cleanliness.

---

## 7. not closed here

The following concerns remain outside Phase 88 closure:

- broader milestone authority reconciliation still owned by Phase 94
- unrelated documentation drift such as `guides/how-threadline-works.md`
- any future widening of support-lane capability beyond the denial/fallback
  posture proven here

Phase 88 is therefore verified for the denial/fallback UX and export-denial
contract on the current tree.
