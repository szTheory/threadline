---
phase: 198-green-bringup
plan: 26
subsystem: testing
tags: [playwright, e2e, ci, green-bringup, attribution, register, operator-find-mobile]

requires:
  - phase: 198-green-bringup (plan 198-17)
    provides: the discovery that the browser lane's CI-reported 5 failures were a
      maxFailures:5 truncation masking 28 real failures, logged in deferred-items.md
      and WINDOWS.md entry #8
provides:
  - A measured, on-disk attribution table for all 29 masked Playwright failures
    (spec/line/project/verbatim message/cause/seed-sensitive), superseding the
    unattributed 28-figure carried in deferred-items.md
  - Cluster assignment for plans 198-27 (12 rows) and 198-28 (13 rows) — a real work
    list, not a guess
  - register.spec.ts and operator-find-mobile.spec.ts fixed at cause with red-then-green
    proof
  - A measured lane failure-count delta (29 -> 18) with an honest accounting of which
    4 rows this plan fixed vs. which 7 disappeared as confirmed non-determinism
affects: [198-27, 198-28, 198-29]

actuals:
  tokens: 42000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Scope ambiguous text/role assertions to a specific container instead of
      widening or deleting them (register.spec.ts, .rd-signed-in)"
    - "Click open a collapsed native <details> row before asserting its body content
      is visible (operator-find-mobile.spec.ts)"

key-files:
  created:
    - .planning/audits/198-round4-playwright.md
  modified:
    - examples/threadline_phoenix/e2e/tests/register.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts

key-decisions:
  - "Measured before fixing: the starting hypothesis (5 failing tests in
    operator-find-mobile.spec.ts) was measured and found wrong — only 1 of its 5
    tests was actually failing (coverage mobile), closing 2 rows not 10."
  - "Documented 7 non-deterministic rows (login-redirect and stress-preview-mount
    timing flakes) honestly rather than claiming credit for their disappearance
    between the before- and after-run, since no code change in this plan touched
    their files."
  - "Union size came out to 29, not the 28 recorded in deferred-items.md; explained
    as consistent with the same measured non-determinism rather than assumed away."

requirements-completed: [GREEN-07]

coverage:
  - id: D1
    description: "Full attribution table for all 29 masked Playwright failures, with
      verbatim messages, named causes, seed-sensitivity, and cluster assignment"
    requirement: "GREEN-07"
    verification:
      - kind: other
        ref: ".planning/audits/198-round4-playwright.md#full-failure-attribution (produced from a real unbounded local run, /tmp/198-26-before.log)"
        status: pass
    human_judgment: false
  - id: D2
    description: "register.spec.ts fixed at cause (scoped signed-in assertion to
      home hero) with red-then-green proof"
    requirement: "GREEN-07"
    verification:
      - kind: e2e
        ref: "mix verify.example_browser register.spec.ts --project=desktop-chromium --project=mobile-chromium"
        status: pass
    human_judgment: false
  - id: D3
    description: "operator-find-mobile.spec.ts fixed at cause (expand collapsed
      <details> before asserting remediation command) with red-then-green proof"
    requirement: "GREEN-07"
    verification:
      - kind: e2e
        ref: "mix verify.example_browser operator-find-mobile.spec.ts --project=desktop-chromium --project=mobile-chromium"
        status: pass
    human_judgment: false
  - id: D4
    description: "Lane re-measured with an integer delta (29 -> 18) and the GREEN-07
      ceiling (Tier A lane forbidden under D-39) stated explicitly in writing"
    requirement: "GREEN-07"
    verification:
      - kind: e2e
        ref: ".planning/audits/198-round4-playwright.md#measured-after-count-198-26 (mix verify.example_browser --project=desktop-chromium --project=mobile-chromium, /tmp/198-26-after.log)"
        status: pass
    human_judgment: false

duration: 62min
completed: 2026-08-28
status: complete
---

# Phase 198 Plan 26: Playwright masked-failure attribution + cluster 1 fix Summary

**Measured all 29 masked Playwright failures (not the previously-assumed 28), fixed 4
of them at cause (register.spec.ts's nav-identity collision, operator-find-mobile's
collapsed remediation `<details>`), and documented 7 more as confirmed
non-deterministic rather than silently crediting their disappearance.**

## Performance

- **Duration:** 62 min
- **Tasks:** 3
- **Files modified:** 3 (1 created, 2 modified)

## Accomplishments

- Ran `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium`
  unbounded before any spec edit: **29 failed, 15 skipped, 318 passed (10.9m)**.
- Produced a full attribution table (29 rows) in
  `.planning/audits/198-round4-playwright.md`: spec file, line, test title, project,
  verbatim message, named cause, shares-cause-with, and seed-sensitive verdict for
  every row.
- Discovered, through direct measurement, that the operator-find-mobile.spec.ts
  cluster's starting hypothesis (5 failing tests) was wrong — only 1 test
  (`coverage mobile shows Add capture remediation without horizontal overflow`) was
  actually failing, in both projects (2 rows, not 10).
