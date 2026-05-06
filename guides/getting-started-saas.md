# Getting started with Threadline in a Phoenix SaaS app

This guide gives a first-time adopter one copy-paste path from install through the first `Threadline.as_of/4` query using the shipped `examples/threadline_phoenix/` flow.

## 1. Prerequisites

- You need a Phoenix app with Ecto + PostgreSQL available before you start. If Phoenix is new to you, read <https://phoenixframework.org> first, then come back here.
- The walkthrough assumes your app has a `posts` table you want to audit first.
- Commands below use the same vocabulary as `examples/threadline_phoenix/`.

## 2. Add Threadline to your app

Add Threadline to `mix.exs`:

```elixir
defp deps do
  [
    {:threadline, "~> 0.3"}
  ]
end
```

Then fetch deps:

```bash
mix deps.get
```

## 3. Install the audit schema

Generate Threadline's base migrations, then run them:

```bash
mix threadline.install
mix ecto.migrate
```

## 4. Generate triggers for posts

Generate capture triggers for your first audited table:

```bash
mix threadline.gen.triggers --tables posts
mix ecto.migrate
```

Threadline reads your app config when it generates trigger SQL, so use the same `MIX_ENV` locally and in CI when you regenerate.

## 5. Wire `Threadline.Plug` with actor and additive request metadata

The Phoenix example keeps request capture small and explicit by wiring both
Sigra callbacks directly into `Threadline.Plug`:

```elixir
    plug(:accepts, ["json"])

    plug(Threadline.Plug,
      actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1,
      context_overrides_fn: &Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1
    )
```

If you do not use Sigra, keep the same shape: populate the conn with authenticated
request context first, then hand `Threadline.Plug` an `actor_fn` and any
request-derived context overrides you need.

`actor_fn` remains the only actor-authority path. `context_overrides_fn` is
for additive `request_id` and `correlation_id` metadata only, and those values
fill missing fields only. Explicit `x-request-id`, explicit
`x-correlation-id`, and the actor derived by `actor_fn` still win when present.

Keep `Threadline.Plug` in the router pipeline after auth setup and after any
host-owned proxy/IP normalization. If `context_overrides_fn` returns unknown
keys or any non-map value, `Threadline.Plug` raises `ArgumentError`
immediately so the wiring contract fails loudly.

## 6. Exercise the first audited write

The example writes the actor into the same database transaction as the insert, then records semantic intent before returning an `audit_transaction_id`:

```elixir
          Repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])

          case Repo.insert(Post.changeset(%Post{}, attrs)) do
            {:error, changeset} ->
              Repo.rollback(changeset)

            {:ok, post} ->
              opts = [
                repo: Repo,
                actor: actor_ref,
                correlation_id: audit_context.correlation_id,
                request_id: audit_context.request_id
              ]

              case Threadline.record_action(:post_created_via_api, opts) do
                {:error, cs} ->
                  Repo.rollback(cs)

                {:ok, %AuditAction{id: action_id}} ->
                  {count, _} =
                    Repo.update_all(
                      from(at in AuditTransaction,
                        where: at.txid == fragment("txid_current()")
                      ),
                      set: [action_id: action_id]
                    )

                  if count != 1 do
                    Repo.rollback(:missing_audit_transaction_for_link)
                  end

                  audit_transaction_id =
                    Repo.one!(
                      from(at in AuditTransaction,
                        where: at.txid == fragment("txid_current()"),
                        select: at.id
                      )
                    )

                  %{post: post, audit_transaction_id: audit_transaction_id}
              end
          end
```

Start your Phoenix app, then send the first audited request:

```bash
curl -sS -X POST "http://localhost:4000/api/posts" \
  -H "content-type: application/json" \
  -H "x-request-id: $(uuidgen)" \
  -H "x-correlation-id: demo-corr" \
  -d '{"post":{"title":"Hello","slug":"hello-demo-slug"}}'
```

Keep the returned `audit_transaction_id`; you will use it in step 8.

## 7. Check trigger coverage

Run the coverage task in CI, and keep the direct health check handy in IEx:

```elixir
case Threadline.Health.trigger_coverage(repo: MyApp.Repo) do
  [{:covered, _} | _] = coverage ->
    coverage

  other ->
    other
end
```

The literal `{:covered, _}` shape is the fast signal that your first public table is wired.

## 8. Investigate the captured timeline

Open IEx in the app and use the same first request to inspect row history, transaction drill-down, and point-in-time reconstruction:

```elixir
filters = [table: "posts", correlation_id: "demo-corr", repo: MyApp.Repo]

timeline = Threadline.timeline(filters)

first_page = Threadline.timeline_page(filters, page_size: 100)

{:ok, bundle} = Threadline.incident_bundle(audit_transaction_id, repo: MyApp.Repo)

as_of_at = DateTime.utc_now()

{:ok, post_as_of} =
  Threadline.as_of(MyApp.Post, post_id, as_of_at, repo: MyApp.Repo)
```

The reference app also requires an authenticated actor before it serves
`GET /api/audit_transactions/:id/changes`. That keeps the example honest about
incident drill-down: auth is included, while tenancy rules still belong to the
host app.

If you need to build a custom incident view instead of using the bundled default,
drop to `Threadline.audit_changes_for_transaction/2`, `Threadline.transaction_context/2`,
or `Threadline.change_diff/2` as advanced building blocks.

That sequence gives you the three first-hour operator questions:

- `Threadline.timeline/2` shows which rows moved in the request.
- `Threadline.timeline_page/2` is the same investigation path when the window is too large to read eagerly at once; continue with `first_page.next_cursor` instead of offsets.
- `Threadline.incident_bundle/2` gives you the default single-transaction incident view, including the linked context and packaged change diffs in `bundle`.
- `Threadline.as_of/4` reconstructs what the row looked like at a chosen point in time.

## Next reads

- [guides/production-checklist.md](production-checklist.md)
- [guides/incident-playbook.md](incident-playbook.md)
- [guides/performance.md](performance.md)
- [guides/integrations/sigra.md](integrations/sigra.md)
- [guides/brownfield-continuity.md](brownfield-continuity.md)
- [guides/adoption-pilot-backlog.md](adoption-pilot-backlog.md)
