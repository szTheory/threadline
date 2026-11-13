---
phase: "251"
slug: "complete-investigation-and-inspection-screens"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-11-12"
---

# Phase 251 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + existing Node contracts + Playwright 1.60.0 |
| **Config file** | mix.exs; examples/threadline_phoenix/e2e/playwright.config.ts |
| **Quick run command** | `mix verify.test test/threadline/query/filter_params_test.exs` |
| **Full suite command** | `Selected Phase 251 owners, finalized in plans; whole-root repeat remains stopped` |
| **Estimated runtime** | Unmeasured; record actual scoped runtimes |

---

## Sampling Rate

- **After every task commit:** Run `mix verify.test with the changed owner paths specified in each plan`
- **After every plan wave:** Run `the combined selected Phase 251 regression specified by the plan`
- **Before `$gsd-verify-work`:** All selected checks must be green; no claim of a whole-root run
- **Max feedback latency:** 60 seconds for an update; actual command runtimes recorded

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 251-01-1 | 01 | 1 | ADM-15, ADM-19 | T-251-01 | Unsupported-only input clears results and shows correction without calling a broader query; malformed persisted filters are rejected before canonicalization; valid filters and from= round-trip. | ExUnit + mounted browser | `mix verify.test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/query/filter_params_test.exs`; `cd examples/threadline_phoenix/e2e && THREADLINE_E2E_EVIDENCE=1 E2E_BASE_URL="$THREADLINE_PHASE251_APP_URL" ./node_modules/.bin/playwright test tests/operator-route-states.spec.ts --project=desktop-chromium --grep "Phase251 Timeline and saved-view guards" --retries=0 --workers=1` (exactly one case) | Existing owning checks/captures and independent review; see251-PAIR-EVIDENCE.md | ✅ verified |
| 251-01-2 | 01 | 1 | ADM-15, ADM-19 | T-251-02/03 | Invalid retained context produces a visible notice before bare-Timeline recovery; valid context remains exact and an unknown origin never grants scope. | ExUnit + mounted browser | `mix verify.test test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/live/row_history_live_test.exs`; `cd examples/threadline_phoenix/e2e && THREADLINE_E2E_EVIDENCE=1 E2E_BASE_URL="$THREADLINE_PHASE251_APP_URL" ./node_modules/.bin/playwright test tests/operator-earned-flows.spec.ts --project=desktop-chromium --grep "Phase251 retained-context recovery" --retries=0 --workers=1` (exactly one case) | Existing owning checks/captures and independent review; see251-PAIR-EVIDENCE.md | ✅ verified |
| 251-01-3 | 01 | 1 | ADM-15, ADM-19 | T-251-02/03 | Independent source/route declarations and negative controls; current capture/review identity | ExUnit + Node/source | `mix verify.test test/threadline/operator_surface/rendered_output_contract_test.exs test/threadline/operator_surface/operator_surface_fixture_contract_test.exs test/threadline/browser_journey_evidence_contract_test.exs`; `cd examples/threadline_phoenix/e2e && ./node_modules/.bin/tsx --test support/operator-ci-evidence.test.ts support/operator-route-evidence.test.ts` scoping already proven in Phase250 | Existing owning checks/captures and independent review; see251-PAIR-EVIDENCE.md | ✅ verified |
| 251-02-1 | 02 | 2 | ADM-18, ADM-19, ADM-15 | T-251-04/06 | Missing/blank as_of uses default; malformed nonempty as_of stays invalid and does not run as_of with nil fallback; valid UTC/offset selects the actual snapshot. | ExUnit + mounted browser | `mix verify.test test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/rendered_output_contract_test.exs`; `cd examples/threadline_phoenix/e2e && THREADLINE_E2E_EVIDENCE=1 E2E_BASE_URL="$THREADLINE_PHASE251_APP_URL" ./node_modules/.bin/playwright test tests/operator-earned-flows.spec.ts --project=desktop-chromium --grep "Phase251 standalone snapshot intent" --retries=0 --workers=1` (exactly one case) | Existing owning checks/captures and independent review; see251-PAIR-EVIDENCE.md | ✅ verified |
| 251-02-2 | 02 | 2 | ADM-18, ADM-19, ADM-15 | T-251-04/06 | Nested history rejects malformed explicit time, clears to default and preserves valid offsets, full identity, Timeline filters and focus-return target. | ExUnit + mounted browser | `mix verify.test test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/row_history_component_test.exs`; `cd examples/threadline_phoenix/e2e && THREADLINE_E2E_EVIDENCE=1 E2E_BASE_URL="$THREADLINE_PHASE251_APP_URL" ./node_modules/.bin/playwright test tests/operator-earned-flows.spec.ts --project=desktop-chromium --grep "Phase251 transaction snapshot intent" --retries=0 --workers=1` (exactly one case) | Existing owning checks/captures and independent review; see251-PAIR-EVIDENCE.md | ✅ verified |
| 251-02-3 | 02 | 2 | ADM-18, ADM-19, ADM-15 | T-251-05 | Independent source/route declarations and negative controls; current capture/review identity | ExUnit + mounted browser | `mix verify.test test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/live/actor_live_test.exs`; `cd examples/threadline_phoenix/e2e && THREADLINE_E2E_EVIDENCE=1 E2E_BASE_URL="$THREADLINE_PHASE251_APP_URL" ./node_modules/.bin/playwright test tests/operator-timeline-investigation-flow.spec.ts --project=desktop-chromium --grep "Phase251 Home and actor lifecycle" --retries=0 --workers=1` (exactly one case); `cd examples/threadline_phoenix/e2e && ./node_modules/.bin/tsx --test support/operator-ci-evidence.test.ts support/operator-route-evidence.test.ts` scoping already proven in Phase250 | Existing owning checks/captures and independent review; see251-PAIR-EVIDENCE.md | ✅ verified |
| 251-03-1 | 03 | 3 | ADM-20 | T-251-07/08/09 | A successful custom-schema read and refresh share rows/header/schema/time; an empty/expected-only inspection says other schemas were not inspected and never implies global completeness. | ExUnit + mounted browser | `mix verify.test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/rendered_output_contract_test.exs`; `cd examples/threadline_phoenix/e2e && THREADLINE_E2E_EVIDENCE=1 E2E_BASE_URL="$THREADLINE_PHASE251_APP_URL" ./node_modules/.bin/playwright test tests/operator-coverage-readiness.spec.ts --project=desktop-chromium --grep "Phase251 Coverage selected snapshot" --retries=0 --workers=1` (exactly one case) | Current owning regression and matched evidence; see251-PAIR-EVIDENCE.md | ✅ verified |
| 251-03-2 | 03 | 3 | ADM-20 | T-251-07/08/09 | Same-schema failure may show labeled last-good time; changed-schema failure never presents previous-schema rows as current; host denied, disabled, invalid schema and failed read stay separate. | ExUnit + mounted browser | `mix verify.test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/surface_header_test.exs`; `cd examples/threadline_phoenix/e2e && THREADLINE_E2E_EVIDENCE=1 E2E_BASE_URL="$THREADLINE_PHASE251_APP_URL" ./node_modules/.bin/playwright test tests/operator-route-states.spec.ts --project=desktop-chromium --grep "Phase251 Coverage availability boundaries" --retries=0 --workers=1` (exactly one case) | Current owning regression and matched evidence; see251-PAIR-EVIDENCE.md | ✅ verified |
| 251-03-3 | 03 | 3 | ADM-20 | T-251-07/08/09 | Independent source/route declarations and negative controls; current capture/review identity | ExUnit + Node/source | `mix verify.test test/threadline/operator_surface/rendered_output_contract_test.exs test/threadline/operator_surface/operator_surface_fixture_contract_test.exs test/threadline/browser_journey_evidence_contract_test.exs`; `cd examples/threadline_phoenix/e2e && ./node_modules/.bin/tsx --test support/operator-ci-evidence.test.ts support/operator-route-evidence.test.ts` scoping already proven in Phase250 | Current owning regression and matched evidence; see251-PAIR-EVIDENCE.md | ✅ verified |
| 251-04-1 | 04 | 4 | ADM-21, ADM-22 | T-251-10/13 | Zero configured policies yields no-policy-to-compare across every section; configured versus current deployed source, successful time and Left out/Redacted replacement are explicit; missing trigger, unreadable definition and unavailable read remain distinct. | ExUnit + mounted browser | `mix verify.test test/threadline/operator_surface/live/policy_redaction_live_test.exs test/threadline/operator_surface/rendered_output_contract_test.exs`; `cd examples/threadline_phoenix/e2e && THREADLINE_E2E_EVIDENCE=1 E2E_BASE_URL="$THREADLINE_PHASE251_APP_URL" ./node_modules/.bin/playwright test tests/operator-route-states.spec.ts --project=desktop-chromium --grep "Phase251 Redaction current-definition meaning" --retries=0 --workers=1` (exactly one case) | Current owning live/DB and exact mounted proof; see251-PAIR-EVIDENCE.md | ✅ verified |
| 251-04-2 | 04 | 4 | ADM-21, ADM-22 | T-251-11/12/13 | Latest/history retain subject/reference and ordering; only exact writer/subject-entrypoint pairs get known recorded summary; mismatches/custom values never render; no-match stays distinct from outage. | ExUnit + mounted browser | `mix verify.test test/threadline/operator_surface/live/evidence_live_test.exs`; `cd examples/threadline_phoenix/e2e && THREADLINE_E2E_EVIDENCE=1 E2E_BASE_URL="$THREADLINE_PHASE251_APP_URL" ./node_modules/.bin/playwright test tests/operator-route-states.spec.ts --project=desktop-chromium --grep "Phase251 Evidence recorded provenance" --retries=0 --workers=1` (exactly one case) | Current owning live/DB and exact mounted proof; see251-PAIR-EVIDENCE.md | ✅ verified |
| 251-04-3 | 04 | 4 | ADM-21, ADM-22 | T-251-01–13 | Independent source/route declarations and negative controls; current capture/review identity | ExUnit + Node/source | `mix verify.test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/rendered_output_contract_test.exs`; `cd examples/threadline_phoenix/e2e && ./node_modules/.bin/tsx --test support/operator-ci-evidence.test.ts support/operator-route-evidence.test.ts` scoping already proven in Phase250 | Current scoped contracts plus formal source/security/UI review and disposition | ✅ verified |

