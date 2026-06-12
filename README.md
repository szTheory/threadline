<picture>
  <source media="(prefers-color-scheme: dark)" srcset="brandbook/logo-primary.svg">
  <img alt="Threadline" src="brandbook/logo-primary-light.svg" width="420">
</picture>

# Threadline

[![CI](https://github.com/szTheory/threadline/actions/workflows/ci.yml/badge.svg)](https://github.com/szTheory/threadline/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/threadline.svg)](https://hex.pm/packages/threadline)
[![HexDocs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/threadline)
**CI:** Runs on [GitHub Actions](https://github.com/szTheory/threadline/actions).

Auditing for Phoenix.

Threadline is an open-source audit library for Elixir teams using Phoenix, Ecto, and PostgreSQL. It combines PostgreSQL trigger capture with semantic actions, then exposes the audit trail through `Threadline.Plug`, `Threadline.Audit.transaction/3`, `Threadline.record_action/2`, `Threadline.history/3`, `Threadline.timeline/2`, `Threadline.timeline_page/2`, `Threadline.incident_bundle/2`, `Threadline.export_json/2`, and `Threadline.as_of/4`.

New Phoenix integrations should use `Threadline.Audit.transaction/3`; see [Getting started](guides/getting-started-saas.md) §6.

Use it when you want the audit layer in your app, not a separate event system or a black box.

## Start here

- **Evaluating:** read [guides/evaluating-threadline.md](guides/evaluating-threadline.md) for in-repo proof, host boundaries, and the `mix verify.*` ladder; [HexDocs](https://hexdocs.pm/threadline) remains the API reference.
- **Understanding the system:** read [guides/how-threadline-works.md](guides/how-threadline-works.md) for the architecture/persona/JTBD crash course — both paths converge on `Threadline.Audit.transaction/3` for audited writes.
- **Adopting in Phoenix SaaS:** read [guides/getting-started-saas.md](guides/getting-started-saas.md) — use `Threadline.Audit.transaction/3` as the recommended audited write path (§6).
- **Understanding the integration seams:** read [guides/integration-contracts.md](guides/integration-contracts.md).
- **Checking the named support lanes:** read [guides/upgrade-path.md](guides/upgrade-path.md) for the canonical `capture-only`, `phoenix-surface`, `phx-gen-auth-reference`, and `sigra-reference` matrix.
- **Phoenix auth (reference lanes, pick one):** [phx.gen.auth integration](guides/integrations/phx-gen-auth.md) · [Sigra integration](guides/integrations/sigra.md) — neither required; see [upgrade-path](guides/upgrade-path.md) for claim types.
- **Trying the local demo:** read [guides/local-docker-dx.md](guides/local-docker-dx.md) for the Docker helper, local ports, and multi-stack cleanup.
- **Contributing:** follow [`CONTRIBUTING.md`](CONTRIBUTING.md) and run `mix ci.all`.

## Evidence plane

Threadline can persist evidence about its own governance surfaces such as
trigger coverage, redaction posture, retention runs, export delivery, and the
support-lane posture around mounted capabilities. That evidence plane stays
host-owned on authorization and product scope: Threadline does not become a
legal hold system, an immutable-storage guarantee beyond the host
runtime/storage contract, a generic compliance pack, a vendor-specific
reporting suite, or a Threadline-owned RBAC or tenancy DSL.

For the canonical non-goals list, read
[guides/how-threadline-works.md](guides/how-threadline-works.md). For the
named lane contract, including separately authorized `/audit/evidence`, read
[guides/upgrade-path.md](guides/upgrade-path.md). For the public verdict
vocabulary (`claim_assessment`, `proven`, `inferred_posture`, `unsupported`),
read [guides/domain-reference.md](guides/domain-reference.md).

## What you get

- **Capture:** trigger-backed row-change history in PostgreSQL with `Threadline.Plug`.
- **Semantics:** `Threadline.Audit.transaction/3` as the recommended audited write path (actor, intent, correlation, and request context); `Threadline.record_action/2` is the semantic primitive the helper wraps.
- **Exploration:** timelines and history with `Threadline.timeline/2`, `Threadline.timeline_page/2`, and `Threadline.history/3`.
- **Operations:** exports, snapshots, coverage checks, retention, redaction, and health tooling via `Threadline.export_json/2` and `Threadline.as_of/4`.

## Quick Start

1. Add `threadline` to your dependencies:

   ```elixir
   def deps do
     [
       {:threadline, "~> 0.6"}
     ]
   end
   ```

2. Configure Threadline:

   Threadline Mix tasks resolve the repo from `config :threadline, ecto_repos` (not host `:ecto_repos` alone). Add this to `config/config.exs`:

   ```elixir
   config :threadline,
     ecto_repos: [MyApp.Repo],
     storage_schema: "threadline"
   ```

   `storage_schema` defaults to `"threadline"` and keeps Threadline-owned
   tables/functions out of `public`. Set it to `"public"` explicitly if you want
   the historical public-schema footprint, or to another PostgreSQL schema such
   as `"audit"`.

   See [Getting started §2 — Configure Threadline](guides/getting-started-saas.md#configure-threadline) for dual-repo rationale.

3. Install and migrate:

   ```bash
   mix threadline.install
   mix ecto.migrate
   ```

4. Register triggers for your first audited table:

   ```bash
   mix threadline.gen.triggers --tables posts
   mix ecto.migrate
   ```

   See [getting-started §4](guides/getting-started-saas.md) for the first-table walkthrough and [production-checklist §1](guides/production-checklist.md) for the full `expected_tables` inventory.

5. Wrap audited writes with `Threadline.Audit.transaction/3` — see [Getting started with Threadline in a Phoenix SaaS app](guides/getting-started-saas.md) §6 for the canonical helper snippet (actor GUC + domain writes + optional action linkage in one transaction).

6. Query the audit trail:

    ```elixir
    Threadline.history(MyApp.Post, post.id, repo: MyApp.Repo)
    Threadline.timeline([table: "posts"], repo: MyApp.Repo)
    Threadline.timeline_page([table: "posts"], repo: MyApp.Repo, page_size: 200)
    Threadline.export_json([table: "posts"], repo: MyApp.Repo)
    Threadline.as_of(MyApp.Post, post.id, DateTime.utc_now(), repo: MyApp.Repo)
    ```

Use `Threadline.timeline/2` for smaller eager slices. When the window is too
large to read eagerly, switch to `Threadline.timeline_page/2` and continue with
`next_cursor` instead of offset pagination.

See
[guides/domain-reference.md](guides/domain-reference.md) for the canonical
"which public API first?" table,
[guides/getting-started-saas.md](guides/getting-started-saas.md) for the
canonical first-hour Phoenix walkthrough, and
[guides/incident-playbook.md](guides/incident-playbook.md) for operator recipes.

## Operator Surface

Threadline ships an optional, drop-in LiveView **operator console** — a dark,
branded admin surface for investigating the audit trail natively in your app,
with no asset build step. It opens on a task launcher (**Find / Verify /
Prove**) and threads into a filterable change timeline, atomic-transaction and
row-level diffs, per-actor history, append-only **evidence** with
Proven / Inferred / Unsupported verdicts, a polled **coverage** dashboard, and
read-only **redaction-drift** and **retention** viewers — backed by parity Mix
tasks (`mix threadline.incident`, `mix threadline.health.coverage`,
`mix threadline.policy.show`) for capture-only adopters. Mount is fail-closed by
default. Ensure you have the optional Phoenix
surface dependencies declared in `mix.exs`. The Threadline UI currently ships as
an optional in-tree dependency. For details on this architecture decision and
support guarantees, see the [Upgrade Path](guides/upgrade-path.md).

**1-Minute Mount**

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  import Threadline.OperatorSurface.Router

  # Must pipe through your own authentication
  scope "/audit", MyAppWeb do
    pipe_through [:browser, :require_authenticated_admin]

    threadline_operator_surface "/",
      actor_fn: &MyApp.Audit.current_actor/1,
      authorize_fn: &MyApp.Audit.authorize_operator/1
  end
end
```

For the full first-hour mounted walkthrough, read
[guides/getting-started-saas.md](guides/getting-started-saas.md). For the
"fail-closed" security default, authorization setup, and screen inventory, read
the [Operator Surface guide](guides/operator-surface.md). For the broader host
and framework contract across `Threadline.Plug`, `Threadline.Job`,
`Threadline.Integrations.*`, and operator-surface auth/export auth, read
[guides/integration-contracts.md](guides/integration-contracts.md). For the
current support claims, stay with
[guides/upgrade-path.md](guides/upgrade-path.md) rather than inferring broader
compatibility from the README.

## Notes

- Threadline works with PgBouncer transaction pooling.
- Redaction drift uses three states: `Config matches deployed`, `Drift detected`, and `Could not introspect`; rerun `mix threadline.gen.triggers` if the latter two appear.
- Redaction, retention, export, and continuity live in the guides and HexDocs.
- Next operator reads after the first install are [guides/performance.md](guides/performance.md) and [guides/incident-playbook.md](guides/incident-playbook.md).

## Documentation

- [HexDocs](https://hexdocs.pm/threadline)
- [How Threadline works](guides/how-threadline-works.md)
- [Getting started with Phoenix SaaS](guides/getting-started-saas.md)
- [Evaluating Threadline](guides/evaluating-threadline.md)
- [Local Docker DX](guides/local-docker-dx.md)
- [Integration contracts](guides/integration-contracts.md)
- [Support lanes and upgrade path](guides/upgrade-path.md)
- [phx.gen.auth integration](guides/integrations/phx-gen-auth.md)
- [Sigra integration (reference lane)](guides/integrations/sigra.md)
- [Domain reference](guides/domain-reference.md)
- [Brownfield continuity](guides/brownfield-continuity.md)
- [Performance](guides/performance.md)
- [Incident playbook](guides/incident-playbook.md)
- [Production checklist](guides/production-checklist.md)
- [Adoption pilot backlog](guides/adoption-pilot-backlog.md)
- [CONTRIBUTING.md](CONTRIBUTING.md)
