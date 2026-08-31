---
phase: 198-green-bringup
plan: 05
subsystem: infra
tags: [github-actions, ci, playwright, caching, timeout-minutes, doc-contract, browser-lane]

# Dependency graph
requires:
  - phase: 198-03
    provides: "`ci-required` aggregate gate live in ci.yml with a twelve-entry needs list, plus the measured red-lane inventory and the explicit warning NOT to read the tracer's ~8 minutes as a re-measurement of the ~1h33m regression"
  - phase: 198-01
    provides: "The archived logs of run 28214113903 — the evidence that the Playwright job alone is essentially the entire ~1h33m wall clock"
provides:
  - "Bare `chromium` Playwright project deleted — 549 -> 368 test invocations (-33%), zero orphaned baselines, zero coverage loss"
  - "`maxFailures: process.env.CI ? 5 : 0` — a systemically broken browser suite aborts after 5 failures instead of burning ~382 x 120s timeouts"
  - "An `/audit` operator-surface preflight in run-e2e.sh, plus one `fail_with_log` mechanism shared by all three preflight failure paths"
  - "`if: failure()` diagnostic upload on the browser job — OBSERVED firing on a real run (run 33115615482)"
  - ".github/workflows/browser-full.yml with job id `verify-example-browser-full` — full project set on push-to-main + nightly, NOT a required check, with a deduplicated `ci-browser-full` tracking issue on failure"
  - "`## CI Coverage` table in CONTRIBUTING.md naming the four projects that stopped running on pull requests"
  - "test/threadline/ci_coverage_doc_contract_test.exs — plain contract test, teeth demonstrated red"
  - "timeout-minutes on 13/13 ci.yml jobs, 7/7 release.yml jobs, 1/1 browser-full.yml job, plus a 14-minute step bound inside the 18-minute browser job"
  - "Cache keys keyed on runner + OTP + Elixir + lockfile hash — distinct min/current keys OBSERVED on run 33115615482"
  - "A ci.yml header comment recording the no-trigger-level-path-filter decision, and a cache-block comment recording Phase 199's PLT key requirements"
affects: [198-06, 198-07, 199-dialyzer, 203-credo, 204-css-hash]

actuals:
  tokens: 31000
  tasks: 4
  commits: 4

tech-stack:
  added: ["actions/upload-artifact@v4 (first use in this repo)"]
  patterns:
    - "Reduced-PR-lane / full-post-merge-lane split, where the reduced lane keeps its job id AND its human-readable name byte-identical because GitHub matches required checks on name"
    - "Scheduled lanes report failures into ONE deduplicated tracking issue keyed on a title prefix plus a lane-specific label, because a schedule run notifies nobody"
    - "A doc-contract test that asserts a TABLE ROW exists, not merely a substring, so prose in the same section cannot launder a deleted row"

key-files:
  created:
    - .github/workflows/browser-full.yml
    - test/threadline/ci_coverage_doc_contract_test.exs
    - .planning/phases/198-green-bringup/198-05-SUMMARY.md
  modified:
    - .github/workflows/ci.yml
    - .github/workflows/release.yml
    - examples/threadline_phoenix/e2e/playwright.config.ts
    - examples/threadline_phoenix/e2e/run-e2e.sh
    - CONTRIBUTING.md

key-decisions:
  - "Sized the browser lane's 18-minute bound as a BUDGET, not a p95 multiple, and said so in the file — that lane has no observed green duration to size against"
  - "Did NOT invent a `_build` cache to satisfy D-19's no-restore-keys and purge rules; there is none in ci.yml today, so both rules were recorded in-file as binding on whoever adds one"
  - "Strengthened the doc contract from substring-in-section to table-row-match, because the section's own prose mentions project names and would have laundered a deleted row"
  - "Reworded three of my own comments rather than relaxing three mechanical acceptance greps (`retain-on-failure`, `--project`, the runner OS-family expression)"
  - "Verified on a dedicated dispatch branch `ci/198-05-verify` rather than pushing the shared staging branch, to avoid racing plan 198-04"

patterns-established:
  - "Step-level timeout strictly below the job-level timeout, so the step fails first and the failure-artifact upload still runs"
  - "Cache key contract stated once, in a comment above the first cache step, including the forward requirement for the next phase's cache"

