---
gsd_state_version: 1.0
milestone: v1.15
milestone_name: Host Integration Completion
status: completed
last_updated: "2026-05-05T20:40:00.000Z"
last_activity: 2026-05-05
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
**Current Focus**: Phase 52 shipped; next work is auditing and closing milestone v1.15.

## Current Position

Phase: 52 — Docs and Contract Alignment
Plan: complete
Status: Ready to audit and close milestone v1.15
Last activity: 2026-05-05

## Performance Metrics

- **Total Phases**: 4 planned in v1.15 (Phases 49–52)
- **Phases Completed**: 4
- **Requirements Covered**: 7/7 complete for v1.15
- **Last Milestone**: v1.14 (Shipped 2026-05-05)

## Accumulated Context

### Decisions

- 2026-05-05: Open v1.15 as "Host Integration Completion" — formalize the native `Threadline.Plug` host-wiring hook, direct Sigra callback composition, an authenticated incident drill-down baseline, and the doc/test alignment that keeps that adopter story stable.
- 2026-05-05: Phase 49 locked `Threadline.Plug` context overrides to additive `request_id` / `correlation_id` fills only, kept actor authority on `actor_fn`, and aligned Sigra plus quickstart docs with that contract.
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

- [ ] Audit and close milestone v1.15 after the remaining dirty-worktree decisions are resolved
- [ ] Decide whether the current dirty worktree should be snapshotted as the first v1.15 implementation batch before broader execution continues
- [ ] Decide whether to merge or otherwise retain the isolated clean release candidate commit `4543690` in the mainline history
- [ ] Push milestone tag `v1.14` and release tag `v0.3.0` when the maintainer is ready

### Blockers

- The main workspace remains intentionally dirty, so milestone closeout should continue treating the remaining code changes as in-flight v1.15 work rather than a clean release tree.

## Session Continuity

- **Last Action**: Executed Phase 52, aligned the adopter-facing docs with the direct Sigra host-wiring plus authenticated incident baseline, and locked that wording with focused contract tests.
- **Next Step**: Run `/gsd-audit-milestone v1.15` and then `/gsd-complete-milestone` once the remaining dirty-worktree decisions are resolved.

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| seed | SEED-001-sigra-integration-adapter | acknowledged stale at close; promoted into Phase 44 and shipped in v1.14 |
| Phase 45 P01 | 4m | 2 tasks | 6 files |
| Phase 45-bench-harness-published-baselines P02 | 5m | 2 tasks | 4 files |
| Phase 45 P03 | 3 | 2 tasks | 2 files |
| Phase 45 P04 | 5 | 2 tasks | 2 files |
