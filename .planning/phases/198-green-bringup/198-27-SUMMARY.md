---
phase: 198-green-bringup
plan: 27
subsystem: testing
tags: [playwright, e2e, ci, green-bringup, uat-specs, phase-135, phase-173, phase-175, phase-177]

requires:
  - phase: 198-green-bringup (plan 198-26)
    provides: the measured 29-row attribution table and cluster assignment for
      the masked Playwright failures, naming cluster 198-27's 12 rows
      (operator-phase-135/173/175/177-uat.spec.ts) as this plan's work list
provides:
  - Cluster 198-27's 12 rows fixed at cause, with red-then-green teeth proof
    for one failure per file
  - A measured lane failure-count delta (18 -> 11) against plan 198-26's
    closing count
  - One new out-of-scope discovery (operator-accessibility.spec.ts:655:3,
    mobile-chromium) logged honestly, not silently absorbed or fixed
affects: [198-28, 198-29]

actuals:
  tokens: 58000
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Prefer role/attribute assertions over pinned copy literals when a
      product's UnsupportedView descriptor changes (operator-phase-135-uat.spec.ts)"
    - "Assert the live WAI-ARIA enumerated value (aria-haspopup=\"menu\") rather
      than a generic boolean-style literal (operator-phase-173-uat.spec.ts)"
    - "Target the innermost real disclosure/toggle element when a landmark
      wrapper is added around it, rather than the outer testid element
      (operator-phase-175-uat.spec.ts)"
    - "Match a CSS ancestor-selector's real DOM relationship in a synthetic
      test simulation instead of toggling the class on the descendant element
      the selector never keys off (operator-phase-177-uat.spec.ts)"
    - "Resolve a story/id list from the live catalog at runtime instead of a
      hard-coded array, using nested test.step for per-item granularity within
      one test() call-site (operator-phase-177-uat.spec.ts)"

key-files:
  created: []
  modified:
    - examples/threadline_phoenix/e2e/tests/operator-phase-135-uat.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-phase-173-uat.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-phase-175-uat.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-phase-177-uat.spec.ts
    - .planning/audits/198-round4-playwright.md
    - .planning/phases/198-green-bringup/deferred-items.md
    - .planning/WINDOWS.md

key-decisions:
  - "All 12 cluster-198-27 rows fixed at cause, never by weakening: 6 were
    genuinely still failing (copy-literal mismatch, ARIA attribute value,
    nav-landmark wrapper, test-simulation ancestor mismatch); the other 6
    were confirmed non-deterministic (login-redirect and stress-preview-mount
    timing) by 198-26 and reconfirmed still passing in this plan's own runs
    with zero code change."
  - "Applied GREEN-07's adjacency/empty/ordering-edge discipline to
    already-passing assertions (sticky topbar, pager empty-edge pair, motion
    thresholds, story loop) per the plan's explicit must_haves, not gated on
    whether they were currently failing."
  - "Resolved the Phase 177 story loop from the live /audit/__stress?category=group
    catalog at runtime rather than a hard-coded array, using nested test.step
    for per-story/per-width granularity inside one test() call-site — the
    file's literal test() call-site count is unchanged (6, before and after)."
  - "Logged one new out-of-scope discovery (operator-accessibility.spec.ts
    focus flake, mobile-chromium only) honestly rather than silently fixing
    or ignoring it — it is not among this plan's declared files_modified."

requirements-completed: [GREEN-07]

coverage:
  - id: D1
    description: "Cluster 198-27's 12 rows (Phase 135/173/175/177 UAT specs)
      fixed at cause with red-then-green teeth proof"
    requirement: "GREEN-07"
    verification:
      - kind: e2e
        ref: "mix verify.example_browser operator-phase-135-uat.spec.ts operator-phase-173-uat.spec.ts operator-phase-175-uat.spec.ts operator-phase-177-uat.spec.ts --project=desktop-chromium --project=mobile-chromium"
        status: pass
    human_judgment: false
  - id: D2
    description: "Lane re-measured unbounded with an integer delta (18 -> 11)
      against plan 198-26's closing count, cluster fully reconciled
      (12 closed + 0 open = 12), and the D-39 ceiling restated in writing"
    requirement: "GREEN-07"
    verification:
      - kind: e2e
        ref: ".planning/audits/198-round4-playwright.md#measured-after-count-198-27 (mix verify.example_browser --project=desktop-chromium --project=mobile-chromium)"
        status: pass
    human_judgment: false
  - id: D3
    description: "New discovery (operator-accessibility.spec.ts:655:3,
      mobile-chromium) logged with a cause-in-progress note and a dated
      deferred-items.md entry, not silently absorbed"
    requirement: "GREEN-07"
    verification: []
    human_judgment: true
    rationale: "Root cause of the new discovery is not established — a human
      or a follow-up plan must judge whether the deferral and its recorded
      symptom description are adequate before diagnosing further."

duration: 95min
completed: 2026-08-28
status: complete
---

