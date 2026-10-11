---
phase: investigation-entry-and-transaction-composition
plan: "03"
subsystem: operator-ui
tags: [phoenix-liveview, transaction-detail, audit-evidence, playwright]
requires:
  - phase: 238-current-main-preview-and-acceptance-baseline
    provides: accepted current-main source baseline and isolated seeded browser runner
provides:
  - Transaction detail composition with separate action and row-change evidence
  - Keyboard-operable full-value disclosures for authorized values and exact times
  - Distinct zero-change, not-found, and connection-failure states with scoped denial privacy
affects: [239-04, 239-05, 239-07]
actuals:
  tokens: 8338
  tasks: 3
  commits: 3
  plan_head_before: 3d06a285288bdcd45e7c9489397684cb1a5c4792
  plan_head_after: af274a5af5a7d7739d4380829d578b865acbaab8
tech-stack:
  added: []
  patterns:
    - Native details and summary reveal authorized full values alongside abbreviated references
    - Transaction row evidence is rendered only from that transaction's incident bundle
    - Connection failures get a safe retry state while scoped misses retain a generic not-found response
key-files:
  created:
    - examples/threadline_phoenix/e2e/tests/operator-transaction-evidence.spec.ts
  modified:
    - lib/threadline/change_diff.ex
    - lib/threadline/operator_surface/live/transaction_live.ex
    - lib/threadline/operator_surface/ui/display.ex
    - test/threadline/change_diff_test.exs
    - test/threadline/operator_surface/transaction_live_test.exs
    - test/threadline/operator_surface/ui_test.exs
key-decisions:
  - "Keep scoped denial indistinguishable from a missing transaction so the detail route does not disclose cross-tenant existence."
  - "Preserve an absent after-value as an absent key instead of converting it to null; explicit null remains visible as null."
requirements-completed: [UIS-02, UIS-03, UII-03, UIA-01, UIA-04]
coverage:
  - id: D1
    description: Transaction details keep the linked semantic action separate from the transaction's own row changes, including when one action links to multiple transactions.
    requirement: UIS-02
    verification:
      - kind: integration
        ref: "mix test test/threadline/change_diff_test.exs test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/transaction_live_test.exs (144/144 passed)"
        status: pass
      - kind: e2e
        ref: "mix verify.example_browser --project=desktop-chromium operator-transaction-evidence.spec.ts (1/1 Chromium test and 21/21 runner checks passed; MIX_TEST_PARTITION=tl239_101815; THREADLINE_E2E_PORT=4318)"
        status: pass
    human_judgment: false
  - id: D2
    description: Authorized abbreviated references, row values, and captured times have a keyboard-operable visible disclosure containing complete selectable text; redacted values do not expose a canary in alternate markup or attributes.
    requirement: UIS-03
    verification:
      - kind: integration
        ref: "mix test test/threadline/change_diff_test.exs test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/transaction_live_test.exs (144/144 passed)"
        status: pass
      - kind: e2e
        ref: "operator-transaction-evidence.spec.ts: Chromium Enter-key disclosure assertions for complete Unicode title and timezone-explicit captured time (1/1 passed)"
        status: pass
    human_judgment: false
  - id: D3
    description: Zero, one, and many changes; absent, omitted, null, and redacted field evidence; missing or scoped transactions; and connection failures keep distinct meanings and controls.
    requirement: UII-03
    verification:
      - kind: integration
        ref: "mix test test/threadline/change_diff_test.exs test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/transaction_live_test.exs (144/144 passed)"
        status: pass
      - kind: e2e
        ref: "operator-transaction-evidence.spec.ts: route transaction ID and rendered row identity remain aligned after navigating to a second transaction (1/1 passed)"
        status: pass
    human_judgment: false
duration: 26min
completed: 2026-10-09
status: complete
---

# Phase 239 Plan 03: Transaction Evidence Summary

**Phoenix transaction details now pair each database transaction with its own row changes, expose complete authorized evidence through native disclosure, and distinguish absent data from null or read failure.**

## Performance

- **Duration:** 26 min
- **Started:** 2026-10-09T13:18:46Z
- **Completed:** 2026-10-09T13:44:53Z
- **Tasks:** 3
- **Files modified or created:** 7

## Accomplishments

