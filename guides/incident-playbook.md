# Incident Playbook

This playbook outlines how to use Threadline's audit logs to investigate common production incidents.

## Reading `change_diff`

The `change_diff` field stores the delta of the row mutation. The shape depends on the action:

- **INSERT**: Contains the complete set of inserted attributes.
- **UPDATE**: Contains only the attributes that changed.
- **DELETE**: Contains the complete set of attributes before deletion (or primary key only, based on retention settings).

### The `changed_from` opt-in matrix

Threadline supports tracking previous values via the `changed_from` field, but this is opt-in per table or column to balance storage costs. When enabled, updates include both the new value in `change_diff` and the old value in `changed_from`.

## who changed this row at time T?

### Scenario
A specific row was mutated unexpectedly at a known time, and we need to identify the actor.

### Diagnosis (API)
```elixir
Threadline.Query.timeline(
  [
    table: "users",
    row_pk: "user_123",
    from: ~U[2024-01-01 12:00:00Z],
    to: ~U[2024-01-01 13:00:00Z]
  ],
  repo: MyApp.Repo
)
```

### Diagnosis (raw SQL)
```sql
SELECT id, actor_id, action, change_diff, inserted_at
FROM audit_changes
WHERE table_name = 'users'
  AND row_pk = 'user_123'
  AND inserted_at BETWEEN '2024-01-01 12:00:00Z' AND '2024-01-01 13:00:00Z'
ORDER BY inserted_at DESC;
```

### Expected output
You should see the specific `audit_changes` record detailing the `actor_id` who made the change.

### Recovery
If the change was malicious or accidental, use the `change_diff` (and `changed_from` if available) to construct an update reverting the row to its previous state.

## what did service-account X do today?

### Scenario
We need to audit all actions performed by a specific service account over the course of a day.

### Diagnosis (API)
```elixir
Threadline.Query.timeline(
  [
    actor_ref: Threadline.Semantics.ActorRef.service_account!("svc_worker_456"),
    from: ~U[2024-01-01 00:00:00Z],
    to: ~U[2024-01-01 23:59:59Z]
  ],
  repo: MyApp.Repo
)
```

### Diagnosis (raw SQL)
<!-- LIVE-JOIN-WARNING -->
```sql
SELECT a.id, a.table_name, a.row_pk, a.action, a.inserted_at
FROM audit_changes a
JOIN users u ON a.actor_id = u.id::text
WHERE a.actor_id = 'svc_worker_456'
  AND a.inserted_at >= '2024-01-01 00:00:00Z'
  AND a.inserted_at < '2024-01-02 00:00:00Z'
ORDER BY a.inserted_at ASC;
```

### Expected output
A chronological sequence of mutations (table, row, action) performed by the service account.

### Recovery
Review the output for unauthorized actions. Roll back specific changes if necessary by applying inverse mutations.

## did this Oban job actually mutate the DB?

### Scenario
An Oban job ran, but we need to verify if it actually performed any database mutations, especially if it was a dry-run or failed halfway.

### Diagnosis (API)
```elixir
Threadline.Query.timeline(
  context: %{"oban_job_id" => 789}
)
```

### Diagnosis (raw SQL)
```sql
SELECT id, table_name, action, change_diff
FROM audit_changes
WHERE context->>'oban_job_id' = '789'
ORDER BY inserted_at ASC;
```

### Expected output
A list of database mutations performed within the context of that specific Oban job.

### Recovery
If the job failed partially, use the log to identify which records were updated and manually complete or revert the remaining work.

## what did this row look like at time T?

### Scenario
We need to reconstruct the exact state of a row at a specific point in time in the past.

### Diagnosis (API)
```elixir
# Note: Threadline API provides timelines; reconstruction requires application logic.
Threadline.Query.timeline(
  table: "orders",
  row_pk: "order_999",
  to: ~U[2024-01-01 10:00:00Z]
)
```

### Diagnosis (raw SQL)
```sql
SELECT change_diff, changed_from, action, inserted_at
FROM audit_changes
WHERE table_name = 'orders'
  AND row_pk = 'order_999'
  AND inserted_at <= '2024-01-01 10:00:00Z'
ORDER BY inserted_at ASC;
```

### Expected output
The complete history of the row up to time T. By applying the `change_diff`s chronologically (starting from the INSERT), you can reconstruct the row's state.

### Recovery
Use the reconstructed state to fix data corruption or answer compliance inquiries.

## single-transaction drilldown

### Scenario
Several mutations occurred together in a single transaction, and we want to view all changes that happened atomically.

### Diagnosis (API)
```elixir
Threadline.Query.audit_changes_for_transaction("tx_abc123", repo: MyApp.Repo)
```

### Diagnosis (raw SQL)
```sql
SELECT table_name, row_pk, action, change_diff
FROM audit_changes
WHERE transaction_id = 'tx_abc123'
ORDER BY seq ASC;
```

### Expected output
All changes that were committed as part of the specified transaction, allowing you to see the full scope of a complex operation.

### Recovery
If a complex operation had side effects, viewing the entire transaction context helps understand exactly which related tables were touched so you can comprehensively revert or fix them.
