# Project milestones: Threadline

Entries are newest first.

## v1.11 — Composable incident surface (in flight, 2026-04-24)

**Goal:** Close the integrator **composition** gap — **`POST /api/posts`** returns **`audit_transaction_id`**, **`GET /api/audit_transactions/:id/changes`** returns ordered **`AuditChange`** rows with **`change_diff`** maps — without LiveView, **`threadline_web`**, or new capture semantics.

**Phases:** **37** (example HTTP JSON path + **`COMP-EXAMPLE-INCIDENT-JSON`** doc contract + README).

**Living artifacts:** **`.planning/REQUIREMENTS.md`**, **`.planning/ROADMAP.md`**, **`.planning/PROJECT.md`** (Current Milestone).

**Distribution:** **`v0.2.0`** / **`threadline` 0.2.0** unchanged unless a separate release milestone is run.

**What is next:** **`/gsd-complete-milestone`** when ready to archive **v1.11** to **`.planning/milestones/v1.11-*`**.

---

## v1.10 — Support-grade exploration primitives (shipped 2026-04-24)

**Goal:** Support- and integrator-facing **exploration primitives** — **field-level** change presentation from `%AuditChange{}`, **transaction-scoped** change listing, and **operator doc routing** — on top of shipped capture + semantics + timeline/export, **without** LiveView or new capture semantics.

**Distribution:** **`v0.2.0`** / **`threadline` 0.2.0** unchanged unless a separate release milestone is run.

**Phases completed:** **31–36** (31–33 core: **4** plans with `SUMMARY.md`; **34–36** audit + planning hygiene via **`VERIFICATION.md`**).

**Key accomplishments:**

- Shipped **`Threadline.ChangeDiff`**, **`Threadline.change_diff/2`**, and **`test/threadline/change_diff_test.exs`** — deterministic JSON-serializable field maps (**XPLO-01**, Phases **31-01**, **31-02**).
- Shipped **`Threadline.Query.audit_changes_for_transaction/2`** and **`Threadline.audit_changes_for_transaction/2`** with documented stable ordering and DB-backed tests (**XPLO-02**, Phase **32-01**).
- Shipped **`guides/domain-reference.md`** **Exploration API routing (v1.10+)**, production-checklist cross-link, and **`Threadline.ExplorationRoutingDocContractTest`** (**XPLO-03**, Phase **33-01**).
- Closed **INT-DOC-01** / **FLOW-TEST-01** and **`ChangeDiff`** lowercase **`op`** normalization for trigger-shaped rows (**Phase 34**).
- Added **`34-VERIFICATION.md`** and aligned **`.planning/PROJECT.md`** with shipped **XPLO-03** (**Phase 35**); planning matrix + **`32-VALIDATION`** alignment (**Phase 36**).

**Stats:** 6 phases, 4 plans with summaries; v1.10 requirements **3/3** complete at close (see archived traceability). Standalone **`v1.10-MILESTONE-AUDIT.md`** **passed** at pre-close.

**Archives:** `.planning/milestones/v1.10-REQUIREMENTS.md`, `.planning/milestones/v1.10-ROADMAP.md`, `.planning/milestones/v1.10-MILESTONE-AUDIT.md`.

**Known gaps at close:** None for in-repo acceptance. **`gsd-sdk query milestone.complete`** returned **`version required for phases archive`** — archives written manually (same as **v1.9**).

**What is next:** **`/gsd-new-milestone`** — fresh **`.planning/REQUIREMENTS.md`** and next roadmap slice when scope is ready.

---

## v1.9 — Production confidence at volume (shipped 2026-04-24)

**Goal:** Credible **ops-at-volume** narrative for telemetry + **`Threadline.Health`**, a durable **audit indexing** cookbook with doc contracts, and **retention-at-scale** guidance tied to **`Threadline.Retention`** / export / timeline — **docs-first**.

**Distribution:** **`v0.2.0`** / **`threadline` 0.2.0** unchanged unless a separate release decision is made.

**Phases completed:** **28–30** (3 phases; 6 plans with `SUMMARY.md`; execution trees under **`.planning/milestones/v1.9-phases/`**).

**Key accomplishments:**

