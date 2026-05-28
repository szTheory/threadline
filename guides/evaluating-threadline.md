# Evaluating Threadline

## Who this is for

This guide is for a **technical evaluator** or **pilot host** deciding whether Threadline fits a Phoenix + Ecto + PostgreSQL stack. It summarizes what maintainers prove in-repo and what **you** must prove in staging or production-like environments.

It is **not** a compliance procurement sign-off or legal attestation of your environment.

## What Threadline 0.6.0 packages

Threadline **0.6.0** is the in-repo and doc SSOT (`mix.exs` `@version`). As of 2026-05-27, [hex.pm](https://hex.pm/packages/threadline) may still list **0.5.0** as latest until maintainers push tag **`v0.6.0`** (see [`guides/adoption-pilot-backlog.md`](adoption-pilot-backlog.md) Distribution preflight).

0.6.0 packages Evidence, `Audit.transaction/3`, and aligned operator surfaces that landed in-repo after **0.5.0**; upgrade steps are semver-scoped in `CHANGELOG.md` and this guide.

Read [`CHANGELOG.md`](../CHANGELOG.md) `[0.6.0]` for the Evidence plane (`Threadline.Evidence`, proof vocabulary, `/audit/evidence`), the blessed audited write path (`Threadline.Audit.transaction/3`), and operator/demo surfaces from the reference walkthrough.

## Three layers (mental model)

Threadline separates concerns into three layers:

- **Capture** — PostgreSQL trigger-backed row mutations (`AuditTransaction`, `AuditChange`).
- **Semantics** — application-level actions binding actor, intent, correlation, and request/job context (`AuditAction`, `ActorRef`).
- **Exploration** — timelines, exports, retention, redaction, and operator surfaces for investigation.

See [`guides/how-threadline-works.md`](how-threadline-works.md) for the full architecture narrative.

## What maintainers prove in-repo (CI-class)

Maintainers exercise the library through named **`mix verify.*`** entrypoints and integration tests — **not** by citing ExUnit test counts as proof.

In-repo evidence includes:

- **Trigger capture** and semantics APIs under `test/threadline/`.
- **Evidence plane** vocabulary, `Threadline.Evidence`, and `mix threadline.evidence.show`.
- **`mix verify.*` ladder** and **`mix verify.doc_contract`** — doc-contract tests lock public prose to code.
- **PgBouncer transaction-mode class** via **`verify-pgbouncer-topology`** (`mix verify.topology`, `mix verify.threadline` through a transaction pooler).
- **Reference app CI-class HTTP paths** via `mix verify.example` (`examples/threadline_phoenix`).

## What integrators must prove (host-class)

Threadline does not operate your staging stack. **Host-owned** evidence covers:

- **Auth and tenancy** — who may read audit data in your app.
- **Production or staging topology** — app → pooler → Postgres chain, pool mode, and Ecto pool settings matching how you run.
- **Your HTTP and Oban (or job) audited paths** — routes and workers that perform audited writes in *your* deployment.
- **Backups / PITR vs retention** and **redaction policy review** — operational choices outside library CI.

Use [`guides/production-checklist.md`](production-checklist.md) for the checklist shape. For how maintainers accept **short in-repo indexes** (tables, redacted links) without vouching for third-party environments, read [`CONTRIBUTING.md`](../CONTRIBUTING.md) § Host STG evidence.

## How to verify (evaluator ladder)

1. **`mix deps.get`** — resolve dependencies from the tree you are evaluating.
2. **Full contributor gate** — `DB_PORT=5433 MIX_ENV=test mix ci.all` when Postgres is available (see [`CONTRIBUTING.md`](../CONTRIBUTING.md) for Compose port `5433` and env setup). The chain runs: `mix verify.format` → `mix verify.credo` → `mix compile --warnings-as-errors` → `mix verify.compile_no_optional` → `mix verify.test` → `mix verify.threadline` → `mix verify.example` → `mix verify.doc_contract`.
3. **Targeted checks** — `mix verify.doc_contract` and/or `mix verify.example` when you only need doc or reference-app proof.
4. **Optional Track A (sigra-reference)** — walk `examples/threadline_phoenix` per its README and walkthrough docs.

Cite **entrypoint names only** when recording evidence — do not substitute test counts for proof.

## Explicit non-claims

Threadline is:

- **Not** a SIEM or generic security analytics product.
- **Not** a compliance platform, legal hold system, or immutable archive beyond your host runtime/storage contract.
- **Not** a Threadline-owned RBAC or tenancy DSL — authorization stays in your app.
- **Not** a claim that Threadline maintainers have validated your staging topology — maintainers prove CI-class library paths; integrators own STG realism for HTTP and job paths.

## Pilot next step

When you are ready to run a staging pilot, copy the scaffolds in [`guides/adoption-pilot-backlog.md`](adoption-pilot-backlog.md):

- **`STG-HOST-TOPOLOGY-TEMPLATE`** — one row per environment (pooler chain, pool mode, sandbox note, evidence link).
- **`STG-AUDITED-PATH-RUBRIC`** — HTTP and job paths with OK / Issue / N/A / Not run and reproducible pointers.

Fill templates in **your** repo or fork; open a modest PR if you want a short in-repo index merged here. Maintainers review **modesty**, **redaction**, and **link hygiene** only.

For lane and upgrade narrative, read [`guides/upgrade-path.md`](upgrade-path.md). For the `phx-gen-auth-reference` lane, read [`guides/integrations/phx-gen-auth.md`](integrations/phx-gen-auth.md). **You** prove auth and tenancy in staging; maintainers prove the phx.gen.auth reference path via root integration tests and the Sigra reference path via `mix verify.example` — neither auth integration is required to adopt Threadline capture and semantics.
