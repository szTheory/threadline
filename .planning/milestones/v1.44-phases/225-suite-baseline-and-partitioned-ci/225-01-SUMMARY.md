---
phase: 225-suite-baseline-and-partitioned-ci
plan: 01
subsystem: testing
tags: [ci, github-actions, elixir, mix-test, citation-check, baseline]

requires:
  - phase: 224-capture-and-bench-fixes
    provides: "dd780e68 milestone-base local timing figures and run 36730596489 job-level evidence, cited by this plan"
provides:
  - "225-BASELINE.md: cited SUITE-01 baseline (CI Run tests step seconds + billed-minute proxy for run 36730596489, local slowest-modules/slowest-tests rankings, three mix test timing runs, D-03 partition-count confirmation, historical cross-checks)"
  - "tools/check-citations.py + fixtures/: phase-local citation gate widened to phases 214-230"
  - "tools/ci-job-timing.py: the one script (single mode + --compare + --self-test) that will grade both the before and after SUITE-02 figures, so the formula cannot drift"
affects: [225-02, 225-03, 225-04]

actuals:
  tokens: 9018
  tasks: 2
  commits: 1

tech-stack:
  added: []
  patterns:
    - "Phase-local tools/ directory (not bin/) for measurement scripts, matching the 192/219/222 precedent"
    - "Citation-checked baseline doc: every figure line cites `run NNNNNNNN` or a backticked command"

key-files:
  created:
    - .planning/phases/225-suite-baseline-and-partitioned-ci/225-BASELINE.md
    - .planning/phases/225-suite-baseline-and-partitioned-ci/tools/check-citations.py
    - .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py
    - .planning/phases/225-suite-baseline-and-partitioned-ci/tools/fixtures/cited.md
    - .planning/phases/225-suite-baseline-and-partitioned-ci/tools/fixtures/uncited.md
  modified: []

key-decisions:
  - "Squashed the tracer-task commit into Task 2's single commit (git reset --soft) to satisfy the plan's explicit instruction that the five baseline paths land in exactly one `docs(225): record the suite-time baseline` commit, rather than leaving two commits from the per-task default protocol."
  - "ci-job-timing.py's --cache-state fetch needed `gh api ... logs --allow-escape-sequences` (not plain `gh api ... logs`, which gh refuses on terminal-escape content) — added after the first cache-state run returned `unknown` for all three lanes."
  - "D-03 confirmed N=3 by measurement: median run Finished-in total T=137.0s, slowest module M=28.8s (Threadline.PlaywrightFailFastContractTest), T/3=45.7s >= M, so N=3 is confirmed rather than needing a smaller N."

requirements-completed: [SUITE-01]

coverage:
  - id: D1
    description: "225-BASELINE.md records the CI before figures (Run tests step seconds min/current/latest and the billed-minute proxy) for run 36730596489, cited and passing the citation gate"
    requirement: SUITE-01
    verification:
      - kind: unit
        ref: "python3 tools/ci-job-timing.py 36730596489 (288/291/267 s, proxy 20)"
        status: pass
      - kind: unit
        ref: "python3 tools/check-citations.py 225-BASELINE.md"
        status: pass
    human_judgment: false
  - id: D2
    description: "ci-job-timing.py's --compare mode is the single before/after formula (inclusive 30%/10% thresholds, integer arithmetic, INSUFFICIENT with <2 after runs), self-tested offline"
    requirement: SUITE-01
    verification:
      - kind: unit
        ref: "python3 tools/ci-job-timing.py --self-test (7/7 ok)"
        status: pass
    human_judgment: false
  - id: D3
    description: "check-citations.py is the 222 checker copied byte-identical except the phase-exempt regex widened to 214-230; its own self-test and the check on 225-BASELINE.md both exit 0"
    requirement: SUITE-01
    verification:
      - kind: unit
        ref: "python3 tools/check-citations.py --self-test"
        status: pass
    human_judgment: false
  - id: D4
    description: "Local detail at 225's starting HEAD (slowest-modules, slowest-tests, three timing runs, D-03 N-confirmation) and historical cross-checks, all cited, with no suite code change under lib/test/config/bin/.github/mix.exs"
    requirement: SUITE-01
    verification:
      - kind: unit
        ref: "git diff --quiet caabf12c -- lib test config mix.exs bin .github"
        status: pass
      - kind: unit
        ref: "bin/verify-repo-hygiene"
        status: pass
    human_judgment: false

duration: ~45min
completed: 2026-09-30
status: complete
---

# Phase 225 Plan 01: Suite-time baseline (SUITE-01) Summary

**Cited SUITE-01 baseline: CI `Run tests` step 288/291/267 s and proxy 20 for run 36730596489, local slowest-modules/tests rankings, three `mix test` timing runs, and D-03's N=3 confirmation — all gated by a widened copy of the 222 citation checker.**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-09-30T21:19Z (approx)
- **Completed:** 2026-09-30
- **Tasks:** 2
- **Files modified:** 5 created

