---
phase: 180-accessibility-verification-guardrails-adversarial-closeout
artifact: automated-a11y-evidence
requirement: A11Y-01
created: 2026-06-20
status: passed
---

# Phase 180 Automated Accessibility Evidence

## Scope

This artifact replaces the originally planned manual screen-reader checkpoint with deterministic browser evidence. It records what Playwright proved and what it did not prove.

No real screen reader, assistive-technology pairing, or human UAT session was run or claimed.

## Environment

| Field | Value |
|-------|-------|
| Date | 2026-06-20 |
| Browser projects | Chromium, desktop Chromium, mobile Chromium, desktop Chromium light/system |
| Tooling | Existing Playwright e2e harness; `locator.ariaSnapshot()`; role/name/focus assertions |
| New dependencies | None |
| Key test | `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` |

## Surfaces Tested

| Surface | Evidence |
|---------|----------|
| Home | Main landmark, H1, system-health status, Timeline link, table combobox, record-id textbox, row-history action |
| Timeline filters | Investigation region, primary filters, advanced filters drawer, search grouping, status output |
| Row-history drawer | Dialog role/name, close link, snapshot-at input, row timeline list |
| Stress preview menu | Dropdown trigger expanded state, combobox, validation alert, tablist |
| Stress modal | Dialog role/name, heading, confirm button |
| Stress drawer | Dialog role/name, heading, close button |
| Keyboard/focus flows | Skip link, shell nav, mobile nav, modal/drawer focus entry and restoration, non-obscured focus checks |

## Results

| Command | Result |
|---------|--------|
| `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-accessibility.spec.ts` | Passed before closeout: 24 tests, 0 failures |
| `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-accessibility.spec.ts tests/operator-motion.spec.ts tests/operator-phase-178-uat.spec.ts tests/operator-stress.spec.ts` | Passed after closeout fixes: 150 passed, 6 skipped |
| `THREADLINE_E2E_THEME=system ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-accessibility.spec.ts tests/operator-motion.spec.ts tests/operator-stress.spec.ts` | Passed: 28 passed, 3 skipped |

The accessibility-tree test attaches these text snapshots to the Playwright report:

- `home-main-aria-snapshot`
- `timeline-main-aria-snapshot`
- `row-history-drawer-aria-snapshot`
- `stress-menu-aria-snapshot`
- `stress-modal-aria-snapshot`
- `stress-drawer-aria-snapshot`

## Limits Of Proof

This evidence proves that the sampled rendered states expose expected roles, names, headings, controls, expanded state, dialog/drawer structure, status/alert structure, and keyboard focus behavior in Chromium's accessibility tree.

This evidence does not prove:

- Real screen-reader announcement timing or verbosity.
- Rotor/quick-nav behavior in VoiceOver, NVDA, JAWS, Narrator, or TalkBack.
- User comprehension or operator task success with assistive technology.
- Every possible row, seed, capability, theme, localization, browser, or host integration state.

## Gaps

No Phase 180-owned A11Y-01 gap remains in the automated evidence. The explicit residual gap is that no human assistive-technology UAT was performed.
