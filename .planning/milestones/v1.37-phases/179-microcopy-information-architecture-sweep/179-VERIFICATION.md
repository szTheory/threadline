---
phase: 179-microcopy-information-architecture-sweep
verified: 2026-06-19T21:02:00Z
status: passed
score: "30/30 must-haves verified"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 179: Microcopy & Information-Architecture Sweep Verification Report

**Phase Goal:** Sweep all UI copy and information architecture to brand voice, banned-vocabulary, and domain-language standards with a GOV.UK least-surprise / progressive-disclosure lens that preserves power-user efficiency.
**Verified:** 2026-06-19T21:02:00Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Roadmap SC1: All UI copy follows brand voice and avoids banned vocabulary; state/destructive/error copy follows object, consequence, no-blame patterns. | VERIFIED | `copy_contract_test.exs` rejects exclamation marks, title-case state leaks, primary CamelCase model names, broad proof wording, and missing full copy targets; `mix test ...` passed 305 tests. |
| 2 | Roadmap SC2: Domain language is consistent across headings, tabs, filters, buttons, and alerts. | VERIFIED | Runtime copy uses transaction, row-level changes, actor, correlation id, covered/need capture, redaction policy, retention window, Evidence, proof history only in allowed detail contexts; tests assert those terms. |
| 3 | Roadmap SC3: IA follows least-surprise/progressive disclosure while preserving keyboard support, dense views, stable URLs, copyable IDs, and direct links. | VERIFIED | Shell/Home/Timeline/Evidence/Exports/Retention E2E specs passed; route hrefs, URL state, direct links, and `data-tl-copy` contracts are asserted. |
| 4 | 179-01 D-01/D-02: Shell uses task/domain-led group labels while routes, URL shapes, current atoms, and test IDs remain unchanged. | VERIFIED | `surface_header.ex` renders `Investigate`, `Audit readiness`, `Evidence & exports`; `surface_header_test.exs` asserts legacy ids/hrefs/data-testids/order. |
| 5 | 179-01 D-01/D-03: Overview remains reachable and Home jobs are renamed in the same change. | VERIFIED | `start_live.ex` renders `Find what changed`, `Check audit readiness`, `Use evidence and exports`; tests and mobile E2E assert the same routes. |
| 6 | 179-01 D-04/D-16: Copy-contract tests reject primary UI CamelCase model names while allowing code-ish and advanced contexts. | VERIFIED | `copy_contract_test.exs` defines model-name/title-case/proof allowlists and negative assertions over rendered shell/Home text. |
| 7 | 179-01 COPY-01/COPY-02/COPY-03: Guard-first coverage exists before broad copy edits proceed. | VERIFIED | `Threadline.OperatorSurface.CopyContractTest` exists and was exercised by the targeted ExUnit gate. |
| 8 | 179-02 D-04/D-05: Shared helpers use plain operator nouns while scoped verdicts/code tokens stay allowed. | VERIFIED | `Presentation.status_label/1` keeps evidence verdict labels and sentence-case fallback; copy contract asserts `Proven`, `Inferred`, `Unsupported` only as allowed verdict terms. |
| 9 | 179-02 D-06/D-07/D-08: Shared states use sentence-case controlled templates. | VERIFIED | `UI.data_state/1`, `empty_state/1`, `error_state/1`, `stale_banner/1`, and unsupported descriptors render object plus next-action copy; helper tests passed. |
| 10 | 179-02 D-09: Permission/unavailable states are alerts, neutral states are status-oriented, validation summaries focus and link fields. | VERIFIED | `UI.data_state/1` uses `role="alert"` for permission/source-down and `role="status"` for no-data/redacted/pruned; `UI.error_summary/1` has `tabindex="-1"` and field links. |
| 11 | 179-02 D-10: Reference helpers keep full-value `data-tl-copy` targets. | VERIFIED | `UI.ref/1` binds full values on code and button nodes; `ui_test.exs` and `copy_contract_test.exs` assert full value != visible short ref. |
| 12 | 179-02 D-15: Shared helper edits introduce no dependency, public API, route, LiveComponent, or capability churn. | VERIFIED | `mix.exs`/`mix.lock` unchanged by Phase 179; git diff under `lib/threadline/operator_surface` is modifications only, no new runtime modules or routes. |
| 13 | 179-03 D-04/D-05: Actor, transaction, row history, and coverage pages use canonical domain terms. | VERIFIED | Runtime modules and tests assert `Invalid actor reference`, `database transaction`, `row-level changes`, `Row history`, `Snapshot as of`, `covered`, and `need capture`. |
| 14 | 179-03 D-06/D-08: Not-found, no-data, snapshot, stale, and readiness states use sentence-case templates. | VERIFIED | Actor, transaction, row-history, and coverage tests assert object-specific no-blame copy and next actions. |
| 15 | 179-03 D-09: Page-level permission/unavailable/validation states preserve severity roles. | VERIFIED | Pages consume the 179-02 shared state helpers; targeted page tests passed in the 305-test ExUnit gate. |
| 16 | 179-03 D-10: Existing copyable IDs keep full-value `data-tl-copy` targets. | VERIFIED | Transaction and actor tests assert transaction/correlation full values are bound to `data-tl-copy`, not truncated visible labels. |
| 17 | 179-03 D-15: Investigation/readiness copy changes introduce no dependency, route, public API, or capability churn. | VERIFIED | Git diff shows modifications to existing page modules only; route and direct-link assertions remained green. |
| 18 | 179-04 D-11/D-12/D-14: Timeline keeps dense controls first, moves explanatory copy below work surfaces, and preserves URL-driven advanced disclosures. | VERIFIED | `timeline_live.ex` renders the sentence-case workflow line below controls and `open={@advanced_filters_active?}`; ExUnit and Playwright assertions passed. |
| 19 | 179-04 D-04/D-05: Timeline uses transaction, row history, correlation id, action, and row-level change terms consistently. | VERIFIED | Timeline runtime/tests assert correlation id, transaction links, row history links, and export workflow language. |
| 20 | 179-04 D-08/D-09: Invalid filter and unknown-table messages name the failed object and next action with severity. | VERIFIED | `timeline_live_test.exs` asserts invalid correlation-id and unknown-table copy; browser accessibility spec passed. |
| 21 | 179-04 D-10: Timeline refs keep full-value `data-tl-copy` targets. | VERIFIED | `timeline_live.ex` uses `UI.ref` for correlation ids; `timeline_live_test.exs` asserts full correlation target and copy label. |
| 22 | 179-04 D-13/D-15: No novice/expert mode, route churn, dependency, public API, or new Timeline capability appears. | VERIFIED | Source scans found no new copy DSL/i18n/deps/routes; Timeline changes are copy/disclosure/test assertions over existing flows. |
| 23 | 179-05 D-05/D-12: Evidence/export copy reserves proof-history language for append-only evidence history and verdicts. | VERIFIED | Evidence title is `Evidence`; `Open proof history` appears only in history/detail affordances; Exports tests reject retired proof-handoff wording. |
| 24 | 179-05 D-08/D-09: Redaction, retention, export, stale, success, warning, permission, and destructive states name object, consequence, next action, and role. | VERIFIED | Governance LiveViews assert redaction policy/drift, export handoff, retention window, permanent pruning, and type-to-confirm copy; ExUnit/E2E passed. |
| 25 | 179-05 D-11/D-14: Governance trust rails remain where risk is central and direct evidence/export links plus URL state remain available. | VERIFIED | Evidence and ExportStatus use URL-backed `Carry to Exports`, `Evidence export context`, and `Reopen Evidence`; E2E handoff tests passed. |
| 26 | 179-05 D-13/D-15: No novice/expert mode, route churn, new capability, dependency, public API, copy DSL, CMS, i18n, or LiveComponent extraction appears. | VERIFIED | Source scan found no new registry/i18n/dependency patterns; `row_history_component.ex` LiveComponent predates Phase 179. |
| 27 | 179-06 D-08/D-09: Stress route renders Phase 179 permission, unavailable, redacted, pruned, stale, evidence, retention, and destructive states with correct roles. | VERIFIED | `stress_fixtures.ex`, `stress_live.ex`, fixture tests, and `operator-stress.spec.ts` assert Phase 179 copy-state evidence; browser stress passed. |
| 28 | 179-06 D-16: Rendered copy-contract guards stay green after every page copy slice lands. | VERIFIED | Targeted ExUnit command included `copy_contract_test.exs` with all changed page suites; 305 tests passed. |
| 29 | 179-06 D-17: Stress fixtures include copy-state evidence without adding capabilities or changing story/ledger ids. | VERIFIED | Stress fixture and ledger tests passed; git diff shows no ledger/projection file churn for Phase 179 stress copy. |
| 30 | 179-06 D-13/D-15: Stress validation adds no novice/expert mode, route churn, dependency, public API, copy DSL, CMS, i18n, or LiveComponent extraction. | VERIFIED | Stress changes are existing fixture/live/spec modifications; source scans found no new dependency/copy architecture. |