## Accomplishments
- `tools/check-citations.py` + `fixtures/` copied byte-identical from the 222 phase's tools directory except the phase-exempt regex widened from `21[4-9]|22[0-2]` to `21[4-9]|22[0-9]|230` (three fragments) and the docstring usage paths.
- `tools/ci-job-timing.py`: the single script that computes the `Run tests` step duration, the billed-runner-minutes proxy, and the `--compare`/`--self-test` verdict logic, so the before and after SUITE-02 figures can never drift onto different formulas. Verified live against run 36730596489: `Run tests` seconds 288 (min) / 291 (current) / 267 (latest), proxy total 20.
- `225-BASELINE.md`: cites the CI before figures, the local slowest-modules (10) and slowest-tests (50) rankings, three plain `mix test` timing runs with the median marked (run 3, 137.0 s, 16.9s async/120.1s sync), the D-03 partition check (`T/3 = 45.7s >= M = 28.8s`, so `N = 3 confirmed by measurement`), and historical cross-checks (Flake Detection run 36359135268, dd780e68 local figures cited from 224-EVIDENCE.md).

## Task Commits

Both tasks landed in one commit per the plan's explicit instruction (see Deviations):

1. **docs(225): record the suite-time baseline** — `75dcd5a1` (docs) — all five paths: `225-BASELINE.md`, `tools/check-citations.py`, `tools/fixtures/cited.md`, `tools/fixtures/uncited.md`, `tools/ci-job-timing.py`.

**Plan metadata:** (pending, this commit)

## Files Created/Modified
- `.planning/phases/225-suite-baseline-and-partitioned-ci/225-BASELINE.md` — the cited SUITE-01 baseline doc (CI before, local detail, historical cross-checks)
- `.planning/phases/225-suite-baseline-and-partitioned-ci/tools/check-citations.py` — citation gate, copied from 222, regex widened to 214-230
- `.planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py` — the single before/after CI timing/proxy/verdict script
- `.planning/phases/225-suite-baseline-and-partitioned-ci/tools/fixtures/cited.md` — citation-checker fixture (byte-identical to 222's)
- `.planning/phases/225-suite-baseline-and-partitioned-ci/tools/fixtures/uncited.md` — citation-checker fixture (byte-identical to 222's)

## Decisions Made
- Squashed the Task 1 tracer commit into Task 2's single commit via `git reset --soft`, because the plan's Task 2 `<action>` explicitly names all five paths for one `docs(225): record the suite-time baseline` commit, and the `git log -1 --name-only` acceptance criterion requires exactly those five paths in the latest commit. No push had happened, so the squash is local-only and safe.
- `--cache-state` needed `gh api ... logs --allow-escape-sequences`; without it `gh` refuses the escape-sequence-bearing log stream and the script silently reported `unknown` for every lane. Added the flag once the live run surfaced this.
- D-03: N=3 confirmed by measurement (median run T=137.0s, slowest module M=28.8s, T/3=45.7s >= M).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `gh api ... logs` needed `--allow-escape-sequences`**
- **Found during:** Task 1, `--cache-state` verification
- **Issue:** `gh api repos/.../actions/jobs/<id>/logs` without `--allow-escape-sequences` returns a non-zero exit ("the response contains terminal escape sequences; pass --allow-escape-sequences to output it anyway"), so the cache-state column silently showed `unknown` for every lane instead of the real hit/miss state.
- **Fix:** Added `--allow-escape-sequences` to the `gh api` call in `fetch_cache_state`.
- **Files modified:** `tools/ci-job-timing.py`
- **Verification:** Re-ran `ci-job-timing.py 36730596489 --cache-state`; all three lanes now report `hit`.
- **Committed in:** `75dcd5a1` (single plan commit)

**2. [Rule 3 - Blocking] Per-line citation requirement on markdown tables**
- **Found during:** Task 1 and Task 2, writing `225-BASELINE.md`
- **Issue:** `check-citations.py` evaluates each physical line independently; a wrapped prose paragraph or a markdown table row with digits but no citation *on that line* fails, even when an adjacent line cites the run. Backtick citations must also start with one of the checker's allowed command prefixes (`gh|mix|MIX_ENV=|git|python3|bash|jq|psql|elixir`) — a backtick starting with `/usr/bin/time -p mix test` does not match.
- **Fix:** Rewrote the doc so every digit-bearing line either ends in its own `run NNNNNNNN` citation or a backtick starting with an allowed prefix (e.g. `` `mix test` `` with the timing wrapper moved outside the backtick), and added a `Source` column citing `run 36730596489` on every CI-figures table row.
- **Files modified:** `225-BASELINE.md`
- **Verification:** `python3 tools/check-citations.py 225-BASELINE.md` exits 0.
- **Committed in:** `75dcd5a1` (single plan commit)

---

**Total deviations:** 2 auto-fixed (both Rule 3 — blocking issues preventing the task's own verify commands from passing).
**Impact on plan:** Both fixes were necessary to make the script and doc actually pass their own stated verification; no scope creep.

## Issues Encountered
- Local Postgres showed 1 non-idle `pg_stat_activity` connection from an unrelated concurrent project's test run at the start of Task 2's measurement window (per the `executor_safety` contention check). Waited and re-polled every 20s; cleared after ~100s, well under the 15-minute halt budget. No suite or beam process for this repo was ever running concurrently with the measurement.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- SUITE-01 is complete: the CI before figures, local rankings, and D-03's N=3 confirmation are all recorded and cited.
- Plan 02 (SUITE-02 partitioning) can now lock N=3 from this plan's D-03 line and build `bin/ci-test-partitions` against the recorded `ci-job-timing.py --compare` formula.
- No blockers for 225-02.

## Self-Check: PASSED

All five created files found on disk; commit `75dcd5a1` found in `git log --oneline --all`.

---
*Phase: 225-suite-baseline-and-partitioned-ci*
*Completed: 2026-09-30*
