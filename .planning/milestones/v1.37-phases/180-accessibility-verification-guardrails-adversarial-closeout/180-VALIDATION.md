---
phase: 180
slug: accessibility-verification-guardrails-adversarial-closeout
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-19
---

# Phase 180 - Validation Strategy

Per-phase validation contract for accessibility, motion, guardrail, and adversarial closeout work.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Frameworks | ExUnit via Mix; Playwright via `examples/threadline_phoenix/e2e/run-e2e.sh` |
| Config files | `mix.exs`; `examples/threadline_phoenix/e2e/playwright.config.ts` |
| Quick contract command | `mix test test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/component_contract_test.exs test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/card_nesting_regression_test.exs` |
| Browser accessibility command | `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-accessibility.spec.ts` |
| Browser motion command | `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-motion.spec.ts` |
| Guardrail continuity command | `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-phase-178-uat.spec.ts tests/operator-stress.spec.ts` |
| Light/system lane | `THREADLINE_E2E_THEME=system ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-accessibility.spec.ts tests/operator-motion.spec.ts tests/operator-stress.spec.ts` |
| Local screenshot evidence | `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-screenshot-regression.spec.ts` |
| Full suite command | `mix ci.all` with residual failure classification against Phase 179 |
| Estimated runtime | Quick contracts under a few minutes; browser lanes and `mix ci.all` are long-running gates |

## Sampling Rate

- After every task commit: run the smallest affected ExUnit or Playwright command for that task.
- After every plan wave: run quick contracts plus the affected browser spec.
- Before phase verification: run the full targeted matrix, light/system lane, optional local screenshot evidence, and `mix ci.all`.
- Max feedback latency: keep task-level checks focused; defer long browser matrix to wave and phase gates.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 180-01 | 01 | 1 | A11Y-01 | T-180-01 | Rendered operator states expose accessible names, landmarks, focus behavior, and keyboard paths without obscured focus or overflow. | browser | `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-accessibility.spec.ts` | yes | green |
| 180-02 | 02 | 2 | A11Y-02 | T-180-02 | Custom widgets follow applicable APG behavior; native/non-applicable controls are documented; color is not the only signal. | exunit + browser | `mix test test/threadline/operator_surface/component_contract_test.exs test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/style_contract_test.exs` plus targeted accessibility spec checks | yes | green |
| 180-03 | 03 | 3 | MOTION-01 | T-180-03 | Motion uses token durations/easing, avoids unsafe transforms, respects reduced motion, and keeps disabled controls still. | exunit + browser | `mix test test/threadline/operator_surface/style_contract_test.exs` and `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-motion.spec.ts` | yes | green |
| 180-04 | 04 | 4 | MOTION-02 | T-180-04 | Existing guardrails remain green; residual CI failures are classified; adversarial closeout separates source, browser, and automated accessibility-tree evidence. | exunit + browser + artifact | quick contract command, guardrail continuity command, light/system lane, local screenshot evidence, `mix ci.all` | yes | green |

Status: pending, green, red, flaky.

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No separate Wave 0 framework, fixture, or harness setup is required.

The Phase 180 plans still add failing or tightened checks during execution:

- Extend existing `operator-accessibility.spec.ts` coverage for D-04 rendered states where gaps remain.
- Extend existing component/style contracts for APG mapping, non-color-only signals, touch targets, and `scale(0)` absence.
- Extend existing `operator-motion.spec.ts` computed-style checks for easing, transition properties, reduced-motion collapse, press feedback, and dense-row stillness.
- Create final closeout/adversarial/automated accessibility-tree evidence artifacts during execution.

## Automated Accessibility-Tree Verifications

| Behavior | Requirement | Why This Evidence Is Bounded | Test Instructions |
|----------|-------------|------------|-------------------|
| Keyboard traversal and focus judgement across representative operator flows | A11Y-01 | Playwright verifies selectors, focus location, focus restoration, and non-obscured focus, but does not judge a human user's full keyboard experience. | Record bounded keyboard assertions for shell navigation, modal/drawer open-close, filter form, status/error state, and stress-route sample. |
| Accessibility-tree snapshots for landmarks, headings, labels, status, alert, dialog, drawer, menu, tab, and combobox states | A11Y-01 | Browser accessibility-tree snapshots are a deterministic proxy for screen-reader-ready structure; they do not prove real assistive-technology announcement timing, verbosity, rotor behavior, or user comprehension. | Attach ARIA snapshots from `operator-accessibility.spec.ts` and record browser/project, covered routes/states, gaps, and limits in `180-AUTOMATED-A11Y-EVIDENCE.md`. |
| Adversarial closeout judgement | MOTION-02 | The phase requires a written review of usability, architecture weight, route stability, screenshot-only risk, and residual CI ownership. | Write closeout evidence comparing final results to Phase 179 residual failures and Phase 180 requirements. |

## Validation Sign-Off

- [x] All phase requirements have automated verification or explicit bounded accessibility-tree evidence.
- [x] Sampling continuity keeps every implementation plan tied to affected checks.
- [x] Wave 0 gaps are scoped to extending existing files, not adding a new harness.
- [x] No watch-mode flags are part of the required commands.
- [x] Feedback latency is bounded by task-level focused commands.
- [x] `nyquist_compliant: true` is set in frontmatter.

Approval: approved 2026-06-19
