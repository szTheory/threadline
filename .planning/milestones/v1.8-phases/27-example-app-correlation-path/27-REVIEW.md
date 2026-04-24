---
phase: 27-example-app-correlation-path
status: clean
reviewed: 2026-04-24
---

# Phase 27 code review (advisory)

## Scope

- `examples/threadline_phoenix/lib/threadline_phoenix/blog.ex` — **`record_action`** + **`audit_transactions.action_id`** link
- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_correlation_path_test.exs` — HTTP → timeline proof
- `examples/threadline_phoenix/README.md` — operator contract and export snippet

## Findings

- **Semantics / capture:** **`record_action`** runs only after **`{:ok, post}`**; linkage uses **`txid_current()`** scoped to the open transaction — avoids cross-transaction updates. Rollback paths preserve atomicity.
- **Security:** Reuses existing **`AuditContext.actor_ref`** from **`Threadline.Plug`**; no new trust boundary.
- **Quality:** Test follows **`PostsAuditPathTest`** ConnCase patterns; README preserves REF-01 literals.

## Recommendation

Ship as-is.