Every runnable task command has an immediately following `fails_when` in its plan. Every mounted Playwright client command explicitly sets THREADLINE_E2E_EVIDENCE=1 before the executable, including selected coupled controls; normal app startup retains THREADLINE_E2E_EVIDENCE=0. Do not export the client override into app startup. Exit zero with missing/zero/skipped/retried expected cases is non-acceptance. Commands are authored, not execution receipts. ExUnit/native read assertions and browser route/capture assertions retain their distinct boundaries.

### Exact first-attempt mounted case set

| Task | Existing owner | New exact title | Required result |
|---|---|---|---|
| 251-01-1 | `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts` | Phase251 Timeline and saved-view guards | Exactly 1 selected, passed, 0 retries, 0 skips; source/capture-bound |
| 251-01-2 | `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` | Phase251 retained-context recovery | Exactly 1 selected, passed, 0 retries, 0 skips; source/capture-bound |
| 251-02-1 | `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` | Phase251 standalone snapshot intent | Exactly 1 selected, passed, 0 retries, 0 skips; source/capture-bound |
| 251-02-2 | `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` | Phase251 transaction snapshot intent | Exactly 1 selected, passed, 0 retries, 0 skips; source/capture-bound |
| 251-02-3 | `examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts` | Phase251 Home and actor lifecycle | Exactly 1 selected, passed, 0 retries, 0 skips; source/capture-bound |
| 251-03-1 | `examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts` | Phase251 Coverage selected snapshot | Exactly 1 selected, passed, 0 retries, 0 skips; source/capture-bound |
| 251-03-2 | `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts` | Phase251 Coverage availability boundaries | Exactly 1 selected, passed, 0 retries, 0 skips; source/capture-bound |
| 251-04-1 | `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts` | Phase251 Redaction current-definition meaning | Exactly 1 selected, passed, 0 retries, 0 skips; source/capture-bound |
| 251-04-2 | `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts` | Phase251 Evidence recorded provenance | Exactly 1 selected, passed, 0 retries, 0 skips; source/capture-bound |

