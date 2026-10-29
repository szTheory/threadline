---
phase: 246-debt-closeout-and-critic-retirement
plan: 07
subsystem: planning-ledgers, e2e-tests, landing
status: complete
tags: [debt, windows, phase-gate, landing, archive-tag, critic-retirement]
requires: [246-06]
provides:
  - WINDOWS ledger at open_count 0 (fixed 27, waived 40, total 67)
  - D-24 gate evidence (ci.all exit 0; standalone browser 419/10/58)
  - Removal-Slice C6 (test focus-race fix found by the gate)
  - 246-LANDING.md hand-off (squash PR, tag message, ARCHIVE-REGISTER row, D-14 checks)
affects: [phase-247, v1.47-landing, SEED-008]
tech-stack:
  added: []
  patterns: [CLI-only WINDOWS writes, content-based landing readiness check, per-slice path union]
key-files:
  created:
    - .planning/phases/246-debt-closeout-and-critic-retirement/246-LANDING.md
    - .planning/phases/246-debt-closeout-and-critic-retirement/deferred-items.md
  modified:
    - .planning/WINDOWS.md
    - examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts
decisions:
  - "Added Removal-Slice C6 (8eb54275): C4's ledger prune exposed a focus race in operator-accessibility.spec.ts:1281; the fix waits for the drawer's [data-tl-initial-focus] and must land with C4 in the removal squash"
  - "The standalone browser baseline is 10 failures, not 8: operator-screenshot-regression.spec.ts:101 x2 already fails on origin/main 23178fb0 and before the slices; it is routed to SEED-008, and no baseline was regenerated"
  - "The landing readiness path set is the per-slice file union (527 paths), not a first^..last range diff, because 246-05 test commits sit between C5 and C6"
metrics:
  duration: ~75 min
  completed: 2026-10-25
estimate:
  tokens: 85000
  tasks: 3
actuals:
  tokens: 30000
  tasks: 3
  commits: 4
plan_head_before: 80a21633249d8499d1c9bbab64a69546452bce13
plan_head_after: 72c46f0c1b552b95c24bb8f2d32c9463e91afc54
---

# Phase 246 Plan 07: Debt close-out, phase gate and landing hand-off Summary

All 60 open WINDOWS rows were resolved through the gsd-tools CLI, leaving `open_count: 0`.
The D-24 gate passed on an ephemeral postgres:16: `CI=true mix ci.all` exited 0 after a new
C6 slice fixed a focus race that C4 exposed. `246-LANDING.md` gives the maintainer a
ready-to-copy recipe for the removal squash PR and the `archive/ui-critic-loop` tag.

## Tasks

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Tracer: resolve 60 WINDOWS rows through the CLI | `602e358f` | .planning/WINDOWS.md (alone) |
| 2 | D-24 phase gate | `8eb54275` (C6 fix), `5c63652f` (evidence) | operator-accessibility.spec.ts; 246-LANDING.md; deferred-items.md |
| 3 | Landing hand-off | `72c46f0c` | 246-LANDING.md |

**Task 1.** The tracer call `windows fixed 1` was checked first: `open_count` went to 59 and
the table re-rendered. The remaining 59 rows were then written one call at a time, in
ascending id order:
- 21 register-`closed` rows: `fixed`
- 33 `waived` rows: `waive "<register reason> (246-DEBT-REGISTER.md#W<id>)"`
- 6 `routed` rows (W7 to v1.48; W14–17 and W62 to SEED-008): `waive "routed to … per 246-DEBT-REGISTER.md#W<id>"`

A JSON diff against HEAD showed that only the 60 previously open entries changed, and only
in `status`, `reason` and `resolved_at`. The file has 78 `246-DEBT-REGISTER.md#W` citations
(≥ 39 required). The CLI did not touch STATE.md.

**Task 2.** Final run:
- `ci.all` exit 0: library 3328 tests / 0 failures; example app 132 / 0; Dialyzer 0 errors;
  CI browser lane 415 passed + 3 flaky / 0 failed / 56 skipped.
