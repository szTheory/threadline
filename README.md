# Threadline

[![CI](https://github.com/szTheory/threadline/actions/workflows/ci.yml/badge.svg)](https://github.com/szTheory/threadline/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/threadline.svg)](https://hex.pm/packages/threadline)
[![HexDocs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/threadline)
**CI:** Runs on [GitHub Actions](https://github.com/szTheory/threadline/actions).

Auditing for Phoenix.

Threadline is an open-source audit library for Elixir teams using Phoenix, Ecto, and PostgreSQL. It combines PostgreSQL trigger capture with semantic actions, then exposes the audit trail through `Threadline.Plug`, `Threadline.record_action/2`, `Threadline.history/3`, `Threadline.timeline/2`, `Threadline.timeline_page/2`, `Threadline.incident_bundle/2`, `Threadline.export_json/2`, and `Threadline.as_of/4`.

Use it when you want the audit layer in your app, not a separate event system or a black box.

## Start here

- **Evaluating:** open the [HexDocs](https://hexdocs.pm/threadline) for the full API.
- **Adopting in Phoenix SaaS:** read [guides/getting-started-saas.md](guides/getting-started-saas.md).
- **Using Sigra:** read [guides/integrations/sigra.md](guides/integrations/sigra.md).
- **Contributing:** follow [`CONTRIBUTING.md`](CONTRIBUTING.md) and run `mix ci.all`.

## What you get

- **Capture:** trigger-backed row-change history in PostgreSQL with `Threadline.Plug`.
- **Semantics:** actor, intent, correlation, and request context via `Threadline.record_action/2`.
- **Exploration:** timelines and history with `Threadline.timeline/2`, `Threadline.timeline_page/2`, and `Threadline.history/3`.
- **Operations:** exports, snapshots, coverage checks, retention, redaction, and health tooling via `Threadline.export_json/2` and `Threadline.as_of/4`.

## Quick Start

1. Add `threadline` to your dependencies:

   ```elixir
   def deps do
     [
       {:threadline, "~> 0.3"}
     ]
   end
   ```

2. Install and migrate:

   ```bash
   mix threadline.install
   mix ecto.migrate
   ```

3. Register triggers for the tables you want to audit:

   ```bash
   mix threadline.gen.triggers --tables users,posts,comments
   mix ecto.migrate
   ```

4. Add the plug and set an actor inside your transaction:

    ```elixir
    # lib/my_app_web/router.ex
    pipeline :browser do
      plug Threadline.Plug, actor_fn: &MyApp.Auth.to_actor_ref/1
    end

   alias Threadline.Semantics.ActorRef

   actor_ref = ActorRef.user("user:123")
   json = ActorRef.to_map(actor_ref) |> Jason.encode!()

    MyApp.Repo.transaction(fn ->
      MyApp.Repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])
      MyApp.Repo.insert!(%MyApp.Post{title: "Ship audit logs"})
    end)

    {:ok, _action} =
      Threadline.record_action(:post_published,
        repo: MyApp.Repo,
        actor: actor_ref
      )
    ```

5. Query the audit trail:

    ```elixir
    Threadline.history(MyApp.Post, post.id, repo: MyApp.Repo)
    Threadline.timeline([table: "posts"], repo: MyApp.Repo)
    Threadline.timeline_page([table: "posts"], repo: MyApp.Repo, page_size: 200)
    Threadline.export_json([table: "posts"], repo: MyApp.Repo)
    Threadline.as_of(MyApp.Post, post.id, DateTime.utc_now(), repo: MyApp.Repo)
    ```

Use `Threadline.timeline/2` for smaller eager slices. When an investigation window is
large enough that you want stable incremental traversal, switch to `Threadline.timeline_page/2`
and continue with the returned `next_cursor` instead of offset pagination.

For the rest of the investigation hierarchy: use the higher-level investigation
helpers when you want a packaged answer to a common support question, and use
`Threadline.incident_bundle/2` when you need the default drill-down for one
transaction incident. Keep the root README as the map, then use
[guides/domain-reference.md](guides/domain-reference.md) for the canonical
"which public API first?" table, [guides/getting-started-saas.md](guides/getting-started-saas.md)
for the first-hour Phoenix walkthrough, and
[guides/incident-playbook.md](guides/incident-playbook.md) for operator recipes.

## Operator Surface

Threadline provides an optional, drop-in LiveView UI to investigate the audit trail natively in your app, including a polled coverage dashboard at `/audit/coverage`, a read-only redaction drift viewer at `/audit/policy/redaction`, and parity Mix tasks `mix threadline.health.coverage` plus `mix threadline.policy.show`. Ensure you have the `phoenix`, `phoenix_live_view`, `phoenix_html`, and `phoenix_pubsub` dependencies in your `mix.exs`.

**1-Minute Mount**

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  import Threadline.OperatorSurface.Router

  # Must pipe through your own authentication
  scope "/admin", MyAppWeb do
    pipe_through [:browser, :require_authenticated_admin]

    threadline_operator_surface "/audit",
      actor_fn: {MyApp.Audit, :current_actor},
      authorize_fn: {MyApp.Audit, :authorize_operator}
  end
end
```

For full details on the "fail-closed" security default, setting up authorization, and the available investigation screens, read the [Operator Surface guide](guides/operator-surface.md).

## Notes

- Threadline works with PgBouncer transaction pooling.
- Redaction drift uses three states: `Config matches deployed`, `Drift detected`, and `Could not introspect`; rerun `mix threadline.gen.triggers` if the latter two appear.
- Redaction, retention, export, and continuity live in the guides and HexDocs.
- Next operator reads after the first install are [guides/performance.md](guides/performance.md) and [guides/incident-playbook.md](guides/incident-playbook.md).

## Documentation

- [HexDocs](https://hexdocs.pm/threadline)
- [Getting started with Phoenix SaaS](guides/getting-started-saas.md)
- [Sigra integration](guides/integrations/sigra.md)
- [Domain reference](guides/domain-reference.md)
- [Brownfield continuity](guides/brownfield-continuity.md)
- [Performance](guides/performance.md)
- [Incident playbook](guides/incident-playbook.md)
- [Production checklist](guides/production-checklist.md)
- [Adoption pilot backlog](guides/adoption-pilot-backlog.md)
- [CONTRIBUTING.md](CONTRIBUTING.md)
