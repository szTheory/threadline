---
phase: 222-seed-006-change-aware-lanes-conditional
plan: 01
subsystem: ci-measurement-tooling
tags: [gh-cli, python-stdlib, ci-economy, seed-006, inert-share, measurement]

requires:
  - phase: 214-baseline-measurement
    provides: inert-share.py classifier, inert-allowlist.txt, the BASE-01 gh collection commands
  - phase: 219-deps-only-build-cache
    provides: collect-ci-runs.sh, summarize-ci.py, check-citations.py, the remeasure-N.py import-the-summarizer pattern, the three skip-eligible warm run IDs (Browser E2E 36455432448, Capture 36450388764, PgBouncer 36457705448)
provides:
  - A phase-local copy of inert-share.py extended with at-214, since-214 and 30d-now fixed windows plus a --last N mode, proven byte-identical to Phase 214 on a fresh snapshot
  - A fresh, committed raw/prs/ snapshot (49 merged PRs) and raw/ci/ snapshot (28 PRs' representative ci.yml pull_request runs)
  - remeasure-222.py: the D-02 two-part minute gate and the D-03 non-voting ceiling, both self-tested and deterministic
  - A one-command phase gate (verify-phase.sh) proving all of the above plus read-only-gh and no-machine-path guards
  - The measured verdict for SEED-006: CLOSE
affects: [222-seed-006-change-aware-lanes-conditional/222-02, SEED-006-ci-feedback-loop-cost-and-latency]

actuals:
  tokens: 445925
  tasks: 3
  commits: 3
  plan_head_before: 458609849538c9cae77835837e9994f79d1e604f
  plan_head_after: 125a2586a4db8257b549694b159b68546f5bb268

tech-stack:
  added: []
  patterns:
    - "Copy-and-retarget: a prior phase's proven measurement tool is copied verbatim into this phase's tools/, retargeting only self-path strings and (for check-citations.py) the phase-number citation exemption"
    - "Import-the-summarizer: remeasure-222.py loads summarize-ci.py and inert-share.py via importlib.util.spec_from_file_location rather than reimplementing billed-minute arithmetic or the fail-closed inert-PR rule"

key-files:
  created:
    - .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py
    - .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-allowlist.txt
    - .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/collect-ci-runs.sh
    - .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/summarize-ci.py
    - .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/check-citations.py
    - .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py
    - .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/verify-phase.sh
    - .planning/phases/222-seed-006-change-aware-lanes-conditional/COVERAGE.md
    - .planning/phases/222-seed-006-change-aware-lanes-conditional/raw/prs/ (49 PRs' index.json, heads.json, manifest.json, <n>.files.txt)
    - .planning/phases/222-seed-006-change-aware-lanes-conditional/raw/ci/ (manifest.json + 32 run JSONs)
  modified: []

key-decisions:
  - "D-01 reproduction verified: the 222 copy of inert-share.py reproduces Phase 214 exactly on a fresh snapshot (at-214 = 1 of 40, #8; 30d = 0 of 20), with the 40 file lists byte-identical and adjacency n(at-214)+n(since-214)=n(all) holding (40+9=49)"
  - "D-02 gate computed by command, not prose: minute-gate --window 30d-now gives n=28, k=0 strict-inert, denominator 1553 billed min (one representative ci.yml pull_request run per merged PR, highest run id on the PR's final head SHA), part 1 0.0% < 20% FAIL, part 2 0.0% < 10% FAIL, verdict: CLOSE"
  - "D-03 ceiling computed for the record: github-only 0 of 28, docs-only 6 of 28 (~7.3% of D), no-product-code 15 of 28 -- none of these vote, and the margin between the docs-only ceiling and the 10% gate threshold is wide"
  - "Fixed a cosmetic bug in the copied inert-share.py during Task 1: the at-214 window (lo=None, hi set) printed the misleading bounds label \"all merged PRs into main\"; corrected the bounds-string branch to distinguish lo=None/hi=None from a one-sided bound"

requirements-completed: []

coverage:
  - id: D1
    description: "The 222 copy of inert-share.py reproduces Phase 214's inert-PR share exactly on a fresh, committed snapshot, and reports the two new windows (since-214, 30d-now) plus a --last N mode"
    requirement: SCOPE-01
    verification:
      - kind: other
        ref: "bash .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/verify-phase.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "The D-02 two-part minute gate and D-03 ceiling are computed deterministically by remeasure-222.py, not by prose arithmetic, with a passing self-test"
    requirement: SCOPE-01
    verification:
      - kind: unit
        ref: "python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py --self-test"
        status: pass
      - kind: other
        ref: "python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py minute-gate --window 30d-now"
        status: pass
    human_judgment: false
  - id: D3
    description: "The measured verdict is CLOSE, so the plan continues to 222-02 (no checkpoint, nothing built)"
    requirement: SCOPE-01
    verification:
      - kind: other
        ref: "python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py minute-gate --window 30d-now | tail -1"
        status: pass
    human_judgment: false

duration: ~15min
completed: 2026-09-29
status: complete
---

# Phase 222 Plan 01: SEED-006 Re-Measure Summary

**Re-ran the Phase 214 inert-PR classifier on a fresh 49-PR snapshot and computed the D-02 minute gate by command: verdict CLOSE (0 of 28 strict-inert in the rolling 30 days, denominator 1553 billed min, both gate parts FAIL at 0.0%).**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-09-29T18:36:00Z (approx, first `gh` collection call)
- **Completed:** 2026-09-29T18:58:47Z
- **Tasks:** 3
- **Files modified:** 95 (mostly fresh, committed `raw/prs/` and `raw/ci/` snapshot data)

## Accomplishments

- Copied `inert-share.py` + `inert-allowlist.txt` from Phase 214 byte-for-byte (allowlist untouched); extended the copy's `WINDOWS` with `at-214`, `since-214` and `30d-now` as fixed constants derived from this collection's `manifest.json`, plus a `--last N` mode. Reproduced 214 exactly on a fresh 49-PR snapshot: `at-214` = 1 of 40 (`#8`), `30d` = 0 of 20.
- New windows on the fresh data: `since-214` = 0 of 9 (informational, n<10), `30d-now` = 0 of 28 (the D-02 gate window), `--last 20` = 0 of 20.
- Copied `collect-ci-runs.sh`, `summarize-ci.py`, `check-citations.py` and fixtures from Phase 219; widened `check-citations.py`'s phase-number exemption to admit 214-222. Collected per-PR `ci.yml` runs (read-only) for all 28 `30d-now` PRs, keyed by each PR's final head SHA.
- Wrote `remeasure-222.py`: `skip-saving` (19 billed min from the three fixed 219 warm skip-eligible runs), `minute-gate --window` (the D-02 two-part gate over one representative `pull_request` run per merged PR), `ceiling --window` (the D-03 non-voting classifiers) — all importing the copied `summarize-ci.py`/`inert-share.py` rather than reimplementing arithmetic. `--self-test` covers every case in the plan's `<behavior>` block, including the n=0/n<10 floors, the k=0 and k=6 synthetic gate scenarios, the exact threshold edges (20%/10%), the missing-manifest-entry data error, the no-pull_request-run exclusion, and the three ceiling classifiers.
- Wrote `verify-phase.sh`: a 13-check one-command phase gate (214 reproduction, byte-identity, adjacency, two-run determinism across every window/`--last 20`/minute-gate/ceiling, both tool self-tests, a read-only-`gh` guard, a machine-local-path guard). `--bogus` exits 64. All 13 checks pass.
- Wrote `COVERAGE.md`: no-external-API-integration statement naming the read-only `gh` commands used.
- **Measured the D-02 gate:** `minute-gate --window 30d-now` -> n=28 merged PRs, k=0 strict-inert, denominator 1553 billed min, part 1 0 of 28 = 0.0% (need >=20%) FAIL, part 2 saving 0x19 = 0 of 1553 = 0.0% (need >=10%) FAIL, **verdict: CLOSE**.
- **D-03 ceiling (information only):** github-only 0 of 28; docs-only 6 of 28 (`#45, #48, #51, #54, #58, #59`, ~7.3% of D); no-product-code 15 of 28.

## Task Commits

Each task was committed atomically:

1. **Task 1 (tracer): copy inert-share.py, collect a fresh PR snapshot, reproduce 214, report the new windows** - `3469e73c` (docs)
2. **Task 2: copy the CI collector, summarizer and citation checker; collect per-PR runs; build remeasure-222.py** - `d6d26ccc` (docs)
3. **Task 3: phase gate script, COVERAGE.md, and the conditional halt on the verdict** - `125a2586` (docs)

**Plan metadata:** this SUMMARY's own commit (pending)

## Files Created/Modified

- `.planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py` - Phase 214's classifier, extended with `at-214`/`since-214`/`30d-now` windows and `--last N`
- `.planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-allowlist.txt` - byte-identical copy of 214's allowlist
- `.planning/phases/222-seed-006-change-aware-lanes-conditional/tools/collect-ci-runs.sh`, `summarize-ci.py`, `check-citations.py`, `fixtures/{cited,uncited}.md` - copied from Phase 219, self-path strings and the citation phase-number regex retargeted
- `.planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py` - new: `skip-saving`, `minute-gate --window`, `ceiling --window`, `--self-test`
- `.planning/phases/222-seed-006-change-aware-lanes-conditional/tools/verify-phase.sh` - new: one-command phase gate
- `.planning/phases/222-seed-006-change-aware-lanes-conditional/COVERAGE.md` - new
- `.planning/phases/222-seed-006-change-aware-lanes-conditional/raw/prs/*` - fresh 49-PR snapshot (index.json, heads.json, manifest.json, `<n>.files.txt`)
- `.planning/phases/222-seed-006-change-aware-lanes-conditional/raw/ci/*` - manifest.json + 32 run JSONs for the 28 `30d-now` PRs

## Decisions Made

- Used option (b) from RESEARCH.md §1 for the 214 reproduction: collect one fresh superset snapshot, then verify the `at-214` window (fixed to Phase 214's exact PR set by mergedAt bound) reproduces 214's numbers byte-for-byte on file-list content, rather than copying 214's `raw/prs/` tree into 222. The fresh, larger `all` total (49) is reported honestly and separately.
- The D-02 minute-gate denominator uses real per-run billed minutes (RESEARCH.md §3 option 2, the "more rigorous option"), not a p50-proxy extrapolation: one representative `ci.yml pull_request` run per merged PR in `30d-now`, collected via `collect-ci-runs.sh --head-sha`.
- `since-214` (n=9) is presented as informational only in `minute-gate`'s own n<10 floor message; the formal D-02 gate is scoped to `30d-now` alone, per the RESEARCH.md Open Question 2 resolution already recorded in the plan.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed misleading window-bounds label for `at-214`**
- **Found during:** Task 1, first run of `--window at-214`
- **Issue:** `inert-share.py`'s original `summarize()` computed the bounds display string as `"all merged PRs into main" if lo is None else ...`, which is correct for the pre-existing `all` window (both bounds `None`) but wrong for the new `at-214` window (`lo=None`, `hi` set): it printed "all merged PRs into main" even though there is an upper bound.
- **Fix:** Replaced the single ternary with a four-way branch (`lo is None and hi is None` / `lo is None` / `hi is None` / both set) so `at-214` now prints "mergedAt on or before 2026-09-26".
- **Files modified:** `.planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py`
- **Verification:** `--self-test` and all five windows re-run after the fix; `at-214`'s printed numbers (`1 of 40`, `#8`) are unchanged, only the cosmetic bounds string improved.
- **Committed in:** `3469e73c` (Task 1 commit — fixed before the tracer verify block, not a separate commit)

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug, cosmetic display only — no numeric or classification impact).
**Impact on plan:** None on the measured numbers; improves the honesty/readability of the tool's own output for a window shape (`at-214`) that didn't exist in the 214 original.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required. `gh` was already authenticated (read-only calls only: `gh pr list`, `gh api pulls/<n>/files`, and `collect-ci-runs.sh`'s `gh run list` / `gh api actions/runs/<id>/jobs`).

## Next Phase Readiness

- The verdict is **CLOSE**, so per the plan's conditional-halt instruction (Task 3, step 5) execution proceeds to `222-02` — no `## CHECKPOINT REACHED` was returned, and no closure artifact (222-DECISION.md, SEED-006, REQUIREMENTS.md, PROJECT.md) was touched by this plan.
- `222-02` has everything it needs: the committed `raw/prs/` and `raw/ci/` snapshots, `remeasure-222.py`'s `minute-gate`/`ceiling`/`skip-saving` outputs (to cite verbatim), and `verify-phase.sh`'s 13 passing checks as the measurement-gate baseline it will extend with `--close`.
- No blockers or concerns.

## Self-Check: PASSED

- All key files verified present with `[ -f ]`.
- All four commits (`3469e73c`, `d6d26ccc`, `125a2586`, `c1fd04a3`) found in `git log --oneline --all`.
- All 13 `verify-phase.sh` checks re-run and passing.
- `bin/verify-repo-hygiene` passing (4221 tracked text files clean).
- `remeasure-222.py minute-gate --window 30d-now` re-run: `verdict: CLOSE` (unchanged).

---
*Phase: 222-seed-006-change-aware-lanes-conditional*
*Completed: 2026-09-29*
