# Threadline Incident Playbook

When incidents occur, engineering and support teams need fast, reliable ways to query audit data to determine what happened. This playbook provides canonical recipes for investigating common incidents using Threadline's API and raw SQL queries.

## Reading `change_diff`

Before diving into specific scenarios, it's important to understand how Threadline records changes via the `change_diff` column. This JSON field describes what changed during a mutation.

For `INSERT`: `change_diff` contains the full row payload as it was inserted.
For `UPDATE`: `change_diff` contains only the columns that actually changed, holding their *new* values. To see the *old* values alongside the new values, the `changed_from` opt-in matrix must be configured for the table.
For `DELETE`: `change_diff` is empty (the primary key is enough context, and full rows aren't retained by default for deletions).

## Scenario: who changed this row at time T?

When a specific record looks incorrect, the first question is usually who touched it around the time the issue occurred.

### Diagnosis (API)

```elixir
Threadline.Query.changes_for_record("users", user_id,
  from: ~U[2024-03-15 10:00:00Z],
  to: ~U[2024-03-15 11:00:00Z]
)
```

### Diagnosis (raw SQL)

```sql
SELECT
  id,
  table_name,
  record_pk,
  action,
  change_diff,
  actor_id,
  inserted_at
FROM threadline_changes
WHERE table_name = 'users'
  AND record_pk = '123'
  AND inserted_at >= '2024-03-15 10:00:00Z'
  AND inserted_at <= '2024-03-15 11:00:00Z'
ORDER BY inserted_at DESC;
```

### Expected output

You will see a list of changes matching the time window, including the `actor_id` who performed the mutation and the `change_diff` showing what was modified.

### Recovery

Revert the specific fields using the prior values (if `changed_from` is configured) or by communicating with the identified actor.

## Scenario: what did service-account X do today?

If a service account went rogue or processed a bad batch, you need to identify all mutations it performed.

### Diagnosis (API)

```elixir
Threadline.Query.changes_by_actor(service_account_id,
  from: Date.utc_today() |> DateTime.new!(~T[00:00:00])
)
```

### Diagnosis (raw SQL)

<!-- LIVE-JOIN-WARNING -->
Warning: Joining against live application tables in incident queries can cause performance degradation. Use caution.

```sql
SELECT
  tc.id,
  tc.table_name,
  tc.record_pk,
  tc.action,
  tc.change_diff,
  tc.inserted_at
FROM threadline_changes tc
WHERE tc.actor_id = 'service-acct-uuid'
  AND tc.inserted_at >= CURRENT_DATE
ORDER BY tc.inserted_at DESC;
```

### Expected output

A timeline of all changes executed by the specified service account across all audited tables for the day.

### Recovery

Analyze the scope of the unintended changes. If necessary, construct a script to reverse the specific updates or deletions based on the `change_diff` payloads.

## Scenario: did this Oban job actually mutate the DB?

Sometimes a job completes successfully but it's unclear if it actually changed any data, or if it bypassed updates due to logic checks.

### Diagnosis (API)

```elixir
Threadline.Query.changes_by_context("oban_job_id", job_id)
```

### Diagnosis (raw SQL)

```sql
SELECT
  id,
  table_name,
  record_pk,
  action,
  change_diff
FROM threadline_changes
WHERE context_json->>'oban_job_id' = 'job-12345';
```

### Expected output

If the job performed mutations, they will be listed. If the result set is empty, the job completed without altering any audited tables.

### Recovery

If mutations were expected but absent, investigate the job's logic conditions. If unintended mutations occurred, use the result set to target cleanup.

## Scenario: what did this row look like at time T?

To reconstruct the state of a record at a specific point in time, you need to replay the changes backwards from the current state, or forwards from creation.

### Diagnosis (API)

```elixir
Threadline.Continuity.reconstruct_at("users", user_id, ~U[2024-03-15 10:30:00Z])
```

### Diagnosis (raw SQL)

```sql
SELECT
  action,
  change_diff,
  inserted_at
FROM threadline_changes
WHERE table_name = 'users'
  AND record_pk = '123'
  AND inserted_at <= '2024-03-15 10:30:00Z'
ORDER BY inserted_at ASC;
```

### Expected output

A chronological list of changes up to time T. The API method will return a map representing the reconstructed row state.

### Recovery

Use the reconstructed state to manually repair the current row or to understand the context of a bug report tied to that timestamp.

## Scenario: single-transaction drilldown

When a complex operation (like an API request) touches multiple tables, you may need to see all changes that occurred within that specific database transaction.

### Diagnosis (API)

```elixir
Threadline.Query.changes_in_transaction(transaction_id)
```

### Diagnosis (raw SQL)

```sql
SELECT
  id,
  table_name,
  record_pk,
  action,
  change_diff,
  inserted_at
FROM threadline_changes
WHERE transaction_id = 'tx-789'
ORDER BY inserted_at ASC;
```

### Expected output

All mutations that were committed together in the specified transaction, providing a holistic view of the operation's side effects.

### Recovery

If the transaction represented a logical error, the entire set of changes must be addressed (e.g., reverting an order and its associated line items).
