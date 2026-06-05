---
phase: 143-accessibility-consistency-sweep-regression
requirements: [POLISH-A11Y]
date: 2026-06-04
---

# Phase 143 Patterns

## Source Contracts

Existing source-contract pattern:

- `test/threadline/operator_surface/style_contract_test.exs`
- reads `lib/threadline/operator_surface/style.ex` using `File.read!`;
- asserts token values, selector blocks, forbidden patterns, media layers, and specific declarations.

Use this for:

- contrast token lock and contrast ratio helper;
- focus-visible coverage;
- no blanket focus removal without replacement;
- non-color-only status/verdict selector source patterns.

## Browser Specs

Existing Playwright specs are self-contained and use:

- local `login(page)` helpers;
- `expectNoHorizontalOverflow(page)`;
- `scrollIntoViewIfNeeded`;
- computed-style checks for motion/responsive behavior;
- dynamic route discovery through existing test IDs.

Use this for:

- keyboard Tab traversal;
- `:focus-visible` computed box-shadow checks;
- accessible names and ARIA states;
- drawer keyboard escape/close behavior if currently supported by the UI;
- screenshot guard.

## Screenshot Capture

Existing screenshot spec:

- `operator-screenshots.spec.ts`
- `capture(page, testInfo, name)` writes full-page PNGs to Playwright output.

For final artifacts:

- preserve existing browser assertions that wait for stable page content;
- add a path mode to write final screenshots to `.planning/milestones/v1.31-screenshots/final/`;
- keep CI/test-output screenshots separate from durable planning screenshots;
- do not commit Playwright `test-results`.

## Audit Closure

Use `.planning/milestones/v1.31-UI-AUDIT.md` as the finding registry.

For each finding:

- mark `closed-by-phase`, `verified-by`, or `accepted/deferred`;
- cite the phase summary/verification or the specific Phase 143 command;
- do not silently omit findings assigned to prior phases.

## Guard Pattern

Preferred guard:

- Playwright spec captures stable representative screenshots and uses `expect(buffer).toMatchSnapshot(...)`.
- Snapshot files live next to the spec in the Playwright snapshot convention so `npm test` and CI fail on unexpected drift.
- The spec is narrow enough to be a guard, not a complete visual audit; the complete final diff remains the human-readable `143-SCREENSHOT-DIFF.md`.

Fallback guard if Playwright snapshots are unsuitable:

- Node script compares dimensions and SHA256 hashes of a small guard set and reports deltas;
- `npm test` or a package script invokes it from the browser lane.

