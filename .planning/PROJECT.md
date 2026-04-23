# Threadline

## What This Is

Threadline is an open-source audit platform for Elixir teams using Phoenix, Ecto, and PostgreSQL. It combines trigger-backed row-change capture, first-class application action semantics (actor, intent, request/job context), and operator-grade exploration tools. It is built for teams who need audit trails that are hard to bypass, SQL-queryable without blobs, and genuinely useful for support and ops — not just compliance.

## Core Value

Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

## Current Milestone: v1.1 GitHub, CI, and Hex

**Goal:** Host the project on a canonical GitHub repository with CI proving `main`, then ship **`threadline` 0.1.0** to Hex with matching git tag and changelog.

**Target features:**

- **Git remote & URL alignment** — `origin` on GitHub; `@source_url` / docs match the real repo.
- **CI on GitHub** — Existing `.github/workflows/ci.yml` runs green on `main`; README tells contributors where to look.
- **Hex publish** — Version `0.1.0`, `CHANGELOG.md`, tag `v0.1.0`, successful `mix hex.publish`.

## Current state

- **Planning milestone v1.0** is archived (2026-04-23): Phases 1–4 shipped end-to-end. Historical roadmap and requirements live under `.planning/milestones/v1.0-*.md`; phase execution artifacts under `.planning/milestones/v1.0-phases/`.
- **v1.1** (this milestone) is scoped to distribution only. Product themes from the v1.0 archive (before-values, tooling, retention, export) wait for a **later** planning milestone after Hex is live.

## Requirements

### Validated

- [x] **Capture layer (Phase 1)** — Custom `Threadline.Capture` trigger SQL, `mix threadline.install` / `mix threadline.gen.triggers`, integration tests on PostgreSQL, GitHub Actions CI, CONTRIBUTING. Validated in Phase 1: Capture Foundation (2026-04-23).
- [x] **Semantics layer (Phase 2)** — `ActorRef`, `audit_actions` / nullable `audit_transactions.actor_ref`, `record_action/2`, `Threadline.Plug`, `Threadline.Job`, transaction-local GUC bridge for trigger-populated `actor_ref`. Validated in Phase 2: Semantics Layer (2026-04-23).
- [x] **Query + observability (Phase 3)** — `Threadline.Query`, delegators on `Threadline`, health coverage checks, telemetry hooks. Validated in Phase 3: Query & Observability (2026-04-23).
- [x] **Documentation + Hex readiness (Phase 4)** — root `README.md`, `guides/domain-reference.md`, `LICENSE`, `CHANGELOG.md`, ExDoc configuration, capture schema `@moduledoc`, `mix docs` / `mix hex.build` / `mix ci.all` green. Validated in Phase 4: Documentation & Release (2026-04-23).

### Active

- [ ] **Canonical GitHub hosting** — `origin` remote, URL parity in `mix.exs` / docs, `main` pushed
- [ ] **CI signal on GitHub** — Actions workflow green for all jobs on `main`; README documents where to find status
- [ ] **Hex package `threadline` 0.1.0** — release semver, changelog, `v0.1.0` tag, `mix hex.publish` complete

### Out of Scope

- **SIEM / security information and event management** — different product category, different buyers, different infrastructure
- **Full event sourcing / CQRS** — Threadline captures audit facts; it does not drive application state reconstruction
- **pgAudit replacement** — statement-level DB auditing is a separate concern; Threadline is application-level
- **Data warehouse / CDC pipeline** — WAL/logical replication adds operational surface area (PgBouncer hazards, cloud caveats, cannot be reverted) that is not worth the tradeoff for v0.x
- **LiveView operator UI** — deferred until capture + semantics are proven; premature without a stable API surface
- **Retention, redaction, and export** — important but not v0.1 scope; listed in roadmap for v0.2+
- **Multi-tenant / prefix-scoped capture beyond Ecto prefix support** — defer until basic capture is validated
- **Umbrella package structure or `threadline_web` companion** — defer; decide after API sketch exists and usage patterns are known
- **v1.1 milestone:** automated Hex publish from CI, Elixir/OTP version bumps in CI unless required for breakage

