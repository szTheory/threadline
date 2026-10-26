---
phase: 246-debt-closeout-and-critic-retirement
plan: 09
subsystem: planning-records
tags: [gap-closure, debt-register, seed-008, screenshot-baselines]
status: complete
requires:
  - "246-VERIFICATION.md gap 2 (partial D-24: :101 route missing at its destination)"
  - "246-08 (shared 246-LANDING.md edits)"
provides:
  - "SEED-008 Scope owning 10 screenshot baselines (:101 x2 added) and a 10-failure threshold"
  - "register row UI-HOME-SHOT-101 (routed, SEED-008), pinned in verify-phase.sh REQUIRED_IDS"
affects:
  - "the reopened operator-UI work (SEED-008 regression threshold)"
tech-stack:
  added: []
  patterns:
    - "new register id pinned in REQUIRED_IDS so dropping the row turns --close red"
key-files:
  created: []
  modified:
    - .planning/seeds/SEED-008-operator-ui-carry.md
    - .planning/phases/246-debt-closeout-and-critic-retirement/246-DEBT-REGISTER.md
    - .planning/phases/246-debt-closeout-and-critic-retirement/tools/verify-phase.sh
    - .planning/phases/246-debt-closeout-and-critic-retirement/deferred-items.md
    - .planning/phases/246-debt-closeout-and-critic-retirement/246-LANDING.md
decisions:
  - "The :101 Home screenshot drift is routed to SEED-008 as register row UI-HOME-SHOT-101; the healthy standalone browser lane is exactly 10 failures (:101/:108/:115/:136/:145 x desktop/mobile), a documented deviation from 246-07's 8, not an override"
requirements: [DEBT-01]
metrics:
  duration: "~5 min"
  completed: 2026-10-25
estimate:
  tokens: 40000
  tasks: 2
actuals:
  tokens: 4000
  tasks: 2
  commits: 1
plan_head_before: 996fd39004ef4968b3d3735b1fd99845293011cf
plan_head_after: cea43407
---

# Phase 246 Plan 09: Route the :101 Home screenshot drift to SEED-008 Summary

The `operator-screenshot-regression.spec.ts:101` Home drift now has a routed register row
(`UI-HOME-SHOT-101`, SEED-008), SEED-008's regression threshold reads the measured 10
failures instead of 8, and the close check pins the new id.

## What changed

- **SEED-008:** Scope bullet retitled "The 10 screenshot-regression baselines.", naming
  :108/:115/:136/:145 plus `:101` ("global chrome and Home workflow launchers stay stable"),
  each on desktop and mobile, with the height evidence (baseline 1281/2013 px, origin/main
  `23178fb0` 1274/2048 px, already failing at `614cb1fd`). "exactly these 10 failures"; any
  other set is a regression. Done-when says "10-failure browser baseline". Frontmatter
  untouched.
- **246-DEBT-REGISTER.md:** row `UI-HOME-SHOT-101` after `UI-REDACTION-COPY`; frontmatter
  routed 24 / total 132 (closed 64, waived 44 unchanged); body count 132 plus a source
  bullet; Verdict SEED-008 bullet names the 10 baselines and the :101 pair. W8/W62 history
  text left alone.
- **verify-phase.sh:** `UI-HOME-SHOT-101` appended to `REQUIRED_IDS`. Nothing else changed.
- **deferred-items.md:** the :101 Disposition cites the register row and SEED-008 Scope,
  states 419 passed / 10 failed / 58 skipped, and records the deviation as evidenced, not an
  override.
- **246-LANDING.md:** the standalone-run sentence cites `UI-HOME-SHOT-101` and SEED-008's
  10-failure threshold. Numbers and 246-08's C7 content untouched.
- **246-07-SUMMARY.md:** read-only. It already records 419 / 10 / 58.

## Verification

- `verify-phase.sh --close` and `--self-test` both print `verify-phase: all checks passed`.
- Mutation on a scratch copy (row removed, counts reset to 23/131) with `REGISTER=` set:
  exit 1, `missing required ids: UI-HOME-SHOT-101`. The live register was never touched and
  still passes.
- All acceptance greps hit their targets. `git diff --stat -- examples/` is empty, so no
  baseline or spec was touched.
- `bin/verify-repo-hygiene` exit 0. No home paths and no username in the edited files.

## Commits

- `cea43407` docs(246-09): route the :101 Home screenshot drift to SEED-008 (the 5 plan paths only, no `Removal-Slice:` trailer)

## Deviations from Plan

- deferred-items.md did not state the 419/10/58 gate before this plan, although the plan's
  truth required it. It was added in the Disposition bullet, inside Task 2's scope.
- Tasks 1 and 2 share one commit, as the plan's Output requires ("one `.planning/` commit").

## Self-Check: PASSED

- All 5 modified files exist; commit `cea43407` is an ancestor of HEAD.
