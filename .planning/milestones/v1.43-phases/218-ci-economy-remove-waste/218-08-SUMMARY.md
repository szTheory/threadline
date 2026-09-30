---
phase: 218-ci-economy-remove-waste
plan: 08
subsystem: ci
status: complete
tags: [ci, measurement, econ-07, econ-02, econ-05, runner-minutes, critical-path]
requires:
  - phase: 214-baseline-measurement
    provides: "BASE-01 figures and the collector / summarizer / citation-checker tools (copied, never run in place)"
  - phase: 218-01
    provides: "release PR single-run guard (ECON-03, recorded as [inference])"
  - phase: 218-02
    provides: "bin/upsert-ci-issue --close and the #28/#36 hand-off"
  - phase: 218-03
    provides: "live Dialyzer slice in verify-dialyzer only, fail-closed"
  - phase: 218-04
    provides: "removal of verify-mechanical, verify-docs, verify-hex-package and the capture lane's mechanical step"
  - phase: 218-05
    provides: "weekly bounded Flake Detection with the green-SHA gate"
  - phase: 218-07
    provides: "Browser-full derived project partition"
provides:
  - "218-REMEASURE.md: cited post-change runner-minute, wall, critical-path, per-job, flake and Browser-full deltas against BASE-01"
  - "tools/remeasure-218.py: named-sample-set figures on the copied summarizer's unchanged arithmetic (its base set reproduces BASE-01 exactly)"
  - "raw/ci: 22 collected run files and manifest for the post-landing window"
  - "ECON-02 evidence: #28 and #36 closed by the green dispatch runs"
  - "Three landing fixes on draft PR #60 (Playwright dependency, published-snapshot scrub, flake repeat count)"
affects: [219, 221, 222]
tech-stack:
  added: []
  patterns:
    - "Re-measurement from copied tools into the phase's own raw/ci, never the baseline's"
    - "New figures come from a separately named script that imports the copied arithmetic, never from an edited copy"
    - "verify-dialyzer samples labeled hit/miss from the PLT step output before any attribution"
key-files:
  created:
    - .planning/phases/218-ci-economy-remove-waste/tools/collect-ci-runs.sh
    - .planning/phases/218-ci-economy-remove-waste/tools/summarize-ci.py
    - .planning/phases/218-ci-economy-remove-waste/tools/check-citations.py
    - .planning/phases/218-ci-economy-remove-waste/tools/fixtures/cited.md
    - .planning/phases/218-ci-economy-remove-waste/tools/fixtures/uncited.md
    - .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py
    - .planning/phases/218-ci-economy-remove-waste/raw/ci/manifest.json
    - .planning/phases/218-ci-economy-remove-waste/raw/ci/runs/ (22 run files)
    - .planning/phases/218-ci-economy-remove-waste/218-08-DEVIATIONS.md
  modified:
    - .planning/phases/218-ci-economy-remove-waste/218-REMEASURE.md
    - .planning/phases/218-ci-economy-remove-waste/deferred-items.md
    - examples/threadline_phoenix/e2e/playwright.config.ts
    - bin/browser-full-projects
    - test/threadline/browser_full_projects_contract_test.exs
    - mix.exs
    - .github/workflows/flake-detection.yml
    - bin/classify-flake-run
    - test/threadline/flake_classifier_contract_test.exs
    - CONTRIBUTING.md
key-decisions:
  - "The headline per-run figures use all eight post-landing ci.yml runs: all ran the identical 15-job set, and the six failures were confined to the 6-8 s Repo hygiene job plus the CI required aggregate"
  - "Attributable runner-minute savings exclude verify-deps-audit (phase 215) and verify-repo-hygiene (phase 217); the test-lane deltas are reported but not credited, because of suite growth and the min-lane runner change"
  - "The +20 s critical-path p50 is inside the browser job's own BASE-01 spread and is not credited to 218; ECON never targeted the critical path"
  - "verify-dialyzer's +74 s comes from PLT-hit samples only (n=5 vs n=15); none of the post-landing misses is a cold PLT build"
  - "The flake lane was resized 15 -> 12 repeats (deviation 3) instead of widening the budget; a pass now leaves about 20% of the 55-minute budget unused"