requirements-completed: [GREEN-06, GREEN-07]

coverage:
  - id: D1
    description: "The bare `chromium` Playwright project is deleted, provably with zero orphaned baselines and zero coverage loss"
    requirement: GREEN-06
    verification:
      - kind: integration
        ref: "find examples/threadline_phoenix/e2e/tests -name '*-chromium.png' | grep -v -e '-desktop-chromium.png' -e '-mobile-chromium.png' returned NOTHING, run BEFORE the deletion"
        status: pass
      - kind: integration
        ref: "grep -c 'name: \"chromium\"' playwright.config.ts == 0; desktop-chromium == 1; mobile-chromium == 1"
        status: pass
      - kind: integration
        ref: "npx playwright test --list: 549 tests before, 368 after (-181, -33%)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A systemically broken browser suite aborts after 5 failures on CI while keeping trace retention and the boot log"
    requirement: GREEN-06
    verification:
      - kind: integration
        ref: "playwright.config.ts `maxFailures: process.env.CI ? 5 : 0`; grep -c 'retain-on-failure' == 1, unchanged from before the task"
        status: pass
      - kind: e2e
        ref: "run 33115615482 job 98669374595: the `if: failure()` upload step EXECUTED after the Playwright step (log line 20:56:53)"
        status: pass
    human_judgment: true
    rationale: "The abort-after-5 path itself has NOT been exercised on CI. The browser lane currently dies in `mix demo.seed` with `relation \"audit_transactions\" does not exist` — the pre-existing red baseline that plans 04/06 own — which is BEFORE Playwright starts. The mechanism is wired and its ordering is proven; its actual firing is unobserved and a verifier should not read the upload step's execution as proof that maxFailures works."
  - id: D3
    description: "The e2e boot preflight refuses to start if the operator surface is not mounted"
    requirement: GREEN-06
    verification:
      - kind: e2e
        ref: "test/threadline/e2e_preflight_contract_test.exs + examples/threadline_phoenix/e2e/run-e2e.sh"
        status: pass
      - kind: unit
        ref: "bash -n run-e2e.sh passes; `operator_surface_ready()` requests ${BASE_URL}/audit and `fail_with_log` exits 1 with tail -80 of the boot log"
        status: pass
    human_judgment: false
    rationale: "Static/syntactic verification only. The lane dies before phx.server boots, so this preflight has never run on CI. It also encodes a judgment call a human should check: /audit sits behind :operator_auth, so a 3xx redirect to login is treated as HEALTHY and only 4xx/5xx/no-response aborts. If a future auth change makes /audit return 200-with-empty-shell on a broken mount, this check would pass wrongly. Discharged by phase-199: the hole this entry named is closed. A 3xx now passes only when the Location header points at /users/log_in, and a 2xx only when the body carries the '.threadline-ui' shell and '#tl-main' - so the 200-with-empty-shell case this rationale predicted would 'pass wrongly' now fails. Guarded against re-weakening by a contract test."
  - id: D4
    description: "The pull-request browser job keeps its job id AND its human-readable name byte-identical, and stays inside the aggregate gate"
    requirement: GREEN-07
    verification:
      - kind: integration
        ref: "git diff HEAD~1 -- .github/workflows/ci.yml | grep '^-.*Example app browser E2E' returned empty; yq '.jobs[\"ci-required\"].needs' still contains verify-example-browser and has length 12"
        status: pass
      - kind: e2e
        ref: "run 33115615482 emitted a job named exactly `Example app browser E2E (Playwright)`"
        status: pass
    human_judgment: false
  - id: D5
    description: "A new non-required job id `verify-example-browser-full` runs the whole project set on push-to-main and nightly"
    requirement: GREEN-07
    verification:
      - kind: integration
        ref: "yq over browser-full.yml: job id verify-example-browser-full, on.push.branches == [main], on.schedule cron '0 5 * * *', workflow_dispatch present, no per-project flags on the run step"
        status: pass
      - kind: integration
        ref: "yq '.jobs[\"ci-required\"].needs | contains([\"verify-example-browser-full\"])' == false"
        status: pass
    human_judgment: true
    rationale: "The workflow has never executed — it triggers on push-to-main and a nightly schedule, and this phase deliberately has not pushed main. Its YAML shape is asserted; its runtime behaviour (including the gh issue create-or-update step, which needs a real failure and a real token) is entirely unobserved."
  - id: D6
    description: "CONTRIBUTING.md states verbatim which Playwright projects run where, guarded by a contract test with demonstrated teeth"
    requirement: GREEN-07
    verification:
      - kind: unit
        ref: "mix test test/threadline/ci_coverage_doc_contract_test.exs — 2 tests, 0 failures"
        status: pass
      - kind: unit
        ref: "Teeth demo: removing the `desktop-chromium` row turned the test RED naming `desktop-chromium` exactly; row restored, green again"
        status: pass
      - kind: integration
        ref: "grep -c 'ci_coverage_doc_contract' mix.exs == 0 — not wired into any verify.* alias"
        status: pass
    human_judgment: false
  - id: D7
    description: "Every job in ci.yml, release.yml and browser-full.yml carries a timeout-minutes bound"
    requirement: GREEN-06
    verification:
      - kind: integration
        ref: "yq job-count vs bounded-count: ci.yml 13/13, release.yml 7/7, browser-full.yml 1/1; grep -c 'timeout-minutes' ci.yml == 14 (13 job-level + 1 step-level)"
        status: pass
      - kind: integration
        ref: "verify-example-browser job bound 18, its Playwright step bound 14 (strictly less); verify-capture 35, verify-test 20, ci-required 5, browser-full 50; release.yml gate-ci-green 45 > its 60x30s = 30-minute poll window"
        status: pass
      - kind: e2e
        ref: "run 33115615482 executed with the bounds in place — no workflow parse error, all 14 jobs scheduled"
        status: pass
    human_judgment: true
    rationale: "The VALUES are a judgment call a maintainer should review, and one of them is weaker than the others: 18 for the browser lane is a D-16 budget, not a multiple of an observed green p95, because that lane has no observed green run (its only two recorded durations are 1h33m38s broken and ~2m fast-failing). No bound has been observed actually firing on a hang."
  - id: D8
    description: "The two matrix lanes no longer share one cache entry"
    requirement: GREEN-06
    verification:
      - kind: e2e
        ref: "run 33115615482 job 98669374716 (min) logged key `ubuntu-22.04-otp26-elixir1.15-mix-deps-e0c08af6...`; job 98669374524 (current) logged `ubuntu-24.04-otp27-elixir1.17.3-mix-deps-e0c08af6...` — distinct prefixes, same lockfile hash"
        status: pass
      - kind: integration
        ref: "grep -c 'runner.os' .github/workflows/ci.yml == 0 (also 0 case-insensitively)"
        status: pass
      - kind: integration
        ref: "yq '.on.push | has(\"paths\")' and '.on.pull_request | has(\"paths\")' both false"
        status: pass
    human_judgment: false