These nine explicit mounted cases are new names in existing owners, not fabricated existing checks. Before editing runtime, register the owning case and capture the old behavior at the unchanged real route. After implementation collect fresh matched after evidence. The combined selected set must be exactly these nine non-skipped first-attempt passes plus explicitly inventoried existing coupled controls, without silently selecting a full browser suite.

### Combined regression ownership

After each plan, combine only its listed ExUnit paths and run the existing Node pair:
`cd examples/threadline_phoenix/e2e && ./node_modules/.bin/tsx --test support/operator-ci-evidence.test.ts support/operator-route-evidence.test.ts`.
Run `mix compile --warnings-as-errors` and `mix verify.format` on the current candidate; real nonzero exit blocks acceptance. Reuse those predecessor-proven entrypoints verbatim. The root named suite remains stopped; no whole-root repeat or hosted CI is planned.

## Dependency and artifact coverage

| Plan / wave | Needs | Produces | Delivery group |
|---|---|---|---|
| 01 / 1 | Accepted Phase250 route/filter foundation, prepared custody | UI/saved-input guards, visible lost-context recovery and coupled source/route/render contracts | Navigation/history |
| 02 / 2 | 01 private retained-context helper, actual rendered/inventory contracts | Both snapshot entry paths, exact default/invalid semantics and existing Home/Actor lifecycle proof | Navigation/history |
| 03 / 3 | Completed navigation/history group; shared shell and source inventory | Current selected-schema Coverage rows/header, availability and coupled controls | Scoped inspection |
| 04 / 4 | 03 selected-schema/header semantics and inventory | Current Redaction comparison, bounded recorded Evidence, formal review/security/UI receipts | Scoped inspection |

