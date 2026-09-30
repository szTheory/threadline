---
phase: 216-ci-platform-currency
plan: 06
subsystem: ci
tags: [github-actions, otp, ubuntu-24.04, lazy_html, node24, evidence]
status: complete
requires:
  - phase: 216-05
    provides: "Node 24 action allowlist, Release Please v5 bump, strict toolchain pins in every workflow"
provides:
  - "Negative control proving the post-push recipe fails the drifted pre-phase run 36258719902"
  - "Post-push CI evidence from PR #55 run 36318716184: seven checks PASS"
affects: [216-07, 216-VERIFICATION]
tech-stack:
  added: []
  patterns:
    - "Tracer-first evidence: run the exact grep recipe on a known-drifted run before trusting it on the new one"
    - "Job-scoped log checks: filter `gh run view --log` by the job name field before grepping for per-lane facts"
key-files:
  created: []
  modified:
    - .planning/phases/216-ci-platform-currency/216-EVIDENCE.md
    - .planning/phases/216-ci-platform-currency/deferred-items.md
key-decisions:
  - "Landing shape (maintainer, OD-2): filtered branch land/v1.43-215-216 with zero .planning/ paths; the Release Please bump kept its own one-line commit 4dc227bf there"
  - "Filtered-branch precondition checked through the head tree (release.yml:95 uses release-please-action@v5), as the plan allows, instead of ancestry of the milestone commit 21bb7e1b"
requirements-completed: [PLAT-01, PLAT-02, PLAT-03]
coverage:
  - id: D1
    description: "Evidence recipe proven non-vacuous on pre-phase run 36258719902 (OTP-27.0.1, 22.04 min image, 12 Node 20 lines, lazy_html 0.1.12)"
    requirement: PLAT-01
    verification:
      - kind: other
        ref: "216-EVIDENCE.md ## Pre-push negative controls (CONTROL OK)"
        status: pass
    human_judgment: false
  - id: D2
    description: "CI resolves the committed OTP everywhere: 14 x OTP-27.3.4.15 and min lane OTP-26.2.5.21, all built on amd64/ubuntu-24.04"
    requirement: PLAT-01
    verification:
      - kind: other
        ref: "run 36318716184 otp-pin / elixir-pin"
        status: pass
    human_judgment: false
  - id: D3
    description: "No Node 20 annotation on a real CI run"
    requirement: PLAT-02
    verification:
      - kind: other
        ref: "run 36318716184 node20 = 0"
        status: pass
    human_judgment: false
  - id: D4
    description: "Min lane on ubuntu-24.04 downloads lazy_html-nif-2.16-x86_64-linux-gnu-0.1.13 with zero source compiles"
    requirement: PLAT-03
    verification:
      - kind: other
        ref: "run 36318716184 min-image / nif-download / nif-no-source-compile"
        status: pass
    human_judgment: false
duration: "~70 min of executor time across two sessions (Task 1 dominated by the 35.5 min mix ci.all)"
completed: 2026-09-27
metrics:
  tasks: 3
  files: 2
plan_head_before: 2e27d9cda086fb2d634c612bb1918e937cd3a503
plan_head_after: 057ce8b508f98f144f43bf800d1131f2e4c22475
actuals:
  tokens: 4200
  tasks: 3
  commits: 11
  plan_commits: 2
---

# Phase 216 Plan 06: Post-push CI evidence Summary

**A real CI run (PR #55, run 36318716184) shows the committed OTP (27.3.4.15, min lane 26.2.5.21) on ubuntu-24.04 in every job, the min lane downloading lazy_html's 0.1.13 NIF 2.16 artifact with no source compile, and zero Node 20 annotations. The same recipe fails the pre-phase run 36258719902 on every one of those points.**

## Performance

- **Completed:** 2026-09-27
- **Tasks:** 3 of 3 (Task 2 was the maintainer gate)
- **Files modified:** 2 (evidence and deferred items only, no product files)

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Tracer: negative control on 36258719902, local gate, push brief, deferred items | 05c4447e | 216-EVIDENCE.md, deferred-items.md |
| 2 | Maintainer push gate (`checkpoint:human-action`, blocking-human) | none | cleared by the maintainer's own direct grant in-session |
| 3 | Post-push CI evidence on PR #55 | 057ce8b5 | 216-EVIDENCE.md |

## Accomplishments

- **Control (Task 1):** on run 36258719902 the recipe found `OTP-27.0.1` (12 jobs), a min lane built on `amd64/ubuntu-22.04` with `Image: ubuntu-22.04`, 12 `Node.js 20 is deprecated` lines, and lazy_html `0.1.12`. The recipe would fail that run on four checks. Local gate: `mix ci.all` exit 0 (2131 s), `mix test` 2317 tests, 0 failures, actionlint clean.
- **Push gate (Task 2):** the maintainer chose a filtered branch, `land/v1.43-215-216`: 29 commits, no `.planning/` paths. The Release Please bump stayed a standalone one-line commit there (`4dc227bf`). PR #55 was opened from it and landed later as squash `ff346b1a` (plan 07).
- **Post-push evidence (Task 3):** run `36318716184` on head `1b1e8299`, `pull_request`, 17/17 jobs success. All seven checks PASS:
  - otp-pin
  - elixir-pin
  - min-image
  - nif-download
  - nif-no-source-compile
  - node20
  - conclusion

  `OTP-27.0.1` count and `amd64/ubuntu-22.04` count are both 0. The cold-cache marker `THREADLINE_DIALYZER_PLT_CACHE=miss` appeared twice, as expected.

## Deviations from Plan

- **Precondition wording:** the precondition expects the reply "pushed: PR #N". The push was done by the maintainer-authorized orchestrator under the maintainer's own direct grant (PR #55, head `1b1e8299`). The filtered branch does not contain the milestone commit `21bb7e1b`, so the Task 2 acceptance was checked through the tree: `release-please-action@v5` at `release.yml:95`. The plan explicitly allows that alternative.
- **Commit count:** `plan_head_before..plan_head_after` measures 11 commits. Only 2 of them belong to this plan (`05c4447e`, `057ce8b5`). The other 9 are orchestrator tracking commits and the gap-closure plan 216-08, which ran between Task 2 and Task 3. `plan_commits: 2` is the figure to use for calibration.

## Issues Encountered

None in this plan. The post-landing sparse-checkout regression in Release (run 36319430805) belongs to plan 07's scope and was closed by gap plan 216-08.

## Next Phase Readiness

Plan 07 can use this plan's PR #55 evidence and the landing SHA `ff346b1a`.

## Self-Check: PASSED

- FOUND: .planning/phases/216-ci-platform-currency/216-EVIDENCE.md (`## Post-push CI evidence`, 7 PASS, 0 FAIL, run URL)
- FOUND: .planning/phases/216-ci-platform-currency/deferred-items.md (node-version-file, SHA-pin, flake-detection, cache_key_errors)
- FOUND commits: 05c4447e, 057ce8b5
- Product files unchanged: `git status --porcelain -- .github test bin CONTRIBUTING.md .tool-versions` is empty
