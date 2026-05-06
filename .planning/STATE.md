---
gsd_state_version: 1.0
milestone: v1.16
milestone_name: Investigation Table Stakes
status: milestone shipped
last_updated: "2026-05-06T00:00:00Z"
last_activity: 2026-05-06
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 8
  completed_plans: 8
  percent: 100
---

# Project State: Threadline

## Project Reference

**Core Value**: Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.
**Current Focus**: No active milestone is open. v1.16 is shipped and archived; use `.planning/MILESTONE-ARC.md` to open the next milestone, currently recommended as v1.17 — Operator Surface Foundation.

## Current Position

Phase: none active
Plan: none active
Status: v1.16 closed on 2026-05-06 after the milestone audit passed and the roadmap/requirements were archived.
Last activity: 2026-05-06 — Archived v1.16, updated the planning summaries, and advanced the milestone arc to v1.17 as the standing next recommendation.

## Performance Metrics

- **Total Phases**: 4 planned in v1.16
- **Phases Completed**: 4 of 4 in shipped milestone (Phases 53-56 shipped)
- **Requirements Covered**: 5/5 shipped in v1.16 (`EXPLORE-01`, `EXPLORE-02`, `INCIDENT-06`, `INCIDENT-07`, `ADOPT-04`)
- **Last Milestone**: v1.16 (Shipped 2026-05-06)

## Accumulated Context

### Decisions

- 2026-05-05: Open v1.16 as "Investigation Table Stakes" — prioritize packaged investigation workflows over more adapters or UI breadth because the biggest adoption gap is still time-to-answer after install.
- 2026-05-05: Record a standing milestone arc in `.planning/MILESTONE-ARC.md` so future `/gsd-new-milestone` runs start from a durable recommendation instead of a blank prompt.
- 2026-05-05: Keep phase numbering continuous; v1.16 starts at Phase 53.
- 2026-05-05: Skip fresh research for v1.16 — the gap is already well grounded in shipped docs, APIs, and example composition patterns inside this repo.
- 2026-05-05: Phase 53 introduced a shared `(captured_at, id)` keyset paging contract, exposed `Threadline.timeline_page/2`, and aligned export plus investigation docs on the same traversal semantics.
- 2026-05-05: Phase 54 packaged row-history, actor-window, correlation-bundle, and transaction-context questions into public `Threadline` investigation helpers while keeping `change_diff`-driven incident bundles deferred to Phase 55.
- 2026-05-05: Phase 55 plan 55-01 added `Threadline.incident_bundle/2`, explicit incident bundle structs, and existence-aware not-found versus empty-change semantics while leaving `transaction_context/2` and `audit_changes_for_transaction/2` backward-compatible.
- 2026-05-05: Phase 55 plan 55-02 moved the Phoenix reference incident endpoint onto `Threadline.incident_bundle/2`, added a dedicated JSON renderer, and proved the authenticated `401`/`400`/`404`/`200` request paths.
- 2026-05-05: Phase 56 converged the README, domain reference, SaaS quickstart, incident playbook, production checklist, and Phoenix example README on one canonical investigation hierarchy with `Threadline.incident_bundle/2` as the default transaction drill-down path.
- 2026-05-05: Phase 56 extended the focused doc-contract suite so routing literals, the bundled incident story, and the host-owned auth/policy boundary now fail fast on drift.
- 2026-05-05: Phase 56 refreshed `.planning/PROJECT.md` and `.planning/STATE.md` to treat `.planning/MILESTONE-ARC.md` as the only ranked forward-strategy source.
- 2026-05-05: Open v1.15 as "Host Integration Completion" — formalize the native `Threadline.Plug` host-wiring hook, direct Sigra callback composition, an authenticated incident drill-down baseline, and the doc/test alignment that keeps that adopter story stable.
- 2026-05-05: Phase 49 locked `Threadline.Plug` context overrides to additive `request_id` / `correlation_id` fills only, kept actor authority on `actor_fn`, and aligned Sigra plus quickstart docs with that contract.
- 2026-05-05: Phase 50 made `Threadline.Integrations.Sigra` the canonical direct callback pair for `Threadline.Plug` and removed the example-only delegate seam.
- 2026-05-05: Phase 51 kept the incident auth boundary endpoint-local, keyed off `audit_context.actor_ref`, and documented tenancy plus richer authorization as host-owned.
- 2026-05-05: Phase 52 aligned the adopter-facing docs and added cross-doc contract coverage so the shared host-wiring story cannot drift silently.
- 2026-05-05: Close v1.15 as shipped after the milestone audit passed 7/7 requirements, 7/7 integration checks, and 4/4 end-to-end flows.
- 2026-05-05: Continue phase numbering from 48 (no `--reset-phase-numbers`); v1.15 starts at Phase 49.
- 2026-05-05: Skip fresh milestone research — the scope is already grounded in current in-flight repo work and known post-`0.3.0` adoption gaps.
- 2026-04-26: Open v1.14 as "Drop-in Production Adopter Slice" — bundle Sigra integration adapter, performance evidence, incident playbook, threadline 0.3.0 release packaging, and SaaS adopter onramp into one strategic milestone aimed at production adoption.
- 2026-04-26: Promote SEED-001 (Sigra integration adapter) into v1.14 scope — its trigger ("v1.12 ships") has been met since 2026-04-25.
- 2026-04-26: Continue phase numbering from 43 (no `--reset-phase-numbers`); v1.14 starts at Phase 44.
- 2026-04-26: v1.14 phase order is strictly sequential — SIGRA (44) → PERF (45) → INCIDENT (46) → ADOPT (47) → RELEASE (48). RELEASE last because it consolidates CHANGELOG narrative, ExDoc `groups_for_modules` (`Threadline.Integrations.Sigra`), and quotes PERF baseline numbers.
- 2026-04-26: Phase 44 has a blocking `/gsd-spec-phase sigra-integration-adapter` prerequisite; SPEC.md must answer SEED-001 Q1–Q6 (impersonation, org scope, session→correlation, telemetry-vs-Plug, API-token mapping, anonymous fallback) before plan.
- 2026-04-26 (v1.13): Treat README docs drift as a first-class milestone; doc-contract tests must lock README literals so future drift fails CI.
- 2026-04-26 (v1.13): Verification artifacts are first-class milestone output — write `*-VERIFICATION.md` alongside SUMMARY.md, not after.
- 2026-05-05: Close v1.14 as shipped after milestone audit passed 13/13 requirements, 13/13 integration checks, and 4/4 end-to-end flows.
- 2026-05-05: Record the exact clean release candidate as commit `4543690`; keep release verification tied to a clean worktree even when the main workspace is intentionally dirty.
- Created an independent sibling Mix project in bench/ to prevent benchmarking dependencies (benchee, benchee_html) from bleeding into the root library.
- Wrote robust Ecto state management scripts (seed_audit_changes.exs and teardown.exs) that can load or truncate three benchmarking presets (cold_single_table, warm_loaded, concurrent_purge).
- Truncate audit tables before seeding to prevent duplicate key errors
- Isolate benchmarks to verify.bench alias which shells out to the bench sibling application to avoid mixing dependencies into the main workspace.
- Included a BENCHMARK-ENV block to ensure published numbers have reproducible context (hardware, Postgres version, etc).
- Used exact ExUnit doc-contract patterns rather than checking actual numbers to prevent test brittleness as performance evolves.