# Metrics
duration: 27 min
completed: 2026-08-27
status: complete
---

# Phase 198 Plan 05: CI Cost Surgery Summary

**The browser lane lost a third of its invocations to a provably redundant Chromium project, gained a five-failure abort with its traces intact and an `/audit` mount preflight, and split into a required reduced PR lane plus a non-required full main/nightly lane documented in CONTRIBUTING.md and asserted by a contract test with demonstrated teeth — while every job in three workflows gained a `timeout-minutes` bound and the min/current matrix lanes were observed, on a real run, finally caching under distinct keys.**

## Performance

- **Duration:** 27 min
- **Started:** 2026-08-27T20:39:00Z
- **Completed:** 2026-08-27T21:06:32Z
- **Tasks:** 4 of 4
- **Files created:** 2 (+ this summary); **modified:** 5

## Accomplishments

- **The 33% cut is the project deletion, not the split.** Deleting the bare `chromium` project took `npx playwright test --list` from **549 to 368** invocations. Verified BEFORE deleting, as the plan required: `find … -name '*-chromium.png' | grep -v -e '-desktop-chromium.png' -e '-mobile-chromium.png'` returned nothing, so no baseline was orphaned; and both snapshot-bearing specs already excluded the bare project by name (`operator-screenshot-regression.spec.ts:83`, `operator-stress.spec.ts:268`). Zero coverage loss, confirmed rather than assumed.
- **The cache-sharing bug is fixed and the fix was OBSERVED, not asserted.** On run `33115615482` the min lane logged key `ubuntu-22.04-otp26-elixir1.15-mix-deps-e0c08af6…` and the current lane `ubuntu-24.04-otp27-elixir1.17.3-mix-deps-e0c08af6…` — same lockfile hash, distinct prefixes. Before this change both resolved to `Linux-mix-deps-<hash>`, meaning the Elixir 1.15 floor lane could be verified against dependencies resolved for current. That is a false-green risk (T-198-05-01), not a speed problem.
- **Nothing is unbounded any more.** 13/13 jobs in `ci.yml`, 7/7 in `release.yml`, 1/1 in `browser-full.yml`. Confirmed alongside it that the concurrency rule cancels only `pull_request` runs (`cancel-in-progress: ${{ github.event_name == 'pull_request' }}`) — a push-to-main hang is exactly the case these bounds exist to stop, and concurrency does not stop it.
- **The diagnosis half of D-18 is proven wired.** On the real run the `if: failure()` upload step executed after the Playwright step and reported (correctly) that there were no files to collect, because the lane died earlier than Playwright. Ordering and condition are therefore observed, not merely written.
- **The doc contract has teeth, demonstrated.** Removing the `desktop-chromium` row from CONTRIBUTING.md turned the test red naming `desktop-chromium` exactly; the row was restored and the test went green.

