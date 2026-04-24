# Threadline

## What This Is

Threadline is an open-source audit platform for Elixir teams using Phoenix, Ecto, and PostgreSQL. It combines trigger-backed row-change capture, first-class application action semantics (actor, intent, request/job context), and operator-grade exploration tools. It is built for teams who need audit trails that are hard to bypass, SQL-queryable without blobs, and genuinely useful for support and ops — not just compliance.

## Core Value

Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

## Last milestone shipped: v1.6 — Host staging / pooler parity (Phase 21, 2026-04-24)

**Goal (achieved in-repo):** Close the gap between **library CI** and **honest host documentation** using integrator-owned templates and evidence pointers — not maintainer attestation of third-party staging.

**Shipped (maintainer affordances):**

- **STG-01** — Fixed-field topology scaffold (`STG-HOST-TOPOLOGY-TEMPLATE`) in **`guides/adoption-pilot-backlog.md`** plus **partial** rationale guidance.
- **STG-02** — Audited HTTP/job path rubric (`STG-AUDITED-PATH-RUBRIC`) with **OK / Issue / N/A / Not run** and **Evidence / pointer** column.
- **STG-03** — Rubric rules (no OK without pointer; **N/A** vs **Not run**; CI vs host labeling); **CONTRIBUTING** `## Host STG evidence (integrators)`; production-checklist intro cross-link; doc contracts in **`test/threadline/ci_topology_contract_test.exs`** and **`test/threadline/stg_doc_contract_test.exs`**.

**Non-goals (unchanged):** New capture semantics, exploration API expansion, LiveView UI, or claiming external pilot environments the library does not control — see **Out of Scope** below and **Future** in **`.planning/milestones/v1.6-REQUIREMENTS.md`** (archived v1.6 scope).

## Shipped milestones

**v1.0** through **v1.6** are complete (**v1.6** shipped 2026-04-24). Archives live under `.planning/milestones/` (`v1.0-*.md` … `v1.6-*.md`, plus `v1.0-phases/`, `v1.1-phases/`). Living roadmap: `.planning/ROADMAP.md`. **v1.6** requirements: **`.planning/milestones/v1.6-REQUIREMENTS.md`** (living `.planning/REQUIREMENTS.md` removed at close — recreate with **`/gsd-new-milestone`**).

## Last shipped milestone: v1.5 — Adoption feedback loop

**Goal (achieved):** Close the loop between **Hex-published releases** and **documented pilot evidence** with **`guides/adoption-pilot-backlog.md`**, telemetry operator reference in **`guides/domain-reference.md`**, README / ExDoc discovery, and **ADOP-03** closed with maintainer CI–backed evidence plus **STG-01** follow-up for host pooler depth.

**Shipped:**

- **Phase 19** — Adoption operator docs (ADOP-01, ADOP-02, TELEM-01, TELEM-02).
- **Phase 20** — First external pilot / **ADOP-03** closure with backlog evidence and **AP-ENV.1** → **STG-01**.

**Archives:** `.planning/milestones/v1.5-REQUIREMENTS.md`, `.planning/milestones/v1.5-ROADMAP.md`.

**Next:** Open the next milestone on **`.planning/ROADMAP.md`** when scope is ready; **`v0.2.0`** / **`threadline` 0.2.0** remain current until the next semver bump.

## Prior milestone: v1.4 — Adoption & release readiness

**Goal (achieved):** First production week narrative + **0.2.0** packaging in-repo: onboarding/README updates, production checklist guide, clearer timeline/export errors, ExDoc extras for retention and checklist.

**Shipped:**

- **Phase 15** — README `~> 0.2`, quickstart export step, documentation index (ONB-01 — ONB-03).
- **Phase 16** — `guides/production-checklist.md` (PROD-01).
- **Phase 17** — `timeline_repo!/2`, validation order, tests (DX-01 — DX-03).
- **Phase 18** — `mix.exs` **0.2.0**, CHANGELOG **0.2.0**, ExDoc groups/extras (REL-01 — REL-03).

**Archives:** `.planning/milestones/v1.4-REQUIREMENTS.md`, `.planning/milestones/v1.4-ROADMAP.md`.

