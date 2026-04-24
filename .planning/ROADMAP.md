# Roadmap: Threadline

## Milestones

- 🔄 **v1.9 — Production confidence at volume** — Phases 28–30 (opened 2026-04-24) — [requirements](REQUIREMENTS.md) · living roadmap (this file)
- ✅ **v1.8 — Close the support loop** — Phases 25–27 (shipped 2026-04-24) — [requirements](milestones/v1.8-REQUIREMENTS.md) · [archive](milestones/v1.8-ROADMAP.md)
- ✅ **v1.7 — Reference integration for SaaS** — Phases 22–24 (shipped 2026-04-24) — [requirements](milestones/v1.7-REQUIREMENTS.md) · [archive](milestones/v1.7-ROADMAP.md)
- ✅ **v1.6 — Host staging / pooler parity** — Phase 21 (shipped 2026-04-24) — [requirements](milestones/v1.6-REQUIREMENTS.md) · [archive](milestones/v1.6-ROADMAP.md) · [research](research/SUMMARY.md)
- ✅ **v1.5 — Adoption feedback loop** — Phases 19–20 (shipped 2026-04-23) — [archive](milestones/v1.5-REQUIREMENTS.md)
- ✅ **v1.4 — Adoption & release readiness** — Phases 15–18 (shipped 2026-04-23) — [archive](milestones/v1.4-REQUIREMENTS.md)
- ✅ **v1.3 — Production adoption (redaction, retention, export)** — Phases 12–14 (shipped 2026-04-23) — [full archive](milestones/v1.3-ROADMAP.md)
- ✅ **v1.2 — Before-values & developer tooling** — Phases 9–11 (shipped 2026-04-23) — [full archive](milestones/v1.2-ROADMAP.md)
- ✅ **v1.1 — GitHub, CI, and Hex** — Phases 5–8 (shipped 2026-04-23) — [full archive](milestones/v1.1-ROADMAP.md)
- ✅ **v1.0 MVP** — Phases 1–4 (shipped 2026-04-23) — [full archive](milestones/v1.0-ROADMAP.md)

## Phases

<details>
<summary>🔄 v1.9 Production confidence at volume (Phases 28–30) — OPEN 2026-04-24</summary>

**Goal:** Credible **ops-at-volume** narrative for telemetry + **`Threadline.Health`**, a durable **audit indexing** cookbook, and **retention-at-scale** guidance grounded in shipped APIs — see **[REQUIREMENTS.md](REQUIREMENTS.md)**.

**Requirements map:** Phase 28 → OPS-01, OPS-02 · Phase 29 → IDX-01, IDX-02 · Phase 30 → SCALE-01, SCALE-02

**Success criteria**

**Phase 28 — Telemetry & health operators' narrative**

1. A reader can map each **`[:threadline, :transaction, :committed]`**, **`[:threadline, :action, :recorded]`**, and **`[:threadline, :health, :checked]`** event to **when it fires**, **what to measure**, and **degraded behavior** without reading Elixir implementation files first.
2. **`Threadline.Health.trigger_coverage/1`** is documented for weekly/production checks together with **`mix threadline.verify_coverage`**, including interpretation of covered vs uncovered user tables and the audit-table exclusion rule.

**Phase 29 — Audit table indexing cookbook**

3. A dedicated guide lists **index strategies** (not mandatory DDL) for **`audit_transactions`**, **`audit_changes`**, and **`audit_actions`** aligned with timeline, export, optional correlation filter, and retention/purge access patterns, including **tradeoffs**.
4. A **doc contract test** locks anchors from that guide so headings or markers cannot drift unnoticed.

**Phase 30 — Retention at scale & discovery**

5. **`guides/production-checklist.md`** includes **volume** guidance: growth monitoring, purge cadence thinking, and explicit ties to **`Threadline.Retention`** + export/timeline workflows already used in support narratives.
6. **README** and/or **`guides/domain-reference.md`** surfaces a **single discovery link** to the new material so operators find it from onboarding paths.

- [x] **Phase 28 — Telemetry & health operators' narrative** — OPS-01, OPS-02 — completed 2026-04-24
- [x] **Phase 29 — Audit table indexing cookbook** — IDX-01, IDX-02 — completed 2026-04-24
- [ ] **Phase 30 — Retention at scale & discovery** — SCALE-01, SCALE-02

</details>

<details>
<summary>✅ v1.8 Close the support loop (Phases 25–27) — SHIPPED 2026-04-24</summary>

