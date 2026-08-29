---
phase: 198-green-bringup
plan: 29
subsystem: infra
tags: [github-actions, ci, playwright, exunit, measurement, requirements-traceability]

requires:
  - phase: 198-green-bringup
    provides: "plans 198-23/24/25 demo-seed fixes and 198-26/27/28 Playwright fixes, merged at f433ef3e"
provides:
  - "Measured CI run 33253587315 recorded end-to-end: per-job table, verbatim alls-green output, prediction scorecard, five-column baseline comparison, root cause per red lane"
  - "GREEN-04 and GREEN-07 verdicts set strictly from measured CI conclusion strings (both Pending)"
  - "Root-caused, previously-invisible CI-only defect: demo_reset_test.exs:56 60s ExUnit timeout — the sole blocker between the current state and GREEN-04"
  - "Two falsified predictions recorded as misses without retro-editing the prediction"
affects: [198-round5, green-bringup, ci-gating, milestone-audit]

actuals:
  tokens: 15000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Right-censored CI failure counts (maxFailures) must be read as floors, not censuses"
    - "Local-vs-CI disagreement recorded side by side with provenance, never resolved by recency"

key-files:
  created:
    - .planning/phases/198-green-bringup/198-29-SUMMARY.md
  modified:
    - .planning/phases/198-green-bringup/198-CI-MEASUREMENT.md
    - .planning/phases/198-green-bringup/deferred-items.md
    - .planning/REQUIREMENTS.md
    - .planning/STATE.md
    - .planning/WINDOWS.md

key-decisions:
  - "GREEN-04 left Pending — Run test suite (current) concluded `failure`, not the literal string `success` (D-01)"
  - "GREEN-07 left Pending — CI required concluded `failure` with 3/12 needs: red; closure not pursued by narrowing needs: (D-42)"
  - "The pre-push prediction was NOT amended after scoring; both falsified predictions (target 3→1, prediction of 2) recorded as misses"
  - "Tier A drift NOT characterised beyond the workflow-truncated diff — 183 of 198 drifted files are unobserved and no claim is made about them"
  - "operator-responsive-mobile-first.spec.ts:577 root cause deliberately NOT guessed — diagnosis needs source outside this plan's documentation-only files_modified"

patterns-established:
  - "Censored-metric discipline: a CI failure count capped by maxFailures is a floor; compare composition, not the capped integer"
  - "Truncation honesty: when a CI step pipes a diff through `head -200`, record only what the log shows and state the unobserved remainder"

requirements-completed: []

coverage:
  - id: D1
    description: "Round 4 measured-CI record on disk: run id, head SHA, attempt, per-job table, verbatim alls-green output, prediction scorecard, five-column baseline comparison, wall clock, CI required conclusion, mergeStateStatus, root cause per red lane"
    requirement: "GREEN-07"
    verification:
      - kind: other
        ref: "gh run view 33253587315 --json status,conclusion,createdAt,updatedAt,attempt,headSha,event"
        status: pass
      - kind: other
        ref: "grep -q '^## Round 4 (2026-08-29)' .planning/phases/198-green-bringup/198-CI-MEASUREMENT.md"
        status: pass
    human_judgment: false
  - id: D2
    description: "GREEN-04 and GREEN-07 statuses set strictly from the measured run, prose and status table in agreement, no gate narrowed"
    requirement: "GREEN-04"
    verification:
      - kind: other
        ref: "git diff f18ed150 --name-only (only .planning/ documentation files changed; .github/, CONTRIBUTING.md, playwright.config.ts untouched)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Honest verdict that this round MISSED its stated target (red needs: 3→1) and FALSIFIED its own pre-push prediction (2), recorded without softening or retro-editing"
    verification: []
    human_judgment: true
    rationale: "Whether the record is genuinely unsoftened — rather than technically accurate but rhetorically hedged — is a judgment about candour that no automated check can make."

duration: 25min
completed: 2026-08-29
status: complete
---

# Phase 198 Plan 29: Round 4 Measured CI Run Summary

