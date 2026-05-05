# Threadline Incident Playbook

When incidents occur, engineering and support teams need fast, reliable ways to query audit data to determine what happened. This playbook provides canonical recipes for investigating common incidents using Threadline's shipped API surface and raw SQL against the audit tables.

The Phoenix reference app now includes a baseline auth gate for
`GET /api/audit_transactions/:id/changes`: incident drill-down requires an
authenticated actor. Treat that as the minimum host shape, then layer your own
tenancy and policy rules on top.

## Reading `change_diff`

Before diving into specific scenarios, it helps to understand what `Threadline.change_diff/2` is projecting from each `audit_changes` row.

For `INSERT`, the diff represents the inserted row as captured by the trigger.
For `UPDATE`, the diff includes the changed fields with their new values; when `changed_from` is enabled for the table, you also have the prior values alongside the update.
For `DELETE`, the diff is intentionally sparse because the row is gone; use `table_pk`, the transaction actor, and earlier history rows to reconstruct context.

## Scenario: who changed this row at time T?

When a specific record looks incorrect, the first question is usually who touched it around the time the issue occurred.

### Diagnosis (API)

```elixir
window_start = ~U[2024-03-15 10:00:00Z]
window_end = ~U[2024-03-15 11:00:00Z]

Threadline.history(MyApp.User, user_id, repo: MyApp.Repo)
|> Enum.filter(fn change ->
  DateTime.compare(change.captured_at, window_start) != :lt and
    DateTime.compare(change.captured_at, window_end) != :gt
end)
```

### Diagnosis (raw SQL)

```sql
SELECT
  ac.id,
  ac.table_name,
  ac.table_pk,
  ac.op,
  ac.changed_fields,
  ac.changed_from,
  ac.data_after,
  ac.captured_at,
  at.actor_ref
FROM audit_changes ac
JOIN audit_transactions at
  ON at.id = ac.transaction_id
WHERE ac.table_name = 'users'
  AND ac.table_pk @> '{"id":"123"}'::jsonb
  AND ac.captured_at >= '2024-03-15 10:00:00Z'::timestamptz
  AND ac.captured_at <= '2024-03-15 11:00:00Z'::timestamptz
ORDER BY ac.captured_at DESC, ac.id DESC;
```

### Expected output

You will see the matching row changes in the incident window, along with the actor captured on the containing transaction.

### Recovery

Use `changed_from` when it is available to reverse the exact field-level mutation. If it is absent, use the actor and timestamp trail to coordinate a manual repair.

## Scenario: what did service-account X do today?

If a service account went rogue or processed a bad batch, you need to identify all mutations it performed.

### Diagnosis (API)

```elixir
{:ok, actor_ref} =
  Threadline.Semantics.ActorRef.new(:service_account, service_account_id)

day_start = Date.utc_today() |> DateTime.new!(~T[00:00:00], "Etc/UTC")

Threadline.actor_history(actor_ref, repo: MyApp.Repo)
|> Enum.filter(fn tx ->
  DateTime.compare(tx.occurred_at, day_start) != :lt
end)
|> Enum.flat_map(fn tx ->
  Threadline.audit_changes_for_transaction(tx.id, repo: MyApp.Repo)
end)
```

### Diagnosis (raw SQL)

```sql
SELECT
  at.id AS transaction_id,
  at.occurred_at,
  ac.table_name,
  ac.table_pk,
  ac.op,
  ac.changed_fields,
  ac.changed_from,
  ac.data_after
FROM audit_transactions at
JOIN audit_changes ac
  ON ac.transaction_id = at.id
WHERE at.actor_ref @> '{"type":"service_account","id":"service-acct-uuid"}'::jsonb
  AND at.occurred_at >= date_trunc('day', now() AT TIME ZONE 'utc')
ORDER BY at.occurred_at DESC, ac.captured_at DESC, ac.id DESC;
```

### Expected output

