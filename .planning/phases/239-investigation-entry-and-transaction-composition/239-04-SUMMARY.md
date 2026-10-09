---
phase: 239-investigation-entry-and-transaction-composition
plan: "04"
subsystem: operator-timeline
tags: [phoenix, liveview, timeline, browser, query-state]
requires:
  - phase: 239-01
    provides: accepted investigation entry and browser test setup
provides:
  - Truthful populated-to-pending-to-empty Timeline query identity
  - Separate retryable query error and filtered empty states
  - Apply progress feedback that survives the LiveView request
affects: [operator-timeline, phase-239-plan-05]
actuals:
  tokens: 7602
  tasks: 2
  commits: 7
  plan_head_before: a6a570e032cfac5662ec5490120a77f0364a788e
  plan_head_after: f175ed18a5f60195a8143ed3e11a2d7e4f252bf9
tech-stack:
  added: []
  patterns: [supervised parallel Timeline reads, explicit retryable query-error state]
key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/live/timeline_live.ex
    - lib/threadline/operator_surface/live/timeline_live/filters.ex
    - test/threadline/operator_surface/live/timeline_live_test.exs
    - examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts
key-decisions:
  - "Keep the previous result summary and rows paired while a replacement query is pending; publish the new identity only with its result."
  - "Treat a failed scoped read as a retryable error and retain the canonical applied query, without weakening host scope."
requirements-completed: [UII-02, UIA-04, UIS-02]
coverage:
  - id: D1
    description: Populated query A remains paired with its rows while query B is pending; completion replaces both with B and restores the Apply control.
    requirement: UII-02
    verification:
      - kind: automated_ui
        ref: "examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts#Timeline keeps populated query identity while an applied replacement is pending"
        status: pass
      - kind: integration
        ref: "mix verify.example_browser --project=desktop-chromium operator-route-states.spec.ts"
        status: pass
    human_judgment: false
  - id: D2
    description: Filtered empty results use the specified copy; a populated-to-B read failure clears old rows, leaves B retryable with an unknown count, and a same-scope B retry restores only authorized B rows.
    requirement: UIA-04
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/live/timeline_live_test.exs#F-401: filtered empty state uses the canonical heading and body"
        status: pass
      - kind: unit
        ref: "test/threadline/operator_surface/live/timeline_live_test.exs#query B failure clears A, retry succeeds under the same scope, and host denial stops before mount"
        status: pass
      - kind: integration
        ref: "mix test test/threadline/operator_surface/live/timeline_live_test.exs"
        status: pass
      - kind: automated_ui
        ref: "examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts#real host denial under Acme support is distinct from busy and disabled"
        status: pass
    human_judgment: false
  - id: D3
    description: A 232-character correlation value remains intact through pending and completed empty results, and the populated A-to-B transition retains the full B value.
    requirement: UIS-02
    verification:
      - kind: automated_ui
        ref: "examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts#Timeline delayed query exposes pending then real empty result with a long unbroken filter"
        status: pass
      - kind: automated_ui
        ref: "examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts#Timeline keeps populated query identity while an applied replacement is pending"
        status: pass
    human_judgment: false
duration: 27 min
completed: 2026-10-09
status: complete
---

# Phase 239 Plan 04: Investigation Entry and Transaction Composition Summary

**Timeline keeps populated rows paired with their applied query through pending replacement, then distinguishes filtered empty results from retryable read errors.**

## Performance

- **Duration:** 27 min
- **Started:** 2026-10-09T13:47:13.510Z (durable worker record)
- **Completed:** 2026-10-09T14:15:06Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added a real-browser regression that holds the LiveView request after populated query A, confirms A remains paired with its rows while B is pending, then confirms B's filtered-empty result and restored Apply control.
- Added Apply progress feedback and distinct filtered-empty and retryable query-error states. Failed reads clear stale rows and retain the canonical applied query for retry.
- Added LiveView coverage for filtered-empty copy and the fail-closed scoped-read error state.

## Task Commits

1. **Task 1: Apply B while populated A is held in view, then complete B** — `f4c7e65a` (test)
2. **Task 1: Apply progress feedback** — `d1ae5d29` (feat)
3. **Task 2: Recover accurately from empty, failed and denied queries** — `e945f196` (test)
4. **Task 2: Preserve Timeline query result states** — `b940a131` (feat)
5. **Task 2 correction: Exercise scoped failure, retry, and host denial boundaries** — `42a89560` (test)
6. **Task 2 correction: Make query workers lifecycle-safe and failed counts unknown** — `f175ed18` (fix)

