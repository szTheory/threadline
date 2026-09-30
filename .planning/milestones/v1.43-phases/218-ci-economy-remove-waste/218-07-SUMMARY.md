---
phase: 218-ci-economy-remove-waste
plan: 07
subsystem: ci
status: complete
tags: [ci, browser-full, playwright, econ-04, econ-02, contract-test]
requires:
  - phase: 218-02
    provides: "bin/upsert-ci-issue --close (title prefix + label match)"
  - phase: 218-05
    provides: "bin/ci-sha-gate (schedule-only green-SHA skip, fail open to run)"
  - phase: 218-06
    provides: "close-on-pass wiring + mutation-control idiom in flake-detection.yml"
provides:
  - "bin/browser-full-projects: derived CONFIG / CI / BROWSER-FULL Playwright project sets"
  - "Browser-full runs only the 4 projects ci.yml does not run, on push, nightly and dispatch"
  - "Browser-full nightly skips an already-green SHA; a green run closes the ci-browser-full tracking issue"
  - "partition contract (union == config, intersection empty) with mutation and comment controls"
affects: [218-08, 219, 221, 222]
tech-stack:
  added: []
  patterns:
    - "derived project partition via an #!/usr/bin/env elixir bin script, pinned by union/intersection contract"
    - "CI flags read only from comment-stripped run: bodies plus mix alias function bodies"
key-files:
  created:
    - bin/browser-full-projects
    - test/threadline/browser_full_projects_contract_test.exs
  modified:
    - .github/workflows/browser-full.yml
    - CONTRIBUTING.md
    - test/threadline/ci_coverage_doc_contract_test.exs
key-decisions:
  - "Browser-full runs the derived difference (graded/refute/route/storybook-capture) on every event, not only push: ci.yml already covers the other four on every push to main"
  - "bin/browser-full-projects is an elixir script that reads files only (no npx); the contract test runs it rather than re-parsing"
  - "The Browser-full gate has no --upstream: ci.yml's browser lanes are the ones this workflow no longer repeats"
requirements-completed: [ECON-04, ECON-02]
duration: 10 min
completed: 2026-09-27
commits: 3
plan_head_before: 2759e541a76fc78ff1e41d0e009a830d0986d4dd
plan_head_after: 9cfe06d4c9308f45066189160a94f04a762172df
actuals:
  tokens: 11400
  tasks: 2
  commits: 3
coverage:
  - deliverable: "bin/browser-full-projects derives the difference and partitions the config"
    human_judgment: false
    verification:
      - kind: test
        ref: "test/threadline/browser_full_projects_contract_test.exs"
        status: pass
      - kind: command
        ref: "bin/browser-full-projects prints exactly the four difference projects"
        status: pass
  - deliverable: "browser-full.yml runs the derived set, gates the nightly, closes the issue on green"
    human_judgment: false
    verification:
      - kind: test
        ref: "test/threadline/browser_full_projects_contract_test.exs#browser-full.yml wiring"
        status: pass
      - kind: command
        ref: "actionlint -shellcheck="
        status: pass
  - deliverable: "CONTRIBUTING ## CI Coverage states the partition truthfully"
    human_judgment: false
    verification:
      - kind: test
        ref: "test/threadline/ci_coverage_doc_contract_test.exs"
        status: pass
  - deliverable: "End-to-end: the derived set actually runs green on GitHub and #28 closes"
    human_judgment: true
    rationale: "Needs a real push/dispatch of browser-full.yml; that is the 218-08 dispatch, not runnable locally (no GitHub writes in this plan)"
---

# Phase 218 Plan 07: Browser-full Derived Project Partition Summary

**Browser-full now runs only the four Playwright projects ci.yml does not (graded, refute, route and storybook capture). The list is derived by `bin/browser-full-projects` and a contract test proves the two lanes partition the config. The nightly skips a SHA it already proved green through `bin/ci-sha-gate`, and a green run closes the `ci-browser-full` tracking issue.**

## Performance

- **Duration:** about 10 min wall clock (includes one 214 s full-suite run)
- **Completed:** 2026-09-27
- **Tasks:** 2 (Task 1 tracer with TDD RED and GREEN commits, Task 2 auto)
- **Files:** 2 created, 3 modified

