# Threadline

[![CI](https://github.com/szTheory/threadline/actions/workflows/ci.yml/badge.svg)](https://github.com/szTheory/threadline/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/threadline.svg)](https://hex.pm/packages/threadline)
[![HexDocs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/threadline)

Auditing for Phoenix.

Threadline is an open-source audit library for Elixir teams using Phoenix, Ecto, and PostgreSQL. It combines PostgreSQL trigger capture with semantic actions, then exposes the audit trail through `Threadline.Plug`, `Threadline.record_action/2`, `Threadline.history/3`, `Threadline.timeline/2`, `Threadline.export_json/2`, and `Threadline.as_of/4`.

Use it when you want the audit layer in your app, not a separate event system or a black box.

## Start here

- **Evaluating:** open the [HexDocs](https://hexdocs.pm/threadline) for the full API.
- **Integrating:** read [Quick Start](#quick-start) and then [guides/domain-reference.md](guides/domain-reference.md).
- **Contributing:** follow [`CONTRIBUTING.md`](CONTRIBUTING.md) and run `mix ci.all`.

## What you get

- **Capture:** trigger-backed row-change history in PostgreSQL with `Threadline.Plug`.
- **Semantics:** actor, intent, correlation, and request context via `Threadline.record_action/2`.
- **Exploration:** timelines and history with `Threadline.timeline/2` and `Threadline.history/3`.
- **Operations:** exports, snapshots, coverage checks, retention, redaction, and health tooling via `Threadline.export_json/2` and `Threadline.as_of/4`.

## Quick Start

1. Add `threadline` to your dependencies:

   ```elixir
   def deps do
     [
       {:threadline, "~> 0.2"}
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
    Threadline.export_json([table: "posts"], repo: MyApp.Repo)
    Threadline.as_of(MyApp.Post, post.id, DateTime.utc_now(), repo: MyApp.Repo)
    ```

## Notes

- Threadline works with PgBouncer transaction pooling.
- Redaction, retention, export, and continuity live in the guides and HexDocs.

## Documentation

- [HexDocs](https://hexdocs.pm/threadline)
- [Domain reference](guides/domain-reference.md)
- [Brownfield continuity](guides/brownfield-continuity.md)
- [Production checklist](guides/production-checklist.md)
- [Adoption pilot backlog](guides/adoption-pilot-backlog.md)
- [CONTRIBUTING.md](CONTRIBUTING.md)
