# Stack Research

**Domain:** Elixir / Phoenix / PostgreSQL audit library + connection poolers  
**Researched:** 2026-04-23  
**Confidence:** HIGH (repo-local; no new runtime deps for STG milestone)

## Recommended Stack

### Core Technologies (unchanged for v1.6)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Elixir / OTP | ≥ 1.15 / ≥ 26 | Threadline runtime | Project baseline per `PROJECT.md` |
| PostgreSQL | ≥ 14 | Audit storage + triggers | Capture layer contract |
| Ecto | 3.x | Repo + migrations | Integrator standard path |

### Pooler / topology (evidence only)

| Component | Role | Notes |
|-----------|------|-------|
| **PgBouncer** | Transaction or session pooling in front of Postgres | Threadline CI uses **`edoburu/pgbouncer`** with **`POOL_MODE=transaction`** (`.github/workflows/ci.yml` → `verify-pgbouncer-topology`). Hosts may use RDS Proxy, built-in poolers, or none — STG-01 is documentation + proof, not prescribing PgBouncer. |
| **Docker Compose** | Local parity | `docker-compose.yml` + `CONTRIBUTING.md#pgbouncer-topology-ci-parity` |

### Development / verification

| Tool | Purpose |
|------|---------|
| `mix verify.topology` | Runs `@moduletag :pgbouncer_topology` tests when `THREADLINE_PGBOUNCER_TOPOLOGY=1` |
| `mix verify.threadline` | Coverage / install checks; also run through pooler in CI job |
| `priv/ci/topology_bootstrap.exs` | CI bootstrap before pooler verification |

## Installation

No new install steps for the **library** in v1.6. Integrators reproduce CI parity from **CONTRIBUTING**; STG milestone adds **host-run** checklist completion and evidence pointers.

## Risks

- **Session vs transaction mode:** Wrong mode choice breaks GUC / same-transaction semantics; hosts must document actual prod mode.
- **Managed Postgres:** Some hosts hide pooler details — **matches prod: partial** is an honest outcome.
