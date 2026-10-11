---
phase: "242"
slug: "export-and-retention-operations"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-10"
---

# Phase 242 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit for root package; Playwright for mounted Phoenix example browser tests. |
| **Config file** | `test/test_helper.exs`; `examples/threadline_phoenix/e2e/playwright.config.ts`. |
| **Quick run command** | `mix test test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs test/threadline/retention/pruner_test.exs test/threadline/retention_test.exs` |
| **Full suite command** | `mix ci.all` |
| **Measured runtime** | Focused ExUnit audit run: 3.6 seconds (111 tests); final focused retention set: 53 tests, 0 failures. Canonical `mix ci.all` passed with 3,125 root tests, 132 example tests, and 414 desktop/mobile Playwright checks; 66 browser cases were intentionally skipped. |

---

## Sampling Rate

- **After every task commit:** Run the affected ExUnit file(s) from the quick command.
- **After every plan wave:** Run the full quick ExUnit command and relevant named browser suite.
- **Before `$gsd-verify-work`:** `mix ci.all` and the full affected mounted-browser journeys must be green.
- **Max feedback latency:** 300 seconds for the focused validation set; measure and revise if the actual command exceeds this budget.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 242-01-01 | 01 | 1 | UIO-01 | T-242-01 | Actor-owned persisted jobs; validated local return path; controller remains the per-request download authority. | LiveView + controller | `mix test test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs` | ✅ | ✅ green (included in 111-test focused run) |
| 242-01-02 | 01 | 1 | UIO-01 | T-242-01 | Queue acceptance, failed enqueue, missing/expired file, and source-query restoration remain distinct. | Mounted browser | `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-route-states.spec.ts` | ✅ | ✅ green; current `mix ci.all` passed both desktop and mobile browser projects |
| 242-02-01 | 02 | 1 | UIO-05 | T-242-02, T-242-03, T-242-04 | Exact confirmation and server authorization precede audit and prune; one existing run records accepted, running, partial, and terminal outcomes without raw exception disclosure, including worker-start failure recovery. | ExUnit | `mix test test/threadline/operator_surface/live/retention_history_live_test.exs test/threadline/retention/pruner_test.exs test/threadline/retention_test.exs` | ✅ | ✅ green; final focused retention tests 53/0, including injected `Task.start/1` failure regression; full root suite passed 3,125/0 |
| 242-03-01 | 03 | 2 | UIO-05, UIA-05 | T-242-02, T-242-03, T-242-04 | Scope and status remain accurate; keyboard and pointer mutations are natively unavailable while disconnected/in flight; reconnect reconciles persisted state and creates no implicit duplicate. | Mounted browser | `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-route-states.spec.ts operator-accessibility.spec.ts` | ✅, socket-loss coverage added | ✅ green; full `mix ci.all` passed both desktop and mobile projects, including the real socket-loss route-state and accessibility checks |
| 242-03-02 | 03 | 2 | UIA-05 | T-242-03 | Shared status announcement remains readable; source search, jobs, runs, and modal controls work at narrow widths, themes, keyboard, reduced motion, and actual 200% zoom. | Mounted browser | `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-accessibility.spec.ts operator-motion.spec.ts operator-zoom-proof.spec.ts` | ✅ | ✅ green; full `mix ci.all` passed the desktop actual 200% zoom proof and both projects' accessibility/motion checks; mobile actual zoom instrumentation remains unsupported/skipped |

---

## Wave 0 Requirements

Existing ExUnit, LiveView test helpers, mounted Playwright configuration, browser projects, and example-app dependencies cover the phase. No framework, package, migration, or generated service is required. Real socket-loss/reconnect assertions now exist in the route-state and accessibility suites. Route-state tests close and restore the LiveView WebSocket, assert native disabled state for pointer/Enter/Space paths, wait for a changed server-rendered freshness revision, verify counts stay stable during recovery, and prove only a later deliberate action starts a new export. Retention focus/cancel coverage asserts no prune on cancellation.

---

## Manual-Only Verifications

No manual-only behavior remains. The existing zoom proof reads actual tab zoomFactor 2 on desktop Chromium. Mobile actual zoom instrumentation is explicitly unsupported by the installed browser. A restricted sandbox retry could not launch Chromium (MachPortRendezvous permission denied), but the canonical `mix ci.all` run completed on the permitted browser runner and passed the full desktop/mobile lane.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Focused ExUnit feedback latency < 300s (3.6 seconds); canonical full CI completed successfully
- [x] `nyquist_compliant: true` set in frontmatter

**Audit result:** All five task rows have concrete behavioral assertions and execution evidence. The focused audit ExUnit rerun passed 111 tests; the focused retention suite passed 53 tests with 0 failures, including an injected `Task.start/1` failure regression proving worker-start recovery. The canonical `mix ci.all` passed Credo, dependency audit, repository hygiene, cycle checks, 3,125 root tests with 0 failures, 132 example tests with 0 failures, Dialyzer, live-slice checks, and 414 Playwright checks with 66 intentional skips.

## Validation Audit 2026-10-11

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 5 |
| Escalated | 0 |

The cross-phase regression gate also passed: `mix test` completed with 3,125 tests, 0 failures, and 3 excluded. Its first sandbox run could not create a temporary linked worktree under the read-only `.git` boundary; the permission-enabled retry passed the full suite.
