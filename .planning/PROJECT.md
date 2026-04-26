# Threadline

## What This Is

Threadline is an open-source audit platform for Elixir teams using Phoenix, Ecto, and PostgreSQL. It combines trigger-backed row-change capture, first-class application action semantics (actor, intent, request/job context), and operator-grade exploration tools. It is built for teams who need audit trails that are hard to bypass, SQL-queryable without blobs, and genuinely useful for support and ops — not just compliance.

## Core Value

Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

## Current State

**Last shipped:** v1.13 — Docs Contract Repair (Phases 41–43, 2026-04-26)

**Shipped capabilities:**
- Root `README.md` and `examples/threadline_phoenix/README.md` are aligned with the shipped public API surface and locked by `test/threadline/readme_doc_contract_test.exs`.
- `Threadline.as_of/4` reconstructs single-row history from audit snapshots; `cast: true` returns an Ecto struct with loose historical loading; deleted records and genesis-gap reads return explicit errors.

## Next Milestone Goals

- Pending — start with `/gsd-new-milestone` to define v1.14 scope.

## Last milestone shipped: v1.13 — Docs Contract Repair (Phases 41–43, 2026-04-26)

**Goal (achieved):** Repair README contract drift on the root project and the Phoenix example so the published docs match the shipped public API surface, and restore the verification artifacts the milestone audit was missing.

**Shipped:**
- **Phase 41** — DOC-01: Root `README.md` aligned with the shipped public API surface; doc-contract test locks the literals.
- **Phase 42** — DOC-02: `examples/threadline_phoenix/README.md` and `examples/README.md` aligned with the runnable Phoenix reference app; doc-contract test extended to cover example install/runbook + historical reconstruction literals.
- **Phase 43** — DOC-03: `41-VERIFICATION.md`, `42-VERIFICATION.md`, and reconciled `v1.13-MILESTONE-AUDIT.md` close the audit evidence gap so DOC-01–03 are counted as verified.

**Archives:** `.planning/milestones/v1.13-REQUIREMENTS.md`, `.planning/milestones/v1.13-ROADMAP.md`, `.planning/milestones/v1.13-MILESTONE-AUDIT.md`, `.planning/milestones/v1.13-phases/`.

## Prior milestone shipped: v1.12 — Temporal Truth & Safety (Phases 38–40, 2026-04-25)

**Goal (achieved):** Provide a stable foundation for point-in-time row reconstruction with map-first reads, opt-in struct reification, and copy-pasteable operator docs.

**Shipped:**
- **Phase 38** — ASOF-01/02/05: snapshot-first `Threadline.as_of/4` with delete and genesis-gap handling.
- **Phase 39** — ASOF-03/04: opt-in struct reification with loose historical loading.
- **Phase 40** — ASOF-06: Time Travel operator docs and Phoenix example walkthrough.

**Archive:** `.planning/milestones/v1.12-REQUIREMENTS.md`, `.planning/milestones/v1.12-ROADMAP.md`.

## Last milestone shipped: v1.11 — Composable incident surface (Phase 37, 2026-04-24)

**Goal (achieved):** Close the integrator **composition** gap with a **two-step HTTP JSON** pattern in the reference Phoenix app: **`POST /api/posts`** returns **`audit_transaction_id`**, then **`GET /api/audit_transactions/:id/changes`** returns ordered changes plus **`change_diff`** maps.

**Shipped:**
- **Phase 37** — COMP-01/02/03: Example incident JSON path in `examples/threadline_phoenix`, `AuditTransactionController`, and `COMP-EXAMPLE-INCIDENT-JSON` doc contract.

## Last milestone shipped: v1.10 — Support-grade exploration primitives (Phases 31–36, 2026-04-24)

**Goal (achieved in-repo):** Turn shipped **capture + semantics + timeline/export** into faster **incident answers** with **small, explicit library APIs** — without new capture semantics or a UI framework.

**Shipped:**

- **Phase 31** — XPLO-01: **`Threadline.ChangeDiff`** + **`Threadline.change_diff/2`** — JSON-serializable field-level projection; documented INSERT/UPDATE/DELETE and `changed_from` absence.
- **Phase 32** — XPLO-02: **`Threadline.Query.audit_changes_for_transaction/2`** + **`Threadline.audit_changes_for_transaction/2`** — stable ordering for one transaction id.
- **Phase 33** — XPLO-03: **`## Exploration API routing (v1.10+)`** in **`guides/domain-reference.md`**, production-checklist cross-link, **`Threadline.ExplorationRoutingDocContractTest`**.