- Shipped per-event **telemetry** operator narrative + **`## Trigger coverage (operational)`** in **`guides/domain-reference.md`**; checklist cross-links (**Phase 28**, OPS-01, OPS-02).
- Shipped **`guides/audit-indexing.md`**, ExDoc extra, cross-links, **`test/threadline/audit_indexing_doc_contract_test.exs`** (**Phase 29**, IDX-01, IDX-02).
- Shipped **`guides/production-checklist.md`** volume / purge cadence H3; **`guides/domain-reference.md`** **`## Operating at scale (v1.9+)`** hub; **README** Maintainer-band discovery (**Phase 30**, SCALE-01, SCALE-02).

**Stats:** 3 phases, 6 plans, 6/6 summaries; v1.9 requirements **6/6** complete at close (see archived traceability).

**Archives:** `.planning/milestones/v1.9-REQUIREMENTS.md`, `.planning/milestones/v1.9-ROADMAP.md`.

**Known gaps at close:** None for in-repo acceptance. No standalone **`v1.9-MILESTONE-AUDIT.md`**; optional **`/gsd-audit-milestone`** next time. **`gsd-sdk query milestone.complete`** returned **`version required for phases archive`** — archives written manually.

**What is next:** **`/gsd-new-milestone`** — fresh **`.planning/REQUIREMENTS.md`** and next roadmap slice when scope is ready.

---

## v1.8 — Close the support loop (shipped 2026-04-24)

**Goal:** Reduce SaaS support **time-to-answer** with **correlation-aware** timeline + export, **operator playbooks** in guides, an **example app** correlation path, and **doc contract** anchors.

**Distribution:** **`v0.2.0`** / **`threadline` 0.2.0** unchanged unless a separate release decision is made.

**Phases completed:** **25–27** (3 phases; 5 plans with `SUMMARY.md`; execution trees under **`.planning/milestones/v1.8-phases/`**).

**Key accomplishments:**

- Shipped **`:correlation_id`** on **`Threadline.Query`** / **`Threadline.Export`** with strict `AuditAction` join when set, validation + integration tests, CHANGELOG (**Phase 25**, LOOP-01).
- Shipped **Support incident queries** in **`guides/domain-reference.md`** and **`guides/production-checklist.md`**; marker **`LOOP-04-SUPPORT-INCIDENT-QUERIES`**; **`test/threadline/support_playbook_doc_contract_test.exs`** (**Phase 26**, LOOP-02, LOOP-04).
- Shipped example **`POST /api/posts`** with **`record_action`**, linked **`audit_transactions.action_id`**, **`ThreadlinePhoenixWeb.PostsCorrelationPathTest`**, README **`export_json`** / **`jq`** (**Phase 27**, LOOP-03).

**Stats:** 3 phases, 5 plans, 5/5 summaries; v1.8 requirements **4/4** complete at close (see archived traceability).

**Archives:** `.planning/milestones/v1.8-REQUIREMENTS.md`, `.planning/milestones/v1.8-ROADMAP.md`.

**Known gaps at close:** None for in-repo acceptance. No standalone `v1.8-MILESTONE-AUDIT.md`; optional **`/gsd-audit-milestone`** next time. `gsd-sdk query milestone.complete` returned `version required for phases archive` — archives written manually.

**What is next:** **`/gsd-new-milestone`** — fresh **`.planning/REQUIREMENTS.md`** and next roadmap slice when the **next** planning milestone scope is ready.

---

## v1.7 — Reference integration for SaaS (shipped 2026-04-24)

**Goal:** Runnable in-repo Phoenix example (**`examples/threadline_phoenix/`**) with HTTP + Oban audited paths, `record_action/2`, and links to production checklist + STG rubric.

**Distribution:** **`v0.2.0`** / **`threadline` 0.2.0** unchanged unless a separate release decision is made.

**Phases completed:** 22–24 (3 phases; 5 plans with `SUMMARY.md` under `.planning/milestones/v1.7-phases/`).

**Key accomplishments:**

- Shipped **path-dep** Phoenix example with **`mix threadline.install`**, **`mix threadline.gen.triggers`** for **`posts`**, **`mix verify.example`** in **`mix ci.all`**, and contributor README runbook (**Phase 22**).
- Landed **HTTP audited path**: **`Threadline.Plug`** on `:api`, **`Blog.create_post/2`** with transaction-local GUC, ConnCase proof for audit rows (**Phase 23**).
- Landed **Oban** **`PostTouchWorker`**, **`Threadline.Job`** + **`record_action(:post_title_refreshed_from_queue, …)`** with integration test (Sandbox **`unboxed_run`** where needed); README **Semantics in jobs** + links to **`guides/production-checklist.md`** and **`guides/adoption-pilot-backlog.md`** (**Phase 24**).