**Goal:** Faster production support using the same **timeline + export** vocabulary, **correlation-aware** filtering where actions carry `correlation_id`, and **copy-paste operator docs** — see [`.planning/milestones/v1.8-REQUIREMENTS.md`](milestones/v1.8-REQUIREMENTS.md).

**Requirements map:** Phase 25 → LOOP-01 · Phase 26 → LOOP-02, LOOP-04 · Phase 27 → LOOP-03

**Success criteria**

**Phase 25 — Correlation-aware timeline & export**

1. With `:correlation_id` set, `Threadline.Query.timeline/2` and `Threadline.Export` entrypoints return only changes whose transaction links to an `audit_actions` row with that correlation; with it unset, behavior is unchanged.
2. `validate_timeline_filters!/1` accepts `:correlation_id`; unknown keys still raise; CHANGELOG documents the addition.
3. Integration tests cover timeline + at least one export shape with correlation filter.

**Phase 26 — Support playbooks & doc contracts**

4. `guides/domain-reference.md` and `guides/production-checklist.md` include **Support incident queries** material mapping the five canonical questions to API vs SQL.
5. A doc contract test locks anchors for those sections (LOOP-04).

**Phase 27 — Example app correlation path**

6. `examples/threadline_phoenix/` documents and tests (or README-verifiable) flow: correlation header → audited write / action → retrieval using `:correlation_id` after Phase 25.

- [x] **Phase 25 — Correlation-aware timeline & export** — LOOP-01 — completed 2026-04-24
- [x] **Phase 26 — Support playbooks & doc contracts** — LOOP-02, LOOP-04 — completed 2026-04-24
- [x] **Phase 27 — Example app correlation path** — LOOP-03 — completed 2026-04-24

Full snapshot: [.planning/milestones/v1.8-ROADMAP.md](milestones/v1.8-ROADMAP.md).

</details>

<details>
<summary>✅ v1.7 Reference integration for SaaS (Phases 22–24) — SHIPPED 2026-04-24</summary>

**Goal:** Runnable Phoenix example under **`examples/threadline_phoenix/`** with **HTTP** and **Oban** audited writes, **`record_action/2`**, and **links** to production checklist + STG rubric — see [`.planning/milestones/v1.7-REQUIREMENTS.md`](milestones/v1.7-REQUIREMENTS.md).

**Requirements map:** Phase 22 → REF-01, REF-02 · Phase 23 → REF-03 · Phase 24 → REF-04, REF-05, REF-06

**Success criteria**

**Phase 22 — Example app layout & runbook**

1. A new contributor can `cd` into the example directory, follow README, start Postgres, migrate, and run the app **without** publishing `threadline` to Hex (path dep).
2. Example migrations reflect Threadline install + generated triggers for ≥1 table; README calls out **`MIX_ENV`** parity for `mix threadline.gen.triggers`.

**Phase 23 — HTTP audited path**

3. Integration test or documented HTTP steps show **audit row** for an authenticated or synthetic request through **`Threadline.Plug`** pipeline.

**Phase 24 — Job path, actions, adoption pointers**

4. Oban job test demonstrates **audited write** with **`Threadline.Job`** actor propagation.
5. **`record_action/2`** appears at least once with operator-facing note in README or small guide section.
6. Example README links **`guides/production-checklist.md`** and **`guides/adoption-pilot-backlog.md`** STG blocks.

- [x] **Phase 22 — Example app layout & runbook** — REF-01, REF-02 (2026-04-24)
- [x] **Phase 23 — HTTP audited path** — REF-03 (2026-04-24)
- [x] **Phase 24 — Job path, actions, adoption pointers** — REF-04, REF-05, REF-06 (2026-04-24)

Full snapshot: [.planning/milestones/v1.7-ROADMAP.md](milestones/v1.7-ROADMAP.md).

</details>

<details>
<summary>✅ v1.5 Adoption feedback loop (Phases 19–20) — SHIPPED 2026-04-23</summary>

Phase-level snapshot: [.planning/milestones/v1.5-ROADMAP.md](milestones/v1.5-ROADMAP.md). Requirements (archived): [.planning/milestones/v1.5-REQUIREMENTS.md](milestones/v1.5-REQUIREMENTS.md).

