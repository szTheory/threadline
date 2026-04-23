# Phase 13 — Pattern map

Analogs for new/modified files (from `13-CONTEXT.md` + `13-RESEARCH.md`).

## New: retention policy / config validation

| Role | New file (planned) | Analog | Excerpt / convention |
|------|-------------------|--------|----------------------|
| Validate host config at runtime or compile | `lib/threadline/retention/policy.ex` (name TBD) | `lib/threadline/capture/redaction_policy.ex` | `validate!/1`, raises `ArgumentError` with clear message; no I/O |

## New: purge API

| Role | New file | Analog | Excerpt / convention |
|------|----------|--------|----------------------|
| Public DB API with `repo:` | `lib/threadline/retention.ex` | `lib/threadline/query.ex` | Pass `repo:` in opts keyword; `import Ecto.Query` |

## New: Mix task

| Role | New file | Analog | Excerpt |
|------|----------|--------|---------|
| CLI entry | `lib/mix/tasks/threadline.retention.purge.ex` | `lib/mix/tasks/threadline.verify_coverage.ex` | `Mix.Task.run("app.config", [])`, `resolve_repo!/0`, `ensure_repo_started!/1` |

## Modified: docs

| File | Analog section | Notes |
|------|------------------|-------|
| `guides/domain-reference.md` | Redaction / capture sections from Phase 12 | Add “Retention” subsection: clock field, cutoff semantics vs `timeline/2`, orphan txn cleanup |
| `README.md` | Hex / install overview | Short cross-link to retention Mix task |

## DB patterns

| Operation | Pattern |
|-----------|---------|
| Batched delete | Subquery `SELECT id … LIMIT $n` wrapped in `delete_all` or `Ecto.Adapters.SQL.query` if `LIMIT` on DELETE unsupported |
| Orphan txn cleanup | `DELETE FROM audit_transactions t WHERE NOT EXISTS (SELECT 1 FROM audit_changes c WHERE c.transaction_id = t.id)` in batches |

---

## PATTERN MAPPING COMPLETE
