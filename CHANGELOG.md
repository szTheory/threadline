# Changelog

## [Unreleased]

## [0.4.0] - 2026-05-06

Threadline 0.4.0 is the operator-surface foundation release: an opt-in web UI ships behind optional Phoenix/LiveView/HTML/PubSub deps so capture-only adopters keep zero new transitive bloat, the timeline / export query and Mix-task surface gains a `:correlation_id` filter that walks `audit_actions.correlation_id` via the action linkage, and exports learn an opt-in action-metadata pair (JSON `action` object, CSV `include_action_metadata: true`) so incident-response tooling can correlate rows back to the action that produced them — all without changing the default column order or breaking pre-0.4 callers.

### Added

- **Operator Surface** — introduces an opt-in web UI via `Threadline.OperatorSurface.Router`. `phoenix`, `phoenix_live_view`, `phoenix_html`, and `phoenix_pubsub` are now declared as `optional: true` dependencies, meaning zero bloat for capture-only adopters. Hosts that want the UI must add these dependencies to their `mix.exs` and use the `threadline_operator_surface` mount macro in their router.
- **`examples/threadline_phoenix`** — **`audit_transaction_id`** on **`POST /api/posts`** and **`GET /api/audit_transactions/:id/changes`** returning ordered changes with **`change_diff`** maps per row (composition demo; add auth in production). **`guides/domain-reference.md`** documents the pattern under **COMP-EXAMPLE-INCIDENT-JSON**.
- **`:correlation_id` timeline / export filter** — optional keyword on `Threadline.Query.timeline/2`,
  `timeline_query/1`, `export_changes_query/1`, and export entrypoints. Values are trimmed; empty
  after trim, `nil`, non-binary, or longer than **256 UTF-8 bytes** raise `ArgumentError`. When set,
  only `audit_changes` whose transaction has a matching `audit_actions.correlation_id` (via
  `action_id`) are returned (inner join; omit the key for previous behavior). See `Threadline.Query`
  moduledoc for full rules.
- **Export JSON `action` object** — each change may include `"action": {"id", "correlation_id"}`
  when the transaction is linked to an `audit_actions` row.
- **Export CSV `include_action_metadata: true`** — opt-in trailing columns `correlation_id` and
  `action_id`; default CSV column order is unchanged.
- **`guides/adoption-pilot-backlog.md`** — matrix aligned to the production checklist for host pilots, plus distribution preflight and prioritized issue rows.
- **Telemetry (operator reference)** — `[:threadline, …]` event table in **`guides/domain-reference.md`**, linked from **`guides/production-checklist.md`** observability section.

### Changed

- **README** — Documentation list includes the adoption pilot backlog; **ExDoc** extras include the new guide.

## [0.3.0] - 2026-05-05

Threadline 0.3.0 is the drop-in production adoption release for Phoenix SaaS teams: the release packages the first-hour SaaS onboarding path, Sigra-ready actor capture, operator incident guidance, and published capture baselines into one taggable Hex surface.

### Added

- **SaaS onboarding route** — [`guides/getting-started-saas.md`](guides/getting-started-saas.md) ships as the first-hour Phoenix SaaS path and is now promoted from the package front door.
- **Sigra integration route** — [`guides/integrations/sigra.md`](guides/integrations/sigra.md) ships as the best-supported auth bridge for Sigra-backed Phoenix hosts and is surfaced separately in ExDoc navigation.
- **Published capture baselines** — the cold-single-table benchmark now anchors the release story with `insert` at `4.87 K` IPS / `205.13 µs`, `update` at `4.30 K` IPS / `232.49 µs`, and `delete` at `7.61 K` IPS / `131.39 µs`.
- **Release-surface contract** — `test/threadline/release_artifact_contract_test.exs` locks package files, ExDoc extras/module grouping, guide presence on disk, and release-only README / maintainer literals.

### Changed