- Standalone `verify.example_browser`: 419 / 10 / 58.
- `verify-phase.sh --close`: `verify-phase: all checks passed`.
- `bin/verify-repo-hygiene`: exit 0.
- No gate-db container remains.

**Task 3.** `246-LANDING.md` contains:
- `### Prerequisites`, with the readiness check run read-only against the local origin/main
  `23178fb0`. It exits 1, **not yet satisfied**, as expected: 10 paths differ, all of them
  244/245 edits.
- The ordered C1..C6 SHAs, each checked to touch no `.planning/` path.
- The cherry-pick recipe.
- The D-31-shape tag message. Its only placeholders are `<removal-squash-sha>` and
  `<parent-sha>`. The fallback restore list is 25 pathspecs covering all 479 deleted files,
  plus the mix.exs hunks to restore by hand.
- The ARCHIVE-REGISTER row text and the Rows 11 → 12 edit, both to apply at landing.
- The D-14 evidence commands and the `git grep` output.
- The maintainer line `! git push origin refs/tags/archive/ui-critic-loop`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Focus race in operator-accessibility.spec.ts:1281 exposed by C4 (Removal-Slice C6)**
- **Found during:** Task 2. Gate run 1 had `ci.all` red with this test failed on desktop.
  The standalone run also failed it.
- **Investigation:**
  - It failed 3 of 3 at HEAD and passed at `614cb1fd` (before the slices).
  - Bisect: C3b `1258c014` passed; C4 `35243789` and C5 `61f58954` failed.
  - The trace showed the drawer's asynchronous `JS.focus` chain taking focus back to
    `[data-tl-initial-focus]` after `toastClose.focus()`.
- **Fix:** the test now waits for the drawer's initial focus before focusing the toast. It
  passed 10 of 10 with `--repeat-each=5` on desktop and mobile. Committed as `chore:` with
  trailer `Removal-Slice: C6`, touching no `.planning/` path.
- **Files modified:** examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts
- **Commit:** `8eb54275`

**2. [Plan correction] Landing path set and the "exactly 8" browser failures**
- **Path set.** The plan's `git diff --name-only <first-slice>^ <last-slice>` stops being the
  slice union once C6 exists, because the 246-05 `test:` commits sit between C5 and C6. The
  landing doc derives paths from the per-slice union instead (527 paths), and the fallback
  test list adds the C6 spec.
- **Browser failures.** The plan expects exactly the 8 known screenshot failures. The
  measured standalone set is 10: `operator-screenshot-regression.spec.ts:101` also fails on
  desktop and mobile. It fails the same way at `614cb1fd` and on origin/main `23178fb0`, so it
  pre-dates phase 246. It was logged in `deferred-items.md` and routed to SEED-008, the owner
  of the screenshot baselines. Baselines were not regenerated.
- **Where to look:** the failure set itself is in `246-LANDING.md` `## Gate evidence`.
- **Note:** the plan's `git ls-remote --tags …` landing check is written as the equivalent
  `git ls-remote origin refs/tags/archive/ui-critic-loop`. This keeps the doc free of a bare
  `--tags` flag, per the Task 3 verify.

## Deferred Issues

- `:101` Home screenshot drift: see `deferred-items.md`; routed to SEED-008.
- `operator-motion.spec.ts:246` (desktop and mobile) and `operator-accessibility.spec.ts:1332`
  were flaky (passed on retry) in the final `ci.all` run. They were recorded in the gate
  evidence and not investigated further.

## Known Stubs

None.

## Threat Flags

None. No new network, auth or file-access surface. The tag push stays a maintainer-only
explicit-refspec step (T-246-18).

## Self-Check: PASSED

- FOUND: .planning/WINDOWS.md (`open_count: 0`), 246-LANDING.md, deferred-items.md
- FOUND commits: 602e358f, 8eb54275, 5c63652f, 72c46f0c (all ancestors of HEAD)
- `verify-phase.sh --close`: all checks passed; no `archive/*ui-critic*` tag exists;
  ARCHIVE-REGISTER.md unchanged since 872ee30f.
