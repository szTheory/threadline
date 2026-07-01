---
phase: 186-detail-governance-and-export-surfaces
verified: 2026-06-30T12:23:25Z
status: passed
score: "30/30 must-haves verified"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 186: Detail, Governance, and Export Surfaces Verification Report

**Phase Goal:** Apply the cleaned IA/component patterns to remaining operator pages.
**Verified:** 2026-06-30T12:23:25Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Transaction, row-history, and actor pages align on detail header, metadata, refs, drawers, copy, and state handling. | VERIFIED | `TransactionLive` uses `UI.shell`, `UI.page_header`, `UI.detail_header`, `UI.ref`, state components, and row-history pivots (`lib/threadline/operator_surface/live/transaction_live.ex:86`, `:101`, `:136`, `:170`, `:202`). `RowHistoryLive` and `RowHistoryComponent` use the same page/detail plus drawer contract (`row_history_live.ex:36`, `:52`, `:61`; `row_history_component.ex:73`). `ActorLive` uses detail anatomy, refs, segmented window, and bounded kind parsing (`actor_live.ex:86`, `:136`, `:152`, `:330`). |
| 2 | Evidence, Exports, Redaction, and Retention become focused workflows rather than dense metadata dumps. | VERIFIED | Evidence summary is directly below the header (`evidence_live.ex:78`, `:288`); Exports has one workflow summary (`export_status_live.ex:135`); Redaction uses a presenter-driven posture summary (`policy_redaction_live.ex:61`, `:167`); Retention uses a window-health summary (`retention_history_live.ex:181`). Focused workflow tests passed in the 231-test targeted ExUnit lane. |
| 3 | Export/download links and feature-gated controls are enabled/disabled correctly for pointer, keyboard, and assistive tech users. | VERIFIED | Completed exports render real links with only `href` and button class attrs (`export_status_live.ex:291`, `:484`); non-ready jobs render status text (`export_status_live.ex:299`, `:465`). Tests assert no `aria-disabled`, `tabindex="-1"`, or `data-tl-mutating` on completed links and no fake links for non-ready jobs (`export_status_live_test.exs:409`, `:415`, `:463`). Feature-gate/browser checks passed. |
| 4 | Retention destructive flow keeps type-to-confirm, auth re-check, audit-the-action, reconnect-safe disabled state, object/consequence copy, and focus restoration. | VERIFIED | Server handler re-checks auth, derives canonical policy `default`, uses `Plug.Crypto.secure_compare/2`, audits via `Threadline.record_action/2`, then calls `Pruner.trigger/0` (`retention_history_live.ex:67`, `:70`, `:72`, `:339`). Modal uses `UI.modal`, type input, locked labels, and `data-tl-mutating` (`retention_history_live.ex:281`, `:289`, `:304`, `:436`). ExUnit and Playwright focus tests passed. |
| 5 | DETAIL-01 / D-186-05 detail surfaces render compact shell/page-header/detail-header anatomy instead of page-specific object summaries. | VERIFIED | Source and copy contracts lock `Transaction`, `Row history`, and `Actor activity` H1/detail-title split (`copy_contract_test.exs:374`). |
| 6 | D-186-06 detail pages keep Timeline nav context, breadcrumbs back to Timeline, and one active navigation state. | VERIFIED | Detail LiveViews pass `current={:timeline}` (`transaction_live.ex:95`, `row_history_live.ex:45`, `actor_live.ex:95`) and render Timeline breadcrumbs. Targeted detail and browser route tests passed. |
| 7 | D-186-07 detail actions remain investigation pivots only. | VERIFIED | Detail pages expose `Open timeline`, `Open row history`, and `Open transaction` pivots (`transaction_live.ex:116`, `:202`; `actor_live.ex:145`, `:210`). |
| 8 | D-186-08 row history uses `UI.drawer/1` with dialog/Escape/close/focus contract. | VERIFIED | `RowHistoryComponent` renders `<UI.drawer>` with `data-testid="row-history-drawer"` and visible Close (`row_history_component.ex:73`, `:78`, `:89`). `UI.drawer/1` supplies dialog, modal, Escape, focus, and pop-focus behavior (`ui.ex:954`, `:971`, `:981`, `:1005`, `:1023`). |
| 9 | D-186-09 / D-186-25 / D-186-26 dense maps stay below object summary, state copy preserves distinctions, and labels use Threadline nouns. | VERIFIED | Detail headers render compact metadata first; snapshot/diff data remains row/drawer-local. Copy contracts assert Phase 186 labels and state distinctions (`copy_contract_test.exs:330`, `:374`, `:406`). |
| 10 | D-186-27 through D-186-32 detail surfaces remain non-color-only, responsive, motion-restrained, and targeted. | VERIFIED | Style contracts assert focus/non-color/motion guardrails and no page-local ungoverned motion (`style_contract_test.exs:438`, `:465`). Browser responsive lanes passed at 320, 375, 768, 1024, and 1440 where applicable. |
| 11 | GOV-01 / D-186-10 / D-186-11 Evidence and Redaction render one focused summary/decision unit without repeated trust rails or generic CTA clusters. | VERIFIED | Evidence and Redaction LiveView tests assert exactly one workflow/posture summary and refute trust rails/summary-grid duplication (`evidence_live_test.exs:159`, `:168`; `policy_redaction_live_test.exs:184`, `:185`, `:186`). |
| 12 | D-186-13 Evidence remains grouped by subject and exposes Carry to Exports only when exports are enabled and context is valid. | VERIFIED | Evidence renders grouped record cards and gated handoff (`evidence_live.ex:94`, `:310`). Tests prove valid handoff, exports-disabled absence, and invalid-context absence (`evidence_live_test.exs:237`, `:272`, `:290`). |
| 13 | D-186-14 / D-186-24 / GOV-03 Redaction distinguishes configured policy from deployed trigger posture and never renders runtime redaction destructive controls. | VERIFIED | Redaction uses `RedactionPresenter.build/1` (`policy_redaction_live.ex:20`) and posture summary (`:167`). Source contract refutes destructive redaction strings (`copy_contract_test.exs:406`, `:427`). |
| 14 | D-186-19 / D-186-25 / D-186-26 / D-186-27 / D-186-30 through D-186-32 feature-gated links, labels, nouns, non-color cues, and verification stay source-backed and targeted. | VERIFIED | Feature links are conditional in source (`policy_redaction_live.ex:212`, `evidence_live.ex:310`) and tests/browser lanes passed. |
| 15 | GOV-01 / D-186-10 / D-186-15 Retention renders one focused window-health and consequence summary. | VERIFIED | Retention summary is `aria-label="Retention window health"` (`retention_history_live.ex:181`) and tests assert no duplicate trust rail (`retention_history_live_test.exs:190`, `:208`). |
| 16 | GOV-03 / D-186-21 / D-186-22 / D-186-23 Retention destructive flow keeps locked labels, type-confirm, auth, audit, mismatch/runtime handling, reconnect state, and focus. | VERIFIED | Locked labels and fail-closed paths are in source (`retention_history_live.ex:67`, `:83`, `:89`, `:436`) and tests cover modal labels, forged token, auth absence, and audit action (`retention_history_live_test.exs:276`, `:421`, `:466`, `:477`). |
| 17 | D-186-15 row-menu prune ambiguity is resolved with one page-level destructive action. | VERIFIED | Source contract asserts one `Run retention prune` path and no row action destructive controls (`copy_contract_test.exs:353`). LiveView test asserts a single page-level entry (`retention_history_live_test.exs:301`). |
| 18 | D-186-03 / D-186-04 route/test-id/feature-gate/auth/dependency/theme/CSP/host boundaries remain unchanged. | VERIFIED | Stable test ids remain (`row-history-drawer`, `transaction-change-row`, `row-history-link`, `actor-transaction-row`, `transaction-link`, export context ids). `git status --short` was clean before report creation; dependency/package searches found no Phase 186 package additions. |
| 19 | D-186-27 / D-186-29 / D-186-30 through D-186-32 Retention source proof covers non-color cues, restrained motion, targeted tests, and source contracts. | VERIFIED | Style contracts cover Retention motion and touched page modules (`style_contract_test.exs:438`, `:465`). |
| 20 | GOV-01 / D-186-10 / D-186-12 Exports renders one focused workflow summary for downloads, processing, and source search. | VERIFIED | `ExportStatusLive` renders `aria-label="Export workflow summary"` and state-specific summary text (`export_status_live.ex:135`, `:431`). |
| 21 | GOV-02 / D-186-16 completed export downloads render real focusable HTTP links without disabled-looking attributes. | VERIFIED | `download_link_attrs/1` returns `href` and class only (`export_status_live.ex:484`). Tests assert rendered link shape and absence of disabled attributes (`export_status_live_test.exs:409`, `:415`). |
| 22 | GOV-02 / D-186-17 non-ready, expired, failed, unauthorized, and gated jobs expose status text instead of fake links. | VERIFIED | `export_job_status_label/1` returns `Queued`, `Processing`, `Failed`, `Expired`, or unavailable text (`export_status_live.ex:465`); tests assert no download href for non-ready jobs (`export_status_live_test.exs:420`, `:463`). |
| 23 | GOV-02 / D-186-18 / D-186-20 Queue Timeline export remains a native button only for valid context and enabled exports, with server enforcement. | VERIFIED | Source gates queue button on valid context (`export_status_live.ex:167`) and event handler enforces `threadline_exports_enabled` plus valid parsed context (`export_status_live.ex:49`, `:54`). Tests cover invalid and forged events (`export_status_live_test.exs:198`, `:212`). |
| 24 | D-186-19 / D-186-30 through D-186-32 feature-gated export routes and controls use targeted LiveView/controller/auth proof. | VERIFIED | Controller parses filters and enforces download behavior (`export_controller.ex:171`); gating tests assert exports-disabled routes omit controls and direct routes (`gating_test.exs:92`, `:104`); controller/auth tests passed. |
| 25 | DETAIL-01 / D-186-05 / D-186-08 browser proof covers Transaction, row-history drawer/dialog, and Actor headings without route/test-id churn. | VERIFIED | Playwright specs assert headings and drawer test ids (`operator-timeline-investigation-flow.spec.ts:352`, `:369`, `:373`, `:376`; `operator-accessibility.spec.ts:433`). Combined browser run passed 147 tests. |
| 26 | GOV-01 / D-186-10 / D-186-13 / D-186-15 browser proof covers focused Evidence, Redaction, and Retention workflows. | VERIFIED | Browser specs cover Evidence/Redaction/Retention visible headings and workflow regions (`operator-prove-mobile.spec.ts:120`, `:143`; `operator-responsive-mobile-first.spec.ts:494`, `:505`, `:519`). Combined browser run passed. |
| 27 | GOV-02 / D-186-16 through D-186-20 browser proof covers download links, non-ready status, queue controls, feature gates, and unavailable states. | VERIFIED | Browser specs assert ready-only `Download export`, no non-ready download link, feature disabled controls absent, and Exports handoffs (`operator-prove-mobile.spec.ts:38`, `operator-features.spec.ts:212`, `operator-earned-flows.spec.ts:145`, `:187`). |
| 28 | GOV-03 / D-186-21 through D-186-23 browser proof covers Retention modal labels, focus restoration, and reconnect-safe disabled behavior. | VERIFIED | Accessibility browser spec asserts modal role/name, copy, Escape close, and focus return (`operator-accessibility.spec.ts:395`, `:426`) plus ARIA snapshot (`:652`). |
| 29 | D-186-27 / D-186-29 through D-186-32 Wave 2 source contracts cover locked copy, state distinctions, and motion/style prohibitions without broad screenshots. | VERIFIED | Copy and style source contracts passed (`copy_contract_test.exs:330`, `:374`, `:406`, `:440`; `style_contract_test.exs:438`, `:465`). |
| 30 | D-186-28 / D-186-30 through D-186-32 closeout uses targeted existing lanes at Phase 186 responsive widths and does not expand broad screenshot matrix. | VERIFIED | Existing targeted browser specs include 320/375/768/1024/1440 proof in the investigation lane (`operator-timeline-investigation-flow.spec.ts:10`) and responsive route matrix (`operator-responsive-mobile-first.spec.ts:7`). No screenshot-matrix expansion was found in Phase 186 plans or changed proof lanes. |

