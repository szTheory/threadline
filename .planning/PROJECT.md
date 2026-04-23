# Threadline

## What This Is

Threadline is an open-source audit platform for Elixir teams using Phoenix, Ecto, and PostgreSQL. It combines trigger-backed row-change capture, first-class application action semantics (actor, intent, request/job context), and operator-grade exploration tools. It is built for teams who need audit trails that are hard to bypass, SQL-queryable without blobs, and genuinely useful for support and ops — not just compliance.

## Core Value

Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

## Shipped milestones

**v1.0 MVP** (2026-04-23) and **v1.1 — GitHub, CI, and Hex** (2026-04-23) are complete. Archives: `.planning/milestones/v1.0-*.md`, `.planning/milestones/v1.1-*.md`, and phase trees `v1.0-phases/`, `v1.1-phases/`.

## Current Milestone: v1.2 Before-values & developer tooling

**Goal:** Increase audit fidelity and operator confidence with optional UPDATE before-values in the capture path, plus maintainer-grade tooling for coverage checks, doc drift detection, and brownfield adoption.

**Target features:**

- Optional per-table **before-values** (`store_changed_from`) so UPDATE captures prior field values; query API exposes them when enabled at install time.
- **`mix threadline.verify_coverage`** — human-readable audited-table report; non-zero exit when any configured table lacks a valid capture trigger.
- **Doc contract tests** so README / guide examples stay syntactically valid against the public API.
- **Backfill / continuity helper** for turning capture on for an existing table without pretending pre-trigger history exists.

**Explicitly not in v1.2:** retention policies, redaction/masking, CSV/JSON export, LiveView UI — remain deferred per Out of Scope until this milestone closes.

## Current state

- **Hex:** `threadline` **0.1.0** is public on Hex; git **`v0.1.0`** documents the library release line (distinct from planning tags like **`v1.1`**).
- **GitHub:** Canonical `origin`, `main` tracked on `origin`, and Actions green on `main` with recorded CI-02 proof in archived phase verification.
- **Planning:** Milestone **v1.2** requirements and roadmap live in `.planning/REQUIREMENTS.md` and `.planning/ROADMAP.md` (Phases 9–11); execution uses `.planning/phases/` once Phase 9 starts.

## Requirements

### Validated

- [x] **Capture layer (Phase 1)** — Custom `Threadline.Capture` trigger SQL, `mix threadline.install` / `mix threadline.gen.triggers`, integration tests on PostgreSQL, GitHub Actions CI, CONTRIBUTING. Validated in Phase 1: Capture Foundation (2026-04-23).
- [x] **Semantics layer (Phase 2)** — `ActorRef`, `audit_actions` / nullable `audit_transactions.actor_ref`, `record_action/2`, `Threadline.Plug`, `Threadline.Job`, transaction-local GUC bridge for trigger-populated `actor_ref`. Validated in Phase 2: Semantics Layer (2026-04-23).
- [x] **Query + observability (Phase 3)** — `Threadline.Query`, delegators on `Threadline`, health coverage checks, telemetry hooks. Validated in Phase 3: Query & Observability (2026-04-23).
- [x] **Documentation + Hex readiness (Phase 4)** — root `README.md`, `guides/domain-reference.md`, `LICENSE`, `CHANGELOG.md`, ExDoc configuration, capture schema `@moduledoc`, `mix docs` / `mix hex.build` / `mix ci.all` green. Validated in Phase 4: Documentation & Release (2026-04-23).
- [x] **Canonical GitHub hosting (Phase 5)** — `origin` → `github.com/szTheory/threadline`, `@source_url` / package links / README CI badge aligned; `main` tracks `origin/main`; CI workflow monitors `main` only. Validated in Phase 5: Repository & remote (2026-04-22).
- [x] **CI signal on GitHub (Phases 6 & 8)** — `ci.yml` jobs green on `main` with maintainer-recorded proof (`06-VERIFICATION.md`); README / CONTRIBUTING document Actions. Validated in Phase 8: Publish main & verify CI (2026-04-23).
- [x] **Hex package `threadline` 0.1.0** — semver, dated changelog, `v0.1.0` on `origin`, publish to Hex. Validated in Phase 7–8 (2026-04-23).

### Active

- [ ] **BVAL — before-values capture** — optional trigger/install path and `history` behavior for UPDATE `changed_from` (see REQUIREMENTS.md)
- [ ] **TOOL — maintainer tooling** — `mix threadline.verify_coverage`, README/doc contract tests, backfill continuity helper (see REQUIREMENTS.md)

### Out of Scope

- **SIEM / security information and event management** — different product category, different buyers, different infrastructure
- **Full event sourcing / CQRS** — Threadline captures audit facts; it does not drive application state reconstruction
- **pgAudit replacement** — statement-level DB auditing is a separate concern; Threadline is application-level
- **Data warehouse / CDC pipeline** — WAL/logical replication adds operational surface area (PgBouncer hazards, cloud caveats, cannot be reverted) that is not worth the tradeoff for v0.x
- **LiveView operator UI** — deferred until capture + semantics are proven; premature without a stable API surface
- **Retention, redaction, and export** — important but not v0.1 scope; listed in roadmap for v0.2+
- **Multi-tenant / prefix-scoped capture beyond Ecto prefix support** — defer until basic capture is validated
- **Umbrella package structure or `threadline_web` companion** — defer; decide after API sketch exists and usage patterns are known
- **Automated Hex publish from CI** — tag-triggered workflow exists; interactive `mix hex.publish` remains the documented maintainer path for early releases
- **Elixir/OTP version bumps in CI** — unless required for runner or dependency breakage

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
| Single package `threadline` to start | Avoid premature umbrella/companion split before API is known; revisit after v0.1 | ✓ **0.1.0** shipped on Hex (v1.1) |
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
*Last updated: 2026-04-23 after **v1.2** milestone start — `/gsd-new-milestone` (before-values + tooling scope)*
