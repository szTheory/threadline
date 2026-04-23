# Threadline

[![CI](https://github.com/szTheory/threadline/actions/workflows/ci.yml/badge.svg)](https://github.com/szTheory/threadline/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/threadline.svg)](https://hex.pm/packages/threadline)
[![HexDocs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/threadline)

Threadline is an open-source audit platform for Elixir teams using Phoenix, Ecto, and PostgreSQL. It combines PostgreSQL trigger-backed row-change capture, rich action semantics (actor, intent, correlation), and operator-grade exploration via plain SQL queries — without opaque blobs or a separate event bus.

## Requirements

- Elixir ~> 1.15
- PostgreSQL (trigger support required)
- Ecto and Phoenix (recommended; Plug integration included)

## Installation

Add `threadline` to your dependencies:

```elixir
# mix.exs
def deps do
  [
    {:threadline, "~> 0.1"}
  ]
end
```

Run the installer to generate the base migration:

```bash
mix threadline.install
mix ecto.migrate
```

Register audit triggers on the tables you want to audit:

```bash
mix threadline.gen.triggers --tables users,posts,comments
mix ecto.migrate
```

## Quick Start

### 1. Add the Plug to your router or endpoint

```elixir
# lib/my_app_web/router.ex
pipeline :browser do
  plug Threadline.Plug, actor_fn: &MyApp.Auth.to_actor_ref/1
end
```

Your `actor_fn` receives the `Plug.Conn` and returns a `Threadline.Semantics.ActorRef`:

```elixir
defmodule MyApp.Auth do
  alias Threadline.Semantics.ActorRef

  def to_actor_ref(conn) do
    case conn.assigns[:current_user] do
      nil  -> ActorRef.anonymous()
      user -> ActorRef.user("user:#{user.id}")
    end
  end
end
```

### 2. Record an action with audited writes

Wrap your database writes in `Ecto.Repo.transaction/1` and set the actor GUC **before** the first write. This tells the PostgreSQL trigger which actor performed the changes:

```elixir
def update_user_role(user, new_role, conn) do
  audit_context = conn.assigns[:audit_context]

  {:ok, _} = Threadline.record_action(
    %{
      name: "member.role_changed",
      actor_ref: audit_context.actor_ref,
      status: :ok,
      reason: "Promotion approved by admin"
    },
    fn action ->
      json = Threadline.Semantics.ActorRef.to_map(audit_context.actor_ref) |> Jason.encode!()

      MyApp.Repo.transaction(fn ->
        MyApp.Repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])
        MyApp.Repo.update!(Ecto.Changeset.change(user, role: new_role))
        action
      end)
    end,
    repo: MyApp.Repo
  )
end
```

### 3. Query the audit trail

```elixir
# Full change history for a specific row
Threadline.history("users", %{"id" => user.id}, repo: MyApp.Repo)

# All actions by a specific actor
Threadline.actor_history("user:123", repo: MyApp.Repo)

# Unified timeline of actions and changes
Threadline.timeline(%{repo: MyApp.Repo})
```

## PgBouncer and Connection Pooling

Threadline is safe under PgBouncer **transaction-mode pooling**. The `Threadline.Plug` stores request metadata in `conn.assigns` only — it never issues `SET` or `SET LOCAL` on the database connection outside of a transaction.

Actor information is propagated to the PostgreSQL trigger using `set_config('threadline.actor_ref', $1::text, true)`, where the third argument `true` makes the GUC **transaction-local**: it is automatically cleared when the transaction ends and never leaks to a different connection or pooled session.

For the full SQL bridge pattern and PgBouncer safety explanation, see [`Threadline.Plug`](https://hexdocs.pm/threadline/Threadline.Plug.html).

## Documentation

- **Full API reference:** [hexdocs.pm/threadline](https://hexdocs.pm/threadline)
- **Domain model:** [guides/domain-reference.md](guides/domain-reference.md)
- **Contributing:** [CONTRIBUTING.md](CONTRIBUTING.md)
