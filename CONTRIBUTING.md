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

   **Port 5432 already in use (e.g. Homebrew PostgreSQL):** Compose maps the container to host port **`5433`** by default (`THREADLINE_DB_PORT` in [`docker-compose.yml`](docker-compose.yml)). Point Mix at it:

   ```bash
   DB_PORT=5433 mix ci.all
   ```

4. Run the full local gate (same steps CI runs, modulo Postgres). The project sets **`preferred_envs: ["ci.all": :test]`** in `mix.exs`, so the whole chain (format, credo, compile strict, tests, Threadline trigger coverage, doc contract tests) runs in the **test** environment and picks up `config/test.exs`.

   ```bash
   MIX_ENV=test mix ci.all
   ```

   `mix ci.all` is equivalent when invoked without `MIX_ENV` because of `preferred_envs`.

   With the alternate Compose port: `DB_PORT=5433 mix ci.all`.

## Running tests

```bash
mix verify.test          # format of CI: full suite (needs PostgreSQL)
mix test test/path.exs   # single file
```

Integration tests use a **real** database and triggers; they are not excluded from `mix test`.

**Environment:** `DB_HOST` defaults to `localhost`; **`DB_PORT`** defaults to `5432` (see `config/test.exs`). Override if Postgres listens on another port (e.g. **`DB_PORT=5433`** with the default `docker-compose.yml` mapping).

## CI parity and `act`

GitHub Actions workflow: `.github/workflows/ci.yml`. **Live runs (branch `main`):** https://github.com/szTheory/threadline/actions?query=branch%3Amain — Stable job keys (do not rename; used by docs, `act`, and branch protection):

| Job key | Purpose |
|---------|---------|
| `verify-format` | `mix verify.format` |
| `verify-credo` | `mix verify.credo` |
| `verify-test` | compile `--warnings-as-errors` + `mix verify.test` (Postgres service) |
| `verify-docs` | `MIX_ENV=dev` — `mix docs` (ExDoc + extras) |
| `verify-hex-package` | `mix hex.build` + assert tarball contains `lib/` |
| `verify-release-shape` | `bin/verify-release-shape` — `@version` / dated `CHANGELOG` for release versions |

Hex **publish** (after a SemVer tag `v*` is pushed) runs from **`.github/workflows/hex-publish.yml`** using the **`HEX_API_KEY`** repository secret — see [Hex publish (maintainers)](#hex-publish-maintainers) below.

For running the test job locally with [nektos/act](https://github.com/nektos/act), see `scripts/ci/README.md`.

## Submitting a Pull Request

1. Fork the repository and create a branch from `main`.
2. Make your changes and run the full gate: `mix ci.all` (requires PostgreSQL — see Setup above).
3. Open a pull request against `main`. Describe what changed and why.
4. All CI checks on the PR must pass (including `verify-docs`, `verify-hex-package`, and `verify-release-shape` when present on `main`).

## Branch protection (maintainers)

In GitHub repository settings, require these checks on `main` (names match the workflow `name:` fields or job summaries as shown in the PR UI):

- Check formatting (`verify-format`)
- Run Credo (strict) (`verify-credo`)
- Run test suite (`verify-test`)
- Build ExDoc (dev) (`verify-docs`)
- Hex package tarball (`verify-hex-package`)
- Release metadata (version / changelog) (`verify-release-shape`)

Exact labels depend on GitHub’s UI; map them to the job keys above.

## Hex publish (maintainers)

**Tag-triggered publish:** pushing an annotated SemVer tag matching **`vMAJOR.MINOR.PATCH`** runs [`.github/workflows/hex-publish.yml`](.github/workflows/hex-publish.yml). It checks that **`GITHUB_REF_NAME`** (e.g. `v0.1.0`) matches **`@version`** in `mix.exs` (e.g. `0.1.0`), then runs **`mix hex.publish --yes`** with **`HEX_API_KEY`**.

1. Add repository secret **`HEX_API_KEY`** (Hex.pm API key with publish permission for this package).
2. Ensure **`main`** is green and the release commit has the correct **`@version`** and **`CHANGELOG.md`** section.
3. Tag and push (no `--force` on refs):

   ```bash
   git tag -a v0.1.0 -m "Release v0.1.0"
   git push origin main        # if needed
   git push origin v0.1.0
   ```

4. Watch the **Hex publish** workflow on the Actions tab; confirm with **`mix hex.info threadline`** after the registry updates.

**Manual runbook (optional):** you can still run **`mix hex.publish --dry-run`** and **`mix hex.publish`** locally with **`mix hex.user auth`** instead of relying on CI.

## Maintainer manual checklist (release)

Use this when debugging or if Actions publish failed (no secrets in logs):

1. Clean tree: `git status --porcelain` empty.
2. `bin/verify-release-shape` passes.
3. `DB_PORT=5433 mix ci.all` (or `mix ci.all`) passes with Postgres up.
4. `MIX_ENV=dev mix docs` and `mix hex.build` succeed.
5. `mix hex.publish --dry-run` (local) or rely on CI after **`HEX_API_KEY`** is set.
6. Tag → push branch (if needed) → push tag → verify **`hex-publish`** workflow → **`mix hex.info threadline`**.