There are shared runtime/renderer/browser/JSON/Node files, so every dependency is explicit and waves are serial. Each plan has three tasks and each task names no more than five modified files. Proof tasks close the same production slice before acceptance. Routine private fixture/capture artifacts are listed in each plan's produced-artifact section; no public runner/helper/config or dependency is introduced.

## Multi-source coverage audit

| Source | ID | Required outcome/constraint | Plans/tasks | Status |
|---|---|---|---|---|
| GOAL | Phase251 | Complete remaining investigation and inspection jobs with scoped context, exact meaning and shared design | 01–04 | COVERED |
| REQ | ADM-15 | Filters, saved views, direct/reload/back/return retain validated state/scope | 01.1–3,02.3 | COVERED |
| REQ | ADM-18 | Existing Home/actor/correlation jobs, nonhuman/absent identity | 02.3 | COVERED |
| REQ | ADM-19 | Exact record/transaction snapshot/default/invalid/deletion/horizon/context | 01.2,02.1–2 | COVERED |
| REQ | ADM-20 | Current selected-schema facts/remediation and honest availability | 03.1–3 | COVERED |
| REQ | ADM-21 | Configured/current-deployed policy, source/time, replacement/Left out, safe recovery | 04.1 | COVERED |
| REQ | ADM-22 | Subject/reference/latest/history, snapshot time, bounded recorded provenance and read limits | 04.2 | COVERED |
| RESEARCH | R1 | Invalid nonempty time is explicit at both entries; blank is default | 02.1–2 | COVERED |
| RESEARCH | R2 | UI/saved validation before canonicalization; shared parser unchanged | 01.1 | COVERED |
| RESEARCH | R3 | Existing Home/actor paths and genuine nonhuman/absent identity | 02.3 | COVERED |
| RESEARCH | R4 | Coverage selected/current rows/header and zero/expected/stale/changed-schema distinctions | 03.1–2 | COVERED |
| RESEARCH | R5 | Redaction all-section empty, current definition/time/source and safe nonconnection errors | 04.1 | COVERED |
| RESEARCH | R6 | Evidence constant summary, caller-overridable metadata, hidden maps/actors | 04.2 | COVERED |
| RESEARCH | Proof/constraints | Existing private Phoenix/HEEx composition; coupled inventories/negative controls; matched captures; custody; first-dispatch final review schemas; no renewed repeat | Every plan execution contract and coupling tasks;04.3 | COVERED |
| CONTEXT | D-01 | Exact valid filters/unconstrained/path/default/host-scope and existing pivots | 01.1–2,02.1–3 | COVERED |
| CONTEXT | D-02 | Fail-closed UI/saved input preserving parser compatibility | 01.1 | COVERED |
| CONTEXT | D-03 | Visible retained-context loss before safe recovery | 01.2 | COVERED |
| CONTEXT | D-04 | Invalid/default/valid snapshot distinctions at both entries | 02.1–2 | COVERED |
| CONTEXT | D-05 | Selected-current Coverage scope/header/availability | 03.1–2 | COVERED |
| CONTEXT | D-06 | Current-definition Redaction source/time/empty/error meanings | 04.1 | COVERED |
| CONTEXT | D-07 | Subject/reference-scoped Evidence with bounded recorded metadata | 04.2 | COVERED |
| CONTEXT | D-08 | Two sequential coherent groups, shared UI, coupled proof/review, no public expansion | 01/02 navigation;03/04 inspection; all coupling tasks | COVERED |
| CONTEXT | D-09 | Actual-source small matched changed-state captures, existing owners/custody/limits | Every task execution contract and acceptance;04.3 | COVERED |
| UI | N1 | Eight explicit rows: empty/loading/error/populated/partial/overflow/zero-one-many/long-text | 01 must_haves.truths and01.1–3 | COVERED |
| UI | N2 | Eight explicit rows: existing Home/actor/correlation jobs | 02 must_haves.truths and02.3 | COVERED |
| UI | N3 | Eight explicit rows: snapshot history | 02 must_haves.truths and02.1–2 | COVERED |
| UI | I1 | Eight explicit rows: Coverage | 03 must_haves.truths and03.1–3 | COVERED |
| UI | I2 | Eight explicit rows: Redaction | 04 must_haves.truths and04.1 | COVERED |
| UI | I3 | Eight explicit rows: Evidence | 04 must_haves.truths and04.2 | COVERED |
| EDGE | ADM-20 | Three explicit adjacency/empty/ordering criteria, verbatim | 03 must_haves.truths | COVERED |
| EDGE | ADM-22 | Three explicit adjacency/empty/ordering criteria, verbatim | 04 must_haves.truths | COVERED |
| EDGE | ADM-15/18/19/21 | Four unclassified/unresolved rows | Flagged assumptions in01/02/04,04.3 independent review | RETAINED — no invented resolution |
| PROHIBITION | All six requirements | Six bespoke transparency/identity/assurance/privacy constraints | Installed projectProhibitions output in01/02/03/04 | FLAGGED-UNVERIFIED — descriptor-less |

