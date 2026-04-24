# Adoption pilot backlog

Use this with [`production-checklist.md`](production-checklist.md) when you first run Threadline in a **staging or production-like** environment. Copy rows into issues when something fails; keep **Evidence** (logs, SQL, config redacted) so maintainers can reproduce.

**Evidence pass (maintainer, 2026-04-23):** Rows below cite **integration tests** under `test/`, **`config/test.exs`**, **`.github/workflows/ci.yml`**, and **`DB_PORT=5433 MIX_ENV=test mix ci.all`** (136 tests + `verify.threadline` + doc contract). This satisfies **ADOP-03** for **in-repo / CI truth**; it is **not** a substitute for a **host-owned staging** run with **PgBouncer** parity when production uses transaction pooling — see **Connection topology** and **`AP-ENV.1`** (triage → **STG-01** in [`.planning/REQUIREMENTS.md`](../.planning/REQUIREMENTS.md#stg-01)).

## Distribution preflight (maintainer / CI)

| Item | Status | Evidence / notes |
|------|--------|------------------|
| `threadline` **0.2.0** on [Hex](https://hex.pm/packages/threadline) | Done | Tag **`v0.2.0`** matches `@version` in `mix.exs`; Hex publish workflow green. |
| App depends on `{:threadline, "~> 0.2"}` | OK | README quickstart and doc contract lock the constraint: `test/threadline/readme_doc_contract_test.exs`; `mix.exs` `@version "0.2.0"`. |
| `mix deps.get` resolves without overrides | OK | **GitHub Actions** runs `mix deps.get` per job (e.g. `.github/workflows/ci.yml` → `verify-test` / `verify-format`); root **`mix.lock`** pins resolution — no `override: true` on library deps. |

## Connection topology (host / maintainer)

| Question | Answer | Matches prod? |
|----------|--------|----------------|
| App → pooler → Postgres? | **Maintainer pass:** CI + local `mix ci.all` use **direct TCP** to PostgreSQL (`DB_HOST` / `DB_PORT` in CI and `.planning/STATE.md` metrics). **No PgBouncer** in this evidence path. | **no / partial** — If production uses **PgBouncer transaction mode**, treat this pass as **non-representative** until **STG-01** is executed (see **AP-ENV.1**). |

## Checklist walkthrough (host team)

Map each section of the production checklist. **Status:** `OK` | `Issue` | `N/A` | `Not run`.

### 1. Capture and triggers

| Checklist item (summary) | Status | Evidence |
|--------------------------|--------|----------|
| Install + gen.triggers migrations applied | OK | Integration tests apply Threadline migrations (e.g. `priv/repo/migrations/*threadline*`, capture fixtures); capture tests under `test/threadline/capture/`. |
| `MIX_ENV` parity for trigger regeneration | N/A | Parity for **host** `MIX_ENV=prod` codegen not exercised here; CI uses **`MIX_ENV: test`** (`.github/workflows/ci.yml` → `verify-test`). |
| `verify_coverage` + `expected_tables` in CI / prod-like | OK | `config/test.exs` → `:verify_coverage, expected_tables: ["threadline_ci_coverage_canary"]`; `mix threadline.verify_coverage` is **`verify.threadline`** in `mix.exs` **`ci.all`**; `test/threadline/verify_coverage_task_test.exs`. |
| `Threadline.Health.trigger_coverage/1` wired | OK | `test/threadline/health_test.exs`; README doc contract calls `Threadline.ReadmeQuickstartFixtures.trigger_coverage_call/0` (`test/support/readme_quickstart_fixtures.ex`). |

### 2. Actor bridge and semantics

| Checklist item (summary) | Status | Evidence |
|--------------------------|--------|----------|
| GUC + same transaction as writes (PgBouncer-safe) | OK | `test/threadline/capture/trigger_context_test.exs` — `set_config('threadline.actor_ref', …, true)` + audited writes in same `Repo.transaction`. **Pooler topology** still tracked under **AP-ENV.1**. |
| Jobs use `Threadline.Job` (or equivalent) | OK | `test/threadline/job_test.exs` — `Threadline.Job.actor_ref_from_args/1`. |
| `record_action/2` where intent needed | OK | `test/threadline/semantics/audit_action_test.exs`, `test/threadline/telemetry_test.exs`; README fixture `record_action_call/0` in doc contract test. |

### 3. Redaction and sensitive columns

| Checklist item (summary) | Status | Evidence |
|--------------------------|--------|----------|
| `:trigger_capture` reviewed with security | N/A | **Policy / human review** item — not automated in this pass; library tests cover codegen validation (`test/threadline/` redaction-related tests). |
| `--dry-run` after config changes | OK | Mix task coverage via tests / docs; export dry-run: `test/mix/tasks/threadline/export_test.exs` (`--dry-run`). |
| JSON/JSONB whole-value masking understood | N/A | **Operator understanding** — documented in `guides/production-checklist.md` + domain guide; no discrete automated assertion in this matrix row. |

### 4. Retention and purge

| Checklist item (summary) | Status | Evidence |
|--------------------------|--------|----------|
| Retention config validated | OK | `test/threadline/retention/policy_test.exs`; purge integration `test/threadline/retention/purge_test.exs`. |
| Dry-run purge before execute | OK | Mix task `mix threadline.retention.purge` documents `--dry-run`; destructive paths guarded by `enabled` + `--execute` (see `lib/mix/tasks/threadline.retention.purge.ex`). |
| Batch sizing / scheduling | OK | `purge_test.exs` exercises `batch_size` / `max_batches` behavior. |
| Backups / PITR aligned with purge | N/A | **Ops policy** — host responsibility; not verifiable in library CI. |

### 5. Export and investigation

| Checklist item (summary) | Status | Evidence |
|--------------------------|--------|----------|
| Filter keys match `timeline/2` | OK | Query / export tests under `test/threadline/` (export + timeline validation). |
| Large exports / `max_rows` / streaming | OK | Export tests and `Threadline.Export` coverage in `test/` (see `test/mix/tasks/threadline/export_test.exs`). |

### 6. Observability

| Checklist item (summary) | Status | Evidence |
|--------------------------|--------|----------|
| Telemetry handlers attached | OK | `test/threadline/telemetry_test.exs`; event catalog in [`domain-reference.md`](domain-reference.md#telemetry-operator-reference). |
| Purge logs visible | N/A | **Runtime logging** in host environment — not asserted in unit tests; retention purge behavior covered in `purge_test.exs`. |

### 7. Brownfield and continuity

| Checklist item (summary) | Status | Evidence |
|--------------------------|--------|----------|
| Continuity guide + `mix threadline.continuity` if applicable | OK | `guides/brownfield-continuity.md`; brownfield continuity integration: `test/threadline/continuity_brownfield_test.exs`; Mix task `lib/mix/tasks/threadline.continuity.ex`. |

## In-repo parity (library CI)

These do **not** replace a host pilot when production uses **PgBouncer** or bespoke job topology; they show the **Hex tarball** paths are exercised in CI:

| Check | Status | Evidence |
|-------|--------|----------|
| PostgreSQL integration tests | OK | `test/` — capture, retention, export, continuity, semantics. |
| Full maintainer CI chain | OK | `mix ci.all` in `mix.exs` (`verify.format`, `verify.credo`, compile `--warnings-as-errors`, `verify.test`, `verify.threadline`, `verify.doc_contract`). Green on **`main`** via GitHub Actions. |

## Prioritized issues from pilot

| P | ID | Symptom | Likely area | Owner | Link |
|---|----|---------|--------------|-------|------|
| P1 | AP-ENV.1 | Host-owned **staging/production-like** pilot with **connection topology class matching production** (especially **PgBouncer transaction vs session**) not executed in this maintainer-only pass; HTTP + job paths under realistic pooler not evidenced here. | adoption / topology | Maintainer → host | **STG-01** — [`.planning/REQUIREMENTS.md`](../.planning/REQUIREMENTS.md#stg-01) |

_Add rows as you discover gaps. P0 = wrong or missing audit data / security; P1 = ops friction or docs._
