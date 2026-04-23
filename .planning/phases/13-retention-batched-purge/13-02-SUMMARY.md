# Plan 13-02 Summary: Batched purge API, Mix task & integration tests (RETN-02)

## Outcome

Implemented `Threadline.Retention.purge/1` with required `repo:`, configurable `batch_size` / `max_batches`, `dry_run`, optional stricter `cutoff:`, batched deletes on `captured_at`, and orphan `audit_transactions` cleanup (configurable off). Added `mix threadline.retention.purge` with `--dry-run`, `--execute` prod gate, and README operational guidance (cron, batching, logging).

## Commits

- `feat(13-02): batched retention purge API, Mix task, and tests (RETN-02)`

## Self-Check

- `DB_PORT=5433 MIX_ENV=test mix test test/threadline/retention/` — pass
- `DB_PORT=5433 MIX_ENV=test mix ci.all` — pass
- `MIX_ENV=test mix help threadline.retention.purge` — shows task

## Deviations

None.
