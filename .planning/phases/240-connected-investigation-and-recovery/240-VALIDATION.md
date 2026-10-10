---
phase: "240"
slug: "connected-investigation-and-recovery"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-10"
---

# Phase 240 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit / Phoenix LiveViewTest; Playwright @playwright/test 1.60.0 |
| **Config file** | mix.exs; examples/threadline_phoenix/e2e/playwright.config.ts |
| **Quick run command** | mix test test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/actor_live_test.exs test/threadline/operator_surface/ui_test.exs |
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
| 240-01-01 | 01 | 1 | UII-04 | T-240-01, T-240-02 | Bounded origin and canonical filters; reauthorize host scope; as-of changes are immediate without row motion. | Mounted browser journey | mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-earned-flows.spec.ts | ✅ existing | ✅ passed — focused desktop/mobile route cases and desktop 200% zoom passed; broader spec had an unrelated Evidence-to-Exports timeout |
| 240-01-02 | 01 | 1 | UII-04 | T-240-02, T-240-03 | Preserve parent authorization/scope; unavailable parent performs no child history read. | LiveView + browser integration | mix test test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/row_history_component_test.exs<br>mix verify.example_browser --project=desktop-chromium operator-earned-flows.spec.ts | ✅ existing | ✅ passed — scoped parent-gate ExUnit and desktop/mobile transaction-origin browser journey |
| 240-01-03 | 01 | 1 | UII-04 | T-240-03 | Direct failures remain retryable and distinct from absent/pruned/never-captured states. | LiveView/component integration | mix test test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/row_history_component_test.exs test/threadline/operator_surface/ui_test.exs | ✅ existing | ✅ passed — direct connection error remains retryable and distinct |
| 240-02-01 | 02 | 2 | UII-05 | T-240-05 | Use supported pivot filters; normal route re-evaluates host scope. | LiveView integration | mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/actor_live_test.exs | ✅ existing | ✅ passed — 79 combined tests, 0 failures |
| 240-02-02 | 02 | 2 | UII-06 | T-240-04 | Read/write SavedView only through current identifiable ActorRef; persist committed canonical filters. | LiveView integration | mix test test/threadline/operator_surface/live/timeline_live_test.exs | ✅ existing | ✅ passed — saved-search ownership and canonical restoration covered |
| 240-02-03 | 02 | 2 | UII-05, UII-06 | T-240-05, T-240-06 | Reauthorize pivots/share; prove saved-search overflow/actions and immediate pivot, apply, filter, and page state. | LiveView + rendered browser integration | mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-route-states.spec.ts | ✅ existing | ✅ passed — 13 browser cases, 19 intentional skips, 0 failures; 200% zoom on desktop |
| 240-03-01 | 03 | 3 | UIA-06 | T-240-07, T-240-08 | Keep authorized-copy boundary and factual API/fallback completion; preserve focus and cleanup. | Markup/component integration | mix test test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/transaction_live_test.exs | ✅ existing | ✅ passed — focused tests and full mix ci.all passed |
| 240-03-02 | 03 | 3 | UIA-06 | T-240-07, T-240-08 | No duplicate/early success; copy starts on activation, status does not overlap controls/source, and long authorized text stays selectable without page overflow. | Desktop/mobile browser integration | mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-route-states.spec.ts | ✅ existing | ✅ passed — 21 browser cases, 19 intentional skips; clipboard and pending-query cases each repeated 10 times per project |
| 240-04-01 | 04 | 2 | UIA-07 | T-240-09 | Evidence rows and as-of updates render immediately without entrance animation, delay, or stagger. | Browser motion integration | mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-motion.spec.ts | ✅ existing | ✅ passed — motion and accessibility browser set: 48 passed, 0 failed |
| 240-04-02 | 04 | 2 | UIA-07 | T-240-09 | Keyboard activation/Escape and focus return are immediate; reduced motion and repeated patches preserve state. | Browser accessibility + motion | mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-accessibility.spec.ts operator-motion.spec.ts | ✅ existing | ✅ passed — keyboard, Escape, focus return, reduced-motion, desktop/mobile |

> Final mapping aligns all 10 task IDs, waves, requirements, threat references, and automated commands with plans 240-01 through 240-04.

## Wave 0 Requirements

Existing LiveView and Playwright infrastructure covers all phase requirements. PostgreSQL 15+ is required for valid local integration and phase-gate verification; the currently available PostgreSQL 14 instance is below the project floor.

## Manual-Only Verifications

All phase behaviors have automated verification; no manual-only verification is planned.

## Validation Sign-Off

- [x] All tasks have <automated> verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [ ] Feedback latency < 300 seconds for focused validation — per-task durations were not retained; 300 seconds remains an estimate.
- [x] nyquist_compliant: true set in frontmatter

**Approval:** Automated evidence reviewed; no manual-only checks remain.

## Validation Audit 2026-10-10

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 7 |
| Escalated | 0 |

## Phase Gate Results

`mix ci.all` passed on PostgreSQL 15 in partition `2400316`: root tests 3,100/0 failures, Phoenix example tests 132/0 failures, Dialyzer 0 errors, and Playwright 385 passed / 71 skipped. A previous attempt hit a transient example sandbox idle-transaction timeout; the isolated example suite and subsequent full run both passed.
