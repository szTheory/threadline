# Changelog

## [Unreleased]

### Added

- **`guides/adoption-pilot-backlog.md`** — matrix aligned to the production checklist for host pilots, plus distribution preflight and prioritized issue rows.
- **Telemetry (operator reference)** — `[:threadline, …]` event table in **`guides/domain-reference.md`**, linked from **`guides/production-checklist.md`** observability section.

### Changed

- **README** — Documentation list includes the adoption pilot backlog; **ExDoc** extras include the new guide.

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
