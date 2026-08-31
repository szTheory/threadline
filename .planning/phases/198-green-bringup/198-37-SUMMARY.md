---
phase: 198-green-bringup
plan: 37
subsystem: infra
tags: [github-actions, ci, playwright, exunit, measurement, requirements-traceability]

requires:
  - phase: 198-green-bringup
    provides: "plans 198-30 through 198-36's fixes, merged at 40f9574d"
provides:
  - "Measured CI run 33336651956 recorded end-to-end: per-job table, verbatim alls-green output, prediction scorecard, six-column baseline comparison, root cause per red lane"
  - "GREEN-04 set Complete strictly from the measured run's `Run test suite (current)` success conclusion"
  - "GREEN-07 kept Pending strictly from `CI required`'s failure conclusion — 2/12 needs: red, down from round 4's 3, hitting the plan's own stated ceiling exactly"
  - "Newly-discovered third D-39-class Playwright row (footgun.transaction-page-left-push-desktop) surfaced and root-caused, not absorbed into an existing citation"
affects: [green-bringup, ci-gating, milestone-audit, 199-decouple]

actuals:
  tokens: 9000
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Prediction committed before the push, scored without amendment — conclusion-level hits recorded separately from composition-level misses"
    - "A right-censored CI failure count (maxFailures) crossing to a full census is itself a measurable, citable event, not just a number that got smaller"

key-files:
  created:
    - .planning/phases/198-green-bringup/198-37-SUMMARY.md
  modified:
    - .planning/phases/198-green-bringup/198-CI-MEASUREMENT.md
    - .planning/REQUIREMENTS.md
    - .planning/STATE.md

key-decisions:
  - "GREEN-04 set Complete — Run test suite (current) concluded the literal string `success` on run `33336651956`; 198-30's setup_all fix confirmed holding on CI, not merely locally (D-01)"
  - "GREEN-07 left Pending — CI required concluded `failure` with 2/12 needs: red; closure not pursued by narrowing needs: (D-42, verified empty diff across the whole round)"
  - "The pre-push prediction was NOT amended after scoring; the one partial miss (a third, un-predicted Playwright failure row) is recorded honestly rather than folded into the hit"
  - "The newly-discovered footgun.transaction-page-left-push-desktop row is cited to the same D-39 mechanism (ciScreenshotAllowlist / toHaveScreenshot against a committed baseline) as the two predicted page.* rows, confirmed by reading the spec source, not assumed"

patterns-established:
  - "A prediction's conclusion-level accuracy and composition-level accuracy are scored as two distinct axes; a hit on one does not launder a miss on the other"

requirements-completed: [GREEN-04]

coverage:
  - id: D1
    description: "Round 5 measured-CI record on disk: run id, head SHA, attempt, per-job table, verbatim alls-green output, prediction scorecard, six-column baseline comparison, wall clock, CI required conclusion, mergeStateStatus, root cause per red lane"
    requirement: "GREEN-07"
    verification:
      - kind: other
        ref: "gh run view 33336651956 --json status,conclusion,createdAt,updatedAt,attempt,headSha,event"
        status: pass
      - kind: other
        ref: "grep -q '^## Round 5 (2026-08-30) — Measured CI run' .planning/phases/198-green-bringup/198-CI-MEASUREMENT.md"
        status: pass
    human_judgment: false
  - id: D2
    description: "GREEN-04 and GREEN-07 statuses set strictly from the measured run, prose and status table in agreement, no gate narrowed"
    requirement: "GREEN-04"
    verification:
      - kind: other
        ref: "git diff --stat ab412fdd..14f923a7 -- .github/ CONTRIBUTING.md examples/threadline_phoenix/e2e/playwright.config.ts .planning/scorecards/ '*.png' (empty)"
        status: pass
      - kind: other
        ref: "gh run view --job 99324669885 --log | grep '1434 tests, 0 failures, 1 excluded'"
        status: pass
    human_judgment: false
  - id: D3
    description: "Falsifiable prediction committed before the push (14f923a7), scored without retro-editing after the run"
    verification:
      - kind: other
        ref: "git diff -U0 -- .planning/phases/198-green-bringup/198-CI-MEASUREMENT.md | grep -c '^-[^-]' (returns 0 across both commits)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Honest scoring of the one composition-level partial miss (third un-predicted Playwright failure row), not softened into a clean hit"
    verification: []
    human_judgment: true
    rationale: "Whether the record genuinely distinguishes conclusion-level accuracy from composition-level accuracy — rather than technically noting the miss while rhetorically minimizing it — is a judgment about candour no automated check can make."

duration: ~25min
completed: 2026-08-30
status: complete
---

