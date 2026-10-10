---
phase: "240"
slug: "connected-investigation-and-recovery"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-10"
---

# Phase 240 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit / Phoenix LiveViewTest; Playwright @playwright/test 1.60.0 |
| **Config file** | mix.exs; examples/threadline_phoenix/e2e/playwright.config.ts |
| **Quick run command** | mix test test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/actor_live_test.exs |
| **Full suite command** | mix ci.all |
| **Estimated runtime** | ~300 seconds (planning estimate; revise from first measured run) |

## Sampling Rate

- **After every task commit:** Run the smallest affected ExUnit file(s); use focused Playwright specs for browser behavior.
- **After every plan wave:** Run mix verify.test and the focused browser specs touched in that wave.
- **Before $gsd-verify-work:** Run mix ci.all on PostgreSQL 15+.
- **Max feedback latency:** ~300 seconds for the focused validation set; full CI is a phase gate.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 240-01-01 | 01 | 1 | UII-04 | T-240-01, T-240-04 | Reconstruct local return paths from bounded state; preserve parent outage and row-history evidence distinctions. | LiveView integration | mix test test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/transaction_live_test.exs | ✅ existing | ⬜ pending |
| 240-02-01 | 02 | 2 | UII-05, UII-06 | T-240-02 | Re-evaluate current actor and host scope; save only canonical committed supported filters. | LiveView integration | mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/actor_live_test.exs | ✅ existing | ⬜ pending |
| 240-03-01 | 03 | 3 | UIA-06 | T-240-03, T-240-05 | Expose only authorized copyable values and announce success only after confirmed completion. | Browser integration + markup | mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-earned-flows.spec.ts operator-route-states.spec.ts | ✅ existing | ⬜ pending |
| 240-03-02 | 03 | 3 | UIA-07 | — | Keep frequent interactions immediate; preserve focus, interruptible drawer behavior, and reduced-motion preferences. | Browser accessibility / motion | mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-accessibility.spec.ts operator-motion.spec.ts | ✅ existing | ⬜ pending |

> The planner should align plan/wave/task identifiers and threat references with the final dependency graph while retaining this requirement-to-test coverage.

## Wave 0 Requirements

Existing LiveView and Playwright infrastructure covers all phase requirements. PostgreSQL 15+ is required for valid local integration and phase-gate verification; the currently available PostgreSQL 14 instance is below the project floor.

## Manual-Only Verifications

All phase behaviors have automated verification; no manual-only verification is planned.

## Validation Sign-Off

- [ ] All tasks have <automated> verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 300 seconds for focused validation
- [ ] nyquist_compliant: true set in frontmatter

**Approval:** pending