## Prior milestone: v1.3 — Production adoption (redaction, retention, export)

**Goal (achieved):** Remove the main blockers to **production onboarding**—sensitive data in audit JSON, unbounded table growth, and “get rows out for ops”—while keeping capture **correct-by-default** and **SQL-native**.

**Shipped:**

- **Redaction at capture time** — Phase 12 (`:trigger_capture`, codegen validation, docs).
- **Retention + batched purge** — Phase 13 (`Threadline.Retention.*`, `mix threadline.retention.purge`).
- **Export** — Phase 14 (`Threadline.Export`, `mix threadline.export`, README + domain guide).

**Planning artifacts (archived):** `.planning/milestones/v1.3-REQUIREMENTS.md`, `.planning/milestones/v1.3-ROADMAP.md`.

## Current state

- **Hex:** `threadline` **0.2.0** is on Hex (annotated tag **`v0.2.0`**); **`main`** carries **`@version "0.2.0"`** until the next semver bump. Planning milestone tags **`v1.0`** … track GSD cycles, not only Hex semver.
- **GitHub:** Canonical `origin`, `main` on `origin`, Actions contract extended in v1.2 with `verify.threadline` and `verify.doc_contract` in CI.
- **Capture fidelity:** Optional **`changed_from`** JSONB on UPDATE when triggers are generated with **`--store-changed-from`**; `Threadline.history/3` loads the column when present.
- **Maintainer tooling:** `mix threadline.verify_coverage`, doc contract tests for README quickstart, **`Threadline.Continuity`** + **`mix threadline.continuity`** and **`guides/brownfield-continuity.md`** for brownfield adoption; **`mix threadline.export`** and **`Threadline.Export`** for CSV/JSON dumps aligned with **`Threadline.timeline/2`** filters.
- **Planning:** Milestone **v1.6** shipped and archived (2026-04-24) — Phase **21**; archives **`.planning/milestones/v1.6-*.md`**. Next milestone: **`/gsd-new-milestone`** when scope is ready (no living `REQUIREMENTS.md` until then). **Hex:** `threadline` **0.2.0** published 2026-04-23 (`v0.2.0` tag).

## Requirements

### Validated

