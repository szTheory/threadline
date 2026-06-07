# Requirements: v1.34 Local Docker Admin UI DX

## Goal

Make the Docker-backed Phoenix operator demo easy to start, refresh, inspect, stop, and run alongside other local Docker projects without port or cache pain.

## Demo Startup

- [x] **DX-DEMO-01**: Maintainer can start the seeded Phoenix `/audit` demo with one command from the repository root.
- [x] **DX-DEMO-02**: Demo startup prints the Compose project name, sign-in credentials, key admin UI URLs, and matching lifecycle commands.
- [x] **DX-DEMO-03**: Re-running the helper refreshes the same stack instead of creating a duplicate or silently changing the browser URL.

## Port and Project Isolation

- [x] **DX-PORT-01**: The first demo uses friendly defaults, and occupied host ports are detected with safe alternate ports selected automatically.
- [x] **DX-PORT-02**: Multiple Threadline checkouts or adjacent Docker projects can run without sharing containers, networks, volumes, or host ports accidentally.

## Lifecycle and Cache Behavior

- [x] **DX-CLEAN-01**: Maintainers have explicit `status`, `logs`, `down`, and `fresh` flows that are Compose-profile aware.
- [x] **DX-CACHE-01**: Dockerfile and Compose behavior preserve dependency/build caches for ordinary source/style edits where practical.

## Documentation and Proxy Boundary

- [x] **DX-DOC-01**: Local Docker docs explain the shortest successful path first, then the project-name/port model, cleanup, troubleshooting, and reader-specific workflows.
- [x] **DX-PROXY-01**: Documentation records that Traefik/subdomain routing is deferred, rejects `.dev` for HTTP local demos, and names `.localhost` as the future-safe hostname family if proxy mode is later added.

## Verification

- `bash -n bin/demo-up`
- `docker compose --profile demo config`
- `bin/demo-up` refreshed the existing default demo on `127.0.0.1:4101` without rebuilding.
- Named verification stack `threadline-v134-dx` started on `127.0.0.1:4100` / Postgres `5434`, refreshed on the same port, then was stopped and its volumes removed.
- Explicit demo image build succeeded after adding `ca-certificates`: `COMPOSE_PROJECT_NAME=threadline-v134-build docker compose --profile demo build demo`.
- `DB_PORT=5435 mix test test/threadline/readme_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/local_docker_dx_contract_test.exs`
- `DB_PORT=5435 mix verify.doc_contract`
- `git diff --check`

## Future Requirements

- Optional shared local proxy mode for teams that already run Traefik, Caddy, or another user-owned development proxy.
- HTTPS/mkcert local demo support only if a future browser feature or secure-cookie requirement makes HTTPS materially useful.
- Broader contributor database/PgBouncer workflow automation beyond what is needed to keep the demo easy to run.

## Out of Scope

- Making Traefik or any shared reverse proxy the default local demo path.
- Using `threadline.localhost.dev` or any `.dev` hostname for HTTP local demos.
- Binding demo services to all interfaces by default.
- Adding `container_name` or other globally named Compose resources that make multiple local stacks harder to run.
- Changing runtime operator-surface product UI as part of this Docker DX milestone.

## Traceability

| Requirement | Phase |
|---|---|
| DX-DEMO-01 | 155 |
| DX-DEMO-02 | 155 |
| DX-DEMO-03 | 155 |
| DX-PORT-01 | 155 |
| DX-PORT-02 | 156 |
| DX-CLEAN-01 | 155 |
| DX-CACHE-01 | 156 |
| DX-DOC-01 | 157 |
| DX-PROXY-01 | 157 |
