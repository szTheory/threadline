# Phase 143 Screenshot Diff: Baseline to Final

## Capture

- Baseline: `.planning/milestones/v1.31-screenshots/baseline/`
- Final: `.planning/milestones/v1.31-screenshots/final/`
- Matrix: 12 screens x 2 viewports = 24 baseline PNGs and 24 final PNGs.
- Final capture command:
  - `cd examples/threadline_phoenix/e2e && OPERATOR_SCREENSHOT_DIR=/Users/jon/projects/threadline/.planning/milestones/v1.31-screenshots/final E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-screenshots.spec.ts`
- Result: 6 tests, 0 failures.

## Delta Summary

| Screen | 1280 baseline -> final | 375 baseline -> final | Delta | Status |
|---|---:|---:|---|---|
| home | 1280x900 -> 1280x1130 | 375x1111 -> 375x1905 | Intentional: Phase 139 Home/nav orientation plus Phase 140 EF1/EF4 workflow launchers add content below the hero. | explained |
| timeline | 1280x3928 -> 1280x3959 | 375x8312 -> 375x8463 | Intentional: Phase 138 find polish adds richer row values, empty/future copy support, and stable refs. | explained |
| timeline-dense | 1280x3928 -> 1280x979 | 375x8312 -> 375x2748 | Intentional: final dense capture uses correlation-focused seeded incident thread rather than the original broad dense window; row content remains visible and tested by responsive/browser specs. | explained |
| timeline-empty | 1280x900 -> 1280x902 | 375x2102 -> 375x2260 | Intentional: Phase 138 empty copy is now specific recovery copy: `No captured changes match this window`. | explained |
| transaction | 1280x900 -> 1280x900 | 375x812 -> 375x1030 | Intentional: Phase 138 value rendering exposes actual changed fields and stable copy/ref affordances. | explained |
| row-history | 1280x900 -> 1280x900 | 375x812 -> 375x1030 | Intentional: Phase 138/140 first-class row-history and accessible drawer semantics keep the drawer content inspectable. | explained |
| actor | 1280x900 -> 1280x900 | 375x897 -> 375x1013 | Intentional: Phase 138 actor rows now include blast-radius summaries; Phase 143 exposes selected window state. | explained |
| coverage | 1280x1437 -> 1280x2265 | 375x3606 -> 375x4647 | Intentional: Phase 138 coverage remediation adds real Add capture commands and denser explanatory content. | explained |
| evidence | 1280x1245 -> 1280x1111 | 375x1899 -> 375x2199 | Intentional: Phase 137/140 evidence proof flow and export handoff reorganize proof context and controls. | explained |
| exports | 1280x1414 -> 1280x1892 | 375x2475 -> 375x3220 | Intentional: Phase 137/140 readiness grouping and carried export context add sections but make ready/failed/queued states clearer. | explained |
| redaction | 1280x1233 -> 1280x1265 | 375x1700 -> 375x1778 | Intentional: Phase 137 status treatment and mobile wrapping polish add small content/spacing deltas. | explained |
| retention | 1280x900 -> 1280x900 | 375x1447 -> 375x1598 | Intentional: Phase 137/140 retention safety hierarchy and confirm semantics keep destructive action behind context. | explained |

## Unchanged Surfaces

- Desktop 900px-height screens that remain same-height: Actor, Retention, Row history, Transaction.
- Final file names match the Phase 134 baseline naming scheme exactly.
- No generated Playwright `test-results` screenshot artifacts are part of the durable final matrix.

## Unexplained Deltas

None. Every final delta is intentional and traced to phases 135-143.
