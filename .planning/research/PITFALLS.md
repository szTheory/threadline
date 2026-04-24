# Domain Pitfalls: "As-of" / Point-in-Time Reconstruction

**Domain:** Audit Logging & Historical Data Reconstruction
**Researched:** 2024-05-24
**Overall Confidence:** HIGH

## Critical Pitfalls

Mistakes that cause data inaccuracy, performance collapse, or system crashes during reconstruction.

### 1. The "Genesis Gap" (Missing Start-of-Time)
**What goes wrong:** Attempting to reconstruct a record that was created *before* auditing was enabled (Brownfield data).
**Why it happens:** Most systems have existing data when Threadline is installed. The first audit entry for these rows will be an `UPDATE`, not an `INSERT`.
**Consequences:** 
- A request for "As-of" time *before* the first audit log returns nothing.
- "Rewinding" the first `UPDATE` (using `changed_from`) only gives the state immediately prior to that update, but still leaves a gap back to the record's true creation.
**Prevention:** 
- Use `Threadline.Continuity` (Phase 11) to capture a baseline snapshot for all existing records during migration.
- Explicitly document the "Audit Horizon" for each table.

### 2. Schema Evolution / The "Stale Struct" Trap
**What goes wrong:** Reconstructing a row from 12 months ago and trying to cast it into a modern Ecto schema that has renamed, added, or removed columns.
**Why it happens:** Ecto schemas represent the *current* application state. Historical JSON in `audit_changes` represents the *past* database state.
**Consequences:** 
- `Ecto.CastError` or `ArgumentError` when a field in the log doesn't exist in the current struct.
- Data loss: fields present in the history but missing in the modern struct are dropped silently.
- Logic errors: The reconstructed row passes validation but violates new business invariants.
**Prevention:**
- **Reconstruct to Maps by default:** Provide a `Threadline.as_of_map/3` and make it the primary internal tool.
- **Loose Struct Loading:** Use `Ecto.embedded_load` or similar "permissive" loaders that ignore missing fields.
- **Tombstone Fields:** Maintain deprecated fields in the Ecto schema (as virtual or ignored) to allow historical data to land somewhere.

### 3. Redaction Policy Drift (The "Impossible Peek")
**What goes wrong:** A field was redacted *at capture time* in the past (using `:exclude` or `:mask`). A year later, the policy changes to allow that field.
**Why it happens:** Threadline's redaction happens in the SQL triggers. The data is physically not in the audit log.
**Consequences:** The user requests a reconstruction and sees `"[REDACTED]"` even if they have permission *now*. This can be confusing for support teams.
**Prevention:**
- Document that historical redaction is permanent and "lossy".
- **Reverse Drift:** If a field was *not* redacted in the past but is sensitive *now*, the reconstruction layer must apply the *current* `RedactionPolicy` to the result before returning it to the user.

### 4. The "Ghost State" (Deleted Records)
**What goes wrong:** Attempting to reconstruct a record that has been deleted from the live table.
**Why it happens:** Naive "Backward Reconstruction" (replaying deltas from the live table) has no starting point if the row is gone.
**Consequences:** "Record not found" errors even though history exists.
**Prevention:**
- **Snapshot-First Logic:** Threadline's architecture stores full-row snapshots (`data_after`). The reconstruction logic should find the most recent `AuditChange` at/before time T and use its `data_after` directly, ignoring the live table's existence.

## Moderate Pitfalls

### 1. Transaction Commit Order vs. Sequence IDs
**What goes wrong:** Transaction 100 starts, then Transaction 101 starts and commits, then Transaction 100 commits.
**Why it happens:** PostgreSQL `txid_current()` is assigned at start, but `captured_at` (clock time) is assigned at trigger execution.
**Consequences:** Sorting by `captured_at` vs `transaction_id` vs `id` might yield slightly different "latest" versions in high-concurrency windows.
**Prevention:** Always use the same stable order as `Threadline.Query.timeline/2`: `captured_at DESC, id DESC`.

### 2. Association "Clock Skew"
**What goes wrong:** Reconstructing a `Post` as it looked at 12:00:00, but its `Author` is loaded as they look *now*.
**Why it happens:** Single-table "As-of" reconstruction does not automatically extend to joined associations.
**Consequences:** Inconsistent views (e.g., Post says "Published", but Author is "Suspended").
**Prevention:** 
- Explicitly mark associations as "Current State" in the UI/API.
- Support `correlation_id` filtering to find related changes in the same logical operation.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| **Core Lookup** | Schema Mismatch | Favor `Map` over `Struct` for the internal engine; provide an opt-in `as_struct/2` helper. |
| **Bulk Lookup** | Performance N+1 | Use `LATERAL JOIN` or `PARTITION BY` in SQL to reconstruct many rows in a single query rather than replaying in Elixir. |
| **Rewind Logic** | Missing `changed_from` | Fall back gracefully if `changed_from` is NULL (meaning the user didn't opt-in to prior values for that table). |

## Sources

- [Logidze / Ruby Audited Post-mortems (Schema evolution pain)](https://github.com/palkan/logidze)
- [Threadline PROJECT.md (Trigger-capture mechanics)](/.planning/PROJECT.md)
- [Threadline Capture Schema (AuditChange data_after contract)](lib/threadline/capture/audit_change.ex)