**Non-goals (unchanged):** LiveView operator UI; published **`threadline_web`**; new capture / redaction / retention **semantics**; maintainer-attested third-party STG URLs; **Hex** semver bump unless a **separate** release milestone says so.

**Distribution:** **`v0.2.0`** / **`threadline` 0.2.0** on Hex unchanged unless a release decision is made.

## Last milestone shipped: v1.9 — Production confidence at volume (Phases 28–30, 2026-04-24)

**Goal (achieved in-repo):** Credible **ops-at-volume** narrative for telemetry + **`Threadline.Health`**, a durable **audit indexing** cookbook, and **retention-at-scale** guidance grounded in shipped APIs — **docs-first**.

**Shipped:**

- **Phase 28** — OPS-01, OPS-02: per-event telemetry narrative + **`## Trigger coverage (operational)`** in **`guides/domain-reference.md`**; production checklist cross-links.
- **Phase 29** — IDX-01, IDX-02: **`guides/audit-indexing.md`**, ExDoc extra, doc contract **`test/threadline/audit_indexing_doc_contract_test.exs`**.
- **Phase 30** — SCALE-01, SCALE-02: **`guides/production-checklist.md`** volume / purge cadence H3 + export & support hooks; **`guides/domain-reference.md`** **`## Operating at scale (v1.9+)`** hub; **`README.md`** Maintainer-band discovery paragraph.

**Non-goals (unchanged):** LiveView operator UI; `threadline_web`; new capture/redaction semantics; Hex semver bump unless a separate release decision is made.

## Last milestone shipped: v1.8 — Close the support loop (Phases 25–27, 2026-04-24)

**Goal (achieved in-repo):** Faster **time-to-answer** in production support via shared **timeline + export** vocabulary, **correlation-aware** filtering, **copy-paste operator docs**, and an **example app** slice that proves the correlation path in CI.

**Shipped:**

- **Phase 25** — LOOP-01: `:correlation_id` on timeline/export with strict `audit_actions` join; validation + integration tests.
- **Phase 26** — LOOP-02, LOOP-04: Support incident queries in guides; doc contract anchors.
- **Phase 27** — LOOP-03: Example **`POST /api/posts`** records **`record_action`** in the audited transaction, links **`audit_transactions.action_id`**, **`ThreadlinePhoenixWeb.PostsCorrelationPathTest`**, README correlation + **`export_json`** / **`jq`**.

**Archives:** `.planning/milestones/v1.8-REQUIREMENTS.md`, `.planning/milestones/v1.8-ROADMAP.md`. **Non-goals (unchanged):** LiveView operator UI; `threadline_web` / umbrella; new capture semantics; maintainer-attested third-party STG URLs.

## Last milestone shipped: v1.7 — Reference integration for SaaS (Phases 22–24, 2026-04-24)

**Goal (achieved in-repo):** Give teams a **runnable, minimal Phoenix integration** under **`examples/threadline_phoenix/`** that demonstrates capture and semantics on **HTTP and Oban job paths**, with **`record_action/2`** and cross-links to **`guides/production-checklist.md`** and **`guides/adoption-pilot-backlog.md`** (STG rubric) — integrator-owned host evidence unchanged from v1.6.

**Shipped:**

- **Phase 22** — Path-dep example app, install + `gen.triggers` for `posts`, **`mix verify.example`** in **`mix ci.all`**, README runbook.
- **Phase 23** — **`Threadline.Plug`** on `:api` pipeline; **`Blog.create_post/2`** with transaction-local GUC; ConnCase audit path test.
- **Phase 24** — Oban **`PostTouchWorker`**, **`Blog.touch_post_for_job/2`** with **`Threadline.Job`** + **`record_action(:post_title_refreshed_from_queue, …)`**; README **Semantics in jobs** + adoption doc links.

**Archives:** `.planning/milestones/v1.7-REQUIREMENTS.md`, `.planning/milestones/v1.7-ROADMAP.md`.

**Non-goals (unchanged):** LiveView operator UI; new capture/redaction semantics; Hex semver bump unless a separate release decision is made; published `threadline_web` — example stays under **`examples/`**.

## Prior milestone shipped: v1.6 — Host staging / pooler parity (Phase 21, 2026-04-24)

**Goal (achieved in-repo):** Close the gap between **library CI** and **honest host documentation** using integrator-owned templates and evidence pointers — not maintainer attestation of third-party staging.

**Shipped (maintainer affordances):**

