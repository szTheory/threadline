---
phase: 199-decouple
plan: "14"
subsystem: ci
tags: [dialyzer, github-actions, plt-cache, measurement, tdd]

requires:
  - phase: 199-decouple
    plan: "20"
    provides: "Green strict Dialyzer ratchet with zero ignores and full optional-app PLT coverage"
provides:
  - "One strict verify.dialyzer path shared by mix ci.all and the protected CI aggregate"
  - "Exact current-toolchain PLT restore/build/save/analyze lifecycle with fail-closed measurements"
  - "Authenticated immutable cold-miss and exact-key-hit cost evidence with a derived timeout"
affects: [199-21, ci-required, contributor-workflow]

tech-stack:
  added: []
  patterns:
    - "Separate actions/cache restore and save around conditional PLT construction"
    - "GNU time -v values normalized into stable machine-readable log fields"
    - "Immutable same-SHA push/dispatch evidence pair before deriving a CI timeout"

key-files:
  created:
    - .planning/phases/199-decouple/199-14-SUMMARY.md
  modified:
    - .github/workflows/ci.yml
    - mix.exs
    - CONTRIBUTING.md
    - test/threadline/ci_topology_contract_test.exs

key-decisions:
  - "Set verify-dialyzer timeout-minutes to 9: ceil(252-second measured cold whole-job time times 2.0 divided by 60), preserving 100% headroom."
  - "Treat only an exact actions/cache primary-key match as a hit; same-toolchain partial restores rebuild and re-save the PLT before analysis."
  - "Remove the temporary phase-branch push trigger immediately after collecting the authenticated miss/hit pair, restoring push execution to main only."

requirements-completed: [DECOUPLE-07, DECOUPLE-08]

coverage:
  - id: D1
    description: "Dialyzer is one unconditional blocking path through the local ci.all alias and protected ci-required aggregate."
    requirement: DECOUPLE-07
    verification:
      - kind: integration
        ref: "mix test test/threadline/ci_topology_contract_test.exs test/threadline/ci_coverage_doc_contract_test.exs test/threadline/dialyzer_ignore_contract_test.exs --max-failures 1 — 28 tests, 0 failures"
        status: pass
      - kind: integration
        ref: "mix dialyzer --no-check — Total errors: 0, Skipped: 0, Unnecessary Skips: 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "The exact runner/OTP/Elixir/config-keyed PLT lifecycle builds and saves before analysis on a miss and skips construction on an exact hit."
    requirement: DECOUPLE-08
    verification:
      - kind: e2e
        ref: "GitHub run 34642915672 job 103406722917 — cache miss, PLT saved before successful analysis"
        status: pass
      - kind: e2e
        ref: "GitHub run 34643744220 job 103410179816 — identical SHA/key exact hit, PLT build skipped, analysis successful"
        status: pass
    human_judgment: false
  - id: D3
    description: "Authenticated same-SHA cold/hit timings and peak RSS values are linked in contributor docs, and the CI timeout is derived from the cold whole-job duration."
    requirement: DECOUPLE-08
    verification:
      - kind: e2e
        ref: "Authenticated GitHub job logs for SHA a4f21e7e89ed4f958bc4ff0bb48c796225496bdd: cold PLT 152.82s/2282540 KiB, cold analysis 9.82s/1023056 KiB, hit analysis 9.42s/1009288 KiB"
        status: pass
      - kind: unit
        ref: "Threadline.CiTopologyContractTest mutation controls reject missing run provenance, marker drift, fabricated hit-path PLT values, and timeout drift"
        status: pass
    human_judgment: false

actuals:
  tokens: 6756
  tasks: 3
  commits: 3
plan_head_before: 7b545839a852f7c4de8bc521b0120633a209bb79

duration: 34min
completed: 2026-09-11
status: complete
---

# Phase 199 Plan 14: Blocking Dialyzer CI Gate and Measurement Summary

**A strict full-build Dialyzer path now blocks both `mix ci.all` and `ci-required`, backed by an exact-toolchain PLT cache and authenticated same-SHA cold/hit measurements that derive a nine-minute job timeout.**

## Performance

- **Duration:** 34 min
- **Started:** 2026-09-11T19:54:03Z
- **Completed:** 2026-09-11T20:27:57Z
- **Tasks:** 3
- **Files modified:** 4 implementation/contract files plus this summary

## Accomplishments

- Added `mix verify.dialyzer` to the local `ci.all` chain and a stable, unconditional `verify-dialyzer` current-toolchain job to `ci-required.needs`.
- Split PLT handling into exact-key restore, conditional measured build, pre-analysis save, and measured no-check analysis. Dependency fetch and compilation remain outside both analyzer timers, and malformed GNU time output fails closed.
- Proved a cold miss and exact-key hit at the identical immutable commit, recording linked run/job provenance, runner image/toolchain, dependency/config hash components, wall times, and peak RSS in `CONTRIBUTING.md`.
- Derived `timeout-minutes: 9` from the measured 252-second cold whole-job duration with a documented 2.0 headroom factor.
- Preserved Plan 199-20's strict zero-ignore Dialyzer result: zero errors, zero skipped warnings, and zero unnecessary filters.

## Task Commits

1. **Task 1 RED: Add failing Dialyzer CI topology tracer** — `2019d7db` (`test`)
2. **Task 1 GREEN: Wire blocking Dialyzer CI analyzer** — `a4f21e7e` (`feat`)
3. **Task 3: Seal measured Dialyzer CI evidence** — `1abed790` (`feat`)

