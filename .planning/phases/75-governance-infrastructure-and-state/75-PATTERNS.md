# Phase 75: Governance Infrastructure & State - Patterns

This document maps the requested new features to existing code patterns.

## 1. Migration Generator (`mix threadline.install`)

**Pattern:** `lib/mix/tasks/threadline.install.ex` currently writes `_threadline_audit_schema.exs` and `_threadline_semantics_schema.exs`.
- Uses `Mix.Generator.create_file/2` and reads template content from modules like `Threadline.Capture.Migration.migration_content()`.
- Generates timestamps and prepends them.
- Skips generating if a file ending in that suffix already exists.

**Application to Phase 75:**
We will update `Mix.Tasks.Threadline.Install` to also write `_threadline_governance_schema.exs`. We will define a new module `Threadline.Governance.Migration` that provides the `migration_content/0` function.

## 2. Ecto Schemas

**Pattern:** Ecto schemas are defined in context folders like `lib/threadline/capture/audit_transaction.ex`.
- Use `binary_id` for primary keys: `@primary_key {:id, :binary_id, autogenerate: true}` and `@foreign_key_type :binary_id`.
- Reusing JSONB fields like `actor_ref` using `Threadline.Semantics.ActorRef` which implements `Ecto.ParameterizedType`.

**Application to Phase 75:**
- Create `lib/threadline/governance/export_job.ex`
- Create `lib/threadline/governance/retention_run.ex`
- Create `lib/threadline/governance/saved_view.ex`
- For `export_job.ex` and `saved_view.ex`, we will use `field(:actor_ref, Threadline.Semantics.ActorRef)` just like `AuditTransaction` does.

## 3. Behaviours

**Pattern:** Behaviours in Elixir are defined using `@callback`. The project currently does not have strong abstract behaviour precedents in `lib/threadline`, but Elixir standard practice applies.
- Define a module with `@callback` attributes.
- Use explicit type specs.

**Application to Phase 75:**
- Create `lib/threadline/storage.ex` containing the `@callback`s described in 75-DISCUSSION.md.
- Create `lib/threadline/storage/local.ex` implementing `@behaviour Threadline.Storage`.
- Create `lib/threadline/export_queue.ex` containing the `@callback enqueue(job_id :: Ecto.UUID.t())`.
