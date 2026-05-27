# Phase 112: Reference App Adopts Helper — Patterns

**Mapped:** 2026-05-27

## Files to Create/Modify

| File | Role | Closest analog |
|------|------|----------------|
| `lib/threadline/audit.ex` | Prerequisite lib bugfix — capture-only `:transaction_meta` | `link_action/3` at `:217-228` (meta-only branch) |
| `test/threadline/audit_transaction_test.exs` | Capture-only meta integration test | `"transaction_meta stored on linked audit_transaction"` at `:157-175` |
| `examples/threadline_phoenix/lib/threadline_phoenix/blog.ex` | Migrate `create_post/2` + `touch_post_for_job/2` to helper | Current manual interior at `:33-77`, `:116-134` |
| `examples/threadline_phoenix/lib/threadline_phoenix/help_desk.ex` | Migrate `ticket_replied_and_closed/6` + `delete_reply/3` | Current manual interior at `:155-218`, `:244-261` |
| `examples/threadline_phoenix/lib/threadline_phoenix/workers/post_touch_worker.ex` | Thin Oban edge — unchanged collapse | Current `perform/1` at `:15-18` |
| `guides/getting-started-saas.md` | Replace §6 legacy block with single helper excerpt | §6 `Recommended path` at `:85-110` |
| `test/threadline/getting_started_saas_doc_contract_test.exs` | Doc contract — helper interior + negative legacy refute | `blog_block()` at `:121-126`, guide embed at `:37` |
| `examples/threadline_phoenix/test/threadline_phoenix/workers/post_touch_worker_test.exs` | Strengthen `action_id` linkage assertion | Existing action lookup at `:49-58` |
| `examples/threadline_phoenix/test/threadline_phoenix/help_desk_audit_test.exs` | Optional delete-path `at.meta` assertion | Reply-path meta assert at `:41-42` |
| `README.md` | ADOPT-HELPER-03 quickstart cross-link | Step 4 manual block at `:74-97` |
| `examples/threadline_phoenix/README.md` | Semantics-in-jobs helper description | `:319-323` current GUC + record_action prose |

## Pattern: Capture-only `:transaction_meta` (lib bugfix)

**Source:** `lib/threadline/audit.ex:185-188` (gap), `link_action/3` at `:217-228`, manual meta-only in `help_desk.ex:248-254`

Current capture-only branch skips meta:

```elixir
defp finalize_success(repo, resolved, result) do
  case resolved.action_name do
    nil ->
      attach_audit_transaction_id(repo, result)  # meta never applied
```

Target: when `resolved.transaction_meta` is non-nil, run meta-only `update_all` before attach:

```elixir
nil ->
  with :ok <- apply_capture_meta(repo, resolved.transaction_meta) do
    attach_audit_transaction_id(repo, result)
  end

defp apply_capture_meta(repo, nil), do: :ok

defp apply_capture_meta(repo, transaction_meta) do
  {count, _} =
    repo.update_all(
      from(at in AuditTransaction, where: at.txid == fragment("txid_current()")),
      set: [meta: transaction_meta]
    )

  if count == 1, do: :ok, else: {:error, :missing_audit_transaction_for_link}
end
```

**Test shape** — mirror linked-meta test at `audit_transaction_test.exs:157-175`:

```elixir
test "transaction_meta stored on capture-only audit_transaction" do
  {:ok, actor} = ActorRef.new(:user, "audit-helper-capture-meta")

  assert {:ok, %{result: :done, audit_transaction_id: id}} =
           Threadline.Audit.transaction(
             Repo,
             [
               actor_ref: actor,
               capture_only: true,
               transaction_meta: %{"organization_id" => "org-capture-only"}
             ],
             fn -> insert_row!("capture-meta"); :done end
           )

  at = Repo.get!(AuditTransaction, id)
  assert at.meta == %{"organization_id" => "org-capture-only"}
  assert is_nil(at.action_id)
end
```

## Pattern: HTTP correlation-ready helper call

**Source:** `111-PATTERNS.md` helper contract; target interior from `112-CONTEXT.md:140-154`

Replace manual `Repo.transaction` + `set_config` + `record_action` + `update_all` in `Blog.create_post/2`:

