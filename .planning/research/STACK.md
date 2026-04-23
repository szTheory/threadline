# Stack Research

**Domain:** Elixir library — PostgreSQL trigger-backed audit capture  
**Researched:** 2026-04-23  
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Elixir / OTP | ≥ 1.15 / ≥ 26 | Library runtime | Already project baseline; mature JSON and test tooling |
| PostgreSQL | ≥ 14 | Trigger execution + JSONB | `OLD` / `NEW` row access in PL/pgSQL; JSONB for `changed_from` without new extensions |
| Ecto | 3.x | Schema + migrations | Existing `AuditChange` model; additive column + migration pattern already proven in v1.0 |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Mix tasks (`lib/mix/tasks/`) | — | CLI installer / generators | Extend `threadline.gen.triggers` and add `threadline.verify_coverage` alongside existing tasks |
| PostgreSQL `information_schema` + `pg_trigger` | — | Coverage introspection | Read-only catalog queries from verify task; no extra deps |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `mix test` + integration DB | Regression for trigger SQL | Follow existing PostgreSQL-backed integration tests from capture phases |
| `mix compile --warnings-as-errors` | Quality gate | Already in PKG-05 pattern |

## Installation

No new Hex dependencies required for BVAL/TOOL scope; changes are migrations + PL/pgSQL + Mix.

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| JSONB `changed_from` column | Separate “diff” table | Only if row size or indexing demands normalization — unnecessary for v1.2 |
| Capture-time before-values | Async CDC / logical decoding | Explicitly out of scope per PROJECT.md (WAL/CDC surface area) |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `SET LOCAL` inside trigger | Breaks PgBouncer transaction pooling assumptions | Keep reading GUC only; before-values from `OLD` only |
| Session / process dict for capture flags | Async and pool hazards | Per-trigger DDL options encoded at `gen.triggers` time (or table-level convention documented) |

## Stack Patterns by Variant

**If adopters need minimal storage:** default `store_changed_from: false`; document storage tradeoff for JSONB duplication on wide rows.

**If adopters run PgBouncer transaction mode:** no change — before-values live entirely inside the same trigger transaction as `OLD`/`NEW`.

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| `threadline` 0.1.x | PostgreSQL 14+ | `gen_random_uuid()` and JSONB already required |
| New migration | Existing installs | Add nullable `changed_from`; backfill `NULL` for historical rows |

## Sources

- `lib/threadline/capture/trigger_sql.ex` — current capture path (verified)
- PostgreSQL PL/pgSQL trigger docs — `OLD` / `NEW` semantics for UPDATE
- `.planning/PROJECT.md` — constraints (Path B, no WAL primary)

---
*Stack research for: Threadline v1.2 (before-values + tooling)*  
*Researched: 2026-04-23*