**Score:** 30/30 truths verified (0 present-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `test/threadline/operator_surface/copy_contract_test.exs` | Rendered copy-contract guard | VERIFIED | Defines `Threadline.OperatorSurface.CopyContractTest`; renders shell/Home/helpers and asserts banned vocabulary, IA labels, proof scoping, CamelCase, and full copy targets. |
| `lib/threadline/operator_surface/components/surface_header.ex` | Shell group labels | VERIFIED | `surface_header/1` renders new labels while preserving legacy nav ids and routes. |
| `lib/threadline/operator_surface/live/start_live.ex` | Task-led Home copy and validation | VERIFIED | Job cards and row-history/correlation validation messages are present; tests assert route redirects. |
| `lib/threadline/operator_surface/ui.ex` | Shared state grammar and copy targets | VERIFIED | Implements `ref/1`, `empty_state/1`, `error_state/1`, `stale_banner/1`, `data_state/1`, `error_summary/1`. |
| `lib/threadline/operator_surface/unsupported.ex` | Unsupported/export-denied descriptors | VERIFIED | Provides sentence-case unavailable and export permission descriptors. |
| `lib/threadline/operator_surface/components/unsupported_view.ex` | Rendered unsupported state | VERIFIED | Renders descriptor maps with `role="alert"`; called by Coverage, Evidence, Exports, Redaction, and Retention pages. |
| `lib/threadline/operator_surface/presentation.ex` | Status/domain labels | VERIFIED | `status_label/1` keeps verdict labels and sentence-case fallback. |
| Investigation/readiness LiveViews | Actor, transaction, row history, coverage copy | VERIFIED | Existing modules contain canonical terms and state copy; targeted tests passed. |
| `lib/threadline/operator_surface/live/timeline_live.ex` | Dense Timeline copy/disclosure | VERIFIED | URL-backed advanced filters and dense controls remain; targeted tests passed. |
| Governance LiveViews | Evidence, Exports, Redaction, Retention copy | VERIFIED | Evidence/proof scoping, export handoff, redaction drift, retention destructive copy all verified. |
| Stress artifacts | Stress copy-state evidence | VERIFIED | `stress_fixtures.ex`, `stress_live.ex`, stress tests, and browser stress specs passed. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `copy_contract_test.exs` | `surface_header.ex` | `render_component(&SurfaceHeader.surface_header/1)` | WIRED | Test renders the actual component and extracts shell group labels. |
| `copy_contract_test.exs` | `start_live.ex` | `live(conn, "/audit")` | WIRED | Test renders the actual Home LiveView and extracts job titles/routes. |
| `operator-home-nav-mobile.spec.ts` | Home/shell runtime | Browser navigation assertions | WIRED | Spec asserts Home job titles and all enabled header destinations. |
| `unsupported.ex` | `unsupported_view.ex` | Descriptor maps passed to rendered component | WIRED | Runtime pages pass `Unsupported.descriptor(...)` or export-denied descriptor to `unsupported_view/1`. |
| `timeline_live.ex` | Timeline tests/E2E | Disclosure, DOM-order, direct-link assertions | WIRED | ExUnit and Playwright both passed. |
| Governance LiveViews | Governance tests/E2E | Handoff, permission, retention, proof-history assertions | WIRED | ExUnit and Playwright both passed. |
| Stress fixtures | Stress route/spec/ledger | Story lookup and rendered browser copy-state assertions | WIRED | Stress fixture/ledger tests and browser stress spec passed. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `start_live.ex` | `@saved_views`, health/export/retention counts | `fetch_saved_views/1`, `ExportJob`, `RetentionRun`, repo queries | Yes | FLOWING |
| `timeline_live.ex` | timeline entries, filters, export jobs | `Threadline.Query`, `SavedView`, `ExportJob`, URL params | Yes | FLOWING |
| `evidence_live.ex` | evidence records/groups | `Threadline.Evidence.list_overview/2`, `list_latest_subject_refs/2`, `get_latest_subject_ref/3`, `list_subject_ref_history/3` | Yes | FLOWING |
| `export_status_live.ex` | export jobs and carried contexts | `ExportJob` repo queries and canonical query params | Yes | FLOWING |
| `stress_live.ex` | selected stress story and ledger metadata | `StressFixtures.by_id/1`, `StressFixtures.assigns_for/1`, `.planning/design-system-ledger.json` | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Core Phase 179 rendered copy contracts and page suites | `mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/data_state_mapping_wave0_test.exs test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/live/actor_live_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs test/threadline/operator_surface/stress_fixtures_test.exs test/threadline/operator_surface/stress_ledger_test.exs test/threadline/operator_surface/pager_test.exs test/threadline/operator_surface/component_contract_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs` | 305 tests, 0 failures | PASS |
| Touched browser specs for shell/Home, Timeline accessibility, governance handoffs, and stress route | `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-home-nav-mobile.spec.ts tests/operator-accessibility.spec.ts tests/operator-prove-mobile.spec.ts tests/operator-earned-flows.spec.ts tests/operator-stress.spec.ts` | 87 passed, 6 skipped | PASS |
| Full workspace residual check | `mix ci.all` | Root: 1114 tests, 1 failure. Example: 95 tests, 7 failures. Failures match `deferred-items.md` and are outside Phase 179 copy/IA-owned paths. | NON_BLOCKING_FAIL |

### Probe Execution

No probe scripts were declared in Phase 179 plans/summaries and no conventional `scripts/*/tests/probe-*.sh` files exist. Step 7c not applicable.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| COPY-01 | 179-01 through 179-06 | Brand voice, banned vocabulary, state/destructive/error patterns | SATISFIED | Copy contract, shared state helpers, page LiveView tests, governance copy tests, stress copy evidence, and browser specs passed. |
| COPY-02 | 179-01 through 179-06 | Consistent domain language | SATISFIED | Runtime sources and tests assert transaction/change/action/actor/correlation/coverage/redaction/retention/evidence terminology. |
| COPY-03 | 179-01 through 179-06 | Least-surprise IA and power-user efficiency | SATISFIED | Shell/Home route stability, Timeline URL disclosure/direct links, copyable IDs, Evidence/Export handoff URLs, stress route, and Playwright specs passed. |

No orphaned Phase 179 requirement IDs were found: `COPY-01`, `COPY-02`, and `COPY-03` appear in every Phase 179 plan and in `REQUIREMENTS.md` traceability for Phase 179.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `test/threadline/operator_surface/style_contract_test.exs` | 287 | `TBD` string inside a test assertion | Info | Not a Phase 179 modified file; it is a guard rejecting TBD in motion inventory fields. |
| `lib/threadline/operator_surface/live/policy_redaction_live.ex` | 152-218 | `mask placeholder` / `not available` | Info | Domain terms for redaction-policy placeholder comparison, locked by policy tests; not a stub. |
| `lib/threadline/operator_surface/live/stress_live.ex` | 269 | `UI.avatar src="" alt="Avatar"` | Info | Pre-existing avatar fallback stress atom documented in 179-06 summary; not production data. |

No blocker debt markers (`TBD`, `FIXME`, `XXX`) were found in Phase 179 modified runtime files.

### Residual CI Failures

`mix ci.all` still fails, but the failures are not Phase 179 goal gaps. They match `.planning/phases/179-microcopy-information-architecture-sweep/deferred-items.md`:

- `test/threadline/v1_23_charter_doc_contract_test.exs:15` expects older `PROJECT.md` milestone wording (`has now opened milestone...`).
- `examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_evidence_test.exs:47` cannot find the expected hero close transaction.
- `examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_happy_path_test.exs:215` cannot find the expected hard-delete timestamp.
- `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` has five seed/audit-row failures around expected close transactions, delete incidents, leaving-agent window counts, and `org_memberships` actor attribution.

These failures are in milestone charter documentation and example demo seed/audit-row data. They do not contradict Phase 179 runtime copy, IA, route stability, `data-tl-copy`, browser handoff, or stress-route evidence, all of which passed targeted verification.

### Human Verification Required

None. The phase validation contract marks editorial judgment on whether a lede/trust rail changes operator judgment as optional reviewer spot-check only; all blocking route stability, copy bans, role mapping, full-value copy affordance, stress evidence, and browser nav checks are automated and passed.

### Gaps Summary

No Phase 179 blocking gaps found. The phase goal is achieved in the codebase.

---

_Verified: 2026-06-19T21:02:00Z_
_Verifier: the agent (gsd-verifier)_
