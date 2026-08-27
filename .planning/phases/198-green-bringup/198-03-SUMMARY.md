---
phase: 198-green-bringup
plan: 03
subsystem: infra
tags: [github-actions, ci, branch-protection, alls-green, matrix, pull-request, tracer]

# Dependency graph
requires:
  - phase: 198-02
    provides: "Credential audit verdict PROCEED, D-30 maintainer publication authorization, push protection verified — the gate that made this plan's first-ever push of the local commits legal"
provides:
  - "`ci-required` (name `CI required`) live in .github/workflows/ci.yml — the single aggregate required check, needs: exactly the twelve verify-* job ids"
  - "The first push of the local commit backlog to origin, on staging branch ci/v1_41-green-bringup (611 commits), with push protection NOT triggered"
  - "Pull request szTheory/threadline#27 open against main, gated by a real CI run"
  - "D-11 SETTLED BY OBSERVATION: GitHub appends the base-axis matrix value — emitted names are `Run test suite (min)` and `Run test suite (current)`"
  - "D-09 PROVEN ON A REAL RUN: `CI required` reported `failure` (not skipped, not stale-success) with six of twelve needed jobs red"
  - "D-21 min-lane rehearsal executed: min and current lanes fail IDENTICALLY (1382 tests / 83 failures each) — the Elixir 1.15 floor is not broken"
  - ".planning/audits/198-matrix-name-observation.md — the committed evidence artifact"
  - "A measured red-lane inventory for Plans 04-06: 6 of 13 jobs red, 7 green"
affects: [198-04, 198-05, 198-06, 198-07, 199-dialyzer, 203-credo, 204-css-hash]

actuals:
  tokens: 41000
  tasks: 3
  commits: 3

tech-stack:
  added: ["re-actors/alls-green@release/v1"]
  patterns:
    - "Single aggregate required check over enumerated per-job checks — durable identity moves from N emitted names to one job id"
    - "Platform behaviour that documentation cannot settle is OBSERVED on a real run and committed as an artifact, not assumed in a comment"

key-files:
  created:
    - .planning/audits/198-matrix-name-observation.md
    - .planning/phases/198-green-bringup/198-03-SUMMARY.md
  modified:
    - .github/workflows/ci.yml

key-decisions:
  - "Pushed the worktree branch to origin under the remote ref name ci/v1_41-green-bringup via an explicit refspec, instead of `git switch -c` — switching would have moved HEAD out of the mandatory agent-* namespace and tripped the pre-commit HEAD assertion"
  - "Left the ci.yml verify-test comment UNCHANGED because the observation confirmed it byte for byte; rewriting a correct comment would have been a fabricated correction"
  - "Reworded my own new ci.yml comment to stop it matching `grep -c 'contains(needs'`, rather than weakening the acceptance criterion to accommodate a comment"
  - "Recorded NO nightly-split proposal for Plan 05 — Task 3's fallback is conditioned on drift, and the min-lane failure is not drift"

patterns-established:
  - "Aggregate gate extension point: a new lane becomes blocking by joining ci-required's needs: list, with zero branch-protection edits"
  - "allowed-skips is documented in-file as the extension point for the first conditionally-skipped job, and deliberately absent while all needs run unconditionally"

requirements-completed: [GREEN-07, GREEN-08]

