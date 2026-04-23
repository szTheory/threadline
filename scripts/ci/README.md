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

No separate `createdb` step: `test/test_helper.exs` ensures the test database exists via `Ecto.Adapters.Postgres.storage_up/1`.
