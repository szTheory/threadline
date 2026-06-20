---
phase: 180-accessibility-verification-guardrails-adversarial-closeout
plan: 04
subsystem: ui
tags: [accessibility, guardrails, screenshots, playwright, residual-ci, adversarial-review]

requires:
  - phase: 180-accessibility-verification-guardrails-adversarial-closeout
    provides: Plans 180-01 through 180-03 accessibility, APG, and motion guardrails.
provides:
  - MOTION-02 guardrail matrix completion.
  - Automated accessibility-tree evidence replacing manual screen-reader checkpoint.
  - Residual CI classification against Phase 179 inherited failures.
  - Adversarial closeout review.
affects: [phase-180, accessibility-verification, operator-surface, motion-guardrails]

tech-stack:
  added: []
  patterns:
    - Existing Playwright ARIA snapshots for bounded accessibility-tree evidence.
    - Existing screenshot regression harness with current seeded-row discovery.
    - Existing ExUnit retention tests aligned to conditional modal mounting.

key-files:
  created:
    - .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-AUTOMATED-A11Y-EVIDENCE.md
    - .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-ADVERSARIAL-REVIEW.md
    - .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-RESIDUAL-CI.md
    - .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-VERIFICATION.md
    - .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-04-SUMMARY.md
  modified:
    - examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts-snapshots/*.png
    - examples/threadline_phoenix/config/test.exs
    - test/threadline/operator_surface/live/retention_history_live_test.exs
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md
    - .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-04-PLAN.md
    - .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-VALIDATION.md

key-decisions:
  - "Replace the manual screen-reader checkpoint with Playwright accessibility-tree snapshots and explicit proof limits; no real AT UAT is claimed."
  - "Disable LiveView origin checking in Phoenix test config only so the dynamic e2e runner ports can connect sockets."
  - "Repair screenshot guard discovery to use current `ticket_replies` seeded rows, then refresh local screenshot baselines from current rendered output."
  - "Fix retention LiveView tests to open the conditionally mounted destructive modal before asserting/submitting the prune form."

requirements-completed: [MOTION-02]
duration: completed 2026-06-20
completed: 2026-06-20
status: complete
---

# Phase 180 Plan 04: Guardrail And Adversarial Closeout Summary

**MOTION-02 is complete through existing guardrails, automated accessibility-tree evidence, refreshed screenshot baselines, residual CI classification, and adversarial review.**

## Accomplishments

- Added Playwright ARIA snapshot evidence for Home, Timeline filters, row-history drawer, stress dropdown/menu, stress modal, and stress drawer states.
- Kept accessibility proof honest: the artifacts state that browser accessibility-tree evidence is not a real screen-reader or human UAT pass.
- Fixed the dynamic-port LiveView socket issue in test config so e2e runs connect on runner-selected localhost ports.
- Aligned screenshot regression discovery with current seeded `ticket_replies` rows and refreshed the local desktop/mobile screenshot baselines.
- Fixed retention modal ExUnit tests after the Plan 180-01 focus-management change made the destructive prune form conditional.
- Classified `mix ci.all` residual failures against the Phase 179 baseline.

## Task Commits

1. `b42b330` - `test(180-04): align stress guardrail matrix`
2. `d5b5f34` - `test(180-04): automate accessibility tree evidence`
3. Current closeout commit - screenshot/retention fixes and Phase 180 artifacts.

## Verification

- `mix test test/threadline/operator_surface/live/retention_history_live_test.exs` - passed, 15 tests, 0 failures.
- `mix test test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/component_contract_test.exs test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/card_nesting_regression_test.exs test/threadline/operator_surface/stress_fixtures_test.exs test/threadline/operator_surface/stress_ledger_test.exs test/threadline/operator_surface/stress_router_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs` - passed, 189 tests, 0 failures.
- `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-accessibility.spec.ts tests/operator-motion.spec.ts tests/operator-phase-178-uat.spec.ts tests/operator-stress.spec.ts` - passed, 150 passed, 6 skipped.
- `THREADLINE_E2E_THEME=system ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-accessibility.spec.ts tests/operator-motion.spec.ts tests/operator-stress.spec.ts` - passed, 28 passed, 3 skipped.
- `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-screenshot-regression.spec.ts` - passed, 10 passed, 5 skipped.
- `mix ci.all` - inherited residuals only: root 1120 tests, 1 failure, 1 excluded; example 95 tests, 7 failures.

## Deviations From Original Plan

- The blocking manual screen-reader checkpoint was replaced at user direction with automated Playwright accessibility-tree evidence.
- The screenshot guard was made green rather than waived: stale seeded-row assumptions were fixed and local baselines were refreshed.
- A Phase 180-owned retention test mismatch found by `mix ci.all` was fixed instead of classified as residual.

## Residuals

`mix ci.all` remains non-green only for inherited Phase 179 documentation/demo-seed failures recorded in `180-RESIDUAL-CI.md`.

## Self-Check

- Closeout artifacts exist and are non-empty.
- MOTION-02 is marked complete in requirements tracking.
- No package, public route, production host contract, public component API, or new accessibility framework was added.
