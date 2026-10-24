---
id: SEED-007
status: absorbed (v1.47)
planted: 2026-10-24
planted_during: 1.1.0 release (post-v1.46, no active milestone)
scope: small
related: SEED-006
---

# SEED-007: Auto-refresh a stale release PR; re-check the browser E2E critical path

## Why

Releasing 1.1.0 on 2026-10-23 took hours. CI was not the bottleneck. The release
PR went stale:

- release-please did not regenerate release PR #86 after the `docs(release):`
  CHANGELOG-dating PR #87 merged (a `docs:` commit doesn't change the release
  contents). #86 stayed 1 commit behind main, still showing red checks from
  its old head, until `gh pr update-branch 86 --rebase` was run by hand.
- The same manual step appeared in the 0.11.2 release (223-05), where
  release-please did regenerate. The behaviour is inconsistent, so it is a
  recurring trap.

## Measured CI (2026-10-23)

- ci.yml wall time is about 12–15 min per run (PR run 40037029114, main run
  40038808527).
- Critical path: "Example app browser E2E (2 projects)", 11–13 min, of which
  the Playwright suite step itself is 630 s. Setup and caches take seconds.
- Every other job takes 5 min or less, inside the browser job's window.
- 630 s is past the about-550 s Browser E2E bound cited in SEED-006's
  `reopen_when` (run 36455432448). The suite grew during v1.46. That condition
  was written for a *new lane*; decide whether suite growth also re-opens
  SEED-006.

## Candidate work (ranked)

1. **Release PR auto-refresh (cheap, highest value).** In `release.yml`, after
   Release Please on a push to main, if an open release PR exists and is
   behind main, run `gh pr update-branch <n> --rebase` with a token that
   triggers CI. Contract-test it like the other release.yml jobs (pinned
   permissions, no persisted credentials).
2. **Browser E2E shard 2 ways (judgment call).** About -5 min wall per run for
   about +1 job of runner minutes, plus updates to the partition contract.
   v1.43 deliberately traded wall time for billed minutes, so this needs a
   SEED-006-style measured gate, not a reflex.
3. Profile the slowest Playwright specs before sharding. The 630 s may be
   dominated by a few spec files or fixed waits.

## Not this

- Do not drop or path-filter required browser coverage (SEED-006 measured 0 of 28
  PRs as inert).