### Todos

- [x] Define and ship Phase 53 — Timeline Paging Contract
- [x] Define and ship Phase 54 — Investigation Slice APIs
- [x] Define and ship Phase 55 — Incident Bundle Surface
- [x] Define and ship Phase 56 — Docs, Contracts, and Arc Alignment
- [x] Run the v1.16 milestone audit and archive the roadmap and requirements
- [ ] Push milestone tags `v1.15` and `v1.16` when the maintainer is ready
- [ ] Decide whether to cut and push the separate `v0.3.0` release tag once the release surface is committed on the preferred branch

### Blockers

- No blocker to opening the next milestone remains.
- Repo-wide `mix ci.all` still reports pre-existing format drift in untouched files outside the v1.16 closeout set.

## Session Continuity

- **Last Action**: Closed and archived v1.16 after the milestone audit passed.
- **Next Step**: Run `/gsd-new-milestone` and start from `.planning/MILESTONE-ARC.md`, which now points to v1.17 as the standing next recommendation.

## Deferred Items

Items acknowledged and deferred at milestone close on 2026-05-06:

| Category | Item | Status |
|----------|------|--------|
| seed | SEED-001-sigra-integration-adapter | acknowledged stale at close; promoted into Phase 44 and shipped in v1.14 |
| tech_debt | repo-wide-format-drift | pre-existing formatter drift in untouched files still blocks `mix ci.all` |
| nyquist | phase-53-54-validation-bookkeeping | verification evidence exists, but `53-VALIDATION.md` and `54-VALIDATION.md` were not created during milestone execution |
