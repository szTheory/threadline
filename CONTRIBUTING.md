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

   Wait until Postgres is healthy (`docker compose ps`). The default Compose
   stack starts only PostgreSQL; the Phoenix demo and PgBouncer are opt-in
   profiles.

   **Port 5432 already in use (e.g. Homebrew PostgreSQL):** Compose maps the container to host port **`5433`** by default (`THREADLINE_DB_PORT` in [`docker-compose.yml`](docker-compose.yml)). Point Mix at it:

   ```bash
   DB_PORT=5433 mix ci.all
   ```

   **Multiple Threadline worktrees or other Docker demos:** use the Phoenix demo
   helper when you want the full UI stack. It derives a project name, searches
   for free ports, and prints the URLs plus cleanup command:

   ```bash
   bin/demo-up
   ```

   For Postgres-only test stacks, give each stack a project name and unique host
   port so containers, networks, volumes, and published ports do not collide:

   ```bash
   COMPOSE_PROJECT_NAME=threadline-ui-polish THREADLINE_DB_PORT=5434 docker compose up -d
   DB_PORT=5434 mix ci.all
   ```

   See [`.env.example`](.env.example) for the full set of local Docker
   overrides. Normal cleanup is `COMPOSE_PROJECT_NAME=<name> docker compose down
   --remove-orphans`; use `docker compose down --remove-orphans -v` only when
   you intentionally want to delete Compose volumes. For the full local Docker
   mental model, read [`guides/local-docker-dx.md`](guides/local-docker-dx.md).

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

## Deterministic tests (no flakes)

Tests must be deterministic — a green run must mean the code is correct, not that
the dice landed well. Re-running a flaky test to get green hides real races and,
as we learned, can block a release.

**Test model.** This suite does **not** use Ecto's SQL Sandbox (audit triggers
and `SET LOCAL` GUCs operate at the DB level, outside sandbox awareness).
`Threadline.DataCase` is therefore `async: false` and cleans audit tables in
`setup` (FK order). Keep DB-touching tests on `DataCase`.

**Rules of thumb:**

- **Never `Process.sleep` to wait for a condition.** Use
  `assert_eventually/2` (from `Threadline.AsyncHelpers`, imported by `DataCase`) —
  it polls against a real deadline, robust on slow CI without being racy.
- **Drain GenServers deterministically.** Use `drain_mailbox/1` (two
  `:sys.get_state` round-trips) instead of sleeping after a `cast`/`send`.
- **Advisory locks: hold them on a dedicated session.** Use
  `with_advisory_lock_held/3`, not the repo pool — a pooled lock-holder races
  with the code under test on pool allocation.
- **Stop singletons in `setup`.** For globally-named GenServers (e.g.
  `Threadline.Retention.Pruner`), call `stop_named_process!/1` so a previous
  test can't leak work into the next.
- **Telemetry tests are `async: false`.** `:telemetry` handlers are
  process-global; an `async: true` module that attaches a handler will receive
  events emitted by *any* concurrently-running test for the same event name.
- **Don't assert on unordered query results positionally.** Add an explicit
  `order_by` when a test depends on row order.

**Reproduce / prove determinism.** Run a test (or the suite) repeatedly:

```bash
mix test test/path/to/flaky_test.exs --repeat-until-failure 200
mix test --seed 0 --repeat-until-failure 20   # pin a specific ordering
mix verify.flake                              # full suite, 50 repeats (fresh seed each)
```

`mix verify.flake` is also run nightly (and on demand) by the **Flake Detection**
workflow ([`.github/workflows/flake-detection.yml`](.github/workflows/flake-detection.yml));
it is intentionally kept out of `mix ci.all` so per-PR CI stays fast.

## CI parity and `act`

GitHub Actions workflow: `.github/workflows/ci.yml`. **Live runs (branch `main`):** https://github.com/szTheory/threadline/actions?query=branch%3Amain — Stable job keys (do not rename; used by docs, `act`, and branch protection):