coverage:
  - id: D1
    description: "`ci-required` job wired into ci.yml with if: always(), timeout-minutes, alls-green, and needs: exactly the twelve existing verify-* job ids"
    requirement: GREEN-07
    verification:
      - kind: integration
        ref: "yq '.jobs[\"ci-required\"].needs | length' .github/workflows/ci.yml == 12; .name == 'CI required'; .if == 'always()'; .[\"timeout-minutes\"] == 5"
        status: pass
      - kind: integration
        ref: "grep -c 'contains(needs' .github/workflows/ci.yml == 0 (no hand-rolled result-string gate)"
        status: pass
      - kind: integration
        ref: "yq '.on.push | has(\"paths\")' and '.on.pull_request | has(\"paths\")' both false (D-10/D-20)"
        status: pass
    human_judgment: false
  - id: D2
    description: "No existing ci.yml job id renamed or removed — the stated CLAUDE.md id contract held"
    requirement: GREEN-07
    verification:
      - kind: integration
        ref: "git diff HEAD~1 -- .github/workflows/ci.yml | grep -E '^-  [a-z-]+:$' returns empty; yq '.jobs | keys | length' == 13 (12 + ci-required)"
        status: pass
    human_judgment: false
  - id: D3
    description: "A real pull request against main, from a real push of the local commit backlog, carrying a real CI run"
    requirement: GREEN-07
    verification:
      - kind: e2e
        ref: "gh pr view 27 --json number,baseRefName,headRefName,state => {27, main, ci/v1_41-green-bringup, OPEN}"
        status: pass
      - kind: e2e
        ref: "git push origin HEAD:refs/heads/ci/v1_41-green-bringup succeeded; push protection did not block (no D-29 Class A/B signal)"
        status: pass
    human_judgment: false
  - id: D4
    description: "`CI required` emitted by a real run on the pushed HEAD, and correctly RED on failing lanes"
    requirement: GREEN-07
    verification:
      - kind: e2e
        ref: "gh api repos/:owner/:repo/commits/009edbd9/check-runs => 2 check runs named exactly 'CI required', both conclusion=failure, check-run id 98663112338"
        status: pass
    human_judgment: false
  - id: D5
    description: "GREEN-08's 'verified after the matrix has reported once' satisfied by a committed observation of the emitted names"
    requirement: GREEN-08
    verification:
      - kind: e2e
        ref: "check-runs API on 009edbd9 emitted 'Run test suite (min)' and 'Run test suite (current)' verbatim; recorded in .planning/audits/198-matrix-name-observation.md with a stated ## Verdict"
        status: pass
    human_judgment: false
  - id: D6
    description: "Min lane rehearsed against origin before it can block a contributor PR (D-21), with its conclusion and cause classification recorded"
    requirement: GREEN-08
    verification:
      - kind: e2e
        ref: "workflow_dispatch run 33113172280; job 98661003718 'Run test suite (min)' conclusion=failure, 1382 tests / 83 failures; grep -c 'continue-on-error' ci.yml == 0"
        status: pass
    human_judgment: false
  - id: D7
    description: "Classification of the min-lane failure as a genuine code/test failure rather than runner-image or Playwright version drift"
    verification:
      - kind: e2e
        ref: "current lane (job 98661003731) reported the IDENTICAL '1382 tests, 83 failures, 1 excluded' — the min lane contributes zero additional failures"
        status: pass
    human_judgment: true
    rationale: "The differential evidence (min and current failing identically) is strong and mechanical, and it is what rules out toolchain drift. But 'is the Elixir 1.15 floor promise sound?' is ultimately a maintainer's judgment about what the 83 shared failures mean, and those failures are the milestone's pre-existing red baseline that Plans 04-06 have not yet triaged. A verifier should read the differential rather than accept the headline."
  - id: D8
    description: "Whether the aggregate gate goes GREEN when all twelve needed jobs succeed"
    verification: []
    human_judgment: true
    rationale: "NOT OBSERVED and not observable in this plan — six of twelve lanes are red, so the all-success path has never executed. The gate is proven red-on-failure only. Deliberately recorded as an open half rather than implied by the red-path proof; closing it is Plans 04-06's work."

# Metrics
duration: 17 min
completed: 2026-08-27
status: complete
---

# Phase 198 Plan 03: Aggregate Required Gate — Tracer Summary

