---
gsd_state_version: 1.0
milestone: v1.18
milestone_name: Adoption and Policy Hardening
status: planning
last_updated: "2026-05-07T00:30:00.000Z"
last_activity: 2026-05-07
resume_file: .planning/phases/64-raw-timeline-browse-and-filter-form/64-01-PLAN.md
stopped_at: "Phase 64 planned (3 plans, 2 waves)"
progress:
  total_phases: 5
  completed_phases: 0
  total_plans: 3
  completed_plans: 0
  percent: 0
---

# Project State: Threadline

## Project Reference

**Core Value**: Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.
**Current Focus**: v1.18 — Adoption and Policy Hardening. Round out the v1.17 operator surface so production teams can roll it out cleanly: raw timeline browse + filter form (full `Threadline.Query.timeline/2` parity, URL-as-state via `live_patch`), exports UI parity (download current view; sync iodata for small / chunked stream for large), coverage dashboard + drift-aware redaction admin (read-only) with parity Mix tasks, and lifecycle ergonomics (onboarding revisit, optional-Phoenix-deps upgrade-path docs, repo-wide format drift cleanup). Continuing phase numbering from Phase 64.

## Current Position

Phase: 64 — Raw Timeline Browse & Filter Form (planned)
Plan: 64-01 / 64-02 / 64-03 (Wave 1: 01+02 parallel; Wave 2: 03 depends on 01)
Status: Ready to execute (`/gsd-execute-phase 64`)
Last activity: 2026-05-07 — Phase 64 plan-phase complete; 3 plans / 2 waves; verification PASSED on iteration 1; BROWSE-01..04 all covered

## Performance Metrics

- **Total Phases**: 5 (Phases 64-68) — defined in `.planning/ROADMAP.md`
- **Phases Completed**: 0 of 5 in active milestone
- **Requirements Covered**: 16 of 16 mapped (BROWSE 4, EXPO 3, COV 3, REDN 3, ADOPT 3)
- **Last Milestone**: v1.17 — Operator Surface Foundation (shipped 2026-05-06, 18/18 requirements, Phases 57–63)

## Accumulated Context

### Decisions

