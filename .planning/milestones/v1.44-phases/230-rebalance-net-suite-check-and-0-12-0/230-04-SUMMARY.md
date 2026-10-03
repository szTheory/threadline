---
phase: 230-rebalance-net-suite-check-and-0-12-0
plan: "04"
subsystem: release
tags: [landing, squash, release-please, hex-publish, production-hex, suite-time-gate, pins]

requires:
  - phase: 230-rebalance-net-suite-check-and-0-12-0
    provides: "230-02's fixed SUITE-06 gate formula and table; 230-03's dated 0.12.0 CHANGELOG, upgrade-path coverage and green pre-land gate"
provides:
  - "milestone/v1.44 on main as one feat! squash (#73, 67090195) with three BREAKING CHANGE footers, merged only after its own PR CI run passed the SUITE-06 gate"
  - "SUITE-06 verdict PASS from run 37082623361: all lanes cache hit, sum Run tests 507 s <= 930.6 s, per lane 167/179/161 <= 288/291/267"
  - "threadline 0.12.0 published to hex.pm (Release run 37084163662: publish, smoke and distribution sync all success) and GitHub release v0.12.0"
  - "Release PR #74 (79dd190f) and distribution-sync PR #75 (0d6f36f1) merged with --match-head-commit"
  - "latest-lane pins (Elixir 1.20.4, OTP 29.1.1, PostgreSQL 18.6) re-checked against builds.hex.pm and Docker Hub at landing: all current"
affects: [milestone-v1.44-close]

actuals:
  tasks: 3
  commits: 3
  plan_head_before: "5ace2482"
  plan_head_after: "f76a75bd"

tech-stack:
  added: []
  patterns:
    - "Use the landing PR's own pull_request ci.yml run as the fresh pre-landing measurement, then gate the squash merge on it with --match-head-commit set to the measured head"
    - "Job logs for partition reports need `gh api --allow-escape-sequences …/actions/jobs/<id>/logs`; without the flag gh prints an error to stderr and returns an empty body"

key-files:
  created:
    - .planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-04-SUMMARY.md
  modified:
    - .planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-EVIDENCE.md

key-decisions:
  - "Release-please collapsed the three BREAKING CHANGE footers into one generated bullet. It names all three changes, so the orchestrator treated this as a presentation difference and merged the release PR under the grant rather than stopping"
  - "The CHANGELOG.md heading stays dated 2026-10-02 (local date, and the UTC date at the pre-push check). The generated notes say 2026-10-03 because UTC rolled over minutes after the push. Release PR CI was green and no re-date was done"

requirements-completed: [REL-01, SUITE-06]

duration: ~1h (grant to sync PR merge)
completed: 2026-10-03
---

# Phase 230 Plan 04: Land and Release 0.12.0 Summary

**The milestone landed on main as one `feat!:` squash (#73), gated by its own CI run's SUITE-06 PASS. threadline 0.12.0 is live on hex.pm, and the distribution docs are synced.**

## Performance

- **Tasks:** 3/3
- **Grant:** one maintainer grant, in the maintainer's own words, naming all six D-17 actions. The first reply, "yes i authorize u for that", pointed back at the list; the permission check refused the push and nothing ran.

## Accomplishments

- **Preflight (Task 1):**
  - Merge base equals `origin/main` (`fc47af60`).
  - The CHANGELOG is dated.
  - All three latest-lane pins are current.
  - The squash message is validated: `feat!:` subject, three footers, 0 planning IDs.
- **Landing (Task 2):**
  - Pushed `milestone/v1.44` and opened PR #73.
  - Its CI run `37082623361` finished `success` on head `980faa01`.
  - SUITE-06 measurement: every lane is a cache hit, and Σ Run tests is 507 s against the 930.6 s ceiling (SUITE-01: 846 s).
  - Serial-equivalent work is 1668 s, versus 1644 s at 228. Partition reports are present, every partition exited 0, and there were 0 failures.
  - Verdict PASS, then squash-merged with `--match-head-commit` → `67090195`.
- **Release (Task 3):**
  - Release PR #74 was preflighted (version, manifest, dated heading, breaking heading, 0 IDs) and went green, then merged → `79dd190f`.
  - The orchestrator approved `production-hex` under grant item 5.
  - Publish, smoke and distribution sync all succeeded.
  - Sync PR #75 merged → `0d6f36f1`.
  - hex.pm serves 0.12.0 (`latest_stable_version` 0.12.0), and the GitHub release `v0.12.0` exists.

## Task Commits

1. **Task 1: Landing preflight and pin re-check:** `980faa01` (docs)
2. **Task 2: SUITE-06 fresh run and landing:** `6303571b` (docs, local only)
3. **Task 3: 0.12.0 release:** `f76a75bd` (docs, local only)

Remote artifacts: squash `67090195` (#73), release `79dd190f` (#74), sync `0d6f36f1` (#75), tag `v0.12.0`, hex.pm threadline 0.12.0.

## Deviations from Plan

1. **Push denied on the first grant wording.** The maintainer's first reply pointed at the list instead of naming the actions, and the push was refused. A second, own-words grant naming all six actions unblocked every step. No workaround was attempted.
2. **Generated breaking-change notes are one bullet, not three.** Release Please merges one commit's `BREAKING CHANGE:` footers into a single note. All three changes are named in it, and CHANGELOG.md keeps them separate with `Fix:` lines. The plan's "three items" preflight was not met literally. The orchestrator judged this a presentation difference and merged under the grant (recorded in evidence).
3. **Changelog dates differ by one day.** CHANGELOG.md says 2026-10-02 and CHANGELOG-GENERATED.md says 2026-10-03, because UTC rolled over just after the push. No contract test objected.
4. **Search-index lag on one plan check.** The plan's `gh pr list --state merged --search …` check for the sync PR returned 0 right after the merge. `gh pr view 75` shows `MERGED`, and that direct read is cited instead.
5. **Squash trailer updated.** The squash body's Co-Authored-By trailer was changed to the orchestrator's attribution before merging. The footers are unchanged.

## Issues Encountered

None blocking. `gh api …/jobs/<id>/logs` needs `--allow-escape-sequences`. Without it the body comes back empty, which looks like a missing partition report.

## Next Phase Readiness

- Phase 230's work is complete. Phase verification follows.
- Milestone audit and close (`/gsd-audit-milestone`, `/gsd-complete-milestone`) run afterwards (D-14), and no milestone tag was created here.
- The local `milestone/v1.44` branch carries 2 evidence commits (`6303571b`, `f76a75bd`) plus this summary on top of the pushed head. The milestone close carries them to main.

## Self-Check: PASSED

- `git log -1 --format=%s origin/main~2` = the `feat!:` squash with `(#73)`, carrying 3 `BREAKING CHANGE:` footers
- Evidence: SUITE-06 verdict row reads PASS, the fresh-run section exists, no cell is still pending, and the `### Release` section exists
- `gh release view v0.12.0` returns tag `v0.12.0`; hex.pm serves 0.12.0; the release run's publish, smoke and distribution jobs all succeeded