- Fixed `register.spec.ts` at cause: a global topbar "Signed in as" identity badge
  (added by commit `917e3320`) now coexists with the home hero's own "Signed in as"
  badge, so the unscoped `getByText("Signed in as")` hit Playwright's strict mode.
  Scoped the assertion to `.rd-signed-in` (the hero's own container) rather than
  widening or deleting it.
- Fixed `operator-find-mobile.spec.ts` at cause: the coverage page's remediation
  command (added by commit `b9f8fc15`) now lives inside a native `<details>` that
  renders collapsed by default. Added a click to expand it before asserting the
  command text is visible.
- Re-measured the lane unbounded after both fixes: **18 failed, 15 skipped, 329
  passed (5.6m)** — delta **−11**. Attributed the delta honestly: 4 rows are this
  plan's fixes; 7 rows (login-redirect and stress-preview-mount timing symptoms)
  disappeared with zero relevant code change and are documented as confirmed
  non-determinism, not credited as fixes.
- Assigned every row to exactly one of clusters `198-26` (4, fixed here), `198-27`
  (12), `198-28` (13) — the assigned count equals the 29-row union.
- Flagged 7 rows as `seed-sensitive? = yes` (dependent on `mix demo.seed` content that
  same-wave sibling plan 198-24 is rewriting in an isolated worktree), naming them as
  the work order for plan 198-28's post-merge re-validation gate.
- Diagnosed, as a bonus (not required, but evidence-backed), several out-of-cluster
  causes for plans 198-27/198-28 to consume directly rather than re-diagnose: a
  retired "Unsupported View" / "Coverage inspection is not available" literal
  (`operator-phase-135-uat.spec.ts`), a wrong `aria-haspopup` expected value
  (`operator-phase-173-uat.spec.ts`), a `<details>`-vs-`<nav>` structural mismatch
  (`operator-phase-175-uat.spec.ts`), a `phx-error` class-toggle test-simulation
  defect (`operator-phase-177-uat.spec.ts`), and a duplicate-heading collision on the
  Exports page (`operator-screenshot-regression.spec.ts`).
- Stated the GREEN-07 ceiling explicitly and in writing: this plan cannot make
  `CI required` conclude `success` because the Tier A capture lane's sole remedy is
  forbidden this milestone under D-39.

## Task Commits

Each task was committed atomically:

1. **Task 1: Attribute all 28(29) masked failures to named causes, before changing
   any spec** — `376e032a` (docs)
2. **Task 2: Fix register.spec.ts at its cause, with a red-then-green teeth proof** —
   `0cca236b` (fix)
3. **Task 3: Fix the operator-find-mobile cluster at its cause and re-measure the
   lane** — `ff28601f` (fix)

## Files Created/Modified

- `.planning/audits/198-round4-playwright.md` - full 29-row attribution table,
  cluster assignment, pre-merge status, both red-then-green teeth proofs, measured
  after-count with delta, and the written D-39 ceiling statement.
- `examples/threadline_phoenix/e2e/tests/register.spec.ts` - scoped signed-in
  assertion to `.rd-signed-in`.
- `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts` - click to
  expand the collapsed `<details>` before asserting the remediation command.

## Decisions Made

- Measured before hypothesizing: the plan's own `read_first` hypothesis of "5 failing
  tests in operator-find-mobile.spec.ts" was tested against a real unbounded run and
  found to overcount by 4x (1 test actually failing, not 5). Acted on the
  measurement, not the hypothesis.
- Treated the 7 rows that disappeared between the before- and after-run without any
  relevant code change as non-deterministic and documented them as such, rather than
  silently folding them into this plan's claimed fix count. This mirrors the
  project's own established practice (see `198-round4-demo-seed.md`'s treatment of a
  non-deterministic timeout) and protects plans 198-27/198-28 from inheriting a false
  "already fixed" assumption.
- Diagnosed several out-of-cluster causes opportunistically (while reading the log for
  my own cluster's evidence) and recorded them in the audit file for plans 198-27/28
  to consume directly, since the plan's own text requires every row to carry a named
  mechanism, never "unknown."

## Deviations from Plan

None — plan executed exactly as written. The one place reality diverged from the
plan's own stated hypothesis (5 failing operator-find-mobile.spec.ts tests, actually
1) is not a deviation from the plan's instructions — the plan explicitly frames its
`read_first` hypothesis as "the starting hypothesis, not the answer," and instructs
measuring before acting. That is exactly what happened.

## Issues Encountered

None beyond the non-determinism documented above, which is a discovery this plan is
required to record honestly, not a problem that blocked its own two fixes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plans 198-27 and 198-28 have a real, measured work list
  (`.planning/audits/198-round4-playwright.md`'s `## Cluster assignment`) instead of a
  guess, including bonus diagnosis for several of their rows.
- Plan 198-28 has an explicit work order (7 `seed-sensitive? = yes` rows) for its
  post-merge re-validation gate once same-wave sibling plan 198-24 merges.
- Plans 198-27/198-28 are told explicitly, in the audit file, not to treat this
  plan's after-count (18) as a stable pre-measured baseline — re-run the unbounded
  command themselves, since 7 rows are confirmed non-deterministic and may recur,
  vanish again, or shift sub-case.
- GREEN-07 remains not-Complete this round by design (D-39 forbids the Tier A
  remedy); no claim in this plan or its SUMMARY asserts otherwise.

---
*Phase: 198-green-bringup*
*Completed: 2026-08-28*

## Self-Check: PASSED

- `test -f examples/threadline_phoenix/e2e/tests/register.spec.ts` -> FOUND
- `test -f examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts` -> FOUND
- `test -f .planning/audits/198-round4-playwright.md` -> FOUND
- `test -f .planning/phases/198-green-bringup/198-26-SUMMARY.md` -> FOUND
- Commits `376e032a`, `0cca236b`, `ff28601f` all present in `git log --oneline --all`
- All three tasks' `<verify>` commands re-confirmed passing at write time (see teeth
  proofs and after-count in `.planning/audits/198-round4-playwright.md`)
