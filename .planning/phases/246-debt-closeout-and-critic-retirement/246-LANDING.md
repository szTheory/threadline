---
phase: 246-debt-closeout-and-critic-retirement
artifact: 246-LANDING.md
milestone: v1.47
requirements: [DEBT-01, DEBT-02]
generated: 2026-10-25
---

# Phase 246 · Landing hand-off

This is the maintainer's copy-paste guide for two steps: landing the critic-removal squash PR
and creating and pushing the `archive/ui-critic-loop` tag. No executor in this phase created
or pushed a tag, pushed a branch or opened a PR (D-13). `.planning/ARCHIVE-REGISTER.md` is
unchanged; its row is applied at landing.

## Gate evidence

The D-24 phase gate ran on 2026-10-25 against the final code tree (HEAD `8eb54275`, after
C6). It used an ephemeral `postgres:16` with label `dev.threadline.kind=gate-db`, a random
loopback port and trap removal; the 245-05 recipe is in `<scratch>/gate-246.sh`. Logs were
ANSI-stripped before grepping. Hex reported 2.6.0, so no `mix local.hex` was needed.

| gate step | command | result |
|-----------|---------|--------|
| WINDOWS ledger | `node <home>/.claude/gsd-core/bin/gsd-tools.cjs windows fixed/waive …` (60 calls, commit `602e358f`) | `open_count: 0`; fixed 27, waived 40, total 67 |
| full CI aggregate | `DB_HOST=127.0.0.1 DB_PORT=<port> CI=true mix ci.all` | **exit 0** on run 2 (run 1 was red; see below) |
| standalone browser lane | `DB_HOST=127.0.0.1 DB_PORT=<port> mix verify.example_browser` | **419 passed / 10 failed / 58 skipped** (exit 1, as expected for this lane) |
| D-15 close check (incl. the D-09 grep) | `bash .planning/phases/246-debt-closeout-and-critic-retirement/tools/verify-phase.sh --close` | `verify-phase: all checks passed` |
| repo hygiene | `bin/verify-repo-hygiene` | exit 0 |
| container cleanup | `docker ps -a --filter label=dev.threadline.kind=gate-db -q \| wc -l` | 0 |

**`CI=true mix ci.all`, run 2 (decisive lines):**

```
5565 mods/funs, found no issues.
verify-deps-audit: 3 lockfile(s) audit clean (Hex 2.6.0; 0 non-blocking finding(s))
32 properties, 3328 tests, 0 failures, 3 excluded        (library)
132 tests, 0 failures                                    (example app)
Total errors: 0, Skipped: 0, Unnecessary Skips: 0        (Dialyzer)
17 tests, 0 failures, 16 excluded
  3 flaky
  56 skipped
  415 passed (6.0m)                                      (CI browser lane, 0 failed)
```

The three flaky tests passed on retry:
- `operator-accessibility.spec.ts:1332`, desktop
- `operator-motion.spec.ts:246`, desktop
- `operator-motion.spec.ts:246`, mobile

RESEARCH predicted the CI lane at 418/0/56. The measured 415 passed + 3 flaky = 418 tests
that ran, with 56 skipped, which matches.

**Run 1 was red, and that is how C6 came about.** Run 1 of `ci.all` failed in the browser
lane with 1 failed, 1 flaky, 56 skipped and 416 passed. The failure was
`operator-accessibility.spec.ts:1281` on desktop ("closes the focused menu before its drawer
and recovers from removed or disabled controls"). The toast close button never took focus.
Investigation:
- **Targeted reruns.** The failure reproduced 3 of 3 times at HEAD. It passed at `614cb1fd`,
  the tree before the slices.
- **Bisect.** `1258c014` (C3b) passed; `35243789` (C4) and `61f58954` (C5) failed.
- **Cause.** C4 pruned the stress ledger. That changed the stress page's timing, so the
  drawer's asynchronous `JS.focus` chain landed on `[data-tl-initial-focus]` after the test
  had already called `toastClose.focus()`.
- **Fix.** Commit `8eb54275`
  (`chore: wait for drawer initial focus before focusing the stress toast`, trailer
  `Removal-Slice: C6`) waits for the drawer's initial focus first. It passed 10 of 10
  (`--repeat-each=5`, desktop and mobile).
- **What changed.** The fix touches only the test. No product code, no screenshot baseline and
  no guard changed.

**Standalone `mix verify.example_browser`, run 2:** 419 passed / 10 failed / 58 skipped. The
failures:

| spec | line | desktop-chromium | mobile-chromium |
|------|------|------------------|-----------------|
| `operator-screenshot-regression.spec.ts` | :108 | failed | failed |
| `operator-screenshot-regression.spec.ts` | :115 | failed | failed |
| `operator-screenshot-regression.spec.ts` | :136 | failed | failed |
| `operator-screenshot-regression.spec.ts` | :145 | failed | failed |
| `operator-screenshot-regression.spec.ts` | :101 ("global chrome and Home workflow launchers") | failed | failed |

The first four rows are the 8 known failures (:108/:115/:136/:145 on desktop and mobile).
The two `:101` failures are **not caused by this phase**:
- They also fail on `614cb1fd`, the tree before the slices.
- They also fail on `origin/main` `23178fb0`. There the full-page Home screenshot is 1274 px
  high against the committed 1281 px desktop baseline, and 2048 px against 2013 px on mobile.
- At HEAD the page is 1407 px and 2412 px.
- RESEARCH assumed `:101` passes, but no v1.46/v1.47 artifact had recorded a standalone run.

The real standalone baseline is therefore **10 failures** on this machine: the four known
pairs plus `:101` × 2. Baselines were not regenerated. The `:101` drift is logged in
`deferred-items.md` for SEED-008, where screenshot baselines are owned. A failure outside
these 10 is a regression. RESEARCH predicted about 421/8/58 standalone; the measured result
is 419/10/58.

D-25 scope held: no partition re-weighting, per-spec timing, browser-project split,
contract-lane tagging, time-to-red or CI wall-time measurement was done (Phase 247).
D-26 scope held: no branch-protection or ruleset change was made.