Task 2 was the blocking maintainer action. The maintainer published exact SHA `a4f21e7e89ed4f958bc4ff0bb48c796225496bdd`; the supplied push run `34642915672` and workflow-dispatch run `34643744220` independently resolved to that SHA before Task 3 inspected their logs.

## Evidence

| Property | Cold miss | Exact-key hit |
|---|---|---|
| Workflow / event | `34642915672` / `push` | `34643744220` / `workflow_dispatch` |
| Dialyzer job | `103406722917` / success | `103410179816` / success |
| Commit | `a4f21e7e89ed4f958bc4ff0bb48c796225496bdd` | same |
| Runner image | `ubuntu-24.04` version `20260907.300.1` | same |
| Toolchain | OTP 27.0.1; Elixir 1.17.3 | same |
| Cache | exact key absent, then saved | exact primary key restored |
| PLT build | 152.82s; 2,282,540 KiB peak RSS | skipped; no fabricated values |
| Analysis | 9.82s; 1,023,056 KiB peak RSS | 9.42s; 1,009,288 KiB peak RSS |
| Whole job | 252s | 123s |

The primary key used identical `hashFiles` components in both runs: `mix.lock` = `f8275246d287e483bdc4bea1cc53781d9076e21403d44c887c3adfedaabbb53a`; `mix.exs` = `1025d27a2bd55968da5682d1654a62eff358df117b8d8a52e6c8ed034c0b7861`.

## Decisions Made

- Sized the job from whole-job cold elapsed time rather than only PLT and analysis subprocess time, so setup, dependency, and compilation variance are covered.
- Used a 2.0 headroom multiplier and whole-minute ceiling: `ceil(252 × 2 / 60) = 9`.
- Kept the no-optional compile lane independent; Dialyzer continues to analyze only the full optional build.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Added a temporary exact measurement-branch push trigger**

- **Found during:** Task 1 checkpoint preparation
- **Issue:** The pre-existing workflow triggered pushes only on `main`, so publishing the prepared phase branch could not create the plan-required push-event cold run.
- **Fix:** Contract-tested and temporarily enabled the exact prepared branch for `push`, then removed that trigger in Task 3 immediately after the immutable evidence pair was collected.
- **Files modified:** `.github/workflows/ci.yml`, `test/threadline/ci_topology_contract_test.exs`
- **Commit:** `a4f21e7e` (added), `1abed790` (removed)

**2. [Rule 1 - Bug] Corrected the tracer's workflow-header matcher**

- **Found during:** Task 1 GREEN verification
- **Issue:** The initial assertion assumed the job roster occupied the same line as the header label, while the established workflow contract uses the following comment line.
- **Fix:** Bound the regex to the actual two-line header without weakening the required `verify-dialyzer` assertion.
- **Files modified:** `test/threadline/ci_topology_contract_test.exs`
- **Commit:** `a4f21e7e`

**3. [Rule 3 - Blocking issue] Reconciled legacy Phase 199 roadmap/state position after the SDK skipped it**

- **Found during:** Plan closeout
- **Issue:** `roadmap.update-plan-progress 199` returned `missing_phase_details`, and `state.advance-plan` selected already-completed Plan 199-15 instead of the sole remaining Plan 199-21.
- **Fix:** Reconciled the summary-backed Phase 199 checklist/progress row to 20/21 and Current Position to Plan 21 while preserving the SDK-recorded metrics, decisions, and session timestamp.
- **Files modified:** `.planning/ROADMAP.md`, `.planning/STATE.md`
- **Commit:** final metadata commit

## Authentication Gates

- **Task 2:** A blocking-human checkpoint transferred only the prepared branch/SHA and exact commands. The maintainer supplied run IDs after publishing and dispatching; Task 3 used authenticated read-only GitHub inspection and never pushed, dispatched, requested credentials, or exposed secrets.

## Deferred Issues

- Cold workflow `34642915672` concluded failure because unrelated existing lanes remained red. Its formatting failure named only `test/threadline/main_ci_observer_contract_test.exs` and `test/threadline/e2e_preflight_contract_test.exs`, both already tracked under `199-01: Pre-existing repository-wide formatter drift` in `deferred-items.md`; neither is owned or changed by this plan. Plan-owned formatter checks pass.
- Other cold-run failures in pre-existing test/browser/capture paths are outside Plan 199-14. Both Dialyzer jobs completed successfully and provide the required isolated analyzer evidence.

## Known Stubs

None.

## Verification

- `actionlint .github/workflows/ci.yml` — pass
- `mix format --check-formatted mix.exs test/threadline/ci_topology_contract_test.exs` — pass
- `mix test test/threadline/ci_topology_contract_test.exs test/threadline/ci_coverage_doc_contract_test.exs test/threadline/dialyzer_ignore_contract_test.exs --max-failures 1` — 28 tests, 0 failures
- `mix dialyzer --no-check` — zero errors, skipped warnings, or unnecessary skips

## Self-Check: PASSED

- All four implementation/contract files and this summary exist.
- Task commits `2019d7db`, `a4f21e7e`, and `1abed790` resolve as Git commit objects.
- Summary frontmatter records `status: complete`, the persisted plan-head ledger, and the measured three-commit actual.
