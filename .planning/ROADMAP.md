# Roadmap: Threadline

## Milestones

- ◆ **v1.3 — Production adoption (redaction, retention, export)** — Phases 12–14 — requirements: [.planning/REQUIREMENTS.md](REQUIREMENTS.md)
- ✅ **v1.2 — Before-values & developer tooling** — Phases 9–11 (shipped 2026-04-23) — [full archive](milestones/v1.2-ROADMAP.md)
- ✅ **v1.1 — GitHub, CI, and Hex** — Phases 5–8 (shipped 2026-04-23) — [full archive](milestones/v1.1-ROADMAP.md)
- ✅ **v1.0 MVP** — Phases 1–4 (shipped 2026-04-23) — [full archive](milestones/v1.0-ROADMAP.md)

## Phases

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

### v1.3 — Production adoption (redaction, retention, export)

Continues phase numbering after v1.2 (last shipped phase **11**). Full requirement text: [.planning/REQUIREMENTS.md](REQUIREMENTS.md).

| Phase | Name | Goal | Requirements |
| ----- | ---- | ---- | -------------- |
| 12 | Redaction at capture time | Teams can adopt auditing without storing raw secrets: exclude or mask configured columns in generated triggers so JSONB payloads never contain excluded values and never contain raw masked values. | REDN-01, REDN-02 |
| 13 | Retention & batched purge | Operators can bound audit table growth with a documented retention model and a safe, repeatable batched purge suitable for production cron. | RETN-01, RETN-02 |
| 14 | Export (CSV & JSON) | Support and ops can extract filtered audit rows in standard interchange formats using a documented public API aligned with existing query patterns. | EXPO-01, EXPO-02 |

#### Phase 12: Redaction at capture time

**Goal:** Teams can adopt auditing without storing raw secrets: exclude or mask configured columns in generated triggers so JSONB payloads never contain excluded values and never contain raw masked values.

**Requirements:** REDN-01, REDN-02

**Success criteria:**

1. Integration tests on PostgreSQL prove excluded columns are absent from persisted `audit_changes` payloads for INSERT/UPDATE/DELETE paths relevant to capture.
2. Integration tests prove masked columns persist only the documented placeholder (including on UPDATE when `changed_from` is enabled, if applicable to the design).
3. `mix threadline.gen.triggers` (or documented successor) accepts the configuration surface; README or `guides/domain-reference.md` documents operator semantics and limitations.
4. Code review confirms redaction introduces **no** unsafe session coupling in the trigger path (consistent with Path B / PgBouncer-safe constraints).

#### Phase 13: Retention & batched purge

**Goal:** Operators can bound audit table growth with a documented retention model and a safe, repeatable batched purge suitable for production cron.

**Requirements:** RETN-01, RETN-02

**Success criteria:**

1. Retention configuration semantics are documented (what “expired” means, scope per table or global as implemented).
2. Purge entrypoint deletes only rows matching the retention rule; automated tests cover at least one multi-batch scenario and idempotent re-runs.
3. Batch size is configurable; documentation states operational guidance (cron frequency, monitoring expectations).
4. Purge does not violate referential integrity with `audit_transactions` / related rows (behavior explicit in plan if cascades or orphan rules apply).

#### Phase 14: Export (CSV & JSON)

**Goal:** Support and ops can extract filtered audit rows in standard interchange formats using a documented public API aligned with existing query patterns.

**Requirements:** EXPO-01, EXPO-02

**Success criteria:**

1. Public API returns CSV bytes or string for a non-trivial filtered query (documented filter options).
2. Public API returns JSON for the same logical filter, stable enough for tooling (documented format).
3. Tests cover at least CSV and JSON happy paths plus one edge case (empty result set or large row count strategy per plan).
4. README or guide links export from `Threadline.Query` / `timeline` workflows so new users find it quickly.

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
| 9. Before-values capture | v1.2 | 2/2 | Complete | 2026-04-23 |
| 10. Verify coverage & doc contracts | v1.2 | 2/2 | Complete | 2026-04-23 |
| 11. Backfill / continuity | v1.2 | 2/2 | Complete | 2026-04-23 |
| 12. Redaction at capture time | v1.3 | 0/? | Not started | — |
| 13. Retention & batched purge | v1.3 | 0/? | Not started | — |
| 14. Export (CSV & JSON) | v1.3 | 0/? | Not started | — |