**Stats:** 3 phases, 5 plans, 5/5 summaries; v1.7 requirements **6/6** complete at close (see archived traceability; living `REQUIREMENTS.md` had lagging REF-04–REF-06 checkboxes — reconciled in archive).

**Archives:** `.planning/milestones/v1.7-REQUIREMENTS.md`, `.planning/milestones/v1.7-ROADMAP.md`.

**Known gaps at close:** None for in-repo acceptance. No standalone `v1.7-MILESTONE-AUDIT.md`; optional **`/gsd-audit-milestone`** next time. `gsd-sdk query milestone.complete` returned `version required for phases archive` — archives written manually.

**What is next:** **`/gsd-new-milestone`** — fresh `.planning/REQUIREMENTS.md` and next roadmap slice when scope is ready.

---

## v1.6 — Host staging / pooler parity (shipped 2026-04-24)

**Goal:** Close the gap between **library CI** and **honest host documentation** using integrator-owned templates and evidence pointers — not maintainer attestation of third-party staging (**STG-01**–**STG-03**).

**Distribution:** **`v0.2.0`** / **`threadline` 0.2.0** unchanged unless a separate release decision is made.

**Phases completed:** 21 (1 phase; 2 plans with `SUMMARY.md` under `.planning/phases/21-host-staging-pooler-parity/`).

**Key accomplishments:**

- Landed **STG-HOST-TOPOLOGY-TEMPLATE** and **STG-AUDITED-PATH-RUBRIC** in **`guides/adoption-pilot-backlog.md`** with doc contracts in **`test/threadline/ci_topology_contract_test.exs`**.
- Added **`CONTRIBUTING.md`** **`## Host STG evidence (integrators)`** (fork + PR workflow, redaction emphasis) and **`guides/production-checklist.md`** cross-link to the rubric.
- Shipped **`test/threadline/stg_doc_contract_test.exs`** tying CONTRIBUTING, checklist, and backlog anchors; **`DB_PORT=5433 MIX_ENV=test mix ci.all`** green at close.

**Stats:** 1 phase, 2 plans, 2/2 summaries; v1.6 requirements **3/3** complete at close (see archived traceability; living file had lagging checkboxes — reconciled in archive).

**Archives:** `.planning/milestones/v1.6-REQUIREMENTS.md`, `.planning/milestones/v1.6-ROADMAP.md`.

**Known gaps at close:** None for in-repo acceptance. No standalone `v1.6-MILESTONE-AUDIT.md`; optional **`/gsd-audit-milestone`** next time. `gsd-sdk query milestone.complete` returned `version required for phases archive` — archives written manually.

**What is next:** **`/gsd-new-milestone`** — fresh `.planning/REQUIREMENTS.md` and next roadmap slice when scope is ready.

---

## v1.5 — Adoption feedback loop (shipped 2026-04-23)

**Goal:** Integrator-led adoption — operator telemetry reference, **`guides/adoption-pilot-backlog.md`**, README/ExDoc wiring; **Phase 20** closed **ADOP-03** (2026-04-23) with maintainer CI–backed backlog evidence + **STG-01** follow-up for host pooler/staging depth.

**Distribution:** **`v0.2.0`** pushed; **`threadline` 0.2.0** on Hex (same day).

**Phases completed:** 19–20 (2 phases; plans evidenced via `PLAN.md` / `VERIFICATION.md` under `.planning/phases/`).

**Key accomplishments:**

- Shipped **`guides/adoption-pilot-backlog.md`** with checklist matrix, distribution preflight, and prioritized follow-ups aligned to **`guides/production-checklist.md`**.
- Documented all **`[:threadline, …]`** telemetry events in **`guides/domain-reference.md`** with cross-links from the production checklist (**TELEM-01** / **TELEM-02**).
- README and ExDoc extras surface the pilot backlog for integrator discovery (**ADOP-01** / **ADOP-02**).
- Closed **ADOP-03** with maintainer CI evidence in the backlog; **`AP-ENV.1`** routed to **`STG-01`** for honest host pooler/staging depth.
- CI: **`verify-pgbouncer-topology`** plus contract tests exercise pooler topology paths on `main`.

**Stats:** 2 phases; 5/5 v1.5 requirements complete at close (traceability table).

**Archives:** `.planning/milestones/v1.5-REQUIREMENTS.md`, `.planning/milestones/v1.5-ROADMAP.md`.