**Score:** 30/30 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/threadline/operator_surface/live/transaction_live.ex` | Transaction detail header/state/ref/pivot surface | VERIFIED | Exists, substantive, wired to `Threadline.incident_bundle/2`, tested. |
| `lib/threadline/operator_surface/live/row_history_live.ex` | First-class Row history page anatomy | VERIFIED | Exists, substantive, renders `RowHistoryComponent`, tested. |
| `lib/threadline/operator_surface/live/row_history_component.ex` | Shared drawer-backed row-history overlay | VERIFIED | Exists, substantive, calls `UI.drawer/1`, tested and browser-proven. |
| `lib/threadline/operator_surface/live/actor_live.ex` | Actor activity detail anatomy and safe kind parsing | VERIFIED | Exists, substantive, bounded parser refutes `String.to_atom/1`, tested. |
| `lib/threadline/operator_surface/live/evidence_live.ex` | Focused Evidence workflow and gated export handoff | VERIFIED | Exists, substantive, uses Evidence API data flow, tested. |
| `lib/threadline/operator_surface/live/policy_redaction_live.ex` | Focused Redaction policy posture | VERIFIED | Exists, substantive, presenter-driven, destructive redaction absent. |
| `lib/threadline/operator_surface/live/retention_history_live.ex` | Retention focused summary and destructive flow | VERIFIED | Exists, substantive, server-enforced prune path, tested. |
| `lib/threadline/operator_surface/live/export_status_live.ex` | Exports workflow, download links, status-only non-ready jobs | VERIFIED | Exists, substantive, DB-backed `ExportJob` flow, tested. |
| Phase 186 ExUnit/browser spec files | Targeted proof for detail/governance/export/retention | VERIFIED | All declared test files exist and passed in targeted commands. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `transaction_live.ex` | `row_history_component.ex` | selected row history assigns / `row-history-drawer` route-backed overlay | VERIFIED | `transaction_live.ex:47` assigns history state; row-history links patch at `:202`; component renders drawer. |
| `row_history_component.ex` | `ui.ex` | `UI.drawer/1` | VERIFIED | `row_history_component.ex:73`; `ui.ex:954` implements drawer dialog/focus/Escape. |
| `actor_live.ex` | `Threadline.Semantics.ActorRef` | bounded actor kind parser | VERIFIED | `actor_live.ex:18`, `:330`; no `String.to_atom/1`. |
| `evidence_live.ex` | `export_status_live.ex` | `Carry to Exports` query params when valid/enabled | VERIFIED | `evidence_live.ex:310`; tests at `evidence_live_test.exs:237`, `:272`, `:290`. |
| `policy_redaction_live.ex` | `Threadline.Policy.RedactionPresenter` | configured/deployed posture | VERIFIED | `policy_redaction_live.ex:20`, `:160`. |
| `retention_history_live.ex` | `Threadline.Retention.Pruner` | auth re-check, audit, then prune trigger | VERIFIED | `retention_history_live.ex:70`, `:73`, `:74`. |
| `retention_history_live.ex` | `ui.ex` | `UI.modal/1` type-confirm dialog | VERIFIED | `retention_history_live.ex:281`; `ui.ex:874` modal focus/Escape/pop-focus. |
| `export_status_live.ex` | `export_controller.ex` | completed jobs link to `/exports/download/:job_id` | VERIFIED | `export_status_live.ex:484`; controller handles direct download. |
| `export_status_live.ex` | `exports/filter_params.ex` | canonical Timeline export context parsing | VERIFIED | `export_status_live.ex:10`, `:572`. |
| `gating_test.exs` | `router.ex` | feature-disabled export route/control proof | VERIFIED | `gating_test.exs:92`, `:104`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `transaction_live.ex` | `@bundle`, `@streams.changes` | `Threadline.incident_bundle/2` with repo/scope (`transaction_live.ex:12`) | Yes | FLOWING |
| `row_history_live.ex` / component | `@history`, `@snapshot_result` | Row-history component receives repo/scope and existing row history lookup inputs from route/component assigns | Yes | FLOWING |
| `actor_live.ex` | `@streams.transactions`, `@actor_summaries` | `Threadline.actor_history/2` and repo-backed summaries (`actor_live.ex:23`, `:49`) | Yes | FLOWING |
| `evidence_live.ex` | `@groups` | `Evidence.list_overview`, `list_latest_subject_refs`, and history APIs (`evidence_live.ex:215`) | Yes | FLOWING |
| `policy_redaction_live.ex` | `@report`, `@sections` | `RedactionPresenter.build/1` (`policy_redaction_live.ex:20`) | Yes | FLOWING |
| `retention_history_live.ex` | `@streams.runs`, `@retention_summary` | `RetentionRun` Ecto query (`retention_history_live.ex:352`) | Yes | FLOWING |
| `export_status_live.ex` | `@streams.jobs`, contexts | `ExportJob` Ecto query plus `FilterParams` parsers (`export_status_live.ex:358`, `:572`, `:600`) | Yes | FLOWING |
| `export_controller.ex` | download response | `FilterParams.parse/1`, `Export.count_matching/2`, `Export.to_*` paths (`export_controller.ex:171`) | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Compile and targeted Phase 186 ExUnit/source/controller contracts | `mix compile --warnings-as-errors && mix test ...` with all Phase 186 operator LiveView/controller/gating/copy/style/doc contract tests | 231 tests, 0 failures | PASS |
| Targeted browser closeout across mobile, accessibility, investigation, earned-flow, feature-gate, and responsive lanes | `mix verify.example_browser -- operator-prove-mobile.spec.ts operator-accessibility.spec.ts operator-timeline-investigation-flow.spec.ts operator-earned-flows.spec.ts operator-features.spec.ts operator-responsive-mobile-first.spec.ts` | 147 passed. Command printed an expired local Hex auth warning and unchanged dependency advisories, then completed successfully. | PASS |
| Artifact/frontmatter checks | `gsd_run query verify.artifacts` across five plans | 23/23 artifacts passed | PASS |
| Key-link checks plus manual source confirmation | `gsd_run query verify.key-links` plus manual inspection of `UI.drawer/1` and `UI.modal/1` links | Tool found 14/16 patterns; the two escaped-pattern misses were manually verified in source (`row_history_component.ex:73`, `retention_history_live.ex:281`). | PASS |

### Probe Execution

| Probe | Command | Result | Status |
|-------|---------|--------|--------|
| Phase 186 probes | `find scripts -path '*/tests/probe-*.sh'` plus plan/summary probe grep | No declared or conventional phase probes found. | SKIPPED |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| DETAIL-01 | 186-01, 186-05 | Transaction, row-history, and actor pages use detail-header, metadata, copy/ref, drawer, and state patterns. | SATISFIED | Truths 1, 5-10, 25; ExUnit and browser checks passed. |
| GOV-01 | 186-02, 186-03, 186-04, 186-05 | Evidence, Exports, Redaction, and Retention read as focused workflows rather than dense dumps. | SATISFIED | Truths 2, 11, 15, 20, 26; focused workflow tests passed. |
| GOV-02 | 186-04, 186-05 | Export/download affordances, feature gates, and disabled states are correct for pointer, keyboard, and assistive tech users. | SATISFIED | Truths 3, 21-24, 27; controller/auth/gating and browser tests passed. |
| GOV-03 | 186-02, 186-03, 186-05 | Retention destructive actions keep confirmation/auth/audit/reconnect/focus/copy; runtime redaction destructive flow remains deferred. | SATISFIED | Truths 4, 13, 16, 17, 28; destructive redaction absence and Retention fail-closed tests passed. |

No Phase 186 requirement IDs were orphaned. Phase 187 explicitly owns A11Y-01, A11Y-02, MOTION-01, DOC-01, and CLOSE-01.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/threadline/operator_surface/live/policy_redaction_live.ex` | 249, 255 | `not available` | INFO | Intentional redaction deployed-policy placeholder copy, covered by policy/redaction contract tests. Not a stub. |

Debt marker scan found no `TBD`, `FIXME`, or `XXX` markers in Phase 186 touched source/spec files. Searches found no Phase 186 Tailwind/shadcn/public-component/dependency additions, and no runtime redaction destructive controls.

### Human Verification Required

None. Phase 186 validation states all phase behaviors have automated verification paths, and the targeted ExUnit plus Playwright lanes passed.

### Gaps Summary

No gaps remain. All roadmap success criteria, plan must-haves, key artifacts, key links, data-flow checks, requirement IDs, and prohibitions are verified against the codebase.

---

_Verified: 2026-06-30T12:23:25Z_
_Verifier: the agent (gsd-verifier)_