## Task Commits

1. **Task 1: cut browser fan-out, abort early but diagnosably** — `914aed30` (perf)
2. **Task 2: split the browser lane, guard it with a doc contract** — `7cd0e203` (feat)
3. **Task 3: bound every job with `timeout-minutes`** — `7c358217` (ci)
4. **Task 4: recompose cache keys** — `d941ae10` (fix)

## Files Created/Modified

- `examples/threadline_phoenix/e2e/playwright.config.ts` — bare `chromium` project deleted; `maxFailures: process.env.CI ? 5 : 0` added
- `examples/threadline_phoenix/e2e/run-e2e.sh` — `operator_surface_ready()` preflight against `/audit`; one `fail_with_log` helper now used by all three preflight failure paths
- `.github/workflows/ci.yml` — reduced browser lane, failure-artifact upload, 13 job bounds + 1 step bound, recomposed cache keys, header comment on the no-path-filter decision, cache-block comment on the Phase 199 PLT key
- `.github/workflows/browser-full.yml` — NEW: `verify-example-browser-full`, full project set, push-to-main + nightly + dispatch, deduplicated tracking issue on failure
- `.github/workflows/release.yml` — 7 job bounds
- `CONTRIBUTING.md` — NEW `## CI Coverage` section
- `test/threadline/ci_coverage_doc_contract_test.exs` — NEW contract test

## Timeout budget: chosen value and the basis for each

Durations below are from run `33113148222` (the plan-03 tracer) unless stated. **Read the "basis" column carefully — most red lanes' durations are TRUNCATED by their own failure and are not p95s.**

