# Project Research Summary

**Project:** Threadline  
**Domain:** OSS Elixir audit platform — host adoption / pooler topology  
**Researched:** 2026-04-23  
**Confidence:** HIGH

## Executive Summary

v1.6 does **not** introduce a new capture stack. It formalizes **integrator-owned evidence** that Threadline’s semantics (GUC bridge, Plug, Job) behave correctly when the host’s **real** connection path includes a pooler or differs from direct Postgres. Library CI already proves **`verify-pgbouncer-topology`** for **transaction-mode PgBouncer**; STG closes the honest gap to **staging or production-like** documentation plus **HTTP and async job** audited writes. Pitfalls center on **mis-attributing CI success to host topology** and on **async code paths** skipping **`Threadline.Job`**.

## Key Findings

### Recommended stack

No version churn. Hosts use existing **Elixir / PostgreSQL / Ecto** baselines; pooler choice is **environment-specific**. Reuse **CONTRIBUTING** + **`docker-compose.yml`** for local PgBouncer parity when debugging.

### Expected features

**Table stakes:** Topology write-up; HTTP + job audited path proof; backlog **OK / Issue / N/A** with evidence.

**Differentiators:** Explicit **CI vs host** boundary; honest **matches prod: partial**.

**Defer:** Query/export API expansion; in-repo sample Phoenix app.

### Architecture approach

Document **integration surfaces** (`Threadline.Plug`, `Threadline.Job`, Repo transaction boundaries) against **actual** host topology. Single roadmap phase (**21**) is sufficient unless evidence splits “docs template” vs “external host PR” work.

### Watch out for

- Session vs transaction pool mode confusion  
- Jobs without actor bridge  
- Evidence that cannot be reproduced

## Roadmap implications

- **Phase 21** — Land STG requirements as **docs + backlog + optional small test/doc contract** tightening; avoid feature creep into capture internals.
