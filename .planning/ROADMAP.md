# Roadmap: Threadline

## Milestones

- ◆ **v1.2 — Before-values & developer tooling** — Phases 9–11 _(active)_
- ✅ **v1.1 — GitHub, CI, and Hex** — Phases 5–8 (shipped 2026-04-23) — [full archive](milestones/v1.1-ROADMAP.md)
- ✅ **v1.0 MVP** — Phases 1–4 (shipped 2026-04-23) — [full archive](milestones/v1.0-ROADMAP.md)

## Phases

### v1.2 — Before-values & developer tooling (active)

Phase specs below continue numbering after v1.1 (last shipped phase **8**). Canonical requirement text: `.planning/REQUIREMENTS.md`. Research: `.planning/research/SUMMARY.md`.

| Phase | Name | Goal | Requirements |
| ----- | ---- | ---- | -------------- |
| 9 | 2/2 | Complete    | 2026-04-23 |
| 10 | 2/2 | Complete    | 2026-04-23 |
| 11 | 2/2 | Complete    | 2026-04-23 |

#### Phase 9: Before-values capture

**Goal:** Adopters who opt in at trigger generation time get durable `changed_from` JSONB on UPDATE captures, with query APIs returning the field without breaking existing callers.

**Requirements:** BVAL-01, BVAL-02

**Success criteria:**

1. Integration tests on PostgreSQL cover UPDATE with `store_changed_from` on and off; INSERT/DELETE leave `changed_from` null.
2. `mix threadline.install` migration path (fresh + upgrade) documents the new column; `mix threadline.gen.triggers` can emit option-aware DDL.
3. `Threadline.history/3` doctest or integration example shows `changed_from` when populated.
4. Code review confirms trigger path introduces **no** `SET LOCAL` / session coupling beyond existing GUC read.

#### Phase 10: Verify coverage & doc contracts

**Goal:** Maintainers fail CI when audited tables are missing capture triggers; README examples cannot silently rot.

**Requirements:** TOOL-01, TOOL-03

**Success criteria:**

1. `mix threadline.verify_coverage` exits non-zero in a fixture repo with a missing trigger (integration or smoke test).
2. Task output is readable in logs (table-style or equivalent) and documented in README or CONTRIBUTING.
3. Doc contract tests run in default CI (`mix ci.all` or equivalent) and fail when a public API referenced from README is renamed/removed.
4. Behavior aligns with `Threadline.Health.trigger_coverage/1` for the same database state (no contradictory results).

#### Phase 11: Backfill / continuity

**Goal:** Operators can adopt capture on existing data without the library implying false audit history.

**Requirements:** TOOL-02

**Success criteria:**

1. Public module and/or Mix task documented in `README.md` or `guides/domain-reference.md` with explicit semantics for “no history before T” vs synthetic baseline (exact behavior per plan-phase).
2. Automated tests cover at least one brownfield scenario (e.g. enable capture mid-table lifecycle) and assert invariants on `audit_changes` / `audit_transactions`.
3. No default code path inserts misleading `AuditChange` rows that appear identical to real trigger-generated captures unless documented marker fields/ops distinguish them.

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

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
| ----- | --------- | -------------- | ------ | ---------- |
| 1. Capture Foundation | v1.0 | 3/3 | Complete | 2026-04-23 |
| 2. Semantics Layer | v1.0 | 3/3 | Complete | 2026-04-23 |
| 3. Query & Observability | v1.0 | 2/2 | Complete | 2026-04-23 |
| 4. Documentation & Release | v1.0 | 2/2 | Complete | 2026-04-23 |
| 5. Repository & remote | v1.1 | 1/1 | Complete | 2026-04-22 |
| 6. CI on GitHub | v1.1 | 2/2 | Complete | 2026-04-23 |
| 7. Hex 0.1.0 | v1.1 | 2/2 | Complete | 2026-04-23 |
| 8. Publish main & verify CI | v1.1 | 2/2 | Complete | 2026-04-23 |
| 9. Before-values capture | v1.2 | 0/? | Not started | — |
| 10. Verify coverage & doc contracts | v1.2 | 0/? | Not started | — |
| 11. Backfill / continuity | v1.2 | 0/? | Not started | — |
