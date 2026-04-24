# Roadmap: Threadline

## Milestones

- **v1.5 — Adoption feedback loop** — Phases 19–20 (in progress) — requirements: [REQUIREMENTS.md](REQUIREMENTS.md)
- ✅ **v1.4 — Adoption & release readiness** — Phases 15–18 (shipped 2026-04-23) — [archive](milestones/v1.4-REQUIREMENTS.md)
- ✅ **v1.3 — Production adoption (redaction, retention, export)** — Phases 12–14 (shipped 2026-04-23) — [full archive](milestones/v1.3-ROADMAP.md)
- ✅ **v1.2 — Before-values & developer tooling** — Phases 9–11 (shipped 2026-04-23) — [full archive](milestones/v1.2-ROADMAP.md)
- ✅ **v1.1 — GitHub, CI, and Hex** — Phases 5–8 (shipped 2026-04-23) — [full archive](milestones/v1.1-ROADMAP.md)
- ✅ **v1.0 MVP** — Phases 1–4 (shipped 2026-04-23) — [full archive](milestones/v1.0-ROADMAP.md)

## Phases

<details>
<summary>v1.5 Adoption feedback loop (Phases 19–20) — IN PROGRESS</summary>

Living requirements: [.planning/REQUIREMENTS.md](REQUIREMENTS.md).

- [x] **Phase 19 — Adoption operator docs** — `guides/adoption-pilot-backlog.md`, README + ExDoc extras, domain-reference telemetry table, production-checklist cross-links (ADOP-01, ADOP-02, TELEM-01, TELEM-02).
- [ ] **Phase 20 — First external pilot** — Host team runs checklist + backlog matrix; close **ADOP-03** with evidence rows and triaged issues.

</details>

<details>
<summary>✅ v1.4 Adoption & release readiness (Phases 15–18) — SHIPPED 2026-04-23</summary>

Living requirements: [.planning/REQUIREMENTS.md](REQUIREMENTS.md).

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

### Next milestone

**v1.5** is open (phases 19–20). **`v0.2.0`** is tagged and **`threadline` 0.2.0** is on Hex. Next: run **Phase 20** pilot against [`guides/adoption-pilot-backlog.md`](../guides/adoption-pilot-backlog.md); when **ADOP-03** is satisfied on `main`, run **`/gsd-execute-phase 20`** to verify and close the phase (then milestone wrap-up per project habit).

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
| ----- | --------- | -------------- | ------ | ---------- |
| 19. Adoption operator docs | v1.5 | — | Complete | 2026-04-23 |
| 20. First external pilot | v1.5 | — | Pending | — |
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