Deferred operations/catalog252, broad zoom/inclusive/error-pixel/docs/package/release253 and live REL-01 are excluded by their approved scope, not missing Phase251 deliverables. No new user decision is introduced. Formal code/UI/security review must retain the six prohibition flags and four edge assumptions honestly; behavior proof does not invent a wired prohibition descriptor.


*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. Each tracer starts with meaningful failing regression cases in its existing owners; no MISSING test path, framework installation or new runner is required. The new browser titles and private helper names are declared in the plans. Before execution prepare dedicated Phase251 root/example test and changed-runtime partitions under the retained owned local PostgreSQL; preserve Phase250 pair data/capsules and the full-root repeat stop. Historical planning status was draft until the actual checks/audit; current completed audit is recorded below.


---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
All phase behaviors have automated verification. Independent agent review covers visual/copy judgment; no maintainer UAT is planned.


---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Actual feedback latency recorded; no unmeasured target pass
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** Automated execution, independent review and Nyquist audit completed2026-11-13; no maintainer UAT.

## Plan01 local acceptance

Plan01 completed its bounded source/live/browser/changed-state gates:253 selected ExUnit tests,32 Node cases, exactly two retries-disabled mounted cases, warnings-as-errors compile and named format; ten actual viewport captures per matched half. See [Plan01 summary](251-01-SUMMARY.md) and [pair evidence](251-PAIR-EVIDENCE.md). Initial failed setup and browser attempts remain retained. Independent phase-wide code/security/UI/goal gates are pending, so this does not change whole-phase validation status.