**`ci-required` is live and reporting on a real pull request (#27) against `main`: the twelve `verify-*` jobs collapse into one `CI required` check that went correctly RED on six failing lanes, GitHub was observed appending the matrix axis (`Run test suite (min)` / `(current)`), and the never-before-executed Elixir 1.15 min lane turned out to fail identically to current — so the floor promise is sound.**

## Performance

- **Duration:** 17 min (20:20Z → 20:37Z), including ~8 min of wall-clock waiting on the CI run
- **Started:** 2026-08-27T20:20:00Z
- **Completed:** 2026-08-27T20:37:17Z
- **Tasks:** 3 of 3
- **Files created:** 2; **modified:** 1

## Accomplishments

- **The tracer path is proven end to end.** YAML edit → commit → first-ever push of 611 local commits → pull request → real GitHub Actions run → check-runs API → committed evidence artifact. Every layer this phase touches was exercised on one thin slice, in one pass, with no architectural dead-end found.
- **`ci-required` went RED, which is the payload.** A gate that has only ever been seen green is an unproven gate. With six of twelve needed jobs failing, `CI required` (check-run `98663112338`) completed with conclusion `failure` — **not** `skipped`, **not** a stale success. That is exactly the D-09 behavior `if: always()` plus `jobs: ${{ toJSON(needs) }}` exists to produce, and exactly what a hand-rolled result-string gate would have gotten wrong.
- **D-11 settled by observation, not assumption.** GitHub emitted `Run test suite (min)` and `Run test suite (current)`. The base-axis value appends; the `include:`-only keys (`elixir`/`otp`/`pg`/`runner`) do **not**. RESEARCH A2 was flagged unverified because no authoritative doc covers the base-axis-plus-`include` shape; it is now observed on this repo's own matrix.
- **The min lane's first-ever execution against origin retired the milestone's highest-variance risk.** The ROADMAP carried "min has never run" as the top risk on the theory that the Elixir 1.15 floor might be quietly broken. It is not: **min and current reported the identical `1382 tests, 83 failures, 1 excluded`.** The min lane adds **zero** failures. The 83 are the shared pre-existing red baseline v1.41 exists to retire.
- **The push went through clean.** 611 commits, first publication of `.planning/` history, and push protection did **not** block — no D-29 Class A/B signal to disposition.
- **Plans 04-06 got a measured red-lane inventory** instead of a guess (below).

## Task Commits

1. **Task 1 (tracer): aggregate gate through every layer** — `009edbd9` (ci)
2. **Task 2: record emitted matrix check names** — `b3f1e598` (docs)
3. **Task 3: min-lane rehearsal result** — `c10ba6f2` (docs)

## Files Created/Modified

- `.github/workflows/ci.yml` — added the `ci-required` job (12 `needs:`, `if: always()`, `timeout-minutes: 5`, alls-green with `toJSON(needs)`, an in-file `allowed-skips` extension-point comment) and extended the header job-id contract to name `ci-required` as the single required check
- `.planning/audits/198-matrix-name-observation.md` — provenance, verbatim emitted-name JSON, `## The verify-test matrix`, `## Verdict`, the non-deadlock argument, `## Min-lane rehearsal`, and the aggregate gate's observed red behaviour

## Measured red-lane inventory (hand-off to Plans 04-06)

From run `33113148222` on `009edbd9` — **7 green, 6 red**:

| Job | Conclusion |
|---|---|
| Check formatting | success |
| Run Credo (strict) | success |
| Hex evaluator smoke | success |
| Hex package tarball | success |
| Build ExDoc (dev) | success |
| Release metadata (version / changelog) | success |
| **Compile without optional deps** | **failure** |
| **Run test suite (min)** | **failure** (1382 tests / 83 failures) |
| **Run test suite (current)** | **failure** (1382 tests / 83 failures) |
| **Example app browser E2E (Playwright)** | **failure** |
| **Mechanical checker (committed scorecards)** | **failure** |
| **PgBouncer transaction topology** | **failure** |
| **Tier A capture lane (byte-stable evidence)** | **failure** |

The dominant test-failure signature is `** (Postgrex.Error) ERROR 42P01 (undefined_table) relation "audit_transactions" does not exist` — an un-migrated CI test schema, not 83 independent bugs. Plans 04-06 should test that hypothesis before triaging failures individually.

One timing note worth carrying forward: **the whole run completed in about 8 minutes**, not the ~1h33m the milestone context records. The lanes that historically dominated that wall clock failed fast here, so the 1h33m figure has not been reproduced and should not be treated as re-measured.

## Decisions Made

- **Pushed via an explicit refspec rather than `git switch -c`.** See deviation 1.
- **Left the `ci.yml` `verify-test` comment unchanged.** Task 2 instructs a reconcile-if-contradicted. The observation *confirmed* the comment byte for byte, so editing it would have manufactured a correction. What changed is its epistemic status — flagged-unverified → observed — and that now lives in the artifact rather than being asserted in a comment.
- **Reworded my own new comment rather than relaxing an acceptance criterion.** My explanatory comment quoted the forbidden idiom, which made `grep -c 'contains(needs'` return 1. The criterion is a real anti-regression grep; the right fix was to stop the comment matching it, not to argue the criterion should tolerate comments.
- **Handed Plan 05 nothing.** Task 3's fallback proposal (browser lanes → nightly) is gated on an "if and only if" drift diagnosis. The failure is not drift, so no proposal was recorded. Handing Plan 05 a drift-mitigation for a non-drift failure would have been a fabricated premise.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Pushed the worktree branch by refspec instead of `git switch -c ci/v1_41-green-bringup`**
- **Found during:** Task 1, Step 2
- **Issue:** The plan says `git switch -c ci/v1_41-green-bringup`. This executor runs inside a git worktree under a **mandatory, fail-closed** HEAD assertion: HEAD must stay on an `agent-*` / `worktree-agent-*` branch, re-checked before every commit. Switching to `ci/v1_41-green-bringup` would have moved HEAD out of that namespace and made every subsequent task commit refuse to run.
- **Fix:** `git push origin HEAD:refs/heads/ci/v1_41-green-bringup`. The remote ref name, the branch the PR is opened from, and the pushed content are all exactly what the plan specifies; only the local HEAD's name differs.
- **Verification:** `gh pr view 27` → `headRefName: ci/v1_41-green-bringup`, `baseRefName: main`, `state: OPEN`; CI ran on the branch and `CI required` reported.
- **Committed in:** n/a (no file change — a procedural substitution)
- **Note for the orchestrator:** the worktree branch is the same content, so the merge-back is unaffected. But `ci/v1_41-green-bringup` on origin currently points at `009edbd9` (Task 1 only) — the two docs commits are local until pushed.

**2. [Rule 1 - Bug] My own ci.yml comment tripped the plan's anti-regression grep**
- **Found during:** Task 1, pre-commit verification
- **Issue:** The comment explaining *why not* to use the hand-rolled idiom quoted it literally, so `grep -c 'contains(needs' .github/workflows/ci.yml` returned `1` instead of the required `0`. Caught before the commit, so no bad commit exists.
- **Fix:** Reworded to "a hand-rolled result-string containment expression over the needs results".
- **Verification:** `grep -c 'contains(needs'` → `0`.
- **Committed in:** `009edbd9`

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug)
**Impact on plan:** Neither changes scope or outcome. Deviation 1 is a procedural substitution forced by the execution environment, not a design change. Deviation 2 was caught pre-commit.