- **STG-01** — Fixed-field topology scaffold (`STG-HOST-TOPOLOGY-TEMPLATE`) in **`guides/adoption-pilot-backlog.md`** plus **partial** rationale guidance.
- **STG-02** — Audited HTTP/job path rubric (`STG-AUDITED-PATH-RUBRIC`) with **OK / Issue / N/A / Not run** and **Evidence / pointer** column.
- **STG-03** — Rubric rules (no OK without pointer; **N/A** vs **Not run**; CI vs host labeling); **CONTRIBUTING** `## Host STG evidence (integrators)`; production-checklist intro cross-link; doc contracts in **`test/threadline/ci_topology_contract_test.exs`** and **`test/threadline/stg_doc_contract_test.exs`**.

**Non-goals (unchanged):** New capture semantics, exploration API expansion, LiveView UI, or claiming external pilot environments the library does not control — see **Out of Scope** below and **Future** in **`.planning/milestones/v1.6-REQUIREMENTS.md`** (archived v1.6 scope).

## Shipped milestones

**v1.0** through **v1.13** are complete (**v1.13** shipped 2026-04-26, Phases 41–43). Prior milestones live under **`.planning/milestones/`**. **Living roadmap:** **`.planning/ROADMAP.md`**.

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
- [x] **REF-01 / REF-02 (Phase 22)** — Canonical `examples/threadline_phoenix/` path-dep app, install + `gen.triggers` for `posts`, dedicated `threadline_phoenix_test`, `mix verify.example` in `ci.all`, CI + doc contracts. Validated in Phase 22: Example app layout & runbook (2026-04-24).
- [x] **REF-03 (Phase 23)** — `Threadline.Plug` on example `:api` pipeline; `Blog.create_post/2` with transaction-local GUC; ConnCase `posts_audit_path_test.exs` proves `audit_changes` + `AuditTransaction.actor_ref`. Validated in Phase 23: HTTP audited path (2026-04-24).
- [x] **REF-04 / REF-05 / REF-06 (Phase 24)** — Oban `PostTouchWorker` + `Blog.touch_post_for_job/2` with `Threadline.Job` and `record_action(:post_title_refreshed_from_queue, …)`; example README **Semantics in jobs** + links to **`guides/production-checklist.md`** and **`guides/adoption-pilot-backlog.md`**. Validated in Phase 24: Job path, actions, adoption pointers (2026-04-24).
- [x] **LOOP-01 (Phase 25)** — Optional **`:correlation_id`** on **`Threadline.Query.timeline/2`**, **`timeline_query/1`**, **`export_changes_query/1`**, and **`Threadline.Export`**; strict `AuditAction` join when set; JSON **`action`** object and opt-in CSV **`include_action_metadata`**; integration tests + CHANGELOG. Validated in Phase 25: Correlation-aware timeline & export (2026-04-24).
- [x] **LOOP-02 / LOOP-04 (Phase 26)** — **`guides/domain-reference.md`** + **`guides/production-checklist.md`** **Support incident queries** (five questions, API vs SQL); marker **`LOOP-04-SUPPORT-INCIDENT-QUERIES`**; **`test/threadline/support_playbook_doc_contract_test.exs`**. Validated in Phase 26: Support playbooks & doc contracts (2026-04-24).
- [x] **LOOP-03 (Phase 27)** — **`examples/threadline_phoenix/`** correlation path: **`x-correlation-id`**, **`record_action/2`**, **`ThreadlinePhoenixWeb.PostsCorrelationPathTest`**, README **`timeline`** / **`export_json`** with **`:correlation_id`**. Validated in Phase 27: Example app correlation path (2026-04-24).
- [x] **OPS-01 / OPS-02 (Phase 28)** — **`guides/domain-reference.md`** per-event telemetry narrative + **`## Trigger coverage (operational)`**; **`guides/production-checklist.md`** §1/§6 cross-links; README pointer to **`guides/domain-reference.md#trigger-coverage-operational`**. Validated in Phase 28: Telemetry & health operators' narrative (2026-04-24).
- [x] **IDX-01 / IDX-02 (Phase 29)** — **`guides/audit-indexing.md`** (installed defaults, access patterns vs **`Threadline.Query`** / **`Threadline.Export`** / **`Threadline.Retention`**, tradeoffs, optional DDL framed non-mandatory); ExDoc extra; cross-links from **`guides/domain-reference.md`** and **`guides/production-checklist.md`**; **`test/threadline/audit_indexing_doc_contract_test.exs`**. Validated in Phase 29: Audit table indexing cookbook (2026-04-24).
- [x] **SCALE-01 / SCALE-02 (Phase 30)** — **`guides/production-checklist.md`** volume / purge cadence H3 tied to **`Threadline.Retention.Policy`**, **`Threadline.Retention.purge/1`**, **`mix threadline.retention.purge`**; export §5 + support intro hooks; **`guides/domain-reference.md`** **`## Operating at scale (v1.9+)`** discovery hub; **`README.md`** Maintainer-band pointer. Validated in Phase 30: Retention at scale & discovery (2026-04-24).
- [x] **XPLO-01 (Phase 31)** — **`Threadline.ChangeDiff.from_audit_change/2`** (primary + `:export_compat`), ExDoc matrix for INSERT/UPDATE/DELETE and `before_values` / `prior_state`, **`test/threadline/change_diff_test.exs`**, **`Threadline.change_diff/2`**. Validated in Phase 31: Field-level change presentation (2026-04-24).
- [x] **XPLO-02 (Phase 32)** — **`Threadline.Query.audit_changes_for_transaction/2`**, **`Threadline.audit_changes_for_transaction/2`**, stable order via **`timeline_order/1`**, UUID validation + **`[]`** empty semantics, **`test/threadline/query_test.exs`**. Validated in Phase 32: Transaction-scoped change listing (2026-04-24).
- [x] **XPLO-03 (Phase 33)** — **`guides/domain-reference.md`** **Exploration API routing (v1.10+)**, production-checklist cross-link, **`Threadline.ExplorationRoutingDocContractTest`**. Validated in Phase 33: Operator docs & contracts (2026-04-24).
- [x] **COMP-01 / COMP-02 / COMP-03 (Phase 37)** — Example **`POST /api/posts`** returns **`audit_transaction_id`**; **`GET /api/audit_transactions/:id/changes`** lists changes with **`Threadline.change_diff/2`** maps; **`COMP-EXAMPLE-INCIDENT-JSON`** in **`guides/domain-reference.md`**; **`ThreadlinePhoenixWeb.PostsIncidentJsonPathTest`**. Validated in Phase 37: Example incident JSON path (2026-04-24).
- [x] **ASOF-01 / ASOF-02 / ASOF-05 (Phase 38)** — Map-first reconstruction, deleted-record handling, and genesis-gap errors. Validated in v1.12: Core As-of Reconstruction.
- [x] **ASOF-03 / ASOF-04 (Phase 39)** — Opt-in struct reification and loose casting. Validated in v1.12: Reification & Schema Safety.
- [x] **ASOF-06 (Phase 40)** — Time Travel docs and example walkthrough. Validated in v1.12: Temporal Operator Guides.
- [x] **DOC-01 (Phase 41)** — Root `README.md` aligned with the shipped public API surface; locked by `test/threadline/readme_doc_contract_test.exs`. Validated in v1.13: Docs Contract Repair (2026-04-26).
- [x] **DOC-02 (Phase 42)** — `examples/threadline_phoenix/README.md` and `examples/README.md` aligned with the runnable Phoenix reference app; doc-contract test extended to assert the example surface. Validated in v1.13: Docs Contract Repair (2026-04-26).
- [x] **DOC-03 (Phases 41–42, audit closed in Phase 43)** — Doc-contract tests cover the README and example README literals; `41-VERIFICATION.md`, `42-VERIFICATION.md`, and `v1.13-MILESTONE-AUDIT.md` close the audit evidence gap. Validated in v1.13: Docs Contract Repair (2026-04-26).

### Active

- Pending — next milestone scope to be defined via `/gsd-new-milestone`.

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
| v1.7 reference app under `examples/` | Runnable SaaS-shaped integration without publishing a companion Hex package | ✓ Shipped (Phases 22–24, 2026-04-24) |
| `ChangeDiff` normalizes trigger `op` casing | Lowercase `op` from PostgreSQL trigger paths maps to uppercase INSERT/UPDATE/DELETE in the primary wire map | ✓ Shipped (Phase 34, v1.10) |
| `as_of/4` map-first reconstruction and cast-based reification | Point-in-time reads now support explicit deleted/genesis errors plus opt-in struct loading | ✓ Shipped (Phases 38–40, v1.12) |
| Treat README docs drift as a first-class milestone | README literals are public API; doc-contract tests must lock them so future drift fails CI instead of silently shipping | ✓ Shipped (Phases 41–43, v1.13) |
| Verification artifacts are first-class milestone output | Phase 43 retroactively wrote `*-VERIFICATION.md` to close an audit gap; future phases should land verification evidence alongside SUMMARY.md, not after | ✓ Shipped (Phase 43, v1.13) |

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
*Last updated: 2026-04-26 after v1.13 milestone close.*
