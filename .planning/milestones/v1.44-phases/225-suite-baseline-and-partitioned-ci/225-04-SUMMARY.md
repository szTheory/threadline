---
phase: 225-suite-baseline-and-partitioned-ci
plan: 04
subsystem: testing
tags: [ci, github-actions, elixir, ex_unit, flake-detection, partitioning]

requires:
  - phase: 225-01
    provides: "SUITE-01 baseline (run 36730596489 figures, ci-job-timing.py, check-citations.py)"
  - phase: 225-02
    provides: "SUITE-03 telemetry async conversion and its local 200-repeat proof"
  - phase: 225-03
    provides: "SUITE-02 gate commit (bin/ci-test-partitions, mix verify.test_partitioned, D-07 fix, Flake Detection resize draft)"
provides:
  - "Cited post-change ci.yml runs (36808706517, 36810081717) proving SUITE-02's 30%/10% bar with an OVERALL PASS verdict"
  - "D-07 and D-10 mutation-control proof from the cited runs' own logs"
  - "Cited Flake Detection run 36810083586 (pass, 13 iterations, 0 failures) and the record of the ceiling-exceeded -> maintainer-authorized resize path"
  - "SUITE-06 before/after report (local median + CI step/proxy, SUITE-03 delta reported separately)"
  - "225-EVIDENCE.md passes tools/check-citations.py end to end"
  - "Closed the folded sync-bound-parallelism todo"
  - "SUITE-02 and SUITE-03 marked Complete in REQUIREMENTS.md"
affects: [226, 227, 228, 229, 230]

actuals:
  tokens: 9850
  tasks: 2
  commits: 1
  plan_head_before: 6c4da13f801ec001849905fa7ac711388da12567
  plan_head_after: 9b5dd58bf0d3c3329f3b18ab34f0f6220e2a9db6

tech-stack:
  added: []
  patterns:
    - "ci-job-timing.py --compare as the single formula for before/after CI verdicts, never hand-computed percentages"
    - "check-citations.py: every figure in a phase evidence doc cites its run id or backticked command, enforced mechanically"

key-files:
  created: []
  modified:
    - .planning/phases/225-suite-baseline-and-partitioned-ci/225-EVIDENCE.md
    - .planning/todos/completed/2026-09-28-ci-suite-sync-bound-parallelism.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md

key-decisions:
  - "Cited the actual CI history (PR #71 pull_request runs + one explicit dispatch) rather than re-deriving a literal three-sequential-dispatch shape, since the maintainer's grant was broad ('automatically follow your recommendations... go for it') and every run is still cited, none dropped or re-run for a better figure"
  - "Recorded the Flake Detection ceiling-exceeded path honestly: run 36810083586's raw figures (286.3s cold / 227.2s slowest repeat) exceeded Plan 03's committed ceilings (261s/207s); the orchestrator's maintainer-authorized resize (commit 6c4da13f, 11 repeats, 287s/228s ceilings) is what the run's figures actually fit, and that chain is spelled out rather than silently presented as a plain pass"
  - "Fixed 62 previously-uncited lines in 225-EVIDENCE.md (from the Plan 02/03 sections) so the phase's own citation checker passes end to end, per this plan's additional scope"

requirements-completed: [SUITE-02, SUITE-03]

coverage:
  - id: D1
    description: "SUITE-02 verdict: cited post-change CI runs show the partitioned Run tests step at least 30% faster and billed-minute proxy at most 10% higher than the SUITE-01 baseline, on every lane"
    requirement: "SUITE-02"
    verification:
      - kind: other
        ref: "python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py --compare 36730596489 36808706517 36810081717"
        status: pass
    human_judgment: false
  - id: D2
    description: "D-07: the current lane's Verify Threadline trigger coverage step passes against partition 1's database with the canary table covered, not an empty report"
    requirement: "SUITE-02"
    verification:
      - kind: other
        ref: "gh run view 36808706517 --log (Verify Threadline trigger coverage step)"
        status: pass
    human_judgment: false
  - id: D3
    description: "D-10: Prove the gate goes red (failing partition) mutation control passes on all three lanes of both cited runs"
    requirement: "SUITE-02"
    verification:
      - kind: other
        ref: "gh run view 36808706517 --log, gh run view 36810081717 --log (Prove the gate goes red step)"
        status: pass
    human_judgment: false
  - id: D4
    description: "D-18/D-11: one cited Flake Detection run on the post-change head passes (13 iterations, 0 flaky/broken), with its cold/slowest-repeat figures reconciled against the committed ceilings"
    requirement: "SUITE-03"
    verification:
      - kind: other
        ref: "gh run view 36810083586 --log (Classify broken vs flaky step)"
        status: pass
    human_judgment: false
  - id: D5
    description: "SUITE-06 before/after report: local median and CI step/proxy, before and after, with the SUITE-03 delta reported separately from the partitioning delta"
    verification:
      - kind: other
        ref: "225-EVIDENCE.md ## SUITE-06 before and after"
        status: pass
    human_judgment: false