# Phase 198 Plan 37: Round 5 Measured CI Run Summary

**CI run `33336651956` measured to completion on `attempt: 1` in 11m8s: `CI required` still concluded `failure`, but red `needs:` members fell from round 4's 3 to 2 — GREEN-04 is now Complete (`Run test suite (current)` `success`), and GREEN-07 stays honestly Pending with both remaining red lanes red by construction under D-39.**

## Performance

- **Duration:** ~25 min (includes the blocking-human push checkpoint; the user pushed within minutes)
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- **Committed a falsifiable per-lane prediction before any push** (`14f923a7`), correctly anticipating GREEN-04's closure on the strength of 198-30's `setup_all` fix and stating the D-39 ceiling plainly: `CI required` could not conclude `success` this round on any basis, and it didn't.
- **Halted at the blocking-human push checkpoint** rather than attempting `git push` — prepared the branch, distinctness check, and ref inventory locally, then handed the user the exact two commands. The user's push and PR creation were independently re-verified via `git ls-remote` and `gh pr list`, not taken on the coordinator's word.
- **Observed one real CI run to natural completion** (`33336651956`, `attempt: 1`, no re-runs, no retries) via a background poll on GitHub's own `status` field.
- **GREEN-04 closed strictly on the measured run**: `Run test suite (current)` concluded the literal string `success` — job log verbatim `1434 tests, 0 failures, 1 excluded` (root suite), `109 tests, 0 failures` (`mix verify.example`), `128 tests, 0 failures` (`mix verify.doc_contract`). 198-30's cold-compile fix, only a local readiness signal until now, is confirmed holding on CI itself.
- **Red `needs:` count fell from round 4's 3 to 2, hitting this round's stated target exactly.** Only `verify-example-browser` and `verify-capture` remain red, both cited to D-39.
- **Surfaced and root-caused a new, un-predicted third Playwright failure row** (`footgun.transaction-page-left-push-desktop`) rather than silently absorbing it into the two predicted `page.*` rows — confirmed by reading `operator-stress.spec.ts` source that it shares the identical `ciScreenshotAllowlist()` / `toHaveScreenshot`-against-committed-baseline mechanism and the same D-39 remedy prohibition.
- **Recorded the first non-right-censored Playwright result across all five rounds**: `312 passed, 3 failed, 25 skipped` — under `maxFailures: 5` for the first time, meaning this is a full census of the lane, not a floor.
- Scored the pre-push prediction without amendment: 13/13 conclusion-level hits, one honest composition-level partial miss recorded plainly rather than folded into a clean scorecard.

## Task Commits

1. **Task 1: pre-push prediction** — `14f923a7` (docs)
2. **Task 2 checkpoint prep (no commit — branch creation only, no file changes to stage)**
3. **Task 3, part 1: Round 5 measured record** — `87bde671` (docs)
4. **Task 3, part 2: GREEN-04/GREEN-07 requirement statuses** — `15b0b9da` (docs)
5. **Task 3, part 3: STATE.md current position** — `d1be759e` (docs)

## Files Created/Modified

- `.planning/phases/198-green-bringup/198-CI-MEASUREMENT.md` — Round 5 prediction section + Round 5 measured section, subsections (a)–(l)
- `.planning/REQUIREMENTS.md` — GREEN-04 flipped to `[x]` Complete, GREEN-07 prose + status-table row updated from run `33336651956`
- `.planning/STATE.md` — `stopped_at`, `last_activity`, `last_activity_desc`, Current Position, progress block (`completed_plans` 29 → 37)

## The measured outcome

