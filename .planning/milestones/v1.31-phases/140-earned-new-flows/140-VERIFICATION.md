---
phase: 140-earned-new-flows
verified: 2026-06-04T16:33:08Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 0
---

# Phase 140: Earned New Flows Verification Report

**Phase Goal:** Build the JTBD-traced new flows: record-first lookup from Home (cordoned path, no filter-building), a closed export loop (filtered Timeline/Evidence view -> pre-populated export), correlation-id paste/deep-link from Home, and first-class row-history entry (not only from inside a transaction). Each flow traces to a persona JTBD + a decision record. Done after the hub and screens exist.
**Verified:** 2026-06-04T16:33:08Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A support operator can look up one record's history from Home without building filters. | VERIFIED | `StartLive` renders EF1 record lookup with only a mapped table select and record id input, validates blank/unmapped inputs, and navigates to `/rows/:table/:record_id`; no Home filter-builder controls are introduced. Covered by `start_live_test.exs` and Playwright EF1. |
| 2 | A reviewer can carry a filtered Timeline/Evidence view into a pre-populated export (closed loop). | VERIFIED | `TimelineLive` carries `@filter_query` into `/exports`; `ExportStatusLive` parses Timeline context through `FilterParams`, validates it, renders a visible EF3 context, and queues actor-owned `ExportJob`s only when exports are enabled. `EvidenceLive` carries explicit proof-context keys; `ExportStatusLive` renders a separate Evidence banner and does not treat Evidence params as Timeline file-export filters. Covered by Timeline, Evidence, ExportStatus, ExportController tests and Playwright EF3. |
| 3 | An incident responder can paste or deep-link a `correlation_id` from Home. | VERIFIED | `StartLive.handle_event("open-correlation")` trims input, rejects blank and >256-byte values, delegates query encoding to `FilterParams.canonical_query/1`, and navigates to `/timeline?correlation_id=...`; `TimelineLive` renders the canonical `#filter-correlation-id` field. Covered by `start_live_test.exs`, `timeline_live_test.exs`, and Playwright EF4. |
| 4 | Row history is reachable as a first-class entry, not only from inside a transaction. | VERIFIED | Router mounts `live("/rows/:table/:record_id", RowHistoryLive, :show)`; `RowHistoryLive` wraps `RowHistoryComponent` with explicit first-class `history_path` and `close_path`; the component uses `Threadline.history/3` and `Threadline.as_of/4`. Existing transaction-scoped row-history behavior is preserved by `transaction_live_test.exs`. |
| 5 | Each new flow traces to a named persona JTBD and a recorded decision; no speculative flows shipped. | VERIFIED | EF/persona/JTBD attributes are present for EF1 P2/J4, EF2 P1/J2, EF3 P3/J6, and EF4 P1/J1 in code and tests. `140-CONTEXT.md` records D-01 through D-10 plus EF1-EF4; tests/source guards check the absence of speculative Home builders and Plan 05 excludes Phase 141/142 scope. |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/threadline/operator_surface/router.ex` | First-class row-history route and guarded export HTTP scope | VERIFIED | Route exists under the existing LiveView session; export routes remain behind `ExportAuthPlug`. |
| `lib/threadline/operator_surface/live/row_history_live.ex` | First-class row-history LiveView shell | VERIFIED | Assigns route params, base/history/close paths, repo/scope data, and EF2 trace attributes. |
| `lib/threadline/operator_surface/live/row_history_component.ex` | Reused row-history renderer and query path | VERIFIED | Resolves schemas from configured map without `String.to_atom/1`; calls `Threadline.history/3` and `Threadline.as_of/4`. |
| `lib/threadline/operator_surface/live/start_live.ex` | Home EF1 and EF4 controls | VERIFIED | Implements record lookup and correlation lookup with validation, canonical encoding, route navigation, and trace attributes. |
| `lib/threadline/operator_surface/live/timeline_live.ex` | Timeline EF3 carry affordance | VERIFIED | Renders `Carry to Exports` only when exports are enabled and uses canonical `@filter_query`. |
| `lib/threadline/operator_surface/live/export_status_live.ex` | Timeline/Evidence pre-populated export contexts | VERIFIED | Separates Timeline filter context from Evidence proof context, validates both, and gates queue actions on export auth. |
| `lib/threadline/operator_surface/live/evidence_live.ex` | Evidence EF3 carry affordance | VERIFIED | Builds `source=evidence` URLs with only proof-context keys and trace attributes. |
| `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` | Focused browser UAT for EF1-EF4 | VERIFIED | Spec covers Home record-first, direct row-history, Home correlation, Timeline carry, Evidence carry, and narrow overflow smoke checks. |
| Phase 140 test files | ExUnit coverage for routes, auth, validation, and regressions | VERIFIED | `gsd-sdk query verify.artifacts` passed for all five plans; local combined ExUnit gate passed, 124 tests / 0 failures. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `router.ex` | `RowHistoryLive` | `live("/rows/:table/:record_id", RowHistoryLive, :show)` | WIRED | Mounted under the existing operator surface `live_session`. |
| `RowHistoryLive` | `RowHistoryComponent` | `<.live_component module={RowHistoryComponent} ...>` | WIRED | Passes table, record id, schema map, repo, scope, scope query function, close path, and history path. |
| `RowHistoryComponent` | `Threadline` query API | `Threadline.history/3`, `Threadline.as_of/4` | WIRED | Reuses the existing row-history query path with scope-aware options. |
| `StartLive` | first-class row history | `push_navigate` to `/rows/:table/:record_id` | WIRED | Uses mapped table validation and path-segment encoding. |
| `StartLive` | Timeline correlation filter | `FilterParams.canonical_query/1` then `/timeline?...` | WIRED | Preserves canonical Timeline filter semantics. |
| `TimelineLive` | `ExportStatusLive` | `/exports?#{@filter_query}` | WIRED | Link carries canonical allowed Timeline filters only. |
| `ExportStatusLive` | `FilterParams` / `Threadline.Query` | parse, canonicalize, validate, queue | WIRED | Unknown keys are dropped and invalid filters render error state without queuing. |
| `EvidenceLive` | `ExportStatusLive` | `/exports?source=evidence&...` | WIRED | Carries explicit proof-context keys only. |
| `ExportStatusLive` | `EvidenceLive` | Reopen Evidence proof link | WIRED | Valid Evidence context renders a return path to the source proof view. |
| export HTTP routes | `ExportAuthPlug` | router pipeline `:threadline_exports` | WIRED | Direct CSV/JSON/NDJSON/download endpoints remain guarded. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `RowHistoryComponent` | `history`, `snapshot_result` | `Threadline.history(schema_module, record_id, opts)` and `Threadline.as_of(schema_module, record_id, as_of_dt, opts)` | Yes | FLOWING |
| `StartLive` | `record_table_options` | configured `threadline_schemas` assign | Yes | FLOWING |
| `TimelineLive` | `@filter_query`, `@filters_raw`, streamed changes | `FilterParams` plus `Threadline.Query.timeline_page` | Yes | FLOWING |
| `ExportStatusLive` | `timeline_export_context` | URL params -> `FilterParams` -> `Threadline.Query.validate_timeline_filters!/1` | Yes | FLOWING |
| `ExportStatusLive` | `evidence_export_context` | URL params -> Evidence subject/ref/mode parser -> banner/reopen path | Yes | FLOWING |
| `EvidenceLive` | `groups`, `request` | Evidence APIs (`list_overview`, `list_latest_subject_refs`, `get_latest_subject_ref`, `list_subject_ref_history`) | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Combined Phase 140 ExUnit gate | `mix test test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/row_history_component_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/style_contract_test.exs` | 124 tests, 0 failures | PASS |
| Schema drift | `gsd-sdk query verify.schema-drift 140 --raw` | `drift_detected: false`, `blocking: false` | PASS |
| Browser UAT | `cd examples/threadline_phoenix/e2e && E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-earned-flows.spec.ts` | Local rerun could not connect to `127.0.0.1:4002` because no example server was running; orchestrator evidence for the same command reports 15 tests, 0 failures after seeded server setup. | VERIFIED BY ORCHESTRATOR EVIDENCE |

### Probe Execution

| Probe | Command | Result | Status |
|---|---|---|---|
| None declared | `find scripts -path '*/tests/probe-*.sh'` and phase plan/summary probe scan | No Phase 140 probes found | SKIPPED |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| `POLISH-FLOWS` | 140-01 through 140-05 | Home record-first lookup, Timeline/Evidence export carry-forward, Home correlation paste/deep-link, first-class row history | SATISFIED | All five roadmap truths verified; ExUnit gate passes; browser UAT spec exists and orchestrator passing evidence covers EF1-EF4. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| Phase 140 modified files | n/a | No unreferenced `TBD`, `FIXME`, or `XXX`; no user-visible placeholders or hollow Phase 140 implementations found | INFO | Benign empty-state checks and test assertions for empty lists were reviewed and are not stubs. |

### Human Verification Required

None. Browser UAT was already executed by the orchestrator against a seeded example app server and passed. My local browser rerun was environment-blocked by the missing server, not by an application failure.

### Gaps Summary

No blocking gaps found. The Phase 140 goal is achieved in the codebase, with route/query wiring, data flow, authorization gates, trace attributes, and focused automated coverage present.

---

_Verified: 2026-06-04T16:33:08Z_
_Verifier: the agent (gsd-verifier)_