duration: ~50min
completed: 2026-10-01
status: complete
---

# Phase 225 Plan 04: Cite the Partitioned CI Runs Summary

**Cited CI runs 36808706517 and 36810081717 prove SUITE-02's partitioned-CI bar with an OVERALL PASS (step drop 37.5-65.3%, proxy change -50.0% to -12.5% on every lane), and Flake Detection run 36810083586 proves SUITE-03's no-new-flake claim after a maintainer-authorized ceiling resize.**

## Performance

- **Duration:** ~50 min
- **Completed:** 2026-10-01T04:56:55Z
- **Tasks:** 2 (Task 1, the maintainer grant checkpoint, was already resolved before this plan resumed)
- **Files modified:** 4 (`225-EVIDENCE.md`, the folded todo, `REQUIREMENTS.md`, `ROADMAP.md`)

## Accomplishments
- Measured and cited two independent green post-change `ci.yml` runs (36808706517 `pull_request`, 36810081717 `workflow_dispatch`, both at head `9614535c`) with `ci-job-timing.py --compare 36730596489 ...` → **OVERALL: PASS**, every lane at or beyond the 30% step-drop floor and under the 10% proxy-rise ceiling (every lane actually shows a proxy *drop*).
- Extracted and recorded, straight from each run's own logs: the `Prove the gate goes red (failing partition)` mutation control passing on all three lanes of both runs, the per-lane `Run tests` partition tables in ascending order (matching `ci-job-timing.py`'s seconds), and D-07's `Verify Threadline trigger coverage` step reporting the canary table covered on the current lane.
- Cited Flake Detection run 36810083586: classification **pass**, 13 completed iterations (1 cold + 12 repeats), 0 failures, `GATE_DECISION: run`, exit 0 at 2994s of a 3300s budget. Its raw figures (286.3s cold, 227.2s slowest repeat) exceeded Plan 03's committed ceilings (261s/207s) — recorded as the plan's "exceeds a ceiling" path, resolved by the orchestrator's maintainer-authorized resize (`6c4da13f`, now 287s/228s ceilings at 11 repeats), which this same run's figures fit.
- Wrote `## SUITE-06 before and after`: local median (before 137.0s, after SUITE-03 133.0s, at the phase head 136.5s, SUITE-03's own -2.9% delta called out separately) and CI (per-lane `Run tests` seconds and the billed-minutes proxy, before vs. both cited after runs, with the `--compare` percentages).
- Closed the folded todo (`.planning/todos/pending/2026-09-28-ci-suite-sync-bound-parallelism.md` → `.planning/todos/completed/`) with a resolution note naming which levers Phase 225 delivered and which part is deferred.
- Marked SUITE-02 and SUITE-03 Complete in `.planning/REQUIREMENTS.md` (checkbox + traceability table) and ticked the 225-04 line in `.planning/ROADMAP.md`.
- Made `225-EVIDENCE.md` pass `tools/check-citations.py` end to end: fixed 62 previously-uncited lines carried over from the Plan 02/03 sections (every digit-bearing line now cites its run id or a backticked command), none of the original evidence text deleted.

## Task Commits

1. **Task 1: Maintainer grant for the push and the CI dispatches** — already resolved before this plan resumed (see `<checkpoint_resolution>`; no new commit).
2. **Task 2 + Task 3: Cite the post-change CI runs, the SUITE-02 verdict, the Flake Detection run, the SUITE-06 report, and close the todo** — `9b5dd58b` (docs). The plan's Task 3 `<action>` specified a single commit covering `225-EVIDENCE.md` and the two todo paths; Task 2's evidence additions and Task 3's additions were combined into that one commit, consistent with the plan's own commit-shape instruction.

**Plan metadata:** this SUMMARY plus the `REQUIREMENTS.md`/`ROADMAP.md`/`STATE.md` updates are committed separately per the standard final-metadata-commit step.

## Files Created/Modified
- `.planning/phases/225-suite-baseline-and-partitioned-ci/225-EVIDENCE.md` — added `## CI after` (grant quote, dispatch-shape deviation, full PR #71 run history, both cited runs' figures and log extracts), `## SUITE-02 verdict`, `## Flake Detection`, `## SUITE-06 before and after`; fixed 62 pre-existing uncited lines from earlier sections
- `.planning/todos/completed/2026-09-28-ci-suite-sync-bound-parallelism.md` — moved from `pending/`, resolution note added
- `.planning/REQUIREMENTS.md` — SUITE-02 and SUITE-03 checked off and marked Complete in the traceability table
- `.planning/ROADMAP.md` — 225-04-PLAN.md line checked off

## Decisions Made
- Cited the CI history as it actually happened (PR #71 `pull_request` runs for most of the iteration, plus one explicit `gh workflow run ci.yml` dispatch and one `gh workflow run flake-detection.yml` dispatch) rather than forcing the plan's literal "three sequential dispatches" shape onto a changed situation; the maintainer's grant was broad enough to cover this, and the plan's own safety rules (every run cited, none dropped or re-run for a better number) are satisfied either way.
- Recorded the Flake Detection ceiling-exceeded chain explicitly rather than silently reporting a pass against ceilings that had already changed underneath the cited run — the run both triggered and then (under the new ceilings) satisfies the sizing check.
- Treated the citation-checker cleanup (<also> in the dispatch prompt) as in-scope for this plan since `225-EVIDENCE.md` is this plan's primary deliverable file; fixed by adding minimal trailing citations or wrapping a run id in the required `run NNNNNNNN` format, never by deleting or rephrasing the underlying evidence claims.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] 62 pre-existing uncited lines in 225-EVIDENCE.md blocked a clean `check-citations.py` run**
- **Found during:** Task 3 (dispatch prompt's `<also>` section)
- **Issue:** Lines carried over from the Plan 02 (SUITE-03) and Plan 03 (SUITE-02 local) sections had figures without a citeable run id or backticked command — mostly multi-line sentences where the citation landed on a different physical line than the digit it supported.
- **Fix:** Added a trailing backtick-quoted command citation (e.g. `` (`mix test`) ``, `` (`mix verify.test_partitioned`) ``, `` (`gh run view 36364688861 --log`) ``) to each flagged line, reusing whatever command the surrounding paragraph already referenced; for two lines the fix was removing markdown bold around a run id so `run 36364688861` matched the checker's literal pattern. No evidence text was deleted or its claim changed.
- **Files modified:** `.planning/phases/225-suite-baseline-and-partitioned-ci/225-EVIDENCE.md`
- **Verification:** `python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/check-citations.py .planning/phases/225-suite-baseline-and-partitioned-ci/225-EVIDENCE.md` exits 0; `bin/verify-repo-hygiene` stays clean (4298 tracked files, 0 inert).
- **Committed in:** `9b5dd58b`

**2. [Rule 1 - Bug] Task 2's automated `<verify>` and Task 3's first automated `<verify>` assume a literal `workflow_dispatch`-only history that the actual deviation (PR runs + one dispatch) doesn't produce**
- **Found during:** Task 3, running the plan's literal automated verify commands
- **Issue:** Task 2's `<verify>` filters `gh run list ... --event workflow_dispatch --limit 1` and expects that single latest dispatch's `headSha` to equal the *current* `origin/milestone/v1.44` HEAD; Task 3's first `<verify>` filters `--event workflow_dispatch --limit 3` and needs at least two successful dispatch-event runs. In the actual history, only one run (36810081717) was a `workflow_dispatch`; the other cited run (36808706517) was a `pull_request` run, and the branch head advanced past both cited runs' head (`9614535c`) via later commits (including the orchestrator's `6c4da13f` resize), so neither literal script exits clean.
- **Fix:** Did not change the scripts (out of this plan's scope and not a defect in the tool itself — it is a defect in the verify command's assumption given the documented dispatch-shape deviation). Instead ran the equivalent real check by hand — `ci-job-timing.py --compare 36730596489 36808706517 36810081717` → OVERALL: PASS — and the SUITE-06/todo-closure checks from Task 3's second `<verify>` block, which do pass as written. Documented this gap here rather than silently treating the mismatched literal command as evidence.
- **Files modified:** none (verification-only; no code or script change)
- **Verification:** `ci-job-timing.py --compare 36730596489 36808706517 36810081717` exits 0 with OVERALL: PASS (recorded in `225-EVIDENCE.md`); the SUITE-06/todo/hygiene checks in Task 3's second `<verify>` block pass as written.
- **Committed in:** n/a (no code change; evidence recorded in `9b5dd58b`)

---

**Total deviations:** 2 auto-fixed (1 blocking citation cleanup, 1 documented verify-script/reality mismatch)
**Impact on plan:** Both are evidence-presentation issues, not changes to what was actually measured or proven. No scope creep beyond the dispatch prompt's explicit `<also>` ask.

## Issues Encountered
None beyond the deviations above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- SUITE-01, SUITE-02, SUITE-03, SUITE-05 and SUITE-06 are all Complete for Phase 225; the remaining v1.44 SUITE requirement (SUITE-04, guard-test keep/cut) is Phase 230's.
- Phase 225 is ready for orchestrator-level verification; all four plans (225-01..225-04) report complete in ROADMAP.md.
- A further `pull_request` CI run on the branch tip (`6c4da13f`, run 36815423208) was still `in_progress` when this plan finished and was deliberately not waited on or cited, per the dispatch prompt's instruction; it needs no follow-up from this plan.

---
*Phase: 225-suite-baseline-and-partitioned-ci*
*Completed: 2026-10-01*

## Self-Check: PASSED

All referenced files exist (`225-EVIDENCE.md`, the closed todo, `REQUIREMENTS.md`, `ROADMAP.md`,
this SUMMARY) and commit `9b5dd58b` is present in `git log --oneline --all`.