| Workflow | Job id | Bound | Observed duration | Basis |
|---|---|---|---|---|
| ci.yml | `verify-format` | 10 | 0m18s (green) | ~33x a real green duration |
| ci.yml | `verify-credo` | 10 | 1m18s (green) | ~7.7x a real green duration |
| ci.yml | `verify-compile-no-optional` | 10 | 1m07s (**failed**, truncated) | D-16 fast-verify budget; no green sample exists |
| ci.yml | `verify-test` (both lanes) | 20 | 4m21s min / 4m10s current (**both failed**, truncated) | D-16 matrix budget; ~4.6x the truncated sample. No green sample exists — 83 failures on both lanes |
| ci.yml | `verify-hex-evaluator` | 15 | 0m57s (green) | ~15x a real green duration |
| ci.yml | `verify-example-browser` | 18 (+ 14 step) | 1h33m38s **broken** (run 28214113903); 2m04s fast-fail | **BUDGET, NOT p95.** No green run has ever been observed for this lane. 18 is a deliberate ceiling that will fail a regression back toward 1h33m rather than absorb it |
| ci.yml | `verify-mechanical` | 10 | 1m09s (**failed**, truncated) | D-16 fast-verify budget |
| ci.yml | `verify-capture` | 35 | 7m45s (**failed**, truncated) | D-16 capture budget; ~4.5x the truncated sample, and this lane regenerates 120 scorecards + 54 aria files against a real browser |
| ci.yml | `verify-pgbouncer-topology` | 20 | 1m51s (**failed**, truncated) | D-16 topology budget |
| ci.yml | `verify-docs` | 10 | 1m25s (green) | ~7x a real green duration |
| ci.yml | `verify-hex-package` | 10 | 0m15s (green) | ~40x a real green duration |
| ci.yml | `verify-release-shape` | 10 | 0m08s (green) | ~75x a real green duration |
| ci.yml | `ci-required` | 5 | 0m03s | Unchanged from plan 03 |
| release.yml | `release-please` | 10 | not observed | Single action invocation; generous |
| release.yml | `bootstrap-release-pr-ci` | 5 | not observed | One `gh workflow run` call |
| release.yml | `dispatch-bootstrap` | 10 | not observed | Fetch + tag + push |
| release.yml | `release-ref` | 5 | not observed | Pure output selection, no checkout |
| release.yml | `gate-ci-green` | 45 | not observed | **Sized above its own poll window by construction**: 60 attempts x 30s = 30 min. 45 leaves 15 min for checkout/API latency; the poll still self-fails at 30 |
| release.yml | `publish-hex` | 30 | not observed | deps.get + hex.build + publish + a 36x10s (6 min) Hex-index poll |
| release.yml | `distribution-sync` | 20 | not observed | A second 36x10s (6 min) registry poll, then a doc edit and PR |
| browser-full.yml | `verify-example-browser-full` | 50 (+ 45 step) | never run | D-16 full-lane budget |

## Coverage/time tradeoffs, stated explicitly

This plan is required not to downgrade any promise silently. Three things did change in what runs where, and none of them is free:

1. **Four Playwright projects stopped running on pull requests** — `storybook-capture`, `graded-capture`, `refute-capture`, `route-capture`. They now run only on push-to-main and nightly, in a lane that is **not a required check**. A pull request can therefore merge without them having run. This is stated verbatim in `CONTRIBUTING.md` and asserted by the contract test, and a nightly failure opens or updates a `ci-browser-full` tracking issue so it is not silent. **It is still a reduction in pre-merge coverage.**
2. **The bare `chromium` project was deleted, and this one IS free** — the claim was checked, not assumed. It carried no baselines and both snapshot-bearing specs skipped it by name, so it duplicated `desktop-chromium` at a different viewport with nothing asserting on that viewport.
3. **The split itself buys far less wall clock than the deletion.** The reduced PR lane lists **362** invocations against the full lane's **368** — only six fewer. Those six are the capture specs, which are individually expensive (each writes many screenshots), so the saving is in per-invocation cost, not invocation count. The honest headline is: **the deletion cut 33% of invocations; the split moved six expensive ones off the PR path.** Anyone reading this as "the split halved CI" would be wrong.

Two smaller notes in the same spirit:

- `tier-a-capture` and `tier-a-capture-light` still run on pull requests — not via the browser lane but via `verify-capture` (`mix verify.capture`). Removing them from the browser lane therefore deleted genuinely **duplicated** work rather than coverage. The CONTRIBUTING table says so per-row rather than implying the PR and full sets are disjoint.
- `desktop-chromium-light` is registered only under `THREADLINE_E2E_THEME=system` and is wired into **no** CI job at all, before or after this plan. The table says that plainly rather than omitting the row.

## Decisions Made

- **18 minutes is a budget, and the file says so.** Dressing it up as "a generous multiple of the observed p95" would have been a fabricated justification: the browser lane has no observed green duration. The in-file comment records both real data points (1h33m38s broken, 2m04s fast-fail) and states that 18 is a deliberate ceiling.
- **Did not invent a `_build` cache.** D-19 says the build cache gets no restore-keys and that `_build/$MIX_ENV/lib/threadline` must be purged before compiling. `ci.yml` has **no `_build` cache** — only `deps` and the Playwright browser download. Adding one, or adding a no-op `rm -rf` to nine jobs, would have been scope creep dressed as compliance. Both rules are recorded in the cache-block comment as binding on whoever adds one. The corresponding acceptance criteria are vacuously satisfied, and this summary says vacuously rather than leaving it to be misread as verified.
- **Strengthened the doc contract mid-task.** The first version asserted the project name appeared somewhere in the `## CI Coverage` section. But that section's own prose mentions `desktop-chromium` and `mobile-chromium`, so deleting a row would NOT have gone red. Changed to require a table row (`^\|\s*\`project\`\s*\|`). The teeth demo then failed correctly — which is the point of running the demo rather than assuming it.
- **Verified on a dedicated branch.** Pushed `ci/198-05-verify` and used `workflow_dispatch` rather than updating the shared `ci/v1_41-green-bringup` staging branch, because plan 198-04 is running concurrently and a shared-branch push would have raced it. The branch and run `33115615482` remain on origin as the evidence.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Three of my own comments tripped three mechanical acceptance greps**

