# Architecture Research

**Domain:** Trigger-backed audit capture (Threadline Path B)  
**Researched:** 2026-04-23  
**Confidence:** HIGH

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Application (Elixir)                     │
├─────────────────────────────────────────────────────────────┤
│  Threadline.Plug / Job ──► set_config(threadline.actor_ref) │
│  Mix tasks: install, gen.triggers, verify_coverage (new)     │
├─────────────────────────────────────────────────────────────┤
│              Ecto.Repo ──► audited business tables           │
├─────────────────────────────────────────────────────────────┤
│           PostgreSQL: threadline_capture_changes()           │
│   INSERT / UPDATE / DELETE  ──►  audit_transactions          │
│                              └──►  audit_changes (+ changed_from?)
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|-------------------------|
| `TriggerSQL` | Emit PL/pgSQL for function + per-table triggers | String templates; branch on TG_OP; optional `OLD` JSON for UPDATE |
| `mix threadline.install` | Schema migrations | Additive migration for `changed_from` (nullable jsonb) |
| `mix threadline.gen.triggers` | Per-table DDL | Pass through option that affects generated `CREATE TRIGGER` body or function overload strategy |
| `Threadline.Query` / `Threadline.history` | Read path | Select all existing columns; `changed_from` nil when disabled |
| `mix threadline.verify_coverage` | Operational gate | Query catalog + optional app config list of expected tables |

## Recommended Project Structure

```
lib/threadline/capture/       # TriggerSQL, schemas, migration helpers
lib/threadline/query.ex       # history / timeline (surface changed_from)
lib/mix/tasks/threadline.*.ex # CLI surface
test/                         # integration tests against Postgres
```

### Structure Rationale

- **Keep trigger logic centralized** in `TriggerSQL` so PgBouncer and D-06 constraints stay auditable in one module.
- **Mix tasks colocated** with existing `threadline.gen.triggers` patterns for discoverability.

## Architectural Patterns

### Pattern 1: Additive schema + nullable column

**What:** New `changed_from` jsonb nullable; triggers write NULL when option off.  
**When to use:** Any feature that must not break existing databases on upgrade.  
**Trade-offs:** Wider rows when populated; index strategy usually unchanged (avoid indexing full JSONB unless required).

### Pattern 2: Install-time capture options in generated migrations

**What:** `gen.triggers` bakes options into the migration snippet so production behavior is explicit in version control.  
**When to use:** When runtime toggles would hide which tables capture before-values.  
**Trade-offs:** Changing option requires re-run generator or manual migration edit — acceptable for v1.2.

## Data Flow

### UPDATE with before-values enabled

```
Row UPDATE on audited table
    ↓
threadline_capture_changes()
    ↓
Read OLD → build changed_from subset (or full row per product choice)
    ↓
INSERT audit_changes (..., data_after, changed_fields, changed_from)
```

### Verify coverage task

```
mix threadline.verify_coverage
    ↓
Expected tables (argv, config, or Health-style discovery TBD in plan)
    ↓
PostgreSQL catalog / Health.trigger_coverage
    ↓
stdout table + exit 0 or 1
```

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|---------------------------|
| Typical app DB | JSONB `changed_from` acceptable for moderate row width; document size guidance |
| Very wide rows | Future: column allowlist for `changed_from` |

## Anti-Patterns

### Anti-Pattern: Implicit before-values

**What people do:** Always store full `OLD` without opt-in.  
**Why it's wrong:** PII duplication and storage blowup; surprises adopters.  
**Do this instead:** Opt-in flag per generated trigger / table.

### Anti-Pattern: Application-only backfill

**What people do:** Insert `audit_changes` from Elixir without going through trigger invariants.  
**Why it's wrong:** Violates “hard to bypass” story unless carefully designed.  
**Do this instead:** Documented helper that uses the same schema invariants and clearly labels synthetic rows if any.

## Integration Points

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Trigger ↔ GUC actor_ref | `current_setting` read-only | Unchanged for BVAL |
| Query API ↔ schemas | Ecto structs | `changed_from` field on `AuditChange` |

## Sources

- `lib/threadline/capture/trigger_sql.ex`
- `lib/threadline/query.ex`
- `lib/threadline/capture/audit_change.ex`

---
*Architecture research for: Threadline v1.2*  
*Researched: 2026-04-23*