## Issues Encountered

**The plan's slow-CI warning did not materialise, and that is itself a finding.** The prompt warned CI had previously taken ~1h33m and to poll with a bounded timeout. The run completed in ~8 minutes because the historically expensive lanes failed fast. The bounded poll was used anyway and was not needed. **The 1h33m regression has therefore NOT been re-measured or reproduced by this plan** — it is untouched, not resolved, and Plan 05 should not read this fast run as evidence about it.

**Six lanes are red.** This is expected and explicitly in scope per the plan ("individual verify-* jobs may be red at this point"). The tracer proves the aggregate reports correctly; lane greenness is Plans 04-06.

## Threat Flags

None. No new network endpoint, auth path, file-access pattern, or schema change was introduced. `T-198-03-02` (the moving `@release/v1` tag on `alls-green`, disposition **accept**) is unchanged and remains an accepted risk with SHA-pinning recorded as a follow-up, not silently dropped.

## Push / scope compliance

| Constraint | Status |
|---|---|
| `origin/main` still `67998e0b` | **YES** — unchanged |
| `git log origin/main..main` non-empty | **YES** — 611 commits ahead |
| PR merged? | **NO** — #27 is `OPEN` |
| Tags or releases created? | **NO** |
| Pushed to `main`? | **NO** — only `refs/heads/ci/v1_41-green-bringup` |
| Push protection bypass used? | **NO** — push was never blocked |
| Existing job id renamed? | **NO** — `git diff` shows zero removed job keys |
| STATE.md / ROADMAP.md touched? | **NO** |

## Next Phase Readiness

**Plans 04-06 are unblocked** with a measured red-lane inventory and a leading hypothesis (un-migrated CI test schema) rather than a guess.

**Plan 07 (branch protection) is unblocked on its key precondition:** `CI required` has now genuinely been *emitted* on a real run, not merely configured — which is precisely what `bin/verify-branch-protection` must assert (T-198-03-05). The exact byte-for-byte required-check name to configure is **`CI required`**.

**Two honest gaps carried forward, neither resolvable here:**

1. **The gate has only been proven RED.** The all-green path has never executed because six lanes are failing. `CI required` must be observed green at least once before branch protection points at it, or protection would be armed on a half-proven gate.
2. **The ~1h33m CI regression is untouched.** This run's ~8 minutes is not a re-measurement — it is a fast-failing run.

## Self-Check

- `.github/workflows/ci.yml` — FOUND, `ci-required` present
- `.planning/audits/198-matrix-name-observation.md` — FOUND
- Commit `009edbd9` — FOUND
- Commit `b3f1e598` — FOUND
- Commit `c10ba6f2` — FOUND
- `yq '.jobs["ci-required"].needs | length'` → `12` — PASS
- `ci-required` name/`if`/`timeout-minutes` → `CI required` / `always()` / `5` — PASS
- `grep -c 'contains(needs'` → `0` — PASS
- `yq '.on.push | has("paths")'` / `.on.pull_request` → `false` / `false` — PASS
- `grep -c 'continue-on-error'` → `0` — PASS
- No removed/renamed job key in the Task 1 diff — PASS
- Header comment includes literal `ci-required` — PASS
- `gh pr view 27` resolves, OPEN, `main` ← `ci/v1_41-green-bringup` — PASS
- check-runs on `009edbd9` named exactly `CI required` → count `2` — PASS
- Artifact has `## Verdict` and `## Min-lane rehearsal`, and contains `Run test suite` — PASS
- Task 3 diff lists only the audit artifact — PASS
- `origin/main` = `67998e0b`, unchanged — PASS
- STATE.md / ROADMAP.md untouched — PASS

## Self-Check: PASSED

All three tasks executed, every acceptance criterion and plan-level verification re-run and passing.

---
*Phase: 198-green-bringup*
*Completed: 2026-08-27*