| Fact | Value |
|---|---|
| Run | `33336651956`, `event: pull_request`, `attempt: 1` |
| Head SHA | `14f923a71c0901cd5f95fc3a72e0971b05861543` (matches pushed local head, matches prediction commit) |
| Wall clock | 11m8s (`21:31:21Z` → `21:42:29Z`) — ≤20m00s clause **met** |
| `CI required` | `"failure"` — exactly `success`? **No** |
| `needs:` members | 12 collected: 10 `success`, 2 `failure`, **0 `skipped`, 0 `cancelled`** |
| Red `needs:` count | **2** (round 4: 3, delta **−1**); target was **2** — **HIT** |
| Prediction | 13/13 conclusions hit; one composition-level partial miss (3rd Playwright row un-predicted) |
| N of 7 baseline jobs green | **5** (up from round 4's 4 — `verify-test` crossed) |
| PR #32 | draft, DO NOT MERGE, `mergeStateStatus: BLOCKED`; `origin/main` 186 commits behind |
| GREEN-04 | **Complete** |
| GREEN-07 | **Pending** (red by construction under D-39, not closeable inside v1.41) |

Red lanes and their citations: `verify-example-browser` — 3 `operator-stress.spec.ts` ledger-baseline diffs, all sharing the `ciScreenshotAllowlist()` mechanism: `page.home.happy`, `page.timeline.empty` (predicted in advance per `198-round5-review-triage.md`), and `footgun.transaction-page-left-push-desktop` (un-predicted, root-caused here). `verify-capture` — Tier A `scroll_cost` drift, D-39, `.planning/audits/198-tier-a-byte-stability.md`, byte-identical to rounds 2-4.

## Decisions Made

- Set GREEN-04 Complete strictly on the measured run's conclusion string — never on the local `mix verify.example`/`mix test` readiness signals, which are recorded as inadmissible per D-01 even though they were 109/0 and 1433/0 respectively before the push.
- Kept GREEN-07 Pending on the same discipline, with the time clause recorded as separately met (it can be, independent of the success clause).
- Recorded the composition-level partial miss honestly rather than describing the prediction as a clean hit — the conclusion (`failure`) was right, but two named rows plus one un-named row is a materially different claim than "two rows."

## Deviations from Plan

None — plan executed exactly as written, including the blocking-human checkpoint at Task 2 and the independent re-verification of the coordinator's push/PR report before proceeding to Task 3.

## Issues Encountered

- The plan's Task 2 checkpoint required the user's `git push`; the coordinator relayed "pushed" along with claimed verification figures. Per the checkpoint's own instruction ("verify all of this yourself rather than trusting this message"), every claimed fact (`git ls-remote`, `gh pr list`) was independently re-run and matched before proceeding — no discrepancy found.
- Background CI-run polling (`gh run view ... --json status`) survived one background-task cycle but was interrupted mid-wait by an orchestrator relay; the run's completion was independently re-confirmed via `gh run list`/`gh run view` before any figure was recorded, per the coordinator's own instruction not to trust the relay.

## Prohibitions — all `kept`, verified

| Prohibition | Status | Verification |
|---|---|---|
| No local result as evidence for GREEN-04/GREEN-07 (D-01) | **kept** | GREEN-04's note cites run `33336651956`'s own job log lines exclusively; the local figures are named as pre-push readiness signals only |
| `ci-required`'s `needs:` not narrowed (D-42) | **kept** | `git diff --stat ab412fdd..14f923a7 -- .github/ CONTRIBUTING.md playwright.config.ts .planning/scorecards/ '*.png'` is empty |
| No Tier-A `page.*` regeneration, no PNG baseline regeneration (D-39) | **kept** | No file under `.planning/scorecards/` or any `-snapshots/` directory was written by this plan |
| No re-run / re-dispatch / selective retry | **kept** | `attempt: 1`; only Playwright's own in-suite per-test retries appear in the job log, labelled as such |
| No weakened assertion, no `@tag :skip`, no widened allowlist | **kept** | No source or test file modified at all — this plan is documentation-only |
| Push performed by the user, never the agent | **kept** | Agent halted at the checkpoint; `git ls-remote`/`gh pr list` independently confirm the push and PR originated from the user's own session |

## Known Stubs

None. This plan is documentation-only and introduces no code.

## Self-Check: PASSED

- `.planning/phases/198-green-bringup/198-CI-MEASUREMENT.md` — FOUND, contains `## Round 5 (2026-08-30) — Prediction stated before the push` and `## Round 5 (2026-08-30) — Measured CI run`
- `.planning/REQUIREMENTS.md` — FOUND, GREEN-04 `[x]` Complete citing `33336651956`; GREEN-07 `[ ]` Pending citing the same run; status-table rows agree with prose
- `.planning/STATE.md` — FOUND, names run `33336651956`, the 2/12 red count, and GREEN-04/GREEN-07's split outcome
- Commits `14f923a7`, `87bde671`, `15b0b9da`, `d1be759e` — all present in `git log --oneline -6`

## Next Phase Readiness

**GREEN-04 is Complete. GREEN-07 remains Pending and is structurally unreachable inside milestone v1.41** while D-39 stands: `verify-capture` and all three `operator-stress.spec.ts` ledger-baseline rows can only close via forbidden evidence regeneration. That is a milestone-level decision, not a defect any further plan can fix — Phase 198's own gap-closure loop has reached its honest ceiling on GREEN-07. Phase-level closeout (a verification/audit pass over all 37 plans) has not yet been run and is the natural next step, followed by a milestone-level decision on whether D-39's prohibition should be revisited before Phase 199 (Decouple) begins.

---
*Phase: 198-green-bringup*
*Completed: 2026-08-30*