- [x] **Phase 19 — Adoption operator docs** — `guides/adoption-pilot-backlog.md`, README + ExDoc extras, domain-reference telemetry table, production-checklist cross-links (ADOP-01, ADOP-02, TELEM-01, TELEM-02).
- [x] **Phase 20 — First external pilot** — Maintainer CI evidence in `guides/adoption-pilot-backlog.md`; **ADOP-03** complete; **AP-ENV.1** → **STG-01** (host pooler/staging follow-up).

</details>

<details>
<summary>✅ v1.6 Host staging / pooler parity (Phase 21) — SHIPPED 2026-04-24</summary>

**Goal:** Satisfy **STG-01**–**STG-03** in [`.planning/milestones/v1.6-REQUIREMENTS.md`](milestones/v1.6-REQUIREMENTS.md): integrator-owned topology narrative, HTTP + job audited-path evidence, and adoption backlog updates with citations.

**Requirements:** STG-01, STG-02, STG-03

**Success criteria**

1. A reader can answer **app → pooler → Postgres** (or equivalent), **pool mode**, and **matches prod** for the integrator’s staging or production-like environment without inferring it from Threadline CI alone.
2. Evidence exists for **≥1 HTTP** and **≥1 job** audited write path, each labeled **OK** / **Issue** / **N/A** with a reproducible pointer (log, SQL, redacted config, or issue link).
3. **`guides/adoption-pilot-backlog.md`** (or linked host copy declared in the intro) shows updated **Connection topology** / STG-related rows consistent with that evidence.

**Notes:** Maintainer work is likely **templates, checklist clarity, and merging integrator-supplied doc updates** — not claiming external environments. Hex **`0.2.0`** unchanged unless a separate release decision is made.

- [x] **Phase 21 — Host staging & pooler parity** — STG templates + rubric in `guides/adoption-pilot-backlog.md`; CONTRIBUTING host STG section; production-checklist cross-link; `ci_topology_contract_test.exs` + `stg_doc_contract_test.exs` (STG-01 — STG-03).

</details>

<details>
<summary>✅ v1.4 Adoption & release readiness (Phases 15–18) — SHIPPED 2026-04-23</summary>

Requirements (archived): [.planning/milestones/v1.4-REQUIREMENTS.md](milestones/v1.4-REQUIREMENTS.md).

- [x] **Phase 15 — Onboarding** — README `~> 0.2`, quickstart export step, documentation index links (ONB-01 — ONB-03).
- [x] **Phase 16 — Production checklist** — `guides/production-checklist.md` and README pointer (PROD-01).
- [x] **Phase 17 — DX: timeline/export errors** — `timeline_repo!/2`, validation order, tests (DX-01 — DX-03).
- [x] **Phase 18 — Release 0.2.0** — `mix.exs` 0.2.0, CHANGELOG narrative, ExDoc extras + module groups (REL-01 — REL-03).

</details>

<details>
<summary>✅ v1.3 Production adoption (Phases 12–14) — SHIPPED 2026-04-23</summary>

Phase-level specs, success criteria, and plan checklists live in [.planning/milestones/v1.3-ROADMAP.md](milestones/v1.3-ROADMAP.md). Requirements (archived): [.planning/milestones/v1.3-REQUIREMENTS.md](milestones/v1.3-REQUIREMENTS.md). v1.3 phase execution directories under `.planning/phases/` were removed when **v1.4** opened (`phases.clear`); use git history or milestone archives for on-disk artifacts.

- [x] Phase 12: Redaction at capture time (2/2 plans) — completed 2026-04-23
- [x] Phase 13: Retention & batched purge (2/2 plans) — completed 2026-04-23
- [x] Phase 14: Export (CSV & JSON) (2/2 plans) — completed 2026-04-23

</details>

<details>
<summary>✅ v1.2 Before-values & developer tooling (Phases 9–11) — SHIPPED 2026-04-23</summary>

Phase-level specs, success criteria, and plan checklists live in [.planning/milestones/v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md). On-disk execution directories under `.planning/phases/` for v1.2 were cleared when v1.3 opened; use the milestone archive and git history for detailed v1.2 execution artifacts.

- [x] Phase 9: Before-values capture (2/2 plans) — completed 2026-04-23
- [x] Phase 10: Verify coverage & doc contracts (2/2 plans) — completed 2026-04-23
- [x] Phase 11: Backfill / continuity (2/2 plans) — completed 2026-04-23

</details>

<details>
<summary>✅ v1.1 GitHub, CI, and Hex (Phases 5–8) — SHIPPED 2026-04-23</summary>

