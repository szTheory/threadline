---
phase: 184
slug: timeline-investigation-flow
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-28
---

# Phase 184 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit through Mix, Phoenix.LiveViewTest, and Playwright browser proof |
| **Config file** | `mix.exs`; `examples/threadline_phoenix/e2e/playwright.config.ts` |
| **Quick run command** | `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/timeline_browse_doc_contract_test.exs test/threadline/operator_surface/pager_test.exs test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/exports/filter_params_test.exs` |
| **Full suite command** | `mix verify.format && mix verify.credo && mix verify.test && mix verify.example_browser -- operator-responsive-mobile-first.spec.ts operator-accessibility.spec.ts operator-earned-flows.spec.ts operator-find-mobile.spec.ts` |
| **Estimated runtime** | Quick Mix slice: under 60 seconds locally; full browser-backed suite varies by environment |

---

## Sampling Rate

- **After every task commit:** Run the quick Mix command above plus the narrow browser spec touched by the task.
- **After every plan wave:** Run the full suite command above.
- **Before `/gsd:verify-work`:** Full suite must be green, or any skipped browser gate must be documented with the environment reason.
- **Max feedback latency:** No three consecutive task commits without automated verification.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 184-01-01 | 01 | 1 | TIME-01 | T-184-01 | Timeline pivots use scoped query/export boundaries and do not expose unsafe row-history links | LiveView integration + browser flow | `mix test test/threadline/operator_surface/live/timeline_live_test.exs && mix verify.example_browser -- operator-earned-flows.spec.ts operator-find-mobile.spec.ts` | Yes | pending |
| 184-02-01 | 02 | 1 | TIME-02 | T-184-02 | Filters, saved views, pager, row actions, long refs, and state copy remain operable across required viewports | LiveView/source contract + browser responsive/a11y | `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/pager_test.exs test/threadline/operator_surface/style_contract_test.exs && mix verify.example_browser -- operator-responsive-mobile-first.spec.ts operator-accessibility.spec.ts` | Yes, browser gaps remain | pending |
| 184-03-01 | 03 | 2 | TIME-03 | T-184-03 | Incident-pressure copy is concise without hiding stale/error/empty meaning | Source contract + browser motion/responsive checks | `mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/style_contract_test.exs && mix verify.example_browser -- operator-motion.spec.ts operator-responsive-mobile-first.spec.ts` | Yes | pending |

---

## Wave 0 Requirements

- [ ] Add 320 px and 1440 px proof in `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` or a narrow Timeline-only browser spec.
- [ ] Add explicit safe/unsafe row-history direct-link coverage in `test/threadline/operator_surface/live/timeline_live_test.exs` if implementation changes Timeline row actions.
- [ ] Add browser proof for keyboard-only operation covering filters, result rows, copy controls, pagination, drawer close/return, and route transitions.
- [ ] If Timeline renders stale/last-good state directly, add LiveView/source coverage for that real branch; otherwise rely on the shared stale-state primitive proof.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Operator incident-pressure scan of copy and hierarchy | TIME-01, TIME-03 | Human judgment is useful for final copy density and workflow clarity | Review Timeline at 320, 375, 768, 1024, and 1440 px with realistic audit rows; confirm filter -> scan -> open history -> export remains obvious without explanatory in-app text |

---

## Validation Sign-Off

- [ ] All tasks have automated verification or Wave 0 dependencies.
- [ ] Sampling continuity: no three consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing references.
- [ ] No watch-mode flags.
- [ ] Browser proof covers 320, 375, 768, 1024, and 1440 px.
- [ ] `nyquist_compliant: true` set in frontmatter once the Wave 0 gaps are closed.

**Approval:** pending