- **README install and routing** — the install snippet now targets `{:threadline, "~> 0.3"}` and sends new adopters first to the SaaS quickstart and Sigra guide, with performance and incident docs one step deeper.
- **ExDoc information architecture** — `guides/integrations/sigra.md` now matches an `Integrations` extras group before the broader reference bucket, and `Threadline.Integrations.Sigra` now appears under a new plural `Integrations` module group while Plug / Job / Health / Continuity / Telemetry remain under the singular `Integration` group.
- **Release pre-flight** — `mix verify.release` now validates the exact taggable tree through release metadata checks, pure file-read release contracts, `MIX_ENV=dev mix docs`, and `mix hex.build`.
- **Maintainer publish runbook** — `CONTRIBUTING.md` now documents the `mix verify.release` pre-flight and the `main` CI wait before tagging `v0.3.0`.

### Deprecated

- No runtime API is deprecated in 0.3.0. Older install snippets using `{:threadline, "~> 0.2"}` should be treated as stale documentation, not a supported release target.

### Breaking

- No breaking runtime, dependency, config, or schema changes are introduced in 0.3.0.

### Upgrade from 0.2.x

- **Dependencies:** no runtime dependency changes are required to adopt 0.3.0.
- **Config changes:** none.
- **Migration steps:** none beyond bumping the dependency and re-running your normal dependency fetch/docs sync flow.
- **Sigra adapter:** use `Threadline.Integrations.Sigra.actor_ref_from_conn/1` as the `Threadline.Plug` `actor_fn` when your host already authenticates requests with Sigra.

## [0.2.0] - 2026-04-23

### Added

- **Production checklist** — [`guides/production-checklist.md`](guides/production-checklist.md) for first-week production review (capture, redaction, retention, export, observability, brownfield).
- **`Threadline.Query.timeline_repo!/2`** — resolves `:repo` from filters or opts with clear `ArgumentError` messages for timeline and export callers.
- **ExDoc** — `guides/production-checklist.md` in extras; **`Threadline.Retention`** and **`Threadline.Retention.Policy`** listed under Core API module groups.

### Changed

- **Timeline filter errors** — `validate_timeline_filters!/1` messages now point at allowed keys and `Threadline.Export`.
- **Validation order** — `timeline/2` and export entrypoints validate filter keys before resolving `:repo`, so unknown keys surface before a missing-repo error.

### Release notes (capabilities since 0.1.0)

This minor release documents and packages capabilities shipped across the **v1.1–v1.3** planning cycles that were not fully reflected in the **0.1.0** changelog entry:

- **Before-values** — optional `changed_from` on UPDATE when triggers are generated with `--store-changed-from`; `Threadline.history/3` loads the column when present.
- **Verify coverage & doc contracts** — `mix threadline.verify_coverage`, CI `verify.threadline` / `verify.doc_contract`, README fixture contracts.
- **Brownfield continuity** — `Threadline.Continuity`, `mix threadline.continuity`, [`guides/brownfield-continuity.md`](guides/brownfield-continuity.md).
- **Redaction at capture** — `config :threadline, :trigger_capture`, per-table `exclude` / `mask`, codegen validation.
- **Retention** — `Threadline.Retention.Policy`, `Threadline.Retention.purge/1`, `mix threadline.retention.purge`.
- **Export** — `Threadline.Export`, `Threadline.export_csv/2`, `Threadline.export_json/2`, `mix threadline.export`, shared timeline filter validation.

## [0.1.0] - 2026-04-23

### Added

- `Threadline` core API plus `Threadline.Semantics.ActorRef` and `Threadline.Semantics.AuditContext` for attributing writes to actors in audit context.
- `Threadline.Plug` for resolving `ActorRef` from `Plug.Conn`, plus integration modules `Threadline.Job`, `Threadline.Health`, and `Threadline.Telemetry`.
- `Threadline.Semantics.AuditAction` and `Threadline.Capture` schemas (`AuditTransaction`, `AuditChange`) for PostgreSQL trigger-backed row-change capture.
- Mix tasks `Mix.Tasks.Threadline.Install` and `Mix.Tasks.Threadline.Gen.Triggers` to generate migrations and table-specific audit triggers.