## Accomplishments

- `bin/browser-full-projects` (`#!/usr/bin/env elixir`, mode 0755) derives three sets:
  - **CONFIG:** `name:` entries inside `const projects = [`, with the `...(lightLane ? [...] : [])` block cut out.
  - **CI:** `--project` flags from comment-stripped ci.yml `run:` bodies, plus the `--project=` flags in `verify_capture/1` behind `run: mix verify.capture`.
  - **BROWSER-FULL:** CONFIG minus CI.
  - It exits 1 on an empty config, an empty difference, or a `name:` in an unknown region, and exits 2 on usage errors or unreadable input. `THREADLINE_BROWSER_FULL_ROOT` overrides the root.
- Live output: `--project=graded-capture --project=refute-capture --project=route-capture --project=storybook-capture`. `--list ci` = desktop-chromium, mobile-chromium, tier-a-capture, tier-a-capture-light.
- `browser-full.yml`:
  - The run step captures the script output with plain command substitution under `set -euo pipefail`, refuses an empty array, prints a `::notice::`, and runs `mix verify.example_browser "${projects[@]}"`. The file has no literal `--project` flag.
  - `id: gate` runs `bin/ci-sha-gate --workflow browser-full.yml`, and all 7 heavy steps are gated on `run`.
  - The job has `actions: read`.
  - The close step runs `bin/upsert-ci-issue --close` with the same `TITLE_PREFIX`/`LABEL` as the failure step, under `if: success() && steps.gate.outputs.decision == 'run'`.
  - The header and the failure-issue body were rewritten.
- CONTRIBUTING `## CI Coverage` rewritten as a partition. The table's Nightly column is now "no" for the four ci.yml projects, and the old "overlap" sentence is gone.
- `ci_coverage_doc_contract_test.exs` derives its list from `bin/browser-full-projects --list config` and adds a lane check: each Browser-full row must name `verify-example-browser-full`, and no ci.yml row may.

## Task Commits

1. **Task 1 RED:** `2c723b0e` `test(218-07): add failing Browser-full project partition contract`
2. **Task 1 GREEN:** `87e5d6d2` `ci(218-07): Browser-full runs only the Playwright projects ci.yml does not`
3. **Task 2:** `9cfe06d4` `ci(218-07): skip the Browser-full nightly on an already-green SHA and close its issue on green`

## TDD Evidence

RED (`mix test test/threadline/browser_full_projects_contract_test.exs` before the script existed): `17 tests, 17 failures`. Sixteen failed on the assertion `bin/browser-full-projects is missing or not executable`. The seventeenth failed on `assert yaml =~ "bin/browser-full-projects"` (browser-full.yml did not reference the script yet). These are assertion failures, not load crashes: `run_script/2` asserts the script exists before it spawns anything, so there is no `:enoent` port error.

GREEN: after `87e5d6d2` the same file gave `17 tests, 0 failures`; after Task 2 it gives `19 tests, 0 failures`.

Non-vacuity check (not committed): I temporarily replaced run-body extraction with a raw-file scan. That failed 6 tests, including all three comment/name controls and the live `--list ci` test, so the controls do detect the failure they exist for.

## Named controls (acceptance criterion)

- Comment and name controls:
  - `a YAML comment naming a project leaves the output unchanged`
  - `shell comments inside run: bodies leave the output unchanged` (a whole-line `# e.g. --project=route-capture` in `run: |` bodies, plus a trailing ` # --project=storybook-capture` on a single-line `run:`)
  - `a name: value naming a project leaves the output unchanged`
- Mutation controls:
  - an added `canary-capture` project appears in the output
  - dropping `--project=mobile-chromium` moves it into the output
  - removing `run: mix verify.capture` moves both tier-a projects into the output
  - an empty `const projects = [];` exits non-zero
  - an empty difference exits non-zero
  - an orphan `name:` outside the parsed regions exits non-zero
- Wiring controls: a dropped `actions: read`, an ungated Playwright run step, and an `always()` close condition.

## CI Coverage section before and after

Before, the section contained this sentence (the only `overlap` hit in CONTRIBUTING.md):