```elixir
Threadline.Audit.transaction(
  Repo,
  [
    audit_context: audit_context,
    action: :post_created_via_api,
    transaction_meta: audit_transaction_meta(opts)
  ],
  fn ->
    case Repo.insert(Post.changeset(%Post{}, attrs)) do
      {:error, changeset} -> Repo.rollback(changeset)
      {:ok, post} -> %{post: post}
    end
  end
)
# => {:ok, %{post: %Post{}, audit_transaction_id: uuid}}
```

Same shape for `HelpDesk.ticket_replied_and_closed/6` — multi-step callback, single helper call:

```elixir
Threadline.Audit.transaction(
  Repo,
  [
    audit_context: audit_context,
    action: :ticket_replied_and_closed,
    transaction_meta: audit_transaction_meta(organization)
  ],
  fn ->
    with {:ok, reply} <- Repo.insert(reply_changeset),
         {:ok, updated_ticket} <- Repo.update(ticket_changeset) do
      %{ticket: updated_ticket, reply: reply}
    else
      {:error, cs} -> Repo.rollback(cs)
    end
  end
)
```

Drop `AuditTransaction` / `AuditAction` aliases when no longer referenced. Remove outer `case audit_context.actor_ref` nil guard — helper returns `{:error, :missing_actor}` via `audit_context:` sugar.

## Pattern: Oban correlation-ready helper call

**Source:** `blog.ex:99-137` (SEED-001 footgun — records action without `action_id` link); `Threadline.Job` at `lib/threadline/job.ex`

```elixir
case Job.actor_ref_from_args(args) do
  {:error, _} = err -> err
  {:ok, actor_ref} ->
    Threadline.Audit.transaction(
      Repo,
      [
        actor_ref: actor_ref,
        action: {:post_title_refreshed_from_queue, Job.context_opts(args)}
      ],
      fn ->
        post = Repo.get!(Post, post_id)
        case Repo.update(Post.changeset(post, %{title: title})) do
          {:error, cs} -> Repo.rollback(cs)
          {:ok, updated} -> %{post: updated}
        end
      end
    )
end
# => {:ok, %{post: %Post{}, audit_transaction_id: uuid}}
```

`PostTouchWorker` stays thin — `{:ok, _post}` matches map envelope:

```elixir
case ThreadlinePhoenix.Blog.touch_post_for_job(args, attrs) do
  {:ok, _post} -> :ok
  {:error, reason} -> {:error, reason}
end
```

## Pattern: Capture-only delete with `:transaction_meta`

**Source:** `help_desk.ex:229-267`; D-107-05d (no `:ticket_reply_deleted` action)

```elixir
Threadline.Audit.transaction(
  Repo,
  [
    audit_context: audit_context,
    capture_only: true,
    transaction_meta: audit_transaction_meta(organization)
  ],
  fn ->
    Repo.delete!(reply)
    :deleted
  end
)
|> case do
  {:ok, %{result: :deleted, audit_transaction_id: _}} -> {:ok, :deleted}
  {:error, reason} -> {:error, reason}
end
```

Unify error atom to `:missing_audit_transaction_for_link` (drop `:missing_audit_transaction_for_delete`). Public API preserves `{:ok, :deleted}`.

## Pattern: Doc marker interior swap (example app SSOT)

**Source:** `blog.ex:33-77`; `111-PATTERNS.md` doc anchor extraction; Phase 47 D-03

Marker name unchanged — interior becomes helper call:

```elixir
# doc: start: blog-create-post-transaction
Threadline.Audit.transaction(
  Repo,
  [
    audit_context: audit_context,
    action: :post_created_via_api,
    transaction_meta: audit_transaction_meta(opts)
  ],
  fn ->
    case Repo.insert(Post.changeset(%Post{}, attrs)) do
      {:error, changeset} -> Repo.rollback(changeset)
      {:ok, post} -> %{post: post}
    end
  end
)
# doc: end: blog-create-post-transaction
```

Extract path unchanged:

```elixir
GettingStartedFixtures.extract!(
  "examples/threadline_phoenix/lib/threadline_phoenix/blog.ex",
  "blog-create-post-transaction"
)
```

`audit-transaction-helper` marker in `lib/threadline/audit.ex` stays library doc contract only — **not** getting-started extract source (D-112-02d).

## Pattern: Guide §6 single-block replacement

**Source:** `guides/getting-started-saas.md:83-173`; D-112-02a-c

Remove entire `### Legacy manual recipe (reference app)` subsection. §6 becomes:

