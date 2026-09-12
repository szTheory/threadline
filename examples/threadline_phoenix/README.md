# ThreadlinePhoenix

ThreadlinePhoenix is the maintained, repository-only proof that Threadline can
compose with a Phoenix host, Ecto, PostgreSQL, and Sigra. It is not a second
installation guide. Adopters use the canonical guides below; maintainers use
this page to find the source and automated evidence behind the example.

This app is the current `sigra-reference` lane. It proves the narrow first-party
composition shipped in this repository without claiming that arbitrary Sigra
versions, auth layouts, or non-Phoenix hosts work automatically.

## Before you use the example

- **Audience:** adopters evaluating the reference integration and maintainers
  checking its proof.
- **Outcome:** trace each public claim to the source and test that exercises it.
- **Prerequisites:** a supported Elixir/OTP toolchain and PostgreSQL; the
  canonical procedure explains when each is needed.
- **Safety boundary:** the host owns authentication, authorization, tenancy,
  and database access. Do not copy demo credentials or maintainer-only routes
  into production.

The example resolves Threadline from the repository with
`{:threadline, path: "../.."}` and declares `{:phoenix, "~> 1.8.5"}` plus
`{:sigra, "~> 0.2"}`. The exact dependency declarations remain authoritative in
[`mix.exs`](mix.exs), and the resolved dependency set lives in
[`mix.lock`](mix.lock).

## Follow the canonical procedure

Use the guide for the job in front of you:

| Job | Canonical owner | What you get |
| --- | --- | --- |
| Install Threadline and reach one captured write | [Getting Started — prerequisites](../../guides/getting-started-saas.md#1-prerequisites) | The complete first-hour path from package dependency through capture and query verification |
| Mount and authorize the operator console | [Operator Surface — 1-Minute Mount](../../guides/operator-surface.md#1-minute-mount) | The supported router, authorization, screen, and configuration contract |
| Run the local demo or test database with Docker | [Local Docker DX — Try the UI demo](../../guides/local-docker-dx.md#try-the-ui-demo) | Lifecycle, ports, cleanup, and troubleshooting |

For the exhaustive supported application settings and command boundaries, use
the [configuration and command reference](../../guides/configuration-and-commands.md).
This README intentionally does not repeat any of those ordered procedures.

## What the example proves

### Audited Phoenix writes

The API pipeline in
[`router.ex`](lib/threadline_phoenix_web/router.ex) wires the direct
`Threadline.Integrations.Sigra.actor_ref_from_conn/1` and
`Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1` callback
pair into `Threadline.Plug`. The callbacks are soft-loaded and host-owned; the
example does not teach an app-local delegate seam.

[`blog.ex`](lib/threadline_phoenix/blog.ex) uses
`Threadline.Audit.transaction/3` for the audited write. The automated proof
checks capture, actor context, correlation, and the returned transaction id:

- [`posts_audit_path_test.exs`](test/threadline_phoenix_web/posts_audit_path_test.exs)
- [`posts_correlation_path_test.exs`](test/threadline_phoenix_web/posts_correlation_path_test.exs)
- [`track_a_golden_path_test.exs`](test/threadline_phoenix_web/track_a_golden_path_test.exs)

The example deliberately does not ship API bearer authentication. Its
browser-session path stages Sigra `current_scope` before `Threadline.Plug`;
production hosts should reject unauthenticated requests at their own boundary.

### Incident and historical investigation

Successful audited writes return an `audit_transaction_id`. The incident JSON
route renders the curated result from `Threadline.incident_bundle/2` and
requires an authenticated actor before serving it. Hosts still need their own
tenancy and policy checks.

The corresponding proof lives in
[`posts_incident_json_path_test.exs`](test/threadline_phoenix_web/posts_incident_json_path_test.exs).
Historical reconstruction and explicit `:deleted_record` /
`:before_audit_horizon` outcomes are exercised by the example's focused
history and incident tests, while the public API contract stays in the
[domain reference](../../guides/domain-reference.md).

### Mounted operator boundary

The operator scope in
[`router.ex`](lib/threadline_phoenix_web/router.ex) demonstrates one secured
`/audit` tree with host-owned actor, authorization, export, evidence, coverage,
policy, and query-scope callbacks. Admin and support roles share the mount while
support access remains scoped and export/evidence access remains separately
deniable.

[`operator_surface_test.exs`](test/threadline_phoenix_web/operator_surface_test.exs)
checks the mounted behavior. PhoenixStorybook and `/audit/__stress` remain
maintainer-only review tools. Neither is a production route or a public
component API, and host apps do not install `phoenix_storybook` to use
Threadline.

## Maintainer proof surfaces

The reference app's detailed maintainer walk is
[`WALKTHROUGH.md`](WALKTHROUGH.md). Its stable fiction and user roles are
documented in [`DEMO-MANIFEST.md`](DEMO-MANIFEST.md) and
[`DEMO_USERS.md`](DEMO_USERS.md). Those files describe repository verification;
they are not adopter setup instructions.

The end-to-end walkthrough has three named ConnCase proofs:

- [`walkthrough_happy_path_test.exs`](test/threadline_phoenix_web/walkthrough_happy_path_test.exs)
- [`walkthrough_evidence_test.exs`](test/threadline_phoenix_web/walkthrough_evidence_test.exs)
- [`track_a_golden_path_test.exs`](test/threadline_phoenix_web/track_a_golden_path_test.exs)

Use the [adoption evidence playbook](../../guides/adoption-evidence-playbook.md)
to understand what these repository proofs establish and what a real adopter
must still validate in staging.

## Learn more

- [Getting Started](../../guides/getting-started-saas.md)
- [Operator Surface](../../guides/operator-surface.md)
- [Local Docker DX](../../guides/local-docker-dx.md)
- [Integration contracts](../../guides/integration-contracts.md)
- [Sigra integration](../../guides/integrations/sigra.md)
- [Production checklist](../../guides/production-checklist.md)
