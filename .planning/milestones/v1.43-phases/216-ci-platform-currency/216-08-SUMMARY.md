---
phase: 216-ci-platform-currency
plan: 08
subsystem: ci-release
tags: [ci, release, actions-checkout, sparse-checkout, toolchain, gap-closure]
status: complete
gap_closure: true
requires: ["216-03", "216-05"]
provides:
  - "Release jobs read the toolchain pin from an isolated .toolchain-pin checkout"
  - "Toolchain contract rejects a pathless pin checkout ahead of a ref-switching checkout"
affects: [".github/workflows/release.yml", "release PR #56 (0.11.1)"]
tech-stack:
  added: []
  patterns: ["isolated sparse checkout via path: before a workspace-root ref checkout"]
key-files:
  created: []
  modified:
    - .github/workflows/release.yml
    - test/threadline/ci_workflow_parity_contract_test.exs
    - .planning/phases/216-ci-platform-currency/216-EVIDENCE.md
decisions:
  - "Release jobs read the toolchain pin into path .toolchain-pin, and setup-beam reads .toolchain-pin/.tool-versions. The pin's sparse config never shares a repository with the workspace-root target-ref checkout."
  - "For each job, the file-form setup-beam contract accepts exactly one version-file: root .tool-versions, or <pin path>/.tool-versions when that job's sparse toolchain checkout declares that path"
requirements: [PLAT-01]
metrics:
  duration: ~12min
  completed: 2026-09-27
  tasks: 1
  files: 3
plan_head_before: 1061c0988041a08e32dca9ed9038ac285c1e23ef
actuals:
  tasks: 1
  commits: 2
---

# Phase 216 Plan 08: Release sparse checkout regression Summary

The three release jobs (`sync-release-pr-pins`, `publish-hex`, `smoke-published`) now read `.tool-versions` into `path: .toolchain-pin`, and setup-beam reads `.toolchain-pin/.tool-versions`. Before this fix, git 2.55 kept the sparse config of the pin checkout, so the workspace-root release-branch checkout held only `.tool-versions` (main Release run 36319430805). The toolchain contract now fails closed on that shape.

## What changed

- **release.yml:** each job has 3 `path: .toolchain-pin` lines and 3 `version-file: .toolchain-pin/.tool-versions` lines. The comment explains the isolation and that actions/checkout empties the root (which has no `.git`) before cloning. The target-ref checkouts, `persist-credentials: false`, permissions, concurrency, needs, if and secrets lines are unchanged. `git diff ff346b1a` shows no changed line of those kinds.
- **ci_workflow_parity_contract_test.exs:**
  - `toolchain_source_errors/3` gained `pin_isolation_errors/2`. A sparse pin checkout followed by a `ref:` checkout must declare a `path:` that differs from that checkout's path, and the next setup-beam must read `version-file: <pin>/.tool-versions`.
  - `setup_beam_errors/4` gets the job's pin dir, so every other workflow still needs root `.tool-versions`.
  - Two new mutation controls: (a) the pathless pin checkout with a root version-file (the run 36319430805 shape), and (b) a root version-file while the pin sits in `.toolchain-pin`.
  - A live-tree assertion checks that each ref-switching job carries `path: .toolchain-pin`.
- **release_control_plane_contract_test.exs:** no change needed. `sync-release-pr-pins` still has 2 checkouts and 2 `persist-credentials: false` flags, and the test passes.
- **216-EVIDENCE.md:** added `## Post-landing regression (sparse checkout)` with the failing run, the root cause, the git 2.55.0 Docker reproduction (before/after) and the fix.

## TDD evidence

RED: with the tightened contract applied and release.yml unchanged, the live-tree tests failed. `toolchain_source_errors` reported "toolchain checkout must declare a `path:` that differs from the later `ref:` checkout's path" for all 3 release jobs (2 tests failed, 23 ran). GREEN: after the release.yml edit, all 63 tests in the 4 contract files pass.

## Verification

- `actionlint -shellcheck=`: clean
- `mix test` on the parity, release_control_plane, ci_topology and ci_action_runtime contract files: 63 tests, 0 failures
- `mix verify.format`: clean. `mix verify.credo`: no issues
- Both grep counts are 3
- Full `mix test`: 9 properties, 2317 tests, 0 failures, 2 excluded

## Commits

- 9d19fcd6 fix(ci): read the release toolchain pin from its own checkout directory
- d8ce5786 docs(216-08): record the post-landing sparse checkout regression

## Deviations from Plan

None. The plan was executed as written. `release_control_plane_contract_test.exs` needed no edit because its count assertion was already correct.

## Self-Check: PASSED

- FOUND: .github/workflows/release.yml, test/threadline/ci_workflow_parity_contract_test.exs, 216-EVIDENCE.md (section present, 36319430805, git version 2.55.0)
- FOUND commits: 9d19fcd6, d8ce5786