requirements-completed: [ECON-07, ECON-02]
duration: 3h 10min (including the landing fixes)
completed: 2026-09-28
commits: 9
plan_head_before: 56f46e80b02ceee27b7f700df3949bc37001fe0b
plan_head_after: cb7bdb6c59ac7f9cacdff48975245f1ad8c57c34
actuals:
  tokens: 219000
  tasks: 3
  commits: 9
---

# Phase 218 Plan 08: CI re-measurement after the economy cuts Summary

**Each ci.yml run now costs 44.4 unrounded / 53 billed runner-minutes at p50, down from 46.3 / 55. The part attributable to phase 218 is 43.7 / 51, a saving of 2.6 / 4. The critical path did not move (623 → 643 s, not credited). A Flake Detection pass costs 45.7 min per week instead of 98-137 min per night, and Browser-full costs 6.4 min instead of 18.0. #28 and #36 were closed by those green runs. Every figure cites its run ID in `218-REMEASURE.md`.**

## Performance

- **Duration:** about 3h 10min, from the Task 1 tracer through the landing fixes to this re-measure
- **Completed:** 2026-09-28
- **Tasks:** 3 of 3 (Task 2 was the maintainer's push checkpoint)
- **Files:** 41 changed in the plan range. The 22 raw run JSON files account for most of the size.

## Accomplishments

- **Task 1 (d9d747f8):** copied the 214 tools into 218's own `tools/` and opened the `218-REMEASURE.md` skeleton. The phase gate passed:
  - `mix test`: 2460 tests, 0 failures, 3 excluded;
  - `mix ci.all`: exit 0;
  - `bin/verify-repo-hygiene`: clean.
- **Task 2 (maintainer):** the maintainer pushed branch `land/v1.43-217-218`, opened draft PR #60 against main, and granted the dispatches. The orchestrator ran all of them; this executor dispatched nothing.
- **Task 3 (cb7bdb6c):** collected 22 runs with the copied collector, wrote `tools/remeasure-218.py`, and filled all ten sections of `218-REMEASURE.md`. The citation checker exits 0 on it, and it cites 39 distinct run IDs.

### Headline deltas (all cited in 218-REMEASURE.md)

| Figure | BASE-01 | Post-change | Delta |
|---|---|---|---|
| Runner-min per ci.yml run (all jobs, n=8) | 46.3 unrounded / 55 billed | 44.4 / 53 | −1.9 / −2 |
| Runner-min per ci.yml run (attributable to 218) | 46.3 / 55 | 43.7 / 51 | −2.6 / −4 |
| Critical-path end offset p50 | 623 s | 643 s | +20 s (inside the browser job's spread; not credited) |
| Wall clock p50 | 629 s | 648 s | +19 s |
| verify-dialyzer, PLT hit samples only | 83 s (n=15) | 157 s (n=5) | +74 s (22 s container init plus 54 s live step) |
| Removed jobs (mechanical, docs, hex-package) | 87 + 75 + 17 s | 0 | −179 s, −5 billed min per run |
| Tier A capture job | 532 s | 499 s | −33 s (the removed step was 49 s) |
| Flake Detection per run | 98.0–137.0 min nightly | 45.7 min, `pass` (run 36364688861) | measured |
| Flake Detection per month [inference] | 2,940–4,110 | ≤ ~198 (4.33 × 45.7), ~0 on an unchanged SHA | about −2,742 to −3,912 |
| Browser-full per run | 18.0 min push p50 | 6.4 min (run 36363979144) | −11.6 min |
| Browser-full per month [inference] | 435 nightly + 331 push | ~0 nightly + ~128 push | about −638 |

**Samples used, and why.** The eight ci.yml runs of the pushed code are all runs of the same 15-job set:
- pull_request: 36359132030, 36362405054, 36363356238 and 36364354586;
- workflow_dispatch top-ups: 36359171595, 36359795977, 36360336486 and 36361003789.

The six failed runs failed only at "Repo hygiene (no machine-local paths)" and "CI required". The committed job data shows every other job with conclusion `success` in every run. So they are valid timing and runner-minute samples. The post-fix samples are run 36363356238 and run 36364354586. REMEASURE §2 and §3 also report the pull_request-only, dispatch-only and success-only subsets. The earlier runs of other PRs on 2026-09-27 are kept in `raw/` but excluded, because they ran pre-218 code with the old 17-job roster.

**Dialyzer hit/miss labeling.** Every post-landing verify-dialyzer sample is labeled from the `THREADLINE_DIALYZER_PLT_CACHE` line in its job log:
- 5 hits: 36359795977, 36360336486, 36361003789, 36362405054 and 36363356238;
- 3 warm misses: 36359132030, 36359171595 and 36364354586. In each, the `restore-keys` prefix restored a PLT and the logged PLT build took 0.48-0.66 s.

None of the misses is a cold build. 218-03 predicted a cold build on the first run, and the prefix restore prevented it. The 20 baseline samples were labeled from the committed step conclusions: 15 hits and 5 misses, of which 2 were cold 137-139 s builds. Two baseline logs were fetched as spot checks, and both agree. The +74 s attribution uses hit samples only.

**ECON-02: #28 and #36.** Both issues are `CLOSED` with stateReason `COMPLETED`:
- #28 was closed 2026-09-28T01:01:34Z by Browser-full run 36363979144.
- #36 was closed 2026-09-28T01:52:01Z by Flake Detection run 36364688861.

Both closes came from dispatch runs on the land branch, not from main. The earlier failed and inconclusive runs had updated the same issues (`action=update`). This discharges 218-02's hand-off.

**ECON-05: the live-slice CI confirmation.** All eight post-landing verify-dialyzer logs show `mix verify.dialyzer_slice` running under `MIX_ENV: test`, with `Including tags: [:live_dialyzer]` and `17 tests, 0 failures, 16 excluded`. The literal line `verified slice critic-tooling: 3/40 sealed warnings; ... 0 live warnings` is not in any CI log, because the test captures the verifier's output and only asserts on it. See Deviations 4.

## Task Commits

1. **Task 1: Tracer, copied tools, phase gate** - `d9d747f8` (docs)
2. **Task 2: Maintainer push** - checkpoint. Branch `land/v1.43-217-218`, draft PR #60, pushed 2026-09-27T23:34:10Z.
3. Landing fixes during the checkpoint window (Rule 1, recorded in `218-08-DEVIATIONS.md`):
   - `00011bac` test, then `22a4829f` fix: refute-capture declares its tier-a-capture dependency;
   - `8119e3a9` docs: the deviations record;
   - `77f684c1` test, then `fbfbcb11` fix: the flake lane sized at 12 repeats;
   - `bf5e4359` docs: records the flake-lane sizing deviation.
4. **Task 3: Collect and write the cited re-measure** - `cb7bdb6c` (docs)

`commits: 9` is measured with `git rev-list --count 56f46e80..HEAD`. The count includes `d819c199`, the orchestrator's todo capture, which is not part of 218-08.

## Task 1 tool diffs (complete `diff` output against the 214 originals)

```
== collect-ci-runs.sh
11c11
< #   bash .planning/phases/214-baseline-measurement/tools/collect-ci-runs.sh \
---
> #   bash .planning/phases/218-ci-economy-remove-waste/tools/collect-ci-runs.sh \
== summarize-ci.py
44c44
< SELF = "python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py"
---
> SELF = "python3 .planning/phases/218-ci-economy-remove-waste/tools/summarize-ci.py"
== check-citations.py
5,6c5,6
<   python3 .planning/phases/214-baseline-measurement/tools/check-citations.py <file.md>
<   python3 .planning/phases/214-baseline-measurement/tools/check-citations.py --self-test
---
>   python3 .planning/phases/218-ci-economy-remove-waste/tools/check-citations.py <file.md>
>   python3 .planning/phases/218-ci-economy-remove-waste/tools/check-citations.py --self-test
10c10
<      requirement IDs ([A-Z]+-NN), phase/plan numbers (214, 214-0N), 7-40 char hex
---
>      requirement IDs ([A-Z]+-NN), phase/plan numbers (214-218, 21N-0N), 7-40 char hex
31c31
<     re.compile(r"\b214(?:-0\d)?\b"),                 # phase / plan numbers
---
>     re.compile(r"\b21[4-8](?:-0\d)?\b"),             # phase / plan numbers (214-218)
```

Only self-path strings and the phase-number exemption differ. The fixtures are byte-identical, and `check-citations.py --self-test` passes. `git status --porcelain -- .planning/phases/214-baseline-measurement/` is empty.

## Phase gate (Task 1, before the push checkpoint)

- `mix test`: 9 properties, 2460 tests, 0 failures, 3 excluded.
- `mix ci.all`: exit 0.
- `bin/verify-repo-hygiene`: clean.

After the landing fixes, the main checkout gave `mix test` 2469 tests, 0 failures, 3 excluded, with `bin/verify-repo-hygiene` exit 0 (8 allowlist entries used, 0 inert). After the Task 3 commit, `bin/verify-repo-hygiene` reported 4019 tracked text files clean.

## Files Created/Modified

- `tools/{collect-ci-runs.sh,summarize-ci.py,check-citations.py,fixtures/*}`: copies of the 214 tools, retargeted as shown in the diffs above.
- `tools/remeasure-218.py` (new): figures for named sample sets (`post`, `post-pr`, `post-dispatch`, `post-success`, `base`), built on the copied summarizer's arithmetic, imported unchanged. The copied summarizer cannot do this itself, because its jobs, wall, critical-path and runner-minutes modes read only the plain manifest keys (`ci.yml:pull_request`), and the since-keyed collection never writes them. Its `--set base` reproduces BASE-01's 46.3 / 55 and 629 s exactly.
- `raw/ci/manifest.json` and `raw/ci/runs/*.json` (22 files): four since-keyed entries (ci.yml pull_request and workflow_dispatch, flake-detection and browser-full workflow_dispatch). The files contain only GitHub API job data. There are no runner paths or usernames in them (checked with grep, and the hygiene guard passes).
- `218-REMEASURE.md`: all ten sections filled.
- `deferred-items.md`: two 218-08 items.

## Decisions Made

See the `key-decisions` frontmatter. The main judgment calls:
- The failed-at-hygiene runs count as samples, because the job data shows every other job completed.
- The critical-path regression is reported but not credited to phase 218.
- The test-lane deltas are reported but not credited. ECON-05's saving there is bounded at about one minute per lane, as an [inference].

## Deviations from Plan

### Auto-fixed Issues (landing fixes, full record in `218-08-DEVIATIONS.md`)

**1. [Rule 1 - Bug] Browser-full refute-capture needed tier-a-capture (run 36359136941)**
- **Found during:** the first Browser-full dispatch after the push.
- **Issue:** refute-capture reads the `artifacts/tier-a/<cell>` directories that only tier-a-capture creates. `playwright.config.ts` never declared that dependency. After 218-07 moved tier-a-capture into ci.yml only, refute-capture failed with `missing tier-a cell dir`.
- **Fix:** RED `00011bac`, GREEN `22a4829f`. refute-capture now declares `dependencies: ["tier-a-capture"]`. `bin/browser-full-projects` gained `--list deps` and `--list executed`, the contract test gained mutation controls, and one CONTRIBUTING sentence changed. These became `de9290f7` and `c18f2b2f` on the land branch.
- **Verified on CI:** run 36363979144 ran `5 passed (4.0m)`, with a Playwright step of 332 s against a 45-minute step timeout.

**2. [Rule 1 - Bug] Repo hygiene failed on main's published `.planning/` snapshot (run 36359132030)**
- **Issue:** the land branch carried origin/main's old, unscrubbed `.planning/` files.
- **Fix:** 217-04's prefix-only rewrite was replayed on the land worktree (`23986942`, land branch only). It is byte-identical to `ddcea1c8` for 303 of the 304 files.
- **Residual:** the orchestrator resolved the remaining `UNUSED allowlist entry .planning/ ~/.hex` line by syncing the scrubbed milestone `.planning/` record, which is option (b) in DEVIATIONS.
- **Verified on CI:** run 36363356238 and run 36364354586 are green.

**3. [Rule 1 - Bug] The flake lane was sized past its own budget (run 36359135268)**
- **Issue:** 218-05 sized 15 repeats from BASE-01's 1698-test timings. On the 2460-test suite, 1 + 15 runs need about 57 min, and the budget is 55 min. The run classified `inconclusive` after 15 clean iterations, so as shipped the close-on-pass path could never fire.
- **Fix:** RED `77f684c1`, GREEN `fbfbcb11`. The lane now runs 12 repeats, within D-02's bound, with the budget and timeouts unchanged. A sizing contract test with mutation controls now pins the count. These became `12eac623` and `398e8440` on the land branch.
- **Verified on CI:** run 36364688861 classified `pass`: 13 iterations, a repeat step of 2650 s against the 3300 s budget, and 2469 tests with 0 failures in each iteration. It closed #36.

**4. [Plan must_have partly unmet] The ECON-05 literal line is not in the CI log**
- **Must-have:** the first post-landing verify-dialyzer job log contains `verified slice critic-tooling: 3/40 sealed warnings` and `0 live warnings`.
- **Why it is not met:** the `:live_dialyzer` test captures the verifier's output through `System.cmd` and asserts on it, so a passing run prints only `17 tests, 0 failures, 16 excluded`.
- **Evidence recorded instead:** REMEASURE §8 records the indirect proof:
  - exactly one test ran, and it asserts both strings;
  - the verifier now fails closed;
  - a PLT was present in every run.
- **Follow-up:** making the line quotable from CI needs a code change and a push. It is logged in `deferred-items.md`, with Phase 221 as the candidate. It was not fixed here, because this plan only measures.

**5. [Rule 3 - Blocking] Figures come from a new script instead of the copied summarizer's modes**
- **Issue:** the plan says to run the copied `summarize-ci.py` `jobs` / `wall` / `critical-path` / `runner-minutes --unit pr`. Those modes read only the plain manifest keys, which the plan's own `--status any --since` collector commands do not write (`runner-minutes --unit push` exits "manifest has no entry").
- **Fix:** the plan's fallback: a separately named `tools/remeasure-218.py` that imports the copied arithmetic unchanged. Its base set reproduces BASE-01 exactly. `workflow-cost` was used directly from the copied tool.

---

**Total deviations:** 3 auto-fixed bugs (landing), 1 must-have partly unmet (documented and deferred), 1 tool-path deviation (the plan's own fallback).
**Impact on plan:** ECON-07 holds. Every figure is measured and cited, projections are labeled, and the ECON-02 evidence is complete. The ECON-05 CI proof is indirect rather than a literal quote.

## Issues Encountered

- The GitHub API budget held. 14 job-log fetches were made: 8 verify-dialyzer, 2 flake, 2 Browser-full and 2 baseline spot checks. There were 4 list calls, 22 jobs calls and 2 issue views, and no 403s.
- The collector's `--since` is day-granular, so it also returned 12 earlier runs from other PRs. They were excluded by the push instant, and REMEASURE §1 lists them.

## Known Stubs

None.

## Threat Flags

None. No new network, auth or file surface. The only GitHub calls were read-only GETs.

## Left unproven

- **The push-to-main unit (~52.7 runner-min)** is an [inference] until the first post-merge push.
- **The Browser-full per-push figure** comes from a dispatch run standing in for a push run.
- **The monthly flake and Browser-full figures** are cadence arithmetic. No weekly or nightly scheduled sample ran after the change (D-11).
- **ECON-03** is an [inference]: no release cycle ran.
- **ECON-05's saving in the test lanes** is bounded, not measured, because suite growth and the min-lane runner change confound it.
- **The literal live-slice line** is not in the CI logs (Deviation 4).

## Next Phase Readiness

- Phase 222 (SEED-006) can reuse these per-job figures. REMEASURE §9 holds the attributable per-run baseline for the next re-measure.
- Phase 221 (CI legibility) inherits the two deferred items.

## Self-Check: PASSED

- All created files exist: the tools, `remeasure-218.py`, `raw/ci/manifest.json`, the 22 run files and `218-REMEASURE.md`.
- All commits are in `git log`: d9d747f8, 00011bac, 22a4829f, 8119e3a9, 77f684c1, fbfbcb11, bf5e4359 and cb7bdb6c.
- The citation checker exits 0 on `218-REMEASURE.md`. There are no `Pending:` lines, `[inference]` is present, and 39 distinct run IDs are cited, above the minimum of 7.
- `.planning/phases/214-baseline-measurement/` is unmodified.
