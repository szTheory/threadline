---
gsd_state_version: 1.0
milestone: v1.17
milestone_name: — Operator Surface Foundation
status: executing
last_updated: "2026-05-06T15:35:00Z"
last_activity: 2026-05-06 -- Phase 57 verified and closed; 2 manual-only items deferred to HUMAN-UAT
progress:
  total_phases: 7
  completed_phases: 1
  total_plans: 1
  completed_plans: 1
  percent: 14
---

# Project State: Threadline

## Project Reference

**Core Value**: Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.
**Current Focus**: v1.17 — Operator Surface Foundation. Mountable in-tree LiveView surface (optional Phoenix/LiveView deps), incident drill-down + actor window must-have screens, row history + as-of sub-view, host-mount-default auth with optional `:authorize_fn` and compile-time fail-closed check, telemetry, Mix-task parity. Continuing phase numbering from Phase 57.

## Current Position

Phase: 58 — Mount Macro & Auth Contract
Plan: 02
Status: executing
Last activity: 2026-05-06T16:02:34Z -- Completed 58-01-PLAN.md

## Performance Metrics

- **Total Phases**: 7 planned in v1.17
- **Phases Completed**: 1 of 7 in active milestone (Phase 57 — single-plan phase)
- **Requirements Covered**: 18/18 in v1.17 (2/18 validated: SURF-02, SURF-03)
- **Last Milestone**: v1.16 (Shipped 2026-05-06)

| Phase | Plan | Duration | Tasks | Files |
|-------|------|----------|-------|-------|
| 57    | 01   | ~35 min  | 5     | 4     |
| 58    | 01   | ~5 min   | 2     | 4     |

## Accumulated Context

### Decisions

- 2026-05-06: Operator surface sub-modules use same gating macro as root namespace module

