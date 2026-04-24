# Production checklist (Threadline)

Use this after the [README quickstart](../README.md#quick-start) and before treating audit capture as production-ready. It complements [`brownfield-continuity.md`](brownfield-continuity.md) for existing data.

For **host staging / pooler parity** (**STG-01**–**STG-03**), use **[`guides/adoption-pilot-backlog.md`](adoption-pilot-backlog.md)** as the in-repo matrix and rubric: fixed-field topology (`STG-HOST-TOPOLOGY-TEMPLATE`) plus audited HTTP/job paths with honest status columns under **`STG-AUDITED-PATH-RUBRIC`**. Copy rows into issues when something fails; keep evidence pointers **redacted** and link out to integrator-controlled detail.

## 1. Capture and triggers

- [ ] `mix threadline.install` and `mix threadline.gen.triggers` migrations applied in the target environment.
- [ ] `MIX_ENV` matches between trigger regeneration and runtime (`mix threadline.gen.triggers` loads `app.config`).
- [ ] `config :threadline, :verify_coverage, expected_tables: [...]` lists every audited table; `mix threadline.verify_coverage` passes in CI and on a production-like host.
- [ ] Run `Threadline.Health.trigger_coverage/1` after deploys, schema changes, and on a periodic cadence you trust; each `{:covered, _}` / `{:uncovered, _}` tuple names one **public** user table from the same catalog `verify_coverage` reads — full interpretation: [`domain-reference.md#trigger-coverage-operational`](domain-reference.md#trigger-coverage-operational).
- [ ] `mix threadline.verify_coverage` only fails CI when an **`expected_tables`** name is missing triggers or uncovered; `{:uncovered, _}` on other tables is informational. Audit catalog tables **`audit_transactions`**, **`audit_changes`**, and **`audit_actions`** are excluded from `Health`’s per-table list by design (same link).
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
- [ ] Index strategy for audit tables (baseline vs optional btree/GIN) reviewed with your DBA path; see **[`audit-indexing.md`](audit-indexing.md)** for shipped index names, timeline/export join semantics, and evidence-first additive patterns.

## 5. Export and investigation

- [ ] Exports use the same filter keys as `Threadline.timeline/2` (`:repo`, `:table`, `:actor_ref`, `:from`, `:to`, `:correlation_id` only). Unknown keys raise `ArgumentError` with a message pointing at `Threadline.Query`.
- [ ] Large exports: respect default `max_rows` and `truncated` metadata, or use `Threadline.Export.stream_changes/2` with `Stream.take/2` intentionally.

## 6. Observability

- [ ] `:telemetry` handlers for Threadline events are attached where you need metrics or logs. Event names and measurements: [`domain-reference.md` — Telemetry](domain-reference.md#telemetry-operator-reference); per-event narrative and how health counts relate to coverage checks: [`domain-reference.md#trigger-coverage-operational`](domain-reference.md#trigger-coverage-operational).
- [ ] Retention purge logs (`threadline retention purge batch`, etc.) visible to operators when purge runs.

## 7. Brownfield and continuity

- [ ] If tables already had rows before capture: read [`brownfield-continuity.md`](brownfield-continuity.md); run `mix threadline.continuity` where applicable; document the honest “gap until first audited write” for stakeholders.

## Support incident queries

Pre-launch: confirm operators can answer the five canonical support questions (see [`domain-reference.md`](domain-reference.md#support-incident-queries) for full SQL and API notes).

| Question (1-line) | API / Mix | SQL |
|-------------------|-----------|-----|
| 1. Row history — PK in a time window | `Threadline.history/3`, `Threadline.Query.timeline/2` | [Golden query](domain-reference.md#1-row-history-pk-changes-in-a-time-window) in domain reference |
| 2. Actor window — one actor across tables | `Threadline.actor_history/2`, `timeline/2` + `:actor_ref` | [Golden query](domain-reference.md#2-actor-window-one-actor-across-tables) |
| 3. Correlation bundle — shared `correlation_id` | `timeline/2`, `mix threadline.export` + `:correlation_id` | [Inner-join SQL + strict semantics](domain-reference.md#3-correlation-bundle-shared-correlation_id) |
| 4. Export parity — same filters as timeline | `Threadline.Export`, `mix threadline.export` | [Filter vocabulary](domain-reference.md#4-export-parity-timeline-and-export-filters-agree) |
| 5. Action ↔ capture — link semantics to rows | `Threadline.record_action/2`, `action_id` | [Join pattern](domain-reference.md#5-action-and-capture-link-semantic-actions-to-changes) |

- [ ] **Q1 — Row history:** Read [row history playbook](domain-reference.md#1-row-history-pk-changes-in-a-time-window) (`audit_changes`, `audit_transactions`, bounded `captured_at`).
- [ ] **Q2 — Actor window:** Read [actor window playbook](domain-reference.md#2-actor-window-one-actor-across-tables) (`actor_ref` JSON, time bounds).
- [ ] **Q3 — Correlation:** Read [correlation bundle playbook](domain-reference.md#3-correlation-bundle-shared-correlation_id) — with `:correlation_id`, timeline/export return only changes whose transaction **inner-joins** an `audit_actions` row with that correlation (no orphan capture rows).
- [ ] **Q4 — Export parity:** Read [export parity notes](domain-reference.md#4-export-parity-timeline-and-export-filters-agree) — same keys as `Threadline.Query.timeline/2`.
- [ ] **Q5 — Action ↔ capture:** Read [action/capture join](domain-reference.md#5-action-and-capture-link-semantic-actions-to-changes) (`audit_actions`, `action_id`, `audit_changes`).

## See also

- [Adoption pilot backlog](adoption-pilot-backlog.md) — matrix to run this checklist in a real environment and file issues with evidence.
- [Domain reference](domain-reference.md) — schema, retention semantics, export behavior.
- [HexDocs](https://hexdocs.pm/threadline) — `Threadline`, `Threadline.Export`, `Threadline.Retention`, `Threadline.Query`.
