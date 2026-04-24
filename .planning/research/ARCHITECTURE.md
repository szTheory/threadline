# Architecture Research — STG host parity

**Researched:** 2026-04-23

## Existing architecture (relevant slices)

1. **Capture** — PostgreSQL triggers write `audit_transactions` / `audit_changes`; grouping by `txid_current()`; no `SET LOCAL` in capture path (Path B, PgBouncer transaction–friendly design).
2. **Semantics bridge** — Transaction-local GUC (or equivalent) populated by app code so triggers attach **actor_ref**; **`Threadline.Plug`** (HTTP) and **`Threadline.Job`** (job args → actor) are the documented integration surfaces.
3. **CI topology job** — Direct Postgres for migrations/bootstrap; tests connect via **PgBouncer** port with **`THREADLINE_PGBOUNCER_TOPOLOGY=1`** (`test/threadline/pgbouncer_topology_test.exs`, `lib/mix/tasks/threadline/verify_topology.ex`).

## Integration points for v1.6 (documentation + evidence)

| Layer | What STG adds |
|-------|----------------|
| **Host network** | Document ports, pooler vs direct, TLS termination if it affects DB client |
| **Phoenix / Plug** | Show one request path that performs audited write (can reference host’s own controller/service — no new library API required) |
| **Oban / jobs** | Show one job that uses **`Threadline.Job`** (or documented equivalent) so audit rows tie to job actor |
| **Backlog** | Map proof to adoption pilot matrix rows (especially **Connection topology** and any **AP-ENV** follow-ups) |

## Suggested build order (single phase)

1. Freeze topology narrative (short markdown in host wiki or PR to pilot backlog section — maintainer may accept doc-only PRs that **template** evidence without claiming external hosts).  
2. Capture HTTP + job evidence in host environment.  
3. Update backlog statuses and links.

## New vs modified components

- **No new Elixir modules required** for minimal STG closure unless evidence exposes a real gap (then file as Issue / next milestone, not scope creep in STG).
