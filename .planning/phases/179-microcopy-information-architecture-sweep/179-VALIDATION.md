---
phase: 179
slug: microcopy-information-architecture-sweep
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-19
revised: 2026-06-19
---

# Phase 179 - Validation Strategy

Per-phase validation contract for feedback sampling during execution.
Derived from `179-RESEARCH.md` Validation Architecture and the final
`179-01` through `179-06` plan split.

This phase is a guard-first editorial refactor: rendered copy contracts prove
brand/domain language, targeted browser specs prove shell/Home/Timeline and
governance IA remains usable, and the stress route records copy-state evidence.
Wave 0 is represented by `179-01` Task 1 and is intentionally not complete
until execution creates `test/threadline/operator_surface/copy_contract_test.exs`
and observes the expected red run.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix LiveViewTest for rendered copy contracts; Playwright for browser nav/accessibility/stress checks |
| **Config file** | `mix.exs`; `examples/threadline_phoenix/e2e/playwright.config.ts` |
| **Quick run command** | `mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | Quick ExUnit ~30-90s; targeted browser or full suite gates may run longer and are reserved for plan/wave completion |

---

## Sampling Rate

- **After every task commit:** Run the task's `<automated>` command; include `test/threadline/operator_surface/copy_contract_test.exs` once `179-01` Task 1 creates it.
- **After every plan wave:** Run `mix test test/threadline/operator_surface/` and any touched targeted Playwright specs.
- **Before `/gsd:verify-work`:** `mix ci.all` must be green.
- **Max quick feedback latency:** ~90 seconds for the ExUnit sample; Playwright and `mix ci.all` are explicit gate checks rather than quick-loop samples.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 179-01-T1 | 179-01 | W0 task in plan wave 1 | COPY-01/COPY-02/COPY-03 | T-179-01/T-179-03 | Guard-first tests reject banned vocabulary, title-case leaks, broad proof wording, unallowed CamelCase, route-label drift, and missing full copy targets. | rendered unit/source contract | `mix test test/threadline/operator_surface/copy_contract_test.exs --max-failures 6` | Missing now; created by this task | planned, red-first pending |
| 179-01-T2 | 179-01 | 1 | COPY-03 | T-179-01 | Shell labels change to the D-01 IA while hrefs, current atoms, data-testids, order, and Overview route stay stable. | component/render contract | `mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/surface_header_test.exs` | Existing source/tests plus W0 guard | planned |
| 179-01-T3 | 179-01 | 1 | COPY-01/COPY-02/COPY-03 | T-179-02 | Home jobs and validation copy use D-01/D-08 language while saved searches, row history, correlation lookup, and direct links keep working. | ExUnit + Playwright | `mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/live/start_live_test.exs && ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-home-nav-mobile.spec.ts` | Existing source/tests plus W0 guard | planned |
| 179-02-T1 | 179-02 | 2 | COPY-01/COPY-02/COPY-03 | T-179-04/T-179-05/T-179-06 | Shared state helpers distinguish permission/unavailable/no-data/redacted/pruned/stale states, keep severity roles, focus validation summaries, and preserve full copy targets. | rendered unit contract | `mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/data_state_mapping_wave0_test.exs` | Existing source/tests plus W0 guard | planned |
| 179-03-T1 | 179-03 | 3 | COPY-01/COPY-02/COPY-03 | T-179-07/T-179-08 | Actor, transaction, row-history, and coverage copy use canonical terms without implying absent data when access, retention, or capture state is the cause. | rendered unit contract | `mix test test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/live/actor_live_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/live/coverage_live_test.exs` | Existing source/tests | planned |
| 179-04-T1 | 179-04 | 3 | COPY-01/COPY-02/COPY-03 | T-179-09/T-179-10 | Timeline remains dense and URL-recoverable: filters/results/actions stay first, disclosures open from active params, and copyable refs keep full values. | ExUnit + Playwright | `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/pager_test.exs && ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-accessibility.spec.ts` | Existing source/tests | planned |
| 179-05-T1 | 179-05 | 4 | COPY-01/COPY-02/COPY-03 | T-179-11/T-179-12/T-179-13 | Evidence/Exports/Redaction/Retention copy avoids broad proof language, names policies/consequences, and preserves direct handoff links and permission distinctions. | ExUnit + Playwright | `mix test test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs && ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-prove-mobile.spec.ts tests/operator-earned-flows.spec.ts` | Existing source/tests | planned |
| 179-06-T1 | 179-06 | 5 | COPY-01/COPY-02/COPY-03 | T-179-14/T-179-15 | Stress route renders Phase 179 copy-state evidence while story ids, ledger ids, selectors, routes, and capabilities remain stable; full CI is green. | ExUnit + Playwright + CI | `mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/stress_fixtures_test.exs test/threadline/operator_surface/stress_ledger_test.exs && ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-stress.spec.ts && mix ci.all` | Existing source/tests plus W0 guard | planned |

Status values: `planned` means the task has a concrete automated verification command but has not executed yet.

---

## Wave 0 Requirements

- [ ] `179-01-T1` creates `test/threadline/operator_surface/copy_contract_test.exs` with guard-first rendered/source contracts for COPY-01, COPY-02, and COPY-03.
- [ ] The first run of `179-01-T1` is expected to fail against current shell/Home copy before Tasks 2 and 3 apply the IA changes.
- [ ] Copy-contract guards cover retired `Find / Verify / Prove` primary IA labels, broad proof language outside allowed proof-history contexts, visible CamelCase model names in primary UI, exclamation marks, explicit title-case state leaks, generic state text, and full-value copy affordance invariants.
- [ ] Copy-contract guards include allowlists for operation badges (`INSERT`, `UPDATE`, `DELETE`), evidence verdicts (`Proven`, `Inferred`, `Unsupported`), exact model/code tokens in advanced/error/tooling contexts, and non-UI technical terms such as CSP-proof/phone-proof.
- [ ] `179-02-T1` verifies whether `UI.error_summary/1` already provides focusable linked validation summaries and adds the minimal helper-level behavior if absent.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Editorial judgment on whether a lede or trust rail changes operator judgment | COPY-01/COPY-03 | Some wording quality is contextual and not fully machine-checkable | Optional reviewer spot-check only; automated contracts remain the blocking gate |

All route stability, copy bans, role mapping, full-value copy affordances, stress evidence, and browser nav checks are automated in the plan map.

---

## Validation Sign-Off

- [x] All final tasks have concrete `<automated>` verify commands
- [x] Sampling continuity: no task is manual-only and no watch-mode flags are used
- [x] Wave 0 missing references are assigned to `179-01-T1` with an explicit red-first command
- [x] `UI.error_summary/1` focus behavior is assigned to `179-02-T1`
- [x] Every requirement COPY-01, COPY-02, and COPY-03 appears in at least one plan and in the final validation map
- [x] `nyquist_compliant: true` set in frontmatter because every task has a concrete automated verification path
- [ ] `wave_0_complete: true` remains unchecked until execution completes `179-01-T1`

**Approval:** ready for execution; Wave 0 remains pending by design.
