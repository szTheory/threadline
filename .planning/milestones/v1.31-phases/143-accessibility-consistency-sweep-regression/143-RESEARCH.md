---
phase: 143-accessibility-consistency-sweep-regression
requirements: [POLISH-A11Y]
date: 2026-06-04
---

# Phase 143 Research

## Accessibility Baseline

The relevant WCAG 2.1 AA checks for this final sweep are:

- Text contrast: normal text must be at least 4.5:1, large text at least 3:1.
- Non-text focus indication: keyboard focus must be visible and not removed.
- Keyboard operation: all interactive controls must be reachable and usable without pointer input.
- Name/role/value: interactive primitives need accessible names, selected states, disabled states, and ARIA semantics where native semantics are insufficient.
- Non-color-only meaning: status/verdict must include text/shape/state, not just hue.

The operator surface already has:

- central `--tl-focus-ring`;
- `:focus-visible` coverage for buttons, links, inputs, selects, summaries, and `[role="button"]`;
- skip link;
- dark-first token palette;
- explicit nav `aria-current`;
- segmented controls using `aria-pressed`;
- copy buttons with `aria-label`;
- policy/details and table/card labels in markup.

Remaining risk areas:

- muted text contrast on `--tl-color-bg`, `--tl-color-surface`, and raised surfaces;
- `--tl-color-info-text` / inferred verdict treatment reading like link/action blue;
- focus order and visible focus on topbar nav, Home forms, Timeline filters, segmented controls, details rows, row-history drawer, export actions, and destructive retention controls;
- stale browser specs masking real final regression status.

## Screenshot Baseline

Phase 134 baseline screenshots are present under:

`.planning/milestones/v1.31-screenshots/baseline/`

The baseline contains 24 PNG files:

- actor, coverage, evidence, exports, home, redaction, retention, row-history, timeline-dense, timeline-empty, timeline, transaction;
- each at `1280` and `375`.

There is no Phase 134 phase directory currently present under `.planning/phases`, so the durable screenshot SSOT is the milestone screenshot directory plus `.planning/milestones/v1.31-UI-AUDIT.md`.

## Existing Screenshot Flow

`examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts` captures full-page PNGs to Playwright `testInfo.outputPath(...)`.

Current failures in that spec are stale assertions:

- unscoped `[REDACTED]` selector became ambiguous after row-history/transaction both render the redacted token;
- empty Timeline copy changed from `No changes match` to the Phase 138 locked copy.

This spec is a good foundation for final screenshot collection after stale selectors/copy are fixed.

## CI Lane

`mix verify.example_browser` calls `examples/threadline_phoenix/e2e/run-e2e.sh`, which runs `npm test` in the E2E package.

`.github/workflows/ci.yml` already runs `mix verify.example_browser` in the browser CI job.

Therefore any new Playwright spec under `examples/threadline_phoenix/e2e/tests/` is already wired into the CI lane. A lightweight guard can be added as a Playwright spec without changing CI, or with a package script if a narrower local command is useful.

## Plan Implications

- First fix the browser suite’s stale failures and add accessibility assertions so the final gate is meaningful.
- Then capture final screenshots and write a human-readable diff report against the 24-file baseline.
- Then add an automated screenshot guard in Playwright. Prefer Playwright snapshots over a custom PNG dependency unless existing constraints require arbitrary baseline directory comparison.
- Keep generated screenshots out of `test-results`; final durable artifacts go under `.planning/milestones/v1.31-screenshots/final/`.

