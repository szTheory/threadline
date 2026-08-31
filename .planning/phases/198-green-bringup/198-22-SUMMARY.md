---
phase: 198-green-bringup
plan: 22
subsystem: ci
tags: [ci, ci-required, merge-gate, measurement, green-04, green-07, gap-closure-round-3]

requires:
  - phase: 198-21
    provides: "CI required self-guarding needs:/ruleset contract tests, confirmed all-keep dispositions (D-39/D-40/D-41) already applied on disk"
provides:
  - "A real, measured, re-queryable CI run (33204829086) on a fresh ci/198-round3 branch, superseding round 2's run 33197493051"
  - "Confirmation that the search_path cause GREEN-04 named in round 2 is genuinely closed (0 undefined_table occurrences), and identification of the new cause (demo-seed content mismatches) now blocking it"
  - "GREEN-04 and GREEN-07 statuses set strictly from the measured run, per D-01's admissibility rule"
affects: [198-VERIFICATION, green-04, green-07, ci-required]

actuals:
  tokens: 6000
  tasks: 3
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Measurement-only draft PR (DO NOT MERGE) as the vehicle for observing a real CI run without intent to merge"
    - "Four-column baseline trajectory table, extending round 2's three-way comparison"

key-files:
  created: []
  modified:
    - .planning/phases/198-green-bringup/198-CI-MEASUREMENT.md
    - .planning/REQUIREMENTS.md

key-decisions:
  - "Pushed a fresh branch (ci/198-round3) rather than reusing ci/198-gap-closure, per the plan's explicit instruction, so this round's evidence cannot be confused with round 2's — verified both branches resolve to distinct SHAs on origin."
  - "Classified the two stray 'relation audit_transactions does not exist' Postgres-server-log lines found in the Run test suite (current) job's container-log dump as non-test-failure noise (coincident with the root suite's own completion timestamp, most likely from the root suite's own negative-path search_path contract tests) rather than silently omitting them or misclassifying them as a test failure — recorded verbatim in the measurement artifact either way."
  - "Did not mark GREEN-04 or GREEN-07 Complete despite the search_path cause being genuinely fixed, because the measured run's Run test suite (current) job still concluded failure for a different reason and CI required still concluded failure with 3/12 needs: red — per D-01, only the run's own conclusion counts, not partial cause-closure."
  - "Left PR #30 open, in draft state, unmerged, per the plan's explicit instruction that this is a measurement vehicle only."

requirements-completed: []

coverage:
  - id: D1
    description: "A real GitHub Actions run exists on fresh branch ci/198-round3 whose head commit contains the 198-19 and 198-21 changes; run id, per-job conclusions, and wall-clock duration recorded on disk"
    requirement: "GREEN-07"
    verification:
      - kind: other
        ref: "gh run view 33204829086 --json status,conclusion,createdAt,updatedAt,attempt,headSha -> completed/failure/80bf701e.../attempt 1; git ls-remote --heads origin ci/198-round3 matches local head"
        status: pass
    human_judgment: false
  - id: D2
    description: "Run test suite (current) conclusion recorded verbatim; search_path cause (round 2) confirmed closed via 0 undefined_table occurrences; new cause (demo-seed content mismatches) identified and cited to D-41"
    requirement: "GREEN-04"
    verification:
      - kind: other
        ref: "gh run view --job 98963106051 --log | grep -c undefined_table == 0; 9 named test failures all Ecto.NoResultsError/assertion-mismatch/ExUnit.TimeoutError, none undefined_table"
        status: pass
    human_judgment: false
  - id: D3
    description: "CI required's conclusion recorded verbatim alongside all 12 needs: member conclusions, so the aggregate's verdict traces to its constituents; zero skipped/cancelled"
    requirement: "GREEN-07"
    verification:
      - kind: other
        ref: "gh run view --job 98966369580 --log alls-green summary: 9 success, 3 failure (verify-test, verify-example-browser, verify-capture), 0 skipped/cancelled"
        status: pass
    human_judgment: false
  - id: D4
    description: "GREEN-04 and GREEN-07 marked in REQUIREMENTS.md strictly per the measured run; wall clock recorded as exact figure and compared to the 20-minute clause"
    requirement: "GREEN-04, GREEN-07"
    verification:
      - kind: other
        ref: "REQUIREMENTS.md both entries cite run 33204829086 as current evidence, cite 33197493051 only as superseded; wall clock 13m29s recorded and compared (<=20min)"
        status: pass
    human_judgment: false

