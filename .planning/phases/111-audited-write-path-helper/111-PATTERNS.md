# Phase 111: Audited Write-Path Helper — Patterns

**Mapped:** 2026-05-27

## Files to Create/Modify

| File | Role | Closest analog |
|------|------|----------------|
| `lib/threadline/audit.ex` | New public API | `examples/threadline_phoenix/lib/threadline_phoenix/blog.ex` (manual recipe) |
| `test/threadline/audit_transaction_test.exs` | Integration tests | `test/threadline/capture/trigger_context_test.exs` |
| `test/threadline/audit_doc_contract_test.exs` | Doc contract | `test/threadline/getting_started_saas_doc_contract_test.exs` |
| `guides/getting-started-saas.md` | Adopter guide | §6 existing manual write |
| `guides/integration-contracts.md` | Breadth contract | Plug/Job sections |

## Pattern: Transaction-local actor GUC

**Source:** `lib/threadline/plug.ex:59`, `test/threadline/capture/trigger_context_test.exs:30-39`

```elixir
json = actor_ref |> Threadline.Semantics.ActorRef.to_map() |> Jason.encode!()
Repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])
```

## Pattern: Action linkage by txid

**Source:** `examples/threadline_phoenix/lib/threadline_phoenix/blog.ex:48-71`

```elixir
case Threadline.record_action(:post_created_via_api, action_opts) do
  {:error, cs} -> Repo.rollback(cs)
  {:ok, %AuditAction{id: action_id}} ->
    {count, _} =
      Repo.update_all(
        from(at in AuditTransaction, where: at.txid == fragment("txid_current()")),
        set: [action_id: action_id, meta: meta]
      )
    if count != 1, do: Repo.rollback(:missing_audit_transaction_for_link)
    audit_transaction_id = Repo.one!(from(at in AuditTransaction, ...))
end
```

## Pattern: record_action opts

**Source:** `lib/threadline.ex:40-61`

```elixir
action_opts = [
  repo: Repo,
  actor: actor_ref,
  correlation_id: audit_context.correlation_id,
  request_id: audit_context.request_id
]
Threadline.record_action(:post_created_via_api, action_opts)
```

## Pattern: Doc anchor extraction

**Source:** `test/support/getting_started_fixtures.ex:15-16`

```elixir
# doc: start: audit-transaction-helper
Threadline.Audit.transaction(Repo, [...], fn -> ... end)
# doc: end: audit-transaction-helper
```

```elixir
GettingStartedFixtures.extract!("lib/threadline/audit.ex", "audit-transaction-helper")
```

## Pattern: Trigger test table setup

**Source:** `test/threadline/capture/trigger_context_test.exs:6-27`

```elixir
setup_all do
  Repo.query!("CREATE TABLE IF NOT EXISTS test_audit_target_ctx (...)")
  Repo.query!(Threadline.Capture.TriggerSQL.create_trigger("test_audit_target_ctx"))
  on_exit(fn -> ... drop ... end)
end
```

## Pattern: Correlation timeline assertion

**Source:** `test/threadline/query_test.exs:815-832`

```elixir
results = Threadline.timeline(repo: @repo, table: tname, correlation_id: "loop01-cid")
assert length(results) == 1
```

## Anti-patterns to avoid

- `touch_post_for_job` style: `record_action` without `action_id` linkage when `:action` is passed to helper
- Process dict / Logger for `audit_transaction_id` (rejected per D-111-02e)
- Nested `Repo.transaction/1` inside callback (breaks txid linkage)
