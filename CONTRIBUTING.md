# Contributing to Threadline

## Development environment

**Requirements:**

- Elixir 1.15+ (CI uses 1.17.3)
- OTP 26+ (CI uses OTP 27.0)
- PostgreSQL 14+ (PostgreSQL 16 recommended; matches CI and `docker-compose.yml`)

## Setup

1. Clone the repository.
2. Install dependencies: `mix deps.get`
3. Start PostgreSQL — **no manual `createdb` required**: the test helper creates `threadline_test` when missing.

   ```bash
   docker compose up -d
   ```

   Wait until Postgres is healthy (`docker compose ps`).

4. Run the full local gate (same steps CI runs, modulo Postgres). The project sets **`preferred_envs: ["ci.all": :test]`** in `mix.exs`, so the whole chain (format, credo, test) runs in the **test** environment and picks up `config/test.exs`.

   ```bash
   mix ci.all
   ```

## Running tests

```bash
mix verify.test          # format of CI: full suite (needs PostgreSQL)
mix test test/path.exs   # single file
```

Integration tests use a **real** database and triggers; they are not excluded from `mix test`.

**Environment:** `DB_HOST` defaults to `localhost` (see `config/test.exs`). Override if Postgres runs elsewhere.

## CI parity and `act`

GitHub Actions workflow: `.github/workflows/ci.yml`. Job keys **`verify-format`**, **`verify-credo`**, and **`verify-test`** are stable identifiers — do not rename them (used by docs and local tooling).

For running the test job locally with [nektos/act](https://github.com/nektos/act), see `scripts/ci/README.md`.

## Submitting a Pull Request

1. Fork the repository and create a branch from `main`.
2. Make your changes and run the full gate: `mix ci.all` (requires PostgreSQL — see Setup above).
3. Open a pull request against `main`. Describe what changed and why.
4. All three CI checks (`verify-format`, `verify-credo`, `verify-test`) must pass before merge.

## Branch protection (maintainers)

In GitHub repository settings, require these checks on `main` (names match the workflow `name:` fields or job summaries as shown in the PR UI):

- Check formatting (`verify-format`)
- Run Credo (strict) (`verify-credo`)
- Run test suite (`verify-test`)

Exact labels depend on GitHub’s UI; map them to the three jobs above.