Phase-level specs, success criteria, and the plan checklist live in [.planning/milestones/v1.1-ROADMAP.md](milestones/v1.1-ROADMAP.md). Execution artifacts: [.planning/milestones/v1.1-phases/](milestones/v1.1-phases/).

- [x] Phase 5: Repository & remote (1/1 plans) — completed 2026-04-22
- [x] Phase 6: CI on GitHub (2/2 plans) — completed 2026-04-23
- [x] Phase 7: Hex 0.1.0 (2/2 plans) — completed 2026-04-23
- [x] Phase 8: Publish main & verify CI (2/2 plans) — completed 2026-04-23

</details>

<details>
<summary>✅ v1.0 MVP (Phases 1–4) — SHIPPED 2026-04-23</summary>

Phase-level specs, success criteria, and plan checklist live in [.planning/milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md). Execution artifacts: [.planning/milestones/v1.0-phases/](milestones/v1.0-phases/).

- [x] Phase 1: Capture Foundation (3/3 plans) — completed 2026-04-23
- [x] Phase 2: Semantics Layer (3/3 plans) — completed 2026-04-23
- [x] Phase 3: Query & Observability (2/2 plans) — completed 2026-04-23
- [x] Phase 4: Documentation & Release (2/2 plans) — completed 2026-04-23

</details>

### Next actions

**v1.9** is **open** (Phases **28–30**). Start with **`/gsd-discuss-phase 28`** or **`/gsd-plan-phase 28`**. **`v0.2.0`** / **`threadline` 0.2.0** remain current on Hex until a deliberate semver bump. See **`.planning/MILESTONES.md`**.

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
| ----- | --------- | -------------- | ------ | ---------- |
| 28. Telemetry & health operators' narrative | v1.9 | — | Not started | — |
| 29. Audit table indexing cookbook | v1.9 | — | Not started | — |
| 30. Retention at scale & discovery | v1.9 | — | Not started | — |
| 25. Correlation-aware timeline & export | v1.8 | 2/2 | Complete    | 2026-04-24 |
| 26. Support playbooks & doc contracts | v1.8 | 2/2 | Complete    | 2026-04-24 |
| 27. Example app correlation path | v1.8 | 1/1 | Complete    | 2026-04-24 |
| 22. Example app layout & runbook | v1.7 | 2/2 | Complete    | 2026-04-24 |
| 23. HTTP audited path | v1.7 | 1/1 | Complete    | 2026-04-24 |
| 24. Job path, actions, adoption pointers | v1.7 | 2/2 | Complete    | 2026-04-24 |
| 21. Host staging & pooler parity | v1.6 | 2/2 | Complete | 2026-04-24 |
| 19. Adoption operator docs | v1.5 | — | Complete | 2026-04-23 |
| 20. First external pilot | v1.5 | — | Complete | 2026-04-23 |
| 15. Onboarding | v1.4 | — | Complete | 2026-04-23 |
| 16. Production checklist | v1.4 | — | Complete | 2026-04-23 |
| 17. DX: timeline/export errors | v1.4 | — | Complete | 2026-04-23 |
| 18. Release 0.2.0 | v1.4 | — | Complete | 2026-04-23 |
| 1. Capture Foundation | v1.0 | 3/3 | Complete | 2026-04-23 |
| 2. Semantics Layer | v1.0 | 3/3 | Complete | 2026-04-23 |
| 3. Query & Observability | v1.0 | 2/2 | Complete | 2026-04-23 |
| 4. Documentation & Release | v1.0 | 2/2 | Complete | 2026-04-23 |
| 5. Repository & remote | v1.1 | 1/1 | Complete | 2026-04-22 |
| 6. CI on GitHub | v1.1 | 2/2 | Complete | 2026-04-23 |
| 7. Hex 0.1.0 | v1.1 | 2/2 | Complete | 2026-04-23 |
| 8. Publish main & verify CI | v1.1 | 2/2 | Complete | 2026-04-23 |
| 9. Before-values capture | v1.2 | 2/2 | Complete | 2026-04-23 |
| 10. Verify coverage & doc contracts | v1.2 | 2/2 | Complete | 2026-04-23 |
| 11. Backfill / continuity | v1.2 | 2/2 | Complete | 2026-04-23 |
| 12. Redaction at capture time | v1.3 | 2/2 | Complete | 2026-04-23 |
| 13. Retention & batched purge | v1.3 | 2/2 | Complete | 2026-04-23 |
| 14. Export (CSV & JSON) | v1.3 | 2/2 | Complete | 2026-04-23 |
