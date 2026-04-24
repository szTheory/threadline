---
status: passed
phase: 24
verified: "2026-04-24"
---

# Phase 24 — Verification

## Automated

| Check | Result |
|-------|--------|
| `cd examples/threadline_phoenix && mix format` | Pass |
| `MIX_ENV=test DB_PORT=5433 mix verify.example` (repo root) | Pass — 6 tests, 0 failures |

## Requirements

- **REF-04:** Oban job path updates `posts` with trigger capture; semantics carry `job_id` / correlation via `Threadline.Job` helpers (`post_touch_worker_test.exs`, `PostTouchWorker`, `Blog.touch_post_for_job/2`).
- **REF-05:** `record_action(:post_title_refreshed_from_queue, …)` in the job transaction; README explains semantics in jobs vs capture-only.
- **REF-06:** Example README links production checklist and adoption/STG guide with integrator-owned positioning.

## must_haves (from plans)

### 24-01

| Item | Evidence |
|------|----------|
| Oban dep, config, supervision, `oban_jobs` migration | `mix.exs`, `config/*.exs`, `application.ex`, `priv/repo/migrations/*add_oban_jobs*` |
| `Blog.touch_post_for_job/2` | `blog.ex` |
| `PostTouchWorker` + test | `workers/post_touch_worker.ex`, `workers/post_touch_worker_test.exs` |

### 24-02

| Item | Evidence |
|------|----------|
| `## Semantics in jobs` | `examples/threadline_phoenix/README.md` |
| Guide links `../../guides/…` | same |
| Integrator-owned STG sentence | same |
| `Threadline.Job` reference | same |

## Notes

- Worker integration test uses **`Ecto.Adapters.SQL.Sandbox.unboxed_run`** + truncate cleanup so transaction-local GUC is visible to the capture trigger on `UPDATE` under PostgreSQL; default Sandbox nesting still covers other example tests.