## Context

**Ecosystem gap:** Carbonite (v0.16.x) is the strongest trigger-backed capture substrate in the Elixir ecosystem but is a library, not a platform — it handles what changed but not who did it or why. PaperTrail and ExAudit fill the action-semantics gap but sacrifice correctness (miss direct Repo/SQL writes). No existing library combines both with operator tooling.

**Key prior-art lessons:**
- Logidze: metadata via connection-local variables misbehaves with PgBouncer if transactions are skipped — Threadline must document this and provide safe propagation patterns
- ExAudit: ETS/PID-scoped context ages poorly in async contexts; avoid process-local context stores
- Ruby Audited: YAML storage caused years of upgrade pain — JSONB with typed columns is the answer
- Ruby PaperTrail: association tracking complexity bloated the core — keep association tracking out of v0.1

**Engineering baseline:** The project follows the same OSS quality bar as sibling libraries (Scrypath, Sigra): `mix verify.*` / `mix ci.*` entrypoints, doc contract tests once public docs exist, stable GitHub Actions job IDs, release automation aligned to Hex publishing workflow.

**Capture mechanism (closed):** Path B — custom `Threadline.Capture.TriggerSQL` with transaction-row grouping (`txid_current()`), no `SET LOCAL` in the capture path. Formal decision: `.planning/milestones/v1.0-phases/01-capture-foundation/gate-01-01.md` (archived with v1.0).

## Constraints

- **Tech stack**: Elixir ≥ 1.15 / OTP ≥ 26 / PostgreSQL ≥ 14 / Ecto 3.x — align with active Phoenix LTS baseline
- **SQL-native**: no Erlang binary or opaque blob storage; all audit data must be introspectable with plain SQL
- **Correct by default**: capture must not depend on developers remembering to call library functions on every write path
- **OSS quality bar**: named `mix verify.*` / `mix ci.*` entrypoints; honest `mix test` (no silent exclusions); stable GitHub Actions job IDs
- **Capture mechanism**: Path B (custom triggers) — see archived gate-01-01.md; PgBouncer transaction-mode safe
- **No WAL/CDC as primary backend**: logical replication adds operational surface area incompatible with Threadline's "batteries-included" promise at v0.x

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Trigger-backed capture (not application-hook-based) | Harder to bypass than PaperTrail-style opt-in; correctness is the core value | ✓ Validated (Phase 1) |
| Carbonite vs custom (Phase 1 gate) | Carbonite metadata path uses patterns incompatible with D-06; Threadline needs D-05 schema | ✓ Path B: custom `TriggerSQL` (see archived gate-01-01.md) |
| Separate capture vs. semantics models | Actions ≠ changes; transactions ≠ requests; collapsing them is how prior art created gaps | ✓ Good (design principle) |
| JSONB + typed columns, no binary formats | Avoids YAML/Erlang-term upgrade pain documented in Audited and ExAudit | ✓ Good (design principle) |
| Single package `threadline` to start | Avoid premature umbrella/companion split before API is known; revisit after v0.1 | ✓ Docs + tarball ready; v1.1 completes Hex publish |
| No LiveView UI in v0.1 | Exploration layer matures after capture + semantics prove out | ✓ Good |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):

1. Requirements invalidated? → Move to Out of Scope with reason  
2. Requirements validated? → Move to Validated with phase reference  
3. New requirements emerged? → Add to Active  
4. Decisions to log? → Add to Key Decisions  
5. "What This Is" still accurate? → Update if drifted  

**After each milestone** (via `/gsd-complete-milestone`):

1. Full review of all sections  
2. Core Value check — still the right priority?  
3. Audit Out of Scope — reasons still valid?  
4. Update Context with current state  

---
*Last updated: 2026-04-22 after starting milestone v1.1 (GitHub, CI, Hex)*
