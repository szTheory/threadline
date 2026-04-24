# Phase 32 — Pattern map

## Analog: `history/3`

**File:** `lib/threadline/query.ex` (lines ~202–213)

- `repo = Keyword.fetch!(opts, :repo)`
- `AuditChange` base query + `where` + `order_by` + `repo.all/1`
- Returns plain list; no `{:ok, _}` tuples

## Analog: timeline ordering

**File:** `lib/threadline/query.ex` — `timeline_order/1` (private)

- `order_by([ac], desc: ac.captured_at)` then `order_by([ac], desc: ac.id)`
- **Reuse** the same ordering for `audit_changes_for_transaction/2` (call `timeline_order/1` on a bare `from ac in AuditChange` query after `where`, or duplicate the two `order_by` lines — prefer **single source**: extend with a public or private helper if needed to avoid drift)

## Analog: root delegator

**File:** `lib/threadline.ex`

- `def history(...)`, do: `Threadline.Query.history(...)`
- Add `def audit_changes_for_transaction(txn_id, opts), do: Threadline.Query.audit_changes_for_transaction(txn_id, opts)` (or `defdelegate` matching `change_diff` style)

## Test fixtures

**File:** `test/threadline/query_test.exs`

- `insert_transaction/1`, `insert_change/2`, `@repo Threadline.Test.Repo`
