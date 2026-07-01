---
phase: 186
slug: detail-governance-and-export-surfaces
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-30
---

# Phase 186 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit/Mix with Phoenix.LiveViewTest and Phoenix.ConnTest; Playwright `@playwright/test` for example-browser proof |
| **Config file** | `mix.exs`; `examples/threadline_phoenix/e2e/playwright.config.ts` |
| **Quick run command** | `mix test test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/row_history_component_test.exs test/threadline/operator_surface/live/actor_live_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/gating_test.exs` |
| **Full suite command** | `mix verify.test`; add targeted `mix verify.example_browser -- operator-prove-mobile.spec.ts operator-accessibility.spec.ts operator-timeline-investigation-flow.spec.ts operator-earned-flows.spec.ts operator-features.spec.ts operator-responsive-mobile-first.spec.ts` when browser-facing behavior changes |
| **Estimated runtime** | Targeted Mix slice should stay under 120 seconds locally; browser proof varies with example-app startup |

---

## Sampling Rate

- **After every task commit:** Run the narrow LiveView/source/controller tests for the touched page or control family.
- **After every plan wave:** Run the combined quick Mix command above plus `mix format --check-formatted` if Elixir files changed.
- **Before `/gsd:verify-work`:** Run the targeted Mix slice, `mix verify.test` when local residuals allow, and the targeted browser lane for any changed focus, responsive, keyboard, route, or download behavior.
- **Max feedback latency:** No three consecutive task commits without automated verification; primary Mix sampling target is under 120 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 186-W0-DETAIL-TX | 186-01 | 1 | DETAIL-01 | T-186-01 | Transaction detail shows the locked object summary, full-copy refs, state family, and investigation pivots without route/test-id churn | LiveView | `mix test test/threadline/operator_surface/transaction_live_test.exs` | yes | pending |
| 186-W0-DETAIL-ROW | 186-01 | 1 | DETAIL-01 | T-186-02 | Row history standalone/subview preserves route state and dialog/drawer focus, Escape/close, and focus-return behavior | LiveView + browser | `mix test test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/row_history_component_test.exs && mix verify.example_browser -- operator-accessibility.spec.ts` | yes | pending |
| 186-W0-DETAIL-ACTOR | 186-01 | 1 | DETAIL-01 | T-186-03 | Actor activity uses detail anatomy, window control semantics, copyable refs, and investigation-only actions | LiveView | `mix test test/threadline/operator_surface/live/actor_live_test.exs` | yes | pending |
| 186-W0-GOV-EVIDENCE | 186-02 | 1 | GOV-01 | T-186-04 | Evidence remains subject-grouped and exposes `Carry to Exports` only for exports-enabled valid request context | LiveView + browser mobile | `mix test test/threadline/operator_surface/live/evidence_live_test.exs && mix verify.example_browser -- operator-prove-mobile.spec.ts` | yes | pending |
| 186-W0-GOV-EXPORTS | 186-04 | 1 | GOV-01, GOV-02 | T-186-05 | Exports separates ready/preparing/attention/unavailable jobs; completed downloads are real focusable HTTP links and non-ready jobs expose no fake href | LiveView + controller/auth | `mix test test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/export_auth_plug_test.exs` | yes | pending |
| 186-W0-GOV-REDACTION | 186-02 | 1 | GOV-01, GOV-03 | T-186-06 | Redaction remains configured-vs-deployed policy status and renders no runtime destructive redaction flow | LiveView | `mix test test/threadline/operator_surface/live/policy_redaction_live_test.exs test/threadline/operator_surface/policy_show_doc_contract_test.exs` | yes | pending |
| 186-W0-GOV-RETENTION | 186-03 | 1 | GOV-01, GOV-03 | T-186-07 | Retention prune keeps type-to-confirm, exact labels/copy, auth re-check, secure compare, audit-before-prune, runtime-unavailable handling, reconnect-safe submit, and focus restoration | LiveView/source/copy/style | `mix test test/threadline/operator_surface/live/retention_history_live_test.exs test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/style_contract_test.exs` | yes | pending |
| 186-W0-GATES | 186-04 | 1 | GOV-02 | T-186-08 | Feature-gated actions/nav are omitted or route to unsupported view; unavailable controls use element-appropriate disabled/removed-href semantics | LiveView/source + browser | `mix test test/threadline/operator_surface/gating_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs && mix verify.example_browser -- operator-features.spec.ts` | yes | pending |
| 186-W2-BROWSER-CLOSEOUT | 186-05 | 2 | DETAIL-01, GOV-01, GOV-02, GOV-03 | T-186-09 | Existing targeted browser lanes and Wave 2 source contracts prove detail headings, row-history drawer focus, Evidence handoff/copy, export download/status controls, feature gates, responsive behavior, Redaction destructive-control absence, Actor atom safety, and Retention modal focus/copy without broad screenshot expansion | Browser + source/copy/style closeout | `mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/style_contract_test.exs && mix verify.example_browser -- operator-prove-mobile.spec.ts operator-accessibility.spec.ts operator-timeline-investigation-flow.spec.ts operator-earned-flows.spec.ts operator-features.spec.ts operator-responsive-mobile-first.spec.ts` | yes | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline/operator_surface/live/export_status_live_test.exs` - assert completed download links have `href` and lack `aria-disabled`, `tabindex`, and `data-tl-mutating`; assert non-ready jobs expose status text rather than fake download links.
- [ ] `test/threadline/operator_surface/live/retention_history_live_test.exs` and `examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts` - cover `Keep retention window`, `Prune records permanently`, mismatch copy `Could not prune - confirmation did not match.`, focus restoration, and reconnect-safe mutating state.
- [ ] Transaction, Row history, and Actor tests - assert locked H1s, object summary/detail-header anatomy, metadata/ref copy labels, state family usage, and no stable route/test-id churn.
- [ ] Evidence, Exports, Redaction, and Retention tests - reject repeated trust rails, dense duplicate metric dumps, and runtime redaction destructive controls.
- [ ] Add or amend row-history Escape/focus-return browser assertion if the row-history component does not convert fully to `UI.drawer/1`.
- [ ] Existing browser closeout lanes - keep `operator-prove-mobile.spec.ts`, `operator-accessibility.spec.ts`, `operator-timeline-investigation-flow.spec.ts`, `operator-earned-flows.spec.ts`, `operator-features.spec.ts`, and `operator-responsive-mobile-first.spec.ts` aligned with Phase 186 role/name, focus, export, feature-gate, handoff, and responsive contracts.

---

## Manual-Only Verifications

All phase behaviors have an automated verification path. Manual review may inspect information hierarchy and copy tone, but no requirement should rely on manual-only proof.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all MISSING references.
- [ ] No watch-mode flags.
- [ ] Feedback latency target is under 120 seconds for primary Mix sampling.
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 proof is green.

**Approval:** pending
