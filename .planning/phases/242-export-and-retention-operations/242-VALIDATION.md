---
phase: "242"
slug: "export-and-retention-operations"
status: draft
nyquist_compliant: false
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
| **Estimated runtime** | ~240 seconds for focused ExUnit plus targeted desktop/mobile browser checks; estimate only, measure in the first execution wave. |

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
| 242-01-01 | 01 | 1 | UIO-01 | T-242-01 | Actor-owned persisted jobs; validated local return path; controller remains the per-request download authority. | LiveView + controller | `mix test test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs` | ✅ | ⬜ pending |
| 242-01-02 | 01 | 1 | UIO-01 | T-242-01 | Queue acceptance, failed enqueue, missing/expired file, and source-query restoration remain distinct. | Mounted browser | `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-route-states.spec.ts` | ✅ | ⬜ pending |
| 242-02-01 | 02 | 1 | UIO-05 | T-242-02, T-242-03, T-242-04 | Exact confirmation and server authorization precede audit and prune; one existing run records accepted, running, partial, and terminal outcomes without raw exception disclosure. | ExUnit | `mix test test/threadline/operator_surface/live/retention_history_live_test.exs test/threadline/retention/pruner_test.exs test/threadline/retention_test.exs` | ✅ | ⬜ pending |
| 242-03-01 | 03 | 2 | UIO-05, UIA-05 | T-242-02, T-242-03, T-242-04 | Scope and status remain accurate; keyboard and pointer mutations are natively unavailable while disconnected/in flight; reconnect reconciles persisted state and creates no implicit duplicate. | Mounted browser | `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-route-states.spec.ts operator-accessibility.spec.ts` | ✅, add socket-loss coverage | ⬜ pending |
| 242-03-02 | 03 | 2 | UIA-05 | T-242-03 | Shared status announcement remains readable; source search, jobs, runs, and modal controls work at narrow widths, themes, keyboard, reduced motion, and actual 200% zoom. | Mounted browser | `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-accessibility.spec.ts operator-motion.spec.ts operator-zoom-proof.spec.ts` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

Existing ExUnit, LiveView test helpers, mounted Playwright configuration, browser projects, and example-app dependencies cover the phase. No framework, package, migration, or generated service is required. Add socket-loss/reconnect assertions to the existing route-state suite as a planned test change.

---

## Manual-Only Verifications

All phase behaviors have automated verification. Browser coverage must exercise an actual LiveView transport loss and restoration, not only toggle a CSS class; the existing zoom proof must use browser zoom as specified by its test contract.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 300s (estimated; remeasure in execution)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution evidence