- 2026-05-06: Phase 57 verified and closed — gsd-verifier confirmed 5/5 must-have truths, all artifacts present, all key-links wired, both compile legs (LV-present and LV-absent) clean. User approved phase close with 2 manual-only items persisted in `57-HUMAN-UAT.md` (GH Actions CI confirmation + discretionary hexdocs preview). Code review found 0 blockers / 0 warnings / 1 info (doc hygiene suggestion). Phase boundary discipline holds — none of the deferred Phase 58-63 items leaked in.
- 2026-05-06: Phase 57 plan 01 shipped — `mix.exs` declares `phoenix`, `phoenix_live_view`, `phoenix_html`, `phoenix_pubsub` as `optional: true`; `Threadline.OperatorSurface` namespace module created with file-scope `if Code.ensure_loaded?(Phoenix.LiveView) do defmodule ... end end` wrapper (Sentry `live_view_hook.ex` idiom); `mix verify.compile_no_optional` alias added and folded into `ci.all`; dedicated stable-id `verify-compile-no-optional` GitHub Actions job added; `CONTRIBUTING.md` row added. Five atomic commits (4281556, b8e7044, 409d135, 5d0aebf, 719d7ac). SURF-02 + SURF-03 validated. Pre-existing `mix verify.format` drift in 7 files outside Phase 57 scope remains a known blocker (recorded below) — surfaced not fixed per Task 5 scope discipline.
- 2026-05-06: Phase 57 context captured. Locked four implementation decisions (research-then-recommend, four parallel subagents): (1) `phoenix ~> 1.7`, `phoenix_live_view ~> 1.0`, `phoenix_html ~> 4.0`, `phoenix_pubsub ~> 2.1` declared `optional: true` (greenfield, drops 0.20.x branch); (2) ship one gated namespace module `lib/threadline/operator_surface.ex` with `@moduledoc` only — modeled verbatim on `getsentry/sentry-elixir`'s `lib/sentry/live_view_hook.ex` file-scope `if Code.ensure_loaded?(Phoenix.LiveView) do defmodule ... end` shape; (3) verification via new `mix verify.compile_no_optional` alias + folded into `ci.all` + dedicated immutable-id GitHub Actions job `verify-compile-no-optional` (Sentry's CI gap is an acknowledged omission, not a model to replicate); (4) `:plug` stays a HARD dep — Phase 57 roadmap scopes optionality to Phoenix/LiveView only. Doc-contract test for the gated namespace deferred to Phase 58 alongside the first behavioural module.
- 2026-05-06: Open v1.17 as "Operator Surface Foundation" — turn the v1.16 investigation contracts into a host-usable operator surface; the next adoption bottleneck is presentation/usability, not more raw exploration plumbing.
- 2026-05-06: v1.17 ships the operator surface in-tree (`Threadline.OperatorSurface.Router`) with `phoenix`, `phoenix_live_view`, `phoenix_html`, `phoenix_pubsub` declared as **optional deps** (gated via `Code.ensure_loaded?(Phoenix.LiveView)`), so capture-only adopters retain a Plug-only install footprint. Splitting into a separate `threadline_web` companion package is deferred to v1.19+ with a documented promotion path; LiveDashboard / Oban Web / Ash Admin all split *after* their core had hundreds of adopters, and at v0.3.0 with one maintainer the double-tagging + version-matrix burden is premature. Idiomatic anchor: `sentry-elixir` keeps Phoenix/LiveView integrations optional in-tree without a companion package.
- 2026-05-06: v1.17 first slice ships two must-have screens — incident drill-down (renders `Threadline.incident_bundle/2`) and actor window (renders `actor_history/2`, deep-links into drill-down) — plus a should-have row history + as-of sub-view reachable from drill-down rows. Defers raw paged timeline browse to v1.18 (needs filter form, own scope). Together the must-haves answer 4 of 6 documented support questions on click 1 and match the dominant audit-console pattern (actor entry → transaction detail) seen across CloudTrail, Sentry, Okta, GitHub.
- 2026-05-06: v1.17 ships `mix threadline.incident <transaction_id>` Mix task as a no-LiveView operator path with parity data — adopters who SSH into a box don't need to mount the surface to answer the marquee question.
- 2026-05-06: v1.17 auth contract is host-mount default + optional `:authorize_fn` callback (mirrors `Threadline.Plug`'s `:actor_fn` shape). Fails closed at compile time unless one of (a) the scope has at least one `pipe_through`, (b) `:authorize_fn` is supplied, or (c) `:adopter_acknowledges_unauthenticated: true` is explicit (raises in test, loud `Logger.warning` in prod). Telemetry event `[:threadline, :operator_surface, :authorize]` with `:granted | :denied | :error`. Multi-tenancy stays host-owned; `{:ok, scope}` from `:authorize_fn` is threaded into investigation queries. Idiomatic anchor: Hangfire's fail-closed default + Oban Web's resolver behaviour, adapted. Coheres with v1.15 host-owns-auth boundary.
- 2026-05-06: PROJECT.md "Out of Scope" updated — "LiveView operator UI" replaced with "Hard LiveView/Phoenix dependency in `threadline` core" (the v1.17 surface is opt-in via optional deps); "`threadline_web` companion package" reframed as deferred to v1.19+ with documented migration path.
- 2026-05-06: Continue phase numbering from 56 (no `--reset-phase-numbers`); v1.17 starts at Phase 57.
- 2026-05-06: Targeted research replaced general project ecosystem research for v1.17 — three parallel dimension-specific agents (surface shape, workflow scope, auth model) returned coherent recommendations citing real Elixir-ecosystem peers (LiveDashboard, Oban Web, Ash Admin, Kaffy, Backpex, Sentry-Elixir, Carbonite) plus cross-language prior art (CloudTrail, Sentry, Okta, GitHub, Hangfire, Sidekiq Web, Django Reversion).
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
- [x] Write `.planning/REQUIREMENTS.md` for v1.17 (REQ-IDs across surface shape, screens, mix task, auth, telemetry, doc contracts, example app)
- [x] Spawn `gsd-roadmapper` to phase v1.17 starting at Phase 57
- [x] Plan Phase 57 — `/gsd-plan-phase 57`
- [x] Execute Phase 57 plan 01 — optional deps, gated namespace module, verify gate, CI job, CONTRIBUTING row
- [ ] Plan Phase 58 — `/gsd-plan-phase 58` (mount macro + auth contract + telemetry event)

### Blockers

- No blocker to v1.17 planning remains.
- Repo-wide `mix ci.all` still reports pre-existing format drift in untouched files outside the v1.16 closeout set.

## Session Continuity

- **Last Action**: Phase 57 verified and closed — gsd-code-reviewer found 0 blockers / 0 warnings / 1 info (doc hygiene); gsd-verifier confirmed 5/5 must-have truths via direct codebase inspection plus cold-build behavioural checks (`mix verify.compile_no_optional` exits 0 with zero warnings; gated BEAM correctly absent in no-optional-deps build); user approved close. Phase artifacts: 57-01-SUMMARY.md, 57-REVIEW.md, 57-VERIFICATION.md, 57-HUMAN-UAT.md.
- **Next Step**: `/gsd-plan-phase 58` to plan the mount macro + `:authorize_fn` contract + compile-time fail-closed check + `[:threadline, :operator_surface, :authorize]` telemetry event (Phase 58 also picks up the deferred doc-contract test for "OperatorSurface defined when LV present, absent when LV missing" per CONTEXT.md D-14).

## Deferred Items

Items acknowledged and deferred at milestone close on 2026-05-06:

| Category | Item | Status |
|----------|------|--------|
| seed | SEED-001-sigra-integration-adapter | acknowledged stale at close; promoted into Phase 44 and shipped in v1.14 |
| tech_debt | repo-wide-format-drift | pre-existing formatter drift in untouched files still blocks `mix ci.all` |
| nyquist | phase-53-54-validation-bookkeeping | verification evidence exists, but `53-VALIDATION.md` and `54-VALIDATION.md` were not created during milestone execution |
