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

## Measured Phase 198-50 evidence

Phase 198 Plan 50 adds a synthetic, opt-in assertion-sensitivity control. This does not reverse the diagnosis above: the historical failure's original cause remains unestablished. The control proves only that the current `expectNonObscuredFocused` assertion detects a deterministic element covering the already-focused date input.

### Exact commands and results

All commands ran from the repository root on 2026-09-09 with `ASDF_ELIXIR_VERSION=1.19.5-otp-28` and `ASDF_ERLANG_VERSION=28.4.1`. Playwright retained the checked-in `timeout: 120_000`, `expect.timeout: 15_000`, local `retries: 0`, `workers: 1`, `trace: retain-on-failure`, and `screenshot: only-on-failure` settings.

```text
bash bin/verify-row-history-focus-red-control
mix verify.example_browser operator-accessibility.spec.ts --project=mobile-chromium --grep "keeps row-history drawer dialog semantics and visible focus" --repeat-each=10
mix verify.example_browser operator-accessibility.spec.ts operator-responsive-mobile-first.spec.ts --project=desktop-chromium --grep "row-history"
```

The prover issued the same five argument tokens for its negative and clean executions. The negative execution differed only by `THREADLINE_ROW_HISTORY_RED_CONTROL=obscure-date-input`; it exited non-zero with `expected non-obscured focus` from the protected helper. The clean execution removed that environment entry and passed. The repeated mobile command passed 10/10 in 8.9 seconds. The desktop adjacency command selected the named accessibility scenario and passed 1/1 in 1.0 seconds; the responsive spec has no test title matching the exact `row-history` grep.

```text
known_bad_expected_failures: 1
clean_passes: 1
mobile_repeat_passes: 10
desktop_adjacency_passes: 1
historical_failure_cause: not-established
```

### Structured attachment sample

A supplemental clean mobile run used the same named scenario with Playwright's JSON reporter to inspect the `row-history-focus-geometry` attachment. The attachment records synthetic DOM geometry and element identifiers only—no cookies, headers, field values, credentials, or environment variables.

```json
{
  "activeElement": {
    "ariaLabel": null,
    "id": "row-history-as-of",
    "name": "as_of",
    "role": null,
    "tag": "INPUT",
    "testId": null,
    "type": "datetime-local"
  },
  "dialogRect": {"bottom": 727, "height": 727, "left": 0, "right": 393, "top": 0, "width": 393},
  "dialogScroll": {"left": 0, "top": 0},
  "documentScroll": {"left": 0, "top": 0},
  "inputRect": {"bottom": 316.59375, "height": 40, "left": 37, "right": 357, "top": 276.59375, "width": 320},
  "visible": true,
  "windowViewport": {"height": 727, "width": 393},
  "attempt": {"repeatEachIndex": 0, "retry": 0, "workerIndex": 0},
  "project": "mobile-chromium",
  "trace": {
    "outputDirectory": "operator-accessibility-ope-ae950-semantics-and-visible-focus-mobile-chromium",
    "setting": "retain-on-failure"
  },
  "viewport": {"width": 393, "height": 727}
}
```

The scenario removes `[data-threadline-row-history-red-control]` in `finally` and asserts the marker count is zero on both paths. No product source, assertion threshold, retry, timeout, screenshot baseline, or Playwright configuration changed.