- **Found during:** Tasks 1, 2 and 4 (caught pre-commit each time)
- **Issue:** (a) A comment mentioning `retain-on-failure` took `grep -c 'retain-on-failure'` from 1 to 2, breaking the "unchanged from before this task" criterion. (b) Two comments containing the literal `--project` were picked up by the doc-contract test's own derive regex, which then demanded a CONTRIBUTING row for a project named `restriction`. (c) Two comments explaining the cache bug quoted the forbidden runner OS-family expression, taking `grep -c 'runner.os'` from 0 to 2.
- **Fix:** Reworded all three comments. Same call plan 03 made: the criteria are real anti-regression greps, so the comment is what should move.
- **Verification:** `grep -c 'retain-on-failure'` -> 1; contract test 2 tests / 0 failures; `grep -c 'runner.os'` -> 0 (and 0 with `-i`).
- **Committed in:** `914aed30`, `7cd0e203`, `d941ae10`

**2. [Rule 2 - Missing critical] The doc contract as first written could be laundered by prose**

- **Found during:** Task 2, while running the mandated teeth demonstration
- **Issue:** Substring-in-section matching meant a deleted table row would still pass, because the section's prose names the same projects. The demo is what exposed this — an assertion that cannot fail is worse than no assertion.
- **Fix:** Assert a markdown table row via `~r/^\|\s*\`project\`\s*\|/m`.
- **Verification:** Row removed -> RED naming `desktop-chromium`; row restored -> green.
- **Committed in:** `7cd0e203`

**3. [Rule 3 - Blocking] No `node_modules` and no `deps` in the fresh worktree**

- **Found during:** Task 1 (`npx playwright test --list` failed) and Task 2 (`mix test` refused on missing deps)
- **Issue:** The worktree is a fresh checkout; the before/after invocation counts and the contract test both need real dependencies.
- **Fix:** `npm ci` in `examples/threadline_phoenix/e2e` and `mix deps.get` at the root. Both outputs are gitignored — `git status --short` was empty afterwards, confirmed before staging anything.
- **Verification:** 549/368/362 counts obtained; contract test runs.
- **Committed in:** n/a (no tracked file changed)

---

**Total deviations:** 3 auto-fixed (1 bug, 1 missing-critical, 1 blocking)
**Impact on plan:** No scope change. Deviation 2 strengthened a deliverable the plan asked for; deviations 1 and 3 were environment/self-inflicted friction caught before any commit landed.

## Issues Encountered

**The Task 1 mechanisms are wired but UNEXERCISED on CI, and this matters.** On run `33115615482` the browser lane died at `mix demo.seed` with `** (Postgrex.Error) ERROR 42P01 (undefined_table) relation "audit_transactions" does not exist` — the pre-existing un-migrated-CI-schema baseline that plans 04/06 own — which is **before** `phx.server` boots and long before Playwright starts. Consequently:

- `maxFailures: 5` has never fired.
- The `/audit` preflight has never run.
- The failure-artifact upload ran and correctly found nothing to upload, because no boot log and no `test-results` directory existed yet.

The ordering and the failure condition are therefore proven; the abort-and-diagnose behaviour is not. A verifier should not read "the upload step executed" as "the D-18 mechanism works end to end". Once plans 04/06 fix the CI test schema, the browser lane should be re-run and this gap closed.

**The ~1h33m regression is still not re-measured.** Run `33115615482` completed in **7m39s** wall clock (20:54:45Z -> 21:02:24Z), well inside the 20-minute ceiling — but six of thirteen lanes failed fast, exactly as plan 03 warned. **7m39s is not evidence that CI is now fast.** The only observed browser-lane durations remain 1h33m38s (broken) and ~2m (fast-fail). The 20-minute ceiling cannot be honestly claimed as met until a green run exists.