| Job key | Purpose |
|---------|---------|
| `verify-format` | `mix verify.format` |
| `verify-credo` | `mix verify.credo` |
| `verify-compile-no-optional` | `mix verify.compile_no_optional` (compile without optional deps; gates against missing Phoenix/LiveView) |
| `verify-test` | compile `--warnings-as-errors` + `mix verify.test` (Postgres service) |
| `verify-pgbouncer-topology` | Postgres + **PgBouncer (`POOL_MODE=transaction`)** — `priv/ci/topology_bootstrap.exs` on direct Postgres, then `mix verify.topology` + `mix verify.threadline` on the pooler port |
| `verify-docs` | `MIX_ENV=dev` — `mix docs` (ExDoc + extras) |
| `verify-hex-package` | `mix hex.build` + assert tarball contains `lib/` |
| `verify-release-shape` | `bin/verify-release-shape` — `@version` / dated `CHANGELOG` for release versions |

Hex **publish** runs from **[`.github/workflows/release.yml`](.github/workflows/release.yml)** (canonical) using the **`HEX_API_KEY`** repository secret — see [Hex publish (maintainers)](#hex-publish-maintainers) below. Legacy tag-only fallback: [`.github/workflows/hex-publish.yml`](.github/workflows/hex-publish.yml).

For running the test job locally with [nektos/act](https://github.com/nektos/act), see `scripts/ci/README.md`.

## PgBouncer topology CI parity

`docker-compose.yml` includes **`pgbouncer`** (transaction mode) behind the
`pgbouncer` Compose profile on host port **`6432`** by default
(`THREADLINE_PGBOUNCER_PORT`), alongside Postgres on **`5433`**
(`THREADLINE_DB_PORT`).

1. `docker compose --profile pgbouncer up -d` and wait until both services are healthy.
2. Bootstrap migrations + topology fixture on **direct** Postgres (DDL does not go through PgBouncer):

   ```bash
   MIX_ENV=test DB_HOST=localhost DB_PORT=5433 THREADLINE_TOPOLOGY_BOOTSTRAP=1 mix run priv/ci/topology_bootstrap.exs
   ```

3. Run topology tests + `verify.threadline` through the pooler:

   ```bash
   MIX_ENV=test DB_HOST=localhost DB_PORT=6432 THREADLINE_PGBOUNCER_TOPOLOGY=1 mix verify.topology
   MIX_ENV=test DB_HOST=localhost DB_PORT=6432 THREADLINE_PGBOUNCER_TOPOLOGY=1 mix verify.threadline
   ```

`mix verify.topology` **requires** `THREADLINE_PGBOUNCER_TOPOLOGY=1` so it cannot accidentally pass against direct Postgres only.

## Host STG evidence (integrators)

**Host staging / pooler parity** (requirements **STG-01**–**STG-03**) is **integrator-owned attestation**: detailed topology, logs, and runbooks live in **your** repo or docs under **your** control. Threadline maintainers do not operate your staging stack.

To contribute a **short in-repo index** (tables, links, **redact**ed excerpts) that helps other operators, use a **fork** and open a **pull request** against this repository. Maintainers merge for **modesty** of claims, **redaction**, and **link** hygiene only — not to vouch for third-party environments.

Fill the canonical scaffolds in **`guides/adoption-pilot-backlog.md`**: search for **`STG-HOST-TOPOLOGY-TEMPLATE`** (fixed-field topology narrative) and **`STG-AUDITED-PATH-RUBRIC`** (HTTP + job paths with OK / Issue / N/A / Not run and evidence pointers). Long-form evidence stays in integrator-controlled artifacts; the PR updates the **small, reviewable surface** in `main`.

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
- PgBouncer transaction topology (`verify-pgbouncer-topology`)
- Build ExDoc (dev) (`verify-docs`)
- Hex package tarball (`verify-hex-package`)
- Release metadata (version / changelog) (`verify-release-shape`)

Exact labels depend on GitHub’s UI; map them to the job keys above.

## Backport policy (maintainers)

Security and critical fixes are backported as patch releases on the current minor (e.g. `0.9.1`), which any `~> 0.9.0`-style three-segment pin picks up automatically; crossing a minor stays a deliberate, changelog-reading act. This keeps an install-once audit adopter on a tight pin from being stranded on an unpatched line. This mirrors the backport policy stated for adopters in [`guides/upgrade-path.md`](guides/upgrade-path.md).

## Hex publish (maintainers)

**Canonical path:** [`.github/workflows/release.yml`](.github/workflows/release.yml) — Release Please on `main` (0.6.1+) or **`workflow_dispatch`** bootstrap/recovery (e.g. first **`v0.6.0`** cut).

The release workflow:

1. Resolves the release ref (Release Please tag or dispatch inputs).
2. Waits for green **`ci.yml`** on the release SHA (`gate-ci-green`).
3. Runs **`mix verify.release`**, then **`mix hex.publish --yes`** (idempotent if version already on Hex).
4. Polls Hex.pm until the version is indexed.
5. Opens a **distribution sync PR** (`bin/post-publish-distribution-sync`) that flips the adoption-pilot **Hex attestation row** ("latest is X on Hex") to OK with dated evidence — the one version statement that is only true *after* publish.

> The adoption-pilot **SSOT line** ("Distribution preflight below reflects the **X** tree") is bumped **automatically by Release Please** in the release commit (`release-please-config.json` → `extra-files`, via the `x-release-please-version` annotation on that line). There is **no manual doc prep** before a Release PR — it is green by construction. `test/threadline/adoption_pilot_doc_contract_test.exs` guards this wiring.

**Secrets:** **`HEX_API_KEY`** (required). **`RELEASE_PLEASE_TOKEN`** (optional fine-grained PAT — recommended for Release Please PRs and distribution sync PRs).

### Bootstrap `v0.6.0` (one-shot)

After Wave 1 distribution doc work is on **`main`** and CI is green:

1. Actions → **Release** → **Run workflow**
2. Inputs: `tag` = `v0.6.0`, `release_version` = `0.6.0`
3. Merge the automated **distribution sync** PR when `mix verify.doc_contract` passes on that PR

The workflow creates tag **`v0.6.0`** on green `main` HEAD if the tag does not exist yet.

### Ongoing releases (0.6.1+)

1. Merge conventional commits to **`main`** — Release Please opens/updates a Release PR (`release-please-config.json`, manifest `.release-please-manifest.json`). The Release PR bumps `mix.exs`, `CHANGELOG.md`, **and** the adoption-pilot SSOT line together, so it is green on the doc contract without any manual prep.
2. Merge the Release PR when CI is green — Release Please tags, then the same publish + distribution sync chain runs.

### Recovery / dry-run

**`workflow_dispatch`** inputs:

| Input | Purpose |
|-------|---------|
| `tag` | Existing or to-be-created `vX.Y.Z` |
| `release_version` | Must match `@version` in `mix.exs` at that ref |
| `dry_run` | `mix hex.publish --dry-run --yes` only |
| `skip_distribution_sync` | Publish without opening the doc sync PR |

**Legacy fallback:** pushing tag **`v*.*.*`** still triggers [`.github/workflows/hex-publish.yml`](.github/workflows/hex-publish.yml) (no CI gate, no doc sync).

**Local manual runbook (optional):** `mix hex.publish --dry-run` / `mix hex.publish` with `mix hex.user auth` instead of CI.

Post-publish distribution proof for adopters: adoption-pilot Distribution preflight OK row in `guides/adoption-pilot-backlog.md` plus `.planning/phases/122-release-distribution-truth/122-VERIFICATION.md`.

## Maintainer manual checklist (release)

Use when preparing or debugging a release (no secrets in logs):

1. Clean tree: `git status --porcelain` empty (local preflight only).
2. Run `mix verify.release`.
3. Run `DB_PORT=5433 mix ci.all` (or `mix ci.all`) with Postgres up.
4. Ensure **`main`** CI is green on the commit to release.
5. **Release workflow:** dispatch **`release.yml`** or merge Release Please PR — do not rely on manual `mix hex.info` copy-paste; the workflow polls Hex.pm and opens the distribution sync PR.
6. Merge the distribution sync PR after doc contracts pass.