## Plan02 bounded acceptance

[Plan02](251-02-SUMMARY.md) completed its behavioral gates:231 selected root tests,32 Node controls, five exact retries-disabled mounted cases, compile/format and four matched snapshot captures per half. The initial combined browser failure remains retained and was corrected by actual connection readiness checks. Whole-phase status remains pending. The375px history Close label wraps vertically in both matched halves; Plan04 owns the required shared correction and independent UI confirmation before phase acceptance.

## Completed Nyquist and goal reconciliation —2026-11-13

All12 declared task slots have existing automated verification; there is no run of three tasks without feedback, no MISSING Wave0 path, framework install or watch-mode command. Fail-first controls, source/route discovery and malformed/duplicate/wrong-owner negatives remain intact. Actual feedback examples are below; these are invocation wall times, not invented targets or a full-suite speed claim. The failed156-case gate retained its one outdated fixture assertion and was followed by the attributed18-policy passed retest; the unchanged155 passing cases remain applicable.

| Invocation | Actual wall time | Actual exit |
|---|---|---|
| 03-layout-selected | 4.002s | exit0 |
| 03-final-node | 3.434s | exit0 |
| 04-copy-owning | 3.278s | exit0 |
| 04-review-fix-owning | 3.334s | exit2 |
| 04-review-policy-final | 1.245s | exit0 |
| 04-review-browser-batch | 3.209s | exit0 |
| 04-review-policy-single | 1.638s | exit0 |
| 04-review-evidence-single | 1.437s | exit0 |

The independent [goal verification](251-VERIFICATION.md) passed63/63 truths, six requirements,30 artifact entries,16 manually traced real key links and9/9 decisions, with no implementation gaps. The generic source-to-test string heuristic is not substituted for actual wiring proof. [Automated judgment disposition](251-UAT.md) consumes independent assessments under the standing zero-human policy; six engine prohibition flags and four edge assumptions remain unresolved/non-authoritative, not green. The canonical verification.status owner returns passed.

Current source is c0b1508c; runtime/pixels da665edc; subsequent changes are planning only. [Pair evidence](251-PAIR-EVIDENCE.md), [review disposition](251-REVIEW-DISPOSITION.md) and private reconciliation receipts retain actual identities/outcomes, failures and limits. No full-root repeat, native clipboard/zoom/outage-pixel/hosted/human-comprehension claim or new resource/risk grant is introduced. Phase252 operations/catalog and Phase253 broad inclusive/error-pixel/palette/docs/package/readiness remain next scope.
