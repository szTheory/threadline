# Phase 198 row-history focus regression

Date: 2026-09-08
Disposition: current-tree regression already covered; historical failure is not reproducible

## Historical symptom

The gap inventory carried an unexplained failure near the row-history accessibility scenario. The current scenario is `keeps row-history drawer dialog semantics and visible focus` in `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts`.

An initial focused command used the text `row history` and selected no tests because the test title uses the hyphenated form `row-history`. The command was corrected to the exact title before drawing any conclusion.

## Current regression contract

The checked-in E2E test already asserts all of the relevant behavior:

- the row-history drawer and named dialog are visible;
- the dialog has `aria-modal=true` and an accessible label relationship;
- the `View snapshot at` input is visible and keyboard-focusable;
- the focused input is not obscured; and
- the page has no horizontal overflow.

The responsive matrix independently exercises the row-history route on desktop and phone viewports and checks route usability and horizontal overflow.

## Reproduction and repeated evidence

Run from `examples/threadline_phoenix` with the repository's pinned Elixir/Erlang versions and test database host/port:

1. Exact mobile accessibility scenario: passed.
2. Exact mobile accessibility scenario with `--repeat-each=10`: 10/10 passed in 8.6 seconds.
3. Cross-project row-history selection over `operator-accessibility.spec.ts` and `operator-responsive-mobile-first.spec.ts`: 2/2 selected tests passed, one on `desktop-chromium` and one on `mobile-chromium`.

Commands:

```text
mix verify.example_browser operator-accessibility.spec.ts --project=mobile-chromium --grep row-history
mix verify.example_browser operator-accessibility.spec.ts --project=mobile-chromium --grep row-history --repeat-each=10
mix verify.example_browser operator-accessibility.spec.ts operator-responsive-mobile-first.spec.ts --project=desktop-chromium --project=mobile-chromium --grep row-history
```

## Diagnosis

There is no failing current-tree behavior to attribute. Later Phase 198 work already repaired row-history interaction sequencing and locator scope, and a prior full-suite rerun recorded that cleaning partially seeded test data resolved the accessibility failure. The exact current regression passes repeatedly, so claiming a new product root cause or changing thresholds would be fabrication.

A red control is likewise not honest here: there is no newly identified causal line to revert. Manufacturing one by weakening the checked-in assertion or reverting an unrelated historical repair would only prove that deliberately broken code can fail. The durable disposition is the existing named E2E regression plus repeated focused execution.

## Result

The unresolved human checkpoint is retired as automated E2E evidence. No product or test change was warranted; the current assertions remain intact and green.