A day-scoped list of every audited change executed by that service account, grouped naturally by transaction ID.

### Recovery

Use the returned transaction IDs to batch cleanup work per request or job boundary instead of reverting rows one by one.

## Scenario: did this Oban job actually mutate the DB?

Sometimes a job completes successfully but it is unclear if it actually changed any data, or if it short-circuited before the write path.

### Diagnosis (API)

```elixir
changes =
  Threadline.audit_changes_for_transaction(audit_transaction_id, repo: MyApp.Repo)

Enum.map(changes, fn change ->
  %{
    table: change.table_name,
    op: change.op,
    diff: Threadline.change_diff(change, json_ready: true)
  }
end)
```

### Diagnosis (raw SQL)

```sql
SELECT
  ac.id,
  ac.table_name,
  ac.table_pk,
  ac.op,
  ac.changed_fields,
  ac.changed_from,
  ac.data_after,
  aa.job_id,
  aa.correlation_id
FROM audit_changes ac
JOIN audit_transactions at
  ON at.id = ac.transaction_id
LEFT JOIN audit_actions aa
  ON aa.id = at.action_id
WHERE ac.transaction_id = '00000000-0000-0000-0000-000000000123'::uuid
ORDER BY ac.captured_at DESC, ac.id DESC;
```

### Expected output

If the job mutated audited rows, you will see each change together with any linked `audit_actions` metadata that was recorded in the same transaction.

### Recovery

If the result set is empty, the job did not mutate an audited table. If it is non-empty, use the per-change diffs to decide whether to retry, roll forward, or manually correct the job's effects.

## Scenario: what did this row look like at time T?

To reconstruct the state of a record at a specific point in time, use the public `as_of/4` query first and fall back to raw history only when you need to debug the reconstruction manually.

### Diagnosis (API)

```elixir
Threadline.as_of(MyApp.User, user_id, ~U[2024-03-15 10:30:00Z], repo: MyApp.Repo)
```

### Diagnosis (raw SQL)

```sql
SELECT
  ac.op,
  ac.data_after,
  ac.changed_fields,
  ac.changed_from,
  ac.captured_at
FROM audit_changes ac
WHERE ac.table_name = 'users'
  AND ac.table_pk @> '{"id":"123"}'::jsonb
  AND ac.captured_at <= '2024-03-15 10:30:00Z'::timestamptz
ORDER BY ac.captured_at ASC, ac.id ASC;
```

### Expected output

`Threadline.as_of/4` returns the reconstructed row map at that timestamp. The SQL recipe gives you the chronological raw material behind that answer.

### Recovery

Use the reconstructed row to compare the reported bug window against the row's actual historical state before deciding on a repair.

## Scenario: single-transaction drilldown

When a complex operation touches multiple tables, you may need to see every row mutation that committed inside one database transaction.

### Diagnosis (API)

```elixir
Threadline.audit_changes_for_transaction(transaction_id, repo: MyApp.Repo)
|> Enum.map(fn change ->
  %{table: change.table_name, op: change.op, diff: Threadline.change_diff(change, json_ready: true)}
end)
```

### Diagnosis (raw SQL)

```sql
SELECT
  ac.id,
  ac.table_name,
  ac.table_pk,
  ac.op,
  ac.changed_fields,
  ac.changed_from,
  ac.data_after,
  ac.captured_at
FROM audit_changes ac
WHERE ac.transaction_id = '00000000-0000-0000-0000-000000000123'::uuid
ORDER BY ac.captured_at DESC, ac.id DESC;
```

### Expected output

All mutations that were committed together in the specified transaction, with enough shape to reconstruct each row diff and the operation order.

### Recovery

If the transaction represented a logical error, address the full set of changes together rather than reverting only the most visible row.

<!-- LIVE-JOIN-WARNING -->
Warning: if you extend any of these recipes by joining live application tables such as `users` or `posts`, keep the join narrow and time-bounded so your debugging query does not become its own production load spike.
