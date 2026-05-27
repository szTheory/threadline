# Phase 105 — Pattern Map

**Phase:** 105 — Help-Desk Domain Expansion in Reference App  
**Generated:** 2026-05-27

---

## File → Analog Map

| Role | New file (Phase 105) | Closest analog | Copy what |
|------|----------------------|--------------|-----------|
| Domain schema | `lib/threadline_phoenix/help_desk/organization.ex` | `lib/threadline_phoenix/post.ex` | `use Ecto.Schema`, `changeset/2`, timestamps |
| PK type | All help_desk schemas | (no analog — posts use integer id) | `@primary_key {:id, :binary_id, autogenerate: true}` + `@foreign_key_type :binary_id` |
| Migration | `priv/repo/migrations/*_create_help_desk*.exs` | `20260424080611_create_posts.exs` | `create table`, `unique_index`, `references` |
| Orchestration | `lib/threadline_phoenix/help_desk.ex` | `lib/threadline_phoenix/blog.ex` | `Repo.transaction`, GUC, `record_action`, `update_all` + meta |
| Trigger migration | `priv/repo/migrations/*_threadline_triggers_help_desk*.exs` | `20260424080642_threadline_triggers_posts.exs` | `execute` CREATE TRIGGER per table |
| Capture config | `config/test.exs`, `config/dev.exs` | root `config/test.exs:32-38` | `trigger_capture` tables map |
| Coverage config | `config/test.exs`, `config/dev.exs` | root test `verify_coverage` pattern | `expected_tables` list |
| Fixtures | `test/support/help_desk_fixtures.ex` | (new) | Factory chain: org → membership → agent → ticket |
| Audit proof test | `test/threadline_phoenix/help_desk_audit_test.exs` | `workers/post_touch_worker_test.exs` | `unboxed_run`, join AuditChange→AuditTransaction |
| Org meta scope | `HelpDesk` meta helper | `Blog.audit_transaction_meta/1` | `%{"organization_id" => org_id}` string |

---

## Excerpt — Blog transaction link (M1)

```32:74:examples/threadline_phoenix/lib/threadline_phoenix/blog.ex
        Repo.transaction(fn ->
          Repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])
          # ... writes ...
              case Threadline.record_action(:post_created_via_api, action_opts) do
                {:error, cs} ->
                  Repo.rollback(cs)
                {:ok, %AuditAction{id: action_id}} ->
                  {count, _} =
                    Repo.update_all(
                      from(at in AuditTransaction,
                        where: at.txid == fragment("txid_current()")
                      ),
                      set: [action_id: action_id, meta: audit_transaction_meta(opts)]
                    )
```

**105 adaptation:** Second write = `ticket_replies` insert + `tickets` update; action atom `:ticket_replied_and_closed`; meta from `to_string(organization.id)` not opts keyword.

---

## Excerpt — Capture assertion join

```34:44:examples/threadline_phoenix/test/threadline_phoenix/workers/post_touch_worker_test.exs
      assert {_ac, %AuditTransaction{} = at} =
               Repo.one!(
                 from(ac in AuditChange,
                   join: at in assoc(ac, :transaction),
                   where: ac.table_name == "posts",
                   where: ac.op == "update",
                   ...
                   select: {ac, at}
                 )
               )
```

**105 adaptation:** Two changes same `at.id`; `table_name in ["tickets", "ticket_replies"]`; assert `AuditAction` name `ticket_replied_and_closed`.

---

## Excerpt — Router org scope

```82:95:examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
  def scope_operator_query(query, %{organization_id: org_id}, %{surface: surface})
      when surface in [:timeline, :transaction, :export] and is_binary(org_id) and org_id != "" do
    where(query, [_ac, at], fragment("?->>'organization_id' = ?", at.meta, ^org_id))
  end
```

**105 requirement:** Every help-desk write that should appear in support-scoped `/audit` must set the same meta key shape.

---

## Anti-patterns (do not copy)

| Pattern | Why avoid in 105 |
|---------|------------------|
| `PostsAuditPathTest` ConnCase HTTP | No routes in phase (D-05a) |
| `exclude` for `internal_note_body` | D-03a requires `mask` |
| Soft-delete `deleted_at` | D-04a hard delete |
| Multiple `record_action` per ticket close | D-02d one action per operation |

---

## PATTERN MAPPING COMPLETE
