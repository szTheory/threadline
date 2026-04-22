# Threadline

## What This Is

Threadline is an open-source audit platform for Elixir teams using Phoenix, Ecto, and PostgreSQL. It combines trigger-backed row-change capture, first-class application action semantics (actor, intent, request/job context), and operator-grade exploration tools. It is built for teams who need audit trails that are hard to bypass, SQL-queryable without blobs, and genuinely useful for support and ops — not just compliance.

## Core Value

Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] **Capture layer** — PostgreSQL trigger-backed audit of row mutations (INSERT/UPDATE/DELETE) into a central `audit_changes` table linked to `audit_transactions`; evaluated against Carbonite as the likely substrate
- [ ] **Semantics layer** — first-class `AuditAction` events with actor, intent, reason, and correlation IDs; one blessed way to attach context from Plug/Phoenix requests and Oban jobs
- [ ] **Actor propagation** — `ActorRef` model that covers user, admin, service account, background job, system, and anonymous actors without collapsing them
- [ ] **SQL-native storage** — JSONB columns for changed data, no opaque binary formats; operators can query without Elixir helpers
- [ ] **Hex package `threadline`** — published on Hex, Elixir ≥ 1.15, OTP ≥ 26, compatible with Phoenix LTS and Ecto 3.x
- [ ] **Migration helpers** — `mix threadline.install` and `mix threadline.gen.triggers` to set up audit schema and triggers
- [ ] **CI pipeline** — GitHub Actions with `mix verify.format`, `mix verify.credo`, `mix verify.test`, and `mix ci.all` entrypoints; stable job IDs
- [ ] **README + domain reference** — vision, architecture overview, domain language, and link to domain reference doc; CONTRIBUTING skeleton

### Out of Scope

- **SIEM / security information and event management** — different product category, different buyers, different infrastructure
- **Full event sourcing / CQRS** — Threadline captures audit facts; it does not drive application state reconstruction
- **pgAudit replacement** — statement-level DB auditing is a separate concern; Threadline is application-level
- **Data warehouse / CDC pipeline** — WAL/logical replication adds operational surface area (PgBouncer hazards, cloud caveats, cannot be reverted) that is not worth the tradeoff for v0.x
- **LiveView operator UI** — deferred until capture + semantics are proven; premature without a stable API surface
- **Retention, redaction, and export** — important but not v0.1 scope; listed in roadmap for v0.2+
- **Multi-tenant / prefix-scoped capture beyond Ecto prefix support** — defer until basic capture is validated
- **Umbrella package structure or `threadline_web` companion** — defer; decide after API sketch exists and usage patterns are known

## Context

**Ecosystem gap:** Carbonite (v0.16.x) is the strongest trigger-backed capture substrate in the Elixir ecosystem but is a library, not a platform — it handles what changed but not who did it or why. PaperTrail and ExAudit fill the action-semantics gap but sacrifice correctness (miss direct Repo/SQL writes). No existing library combines both with operator tooling.

**Key prior-art lessons:**
- Logidze: metadata via connection-local variables misbehaves with PgBouncer if transactions are skipped — Threadline must document this and provide safe propagation patterns
- ExAudit: ETS/PID-scoped context ages poorly in async contexts; avoid process-local context stores
- Ruby Audited: YAML storage caused years of upgrade pain — JSONB with typed columns is the answer
- Ruby PaperTrail: association tracking complexity bloated the core — keep association tracking out of v0.1

**Engineering baseline:** The project follows the same OSS quality bar as sibling libraries (Scrypath, Sigra): `mix verify.*` / `mix ci.*` entrypoints, doc contract tests once public docs exist, stable CI job IDs, release automation aligned to Hex publishing workflow.

**Capture mechanism decision pending:** Phase 1 research must validate whether to build on Carbonite directly, fork/extend it, or implement trigger infrastructure independently. Do not assume the answer before the research gate closes.

## Constraints

- **Tech stack**: Elixir ≥ 1.15 / OTP ≥ 26 / PostgreSQL ≥ 14 / Ecto 3.x — align with active Phoenix LTS baseline
- **SQL-native**: no Erlang binary or opaque blob storage; all audit data must be introspectable with plain SQL
- **Correct by default**: capture must not depend on developers remembering to call library functions on every write path
- **OSS quality bar**: named `mix verify.*` / `mix ci.*` entrypoints; honest `mix test` (no silent exclusions); stable GitHub Actions job IDs
- **Capture mechanism**: TBD after Phase 1 research — do not lock architecture before the gate
- **No WAL/CDC as primary backend**: logical replication adds operational surface area incompatible with Threadline's "batteries-included" promise at v0.x

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Trigger-backed capture (not application-hook-based) | Harder to bypass than PaperTrail-style opt-in; correctness is the core value | — Pending validation |
| Carbonite as likely capture substrate | Best-maintained trigger library in Elixir ecosystem; covers INSERT/UPDATE/DELETE, Ecto.Multi, outbox | — Pending Phase 1 research gate |
| Separate capture vs. semantics models | Actions ≠ changes; transactions ≠ requests; collapsing them is how prior art created gaps | ✓ Good (design principle) |
| JSONB + typed columns, no binary formats | Avoids YAML/Erlang-term upgrade pain documented in Audited and ExAudit | ✓ Good (design principle) |
| Single package `threadline` to start | Avoid premature umbrella/companion split before API is known; revisit after v0.1 | — Pending |
| No LiveView UI in v0.1 | Exploration layer matures after capture + semantics prove out | ✓ Good |

---
*Last updated: 2026-04-22 after project initialization*