**CI run `33253587315` measured to completion on `attempt: 1` in 8m11s: `CI required` concluded `failure` with 3 of 12 `needs:` members red — the same count as round 3, missing the stated target of 1 and falsifying the pre-push prediction of 2 — with GREEN-04 and GREEN-07 both left honestly Pending and every red lane root-caused.**

## Performance

- **Duration:** ~25 min
- **Tasks:** 3 (Task 1's push+observe steps were performed by the orchestrator; this agent recorded the measurement and executed Tasks 2 and 3)
- **Files modified:** 5

## Accomplishments

- Recorded `## Round 4 (2026-08-29) — Measured CI run` in `198-CI-MEASUREMENT.md` with all eleven required subsections (a)–(k), plus the push record, three resolved `ci/198-*` ref SHAs, run-selection uniqueness, and PR #31's `isDraft`/`mergeStateStatus`.
- **Root-caused the `verify-test` failure from the job log rather than inheriting a narrative:** `ThreadlinePhoenix.DemoResetTest` at `demo_reset_test.exs:56` times out after 60 000 ms at line 69, where `System.cmd("mix", ["demo.reset"], env: [{"MIX_ENV", "prod"}])` must cold-compile the example app and its deps under `MIX_ENV=prod` before reaching the `DEMO_ALLOW_RESET` guard it asserts on, with no `@tag timeout:` budget. A CI-only test-harness defect — not a demo-seed defect, not a product defect — and the **sole** blocker between the current state and GREEN-04.
- **Proved plans 198-23/24/25 and 198-26/27/28 held, on CI:** the demo-seed content-mismatch class is gone (`109 tests, 1 failure`, and the 1 is the timeout); all five of round 3's failing Playwright tests pass by name; 198-28's two CI-contributing rows pass (`✓ 117`, `✓ 118`).
- **Two falsified predictions recorded as misses, with the pre-push prediction left byte-unchanged.** The plan's target (3→1) and the committed prediction (2) both lost to a measured 3.
- Set GREEN-04 and GREEN-07 from conclusion strings alone; reconciled the REQUIREMENTS status table with the prose; updated STATE.md's position and `last_activity_desc`.
- Seeded `deferred-items.md` and `WINDOWS.md` with the two new defects, both flagged as round-5 candidates.

## Task Commits

1. **Task 1 (finish) + Task 2 record: Round 4 measured record** — `9eb012b7` (docs)
2. **Task 2 remainder: deferred-items + WINDOWS ledger** — `e7764b03` (docs)
3. **Task 3: GREEN-04/GREEN-07 + STATE** — `b607d228` (docs)

## Files Created/Modified

- `.planning/phases/198-green-bringup/198-CI-MEASUREMENT.md` — Round 4 measured section, subsections (a)–(k)
- `.planning/phases/198-green-bringup/deferred-items.md` — dated Plan 198-29 entry, one block per still-red lane
- `.planning/REQUIREMENTS.md` — GREEN-04 and GREEN-07 prose + status-table rows, set from run `33253587315`
- `.planning/STATE.md` — `stopped_at`, `last_activity`, `last_activity_desc`, Current Position
- `.planning/WINDOWS.md` — two new `open` deviation entries

## The measured outcome

| Fact | Value |
|---|---|
| Run | `33253587315`, `event: pull_request`, `attempt: 1` |
| Head SHA | `f433ef3ea6fdc0667bb042addfa5a18eeb7f59e6` (matches pushed local head) |
| Wall clock | 8m11s (`12:52:18Z` → `13:00:29Z`) — ≤20m00s clause **met** |
| `CI required` | `"failure"` — exactly `success`? **No** |
| `needs:` members | 12 collected: 9 `success`, 3 `failure`, **0 `skipped`, 0 `cancelled`** |
| Red `needs:` count | **3** (round 3: 3, delta **0**); target was **1** — **MISSED** |
| Prediction | 11/12 members hit; red-count predicted **2**, actual **3** — **FALSIFIED** |
| N of 7 baseline jobs green | 4 (unchanged from round 3) |
| PR #31 | draft, DO NOT MERGE, `mergeStateStatus: BLOCKED`; `origin/main` 137 commits behind |

Red lanes and their citations: `verify-test` (new CI-only timeout defect, `demo_reset_test.exs:56`), `verify-example-browser` (2 rows = `Expired`→`Export expired` regex rot per the 198-28 deferred entry; 2 rows = `page.*` ledger baselines, D-39; 1 row un-inventoried and undiagnosed), `verify-capture` (D-39, `.planning/audits/198-tier-a-byte-stability.md`).

## Decisions Made

- **Did not amend the pre-push prediction.** A prediction edited after its scoring is not a prediction; the falsified rows are scored in place instead.
- **Did not characterise the Tier A drift beyond the log.** 198 scorecard files drifted (120 `page.*`, 78 `refute.*`); the workflow truncates its diff at `head -200`, so only 15 files are observed. The record explicitly declines to claim the drift is confined to `scroll_cost` or to `page.*`.
- **Did not guess `operator-responsive-mobile-first.spec.ts:577`'s cause.** Diagnosis requires component source outside this plan's documentation-only `files_modified`.

## Deviations from Plan

### Corrections to the briefing, made from primary evidence

**1. [Rule 1 — Bug] The Playwright "5 vs 5, delta 0" comparison is not a valid comparison**
- **Found during:** Task 2 (root-causing `verify-example-browser`)
- **Issue:** The briefing framed round 4's `5 failed` against round 3's `5 failed` as "delta 0 — surface that bluntly." The job log records `Testing stopped early after 5 maximum allowed failures.`, and `examples/threadline_phoenix/e2e/playwright.config.ts:141` sets `maxFailures: process.env.CI ? 5 : 0`. **Both counts are the cap.** Reporting "delta 0" unqualified would have asserted "no progress" when the measured evidence says otherwise: `188 did not run`, all five of round 3's failing tests now pass by name, and 198-28's two CI-contributing rows pass. Publishing an unqualified delta would have understated real, measured progress — a dishonesty in the opposite direction from the usual one.
- **Fix:** Recorded the count as right-censored, cited the config line, compared composition instead, and named the five now-passing round-3 tests with their verbatim `✓` lines.
- **Files modified:** `198-CI-MEASUREMENT.md`, `deferred-items.md`

**2. [Rule 1 — Bug] Tier A drift is NOT confined to `page.*`**
- **Found during:** Task 2
- **Issue:** The briefing described the drift as "confined to `scroll_cost` in `.planning/scorecards/page.*.json`". The step's own `git status --porcelain` output lists **198** modified scorecards — 120 `page.*` and **78 `refute.*`** — and the diff is truncated at 200 lines, so only 15 files' contents are observable.
- **Fix:** Recorded 198/120/78, stated the truncation explicitly, and refused to characterise the 183 unobserved files. The D-39 verdict is unchanged (the lane is red by construction either way).
- **Files modified:** `198-CI-MEASUREMENT.md`, `deferred-items.md`

**3. [Rule 2 — Missing critical] Two of the five Playwright failures already had an established root cause the briefing did not use**
- **Found during:** Task 2, reading `deferred-items.md`'s Plan 198-28 entry
- **Issue:** The briefing asked me to cross-check the three non-screenshot failures against the audit and report whether the audit predicted them closed. It did not — but the 198-28 deferred entry already carries a **corrected** diagnosis for two of them: `fix(198-25)` changed the label from `"Expired"` to `"Export expired"` (lowercase `expired`), breaking both specs' capital-`E` `/Expired|File unavailable/` regex. This supersedes the earlier `demo/seed/exports.ex` hypothesis.
- **Fix:** Cited the corrected cause rather than re-deriving a weaker one, and confirmed both rows were logged `unassigned`, i.e. never believed closed — so they are **not** a prediction miss.
- **Files modified:** `198-CI-MEASUREMENT.md`

**4. [Rule 2 — Missing critical] Recorded a methodological miss the briefing did not anticipate**
- **Found during:** Task 2
- **Issue:** Only 2 of the 5 CI failures appear anywhere in `198-round4-playwright.md`. The audit's inventory was built from **unbounded local** runs (`process.env.CI` unset, `maxFailures: 0`) — a different, non-nested population from a capped CI run.
- **Fix:** Recorded as a named methodological finding for round 5, so the next round does not repeat the substitution.
- **Files modified:** `198-CI-MEASUREMENT.md`, `deferred-items.md`

**5. [Rule 2 — Missing critical] Pre-empted a false "no retry" claim**
- **Found during:** Task 2
- **Issue:** The job log contains `(retry #1)` lines for each failing spec. `attempt: 1` is nonetheless correct — those are Playwright's configured per-test retries inside a single job execution, not workflow re-runs.
- **Fix:** Stated both facts in subsection (k) so a later reader cannot read the `(retry #1)` lines as a contradiction of the re-run discipline.
- **Files modified:** `198-CI-MEASUREMENT.md`

---

**Total deviations:** 5 (2 corrections to briefed facts, 3 additions required for an honest record). **Impact:** none narrows a gate, weakens an assertion, or changes a verdict. Corrections 1 and 2 make the record *less* flattering in one direction (Tier A drift is wider than briefed) and *more* accurate in the other (the browser lane made real progress the capped count hides).

## Issues Encountered

- The plan's Task 1 `<verify>` block runs `gh run list --branch ci/198-round4` and a `grep` — both pass. No blocking issues.
- No package install, no dependency change, no source or test file touched. `git diff f18ed150 --name-only` returns only `.planning/` documentation files.

## Prohibitions — all `kept`, verified

| Prohibition | Status | Verification |
|---|---|---|
| No local result as evidence for GREEN-04/GREEN-07 (D-01) | **kept** | Both notes cite run `33253587315`'s conclusion strings; the local 109/0 is recorded explicitly as inadmissible |
| `ci-required`'s `needs:` not narrowed (D-42) | **kept** | `git diff` on `ci.yml`, `rulesets/main.json`, `CONTRIBUTING.md`, `playwright.config.ts` is empty vs the base; `.github/` untouched |
| No Tier-A `page.*` regeneration, no PNG baseline regeneration (D-39) | **kept** | No file under `.planning/scorecards/` or any `-snapshots/` directory written |
| No re-run / re-dispatch / selective retry | **kept** | `attempt: 1`; only Playwright's in-suite per-test retries appear, and are labelled as such |
| No weakened assertion, no `@tag :skip`, no widened allowlist | **kept** | No source or test file modified at all |

## Known Stubs

None. This plan is documentation-only and introduces no code.

## Self-Check: PASSED

- `.planning/phases/198-green-bringup/198-CI-MEASUREMENT.md` — FOUND, contains `## Round 4 (2026-08-29) — Measured CI run`
- `.planning/phases/198-green-bringup/deferred-items.md` — FOUND, contains `## Plan 198-29`
- `.planning/REQUIREMENTS.md` — FOUND, GREEN-04/GREEN-07 cite `33253587315`, table rows agree
- `.planning/STATE.md` — FOUND, names the run id and the red `needs:` count
- Commits `9eb012b7`, `e7764b03`, `b607d228` — all present in `git log`

## Next Phase Readiness

**GREEN-04 and GREEN-07 both remain Pending. A round 5 is required.** Its shortest honest path:

1. **`demo_reset_test.exs:56`** — the *sole* blocker for GREEN-04. Fix at cause with a `@tag timeout:` sized for a cold prod compile, or pre-warm `_build/prod` in the job. Never `@tag :skip`, never delete the prod-guard assertion.
2. **`Expired` → `Export expired` regex rot** in `operator-accessibility.spec.ts:565` and `operator-prove-mobile.spec.ts:38` (cause already established, owner already recorded).
3. **`operator-responsive-mobile-first.spec.ts:577`** — diagnose from source; no cause established.
4. **GREEN-07 remains structurally unreachable this milestone** while D-39 stands: `verify-capture` and two `operator-stress.spec.ts` `page.*` ledger rows can only be closed by regenerating forbidden evidence. That is a milestone-level decision, not a defect a plan can fix.

---
*Phase: 198-green-bringup*
*Completed: 2026-08-29*