> The pull-request set and the full set **overlap** — `desktop-chromium` and `mobile-chromium` run in both; the table is not a partition.

Before, the desktop, mobile and tier-a rows read `yes | yes | yes` plus `+ verify-example-browser-full`.

After, the section opens with "the split is a **partition**: every default-config Playwright project runs in exactly one lane". The four ci.yml rows read `**yes** | yes | no` and name only their ci.yml job. The four Browser-full rows read `no | yes | yes | verify-example-browser-full`. `grep -c overlap CONTRIBUTING.md` went from 1 to 0. The not-required-check paragraph, the tracking-issue paragraph (with a new close-on-green sentence) and the "deleted outright" `chromium` note are kept.

## Verification

- `actionlint -shellcheck=`: clean.
- `mix test test/threadline/browser_full_projects_contract_test.exs test/threadline/ci_coverage_doc_contract_test.exs test/threadline/ci_sha_gate_contract_test.exs test/threadline/ci_workflow_parity_contract_test.exs`: 66 tests, 0 failures.
- Full `mix test`: 9 properties, 2460 tests, 0 failures, 3 excluded.
- `mix verify.format`: clean. `mix verify.credo`: no issues.
- `bin/verify-repo-hygiene`: clean.
- Acceptance greps:
  - literal `--project` in browser-full.yml: 0
  - `bin/browser-full-projects`: 3
  - `bin/ci-sha-gate --workflow browser-full.yml`: 1
  - gate `if:`: 8
  - `upsert-ci-issue --close`: 1
  - `actions: read`: 1

## Deviations from Plan

**1. [TDD split] Task 1's five files landed in two commits, not one.**
- **Found during:** Task 1
- **Issue:** Task 1's acceptance criterion expects HEAD to contain all five files. The dispatch's TDD rule (hazard 9) requires a real RED commit first, so the new contract test was committed alone in `2c723b0e`.
- **Result:** The GREEN commit `87e5d6d2` holds the other four files. Together the two commits contain exactly the five planned files.
- **Commits:** `2c723b0e`, `87e5d6d2`

**2. [Rule 2 - Missing check] Added an orphan-`name:` control and two usage-exit tests.**
- **Issue:** The must_haves specify exit 1 for a `name:` in an unknown region and exit 2 for usage errors or unreadable input, but the plan's behavior list had no test for either.
- **Fix:** Added those tests to the contract test.
- **Commit:** `2c723b0e`

**3. [Rule 1 - Credo] `wiring_violations/1` was too complex (cyclomatic complexity 10 > 9).**
- **Fix:** Refactored it to use a `has_all?/2` helper before commit.
- **Commit:** `9cfe06d4`

**4. [Minor] Changed the Browser-full label description wording to "Failures of the Browser-full lane".** This drops the old "full-project-set" wording. It only takes effect when the label is created.

**5. [Minor] The job-permissions comment says "The actions read scope" rather than `actions: read`.** This keeps `grep -c 'actions: read'` at exactly 1.

**Total deviations:** 5, all small. None changes the plan's scope.

## Hand-offs

- **#28** ("Browser (full project set) is failing") and **#36** (flake) are still OPEN on GitHub. This plan makes no GitHub writes. #28 closes on the first green Browser-full run that actually runs (push to main or the 218-08 dispatch). #36 closes on the first `pass` Flake Detection run (218-06 wiring).
- ECON-02 is marked Complete here because its last caller (Browser-full) is now wired. The "resolved" half depends on those first green runs; see 218-08.
- The first real run of the derived set on GitHub is the 218-08 dispatch. No local browser run was made, as the plan requires.

## Known Stubs

None.

## Threat Flags

None. The new surface (`actions: read`, the Actions runs API) is already covered by T-218-09/T-218-12/T-218-13.

## Next Phase Readiness

Ready for 218-08 (ECON-07 re-measurement, phase gate, maintainer push checkpoint).

## Self-Check: PASSED

- FOUND: bin/browser-full-projects (executable)
- FOUND: test/threadline/browser_full_projects_contract_test.exs
- FOUND commits: 2c723b0e, 87e5d6d2, 9cfe06d4