# Phase 198 Plan 27: Playwright UAT-spec cluster fix (Phase 135/173/175/177) Summary

**Fixed all 12 cluster-198-27 masked Playwright failures at cause — a retired copy literal, a
wrong ARIA attribute value, a nav-landmark wrapper around a disclosure element, and a
test-simulation CSS-ancestor mismatch — with red-then-green teeth proof, then re-measured the
lane (18 → 11 failures) and honestly logged one new out-of-scope discovery instead of absorbing
or fixing it.**

## Performance

- **Duration:** 95 min
- **Started:** 2026-08-28
- **Completed:** 2026-08-28
- **Tasks:** 3
- **Files modified:** 7 (4 spec files, 1 audit doc, 1 deferred-items doc, 1 defect ledger)

## Accomplishments

- Fixed `operator-phase-135-uat.spec.ts:76:3` ("support user is denied admin-only Coverage"):
  the spec asserted retired literals (`"Unsupported View"` / `"Coverage inspection is not
  available"`); the live product renders `Unsupported.descriptor(:coverage_unavailable)`'s
  `"Coverage unavailable"` / `"Coverage is unavailable in this support lane…"`. Updated the
  spec to the live contract — the access denial itself was never wrong.
- Fixed `operator-phase-173-uat.spec.ts:74:3` ("dropdown: opens and exposes aria-expanded
  state"): the spec asserted `aria-haspopup="true"`; `UI.dropdown` renders the valid,
  never-toggling WAI-ARIA value `aria-haspopup="menu"` for a menu-triggering button. Updated
  the expected value.
- Fixed `operator-phase-175-uat.spec.ts:84:3` ("shell nav is a native `<details>`..."): a
  `<nav data-testid="operator-nav-shell">` landmark now wraps the real
  `.tl-shell-nav__disclosure` `<details>` element (a genuine, intentional accessibility
  improvement, not a regression). Retargeted the tagName/open assertions to the inner element.
- Fixed `operator-phase-177-uat.spec.ts:221:3` ("phx-error reveals the banner..."): the test's
  synthetic simulation toggled `.phx-error` on `.threadline-ui` itself, but the real CSS
  selector (`[data-phx-main].phx-error .threadline-ui .tl-reconnect-banner`) requires the class
  on an ANCESTOR container. Fixed the simulation to toggle the class on the real
  `[data-phx-main]` element.
- Confirmed 6 of the cluster's 12 rows (the `173:88` modal test and the `177:83` stress-preview
  sub-cases) as still non-deterministic (login-redirect and stress-preview-mount timing),
  exactly as plan 198-26 diagnosed — zero code change needed, reconfirmed passing across
  multiple clean runs of this plan's own measurement.
- Applied the plan's GREEN-07 adjacency/empty/ordering-edge discipline to three
  already-passing assertions that were never failing but required explicit threshold/
  precondition/set-based treatment per the plan's `must_haves`: the sticky-topbar clearance
  threshold, the pager empty-edge pair's paired preconditions plus a named empty-state
  affordance, and the Phase 177 motion-duration boundaries.
- Rewrote the Phase 177 UAT #1 story loop to resolve the group-story list at runtime from the
  live `/audit/__stress?category=group` catalog instead of a hard-coded 12-item array — the
  test no longer rots when a story is added, removed, or renamed. Preserved per-story/per-width
  granularity via nested `test.step` inside one `test()` call-site; the file's literal `test(`
  call-site count is unchanged (6, before and after).
- Re-measured the lane unbounded, both projects: **11 failed, 15 skipped, 314 passed (4.8m)**
  — delta **−7** against plan 198-26's closing count of 18. Confirmed zero cluster-198-27 rows
  remain failing (all 40 tests across the four fixed spec files pass on both projects).
- Reconciled all 12 cluster-198-27 rows as `closed` (0 `open`); arithmetic `12 + 0 = 12` stated
  against the cluster's assigned row count.
