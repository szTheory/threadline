---
phase: 226-pure-property-tests-and-run-budget
plan: 06
subsystem: testing
tags: [evidence, ci-timing, flake-detection, run-budget, mutation-testing]

requires:
  - phase: 226-pure-property-tests-and-run-budget
    provides: "All seven mutation-control fragments and PropertyRuns/PROP-08 wiring from 226-01..226-05"
provides:
  - "226-EVIDENCE.md: SC-4 mutation controls for all four properties, SC-5 local + granted CI before/after, D-12 scale-5 Flake Detection re-derivation"
  - "test/threadline/flake_classifier_contract_test.exs Test 6 ceilings re-derived (346s cold / 295s per repeat) citing run 36888506162"
  - "Weekly Flake Detection repeat count dropped from 11 to 8 (mix.exs, flake-detection.yml, CONTRIBUTING.md, bin/classify-flake-run all mirrored)"
affects: []

actuals:
  tokens: 21000
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Single-run ci-job-timing.py invocations in place of --compare when only one post-change CI run exists: --compare's two-after-run design (built for phase 225, which had two after samples) exits INSUFFICIENT with exactly one after run, but single-run mode on each run id reads the identical per-lane Run-tests/proxy/cache-state figures, so a before/after table can still be built and cited without relaxing the tool's own gate."
    - "release_artifact_contract_test.exs scans mix.exs for packaged planning vocabulary (decision IDs like D-NN, phase-prefixed identifiers, certain requirement-ID prefixes) because mix.exs ships in the Hex package; a budget-arithmetic comment there must cite run ids and plain English, never a D-NN decision tag."

key-files:
  created: []
  modified:
    - .planning/phases/226-pure-property-tests-and-run-budget/226-EVIDENCE.md
    - test/threadline/flake_classifier_contract_test.exs
    - .github/workflows/flake-detection.yml
    - mix.exs
    - CONTRIBUTING.md
    - bin/classify-flake-run

key-decisions:
  - "The scale-5 measuring run (36888506162) was classified inconclusive by budget, not failure: 12 'Running ExUnit with seed:' headers were printed but only 11 'Finished in' lines appeared, because the 12th suite run (11th repeat) was still in progress when the 55-minute timeout(1) budget expired. Per the plan's own halt rule this only blocks on a non-pass verdict caused by a test failure; a budget-only inconclusive with every completed iteration green is exactly the sizing problem Task 3's own re-derivation step exists to fix, so sizing proceeded rather than halting."
  - "Confirmed the existing repeat-count convention before changing it: the run attempted 12 suite-run starts under the then-committed 11-repeat setting (1 initial + 11 repeats), matching mix.exs/CONTRIBUTING.md/the workflow comment's existing '11 repeats, 12 suite runs' wording, so 'N repeats' means the same thing (1 + N suite runs) everywhere this plan touches it; the new N=8 setting is applied with that same meaning."
  - "ci-job-timing.py's --compare mode requires at least two after runs and exits INSUFFICIENT with one; rather than relax or bypass that gate, used the tool's own single-run mode on both the before and after run ids and built the before/after table by hand from the two outputs, citing both invocations."

requirements-completed: []

coverage:
  - id: T1
    description: "226-EVIDENCE.md's CI subsection cites a before run (36820084560, the latest successful ci.yml run on milestone/v1.44 before 226's first commit) and an after run (36887218675, ci.yml on b4200f44), with a per-lane Run-tests/proxy/cache-state before/after table built from two ci-job-timing.py single-run invocations (documented reason --compare could not be used: it needs 2+ after runs and this phase only dispatched one)"
    requirement: null
    verification:
      - kind: other
        ref: "python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py 36820084560 --cache-state; python3 .../ci-job-timing.py 36887218675 --cache-state"
        status: pass
    human_judgment: false
  - id: T2
    description: "226-EVIDENCE.md's Flake Detection subsection cites run 36888506162, quotes its THREADLINE_PROPERTY_SCALE=5 banner, its classification (inconclusive by budget, 11/11 completed iterations green), and every Finished-in line"
    requirement: PROP-08
    verification:
      - kind: other
        ref: "gh run view 36888506162 --log (read-only)"
        status: pass
    human_judgment: false
  - id: T3
    description: "flake_classifier_contract_test.exs Test 6 ceilings re-derived to 346s/295s citing run 36888506162; mix.exs verify.flake repeat count dropped 11->8 (9 suite runs); the same count and run citation mirrored in the workflow budget comment, CONTRIBUTING.md and bin/classify-flake-run; the 55-minute timeout budget itself unchanged"
    requirement: PROP-08
    verification:
      - kind: unit
        ref: "mix test test/threadline/flake_classifier_contract_test.exs test/threadline/property_scale_contract_test.exs"
        status: pass
    human_judgment: false
  - id: T4
    description: "226-EVIDENCE.md passes check-citations.py and the whoami/home-path hygiene grep"
    requirement: null
    verification:
      - kind: unit
        ref: "python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/check-citations.py .planning/phases/226-pure-property-tests-and-run-budget/226-EVIDENCE.md"
        status: pass
    human_judgment: false
  - id: T5
    description: "Full repo gates clean after this plan: mix compile --warnings-as-errors, mix format --check-formatted, mix verify.credo, and the full mix test suite (28 properties, 2649 tests, 0 failures, 3 excluded)"
    requirement: null
    verification:
      - kind: unit
        ref: "mix test (full suite)"
        status: pass
      - kind: unit
        ref: "mix verify.credo"
        status: pass
    human_judgment: false