- Added a mounted browser journey from a filtered Timeline row into a real transaction, keeping action actor and request context distinct from transaction actor and row changes.
- Added native keyboard-operable disclosures for complete authorized values and exact timestamps; redacted tokens do not gain a hidden plaintext or alternate-attribute path.
- Preserved zero/one/many change counts and distinct evidence states, including shared actions across transactions, safe scoped misses, and recoverable database connection failures.
- Fixed the diff builder so a missing after-key stays absent while a stored null remains null.

## Task Commits

1. **Task 1: Read one authorized transaction and its labeled field change** — `2f958d85` (`feat(239-03): compose transaction evidence`)
2. **Task 2: Reveal complete sanctioned values and exact time in visible text** — `bbfb4d0d` (`feat(239-03): disclose complete transaction values`)
3. **Task 3: Preserve zero, partial, denied and failed detail meanings** — `af274a5a` (`fix(239-03): preserve transaction detail states`)

## Files Created/Modified

- `examples/threadline_phoenix/e2e/tests/operator-transaction-evidence.spec.ts` — authenticated transaction navigation, keyboard disclosure, and transaction-to-row identity browser coverage.
- `lib/threadline/operator_surface/live/transaction_live.ex` — separate action context, field-axis labels, complete-value disclosures, and explicit unavailable states.
- `lib/threadline/operator_surface/ui/display.ex` — native disclosure for abbreviated references and long values/times.
- `lib/threadline/change_diff.ex` — preserve absent after-values instead of coercing them to null.
- `test/threadline/operator_surface/transaction_live_test.exs` — transaction actor/context, cardinality, evidence states, safe scope behavior, and failure-state coverage.
- `test/threadline/operator_surface/ui_test.exs` — native disclosure and redaction-canary output/attribute contract.
- `test/threadline/change_diff_test.exs` — absent after-key versus explicit null contract.

## Checks Run

- `mix test test/threadline/change_diff_test.exs test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/transaction_live_test.exs` — 144/144 passed.
- `mix verify.example_browser --project=desktop-chromium operator-transaction-evidence.spec.ts` — 1/1 real Chromium test and 21/21 runner checks passed on a fresh isolated partition and port.
- `mix format --check-formatted` on the changed Elixir files — passed.
- `git diff --check` — passed.
- GSD plan evaluation scope resolved on this branch and found all three task commits.

## Decisions Made

- Scoped denial and a nonexistent transaction share a generic not-found response to preserve tenant privacy; operational connection failures use a separate retryable state.
- An UPDATE after-value is emitted only when its key exists in the captured map, preserving the distinction between absence and explicit null.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserve absent after-values in transaction diffs**
- **Found during:** Task 3
- **Issue:** The diff builder emitted `"after": nil` when the captured after-map lacked the changed field, making absent evidence indistinguishable from a recorded null.
- **Fix:** Emit the after key only when it exists in the captured map and add direct diff and mounted rendering assertions.
- **Files modified:** `lib/threadline/change_diff.ex`, `test/threadline/change_diff_test.exs`, `test/threadline/operator_surface/transaction_live_test.exs`
- **Verification:** Focused four-file ExUnit command passed 144/144.
- **Committed in:** `af274a5a`

**Total deviations:** 1 auto-fixed (Rule 1 bug).
**Impact on plan:** This targeted correction was necessary for the required absent/null evidence distinction; no API, route, schema, dependency, or capture-boundary change was introduced.

## Issues Encountered

- Browser assertions initially used ambiguous or overlapping locators/fixture text. The selectors were scoped to the exact reference element, and the two synthetic slugs were made disjoint. The final Chromium journey passed.
- The browser runner's redundant Chromium installer was bypassed using the existing temporary shim that skips only `playwright install chromium`; the installed Chromium revision 1223 matched pinned Playwright 1.60.0.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 03 is complete; the transaction detail route now has automated ExUnit and mounted browser coverage for composition, disclosure, cardinality, and identity.
- Phase-level zoom acceptance and remaining operator UI refinements stay with their later plans.

## Self-Check: PASSED

- All seven plan-owned created/modified files exist.
- Task commits `2f958d85`, `bbfb4d0d`, and `af274a5a` are ancestors of the current plan head.
- Plan evaluation scope resolved with three commits on this branch.

---
*Phase: investigation-entry-and-transaction-composition*
*Completed: 2026-10-09*

## Verification

- Focused ExUnit: 144/144 passed.
- Mounted browser: 1/1 Chromium test and 21/21 runner checks passed.
- Elixir formatting check and `git diff --check`: passed.
- Plan evaluation scope: 3 task commits resolved.
