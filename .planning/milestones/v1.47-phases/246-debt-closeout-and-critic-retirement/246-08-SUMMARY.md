---
phase: 246-debt-closeout-and-critic-retirement
plan: 08
subsystem: ci-docs
tags: [gap-closure, doc-contract, browser-full, removal-slice]
status: complete
requires:
  - "246-VERIFICATION.md gap 1 (review WR-01, IN-02)"
provides:
  - "spec-derived Browser-full coverage wording contract (Threadline.CiCoverageDocContractTest)"
  - "removal slice C7 (f57237d6) in the 246-LANDING.md cherry-pick recipe"
affects:
  - "Phase 247 CI measurement baseline (CONTRIBUTING.md ## CI Coverage)"
tech-stack:
  added: []
  patterns:
    - "doc phrase derived from source (const ROUTES count + const BREAKPOINTS), exact count match with digit lookarounds"
key-files:
  created: []
  modified:
    - test/threadline/ci_coverage_doc_contract_test.exs
    - CONTRIBUTING.md
    - .github/workflows/browser-full.yml
    - examples/threadline_phoenix/e2e/playwright.config.ts
    - test/threadline/ci_workflow_parity_contract_test.exs
    - .planning/phases/246-debt-closeout-and-critic-retirement/246-LANDING.md
    - .planning/phases/246-debt-closeout-and-critic-retirement/246-REVIEW-DISPOSITION.md
decisions:
  - "Browser-full coverage prose is pinned to a phrase derived from operator-page-capture.spec.ts (today `6 curated operator routes at 1280`) plus `only in evidence mode`; both WR-01 false claims are refused"
  - "C7 travels with C3a in the removal squash so main never carries the false Browser-full description"
requirements: [DEBT-02]
metrics:
  duration: "~4 min"
  completed: 2026-10-25
estimate:
  tokens: 60000
  tasks: 2
actuals:
  tokens: 9000
  tasks: 2
  commits: 2
plan_head_before: d8b8422feb123ff7a948f86c7d864d68a936a53d
plan_head_after: 9cfe8b16
---

# Phase 246 Plan 08: Honest Browser-full coverage wording (slice C7) Summary

CONTRIBUTING.md, the browser-full.yml header comment and the playwright.config.ts comment now say what Browser-full actually runs: a render smoke over the 6 curated operator routes at 1280. The inventory-wide 1280/768/375 route tests run only in evidence mode, which Browser-full never turns on. A contract test derives that wording from the spec and enforces it. The job display name was also fixed (IN-02). The change landed as removal slice C7.

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Tracer: spec-derived wording contract, three rewordings, job display rename (C7) | f57237d6 | ci_coverage_doc_contract_test.exs, CONTRIBUTING.md, browser-full.yml, playwright.config.ts, ci_workflow_parity_contract_test.exs |
| 2 | Record C7 in landing hand-off; WR-01/IN-02 fixed | 9cfe8b16 | 246-LANDING.md, 246-REVIEW-DISPOSITION.md |

## TDD Gate Compliance

- RED: the new live-tree test failed on all three sources before any prose edit. Run result: 6 tests, 1 failure, with 9 errors. Each source lacked the derived phrase and `only in evidence mode`. CONTRIBUTING.md also contained both false claims, and browser-full.yml contained `every inventoried route`. The derive test and the negative-control test passed at RED.
- GREEN: after the rewording the five targeted contract files ran 121 tests with 0 failures.
- The RED and GREEN steps share one commit because the slice must be a single green commit (D-10). No separate `test:` commit was made.

## Verification

- `mix test` on ci_coverage_doc, ci_workflow_parity, browser_journey_evidence, browser_full_projects and ci_topology contract tests: 121 tests, 0 failures.
- `mix format --check-formatted`, `bin/verify-repo-hygiene` and `mix verify.credo` were all clean, and `verify.credo` exited 0.
- `verify-phase.sh --close` printed `verify-phase: all checks passed`. It ran before the C7 commit and again after Task 2.
- Tracer gate: `<verify>` was re-run end-to-end before committing and passed.
- Acceptance greps:
  - `every inventoried route`: 0/0/0.
  - `at three viewports` (newline-joined CONTRIBUTING): 0.
  - `(all projects)`: 0.
  - The new `name:` line: 1, and the job id line is unchanged: 1.
  - The evidence env-var name in browser-full.yml: 0.
  - `only in evidence mode`: 1 in CONTRIBUTING and 1 in playwright.config.
- Slices: the trailer grep finds 8 Removal-Slice commits, and each touches 0 `.planning/` paths. C7 lists exactly the 5 task files and does not touch operator-page-capture.spec.ts.
- LANDING:
  - The path-set loop, re-run in bash, gives 528 paths (479 deletions, 49 modified or added). `ci_coverage_doc_contract_test.exs` was added in sorted position.
  - The cherry-pick line ends with `f57237d6`.
  - `| 8 | C7 |` appears 1 time.
- DISPOSITION: WR-01 and IN-02 are `fixed` (f57237d6). `disposition: open` appears 8 times, and the frontmatter count is now `open: 8`.

## Deviations from Plan

**1. [Rule 1 - Bug] Credo flagged `Enum.map |> Enum.join` in the new `prose/1`**
- Found during: Task 1 verification. It was changed to `Enum.map_join/3` before the commit.

**2. [Rule 2 - Correctness] Exact-count phrase matching**
- The phrase check uses digit lookarounds, so `16 curated ...` and `... at 1280/768` cannot satisfy `6 ... at 1280`. A padded-count negative control was added next to the plan's count+1 control.

**3. [Rule 1 - Stale count] Other LANDING counts updated alongside the planned ones**
- The archive tag message's `about 527 files changed` became 528, and its `47-path list` reference became `48 modified paths`, which excludes the one added file. The range-diff example now ends at C7, and the non-contiguity paragraph names the commits between C6 and C7.
- The dated section 5 measurement ("10 files differ", taken at hand-off) was left as historical.

## Self-Check: PASSED

- Files exist: all 7 modified files are present.
- Commits: f57237d6 and 9cfe8b16 are ancestors of HEAD.
