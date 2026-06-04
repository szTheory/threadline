---
phase: 140-earned-new-flows
planned: 2026-06-04
status: planning-validation
plans: 5
waves: 3
requirements: [POLISH-FLOWS]
---

# Phase 140 Planning Validation

## Outcome

Phase 140 is planned as five executable, dependency-aware plans covering the four earned flows plus browser UAT:

| Plan | Wave | Objective | Requirements |
|------|------|-----------|--------------|
| `140-01-PLAN.md` | 1 | First-class row-history route and safe route-aware component paths | POLISH-FLOWS |
| `140-02-PLAN.md` | 2 | Home record-first lookup and correlation paste/deep-link | POLISH-FLOWS |
| `140-03-PLAN.md` | 1 | Timeline filtered context carried into Exports | POLISH-FLOWS |
| `140-04-PLAN.md` | 2 | Evidence proof context carried into Exports | POLISH-FLOWS |
| `140-05-PLAN.md` | 3 | Focused browser UAT for EF1, EF2, EF3, and EF4 | POLISH-FLOWS |

## Dependency Graph

| Plan | Needs | Creates | Wave |
|------|-------|---------|------|
| `140-01` | Existing router, `RowHistoryComponent`, transaction route tests | `/rows/:table/:record_id`, `RowHistoryLive`, safe component paths | 1 |
| `140-03` | Existing Timeline filters, Exports monitor, export auth/controller tests | Timeline carry link, Exports Timeline context banner/queue action | 1 |
| `140-02` | `140-01` first-class row-history target, Phase 139 Home baseline | Home EF1 and EF4 controls | 2 |
| `140-04` | `140-03` Exports context structure, Evidence parser | Evidence EF3 proof-context handoff | 2 |
| `140-05` | `140-02` Home entries, `140-04` completed export handoffs | Cross-surface browser UAT | 3 |

Same-wave file overlap check:

| Wave | Plans | Shared files |
|------|-------|--------------|
| 1 | `140-01`, `140-03` | none |
| 2 | `140-02`, `140-04` | none |
| 3 | `140-05` | none |

## Multi-Source Coverage Audit

| SOURCE | ID | Feature / Requirement | Plan | Status | Notes |
|--------|----|-----------------------|------|--------|-------|
| GOAL | Phase 140 | Record-first lookup from Home | 140-01, 140-02, 140-05 | COVERED | Row-history route target first, Home entry second, browser proof last. |
| GOAL | Phase 140 | Closed export loop from filtered Timeline/Evidence into Exports | 140-03, 140-04, 140-05 | COVERED | Timeline filter context and Evidence proof context are separate to preserve export semantics. |
| GOAL | Phase 140 | Correlation-id paste/deep-link from Home | 140-02, 140-05 | COVERED | Uses `FilterParams.canonical_query/1` and Timeline validation. |
| GOAL | Phase 140 | First-class row-history entry | 140-01, 140-05 | COVERED | Dedicated `/rows/:table/:record_id` route, browser direct-route proof. |
| GOAL | Phase 140 | Persona/JTBD/decision trace and no speculative flows | 140-01, 140-02, 140-03, 140-04, 140-05 | COVERED | Plans require EF/persona/JTBD trace attributes plus negative scope guards. |
| REQ | POLISH-FLOWS | Support operator can look up one record's history from Home without filters | 140-01, 140-02, 140-05 | COVERED | Maps to EF1 / P2 / J4. |
| REQ | POLISH-FLOWS | Reviewer can carry filtered Timeline/Evidence view into pre-populated export context | 140-03, 140-04, 140-05 | COVERED | Maps to EF3 / P3 / J6. |
| REQ | POLISH-FLOWS | Incident responder can paste/deep-link `correlation_id` from Home | 140-02, 140-05 | COVERED | Maps to EF4 / P1 / J1. |
| REQ | POLISH-FLOWS | Row history reachable as first-class entry | 140-01, 140-05 | COVERED | Maps to EF2 / P1 / J2. |
| RESEARCH | Route recommendation | Add `/rows/:table/:record_id` thin LiveView wrapper | 140-01 | COVERED | Uses existing `RowHistoryComponent`. |
| RESEARCH | Security pitfall | Avoid `String.to_atom/1` on untrusted table input | 140-01 | COVERED | Source contract and schema-map validation required. |
| RESEARCH | Path pitfall | Make component close/as-of paths route-aware | 140-01 | COVERED | Preserves transaction route behavior. |
| RESEARCH | Home controls | Home owns record-first and correlation entries | 140-02 | COVERED | Depends on route target from Plan 01. |
| RESEARCH | Filter allowlist | Use `FilterParams` for correlation and Timeline export context | 140-02, 140-03 | COVERED | No ad hoc Timeline query parser. |
| RESEARCH | Export auth | Keep direct downloads under `ExportAuthPlug`; gate LiveView controls | 140-03, 140-04 | COVERED | Controller regression tests included. |
| RESEARCH | Evidence pitfall | Evidence params are proof context, not Timeline export filters | 140-04 | COVERED | Separate proof-context banner and no direct file-filter passthrough. |
| RESEARCH | Browser UAT | Add focused `operator-earned-flows.spec.ts` | 140-05 | COVERED | Uses seeded `walk-acme-4521-close` and existing helpers. |
| RESEARCH | Package audit | No new external packages | all | COVERED | Threat register includes package-install stop condition. |
| CONTEXT | D-01 | Ship only the four roadmap-listed flows | all | COVERED | Negative guards in Plans 02, 03, 04, 05. |
| CONTEXT | D-02 | Keep Home as entry for record-first and correlation paste | 140-02 | COVERED | Home owns EF1 and EF4 controls. |
| CONTEXT | D-03 | Record-first path is cordoned, plain-language schema/table + id | 140-01, 140-02 | COVERED | Schema-map selector and row-history route, no Timeline filter builder. |
| CONTEXT | D-04 | Correlation paste/deep-link reuses existing Timeline semantics with validation | 140-02 | COVERED | `FilterParams` + 256-byte guard. |
| CONTEXT | D-05 | Closed export loop is context carry-forward, not a new builder | 140-03, 140-04 | COVERED | Timeline queue context and Evidence proof-context banner. |
| CONTEXT | D-06 | First-class row-history reuses existing components/query constraints | 140-01 | COVERED | Thin wrapper over `RowHistoryComponent`. |
| CONTEXT | D-07 | Every flow traces to persona/JTBD/earned-flow record | all | COVERED | EF/P/J attributes and browser assertions required. |
| CONTEXT | D-08 | Preserve Phase 139 Home/nav baseline | 140-02, 140-05 | COVERED | Home tests preserve scope/header/health/saved-view baseline; browser scope kept narrow. |
| CONTEXT | D-09 | Use existing primitives, `FilterParams`, `Threadline.Query`, export/auth/scoping seams | all | COVERED | Each plan consumes local seams before adding wrappers. |
| CONTEXT | D-10 | Focused ExUnit and browser validation | all | COVERED | Tests-first tasks plus final Playwright spec. |

