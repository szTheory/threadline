---
phase: 24
plan: 24-01
status: complete
---

# Plan 24-01 Summary: Oban worker — audited posts update + record_action

## Outcome

- Added **Oban** to `examples/threadline_phoenix` (dependency, `config.exs`, `test.exs`, supervision after `Repo`, `oban_jobs` migration).
- Implemented **`ThreadlinePhoenix.Blog.touch_post_for_job/2`**: `Threadline.Job.actor_ref_from_args/1`, transaction-local GUC, `Post.changeset` update, `Threadline.record_action(:post_title_refreshed_from_queue, …)` with `Threadline.Job.context_opts/1`.
- Added **`ThreadlinePhoenix.Workers.PostTouchWorker`** (`queue: :threadline_audit`) merging `"job_id"` into args before calling `Blog.touch_post_for_job/2`.
- Added **`post_touch_worker_test.exs`**: `Oban.Testing` + `perform_job/1`, capture + semantics assertions. The test body runs inside **`Ecto.Adapters.SQL.Sandbox.unboxed_run/2`** because nested Sandbox savepoints prevented the capture trigger from observing transaction-local `threadline.actor_ref` on `UPDATE` under the default harness; the test truncates `posts` and audit tables afterward to avoid leaking rows to sandboxed tests.

## Verification

- `cd examples/threadline_phoenix && mix format && mix compile --warnings-as-errors`
- `DB_PORT=5433 mix test` (example app)
- `DB_PORT=5433 MIX_ENV=test mix verify.example` (repository root)

## Deviations

- Test uses `Sandbox.unboxed_run` + `TRUNCATE … CASCADE` instead of relying on default per-test rollback for the worker assertion (documented above).
