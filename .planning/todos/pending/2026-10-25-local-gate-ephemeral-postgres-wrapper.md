---
created: 2026-10-25T15:30:00Z
title: Run the local gate on its own ephemeral Postgres (bin/with-test-postgres)
area: ci
files:
  - bin/with-test-postgres
  - test/threadline/with_test_postgres_contract_test.exs
  - test/threadline/ci_workflow_parity_contract_test.exs
  - test/threadline/operator_surface/operator_evidence_contract_test.exs
  - CONTRIBUTING.md
  - guides/local-docker-dx.md
---

## Why

Phase 244's closing gate (`CI=true mix ci.all`) went red at `verify.example` with
`too_many_connections`: the maintainer's shared localhost:5432 server had about 21 free slots
and the example app's test pool opens `schedulers_online() * 2` (36 here) eagerly. The same
shared server is Homebrew PostgreSQL 14 (below the PG15 support floor), uses `C` collation and
a non-UTC timezone, and carries a stale `public.threadline_capture_changes()` in
`threadline_test`, so a local green there can hide failures CI would catch (PR #52 class). The
same ORDER BY returned different rows on the shared server and on `postgres:16`.

Phase 244 proved its gate ad hoc on a throwaway `postgres:16` container. This todo makes that
the durable, documented path.

## Design (from the 2026-10-25 three-way research fan-out)

- `bin/with-test-postgres <cmd...>`, opt-in, modelled on `bin/with-rehearsal-registry`; plain
  bash, no new dependency (no testcontainers).
- `docker run -d --rm --pull never -p 127.0.0.1::5432` with a unique name and
  `dev.threadline.kind=test-postgres` / `owner-pid` labels; read the port with `docker port`
  (no free-port probe race).
- Readiness: `pg_isready -h 127.0.0.1` inside the container (the first-boot init server is
  socket-only), 60s deadline, dump `docker logs` on timeout.
- Export `DB_HOST=127.0.0.1`, `DB_PORT`, `PGHOST`, `PGPORT`, `PGPASSWORD` for the whole child
  run; print `version()` and `inet_server_port()` first so evidence proves it did not hit 5432.
- `trap cleanup EXIT INT TERM`; `THREADLINE_TEST_PG_KEEP=1` keeps it. Startup sweep removes
  only our-labelled containers whose owner pid is dead (never by name prefix).
- Fail loudly when Docker is absent or the image is not cached; never fall back to the shared
  server. Do not wrap `docker pull` in `bin/retry-network` (its allowlist is deps.get/local.hex).
- Refuse under `GITHUB_ACTIONS=true` (CI uses service containers); do not key on `CI`.
- Keep Postgres defaults (max_connections 100, no fsync/tmpfs tuning) for CI parity.
- Add the wrapper's image default to the D-16 pg-tag scan in
  `ci_workflow_parity_contract_test.exs` so it cannot drift from `postgres:16`.
- Fake-docker contract test in the style of `retry_network_contract_test.exs`.
- Docs: a CONTRIBUTING paragraph under "Run `mix ci.all`" and a row in
  `guides/local-docker-dx.md`, pinned by the existing doc-contract tests.
- Fix `operator_evidence_contract_test.exs:435-436`, which hardcodes `127.0.0.1:5432` in an lsof
  regex and `psql -p 5432` (dormant unless `THREADLINE_OPERATOR_PREVIEW_REQUIRED=1`).
- First run: record a baseline, since collation/timezone/stale-schema differences may surface
  true CI-parity reds that were masked locally.
