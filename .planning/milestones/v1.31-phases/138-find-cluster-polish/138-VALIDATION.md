---
phase: 138
slug: find-cluster-polish
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-04
---

# Phase 138 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.LiveViewTest; Playwright through example app E2E |
| **Config file** | `mix.exs`; `examples/threadline_phoenix/e2e` |
| **Quick run command** | `mix test test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/row_history_component_test.exs test/threadline/operator_surface/live/actor_live_test.exs test/threadline/operator_surface/live/coverage_live_test.exs` |
| **Full suite command** | `mix ci.all` |
| **Browser UAT command** | `mix verify.example_browser` |
| **Estimated runtime** | Focused suite under 60 seconds; browser/full suite depends on local services |

---

## Sampling Rate

- **After every task commit:** Run the focused command for the files touched by that task.
- **After every plan wave:** Run the focused Find suite; run `mix verify.example_browser` after the Find mobile Playwright spec exists.
- **Before `$gsd-verify-work`:** `mix ci.all` must be green, with explicit note if browser verification is unavailable.
- **Max feedback latency:** no more than one task without an automated focused verification command.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 138-01-01 | 01 | 1 | POLISH-FIND | T-138-01 | Helper output is escaped data, not raw HTML | unit/contract | `mix test test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/style_contract_test.exs` | yes | pending |
| 138-02-01 | 02 | 2 | POLISH-FIND | T-138-02 | Transaction and row-history values preserve authorized scope and escaped output | LiveView/component | `mix test test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/row_history_component_test.exs` | yes | pending |
| 138-03-01 | 03 | 2 | POLISH-FIND | T-138-03 | Timeline filters remain validated/scoped and long refs expose only authorized visible values | LiveView + browser | `mix test test/threadline/operator_surface/live/timeline_live_test.exs` and `mix verify.example_browser` | Playwright spec missing | pending |
| 138-04-01 | 04 | 3 | POLISH-FIND | T-138-04 | Actor summaries avoid N+1 scope bypass and Coverage schema input remains validated | LiveView + browser | `mix test test/threadline/operator_surface/live/actor_live_test.exs test/threadline/operator_surface/live/coverage_live_test.exs` and `mix verify.example_browser` | Playwright spec missing | pending |

*Status: pending, green, red, flaky.*

---

## Wave 0 Requirements

- [ ] `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts` - covers Timeline dense/mobile, Transaction constrained content, Row-history values, Actor summaries, and Coverage remediation.
- [ ] `test/threadline/operator_surface/presentation_test.exs` - value tokens, expected-gap grammar, coverage remediation labels, and actor transaction summaries.
- [ ] `test/threadline/operator_surface/row_history_component_test.exs` - snapshot value fixtures for null and timestamps.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Dense/mobile visual pressure on Timeline | POLISH-FIND | Source and LiveView assertions do not fully prove first-viewport scan order | Run `mix verify.example_browser`, inspect generated mobile screenshots, and confirm active filters plus rows appear before inert orientation chrome dominates the viewport. |
| Actor summary fallback acceptability | POLISH-FIND | Implementation may choose the locked fallback if bounded preload is not feasible | Confirm Actor rows either show operation/table/change-count summaries or the honest `Changes unavailable` fallback plus `Open transaction`, with no misleading first-table-only labels. |

---

## Validation Sign-Off

- [x] All planned task families have automated verify commands or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers missing browser/mobile and helper fixture references.
- [x] No watch-mode flags.
- [x] Feedback latency is bounded to focused ExUnit/LiveView commands per task.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-06-04
