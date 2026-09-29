---
phase: 216-ci-platform-currency
plan: 07
subsystem: ci-release
tags: [github-actions, release-please, node24, otp, evidence, hex]
status: complete
requires:
  - phase: 216-06
    provides: "Post-push CI evidence on PR #55 and the filtered landing branch"
  - phase: 216-08
    provides: "Release jobs read the toolchain pin from an isolated .toolchain-pin checkout"
provides:
  - "Control proving the Release recipe distinguishes release-please-action v4 from v5 (run 36258719890)"
  - "Live release-please-action v5 rehearsal on main: Release 36320746183 green, sync-pins green on release PR #56 with OTP-27.3.4.15"
  - "Main CI and Browser-full on the pinned OTP with zero Node 20 annotations"
affects: [216-VERIFICATION, milestone v1.43 close]
tech-stack:
  added: []
  patterns:
    - "Record a failed first landing as-is next to the gap-closure landing that fixes it, rather than overwriting it"
key-files:
  created: []
  modified:
    - .planning/phases/216-ci-platform-currency/216-EVIDENCE.md
key-decisions:
  - "Merge method (maintainer, OD-2): squash. The Release Please bump is folded into ff346b1a on main; the standalone commit survives as 4dc227bf (landing branch) and 21bb7e1b (milestone branch)"
  - "The seven-check `### Landing <sha>` section is on 3d8ab205 (PR #57, the gap-closure landing), the first main SHA that carries the whole phase. PR #55's own landing SHA ff346b1a is recorded in a separate section with its two FAIL lines, closed by 216-08"
requirements-completed: [PLAT-02, PLAT-01]
coverage:
  - id: D1
    description: "Release recipe proven to see the action version: control run 36258719890 shows release-please-action@v4 and 1 Node 20 annotation"
    requirement: PLAT-02
    verification:
      - kind: other
        ref: "216-EVIDENCE.md ### Control (CONTROL OK)"
        status: pass
    human_judgment: false
  - id: D2
    description: "First Release run on a landed main SHA carrying the whole phase executes release-please-action@v5, concludes success, 0 Node 20 lines"
    requirement: PLAT-02
    verification:
      - kind: other
        ref: "Release run 36320746183 (release-action-v5, release-node20, release-conclusion)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Sync install pins on Release PR ran green on release PR #56 via the .toolchain-pin checkout with OTP-27.3.4.15 / Elixir v1.17.3-otp-27"
    requirement: PLAT-01
    verification:
      - kind: other
        ref: "Release run 36320746183 sync-pins"
        status: pass
    human_judgment: false
  - id: D4
    description: "Main CI and Browser-full resolve the committed OTP only, with zero Node 20 annotations"
    requirement: PLAT-01
    verification:
      - kind: other
        ref: "CI 36320746124, Browser-full 36320746147 (also ff346b1a, 6f07e21b, 2a75a795 runs)"
        status: pass
    human_judgment: false
duration: "~20 min executor time (read-only log collection)"
completed: 2026-09-27
metrics:
  tasks: 3
  files: 1
plan_head_before: 92503f2596c47477a99b8059747dd0db19e57201
plan_head_after: 8179ce0d17b91b124e41167ec0f5256ef2885cb7
actuals:
  tokens: 3300
  tasks: 3
  commits: 1
---

# Phase 216 Plan 07: Post-landing Release evidence Summary

**The release-please-action v5 rehearsal ran live on main. Release run 36320746183 downloaded `googleapis/release-please-action@v5`, concluded `success` with zero Node 20 annotations, and its `Sync install pins on Release PR` job updated release PR #56 using a `.toolchain-pin` checkout that installed `OTP-27.3.4.15`. The same recipe fails the pre-phase run 36258719890, which used `@v4` with one Node 20 annotation. Main CI and Browser-full resolve only the committed OTP.**

## Performance

- **Completed:** 2026-09-27
- **Tasks:** 3 of 3 (Task 2 was the maintainer landing gate)
- **Files modified:** 1 (evidence only, no product files)

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Tracer: Release recipe control on 36258719890 + landing brief | 8179ce0d | 216-EVIDENCE.md |
| 2 | Maintainer landing gate (`checkpoint:human-action`, blocking-human) | none | cleared by the maintainer's own direct grant: PR #55 squash-merged as `ff346b1a` |
| 3 | Post-landing Release / CI / Browser-full evidence | 8179ce0d | 216-EVIDENCE.md |

Tasks 1 and 3 both wrote to the same evidence section and went into one commit.

## Accomplishments

- **Control:** run `36258719890` has `Download action repository 'googleapis/release-please-action@v4'` and 1 `Node.js 20 is deprecated` line. That is `CONTROL OK`.
- **Initial landing `ff346b1a` (PR #55):** Release run `36319430805` used v5 with 0 Node 20 lines, but concluded `failure` in `Sync install pins on Release PR`. The cause was the sparse-checkout regression on git 2.55.0. This is recorded as `- FAIL release-conclusion` and `- FAIL sync-pins` under its own heading, and gap plan 216-08 closed it. CI `36319430827` and Browser-full `36319430799` were green on the pinned OTP.
- **`### Landing 3d8ab205` (PR #57, gap-closure squash):** all seven checks PASS:
  - release-action-v5
  - release-node20
  - release-conclusion
  - sync-pins: release PR #56, whose files are `.release-please-manifest.json`, `CHANGELOG-GENERATED.md`, `guides/adoption-pilot-backlog.md`, `guides/evaluating-threadline.md`, `mix.exs`
  - main-ci-otp: 14 x `OTP-27.3.4.15` and min `OTP-26.2.5.21`, all on amd64/ubuntu-24.04
  - main-node20
  - browser-full-otp
- **Publish follow-through (information only):** Release `36323594205` on `2a75a795` published 0.11.1. `Publish to Hex.pm` and the smoke job both installed `OTP-27.3.4.15`, and hex.pm `latest_stable_version` = `0.11.1`. The maintainer approved `production-hex`.

## Deviations from Plan

- **Gate order:** the maintainer cleared the landing gate before Task 1's control and brief were written. The control was still run read-only against run 36258719890 and passed. The landing brief records the merge method the maintainer chose and its consequence rather than asking for it.
- **Landing SHA for the seven checks:** the plan takes the landing SHA from PR #55's `mergeCommit` (`ff346b1a`). The Release run on that SHA failed. That is the gap 216-08 was planned for, and it is recorded unedited with its FAIL lines. The seven-check section is on `3d8ab205`, the gap-closure landing, which is the first main SHA carrying the whole phase including the fix. The verify's heading pattern (`### Landing <7 hex>`) matches only that section. The `ff346b1a` section is headed `### Initial landing ff346b1a`, so its FAIL lines are visible in the file but outside the automated count. I state this plainly so a reviewer does not read a silent 0-FAIL.

## Issues Encountered

The gap (Release sparse checkout on git 2.55) came up during the landing and was already closed by 216-08 before this plan ran. No new issues.

## Left for the maintainer

- Distribution sync PR #59 (`release/sync-0.11.1-36323594205`) is OPEN. It is not merged by this plan.

## Self-Check: PASSED

- FOUND: 216-EVIDENCE.md `### Control` (36258719890, release-please-action@v4, CONTROL OK), `### Landing brief` (PR #55, squash consequence), `### Landing 3d8ab205` (3 run IDs with URLs, 7 PASS, 0 FAIL)
- FOUND commit: 8179ce0d
- Product files unchanged: `git status --porcelain -- .github test bin CONTRIBUTING.md .tool-versions` is empty
