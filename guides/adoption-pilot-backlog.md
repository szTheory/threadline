# Adoption pilot backlog

Use this with [`production-checklist.md`](production-checklist.md) when you first run Threadline in a **staging or production-like** environment. Copy rows into issues when something fails; keep **Evidence** (logs, SQL, config redacted) so maintainers can reproduce.

## Distribution preflight (maintainer / CI)

| Item | Status | Evidence / notes |
|------|--------|------------------|
| `threadline` **0.2.0** on [Hex](https://hex.pm/packages/threadline) | Done | Tag **`v0.2.0`** matches `@version` in `mix.exs`; Hex publish workflow green. |
| App depends on `{:threadline, "~> 0.2"}` | Not run | |
| `mix deps.get` resolves without overrides | Not run | |

## Checklist walkthrough (host team)

Map each section of the production checklist. **Status:** `OK` | `Issue` | `N/A` | `Not run`.

### 1. Capture and triggers

| Checklist item (summary) | Status | Evidence |
|--------------------------|--------|----------|
| Install + gen.triggers migrations applied | Not run | |
| `MIX_ENV` parity for trigger regeneration | Not run | |
| `verify_coverage` + `expected_tables` in CI / prod-like | Not run | |
| `Threadline.Health.trigger_coverage/1` wired | Not run | |

### 2. Actor bridge and semantics

| Checklist item (summary) | Status | Evidence |
|--------------------------|--------|----------|
| GUC + same transaction as writes (PgBouncer-safe) | Not run | |
| Jobs use `Threadline.Job` (or equivalent) | Not run | |
| `record_action/2` where intent needed | Not run | |

### 3. Redaction and sensitive columns

| Checklist item (summary) | Status | Evidence |
|--------------------------|--------|----------|
| `:trigger_capture` reviewed with security | Not run | |
| `--dry-run` after config changes | Not run | |
| JSON/JSONB whole-value masking understood | Not run | |

### 4. Retention and purge

| Checklist item (summary) | Status | Evidence |
|--------------------------|--------|----------|
| Retention config validated | Not run | |
| Dry-run purge before execute | Not run | |
| Batch sizing / scheduling | Not run | |
| Backups / PITR aligned with purge | Not run | |

### 5. Export and investigation

| Checklist item (summary) | Status | Evidence |
|--------------------------|--------|----------|
| Filter keys match `timeline/2` | Not run | |
| Large exports / `max_rows` / streaming | Not run | |

### 6. Observability

| Checklist item (summary) | Status | Evidence |
|--------------------------|--------|----------|
| Telemetry handlers attached | Not run | See [Telemetry (operator reference)](domain-reference.md#telemetry-operator-reference). |
| Purge logs visible | Not run | |

### 7. Brownfield and continuity

| Checklist item (summary) | Status | Evidence |
|--------------------------|--------|----------|
| Continuity guide + `mix threadline.continuity` if applicable | Not run | |

## In-repo parity (library CI)

These do **not** replace a host pilot; they show the **Hex tarball** paths are exercised in CI:

- PostgreSQL integration tests under `test/` (capture, retention, export, continuity).
- `mix ci.all` (or `mix verify.test` + `mix verify.threadline` when using Docker Postgres).

## Prioritized issues from pilot

| P | ID | Symptom | Likely area | Owner | Link |
|---|----|---------|--------------|-------|------|
| | | | | | |

_Add rows as you discover gaps. P0 = wrong or missing audit data / security; P1 = ops friction or docs._