**Note:** No standalone `v1.5-MILESTONE-AUDIT.md` in `.planning/` at close; optional `/gsd-audit-milestone` next time for extra assurance. `gsd-sdk query milestone.complete` returned `version required for phases archive` in this environment — archives were written manually to match prior milestones.

**What is next (historical at v1.5 close):** v1.6 — shipped 2026-04-24; see **v1.6** entry above.

---

## v1.4 — Adoption & release readiness (shipped 2026-04-23)

**Delivered:** README **`~> 0.2`**, quickstart **export** step, documentation index links; **`guides/production-checklist.md`**; **`Threadline.Query.timeline_repo!/2`**, timeline filter validation before repo resolution, clearer `ArgumentError` messages; **`mix.exs` 0.2.0**, **CHANGELOG 0.2.0** narrative for upgraders from 0.1.0; ExDoc **extras** + **`Threadline.Retention`** / **`Policy`** in module groups.

**Phases completed:** 15–18 (adoption slice; no per-phase execution trees — `gsd-sdk query phases.clear` at milestone open).

**Archives:** `.planning/milestones/v1.4-REQUIREMENTS.md`, `.planning/milestones/v1.4-ROADMAP.md`.

**What is next:** Tag **`v0.2.0`** and `mix hex.publish` when ready; **`/gsd-new-milestone`** for **v1.5**.

---

## v1.3 — Production adoption (redaction, retention, export) (shipped 2026-04-23)

**Delivered:** **Capture-time redaction** (`RedactionPolicy`, `TriggerSQL` exclude/mask, `config :threadline, :trigger_capture`, `mix threadline.gen.triggers` integration); **retention + batched purge** (`Threadline.Retention.Policy`, `Threadline.Retention.purge/1`, `mix threadline.retention.purge`); **CSV/JSON export** (`Threadline.Export`, shared timeline filter validation, `mix threadline.export`, README + domain guide).

**Phases completed:** 12–14 (6 plans).

**Key accomplishments:**

- Landed REDN-01/REDN-02: per-table exclude/mask at trigger generation with PostgreSQL integration tests and operator docs (Path B safe).
- Landed RETN-01/RETN-02: documented retention window, batched idempotent purge with orphan transaction cleanup and Mix task ergonomics.
- Landed EXPO-01/EXPO-02: export APIs and Mix task aligned with `Threadline.Query.timeline/2` filters; NimbleCSV-backed CSV and JSON/NDJSON paths with stream support.

**Stats:**

- v1.3-focused window (see `git log` from `2b7f879` / `fb65250` through tip): phases 12–14 feature and docs commits; six plan summaries complete on disk.
- 3 phases, 6 plans, 100% summaries; requirements traceability 6/6 Complete at close.

**Archives:**

- Roadmap: `.planning/milestones/v1.3-ROADMAP.md`
- Requirements: `.planning/milestones/v1.3-REQUIREMENTS.md`

**Note:** No standalone `v1.3-MILESTONE-AUDIT.md` in `.planning/` at close; optional `/gsd-audit-milestone` next time for extra assurance. `gsd-sdk query milestone.complete` returned `version required for phases archive` in this environment — archives were written manually to match prior milestones.

**What is next:** `/gsd-new-milestone` — define the next product slice and a fresh `.planning/REQUIREMENTS.md`.

---

## v1.2 — Before-values & developer tooling (shipped 2026-04-23)

**Delivered:** Optional per-table **`changed_from`** on UPDATE captures with opt-in trigger generation; **`mix threadline.verify_coverage`** and CI wiring; **README doc contract** tests and Nyquist parity for expanded `ci.all`; **`Threadline.Continuity`** + **`mix threadline.continuity`** with brownfield integration coverage and **`guides/brownfield-continuity.md`**.

**Phases completed:** 9–11 (6 plans).

**Key accomplishments:**

- Landed BVAL-01/BVAL-02: migration + `--store-changed-from` triggers, `AuditChange.changed_from`, integration tests, `history/3` documentation.
- Shipped TOOL-01: `Threadline.Verify.CoveragePolicy`, `Mix.Tasks.Threadline.VerifyCoverage`, canary migration for CI failure path, README maintainer guidance.
- Shipped TOOL-03: quickstart fixtures, `readme_doc_contract_test.exs`, `verify.threadline` / `verify.doc_contract` in `ci.all` and GitHub Actions.
- Shipped TOOL-02: `Threadline.Continuity`, continuity Mix task, brownfield test, guide + README + HexDocs extras cross-links.

