# Architecture Patterns — "As-of" Reconstruction

**Domain:** Audit & Temporal Data
**Researched:** 2026-04-24

## Recommended Architecture

Threadline uses a **Snapshot-at-Capture** architecture. Unlike patch-based systems (like `ExAudit`) or system-period temporal tables (which clones rows into a separate table), Threadline stores the full state of the row in a `JSONB` column (`data_after`) on every change event.

### Data Flow

```mermaid
graph TD
    A[Request: as_of/3] --> B[Query audit_changes]
    B --> C{Found?}
    C -- Yes --> D[Extract data_after JSONB]
    C -- No --> E[Return nil]
    D --> F[Ecto.embedded_load]
    F --> G[Reified %Schema{}]
```

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| **Threadline.Query** | Point-in-time lookup logic (PostgreSQL) | `AuditChange` / `Repo` |
| **Threadline.Reify** | Transforming raw maps to Ecto structs | Ecto Metadata |
| **AuditChange** | Storage for `data_after` snapshots | PostgreSQL |

## Patterns to Follow

### Pattern 1: Point-in-Time Lookup
**What:** Find the most recent audit entry for a record at or before a given time.
**When:** Whenever "As-of" state is requested.
**SQL Example:**
```sql
SELECT data_after 
FROM audit_changes 
WHERE table_name = 'posts' 
  AND table_pk @> '{"id": 1}' 
  AND captured_at <= '2023-01-01 10:00:00Z' 
ORDER BY captured_at DESC 
LIMIT 1;
```

### Pattern 2: Struct Reification via `embedded_load`
**What:** Using Ecto's internal loading logic to cast a JSON map back to a struct.
**Example:**
```typescript
// Conceptual Elixir implementation
def reify(schema, data) when is_map(data) do
  # Uses Ecto's native type casting and embed handling
  Ecto.embedded_load(schema, data, :json)
end
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Reconstructing via Diff Replay
**What:** Attempting to start from the current live table and "undo" `change_diff` entries to get back to time T.
**Why bad:** Extremely slow; fails if `changed_from` wasn't stored; prone to error if schema drifted.
**Instead:** Use the `data_after` snapshot from the audit log directly.

## Scalability Considerations

| Concern | At 100 users | At 10K users | At 1M users |
|---------|--------------|--------------|-------------|
| **Query Latency** | Negligible | Requires Index on `(table_name, table_pk, captured_at)` | Partitioning `audit_changes` by time may be necessary. |
| **Storage Growth** | Managed | Snapshot storage grows linearly with updates. | Implement `Threadline.Retention` policies to prune old history. |

## Sources
- `Threadline.Capture.TriggerSQL` implementation.
- `Ecto` internal loading patterns.
- [PostgreSQL Indexing for JSONB](https://www.postgresql.org/docs/current/datatype-json.html#JSONB-INDEXING)