- [x] **Capture layer (Phase 1)** — Custom `Threadline.Capture` trigger SQL, `mix threadline.install` / `mix threadline.gen.triggers`, integration tests on PostgreSQL, GitHub Actions CI, CONTRIBUTING. Validated in Phase 1: Capture Foundation (2026-04-23).
- [x] **Semantics layer (Phase 2)** — `ActorRef`, `audit_actions` / nullable `audit_transactions.actor_ref`, `record_action/2`, `Threadline.Plug`, `Threadline.Job`, transaction-local GUC bridge for trigger-populated `actor_ref`. Validated in Phase 2: Semantics Layer (2026-04-23).
- [x] **Query + observability (Phase 3)** — `Threadline.Query`, delegators on `Threadline`, health coverage checks, telemetry hooks. Validated in Phase 3: Query & Observability (2026-04-23).
- [x] **Documentation + Hex readiness (Phase 4)** — root `README.md`, `guides/domain-reference.md`, `LICENSE`, `CHANGELOG.md`, ExDoc configuration, capture schema `@moduledoc`, `mix docs` / `mix hex.build` / `mix ci.all` green. Validated in Phase 4: Documentation & Release (2026-04-23).
- [x] **Canonical GitHub hosting (Phase 5)** — `origin` → `github.com/szTheory/threadline`, `@source_url` / package links / README CI badge aligned; `main` tracks `origin/main`; CI workflow monitors `main` only. Validated in Phase 5: Repository & remote (2026-04-22).
- [x] **CI signal on GitHub (Phases 6 & 8)** — `ci.yml` jobs green on `main` with maintainer-recorded proof (`06-VERIFICATION.md`); README / CONTRIBUTING document Actions. Validated in Phase 8: Publish main & verify CI (2026-04-23).
- [x] **Hex package `threadline` 0.1.0** — semver, dated changelog, `v0.1.0` on `origin`, publish to Hex. Validated in Phase 7–8 (2026-04-23).
- [x] **Before-values capture (Phase 9)** — nullable `audit_changes.changed_from`, opt-in per-table trigger SQL via `mix threadline.gen.triggers --store-changed-from`, `AuditChange.changed_from` and `Threadline.history/3` loading. Validated in Phase 9: Before-values capture (2026-04-23).
- [x] **Verify coverage & doc contracts (Phase 10)** — `mix threadline.verify_coverage`, `Threadline.Verify.CoveragePolicy`, CI `verify.threadline` / `verify.doc_contract`, README doc contract fixtures, CONTRIBUTING parity. Validated in Phase 10: Verify coverage & doc contracts (2026-04-23).
- [x] **Backfill / continuity (Phase 11)** — `Threadline.Continuity`, `mix threadline.continuity`, brownfield integration test, `guides/brownfield-continuity.md`, README and HexDocs discovery. Validated in Phase 11: Backfill / continuity (2026-04-23).
- [x] **Redaction at capture (Phase 12)** — `config :threadline, :trigger_capture`, `RedactionPolicy`, `TriggerSQL` exclude/mask, tests and operator docs. Validated in Phase 12 (2026-04-23).
- [x] **Retention + batched purge (Phase 13)** — `Threadline.Retention.Policy`, `Threadline.Retention.purge/1`, `mix threadline.retention.purge`, integration tests on PostgreSQL. Validated in Phase 13 (2026-04-23).
- [x] **Export (Phase 14)** — `Threadline.Export`, strict timeline filter validation, `mix threadline.export`, README + domain guide + ExDoc. Validated in Phase 14 (2026-04-23).
- [x] **Onboarding & README (Phase 15)** — `~> 0.2`, quickstart export, doc index links. Validated in Phase 15 (2026-04-23).
- [x] **Production checklist (Phase 16)** — `guides/production-checklist.md`. Validated in Phase 16 (2026-04-23).
- [x] **Timeline/export DX (Phase 17)** — `Threadline.Query.timeline_repo!/2`, validation order, tests. Validated in Phase 17 (2026-04-23).
- [x] **Release 0.2.0 packaging (Phase 18)** — `mix.exs` 0.2.0, CHANGELOG, ExDoc extras + retention in module groups. Validated in Phase 18 (2026-04-23).
- [x] **Adoption operator docs (Phase 19)** — `guides/adoption-pilot-backlog.md`, README + ExDoc extras, domain-reference telemetry operator table, production-checklist cross-links (ADOP-01, ADOP-02, TELEM-01, TELEM-02). Validated in Phase 19 (2026-04-23).
- [x] **ADOP-03 (Phase 20)** — Pilot backlog filled with **OK** / **N/A** + evidence; **AP-ENV.1** triaged to **STG-01**. Validated in Phase 20: First external pilot (maintainer CI evidence pass, 2026-04-23).
- [x] **STG-01 — STG-03 (Phase 21)** — In-repo topology template, audited-path rubric, CONTRIBUTING integrator workflow, production-checklist pointer, doc contract tests. Validated in Phase 21: Host staging & pooler parity (2026-04-24). Integrators still fill matrices with host-specific evidence via fork + PR.

### Active

_No open requirement rows — run **`/gsd-new-milestone`** to author a fresh `.planning/REQUIREMENTS.md` and the next roadmap slice when scope is ready._

### Out of Scope

- **SIEM / security information and event management** — different product category, different buyers, different infrastructure
- **Full event sourcing / CQRS** — Threadline captures audit facts; it does not drive application state reconstruction
- **pgAudit replacement** — statement-level DB auditing is a separate concern; Threadline is application-level
- **Data warehouse / CDC pipeline** — WAL/logical replication adds operational surface area (PgBouncer hazards, cloud caveats, cannot be reverted) that is not worth the tradeoff for v0.x
- **LiveView operator UI** — deferred until capture + semantics are proven; premature without a stable API surface
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

**After each phase transition** (e.g. GSD `phase.complete` / roadmap update after `/gsd-execute-phase` when applicable):

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
*Last updated: 2026-04-23 — v1.6 milestone archived (`milestones/v1.6-*.md`); living requirements file removed pending next milestone.*