1. One fenced block = `blog_block()` from marker (rollback-safe `case`/`Repo.rollback`, not bang inserts)
2. Prose on `:audit_transaction_id`, capture-only opt-out, link to `guides/integration-contracts.md` § Audited write path
3. Curl exercise unchanged (`:165-171`)

Align rollback-safe shape across marker, §6, and (optional) `integration-contracts.md`:

```elixir
fn ->
  case Repo.insert(Post.changeset(%Post{}, attrs)) do
    {:error, changeset} -> Repo.rollback(changeset)
    {:ok, post} -> %{post: post}
  end
end
```

## Pattern: Doc contract updates

**Source:** `getting_started_saas_doc_contract_test.exs:37`, `:121-126`

```elixir
assert String.contains?(doc, blog_block())
refute String.contains?(doc, "Legacy manual recipe")
assert String.contains?(blog_block(), "Threadline.Audit.transaction")
```

Router/mount anchors (`router_block()`, `mount_block()`) — unchanged.

## Pattern: action_id linkage assertion (SEED-001 fix proof)

**Source:** `post_touch_worker_test.exs:49-58`; `help_desk_audit_test.exs:45-53` (linked HTTP path)

After worker test finds action, add linkage proof:

```elixir
assert at.action_id == action.id
```

Optional delete-path meta (D-112-03e) — after `help_desk_audit_test.exs:84`:

```elixir
delete_at =
  Repo.one!(
    from(at in AuditTransaction,
      join: ac in assoc(at, :changes),
      where: ac.table_name == "ticket_replies" and ac.op == "delete",
      where: fragment("?->>'id' = ?", ac.table_pk, ^to_string(reply.id)),
      order_by: [desc: at.captured_at],
      limit: 1
    )
  )

assert delete_at.meta["organization_id"] == to_string(org.id)
```

## Pattern: README cross-links (ADOPT-HELPER-03)

**Source:** `README.md:74-97`; `examples/threadline_phoenix/README.md:319-323`, `:332`

Root README step 4 — point to `Threadline.Audit.transaction/3` + `guides/getting-started-saas.md` §6 instead of separate `set_config` + `record_action` blocks.

Example README "Semantics in jobs" — describe helper-based `touch_post_for_job/2`:

```markdown
`PostTouchWorker` → `Blog.touch_post_for_job/2` uses `Threadline.Audit.transaction/3`
with `actor_ref:` and `action: {:post_title_refreshed_from_queue, Job.context_opts(args)}`.
See `Threadline.Job` for `actor_ref_from_args/1` and `context_opts/1`.
```

Update POST /api/posts note to cite helper linkage instead of manual `action_id` wiring.

## Pattern: Org-scoped transaction meta helpers

**Source:** `blog.ex:82-90` (opts keyword); `help_desk.ex:269-271` (Organization struct)

Blog — optional org from caller opts:

```elixir
defp audit_transaction_meta(opts) do
  case Keyword.get(opts, :organization_id) do
    org_id when is_binary(org_id) and org_id != "" -> %{"organization_id" => org_id}
    _ -> nil
  end
end
```

HelpDesk — always from organization:

```elixir
defp audit_transaction_meta(%Organization{id: org_id}) do
  %{"organization_id" => to_string(org_id)}
end
```

Pass via helper `:transaction_meta:` opt — helper applies on both correlation-ready and capture-only paths after lib fix.

## Anti-patterns to avoid

- Leaving manual `set_config` → `record_action` → `update_all` in the four migrated paths when helper exists
- `touch_post_for_job` returning bare `%Post{}` without `audit_transaction_id` envelope (SEED-001 footgun)
- `record_action` inside helper callback (forbidden — breaks txid linkage)
- Adding `:ticket_reply_deleted` semantic action on hard delete (D-107-05d)
- Second fenced manual block in getting-started §6 ("Legacy manual recipe")
- Using `Repo.insert!` in doc snippets when marker uses rollback-safe `case` (D-112-02e)
- Migrating `provision_default_workspace_for_user/2`, demo seeds, or `incident_replay.exs` (out of scope D-112-01b)
- Opt-in `return_audit:` flag or struct-only return from context functions (D-112-04d — one canonical envelope)
- Weakening audit tests to only check action existence without `at.action_id == action.id`

## PATTERN MAPPING COMPLETE
