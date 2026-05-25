---
phase: 86-scoped-read-path-closure
verified: 2026-05-25T13:34:15Z
status: verified
score: 3/3 evidence bands reviewed
authoritative_surface_drift: reconciled
---

# Phase 86: Scoped Read-Path Closure — Verification Report

**Phase Goal:** Close `SCOPE-01` and `SCOPE-02` against the current tree by proving that support-scoped operators only see host-allowed audit records across the shipped `/audit` read paths, including row history / as-of.

**Verified:** 2026-05-25T13:34:15Z  
**Status:** verified  
**Re-verification:** Yes, via Phase 91 current-tree backfill

Verdict: support-scoped row history / as-of is proven on the current tree.

## Requirement Verdict

- `SCOPE-01`: PASS. Support-scoped operators only see records allowed by the host-owned scope across the proven `/audit` read paths.
- `SCOPE-02`: PASS. `history/3`, `as_of/4`, `row_history/4`, and `row_history_page/4` are scope-aware with current-tree proof at the query, helper, and mounted-route layers.

## 1. Query-Level Proof

**Result:** PASS

The direct historical query APIs now have explicit support-scope assertions:

- `Threadline.history/3` excludes out-of-scope row history entries.
- `Threadline.as_of/4` reconstructs only the in-scope snapshot when a later out-of-scope change exists.

The current tree still uses the original Phase 86 seam:

- `lib/threadline/query.ex` keeps `surface: Keyword.get(opts, :surface, :row_history)`
- row-history queries still pass through `maybe_apply_scope/2`

## 2. Helper / Public API Parity

**Result:** PASS

The higher-level investigation helpers now prove the same scoped behavior instead of relying on query-layer implication:

- `Threadline.row_history/4` returns only support-visible linked changes.
- `Threadline.row_history_page/4` preserves the same scoped result set under paging.

This closes the public helper contract, not just the lower-level query composition.

## 3. Mounted `/audit` Transaction-History Proof

**Result:** PASS

The shipped `/audit_scoped/transactions/:id/history/:table/:record_id` route now has direct current-tree proof:

- the support-scoped mounted route renders in-scope row history
- out-of-scope historical content does not appear
- `TransactionLive` now persists the resolved repo onto the socket so `RowHistoryComponent` receives the same repo as the transaction drill-down path

That repo-threading fix was the only code repair required during this verification backfill.

## 4. Authority-Surface Outcome

**Result:** PASS

Because all three proof bands are green, the authoritative claim moves from “narrowed / unclaimed” to “proven” for support-scoped row history / as-of on the current tree. Phase 91 therefore updates:

- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `guides/operator-surface.md`
- `guides/upgrade-path.md`
- `guides/getting-started-saas.md`
- `examples/threadline_phoenix/README.md`

## Commands Actually Used

```bash
MIX_ENV=test mix test test/threadline/query_test.exs test/threadline/investigation_test.exs --max-failures 1
MIX_ENV=test mix test test/threadline/operator_surface/transaction_live_test.exs --seed 154054
MIX_ENV=test mix test test/threadline/query_test.exs test/threadline/investigation_test.exs test/threadline/operator_surface/transaction_live_test.exs --max-failures 1
```

All commands passed on the current tree after the narrow `TransactionLive` repo-threading repair.

## Not Closed Here

This verification artifact does **not** close later-phase or broader milestone work:

- `ADOPT-01` — canonical `/audit` mount recipe proof remains in Phase 92
- `ADOPT-02` — example-app verification backfill remains in Phase 92
- `AUTH-01` — export denial posture remains in Phase 93
- `UX-01` — denial / fallback UX closure remains in Phase 93
- `UX-02` — support-lane fallback guidance remains in Phase 93
- `DOC-01` — broader contract reconciliation remains in Phase 94
- `DOC-02` — milestone re-audit and final authority lock remain in Phase 94

This file closes the missing Phase 86 current-tree proof only.