- Honestly logged one new out-of-scope discovery — `operator-accessibility.spec.ts:655:3`
  ("opens stress rendered widgets..."), mobile-chromium only — as a new, unassigned
  attribution row plus a dated `deferred-items.md` entry and a `WINDOWS.md` ledger entry,
  rather than fixing (out of this plan's declared `files_modified`) or silently absorbing it.
- Stated `seed-sensitive? = no` for all 12 cluster rows (0 provisional pending 198-28's
  post-merge re-validation) and restated the D-39 ceiling in writing: `Tier A capture lane`
  stays red regardless of this cluster's closure.

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix the Phase 135 and Phase 173 UAT specs at their causes** — `e80405d5` (fix)
2. **Task 2: Fix the Phase 175 and Phase 177 UAT specs at their causes** — `34e67e41` (fix)
3. **Task 3: Re-measure the lane and reconcile this cluster against the attribution table** —
   `30a50955` (docs) + `764f10b3` (docs — WINDOWS.md ledger entry for the new discovery)

## Files Created/Modified

- `examples/threadline_phoenix/e2e/tests/operator-phase-135-uat.spec.ts` — coverage-denial copy
  literals updated to the live descriptor contract.
- `examples/threadline_phoenix/e2e/tests/operator-phase-173-uat.spec.ts` — `aria-haspopup`
  expected value corrected to `"menu"`.
- `examples/threadline_phoenix/e2e/tests/operator-phase-175-uat.spec.ts` — shell-nav disclosure
  assertions retargeted to the inner element; sticky-topbar threshold comment; pager empty-edge
  pair preconditions + named empty-state affordance.
- `examples/threadline_phoenix/e2e/tests/operator-phase-177-uat.spec.ts` — phx-error simulation
  retargeted to `[data-phx-main]`; motion-threshold boundary comments; story loop resolved at
  runtime from the live catalog.
- `.planning/audits/198-round4-playwright.md` — cluster 198-27 fixes table, two red-then-green
  teeth-proof sections, measured after-count with delta, cluster reconciliation, new
  attribution row, pre-merge status, and the restated D-39 ceiling.
- `.planning/phases/198-green-bringup/deferred-items.md` — dated entry for the new
  out-of-scope discovery.
- `.planning/WINDOWS.md` — ledger entry for the new discovery.

## Decisions Made

- Fixed every row at cause, never by weakening — no `test.skip`/`.fixme`/`.only`, no deleted
  assertions, no config/workflow/ruleset edits. Verified via the acceptance criteria's grep
  checks after every task.
- Distinguished "genuinely still failing" (6 rows: copy literal, ARIA value, nav wrapper,
  simulation mismatch) from "confirmed non-deterministic, already passing" (6 rows) rather than
  claiming credit for fixing rows that were never actually broken by anything this plan changed.
- Applied the GREEN-07 must_haves discipline (threshold/precondition/set-based assertions) to
  passing tests as instructed by the plan text, not gated on current pass/fail status.
- When the isolated single-test run of the `phx-error` test showed inconsistent per-project
  failure symptoms (a `[data-phx-main]`-ancestor real-environment timing effect visible only
  when running that one test in isolation against a freshly-reset local DB), did not treat the
  isolated anomaly as authoritative — re-ran the full four-file suite twice, cleanly, and used
  that as the basis for the SUMMARY's claims. Documented the isolated red capture as the teeth
  proof's "before" state since it reproduces the same root defect (toggling the wrong element)
  the fix addresses.
- Logged the new `operator-accessibility.spec.ts` discovery rather than fixing it: the file is
  not in this plan's declared `files_modified`, and Rule 1/2 auto-fix authority does not extend
  past the plan's declared scope boundary.

## Deviations from Plan

### Auto-fixed Issues

None beyond the plan's own declared fix scope — all four spec-file changes were directly
instructed by the plan's `<action>` blocks (fix cluster-198-27 rows at cause) and confirmed
against plan 198-26's bonus diagnosis. No Rule 1/2/3 auto-fixes outside the plan's declared
`files_modified` were made.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** None — plan executed as written, including the GREEN-07 must_haves
discipline applied to already-passing assertions.

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, file-access patterns, or schema changes were
introduced. All changes were to test assertions and one CSS-selector-targeting fix inside a
synthetic test harness.

## Issues Encountered

- A local test-DB `search_path` regression appeared mid-execution after running `mix
  ecto.reset` manually to investigate a demo-seed collision (`tickets_organization_id_number_index`
  already-taken error on repeat `mix demo.seed` runs without a full drop). Resolved per this
  project's own documented fix (`ci.yml:374`'s `ALTER DATABASE ... SET search_path TO
  "$user", public, threadline;`) applied to the local `threadline_phoenix_test` database — this
  is the example app's database, not `threadline_test`, so the project's "never restore a
  search_path on `threadline_test`" caution does not apply here.
- One isolated single-test run of the `177:221` phx-error test showed a per-project-inconsistent
  failure mode not reproduced in the full four-file suite; resolved by treating the full clean
  suite run (reproduced twice) as authoritative, per this project's own "measure, don't
  hypothesize" precedent from plan 198-26.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 198-28 has cluster-198-27 fully closed and out of its way — 0 rows carried forward.
- Plan 198-28's own 13-row cluster (`operator-screenshot-regression.spec.ts`,
  `operator-screenshots.spec.ts`) is unaffected by this plan; the after-count baseline for its
  own before-measurement should be re-taken fresh per this plan's own experience of two
  unrelated transient flakes on a first run that cleared on retry — do not assume this plan's
  11-failure figure as a stable pre-measured baseline.
- The new `operator-accessibility.spec.ts:655:3` discovery is unassigned to any cluster and
  needs a follow-up 198 (or successor-phase) gap-closure plan to diagnose.
- GREEN-07 remains not-Complete this round by design (D-39 forbids the Tier A remedy); no claim
  in this plan or its SUMMARY asserts otherwise.

---
*Phase: 198-green-bringup*
*Completed: 2026-08-28*