duration: ~40min
completed: 2026-08-28
status: complete
---

# Phase 198 Plan 22: Round-3 CI Measurement Summary

**Pushed a fresh `ci/198-round3` branch, watched one real CI run (`33204829086`) to completion, and recorded it: the search_path cause GREEN-04 named in round 2 is genuinely fixed (0 `undefined_table` occurrences), but `Run test suite (current)` and `CI required` both still concluded `failure` for previously-known, cited causes — GREEN-04 and GREEN-07 stay honestly Pending.**

## Performance

- **Duration:** ~40 min (push+PR ~3 min; CI run wall clock 13m29s watched to completion; log analysis + measurement write-up + REQUIREMENTS.md update ~20 min)
- **Started:** 2026-08-28 (session continuation from 198-21)
- **Completed:** 2026-08-28
- **Tasks:** 3 of 3 completed
- **Files modified:** 2 (`198-CI-MEASUREMENT.md`, `REQUIREMENTS.md`) plus this SUMMARY

## Accomplishments

- **Task 1:** Confirmed working tree clean, head SHA `80bf701e7486962e538d16f213874cbba8f24115` (a merge commit carrying all of 198-01 through 198-21, verified by `git log --oneline --grep` matches for both `198-19` and `198-21` commit messages resolving as ancestors). Pushed to a **fresh** branch `ci/198-round3` (`git ls-remote --heads origin ci/198-round3` confirms the remote SHA matches local head; `ci/198-gap-closure` independently confirmed to still point at round 2's distinct SHA `f748e43d...`). Opened **draft** PR #30 against `main`, explicitly marked "DO NOT MERGE", citing run `33197493051` as what it supersedes. Watched run `33204829086` to completion via `gh run watch --exit-status` (which correctly exited non-zero, reflecting the run's own `failure` conclusion — not a tooling error) plus direct polling. Confirmed `attempt: 1` — no rerun, re-dispatch, or retry of any kind. Only one run exists for this branch/head SHA (`gh run list --branch ci/198-round3` returns exactly one entry) — no ordering ambiguity.
- **Task 2:** Appended a Round 3 section to `198-CI-MEASUREMENT.md`: run id, head SHA, branch, PR number, wall clock (`13m29s`, byte-identical to round 2's own figure), a full 14-check per-job table with start/end timestamps, and a four-column baseline comparison extending round 2's three-way table (baseline → round 1 → round 2 → round 3). Every still-red job (`Run test suite (current)`, `Tier A capture lane`, `Example app browser E2E`) carries a verbatim first-failure excerpt and exactly one classification: `Run test suite (current)` is a **newly discovered cause** (D-41's predicted demo-seed content class, distinct from round 2's now-closed search_path cause); `Tier A capture lane` and `Example app browser E2E` are both **previously known and deferred**, cited to D-39/`198-tier-a-byte-stability.md` and D-40/`deferred-items.md` Plan 198-17 entry respectively. Recorded the `CI required` step's own verbatim `alls-green` job-status summary (all 12 `needs:` members named, 9 `success`/3 `failure`/0 `skipped`/0 `cancelled`), the exact `mergeStateStatus: BLOCKED` for PR #30, and stated the phase goal's headline claim as **false** (not true-subject-to-a-merge — `mergeStateStatus` is `BLOCKED`, not `CLEAN`/`UNSTABLE`).
- **Task 3:** Updated GREEN-04's and GREEN-07's REQUIREMENTS.md prose entries and the status table to cite run `33204829086` as current evidence, retaining `33197493051` only in "supersedes" citations (never as current evidence). Neither requirement was marked Complete. GREEN-04's note distinguishes the now-closed search_path cause from the new demo-seed-content cause with the exact grep-based proof (`grep -c "undefined_table"` returns 0 against the job log). GREEN-07's note states the exact 3-of-12 breakdown by both job `id:` and check `name:`, confirms zero laundering via `skipped`/`cancelled`, and states explicitly that this closure was NOT reached by narrowing `needs:` — per D-39/D-40/D-41 all three red lanes are kept by explicit maintainer choice, so any future genuine closure will be a real green, not a scope reduction.

## Task Commits

1. **Task 2: round-3 measurement artifact** — `4b39cf33` (docs)
2. **Task 3: GREEN-04/GREEN-07 status update** — `8cbf67a4` (docs)

Task 1 made no repository file changes (push + PR creation only, per the plan's own `<files>` spec: "no repository files modified") — no commit for Task 1 itself; its verification (branch existence, head SHA match, run watched to completion) is fully evidenced in Task 2's measurement record and this SUMMARY.

**Plan metadata:** committed alongside this SUMMARY.

## Files Created/Modified

- `.planning/phases/198-green-bringup/198-CI-MEASUREMENT.md` — new "Round 3" section: run `33204829086`, 14-check table, four-column baseline trajectory, three classified still-red causes, wall-clock evaluation, `CI required` conclusion, `mergeStateStatus`.
- `.planning/REQUIREMENTS.md` — GREEN-04 and GREEN-07 prose entries and status table rows updated to cite run `33204829086`, with `33197493051` retained only as superseded history.

## Decisions Made

- **Fresh branch, not reused.** Per the plan's explicit instruction, pushed to `ci/198-round3` rather than `ci/198-gap-closure` (which still backs open PR #29 from round 2). Verified both branches independently resolve to distinct SHAs on `origin` at measurement time.
- **The two stray Postgres-server-log "relation audit_transactions does not exist" lines are recorded but not classified as a test failure.** They appear in the `Run test suite (current)` job's container-log dump (`Stop containers` step) at `19:43:37Z`, coincident with the *root* `mix verify.test` step's own completion (`19:43:42Z`, reporting `1423 tests, 0 failures, 1 excluded`) — not with the later `mix verify.example` step where the 9 named failures occur. None of the 9 named `mix verify.example` failures cite `undefined_table`. Most plausible explanation: the root suite's own negative-path contract tests (e.g. `storage_schema_prefix_contract_test.exs`) intentionally probe unprefixed access to prove it fails. Recorded verbatim per the honesty requirement rather than silently omitted or over-classified.
- **GREEN-04's search_path-vs-demo-seed distinction stated as measured fact, not inference.** `grep -c "undefined_table"` against the job's full log returns exactly `0`; this is offered as the closure proof for the round-2-named cause, distinct from the new cause's own count (9 failures, all a different error class).
- **GREEN-07's note states explicitly that closure did not come from `needs:` narrowing.** Per D-39/D-40/D-41 (all "keep"), the aggregate's guarantee is unchanged from what it has always meant — this is recorded so a future reader does not mistake "still 3 red" for "the gate got weaker" or vice versa.
- **Neither requirement marked Complete**, even though one of GREEN-04's two historically-cited causes is now genuinely fixed. D-01's admissibility rule is binary on the run's own conclusion, not on partial cause-closure — `Run test suite (current)` still concluded `failure`, so GREEN-04 stays Pending, with the fix and the new blocker both stated precisely so the next round does not have to re-diagnose either.

## Deviations from Plan

None — plan executed exactly as written. All three tasks' acceptance criteria were met: the branch is fresh and verified against local head; every job's conclusion (not only failures) is recorded; the wall clock is an exact figure; the `CI required` and `Run test suite (current)`/`Run test suite (min)` conclusions are recorded verbatim; no job was re-run (`attempt: 1`); GREEN-04/GREEN-07 cite the new run id and are not marked Complete; the diff for each task's files matched the plan's stated scope exactly (`git diff --name-only` checked after each task).

## Issues Encountered

None beyond the expected polling/watch mechanics of waiting ~13 minutes for a real CI run to complete — handled via `gh run watch --exit-status` (backgrounded) plus periodic `gh run view` polling, both read-only.

## User Setup Required

None — no external service configuration required. This plan only pushed a branch, opened a draft PR, and updated planning documents.

## What STATE.md should record (orchestrator to apply — worktree carveout per this plan's `<state_md_carveout>`)

- `status`: unchanged phase-in-progress state; this plan does not complete Phase 198 (GREEN-04/GREEN-07 both stay Pending, per D-41's own prediction that a dedicated successor round is still needed).
- `stopped_at`: "Completed 198-22-PLAN.md (round-3 CI measurement)"
- `last_activity`: 2026-08-28
- `last_activity_desc`: "Measured CI run 33204829086 on ci/198-round3 (PR #30, draft): CI required concluded failure (3/12 needs: red: verify-test/Run test suite (current), verify-capture/Tier A capture lane, verify-example-browser/Example app browser E2E). Round-2's search_path cause for Run test suite (current) is confirmed CLOSED (0 undefined_table occurrences); the job is red for a new, previously-masked cause (9 demo-seed content mismatches, predicted by D-41). GREEN-04 and GREEN-07 both remain Pending — see REQUIREMENTS.md and 198-CI-MEASUREMENT.md Round 3 section."
- `## Current Position`: Phase 198 (green-bringup), plan 22 of (at least) 22 complete. Two requirements (GREEN-04, GREEN-07) remain open, both requiring a dedicated successor round per D-40/D-41's already-recorded scope (28 masked Playwright failures across 14 spec files; 9 demo-seed content mismatches across 3 test files) — neither in scope for 198-22, which is measurement-only per its own frontmatter.

## Next Phase Readiness

- **GREEN-04 remains Pending.** The originally-named search_path cause is genuinely closed and measured so. A new, different, already-anticipated cause (demo-seed content mismatches) now blocks it — the same class D-41 already scoped to a dedicated successor round, out of both 198-19's/198-21's and this plan's authority to fix.
- **GREEN-07 remains Pending.** `CI required` concluded `failure` with the same 3-of-12 red count as round 2, for reasons entirely traceable to D-39 (Tier A, unchanged), D-40 (browser E2E, unchanged), and the newly-cited demo-seed cause behind `Run test suite (current)`. No lane was narrowed out of `needs:` to manufacture this result — all three stay required by explicit maintainer choice, so future closure will be genuine, not definitional.
- **Two dedicated successor rounds are still required**, exactly as 198-20/198-21 already recorded: (1) the 28 masked Playwright failures across the named spec files (D-40/B1); (2) the demo-seed content mismatches across the three named test files (D-41/C1, appendix Lane C). Neither was attempted here, consistent with this plan's measurement-only scope.
- PR #30 (`ci/198-round3`, draft) is left open and unmerged, as instructed — it is a measurement artifact, not a merge candidate.
- No blockers for a future round-4 measurement once either successor round lands; `198-CI-MEASUREMENT.md`'s Round 3 section is structured so a re-query of run `33204829086` alone can re-derive every verdict in this SUMMARY.

## Self-Check: PASSED

- `.planning/phases/198-green-bringup/198-CI-MEASUREMENT.md` — FOUND, contains `ci/198-round3` and `mergeStateStatus`
- `.planning/REQUIREMENTS.md` — FOUND, GREEN-04/GREEN-07 cite `33204829086`
- Commit `4b39cf33` (Task 2) — FOUND in `git log --oneline --all`
- Commit `8cbf67a4` (Task 3) — FOUND in `git log --oneline --all`
- Branch `ci/198-round3` — FOUND on origin (`git ls-remote --heads origin ci/198-round3`)
- PR #30 — FOUND, OPEN, draft, `mergeStateStatus: BLOCKED`
- Run `33204829086` — FOUND, `conclusion: failure`, `attempt: 1`, `headSha` matches local head

---
*Phase: 198-green-bringup*
*Completed: 2026-08-28*
