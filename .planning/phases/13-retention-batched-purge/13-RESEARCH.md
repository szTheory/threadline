# Phase 13 — Technical research: Retention & batched purge

**Question answered:** What do we need to know to plan RETN-01 / RETN-02 well?

## Schema & integrity

- **`audit_changes.transaction_id`** references **`audit_transactions.id`** with `ON DELETE CASCADE` (parent delete removes children). Purging **only** `audit_changes` leaves **orphan** `audit_transactions` rows — bad for `actor_history/2` and mental model (`13-CONTEXT.md` D-08).
- **`captured_at`** is indexed (`audit_changes_captured_at_idx`). Retention predicates should use `captured_at < ^cutoff` (or `<=` per documented inclusive/exclusive contract) so PostgreSQL can use the index.
- **`txid`** on `audit_transactions` is unique; capture groups changes by DB txn. Row-level retention means one txn can span ages of `captured_at`; document per D-02.

## Ecto delete patterns

- **Batched deletes:** Prefer `DELETE FROM audit_changes WHERE id IN (SELECT id FROM audit_changes WHERE … LIMIT $batch)` in a loop (or `ctid`-based patterns on older PG) to cap lock duration. Ecto: `Repo.delete_all(from q in AuditChange, where: …, limit: ^n)` — verify Ecto 3.x supports `limit` on delete for the project's version; if not, use raw SQL or subquery `where: ac.id in subquery(...)`.
- **Transactions:** Each batch in its own `Repo.transaction` keeps locks short (D-10). Order: delete eligible changes → then delete empty parents (second query per batch or dedicated pass).

## Config idioms (Phase 12 alignment)

- Phase 12 uses `config :threadline, :trigger_capture, …`. Retention should use a dedicated key e.g. `config :threadline, :retention, max_age: …` or `retention_days:` resolved once per purge invocation (`13-CONTEXT.md` D-07).
- **Production safety (D-14):** Mirror industry pattern: `enabled: false` default in `:prod` sample, or require `purge_allowed: true` + explicit `--execute` on Mix; document in README.

## Mix task precedents

- `Mix.Tasks.Threadline.VerifyCoverage`: `Mix.Task.run("app.config", [])`, `Application.ensure_all_started` chain, `resolve_repo!` from `:ecto_repos`, `start_link` idempotent handling.
- New task `mix threadline.retention.purge` should delegate to **`Threadline.Retention.purge/1`** (or agreed module name) per D-11–D-12.

## Query alignment

- `Threadline.Query.timeline/2` uses inclusive `:from` / `:to` on `captured_at`. Purge cutoff semantics must be documented beside those filters to avoid off-by-one operator confusion.

## Testing strategy

- **Integration:** Insert N synthetic `audit_changes` (and parents) with controlled `captured_at` (via direct SQL `UPDATE` after insert if triggers always set `now()`), run purge with small `batch_size`, assert counts and that parents with zero children are removed when default enabled.
- **Idempotency:** Second `purge/1` with same cutoff deletes 0 rows.
- **Multi-batch:** `max_batches: 1` twice should drain a backlog in steps; or more rows than one batch with `max_batches` unset until empty.

## Prior art (condensed)

- TTL-style audit pruning typically keys off **row insert/capture time**, not business "occurred" time, unless product is txn-centric — matches D-01.
- Orphan shell txn rows after child-only delete are a known footgun; second-pass parent delete is standard.

## Validation Architecture

Execution feedback for Nyquist / plan checker:

| Dimension | How this phase proves it |
|-----------|---------------------------|
| Correctness | Integration tests: cutoff boundary, multi-batch, idempotent re-run, FK-safe parent cleanup |
| Safety | Unit tests for policy validation; Mix/API refuses unguarded prod purge per config |
| Ops | Docs: cron frequency, batch_size, monitoring (logs/telemetry), dry_run semantics |
| Performance | Batch-scoped transactions; optional note on index use for `captured_at` |

Sampling: after each task touching `lib/threadline/retention*.ex` or Mix task — `MIX_ENV=test mix test test/threadline/retention/` (once created); wave end — `mix ci.all` or `mix verify.test` per repo convention.

---

## RESEARCH COMPLETE
