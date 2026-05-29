# Production checklist (Threadline)

Use this after the [README quickstart](../README.md#quick-start) and before treating audit capture as production-ready. It complements [`brownfield-continuity.md`](brownfield-continuity.md) for existing data.

For **host staging / pooler parity** (**STG-01**–**STG-03**), use **[`guides/adoption-pilot-backlog.md`](adoption-pilot-backlog.md)** as the in-repo matrix and rubric: fixed-field topology (`STG-HOST-TOPOLOGY-TEMPLATE`) plus audited HTTP/job paths with honest status columns under **`STG-AUDITED-PATH-RUBRIC`**. Copy rows into issues when something fails; keep evidence pointers **redacted** and link out to integrator-controlled detail.

## Host repo wiring (prerequisite)

- [ ] `config :threadline, ecto_repos: [MyApp.Repo]` is set in `config/config.exs` ([getting-started §2 — Configure Threadline](getting-started-saas.md#configure-threadline)). Required for all `mix threadline.*` tasks that call `resolve_repo!/0` and for operator-surface Mix fallbacks when LiveView is denied or not mounted.
- [ ] **Multi-database hosts:** list only the repo that holds audit tables **first** in `:ecto_repos`; do not mirror your full host `:ecto_repos` list unless the first entry is the audit database. Pass `repo:` on mount and on programmatic APIs when using a non-default repo.

## 1. Capture and triggers

- [ ] `mix threadline.install` and `mix threadline.gen.triggers` migrations applied in the target environment.
- [ ] `MIX_ENV` matches between trigger regeneration and runtime (`mix threadline.gen.triggers` loads `app.config`).
- [ ] `config :threadline, :verify_coverage, expected_tables: [...]` lists every audited table; `mix threadline.verify_coverage` passes in CI and on a production-like host.
- [ ] Run `Threadline.Health.trigger_coverage/1` after deploys, schema changes, and on a periodic cadence you trust; each `{:covered, _}` / `{:uncovered, _}` tuple names one **public** user table from the same catalog `verify_coverage` reads — full interpretation: [`domain-reference.md#trigger-coverage-operational`](domain-reference.md#trigger-coverage-operational).
- [ ] `mix threadline.verify_coverage` only fails CI when an **`expected_tables`** name is missing triggers or uncovered; `{:uncovered, _}` on other tables is informational. Audit catalog tables **`audit_transactions`**, **`audit_changes`**, and **`audit_actions`** are excluded from `Health`’s per-table list by design (same link).
- [ ] `Threadline.Health.trigger_coverage/1` is wired into health checks or release checks where you need fast failure on drift.

## Coverage drift visibility

Threadline's strongest production posture comes from making coverage drift impossible to miss. After mounting the operator surface and configuring triggers, verify:

- [ ] **Surface header pill renders on every LV** — visit any operator-surface page and confirm the badge shows either "All covered" (green-muted) or "{N} uncovered" (amber). The badge link goes to `/audit/coverage`.
- [ ] **Coverage dashboard responds at `/audit/coverage`** — the page renders three buckets (covered / uncovered / expected) with a 30-second polling default.
- [ ] **Mix-task parity for capture-only paths** — `mix threadline.health.coverage` prints the same data; `mix threadline.health.coverage --json` for machine consumption.
- [ ] **Adopter-declared expected-uncovered set** — if you use Oban, vendor add-ons, or non-Threadline bookkeeping tables, declare them in `config :threadline, :health, expected_uncovered_tables: [...]`. Run `Threadline.Health.Policy.validate!/1` at boot to fail loudly on typos.
- [ ] **Telemetry alert on failure** — subscribe to `[:threadline, :health, :checked, :error]` so sustained polling failures (e.g. DB connection issues) page someone instead of silently freezing the dashboard at the last-good count.

See also `guides/operator-surface.md` §"Coverage dashboard".

## 2. Actor bridge and semantics

- [ ] Request paths set `threadline.actor_ref` inside the **same** `Ecto.Multi` / `Repo.transaction` as audited writes (transaction-local GUC; safe under PgBouncer transaction pooling — see README **PgBouncer** section).
- [ ] Background jobs use `Threadline.Job` (or equivalent) so jobs and HTTP requests both attribute actors consistently.
- [ ] Where you need intent beyond row diffs, `Threadline.record_action/2` is called with `:repo` and a valid `ActorRef`.

## 3. Redaction and sensitive columns

- [ ] `config :threadline, :trigger_capture, tables: %{"users" => [exclude: ..., mask: ...]}` reviewed with security; no column in both `exclude` and `mask`.
- [ ] `mix threadline.gen.triggers --dry-run` used after config changes; migrations applied before relying on new trigger SQL.
- [ ] Visit `/audit/policy/redaction` after deploys or config changes; confirm the affected tables land in `Config matches deployed`, not `Drift detected` or `Could not introspect`.
- [ ] Capture-only path checked too: `mix threadline.policy.show` for human output, `mix threadline.policy.show --json` for machine checks or incident tooling.
- [ ] If any table shows `Drift detected` or `Could not introspect`, rerun `mix threadline.gen.triggers`, apply the generated migration, and re-check before declaring the rollout aligned.
- [ ] Confirm the redaction viewer stays safe for operator screenshots and incident notes: it should show only column names and placeholder metadata, never sample values.
- [ ] JSON/JSONB columns: remember masking replaces the **whole** value (no field-level redaction in current releases).

## 4. Retention and purge

- [ ] `config :threadline, :retention` validated (`keep_days` **or** `max_age_seconds`, not both; positive window).
- [ ] **Destructive purge** only with `enabled: true` after ops sign-off; always `mix threadline.retention.purge --dry-run` first.
- [ ] Production: `MIX_ENV=prod mix threadline.retention.purge --execute` (requires explicit `--execute`).
- [ ] Batch size and `max_batches` tuned so each run finishes under lock/latency budgets; schedule often enough that volume per run stays bounded.
- [ ] Backups / point-in-time recovery: purges are **permanent** deletes of `audit_changes` (and optionally empty `audit_transactions`); align retention with compliance needs.
- [ ] Index strategy for audit tables (baseline vs optional btree/GIN) reviewed with your DBA path; see **[`audit-indexing.md`](audit-indexing.md)** for shipped index names, timeline/export join semantics, and evidence-first additive patterns.

### Volume, growth, and purge cadence

- Treat **`audit_changes`** (and related storage) as a **monotonically growing** dataset until retention runs; chart table size and free space alongside application traffic so growth surprises surface before purge latency spikes.
- **Schedule purges often enough** that each run finishes well inside the configured **`max_batches`** outer loop — if you routinely hit the cap, eligible rows remain until the next run; lowering per-pass volume (smaller **`--batch-size`** / `batch_size`) or running more frequently is safer than silently leaving a long tail of old rows.
- Start **`batch_size`** near **500** (the `Threadline.Retention.purge/1` default), then adjust with **lock wait**, **statement duration**, and **capture concurrency** in mind; the Mix task maps **`--batch-size`** / **`--max-batches`** to the same options.
- **`Threadline.Retention.Policy`** is the validated view of **`config :threadline, :retention`**; call **`Threadline.Retention.purge/1`** with a required **`repo:`** keyword (and optional `dry_run:`, `batch_size`, `max_batches`, `cutoff:`) from automation, or use **`mix threadline.retention.purge`**: always **`--dry-run`** first, then production **`MIX_ENV=prod mix threadline.retention.purge --execute`** only after ops sign-off — until **`enabled: true`**, programmatic calls return **`{:error, :disabled}`** and the Mix task raises.
- **Monitor each run:** Mix and library logs include batch indices and cumulative **`deleted_changes`** (and empty-transaction counts when applicable); track **wall-clock duration per run** and whether the final summary shows unused **`max_batches`** headroom.
- Cutoff clock, orphan **`audit_transactions`**, and empty-parent semantics stay in **[`domain-reference.md` — Retention](domain-reference.md#retention)** — do not fork a second spec in this checklist.

## 5. Export and investigation

Confirm [Host repo wiring (prerequisite)](#host-repo-wiring-prerequisite) before running export or evidence Mix tasks in CI.

- [ ] Exports use the same filter keys as `Threadline.timeline/2` (`:repo`, `:table`, `:actor_ref`, `:from`, `:to`, `:correlation_id` only). Unknown keys raise `ArgumentError` with a message pointing at `Threadline.Query`.
- [ ] Large exports: respect default `max_rows` and `truncated` metadata, or use `Threadline.Export.stream_changes/2` with `Stream.take/2` intentionally.
- [ ] **Retention vs filters:** `Threadline.timeline/2`, **`mix threadline.export`**, and correlation-heavy playbooks only return rows that **still exist** after your purge windows — align **`:from` / `:to`**, **`max_rows`**, streaming (`Threadline.Export.stream_changes/2`), and **`:correlation_id`** investigations with the policy in **[§4 Retention and purge](#4-retention-and-purge)**; export behavior details live in **[`domain-reference.md` — Export](domain-reference.md#export)**.
- [ ] **Operator Surface:** If you mount the LiveView operator UI, ensure it is protected behind an authenticated admin pipeline with a strict `:authorize_fn` policy. See the [Operator Surface guide](operator-surface.md) for fail-closed requirements.
- [ ] **Policy drift review:** add `/audit/policy/redaction` or `mix threadline.policy.show` to the same post-deploy operational pass where you already check trigger coverage, especially after redaction config changes.

## 6. Observability

- [ ] `:telemetry` handlers for Threadline events are attached where you need metrics or logs. Event names and measurements: [`domain-reference.md` — Telemetry](domain-reference.md#telemetry-operator-reference); per-event narrative and how health counts relate to coverage checks: [`domain-reference.md#trigger-coverage-operational`](domain-reference.md#trigger-coverage-operational).
- [ ] Retention purge logs (`threadline retention purge batch`, etc.) visible to operators when purge runs.

## 7. Brownfield and continuity

- [ ] If tables already had rows before capture: read [`brownfield-continuity.md`](brownfield-continuity.md); run `mix threadline.continuity` where applicable; document the honest “gap until first audited write” for stakeholders.

## Support incident queries

Incident queries assume audit rows still within the **retained** window — aggressive purges can make historical answers empty; reconcile timelines with **[retention and purge](#4-retention-and-purge)** before escalating missing data.

Pre-launch: confirm operators can answer the five canonical support questions (see [`domain-reference.md`](domain-reference.md#support-incident-queries) for full SQL and API notes). For a **skimmable “which public API first?”** map before diving into playbooks, see [`domain-reference.md` — Exploration API routing](domain-reference.md#exploration-api-routing-v110).

| Question (1-line) | API / Mix | SQL |
|-------------------|-----------|-----|
| 1. Row history — PK in a time window | `Threadline.history/3`, `Threadline.Query.timeline/2` | [Golden query](domain-reference.md#1-row-history-pk-changes-in-a-time-window) in domain reference |
| 2. Actor window — one actor across tables | `Threadline.actor_history/2`, `timeline/2` + `:actor_ref` | [Golden query](domain-reference.md#2-actor-window-one-actor-across-tables) |
| 3. Correlation bundle — shared `correlation_id` | `timeline/2`, `mix threadline.export` + `:correlation_id` | [Inner-join SQL + strict semantics](domain-reference.md#3-correlation-bundle-shared-correlation_id) |
| 4. Export parity — same filters as timeline | `Threadline.Export`, `mix threadline.export` | [Filter vocabulary](domain-reference.md#4-export-parity-timeline-and-export-filters-agree) |
| 5. Action ↔ capture — link semantics to rows | `Threadline.record_action/2`, `action_id` | [Join pattern](domain-reference.md#5-action-and-capture-link-semantic-actions-to-changes) |
| 6. Single transaction incident drill-down | Start with [`domain-reference.md` — Exploration API routing](domain-reference.md#exploration-api-routing-v110) | Then use the bundled incident story in [`incident-playbook.md`](incident-playbook.md#scenario-single-transaction-drilldown) |

- [ ] **Q1 — Row history:** Read [row history playbook](domain-reference.md#1-row-history-pk-changes-in-a-time-window) (`audit_changes`, `audit_transactions`, bounded `captured_at`).
- [ ] **Q2 — Actor window:** Read [actor window playbook](domain-reference.md#2-actor-window-one-actor-across-tables) (`actor_ref` JSON, time bounds).
- [ ] **Q3 — Correlation:** Read [correlation bundle playbook](domain-reference.md#3-correlation-bundle-shared-correlation_id) — with `:correlation_id`, timeline/export return only changes whose transaction **inner-joins** an `audit_actions` row with that correlation (no orphan capture rows).
- [ ] **Q4 — Export parity:** Read [export parity notes](domain-reference.md#4-export-parity-timeline-and-export-filters-agree) — same keys as `Threadline.Query.timeline/2`.
- [ ] **Q5 — Action ↔ capture:** Read [action/capture join](domain-reference.md#5-action-and-capture-link-semantic-actions-to-changes) (`audit_actions`, `action_id`, `audit_changes`).
- [ ] **Q6 — Single transaction incident drill-down:** Start with [exploration routing](domain-reference.md#exploration-api-routing-v110), then follow the bundled incident path in [incident-playbook.md](incident-playbook.md#scenario-single-transaction-drilldown).

## See also

- [Adoption pilot backlog](adoption-pilot-backlog.md) — matrix to run this checklist in a real environment and file issues with evidence.
- [Domain reference](domain-reference.md) — schema, retention semantics, export behavior.
- [HexDocs](https://hexdocs.pm/threadline) — `Threadline`, `Threadline.Export`, `Threadline.Retention`, `Threadline.Query`.