## Files Created/Modified

- `lib/threadline/operator_surface/live/timeline_live.ex` — Keeps query errors separate from empty results; supervised parallel reads return a safe error state without stale rows and preserve the applied query for retry.
- `lib/threadline/operator_surface/live/timeline_live/filters.ex` — Shows “Applying filters…” while the LiveView request is pending.
- `test/threadline/operator_surface/live/timeline_live_test.exs` — Covers canonical filtered-empty copy; populated A to failed B; clearing A rows; same-scope B recovery; cross-tenant exclusion; and pre-mount host denial followed by allowed access.
- `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts` — Holds populated-to-empty replacement requests, validates long query retention, and exercises the actual unauthenticated redirect and Acme support authorization boundary in Chromium.

## Decisions Made

- Pending query B does not relabel query A's still-visible rows; B becomes the displayed identity only after its result arrives.
- Read failures are shown as errors, not empty results. Retry uses the same canonical query and existing server-owned scope.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Use supervised task streaming for query failure isolation and cleanup**
- **Found during:** Task 2
- **Issue:** `Task.async_nolink/1` is unavailable on the project's Elixir 1.17.3 runtime. The first supervised implementation could also leave the first task alive if starting its sibling raised, and reported a failed query as a known count of zero.
- **Fix:** Used `Task.Supervisor.async_stream_nolink/4` with `on_timeout: :kill_task`, wrapped read functions to normalize exceptions and exits, and set the matching count to `Unknown` when the query did not complete.
- **Files modified:** `lib/threadline/operator_surface/live/timeline_live.ex`, `lib/threadline/operator_surface/live/timeline_live/filters.ex`
- **Verification:** The focused LiveView suite passed 58/58, including failure and same-scope recovery.
- **Committed in:** `f175ed18`

**Total deviations:** 1 auto-fixed (1 runtime compatibility and lifecycle issue). **Impact:** Preserved parallel reads, guaranteed timeout cleanup, and avoided presenting an unknown result count as zero, without adding a dependency or changing the public API.

## Issues Encountered

- An initial browser authorization assertion expected the unfiltered Timeline URL; the host correctly canonicalized its date window. The assertion now accepts that canonical query while verifying the route remains Timeline.
- **Authorization boundary:** the host `authorize_fn` denies before LiveView mount and redirects to `/`; it cannot produce an in-view “denied B” state. Once a host scope is authorized, a zero-row result must remain indistinguishable from an empty authorized result to protect cross-tenant record existence. The plan's request for a separate post-mount denied-query message conflicts with this host contract. This plan proves the actual pre-mount denial and later allowed access separately from mounted query failure and same-query recovery; it does not invent a backend denial signal for empty scoped results.
- Browser failure/retry limitation: the existing browser fixture safely holds a delayed query but has no seam for raising an authorized scoped-read exception. The populated A → failed B → same-scope recovery transition is therefore proven by the mounted LiveView test; browser evidence separately proves pending replacement and the real host authorization boundary. No production fault route was added.
- The normal focused browser mode still skips unrelated evidence-only scenarios. The plan-owned pending/empty, long-value, and host-boundary cases were explicitly enabled and observed. The separate 232-character layout/overflow gate remains with Plan 05.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Timeline query identity and error recovery are ready for Plan 05's separate long-value layout and overflow work.
- Existing authorization behavior remains server-owned; the query retry path does not remove or broaden scope.

## Checks Run

- Focused LiveView suite: **58/58 passed** (`mix test test/threadline/operator_surface/live/timeline_live_test.exs`).
- Browser pending/empty and populated A-to-B transitions: **2/2 passed** in the focused Chromium spec; 9 unrelated evidence-only scenarios skipped.
- Browser host authorization boundary: **1/1 passed** in a focused Chromium rerun. It observed the unauthenticated login redirect, Acme support Timeline access, and the actual 403 export authorization denial.
- Browser unit discovery: **21/21 passed** in the runner's required E2E package check.
- Evaluation scope: resolved; 7 plan commits found on this branch, including the prior summary metadata commit.
- Actuals: 30,408 changed-diff bytes / 4 = 7,602 tokens; 2 tasks; 7 measured plan commits.

---
*Phase: 239-investigation-entry-and-transaction-composition*
*Completed: 2026-10-09*

## Self-Check: PASSED

- All four plan-owned source/test files exist and are included in the measured plan commits.
- The six task commits are ancestors of the current branch HEAD.
- No phase tracker or parent-owned planning files are included in this plan summary commit.
