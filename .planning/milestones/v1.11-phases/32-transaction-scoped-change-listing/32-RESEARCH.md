# Phase 32 — Technical research

**Phase:** 32 — Transaction-scoped change listing  
**Question:** What do we need to know to plan XPLO-02 well?

## Summary

Phase 32 adds a **narrow, read-only** listing API: all `%AuditChange{}` rows for one `audit_transactions.id`, explicit `:repo`, stable **total order** aligned with `timeline_order/1` (`captured_at` DESC, `id` DESC). **No** timeline filter vocabulary extension; **no** capture or schema migrations.

Anchors: `lib/threadline/query.ex` (`timeline_order/1`, `history/3`, `Keyword.fetch!(opts, :repo)`), `test/threadline/query_test.exs` (`insert_transaction/1`, `insert_change/2`), `32-CONTEXT.md` (D-1–D-6).

## API surface

| Decision | Choice |
|----------|--------|
| Name | `audit_changes_for_transaction/2` on `Threadline.Query` and `Threadline` |
| Args | `(transaction_id, opts)` with required `opts[:repo]` |
| Order | `order_by desc: captured_at`, `order_by desc: id` — reuse same stack as `timeline_order/1` |
| Bad UUID | `ArgumentError` before DB (e.g. `Ecto.UUID.cast/1` → `:error`) |
| Unknown txn / no rows | `[]` (do not distinguish txn missing vs zero children) |
| Preload | Opt-in `opts[:preload]` only; default plain `%AuditChange{}` |

## Ecto mechanics

- Query: `from ac in AuditChange, where: ac.transaction_id == ^id, order_by: [desc: ac.captured_at, desc: ac.id]` — or pipe through a small private that mirrors `timeline_order/1` for doc parity.
- Optional `Repo.preload(results, Keyword.get(opts, :preload, []))` when preload list non-empty.

## Testing

- Extend `Threadline.QueryTest`: one transaction, **≥2** changes with **different** `captured_at` (and same `captured_at` + different `id` if feasible) to assert ordering.
- Assert `Threadline.audit_changes_for_transaction/2` equals `Threadline.Query.audit_changes_for_transaction/2` for same inputs.
- Malformed id: `assert_raise ArgumentError, fn -> ... end`.

## Out of scope (confirmed)

- `:transaction_id` on `validate_timeline_filters!/1`
- LiveView / Phase 33 doc routing
- Ascending order variant unless follow-up

## Validation Architecture

**Dimension 8 (integrator contract):** Automated tests must lock ordering rule, empty-set behavior, UUID validation, and delegator parity. **Sampling:** `mix test test/threadline/query_test.exs` after each task touching query or tests; full `mix test` before phase verify.

**Dimension 3 (correctness):** Multi-row fixture proves **all** changes for txn returned (no accidental `limit 1`).

**Security:** Read-only SELECT; no new secrets; malformed input fails closed with `ArgumentError` (no raw Postgrex UUID errors to callers).

## RESEARCH COMPLETE

Ready for planning and execution.