duration: ~1h
completed: 2026-10-01
status: complete
---

# Phase 226 Plan 6: Pure Property Tests and Run Budget — Evidence and D-12 Re-derivation Summary

**Fills 226-EVIDENCE.md's CI and Flake Detection sections with the maintainer-granted push and dispatch results (ci.yml runs 36820084560/36887218675, Flake Detection run 36888506162), and re-derives the weekly Flake Detection lane's sizing from that scale-5 run — repeat count drops from 11 to 8 so 346s cold / 295s per-repeat ceilings fit the unchanged 55-minute budget.**

## Performance

- **Duration:** ~1h (continuation session; Task 1 and the maintainer grant for Task 2 had already landed before this session; this session executed Task 3)
- **Completed:** 2026-10-01
- **Tasks:** Task 3 of 3 (Task 1 committed as `b4200f44`; Task 2's grant and its push/dispatches were executed by the orchestrator before this session started)
- **Files modified:** 6

## Accomplishments

- **CI before/after (D-23.3).** Before run `36820084560` (latest successful `ci.yml` run on `milestone/v1.44` before 226's first commit, `679544d5` at 12:06:47 UTC) and after run `36887218675` (`ci.yml` on `b4200f44`, success, all three lanes success) are cited in `226-EVIDENCE.md`. `ci-job-timing.py --compare` needs 2+ after runs and exits `INSUFFICIENT` with the one post-226 run this phase produced, so the before/after table is built from two single-run `ci-job-timing.py` invocations instead, documented inline as a deliberate deviation from the plan's literal `--compare` instruction, not a bypass of its gate.
- **Flake Detection at scale 5 (D-12).** Run `36888506162` is cited with its `THREADLINE_PROPERTY_SCALE=5: pure max_runs x5, DB x3` banner, its classification (`inconclusive (completed iterations: 12, exit: 124)` — the 55-minute `timeout(1)` budget expired mid the 12th suite run, `ELAPSED_S` 3300 = `BUDGET_S` 3300), and all 11 `Finished in` lines (cold 345.1s, repeats 286.8-293.5s). Every completed iteration reports `28 properties, 2649 tests, 0 failures, 3 excluded` — the inconclusive verdict is a budget expiry, not a test failure, so sizing re-derivation proceeded per the plan's own fallback guidance rather than halting.
- **D-12 re-derivation.** `flake_classifier_contract_test.exs` Test 6's `@cold_first_run_ceiling_s`/`@repeat_ceiling_s` are re-derived to 346/295 (345.1s/293.5s rounded up with a 1s margin), citing run `36888506162`. At the then-committed 11 repeats, 346 + 11 x 295 = 3,591s is well over the 2,970s usable budget (55 minutes less 10% headroom); 8 repeats fits at 2,706s (about 9% headroom; 9 repeats would be 3,001s, still over). The repeat count dropped from 11 to 8 in `mix.exs`'s `"verify.flake"` alias, with the same count and run citation mirrored in the workflow budget comment, `CONTRIBUTING.md` ("full suite, 8 repeats (fresh seed each)") and `bin/classify-flake-run`'s header comment — all four pinned together by Test 6. The 55-minute `timeout --signal=TERM --kill-after=60s 55m mix verify.flake` budget itself is unchanged, as required.
- **Confirmed the repeat-count convention before changing it.** The measuring run started 12 suite-run attempts under the then-committed 11-repeat setting (1 initial + 11 repeats), matching the existing "11 repeats, 12 suite runs" wording everywhere it appears, so the new 8-repeat setting (9 suite runs) carries the identical meaning.

## Task Commits

1. **Task 1: Local wall clock, weights check, SC-4 evidence assembly** — `b4200f44` (docs; landed in a prior session, cited here for continuity)
2. **Task 3: Dispatch citation, Test 6 re-derivation, evidence completion** — `2c51815a` (docs)

**Plan metadata:** pending (this commit)

## Files Created/Modified

- `.planning/phases/226-pure-property-tests-and-run-budget/226-EVIDENCE.md` — CI and Flake Detection subsections filled with cited run data, replacing the "pending (no grant)" placeholders
- `test/threadline/flake_classifier_contract_test.exs` — Test 6 ceilings (346/295), run citation (`36888506162`), comment rewording
- `.github/workflows/flake-detection.yml` — budget comment cites the new run/ceilings/arithmetic and `THREADLINE_PROPERTY_SCALE=5`; top-of-file "bounded 8-repeat" wording; 226-06 provenance paragraph added
- `mix.exs` — `"verify.flake"` repeat count 11 → 8, comment reworded to avoid packaged planning vocabulary (no `D-NN` decision tag, since `release_artifact_contract_test.exs` scans `mix.exs` for exactly that shape)
- `CONTRIBUTING.md` — "full suite, 8 repeats (fresh seed each)"
- `bin/classify-flake-run` — header comment repeat count 11 → 8

## Decisions Made

- Classified the scale-5 run's `inconclusive` verdict as a budget-sizing problem, not a halt condition, because every completed iteration was green; proceeded to re-derive sizing per the plan's documented fallback path instead of stopping and reporting.
- Used `ci-job-timing.py`'s single-run mode twice (once per run id) instead of `--compare`, since `--compare` requires 2+ after runs by design and this phase only produced one post-226 `ci.yml` run; documented the reason inline in the evidence doc rather than silently deviating from the plan's literal command.
- Removed the `D-12` decision-ID tag from the `mix.exs` comment (caught by `release_artifact_contract_test.exs`'s packaged-vocabulary scan, which inspects `mix.exs` because it ships in the Hex package) and reworded to plain English citing the run id instead — see Deviations below.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] mix.exs comment tripped `release_artifact_contract_test.exs`'s packaged-vocabulary scan**
- **Found during:** full `mix test` gate run after the first draft of the `mix.exs` comment
- **Issue:** The initial `verify.flake` comment included the decision tag `D-12` and phase/plan references, which `release_artifact_contract_test.exs`'s "all packaged source uses durable vocabulary" and "the entire readable archive is free of planning vocabulary" tests flag via a `@banned_shapes` regex (`\bD-\d{2,}\b` for decision IDs) applied to `mix.exs` and `lib/**/*.ex`, because `mix.exs` ships inside the built Hex package.
- **Fix:** Reworded the comment to cite the run id and plain English ("re-derived from dispatch run 36888506162 after a 5x property-run scale raised the per-run cost on this lane") with no decision tag.
- **Files modified:** `mix.exs`
- **Verification:** `mix test test/threadline/release_artifact_contract_test.exs` (19 tests, 0 failures); full `mix test` re-run afterward: 2649 tests, 0 failures.
- **Committed in:** `2c51815a` (the fix was made before the first commit of this task, so no separate fix commit was needed)

---

**Total deviations:** 1 auto-fixed (Rule 1 — a packaged-vocabulary regression caught by the plan's own full-suite gate before commit).
**Impact on plan:** None on scope; only the `mix.exs` comment's wording changed, no behavior change.

## Issues Encountered

None beyond the auto-fixed issue above. The `ci-job-timing.py --compare` INSUFFICIENT exit was anticipated during execution (not a surprise mid-task) once the single post-226 `ci.yml` run count became clear, and handled per the Decisions section above.

## User Setup Required

None — no external service configuration required. The push and both workflow dispatches this plan's evidence cites were already carried out by the orchestrator under the maintainer's grant before this session began.

## Next Phase Readiness

- SC-4 and SC-5 are both fully recorded in `226-EVIDENCE.md`: mutation controls for all four properties with kill rates, and local + granted CI wall-clock before/after.
- D-12's scale-5 re-derivation is complete: the weekly Flake Detection lane now runs 8 repeats (9 suite runs) at ceilings measured under `THREADLINE_PROPERTY_SCALE=5`, fitting the unchanged 55-minute budget with about 9% headroom.
- **Not yet closed:** a confirmation Flake Detection run at the new 8-repeat count has not been dispatched — `226-EVIDENCE.md` records this explicitly as "Confirmation run at the re-derived repeat count: pending (orchestrator dispatch)". Per this plan's instructions, `.planning/REQUIREMENTS.md` PROP-08 stays unchecked here; the orchestrator marks it complete once that confirmation run passes.
- Full `mix test` (2649 tests, 0 failures, 28 properties), `mix verify.credo`, `mix compile --warnings-as-errors`, and `mix format --check-formatted` are all clean repo-wide.
- No other blockers for closing phase 226 once the confirmation run is dispatched and cited.

---
*Phase: 226-pure-property-tests-and-run-budget*
*Completed: 2026-10-01*

## Self-Check: PASSED

All 6 modified files confirmed present on disk; both cited commits (`b4200f44`, `2c51815a`) confirmed in `git log --oneline --all`.
