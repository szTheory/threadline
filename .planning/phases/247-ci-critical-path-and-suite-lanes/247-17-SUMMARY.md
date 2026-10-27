---
phase: 247-ci-critical-path-and-suite-lanes
plan: 17
subsystem: testing
status: complete
tags: [playwright, motion, focus, gap-closure]
requires:
  - phase: 247-15
    provides: Historical excluded failed motion run and proved sibling synchronization
provides:
  - State-synchronized modal-to-toast motion fixtures
  - Two-project no-retry browser proof and preserved failed-run disposition
affects: [247-18, 247-19]
tech-stack:
  added: []
  patterns: [await-modal-hidden-and-opener-focused]
key-files:
  created: []
  modified: [examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts, .planning/phases/247-ci-critical-path-and-suite-lanes/deferred-items.md]
requirements-completed: []
requirements-implemented: [CI-02, CI-03]
coverage:
  - id: motion-focus
    description: Modal focus restoration finishes before the toast/drawer path on both projects
    requirement: CI-02
    verification:
      - {kind: e2e, ref: 'CI=true mix verify.example_browser operator-motion.spec.ts --project=desktop-chromium --project=mobile-chromium --retries=0', status: pass}
    human_judgment: false
actuals: {tokens: 1500, tasks: 2, commits: 2}
duration: 7min
completed: 2026-10-27
---

# Phase 247 Plan 17 Summary

**The default and reduced-motion fixtures wait for the stress modal to hide and its exact Show Modal opener to regain focus before continuing.**

## Changes

The default-motion modal confirmation now awaits `#stress-modal` hidden and `modalOpener` focused before the existing Close focus, keyboard Enter and toast-hidden assertion. The reduced-motion fixture also awaits opener focus after its existing hidden assertion before pointer dismissal/drawer interaction. Motion/style assertions, keyboard action, projects, workers and retries are unchanged. No sleeps or product source changes.

Historical main attempt 40435657557 / mobile job 121963594493 at B3 89add23e remains failed and excluded. Its attempt/job was never rerun or reclassified. Only the recorded motion paragraph in deferred-items.md gains the new-source disposition and evidence pointer.

## Verification

Exact source HEAD for the complete motion run: 832bfe5e788310dd0d46341f03bdb14add5922d6 (source file remains unchanged in later docs commits).

- Focused stress overlays case via `mix verify.example_browser`, desktop and mobile, `--retries=0`: 2 passed (7.4 s), one per project.
- Complete `operator-motion.spec.ts`, both projects, `--retries=0`: 24 passed (22.5 s), 12 desktop and 12 mobile; exit 0, no skips or retries.
- Example-app `mix precommit`: exit 0, 132 tests, 0 failures; compile, unused-dependency check and format also passed.
- Independent automated reviewer: no findings; checked sibling parity, preserved keyboard/toast/motion assertions and both project receipts.
- `git diff --check` passed; historical failed run retained by literal readback.
- Used ephemeral loopback postgres:16 labelled dev.threadline.plan=247-17; removed after verification.

## Task commits

1. Motion synchronization and focused browser proof: 832bfe5e.
2. Full-spec proof and historical disposition: d0a338f8.

## Deviations and issues

Playwright installer needed browser-cache access outside the managed filesystem sandbox. Stopped only that task-owned waiting installer and repeated the named entrypoint with browser access; no source workaround or test retry. The complete specification and example precommit passed afterward. Existing non-blocking dependency advisories and runtime migration-module warnings are unchanged.

## Self-Check: PASSED

Both modified paths exist, plan-scoped commits are reachable, focused and complete project runs passed without retries, and the historical exclusion remains. Numeric CI-03 acceptance is still reserved for new protected-main measurements.
