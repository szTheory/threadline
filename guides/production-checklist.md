# Production checklist (Threadline)

Use this after the [README quickstart](../README.md#quick-start) and before treating audit capture as production-ready. It complements [`brownfield-continuity.md`](brownfield-continuity.md) for existing data.

For **host staging / pooler parity** (**STG-01**–**STG-03**), use **[`guides/adoption-pilot-backlog.md`](adoption-pilot-backlog.md)** as the in-repo matrix and rubric: fixed-field topology (`STG-HOST-TOPOLOGY-TEMPLATE`) plus audited HTTP/job paths with honest status columns under **`STG-AUDITED-PATH-RUBRIC`**. Copy rows into issues when something fails; keep evidence pointers **redacted** and link out to integrator-controlled detail.

## 1. Capture and triggers

- [ ] `mix threadline.install` and `mix threadline.gen.triggers` migrations applied in the target environment.
- [ ] `MIX_ENV` matches between trigger regeneration and runtime (`mix threadline.gen.triggers` loads `app.config`).
- [ ] `config :threadline, :verify_coverage, expected_tables: [...]` lists every audited table; `mix threadline.verify_coverage` passes in CI and on a production-like host.
- [ ] `Threadline.Health.trigger_coverage/1` is wired into health checks or release checks where you need fast failure on drift.

## 2. Actor bridge and semantics

- [ ] Request paths set `threadline.actor_ref` inside the **same** `Ecto.Multi` / `Repo.transaction` as audited writes (transaction-local GUC; safe under PgBouncer transaction pooling — see README **PgBouncer** section).
- [ ] Background jobs use `Threadline.Job` (or equivalent) so jobs and HTTP requests both attribute actors consistently.
- [ ] Where you need intent beyond row diffs, `Threadline.record_action/2` is called with `:repo` and a valid `ActorRef`.

## 3. Redaction and sensitive columns

- [ ] `config :threadline, :trigger_capture, tables: %{"users" => [exclude: ..., mask: ...]}` reviewed with security; no column in both `exclude` and `mask`.
- [ ] `mix threadline.gen.triggers --dry-run` used after config changes; migrations applied before relying on new trigger SQL.
- [ ] JSON/JSONB columns: remember masking replaces the **whole** value (no field-level redaction in current releases).

## 4. Retention and purge

- [ ] `config :threadline, :retention` validated (`keep_days` **or** `max_age_seconds`, not both; positive window).
- [ ] **Destructive purge** only with `enabled: true` after ops sign-off; always `mix threadline.retention.purge --dry-run` first.
- [ ] Production: `MIX_ENV=prod mix threadline.retention.purge --execute` (requires explicit `--execute`).
- [ ] Batch size and `max_batches` tuned so each run finishes under lock/latency budgets; schedule often enough that volume per run stays bounded.
- [ ] Backups / point-in-time recovery: purges are **permanent** deletes of `audit_changes` (and optionally empty `audit_transactions`); align retention with compliance needs.

## 5. Export and investigation

- [ ] Exports use the same filter keys as `Threadline.timeline/2` (`:repo`, `:table`, `:actor_ref`, `:from`, `:to` only). Unknown keys raise `ArgumentError` with a message pointing at `Threadline.Query`.
- [ ] Large exports: respect default `max_rows` and `truncated` metadata, or use `Threadline.Export.stream_changes/2` with `Stream.take/2` intentionally.

## 6. Observability

- [ ] `:telemetry` handlers for Threadline events are attached where you need metrics or logs. Event names and measurements: [`domain-reference.md` — Telemetry](domain-reference.md#telemetry-operator-reference).
- [ ] Retention purge logs (`threadline retention purge batch`, etc.) visible to operators when purge runs.

## 7. Brownfield and continuity

- [ ] If tables already had rows before capture: read [`brownfield-continuity.md`](brownfield-continuity.md); run `mix threadline.continuity` where applicable; document the honest “gap until first audited write” for stakeholders.

## See also

- [Adoption pilot backlog](adoption-pilot-backlog.md) — matrix to run this checklist in a real environment and file issues with evidence.
- [Domain reference](domain-reference.md) — schema, retention semantics, export behavior.
- [HexDocs](https://hexdocs.pm/threadline) — `Threadline`, `Threadline.Export`, `Threadline.Retention`, `Threadline.Query`.