**`browser-full.yml` has never executed.** It triggers on push-to-main and a nightly schedule; this phase deliberately has not pushed main. Its YAML shape is asserted by `yq`, but its issue create-or-update step — including whether `gh label create` and the `--search "<prefix> in:title"` dedup behave as intended with `GITHUB_TOKEN` — is unobserved.

**The `ci-browser-full` label's "distinct from flake-detection" property is vacuous today.** `flake-detection.yml` currently has **no** issue-reporting step and therefore no label (that is D-35, plan 06's work). Distinctness holds by construction right now; **plan 06 must not reuse `ci-browser-full`** when it adds Flake Detection's dedup stream.

## Known Stubs

None. No hardcoded empty value, placeholder string, or unwired component was introduced.

## Threat Flags

None. No new network endpoint, auth path, or schema change. Two register notes:

- `T-198-05-04` (issue-writing token in the nightly workflow) is mitigated as planned: `browser-full.yml` grants `issues: write` at the **job** level over a workflow default of `contents: read`, rather than inheriting a broad default.
- `T-198-05-05` (failure-artifact upload may contain seeded demo data) remains **accepted** per the plan; the example app's seed data is synthetic and already public in this repository. `retention-days: 14` bounds how long it lingers.

## Verification (plan-level)

| Check | Result |
|---|---|
| Job count == bounded-job count in `ci.yml` / `release.yml` / `browser-full.yml` | PASS — 13/13, 7/7, 1/1 |
| `grep -c 'runner.os' .github/workflows/ci.yml` == 0 | PASS |
| `grep -c 'name: "chromium"' playwright.config.ts` == 0 | PASS |
| `mix test test/threadline/ci_coverage_doc_contract_test.exs` exits 0 | PASS — 2 tests, 0 failures |
| `verify-example-browser`'s name byte-identical, still in the aggregate's needs | PASS — no `-` line for the name in the diff; needs length 12, contains it |
| Latest run's wall clock vs the 20-minute ceiling | **7m39s — but a fast-failing run. NOT a valid measurement of the ceiling.** |

## Self-Check

- `.github/workflows/browser-full.yml` — FOUND
- `test/threadline/ci_coverage_doc_contract_test.exs` — FOUND
- `.github/workflows/ci.yml`, `.github/workflows/release.yml`, `CONTRIBUTING.md`, `playwright.config.ts`, `run-e2e.sh` — FOUND, all modified
- Commit `914aed30` — FOUND
- Commit `7cd0e203` — FOUND
- Commit `7c358217` — FOUND
- Commit `d941ae10` — FOUND
- `mix format --check-formatted` on the new test — PASS
- `mix credo --strict` on the new test — PASS, no issues
- `mix test test/threadline/ci_topology_contract_test.exs test/threadline/ci_coverage_doc_contract_test.exs` — PASS, 12 tests / 0 failures
- `grep -c 'ci_coverage_doc_contract' mix.exs` == 0 — PASS (mix.exs untouched; it is plan 198-04's file)
- No edits to plan 198-04's paths (`test/test_helper.exs`, `mix.exs`, `test/threadline/**` except the new contract test, `lib/threadline/operator_surface/live/*`) — PASS
- `.planning/STATE.md` / `.planning/ROADMAP.md` untouched — PASS

## Self-Check: PASSED

All four tasks executed; every acceptance criterion re-run and passing, with the vacuous ones (no `_build` cache) labelled vacuous rather than reported as verified.

## Next Phase Readiness

- **Plan 06** inherits two things: the `ci-browser-full` label name it must not collide with, and a browser lane whose fail-fast machinery cannot be validated until the un-migrated CI test schema is fixed.
- **Plan 07** (branch protection) is unaffected: `ci-required`'s `needs:` list is unchanged at twelve entries, the required name `CI required` is untouched, and `verify-example-browser-full` was deliberately kept out of it.
- **Phase 199** has a cache key shape to slot into unchanged, with its two extra requirements (`mix.exs` in the key, OTP in the key, restore-keys permitted) written into `ci.yml` next to the caches themselves rather than left in a planning document.

---
*Phase: 198-green-bringup*
*Completed: 2026-08-27*
