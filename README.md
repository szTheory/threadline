<picture>
  <source media="(prefers-color-scheme: dark)" srcset="brand/assets/logo/threadline-lockup-dark.svg">
  <img alt="Threadline" src="brand/assets/logo/threadline-lockup-light.svg" width="420">
</picture>

# Threadline

[![CI](https://github.com/szTheory/threadline/actions/workflows/ci.yml/badge.svg)](https://github.com/szTheory/threadline/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/threadline.svg)](https://hex.pm/packages/threadline)
[![HexDocs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/threadline)
**CI:** Runs on [GitHub Actions](https://github.com/szTheory/threadline/actions).

**Follow what happened.**

Threadline is an audit trail library for Phoenix apps. It records every insert, update and delete in your PostgreSQL database, with who made each change and when, and adds Threadline Admin, where your team can follow what happened.

PostgreSQL triggers capture writes on the tables you register; actor details come from the context your app supplies.

New Phoenix integrations should use `Threadline.Audit.transaction/3`; see [Getting started](guides/getting-started-saas.md) §6.

Use it when you want the audit layer in your app, not a separate event system or a black box.

## Start here

Pick the row that matches what you want to do. Each lane points at its canonical landing and the next guide to read.

| I want to... | Start here | Then read |
| --- | --- | --- |
| **Evaluate** — see what Threadline proves in-repo, and what you must prove in staging. | [guides/evaluating-threadline.md](guides/evaluating-threadline.md) | [how-threadline-works.md](guides/how-threadline-works.md) |
| **Adopt** — install, capture one real write, and mount Threadline Admin in the first hour. Wire it into a Phoenix app. | [guides/getting-started-saas.md](guides/getting-started-saas.md) | [configuration and commands](guides/configuration-and-commands.md) |
| **Operate** — follow row changes and actor history in Threadline Admin at `/audit`. | [guides/operator-surface.md](guides/operator-surface.md) | [incident-playbook.md](guides/incident-playbook.md) |
| **Contribute** — set up the repo, run `mix ci.all`, and follow the contribution gate. | [`CONTRIBUTING.md`](CONTRIBUTING.md) | [guides/adoption-pilot-backlog.md](guides/adoption-pilot-backlog.md) |

[HexDocs](https://hexdocs.pm/threadline) remains the complete API reference.

<a id="evidence-plane"></a>

## Check audit coverage and operations

Use Threadline Admin to check which tables are audited, compare configured
redaction with deployed triggers, review retention runs, and follow export
status. Stored evidence records let your team review those observations later.

Authorization and product scope remain host-owned. Threadline does not provide
legal hold, regulatory certification, a reporting suite, or its own role or
tenant model. Protection and durability depend on the host runtime and storage.

For the canonical non-goals list, read
[guides/how-threadline-works.md](guides/how-threadline-works.md). For the
named lane contract, including separately authorized `/audit/evidence`, read
[guides/upgrade-path.md](guides/upgrade-path.md). For the public verdict
vocabulary (`claim_assessment`, `proven`, `inferred_posture`, `unsupported`),
read [guides/domain-reference.md](guides/domain-reference.md).

## What you get

- **Capture:** trigger-backed row-change history in PostgreSQL with `Threadline.Plug`.
- **Semantics:** `Threadline.Audit.transaction/3` as the recommended audited write path (actor, intent, correlation, and request context); `Threadline.record_action/2` is the semantic primitive the helper wraps.
- **Exploration:** timelines and history with `Threadline.timeline/2`, `Threadline.timeline_page/2`, and `Threadline.row_history/3`.
- **Operations:** exports, snapshots, coverage checks, retention, redaction, and health tooling via `Threadline.export_json/2` and `Threadline.as_of/4`.

The broader public surface includes `Threadline.Plug`, `Threadline.record_action/2`, and `Threadline.incident_bundle/2`; the [domain reference](guides/domain-reference.md) maps each job to the API to use first.

## Quick Start

Add the current Threadline package coordinate to your dependencies:

```elixir
{:threadline, "~> 1.1.0"}
```

Then follow [Getting started with Threadline in a Phoenix SaaS app](guides/getting-started-saas.md)
for the single runnable install, configuration, first audited write, and first
query path. When you need the exhaustive supported settings and command
boundaries, use the [configuration and command reference](guides/configuration-and-commands.md).
The [domain reference](guides/domain-reference.md) keeps the canonical "which public API first?" table.

<a id="operator-surface"></a>

## Threadline Admin

Threadline Admin is the optional, in-tree LiveView interface for finding a
record, following its change history, checking capture coverage, and reviewing
exports and retention, with no asset build step. Mounting is fail-closed:
the host supplies authentication and authorization, and must declare the
optional Phoenix surface dependencies. The Threadline UI currently ships as an
optional in-tree dependency; the [Threadline Admin guide](guides/operator-surface.md)
is the sole owner for the supported `threadline_operator_surface/2` mount,
authentication callbacks, screen inventory, and mount-specific configuration.
The [Upgrade Path](guides/upgrade-path.md) owns its support guarantees.

Dark is the default. The header offers Dark, Light, and System preferences
through a native form. Hosts can mount with `theme: :system` to follow the
operator's OS light/dark preference through CSS; see the
[Threadline Admin guide](guides/operator-surface.md#theme) for the full
`:dark | :light | :system` triad.

Continue with the [canonical first-hour Phoenix walkthrough](guides/getting-started-saas.md),
then use the [Threadline Admin guide](guides/operator-surface.md) for fail-closed
authorization and the [integration contracts](guides/integration-contracts.md)
for host/framework boundaries. For current support claims, stay with the
[Upgrade Path](guides/upgrade-path.md) rather than inferring broader compatibility
from the README.

## Notes

- **Supported versions:** Elixir **1.15 floor / 1.17.3 current**, OTP **26 min / 27 current**, PostgreSQL **15 min / 16 current**. CI's `min` lane runs the full suite on Elixir 1.15 / OTP 26 / PostgreSQL 15; `current` and `latest` CI versions are in the [toolchain support policy table](guides/upgrade-path.md#toolchain-support-policy). The `latest` lane is **tested on**, not a new support floor.
- Threadline names four support lanes — the canonical `capture-only`, `phoenix-surface`, `phx-gen-auth-reference`, and `sigra-reference` matrix — in [guides/upgrade-path.md](guides/upgrade-path.md). Phoenix auth (reference lanes, pick one): [phx.gen.auth integration](guides/integrations/phx-gen-auth.md) · [Sigra integration](guides/integrations/sigra.md); neither is required.
- Threadline works with PgBouncer transaction pooling.
- Redaction drift uses three states: `Config matches deployed`, `Drift detected`, and `Could not introspect`; rerun `mix threadline.gen.triggers` if the latter two appear.
- Redaction, retention, export, and continuity live in the guides and HexDocs.
- Next operator reads after the first install are [guides/performance.md](guides/performance.md) and [guides/incident-playbook.md](guides/incident-playbook.md).

## Documentation

Quick destinations: [Evaluate](guides/evaluating-threadline.md) ·
[Adopt](guides/getting-started-saas.md) ·
[Operate](guides/operator-surface.md) ·
[Contribute](CONTRIBUTING.md)

<details>
<summary>All guides</summary>

- [HexDocs](https://hexdocs.pm/threadline) — the generated API reference.

**Evaluate**

- [How Threadline works](guides/how-threadline-works.md)
- [Code walkthrough](guides/code-walkthrough.md)
- [Evaluating Threadline](guides/evaluating-threadline.md)
- [Domain reference](guides/domain-reference.md)

**Adopt**

- [Getting started with Phoenix SaaS](guides/getting-started-saas.md)
- [Production checklist](guides/production-checklist.md)
- [Brownfield continuity](guides/brownfield-continuity.md)
- [Integration contracts](guides/integration-contracts.md)
- [Local Docker DX](guides/local-docker-dx.md)
- [Support lanes and upgrade path](guides/upgrade-path.md)
- [Upgrading to 0.11](guides/upgrading-to-0.11.md)

**Operate**

- [Threadline Admin](guides/operator-surface.md)
- [Incident playbook](guides/incident-playbook.md)
- [Performance](guides/performance.md)
- [Audit indexing](guides/audit-indexing.md)
- [Adoption evidence playbook](guides/adoption-evidence-playbook.md)
- [Telemetry](guides/telemetry.md)

**Integrations**

- [phx.gen.auth integration](guides/integrations/phx-gen-auth.md)
- [Sigra integration (reference lane)](guides/integrations/sigra.md)

**Contribute**

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [Adoption pilot backlog](guides/adoption-pilot-backlog.md)
- [CHANGELOG.md](CHANGELOG.md)

</details>