Deferred ideas excluded from planning: Phase 141 motion, Phase 142 responsive matrix, screenshot-diff infrastructure, bulk export lifecycle redesign, advanced saved search/query builder, and unlisted persona flows.

## Goal-Backward Must-Haves

Observable truths:

1. A support operator can use Home to reach one row's history without Timeline filters.
2. A reviewer can carry active Timeline filter context into Exports.
3. A reviewer can carry Evidence proof context into Exports without Evidence params becoming Timeline file filters.
4. An incident responder can paste a correlation id on Home and land on Timeline correlation results.
5. Row history is a first-class route.
6. Scoped operators, export authorization, table validation, filter allowlisting, and invalid inputs remain guarded.
7. Browser UAT proves the four flows and trace IDs without broadening into Phase 141/142 work.

Required artifacts:

| Artifact | Provides |
|----------|----------|
| `lib/threadline/operator_surface/live/row_history_live.ex` | First-class row-history route wrapper |
| `lib/threadline/operator_surface/router.ex` | Mounted `/rows/:table/:record_id` route |
| `lib/threadline/operator_surface/live/row_history_component.ex` | Safe schema lookup and route-aware row-history paths |
| `lib/threadline/operator_surface/live/transaction_live.ex` | Existing transaction row-history invocation updated only if route-aware path assigns require it |
| `lib/threadline/operator_surface/live/start_live.ex` | Home EF1 and EF4 controls |
| `lib/threadline/operator_surface/live/timeline_live.ex` | Timeline EF3 carry-to-Exports link |
| `lib/threadline/operator_surface/live/export_status_live.ex` | Timeline/Evidence context banners and queue behavior |
| `lib/threadline/operator_surface/live/evidence_live.ex` | Evidence EF3 proof-context handoff |
| `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` | Browser UAT for EF1, EF2, EF3, EF4 |

Key links:

| From | To | Via |
|------|----|-----|
| Home record form | Row history route | `/audit/rows/:table/:record_id` |
| Home correlation form | Timeline | `FilterParams.canonical_query/1` |
| Timeline filters | Exports | `/audit/exports?...` allowed filters |
| Evidence proof view | Exports | `source=evidence` proof-context params |
| Exports context queue | Export jobs | actor-owned `ExportJob.query_params` |
| Row-history route | scoped query | `Threadline.history/3`, `Threadline.as_of/4`, `surface: :row_history` |

## Planned Verification Commands

Per-plan commands:

- `mix test test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/row_history_component_test.exs test/threadline/operator_surface/transaction_live_test.exs`
- `mix test test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/style_contract_test.exs`
- `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs`
- `mix test test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs`
- `cd examples/threadline_phoenix/e2e && E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-earned-flows.spec.ts`

Phase gate command:

```bash
mix test test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/row_history_component_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs
```

Browser gate requires a seeded example app server, then:

```bash
cd examples/threadline_phoenix/e2e && E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-earned-flows.spec.ts
```

## Non-Goal Guardrails

- No new package dependencies.
- No schema migrations.
- No broad responsive redesign, breakpoint matrix, or screenshot baseline work.
- No motion or animation work.
- No advanced query DSL or general search builder.
- No bulk export lifecycle redesign.
- No direct Evidence params in Timeline file export links.
- No route/query changes outside the four earned flows.

## Planner Validation

To be run after writing plans:

- `gsd-sdk query frontmatter.validate .planning/phases/140-earned-new-flows/140-01-PLAN.md --schema plan`
- `gsd-sdk query verify.plan-structure .planning/phases/140-earned-new-flows/140-01-PLAN.md`
- Repeat for `140-02` through `140-05`.

Expected result: all plan frontmatter and XML task structure are valid.