**Stats:**

- v1.2-focused window (see `git log` from `002bdf7` through tip): feature and docs commits across capture, verify, continuity; six plan summaries complete on disk.
- 3 phases, 6 plans, 100% summaries; requirements traceability 5/5 Complete at close.

**Archives:**

- Roadmap: `.planning/milestones/v1.2-ROADMAP.md`
- Requirements: `.planning/milestones/v1.2-REQUIREMENTS.md`

**Note:** No standalone `v1.2-MILESTONE-AUDIT.md` in `.planning/` at close; optional `/gsd-audit-milestone` next time for extra assurance.

**What is next:** `/gsd-new-milestone` — define the next product slice and a fresh `.planning/REQUIREMENTS.md`.

---

## v1.1 — GitHub, CI, and Hex (shipped 2026-04-23)

**Delivered:** Canonical GitHub `origin` with `@source_url` / docs alignment; GitHub Actions all green on `main` with maintainer-recorded CI-02 proof; **`threadline` 0.1.0** on Hex with dated `CHANGELOG.md` and **`v0.1.0`** on `origin`; Phase 8 closed audit gaps (remote/`main`, live CI, traceability).

**Phases completed:** 5–8 (7 plans).

**Key accomplishments:**

- Locked REPO-01–REPO-03 with CLI-verified evidence and `main` ↔ `origin/main` alignment.
- Landed CI-01–CI-03: stable job keys, release-hygiene jobs, README/CONTRIBUTING CI surfacing, and Nyquist contract tests for the workflow shape.
- Shipped HEX-01–HEX-04: `0.1.0` semver, changelog section, annotated tag pushed, registry-visible package.
- Refreshed Phase 8 verification so `06-VERIFICATION.md`, requirement checklists, and phase summaries agree on live GitHub state.

**Stats:**

- ~58 files touched, ~3.9k insertions in the `v1.0..HEAD` window (distribution + CI + Hex).
- ~2.4k lines of Elixir under `lib/` + `test/` (`wc` on `*.ex` / `*.exs` at close).
- 4 phases, 7 plans, 100% summaries on disk; milestone audit **passed** (2026-04-23).

**Archives:**

- Roadmap: `.planning/milestones/v1.1-ROADMAP.md`
- Requirements: `.planning/milestones/v1.1-REQUIREMENTS.md`
- Milestone audit: `.planning/milestones/v1.1-MILESTONE-AUDIT.md`
- Phase execution tree: `.planning/milestones/v1.1-phases/`

**What is next:** `/gsd-new-milestone` — define v1.2+ product requirements (see v2 backlog in `v1.0-REQUIREMENTS.md` archive).

---

## v1.0 MVP (shipped 2026-04-23)

**Delivered:** Trigger-backed row capture (Path B), application semantics (`ActorRef`, `record_action/2`, Plug/Job context), query and telemetry APIs, and release-grade docs with ExDoc/Hex build gates.

**Phases completed:** 1–4 (10 plans).

**Key accomplishments:**

- Closed the capture substrate via `gate-01-01.md` and shipped `Threadline.Capture` triggers with idempotent installer tasks and CI.
- Landed semantics: `AuditAction`, six-way `ActorRef`, transaction-local GUC bridge, `Threadline.Plug`, and `Threadline.Job`.
- Shipped `Threadline.Query` (`history`, `actor_history`, `timeline`), `Threadline.Health.trigger_coverage/1`, and structured `:telemetry` events.
- Published-quality README, `guides/domain-reference.md`, LICENSE, CHANGELOG stub, ExDoc layout, and `mix hex.build` / `mix ci.all` green.

**Stats:**

- ~95 files touched from initial commit to tip (`git diff --stat` range); ~11k insertions in that window.
- ~2.3k lines of Elixir under `lib/` + `test/` (wc on `*.ex` / `*.exs`).
- 4 phases, 10 plans, 100% roadmap summaries on disk at close.

**Archives:**

- Roadmap: `.planning/milestones/v1.0-ROADMAP.md`
- Requirements: `.planning/milestones/v1.0-REQUIREMENTS.md`
- Phase execution tree: `.planning/milestones/v1.0-phases/`

**What is next:** Cut application tag `v0.1.0`, run `mix hex.publish` when ready, then `/gsd-new-milestone` for v1.1 themes (see v2 requirement backlog in archived requirements).

---
