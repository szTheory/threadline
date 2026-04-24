# Technology Stack — "As-of / History" Reconstruction

**Project:** Threadline
**Researched:** 2026-04-24
**Confidence:** HIGH

## Recommended Stack

No new external library dependencies are required for "As-of" row reconstruction in Threadline. The feature can be built using existing validated primitives.

### Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Elixir** | ≥ 1.15 | Language | Standard for project. |
| **Ecto** | ≥ 3.10 | Data Mapping | Use `Ecto.embedded_load/3` to reify JSONB maps into typed Elixir structs. |
| **PostgreSQL**| ≥ 14 | Database | Leverages `JSONB` for snapshot storage and standard B-Tree indexes for point-in-time lookup. |

### Supporting Libraries (Already in Project)
| Library | Purpose | When to Use |
|---------|---------|-------------|
| **Jason** | JSON parsing | Internal to Ecto/Postgrex for handling `data_after` blobs. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| **State Reconstruction** | **Snapshot-based (native)** | **Patch-based (e.g. `ExAudit`)** | Threadline already stores full `data_after` snapshots in `audit_changes`. Re-calculating state via patches adds complexity and performance overhead without gain. |
| **Temporal Logic** | **Standard SQL + Ecto** | **PostgreSQL `temporal_tables` extension** | Requires C-extensions on the DB host; conflicts with Threadline's goal of being "application-level" and "batteries-included." |
| **Data Mapping** | **`Ecto.embedded_load/3`** | **`jsonpatch` / `ecto_diff`** | Standard Ecto primitives are safer for schema-aware casting and handles embeds natively. |

## Implementation Rationale

### Why Snapshot-based?
Threadline's `audit_changes.data_after` column stores a full row image after every mutation (INSERT/UPDATE). This makes "As-of" reconstruction a simple two-step process:
1.  **Query:** `SELECT data_after FROM audit_changes WHERE table_name = $1 AND table_pk @> $2 AND captured_at <= $3 ORDER BY captured_at DESC LIMIT 1`.
2.  **Reify:** Map the resulting JSONB object back into the target Ecto struct using the schema metadata.

### Interaction with JSONB Fields
If a table has a `JSONB` column (e.g., `metadata`), it is stored as a nested object within `audit_changes.data_after`. Ecto's loading mechanism (via `embeds_one`/`embeds_many`) naturally handles this recursive reconstruction as long as the application schema defines the fields.

### Handling Redaction
Columns that are `exclude`ed or `mask`ed at capture time will be missing or replaced in the reconstructed struct. This is consistent with Threadline's "honest" capture philosophy.

## Installation

No new packages needed. Ensure `ecto` and `jason` are current.

```bash
# Verify existing deps
mix deps.get
```

## Sources
- `Threadline.Capture.TriggerSQL`: Confirmed `data_after` stores full snapshots.
- `Ecto.Schema` Documentation: Confirmed `embedded_load/3` capabilities.
- [ExAudit](https://hexdocs.pm/ex_audit): Comparison for patch-based vs snapshot-based.
- [Carbonite](https://hexdocs.pm/carbonite): Comparison for trigger-backed ecosystem patterns.
