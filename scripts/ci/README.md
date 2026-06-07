# Local CI helpers

## `act` (optional)

To approximate the **`verify-test`** job locally (Elixir + PostgreSQL service):

```bash
act -j verify-test --container-architecture linux/amd64
```

**Notes:**

- `act` must be installed (`brew install act` on macOS).
- GitHub Actions **service containers** require a recent `act` and Docker with sufficient resources. If services fail to start, use **Docker Compose** instead (`docker compose up -d` from the repo root) and run `mix verify.test` on the host — that matches CI’s Postgres 16 + `threadline_test` database.

## Compose + Mix (recommended local path)

```bash
docker compose up -d
mix deps.get
mix ci.all
```

If **port 5432** is already taken by another PostgreSQL on the host, Compose defaults to **5433** — use:

```bash
DB_PORT=5433 mix ci.all
```

When running more than one checkout or Docker-backed demo at the same time,
pair a unique Compose project name with a unique host database port:

```bash
COMPOSE_PROJECT_NAME=threadline-ci-a THREADLINE_DB_PORT=5434 docker compose up -d
DB_PORT=5434 mix ci.all
COMPOSE_PROJECT_NAME=threadline-ci-a docker compose down --remove-orphans
```

For the broader port/project-name model, see
[`guides/local-docker-dx.md`](../../guides/local-docker-dx.md).

No separate `createdb` step: `test/test_helper.exs` ensures the test database exists via `Ecto.Adapters.Postgres.storage_up/1`.

## Other jobs (`act`)

Approximate **ExDoc** build (matches `verify-docs`):

```bash
act -j verify-docs --container-architecture linux/amd64
```

**Hex tarball** and **release-shape** jobs need no services:

```bash
act -j verify-hex-package --container-architecture linux/amd64
act -j verify-release-shape --container-architecture linux/amd64
```

## PgBouncer topology job (`act`)

Requires **two** service containers (Postgres + PgBouncer). `act` support varies by version; if it fails, use **Docker Compose** (`docker compose up -d`) and the commands in [CONTRIBUTING.md](../../CONTRIBUTING.md#pgbouncer-topology-ci-parity).

```bash
act -j verify-pgbouncer-topology --container-architecture linux/amd64
```