- 2026-05-07: Phase 64 plans landed. 3 plans / 2 waves: Plan 01 (TimelineLive core + router edit + style + back-links on TransactionLive/ActorLive) and Plan 02 (LV integration test, 13 cases) parallel in Wave 1; Plan 03 (BROWSE-04 doc-contract test) in Wave 2. Plan-checker PASSED on iteration 1 (after one revision pass that fixed 2 blockers + 5 warnings: cursor-keyword-sugar grep alignment, viewport-bottom-on-empty-data restructure, `:filters_raw` URL hydration, `assert_patch/1` return shape, ActorLive not_found back-link, F-3 cursor-guard grep enforcement, two missing test cases for BROWSE-02 allowlist drop and BROWSE-03 one-Apply-one-history-entry). All four BROWSE-IDs covered; all 14 D-IDs implemented behaviorally.
- 2026-05-07: Hex 0.4.0 cut between Phase 64 plan-phase and execute-phase (operator-surface foundation release: opt-in web UI behind optional Phoenix/LiveView/HTML/PubSub deps, `:correlation_id` timeline/export filter, export JSON `action` object, CSV `include_action_metadata`, telemetry event table, composition demo). Tagged `v0.4.0`; CI workflow `hex-publish.yml` triggers `mix hex.publish --yes` on tag push. v1.18 closes with 0.5.0.
- 2026-05-06: Phase 64 context captured. Locked 14 implementation decisions (research-then-recommend, four parallel `gsd-advisor-researcher` subagents): (1) **Route**: new TimelineLive mounts at the surface root (`/audit`) — convention follows Oban Web / LiveDashboard / Hangfire / Sentry / GitHub `/audit-log` (firehose = landing page); inline "← Timeline" back-link on TransactionLive / ActorLive header; defer real top-nav to Phase 66 when sibling routes exist. (2) **Filter form**: sticky top toolbar with right-aligned `[Clear all] [Apply]` cluster (Phase 65 will append `[Download CSV] [Download JSON]` to the same cluster); explicit Apply via `<form phx-submit>` (Enter-anywhere submits) — not auto-apply; `phx-debounce="blur"` defensively on text inputs; single "Clear all" link patches to bare path (re-defaults to last 24h). (3) **Input shapes**: `:table` is `<input list>` + `<datalist>` populated from `Threadline.Health.trigger_coverage/1` covered tables only (free-text + native autocomplete, zero JS, stale URLs round-trip with server hint); `:actor_ref` is two flat URL params `actor_kind=` + `actor_id=` (1:1 with `ActorRef` struct, no `kind:id` colon-DSL); `:correlation_id` plain text + `phx-debounce="300"` + `maxlength="256"` + inline help; validation reuses `Threadline.Query.validate_timeline_filters!/1` verbatim. (4) **Pagination**: infinite scroll via `phx-viewport-bottom` + `Phoenix.LiveView.Stream` matching v1.17 TransactionLive / ActorLive pattern; cursor in socket assigns, **never in URL** (URL = filter-state only); `page_size: 50` passed at LV call site (lib's `@default_timeline_page_size = 1000` stays for API/export callers). Tombstone safety: pasted stale URLs re-resolve from "now" through the filter window, no silent stuck-on-empty-cursor failure. Canonical URL contract locked in CONTEXT.md for Phase 65 to reuse verbatim.
- 2026-05-06: v1.18 roadmap landed at 5 phases (64-68): BROWSE → EXPO → COV → REDN → ADOPT. BROWSE first because both EXPO-03's controller and EXPO-05's parity assertion re-validate against the same `validate_timeline_filters!/1` literal the filter form ships. COV and REDN intentionally kept as separate phases (rather than folded into one "policy admin" phase under coarse granularity) because COV-02 has a real lib-API change (`:schema` argument on `Threadline.Health.trigger_coverage/1`) and REDN-04 has the heavyweight `pg_proc.prosrc` introspection logic — different "what could go wrong" risks, mirrors v1.17 Phase 59/60/61 per-screen separation. ADOPT last because onboarding (ADOPT-05) and upgrade-path docs (ADOPT-06) must reflect the surface as it actually shipped; ADOPT-07 (format drift cleanup) is the tidy closing slice. `mix verify.compile_no_optional` stays green across every UI phase as a continuous constraint.
- 2026-05-06: Open v1.18 as "Adoption and Policy Hardening" — once a real operator surface ships (v1.17), the next adoption gap moves from "is there a usable surface?" to "is the surface easy to roll out, upgrade, and govern in production?" v1.18 closes that loop with: raw timeline browse + filter form, exports UI parity (download current view), coverage dashboard + drift-aware redaction admin (read-only), and lifecycle ergonomics. Read-only throughout; zero new platform infrastructure; Mix-task parity for every UI viewer.
- 2026-05-06: v1.18 raw timeline browse ships with full `Threadline.Query.timeline/2` filter parity (5 filters: from, to, table, actor_ref kind+id, correlation_id) — no narrow starter, no saved views. URL-as-state via `live_patch` so links are shareable; reuses `validate_timeline_filters!/1` so UI/API/export share one filter vocabulary. Saved views deferred — would drag a tiny new auth model (owner / visibility / sharing) into a lib that's stayed auth-agnostic since v1.15; bookmarks + URL state cover the persistence story for free, which is what GitHub audit log + Oban Web do at scale. Idiomatic anchor: Oban Web's filter pills.
- 2026-05-06: v1.18 exports UI ships as "download current view" only — sync iodata for small windows (≈≤5,000 rows), chunked stream via `Plug.Conn.send_chunked/2` + `Threadline.Export.stream_changes/2` for large; pre-flight `Threadline.Export.count_matching/2` renders a "what you'll get" preview before click; UTC-ISO filenames + RFC 5987 `filename*=UTF-8''…` + RFC 4180 CSV (no BOM); LiveView event → redirect to a Phoenix controller endpoint with the same filter params (Backpex/Ash Admin pattern). Queued/Oban-backed exports + status page deferred to v1.20+ — adding Oban as a hard dep walks back the v1.17 optional-deps win, and storage adapters are platform creep. Idiomatic anchor: Linear "current filtered view download."
- 2026-05-06: v1.18 ships read-only policy admin viewers — coverage dashboard (wraps `Threadline.Health.trigger_coverage/1` with poll interval + `:schema` option; parity Mix task `mix threadline.health.coverage`) and drift-aware redaction admin (config-vs-deployed reconciliation comparing `config :threadline, :trigger_capture` against per-table `pg_proc.prosrc` introspection, with a "config matches deployed" badge; never displays sample values; parity Mix task `mix threadline.policy.show`). Retention admin deferred to v1.19 because "last purge" stats require net-new `audit_retention_runs` capture machinery (writes from `Threadline.Retention.purge/1`) — that broadens rather than hardens. Naive config-only redaction view rejected — would actively mislead operators after a config edit without `gen.triggers` rerun (Logidze/Carbonite-class footgun). Read-only ceiling holds throughout — no "Purge now" buttons, no runtime policy edits.
- 2026-05-06: Continue phase numbering from 63 (no `--reset-phase-numbers`); v1.18 starts at Phase 64.
- 2026-05-06: v1.18 scope informed by three parallel research subagents (filter form, exports UI, policy admin) returning coherent recommendations citing real Elixir-ecosystem peers (LiveDashboard, Oban Web, Ash Admin, Kaffy, Backpex, Sentry-Elixir) plus cross-language prior art (Linear, Backpex, Sidekiq Pro CSV pain, GitHub audit log, CloudTrail, Sentry, Hangfire, Datadog log retention).
- Phase 63 Plan 01: Kept the core library README lean by providing a 1-minute mount example and delegating policy details to the new comprehensive guide.

- Phase 60 Plan 02: Used Phoenix.LiveView for rendering the actor window screen to allow dynamic time window updates.
- Phase 60 Plan 02: Updated the operator surface router to include the new LiveView route /audit/actors/:actor_type/:actor_id.
- Phase 60 Plan 01: Extracted pagination state to a distinct ActorHistoryPage struct mimicking TimelinePage for predictable operator DX.
- Phase 60 Plan 01: Dropped the previous behavior of returning a raw list in favor of ActorHistoryPage, explicitly adopting keyset navigation parameters.

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

- [ ] Push milestone tags `v1.15`, `v1.16`, and `v1.17` when the maintainer is ready
- [ ] Decide whether to cut and push the separate `v0.3.0` release tag once the release surface is committed on the preferred branch
- [x] Write `.planning/REQUIREMENTS.md` for v1.18 (REQ-IDs across raw timeline browse, exports UI, coverage dashboard, drift-aware redaction admin, lifecycle ergonomics)
- [x] Spawn `gsd-roadmapper` to phase v1.18 starting at Phase 64 — completed 2026-05-06; ROADMAP.md written with 5 phases (64-68), 16/16 requirements mapped
- [ ] Plan Phase 64 (Raw Timeline Browse & Filter Form) — first phase of v1.18; run `/gsd-plan-phase 64` next
- [ ] Repo-wide `mix format` drift cleanup — clears the open `mix ci.all` blocker tracked since v1.16 (will land in Phase 68 via ADOPT-07)

### Blockers

- No blocker to v1.18 execution remains.
- Repo-wide `mix ci.all` still reports pre-existing format drift in untouched files outside the v1.16/v1.17 closeout sets — will be closed by Phase 68 (ADOPT-07).

## Session Continuity

- **Last Action**: v1.18 ROADMAP.md written. 5 phases (64-68): Raw Timeline Browse & Filter Form → Exports UI Parity → Coverage Dashboard & Mix Task Parity → Drift-Aware Redaction Admin & Mix Task Parity → Lifecycle Ergonomics. 16/16 requirements mapped (BROWSE-01..04 → 64; EXPO-03..05 → 65; COV-01..03 → 66; REDN-03..05 → 67; ADOPT-05..07 → 68). REQUIREMENTS.md traceability table updated (all `TBD`/`pending` → phase numbers + `mapped`).
- **Next Step**: Run `/gsd-plan-phase 64` to plan the Raw Timeline Browse & Filter Form phase.

## Deferred Items

Items acknowledged and deferred at milestone close on 2026-05-06:

| Category | Item | Status |
|----------|------|--------|
| seed | SEED-001-sigra-integration-adapter | acknowledged stale at close; promoted into Phase 44 and shipped in v1.14 |
| tech_debt | repo-wide-format-drift | pre-existing formatter drift in untouched files still blocks `mix ci.all` — scheduled for v1.18 Phase 68 (ADOPT-07) |
| nyquist | phase-53-54-validation-bookkeeping | verification evidence exists, but `53-VALIDATION.md` and `54-VALIDATION.md` were not created during milestone execution |
